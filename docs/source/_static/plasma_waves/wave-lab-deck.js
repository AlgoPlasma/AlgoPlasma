(() => {
  'use strict';
  const $ = id => document.getElementById(id);
  const slides = [...document.querySelectorAll('.lab-slide')];
  const parts = slides.map(slide => [...slide.querySelectorAll('.build-block')]);
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  let page = 0, step = 0, language, state, playing = false, frameId, previousTime;
  const section = () => slides[page];
  const scene = () => section().querySelector('.scene');
  const words = (zh,en) => language === 'en' ? en : zh;
  function stop() {
    playing = false;
    cancelAnimationFrame(frameId);
    previousTime = undefined;
  }
  function resetState() {
    stop();
    const kind = scene()?.dataset.kind;
    state = {probeK:16, time:0, energy:2, k:10, omega:kind==='frequency'?4:8,
      gamma:kind==='frequency'?0:-0.3, amplitude:0.5, overlay:false};
  }
  function syncFigure() {
    const fig = scene();
    if (!fig) return;
    const kind = fig.dataset.kind;
    const units = {energy:'eV', k:'rad/m', probeK:'rad/m', time:'s', omega:'rad/s', gamma:'s⁻¹', amplitude:'V/m'};
    for (const input of section().querySelectorAll('[data-param]')) {
      const key = input.dataset.param;
      if (input.type==='checkbox') {input.checked=state[key];continue;}
      input.value=state[key];
      let display=Number(state[key].toFixed(2))+' '+units[key];
      if (kind==='pressure' && key==='time') display=Math.round(100*state.time/4)+'%';
      if (kind==='field' && key==='time') display=(Math.round(state.time*31/4)*WaveLabModel.dt*1e9).toFixed(1)+' ns';
      const output=section().querySelector('[data-value="'+key+'"]');
      output.textContent=display;input.setAttribute('aria-valuetext',display);
    }
    const motion=section().querySelector('.motion');
    if (motion) {
      motion.textContent=playing?words('暂停','Pause'):words('播放','Play');
      motion.setAttribute('aria-pressed',String(playing));
    }
    const readout=section().querySelector('.reading');
    if (kind==='dispersion') {
      const w=WaveLabModel.warmOmega(state.k,state.energy)/1e8;
      readout.textContent=words('冷模型 1.0000，温模型 ','Cold 1.0000, warm ')+w.toFixed(4)+'  (10⁸ rad/s)';
    } else if (kind==='pair') {
      const peak=WaveLabPlots.peakAt('pair',state.amplitude,20);
      readout.textContent=words('第二个峰相对第一个峰','Second peak relative to first')+'  '+(peak.db < -40?'≤ −40':peak.db.toFixed(1))+' dB';
    } else if (kind==='overlay') {
      const peak=WaveLabPlots.peakAt('band',1,state.probeK);
      const theory=WaveLabModel.warmOmega(state.probeK,4);
      readout.textContent=peak.db < -40 ? words('这一列低于显示下限。','This column is below the color scale.') :
        words('白圈处的谱峰 ','Peak at the white circle ')+(peak.frequency/1e8).toFixed(4)+' × 10⁸ rad/s';
      if (state.overlay) {
        readout.textContent+=words(' · 理论 ',' · Theory ')+(theory/1e8).toFixed(4)+' × 10⁸ rad/s';
        if (peak.db>=-40) readout.textContent+=words(' · 相差 ',' · Difference ')+(Math.abs(theory-peak.frequency)/WaveLabModel.dw).toFixed(2)+words(' 格',' bins');
      }
    } else if (['frequency','growth','damped'].includes(kind)) {
      readout.textContent='ωᵣ = '+state.omega+' rad/s  ·  γ = '+state.gamma.toFixed(2)+' s⁻¹  ·  A(t) = '+Math.exp(state.gamma*state.time).toFixed(2)+' V/m';
    }
    const canvas=fig.querySelector('canvas');
    canvas.setAttribute('aria-label',fig.querySelector('figcaption .'+language).textContent);
    const supported=!!canvas.getContext('2d');
    fig.querySelector('.canvas-fallback').hidden=supported;
    canvas.hidden=!supported;
    if (supported) WaveLabPlots.draw(canvas,kind,state);
  }
  function animate(now) {
    if (!playing) return;
    const dt = previousTime===undefined ? 0 : Math.min(0.1,(now-previousTime)/1000);
    previousTime=now;
    state.time=Math.min(4,state.time+dt);
    if (state.time>=4) stop();
    syncFigure();
    if (playing) frameId=requestAnimationFrame(animate);
  }
  function togglePlay() {
    if (!section().querySelector('.motion')) return;
    if (playing) stop();
    else {
      if (state.time>=4) state.time=0;
      playing=true;frameId=requestAnimationFrame(animate);
    }
    syncFigure();
  }
  function showPosition(reason) {
    const current=section(), blocks=parts[page];
    slides.forEach((node,i)=>{node.hidden=i!==page;});
    blocks.forEach((block,i)=>{block.hidden=i>step;});
    $('lesson').dataset.slide=page+1;$('lesson').dataset.build=step+1;
    const more=step+1<blocks.length, next=page+1<slides.length;
    $('advance-kind').textContent=more?words('下一步','Next step'):next?words('下一页','Next slide'):words('从头回顾','Replay lesson');
    $('advance-text').textContent=!more && next?slides[page+1].querySelector('h1 .'+language).textContent:'';
    $('back').hidden=page===0 && step===0;
    $('back').textContent=step?words('上一步','Back a step'):words('上一页','Previous slide');
    $('stage-count').textContent=words('幻灯片 ','Slide ')+(page+1)+' / '+slides.length;
    $('build-count').textContent=words('本页 ','Step ')+(step+1)+' / '+blocks.length;
    $('progress').replaceChildren(...blocks.map((_,i)=>{
      const bar=document.createElement('i');bar.classList.toggle('filled',i<=step);return bar;
    }));
    $('status').textContent=$('stage-count').textContent+' · '+$('build-count').textContent;
    const url=new URL(location.href);
    url.searchParams.set('lang',language);
    url.hash='slide-'+(page+1)+'-step-'+(step+1);
    try {history.replaceState(null,'',url);} catch (_) {}
    if (reason==='reveal') {
      const block=blocks[step];
      if (!reduced.matches) block.animate([{opacity:0,transform:'translateY(6px)'},{opacity:1,transform:'none'}],{duration:850,easing:'ease-out'});
      const edge=getComputedStyle(document.querySelector('footer')).position==='sticky'
        ? document.querySelector('footer').getBoundingClientRect().top : innerHeight;
      if (block.getBoundingClientRect().bottom>edge) block.scrollIntoView({block:'start'});
    } else if (reason==='page') {
      window.scrollTo(0,0);
      current.querySelector('h1').focus({preventScroll:true});
      if (!reduced.matches) {
        for (const node of current.querySelectorAll('h1,.narration,.build-block:not([hidden])')) {
          node.animate([{opacity:0},{opacity:1}],{duration:700,easing:'ease-out'});
        }
      }
    } else if (reason==='back' || reason==='reset') window.scrollTo(0,0);
    syncFigure();
  }
  function enter(p,s,reason) {
    const changed=p!==page;
    page=p;step=s;
    if (changed || reason==='reset' || reason==='hash') resetState();
    showPosition(changed?'page':reason);
  }
  function readHash() {
    const m=/^#slide-(\d+)(?:-step-(\d+))?$/.exec(location.hash);
    const p=Math.max(0,Math.min(slides.length-1,Number(m?.[1]||1)-1));
    enter(p,Math.max(0,Math.min(parts[p].length-1,Number(m?.[2]||1)-1)),'hash');
  }
  function useLanguage(value,save) {
    language=value==='en'?'en':'zh';
    document.documentElement.lang=words('zh-CN','en');
    if (save) {try{localStorage.setItem('ap-doc-language',language);}catch(_){}}
    PlasmaNavigation.setLanguage(language);
    document.title=$('slide-label').querySelector('.'+language).textContent+' | AlgoPlasma';
    $('language-switch').setAttribute('aria-label',words('选择语言','Select language'));
    document.querySelectorAll('[data-language]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.language===language)));
  }
  $('advance').addEventListener('click',()=>{
    if (step+1<parts[page].length) enter(page,step+1,'reveal');
    else enter((page+1)%slides.length,0,'page');
  });
  $('back').addEventListener('click',()=>{
    if (step>0) enter(page,step-1,'back');
    else if (page>0) enter(page-1,parts[page-1].length-1,'page');
  });
  $('restart-slide').addEventListener('click',()=>enter(page,0,'reset'));
  $('restart-lesson').addEventListener('click',()=>enter(0,0,'reset'));
  for (const button of document.querySelectorAll('[data-language]')) button.addEventListener('click',()=>{
    useLanguage(button.dataset.language,true);showPosition('language');
  });
  for (const button of document.querySelectorAll('.motion')) button.addEventListener('click',togglePlay);
  document.addEventListener('input',event=>{
    const key=event.target.dataset.param;
    if (!key) return;
    if (key==='time') stop();
    state[key]=event.target.type==='checkbox'?event.target.checked:Number(event.target.value);
    syncFigure();
  });
  document.addEventListener('keydown',async event=>{
    if (event.ctrlKey || event.altKey || event.metaKey || event.shiftKey || event.repeat || event.target.closest('input,select,textarea,[contenteditable]')) return;
    if (event.key.toLowerCase()==='p') togglePlay();
    if (event.key.toLowerCase()==='f') {
      try {if(document.fullscreenElement) await document.exitFullscreen();else await document.documentElement.requestFullscreen();}
      catch (_) {$('status').textContent=words('当前预览不能全屏。','Fullscreen is unavailable in this view.');}
    }
  });
  reduced.addEventListener('change',()=>{if(reduced.matches){stop();syncFigure();}});
  document.addEventListener('visibilitychange',()=>{if(document.hidden){stop();syncFigure();}});
  window.addEventListener('hashchange',readHash);
  let initial=new URLSearchParams(location.search).get('lang');
  if (!['zh','en'].includes(initial)) {try {initial=localStorage.getItem('ap-doc-language');}catch(_){}}
  useLanguage(initial,false);
  readHash();
  const resize=new ResizeObserver(entries=>{
    if (entries.some(entry=>entry.target===scene()?.querySelector('canvas'))) syncFigure();
  });
  document.querySelectorAll('canvas').forEach(node=>resize.observe(node));
})();
