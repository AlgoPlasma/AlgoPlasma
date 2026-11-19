/* Shared presentation controls and prescribed-density kinematics for the course.
 * Not a plasma solver. See docs/author_notes/plasma_waves_measurements.md. */
(() => {
  'use strict';
  const TAU = 2 * Math.PI;
  const colors = { mint: '#b5efcf', gold: '#f4c583', blue: '#b4cefa', muted: '#e0ebe6', line: '#30413f' };
  const mod = (x, n) => ((x % n) + n) % n;
  // q = x + sum(a/k sin(kx - wt + phi)). Then dq/dx = n/n0 exactly.
  // Inverting this monotone map makes dot spacing agree with the Eulerian curve.
  const density = (x, t, waves) => waves.reduce((n, v) => n + v.a * Math.cos(v.k * x - v.w * t + (v.phi || 0)), 1);
  function position(q, t, waves) {
    let x = q;
    for (let i = 0; i < 7; i++) {
      const residual = waves.reduce((f, v) => f + v.a / v.k * Math.sin(v.k * x - v.w * t + (v.phi || 0)), x - q);
      x -= residual / density(x, t, waves);
    }
    return x;
  }
  const models = new Map();
  function register(name, model) { models.set(name, model); }
  function start() {
    const $ = id => document.getElementById(id);
    const canvas = $('plasma'), ctx = canvas.getContext('2d');
    const preference = matchMedia('(prefers-reduced-motion: reduce)');
    const s = { stage: 0, time: 0, paused: preference.matches, width: 0, height: 0, data: {} };
    let language = 'zh', text, lastTime = null, toastTimer, previousStage, previousLanguage;
    const api = { $, s, ctx, colors, TAU, mod, density, position, line, dot, label, arrow, bracket, curve, grid,
      get reading() { return deck.reading; }, get text() { return text; }, get language() { return language; }, render, draw };
    const deck = WaveSlides.create(setStage);
    let config = models.get(deck.model);
    function line(x1, y1, x2, y2, color = colors.line, width = 1, dash = []) {
      ctx.beginPath(); ctx.strokeStyle = color; ctx.lineWidth = width; ctx.setLineDash(dash);
      ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke(); ctx.setLineDash([]);
    }
    function dot(x, y, r, color = colors.mint) {
      ctx.beginPath(); ctx.fillStyle = color; ctx.arc(x, y, r, 0, TAU); ctx.fill();
    }
    function label(value, x, y, color = colors.muted, size = 23, align = 'center') {
      PlasmaText.label(ctx, value, x, y, color, size, align);
    }
    function arrow(x1, y, x2, color = colors.gold) {
      line(x1, y, x2, y, color, 2);
      const d = Math.sign(x2 - x1);
      if (Math.abs(x2 - x1) > 5) { line(x2 - d * 8, y - 5, x2, y, color, 2); line(x2 - d * 8, y + 5, x2, y, color, 2); }
    }
    function bracket(x1, x2, y, value, color = colors.gold) {
      line(x1, y, x2, y, color, 1.8); line(x1, y - 5, x1, y + 5, color, 1.8); line(x2, y - 5, x2, y + 5, color, 1.8);
      label(value, (x1 + x2) / 2, y + 22, color, s.width < 650 ? 20 : 27);
    }
    function curve(fn, left, right, y, scale, color = colors.mint, width = 2.5, dash = []) {
      ctx.beginPath(); ctx.strokeStyle = color; ctx.lineWidth = width; ctx.setLineDash(dash);
      for (let i = 0; i <= 360; i++) {
        const u = i / 360, px = left + u * (right - left), py = y - scale * fn(u);
        if (!i) ctx.moveTo(px, py); else ctx.lineTo(px, py);
      }
      ctx.stroke(); ctx.setLineDash([]);
    }
    function grid(waves, t, left, right, top, bottom, length = 2.5, sampling = {}) {
      const columns = sampling.columns || (s.width < 650 ? 35 : 81), rows = sampling.rows || (s.width < 650 ? 4 : 5);
      const scale = (right - left) / length;
      ctx.save(); ctx.beginPath(); ctx.rect(left - 1, top - 10, right - left + 2, bottom - top + 20); ctx.clip();
      for (let row = 0; row < rows; row++) for (let col = -5; col <= columns + 5; col++) {
        const q = col * length / columns, x = position(q, t, waves), y = top + row * (bottom - top) / (rows - 1);
        dot(left + x * scale, y, s.width < 650 ? 2.5 : 3.7);
      }
      ctx.restore();
    }
    function motion() {
      $('motion').hidden = !config.running(s) || $('scene').hidden || !ctx;
      $('motion').textContent = s.paused ? text.play : text.pause;
      $('motion').setAttribute('aria-pressed', String(s.paused));
    }
    function translateModel() {
      text = config.translations[language];
      document.title = text.chapter + ' | AlgoPlasma';
      $('chapter').textContent = text.chapter;
      $('model-note').textContent = text.model;
      if ($('electron-name')) {
        $('electron-name').textContent = text.electron;
        $('ion-name').textContent = text.ion;
        $('scene-prompt').textContent = text.prompt || '';
      }
    }
    function setLanguage(value) {
      language = value === 'en' ? 'en' : 'zh';
      translateModel();
      document.documentElement.lang = language === 'en' ? 'en' : 'zh-CN';
      $('return-link').setAttribute('aria-label', text.returnLabel); $('back').setAttribute('aria-label', text.back);
      window.PlasmaNavigation?.setLanguage(language);
      $('language-switch').setAttribute('aria-label', language === 'en' ? 'Choose language' : '选择语言');
      document.querySelectorAll('[data-language]').forEach(b => b.setAttribute('aria-pressed', String(b.dataset.language === language)));
      try { localStorage.setItem('ap-doc-language', language); } catch (_) { /* Optional preference. */ }
      try { const url = new URL(location.href); url.searchParams.set('lang', language); history.replaceState(null, '', url); } catch (_) { /* file preview. */ }
      $('toast').hidden = true; render();
    }
    function render() {
      const equation = $('equation'), previousEquation = equation.innerHTML;
      const formula = text.equations?.[s.stage] || '';
      const newContent = previousStage !== s.stage || previousLanguage !== language;
      const interactionWasHidden = $('interaction')?.hidden;
      $('lesson').dataset.stage = String(s.stage);
      if (newContent) equation.innerHTML = formula;
      equation.hidden = !formula;
      $('takeaway').hidden = s.stage !== text.steps.length - 1 || !deck.finalBuild;
      if ($('takeaway-text').innerHTML !== text.takeaway) $('takeaway-text').innerHTML = text.takeaway;
      canvas.setAttribute('aria-label', text.descriptions[s.stage]); canvas.textContent = text.descriptions[s.stage];
      if (!ctx) $('canvas-fallback').textContent = text.descriptions[s.stage];
      config.update?.(api);
      deck.render(text, language);
      if (newContent && equation.innerHTML !== previousEquation && !equation.hidden) WaveSlides.fade(equation);
      if (interactionWasHidden && !$('interaction').hidden) WaveSlides.fade($('interaction'));
      previousStage = s.stage; previousLanguage = language;
      motion(); fit();
    }
    function setStage(value, reset = false) {
      const old = s.stage;
      const nextModel = models.get(deck.model);
      const changedModel = config !== nextModel;
      config = nextModel;
      s.stage = value;
      if (changedModel) {
        previousStage = undefined;
        translateModel();
        if ($('interaction')) $('interaction').hidden = true;
      }
      if (reset || changedModel) {
        s.data = structuredClone(defaults);
        s.time = 0; s.paused = preference.matches; lastTime = null;
      }
      if (reset || changedModel || old !== value) config.onStage?.(s, changedModel ? -1 : old, reset || changedModel);
      render();
    }
    function toggle() { if (!$('motion').hidden) { s.paused = !s.paused; motion(); } }
    async function fullscreen() {
      try { if (document.fullscreenElement) await document.exitFullscreen(); else await document.documentElement.requestFullscreen(); }
      catch (_) { $('toast').textContent = text.fullscreenFailed; $('toast').hidden = false; clearTimeout(toastTimer); toastTimer = setTimeout(() => { $('toast').hidden = true; }, 4000); }
    }
    function fit() {
      const rect = canvas.getBoundingClientRect(), dpr = Math.min(devicePixelRatio || 1, 2);
      if (!rect.width || !rect.height) return;
      s.width = rect.width; s.height = rect.height;
      const width = Math.round(rect.width * dpr), height = Math.round(rect.height * dpr);
      if (canvas.width !== width) canvas.width = width;
      if (canvas.height !== height) canvas.height = height;
      ctx?.setTransform(dpr, 0, 0, dpr, 0, 0); draw();
    }
    function draw() {
      if (!ctx || !text || !s.width || !s.height) return;
      ctx.clearRect(0, 0, s.width, s.height); config.draw(api);
    }
    function frame(now) {
      const dt = lastTime === null ? 0 : Math.min((now - lastTime) / 1000, .05); lastTime = now;
      if (!document.hidden && config.frame) {
        config.frame(s, dt);
        draw();
      } else if (!document.hidden && !s.paused && !$('scene').hidden && config.running(s)) {
        s.time += dt * (config.rate?.(s) || .15); draw();
      }
      requestAnimationFrame(frame);
    }
    for (const model of models.values()) model.setup?.(api);
    const defaults = structuredClone(s.data);
    $('motion').addEventListener('click', toggle);
    document.querySelectorAll('[data-language]').forEach(b => b.addEventListener('click', () => setLanguage(b.dataset.language)));
    document.addEventListener('keydown', e => {
      if (e.altKey || e.ctrlKey || e.metaKey || e.shiftKey || e.repeat || e.target.closest('input,textarea,select,[contenteditable]')) return;
      if (e.key === ' ' && e.target.closest('button,a')) return;
      if (e.key.toLowerCase() === 'p') { e.preventDefault(); toggle(); }
      if (e.key.toLowerCase() === 'f') { e.preventDefault(); fullscreen(); }
    });
    preference.addEventListener('change', e => { s.paused = e.matches; motion(); draw(); });
    document.addEventListener('visibilitychange', () => { lastTime = null; });
    window.addEventListener('resize', fit); new ResizeObserver(fit).observe(canvas);
    let initial = new URLSearchParams(location.search).get('lang');
    if (!['zh', 'en'].includes(initial)) { try { initial = localStorage.getItem('ap-doc-language'); } catch (_) { /* Optional preference. */ } }
    if (!ctx) { canvas.hidden = true; $('canvas-fallback').hidden = false; }
    s.stage = deck.initialStage;
    config.onStage?.(s, -1, true);
    setLanguage(initial); requestAnimationFrame(frame);
  }
  window.PlasmaLesson = { register, density, position };
  document.addEventListener('DOMContentLoaded', start, { once: true });
})();

/* Plasma-wave contribution history (Git author dates; edit time includes timezone).
 * 2026-11-17 20:09 +08:00 | Yinjian Zhao | git c97a40fba286
 * 2026-11-17 20:26 +08:00 | Yinjian Zhao | git 80d9ffd0c710
 * 2026-11-17 21:23 +08:00 | Yinjian Zhao | git 789e519340b7
 * 2026-11-18 08:16 +08:00 | Yinjian Zhao | git 45f247468130
 * 2026-11-18 15:11 +08:00 | Yinjian Zhao | git 8e431a343dc7
 * 2026-11-19 15:22 +08:00 | Yinjian Zhao | git b32e8af2bb2b
 * 2026-11-19 16:01 +08:00 | Yinjian Zhao | git 2113cbc05ed4
 * 2026-11-19 16:28 +08:00 | Yinjian Zhao | edit (Codex-assisted)
 */
