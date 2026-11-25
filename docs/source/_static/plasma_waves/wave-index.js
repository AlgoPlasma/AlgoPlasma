/* Honour a lesson's language when returning to the directory, including file previews. */
(() => {
  'use strict';
  const language = new URLSearchParams(location.search).get('lang');
  if (language !== 'zh' && language !== 'en') return;
  try { localStorage.setItem('ap-doc-language', language); } catch (_) { /* Optional storage. */ }
  // The shared Sphinx language switch initializes on DOMContentLoaded.
  window.addEventListener('load', () => {
    if (document.documentElement.dataset.apLang !== language) {
      document.querySelector(`[data-ap-set-lang="${language}"]`)?.click();
    }
  }, { once: true });
})();

/* Plasma-wave contribution history (Git author dates; edit time includes timezone).
 * 2026-11-18 08:16 +08:00 | Yinjian Zhao | git 45f247468130
 * 2026-11-19 16:28 +08:00 | Yinjian Zhao | edit (Codex-assisted)
 */
