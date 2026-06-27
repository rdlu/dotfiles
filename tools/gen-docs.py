#!/usr/bin/env python3
"""Regenerate the generated sections of the markdown docs from the live configs.

Reads:
  - terminal/dot-tmux.conf                   -> tmux key bindings
  - terminal/dot-config/zellij/config.kdl    -> zellij key bindings (all modes)
  - niri/dot-config/niri/binds.kdl           -> niri key bindings
  - fish/**/*.fish (top-level `bind` lines)  -> custom shell bindings
  - `just --dump --dump-format json`         -> justfile recipe reference

Writes (in place, between markers):
  - docs/shortcuts/tmux.md     <!-- gen:tmux-binds -->
  - docs/shortcuts/zellij.md   <!-- gen:zellij-binds -->
  - docs/shortcuts/niri.md     <!-- gen:niri-binds -->
  - docs/shortcuts/shell.md    <!-- gen:fish-binds -->
  - docs/justfile.md           <!-- gen:just-recipes -->
plus tools/cheatsheets/data.json, the input for cheatsheet.typ.

Each generated block is replaced between `<!-- gen:NAME -->` and
`<!-- /gen:NAME -->` markers; everything else in the files is hand-written
and left untouched. Stdlib only — no dependencies.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
TMUX_CONF = REPO / "terminal" / "dot-tmux.conf"
NIRI_BINDS = REPO / "niri" / "dot-config" / "niri" / "binds.kdl"
ZELLIJ_CONF = REPO / "terminal" / "dot-config" / "zellij" / "config.kdl"

DOCS = REPO / "docs"


def md_escape(text: str) -> str:
    """Escape characters that would break a markdown table cell."""
    return text.replace("|", "\\|").replace("\n", " ")


def code(text: str) -> str:
    """Wrap in a code span, choosing a fence that doesn't collide."""
    if not text:
        return ""
    ticks = "`" * (max((len(m) for m in re.findall(r"`+", text)), default=0) + 1)
    pad = " " if text.startswith("`") or text.endswith("`") else ""
    return f"{ticks}{pad}{text}{pad}{ticks}"


def table(headers: list[str], rows: list[list[str]]) -> str:
    out = ["| " + " | ".join(headers) + " |",
           "| " + " | ".join("---" for _ in headers) + " |"]
    for row in rows:
        out.append("| " + " | ".join(row) + " |")
    return "\n".join(out)


# --------------------------------------------------------------------------
# tmux
# --------------------------------------------------------------------------

# Human descriptions for binds whose command isn't self-explanatory,
# keyed by (key-table, key).
TMUX_DESCRIPTIONS = {
    ("prefix", "C-a"): "Jump to the last active window",
    ("root", "F12"): "Toggle **OFF mode** for nested/remote tmux — all keys "
                     "(incl. the prefix) pass through to the pane; status bar turns red",
    ("off", "F12"): "Leave OFF mode (restore the local prefix)",
    ("copy-mode-vi", "v"): "Begin selection (vi-style)",
    ("copy-mode-vi", "C-v"): "Toggle rectangle (block) selection",
    ("copy-mode-vi", "y"): "Copy selection and leave copy mode",
    ("prefix", "Escape"): "Enter copy mode",
    ("prefix", "p"): "Paste buffer",
    ("prefix", "r"): "Reload `~/.tmux.conf`",
    ("prefix", "="): "Split pane **horizontally** (keeps current path)",
    ("prefix", "-"): "Split pane **vertically** (keeps current path)",
    ("prefix", "M"): "Mouse mode **ON**",
    ("prefix", "m"): "Mouse mode **OFF**",
    ("prefix", "C-l"): "Send a literal `Ctrl+L` (clear screen) to the pane",
    ("prefix", "u"): "Capture pane and pick a URL to open (urlview popup window)",
    ("root", "C-t"): "Unified **file finder** — passed through in fish/editors, "
                     "else a popup that injects paths into the pane's TUI "
                     "(`pick-files`)",
    ("prefix", "C-t"): "Popup **terminal** in the current pane's path",
}

TMUX_TABLE_TITLES = {
    "prefix": ("After the prefix", "Press the prefix first, then the key."),
    "root": ("No prefix (root table)", "Active anywhere, no prefix needed."),
    "copy-mode-vi": ("Copy mode (vi keys)", "Active while in copy mode."),
    "off": ("OFF mode", "Active only while OFF mode is toggled on."),
}


def parse_tmux(path: Path):
    """Yield (key_table, key, command) for every bind/bind-key line."""
    # Join continuation lines (trailing backslash) into single logical lines.
    logical, buf = [], ""
    for raw in path.read_text().splitlines():
        line = buf + raw
        if line.rstrip().endswith("\\"):
            buf = line.rstrip()[:-1] + " "
            continue
        buf = ""
        logical.append(line)

    prefix = "C-a"
    binds = []
    for line in logical:
        line = line.strip()
        m = re.match(r"^set\s+-g\s+prefix\s+(\S+)", line)
        if m:
            prefix = m.group(1)
        m = re.match(r"^bind(?:-key)?\s+(.*)$", line)
        if not m:
            continue
        rest = m.group(1)
        key_table = "prefix"
        # consume flags
        while True:
            flag = re.match(r"^(-[A-Za-z])\s+(?:(\S+)\s+)?", rest)
            if not flag:
                break
            if flag.group(1) == "-T":
                key_table = flag.group(2)
                rest = rest[flag.end():]
            elif flag.group(1) == "-n":
                key_table = "root"
                rest = rest[len("-n "):].lstrip()
            elif flag.group(1) == "-r":
                rest = rest[len("-r "):].lstrip()
            else:
                rest = rest[flag.end():]
        key, _, command = rest.partition(" ")
        binds.append((key_table, key, " ".join(command.split())))
    return prefix, binds


def shorten(cmd: str, limit: int = 72) -> str:
    return cmd if len(cmd) <= limit else cmd[: limit - 1] + "…"


def gen_tmux() -> str:
    prefix, binds = parse_tmux(TMUX_CONF)
    by_table: dict[str, list] = {}
    for key_table, key, command in binds:
        by_table.setdefault(key_table, []).append((key, command))

    parts = [f"The prefix is {code(prefix)} (`Ctrl+a`)."]
    for key_table in ("prefix", "root", "copy-mode-vi", "off"):
        rows = by_table.pop(key_table, [])
        if not rows:
            continue
        title, hint = TMUX_TABLE_TITLES[key_table]
        parts.append(f"### {title}\n\n{hint}")
        parts.append(table(
            ["Key", "Description", "Command"],
            [[code(md_escape(key)),
              TMUX_DESCRIPTIONS.get((key_table, key), ""),
              code(md_escape(shorten(cmd)))]
             for key, cmd in rows],
        ))
    for key_table, rows in by_table.items():  # any table not listed above
        parts.append(f"### Key table `{key_table}`")
        parts.append(table(
            ["Key", "Description", "Command"],
            [[code(md_escape(k)), "", code(md_escape(shorten(c)))] for k, c in rows],
        ))
    return "\n\n".join(parts)


# --------------------------------------------------------------------------
# herdr
# --------------------------------------------------------------------------

HERDR_CONF = REPO / "terminal" / "dot-config" / "herdr" / "config.toml"

# herdr ships a fixed binding set (no TPM-style plugins), so the post-prefix
# chords below are baked from `herdr --default-config` (v0.7.x) with this repo's
# config.toml choices folded in (e.g. the `=` split). CI has no herdr binary, so
# only the volatile bits — the prefix and the custom [[keys.command]] entries —
# are read live from config.toml.
HERDR_SECTIONS = [
    ("Tabs", [
        ("c", "New tab"),
        (",", "Rename tab"),
        ("n", "Next tab"),
        ("p", "Previous tab"),
        ("1-9", "Jump to tab 1–9"),
        ("Shift+x", "Close tab"),
    ]),
    ("Panes", [
        ("h j k l", "Focus pane ← ↓ ↑ →"),
        ("=", "Split side-by-side"),
        ("-", "Split stacked"),
        ("v", "Split side-by-side (alias)"),
        ("z", "Zoom / fullscreen pane"),
        ("r", "Resize mode (then arrows / hjkl)"),
        ("x", "Close pane"),
        ("Tab", "Cycle to next pane"),
        ("Shift+Tab", "Cycle to previous pane"),
        ("Shift+p", "Rename pane"),
    ]),
    ("Workspaces & sessions", [
        ("w", "Workspace picker"),
        ("Shift+n", "New workspace"),
        (".", "Rename workspace"),
        ("Shift+d", "Close workspace (confirm)"),
        ("Shift+g", "New git-worktree workspace"),
        ("g", "Goto / jump prompt"),
        ("q", "Detach session"),
    ]),
    ("Scrollback & misc", [
        ("e", "Edit / copy pane scrollback"),
        ("b", "Toggle sidebar"),
        ("Shift+o", "Open latest notification's target"),
        ("s", "Settings"),
        ("?", "Help / keybinding overlay"),
        ("Shift+r", "Reload config"),
    ]),
]

# Friendly descriptions for the custom & plugin commands, keyed by the command.
HERDR_CMD_DESC = {
    "exec $SHELL": "Scratch shell (disposable temp pane)",
    "pick-files-herdr": "Pick files (fd+fzf) → inject paths into the pane",
    "pick-files-yazi": "Pick files (yazi UI) → inject paths into the pane",
    "herdr-extract": "Grab URLs / paths / IDs from scrollback "
                     "(copy / open / insert)",
    "herdr-sessionize": "Fuzzy-open a project / notes dir as a workspace",
    "cloudmanic.herdr-plus.projects": "herdr-plus: project workspace templates",
    "cloudmanic.herdr-plus.quick-actions": "herdr-plus: quick-action launcher",
    "persiyanov.reviewr.toggle": "reviewr: toggle code-review sidebar",
    "vim-herdr-navigation.left": "vim-nav: focus split / pane left",
    "vim-herdr-navigation.down": "vim-nav: focus split / pane down",
    "vim-herdr-navigation.up": "vim-nav: focus split / pane up",
    "vim-herdr-navigation.right": "vim-nav: focus split / pane right",
}


def herdr_prefix_label(prefix: str) -> str:
    """`f12` -> `F12`, `ctrl+b` -> `Ctrl+b`."""
    out = []
    for tok in prefix.split("+"):
        if re.fullmatch(r"f\d+", tok):
            out.append(tok.upper())
        elif tok in ("ctrl", "alt", "shift", "cmd", "super", "meta"):
            out.append(tok.capitalize())
        else:
            out.append(tok)
    return "+".join(out)


def title_mods(chord: str) -> str:
    """Tidy a chord's tokens for display: `shift+x` -> `Shift+x`, `up` -> `Up`."""
    named = ("shift", "ctrl", "alt", "cmd", "super", "meta", "up", "down",
             "left", "right", "tab", "enter", "esc", "space", "home", "end",
             "pageup", "pagedown")
    return "+".join(t.capitalize() if t in named else t
                    for t in chord.split("+"))


def herdr_config() -> tuple[str, list[tuple[str, str]], list[tuple[str, str]]]:
    """(prefix_label, prefix_rows, direct_rows) read live from config.toml.

    prefix_rows: (post-prefix key, desc) for `prefix+…` commands.
    direct_rows: (chord label, desc) for non-prefix commands (e.g. `alt+h`).
    """
    import tomllib
    data = tomllib.loads(HERDR_CONF.read_text())
    keys = data.get("keys", {})
    prefix = herdr_prefix_label(keys.get("prefix", "ctrl+b"))
    prefix_rows, direct_rows = [], []
    for cmd in keys.get("command", []):
        chord = cmd.get("key", "")
        command = cmd.get("command", "")
        desc = HERDR_CMD_DESC.get(command, f"Run `{command}`")
        if chord.startswith("prefix+"):
            prefix_rows.append((title_mods(chord[len("prefix+"):]), desc))
        else:
            direct_rows.append((title_mods(chord), desc))
    return prefix, prefix_rows, direct_rows


def herdr_sections() -> tuple[str, list[dict]]:
    """(prefix_label, sections) — the cheatsheet view (keycaps are post-prefix)."""
    prefix, prefix_rows, direct_rows = herdr_config()
    sections = [{"title": title, "rows": [{"keys": k, "desc": d}
                                          for k, d in rows]}
                for title, rows in HERDR_SECTIONS]
    if prefix_rows:
        sections.append({"title": "Custom commands",
                         "rows": [{"keys": k, "desc": d} for k, d in prefix_rows]})
    if direct_rows:
        sections.append({"title": "Direct keys (no prefix)",
                         "rows": [{"keys": k, "desc": d} for k, d in direct_rows]})
    return prefix, sections


def gen_herdr() -> str:
    prefix, prefix_rows, direct_rows = herdr_config()
    parts = [f"The prefix is {code(prefix)} — press it, release, then the key; "
             f"every {code(prefix + ' X')} below means *prefix then X*."]
    for title, rows in HERDR_SECTIONS:
        parts.append(f"### {title}")
        parts.append(table(["Key", "Action"],
            [[code(f"{prefix} {md_escape(k)}"), md_escape(d)] for k, d in rows]))
    if prefix_rows:
        parts.append("### Custom commands")
        parts.append(table(["Key", "Action"],
            [[code(f"{prefix} {md_escape(k)}"), md_escape(d)]
             for k, d in prefix_rows]))
    if direct_rows:
        parts.append("### Direct keys (no prefix)")
        parts.append(table(["Key", "Action"],
            [[code(md_escape(k)), md_escape(d)] for k, d in direct_rows]))
    return "\n\n".join(parts)


# --------------------------------------------------------------------------
# niri
# --------------------------------------------------------------------------

NIRI_CATEGORIES = [
    # (title, predicate on (keys, action))
    ("Media, volume & brightness",
     lambda k, a: k.startswith("XF86") or "swayosd" in a or "playerctl" in a),
    ("Mouse warp (wl-kbptr)",
     lambda k, a: "wl-kbptr" in a),
    ("Apps & launchers",
     lambda k, a: a.startswith(("spawn", "spawn-sh"))),
    ("Screenshots & screencasting",
     lambda k, a: "screenshot" in a or "dynamic-cast" in a),
    ("Workspaces",
     lambda k, a: "workspace" in a),
    ("Monitors",
     lambda k, a: "monitor" in a and "power-off" not in a),
    ("Focus",
     lambda k, a: a.startswith("focus-")),
    ("Moving windows & columns",
     lambda k, a: a.startswith(("move-", "consume", "expel"))),
    ("Layout & sizing",
     lambda k, a: any(w in a for w in (
         "width", "height", "maximize", "fullscreen", "center", "floating",
         "tabbed", "switch-layout"))),
    ("Session & misc", lambda k, a: True),  # catch-all
]


def humanize(action: str) -> str:
    """Turn `focus-column-left` into `Focus column left`."""
    head = action.split(None, 1)[0]
    words = head.replace("-", " ").capitalize()
    arg = action[len(head):].replace('"', "").strip().strip(";")
    return f"{words} {arg}".strip()


def spawn_command(action: str) -> str:
    """Extract the command line from a `spawn "cmd" "arg" ...` action."""
    args = re.findall(r'"((?:[^"\\]|\\.)*)"', action)
    return " ".join(args) if args else action.split(None, 1)[1]


def parse_niri(path: Path):
    """Yield (keys, props, action) for every active bind in binds.kdl."""
    text = path.read_text()
    # Strip // comments (none of the configs use // inside strings).
    text = re.sub(r"\s*//.*$", "", text, flags=re.MULTILINE)
    # Drop the enclosing `binds { ... }` wrapper so it can't be glued onto
    # the first bind by the multi-line join below.
    text = re.sub(r"^binds\s*\{", "", text)
    # Multi-line blocks -> single line.
    text = re.sub(r"\{\s*\n\s*", "{ ", text)
    text = re.sub(r"\s*\n\s*\}", "; }", text)

    binds = []
    pattern = re.compile(
        r"^\s*(?P<keys>[A-Za-z0-9_]+(?:\+[A-Za-z0-9_]+)*)\s+"
        r"(?P<props>(?:[a-z-]+=(?:\"[^\"]*\"|\S+)\s+)*)"
        r"\{\s*(?P<action>[^{}]*?)\s*;?\s*\}",
        re.MULTILINE,
    )
    for m in pattern.finditer(text):
        if m.group("keys") == "binds":
            continue
        props = dict(re.findall(r"([a-z-]+)=(\"[^\"]*\"|\S+)", m.group("props")))
        props = {k: v.strip('"') for k, v in props.items()}
        action = " ".join(m.group("action").split())
        binds.append((m.group("keys"), props, action))
    return binds


NIRI_DISPLAY_ORDER = [
    "Apps & launchers", "Mouse warp (wl-kbptr)",
    "Media, volume & brightness", "Focus", "Moving windows & columns",
    "Workspaces", "Monitors", "Layout & sizing",
    "Screenshots & screencasting", "Session & misc",
]


def niri_rows() -> dict[str, list]:
    """Categorized plain-data rows: {category: [(keys, desc, is_cmd, notes)]}.

    `desc` is plain text (no markdown); `is_cmd` marks spawn command lines.
    """
    grouped: dict[str, list] = {title: [] for title, _ in NIRI_CATEGORIES}
    for keys, props, action in parse_niri(NIRI_BINDS):
        title = next(t for t, match in NIRI_CATEGORIES if match(keys, action))
        desc, is_cmd = props.get("hotkey-overlay-title", ""), False
        if desc in ("", "null"):
            if action.startswith(("spawn ", "spawn-sh ")):
                desc, is_cmd = shorten(spawn_command(action), 56), True
            else:
                desc = humanize(action)
        notes = []
        if props.get("allow-when-locked") == "true":
            notes.append("works on lock screen")
        if props.get("allow-inhibiting") == "false":
            notes.append("never inhibited")
        if "cooldown-ms" in props:
            notes.append(f"cooldown {props['cooldown-ms']}ms")
        if props.get("repeat") == "false":
            notes.append("no key-repeat")
        grouped[title].append((keys, desc, is_cmd, notes))
    return grouped


def gen_niri() -> str:
    grouped = niri_rows()
    parts = ["`Mod` is the **Super** key. Press `Mod+Shift+/` to open these "
             "docs as a local web app."]
    for title in NIRI_DISPLAY_ORDER:
        rows = grouped[title]
        if not rows:
            continue
        parts.append(f"### {title}")
        body = []
        for keys, desc, is_cmd, notes in rows:
            desc = "Run " + code(md_escape(desc)) if is_cmd else md_escape(desc)
            if notes:
                desc += f" *({', '.join(notes)})*"
            body.append([code(md_escape(keys)), desc])
        parts.append(table(["Keys", "Action"], body))
    return "\n\n".join(parts)


# --------------------------------------------------------------------------
# zellij
# --------------------------------------------------------------------------

# (mode-spec, section title) in display order. Tuples match the normalized
# shared_among/shared_except headers; anything unmatched lands in the final
# catch-all section.
ZELLIJ_SECTIONS = [
    ("tmux", "Tmux mode — Ctrl a"),
    (("shared_among", "normal", "locked"), "Always available (normal & locked)"),
    ("pane", "Pane mode — p"),
    ("tab", "Tab mode — t"),
    ("resize", "Resize mode — r"),
    ("move", "Move mode — m"),
    ("scroll", "Scroll mode — s"),
    (("shared_among", "scroll", "search"), "Scrolling keys (scroll & search)"),
    ("search", "Search options"),
    ("session", "Session mode — o"),
    ("locked", "Locked mode (default)"),
    (None, "Mode switches & misc"),  # catch-all for the shared_* leftovers
]

ZELLIJ_ACTION_DESC = {
    "ToggleTab": "Toggle last tab",
    "ToggleFocusFullscreen": "Fullscreen pane",
    "TogglePaneEmbedOrFloating": "Embed ⇄ float pane",
    "ToggleFloatingPanes": "Show/hide floating panes",
    "TogglePaneFrames": "Toggle pane frames",
    "ToggleActiveSyncTab": "Sync input to all panes in tab",
    "SwitchFocus": "Next pane",
    "NewTab": "New tab", "CloseTab": "Close tab", "CloseFocus": "Close pane",
    "GoToPreviousTab": "Previous tab", "GoToNextTab": "Next tab",
    "BreakPane": "Break pane into new tab",
    "BreakPaneLeft": "Break pane to tab left",
    "BreakPaneRight": "Break pane to tab right",
    "NextSwapLayout": "Next layout",
    "MovePaneBackwards": "Move pane backwards",
    "Detach": "Detach session", "Quit": "Quit zellij",
    "UndoRenameTab": "Cancel rename", "UndoRenamePane": "Cancel rename",
    "EditScrollback": "Edit scrollback in $EDITOR",
    "PageScrollDown": "Page down", "PageScrollUp": "Page up",
    "HalfPageScrollDown": "Half page down", "HalfPageScrollUp": "Half page up",
    "ScrollDown": "Line down", "ScrollUp": "Line up",
    "ScrollToBottom": "Jump to bottom",
}


def _kdl_block(text: str, start: int) -> tuple[str, int]:
    """Return (body, index-after-close) of the brace block opening at start."""
    depth, i = 1, start
    while depth:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
        i += 1
    return text[start:i - 1], i


def _split_actions(body: str) -> list[str]:
    parts, depth, cur = [], 0, ""
    for ch in body:
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
        if ch == ";" and depth == 0:
            parts.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        parts.append(cur.strip())
    return parts


def _zellij_action_desc(action: str) -> str | None:
    name = action.split(None, 1)[0]
    quoted = re.findall(r'"([^"]*)"', action)
    arg = quoted[0] if quoted else (action.split() + ["", ""])[1]
    if name in ("TabNameInput", "PaneNameInput", "SearchInput"):
        return None  # companion of a SwitchToMode, never standalone
    if name in ZELLIJ_ACTION_DESC:
        return ZELLIJ_ACTION_DESC[name]
    if name == "SwitchToMode":
        mode = arg.lower()
        if mode == "renametab":
            return "Rename tab"
        if mode == "renamepane":
            return "Rename pane"
        if mode == "entersearch":
            return "Search"
        return f"→ {mode} mode"
    if name == "NewPane":
        return f"New pane {arg.lower()}".strip()
    if name == "MoveFocus":
        return f"Focus pane {arg.lower()}"
    if name == "MoveFocusOrTab":
        return f"Focus pane/tab {arg.lower()}"
    if name == "MovePane":
        return f"Move pane {arg.lower()}".strip() if arg else "Move pane (next)"
    if name == "MoveTab":
        return f"Move tab {arg.lower()}"
    if name == "GoToTab":
        return f"Go to tab {arg}"
    if name == "Resize":
        words = arg.split()
        verb = "Grow" if words[0].lower() == "increase" else "Shrink"
        return f"{verb} {words[1].lower()}" if len(words) > 1 else verb
    if name == "LaunchOrFocusPlugin":
        return f"Open {arg}"
    if name == "Search":
        return "Next match" if arg.lower() == "down" else "Previous match"
    if name == "SearchToggleOption":
        opts = {"CaseSensitivity": "case-sensitivity", "WholeWord": "whole-word",
                "Wrap": "wrap"}
        return f"Toggle {opts.get(arg, arg)}"
    # fallback: CamelCase -> spaced words
    return re.sub(r"(?<!^)(?=[A-Z])", " ", name).capitalize() + (f" {arg}" if arg else "")


def parse_zellij(path: Path) -> list[tuple]:
    """Return [(mode_spec, [(key, desc), ...])] in file order.

    mode_spec is a mode name string or a normalized ("shared_among"|
    "shared_except", *modes) tuple.
    """
    text = re.sub(r"\s*//.*$", "", path.read_text(), flags=re.MULTILINE)
    m = re.search(r"^keybinds[^\n{]*\{", text, re.MULTILINE)
    keybinds, _ = _kdl_block(text, m.end())

    sections = []
    pos = 0
    header = re.compile(r'(\w+|shared_(?:among|except)(?:\s+"[^"]+")+)\s*\{')
    while (m := header.search(keybinds, pos)):
        body, pos = _kdl_block(keybinds, m.end())
        spec_words = m.group(1).split(None, 1)
        spec = (tuple([spec_words[0]] + re.findall(r'"([^"]+)"', m.group(1)))
                if spec_words[0].startswith("shared_") else spec_words[0])

        rows = []
        bpos = 0
        bind_re = re.compile(r'bind((?:\s*"[^"]+")+)\s*\{')
        while (b := bind_re.search(body, bpos)):
            action_body, bpos = _kdl_block(body, b.end())
            keys = re.findall(r'"([^"]+)"', b.group(1))
            actions = _split_actions(action_body)
            # a trailing "return to locked" is navigation noise, not the action
            if len(actions) > 1 and re.fullmatch(
                    r'SwitchToMode\s+"[Ll]ocked"', actions[-1].strip()):
                actions = actions[:-1]
            descs = [d for a in actions if (d := _zellij_action_desc(a))]
            desc = " · ".join(dict.fromkeys(descs))
            for key in keys:
                rows.append((key, desc))
        sections.append((spec, rows))
    return sections


def zellij_sections() -> list[dict]:
    """Display sections with alternative keys merged: [{title, rows}]."""
    parsed = parse_zellij(ZELLIJ_CONF)
    out, used = [], set()
    for spec, title in ZELLIJ_SECTIONS:
        rows = []
        if spec is None:  # catch-all: every section not claimed above
            for i, (s, r) in enumerate(parsed):
                if i not in used:
                    rows.extend(r)
        else:
            for i, (s, r) in enumerate(parsed):
                if s == spec:
                    rows.extend(r)
                    used.add(i)
        # collapse digit runs (GoToTab 1..9), then merge keys that trigger
        # the same action, preserving order
        rows = [(r["keys"], r["desc"]) for r in collapse_runs(
            [{"keys": k, "desc": d} for k, d in rows])]
        merged: dict[str, list] = {}
        for key, desc in rows:
            merged.setdefault(desc, []).append(key)
        if merged:
            out.append({"title": title, "rows": [
                {"keys": keys, "desc": desc} for desc, keys in merged.items()]})
    return out


def gen_zellij() -> str:
    parts = ["The default mode is **locked** (keys pass through to the shell). "
             "`Ctrl a` enters **tmux mode** — a tmux-style prefix — and "
             "`Ctrl g` toggles the regular zellij modes. Most actions return "
             "to locked automatically."]
    for section in zellij_sections():
        parts.append(f"### {section['title']}")
        parts.append(table(["Keys", "Action"], [
            [" ".join(code(md_escape(k)) for k in row["keys"]),
             md_escape(row["desc"])]
            for row in section["rows"]]))
    return "\n\n".join(parts)


# --------------------------------------------------------------------------
# fish shell
# --------------------------------------------------------------------------

# Top-level `bind` lines in these globs are the custom shell bindings.
# Indented binds (inside functions, e.g. the inactive thefuck example) and
# tool-injected bindings (atuin, documented statically in
# docs/shortcuts/shell.md) are not picked up.
FISH_GLOBS = ["fish/**/*.fish", "terminal/dot-config/fish/**/*.fish"]

FISH_BIND_DESC = {
    "nvims .": "Neovim config picker (default / nvim-lazy / nvim-full)",
    "yazi": "Open the yazi file manager",
    "backward-kill-word": "Delete the word left of the cursor",
    "_pick_files": "Insert file path(s) (fzf)",
    "_pick_dirs": "Insert a directory path (fzf)",
    "_pick_pacman": "Insert pacman package(s) (fzf)",
    "_pick_git_log": "Insert a commit SHA (fzf)",
    "_pick_git_status": "Insert changed file path(s) (fzf)",
    "_pick_procs": "Insert a PID (fzf)",
    "_pick_vars": "Insert a shell variable name (fzf)",
}


def fish_key(key: str) -> str:
    """Translate fish bind notation (\\ce, alt-f) into Ctrl+e / Alt+f."""
    if key.startswith("\\"):
        key = key.replace("\\c", " Ctrl+").replace("\\e", " Esc").strip()
        # "Ctrl+H" means ctrl-h — lowercase the letter for display
        key = re.sub(r"(Ctrl\+)([A-Z])(?![a-z])",
                     lambda m: m.group(1) + m.group(2).lower(), key)
        return key
    return "+".join(t.capitalize() if t in ("ctrl", "alt", "shift") else t
                    for t in key.split("-"))


def parse_fish(repo: Path = REPO) -> list[tuple[str, str, str]]:
    """Return (key_display, command, source_file) for top-level binds."""
    rows = []
    for pattern in FISH_GLOBS:
        for path in sorted(repo.glob(pattern)):
            for line in path.read_text().splitlines():
                m = re.match(r"^bind\s+(\S+)\s+(.+?)\s*(?:#.*)?$", line)
                if m:
                    key, cmd = m.group(1), m.group(2).strip().strip("'\"")
                    rows.append((fish_key(key), cmd,
                                 str(path.relative_to(repo))))
    return rows


def gen_fish() -> str:
    body = []
    for key, cmd, src in parse_fish(REPO):
        desc = FISH_BIND_DESC.get(cmd) or code(md_escape(cmd))
        body.append([code(md_escape(key)), desc, code(src)])
    return table(["Keys", "Action", "Defined in"], body)


# --------------------------------------------------------------------------
# justfile
# --------------------------------------------------------------------------

JUST_GROUP_ORDER = [
    (None, "Top-level"),
    ("install-essentials", "Install: essentials"),
    ("install-graphical", "Install: graphical stack"),
    ("install-other", "Install: optional extras"),
    ("stow", "Stow (symlink management)"),
    ("services", "Services"),
    ("niri-reload", "niri: reload helpers"),
    ("maintenance", "Maintenance"),
    ("docs", "Docs (this site)"),
]


def gen_just() -> str:
    dump = json.loads(subprocess.run(
        ["just", "--dump", "--dump-format", "json"],
        cwd=REPO, capture_output=True, text=True, check=True,
    ).stdout)

    grouped: dict[str | None, list] = {}
    for name, recipe in sorted(dump["recipes"].items()):
        attrs = recipe.get("attributes", [])
        groups = [a["group"] for a in attrs if isinstance(a, dict) and "group" in a]
        private = name.startswith("_") or "private" in attrs or recipe.get("private")
        if private or name == "default":
            continue
        deps = [d["recipe"] if isinstance(d, dict) else str(d)
                for d in recipe.get("dependencies", [])]
        grouped.setdefault(groups[0] if groups else None, []).append(
            (name, recipe.get("doc") or "", deps))

    known = [g for g, _ in JUST_GROUP_ORDER]
    extra = [(g, g) for g in sorted(k for k in grouped if k not in known and k)]
    parts = ["Run from the repo root. `just` with no arguments lists everything."]
    for group, title in JUST_GROUP_ORDER + extra:
        rows = grouped.get(group)
        if not rows:
            continue
        parts.append(f"### {title}")
        parts.append(table(
            ["Recipe", "Description", "Runs"],
            [[code(f"just {name}"), md_escape(doc),
              ", ".join(code(d) for d in deps)]
             for name, doc, deps in rows],
        ))
    return "\n\n".join(parts)


# --------------------------------------------------------------------------
# cheatsheet data (consumed by tools/cheatsheets/cheatsheet.typ)
# --------------------------------------------------------------------------

CHEAT_DATA = Path(__file__).resolve().parent / "cheatsheets" / "data.json"

# Plugin/default bindings aren't in tmux.conf — curated by hand, same as the
# tables in docs/shortcuts/tmux.md.
TMUX_CHEAT_EXTRAS = [
    ("Defaults worth remembering", [
        ("c", "New window (tab)"), ("1-9", "Go to window #"),
        ("!", "Promote pane to window"), (",", "Rename window"),
        ("w", "List windows"), ("f", "Find window"),
        ("&", "Kill window"), ("$", "Rename session"),
        ("d", "Detach"), ("z", "Zoom pane"),
    ]),
    ("pain-control — panes", [
        ("|", "Split horizontally"), ("-", "Split vertically"),
        ("h j k l", "Select pane ← ↓ ↑ →"),
        ("H J K L", "Resize pane ← ↓ ↑ →"),
        ("< >", "Swap window left / right"),
    ]),
    ("sessionist / sessionx", [
        ("g", "Switch session by name"), ("C", "Create named session"),
        ("X", "Kill session, stay attached"), ("S", "Last session"),
        ("@", "Promote pane to session"), ("o", "sessionx picker (zoxide)"),
    ]),
    ("copy & search plugins", [
        ("/", "copycat: regex search"), ("n N", "copycat: next / prev match"),
        ("y", "yank: copy to clipboard"), ("Tab", "extrakto: fuzzy pick text"),
        ("Space", "thumbs: hint-copy text"), ("o", "open selection (copy mode)"),
        ("Ctrl+o", "open selection in $EDITOR"),
    ]),
    ("resurrect / logging / tpm", [
        ("Ctrl+s", "Save session layout"), ("Ctrl+r", "Restore session layout"),
        ("P", "Start/stop logging"), ("Alt+p", "Log visible screen"),
        ("I", "Install plugins"), ("U", "Update plugins"),
        ("F", "tmux-fzf menu"),
    ]),
]


# Tool-injected and built-in fish bindings aren't bind lines in the repo —
# curated by hand, same as the static tables in docs/shortcuts/shell.md.
FISH_CHEAT_EXTRAS = [
    ("History — atuin", [
        ("Ctrl+r", "Search history (atuin)"),
        ("?", "Ask atuin AI (empty prompt)"),
    ]),
    ("thefuck — fix the last command", [
        ("Esc Esc Ctrl+f", "Correct the previous command"),
        ("fuck", "Same, typed out"),
    ]),
    ("fish built-ins worth remembering", [
        ("Alt+e", "Edit command line in $EDITOR"),
        ("Alt+s", "Prepend sudo / doas to (last) command"),
        ("Alt+b", "Previous dir (prevd) on empty line"),
        ("Alt+↑ Alt+↓", "History search by cursor token"),
        ("Alt+l", "List directory of cursor token"),
        ("Alt+p", "Append '&| less' (paginate)"),
        ("Alt+h F1", "Man page for cursor command"),
        ("Alt+w", "One-line description of command"),
        ("Ctrl+w", "Delete path component left"),
        ("Ctrl+z", "Undo edit"),
    ]),
    ("Handy abbreviations & functions", [
        ("mux mux1", "Open/attach tmux session 0 / 1"),
        ("nvims nv lvi", "Pick / light / lazy neovim config"),
        ("z zi", "zoxide jump / interactive"),
        ("b", "Back to previous dir + list"),
        ("mcd", "mkdir -p + cd"),
        ("cpv", "Copy with progress (rsync)"),
    ]),
]


# Neovim plugin keymaps live in lua, not a parseable config — curated by hand
# from the tables in docs/neovim-plugins.md (nvim-light profile). leader = Space
# (shown as "Spc"); localleader = "\".
NEOVIM_CHEAT = [
    ("Find & search — fff.nvim", [
        ("Spc sf", "Find files"),
        ("Spc sg", "Live grep"),
        ("Spc sz", "Live grep — fuzzy + plain"),
        ("Spc sw", "Grep word under cursor"),
        ("Spc sr", "Project search & replace (grug-far)"),
    ]),
    ("Move — leap.nvim", [
        ("s", "Leap forward — then 2 chars"),
        ("S", "Leap backward — then 2 chars"),
        ("gs", "Leap across windows — then 2 chars"),
    ]),
    ("Yank ring — yanky.nvim", [
        ("Spc p", "Yank-history picker"),
        ("[y ]y", "Cycle ring after a paste"),
        ("gp gP", "Put after / before selection"),
        ("]p [p", "Put with the current indent"),
    ]),
    ("Surround — mini.surround (gz)", [
        ("gza", "Add — then textobject + char"),
        ("gzd", "Delete surrounding"),
        ("gzr", "Replace surrounding"),
        ("gzf gzF", "Find next / prev surrounding"),
        ("gzh", "Highlight surrounding"),
        ('gzaiw"', "Quote a word (example)"),
    ]),
    ("Format & LSP", [
        ("Spc cf", "Format buffer (conform)"),
        ("Spc cF", "Format injected languages"),
        ("Spc cm", "Open Mason"),
        ("Spc cr", "LSP rename symbol"),
        ("Spc ca", "LSP code actions"),
    ]),
    ("Claude — claudecode.nvim", [
        ("Spc ac", "Toggle Claude terminal"),
        ("Spc af", "Focus Claude"),
        ("Spc ar Spc aC", "Resume / continue session"),
        ("Spc ab", "Add current buffer to context"),
        ("Spc as", "Send selection / add file"),
        ("Spc aa Spc ad", "Accept / deny diff"),
    ]),
    ("Git & utility — snacks.nvim", [
        ("Spc gg", "Lazygit (root) — gG for cwd"),
        ("Spc gb", "Git blame line"),
        ("Spc gB", "Open line in browser"),
        ("Spc . Spc S", "Toggle / select scratch buffer"),
        ("Spc n Spc un", "Notifications: history / dismiss all"),
        ("Ctrl+/", "Toggle terminal"),
        ("Spc cR", "Rename file (updates imports)"),
    ]),
    ("Notes — obsidian / dotmd", [
        (":Obsidian today", "Daily note (tomorrow / yesterday)"),
        (":Obsidian new", "New note"),
        (":Obsidian search", "Grep / quick-switch notes"),
        (":Obsidian backlinks", "Find references / tags"),
        ("Spc zc Spc zt", "dotmd note / today's todo"),
        ("Spc zj Spc zi", "dotmd journal / inbox"),
        ("Spc zs", "dotmd search notes"),
    ]),
    ("Sessions, numbers & prose", [
        ("Spc qs", "Restore this dir's session"),
        ("Spc ql", "Restore the last session"),
        ("Spc qS Spc qd", "Pick / stop session"),
        ("Ctrl+a Ctrl+x", "Increment / decrement (dial)"),
        ("Spc um", "Toggle markdown render"),
        ("Spc cp", "Browser markdown preview"),
    ]),
    ("Tips & combos", [
        ("Spc", "…then wait — which-key shows follow-ups"),
        ("ciw cif", "mini.ai: change inside word / function"),
        ("daa vai", "mini.ai: delete an arg / select indent"),
        ("g Ctrl+a", "Visual: make a column count 1, 2, 3…"),
        ("gzaiwt", "Wrap word in an HTML tag (then type it)"),
        ("gzaiwf", "Wrap word in a function call"),
        (":PencilToggle", "Soft-wrap prose mode"),
    ]),
    ("LaTeX — vimtex (localleader \\)", [
        ("\\ll", "Start / stop compilation"),
        ("\\lv", "Forward-search to PDF viewer"),
        ("\\lt \\le", "Table of contents / errors"),
        ("\\lc", "Clean aux files"),
        ("Spc K", "Package docs under cursor"),
    ]),
]


# Display-only abbreviations for the cheatsheet keycaps (the markdown pages
# keep the real XKB names).
NIRI_KEY_SHORT = {
    "WheelScrollDown": "Wheel↓", "WheelScrollUp": "Wheel↑",
    "WheelScrollLeft": "Wheel←", "WheelScrollRight": "Wheel→",
    "Page_Down": "PgDn", "Page_Up": "PgUp",
    "BracketLeft": "[", "BracketRight": "]",
    "Comma": ",", "Period": ".", "Minus": "-", "Equal": "=",
    "Slash": "/", "Escape": "Esc", "Delete": "Del",
    "XF86AudioRaiseVolume": "Vol↑", "XF86AudioLowerVolume": "Vol↓",
    "XF86AudioMute": "Mute", "XF86AudioMicMute": "MicMute",
    "XF86MonBrightnessUp": "Brt↑", "XF86MonBrightnessDown": "Brt↓",
    "XF86AudioNext": "Next", "XF86AudioPause": "Pause",
    "XF86AudioPlay": "Play", "XF86AudioPrev": "Prev",
}

# Friendlier cheatsheet descriptions for binds whose generated description is
# a raw command line, keyed by the original key combo.
CHEAT_NIRI_DESC = {
    "XF86AudioRaiseVolume": "Volume up (OSD)",
    "XF86AudioLowerVolume": "Volume down (OSD)",
    "XF86AudioMute": "Toggle mute (OSD)",
    "XF86AudioMicMute": "Toggle mic mute (OSD)",
    "XF86MonBrightnessUp": "Brightness up (OSD)",
    "XF86MonBrightnessDown": "Brightness down (OSD)",
    "XF86AudioNext": "Next track",
    "XF86AudioPause": "Play / pause",
    "XF86AudioPlay": "Play / pause",
    "XF86AudioPrev": "Previous track",
}


def shorten_keys(keys: str) -> str:
    return "+".join(NIRI_KEY_SHORT.get(t, t) for t in keys.split("+"))


# zellij key tokens appear in mixed case ("left", "Left", "PageDown").
ZELLIJ_KEY_SHORT = {
    "left": "←", "down": "↓", "up": "↑", "right": "→",
    "pagedown": "PgDn", "pageup": "PgUp", "esc": "Esc", "enter": "Enter",
    "tab": "Tab", "space": "Space",
}


def zellij_cheat_keys(key: str) -> str:
    # a literal "+" key would read as a separator after joining — the
    # template's keycap() renders "{plus}" back as "+"
    return "+".join("{plus}" if t == "+" else ZELLIJ_KEY_SHORT.get(t.lower(), t)
                    for t in key.split())


def collapse_runs(rows: list[dict]) -> list[dict]:
    """Merge runs of rows that differ only by a trailing digit (Mod+1..Mod+9)."""
    out, i = [], 0
    while i < len(rows):
        row, run = rows[i], [rows[i]]
        m = re.fullmatch(r"(.*?)(\d)", row["keys"])
        if m and not row.get("cmd"):
            base, start = m.group(1), int(m.group(2))
            for nxt in rows[i + 1:]:
                m2 = re.fullmatch(re.escape(base) + r"(\d)", nxt["keys"])
                if (m2 and int(m2.group(1)) == start + len(run)
                        and nxt["desc"].replace(m2.group(1), "#")
                        == row["desc"].replace(m.group(2), "#")):
                    run.append(nxt)
                else:
                    break
        if len(run) >= 3:
            lo, hi = row["keys"][-1], run[-1]["keys"][-1]
            out.append({"keys": f"{row['keys'][:-1]}{lo}…{hi}",
                        "desc": re.sub(rf"{lo}$", f"{lo}…{hi}", row["desc"])})
        else:
            out.extend(run)
        i += len(run)
    return out


def strip_md(text: str) -> str:
    return text.replace("**", "").replace("`", "")


def cheat_data() -> dict:
    prefix, binds = parse_tmux(TMUX_CONF)
    by_table: dict[str, list] = {}
    for key_table, key, command in binds:
        by_table.setdefault(key_table, []).append((key, command))

    tmux_sections = []
    for key_table in ("prefix", "root", "copy-mode-vi", "off"):
        rows = []
        for key, cmd in by_table.get(key_table, []):
            desc = TMUX_DESCRIPTIONS.get((key_table, key))
            rows.append(
                {"keys": key, "desc": strip_md(desc)} if desc else
                {"keys": key, "desc": shorten(cmd, 48), "cmd": True})
        title, _ = TMUX_TABLE_TITLES[key_table]
        tmux_sections.append({"title": title, "rows": rows})
    tmux_sections[1:1] = [
        {"title": title, "rows": [{"keys": k, "desc": d} for k, d in rows]}
        for title, rows in TMUX_CHEAT_EXTRAS
    ]

    grouped = niri_rows()
    niri_sections = []
    for title in NIRI_DISPLAY_ORDER:
        rows = []
        for keys, desc, is_cmd, notes in grouped[title]:
            if keys in CHEAT_NIRI_DESC:
                desc, is_cmd, notes = CHEAT_NIRI_DESC[keys], False, []
            if notes:
                desc += f" ({', '.join(notes)})"
            rows.append({"keys": shorten_keys(keys), "desc": desc,
                         **({"cmd": True} if is_cmd else {})})
        if rows:
            niri_sections.append({"title": title, "rows": collapse_runs(rows)})

    zellij_cheat = []
    for s in zellij_sections():
        rows = []
        for row in s["rows"]:
            keys = [zellij_cheat_keys(k) for k in row["keys"]]
            # >3 alternative keys would squeeze the description column —
            # continue on extra rows instead
            for i in range(0, len(keys), 3):
                rows.append({"keys": " ".join(keys[i:i + 3]),
                             "desc": row["desc"] if i == 0 else "…"})
        zellij_cheat.append({"title": s["title"], "rows": rows})

    shell_sections = [{"title": "Custom bindings", "rows": [
        {"keys": key, "desc": FISH_BIND_DESC.get(cmd, cmd),
         **({} if cmd in FISH_BIND_DESC else {"cmd": True})}
        for key, cmd, _ in parse_fish(REPO)]}]
    shell_sections += [
        {"title": title, "rows": [{"keys": k, "desc": d} for k, d in rows]}
        for title, rows in FISH_CHEAT_EXTRAS
    ]

    herdr_prefix, herdr_cheat = herdr_sections()

    return {
        "tmux": {
            "title": "tmux",
            "prefix": prefix,
            "subtitle": "open with mux / mux1",
            "cols": 2,
            "size": 8.2,
            "split_keys": False,
            "sections": tmux_sections,
        },
        "herdr": {
            "title": "herdr",
            "prefix": herdr_prefix,
            "subtitle": "agent multiplexer",
            "cols": 2,
            "size": 8.6,
            "split_keys": False,
            "sections": herdr_cheat,
        },
        "zellij": {
            "title": "zellij",
            "subtitle": "default: locked · Ctrl+a → tmux mode · Ctrl+g → modes",
            "cols": 4,
            "size": 7.4,
            "split_keys": True,
            "sections": zellij_cheat,
        },
        "shell": {
            "title": "shell",
            "subtitle": "fish · atuin · fzf · zoxide",
            "cols": 2,
            "size": 9.6,
            "split_keys": True,
            "sections": shell_sections,
        },
        "neovim": {
            "title": "neovim",
            "subtitle": "LazyVim · leader = Space (Spc) · profile nvim-light",
            "cols": 3,
            "size": 7.6,
            "split_keys": False,
            "sections": [
                {"title": title,
                 "rows": [{"keys": k, "desc": d} for k, d in rows]}
                for title, rows in NEOVIM_CHEAT
            ],
        },
        "niri": {
            "title": "niri",
            "subtitle": "Mod = Super · Mod+Shift+/ opens the docs web app",
            "cols": 4,
            "size": 7.0,
            "split_keys": True,
            "sections": niri_sections,
        },
    }


# --------------------------------------------------------------------------
# marker replacement
# --------------------------------------------------------------------------

TARGETS = {
    DOCS / "shortcuts" / "tmux.md": {"tmux-binds": gen_tmux},
    DOCS / "shortcuts" / "herdr.md": {"herdr-binds": gen_herdr},
    DOCS / "shortcuts" / "zellij.md": {"zellij-binds": gen_zellij},
    DOCS / "shortcuts" / "shell.md": {"fish-binds": gen_fish},
    DOCS / "shortcuts" / "niri.md": {"niri-binds": gen_niri},
    DOCS / "justfile.md": {"just-recipes": gen_just},
}


def replace_block(text: str, name: str, content: str, path: Path) -> str:
    begin, end = f"<!-- gen:{name} -->", f"<!-- /gen:{name} -->"
    if begin not in text or end not in text:
        sys.exit(f"error: markers for '{name}' not found in {path}")
    pattern = re.compile(re.escape(begin) + r".*?" + re.escape(end), re.DOTALL)
    block = f"{begin}\n{content}\n{end}"
    return pattern.sub(lambda _: block, text)


def main() -> None:
    changed = 0
    for path, blocks in TARGETS.items():
        text = original = path.read_text()
        for name, generator in blocks.items():
            text = replace_block(text, name, generator(), path)
        if text != original:
            path.write_text(text)
            changed += 1
            print(f"updated  {path.relative_to(REPO)}")
        else:
            print(f"current  {path.relative_to(REPO)}")
    CHEAT_DATA.parent.mkdir(exist_ok=True)
    CHEAT_DATA.write_text(json.dumps(cheat_data(), indent=1) + "\n")
    print(f"written  {CHEAT_DATA.relative_to(REPO)}")
    print(f"done ({changed} file(s) changed)")


if __name__ == "__main__":
    main()
