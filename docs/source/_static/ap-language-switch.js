(function () {
  "use strict";

  var storageKey = "ap-doc-language";

  function readStoredLanguage() {
    try {
      return window.localStorage.getItem(storageKey);
    } catch (error) {
      return null;
    }
  }

  function storeLanguage(language) {
    try {
      window.localStorage.setItem(storageKey, language);
    } catch (error) {
      // file:// pages can disable localStorage in some browsers.
    }
  }

  function targetForLink(link) {
    var href = link.getAttribute("href");
    if (!href || href.indexOf("#") === -1) {
      return null;
    }

    var hash = href.slice(href.indexOf("#") + 1);
    if (!hash) {
      return null;
    }

    try {
      hash = decodeURIComponent(hash);
    } catch (error) {
      // Keep the raw hash if decoding fails.
    }

    return document.getElementById(hash);
  }

  function setNavigationLanguage(language) {
    var links = document.querySelectorAll(".wy-menu a.reference.internal[href*='#']");
    Array.prototype.forEach.call(links, function (link) {
      var target = targetForLink(link);
      if (!target) {
        return;
      }

      var languageSection = target.classList.contains("ap-lang")
        ? target
        : target.closest(".ap-lang");
      if (!languageSection) {
        return;
      }

      var item = link.closest("li");
      if (!item) {
        return;
      }

      item.hidden = !languageSection.classList.contains("ap-lang-" + language);
    });
  }

  function setButtonState(language) {
    var buttons = document.querySelectorAll("[data-ap-set-lang]");
    Array.prototype.forEach.call(buttons, function (button) {
      var isActive = button.getAttribute("data-ap-set-lang") === language;
      button.classList.toggle("is-active", isActive);
      button.setAttribute("aria-pressed", isActive ? "true" : "false");
    });
  }

  function setBlockVisibility(language) {
    var blocks = document.querySelectorAll(".ap-lang");
    Array.prototype.forEach.call(blocks, function (block) {
      var isActive = block.classList.contains("ap-lang-" + language);
      block.hidden = !isActive;
      block.style.setProperty("display", isActive ? "block" : "none", "important");
    });
  }

  function setLanguage(language) {
    if (language !== "en") {
      language = "zh";
    }

    document.documentElement.setAttribute("data-ap-lang", language);
    document.documentElement.setAttribute("lang", language === "zh" ? "zh-CN" : "en");
    setBlockVisibility(language);
    setButtonState(language);
    setNavigationLanguage(language);
    storeLanguage(language);
  }

  function keepSwitcherInView(button) {
    var switcher = button.closest(".ap-language-switch");
    if (!switcher) {
      return;
    }

    switcher.scrollIntoView({ block: "start", inline: "nearest" });
  }

  document.addEventListener("DOMContentLoaded", function () {
    var hasLanguageBlocks = document.querySelector(".ap-lang");
    var buttons = document.querySelectorAll("[data-ap-set-lang]");
    if (!hasLanguageBlocks && buttons.length === 0) {
      return;
    }

    var initialLanguage = readStoredLanguage() || "zh";
    setLanguage(initialLanguage);

    Array.prototype.forEach.call(buttons, function (button) {
      button.addEventListener("click", function () {
        setLanguage(button.getAttribute("data-ap-set-lang"));
        keepSwitcherInView(button);
      });
    });
  });
})();
