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
