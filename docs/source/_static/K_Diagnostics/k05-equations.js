/* K05 contribution history (Git author dates; edit times include timezone).
 * 2026-10-23 16:13 +08:00 | Yinjian Zhao | git 482110a190d6
 * 2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)
 */

/* Equation links reveal their language panel and any containing disclosures. */
(() => {
  "use strict";
  function revealEquation() {
    let id;
    try { id = decodeURIComponent(location.hash.slice(1)); } catch (_) { return; }
    if (!id.startsWith("equation-k05-")) return;
    const target = document.getElementById(id);
    if (!target) return;
    const panel = target.closest(".ap-lang");
    if (panel && getComputedStyle(panel).display === "none") {
      const lang = panel.classList.contains("ap-lang-zh") ? "zh" : "en";
      document.querySelector(`[data-ap-set-lang="${lang}"]`)?.click();
    }
    for (let p = target.parentElement; p; p = p.parentElement) {
      if (p.tagName === "DETAILS") p.open = true;
    }
    requestAnimationFrame(() => target.scrollIntoView({block: "center"}));
  }
  window.addEventListener("load", revealEquation);
  window.addEventListener("hashchange", revealEquation);
  document.addEventListener("click", event => {
    if (event.target.closest(".k05-eq-ref")) setTimeout(revealEquation, 0);
  });
})();
