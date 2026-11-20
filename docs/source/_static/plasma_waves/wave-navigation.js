/* Page navigation is independent of each lesson's reveal steps. */
(() => {
  'use strict';
  const lessons = [
    ['01_what_moves.html', '电子运动与等离子体振荡', 'Electron motion and plasma oscillations'],
    ['02_measuring_a_wave.html', '波的测量与相位', 'Wave measurements and phase'],
    ['03_superposition.html', '干涉、拍频与驻波', 'Interference, beats and standing waves'],
    ['04_complex_waves.html', '波的复数表达', 'Complex wave representation'],
    ['05_dispersion.html', '色散关系与读图', 'Reading a dispersion relation'],
    ['06_wave_packets.html', '波包、相速度与群速度', 'Wave packets, phase and group velocities'],
    ['07_deriving_dispersion.html', '第一条色散关系怎样推出来？', 'Deriving the first dispersion relation'],
    ['08_warm_langmuir.html', '温度怎样改变波？', 'How does temperature change the wave?'],
    ['09_complex_frequency.html', '波为什么增长或衰减？', 'Why do waves grow or damp?'],
    ['10_reading_spectra.html', '如何看模拟中的 ω–k 谱图？', 'How do we read an ω–k spectrum?']
  ];
  const $ = id => document.getElementById(id);
  const current = Number($('lesson').dataset.page) - 1;
  function setLanguage(language) {
    const en = language === 'en', lang = en ? 'en' : 'zh';
    const contents = en ? 'Contents' : '课程目录';
    $('page-navigation').setAttribute('aria-label', en ? 'Course page navigation' : '课程导航');
    $('lesson-index').textContent = contents;
    $('lesson-index').setAttribute('aria-label', en ? `Course contents, lesson ${current + 1} of ${lessons.length}` : `课程目录，当前第 ${current + 1} 课，共 ${lessons.length} 课`);
    const indexURL = `../../learning/plasma_waves/index.html?lang=${lang}`;
    $('lesson-index').href = indexURL; $('return-link').href = indexURL;
    for (const [id, offset, label] of [
      ['previous-lesson', -1, en ? 'Prev lesson' : '上一课'],
      ['next-lesson', 1, en ? 'Next lesson' : '下一课']
    ]) {
      const link = $(id), target = lessons[current + offset];
      link.textContent = label;
      if (target) {
        link.href = `${target[0]}?lang=${lang}`;
        const title = `${offset < 0 ? (en ? 'Previous lesson' : '上一课') : (en ? 'Next lesson' : '下一课')}：${target[en ? 2 : 1]}`;
        link.title = title; link.setAttribute('aria-label', title);
        link.removeAttribute('aria-disabled'); link.removeAttribute('tabindex');
      } else {
        link.removeAttribute('href'); link.setAttribute('aria-disabled', 'true'); link.setAttribute('tabindex', '-1');
        link.title = offset < 0 ? (en ? 'This is the first lesson' : '已是第一课') : (en ? 'This is the last lesson' : '已是最后一课');
        link.setAttribute('aria-label', link.title);
      }
    }
  }
  window.PlasmaNavigation = { setLanguage };
})();

/* Plasma-wave contribution history (Git author dates; edit time includes timezone).
 * 2026-11-18 08:16 +08:00 | Yinjian Zhao | git 45f247468130
 * 2026-11-18 15:11 +08:00 | Yinjian Zhao | git 8e431a343dc7
 * 2026-11-18 15:43 +08:00 | Yinjian Zhao | git 1f9402dd7fdd
 * 2026-11-18 16:36 +08:00 | Yinjian Zhao | git 4be5f6b5764f
 * 2026-11-19 11:06 +08:00 | Yinjian Zhao | git 3242c1a909ef
 * 2026-11-19 15:22 +08:00 | Yinjian Zhao | git b32e8af2bb2b
 * 2026-11-19 15:26 +08:00 | Yinjian Zhao | git b9e33596c00f
 * 2026-11-19 16:01 +08:00 | Yinjian Zhao | git 2113cbc05ed4
 * 2026-11-19 16:28 +08:00 | Yinjian Zhao | edit (Codex-assisted)
 */
