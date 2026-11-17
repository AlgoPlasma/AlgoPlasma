/* Rigid electron-slab illustration in the small-displacement bulk-field
 * approximation. Model and limits: docs/author_notes/plasma_waves_restoring.md. */
(() => {
  'use strict';
  const $ = id => document.getElementById(id);
  const translations = {
    zh: {
      title: '电子为什么<span>会来回运动？</span>', documentTitle: '电子为什么会来回运动？ | AlgoPlasma',
      chapter: '02 / 恢复力与惯性', back: '上一步', returnLabel: '返回等离子体波课堂',
      electron: '电子层', ion: '固定离子层', pause: '暂停动画', play: '播放动画',
      model: '平板模型：离子固定，电子层整体移动；省略热运动和碰撞，动画减速。',
      keyboard: '点击点阵或按 → 继续 · F 全屏',
      steps: [
        '电子与离子的电荷相互抵消，先从平衡开始。',
        '先将整个电子层，向右移开一点。',
        '左侧留下正电，右侧多出负电。',
        '电场从正电指向负电：向右。',
        '电子带负电，所以受力与电场相反：向左。',
        '回到原位时仍有速度，电子会越过平衡位置。'
      ],
      actions: ['把电子层向右移', '观察两侧电荷', '电场指向哪里？', '电子受到什么力？', '释放电子层', '重新看一遍'],
      field: '电场 E', fieldZero: '电场 E = 0', force: '电子受力', forceZero: '电子受力 = 0',
      positive: '正电', negative: '负电', displaced: '电子层右移', equilibrium: '平衡位置',
      takeaway: '<span class="mint">电场把电子拉回，</span><br class="mobile-break"><span class="gold">惯性让它越过原位。</span>',
      previous: '← 回看第一页：电子运动与波的图样', progress: '推演步骤',
      descriptions: [
        '电子层和固定离子层重合，总电荷为零。',
        '电子层整体向右偏移，固定离子层仍在原位。这是人为准备的初始位移。',
        '电子层右移后，左侧露出带正电的离子区域，右侧形成带负电的电子区域。',
        '电荷分离产生向右的电场，从左侧正电指向右侧负电。',
        '电子带负电，电场向右时电子所受的电场力向左，指向平衡位置。',
        '释放电子层后，电场力使它向平衡位置加速。通过平衡位置时力为零但速度不为零。越过原位后，电场和恢复力反向，电子层减速、转向并反复振荡。'
      ],
      fullscreenFailed: '当前预览不允许全屏，请在独立浏览器窗口中打开。',
      canvasFailed: '当前浏览器无法绘制动画。电荷分离建立恢复电场；惯性使电子越过平衡位置。'
    },
    en: {
      title: 'Why do electrons <span>keep oscillating?</span>', documentTitle: 'Why do electrons keep oscillating? | AlgoPlasma',
      chapter: '02 / Restoring force and inertia', back: 'Previous step', returnLabel: 'Return to the plasma waves course',
      electron: 'Electrons', ion: 'Fixed ions', pause: 'Pause', play: 'Play',
      model: 'Slab model: fixed ions, coherent electron displacement, no thermal motion or collisions. Motion is slowed.',
      keyboard: 'Click the dots or press → to continue · F fullscreen',
      steps: [
        'Electron and ion charges balance. Begin at equilibrium.',
        'Shift the entire electron layer slightly to the right.',
        'Positive charge is exposed on the left; negative charge on the right.',
        'The field points from positive to negative charge: to the right.',
        'Electrons are negative. Their electric force points left.',
        'At equilibrium they still have velocity, so they move past it.'
      ],
      actions: ['Shift the electrons', 'Inspect the charges', 'Which way is the field?', 'Find the electron force', 'Release the electrons', 'Watch again'],
      field: 'Electric field E', fieldZero: 'Electric field E = 0', force: 'Electron force', forceZero: 'Electron force = 0',
      positive: 'Positive', negative: 'Negative', displaced: 'Electron displacement', equilibrium: 'Equilibrium',
      takeaway: '<span class="mint">The field pulls electrons back.</span><br class="mobile-break"> <span class="gold">Inertia carries them past equilibrium.</span>',
      previous: '← Page 1: electron motion and the wave pattern', progress: 'Explanation step',
      descriptions: [
        'The electron layer overlaps a fixed ion layer. Their charges cancel.',
        'The electron layer is displaced to the right while ions stay fixed. This imposed displacement prepares the initial condition.',
        'A positive ion region is exposed on the left and a negative electron region on the right.',
        'The separated charge produces an electric field from left to right, from positive to negative.',
        'The field points right, but the force on a negative electron points left, toward equilibrium.',
        'After release, the electric force accelerates the electrons toward equilibrium. The force is zero there but velocity is not. After crossing, field and force reverse; electrons slow down, turn around and oscillate repeatedly.'
      ],
      fullscreenFailed: 'Fullscreen is unavailable here. Open this lesson in a separate browser tab.',
      canvasFailed: 'This browser cannot draw the animation. Charge separation creates a restoring field; inertia carries electrons past equilibrium.'
    }
  };
  const canvas = $('plasma'), ctx = canvas.getContext('2d');
  const preference = matchMedia('(prefers-reduced-motion: reduce)');
  const state = { stage: 0, shift: 0, phase: 0, paused: preference.matches, lastTime: null, width: 0, height: 0 };
  const PHASE_RATE = 1.15; // Display radians per second; no physical time calibration.
  const SHIFT_FRACTION = .085; // Relative to the illustrated slab width.
  let language, text, toastTimer;

  function initialLanguage() {
    const requested = new URLSearchParams(location.search).get('lang');
    if (requested === 'zh' || requested === 'en') return requested;
    try { if (localStorage.getItem('ap-doc-language') === 'en') return 'en'; } catch (_) { /* Optional preference. */ }
    return 'zh';
  }
  function setLanguage(value) {
    language = value === 'en' ? 'en' : 'zh'; text = translations[language];
    document.documentElement.lang = language === 'en' ? 'en' : 'zh-CN'; document.title = text.documentTitle;
    $('title').innerHTML = text.title; $('chapter').textContent = text.chapter;
    $('return-link').setAttribute('aria-label', text.returnLabel); $('back').setAttribute('aria-label', text.back);
    $('electron-name').textContent = text.electron; $('ion-name').textContent = text.ion;
    $('model-note').textContent = text.model; $('keyboard-note').textContent = text.keyboard;
    $('takeaway-text').innerHTML = text.takeaway;
    $('previous-lesson').textContent = text.previous;
    $('previous-lesson').href = `01_what_moves.html?lang=${language}`;
    $('language-switch').setAttribute('aria-label', language === 'en' ? 'Choose language' : '选择语言');
    document.querySelectorAll('[data-language]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.language === language)));
    try { localStorage.setItem('ap-doc-language', language); } catch (_) { /* file:// may restrict storage. */ }
    try { const url = new URL(location.href); url.searchParams.set('lang', language); history.replaceState(null, '', url); } catch (_) { /* file:// may restrict history. */ }
    $('toast').hidden = true;
    render(false);
  }
  function updateMotion() {
    $('motion').hidden = state.stage !== 5;
    $('motion').textContent = state.paused ? text.play : text.pause;
    $('motion').setAttribute('aria-pressed', String(state.paused));
  }
  function render(animate = true) {
    $('lesson').dataset.stage = String(state.stage);
    $('narration').textContent = text.steps[state.stage];
    $('narration').classList.remove('changed');
    if (animate) { void $('narration').offsetWidth; $('narration').classList.add('changed'); }
    $('advance-text').textContent = text.actions[state.stage];
    $('advance-arrow').textContent = state.stage === 5 ? '↺' : '→';
    $('back').hidden = state.stage === 0; $('takeaway').hidden = state.stage !== 5;
    $('stage-count').textContent = `${state.stage + 1} / 6`;
    $('progress').setAttribute('aria-label', `${text.progress} ${state.stage + 1} / 6`);
    [...$('progress').children].forEach((dot, i) => dot.classList.toggle('filled', i <= state.stage));
    canvas.setAttribute('aria-label', text.descriptions[state.stage]); canvas.textContent = text.descriptions[state.stage];
    $('status').textContent = text.descriptions[state.stage];
    updateMotion(); fitCanvas();
  }
  function setStage(value) {
    const oldStage = state.stage;
    state.stage = Math.max(0, Math.min(5, value));
    if (state.stage === 0) { state.shift = 0; state.phase = 0; state.paused = preference.matches; }
    if (state.stage === 5 && oldStage !== 5) { state.shift = 1; state.phase = 0; state.paused = preference.matches; }
    if (oldStage === 5 && state.stage < 5) { state.phase = 0; state.shift = state.stage > 0 ? 1 : 0; }
    if (preference.matches && state.stage > 0 && state.stage < 5) state.shift = 1;
    render();
  }
  function next() { setStage(state.stage === 5 ? 0 : state.stage + 1); }
  function back() { if (state.stage > 0) setStage(state.stage - 1); }
  function toggleMotion() { if (state.stage === 5) { state.paused = !state.paused; updateMotion(); } }
  $('advance').addEventListener('click', next); $('back').addEventListener('click', back);
  canvas.addEventListener('click', next); $('motion').addEventListener('click', toggleMotion);
  document.querySelectorAll('[data-language]').forEach(button => button.addEventListener('click', () => setLanguage(button.dataset.language)));
  async function fullscreen() {
    try { if (document.fullscreenElement) await document.exitFullscreen(); else await document.documentElement.requestFullscreen(); }
    catch (_) { $('toast').textContent = text.fullscreenFailed; $('toast').hidden = false; clearTimeout(toastTimer); toastTimer = setTimeout(() => { $('toast').hidden = true; }, 4000); }
  }
  document.addEventListener('keydown', event => {
    if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey || event.repeat || event.target.closest('input,textarea,select,[contenteditable]')) return;
    if (event.key === ' ' && event.target.closest('button,a')) return;
    if (['ArrowRight', 'PageDown', ' '].includes(event.key)) { event.preventDefault(); next(); }
    if (['ArrowLeft', 'PageUp'].includes(event.key)) { event.preventDefault(); back(); }
    if (event.key.toLowerCase() === 'f') { event.preventDefault(); fullscreen(); }
    if (event.key.toLowerCase() === 'p') { event.preventDefault(); toggleMotion(); }
  });
  preference.addEventListener('change', event => { state.paused = event.matches; if (event.matches && state.stage > 0 && state.stage < 5) state.shift = 1; updateMotion(); draw(); });

  function fitCanvas() {
    const rect = canvas.getBoundingClientRect(); if (rect.width <= 0 || rect.height <= 0) return;
    state.width = rect.width; state.height = rect.height;
    const dpr = Math.min(devicePixelRatio || 1, 2); canvas.width = Math.round(rect.width * dpr); canvas.height = Math.round(rect.height * dpr);
    if (ctx) ctx.setTransform(dpr, 0, 0, dpr, 0, 0); draw();
  }
  function line(x1, y1, x2, y2, color, width = 1, dash = []) {
    ctx.beginPath(); ctx.strokeStyle = color; ctx.lineWidth = width; ctx.setLineDash(dash); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke(); ctx.setLineDash([]);
  }
  function dot(x, y, radius, color) { ctx.beginPath(); ctx.fillStyle = color; ctx.arc(x, y, radius, 0, 2 * Math.PI); ctx.fill(); }
  function label(value, x, y, color, size, align = 'center') {
    ctx.font = `${size}px "Segoe UI","Microsoft YaHei","PingFang SC",sans-serif`; ctx.fillStyle = color; ctx.textAlign = align; ctx.textBaseline = 'middle'; ctx.fillText(value, x, y);
  }
  function arrow(x1, y, x2, color) {
    line(x1, y, x2, y, color, 2); const direction = Math.sign(x2 - x1);
    if (Math.abs(x2 - x1) > 5) { line(x2 - direction * 7, y - 4, x2, y, color, 2); line(x2 - direction * 7, y + 4, x2, y, color, 2); }
  }
  function draw() {
    if (!ctx || !text || !state.width || !state.height) return;
    const w = state.width, h = state.height, small = w < 650;
    ctx.clearRect(0, 0, w, h);
    const left = w * .16, slabWidth = w * .68, top = small ? 104 : 106;
    const bottom = Math.max(top + 65, h - 91), slabHeight = bottom - top;
    const displacement = state.shift * SHIFT_FRACTION * slabWidth;
    const right = left + slabWidth, absShift = Math.abs(displacement);
    const center = w / 2, rows = 5, columns = small ? 13 : 25;
    // Charge-exposed bands are the non-overlapping ends of the two slabs.
    if (state.stage >= 2 && absShift > .25) {
      const positiveLeft = displacement > 0 ? left : right + displacement;
      const negativeLeft = displacement > 0 ? right : left + displacement;
      ctx.fillStyle = '#8eadd92c'; ctx.fillRect(positiveLeft, top - 13, absShift, slabHeight + 26);
      ctx.fillStyle = '#b5efcf2d'; ctx.fillRect(negativeLeft, top - 13, absShift, slabHeight + 26);
      label('+', positiveLeft + absShift / 2, top - 30, '#a4c0e3', small ? 25 : 32);
      label('−', negativeLeft + absShift / 2, top - 30, '#b5efcf', small ? 25 : 32);
    }
    line(left, top - 13, left, bottom + 13, '#8eadd965', 1.2, [4, 4]);
    line(right, top - 13, right, bottom + 13, '#8eadd965', 1.2, [4, 4]);
    for (let row = 0; row < rows; row++) {
      const y = top + row * slabHeight / (rows - 1);
      for (let col = 0; col < columns; col++) {
        const x = left + (col + .5) * slabWidth / columns;
        line(x - 3.5, y, x + 3.5, y, '#8eadd9a0', 1.4); line(x, y - 3.5, x, y + 3.5, '#8eadd9a0', 1.4);
        const tracked = state.stage >= 4 && col === Math.floor(columns / 2) && row === 2;
        dot(x + displacement, y, tracked ? (small ? 5.5 : 7) : (small ? 3 : 4.5), tracked ? '#f4c583' : '#b5efcf');
        if (tracked) {
          ctx.beginPath(); ctx.strokeStyle = '#f4c58388'; ctx.lineWidth = 1.2; ctx.arc(x + displacement, y, small ? 11 : 15, 0, 2 * Math.PI); ctx.stroke();
          line(x, top - 10, x, bottom + 12, '#f4c58344', 1, [3, 5]);
        }
      }
    }
    if (state.stage === 1) {
      arrow(center - 10, bottom + 35, center - 10 + Math.max(displacement, 1), '#b5efcf');
      label(text.displaced, center, bottom + 64, '#b5efcf', small ? 17 : 23);
    }
    const vectorLength = Math.min(w * .20, 185) * state.shift;
    if (state.stage >= 3) {
      label(Math.abs(state.shift) < .035 ? text.fieldZero : text.field, center, 48, '#b5efcf', small ? 18 : 25);
      if (Math.abs(state.shift) >= .035) arrow(center - vectorLength / 2, 72, center + vectorLength / 2, '#b5efcf');
    }
    if (state.stage >= 4) {
      if (Math.abs(state.shift) >= .035) arrow(center + vectorLength / 2, bottom + 36, center - vectorLength / 2, '#f4c583');
      label(Math.abs(state.shift) < .035 ? text.forceZero : text.force, center, bottom + 66, '#f4c583', small ? 18 : 25);
    }
  }
  function frame(now) {
    const dt = state.lastTime === null ? 0 : Math.min((now - state.lastTime) / 1000, .05); state.lastTime = now;
    if (!document.hidden) {
      if (state.stage === 5) {
        if (!state.paused) state.phase = (state.phase + dt * PHASE_RATE) % (2 * Math.PI);
        state.shift = Math.cos(state.phase);
      } else if (!preference.matches) {
        state.shift += ((state.stage > 0 ? 1 : 0) - state.shift) * (1 - Math.exp(-dt * 7));
      }
      draw();
    }
    requestAnimationFrame(frame);
  }
  new ResizeObserver(fitCanvas).observe(canvas);
  window.addEventListener('resize', fitCanvas);
  document.addEventListener('visibilitychange', () => { state.lastTime = null; });
  if (!ctx) canvas.hidden = true;
  setLanguage(initialLanguage()); requestAnimationFrame(frame);
})();
