/* K05 contribution history (Git author dates; edit times include timezone).
 * 2026-10-23 16:13 +08:00 | Yinjian Zhao | git 482110a190d6
 * 2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)
 */

/* An illustrative solution of (d_t + vg d_y) A = gamma A.
 * Arbitrary units; no experimental or EDI parameters. No external dependencies.
 * h = exp(gamma*t) exp(-(y-y0-vg*t)^2/(2*sigma^2)); u = h cos(k*y-omega*t).
 * The first-order envelope model omits spreading. The carrier and group
 * velocities differ: omega/k = 1.6, vg = 0.7.
 */
(function () {
  "use strict";
  var words = {
    en: {
      title: "Build the wave from two factors", time: "Time", growth: "Amplitude change",
      decay: "Decay", constant: "Constant height", grow: "Growth",
      play: "Play", pause: "Pause", reset: "Reset", wave: "Orange: u = h × cos",
      envelope: "Blue dashed: ±h", cosine: "Green: cosine factor", position: "Position (arbitrary units)",
      factor: "Cosine factor: cos(ky − ωt) · dimensionless",
      voltage: "Potential (arbitrary units)", height: "Peak envelope height",
      alt: "Upper panel: the orange wave u lies between the blue bounds +h and −h. Lower panel: the cosine factor ranges from −1 to +1. Multiply h by that factor to obtain u."
    },
    zh: {
      title: "两个因子相乘，得到波形", time: "时间", growth: "幅值变化",
      decay: "衰减", constant: "高度不变", grow: "增长",
      play: "播放", pause: "暂停", reset: "重置", wave: "橙色：u = h × cos",
      envelope: "蓝色虚线：±h", cosine: "绿色：余弦因子", position: "位置（任意单位）",
      factor: "余弦因子：cos(ky − ωt) · 无量纲",
      voltage: "电势（任意单位）", height: "包络峰值高度",
      alt: "上图：橙色波形 u 位于蓝色边界 +h 与 −h 之间。下图：余弦因子在 −1 与 +1 之间变化。把 h 与该因子相乘，就得到 u。"
    }
  };

  function initialize(host, index) {
    var w = words[host.getAttribute("data-k05-wave")] || words.en;
    var chart = words.en; // Figure labels are shared; controls remain localized.
    var prefix = "k05-wave-" + index;
    var ui = document.createElement("div");
    ui.innerHTML = '<p class="k05-wave-title">' + w.title + '</p>' +
      '<svg viewBox="0 0 720 430" role="img" aria-labelledby="' + prefix + '-title">' +
      '<title id="' + prefix + '-title">' + w.alt + '</title>' +
      '<defs><clipPath id="' + prefix + '-clip"><rect x="50" y="25" width="650" height="210"/></clipPath>' +
      '<clipPath id="' + prefix + '-cos-clip"><rect x="50" y="310" width="650" height="80"/></clipPath></defs>' +
      '<path d="M50 25V235H700 M50 130H700 M50 310V390H700 M50 350H700" stroke="#b3c1cd" fill="none"/>' +
      '<g fill="#485d6d" font-family="sans-serif" font-size="13">' +
      '<text x="50" y="16">' + chart.voltage + '</text>' +
      '<text x="375" y="425" text-anchor="middle">' + chart.position + '</text>' +
      '<text x="50" y="252" text-anchor="middle">−8</text>' +
      '<text x="375" y="252" text-anchor="middle">0</text>' +
      '<text x="700" y="252" text-anchor="middle">8</text>' +
      '<text x="40" y="134" text-anchor="end">0</text>' +
      '<text x="40" y="46" text-anchor="end">2</text>' +
      '<text x="40" y="222" text-anchor="end">−2</text>' +
      '<text x="50" y="292" fill="#237344">' + chart.factor + '</text>' +
      '<text x="40" y="322" text-anchor="end">1</text>' +
      '<text x="40" y="354" text-anchor="end">0</text>' +
      '<text x="40" y="386" text-anchor="end">−1</text>' +
      '<text x="50" y="408" text-anchor="middle">−8</text>' +
      '<text x="375" y="408" text-anchor="middle">0</text>' +
      '<text x="700" y="408" text-anchor="middle">8</text></g>' +
      '<g clip-path="url(#' + prefix + '-clip)" fill="none" stroke-width="2">' +
      '<path data-upper stroke="#216b96" stroke-dasharray="7 5"/>' +
      '<path data-lower stroke="#216b96" stroke-dasharray="7 5"/>' +
      '<path data-wave stroke="#a34508"/></g>' +
      '<g fill="#216b96" class="k05-envelope-labels" font-family="sans-serif" font-size="14">' +
      '<text data-h-plus>+h(y,t)</text><text data-h-minus>−h(y,t)</text></g>' +
      '<path data-cosine clip-path="url(#' + prefix + '-cos-clip)" fill="none" stroke="#237344" stroke-width="2"/></svg>' +
      '<p class="k05-wave-legend"><span class="k05-orange">' + w.wave +
      '</span><span class="k05-blue">' + w.envelope + '</span>' +
      '<span class="k05-green">' + w.cosine + '</span></p>' +
      '<div class="k05-wave-controls">' +
      '<label class="k05-time-label" for="' + prefix + '-time">' + w.time +
      '<input id="' + prefix + '-time" type="range" min="0" max="6" step="0.02" value="0"></label>' +
      '<label for="' + prefix + '-growth">' + w.growth +
      '<select id="' + prefix + '-growth"><option value="0">' + w.constant +
      '</option><option value="0.12">' + w.grow + '</option><option value="-0.12">' +
      w.decay + '</option></select></label>' +
      '<button type="button" data-play aria-pressed="false">' + w.play + '</button>' +
      '<button type="button" data-reset>' + w.reset + '</button></div>' +
      '<p class="k05-wave-readout" aria-live="off"></p>';
    var time = ui.querySelector("input");
    var growth = ui.querySelector("select");
    var play = ui.querySelector("[data-play]");
    var paths = [ui.querySelector("[data-upper]"), ui.querySelector("[data-lower]"), ui.querySelector("[data-wave]"), ui.querySelector("[data-cosine]")];
    var upperLabel = ui.querySelector("[data-h-plus]");
    var lowerLabel = ui.querySelector("[data-h-minus]");
    var readout = ui.querySelector(".k05-wave-readout");
    var running = false;
    var frame = null;
    var previous = null;
    var animationTime = 0;

    function draw() {
      var t = Number(time.value);
      var gamma = Number(growth.value);
      var lines = [[], [], [], []];
      for (var j = 0; j <= 480; j += 1) {
        var y = -8 + 16 * j / 480;
        var amplitude = Math.exp(gamma * t - Math.pow((y + 2 - 0.7 * t) / 2.2, 2) / 2);
        var cosine = Math.cos(5 * y - 8 * t);
        var values = [amplitude, -amplitude, amplitude * cosine, cosine];
        for (var p = 0; p < 4; p += 1) {
          var vertical = p === 3 ? 350 - values[p] * 32 : 130 - values[p] * 210 / 4.8;
          lines[p].push((j === 0 ? "M" : "L") + (50 + 650 * j / 480).toFixed(2) +
            " " + vertical.toFixed(2));
        }
      }
      paths.forEach(function (path, p) { path.setAttribute("d", lines[p].join(" ")); });
      var centreX = 50 + 650 * ((-2 + 0.7 * t) + 8) / 16;
      var peakPixels = Math.exp(gamma * t) * 210 / 4.8;
      upperLabel.setAttribute("x", (centreX + 8).toFixed(2));
      upperLabel.setAttribute("y", (130 - peakPixels - 9).toFixed(2));
      lowerLabel.setAttribute("x", (centreX + 8).toFixed(2));
      lowerLabel.setAttribute("y", (130 + peakPixels + 15).toFixed(2));
      readout.textContent = w.time + " = " + t.toFixed(2) + " · " + w.height + " = " + Math.exp(gamma * t).toFixed(2);
      time.setAttribute("aria-valuetext", t.toFixed(2));
    }

    function stop() {
      running = false;
      if (frame !== null) window.cancelAnimationFrame(frame);
      frame = null;
      previous = null;
      play.textContent = w.play;
      play.setAttribute("aria-pressed", "false");
    }

    function tick(now) {
      if (!running) return;
      // Stop when the language panel is hidden or the tab goes into the background.
      if (document.hidden || !host.getClientRects().length) { stop(); return; }
      if (previous !== null) {
        animationTime = Math.min(6, animationTime + Math.min((now - previous) / 1000, 0.1) * 0.8);
        time.value = String(animationTime);
        draw();
      }
      previous = now;
      if (Number(time.value) >= 6) { stop(); return; }
      frame = window.requestAnimationFrame(tick);
    }

    time.addEventListener("input", function () { stop(); draw(); });
    growth.addEventListener("change", draw);
    play.addEventListener("click", function () {
      if (running) { stop(); return; }
      if (Number(time.value) >= 6) { time.value = "0"; draw(); }
      running = true;
      animationTime = Number(time.value);
      play.textContent = w.pause;
      play.setAttribute("aria-pressed", "true");
      frame = window.requestAnimationFrame(tick);
    });
    ui.querySelector("[data-reset]").addEventListener("click", function () {
      stop(); time.value = "0"; growth.value = "0"; draw();
    });
    document.addEventListener("visibilitychange", function () { if (document.hidden) stop(); });
    draw();
    host.appendChild(ui);
    var fallback = host.querySelector(".k05-wave-fallback");
    if (fallback) fallback.remove();
    // The drawing starts still; animation only follows an explicit button press.
  }

  document.addEventListener("DOMContentLoaded", function () {
    document.querySelectorAll("[data-k05-wave]").forEach(initialize);
  });
})();
