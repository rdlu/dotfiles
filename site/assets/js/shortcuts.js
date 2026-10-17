/* Keycap rendering + per-page accents for the shortcut tables.
   HTML-only polish: the markdown keeps plain `code` spans so the
   pandoc/typst PDF pipeline is unaffected. Loaded with `defer` by
   site/layouts/_partials/custom/head-end.html. */

(function () {
  // Pages with their own accent color (matches the PDF cards on the home
  // page); anything else falls back to the default accent in custom.css.
  var PAGES = ["tmux", "zellij", "niri", "shell", "justfile", "herdr"];

  function pageKey() {
    var path = window.location.pathname;
    for (var i = 0; i < PAGES.length; i++)
      if (path.indexOf(PAGES[i]) !== -1) return PAGES[i];
    return "default";
  }

  // "Mod+Shift+Slash" / "Ctrl+Alt+f" — plus-joined chord we can split.
  // Things like "C-a", "1…6", "|", "Alt++" stay as a single keycap.
  var CHORD = /^[A-Za-z0-9↑↓←→]+(\+[^+\s]+)+$/;

  function kbd(text) {
    var el = document.createElement("kbd");
    el.textContent = text;
    return el;
  }

  function keycapify(code) {
    var span = document.createElement("span");
    span.className = "keyseq";
    // the generator escapes "|" for the markdown table; undo it here
    var text = code.textContent.replace(/\\\|/g, "|");
    var chunks = text.split(" ").filter(Boolean);
    chunks.forEach(function (chunk, i) {
      if (i > 0) span.append(" ");
      if (CHORD.test(chunk)) {
        chunk.split("+").forEach(function (part, j) {
          if (j > 0) span.append(" + ");
          span.append(kbd(part));
        });
      } else {
        span.append(kbd(chunk));
      }
    });
    code.replaceWith(span);
  }

  function init() {
    document.body.dataset.page = pageKey();
    document.querySelectorAll(".content table").forEach(function (table) {
      var th = table.querySelector("thead th:first-child");
      if (!th) return;
      var head = th.textContent.trim().toLowerCase();
      if (head !== "key" && head !== "keys") return;
      // a data attribute, which custom.css styles
      table.setAttribute("data-shortcuts", "");
      table.querySelectorAll("tbody td:first-child code").forEach(keycapify);
    });
  }

  init();
})();
