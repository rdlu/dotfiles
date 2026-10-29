/* Tooltips for the Sofle keymap grids (layouts/_partials/sofle/layer.html).
   Each key carries its tooltip as a visually hidden .tip; on hover or focus
   this copies it into one floating box above the key, kept inside the
   viewport. Escape hides it. Without JS the hidden text still reaches
   screen readers. */

(function () {
  var keys = document.querySelectorAll(".sf-k");
  if (!keys.length) return;

  var pop = document.createElement("div");
  pop.className = "sf-pop";
  pop.setAttribute("aria-hidden", "true");
  document.body.appendChild(pop);
  var current = null;

  function show(key) {
    var tip = key.querySelector(".tip");
    if (!tip) return;
    current = key;
    pop.innerHTML = tip.innerHTML;
    pop.style.setProperty("--lc", getComputedStyle(key).getPropertyValue("--lc"));
    pop.classList.add("on");
    var r = key.getBoundingClientRect();
    var w = pop.offsetWidth, h = pop.offsetHeight, gap = 8;
    var left = Math.min(Math.max(8, r.left + r.width / 2 - w / 2),
                        window.innerWidth - w - 8);
    var top = r.top - h - gap;
    if (top < 8) top = r.bottom + gap;
    pop.style.left = left + "px";
    pop.style.top = top + "px";
  }

  function hide(key) {
    if (key && key !== current) return;
    current = null;
    pop.classList.remove("on");
  }

  keys.forEach(function (key) {
    key.addEventListener("mouseenter", function () { show(key); });
    key.addEventListener("mouseleave", function () { hide(key); });
    key.addEventListener("focus", function () { show(key); });
    key.addEventListener("blur", function () { hide(key); });
  });
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape") hide();
  });
  window.addEventListener("scroll", function () { hide(); }, { passive: true });
})();
