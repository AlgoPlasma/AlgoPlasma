/* Page navigation is independent of each lesson's reveal steps. */
(() => {
  'use strict';
  const lessons = [
    ['01_what_moves.html', '波与电子运动', 'Waves and electron motion'],
    ['02_why_oscillates.html', '恢复力与惯性', 'Restoring force and inertia'],
    ['03_measuring_a_wave.html', '周期、波长与相速度', 'Period, wavelength and phase speed'],
    ['04_phase.html', '相位与波的表达式', 'Phase and the wave expression'],
    ['05_superposition.html', '干涉、拍频与驻波', 'Interference, beats and standing waves'],
    ['06_complex_waves.html', '波的复数表达', 'Complex wave representation'],
    ['07_dispersion.html', '色散关系与读图', 'Reading a dispersion relation'],
    ['08_wave_packets.html', '波包、相速度与群速度', 'Wave packets, phase and group velocities'],
    ['09_deriving_dispersion.html', '第一条色散关系怎样推出来？', 'Deriving the first dispersion relation']
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
