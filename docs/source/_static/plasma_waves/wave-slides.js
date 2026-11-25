/* A slide groups model stages. Repeated stages reveal the next line of algebra
 * without restarting the simulation. Navigation belongs to the footer. */
(() => {
  'use strict';
  const slide = (zh, en, stages, cues = []) => ({ title: { zh, en }, stages, cues });
  const sections = {
    motion: [
      slide('波来了，电子去哪儿了？', 'Where do the electrons go?', [0, 1]),
      slide('跟踪一个电子，再跟踪一处密集区', 'Follow an electron, then a dense region', [2, 3, 4])
    ],
    restoring: [
      slide('移开电子层，哪里会带电？', 'Where does charge appear?', [0, 1, 2]),
      slide('什么力把电子拉回来？', 'What pulls the electrons back?', [3, 4]),
      slide('回到平衡位置时，电子会停下吗？', 'Do electrons stop at equilibrium?', [5])
    ],
    measures: [
      slide('固定一个位置，测周期', 'Measure the period at one position', [0, 1]),
      slide('冻结一个时刻，测波长', 'Measure wavelength in a snapshot', [2]),
      slide('跟随同一个波峰，测相速度', 'Follow a crest to measure phase speed', [3])
    ],
    phase: [
      slide('两个探针看到的起伏一样吗？', 'What do two probes see?', [0, 1]),
      slide('相位怎样随空间和时间改变？', 'How does phase vary in space and time?', [2, 3]),
      slide('把相位写进密度波', 'Write the density wave using its phase', [4])
    ],
    superposition: [
      slide('两列波相遇，会发生什么？', 'What happens when two waves meet?', [0, 1]),
      slide('频率略有不同，探针看到什么？', 'What does a probe see at two close frequencies?', [2]),
      slide('为什么有些位置的密度始终不变？', 'Where does the density stay constant?', [3]),
      slide('把两列行波加成驻波', 'Add two traveling waves to get a standing wave', [4, 4, 4],
        [['展开左行波', 'Expand the left-going wave'], ['相加并约去正弦项', 'Add and cancel the sine terms']]),
      slide('在密度节点，哪个量为零？', 'What vanishes at a density node?', [5])
    ],
    complex: [
      slide('用旋转的箭头读出密度', 'Read density from a rotating arrow', [0, 1]),
      slide('用复振幅表示和叠加波', 'Represent and add waves with complex amplitudes', [2, 3]),
      slide('求导怎样变成乘法？', 'How does differentiation become multiplication?', [4]),
      slide('固定位置，求时间偏导', 'Differentiate in time at fixed position', [5, 5], [['用实部核对结果', 'Check the real part']]),
      slide('固定时刻，求空间偏导', 'Differentiate in space at fixed time', [6, 6], [['用实部核对结果', 'Check the real part']])
    ],
    dispersion: [
      slide('波长和频率怎样搭配？', 'Which wavelengths and frequencies go together?', [0, 1]),
      slide('沿曲线选一个允许的分量', 'Select an allowed component on the curve', [2]),
      { ...slide('这条色散曲线由什么决定？', 'What sets the shape of this curve?', [2, 2, 2],
        [['看压强参数', 'Examine the pressure parameter'], ['对照粒子图', 'Relate the model to the dots']]), reading: 'model' },
      slide('从一个点读出波长、周期和相速度', 'Read wavelength, period and phase speed from a point', [3, 4]),
      slide('选三个分量，观察同一组电子', 'Choose three components and follow the electrons', [5]),
      { ...slide('哪些分量真正出现在波里？', 'Which components are present in the wave?', [5, 5, 5],
        [['写出合成密度', 'Write the combined density'], ['读出点阵的含义', 'Interpret the dots']]), reading: 'sum' }
    ]
  };
  const lessons = {
    1: ['motion', 'restoring'],
    2: ['measures', 'phase'],
    3: ['superposition'],
    4: ['complex'],
    5: ['dispersion']
  };
  const $ = id => document.getElementById(id);
  function fade(node) {
    node.classList.remove('lesson-fade');
    void node.offsetWidth;
    node.classList.add('lesson-fade');
  }
  function create(enter) {
    const lesson = Number($('lesson').dataset.page);
    const slides = lessons[lesson].flatMap(model => sections[model].map(item => ({ ...item, model })));
    let page = 0, step = 0, renderedPage, renderedStep, renderedLanguage, firstNewBlock;
    function readPosition() {
      const match = /^#slide-(\d+)-step-(\d+)$/.exec(location.hash);
      page = lesson === 5 && location.hash === '#superposition' ? slides.findIndex(item => item.stages[0] === 5) : 0;
      step = 0;
      if (!match) return;
      page = Math.max(0, Math.min(slides.length - 1, Number(match[1]) - 1));
      step = Math.max(0, Math.min(slides[page].stages.length - 1, Number(match[2]) - 1));
    }
    readPosition();
    function go(nextPage, nextStep, reset = false) {
      const changedPage = page !== nextPage;
      page = nextPage;
      step = nextStep;
      enter(slides[page].stages[step], reset);
      if (changedPage || reset) {
        window.scrollTo(0, 0);
      } else if (firstNewBlock) {
        const rect = firstNewBlock.getBoundingClientRect();
        const footer = document.querySelector('.controls').getBoundingClientRect();
        if (rect.top < 0 || rect.top > Math.min(innerHeight, footer.top) - 64) {
          firstNewBlock.scrollIntoView({ block: 'start' });
        }
      }
    }
    $('advance').addEventListener('click', () => {
      if (step + 1 < slides[page].stages.length) go(page, step + 1);
      else if (page + 1 < slides.length) go(page + 1, 0);
      else go(0, 0, true);
    });
    $('back').addEventListener('click', () => {
      if (step) go(page, step - 1);
      else if (page) go(page - 1, slides[page - 1].stages.length - 1);
    });
    $('restart-slide').addEventListener('click', () => go(page, 0, true));
    $('restart-lesson').addEventListener('click', () => go(0, 0, true));
    window.addEventListener('hashchange', () => {
      readPosition();
      enter(slides[page].stages[step], false);
    });
    function render(text, language) {
      const current = slides[page], en = language === 'en';
      const changedPage = page !== renderedPage || language !== renderedLanguage;
      const initial = renderedPage === undefined;
      firstNewBlock = null;
      $('lesson').dataset.slide = String(page + 1);
      $('lesson').dataset.build = String(step + 1);
      $('slide-label').textContent = text.chapter;
      if (changedPage) {
        $('title').textContent = current.title[language];
        $('narration').replaceChildren();
        if (!initial) fade($('title'));
      }
      const stages = current.reading ? [] : [...new Set(current.stages.slice(0, step + 1))];
      while ($('narration').childElementCount > stages.length) $('narration').lastElementChild.remove();
      stages.slice($('narration').childElementCount).forEach(stage => {
        const line = document.createElement('p');
        line.textContent = text.steps[stage];
        $('narration').append(line);
        firstNewBlock ||= line;
        if (!initial) fade(line);
      });
      document.querySelectorAll('.reading-panel [data-reveal-part]').forEach(node => {
        if (node.parentElement.closest('[hidden]')) return;
        const wasHidden = node.hidden;
        node.hidden = Number(node.dataset.revealPart) > step;
        if (!node.hidden && (wasHidden || changedPage)) {
          firstNewBlock ||= node;
          if (!initial) fade(node);
        }
      });
      const hasStep = step + 1 < current.stages.length, hasPage = page + 1 < slides.length;
      $('advance-kind').textContent = hasStep ? (en ? 'Next step' : '下一步') : hasPage ? (en ? 'Next slide' : '下一页') : (en ? 'Replay' : '重新学习');
      $('advance-text').textContent = hasStep ? (current.cues[step]?.[Number(en)] || text.actions[current.stages[step]]) :
        hasPage ? slides[page + 1].title[language] : text.chapter;
      $('back').hidden = !page && !step;
      $('back').textContent = step ? (en ? 'Back' : '上一步') : (en ? 'Prev slide' : '上一页');
      $('back').setAttribute('aria-label', $('back').textContent);
      $('restart-slide').textContent = en ? 'Slide start' : '本页起始';
      $('restart-lesson').textContent = en ? 'Lesson start' : '本课起始';
      $('stage-count').textContent = (en ? 'Slide ' : '幻灯片 ') + (page + 1) + ' / ' + slides.length;
      $('build-count').textContent = (en ? 'Step ' : '本页 ') + (step + 1) + ' / ' + current.stages.length;
      $('keyboard-note').textContent = en ? 'P play · F fullscreen' : 'P 播放 · F 全屏';
      const hash = '#slide-' + (page + 1) + '-step-' + (step + 1);
      if (location.hash !== hash) {
        try { history.replaceState(null, '', hash); } catch (_) { location.hash = hash; }
      }
      if (changedPage || renderedStep !== step) {
        const cue = current.cues[step - 1]?.[Number(en)];
        const description = current.reading ? current.title[language] : text.descriptions[current.stages[step]];
        $('status').textContent = [$('stage-count').textContent, $('build-count').textContent, cue, description].filter(Boolean).join('. ');
      }
      renderedStep = step;
      renderedPage = page;
      renderedLanguage = language;
    }
    return {
      render,
      get model() { return slides[page].model; },
      initialStage: slides[page].stages[step],
      get reading() { return slides[page].reading; },
      get finalBuild() { return step + 1 === slides[page].stages.length; }
    };
  }
  window.WaveSlides = { create, fade };
})();

/* Plasma-wave contribution history (Git author dates; edit time includes timezone).
 * 2026-11-19 15:22 +08:00 | Yinjian Zhao | git b32e8af2bb2b
 * 2026-11-19 16:01 +08:00 | Yinjian Zhao | git 2113cbc05ed4
 * 2026-11-19 16:28 +08:00 | Yinjian Zhao | edit (Codex-assisted)
 */
