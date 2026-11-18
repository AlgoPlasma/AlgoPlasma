(function () {
  "use strict";
  window.addEventListener("message", function (event) {
    if (event.origin !== window.location.origin || !event.data || event.data.type !== "g03-demo-height") return;
    const height = event.data.height;
    if (!Number.isFinite(height) || height < 300 || height > 12000) return;
    document.querySelectorAll("iframe.g03-collision-demo").forEach(function (frame) {
      if (event.source === frame.contentWindow) frame.style.height = Math.ceil(height) + "px";
    });
  });
})();
