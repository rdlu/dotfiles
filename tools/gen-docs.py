#!/usr/bin/env python3
"""Regenerate the generated sections of the markdown docs from the live configs.

Reads:
  - terminal/dot-tmux.conf                  -> tmux key bindings
  - niri/dot-config/niri/binds.kdl          -> niri key bindings
  - `just --dump --dump-format json`        -> justfile recipe reference

Writes (in place, between markers):
  - docs/shortcuts/tmux.md     <!-- gen:tmux-binds -->
  - docs/shortcuts/niri.md     <!-- gen:niri-binds -->
  - docs/justfile.md           <!-- gen:just-recipes -->

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
    ("prefix", "C-f"): "Popup fuzzy **file picker** (`pick-files`)",
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
    parts = ["`Mod` is the **Super** key. Press `Mod+Shift+/` for the built-in "
             "hotkey overlay."]
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

    return {
        "tmux": {
            "title": "tmux",
            "subtitle": f"prefix {prefix} (Ctrl+a) · open with mux / mux1",
            "cols": 2,
            "size": 8.2,
            "split_keys": False,
            "sections": tmux_sections,
        },
        "niri": {
            "title": "niri",
            "subtitle": "Mod = Super · Mod+Shift+/ shows the hotkey overlay",
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
