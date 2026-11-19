/* Linear density superposition: interference, beats and standing-wave nodes. */
(() => {
  'use strict';
  function standingDerivation(t) {
    return `<p class="standing-assumptions">${t.standingAssumptions}</p>
      <div class="standing-component"><h2>${t.rightward}</h2>
        <p class="standing-math"><span class="math-part">δn₁ = A cos(kx−ωt)</span> <span class="math-part">= A cos(kx) cos(ωt)</span> <span class="math-part gold">+ A sin(kx) sin(ωt)</span></p></div>
      <div class="standing-component" data-reveal-part="1" hidden><h2>${t.leftward}</h2>
        <p class="standing-math"><span class="math-part">δn₂ = A cos(kx+ωt)</span> <span class="math-part">= A cos(kx) cos(ωt)</span> <span class="math-part gold">− A sin(kx) sin(ωt)</span></p></div>
      <p class="standing-explanation" data-reveal-part="2" hidden>${t.cancelTerms}</p>
      <p class="standing-math standing-result" data-reveal-part="2" hidden><span class="math-part">δn = δn₁ + δn₂</span> <span class="math-part mint">= 2A cos(kx) cos(ωt)</span></p>
      <p class="standing-units">${t.standingUnits}</p>
      <p class="standing-nodes" data-reveal-part="2" hidden>${t.fixedNodes}</p>`;
  }
  const translations = {
    zh: {
      documentTitle: '两列波相遇会发生什么？', title: '两列波相遇，<span>会发生什么？</span>', chapter: '03 / 干涉、拍频与驻波',
      pause: '暂停动画', play: '播放动画', back: '上一步', returnLabel: '返回等离子体波课堂', progress: '讲解步骤',
      fullscreenFailed: '当前预览不允许全屏，请在独立浏览器中打开。',
      model: '线性密度扰动示意，幅度放大；离子固定，无热运动。按 λ₁、T₁、n₀ 缩放，未设绝对值；播放速度经过调整。',
      steps: ['先看一列电子密度波，再让另一列加入。', '同向、同频、等幅：相位决定增强，还是相消。', '频率略有差别：固定位置的起伏时强时弱，形成“拍”。', '同频、等幅、相向传播：形成密度节点位置固定的驻波。', '分别展开两列行波的余弦。相加时，哪些项会抵消？', '预测一下：密度节点处，哪一个量始终为零？'],
      actions: ['加入第二列波', '让频率略有不同', '让两列波相向传播', '推导这个公式', '试一个判断', '重新看叠加'],
      equations: ['', 'δn = δn₁ + δn₂ <small>密度扰动 [m⁻³]；总密度 nₑ = n₀ + δn</small>', 'f<sub>beat</sub> = |f₂ − f₁| = 0.2 f₁ <small>频率均用 Hz；本例 f₂ = 1.2 f₁</small>', 'δn = 2A cos(kx) cos(ωt) <small>A：每列行波的密度幅值 [m⁻³]；空间形状 × 时间振荡</small>', '', ''],
      descriptions: ['先单独观察一个给定的电子密度波。', '两列同向、同频、等幅的密度扰动相加。滑块调节相位差：零相位差时合成幅值为 2A，π 时完全相消，2π 时恢复同相。三条曲线分别显示扰动一、扰动二和总扰动；总电子密度只含一个背景 n0。', '两列同向波频率为 f1 和 1.2 f1，波数也以相同比例变化。本页在固定位置测总密度扰动。慢包络描述起伏幅度的变化，拍频为 0.2 f1，拍周期为 5T1。虚线包络不是第三列独立的波。', '等频等幅的两个相向波相加，得到 2A cos(kx) cos(ωt)。密度节点满足 cos(kx)=0，位置固定，那里 δn 始终为零。波腹的密度起伏最强。节点说的是密度扰动，不是某个电子固定不动。', '取k>0、ω>0，两个初相位为零的相向行波分别是δn₁=Acos(kx−ωt)和δn₂=Acos(kx+ωt)。用余弦差角与和角公式展开，两式中的Asin(kx)sin(ωt)项符号相反、相加抵消，余下两项Acos(kx)cos(ωt)相同，因此δn=δn₁+δn₂=2Acos(kx)cos(ωt)。A是每列行波的密度幅值，单位m⁻³；合成局部幅值为2A|cos(kx)|。cos(kx)=0的位置不随时间改变，那里δn始终为零。', '固定的蓝色虚线标记密度节点。金色电子在节点附近来回运动，并可以穿过节点。预测始终为零的是密度扰动还是电子速度；选择后获得反馈，答题不阻止导航。'],
      takeaway: '<span class="mint">密度节点固定，</span><span class="gold">电子仍可运动。</span>',

      derivationTitle: '两列行波，<span>直接相加。</span>',
      standingAssumptions: '线性叠加；两波同 A、同 |k|、同 ω。取 k > 0、ω > 0，初相位均为 0。',
      rightward: '① 向右（+x）：展开 cos(kx−ωt)', leftward: '② 向左（−x）：展开 cos(kx+ωt)',
      cancelTerms: '相加时，金色的正弦乘积项一正一负，恰好抵消；两个余弦乘积项相同。',
      standingUnits: 'A：每列行波的密度幅值 [m⁻³]；k [rad/m]，ω [rad/s]，x [m]，t [s]。',
      fixedNodes: '合成局部幅值为 2A|cos(kx)|，波腹为 2A。在 cos(kx) = 0 的固定位置，δn 对所有时刻都为 0。',
      phaseLabel: '两列波的相位差', phaseUnit: '相位差', constructive: '同相增强 · 幅值 2A', destructive: '反相相消 · 幅值 0', amplitude: '合成幅值',
      first: '先看一列波', probe: '固定探针 · 看时间信号', position: '位置 x [m]', time: '时间 t [s]', node: '密度节点', antinode: '波腹', tracked: '追踪一个电子',
      densityAnswer: '密度扰动 δn', velocityAnswer: '电子速度',
      correct: '对。节点处 nₑ = n₀，但电子仍可穿过该位置。',
      incorrect: '再看金色电子：它会穿过节点。始终为零的是 δn。',
    },
    en: {
      documentTitle: 'What happens when two waves meet?', title: 'Two waves meet. <span>What happens?</span>', chapter: '03 / Interference, beats and standing waves',
      pause: 'Pause', play: 'Play', back: 'Previous step', returnLabel: 'Return to the plasma waves course', progress: 'Explanation step',
      fullscreenFailed: 'Fullscreen is unavailable here. Open a separate browser tab.',
      model: 'Linear density perturbations, enlarged; fixed ions, no thermal motion. Scales: λ₁, T₁, n₀; no absolute values. Playback speed varies.',
      steps: ['Start with one electron-density wave, then add another.', 'Same direction, frequency and amplitude: phase sets reinforcement or cancellation.', 'Slightly different frequencies: density oscillations grow and fade in beats.', 'Equal frequency and amplitude, opposite directions: density nodes stay fixed.', 'Expand the cosine of each traveling wave. Which terms cancel when you add the waves?', 'Predict: at a density node, which quantity is always zero?'],
      actions: ['Add a second wave', 'Change one frequency', 'Send waves toward each other', 'Derive this formula', 'Try a prediction', 'Explore again'],
      equations: ['', 'δn = δn₁ + δn₂ <small>Density perturbations [m⁻³]; total density nₑ = n₀ + δn</small>', 'f<sub>beat</sub> = |f₂ − f₁| = 0.2 f₁ <small>Frequencies in Hz; here f₂ = 1.2 f₁</small>', 'δn = 2A cos(kx) cos(ωt) <small>A: amplitude of each traveling wave [m⁻³]; space × time</small>', '', ''],
      descriptions: ['Begin with a single prescribed electron-density wave.', 'Two density perturbations have equal amplitude and frequency and travel in the same direction. Adjust their relative phase: zero gives amplitude 2A, π cancels the perturbation, and 2π restores reinforcement. Three curves show the two components and their sum. Total density includes the background n0 only once.', 'Two waves travel in the same direction at frequencies f1 and 1.2 f1, with wavenumbers in the same ratio. At a fixed probe their summed density signal has a slowly varying envelope. Beat frequency is 0.2 f1 and beat period is 5T1. The dashed envelope is not a third independent wave.', 'Two equal-amplitude, equal-frequency waves moving in opposite directions sum to 2A cos(kx) cos(ωt). Density nodes satisfy cos(kx)=0, stay in place and have δn=0 at all times. Antinodes have the largest density oscillations. Nodes concern density, not stationary electrons.', 'Take k>0 and ω>0, with zero initial phases. The opposite traveling waves are δn₁=Acos(kx−ωt) and δn₂=Acos(kx+ωt). Expand each using the cosine difference and sum identities. The Asin(kx)sin(ωt) terms have opposite signs and cancel; the identical Acos(kx)cos(ωt) terms add. Thus δn=δn₁+δn₂=2Acos(kx)cos(ωt). A is the density amplitude of each traveling wave, in m⁻³; the local resultant amplitude is 2A|cos(kx)|. Positions where cos(kx)=0 stay fixed and have δn=0 at every time.', 'Blue dashed lines mark fixed density nodes. A gold electron oscillates near a node and can pass through it. Predict whether density perturbation or electron velocity is always zero there. Feedback is optional and does not block navigation.'],
      takeaway: '<span class="mint">Density nodes stay fixed.</span> <span class="gold">Electrons can still move.</span>',

      derivationTitle: 'Two traveling waves. <span>Add them.</span>',
      standingAssumptions: 'Linear superposition; equal A, |k| and ω. Choose k > 0, ω > 0 and both initial phases zero.',
      rightward: '① Rightward (+x): expand cos(kx−ωt)', leftward: '② Leftward (−x): expand cos(kx+ωt)',
      cancelTerms: 'The gold sine products have opposite signs and cancel. The two cosine products are identical and add.',
      standingUnits: 'A: density amplitude of each traveling wave [m⁻³]; k [rad/m], ω [rad/s], x [m], t [s].',
      fixedNodes: 'The local amplitude is 2A|cos(kx)|, reaching 2A at antinodes. At fixed positions where cos(kx) = 0, δn = 0 at every time.',
      phaseLabel: 'Relative phase', phaseUnit: 'Phase difference', constructive: 'In phase · amplitude 2A', destructive: 'Opposite phase · amplitude 0', amplitude: 'Resultant amplitude',
      first: 'Start with one wave', probe: 'Fixed probe · time signal', position: 'Position x [m]', time: 'Time t [s]', node: 'Density node', antinode: 'Antinode', tracked: 'Follow one electron',
      densityAnswer: 'Density perturbation δn', velocityAnswer: 'Electron velocity',
      correct: 'Yes. At a node nₑ = n₀, but electrons can still pass through.',
      incorrect: 'Watch the gold electron cross the node. It is δn that stays zero.',
    }
  };
  PlasmaLesson.register('superposition', {
    translations, running: s => s.stage !== 4,
    rate: s => s.stage === 2 ? .6 : .15,
    setup(a) {
      a.s.data.phase = 0; a.s.data.answer = null;
      a.$('relative-phase').addEventListener('input', e => { a.s.data.phase = Number(e.target.value); a.render(); });
      a.$('density-answer').addEventListener('click', () => { a.s.data.answer = 'density'; a.render(); });
      a.$('velocity-answer').addEventListener('click', () => { a.s.data.answer = 'velocity'; a.render(); });
    },
    onStage(s) { s.time = 0; if (s.stage === 0) { s.data.phase = 0; s.data.answer = null; } },
    update(a) {
      const { s, text: t, $ } = a, phase = s.data.phase;
      $('interaction').hidden = s.stage !== 1 && s.stage !== 5;
      $('phase-control').hidden = s.stage !== 1; $('quiz').hidden = s.stage !== 5;
      $('relative-phase').value = String(phase); $('relative-phase-label').textContent = t.phaseLabel;
      $('relative-phase').setAttribute('aria-valuetext', `${t.phaseUnit}: ${phase.toFixed(2)} π rad`);
      $('relative-phase-output').textContent = `Δφ = ${phase.toFixed(2)} π rad`;
      $('density-answer').textContent = t.densityAnswer; $('velocity-answer').textContent = t.velocityAnswer;
      for (const id of ['density', 'velocity']) $(id + '-answer').setAttribute('aria-pressed', String(s.data.answer === id));
      $('feedback').hidden = !s.data.answer;
      $('feedback').textContent = s.data.answer === 'density' ? t.correct : s.data.answer === 'velocity' ? t.incorrect : '';
      $('takeaway-text').hidden = !s.data.answer;
      const deriving = s.stage === 4;
      $('lesson').classList.toggle('is-deriving', deriving);
      $('scene').hidden = deriving;
      $('standing-derivation').hidden = !deriving;
      const panel = $('standing-derivation'), key = a.language + '-' + s.stage;
      if (deriving && panel.dataset.content !== key) {
        panel.innerHTML = standingDerivation(t);
        panel.dataset.content = key;
      }
    },
    draw(a) {
      const { s, text: t, colors: c, TAU, mod, density, position, line, dot, label, bracket, curve, grid, arrow } = a;
      if (s.stage === 4) return;
      const w = s.width, h = s.height, small = w < 650, fs = small ? 18 : 24;
      const left = small ? 22 : 38, right = w - left, length = 2.5, px = x => left + x / length * (right - left), A = .14;
      let waves = [{ a: A, k: TAU, w: TAU }];
      if (s.stage === 1) waves.push({ a: A, k: TAU, w: TAU, phi: s.data.phase * Math.PI });
      if (s.stage === 2) waves.push({ a: A, k: 1.2 * TAU, w: 1.2 * TAU });
      if (s.stage >= 3) waves.push({ a: A, k: TAU, w: -TAU });
      if (!s.stage) {
        label(t.first, left, 24, c.muted, fs, 'left'); grid(waves, s.time, left, right, h * .25, h * .76);
        arrow(w * .43, h - 28, w * .57, c.mint); return;
      }
      if (s.stage === 5) {
        const top = 52, bottom = Math.max(top + 50, h - 48);
        // This sampling includes q=0.75 exactly; the gold dot replaces a grid dot.
        grid(waves, s.time, left, right, top, bottom, length, { columns: small ? 40 : 80, rows: 5 });
        for (let node = .25; node < length; node += .5) line(px(node), top - 10, px(node), bottom + 13, '#8eadd966', 1.2, [4, 5]);
        label(t.node, px(.75), 23, c.blue, fs);
        const electron = px(position(.75, s.time, waves));
        dot(electron, (top + bottom) / 2, small ? 5 : 7, c.gold);
        label(t.tracked, left, h - 15, c.gold, small ? 17 : 23, 'left');
        return;
      }
      const top = small && s.stage === 3 ? 78 : 49, bottom = Math.max(top + 42, h * .31);
      grid(waves, s.time, s.stage === 1 ? left + (small ? 35 : 55) : left, right, top, bottom);
      if (s.stage === 1) {
        const phase = s.data.phase, amplitude = 2 * Math.abs(Math.cos(phase * Math.PI / 2));
        const feedback = phase === 0 || phase === 2 ? t.constructive : phase === 1 ? t.destructive : `${t.amplitude} ${amplitude.toFixed(2)} A`;
        label(feedback, left, 20, c.gold, small ? 16 : fs, 'left');
        const plotLeft = left + (small ? 35 : 55), start = bottom + 22, lane = (h - 34 - start) / 3, amp = Math.min(16, lane * .28);
        [[waves.slice(0, 1), 'δn₁', c.blue], [waves.slice(1), 'δn₂', c.gold], [waves, 'δn', c.mint]].forEach(([parts, name, color], i) => {
          const y = start + (i + .5) * lane;
          label(name, left, y, color, small ? 17 : 23, 'left'); line(plotLeft, y, right, y);
          // Each lane uses the same horizontal coordinate and vertical scale.
          curve(u => (density(u * length, s.time, parts) - 1) / A, plotLeft, right, y, amp, color);
        });
        label(t.position, right, h - 10, c.muted, small ? 16 : 21, 'right'); return;
      }
      const y = Math.max(bottom + 72, h * .64), amp = Math.min(40, h * .12);
      line(left, y, right, y);
      if (s.stage === 2) {
        label(t.probe, left, 20, c.gold, small ? 17 : fs, 'left');
        line(left, top - 8, left, bottom + 10, c.gold, 2);
        const span = 10, tx = v => left + v / span * (right - left), current = mod(s.time, span);
        curve(u => Math.abs(Math.cos(Math.PI * .2 * u * span)), left, right, y, amp, '#f4c58399', 1.5, [5, 5]);
        curve(u => -Math.abs(Math.cos(Math.PI * .2 * u * span)), left, right, y, amp, '#f4c58399', 1.5, [5, 5]);
        curve(u => (density(0, u * span, waves) - 1) / (2 * A), left, right, y, amp);
        const cx = tx(current); line(cx, y - amp - 6, cx, y + amp + 6, '#f4c58366');
        dot(cx, y - amp * (density(0, s.time, waves) - 1) / (2 * A), 5, c.gold);
        bracket(tx(0), tx(5), y + amp + 13, 'Tbeat = 5T₁');
        label('δn [m⁻³]', left, y - amp - 18, c.muted, small ? 17 : 21, 'left');
        label('0', left - 6, y, c.muted, 16, 'right');
        label(t.time, right, h - 10, c.muted, small ? 16 : 21, 'right');
      } else {
        for (let node = .25; node < length; node += .5) {
          line(px(node), top - 10, px(node), y + amp + 10, '#8eadd966', 1.2, [4, 5]); dot(px(node), y, 4, c.blue);
        }
        label(t.node, px(.75), 20, c.blue, small ? 17 : fs);
        label(t.antinode, px(1.5), small ? 48 : 20, c.gold, small ? 17 : fs);
        curve(u => Math.cos(TAU * u * length), left, right, y, amp, '#a6b8b53b', 1.2, [4, 5]);
        curve(u => -Math.cos(TAU * u * length), left, right, y, amp, '#a6b8b53b', 1.2, [4, 5]);
        curve(u => (density(u * length, s.time, waves) - 1) / (2 * A), left, right, y, amp);
        dot(px(1.5), y - amp * (density(1.5, s.time, waves) - 1) / (2 * A), 5, c.gold);
        label('δn [m⁻³]', left, y - amp - 18, c.muted, small ? 17 : 21, 'left');
        label('0', left - 6, y, c.muted, 16, 'right');
        label(t.position, right, h - 10, c.muted, small ? 16 : 21, 'right');
      }
    }
  });
})();
