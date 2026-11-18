(() => {
  'use strict';
  const M = PlasmaPacketModel, gold = '#f4c583', blue = '#b4cefa';
  const speed = value => `${(value / 1e6).toFixed(3)} × 10⁶ m/s`;
  const texts = {
    zh: {
      documentTitle: '波包、相速度与群速度', title: '一群波，<span>谁在向前走？</span>', chapter: '08 / 波包、相速度与群速度',
      pause: '暂停动画', play: '播放动画', back: '上一步', returnLabel: '返回等离子体波课堂', progress: '讲解步骤',
      keyboard: '点击点阵或按 → 继续 · F 全屏', fullscreenFailed: '当前预览不允许全屏，请在独立浏览器中打开。',
      model: '窄带温电子流体示例；无磁场、离子固定，忽略阻尼。点阵示意合成密度，时间减速并循环。',
      comparisonModel: '数学对照 ω = Vk；保留相同波数、幅值和初相位。时间减速并循环。',
      steps: [
        '相近波数的分量叠加，让密度扰动集中在一段空间：波包。',
        '蓝色虚线勾勒波包的包络：它告诉我们哪里振荡强、哪里振荡弱。',
        '金点跟踪中心分量的一个等相位位置。相速度描述内部波峰的推进。',
        '蓝圈跟踪包络最强处。窄带、弱失真时，它的速度近似为群速度。',
        '在中心波数处：原点连线给相速度，切线给群速度。两种斜率对应两种运动。',
        '切换对照：当 ω 与 k 成正比，包络与内部波峰会一起移动。'
      ],
      actions: ['画出包络', '跟踪内部波峰', '跟踪包络中心', '回到色散图', '比较无色散情况', '重新读一遍'],
      equations: ['',
        'δn = ∑ⱼ Aⱼ cos(kⱼx − ωⱼt)<small>31 个相近分量；中心波数 k<sub>c</sub> = 60 rad/m；δn、Aⱼ [m⁻³]</small>',
        'v<sub>ph</sub> = ω<sub>c</sub> / k<sub>c</sub>',
        'v<sub>g</sub> = (dω/dk)<sub>c</sub>',
        'v<sub>ph</sub> = ω<sub>c</sub>/k<sub>c</sub>　v<sub>g</sub> = (dω/dk)<sub>c</sub>',
        'ω = Vk　⇒　v<sub>ph</sub> = v<sub>g</sub> = V'],
      descriptions: [
        '31个相近波数的电子密度波叠加成一个局部增强的波包。上方曲线是相对密度扰动δn/n₀，下方是同一组电子的密度点阵。横轴x为米，观察窗为−0.5到0.9m。初始暂停；可以播放动画。',
        '在总密度波外画出正负包络。蓝色虚线的高度来自同一复数叠加的模，刻画振荡强弱；它不是另一组电子或另一种密度。',
        '金点位于中心分量的恒定相位k_c x−ω_c t=0，随x=vph t移动。它近似跟随波包中的一个波峰；它不是被标记的电子。可播放或拖动时间比较位置。',
        '蓝圈定位实际计算的包络最大值；金点仍跟踪中心分量相位。此窄带例子中蓝圈移动更慢，内部波峰穿过包络并逐渐减弱。群速度是中心波数处dω/dk，近似包络速度，不是电子速度。',
        '色散图横轴k [rad/m]、纵轴ω [rad/s]，淡色带表示所取分量42至78 rad/m。中心点k_c=60 rad/m。金色原点连线斜率是相速度；蓝色虚线是切线，其斜率是群速度。右侧仍用各分量的实际色散频率计算波包。',
        '无色散对照采用过原点的直线ω=Vk，V取原模型中心相速度。保持同一组波数、幅值和初相位，所有分量以V传播，波包形状精确平移，金点与蓝圈同步。取消对照即可在同一时刻比较温电子流体分支。'
      ],
      takeaway: '<span class="gold">相速度：跟相位。</span> <span style="color:#b4cefa">群速度：窄带包络。</span> 两者都不是电子速度。',
      envelopeKey: '蓝色虚线：包络', phaseKey: '金点：中心分量相位', groupKey: '蓝圈：包络中心',
      dotsTitle: '同一组电子', slopeTitle: '原点连线与切线', timeLabel: '观察时间 t',
      compare: '无色散对照：ω = Vk', chartDescription: '色散图，横轴k [rad/m]，纵轴ω [rad/s]。金色原点连线给相速度，蓝色切线给群速度。',
      groupNote: '邻近分量：Δω/Δk → dω/dk；窄带包络速度 ≈ v<sub>g</sub>',
      phaseNote: 'k<sub>c</sub> = 60 rad/m；ω<sub>c</sub> = 1.166 × 10⁸ rad/s；金点不是电子',
      derivationTitle: '为什么群速度是 dω/dk？',
      derivation: '<p>先用两个等幅、相近波数的分量说明。令 Δk = k₂ − k₁ [rad/m]，Δω = ω₂ − ω₁ [rad/s]；k̄ = (k₁+k₂)/2，ω̄ = (ω₁+ω₂)/2。</p><p class="math">δn = A cos(k₁x−ω₁t) + A cos(k₂x−ω₂t)</p><p>用和差化积，把快速振荡与缓慢调制分开：</p><p class="math">δn = 2A cos[(Δk x−Δω t)/2] cos(k̄x−ω̄t)</p><p>A [m⁻³]；x [m]；t [s]。第一项是缓慢变化的调制，第二项是内部快速振荡。跟踪调制的固定相位：</p><p class="math">Δk x − Δω t = 常数<br>Δk dx/dt − Δω = 0<br>dx/dt = Δω/Δk</p><p>两个波数趋近中心 k<sub>c</sub>，割线斜率趋于切线斜率：</p><p class="math">v<sub>g</sub> = lim<sub>Δk→0</sub> Δω/Δk = (dω/dk)<sub>c</sub> [m/s]</p><p>两个分量形成周期性的拍包络；许多邻近分量适当加权，才形成本页这样的局部波包。相速度则由 k̄x−ω̄t = 常数得到 ω̄/k̄，在窄带极限趋于 ω<sub>c</sub>/k<sub>c</sub>。</p>',
      detailsTitle: '波包怎样生成？近似在哪里？',
      details: '<p>沿用 07 页的温电子流体模型：ω(k) = √(ω₀²+u²k²)，ω₀=10⁸ rad/s，u=10⁶ m/s。均匀、无磁场、离子固定，忽略碰撞和 Landau 阻尼；温度通过电子压强项体现。</p><p class="math">2ω dω/dk = 2u²k<br>v<sub>g</sub> = u²k<sub>c</sub>/ω<sub>c</sub></p><p>取31个波数 kⱼ=42+1.2j rad/m（j=0,…,30），以 k<sub>c</sub>=60 rad/m 为中心。权重 wⱼ=exp[−(kⱼ−k<sub>c</sub>)²/(2σₖ²)]，σₖ=6 rad/m；Aⱼ/n₀=0.18 wⱼ/∑wⱼ，初相位均为0 rad。n₀、Aⱼ、δn 的单位为 m⁻³，因此 |δn/n₀|≤0.18，密度始终为正。离散谱的空间重复间距约5.24 m，本页观察窗中只显示一个波包。</p><p>每个分量使用实际的 ω(kⱼ) 演化。白线是 ∑(Aⱼ/n₀)cos(kⱼx−ωⱼt)，蓝色包络是复数和 ∑(Aⱼ/n₀)exp[i(kⱼx−ωⱼt)] 的模。蓝圈定位这个包络的实际最大值；金点跟踪中心分量的相位 x=(ω<sub>c</sub>/k<sub>c</sub>)t。窄带下金点近似跟随一个内部波峰。</p><p>对中心附近作一阶展开，ω(k)≈ω<sub>c</sub>+v<sub>g</sub>(k−k<sub>c</sub>)，可得“以 v<sub>g</sub> 移动的缓慢包络 × 内部载波”。本页直接叠加完整频率，保留轻微失真；包络速度与 (dω/dk)꜀ 的对应是窄带近似。更宽频带或更长传播时间可能出现展宽，不能套用刚性包络。本例 v<sub>g</sub>&lt;vph，不代表所有色散关系都如此；这里也不将群速度无条件等同于能量或信息速度。</p><p>无色散对照改用 ω=Vk，V=ω<sub>c</sub>/k<sub>c</sub>≈1.944×10⁶ m/s。这是数学对照，不是另一条等离子体模型。频带、幅值、初相位、空间窗和时间比例保持不变。</p><p>动画每秒对应3×10⁻⁸ s；从0到2×10⁻⁷ s循环回放。拖动时间会暂停。点阵根据合成密度作守恒的运动学映射，不求解粒子受力，也不绘制随机热运动。</p><p>读图与群速度推导参考：<a href="https://bpb-us-e1.wpmucdn.com/sites.harvard.edu/dist/0/550/files/2023/11/waves_dispersion.pdf" target="_blank" rel="noopener">David Morin · Dispersion，§6.3</a>。温电子流体背景：<a href="https://silas.psfc.mit.edu/introplasma/master.pdf" target="_blank" rel="noopener">MIT · Introduction to Plasma Physics</a>。</p>'
    },
    en: {
      documentTitle: 'Wave packets, phase and group velocities', title: 'A group of waves. <span>What moves forward?</span>', chapter: '08 / Wave packets, phase and group velocities',
      pause: 'Pause', play: 'Play', back: 'Previous step', returnLabel: 'Return to the plasma waves course', progress: 'Explanation step',
      keyboard: 'Click the dots or press → · F fullscreen', fullscreenFailed: 'Fullscreen is unavailable here. Open a separate browser tab.',
      model: 'Narrow-band warm-electron fluid example; no magnetic field, fixed ions, no damping. Dots depict total density; time is slowed and looped.',
      comparisonModel: 'Mathematical comparison ω = Vk; same wavenumbers, amplitudes and initial phases. Time is slowed and looped.',
      steps: [
        'Nearby wavenumbers add up to a density disturbance concentrated in space: a wave packet.',
        'The blue dashed envelope shows where the oscillations are strong and where they are weak.',
        'The gold dot follows a constant phase of the central component. Phase speed tracks the inner crests.',
        'The blue ring follows the strongest part of the envelope. For a narrow band with little distortion, its speed is approximately the group speed.',
        'At the central wavenumber: the origin-to-point slope gives phase speed; the tangent gives group speed.',
        'Switch the comparison: when ω is proportional to k, the envelope and inner crests travel together.'
      ],
      actions: ['Show the envelope', 'Track an inner crest', 'Track the envelope', 'Read the dispersion plot', 'Compare no dispersion', 'Read it again'],
      equations: ['',
        'δn = ∑ⱼ Aⱼ cos(kⱼx − ωⱼt)<small>31 nearby components; central k<sub>c</sub> = 60 rad/m; δn, Aⱼ [m⁻³]</small>',
        'v<sub>ph</sub> = ω<sub>c</sub> / k<sub>c</sub>', 'v<sub>g</sub> = (dω/dk)<sub>c</sub>',
        'v<sub>ph</sub> = ω<sub>c</sub>/k<sub>c</sub>　v<sub>g</sub> = (dω/dk)<sub>c</sub>',
        'ω = Vk　⇒　v<sub>ph</sub> = v<sub>g</sub> = V'],
      descriptions: [
        '31 nearby wavenumbers form a localized electron-density packet. The upper curve is relative perturbation δn/n₀; below is one shared electron population. Horizontal x is in meters, from −0.5 to 0.9m. The animation starts paused and can be played.',
        'Blue dashed upper and lower envelopes surround the total density wave. Their magnitude comes from the modulus of the same complex superposition. The envelope is not another electron population or another density.',
        'The gold dot follows k_c x−ω_c t=0 at x=vph t. It approximately follows an inner crest of the narrow-band packet. It does not mark an electron. Play or scrub time to compare positions.',
        'The blue ring marks the computed envelope maximum while the gold dot follows the central phase. Here the ring travels more slowly; the inner crest passes through the envelope and fades. The derivative dω/dk at the central k is the group speed, approximately the envelope speed, not an electron velocity.',
        'The dispersion axes are k [rad/m] and ω [rad/s]. The shaded band spans the selected 42–78 rad/m; the central point is k_c=60 rad/m. The gold origin ray gives phase speed; the blue dashed tangent gives group speed. The packet still uses each component’s actual dispersion frequency.',
        'The nondispersive comparison uses a line through the origin, ω=Vk, with V equal to the original central phase speed. The same wavenumbers, amplitudes and initial phases now translate exactly at V. The gold dot and blue ring travel together. Uncheck to compare the warm-electron branch at the same time.'
      ],
      takeaway: '<span class="gold">Phase speed: follow phase.</span> <span style="color:#b4cefa">Group speed: the narrow-band envelope.</span> Neither is an electron velocity.',
      envelopeKey: 'Blue dashes: envelope', phaseKey: 'Gold dot: central phase', groupKey: 'Blue ring: envelope center',
      dotsTitle: 'Same electrons', slopeTitle: 'Origin ray and tangent', timeLabel: 'Observe time t',
      compare: 'No-dispersion comparison: ω = Vk', chartDescription: 'Dispersion axes: k [rad/m], ω [rad/s]. Gold origin ray: phase speed. Blue tangent: group speed.',
      groupNote: 'Nearby components: Δω/Δk → dω/dk; narrow-band envelope speed ≈ v<sub>g</sub>',
      phaseNote: 'k<sub>c</sub> = 60 rad/m; ω<sub>c</sub> = 1.166 × 10⁸ rad/s; the gold dot is not an electron',
      derivationTitle: 'Why is group speed dω/dk?',
      derivation: '<p>Start with two equal-amplitude waves at nearby wavenumbers. Define Δk=k₂−k₁ [rad/m], Δω=ω₂−ω₁ [rad/s], k̄=(k₁+k₂)/2 and ω̄=(ω₁+ω₂)/2.</p><p class="math">δn = A cos(k₁x−ω₁t) + A cos(k₂x−ω₂t)</p><p>The sum-to-product identity separates fast oscillation and slow modulation:</p><p class="math">δn = 2A cos[(Δk x−Δω t)/2] cos(k̄x−ω̄t)</p><p>A [m⁻³], x [m], t [s]. The first factor is the slow modulation; the second is the inner oscillation. Track a fixed modulation phase:</p><p class="math">Δk x − Δω t = constant<br>Δk dx/dt − Δω = 0<br>dx/dt = Δω/Δk</p><p>As the wavenumbers approach k<sub>c</sub>, the secant slope approaches the tangent slope:</p><p class="math">v<sub>g</sub> = lim<sub>Δk→0</sub> Δω/Δk = (dω/dk)<sub>c</sub> [m/s]</p><p>Two components give a periodic beat envelope. Many nearby, appropriately weighted components form a localized packet. Following k̄x−ω̄t=constant instead gives the phase speed ω̄/k̄, tending to ω<sub>c</sub>/k<sub>c</sub> in the narrow-band limit.</p>',
      detailsTitle: 'How is the packet built? What is approximate?',
      details: '<p>Use the page 07 warm-electron fluid branch: ω(k)=√(ω₀²+u²k²), ω₀=10⁸ rad/s, u=10⁶ m/s. Uniform, unmagnetized, fixed ions; collisions and Landau damping are omitted. Temperature enters through electron pressure.</p><p class="math">2ω dω/dk = 2u²k<br>v<sub>g</sub> = u²k<sub>c</sub>/ω<sub>c</sub></p><p>Take 31 wavenumbers kⱼ=42+1.2j rad/m (j=0,…,30), centered on k<sub>c</sub>=60 rad/m. Weights are wⱼ=exp[−(kⱼ−k<sub>c</sub>)²/(2σₖ²)] with σₖ=6 rad/m. Set Aⱼ/n₀=0.18 wⱼ/∑wⱼ and all initial phases to 0 rad. The units of n₀, Aⱼ and δn are m⁻³. Thus |δn/n₀|≤0.18 and density remains positive. The discrete spectrum repeats in space every 5.24m; this window shows one packet.</p><p>Every component evolves with its actual ω(kⱼ). The white curve is ∑(Aⱼ/n₀)cos(kⱼx−ωⱼt); the envelope is the modulus of the complex sum ∑(Aⱼ/n₀)exp[i(kⱼx−ωⱼt)]. The blue ring locates its computed maximum. The gold dot follows the central phase x=(ω<sub>c</sub>/k<sub>c</sub>)t, approximately an inner crest for this narrow band.</p><p>The first-order expansion ω(k)≈ω<sub>c</sub>+v<sub>g</sub>(k−k<sub>c</sub>) gives a slow envelope moving at v<sub>g</sub> times an inner carrier. We use the full frequencies, retaining slight distortion; the match between envelope speed and (dω/dk)꜀ is a narrow-band approximation. A broader band or longer propagation can cause spreading. This example has v<sub>g</sub>&lt;vph; other branches need not. Group speed is not unconditionally an energy or information speed.</p><p>The nondispersive comparison uses ω=Vk, V=ω<sub>c</sub>/k<sub>c</sub>≈1.944×10⁶m/s. This is a mathematical comparison, not another plasma model. The wavenumber band, amplitudes, initial phases, spatial window and playback time scale stay fixed.</p><p>Each playback second represents 3×10⁻⁸s. The animation loops from 0 to 2×10⁻⁷s; scrubbing time pauses it. Dots use a conservative kinematic map of the total density, without solving particle forces or random thermal motion.</p><p>Geometry and group-speed derivation: <a href="https://bpb-us-e1.wpmucdn.com/sites.harvard.edu/dist/0/550/files/2023/11/waves_dispersion.pdf" target="_blank" rel="noopener">David Morin · Dispersion, §6.3</a>. Warm-electron background: <a href="https://silas.psfc.mit.edu/introplasma/master.pdf" target="_blank" rel="noopener">MIT · Introduction to Plasma Physics</a>.</p>'
    }
  };
  function chart(a) {
    if (!a.text || a.s.stage < 4) return;
    const svg = a.$('slope-chart'), w = svg.clientWidth, h = svg.clientHeight;
    if (!w || !h) return;
    const left = w < 400 ? 57 : 80, right = w - 24, top = 65, bottom = h - 72;
    const x = k => left + k / 100 * (right - left), y = omega => bottom - omega / 2.1e8 * (bottom - top);
    const add = (tag, attrs, text) => {
      const node = document.createElementNS('http://www.w3.org/2000/svg', tag);
      for (const [key, value] of Object.entries(attrs)) node.setAttribute(key, String(value));
      if (text !== undefined) node.textContent = text;
      svg.append(node); return node;
    };
    const line = (x1, y1, x2, y2, cls) => add('line', { x1, y1, x2, y2, class: cls });
    const label = (text, px, py, anchor = 'middle') => add('text', { x: px, y: py, 'text-anchor': anchor }, text);
    svg.setAttribute('viewBox', `0 0 ${w} ${h}`); svg.replaceChildren();
    add('rect', { x: x(42), y: top, width: x(78) - x(42), height: bottom - top, fill: '#b5efcf', opacity: .09 });
    line(left, bottom, right + 8, bottom, 'packet-axis'); line(left, bottom, left, top - 10, 'packet-axis');
    label('ω [rad/s]', left, 27, 'start'); label('k [rad/m]', right, h - 10, 'end');
    for (const k of [0, 60, 100]) { line(x(k), bottom, x(k), bottom + 7, 'packet-axis'); label(k, x(k), bottom + 32, k === 100 ? 'end' : 'middle'); }
    line(left, y(1e8), right, y(1e8), 'packet-guide'); label('10⁸', left - 12, y(1e8) + 8, 'end');
    const linear = a.s.data.linear, vg = M.groupSpeed(M.KC, linear);
    add('polyline', { points: Array.from({ length: 101 }, (_, k) => `${x(k)},${y(M.frequency(k, linear))}`).join(' '), class: 'packet-branch' });
    line(left, bottom, x(M.KC), y(M.WC), 'packet-ray');
    line(x(0), y(M.WC - vg * M.KC), x(100), y(M.WC + vg * (100 - M.KC)), 'packet-tangent');
    add('circle', { cx: x(M.KC), cy: y(M.WC), r: 7, fill: '#edf5f1', stroke: '#10181c', 'stroke-width': 2 });
    label('P', x(M.KC) + 14, y(M.WC) - 18, 'start');
    svg.setAttribute('aria-label', `${a.text.chartDescription} vph = ${speed(M.VP)}; vg = ${speed(vg)}.`);
  }
  function syncTime(a) {
    a.$('packet-time').value = String(a.s.time);
    const text = `${(a.s.time / 10).toFixed(2)} × 10⁻⁷ s`;
    a.$('time-output').textContent = text;
    a.$('packet-time').setAttribute('aria-valuetext', text);
  }
  PlasmaLesson.start({
    translations: texts, running: s => !s.data.noCanvas, rate: () => 3,
    setup(a) {
      a.s.paused = true; a.s.data.linear = false; a.s.data.noCanvas = !a.ctx;
      a.$('packet-time').addEventListener('input', e => { a.s.time = Number(e.target.value); a.s.paused = true; a.render(); });
      a.$('linear-branch').addEventListener('change', e => { a.s.data.linear = e.target.checked; a.render(); });
      new ResizeObserver(() => chart(a)).observe(a.$('slope-chart'));
    },
    onStage(s, old) {
      if (s.stage === 0) { s.time = 0; s.paused = true; }
      if (s.stage !== 5) s.data.linear = false;
      if (s.stage === 2 && s.time === 0) s.time = 8;
      if (s.stage === 5 && old !== 5) { s.data.linear = true; s.time = 8; }
    },
    update(a) {
      const { s, text: t, $ } = a;
      $('slope-pane').hidden = s.stage < 4; $('slope-heading').textContent = t.slopeTitle;
      $('time-controls').hidden = s.stage < 2; $('time-label').textContent = t.timeLabel;
      $('comparison').hidden = s.stage !== 5; $('comparison-label').textContent = t.compare;
      $('linear-branch').checked = s.data.linear;
      $('packet-legend').hidden = s.stage < 1; $('phase-key').hidden = s.stage < 2;
      $('phase-key').textContent = t.phaseKey; $('group-key').textContent = s.stage >= 3 ? t.groupKey : t.envelopeKey;
      $('model-note').textContent = s.data.linear ? t.comparisonModel : t.model;
      const vg = M.groupSpeed(M.KC, s.data.linear);
      if (s.stage === 2) $('equation').innerHTML = `v<sub>ph</sub> = ω<sub>c</sub>/k<sub>c</sub> = ${speed(M.VP)}<small>${t.phaseNote}</small>`;
      if (s.stage === 3) $('equation').innerHTML = `v<sub>g</sub> = (dω/dk)<sub>c</sub> = ${speed(vg)}<small>${t.groupNote}</small>`;
      if (s.stage >= 4) $('equation').innerHTML = `${s.data.linear ? 'ω = Vk<small>' : '<small>'}<span class="speed-term phase-key">v<sub>ph</sub> = ${speed(M.VP)}</span><span class="speed-term group-key">v<sub>g</sub> = ${speed(vg)}</span></small>`;
      $('group-derivation').hidden = s.stage < 3; $('derivation-summary').textContent = t.derivationTitle;
      $('derivation-content').innerHTML = t.derivation;
      $('packet-details').hidden = s.stage < 1; $('packet-summary').textContent = t.detailsTitle;
      $('packet-description').innerHTML = t.details;
      if (s.stage === 0) { $('group-derivation').open = false; $('packet-details').open = false; }
      syncTime(a); chart(a);
    },
    draw(a) {
      const { s, text: t, ctx, line, label, dot } = a;
      if (s.time > M.TMAX * M.W0) s.time %= M.TMAX * M.W0;
      syncTime(a);
      const time = s.time / M.W0, modes = M.modes(s.data.linear);
      const left = 66, right = s.width - 18, width = right - left, mid = 170, scale = 90 / M.AMPLITUDE;
      const px = x => left + (x - M.XMIN) / (M.XMAX - M.XMIN) * width;
      label('δn / n₀ [1]', 24, 28, '#edf5f1', 26, 'left');
      for (const value of [-.18, 0, .18]) {
        line(left, mid - scale * value, right, mid - scale * value);
        label(value === 0 ? '0' : value.toFixed(2), left - 10, mid - scale * value, '#e0ebe6', 22, 'right');
      }
      const samples = Array.from({ length: 361 }, (_, i) => M.sample(M.XMIN + i / 360 * (M.XMAX - M.XMIN), time, modes));
      function trace(fn, color, dash = [], thick = 2.5) {
        ctx.beginPath(); ctx.strokeStyle = color; ctx.lineWidth = thick; ctx.setLineDash(dash);
        samples.forEach((v, i) => { const x = left + i / 360 * width, y = mid - scale * fn(v); if (i) ctx.lineTo(x, y); else ctx.moveTo(x, y); });
        ctx.stroke(); ctx.setLineDash([]);
      }
      if (s.stage >= 1) { trace(v => v.envelope, blue, [9, 6]); trace(v => -v.envelope, blue, [9, 6]); }
      trace(v => v.re, '#edf5f1');
      if (s.stage >= 3) {
        const x = M.peak(time, s.data.linear), y = mid - scale * M.sample(x, time, modes).envelope;
        line(px(x), 64, px(x), 274, blue, 1.5, [6, 5]);
        ctx.beginPath(); ctx.strokeStyle = blue; ctx.lineWidth = 3; ctx.arc(px(x), y, 10, 0, a.TAU); ctx.stroke();
      }
      if (s.stage >= 2) {
        const x = M.VP * time, y = mid - scale * M.sample(x, time, modes).re;
        line(px(x), 65, px(x), 274, gold, 1.5); dot(px(x), y, 5, gold);
      }
      label('−0.5', left, 292, '#e0ebe6', 22);
      if (s.width >= 500) label('0', px(0), 292, '#e0ebe6', 22);
      label('0.9', right, 292, '#e0ebe6', 22, 'right'); label('x [m]', right, 327, '#e0ebe6', 24, 'right');
      label(t.dotsTitle, 24, 368, '#b5efcf', 26, 'left');
      const columns = Math.max(64, Math.floor(width / 9)), radius = Math.min(3.5, width / columns * .30);
      // Solve each particle once, then reuse its x coordinate in the schematic rows.
      ctx.save(); ctx.beginPath(); ctx.rect(left, 400, width, 75); ctx.clip();
      for (let j = -2; j <= columns + 2; j++) {
        const q = M.XMIN + j / columns * (M.XMAX - M.XMIN), x = px(M.position(q, time, modes));
        for (let row = 0; row < 4; row++) dot(x, 412 + row * 17, radius, '#b5efcf');
      }
      ctx.restore();
    }
  });
})();
