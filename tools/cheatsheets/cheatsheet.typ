// Landscape keyboard-shortcut cheatsheet, themed with Catppuccin.
// Data comes from data.json (written by tools/gen-docs.py).
//
// Compile (see `just docs-cheatsheets`):
//   typst compile --input sheet=tmux --input theme=latte \
//     tools/cheatsheets/cheatsheet.typ docs/pdf/tmux-cheatsheet.pdf

#let sheet-id = sys.inputs.at("sheet", default: "tmux")
#let theme-id = sys.inputs.at("theme", default: "latte")
#let data = json("data.json").at(sheet-id)

// Catppuccin Latte (light, print-friendly) and Mocha (dark, screens).
#let themes = (
  latte: (
    bg: rgb("#eff1f5"), text: rgb("#4c4f69"), subtext: rgb("#6c6f85"),
    key-bg: rgb("#dce0e8"), key-stroke: rgb("#9ca0b0"), key-text: rgb("#4c4f69"),
    card: rgb("#e6e9ef"), title-text: rgb("#eff1f5"),
    accents: (rgb("#8839ef"), rgb("#1e66f5"), rgb("#40a02b"), rgb("#fe640b"),
              rgb("#d20f39"), rgb("#179299"), rgb("#df8e1d"), rgb("#ea76cb")),
  ),
  mocha: (
    bg: rgb("#1e1e2e"), text: rgb("#cdd6f4"), subtext: rgb("#a6adc8"),
    key-bg: rgb("#313244"), key-stroke: rgb("#585b70"), key-text: rgb("#cdd6f4"),
    card: rgb("#181825"), title-text: rgb("#11111b"),
    accents: (rgb("#cba6f7"), rgb("#89b4fa"), rgb("#a6e3a1"), rgb("#fab387"),
              rgb("#f38ba8"), rgb("#94e2d5"), rgb("#f9e2af"), rgb("#f5c2e7")),
  ),
)
#let pal = themes.at(theme-id)
#let base = float(data.at("size", default: 7.2)) * 1pt

#let keycap(k) = box(
  fill: pal.key-bg,
  stroke: 0.6pt + pal.key-stroke,
  radius: 2.5pt,
  inset: (x: 2.6pt, y: 0pt),
  outset: (y: 1.7pt),
  baseline: 0pt,
  // typst reads this nerd font's family as "JetBrainsMono NF" (not the
  // fontconfig alias "JetBrainsMono Nerd Font"); fall back to plain JetBrains
  // Mono where only that is installed (e.g. CI). See `just docs-cheatsheets`.
  text(font: ("JetBrainsMono NF", "JetBrains Mono"), size: base * 0.89, fill: pal.key-text, weight: "medium",
    k.replace("{plus}", "+")),  // literal "+" keys arrive escaped
)

// Sheets driven by a prefix key (tmux, herdr) spell out "press <prefix> first"
// in the header so the bare keycaps below aren't mistaken for direct chords.
#let prefix-note = if "prefix" in data {
  text(size: 7.5pt, fill: pal.text)[Press #keycap(data.prefix) first, then: ]
}

#set page(
  paper: "a4",
  flipped: true,
  margin: (x: 0.9cm, top: 1.3cm, bottom: 0.9cm),
  fill: pal.bg,
  columns: int(data.at("cols", default: 3)),
  header: grid(
    columns: (auto, 1fr),
    align: (left + bottom, right + bottom),
    text(size: 14pt, weight: "black", fill: pal.text,
      data.title + h(4pt) + text(size: 9pt, weight: "regular",
        fill: pal.subtext, "cheatsheet")),
    box[#prefix-note#text(size: 7.5pt, fill: pal.subtext, data.subtitle)],
  ),
  footer: align(center, text(size: 6.5pt, fill: pal.subtext,
    [rdlu/dotfiles · generated #datetime.today().display() · page #context counter(page).display("1 / 1", both: true)])),
)
#set text(font: "Inter", size: base, fill: pal.text)
#set par(leading: 0.4em)
#set columns(gutter: 12pt)

// Space-separated alternatives ("h j k l") each get their own cap; on
// split_keys sheets each alternative is further split into per-key caps
// joined by "+" ("Mod+T").
#let keyspec(s) = s.split(" ").map(alt => {
  if data.at("split_keys", default: false) {
    alt.split("+").map(keycap).join(
      h(1pt) + text(fill: pal.subtext, size: base * 0.76, baseline: -0.5pt, sym.plus) + h(1pt))
  } else {
    keycap(alt)
  }
}).join(h(2pt))

#let desc(r) = if r.at("cmd", default: false) {
  text(font: ("JetBrainsMono NF", "JetBrains Mono"), size: base * 0.86, fill: pal.subtext, r.desc)
} else {
  r.desc
}

// Tall sections may break across columns; short ones move as one card so a
// title bar can never be orphaned at the bottom of a column.
#let section(i, s) = block(
  width: 100%,
  below: 7pt,
  breakable: s.rows.len() > 16,
  {
    block(
      fill: pal.accents.at(calc.rem(i, pal.accents.len())),
      width: 100%,
      radius: (top: 3pt),
      inset: (x: 5pt, y: 3.2pt),
      below: 0pt,
      text(size: base * 1.06, weight: "bold", fill: pal.title-text, upper(s.title)),
    )
    block(
      fill: pal.card,
      width: 100%,
      radius: (bottom: 3pt),
      inset: (x: 5pt, y: 4.5pt),
      above: 0pt,
      grid(
        columns: (auto, 1fr),
        column-gutter: 6pt,
        row-gutter: base * 0.61,
        align: (left + horizon, left + horizon),
        ..s.rows.map(r => (keyspec(r.keys), desc(r))).flatten(),
      ),
    )
  },
)

#for (i, s) in data.sections.enumerate() {
  section(i, s)
}
