/* Analytical displacement illustration; model and teaching brief in
 * docs/author_notes/plasma_waves_intro.md. No particle solver is used here. */
(() => {
  'use strict';
  const translations = { en: {
    title: 'A wave passes. <span>Where do the electrons go?</span>',
    documentTitle: 'A wave passes. Where do the electrons go? | AlgoPlasma',
    chapter: '01 / Electron motion and plasma oscillations', back: 'Previous step', returnLabel: 'Return to the plasma waves course',
    electron: 'Electrons', ion: 'Ion background', pause: 'Pause', play: 'Play',
    model: 'Collective-motion illustration: fixed ions, no thermal motion. Dots are not a crystal lattice; motion is slowed.',
    prompt: 'Start by observing.',
    steps: [
      'Begin with a uniformly distributed plasma.',
      'Watch regions become denser and more sparse.',
      'Will this electron travel across the plasma with the wave?',
      'Now follow one dense region. Which way does it move?',
      'Two kinds of motion, in the same picture.'
    ],
    actions: ['Set electrons moving', 'Follow one electron', 'Follow the pattern', 'Reveal the insight', 'Watch again'],
    particlePrompt: 'Follow this electron', particleLabel: 'One electron: back and forth', patternLabel: 'Density pattern →',
    takeaway: '<span class="gold">Electrons oscillate locally.</span><br class="mobile-break"> <span class="mint">The density pattern moves on.</span>',
    progress: 'Observation step',
    descriptions: [
      'A uniform array of green dots represents electrons. Blue plus signs represent a fixed ion background. This is an illustration, not a crystal lattice.',
      'Electrons move horizontally and form alternating dense and sparse regions. The density pattern moves to the right.',
      'One gold electron oscillates within a short marked interval near its equilibrium position. It does not travel across the plasma.',
      'The gold electron oscillates locally while a highlighted dense region travels to the right.',
      'Local electron oscillations and rightward motion of the density pattern are visible together. This illustrates phase motion, not wave-packet energy transport.'
    ],
    fullscreenFailed: 'Fullscreen is unavailable here. Open the lesson in a separate browser tab.',
    canvasFailed: 'The electron oscillates locally while the density pattern travels to the right. This browser cannot draw the animation.'
  }, zh: {
    title: '波来了，<span>电子去哪儿了？</span>', documentTitle: '波来了，电子去哪儿了？ | AlgoPlasma',
    chapter: '01 / 电子运动与等离子体振荡', back: '上一步', returnLabel: '返回等离子体波课堂',
    electron: '电子', ion: '离子背景', pause: '暂停动画', play: '播放动画',
    model: '集体运动示意：离子固定，省略热运动；点阵不代表晶格，动画已减速。',
    prompt: '从这里，开始观察。', steps: ['先看一片均匀的等离子体。', '出现了疏密相间的变化。', '这个电子，会跟着波一直向右走吗？', '再盯住一处密集的区域：它在向哪里移动？', '同一幅图里，有两种不同的运动。'],
    actions: ['让电子动起来', '追踪一个电子', '再看疏密图样', '揭示这一页的结论', '重新看一遍'],
    particlePrompt: '追踪这一个电子', particleLabel: '这一个电子：局部往复', patternLabel: '疏密图样 →',
    takeaway: '<span class="gold">电子在局部往复，</span><br class="mobile-break"><span class="mint">疏密图样向前移动。</span>',
    progress: '观察步骤',
    descriptions: [
      '均匀排列的绿色点代表电子，蓝色加号代表固定离子背景；点阵只用于示意集体运动，不代表晶格。',
      '电子沿水平方向运动，组成疏密相间、向右移动的密度图样。',
      '金色电子只在标出的短区间内往复运动，并不穿过整片等离子体。',
      '金色电子局部往复运动，同时高亮的密集区域向右移动。',
      '电子在局部往复，密度图样向右移动。这里展示相位运动，不据此推断波包或能量的输运速度。'
    ],
    fullscreenFailed: '当前预览不允许全屏，请在独立浏览器窗口中打开。',
    canvasFailed: '电子在局部往复，疏密图样向右移动。当前浏览器无法绘制动画。'
  }};
  const TWO_PI = 2 * Math.PI;
  const M = 2; // Two spatial periods in the displayed periodic interval.
  const RELATIVE_AMPLITUDE = 0.028; // max |d(displacement)/dq| = 0.352 < 1: no crossing.
  const PHASE_RATE = 1.12; // radians per display second, not a physical frequency.

  function draw({ s, ctx, text, line, dot, arrow, label }) {
    const w = s.width, h = s.height;
    const small = w < 650;
    const left = small ? 9 : 22, right = w - left, span = right - left;
    const gridTop = small ? 148 : 116, gridBottom = Math.max(gridTop + 75, h - (small ? 71 : 94));
    const rows = small ? 5 : 7, columns = Math.max(19, Math.min(49, Math.round(span / 25)));
    const rowSpacing = (gridBottom - gridTop) / (rows - 1);
    const spacing = span / columns, a = RELATIVE_AMPLITUDE * span * s.data.amplitude;
    const k = TWO_PI * M / span;
    const trackedColumn = Math.floor(columns * .36), trackedRow = rows - 1;
    const qTracked = (trackedColumn + .5) * spacing;
    const xTracked = left + qTracked + a * Math.sin(k * qTracked - s.data.phase);
    const alpha = Math.max(0, Math.min(1, s.data.band));
    // A density maximum has k*q - phase = pi. At that phase displacement is zero.
    const peak = ((s.data.phase + Math.PI) / k % span + span) % span;
    const bandWidth = span * .045;

    ctx.save(); ctx.beginPath(); ctx.rect(left - 7, gridTop - 15, span + 14, gridBottom - gridTop + 30); ctx.clip();
    if (alpha > .001) {
      for (const offset of [-span, 0, span]) {
        const center = left + peak + offset;
        const gradient = ctx.createLinearGradient(center - bandWidth, 0, center + bandWidth, 0);
        gradient.addColorStop(0, 'rgba(181,239,207,0)');
        gradient.addColorStop(.5, `rgba(181,239,207,${.14 * alpha})`);
        gradient.addColorStop(1, 'rgba(181,239,207,0)');
        ctx.fillStyle = gradient; ctx.fillRect(center - bandWidth, gridTop - 14, bandWidth * 2, gridBottom - gridTop + 28);
      }
    }
    for (let row = 0; row < rows; row++) {
      const y = gridTop + row * rowSpacing;
      for (let col = 0; col < columns; col++) {
        const q = (col + .5) * spacing;
        const qx = left + q;
        line(qx - 2.8, y, qx + 2.8, y, '#7799b266', 1.1);
        line(qx, y - 2.8, qx, y + 2.8, '#7799b266', 1.1);
        const shifted = q + a * Math.sin(k * q - s.data.phase);
        const x = left + ((shifted % span + span) % span);
        const tracked = row === trackedRow && col === trackedColumn && s.data.track > .001;
        if (tracked) {
          const glow = ctx.createRadialGradient(x, y, 0, x, y, 19);
          glow.addColorStop(0, `rgba(244,197,131,${s.data.track * .32})`); glow.addColorStop(1, 'rgba(244,197,131,0)');
          ctx.fillStyle = glow; ctx.fillRect(x - 19, y - 19, 38, 38);
          dot(x, y, small ? 5.5 : 7, '#f4c583');
          ctx.beginPath(); ctx.strokeStyle = `rgba(244,197,131,${s.data.track * .65})`; ctx.lineWidth = 1.3; ctx.arc(x, y, small ? 11 : 14, 0, TWO_PI); ctx.stroke();
        } else dot(x, y, small ? 3 : 4, '#b5efcf');
      }
    }
    ctx.restore();

    if (s.data.track > .001) {
      ctx.save(); ctx.globalAlpha = s.data.track;
      const origin = left + qTracked, trackY = gridBottom + 26;
      line(origin, gridBottom - 15, origin, trackY + 5, '#f4c58366', 1, [3, 4]);
      arrow(origin, trackY, origin - RELATIVE_AMPLITUDE * span, '#f4c583');
      arrow(origin, trackY, origin + RELATIVE_AMPLITUDE * span, '#f4c583');
      line(xTracked, gridBottom + 9, xTracked, trackY, '#f4c58388', 1);
      // Keep callout text inside the canvas even on narrow displays.
      label(s.stage === 2 ? text.particlePrompt : text.particleLabel, small ? w / 2 : origin, gridBottom + 57, '#f4c583', small ? 17 : 23, 'center');
      ctx.restore();
    }
    if (alpha > .001) {
      ctx.save(); ctx.globalAlpha = alpha;
      const center = left + peak;
      const labelX = Math.max(small ? 83 : 145, Math.min(w - (small ? 83 : 145), center));
      label(text.patternLabel, labelX, gridTop - 37, '#b5efcf', small ? 18 : 24, 'center');
      line(center, gridTop - 19, center, gridTop - 9, '#b5efcf88', 1.5);
      ctx.restore();
    }
  }

  PlasmaLesson.register('motion', {
    translations, draw,
    running: s => s.stage > 0,
    setup({ s }) { Object.assign(s.data, { phase: 0, amplitude: 0, track: 0, band: 0 }); },
    onStage(s, old, reset) {
      if (reset || s.stage === 0) s.data.phase = 0;
      if (reset || s.paused || s.stage === 0) {
        s.data.amplitude = Number(s.stage > 0);
        s.data.track = Number(s.stage >= 2);
        s.data.band = Number(s.stage >= 3);
      }
    },
    frame(s, dt) {
      const blend = s.paused ? 1 : 1 - Math.exp(-dt * 6);
      s.data.amplitude += (Number(s.stage > 0) - s.data.amplitude) * blend;
      s.data.track += (Number(s.stage >= 2) - s.data.track) * blend;
      s.data.band += (Number(s.stage >= 3) - s.data.band) * blend;
      if (s.stage > 0 && !s.paused) s.data.phase = (s.data.phase + dt * PHASE_RATE) % (TWO_PI * M);
    }
  });
})();

/* Plasma-wave contribution history (Git author dates; edit time includes timezone).
 * 2026-11-17 19:33 +08:00 | Yinjian Zhao | git fb1cc989ad32
 * 2026-11-17 19:41 +08:00 | Yinjian Zhao | git 7667d669c7ec
 * 2026-11-17 19:50 +08:00 | Yinjian Zhao | git 3e022dd90c69
 * 2026-11-18 08:16 +08:00 | Yinjian Zhao | git 45f247468130
 * 2026-11-18 15:11 +08:00 | Yinjian Zhao | git 8e431a343dc7
 * 2026-11-19 15:22 +08:00 | Yinjian Zhao | git b32e8af2bb2b
 * 2026-11-19 16:01 +08:00 | Yinjian Zhao | git 2113cbc05ed4
 * 2026-11-19 16:28 +08:00 | Yinjian Zhao | edit (Codex-assisted)
 */
