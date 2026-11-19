/* Period, wavelength and phase speed, using one consistent density field. */
(() => {
  'use strict';
  const translations = {
    zh: {
      documentTitle: '怎样测量一列波？', title: '一列波，<span>怎样测量？</span>', chapter: '03 / 周期、波长与相速度',
      pause: '暂停动画', play: '播放动画', back: '上一步', returnLabel: '返回等离子体波课堂', progress: '讲解步骤',
      fullscreenFailed: '当前预览不允许全屏，请在独立浏览器中打开。',
      model: '正弦密度波示意：固定离子，无热运动，动画减速。探针固定；图按 λ、T、n₀ 缩放，未设绝对数值。',
      steps: ['看同一列电子疏密波，从时间和空间分别测量。', '固定一个位置：两次密度最高之间，隔了多久？', '冻结同一时刻：两个相邻密度峰之间，隔了多远？', '追踪同一密度峰：经过一个周期，前进一个波长。'],
      actions: ['固定一个位置', '冻结这一刻', '跟随一个密度峰', '重新测量'],
      equations: ['', 'f = 1 / T <small>T：周期 [s]　f：频率 [Hz]</small>', 'λ <small>波长 [m]：同一时刻，相邻同相位点的间距</small>', 'v<sub>ph</sub> = λ / T = λf <small>相速度 [m/s]：密度图样的传播速度</small>'],
      descriptions: ['电子局部往复运动，密集区域向右移动。', '金色线是固定空间位置的虚拟探针；下方曲线是该处电子密度随时间的变化。相邻峰值间隔为 T，频率为 1/T。', '动画冻结；下方曲线改为这一时刻的电子密度空间分布。相邻密度峰间距为波长 λ。', '空心圆标记初始密度峰，实心圆追踪同一个峰。一个周期 T 后，它移动了 λ，故相速度为 λ/T。这不代表电子运动速度，也不自动等于能量传播速度。'],
      takeaway: '<span class="mint">周期：多久重复。</span> <span class="gold">波长：多远重复。</span>',

      probe: '固定探针', electron: '电子密度波', timeView: '看时间 · 固定位置', spaceView: '看空间 · 固定时刻', follow: '追踪同一个密度峰',
      time: '时间 t [s]', space: '位置 x [m]', density: 'nₑ [m⁻³]', frozen: '画面已冻结', elapsed: '经过', start: '起点', end: '一个周期后',
    },
    en: {
      documentTitle: 'How do we measure a wave?', title: 'One wave. <span>How do we measure it?</span>', chapter: '03 / Period, wavelength and phase speed',
      pause: 'Pause', play: 'Play', back: 'Previous step', returnLabel: 'Return to the plasma waves course', progress: 'Explanation step',
      fullscreenFailed: 'Fullscreen is unavailable here. Open a separate browser tab.',
      model: 'Prescribed density wave; fixed ions, no thermal motion, slowed playback. Fixed probe. Plots scale with λ, T and n₀; no absolute values are assigned.',
      steps: ['Measure the same electron-density wave in time and in space.', 'Fix a position: how long between two density maxima?', 'Freeze time: how far between adjacent density peaks?', 'Follow one density peak: it travels one wavelength in one period.'],
      actions: ['Fix a position', 'Freeze this instant', 'Follow a density peak', 'Measure again'],
      equations: ['', 'f = 1 / T <small>T: period [s]　f: frequency [Hz]</small>', 'λ <small>Wavelength [m]: adjacent equal-phase points at one instant</small>', 'v<sub>ph</sub> = λ / T = λf <small>Phase speed [m/s]: motion of the density pattern</small>'],
      descriptions: ['Electrons oscillate locally while dense regions move right.', 'The gold line marks a probe at a fixed spatial position. The lower curve is electron density there versus time. Consecutive maxima are a period T apart; frequency is 1/T.', 'Time is frozen. The lower curve now shows electron density versus position at that instant. Adjacent density peaks are one wavelength apart.', 'An open circle marks the initial crest position and a filled circle follows that same crest. In one period T it advances λ, so phase speed is λ/T, not the speed of an electron or necessarily the speed of energy transport.'],
      takeaway: '<span class="mint">Period: repeat in time.</span> <span class="gold">Wavelength: repeat in space.</span>',

      probe: 'Fixed probe', electron: 'Electron density wave', timeView: 'Time view · fixed position', spaceView: 'Space view · fixed time', follow: 'Follow the same density peak',
      time: 'Time t [s]', space: 'Position x [m]', density: 'nₑ [m⁻³]', frozen: 'Time is frozen', elapsed: 'Elapsed', start: 'Start', end: 'One period later',
    }
  };
  PlasmaLesson.start({
    translations,
    running: s => s.stage !== 2,
    onStage(s, old) { if (s.stage === 0 || s.stage === 3 || (old === 3 && s.stage === 2)) s.time = 0; },
    draw(a) {
      const { s, text: t, ctx, colors: c, TAU, mod, density, line, dot, label, bracket, arrow, curve, grid } = a;
      const w = s.width, h = s.height, small = w < 650, fs = small ? 18 : 24;
      const left = small ? 22 : 38, right = w - left, length = 2.5, px = x => left + x / length * (right - left);
      const waves = [{ a: .28, k: TAU, w: TAU }];
      const travel = Math.min(mod(s.time, 1.45), 1), time = s.stage === 3 ? .25 + travel : s.time;
      if (!s.stage) {
        label(t.electron, left, 24, c.muted, fs, 'left');
        grid(waves, time, left, right, h * .27, h * .76);
        arrow(w * .43, h - 28, w * .57, c.mint); return;
      }
      const top = 51, bottom = Math.max(top + 45, h * .40), y = Math.max(bottom + 58, h * .68), amp = Math.min(31, h * .085);
      if (!(small && s.stage === 3)) label(s.stage === 1 ? t.timeView : s.stage === 2 ? t.spaceView : t.follow, left, 20, c.muted, fs, 'left');
      grid(waves, time, left, right, top, bottom);
      if (s.stage === 1) {
        const probe = .5, probeX = px(probe), xmax = 2.2, tx = v => left + v / xmax * (right - left);
        line(probeX, top - 10, probeX, bottom + 13, c.gold, 2);
        label(t.probe, probeX + 10, bottom + (small ? 18 : 28), c.gold, small ? 16 : 21, 'left');
        line(left, y, right, y); curve(u => (density(probe, u * xmax, waves) - 1) / .28, left, right, y, amp);
        const current = mod(time, 2), cx = tx(current), cy = y - amp * (density(probe, time, waves) - 1) / .28;
        line(cx, y - amp - 5, cx, y + amp + 5, '#f4c58355', 1); dot(cx, cy, 5, c.gold);
        bracket(tx(.5), tx(1.5), y + amp + 12, 'T');
        label(t.time, right, h - 13, c.muted, small ? 17 : 21, 'right');
        label(t.density, left, y - amp - 18, c.muted, small ? 16 : 20, 'left');
      } else {
        line(left, y, right, y); curve(u => (density(u * length, time, waves) - 1) / .28, left, right, y, amp);
        const peak = mod(time, 1);
        label(t.density, left, y - amp - 18, c.muted, small ? 16 : 20, 'left');
        if (s.stage === 2) {
          [peak, peak + 1].forEach(x => { line(px(x), top - 10, px(x), y + amp + 10, '#f4c58377', 1, [4, 5]); dot(px(x), y - amp, 5, c.gold); });
          bracket(px(peak), px(peak + 1), y + amp + 12, 'λ');
        } else {
          const start = px(.25), end = px(1.25), current = px(.25 + travel);
          ctx.strokeStyle = '#f4c58377'; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(start, y - amp, 6, 0, TAU); ctx.stroke();
          line(current, top - 10, current, bottom + 10, c.gold, 2);
          dot(current, y - amp, 6, c.gold); arrow(start, bottom + 25, current, c.gold);
          label(`${t.elapsed} ${travel.toFixed(2)} T`, small ? left : right, 20, c.gold, fs, small ? 'left' : 'right');
          bracket(start, end, y + amp + 12, 'λ');
        }
        label(t.space, right, h - 13, c.muted, small ? 17 : 21, 'right');
      }
      label('n₀', left - 4, y, c.muted, small ? 14 : 17, 'right');
    }
  });
})();
