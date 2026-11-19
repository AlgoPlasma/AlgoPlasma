/* Rigid electron-slab illustration in the small-displacement bulk-field
 * approximation. Model and limits: docs/author_notes/plasma_waves_restoring.md. */
(() => {
  'use strict';
  const translations = {
    zh: {
      title: '电子为什么<span>会来回运动？</span>', documentTitle: '电子为什么会来回运动？ | AlgoPlasma',
      chapter: '01 / 电子运动与等离子体振荡', back: '上一步', returnLabel: '返回等离子体波课堂',
      electron: '电子层', ion: '固定离子层', pause: '暂停动画', play: '播放动画',
      model: '平板模型：离子固定，电子层整体移动；省略热运动和碰撞，动画减速。',
      steps: [
        '电子为什么会往复运动？把电子和离子看成两层，先让它们重合，此时净电荷为零。',
        '先将整个电子层，向右移开一点。',
        '左侧留下正电，右侧多出负电。',
        '电场从正电指向负电：向右。',
        '电子带负电，所以受力与电场相反：向左。',
        '回到原位时仍有速度，电子会越过平衡位置。'
      ],
      actions: ['把电子层向右移', '观察两侧电荷', '电场指向哪里？', '电子受到什么力？', '释放电子层', '重新看一遍'],
      field: '电场 E [V/m]', fieldZero: '电场 E = 0 V/m', force: '电子受力 F [N]', forceZero: '电子受力 F = 0 N',
      positive: '正电', negative: '负电', displaced: '电子层右移', equilibrium: '平衡位置',
      takeaway: '<span class="mint">电场把电子拉回，</span><br class="mobile-break"><span class="gold">惯性让它越过原位。</span>',
      progress: '推演步骤',
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
      chapter: '01 / Electron motion and plasma oscillations', back: 'Previous step', returnLabel: 'Return to the plasma waves course',
      electron: 'Electrons', ion: 'Fixed ions', pause: 'Pause', play: 'Play',
      model: 'Slab model: fixed ions, coherent electron displacement, no thermal motion or collisions. Motion is slowed.',
      steps: [
        'Why do the electrons move back and forth? Picture overlapping electron and ion layers. Their charges balance at equilibrium.',
        'Shift the entire electron layer slightly to the right.',
        'Positive charge is exposed on the left; negative charge on the right.',
        'The field points from positive to negative charge: to the right.',
        'Electrons are negative. Their electric force points left.',
        'At equilibrium they still have velocity, so they move past it.'
      ],
      actions: ['Shift the electrons', 'Inspect the charges', 'Which way is the field?', 'Find the electron force', 'Release the electrons', 'Watch again'],
      field: 'Electric field E [V/m]', fieldZero: 'Electric field E = 0 V/m', force: 'Electron force F [N]', forceZero: 'Electron force F = 0 N',
      positive: 'Positive', negative: 'Negative', displaced: 'Electron displacement', equilibrium: 'Equilibrium',
      takeaway: '<span class="mint">The field pulls electrons back.</span><br class="mobile-break"> <span class="gold">Inertia carries them past equilibrium.</span>',
      progress: 'Explanation step',
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
  const PHASE_RATE = 1.15; // Display radians per second; no physical time calibration.
  const SHIFT_FRACTION = .085; // Relative to the illustrated slab width.

  function draw({ s, ctx, text, line, dot, arrow, label }) {
    const w = s.width, h = s.height, small = w < 650;
    const left = w * .16, slabWidth = w * .68, top = small ? 104 : 106;
    const bottom = Math.max(top + 65, h - 91), slabHeight = bottom - top;
    const displacement = s.data.shift * SHIFT_FRACTION * slabWidth;
    const right = left + slabWidth, absShift = Math.abs(displacement);
    const center = w / 2, rows = 5, columns = small ? 13 : 25;
    // Charge-exposed bands are the non-overlapping ends of the two slabs.
    if (s.stage >= 2 && absShift > .25) {
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
        const tracked = s.stage >= 4 && col === Math.floor(columns / 2) && row === 2;
        dot(x + displacement, y, tracked ? (small ? 5.5 : 7) : (small ? 3 : 4.5), tracked ? '#f4c583' : '#b5efcf');
        if (tracked) {
          ctx.beginPath(); ctx.strokeStyle = '#f4c58388'; ctx.lineWidth = 1.2; ctx.arc(x + displacement, y, small ? 11 : 15, 0, 2 * Math.PI); ctx.stroke();
          line(x, top - 10, x, bottom + 12, '#f4c58344', 1, [3, 5]);
        }
      }
    }
    if (s.stage === 1) {
      arrow(center - 10, bottom + 35, center - 10 + Math.max(displacement, 1), '#b5efcf');
      label(text.displaced, center, bottom + 64, '#b5efcf', small ? 17 : 23);
    }
    const vectorLength = Math.min(w * .20, 185) * s.data.shift;
    if (s.stage >= 3) {
      label(Math.abs(s.data.shift) < .035 ? text.fieldZero : text.field, center, 48, '#b5efcf', small ? 18 : 25);
      if (Math.abs(s.data.shift) >= .035) arrow(center - vectorLength / 2, 72, center + vectorLength / 2, '#b5efcf');
    }
    if (s.stage >= 4) {
      if (Math.abs(s.data.shift) >= .035) arrow(center + vectorLength / 2, bottom + 36, center - vectorLength / 2, '#f4c583');
      label(Math.abs(s.data.shift) < .035 ? text.forceZero : text.force, center, bottom + 66, '#f4c583', small ? 18 : 25);
    }
  }

  PlasmaLesson.register('restoring', {
    translations, draw,
    running: s => s.stage === 5,
    setup({ s }) { Object.assign(s.data, { shift: 0, phase: 0 }); },
    onStage(s, old, reset) {
      if (reset || old === 5 || s.stage === 0 || s.stage === 5) {
        s.data.phase = 0;
        s.data.shift = Number(s.stage > 0);
      }
    },
    frame(s, dt) {
      if (s.stage === 5) {
        if (!s.paused) s.data.phase = (s.data.phase + dt * PHASE_RATE) % (2 * Math.PI);
        s.data.shift = Math.cos(s.data.phase);
      } else {
        const blend = s.paused ? 1 : 1 - Math.exp(-dt * 7);
        s.data.shift += (Number(s.stage > 0) - s.data.shift) * blend;
      }
    }
  });
})();

/* Plasma-wave contribution history (Git author dates; edit time includes timezone).
 * 2026-11-17 19:50 +08:00 | Yinjian Zhao | git 3e022dd90c69
 * 2026-11-17 20:09 +08:00 | Yinjian Zhao | git c97a40fba286
 * 2026-11-17 20:54 +08:00 | Yinjian Zhao | git d334e2e4b253
 * 2026-11-18 08:16 +08:00 | Yinjian Zhao | git 45f247468130
 * 2026-11-18 15:11 +08:00 | Yinjian Zhao | git 8e431a343dc7
 * 2026-11-19 15:22 +08:00 | Yinjian Zhao | git b32e8af2bb2b
 * 2026-11-19 16:01 +08:00 | Yinjian Zhao | git 2113cbc05ed4
 * 2026-11-19 16:28 +08:00 | Yinjian Zhao | edit (Codex-assisted)
 */
