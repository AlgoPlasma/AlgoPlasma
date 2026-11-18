/* A specified warm-electron fluid branch, not a kinetic plasma solver.
 * Physical model and plotting conversions: docs/author_notes/plasma_waves_dispersion.md. */
(() => {
  'use strict';
  const W0 = 1e8, U = 1e6, K0 = W0 / U, LENGTH = .4, AMPLITUDE = .18;
  const frequency = k => Math.sqrt(W0 * W0 + U * U * k * k);
  const wave = k => ({ a: AMPLITUDE, k: k / K0, w: frequency(k) / W0 });
  const values = k => ({ k, omega: frequency(k), wavelength: 2 * Math.PI / k,
    period: 2 * Math.PI / frequency(k), phaseSpeed: frequency(k) / k });
  function chartGeometry(width, height) {
    return { left: width < 400 ? 57 : 80, right: width - 24, top: 66, bottom: height - 72 };
  }
  function renderChart(a) {
    if (!a.text || a.s.stage === 0) return;
    const svg = a.$('dispersion-chart'), t = a.text, v = values(a.s.data.k);
    const width = svg.clientWidth, height = svg.clientHeight;
    if (!width || !height) return;
    const g = chartGeometry(width, height), sx = k => g.left + k / 100 * (g.right - g.left);
    const sy = omega => g.bottom - omega / (1.5 * W0) * (g.bottom - g.top);
    const ns = 'http://www.w3.org/2000/svg';
    svg.setAttribute('viewBox', `0 0 ${width} ${height}`); svg.replaceChildren();
    const add = (tag, attrs, content) => {
      const node = document.createElementNS(ns, tag);
      for (const [name, value] of Object.entries(attrs)) node.setAttribute(name, String(value));
      if (content !== undefined) node.textContent = content;
      svg.append(node); return node;
    };
    const line = (x1, y1, x2, y2, className) => add('line', { x1, y1, x2, y2, class: className });
    const label = (text, x, y, anchor = 'middle', className = '') => add('text', { x, y, 'text-anchor': anchor, class: className }, text);
    line(g.left, g.bottom, g.right + 8, g.bottom, 'chart-axis');
    line(g.left, g.bottom, g.left, g.top - 10, 'chart-axis');
    label('ω [rad/s]', g.left, 27, 'start');
    label('k [rad/m]', g.right, height - 12, 'end');
    for (const k of [0, 40, 80]) {
      line(sx(k), g.bottom, sx(k), g.bottom + 7, 'chart-axis');
      label(String(k), sx(k), g.bottom + 33);
    }
    line(g.left - 7, sy(W0), g.right, sy(W0), 'chart-grid');
    label('10⁸', g.left - 12, sy(W0) + 8, 'end');
    if (a.s.stage >= 2) {
      const points = Array.from({ length: 101 }, (_, k) => `${sx(k)},${sy(frequency(k))}`).join(' ');
      add('polyline', { points, class: 'dispersion-curve' });
      for (const k of [20, 50, 80]) add('circle', { cx: sx(k), cy: sy(frequency(k)), r: 5, class: 'curve-sample' });
    }
    if (a.s.stage === 4) {
      line(g.left, g.bottom, sx(v.k), sy(v.omega), 'phase-ray');
    }
    line(sx(v.k), g.bottom, sx(v.k), sy(v.omega), 'point-guide');
    line(g.left, sy(v.omega), sx(v.k), sy(v.omega), 'point-guide');
    add('circle', { cx: sx(v.k), cy: sy(v.omega), r: 8, class: 'selected-mode' });
    label('P', sx(v.k) + 13, sy(v.omega) - 16, 'start', 'point-name');
    svg.setAttribute('aria-label', `${t.chartDescription} k = ${v.k} rad/m; ω = ${(v.omega / W0).toFixed(3)} × 10⁸ rad/s.`);
  }
  const translations = {
    zh: {
      documentTitle: '色散关系：波长与频率怎样搭配？', title: '波长变了，<span>频率怎样变？</span>', chapter: '07 / 色散关系与读图',
      pause: '暂停动画', play: '播放动画', back: '上一步', returnLabel: '返回等离子体波课堂', progress: '讲解步骤',
      keyboard: '点击点阵或按 → 继续 · F 全屏', fullscreenFailed: '当前预览不允许全屏，请在独立浏览器中打开。',
      model: '温电子流体波示例；无磁场、离子固定，忽略阻尼。点阵按 n₀ 缩放，幅值放大，时间统一减速。',
      steps: [
        '同一种等离子体波，波长和频率可以任意搭配吗？',
        '横轴是波数，纵轴是角频率。一个点，对应一组 k 和 ω。',
        '曲线给出这个模型允许的配对。拖动 k，或点击图中的曲线。',
        '选中一个点，就能读出波长和周期。比较不同的 k，会怎样变化？',
        '把原点连到选中的点：纵坐标除以横坐标，就是相速度。'
      ],
      actions: ['画出参数坐标', '哪些配对被允许？', '读出波长和周期', '从图上读相速度', '重新读一遍'],
      equations: ['', 'k [rad/m]　↔　ω [rad/s]', 'ω = ω(k) <small>给定模型的一条自由波分支；曲线不是粒子的运动轨迹</small>',
        'λ = 2π / k　　T = 2π / ω <small>波长 λ [m]；周期 T [s]；ω 是角频率</small>',
        'v<sub>ph</sub> = ω / k = λ / T <small>相速度 [m/s]：原点连线的斜率，不是该点切线的斜率</small>'],
      descriptions: [
        '绿色点阵表示一列向右传播的电子密度波。波长和振荡频率由同一个给定的温电子流体波模型决定，不是两个独立的自由调节量。',
        '色散图横轴是k，单位rad/m；纵轴是ω，单位rad/s，不是位置和时间。金色点P的两条虚线投影给出它的波数和角频率。右侧仍是这个波的电子密度图样。',
        '绿色曲线是给定流体模型的一条正频率分支ω(k)。同一曲线上的点对应不同的波分量，不是同一粒子或同一波随时间走过的轨迹。用滑块或点击图选择k，ω随模型确定；图外点不是这个分支的自由波解。',
        '由所选点计算λ=2π/k和T=2π/ω。点阵下面的括号标出一个波长，固定在x=0的探针曲线给出随时间的密度扰动。横向观察窗始终为0.4m，时间窗始终为8×10⁻⁸s，因此可以直接比较不同波。此分支k越大，波长越短，角频率越大，周期越短。',
        '金色直线连接坐标原点和选中的P点。它的斜率是ω/k，单位m/s，等于密度波峰的相速度λ/T；它不是粒子速度，也不是色散曲线在P点的切线斜率。点阵上的金色标记追踪一个密度峰，经过一个波长后重新标记下一峰。'
      ],
      takeaway: '<span class="mint">一个点：一组 k 与 ω。</span> <span class="gold">原点连线：相速度。</span>',
      chartTitle: '色散图 · 参数之间的关系', chartDescription: '色散图：横轴k [rad/m]，纵轴ω [rad/s]。金色点是当前所选的波。',
      waveTitle: '电子密度波 · 向右传播', probe: '固定探针 x = 0', normalizedDensity: 'δn / n₀',
      selection: '选择波数 k',
      slopeNote: '原点连线的斜率；它不是曲线在该点的切线斜率',
      compare: '拖动是在比较不同的波；它不是一个波随时间改变 k。',
      detailsTitle: '这条示例曲线采用什么模型？',
      details: '<p>本页先给定一条温电子流体波曲线，练习读图，推导留到后续页面。</p><p class="model-equation">ω² = ω₀² + u²k²</p><p>ω₀ = 10⁸ rad/s，是 k → 0 时的电子振荡角频率；u = 10⁶ m/s，是电子压强项对应的速度参数，并不是单个电子的速度。</p><p>模型采用一维电子压强闭合：u² = 3k<sub>B</sub>Tₑ/mₑ；k<sub>B</sub> 是玻尔兹曼常量 [J/K]，Tₑ 是电子温度 [K]，mₑ 是电子质量 [kg]。均匀、无磁场、固定离子背景；只画 k ≥ 0、ω > 0 的分支。</p><p>这是给定参数的线性流体示例，不是实验数据或完整动理学计算；忽略碰撞与 Landau 阻尼。点阵不绘制随机热运动，温度通过曲线中的压强项体现。δn/n₀ 的幅值放大至 0.18；动画每秒对应 3×10⁻⁸ s，所有 k 使用相同减速比例。</p><p>模型参考：<a href="https://silas.psfc.mit.edu/introplasma/master.pdf" target="_blank" rel="noopener">MIT · Introduction to Plasma Physics</a>。相速度读图：<a href="https://bpb-us-e1.wpmucdn.com/sites.harvard.edu/dist/0/550/files/2023/11/waves_dispersion.pdf" target="_blank" rel="noopener">Harvard · Dispersion</a>。</p>'
    },
    en: {
      documentTitle: 'Dispersion: how do wavelength and frequency pair?', title: 'Change wavelength. <span>What happens to frequency?</span>', chapter: '07 / Reading a dispersion relation',
      pause: 'Pause', play: 'Play', back: 'Previous step', returnLabel: 'Return to the plasma waves course', progress: 'Explanation step',
      keyboard: 'Click the dots or press → · F fullscreen', fullscreenFailed: 'Fullscreen is unavailable here. Open a separate browser tab.',
      model: 'Warm-electron fluid example; no magnetic field, fixed ions, no damping. Dots scaled by n₀; amplitude enlarged; time uniformly slowed.',
      steps: ['For one type of plasma wave, can wavelength and frequency be chosen independently?',
        'Wavenumber on the horizontal axis; angular frequency on the vertical. One point is one pair.',
        'The curve gives the pairs allowed by this model. Slide k, or click the curve.',
        'Read wavelength and period from the selected point. What changes as k increases?',
        'Join the origin to the selected point. Its rise divided by its run is the phase speed.'],
      actions: ['Draw the parameter axes', 'Which pairs are allowed?', 'Read wavelength and period', 'Read the phase speed', 'Read it again'],
      equations: ['', 'k [rad/m]　↔　ω [rad/s]', 'ω = ω(k) <small>One free-wave branch of the chosen model; not a particle trajectory</small>',
        'λ = 2π / k　　T = 2π / ω <small>Wavelength λ [m]; period T [s]; ω is angular frequency</small>',
        'v<sub>ph</sub> = ω / k = λ / T <small>Phase speed [m/s]: the origin-to-point slope, not the tangent slope</small>'],
      descriptions: [
        'Green dots represent a rightward electron-density wave. Wavelength and oscillation frequency follow one specified warm-electron fluid model, rather than two independent controls.',
        'The horizontal axis is k in rad/m; the vertical axis is ω in rad/s, not position and time. Dashed projections of the gold point P mark its wavenumber and angular frequency. The right panel still shows the density pattern of this wave.',
        'The green curve is one positive-frequency branch ω(k) of a specified fluid model. Its points represent different wave components, not a particle trajectory or the time history of one wave. Select k using the slider or the graph; the model sets ω. Off-curve points are not free-wave solutions of this branch.',
        'Compute λ=2π/k and T=2π/ω from the selected point. A bracket below the dots marks one wavelength; the trace shows the density perturbation at the fixed probe x=0. The spatial window stays 0.4m and the time window stays 8×10⁻⁸s for comparisons. On this branch, increasing k shortens wavelength, raises angular frequency and shortens period.',
        'The gold line joins the origin to P. Its slope is ω/k in m/s, equal to the crest phase speed λ/T. This is neither particle velocity nor the tangent slope at P. A gold marker follows a density crest and selects the next crest after one wavelength.'
      ],
      takeaway: '<span class="mint">One point: one k–ω pair.</span> <span class="gold">Origin-to-point slope: phase speed.</span>',
      chartTitle: 'Dispersion · parameter space', chartDescription: 'Dispersion plot: horizontal k [rad/m], vertical ω [rad/s]. The gold point is the selected wave.',
      waveTitle: 'Electron density wave · rightward', probe: 'Fixed probe x = 0', normalizedDensity: 'δn / n₀',
      selection: 'Select wavenumber k',
      slopeNote: 'The origin-to-point slope, not the tangent slope at that point',
      compare: 'Sliding compares different waves; it does not show one wave changing k over time.',
      detailsTitle: 'Which model supplies this example curve?',
      details: '<p>We prescribe a warm-electron fluid branch to practice reading a dispersion plot. Its derivation comes later.</p><p class="model-equation">ω² = ω₀² + u²k²</p><p>ω₀ = 10⁸ rad/s is the electron oscillation frequency as k → 0. The pressure speed parameter u = 10⁶ m/s is not the speed of an individual electron.</p><p>The one-dimensional pressure closure uses u² = 3k<sub>B</sub>Tₑ/mₑ, where k<sub>B</sub> is Boltzmann’s constant [J/K], Tₑ electron temperature [K], and mₑ electron mass [kg]. The background is uniform and unmagnetized, with fixed ions. Only k ≥ 0 and ω > 0 are plotted.</p><p>This specified linear fluid example is not experimental data or a full kinetic calculation. Collisions and Landau damping are omitted. Random thermal particle motion is not drawn; pressure enters through the curve. The δn/n₀ amplitude is enlarged to 0.18. Each playback second represents 3×10⁻⁸s, using the same time scale for every k.</p><p>Model reference: <a href="https://silas.psfc.mit.edu/introplasma/master.pdf" target="_blank" rel="noopener">MIT · Introduction to Plasma Physics</a>. Phase-speed geometry: <a href="https://bpb-us-e1.wpmucdn.com/sites.harvard.edu/dist/0/550/files/2023/11/waves_dispersion.pdf" target="_blank" rel="noopener">Harvard · Dispersion</a>.</p>'
    }
  };
  PlasmaLesson.start({
    translations, running: () => true, rate: () => 3,
    setup(a) {
      a.s.data.k = 40;
      const choose = k => { a.s.data.k = Math.max(20, Math.min(80, Math.round(k))); a.s.time = 0; a.render(); };
      a.$('wavenumber').addEventListener('input', e => choose(Number(e.target.value)));
      a.$('dispersion-chart').addEventListener('click', e => {
        if (a.s.stage < 2) return;
        const rect = e.currentTarget.getBoundingClientRect(), g = chartGeometry(rect.width, rect.height);
        const x = e.clientX - rect.left, y = e.clientY - rect.top;
        if (x >= g.left && x <= g.right && y >= g.top && y <= g.bottom) choose((x - g.left) / (g.right - g.left) * 100);
      });
      new ResizeObserver(() => renderChart(a)).observe(a.$('dispersion-chart'));
    },
    onStage(s) { if (s.stage === 0) { s.data.k = 40; s.time = 0; } },
    update(a) {
      const { $, s, text: t } = a, v = values(s.data.k);
      $('chart-pane').hidden = s.stage === 0;
      $('chart-heading').textContent = t.chartTitle;
      $('interaction').hidden = s.stage < 2;
      $('wavenumber-label').textContent = t.selection;
      $('wavenumber').value = String(v.k);
      $('wavenumber').setAttribute('aria-valuetext', `k = ${v.k} rad/m; ω = ${(v.omega / W0).toFixed(3)} × 10⁸ rad/s`);
      $('wavenumber-output').textContent = `${v.k} rad/m; ω = ${(v.omega / W0).toFixed(3)} × 10⁸ rad/s`;
      $('comparison-note').textContent = t.compare;
      $('comparison-note').hidden = s.stage !== 2;
      if (s.stage === 1) $('equation').innerHTML = `k = ${v.k} rad/m　 ω = ${(v.omega / W0).toFixed(3)} × 10⁸ rad/s`;
      if (s.stage === 3) $('equation').innerHTML = `<span class="reading-formula">λ = 2π/k = ${v.wavelength.toFixed(3)} m</span> <span class="reading-formula">T = 2π/ω = ${(v.period * 1e8).toFixed(2)} × 10⁻⁸ s</span>`;
      if (s.stage === 4) $('equation').innerHTML = `v<sub>ph</sub> = ω/k = ${(v.phaseSpeed / 1e6).toFixed(3)} × 10⁶ m/s <small>${t.slopeNote}</small>`;
      $('model-details').hidden = s.stage < 2;
      $('model-summary').textContent = t.detailsTitle;
      $('model-description').innerHTML = t.details;
      if (s.stage === 0) $('model-details').open = false;
      renderChart(a);
    },
    draw(a) {
      const { s, text: t, colors: c, label, line, grid, bracket, curve, dot, arrow } = a;
      const w = s.width, h = s.height, left = 28, right = w - 18, waves = [wave(s.data.k)];
      const scaledLength = LENGTH * K0, v = values(s.data.k);
      label(t.waveTitle, left, 25, c.muted, 26, 'left');
      if (s.stage < 3) {
        const top = 90, bottom = h - 85;
        grid(waves, s.time, left, right, top, bottom, scaledLength, { columns: Math.max(28, Math.floor((right - left) / (w < 650 ? 8 : 12))), rows: 5 });
        arrow(w * .42, h - 35, w * .60, c.mint); return;
      }
      grid(waves, s.time, left, right, 78, 175, scaledLength, { columns: Math.max(28, Math.floor((right - left) / (w < 650 ? 8 : 12))), rows: 4 });
      line(left, 67, left, 184, c.gold, 2);
      label('0', left, 202, c.muted, 22);
      label('x = 0.4 m', right, 202, c.muted, 22, 'right');
      bracket(left, left + v.wavelength / LENGTH * (right - left), 230, 'λ [m]', c.mint);
      const narrow = w < 480;
      label(t.probe, left, narrow ? 280 : 291, c.gold, 25, 'left');
      const y = narrow ? 365 : 350, amplitude = 30, timeWindow = 8;
      line(left, y, right, y);
      curve(u => Math.cos(-waves[0].w * u * timeWindow), left, right, y, amplitude, c.mint);
      // Replay the marker within one period, so it always matches the live probe.
      const cursor = a.mod(s.time, v.period * W0);
      dot(left + cursor / timeWindow * (right - left), y - amplitude * Math.cos(waves[0].w * cursor), 5, c.gold);
      label(t.normalizedDensity, right, narrow ? 312 : 291, c.muted, 22, 'right');
      label('T', left + (v.period * W0) / timeWindow * (right - left), y + 45, c.mint, 26);
      label('t [s]', right, y + 80, c.muted, 24, 'right');
      label('0', left, y + 45, c.muted, 22);
      if (s.stage === 4) {
        const crest = a.mod(waves[0].w * s.time / waves[0].k, 2 * Math.PI / waves[0].k);
        const cx = left + crest / scaledLength * (right - left);
        line(cx, 73, cx, 180, '#f4c58399', 2, [5, 5]); dot(cx, 126, 7, c.gold);
      }
    }
  });
})();
