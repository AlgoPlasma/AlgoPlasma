/* Spatial and temporal phase differences, then the traveling-wave expression. */
(() => {
  'use strict';
  const translations = {
    zh: {
      documentTitle: '为什么不同位置不同时起伏？', title: '不同位置，<span>为什么不同时起伏？</span>', chapter: '04 / 相位与波的表达式',
      pause: '暂停动画', play: '播放动画', back: '上一步', returnLabel: '返回等离子体波课堂', progress: '讲解步骤',
      keyboard: '点击点阵或按 → 继续 · F 全屏', fullscreenFailed: '当前预览不允许全屏，请在独立浏览器中打开。',
      model: '正弦密度波示意：离子固定，无热运动，动画减速。按 λ、T、n₀ 缩放；相位用 rad，一整圈为 2π rad。',
      steps: ['各处都在周期性起伏，却不一定同时达到密度最高。', '放两个固定探针。移动 B，比较两条密度曲线。', '同一时刻，相隔一个波长，相位就相差一整圈。', '固定一个位置：每过一个周期，相位减少一整圈。', '把空间、时间和起点，写进同一个相位。'],
      actions: ['比较两个位置', '给空间差一个量', '再看时间的变化', '合成波的表达式', '重新看一遍'],
      equations: ['', '', 'Δφ = kΔx　 k = 2π / λ <small>k：波数 [rad/m]；Δφ：相位差 [rad]</small>', 'ω = 2π / T = 2πf <small>ω：角频率 [rad/s]；固定 x 时 Δφ = −ωΔt</small>', 'δn(x,t) = A cos(kx − ωt + φ₀)<small>δn = nₑ − n₀；A：密度幅值 [m⁻³]；φ₀：初相位 [rad]</small>'],
      descriptions: ['同一电子密度波在不同空间位置的起伏并不总是同步。', '蓝色探针 A 固定，金色探针 B 的位置由滑块选择。下面两条曲线分别是两处密度随时间变化。相隔四分之一波长，相位差为 π/2；相隔半波长则反相；相隔一波长重新同相。', '在同一时刻比较相位的空间变化：Δφ=kΔx，波数 k=2π/λ。动画仍播放，但两个探针始终比较同一瞬间；滑块可检验半波长和一波长的情况。', '只观察固定探针 A 的时间变化。向右行进的余弦波取相位 kx−ωt+φ0，每经过 T，相位减少 2π；角频率 ω=2π/T。', '密度扰动为 δn=A cos(kx−ωt+φ0)，总电子密度为 n0+δn。A 是扰动幅值，k 是波数，ω 是角频率，φ0 是初相位。保持同一相位，x 随 t 增大，因此正 k、正 ω 时该波向右传播，相速度为 ω/k。'],
      takeaway: '<span class="mint">同相位点向右移动：</span> <span class="gold">v<sub>ph</sub> = ω/k。</span>',
      previous: '← 第三页：测量一列波', next: '第五页：两列波相遇，会怎样？ →',
      separation: '探针间距', phase: '相位差', density: 'nₑ [m⁻³]', perturbation: 'δn [m⁻³]', time: '时间 t [s]', space: '位置 x [m]',
      initial: '从不同位置的起伏，读出“相位”', temporal: '固定探针 A', same: '同相', opposite: '反相', offset: '错开',
    },
    en: {
      documentTitle: 'Different positions, different phases', title: 'Different positions. <span>Different phases.</span>', chapter: '04 / Phase and the wave expression',
      pause: 'Pause', play: 'Play', back: 'Previous step', returnLabel: 'Return to the plasma waves course', progress: 'Explanation step',
      keyboard: 'Click the dots or press → · F fullscreen', fullscreenFailed: 'Fullscreen is unavailable here. Open a separate browser tab.',
      model: 'Prescribed density wave; fixed ions, no thermal motion, slowed playback. Scales: λ, T, n₀. Phase in radians: one full turn is 2π rad.',
      steps: ['Density varies periodically everywhere, but maxima need not occur together.', 'Place two fixed probes. Move B and compare their density traces.', 'At the same instant, one wavelength spans one full turn of phase.', 'At a fixed position, phase decreases by one full turn each period.', 'Combine space, time and the starting point into a single phase.'],
      actions: ['Compare two positions', 'Measure spatial phase', 'Now look at time', 'Build the wave expression', 'Watch again'],
      equations: ['', '', 'Δφ = kΔx　 k = 2π / λ <small>k: wavenumber [rad/m]; Δφ: phase difference [rad]</small>', 'ω = 2π / T = 2πf <small>ω: angular frequency [rad/s]; at fixed x, Δφ = −ωΔt</small>', 'δn(x,t) = A cos(kx − ωt + φ₀)<small>δn = nₑ − n₀; A: density amplitude [m⁻³]; φ₀: initial phase [rad]</small>'],
      descriptions: ['Different positions in the same electron-density wave need not reach maximum density together.', 'Probe A is fixed; the slider chooses the position of probe B. Two traces show density versus time. A quarter-wavelength separation gives π/2 phase difference, half a wavelength gives opposite phase, and a full wavelength returns to the same phase.', 'Compare two positions at the same instant: Δφ=kΔx, where wavenumber k=2π/λ. The animation continues, but both probes always compare the same instant. Use the slider to check half and full wavelengths.', 'Observe time variation at fixed probe A. With phase kx−ωt+φ0 for a right-moving wave, one period T decreases phase by 2π. Angular frequency is ω=2π/T.', 'The density perturbation is δn=A cos(kx−ωt+φ0), and total density is n0+δn. A is its amplitude, k the wavenumber, ω the angular frequency and φ0 the initial phase. Keeping phase constant makes x increase with t for positive k and ω, so the pattern moves right at ω/k.'],
      takeaway: '<span class="mint">Equal-phase points move right:</span> <span class="gold">v<sub>ph</sub> = ω/k.</span>',
      previous: '← Page 3: measuring a wave', next: 'Page 5: what happens when waves meet? →',
      separation: 'Probe separation', phase: 'Phase difference', density: 'nₑ [m⁻³]', perturbation: 'δn [m⁻³]', time: 'Time t [s]', space: 'Position x [m]',
      initial: 'Read phase from density at different positions', temporal: 'Fixed probe A', same: 'Same phase', opposite: 'Opposite phase', offset: 'Shifted',
    }
  };
  PlasmaLesson.start({
    translations, previous: '03_measuring_a_wave.html', next: '05_superposition.html', running: () => true,
    setup(a) {
      a.s.data.separation = .25;
      a.$('separation').addEventListener('input', e => { a.s.data.separation = Number(e.target.value); a.render(); });
    },
    onStage(s) { if (s.stage === 0) { s.time = 0; s.data.separation = .25; } },
    update(a) {
      const { s, text: t, $ } = a, dx = s.data.separation, phase = 2 * dx;
      $('interaction').hidden = s.stage !== 1 && s.stage !== 2;
      $('separation').value = String(dx); $('separation-label').textContent = t.separation;
      const relation = dx === 0 || dx === 1 ? t.same : dx === .5 ? t.opposite : t.offset;
      $('separation').setAttribute('aria-valuetext', `Δx = ${dx.toFixed(2)} λ; Δφ = ${phase.toFixed(2)} π rad; ${relation}`);
      $('separation-output').textContent = `Δx = ${dx.toFixed(2)} λ`;
      $('phase-output').textContent = `Δφ = ${phase.toFixed(2)} π rad · ${relation}`;
    },
    draw(a) {
      const { s, text: t, colors: c, TAU, mod, density, line, dot, label, bracket, curve, grid, arrow } = a;
      const w = s.width, h = s.height, small = w < 650, fs = small ? 18 : 24;
      const left = small ? 22 : 38, right = w - left, length = 2.5, px = x => left + x / length * (right - left);
      const waves = [{ a: .28, k: TAU, w: TAU }], xa = .5, xb = xa + s.data.separation;
      if (!s.stage) {
        if (!small) label(t.initial, left, 24, c.muted, fs, 'left');
        grid(waves, s.time, left, right, h * .25, h * .76); arrow(w * .43, h - 28, w * .57, c.mint); return;
      }
      const top = 48, bottom = Math.max(top + 46, h * .37), y = Math.max(bottom + 66, h * .68), amp = Math.min(30, h * .085);
      grid(waves, s.time, left, right, top, bottom);
      if (s.stage < 3) {
        [[xa, 'A', c.blue], [xb, 'B', c.gold]].forEach(([x, name, color], i) => {
          line(px(x), top - 10, px(x), bottom + 9, color, 2);
          label(name, px(x) + (s.data.separation < .08 ? (i ? 10 : -10) : 0), small && s.stage === 2 ? bottom + 21 : 19, color, fs);
        });
      } else if (s.stage === 3) {
        line(px(xa), top - 10, px(xa), bottom + 9, c.blue, 2); label('A', px(xa), 19, c.blue, fs);
      } else {
        const crest = mod(s.time, 1) + 1;
        line(px(crest), top - 10, px(crest), bottom + 9, c.gold, 2);
        label(a.language === 'en' ? 'kx − ωt + φ₀ = constant' : 'kx − ωt + φ₀ = 常数', w / 2, 19, c.gold, small ? 18 : 25);
      }
      line(left, y, right, y);
      if (s.stage < 4) label('n₀', left - 4, y, c.muted, small ? 14 : 17, 'right');
      label(s.stage === 4 ? t.perturbation : t.density, left, y - amp - 20, c.muted, small ? 16 : 20, 'left');
      if (s.stage === 1 || s.stage === 3) {
        const xmax = 2.2, tx = v => left + v / xmax * (right - left), current = mod(s.time, 2);
        const probes = s.stage === 1 ? [[xa, c.blue], [xb, c.gold]] : [[xa, c.blue]];
        probes.forEach(([x, color]) => {
          curve(u => (density(x, u * xmax, waves) - 1) / .28, left, right, y, amp, color);
          dot(tx(current), y - amp * (density(x, s.time, waves) - 1) / .28, 4.5, color);
        });
        line(tx(current), y - amp - 6, tx(current), y + amp + 6, '#a6b8b555');
        if (s.stage === 3) bracket(tx(.5), tx(1.5), y + amp + 12, 'T ↔ 2π rad', c.blue);
        else label(a.$('phase-output').textContent, w / 2, y + amp + 28, c.gold, small ? 17 : 23);
        label(t.time, right, h - 12, c.muted, small ? 17 : 21, 'right');
      } else {
        curve(u => (density(u * length, s.time, waves) - 1) / .28, left, right, y, amp);
        if (s.stage === 2) {
          [[xa, c.blue], [xb, c.gold]].forEach(([x, color]) => { line(px(x), bottom + 12, px(x), y + amp + 8, color + '77', 1, [3, 5]); dot(px(x), y - amp * (density(x, s.time, waves) - 1) / .28, 5, color); });
          bracket(px(xa), px(xb), y + amp + 12, 'Δx');
          label(`Δφ = ${(2 * s.data.separation).toFixed(2)} π rad`, right, 19, c.gold, fs, 'right');
        } else {
          const crest = px(mod(s.time, 1) + 1);
          dot(crest, y - amp, 5, c.gold); arrow(crest - 18, y + amp + 25, crest + 18, c.gold);
          label('0', left - 6, y, c.muted, 16, 'right');
        }
        label(t.space, right, h - 12, c.muted, small ? 17 : 21, 'right');
      }
    }
  });
})();
