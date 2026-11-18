/* K05 contribution history (Git author dates; edit times include timezone).
 * 2026-10-27 16:16 +08:00 | Yinjian Zhao | git 1782aebfbe9c
 * 2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)
 */

/* Preserve bookmarks from the original K05 article entry page. */
(() => {
  "use strict";
  const routes = {
  "k05-wave-growth-and-coupling": "K05_wave_growth.html",
  "k05-wave-overview-en": "K05_wave_growth.html",
  "equation-k05-real-wave-en": "K05_wave_growth.html",
  "equation-k05-gaussian-height-en": "K05_wave_growth.html",
  "equation-k05-complex-wave-en": "K05_wave_growth.html",
  "equation-k05-linear-envelope-en": "K05_wave_growth.html",
  "equation-k05-chain-rule-en": "K05_wave_growth.html",
  "equation-k05-mode-derivative-en": "K05_wave_growth.html",
  "equation-k05-quadratic-envelope-en": "K05_wave_growth.html",
  "equation-k05-phase-product-en": "K05_wave_growth.html",
  "equation-k05-matched-pairs-en": "K05_wave_growth.html",
  "equation-k05-ordered-pair-sum-en": "K05_wave_growth.html",
  "equation-k05-product-rule-en": "K05_wave_growth.html",
  "equation-k05-phase-derivatives-en": "K05_wave_growth.html",
  "equation-k05-matched-phase-product-en": "K05_wave_growth.html",
  "equation-k05-full-wave-equation-1d-en": "K05_wave_growth.html",
  "equation-k05-envelope-substitution-en": "K05_wave_growth.html",
  "equation-k05-full-wave-equation-en": "K05_wave_growth.html",
  "equation-k05-dielectric-expansion-en": "K05_envelope_coefficients.html",
  "equation-k05-response-coefficients-en": "K05_envelope_coefficients.html",
  "k05-reference-1-en": "K05_wave_growth.html",
  "k05-wave-overview-zh": "K05_wave_growth.html",
  "equation-k05-real-wave-zh": "K05_wave_growth.html",
  "equation-k05-gaussian-height-zh": "K05_wave_growth.html",
  "equation-k05-complex-wave-zh": "K05_wave_growth.html",
  "equation-k05-linear-envelope-zh": "K05_wave_growth.html",
  "equation-k05-chain-rule-zh": "K05_wave_growth.html",
  "equation-k05-mode-derivative-zh": "K05_wave_growth.html",
  "equation-k05-quadratic-envelope-zh": "K05_wave_growth.html",
  "equation-k05-phase-product-zh": "K05_wave_growth.html",
  "equation-k05-matched-pairs-zh": "K05_wave_growth.html",
  "equation-k05-ordered-pair-sum-zh": "K05_wave_growth.html",
  "equation-k05-product-rule-zh": "K05_wave_growth.html",
  "equation-k05-phase-derivatives-zh": "K05_wave_growth.html",
  "equation-k05-matched-phase-product-zh": "K05_wave_growth.html",
  "equation-k05-full-wave-equation-1d-zh": "K05_wave_growth.html",
  "equation-k05-envelope-substitution-zh": "K05_wave_growth.html",
  "equation-k05-full-wave-equation-zh": "K05_wave_growth.html",
  "equation-k05-dielectric-expansion-zh": "K05_envelope_coefficients.html",
  "equation-k05-response-coefficients-zh": "K05_envelope_coefficients.html",
  "k05-reference-1-zh": "K05_wave_growth.html"
};
  function followLegacyFragment() {
    const fragment = window.location.hash.slice(1);
    if (Object.prototype.hasOwnProperty.call(routes, fragment)) {
      window.location.replace(routes[fragment] + "#" + fragment);
    }
  }
  followLegacyFragment();
  window.addEventListener("hashchange", followLegacyFragment);
})();
