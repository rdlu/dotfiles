/*
 * zmk-rgb-layer — event-driven per-layer RGB underglow indicator.
 *
 * Listens for layer-state changes and paints the underglow the highest active
 * layer's colour by invoking the GLOBAL &rgb_ug behaviour (ZMK forwards it to
 * both split halves). Central-only (uses the keymap API).
 *
 * Phase 2: the BASE layer's appearance is a runtime-selectable "mood"
 *   DARK   — underglow off
 *   TEAL   — solid dim teal (default)
 *   SWIRL  — animated rainbow swirl
 * cycled by pressing the mood key (a &none key) while the SYS layer is held.
 * Non-base layers always light their solid colour regardless of mood.
 *
 * RGB writes are minimised: a small state cache (on/effect/colour) means each
 * layer change usually emits a SINGLE &rgb_ug call, which keeps the split-bus
 * traffic — the dominant latency source — low.
 *
 * Persistence: the chosen mood + master brightness are saved to the settings
 * partition (debounced, mirroring ZMK's own rgb_underglow). They are restored
 * on boot so a power-cycle / soft-off comes back with the look you last set,
 * not the TEAL/50 defaults. Because ZMK runs settings_load() in main() — AFTER
 * every SYS_INIT — the boot paint is deferred to a short delayed-work item so
 * it fires once the persisted values are loaded (and the split link is up).
 */

#include <zephyr/kernel.h>
#include <zephyr/init.h>
#include <zephyr/logging/log.h>
#include <zephyr/settings/settings.h>
#if IS_ENABLED(CONFIG_BT)
#include <zephyr/bluetooth/conn.h>
#endif

#include <zmk/behavior.h>
#include <zmk/event_manager.h>
#include <zmk/keymap.h>
#include <zmk/events/layer_state_changed.h>
#include <zmk/events/position_state_changed.h>

#include <dt-bindings/zmk/rgb.h>

LOG_MODULE_REGISTER(zmk_rgb_layer, CONFIG_ZMK_LOG_LEVEL);

/* Keymap coupling: three dedicated mood keys on the SYS layer (each a &none key
 * so it has no other effect). Pressed while SYS is the highest active layer:
 *   pos 40 -> DARK, pos 41 -> DIM (teal), pos 42 -> cycle the animations. */
#define SYS_LAYER 4
#define MOOD_KEY_DARK 40
#define MOOD_KEY_DIM 41
#define MOOD_KEY_FX 42
/* The underglow brightness keys, now owned by the module so the level sticks. */
#define BRIGHT_KEY_UP 13
#define BRIGHT_KEY_DOWN 26

/* ZMK underglow effect ids (see rgb_underglow.c UNDERGLOW_EFFECT_*). */
#define EFFECT_SOLID 0
#define EFFECT_BREATHE 1
#define EFFECT_SPECTRUM 2
#define EFFECT_SWIRL 3

#define NO_COLOR 0xFFFFFFFFu /* impossible packed HSB — cache "unknown" sentinel */

/* BASE moods: DARK and TEAL are set directly by their keys; the three
 * animations are reached by the effects key, which steps through them. */
enum base_mood {
    MOOD_DARK = 0,
    MOOD_TEAL = 1,
    MOOD_BREATHE = 2,
    MOOD_SPECTRUM = 3,
    MOOD_SWIRL = 4,
};

static enum base_mood base_mood = MOOD_TEAL;

/* Master brightness applied to all colours, so the underglow brightness keys
 * (which the module now owns) actually stick across repaints. Clamped to
 * [BRIGHT_MIN, BRIGHT_MAX]; BRIGHT_MAX matches CONFIG_..._BRT_MAX (60). */
#define BRIGHT_MIN 4
#define BRIGHT_MAX 60
#define BRIGHT_STEP 8
static uint8_t brightness = 50;

/* The resting TEAL base sits at ~30% of master so it stays a dim glow. */
static uint8_t base_brightness(void) {
    uint8_t v = (uint16_t)brightness * 3 / 10;
    return v < 2 ? 2 : v;
}

struct layer_color {
    uint16_t h;
    uint8_t s;
};

/* Hue/sat for non-base layers, indexed by layer. Brightness is the master. */
static const struct layer_color layer_colors[] = {
    [1] = {250, 100}, /* NAV     — indigo  */
    [2] = {290, 100}, /* CODE    — magenta */
    [3] = {35, 100},  /* MEDIA   — amber   */
    [4] = {0, 100},   /* SYS|NUM — red     */
    [5] = {280, 100}, /* GAME?   — violet  */
    [6] = {120, 100}, /* MINECRFT— green   */
    [7] = {220, 100}, /* GAME    — blue    */
    [8] = {0, 0},     /* NOMANSKY— white   */
    [9] = {60, 100},  /* MYGAME  — yellow  */
};

#define NUM_LAYER_COLORS (sizeof(layer_colors) / sizeof(layer_colors[0]))

/* Desired underglow state for a layer. `color` applies when has_color (solid
 * and breathe use a base colour; spectrum/swirl cycle hues and ignore it). */
struct desired {
    bool on;
    int effect;
    bool has_color;
    uint32_t color;
};

/* Cache of what we last told the strip, so we only emit the diff. */
static bool strip_on;
static int cur_effect = -1;
static uint32_t cur_color = NO_COLOR;

static void invoke_rgb(uint32_t cmd, uint32_t val) {
    struct zmk_behavior_binding binding = {
        .behavior_dev = "rgb_ug",
        .param1 = cmd,
        .param2 = val,
    };
    struct zmk_behavior_binding_event event = {
        .layer = 0,
        .position = 0,
        .timestamp = k_uptime_get(),
#if IS_ENABLED(CONFIG_ZMK_SPLIT)
        .source = 0,
#endif
    };
    zmk_behavior_invoke_binding(&binding, event, true);
}

static struct desired desired_for(uint8_t layer) {
    if (layer != 0) {
        struct layer_color c =
            (layer < NUM_LAYER_COLORS) ? layer_colors[layer] : (struct layer_color){0, 0};
        return (struct desired){true, EFFECT_SOLID, true, RGB_COLOR_HSB_VAL(c.h, c.s, brightness)};
    }

    switch (base_mood) {
    case MOOD_DARK:
        return (struct desired){false, EFFECT_SOLID, false, 0};
    case MOOD_BREATHE:
        return (struct desired){true, EFFECT_BREATHE, true, RGB_COLOR_HSB_VAL(160, 100, brightness)};
    case MOOD_SPECTRUM:
        return (struct desired){true, EFFECT_SPECTRUM, false, 0};
    case MOOD_SWIRL:
        return (struct desired){true, EFFECT_SWIRL, false, 0};
    case MOOD_TEAL:
    default:
        return (struct desired){true, EFFECT_SOLID, true,
                                RGB_COLOR_HSB_VAL(160, 100, base_brightness())};
    }
}

static void apply_desired(struct desired d) {
    if (!d.on) {
        if (strip_on) {
            invoke_rgb(RGB_OFF_CMD, 0);
            strip_on = false;
        }
        return;
    }

    if (!strip_on) {
        invoke_rgb(RGB_ON_CMD, 0);
        strip_on = true;
    }
    if (d.effect != cur_effect) {
        invoke_rgb(RGB_EFS_CMD, d.effect);
        cur_effect = d.effect;
    }
    if (d.has_color && d.color != cur_color) {
        invoke_rgb(RGB_COLOR_HSB_CMD, d.color);
        cur_color = d.color;
    }
}

static void apply_layer(uint8_t layer) {
    apply_desired(desired_for(layer));
}

/* Re-send the FULL desired state, ignoring the diff-cache. Used when a split
 * peripheral (re)connects: it boots restoring its OWN stale underglow state, and
 * the central's cache would otherwise suppress the corrective re-forward. The
 * cache is refreshed to match so steady-state diffing resumes afterwards. */
static void force_apply(struct desired d) {
    if (!d.on) {
        invoke_rgb(RGB_OFF_CMD, 0);
        strip_on = false;
        return;
    }
    invoke_rgb(RGB_ON_CMD, 0);
    strip_on = true;
    invoke_rgb(RGB_EFS_CMD, d.effect);
    cur_effect = d.effect;
    if (d.has_color) {
        invoke_rgb(RGB_COLOR_HSB_CMD, d.color);
        cur_color = d.color;
    }
}

/* --- Persistence (mood + brightness) ------------------------------------- *
 * Mirrors ZMK's rgb_underglow: a debounced delayable work writes a tiny blob
 * to the settings partition; a static handler restores it during settings_load.
 */
struct rgb_layer_persist {
    uint8_t mood;
    uint8_t brightness;
};

#if IS_ENABLED(CONFIG_SETTINGS)
static struct k_work_delayable save_work;

/* Short, dedicated debounce — NOT ZMK's 60 s CONFIG_ZMK_SETTINGS_SAVE_DEBOUNCE.
 * Mood/brightness changes are deliberate and infrequent, and the whole point is
 * that they survive a soft-off that may follow within seconds of the change.
 * 3 s still coalesces a burst of brightness-key repeats into one flash write. */
#define RGB_LAYER_SAVE_DEBOUNCE_MS 3000

static void rgb_layer_save_work(struct k_work *work) {
    struct rgb_layer_persist blob = {.mood = (uint8_t)base_mood, .brightness = brightness};
    settings_save_one("rgb_layer/state", &blob, sizeof(blob));
}

static void persist_state(void) {
    k_work_reschedule(&save_work, K_MSEC(RGB_LAYER_SAVE_DEBOUNCE_MS));
}

static int rgb_layer_settings_set(const char *name, size_t len, settings_read_cb read_cb,
                                  void *cb_arg) {
    const char *next;
    if (settings_name_steq(name, "state", &next) && !next) {
        struct rgb_layer_persist blob;
        if (len != sizeof(blob)) {
            return -EINVAL;
        }
        int rc = read_cb(cb_arg, &blob, sizeof(blob));
        if (rc < 0) {
            return rc;
        }
        if (blob.mood <= MOOD_SWIRL) {
            base_mood = (enum base_mood)blob.mood;
        }
        if (blob.brightness >= BRIGHT_MIN && blob.brightness <= BRIGHT_MAX) {
            brightness = blob.brightness;
        }
        LOG_INF("restored mood=%d brightness=%d", base_mood, brightness);
        return 0;
    }
    return -ENOENT;
}

SETTINGS_STATIC_HANDLER_DEFINE(rgb_layer, "rgb_layer", NULL, rgb_layer_settings_set, NULL, NULL);
#else
static void persist_state(void) {}
#endif

static void set_mood(enum base_mood m) {
    base_mood = m;
    LOG_INF("base mood -> %d", m);
    /* Live preview: paint the chosen base mood now even though SYS is held, so
     * the change is visible immediately. Releasing SYS repaints base anyway. */
    apply_desired(desired_for(0));
    persist_state();
}

/* The effects key steps through the animations; from DARK/TEAL it enters at the
 * first animation. */
static void cycle_effect(void) {
    switch (base_mood) {
    case MOOD_BREATHE:
        set_mood(MOOD_SPECTRUM);
        break;
    case MOOD_SPECTRUM:
        set_mood(MOOD_SWIRL);
        break;
    case MOOD_SWIRL:
        set_mood(MOOD_BREATHE);
        break;
    default:
        set_mood(MOOD_BREATHE);
        break;
    }
}

static void adjust_brightness(int delta) {
    int b = (int)brightness + delta;
    if (b < BRIGHT_MIN) {
        b = BRIGHT_MIN;
    } else if (b > BRIGHT_MAX) {
        b = BRIGHT_MAX;
    }
    brightness = (uint8_t)b;
    LOG_INF("brightness -> %d", brightness);
    /* Repaint the active layer so the new level shows immediately (and sticks). */
    apply_layer(zmk_keymap_highest_layer_active());
    persist_state();
}

static int rgb_layer_listener(const zmk_event_t *eh) {
    if (as_zmk_layer_state_changed(eh) != NULL) {
        apply_layer(zmk_keymap_highest_layer_active());
        return 0;
    }

    const struct zmk_position_state_changed *psc = as_zmk_position_state_changed(eh);
    if (psc != NULL && psc->state && zmk_keymap_highest_layer_active() == SYS_LAYER) {
        switch (psc->position) {
        case MOOD_KEY_DARK:
            set_mood(MOOD_DARK);
            break;
        case MOOD_KEY_DIM:
            set_mood(MOOD_TEAL);
            break;
        case MOOD_KEY_FX:
            cycle_effect();
            break;
        case BRIGHT_KEY_UP:
            adjust_brightness(+BRIGHT_STEP);
            break;
        case BRIGHT_KEY_DOWN:
            adjust_brightness(-BRIGHT_STEP);
            break;
        default:
            break;
        }
    }

    return 0;
}

ZMK_LISTENER(rgb_layer, rgb_layer_listener);
ZMK_SUBSCRIPTION(rgb_layer, zmk_layer_state_changed);
ZMK_SUBSCRIPTION(rgb_layer, zmk_position_state_changed);

/* Paint the resting base mood shortly after boot. Deferred (not painted inline
 * in the SYS_INIT) because ZMK runs settings_load() in main(), AFTER every
 * SYS_INIT — so the persisted mood/brightness aren't available yet at init
 * time. The delay also gives the split link time to come up so the forwarded
 * &rgb_ug reaches the peripheral half. */
static void rgb_layer_boot_paint(struct k_work *work) {
    force_apply(desired_for(zmk_keymap_highest_layer_active()));
}

static K_WORK_DELAYABLE_DEFINE(boot_paint_work, rgb_layer_boot_paint);

#if IS_ENABLED(CONFIG_BT)
/* When a BLE link comes up on the central (the peripheral half joining, or a
 * host reconnecting), force a full repaint after a short delay — long enough for
 * the split GATT service to finish discovery so the forwarded &rgb_ug lands on
 * the freshly-connected peripheral, overriding the stale state it restored. */
static void rgb_layer_resync(struct k_work *work) {
    force_apply(desired_for(zmk_keymap_highest_layer_active()));
}

static K_WORK_DELAYABLE_DEFINE(resync_work, rgb_layer_resync);

static void rgb_layer_on_connected(struct bt_conn *conn, uint8_t err) {
    if (err) {
        return;
    }
    k_work_reschedule(&resync_work, K_MSEC(2500));
}

BT_CONN_CB_DEFINE(rgb_layer_conn_cb) = {
    .connected = rgb_layer_on_connected,
};
#endif

static int rgb_layer_init(void) {
#if IS_ENABLED(CONFIG_SETTINGS)
    k_work_init_delayable(&save_work, rgb_layer_save_work);
#endif
    k_work_schedule(&boot_paint_work, K_MSEC(1500));
    return 0;
}

SYS_INIT(rgb_layer_init, APPLICATION, CONFIG_APPLICATION_INIT_PRIORITY);
