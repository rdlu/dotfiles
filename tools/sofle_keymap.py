"""The Sofle keymap, resolved against this repo's live key bindings.

The firmware lives in rdlu/sofleii; tools/sofle/ holds a snapshot of the
files this needs (refresh it with `mise run docs-sofle-sync`):

  - eyelash_sofle.keymap   every layer's bindings, macros, behaviours
  - eyelash_sofle.json     the physical layout (key x/y/rotation)
  - rgb_layer.c            zmk-rgb-layer's per-layer underglow colours
  - keymap_overrides.yaml  `&none` keys a firmware module acts on
  - SOURCE                 which sofleii commit the snapshot came from

For every key on the command layers this works out what the keyboard sends
(`&kp LG(LS(K))` -> Super+Shift+K) and then what that does here: a niri bind
from binds.kdl, a tmux root-table bind, an xkb keysym niri binds, or just the
key. gen-docs.py calls `write_data()` (site/data/sofle.json, read by the
`sofle-layer` shortcode) and `gen_md()` (the command tables in docs/sofle.md).
Stdlib only.
"""

from __future__ import annotations

import colorsys
import json
import math
import re
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SNAP = REPO / "tools" / "sofle"
NIRI_BINDS = REPO / "niri" / "dot-config" / "niri" / "binds.kdl"
TMUX_CONF = REPO / "terminal" / "dot-tmux.conf"
DATA_OUT = REPO / "site" / "data" / "sofle.json"

# The layers that carry commands. The game layers (5-9) are plain keys for
# games; sofleii's own docs cover them.
LAYERS = ["BASE", "NAV", "CODE", "MEDIA", "SYS|NUM"]

# Keys named by where they are rather than by a BASE letter: the 5-way
# joystick is the centre column, 52 the left encoder's push. (Turning the
# encoder has no position: it's the layers' sensor-bindings, volume.)
PLACES = {6: "joystick ↑", 19: "joystick ↓", 32: "joystick ←",
          45: "joystick →", 58: "joystick press", 52: "encoder press"}

# --------------------------------------------------------------------------
# Keys: ZMK name -> (cap legend, niri/xkb key name, long name)
# --------------------------------------------------------------------------

MOD_FUNCS = {"LG": "Super", "RG": "Super", "LS": "Shift", "RS": "Shift",
             "LC": "Ctrl", "RC": "Ctrl", "LA": "Alt", "RA": "AltGr"}
MOD_KEYS = {"LGUI": "Super", "RGUI": "Super", "LSHFT": "Shift",
            "RSHFT": "Shift", "LCTRL": "Ctrl", "RCTRL": "Ctrl",
            "LALT": "Alt", "RALT": "AltGr"}
MOD_GLYPH = {"Super": "◆", "Ctrl": "⌃", "Alt": "⌥", "Shift": "⇧",
             "AltGr": "AltGr "}
MOD_ORDER = ["Super", "Ctrl", "Alt", "AltGr", "Shift"]

KEYS: dict[str, tuple[str, str, str]] = {
    "GRAVE": ("`", "grave", "`"), "MINUS": ("-", "minus", "-"),
    "EQUAL": ("=", "equal", "="), "BSLH": ("\\", "backslash", "\\"),
    "FSLH": ("/", "slash", "/"), "SEMI": (";", "semicolon", ";"),
    "APOS": ("'", "apostrophe", "'"), "COMMA": (",", "comma", ","),
    "DOT": (".", "period", "."), "LBKT": ("[", "bracketleft", "["),
    "RBKT": ("]", "bracketright", "]"), "LBRC": ("{", "braceleft", "{"),
    "RBRC": ("}", "braceright", "}"), "LPAR": ("(", "parenleft", "("),
    "RPAR": (")", "parenright", ")"), "PLUS": ("+", "plus", "+"),
    "UNDER": ("_", "underscore", "_"), "PERCENT": ("%", "percent", "%"),
    "TAB": ("Tab", "Tab", "Tab"), "ESC": ("Esc", "Escape", "Escape"),
    "RET": ("⏎", "Return", "Enter"), "ENTER": ("⏎", "Return", "Enter"),
    "BSPC": ("⌫", "BackSpace", "Backspace"), "DEL": ("Del", "Delete", "Delete"),
    "SPACE": ("Space", "space", "Space"), "INS": ("Ins", "Insert", "Insert"),
    "HOME": ("Home", "Home", "Home"), "END": ("End", "End", "End"),
    "PG_UP": ("PgUp", "Page_Up", "Page Up"),
    "PG_DN": ("PgDn", "Page_Down", "Page Down"),
    "UP": ("↑", "Up", "Up"), "UP_ARROW": ("↑", "Up", "Up"),
    "DOWN": ("↓", "Down", "Down"), "DOWN_ARROW": ("↓", "Down", "Down"),
    "LEFT": ("←", "Left", "Left"), "LEFT_ARROW": ("←", "Left", "Left"),
    "RIGHT": ("→", "Right", "Right"), "RIGHT_ARROW": ("→", "Right", "Right"),
    "PSCRN": ("PrtSc", "Print", "Print"),
    "PRINTSCREEN": ("PrtSc", "Print", "Print"),
    "PAUSE_BREAK": ("Pause", "Pause", "Pause"),
    "K_APP": ("Menu", "Menu", "Menu (context menu)"),
    "KP_NUM": ("NumLk", "Num_Lock", "Num Lock"),
    "KP_SLASH": ("/", "KP_Divide", "keypad /"),
    "KP_ASTERISK": ("*", "KP_Multiply", "keypad *"),
    "KP_MINUS": ("-", "KP_Subtract", "keypad -"),
    "KP_PLUS": ("+", "KP_Add", "keypad +"),
    "KP_ENTER": ("⏎", "KP_Enter", "keypad Enter"),
    "KP_EQUAL": ("=", "KP_Equal", "keypad ="),
    "KP_DOT": (".", "KP_Decimal", "keypad ."),
    # Consumer keys arrive as XF86 keysyms; F20 is XF86AudioMicMute in xkb's
    # evdev map (symbols/inet), which is why the MEDIA layer uses it.
    "C_VOL_UP": ("Vol+", "XF86AudioRaiseVolume", "XF86AudioRaiseVolume"),
    "C_VOL_DN": ("Vol−", "XF86AudioLowerVolume", "XF86AudioLowerVolume"),
    "C_MUTE": ("Mute", "XF86AudioMute", "XF86AudioMute"),
    "C_PP": ("Play", "XF86AudioPlay", "XF86AudioPlay"),
    "C_NEXT": ("Next", "XF86AudioNext", "XF86AudioNext"),
    "C_PREV": ("Prev", "XF86AudioPrev", "XF86AudioPrev"),
    "C_STOP": ("Stop", "XF86AudioStop", "XF86AudioStop"),
    "C_BRI_UP": ("Bri+", "XF86MonBrightnessUp", "XF86MonBrightnessUp"),
    "C_BRI_DN": ("Bri−", "XF86MonBrightnessDown", "XF86MonBrightnessDown"),
    "C_AL_CALC": ("Calc", "XF86Calculator", "XF86Calculator"),
    # The upper F-keys reach xkb as these keysyms (symbols/inet). F13 is
    # XF86Tools, push-to-talk on the game layers; F22/F23 are touchpad
    # on/off. F19 and F24 stay plain F-keys.
    "F13": ("F13", "XF86Tools", "F13→XF86Tools"),
    "F14": ("F14", "XF86Launch5", "F14→XF86Launch5"),
    "F15": ("F15", "XF86Launch6", "F15→XF86Launch6"),
    "F16": ("F16", "XF86Launch7", "F16→XF86Launch7"),
    "F17": ("F17", "XF86Launch8", "F17→XF86Launch8"),
    "F18": ("F18", "XF86Launch9", "F18→XF86Launch9"),
    "F20": ("F20", "XF86AudioMicMute", "F20→XF86AudioMicMute"),
    "F21": ("F21", "XF86TouchpadToggle", "F21→XF86TouchpadToggle"),
    "F22": ("F22", "XF86TouchpadOn", "F22→XF86TouchpadOn"),
    "F23": ("F23", "XF86TouchpadOff", "F23→XF86TouchpadOff"),
}

# Keys the keyboard sends for host binds that nothing binds yet: drawn as
# spare slots instead of plain keys.
SPARE = {"F14", "F15", "F16", "F17", "F18", "F19", "F21", "F24", "C_AL_CALC"}
for _c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
    KEYS[_c] = (_c, _c, _c)
for _d in range(10):
    KEYS[f"N{_d}"] = (str(_d), str(_d), str(_d))
    KEYS[f"KP_N{_d}"] = (str(_d), f"KP_{_d}", f"keypad {_d}")
for _f in range(1, 25):
    KEYS.setdefault(f"F{_f}", (f"F{_f}", f"F{_f}", f"F{_f}"))

# Characters for a macro's typed text.
MACRO_CHARS = {
    "PIPE": "|", "GT": ">", "LT": "<", "MINUS": "-", "EQUAL": "=",
    "COLON": ":", "LPAR": "(", "RPAR": ")", "LBKT": "[", "RBKT": "]",
    "LBRC": "{", "RBRC": "}", "DQT": '"', "TILDE": "~", "FSLH": "/",
    "EXCL": "!", "UNDER": "_", "PRCNT": "%", "SPACE": " ", "GRAVE": "`",
    "AMPS": "&", "DOT": ".", "PLUS": "+", "STAR": "*", "HASH": "#",
}

# --------------------------------------------------------------------------
# What a niri action is called on a keycap (the tooltip has the full name).
# --------------------------------------------------------------------------

ARROWS = {"left": "←", "right": "→", "up": "↑", "down": "↓",
          "previous": "prev", "next": "next"}

NIRI_SHORT = {
    "screenshot": "Shot region", "screenshot-screen": "Shot screen",
    "screenshot-window": "Shot window",
}
SPAWN_SHORT = {
    "volume-up": "Vol +", "volume-down": "Vol −", "volume-mute": "Mute",
    "mic-mute": "Mic mute", "brightness-up": "Bright +",
    "brightness-down": "Bright −", "screenshot-annotate": "Shot + edit",
    "play-pause": "Play / pause", "next": "Next", "previous": "Prev",
    "lock-session": "Lock",
}
# Scripts whose last argument is a step: "<short> <step>".
SCRIPT_SHORT = {"ext-brightness": "Ext bri"}


# Keycap names for binds' hotkey-overlay-titles that are too long.
TITLE_SHORT = {"Do not disturb": "DND", "Clipboard history": "Clipboard",
               "Control center": "Control center", "Emoji picker": "Emoji",
               "Menu Power": "Power menu", "Calculator": "Calc"}


def niri_short(action: str, title: str = "") -> str:
    head, _, arg = action.partition(" ")
    if head in NIRI_SHORT:
        return NIRI_SHORT[head]
    if head == "focus-workspace":
        return f"WS {arg.strip(chr(34))}"
    m = re.fullmatch(r"(focus|move-column-to|move-window-to|move-workspace-to)"
                     r"-(workspace|monitor|column|window)-(\w+)", head)
    if m:
        verb, what, way = m.groups()
        what = {"workspace": "WS", "monitor": "Mon"}.get(what, what.title())
        way = ARROWS.get(way, way)
        return f"{what} {way}" if verb == "focus" else f"Col → {what} {way}"
    if head in ("spawn", "spawn-sh"):
        args = re.findall(r'"((?:[^"\\]|\\.)*)"', action)
        last = (args[-1] if args else arg).split()[-1]
        script = Path(args[0]).name if args else ""
        if script in SCRIPT_SHORT and re.fullmatch(r"[+-]\d+", last):
            return f"{SCRIPT_SHORT[script]} {last[0]}"
        if script == "wpctl":
            if "set-mute" in args:
                return "Mic mute" if "@DEFAULT_AUDIO_SOURCE@" in args else "Mute"
            return "Vol +" if last.endswith("+") else "Vol −"
        if script == "brightnessctl":
            return "Bright +" if last.endswith("+") else "Bright −"
        if last in SPAWN_SHORT:
            return SPAWN_SHORT[last]
        if title and title != "null":
            title = title.removesuffix(" on/off")
            return TITLE_SHORT.get(title, title)
        return last
    return head.replace("-", " ").capitalize()


def niri_long(action: str, title: str) -> str:
    if title and title != "null":
        return title
    head, _, _ = action.partition(" ")
    if head in ("spawn", "spawn-sh"):
        args = re.findall(r'"((?:[^"\\]|\\.)*)"', action)
        tool = Path((args[0] if args else action.split()[1]).split()[0]).name
        return f"{niri_short(action)} ({tool})"
    return action.replace('"', "").replace("-", " ").capitalize()


# --------------------------------------------------------------------------
# Binding lookups: niri binds.kdl and tmux's root key table
# --------------------------------------------------------------------------

def _norm(mods, key: str) -> tuple[frozenset, str]:
    return frozenset(mods), key.lower()


def niri_index() -> dict:
    """(mods, key) -> {action, title, line} for every active niri bind."""
    lines = NIRI_BINDS.read_text().splitlines()
    out = {}
    names = {"Mod": "Super", "Super": "Super", "Win": "Super",
             "Ctrl": "Ctrl", "Control": "Ctrl", "Shift": "Shift",
             "Alt": "Alt", "ISO_Level3_Shift": "AltGr"}
    pat = re.compile(r'^\s*([A-Za-z0-9_]+(?:\+[A-Za-z0-9_]+)*)\s+'
                     r'((?:[a-z-]+=(?:"[^"]*"|\S+)\s+)*)\{\s*(.*?)\s*;?\s*\}?\s*$')
    for n, line in enumerate(lines, 1):
        line = re.sub(r"\s*//.*$", "", line)
        m = pat.match(line)
        if not m or m.group(1) == "binds":
            continue
        *mods, key = m.group(1).split("+")
        if any(x not in names for x in mods):
            continue
        props = dict(re.findall(r'([a-z-]+)="?([^"\s]*(?:[^"]*)?)"?(?=\s|$)', m.group(2)))
        title = re.search(r'hotkey-overlay-title="([^"]*)"', m.group(2))
        out[_norm({names[x] for x in mods}, key)] = {
            "action": " ".join(m.group(3).rstrip("; }").split()),
            "title": title.group(1) if title else "",
            "line": n,
            "locked": props.get("allow-when-locked") == "true",
        }
    return out


TMUX_ROOT_DESC = {"F12": "toggle nested OFF mode (pass keys to an inner tmux)"}


def tmux_root() -> dict:
    """tmux root-table keys bound in dot-tmux.conf: key -> (desc, line)."""
    out = {}
    for n, line in enumerate(TMUX_CONF.read_text().splitlines(), 1):
        m = re.match(r"^\s*bind(?:-key)?\s+(?:-T\s+root|-n)\s+(\S+)", line)
        if m:
            key = m.group(1)
            out[key] = (TMUX_ROOT_DESC.get(key, "root-table bind"), n)
    return out


# --------------------------------------------------------------------------
# Parsing the keymap snapshot
# --------------------------------------------------------------------------

def keymap_text() -> str:
    text = (SNAP / "eyelash_sofle.keymap").read_text()
    return re.sub(r"//[^\n]*", "", re.sub(r"(?s)/\*.*?\*/", "", text))


def parse_layers(text: str) -> tuple[list[str], dict[str, list[str]]]:
    block = text[text.index("compatible = \"zmk,keymap\";"):]
    order, layers = [], {}
    for body, name in re.findall(
            r'(?s)\w+ \{\s*bindings = <(.*?)>;.*?display-name = "([^"]+)";', block):
        layers[name] = [" ".join(t.split()) for t in re.findall(r"&[^&]+", body)]
        order.append(name)
    return order, layers


def parse_macros(text: str) -> dict[str, dict]:
    """Macro name -> {text, cursor, label}; text only when it is plain typing."""
    out = {}
    for name, body in re.findall(
            r'(?s)(\w+): \w+ \{\s*compatible = "zmk,behavior-macro";(.*?)\};', text):
        label = re.search(r'label = "([^"]+)"', body)
        b = re.search(r"(?s)bindings\s*=\s*(.*?);", body)
        typed, lefts, ok = "", 0, True
        for tok in re.findall(r"&[^&]+", b.group(1) if b else ""):
            f = re.sub(r"[<>,]", " ", tok).split()
            if len(f) != 2 or f[0] != "&kp":
                ok = False
                break
            k = f[1]
            if k == "LEFT":
                lefts += 1
                continue
            if lefts:
                ok = False
                break
            if k in MACRO_CHARS:
                typed += MACRO_CHARS[k]
            elif re.fullmatch(r"[A-Z]", k):
                typed += k.lower()
            elif re.fullmatch(r"LS\(([A-Z])\)", k):
                typed += k[3]
            else:
                ok = False
                break
        out[name] = {"label": label.group(1) if label else name,
                     "text": typed if ok else None, "lefts": lefts}
    return out


def parse_chord(expr: str) -> tuple[list[str], str]:
    """`LG(LS(K))` -> (["Super", "Shift"], "K")."""
    mods = []
    while (m := re.fullmatch(r"(L[GSCA]|R[GSCA])\((.*)\)", expr)):
        mods.append(MOD_FUNCS[m.group(1)])
        expr = m.group(2)
    return sorted(set(mods), key=MOD_ORDER.index), expr


def chord_cap(mods, key) -> str:
    return "".join(MOD_GLYPH[m] for m in mods) + KEYS.get(key, (key,))[0]


def chord_long(mods, key) -> str:
    return "+".join([*mods, KEYS.get(key, (None, None, key))[2]])


def layer_colors(order: list[str]) -> dict[str, str]:
    """Layer name -> a hex of its underglow hue that reads on white (4.5:1).

    Same rule as sofleii's zs/layer-colors.html: keep hue and saturation
    (HSV), lower the value until the contrast clears 4.5:1.
    """
    text = (SNAP / "rgb_layer.c").read_text()
    block = re.search(r"(?s)layer_colors\[\]\s*=\s*\{(.*?)\};", text).group(1)
    out = {}
    for idx, h, s in re.findall(r"\[(\d+)\]\s*=\s*\{\s*(\d+)\s*,\s*(\d+)\s*\}", block):
        for step in range(95, 4, -1):
            rgb = colorsys.hsv_to_rgb(int(h) / 360, int(s) / 100, step / 100)
            b = [round(c * 255) for c in rgb]
            lum = sum(w * ((c / 255) / 12.92 if c / 255 <= 0.04045
                           else (((c / 255) + 0.055) / 1.055) ** 2.4)
                      for w, c in zip((0.2126, 0.7152, 0.0722), b))
            if 1.05 / (lum + 0.05) >= 4.5:
                if int(idx) < len(order):
                    out[order[int(idx)]] = "#%02x%02x%02x" % tuple(b)
                break
    return out


def overrides() -> dict[str, dict[int, dict]]:
    """keymap_overrides.yaml (a fixed two-level shape, so no YAML parser)."""
    out, layer = {}, None
    for line in (SNAP / "keymap_overrides.yaml").read_text().splitlines():
        if (m := re.match(r'^"([^"]+)":\s*$', line)):
            layer = out.setdefault(m.group(1), {})
        elif layer is not None and (m := re.match(
                r'^\s+"(\d+)":\s*\{\s*label:\s*"([^"]*)",\s*note:\s*"([^"]*)"', line)):
            layer[int(m.group(1))] = {"label": m.group(2), "note": m.group(3)}
    return out


def physical() -> tuple[list[dict], dict]:
    data = json.loads((SNAP / "eyelash_sofle.json").read_text())
    keys, xs, ys = [], [], []
    for k in data["layouts"]["default_layout"]["layout"]:
        x, y, r = float(k["x"]), float(k["y"]), float(k.get("r", 0))
        rx, ry = float(k.get("rx", x)), float(k.get("ry", y))
        a = math.radians(r)
        for cx, cy in ((0, 0), (1, 0), (0, 1), (1, 1)):
            dx, dy = x + cx - rx, y + cy - ry
            xs.append(rx + dx * math.cos(a) - dy * math.sin(a))
            ys.append(ry + dx * math.sin(a) + dy * math.cos(a))
        keys.append({"x": x, "y": y, "r": r, "rx": rx, "ry": ry})
    minx, miny = min(xs), min(ys)
    for k in keys:
        # Rotation origin relative to the key's own corner, as CSS wants it.
        k["ox"], k["oy"] = round(k.pop("rx") - k["x"], 3), round(k.pop("ry") - k["y"], 3)
        k["x"], k["y"] = round(k["x"] - minx, 3), round(k["y"] - miny, 3)
    return keys, {"minx": minx, "miny": miny,
                  "w": round(max(xs) - minx, 3), "h": round(max(ys) - miny, 3)}


# --------------------------------------------------------------------------
# Resolving one key
# --------------------------------------------------------------------------

class Resolver:
    def __init__(self):
        self.text = keymap_text()
        self.order, self.raw = parse_layers(self.text)
        self.macros = parse_macros(self.text)
        self.niri = niri_index()
        self.tmux = tmux_root()

    def command(self, mods, key):
        """What a sent chord does here: (kind, cap, long, source) or None."""
        name = KEYS.get(key, (None, key, None))[1]
        hit = self.niri.get(_norm(mods, name))
        if hit:
            spawn = hit["action"].startswith(("spawn", "spawn-sh"))
            src = f"niri/dot-config/niri/binds.kdl:{hit['line']}"
            what = niri_long(hit["action"], hit["title"])
            bind = f"niri: {hit['action']}"
            if hit["locked"]:
                bind += " · works on the lock screen"
            return ("run" if spawn else "niri", niri_short(hit["action"], hit["title"]),
                    what, bind, src)
        if not mods and key in self.tmux:
            desc, line = self.tmux[key]
            return ("app", "tmux OFF", f"tmux: {desc}", f"tmux: bind -T root {key}",
                    f"terminal/dot-tmux.conf:{line}")
        return None

    def tap(self, expr: str) -> dict:
        """A `&kp` argument: legend, chord sent and the command, if any."""
        if expr in MOD_KEYS:
            mod = MOD_KEYS[expr]
            return {"t": MOD_GLYPH[mod].strip() if mod != "AltGr" else "AltGr",
                    "kind": "mod", "sends": mod}
        mods, key = parse_chord(expr)
        out = {"t": chord_cap(mods, key), "kind": "key",
               "sends": chord_long(mods, key)}
        if key not in KEYS:
            out["t"] = key
        cmd = self.command(mods, key)
        if not cmd and not mods and key in SPARE:
            out.update(kind="spare", does="not bound on the host yet")
        if cmd:
            kind, cap, what, action, src = cmd
            out.update(kind=kind, s=out["t"], t=cap, does=what, action=action,
                       src=src)
        return out

    def key(self, layer: str, pos: int, raw: str, below: dict | None) -> dict:
        f = raw.split()
        b = f[0][1:]
        if raw == "&trans":
            e = {"kind": "trans", "t": below["t"] if below else "",
                 "does": "transparent: falls through to the layer below"}
            if below and below.get("does"):
                e["does"] += f" ({below['does']})"
            return e
        if raw == "&none":
            return {"kind": "none", "t": "", "does": "does nothing"}
        if b == "kp":
            return self.tap(f[1])
        if b in ("hml", "hmr", "hml_idx", "hmr_idx", "mt", "ralt_mt"):
            e = self.tap(f[2])
            hold = MOD_KEYS.get(f[1], f[1])
            e["h"] = MOD_GLYPH[hold].strip() if hold != "AltGr" else "AltGr"
            e["hold"] = hold + (" (third level: the usbr layout's ã õ ç …)"
                                if hold == "AltGr" else "")
            return e
        if b in ("mo", "to"):
            name = self.order[int(f[1])]
            verb = "hold for" if b == "mo" else "switch to"
            return {"kind": "layer", "t": name if b == "mo" else f"→ {name}",
                    "does": f"{verb} layer {f[1]} ({name})"}
        if b == "caps_word":
            return {"kind": "fw", "t": "CapsWd",
                    "does": "Caps Word: the next word in capitals"}
        if b == "bt":
            if f[1] == "BT_CLR":
                return {"kind": "fw", "t": "BT clr",
                        "does": "forget the selected Bluetooth profile's host"}
            n = int(f[2]) + 1
            return {"kind": "fw", "t": f"BT {n}",
                    "does": f"select Bluetooth profile {n}"}
        if b == "rgb_ug":
            label = {"RGB_TOG": "RGB ⏻", "RGB_SAI": "Sat+", "RGB_SAD": "Sat−",
                     "RGB_HUI": "Hue+", "RGB_HUD": "Hue−", "RGB_EFF": "FX+",
                     "RGB_EFR": "FX−"}.get(f[1], f[1])
            return {"kind": "fw", "t": label, "does": f"underglow: {f[1]}"}
        if b == "mkp":
            label = {"LCLK": "L click", "RCLK": "R click", "MCLK": "M click",
                     "MB4": "Back", "MB5": "Fwd"}.get(f[1], f[1])
            return {"kind": "fw", "t": label, "does": f"mouse button {f[1]}"}
        if b == "mmv":
            way = ARROWS.get(f[1].split("_")[1].lower(), f[1])
            return {"kind": "fw", "t": f"Ptr {way}", "does": "move the mouse pointer"}
        if b == "SYSRQ":
            return {"kind": "sysrq", "t": "SysRq", "sends": "Alt+SysRq, Alt held",
                    "does": "kernel Magic SysRq: keep holding, tap a command "
                            "letter; kernel.sysrq decides which work "
                            "(16, the systemd default: S, sync, only)",
                    "action": "macro SYSRQ"}
        if b in self.macros:
            m = self.macros[b]
            if m["text"] is not None:
                t = m["text"]
                cut = len(t) - m["lefts"]
                cap = t[:cut] + "▏" + t[cut:] if m["lefts"] else t
                return {"kind": "text", "t": cap, "does": f"types {t!r}"
                        + (", cursor at ▏" if m["lefts"] else ""),
                        "action": f"macro {b}"}
            return {"kind": "fw", "t": m["label"], "does": f"macro {m['label']}"}
        return {"kind": "fw", "t": b, "does": raw}


def build() -> dict:
    r = Resolver()
    phys, box = physical()
    colors = layer_colors(r.order)
    over = overrides()
    base = None
    layers = []
    for name in LAYERS:
        num = r.order.index(name)
        out = []
        for pos, raw in enumerate(r.raw[name]):
            below = base[pos] if base and name != "BASE" else None
            e = r.key(name, pos, raw, below)
            o = over.get(name, {}).get(pos)
            if o and raw == "&none":
                e = {"kind": "fw", "t": o["label"],
                     "does": f"{o['note']} (zmk-rgb-layer, not the keymap)"}
            # The key holding this layer: a `&mo N` below it, here &trans.
            if raw == "&trans" and base and r.raw["BASE"][pos] == f"&mo {num}":
                e = {"kind": "held", "t": name, "does": "held to be on this layer"}
            e["pos"] = pos
            e["raw"] = raw
            if pos in PLACES:
                e["where"] = PLACES[pos]
            out.append(e)
        if name == "BASE":
            base = out
        layers.append({"name": name, "num": num,
                       "color": colors.get(name, "#644ac9"), "keys": out})
    # Hover text: plain rows the template prints as a definition list.
    for layer in layers:
        for e in layer["keys"]:
            tip = []
            letter = base[e["pos"]]["s" if "s" in base[e["pos"]] else "t"]
            e["at"] = e.get("where") or letter
            tip.append(["key", f"{e['at']} · position {e['pos']}"])
            if e.get("sends"):
                tip.append(["sends", e["sends"]])
            if e.get("does"):
                tip.append(["does", e["does"]])
            if e.get("hold"):
                tip.append(["hold", e["hold"]])
            if e.get("action"):
                tip.append(["bind", e["action"]])
            if e.get("src"):
                tip.append(["from", e["src"]])
            tip.append(["zmk", e["raw"]])
            e["tip"] = tip
            e["len"] = len(e.get("t", ""))
    source = (SNAP / "SOURCE").read_text().split()
    return {"layers": layers, "keys": phys, "box": box,
            "source": {"repo": source[0], "commit": source[1], "date": source[2]}}


def write_data() -> Path:
    DATA_OUT.parent.mkdir(exist_ok=True)
    DATA_OUT.write_text(json.dumps(build(), ensure_ascii=False, indent=1) + "\n")
    return DATA_OUT


def code(text: str) -> str:
    """A code span for a table cell, fenced past any backticks inside."""
    ticks = "``" if "`" in text else "`"
    pad = " " if "`" in text else ""
    return f"{ticks}{pad}{text.replace('|', chr(92) + '|')}{pad}{ticks}"


def cell(text: str) -> str:
    return text.replace("|", "\\|").replace("`", "&#96;")


def gen_md() -> str:
    """Per layer, the keys that do more than type their legend.

    Commands (niri, tmux) get a table whose first column is the chord sent,
    which shortcuts.js draws as keycaps (first header "Keys sent"); text
    macros and firmware keys get plain two-column tables.
    """
    parts = []
    for layer in build()["layers"]:
        cmds, typed, fw = [], [], []
        for e in layer["keys"]:
            at = cell(e["at"])
            if e["kind"] in ("niri", "run", "app"):
                cmds.append(f"| {code(e['sends'])} | {at} | {cell(e['does'])} |")
            elif e["kind"] == "text":
                typed.append(f"| {at} | {code(e['t'])} |")
            elif e["kind"] in ("fw", "sysrq", "spare") and layer["name"] != "BASE":
                fw.append(f"| {at} | {cell(e['t'])} | {cell(e['does'])} |")
        blocks = []
        if cmds:
            blocks.append("| Keys sent | Sofle key | Does |\n| --- | --- | --- |\n"
                          + "\n".join(cmds))
        if typed:
            blocks.append("| Sofle key | Types (▏ = cursor) |\n| --- | --- |\n"
                          + "\n".join(typed))
        if fw:
            blocks.append("| Sofle key | Label | Does (in the firmware) |\n"
                          "| --- | --- | --- |\n" + "\n".join(fw))
        if blocks:
            parts.append(f"### {layer['name']}\n\n" + "\n\n".join(blocks))
    return "\n\n".join(parts)
