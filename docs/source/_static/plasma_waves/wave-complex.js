/* Complex density representation, with the same Eulerian density and dot map.
 * Convention: exp(i(kx - omega t)), Re(n_tilde) = delta_n. See author note. */
(() => {
  'use strict';
  const TAU = 2 * Math.PI, REFERENCE = .28;
  function wavesFor(s) {
    if (s.stage === 3) return [
      { a: REFERENCE / 2, k: TAU, w: TAU, phi: 0 },
      { a: REFERENCE / 2, k: TAU, w: TAU, phi: Math.PI * s.data.relativePhase }
    ];
    return [{ a: REFERENCE, k: TAU, w: TAU, phi: s.stage >= 2 ? Math.PI * s.data.initialPhase : 0 }];
  }
  function valueAt(waves, time, x = 0) {
    return waves.reduce((z, v) => {
      const angle = v.k * x - v.w * time + v.phi;
      return { re: z.re + v.a * Math.cos(angle), im: z.im + v.a * Math.sin(angle) };
    }, { re: 0, im: 0 });
  }
  function derivationHTML(spatial, text) {
    const subscript = spatial ? 'ₓ' : 'ₜ';
    const factor = spatial ? 'ik' : '−iω', realFactor = spatial ? '−Ak' : 'Aω';
    const units = spatial ? 'm⁻⁴' : 'm⁻³/s', color = spatial ? 'blue' : 'gold';
    const copy = spatial ? text.spaceDerivation : text.timeDerivation;
    return `<div class="derivation-chain">
      <h2>${text.chainRule}</h2>
      <p class="derivation-explanation">${copy.fixed}</p>
      <p class="derivation-math">∂${subscript}[i(kx−ωt)] = <span class="${color}">${factor}</span></p>
      <p class="derivation-explanation">${text.exponentialRule.replaceAll('{v}', subscript)}</p>
      <p class="derivation-math">∂${subscript}ñ = <span class="math-group">n̂ e<sup>i(kx−ωt)</sup></span> <span class="math-group ${color}">· (${factor})</span><br><span class="derivation-result ${color}">= ${factor}ñ</span></p>
    </div>
    <div class="derivation-check" data-reveal-part="1" hidden>
      <h2>${text.realCheck}</h2>
      <p class="derivation-math"><span class="math-group">ñ = A e<sup>iθ</sup></span> <span class="math-group">= A cosθ + iA sinθ</span></p>
      <p class="derivation-explanation">δn = A cosθ<br>θ = kx−ωt+φ₀</p>
      <p class="derivation-math">∂${subscript}δn = <span class="math-group">Re{${factor}ñ}</span><br><span class="derivation-result ${color}">= ${realFactor} sinθ</span></p>
      <p class="derivation-explanation">${copy.sign}</p>
      <p class="derivation-unit">${text.derivativeUnit} <strong>${units}</strong></p>
    </div>
    <p class="derivation-limit" data-reveal-part="1" hidden>${text.constantAmplitude}</p>`;
  }
  const translations = {
    zh: {
      documentTitle: '波为什么要用复数表示？', title: '波，为什么<span>用复数表示？</span>', chapter: '04 / 波的复数表达',
      pause: '暂停动画', play: '播放动画', back: '上一步', returnLabel: '返回等离子体波课堂', progress: '讲解步骤',
      fullscreenFailed: '当前预览不允许全屏，请在独立浏览器中打开。',
      model: '给定密度波示意：离子固定，无热运动，动画减速。图按 λ、T、n₀ 缩放，未设绝对 SI 数值。',
      steps: ['探针测到实数的密度起伏。复数能帮我们做什么？', '固定位置：箭头顺时针旋转，实轴投影给出密度扰动。', '复振幅 n̂ 记录幅值和初相位；乘指数后，再取实部。', '转动第二个复振幅：合成箭头决定合成波的幅值与初相位。', '时间导数 ∂ₜ、空间导数 ∂ₓ：对这列波，分别乘 −iω 和 ik。', '固定位置 x，对时间 t 求偏导：负号来自相位中的 −ωt。', '固定时刻 t，对位置 x 求偏导：相位中的 kx 给出正号。'],
      actions: ['让起伏变成旋转', '写出整列波', '用复振幅做叠加', '为什么方便计算？', '推导时间偏导', '再推导空间偏导', '重新看一遍'],
      equations: [
        '',
        'ñ = A e<sup>iθ</sup> = A cosθ + iA sinθ <small>i² = −1；探针处 θ = −ωt [rad]；A [m⁻³]</small>',
        'δn = Re{ñ}， ñ = n̂ e<sup>i(kx−ωt)</sup> <small>n̂ = A e<sup>iφ₀</sup> [m⁻³]；φ₀ [rad]</small>',
        'n̂ = n̂₁ + n̂₂ <small>同 k、同 ω；各复振幅 [m⁻³]；Δφ [rad]</small>',
        '∂ₜñ = −iωñ　 ∂ₓñ = ikñ <small>∂ₜñ [m⁻³/s]；∂ₓñ [m⁻⁴]</small>',
        'ñ(x,t) = n̂ e<sup>i(kx−ωt)</sup> <small>n̂ = A e<sup>iφ₀</sup>、k、ω 均为常量；n̂ [m⁻³]，k [rad/m]，ω [rad/s]</small>',
        'ñ(x,t) = n̂ e<sup>i(kx−ωt)</sup> <small>n̂ = A e<sup>iφ₀</sup>、k、ω 均为常量；n̂ [m⁻³]，k [rad/m]，ω [rad/s]</small>'
      ],
      descriptions: [
        '绿色点表示电子；金色线是固定在 x=0 的密度探针。密度起伏是实数，下面将用复数表示同一个密度波。',
        '左边是复密度扰动 ñ 的复平面，实部和虚部都用 m⁻³，坐标轴不是空间方向。ñ=A exp(iθ)=A cosθ+iA sinθ，i²=-1。在固定探针处 θ=-ωt，箭头顺时针旋转。金色实轴投影是实际密度扰动 A cosθ，与右侧探针时间曲线同步。',
        'ñ(x,t)=n̂ exp(i(kx-ωt))，复振幅 n̂=A exp(iφ0) 不随时间变化。n̂、A、ñ和δn的单位为m⁻³，φ0用rad；k用rad/m、ω用rad/s。虚线箭头是 x=0、t=0 的初始复振幅；实线箭头随时间旋转。滑块只改变初相位。实际总密度为 n0+Re(ñ)。',
        '两列波有相同波数和频率，先将不随时间变化的复振幅相加，再乘共同的指数因子。蓝箭头为第一个复振幅，金箭头为第二个，虚线将第二个平移到第一个箭头末端，绿箭头是向量和。相位差为π时幅值为零，合成相位未定义。右侧始终显示对应的实际密度波。',
        '对常复振幅、实数k和ω的这个平面波，时间微分给出-iωñ，空间微分给出ikñ。图中金箭头和曲线是时间导数除以ω，蓝色是空间导数除以k，因而与ñ同为m⁻³。乘-i使相位转-π/2，乘i使相位转+π/2；原始导数还要乘ω或k。取实部后同样得到实际密度扰动的导数。这个代换适用于所选傅里叶分量，不能直接套在变化的包络上。',
        '时间偏导保持x不变。复振幅n̂、k和ω为常量；指数i(kx-ωt)的时间偏导是-iω。链式法则给出∂ₜñ=n̂ exp[i(kx-ωt)](-iω)=-iωñ。取实部：令θ=kx-ωt+φ₀，δn=A cosθ，则∂ₜδn=Aω sinθ，单位m⁻³/s。负的余弦导数与∂ₜθ=-ω相乘，得到正号。',
        '空间偏导保持t不变。指数i(kx-ωt)的空间偏导是ik。链式法则给出∂ₓñ=n̂ exp[i(kx-ωt)](ik)=ikñ。取实部得到∂ₓδn=-Ak sinθ，单位m⁻⁴，负号来自余弦的导数。若复振幅随x或t变化，还必须使用乘积法则加入复振幅的导数。'
      ],
      models: [
        '给定密度波示意：离子固定，无热运动，动画减速。按 λ、T、n₀ 缩放，未设绝对 SI 数值。',
        '复平面两轴均为 m⁻³，空间 x 用 m；i 无量纲。探针测 δn = Re{ñ}，总密度 nₑ = n₀ + δn。',
        '复平面两轴均为 m⁻³；k [rad/m]，ω [rad/s]。指数相位无量纲。图用 λ、T、n₀ 作参考尺度。',
        '以第一列波初相位 0 为参考，左侧先加常复振幅，右侧再乘共同指数。同频、同波数、等幅的线性示意。',
        '图中导数分别除以 ω 或 k，三种箭头和曲线均为 m⁻³；ω [rad/s]，k [rad/m]。此处复振幅为常量。'
      ],
      takeaway: '<span class="mint">实部还原物理量，</span><span class="gold">复数把幅值和相位放在一起。</span>',
      timeTitle: '时间偏导，<span>为什么乘 −iω？</span>', spaceTitle: '空间偏导，<span>为什么乘 ik？</span>',

      chainRule: '从指数到整列波', realCheck: '取实部，核对正负号', derivativeUnit: '导数单位：',
      exponentialRule: '链式法则：∂{v}(eᵍ) = eᵍ ∂{v}g，其中 g = i(kx−ωt)。',
      constantAmplitude: '这里 ∂ₜn̂ = ∂ₓn̂ = 0。若复振幅随 x 或 t 变化，还要用乘积法则加入它的导数。',
      timeDerivation: { fixed: '固定 x，kx 不随 t 变化，先求指数的偏导：', sign: '∂ₜ cosθ = −sinθ · (−ω)，两个负号相消。' },
      spaceDerivation: { fixed: '固定 t，−ωt 不随 x 变化，先求指数的偏导：', sign: '∂ₓ cosθ = −sinθ · k，保留负号。' },
      initialPhase: '初相位 φ₀', relativePhase: '两波相位差 Δφ', probe: '固定探针 x = 0',
      plane: '复平面 [m⁻³]', amplitudePlane: '复振幅 [m⁻³]', initialArrow: '虚线：初始复振幅 n̂',
      realProjection: '实轴投影 = δn', amplitude: '|n̂| / A', undefinedPhase: '幅值为零，相位未定义', phase: '合成初相位',
      density: 'δn [m⁻³]', realParts: '实部 [m⁻³]', time: '时间 t [s]', position: '位置 x [m]',
      complexUnits: 'Re [m⁻³]', imaginaryUnits: 'Im', electronWave: '电子密度波',
    },
    en: {
      documentTitle: 'Why write waves as complex numbers?', title: 'Why use <span>complex waves?</span>', chapter: '04 / Complex wave representation',
      pause: 'Pause', play: 'Play', back: 'Previous step', returnLabel: 'Return to the plasma waves course', progress: 'Explanation step',
      fullscreenFailed: 'Fullscreen is unavailable here. Open a separate browser tab.',
      model: 'Prescribed density wave; fixed ions, no thermal motion, slowed playback. Reference scales λ, T, n₀; no absolute SI values.',
      steps: ['The probe measures a real density signal. What can complex numbers add?', 'At a fixed point, clockwise rotation projects onto the real density signal.', 'The complex amplitude n̂ stores amplitude and initial phase. Take the real part.', 'Rotate the second amplitude: the sum sets the resulting amplitude and phase.', 'Time derivative ∂ₜ: multiply by −iω. Space derivative ∂ₓ: multiply by ik.', 'Hold x fixed and differentiate in t. The minus sign comes from −ωt.', 'Hold t fixed and differentiate in x. The kx term gives a positive sign.'],
      actions: ['Turn oscillation into rotation', 'Write the whole wave', 'Add complex amplitudes', 'Why is calculation easier?', 'Derive the time derivative', 'Derive the space derivative', 'Watch again'],
      equations: [
        '',
        'ñ = A e<sup>iθ</sup> = A cosθ + iA sinθ <small>i² = −1; at the probe θ = −ωt [rad]; A [m⁻³]</small>',
        'δn = Re{ñ},　 ñ = n̂ e<sup>i(kx−ωt)</sup> <small>n̂ = A e<sup>iφ₀</sup> [m⁻³]; φ₀ [rad]</small>',
        'n̂ = n̂₁ + n̂₂ <small>Same k and ω; amplitudes [m⁻³]; Δφ [rad]</small>',
        '∂ₜñ = −iωñ　 ∂ₓñ = ikñ <small>∂ₜñ [m⁻³/s]; ∂ₓñ [m⁻⁴]</small>',
        'ñ(x,t) = n̂ e<sup>i(kx−ωt)</sup> <small>Constant n̂ = A e<sup>iφ₀</sup>, k and ω; n̂ [m⁻³], k [rad/m], ω [rad/s]</small>',
        'ñ(x,t) = n̂ e<sup>i(kx−ωt)</sup> <small>Constant n̂ = A e<sup>iφ₀</sup>, k and ω; n̂ [m⁻³], k [rad/m], ω [rad/s]</small>'
      ],
      descriptions: [
        'Green dots represent electrons; the gold line is a fixed density probe at x=0. Density varies as a real quantity. We will represent this same wave with complex numbers.',
        'The left plot is the complex plane of ñ. Both real and imaginary axes are in m⁻³, not spatial directions. ñ=A exp(iθ)=A cosθ+iA sinθ, with i²=-1. At the fixed probe θ=-ωt, so the arrow rotates clockwise. Its gold real-axis projection is the actual density perturbation A cosθ, synchronized with the probe trace on the right.',
        'ñ(x,t)=n̂ exp(i(kx-ωt)), where the constant complex amplitude n̂=A exp(iφ0) stores amplitude and initial phase. n̂, A, ñ and δn have units m⁻³; φ0 is in rad, k in rad/m and ω in rad/s. The dashed arrow is the initial amplitude at x=0,t=0. The solid arrow rotates with time. The slider changes initial phase only. Total density is n0+Re(ñ).',
        'Both waves have the same wavenumber and frequency. Add their time-independent complex amplitudes, then multiply by the common exponential factor. The blue arrow is the first amplitude, the gold arrow the second; a dashed copy places its tail at the first arrow tip. The green arrow is the sum. At relative phase π the amplitude is zero and resultant phase is undefined. The right panel shows the corresponding real density wave.',
        'For this plane wave with constant complex amplitude and real k and ω, time differentiation gives -iωñ and spatial differentiation gives ikñ. Gold shows the time derivative divided by ω; blue shows the spatial derivative divided by k. All plotted arrows and traces therefore have units m⁻³. Multiplication by -i rotates phase by -π/2; multiplication by i rotates it by +π/2. Actual derivatives also scale by ω or k. Taking real parts gives the derivatives of the physical perturbation. This replacement applies to the selected Fourier component, not directly to a varying envelope.',
        'For the time partial derivative, hold x fixed. With constant n̂, k and ω, the derivative of the exponent i(kx-ωt) is -iω. The chain rule gives ∂ₜñ=n̂ exp[i(kx-ωt)](-iω)=-iωñ. Take real parts: with θ=kx-ωt+φ₀ and δn=A cosθ, ∂ₜδn=Aω sinθ in m⁻³/s. The minus sign from differentiating cosine cancels the minus sign in ∂ₜθ=-ω.',
        'For the space partial derivative, hold t fixed. The derivative of the exponent i(kx-ωt) is ik. The chain rule gives ∂ₓñ=n̂ exp[i(kx-ωt)](ik)=ikñ. Taking real parts gives ∂ₓδn=-Ak sinθ in m⁻⁴, with the minus sign from differentiating cosine. A varying complex amplitude requires additional product-rule terms.'
      ],
      models: [
        'Prescribed density wave; fixed ions, no thermal motion, slowed playback. Scales λ, T, n₀; no absolute SI values.',
        'Both complex axes use m⁻³; spatial x uses m. The number i is dimensionless. The probe measures δn = Re{ñ}; nₑ = n₀ + δn.',
        'Both complex axes use m⁻³; k [rad/m], ω [rad/s]. The exponential phase is dimensionless. Reference scales: λ, T, n₀.',
        'Set the first initial phase to 0; add constant amplitudes, then apply the common exponential. Equal-amplitude waves with the same k and ω.',
        'Derivatives are divided by ω or k so all plotted arrows and traces use m⁻³. Here ω [rad/s], k [rad/m], and the complex amplitude is constant.'
      ],
      takeaway: '<span class="mint">Recover the real signal.</span> <span class="gold">Keep amplitude and phase together.</span>',
      timeTitle: 'Time derivative: <span>why −iω?</span>', spaceTitle: 'Space derivative: <span>why ik?</span>',

      chainRule: 'From exponent to wave', realCheck: 'Take real parts; check the sign', derivativeUnit: 'Derivative units:',
      exponentialRule: 'Chain rule: ∂{v}(eᵍ) = eᵍ ∂{v}g, with g = i(kx−ωt).',
      constantAmplitude: 'Here ∂ₜn̂ = ∂ₓn̂ = 0. If the amplitude varies with x or t, include its derivative using the product rule.',
      timeDerivation: { fixed: 'Hold x fixed: kx is constant in t. Differentiate the exponent first:', sign: '∂ₜ cosθ = −sinθ · (−ω): the two minus signs cancel.' },
      spaceDerivation: { fixed: 'Hold t fixed: −ωt is constant in x. Differentiate the exponent first:', sign: '∂ₓ cosθ = −sinθ · k: the minus sign remains.' },
      initialPhase: 'Initial phase φ₀', relativePhase: 'Relative phase Δφ', probe: 'Fixed probe x = 0',
      plane: 'Complex plane [m⁻³]', amplitudePlane: 'Amplitudes [m⁻³]', initialArrow: 'Dashed: initial amplitude n̂',
      realProjection: 'Real projection = δn', amplitude: '|n̂| / A', undefinedPhase: 'Zero amplitude; phase undefined', phase: 'Initial phase',
      density: 'δn [m⁻³]', realParts: 'Real parts [m⁻³]', time: 'Time t [s]', position: 'Position x [m]',
      complexUnits: 'Re [m⁻³]', imaginaryUnits: 'Im', electronWave: 'Electron density wave',
    }
  };
  PlasmaLesson.register('complex', {
    translations, running: s => s.stage < 5,
    setup(a) {
      a.s.data.initialPhase = 0; a.s.data.relativePhase = .5;
      a.$('complex-phase').addEventListener('input', e => {
        a.s.data[a.s.stage === 2 ? 'initialPhase' : 'relativePhase'] = Number(e.target.value); a.render();
      });
    },
    onStage(s) {
      // An eighth-period snapshot also makes projection visible without motion.
      s.time = s.stage === 1 || s.stage === 2 ? .125 : 0;
      if (s.stage === 0) { s.data.initialPhase = 0; s.data.relativePhase = .5; }
    },
    update(a) {
      const { $, s, text: t } = a, adding = s.stage === 3;
      const phase = adding ? s.data.relativePhase : s.data.initialPhase;
      $('interaction').hidden = s.stage !== 2 && s.stage !== 3;
      $('complex-phase-label').textContent = adding ? t.relativePhase : t.initialPhase;
      $('complex-phase').value = String(phase);
      $('complex-phase-output').textContent = `${adding ? 'Δφ' : 'φ₀'} = ${phase.toFixed(2)} π rad`;
      const sum = valueAt(wavesFor(s), 0), magnitude = Math.hypot(sum.re, sum.im);
      const result = adding ? magnitude < 1e-12 ? t.undefinedPhase : `${t.amplitude} = ${(magnitude / (REFERENCE / 2)).toFixed(2)}` : '';
      $('complex-phase').setAttribute('aria-valuetext', `${phase.toFixed(2)} π rad${result ? '; ' + result : ''}`);
      $('model-note').textContent = t.models[s.stage] || '';
      const deriving = s.stage >= 5;
      $('lesson').classList.toggle('is-deriving', deriving);
      $('scene').hidden = deriving;
      $('derivation').hidden = !deriving;
      const panel = $('derivation'), key = a.language + '-' + s.stage;
      if (deriving && panel.dataset.content !== key) {
        panel.innerHTML = derivationHTML(s.stage === 6, t);
        panel.dataset.content = key;
      }
    },
    draw(a) {
      const { s, ctx, text: t, colors: c, label, line, dot, grid, curve, arrow, mod } = a;
      if (s.stage >= 5) return;
      const w = s.width, h = s.height, stacked = matchMedia('(max-width: 900px)').matches;
      const small = w < 650, fs = small ? 17 : 23, left = small ? 22 : 30, right = w - left;
      const waves = wavesFor(s), z = valueAt(waves, s.time);
      if (!s.stage) {
        label(t.electronWave, left, 20, c.muted, fs, 'left');
        grid(waves, s.time, left, right, h * .25, h * .72);
        line(left, h * .25 - 12, left, h * .72 + 12, c.gold, 2);
        label(t.probe, left + 12, h * .72 + 37, c.gold, fs, 'left');
        arrow(w * .48, h - 24, w * .63, c.mint); return;
      }
      const planeBottom = stacked ? 360 : h;
      const cx = stacked ? w / 2 : w * .19;
      const cy = Math.max(164, planeBottom * .43);
      const radius = Math.min(stacked ? w * .23 : w * .115, 104, (planeBottom - 100) / 2);
      const scale = radius / REFERENCE;
      const point = value => ({ x: cx + value.re * scale, y: cy - value.im * scale });
      function vector(value, color, origin = { x: cx, y: cy }, dash = []) {
        const dx = value.re * scale, dy = -value.im * scale, end = { x: origin.x + dx, y: origin.y + dy };
        line(origin.x, origin.y, end.x, end.y, color, 2.5, dash);
        const size = Math.hypot(dx, dy);
        if (size > 7) {
          const ux = dx / size, uy = dy / size;
          line(end.x, end.y, end.x - 9 * ux + 4 * uy, end.y - 9 * uy - 4 * ux, color, 2.5);
          line(end.x, end.y, end.x - 9 * ux - 4 * uy, end.y - 9 * uy + 4 * ux, color, 2.5);
        }
        return end;
      }
      ctx.beginPath(); ctx.arc(cx, cy, radius, 0, TAU); ctx.strokeStyle = '#526e6266'; ctx.lineWidth = 1.3; ctx.stroke();
      line(cx - radius - 17, cy, cx + radius + 20, cy, '#526e62');
      line(cx, cy + radius + 12, cx, cy - radius - 18, '#526e62');
      label(t.complexUnits, cx + radius + 5, cy + 23, c.muted, small ? 15 : 19);
      label(t.imaginaryUnits, cx + 9, cy - radius - 15, c.muted, small ? 15 : 19, 'left');
      label(s.stage === 3 ? t.amplitudePlane : t.plane, small ? 8 : 14, 17, c.muted, small ? 15 : 20, 'left');
      label(s.stage === 3 ? '−2A' : '−A', cx - radius, cy + 22, c.muted, small ? 15 : 18);
      label(s.stage === 3 ? '2A' : 'A', cx + radius, cy - 17, c.muted, small ? 15 : 18);
      if (s.stage === 3) {
        const z1 = valueAt([waves[0]], 0), z2 = valueAt([waves[1]], 0), sum = valueAt(waves, 0);
        const end1 = vector(z1, c.blue); vector(z2, c.gold); vector(z2, '#f4c58399', end1, [4, 4]);
        vector(sum, c.mint); dot(point(sum).x, point(sum).y, 4, c.mint);
        const magnitude = Math.hypot(sum.re, sum.im), ratio = magnitude / (REFERENCE / 2);
        const phase = Math.atan2(sum.im, sum.re) / Math.PI, phaseLabel = (Math.abs(phase) < 1e-12 ? 0 : phase).toFixed(2);
        label(`${t.amplitude} = ${ratio.toFixed(2)}`, cx, planeBottom - 60, c.mint, small ? 20 : 25);
        label(magnitude < 1e-12 ? t.undefinedPhase : `${t.phase} = ${phaseLabel} π rad`, cx, planeBottom - 22, c.gold, small ? 16 : 21);
        // Color labels avoid making the complex axes look like spatial axes.
        label('n̂₁', 24, 52, c.blue, small ? 18 : 23, 'left');
        label('n̂₂', 70, 52, c.gold, small ? 18 : 23, 'left');
      } else if (s.stage === 4) {
        vector(z, c.mint); vector({ re: z.im, im: -z.re }, c.gold); vector({ re: -z.im, im: z.re }, c.blue);
        label('−i ñ = (∂ₜñ)/ω', cx, planeBottom - 60, c.gold, small ? 18 : 23);
        label('+i ñ = (∂ₓñ)/k', cx, planeBottom - 22, c.blue, small ? 18 : 23);
      } else {
        if (s.stage === 2) vector(valueAt(waves, 0), '#8eadd988', { x: cx, y: cy }, [4, 4]);
        const end = vector(z, c.mint), projection = { x: end.x, y: cy };
        const angle = Math.atan2(z.im, z.re), arcRadius = radius * .28;
        if (Math.abs(angle) > .12) {
          ctx.beginPath(); ctx.arc(cx, cy, arcRadius, 0, -angle, angle > 0); ctx.strokeStyle = '#a6b8b599'; ctx.lineWidth = 1.4; ctx.stroke();
          label('θ', cx + radius * .46 * Math.cos(angle / 2), cy - radius * .46 * Math.sin(angle / 2), c.muted, small ? 17 : 21);
        }
        line(end.x, end.y, projection.x, projection.y, '#f4c58399', 1.5, [4, 5]);
        line(cx, cy, projection.x, cy, c.gold, 3); dot(projection.x, projection.y, 5, c.gold); dot(end.x, end.y, 4, c.mint);
        label(`Re{ñ}/A = ${(z.re / REFERENCE).toFixed(2)}`, cx, planeBottom - 60, c.gold, small ? 20 : 25);
        label(s.stage === 2 ? t.initialArrow : t.realProjection, cx, planeBottom - 22, s.stage === 2 ? c.blue : c.muted, small ? 16 : 21);
      }
      const plotLeft = stacked ? left : w * .46, plotRight = right;
      const panelTop = stacked ? 386 : 0, panelHeight = stacked ? h - panelTop : h;
      if (!stacked) line(w * .405, 24, w * .405, h - 18, c.line);
      else line(left, panelTop - 14, right, panelTop - 14, c.line);
      const top = panelTop + 47, bottom = panelTop + Math.max(90, panelHeight * .34);
      label(t.probe, plotLeft, panelTop + 17, c.gold, fs, 'left');
      grid(waves, s.time, plotLeft, plotRight, top, bottom, 2.5, { columns: small ? 35 : 55, rows: 4 });
      line(plotLeft, top - 8, plotLeft, bottom + 10, c.gold, 2);
      const y = panelTop + Math.max(bottom - panelTop + 75, panelHeight * .70), amplitude = Math.min(30, panelHeight * .10);
      const span = 2.2, tx = time => plotLeft + time / span * (plotRight - plotLeft), current = mod(s.time, 2);
      line(plotLeft, y, plotRight, y);
      label(s.stage === 4 ? t.realParts : t.density, plotLeft, y - amplitude - 20, c.muted, small ? 16 : 20, 'left');
      curve(u => valueAt(waves, u * span).re / REFERENCE, plotLeft, plotRight, y, amplitude, c.mint);
      if (s.stage === 4) {
        curve(u => valueAt(waves, u * span).im / REFERENCE, plotLeft, plotRight, y, amplitude, c.gold, 2);
        curve(u => -valueAt(waves, u * span).im / REFERENCE, plotLeft, plotRight, y, amplitude, c.blue, 2);
        dot(tx(current), y - amplitude * z.im / REFERENCE, 4, c.gold);
        dot(tx(current), y + amplitude * z.im / REFERENCE, 4, c.blue);
      }
      line(tx(current), y - amplitude - 6, tx(current), y + amplitude + 6, '#a6b8b566');
      dot(tx(current), y - amplitude * z.re / REFERENCE, 5, s.stage === 4 ? c.mint : c.gold);
      label('0', plotLeft - 6, y, c.muted, 15, 'right');
      label('T', tx(1), y + amplitude + 20, c.muted, small ? 17 : 21);
      label(t.time, plotRight, panelTop + panelHeight - 11, c.muted, small ? 17 : 21, 'right');
    }
  });
})();

/* Plasma-wave contribution history (Git author dates; edit time includes timezone).
 * 2026-11-17 21:23 +08:00 | Yinjian Zhao | git 789e519340b7
 * 2026-11-18 08:16 +08:00 | Yinjian Zhao | git 45f247468130
 * 2026-11-18 09:53 +08:00 | Yinjian Zhao | git 23e47e779735
 * 2026-11-18 14:00 +08:00 | Yinjian Zhao | git abe90bd9fdab
 * 2026-11-18 15:11 +08:00 | Yinjian Zhao | git 8e431a343dc7
 * 2026-11-19 15:22 +08:00 | Yinjian Zhao | git b32e8af2bb2b
 * 2026-11-19 16:01 +08:00 | Yinjian Zhao | git 2113cbc05ed4
 * 2026-11-19 16:28 +08:00 | Yinjian Zhao | edit (Codex-assisted)
 */
