/* K05 contribution history (Git author dates; edit times include timezone).
 * 2026-10-27 16:16 +08:00 | Yinjian Zhao | git 1782aebfbe9c
 * 2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)
 */

/* Ideal potential samples: Phi(y,t)=cos(pi*y-pi*t), arbitrary units.
 * Probe 1 is at y=0; probe 2 is at y=separation. No growth or coupling.
 * The same renderer produces the static bilingual fallback illustrations.
 */
(function () {
  "use strict";
  var words = {
    en: {
      title: "One moving wave, two fixed records", time: "Time", spacing: "Probe separation Δy",
      play: "Play", pause: "Pause", reset: "Reset", top: "1. Spatial wave at the selected time",
      bottom: "2. Time traces at the two probe positions", position: "Position y (arbitrary units)",
      axisTime: "Time t (arbitrary units)", one: "Probe 1 · y = 0", two: "Probe 2 · y = Δy",
      delay: "Crest delay", phase: "Spatial phase advance", note: "Equal amplitudes; different phases.",
      alt: "A sinusoidal potential wave passes two fixed probes. Dots on the spatial wave correspond to the dots on the two time traces at the selected time. Both traces have equal amplitude but different phase."
    },
    zh: {
      title: "一列移动的波，两处固定的记录", time: "时间", spacing: "探针间距 Δy",
      play: "播放", pause: "暂停", reset: "重置", top: "1. 当前时刻的空间波形",
      bottom: "2. 两个固定位置的时间曲线", position: "位置 y（任意单位）",
      axisTime: "时间 t（任意单位）", one: "探针 1 · y = 0", two: "探针 2 · y = Δy",
      delay: "波峰延迟", phase: "空间相位推进", note: "两处幅值相同，相位不同。",
      alt: "正弦电势波经过两个固定探针。空间波形上的两点，对应当前时刻两条时间曲线上的两点。两条记录的幅值相同，相位不同。"
    }
  };
  var blue = "#216b96", orange = "#a34508";
  function potentialAt(y, t) { return Math.cos(Math.PI * (y - t)); }
  function label(x, y, value, anchor, colour) {
    return '<text x="' + x + '" y="' + y + '" text-anchor="' + (anchor || "start") +
      '" fill="' + (colour || "#334155") + '">' + value + '</text>';
  }
  function curve(fn, lo, hi, baseline, scale, colour) {
    var path = [];
    for (var j = 0; j <= 720; j += 1) {
      var x = lo + (hi-lo)*j/720;
      path.push((j ? "L" : "M") + (66+650*j/720).toFixed(2) + " " + (baseline-scale*fn(x)).toFixed(2));
    }
    return '<path d="' + path.join(" ") + '" fill="none" stroke="' + colour + '" stroke-width="2.2"/>';
  }
  function dot(x, y, colour) {
    return '<circle cx="' + x.toFixed(2) + '" cy="' + y.toFixed(2) + '" r="5" fill="' + colour + '" stroke="white" stroke-width="1.5"/>';
  }
  function plotSvg(separation, t, language, prefix) {
    var w=words[language] || words.en;
    var chart = words.en; // Keep visible figure labels English in both views.
    var s='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 468" role="img" aria-labelledby="'+prefix+'-title">'+
      '<title id="'+prefix+'-title">'+w.alt+'</title><rect width="760" height="468" fill="white"/>'+
      '<g font-family="sans-serif" font-size="14">'+label(66,25,chart.top)+
      label(66,49,chart.one,"start",blue)+label(354,49,chart.two,"start",orange)+
      label(66,274,chart.bottom)+
      '<path d="M66 65V205H716 M66 135H716 M66 294V416H716 M66 355H716" fill="none" stroke="#cbd5e1"/>';
    [-1,0,1].forEach(function (v) {
      s+=label(54,139-64*v,String(v),"end")+label(54,359-55*v,String(v),"end");
    });
    [-1,0,1,2,3,4].forEach(function (y) { s+=label(66+650*(y+1)/5,225,String(y),"middle"); });
    [0,1,2,3,4,5,6].forEach(function (time) { s+=label(66+650*time/6,436,String(time),"middle"); });
    s+=label(391,247,chart.position,"middle")+label(391,460,chart.axisTime,"middle");
    s+=curve(function (y) {return potentialAt(y,t);},-1,4,135,64,"#657785");
    [0,separation].forEach(function (y,n) {
      var colour=n ? orange : blue, x=66+650*(y+1)/5;
      s+='<path d="M'+x.toFixed(2)+' 65V205" stroke="'+colour+'" stroke-dasharray="4 4"/>';
      s+=dot(x,135-64*potentialAt(y,t),colour);
      s+=curve(function (time) {return potentialAt(y,time);},0,6,355,55,colour);
    });
    var cursor=66+650*t/6;
    s+='<path d="M'+cursor.toFixed(2)+' 294V416" stroke="#64748b" stroke-dasharray="4 4"/>';
    s+=dot(cursor,355-55*potentialAt(0,t),blue)+dot(cursor,355-55*potentialAt(separation,t),orange);
    return s+'</g></svg>';
  }
  if (typeof module !== "undefined" && module.exports) {
    module.exports={plotSvg:plotSvg,potentialAt:potentialAt};
    return;
  }
  function initialize(host,index) {
    var lang=host.getAttribute("data-k05-probes"), w=words[lang] || words.en, prefix="k05-probes-"+index;
    var ui=document.createElement("div");
    ui.innerHTML='<p class="k05-probes-title">'+w.title+'</p><div class="k05-probes-controls">'+
      '<label for="'+prefix+'-spacing">'+w.spacing+'<input id="'+prefix+'-spacing" data-spacing type="range" min="0.2" max="1.4" step="0.05" value="0.5"></label>'+
      '<label for="'+prefix+'-time">'+w.time+'<input id="'+prefix+'-time" data-time type="range" min="0" max="6" step="0.02" value="0"></label>'+
      '<button type="button" data-play aria-pressed="false">'+w.play+'</button><button type="button" data-reset>'+w.reset+'</button></div>'+
      '<p class="k05-probes-readout" aria-live="off"></p><div data-plot></div>';
    var spacing=ui.querySelector("[data-spacing]"),time=ui.querySelector("[data-time]"),play=ui.querySelector("[data-play]");
    var plot=ui.querySelector("[data-plot]"),readout=ui.querySelector(".k05-probes-readout");
    var running=false, frame=0, last=null, animationTime=0;
    function draw() {
      var dy=Number(spacing.value),t=Number(time.value);
      plot.innerHTML=plotSvg(dy,t,lang,prefix);
      readout.textContent=w.time+' = '+t.toFixed(2)+' · Δy = '+dy.toFixed(2)+' · '+w.delay+' = '+dy.toFixed(2)+' · '+w.phase+' = '+dy.toFixed(2)+'π · '+w.note;
      spacing.setAttribute("aria-valuetext",dy.toFixed(2));time.setAttribute("aria-valuetext",t.toFixed(2));
    }
    function stop() {
      running=false;last=null;cancelAnimationFrame(frame);play.textContent=w.play;play.setAttribute("aria-pressed","false");
    }
    function tick(now) {
      if (!running) return;
      if (document.hidden || host.getClientRects().length===0) {stop();return;}
      if (last!==null) animationTime=Math.min(6,animationTime+(now-last)/1000);
      time.value=String(animationTime);
      last=now;draw();
      if (animationTime>=6) stop(); else frame=requestAnimationFrame(tick);
    }
    spacing.addEventListener("input",draw);
    time.addEventListener("input",function () {stop();draw();});
    play.addEventListener("click",function () {
      if(running) {stop();return;}
      if(Number(time.value)>=6)time.value="0";
      animationTime=Number(time.value);running=true;last=null;play.textContent=w.pause;play.setAttribute("aria-pressed","true");frame=requestAnimationFrame(tick);
    });
    ui.querySelector("[data-reset]").addEventListener("click",function () {stop();time.value="0";spacing.value="0.5";draw();});
    document.addEventListener("visibilitychange",function () {if(document.hidden)stop();});
    draw();host.replaceChildren(ui);
  }
  function start() {document.querySelectorAll("[data-k05-probes]").forEach(initialize);}
  if(document.readyState==="loading") document.addEventListener("DOMContentLoaded",start); else start();
}());
