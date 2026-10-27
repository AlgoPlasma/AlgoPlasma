/* Synthetic 3, 5, 8 Hz records, T=1 s, N=128; each positive-frequency
 * coefficient has unit magnitude. The renderer uses their exact coefficients,
 * not an estimated FFT. No plasma dynamics or energy transfer is simulated.
 */
(function () {
  "use strict";
  var words = {
    en: {
      title: "Same powers, different phase relations", mode: "Phase relation across records",
      fixed: "Fixed phase relation", random: "Independent phases", count: "Number of records R",
      offset: "Phase offset δ", redraw: "New phases", reset: "Reset",
      left: "1. One arrow per product Z", right: "2. Magnitude of the running mean",
      bottom: "3. The three bin powers stay equal to 1", records: "Records averaged n",
      one: "Grey: individual products", mean: "Orange: their mean B",
      phase: "Phase of B", undefined: "undefined", power: "Powers", seed: "Seed",
      alt: "Complex arrows for individual three-frequency products and their mean, the magnitude of the mean as more records are averaged, and three unchanged power bars."
    },
    zh: {
      title: "功率相同，相位关系不同", mode: "不同记录之间的相位关系",
      fixed: "相位关系固定", random: "相位彼此独立", count: "平均的记录数 R",
      offset: "相位偏移 δ", redraw: "换一组相位", reset: "重置",
      left: "1. 每个三频乘积 Z 对应一支箭头", right: "2. 累积平均值的模",
      bottom: "3. 三个频点的功率始终等于 1", records: "参与平均的记录数 n",
      one: "灰色：各段的乘积", mean: "橙色：它们的平均值 B",
      phase: "B 的相位", undefined: "无定义", power: "功率", seed: "种子",
      alt: "各段三频乘积及其平均值在复平面上的箭头，随记录数增加的平均值模，以及三个保持不变的功率柱。"
    }
  };
  function makeRecords(mode, deltaDegrees, seed, count) {
    var state=seed>>>0, delta=deltaDegrees*Math.PI/180, result=[];
    function uniform() { state=(1664525*state+1013904223)>>>0; return state/4294967296; }
    for(var r=0;r<count;r+=1) {
      var p1=2*Math.PI*uniform(), p2=2*Math.PI*uniform(), independent=2*Math.PI*uniform();
      var p3=(mode==="fixed" ? p1+p2 : independent)-delta;
      var phase=p1+p2-p3;
      result.push({phases:[p1,p2,p3],re:Math.cos(phase),im:Math.sin(phase)});
    }
    return result;
  }
  function runningMeans(records) {
    var re=0,im=0;
    return records.map(function(z,i) {
      re+=z.re; im+=z.im;
      var x=re/(i+1),y=im/(i+1);
      return {re:x,im:y,magnitude:Math.hypot(x,y),b2:x*x+y*y};
    });
  }
  function text(x,y,value,anchor,colour) {
    return '<text x="'+x+'" y="'+y+'" text-anchor="'+(anchor||'start')+'" fill="'+(colour||'#334155')+'">'+value+'</text>';
  }
  function arrow(x,y,colour,width,opacity) {
    var length=Math.hypot(x,y), px=197+110*x, py=175-110*y;
    if(length<1e-10)return '<circle cx="197" cy="175" r="3" fill="'+colour+'"/>';
    var ux=x/length,uy=-y/length,backX=px-8*ux,backY=py-8*uy;
    return '<g opacity="'+opacity+'"><path d="M197 175L'+px.toFixed(2)+' '+py.toFixed(2)+'" stroke="'+colour+'" stroke-width="'+width+'"/>'+
      '<path d="M'+px.toFixed(2)+' '+py.toFixed(2)+'L'+(backX-4*uy).toFixed(2)+' '+(backY+4*ux).toFixed(2)+'L'+(backX+4*uy).toFixed(2)+' '+(backY-4*ux).toFixed(2)+'Z" fill="'+colour+'"/></g>';
  }
  function plotSvg(mode, delta, seed, count, lang, prefix) {
    var w=words[lang]||words.en, records=makeRecords(mode,delta,seed,count), means=runningMeans(records),mean=means[count-1];
    var s='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 780 500" role="img" aria-labelledby="'+prefix+'-title">'+
      '<title id="'+prefix+'-title">'+w.alt+'</title><rect width="780" height="500" fill="white"/>'+
      '<g font-family="sans-serif" font-size="14">'+text(36,26,w.left)+text(424,26,w.right)+
      '<circle cx="197" cy="175" r="110" fill="none" stroke="#cbd5e1"/>'+
      '<path d="M65 175H329 M197 43V307" stroke="#cbd5e1"/>'+
      text(330,170,'Re Z','end')+text(207,51,'Im Z')+text(87,194,'−1','middle')+text(307,194,'1','middle')+
      text(187,72,'1','end')+text(187,290,'−1','end');
    records.forEach(function(z){s+=arrow(z.re,z.im,'#64748b',1.1,.22);});
    s+=arrow(mean.re,mean.im,'#a34508',3.5,1)+text(36,333,w.one)+text(36,355,w.mean,'start','#a34508');
    [0,.5,1].forEach(function(v){
      var y=285-215*v;
      s+='<path d="M440 '+y+'H746" stroke="#e2e8f0"/>'+text(432,y+5,String(v),'end');
    });
    s+=text(440,54,'|Bₙ|')+'<path d="M440 65V285H746" fill="none" stroke="#94a3b8"/>';
    [1,32,64,96,128].forEach(function(n){s+=text(440+306*(n-1)/127,307,String(n),'middle');});
    var path=means.map(function(m,i){return (i?'L':'M')+(440+306*i/127).toFixed(2)+' '+(285-215*m.magnitude).toFixed(2);}).join(' ');
    var cursor=440+306*(count-1)/127;
    s+='<path d="'+path+'" fill="none" stroke="#a34508" stroke-width="2.5"/>'+
      '<path d="M'+cursor+' 65V285" stroke="#64748b" stroke-dasharray="3 4"/>'+
      '<circle cx="'+cursor+'" cy="'+(285-215*mean.magnitude)+'" r="4" fill="#a34508"/>'+
      text(593,333,w.records,'middle')+text(593,355,'|B| = '+mean.magnitude.toFixed(3),'middle');
    s+=text(36,387,w.bottom);
    [3,5,8].forEach(function(f,i){
      var x=150+240*i;
      s+='<rect x="'+(x-28)+'" y="411" width="56" height="40" rx="2" fill="#216b96"/>'+
        text(x,406,'1','middle')+text(x,475,'P('+f+' Hz)','middle');
    });
    return s+'</g></svg>';
  }
  if(typeof module!=="undefined"&&module.exports) {
    module.exports={makeRecords:makeRecords,runningMeans:runningMeans,plotSvg:plotSvg}; return;
  }
  function initialize(host,index) {
    var lang=host.getAttribute('data-k05-statistics'),w=words[lang]||words.en,prefix='k05-statistics-'+index,seed=7;
    var ui=document.createElement('div');
    ui.innerHTML='<p class="k05-statistics-title">'+w.title+'</p><div class="k05-statistics-controls">'+
      '<label for="'+prefix+'-mode">'+w.mode+'<select id="'+prefix+'-mode" aria-label="'+w.mode+'" data-mode><option value="fixed">'+w.fixed+'</option><option value="random">'+w.random+'</option></select></label>'+
      '<label for="'+prefix+'-count">'+w.count+'<input id="'+prefix+'-count" data-count type="range" min="1" max="128" step="1" value="32"></label>'+
      '<label for="'+prefix+'-offset">'+w.offset+'<input id="'+prefix+'-offset" data-offset type="range" min="-180" max="180" step="15" value="60"></label>'+
      '<button type="button" data-redraw>'+w.redraw+'</button><button type="button" data-reset>'+w.reset+'</button></div>'+
      '<p class="k05-statistics-readout" aria-live="polite"></p><div data-plot></div>';
    var mode=ui.querySelector('[data-mode]'),count=ui.querySelector('[data-count]'),offset=ui.querySelector('[data-offset]');
    function draw() {
      var n=Number(count.value),d=Number(offset.value),mean=runningMeans(makeRecords(mode.value,d,seed,n))[n-1];
      ui.querySelector('[data-plot]').innerHTML=plotSvg(mode.value,d,seed,n,lang,prefix);
      var phase=mean.magnitude<1e-10?w.undefined:(Math.atan2(mean.im,mean.re)*180/Math.PI).toFixed(1)+'°';
      ui.querySelector('.k05-statistics-readout').textContent='R = '+n+' · δ = '+d+'° · |B| = '+mean.magnitude.toFixed(3)+' · '+w.phase+' = '+phase+' · '+w.seed+' = '+seed;
      count.setAttribute('aria-valuetext',String(n));offset.setAttribute('aria-valuetext',d+'°');
    }
    mode.addEventListener('change',draw);count.addEventListener('input',draw);offset.addEventListener('input',draw);
    ui.querySelector('[data-redraw]').addEventListener('click',function(){seed=(seed+1)>>>0;draw();});
    ui.querySelector('[data-reset]').addEventListener('click',function(){seed=7;mode.value='fixed';count.value='32';offset.value='60';draw();});
    draw();host.replaceChildren(ui);
  }
  function start(){document.querySelectorAll('[data-k05-statistics]').forEach(initialize);}
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',start);else start();
}());
