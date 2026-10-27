/* Gaussian amplitude weights and their analytic wave-packet superposition.
 * Arbitrary units: k0=5, omega0=8, vg=0.7, h0=1.
 * omega(k0+q)=omega0+vg*q; sigma_y=1/sigma_k. No growth or spreading.
 * Node exports only support static-asset generation and illustration checks.
 */
(function () {
  "use strict";
  var words = {
    en: {
      title: "Closer wavenumbers, a wider packet", width: "Wavenumber width σₖ",
      time: "Time", reset: "Reset", spectrum: "1. Nearby wavenumbers · relative amplitude weight W(q)/W(0)",
      components: "2. Three representative inputs · unit heights for comparing phase",
      sum: "3. Whole-band sum u (orange), with envelope ±h (blue dashed)",
      position: "Position y (arbitrary units)", waveNumber: "Wavenumber k₀ + q",
      alt: "The upper panel shows a Gaussian band around k0. The middle panel shows three representative waves. Their phases align near the packet centre. The lower panel shows the weighted sum of the whole band, an oscillation inside a Gaussian envelope.",
      readout: "Amplitude widths", spatial: "space", frequency: "angular frequency"
    },
    zh: {
      title: "波数越集中，叠加后的波包越宽", width: "波数谱宽 σₖ",
      time: "时间", reset: "重置", spectrum: "1. 邻近波数的分布 · 相对幅值权重 W(q)/W(0)",
      components: "2. 三列代表性输入 · 统一高度，便于比较相位",
      sum: "3. 整个谱带的叠加 u（橙色），以及包络 ±h（蓝色虚线）",
      position: "位置 y（任意单位）", waveNumber: "波数 k₀ + q",
      alt: "上图为 k0 附近的高斯波数分布，中图是三列代表性的波，在波包中心附近相位相同。下图为整个谱带的加权叠加，振荡位于高斯包络之内。",
      readout: "幅值分布宽度", spatial: "空间", frequency: "角频率"
    }
  };
  var k0 = 5, omega0 = 8, vg = 0.7;
  var colours = ["#1c7a48", "#64748b", "#854dab"];

  function packetAt(y, t, sigma) {
    var h = Math.exp(-0.5 * Math.pow(sigma * (y - vg * t), 2));
    return { h: h, u: h * Math.cos(k0 * y - omega0 * t) };
  }
  function path(fn, xmin, xmax, yzero, yscale) {
    var points = [];
    for (var j = 0; j <= 960; j += 1) {
      var x = xmin + (xmax - xmin) * j / 960;
      points.push((j ? "L" : "M") + (60 + 668 * j / 960).toFixed(2) +
        " " + (yzero - yscale * fn(x)).toFixed(2));
    }
    return points.join(" ");
  }
  function label(x, y, text, anchor, colour) {
    return '<text x="' + x + '" y="' + y + '" text-anchor="' + (anchor || "start") +
      '" fill="' + (colour || "#334155") + '">' + text + '</text>';
  }
  function curve(d, colour, dash) {
    return '<path d="' + d + '" fill="none" stroke="' + colour +
      '" stroke-width="2"' + (dash ? ' stroke-dasharray="7 5"' : '') + '/>';
  }
  function plotSvg(sigma, t, language, prefix) {
    var w = words[language] || words.en;
    var s = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 605" role="img" aria-labelledby="' + prefix + '-title">' +
      '<title id="' + prefix + '-title">' + w.alt + '</title>' +
      '<rect width="760" height="605" fill="white"/>' +
      '<g font-family="sans-serif" font-size="14">' +
      label(60, 24, w.spectrum) + label(60, 244, w.components) + label(60, 406, w.sum) +
      '<path d="M60 44V160H728 M60 260V350H728 M60 305H728 M60 423V547H728 M60 485H728" fill="none" stroke="#cbd5e1"/>' +
      label(49, 164, "0", "end") + label(49, 54, "1", "end") +
      label(49, 271, "1", "end") + label(49, 309, "0", "end") + label(49, 350, "−1", "end") +
      label(49, 429, "1", "end") + label(49, 489, "0", "end") + label(49, 547, "−1", "end");
    [3, 4, 5, 6, 7].forEach(function (k) {
      s += label(60 + 668 * (k - 3) / 4, 181, String(k), "middle");
    });
    s += label(728, 205, w.waveNumber, "end");
    [-12, -6, 0, 6, 12].forEach(function (y) {
      var x = 60 + 668 * (y + 12) / 24;
      s += label(x, 370, String(y), "middle") + label(x, 569, String(y), "middle");
    });
    s += label(394, 595, w.position, "middle");
    s += curve(path(function (k) { return Math.exp(-0.5 * Math.pow((k-k0)/sigma, 2)); }, 3, 7, 160, 110), "#28658b");
    [-sigma, 0, sigma].forEach(function (q, n) {
      var x = 60 + 668 * (k0 + q - 3) / 4;
      var top = 160 - 110 * Math.exp(-0.5 * Math.pow(q / sigma, 2));
      s += '<path d="M' + x.toFixed(2) + ' 160V' + top.toFixed(2) + '" stroke="' + colours[n] + '" stroke-dasharray="4 4"/>';
      s += label(60 + n * 160, 205, ["k₀ − σₖ", "k₀", "k₀ + σₖ"][n], "start", colours[n]);
      s += curve(path(function (y) { return Math.cos((k0 + q) * y - (omega0 + vg * q) * t); }, -12, 12, 305, 42), colours[n]);
    });
    s += curve(path(function (y) { return packetAt(y,t,sigma).h; }, -12,12,485,58), "#216b96", true);
    s += curve(path(function (y) { return -packetAt(y,t,sigma).h; }, -12,12,485,58), "#216b96", true);
    s += curve(path(function (y) { return packetAt(y,t,sigma).u; }, -12,12,485,58), "#a34508");
    return s + '</g></svg>';
  }

  // Keep static fallbacks and interactive rendering on the same mathematical model.
  if (typeof module !== "undefined" && module.exports) {
    module.exports = { plotSvg: plotSvg, packetAt: packetAt };
    return;
  }
  function initialize(host, index) {
    var lang = host.getAttribute("data-k05-band");
    var w = words[lang] || words.en;
    var prefix = "k05-band-" + index;
    var ui = document.createElement("div");
    ui.innerHTML = '<p class="k05-band-title">' + w.title + '</p>' +
      '<div class="k05-band-controls"><label for="' + prefix + '-width">' + w.width +
      '<input id="' + prefix + '-width" data-width type="range" min="0.15" max="0.60" step="0.01" value="0.30"></label>' +
      '<label for="' + prefix + '-time">' + w.time +
      '<input id="' + prefix + '-time" data-time type="range" min="0" max="4" step="0.02" value="0"></label>' +
      '<button type="button" data-reset>' + w.reset + '</button></div>' +
      '<p class="k05-band-readout" aria-live="off"></p><div data-plot></div>';
    var width = ui.querySelector("[data-width]");
    var time = ui.querySelector("[data-time]");
    var plot = ui.querySelector("[data-plot]");
    var readout = ui.querySelector(".k05-band-readout");
    function draw() {
      var sigma = Number(width.value), t = Number(time.value);
      plot.innerHTML = plotSvg(sigma, t, lang, prefix);
      readout.textContent = "σₖ = " + sigma.toFixed(2) + " · σᵧ = " + (1/sigma).toFixed(2) +
        " · σω = " + (vg*sigma).toFixed(3) + " · " + w.time + " = " + t.toFixed(2);
      width.setAttribute("aria-valuetext", sigma.toFixed(2));
      time.setAttribute("aria-valuetext", t.toFixed(2));
    }
    width.addEventListener("input", draw);
    time.addEventListener("input", draw);
    ui.querySelector("[data-reset]").addEventListener("click", function () {
      width.value = "0.30"; time.value = "0"; draw();
    });
    draw();
    host.replaceChildren(ui);
  }
  function start() {
    document.querySelectorAll("[data-k05-band]").forEach(initialize);
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", start);
  else start();
}());
