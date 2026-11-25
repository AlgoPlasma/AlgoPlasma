/* Reveal B04 reference targets without changing other documentation pages. */
(function () {
  "use strict";

  document.addEventListener("DOMContentLoaded", function () {
    if (!document.querySelector(".ap-b04-doc")) return;

    function revealFragment(hash) {
      if (!hash || hash === "#") return;
      var id;
      try {
        id = decodeURIComponent(hash.slice(1));
      } catch (_) {
        return;
      }
      var target = document.getElementById(id);
      if (!target || !target.closest(".ap-b04-doc")) return;

      var language = target.closest(".ap-lang-en") ? "en" : "zh";
      if (document.documentElement.getAttribute("data-ap-lang") !== language) {
        var button = document.querySelector('[data-ap-set-lang="' + language + '"]');
        if (button) button.click();
      }
      var details = target.closest("details.ap-b04-api");
      if (details) details.open = true;
      requestAnimationFrame(function () {
        target.scrollIntoView({ block: "start" });
      });
    }

    window.addEventListener("hashchange", function () {
      revealFragment(window.location.hash);
    });
    // A repeated click on the same fragment does not fire hashchange.
    document.addEventListener("click", function (event) {
      if (event.defaultPrevented || event.button !== 0 ||
          event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
      var link = event.target.closest("a[href]");
      if (!link || link.hasAttribute("download") ||
          (link.target && link.target !== "_self")) return;
      var url = new URL(link.href, window.location.href);
      if (url.origin === location.origin && url.pathname === location.pathname &&
          url.search === location.search && url.hash === location.hash) {
        revealFragment(url.hash);
      }
    });
    revealFragment(window.location.hash);
  });
})();
