(function () {
  "use strict";
  const D=window.DsmcDemo,$=id=>document.getElementById(id);
  const n=(x,digits=3)=>Number.isFinite(x)?x.toFixed(digits):"无";
  const vec=v=>"("+v.map(x=>Math.abs(x)>0&&Math.abs(x)<.001?x.toExponential(2):n(x)).join(", ")+")";
  const small=x=>x.toExponential(2);
  const names={rejected:"空候选",elastic:"弹性",coulomb:"屏蔽散射",excitation:"激发",ionization:"单次电离",cex:"电荷交换"};
  const local=["cell","clock","pair","accept","channel","scatter","commit","reject"];
  const titles={ready:"从位置和速度开始",flight:"自由飞行，遇墙后处理剩余时间",regroup:"按新位置重建胞元成员",
    cell:"处理一个碰撞胞元",clock:"确定下一候选时刻",pair:"随机选出两个不同粒子",accept:"接受或拒绝候选",
    channel:"按核占比选择通道",scatter:"计算拟议末态",commit:"共同提交碰后状态",reject:"空候选：状态不变",sample:"本步结束"};
  const duration=1700,reduced=window.matchMedia("(prefers-reduced-motion: reduce)");
  let sim,live,reviewId=null,reviewing=false,liveView=null,busy=false,cancelRun=false;
  let running=false,frame=0,age=duration,progress=1,lastFrame=0,focusId=null,unit=1;
  let lab,labConfig,labSeed=314159;
  const xy=x=>[100+200*x[0],480-200*x[1]];
  const amplify=p=>$("arrows").checked&&p.species!=="electron"?Math.sqrt(sim.c.massRatio):1;

  function description() {
    const e=sim.event;
    switch(sim.phase) {
      case "ready":return sim.c.scenario==="ionization"?"一个原子与一个电子；预设种子在首步产生电离。修改参数后结果可能改变。":"先无外力飞行，再按位置分组，最后在胞元内抽样碰撞。";
      case "flight":return sim.c.wall==="reflect"?"求最早撞壁时刻，反射法向速度，再走完剩余时间。内部胞元线可以穿越。":"飞行到墙面的粒子被吸收；其余粒子走完本步。点选粒子可单独查看轨迹。";
      case "regroup":return "按运输后的位置生成成员表，圈出跨胞元粒子，移除已吸收者。";
      case "cell":return "依次处理全部胞元，从当前成员表抽样碰撞伙伴。";
      case "clock":return sim.hasCandidate?"等待时间落在剩余子步内，接下来均匀选对。":"等待时间超出剩余子步，或成员不足两个；转到下一胞元。";
      case "pair":return "从成员表均匀选取两个不同 ID，橙虚线连接本次候选。";
      case "accept":return e.accepted?"R < q/M，接受候选；再选择物理通道。":"R ≥ q/M，拒绝候选，保留双方状态并继续候选时钟。";
      case "channel":return "通道概率与各自 σg 成正比。低于阈值的反应权重为零。";
      case "scatter":case "commit":
        return e.channel.key==="ionization"?"e + A → e + e + A⁺：联合计算三体末态。新电子与离子共享位置，以同心符号表示。":
          e.channel.key==="excitation"?"相对平动能转入原子内部能；A* 仍是同一种原子。":
          e.channel.key==="cex"?"交换带电身份，并按最终质量守恒重建速度。":
          "质心动量与弹性相对速率保持不变；抽样出射方向，再重建双方速度。";
      case "reject":return "空候选也消耗候选时间。随后按当前成员和状态建立下一时钟。";
      case "sample":return "所有胞元完成碰撞；下一步才用更新后的速度继续飞行。";
    }
  }
  function calculation() {
    const e=sim.event;
    switch(sim.phase) {
      case "ready":return "Δt = "+n(sim.c.dt)+" · 种子 "+sim.c.seed+" · 等权重 W = 1";
      case "flight":return "x′ = x + v δt；撞壁后继续 Δt − t撞";
      case "regroup":return "本步跨胞元 "+sim.moves.length+" 个；吸收 "+sim.traces.filter(t=>!t.alive).length+" 个";
      case "cell":return "胞元 "+(sim.cell+1)+" · N = "+sim.cells[sim.cell].length+" · V = 1";
      case "clock":return "Λ = N(N−1)M/2 = "+n(sim.frequency)+"；δτ = "+n(sim.waiting,5)+"；剩余 "+n(sim.remaining,5);
      case "pair":return "g = "+n(e.rates.g)+"；E相对 = "+n(e.rates.energy)+" eV；q = "+n(e.rates.total);
      case "accept":case "reject":return "q/M = "+n(e.probability,5)+"；R = "+n(e.acceptanceDraw,5)+" → "+(e.accepted?"接受":"拒绝");
      case "channel":return "R通道 = "+n(e.channelDraw,5)+" → "+e.channel.name;
      case "scatter":case "commit": {
        const a=D.budget(e.before,sim.c),b=D.budget(e.after,sim.c);
        return "K："+n(a.kinetic)+" → "+n(b.kinetic)+"；U："+n(a.internal)+" → "+n(b.internal)+" eV";
      }
      case "sample":return "t = "+n(sim.step*sim.c.dt)+"；粒子与壁面能量收支残差 "+small(sim.balance().energy);
    }
  }
  function comparison(e) {
    const state=p=>p?D.label(p)+"<br><span class=\"velocity\">"+vec(p.v)+"</span><br>U = "+n(D.internal(p))+" eV":"不存在";
    return [...new Set([...e.before,...e.after].map(p=>p.id))].map(id=>{
      const a=e.before.find(p=>p.id===id),b=e.after.find(p=>p.id===id),changes=[];
      if(!a)changes.push("新增粒子");
      else if(!b)changes.push("移除");
      else {
        if(a.species!==b.species)changes.push(D.label(a)+" → "+D.label(b));
        if(a.v.some((v,k)=>Math.abs(v-b.v[k])>1e-12))changes.push("速度改变");
        if(Math.abs(D.internal(a)-D.internal(b))>1e-12)changes.push("内能改变");
      }
      return '<tr'+(!a?' class="newborn"':"")+"><td>#"+id+"</td><td>"+state(a)+"</td><td>"+state(b)+"</td><td>"+(changes.join("<br>")||"不变")+"</td></tr>";
    }).join("");
  }
  function population(ps) {
    $("population").textContent=Object.entries(D.SPECIES).map(([key,s])=>s.label+" "+ps.filter(p=>p.species===key).length).join(" / ");
  }
  function updateText() {
    const e=sim.event,phase=sim.phase;
    $("clock").textContent=(reviewing?"回看 · ":"")+"时间步 "+sim.step+(local.includes(phase)?" · 胞元 "+(sim.cell+1)+" · 候选 "+sim.candidate:"");
    population(sim.particles);
    $("phase-title").textContent=titles[phase];$("explanation").textContent=description();$("calculation").textContent=calculation();
    document.querySelectorAll("[data-phase]").forEach(el=>{
      const active=el.dataset.phase===(local.includes(phase)?"collision":phase);
      el.classList.toggle("active",active);
      if(active)el.setAttribute("aria-current","step");else el.removeAttribute("aria-current");
    });
    $("stage-data").textContent=phase==="regroup"?sim.moves.slice(0,6).map(m=>"#"+m.id+"："+(m.from+1)+" → "+(m.to+1)).join("；"):"";
    $("pair-matrix").innerHTML=Object.entries(D.PAIRS).map(([key,p])=>'<div class="pair-card'+(e&&e.rates.key===key?" active":"")+'"><strong>'+p.label+" · "+sim.pairCounts[key]+"</strong>"+p.description+"</div>").join("");
    $("randoms").innerHTML=sim.draws.length?sim.draws.map(r=>"<li><span>"+r.label+(r.discarded?"（丢弃）":"")+"</span><span>"+n(r.value,8)+"</span></li>").join(""):"<li>尚无候选随机数。</li>";
    $("channels").innerHTML=e?e.rates.channels.map(ch=>{
      const f=e.rates.total?ch.rate/e.rates.total:0;
      return '<div class="channel'+(e.channel&&e.channel.key===ch.key?" selected":"")+'">'+ch.name+" · "+n(f*100,1)+"%"+'<div class="channel-track"><div class="channel-fill" style="width:'+f*100+'%"></div></div></div>';
    }).join(""):"尚未选对。";
    const hasOutcome=e&&e.after&&e.accepted;
    $("event-preview").hidden=!hasOutcome;
    if(hasOutcome) {
      $("states").innerHTML=comparison(e);
      $("event-title").textContent=(e.channel?e.channel.name:"空候选")+"："+(phase==="scatter"?"拟议末态":"前后对照");
      $("event-context").textContent="步 "+sim.step+" · 胞元 "+(sim.cell+1)+" · "+D.PAIRS[e.rates.key].label+" · 入射粒子 #"+e.ids.join(" / #")+"。箭头在本事件内统一缩放；表中速度为真实三维分量（v₀）。";
      const a=D.budget(e.before,sim.c),b=D.budget(e.after,sim.c);
      $("collision-budget").textContent="Δ(K+U) = "+small(b.total-a.total)+" eV · |Δp| = "+small(Math.sqrt(D.norm2(D.sub(b.momentum,a.momentum))))+" · ΔQ = "+(b.charge-a.charge);
    }
    const b=sim.balance(),l=sim.ledger;
    $("conservation").textContent="能量收支残差 "+small(b.energy)+"；动量收支残差 "+small(Math.sqrt(D.norm2(b.momentum)))+"；电荷 / 核数残差 "+b.charge+" / "+b.nuclei+"。撞壁 "+l.hits+" 次，吸收 "+l.absorbed+" 个。";
    $("totals").textContent="候选 "+sim.counts.tested+" · "+Object.entries(sim.counts).filter(([k])=>k!=="tested").map(([k,v])=>names[k]+" "+v).join(" · ");
  }
  function arrow(parts,point,v,color,factor=1,ghost=false,padding=0) {
    const dx=v[0]*factor,dy=-v[1]*factor,len=Math.hypot(dx,dy);
    if(len<.02)return;
    const ux=dx/len,uy=dy/len,start=[point[0]+padding*ux,point[1]+padding*uy];
    const x=start[0]+dx,y=start[1]+dy,s=Math.min(7,len*.4);
    parts.push('<path d="M'+start[0]+","+start[1]+" L"+x+","+y+'" fill="none" stroke="'+color+'" stroke-width="'+(ghost?1.5:2.3)+'"'+(ghost?' stroke-dasharray="4 3"':"")+"/>");
    parts.push('<path d="M'+(x-s*ux+s*.45*uy)+","+(y-s*uy-s*.45*ux)+" L"+x+","+y+" L"+(x-s*ux-s*.45*uy)+","+(y-s*uy+s*.45*ux)+'" fill="none" stroke="'+color+'" stroke-width="2"/>');
  }
  function marker(parts,point,p,radius=10) {
    const color=D.SPECIES[p.species].color;
    parts.push('<circle cx="'+point[0]+'" cy="'+point[1]+'" r="'+radius+'" fill="'+color+'" stroke="white" stroke-width="1.5"/>');
    parts.push('<text x="'+point[0]+'" y="'+(point[1]+4)+'" text-anchor="middle" font-size="13" font-weight="bold" fill="white">'+(p.species==="electron"?"−":p.species==="ion"?"+":p.eps?"*":"A")+"</text>");
  }
  function drawEvent() {
    const e=sim.event;if(!e||!e.after)return;
    const ids=[...new Set([...e.before,...e.after].map(p=>p.id))],parts=[];
    const eventScale=44/Math.max(1e-12,...[...e.before,...e.after].map(p=>Math.hypot(p.v[0],p.v[1])*amplify(p)));
    ids.forEach((id,i)=>{
      const center=800/ids.length*(i+.5),a=e.before.find(p=>p.id===id),b=e.after.find(p=>p.id===id);
      parts.push('<text x="'+center+'" y="22" text-anchor="middle" font-size="18">#'+id+" "+(a?D.label(a)+" → ":"新增 ")+D.label(b)+"</text>");
      for(const [p,x,color,text] of [[a,center-48,"#869491","碰前"],[b,center+48,D.SPECIES[b.species].color,"碰后"]]) {
        parts.push('<text x="'+x+'" y="172" text-anchor="middle" font-size="16">'+text+"</text>");
        if(p){arrow(parts,[x,95],p.v,color,eventScale*amplify(p),false,10);marker(parts,[x,95],p,8);}
        else parts.push('<text x="'+x+'" y="100" text-anchor="middle" fill="#869491">无</text>');
      }
    });
    $("event-velocities").innerHTML=parts.join("");
  }
  function draw() {
    const phase=sim.phase,e=sim.event,time=progress*sim.c.dt;
    const display=phase==="flight"?sim.traces.map(t=>D.stateAt(t,time)).filter(Boolean):sim.particles;
    if(phase==="flight")population(display);
    const parts=['<rect x="100" y="80" width="600" height="400" fill="#fbfcfa"/>'];
    if(local.includes(phase))parts.push('<rect x="'+(100+200*(sim.cell%3))+'" y="'+(280-200*Math.floor(sim.cell/3))+'" width="200" height="200" fill="#e3f0df"/>');
    parts.push('<path d="M300,80 v400 M500,80 v400 M100,280 h600" stroke="#829ba4" stroke-width="1.5" stroke-dasharray="7 6"/>');
    for(let cell=0;cell<6;cell++){
      const x=110+200*(cell%3),y=105+200*(1-Math.floor(cell/3));
      const count=display.filter(p=>D.cellOf(p)===cell).length;
      parts.push('<text x="'+x+'" y="'+y+'" font-size="18" fill="#5b747a">'+(cell+1)+(phase==="regroup"||local.includes(phase)||phase==="sample"?" · N="+count:"")+"</text>");
    }
    const trace=sim.traces.find(t=>t.before.id===focusId);
    if(trace&&["flight","regroup"].includes(phase)) {
      const until=phase==="flight"?time:sim.c.dt;
      trace.segments.filter(s=>s.t0<=until).forEach(s=>{
        const frac=s.t1===s.t0?1:Math.min(1,(until-s.t0)/(s.t1-s.t0));
        const a=xy(s.start),b=xy(s.start.map((x,k)=>x+frac*(s.end[k]-x)));
        parts.push('<path d="M'+a.join(",")+" L"+b.join(",")+'" fill="none" stroke="'+D.SPECIES[trace.before.species].color+'" stroke-width="2.5" stroke-dasharray="5 4" opacity=".6"/>');
      });
      trace.hits.filter(h=>h.time<=until).forEach(h=>{
        const p=xy(h.point);
        parts.push('<path d="M'+(p[0]-6)+","+(p[1]-6)+" l12,12 m-12,0 l12,-12"+'" stroke="#bc4b36" stroke-width="3"/>');
      });
    }
    parts.push('<rect x="100" y="80" width="600" height="400" fill="none" stroke="#334744" stroke-width="3"/>');
    if(e)parts.push('<path d="M'+xy(e.before[0].x).join(",")+" L"+xy(e.before[1].x).join(",")+'" stroke="#c78d35" stroke-width="2" stroke-dasharray="6 5"/>');
    const clusters=new Map(),labels=[];
    display.forEach(p=>{
      const key=p.x[0].toFixed(9)+":"+p.x[1].toFixed(9);
      if(!clusters.has(key))clusters.set(key,[]);clusters.get(key).push(p);
    });
    for(const cluster of clusters.values()) {
      const point=xy(cluster[0].x);
      const selected=cluster.some(p=>e&&e.ids.includes(p.id)),focused=cluster.some(p=>p.id===focusId);
      const moved=phase==="regroup"&&cluster.some(p=>sim.moves.some(m=>m.id===p.id));
      const born=cluster.some(p=>p.born);
      parts.push('<g opacity="'+(e&&!selected&&!born?.32:1)+'">');
      if(selected||focused||moved||born)parts.push('<circle cx="'+point[0]+'" cy="'+point[1]+'" r="18" fill="none" stroke="'+(moved?"#326cc5":"#bd8530")+'" stroke-width="2"/>');
      for(const p of cluster) {
        const old=phase==="commit"&&e?e.before.find(a=>a.id===p.id):null;
        if(old)arrow(parts,point,old.v,"#939e98",unit*amplify(old),true,cluster.length>1?15:12);
        arrow(parts,point,p.v,D.SPECIES[p.species].color,unit*amplify(p),false,cluster.length>1?15:12);
      }
      // Co-located products share the true anchor for both glyphs and velocity arrows.
      cluster.slice().sort((a,b)=>D.mass(b,sim.c)-D.mass(a,sim.c)).forEach((p,i)=>{
        parts.push('<g data-particle="'+p.id+'" tabindex="0" role="button" aria-label="粒子 '+p.id+' '+D.label(p)+'"><title>#'+p.id+" "+D.label(p)+"；v="+vec(p.v)+"</title>");
        marker(parts,point,p,cluster.length>1?(i===0?13:7):10);
        parts.push("</g>");
      });
      if(selected||focused||moved||born) {
        const topOfCell=80+200*(1-Math.min(1,Math.floor(cluster[0].x[1])));
        const labelY=point[1]-20<topOfCell+28?point[1]+31:point[1]-20;
        labels.push({point,y:labelY,text:cluster.map(p=>"#"+p.id).join("/")+(cluster.length>1?" 同位置":"")});
      }
      parts.push("</g>");
    }
    // Nearby collision partners need separate label lanes, not displaced particle positions.
    const occupied=[];
    labels.forEach(label=>{
      const width=Array.from(label.text).reduce((sum,c)=>sum+(c.charCodeAt(0)>255?17:10),0)+8;
      const x=Math.max(45+width/2,Math.min(755-width/2,label.point[0]));
      const candidates=[label.y,label.point[1]+31,label.point[1]-24,label.point[1]+54,label.point[1]-47];
      let y=label.y;
      for(const candidate of candidates){
        const box={left:x-width/2,right:x+width/2,top:candidate-18,bottom:candidate+5};
        if(candidate<28||candidate>500||occupied.some(b=>box.left<b.right&&box.right>b.left&&box.top<b.bottom&&box.bottom>b.top))continue;
        y=candidate;occupied.push(box);break;
      }
      parts.push('<text x="'+x+'" y="'+y+'" text-anchor="middle" font-size="17" fill="#2a4143" stroke="#fbfcfa" stroke-width="3" paint-order="stroke">'+label.text+"</text>");
    });
    parts.push('<text x="100" y="54" font-size="17" fill="#5b747a">y ↑</text><text x="690" y="514" font-size="17" fill="#5b747a">x →</text>');
    parts.push('<text x="100" y="535" font-size="17" fill="#5b747a">'+(phase==="flight"?"飞行进度 "+n(progress*100,0)+"%":local.includes(phase)?"碰撞阶段位置不变":"位置投影 x–y")+"</text>");
    $("scene").innerHTML=parts.join("");
    $("arrow-scale").textContent="x–y 投影 · 箭头标尺本轮固定"+($("arrows").checked?" · 重粒子箭头 ×"+n(Math.sqrt(sim.c.massRatio),1):" · 各物种共用速度标尺")+" · 点选粒子查看轨迹";
    const p=display.find(p=>p.id===focusId);
    $("focus-info").textContent=p?"#"+p.id+" "+D.label(p)+" · 胞元 "+(D.cellOf(p)+1)+" · v = "+vec(p.v):
      focusId&&trace&&!trace.alive?"#"+focusId+" 已被壁面吸收，t撞 = "+n(trace.hits[0].time,5):"";
    drawEvent();
  }
  function histogram(id,values,lo,hi,bins,label,theory,height=300,reference=null) {
    const left=52,width=275,top=32,bottom=height-50,plotHeight=bottom-top,range=hi-lo;
    const counts=Array(bins).fill(0);
    values.forEach(v=>counts[Math.min(bins-1,Math.max(0,Math.floor((v-lo)/range*bins)))]++);
    const probabilities=counts.map(x=>x/values.length);
    const expected=theory?counts.map((_,i)=>theory(lo+i*range/bins,lo+(i+1)*range/bins)):null;
    const max=Math.max(...probabilities,...(expected||[]),reference||0,.01)*1.15,parts=[];
    for(let k=0;k<=4;k++) {
      const y=bottom-k*plotHeight/4;
      parts.push('<path d="M'+left+","+y+' h275" stroke="#e3e9e4"/><text x="46" y="'+(y+4)+'" text-anchor="end" font-size="11">'+n(k*max*25,1)+"%</text>");
    }
    probabilities.forEach((p,i)=>{
      const h=p/max*plotHeight;
      parts.push('<rect x="'+(left+i*width/bins+1)+'" y="'+(bottom-h)+'" width="'+(width/bins-2)+'" height="'+h+'" fill="#6aa99b"><title>['+n(lo+i*range/bins,3)+", "+n(lo+(i+1)*range/bins,3)+"]："+counts[i]+" 次</title></rect>");
    });
    if(expected)parts.push('<polyline points="'+expected.map((p,i)=>(left+(i+.5)*width/bins)+","+(bottom-p/max*plotHeight)).join(" ")+'" fill="none" stroke="#b56d28" stroke-width="2.5"/>');
    if(reference)parts.push('<path d="M52,'+(bottom-reference/max*plotHeight)+' h275" stroke="#566d86" stroke-width="2" stroke-dasharray="5 4"/>');
    parts.push('<text x="52" y="'+(bottom+19)+'" font-size="11">'+n(lo,range<.01?5:2)+'</text><text x="327" y="'+(bottom+19)+'" text-anchor="end" font-size="11">'+n(hi,range<.01?5:2)+'</text><text x="190" y="'+(height-7)+'" text-anchor="middle" font-size="12">'+label+'</text><text x="52" y="18" font-size="11">各区间概率'+(theory?" · 橙线：理论":"")+"</text>");
    $(id).innerHTML=parts.join("");
  }
  function rateCurve(heavy) {
    const points = [], parts = [];
    const relative = D.relative(...lab.initial, labConfig);
    const exponent = labConfig.elastic === "HS" ? 1 : 2 - 2 * labConfig.omega;
    // Include the selected speed even for a physical heavy/electron mass ratio.
    const lo = Math.min(0.25, relative.g), hi = Math.max(4, relative.g);
    const rateAt = g => heavy ? Math.pow(g, exponent) : D.rates(
      ...D.labPair($("lab-pair").value, 0.5 * relative.mu * g * g, labConfig),
      labConfig
    ).channels[0].rate;
    for (let i = 0; i <= 80; i++) {
      const g = lo + i * (hi - lo) / 80;
      points.push({ g, rate: rateAt(g) });
    }
    const current = { g: relative.g, rate: rateAt(relative.g) };
    points.push(current);
    points.sort((a, b) => a.g - b.g);
    const max = Math.max(...points.map(p => p.rate)) * 1.15;
    const px = g => 52 + (g - lo) / (hi - lo) * 275;
    const py = q => 250 - q / max * 210;
    for(let k=0;k<=4;k++)parts.push('<path d="M52,'+(250-k*52.5)+' h275" stroke="#e3e9e4"/><text x="46" y="'+(254-k*52.5)+'" text-anchor="end" font-size="11">'+n(k*max/4,2)+"</text>");
    parts.push('<polyline points="'+points.map(p=>px(p.g)+","+py(p.rate)).join(" ")+'" fill="none" stroke="#16786b" stroke-width="3"/>');
    parts.push('<path d="M'+px(current.g)+',250 V'+py(current.rate)+' H52" fill="none" stroke="#b56d28" stroke-dasharray="4 4"/>');
    parts.push('<circle id="rate-current" cx="'+px(current.g)+'" cy="'+py(current.rate)+'" r="5" fill="#b56d28" stroke="white" data-g="'+current.g+'" data-rate="'+current.rate+'"><title>当前入射条件：g₀/v₀ = '+n(current.g,4)+'；'+(heavy?'q(g₀)/q(v₀)':'q(g₀)')+' = '+n(current.rate,4)+'</title></circle>');
    parts.push('<text x="52" y="18" font-size="12">'+(heavy?"q(g) / q(v₀)":"q(g)，教学单位")+'</text><text x="52" y="35" font-size="11" fill="#9c591c">橙点：当前初态 ('+n(current.g,4)+', '+n(current.rate,4)+')</text><text x="52" y="271" font-size="11">'+n(lo,3)+'</text><text x="327" y="271" text-anchor="end" font-size="11">'+n(hi,2)+'</text><text x="190" y="293" text-anchor="middle" font-size="12">相对速率 g / v₀</text>');
    $("rate-chart").innerHTML=parts.join("");
  }
  function updateSample() {
    if(!lab)return;
    const i=Number($("sample-index").value)-1,s=lab.samples[i],pair=lab.initial;
    const target=D.scale(D.sub(s.incoming,s.v),D.mass(pair[0],labConfig)/D.mass(pair[1],labConfig));
    $("lab-sample").textContent="样本 "+(i+1)+" · 入射 g/v₀ = "+n(s.g)+" · cosχ = "+n(s.mu)+"；碰后速度 / v₀：粒子 1（"+D.label(pair[0])+"）"+vec(s.v)+"；粒子 2（"+D.label(pair[1])+"）"+vec(target);
    const point=$("sample-point");if(point){point.setAttribute("cx",180+112*s.direction[0]);point.setAttribute("cy",146-112*s.direction[1]);}
  }
  function drawLab() {
    const key=$("lab-pair").value,heavy=["AA","AI"].includes(key),charged=["ee","eI","II"].includes(key);
    $("lab-mode").disabled=!heavy;
    if(!heavy)$("lab-mode").value="fixed";
    const populationMode=heavy&&$("lab-mode").value==="population";
    $("lab-energy").disabled=populationMode;$("lab-model").disabled=!heavy;
    $("lab-alpha").disabled=!heavy||$("lab-model").value!=="VSS";$("lab-omega").disabled=!heavy||$("lab-model").value==="HS";
    for(const id of ["lab-energy","lab-alpha","lab-omega"])if(!$(id).checkValidity()||$(id).value==="")throw new Error("请填写有效的散射参数");
    labConfig=D.config({massRatio:Number($("lab-mass").value),elastic:$("lab-model").value,alpha:Number($("lab-alpha").value),omega:Number($("lab-omega").value)});
    const energy=Number($("lab-energy").value);
    lab=populationMode?D.populationEnsemble(key,labConfig,labSeed):D.ensemble(key,energy,labConfig,labSeed);
    if (populationMode) {
      $("lab-initial").innerHTML = '<strong>入射库：</strong>目标初始静止，入射方向为 +x，g 在 [0.25, 4]v₀ 均匀分布。'
        + '<span class="hint">从同一个入射库按碰撞核加权抽取 2000 次独立事件；每次使用一组新初态。能量输入在此模式下停用。</span>';
    } else {
      const r = D.relative(...lab.initial, labConfig);
      const kinetic = 0.5 * r.ma * r.g * r.g;
      $("lab-initial").innerHTML = '<strong>每次相同的入射条件：</strong>Erel = ' + n(r.energy,3)
        + ' eV，g₀/v₀ = ' + n(r.g,4) + '。粒子 1（' + D.label(lab.initial[0])
        + '）沿 +x 入射，初始动能 ' + n(kinetic,3) + ' eV；粒子 2（' + D.label(lab.initial[1])
        + '）初始静止。<span class="hint">每次恢复这组初态，以碰撞已发生为条件独立抽取一次散射，共 2000 次。</span>';
    }
    const vss=heavy&&labConfig.elastic==="VSS",delta=labConfig.screening;
    let theory;
    if(charged){const fy=y=>(1/delta-1/(y+delta))/(1/delta-1/(2+delta));theory=(lo,hi)=>fy(1-lo)-fy(1-hi);}
    else theory=vss?(lo,hi)=>Math.pow((hi+1)/2,labConfig.alpha)-Math.pow((lo+1)/2,labConfig.alpha):(lo,hi)=>(hi-lo)/2;
    $("lab-law").innerHTML=!heavy?(charged?"带电粒子使用有限屏蔽教学核，偏转集中于前向。":"电子–原子在此采用各向同性教学弹性核。")+" 重粒子的 ω、α 不适用。":
      "<strong>ω 控制速率权重；α 控制偏转方向。</strong> "+(populationMode?"左图显示入射库按 σg 加权后的碰撞事件速率分布。保持 α 不变时，单独改变 ω 保持方向样本不变。":"相同初态下，改变 ω 只改变碰撞核，右侧条件末态分布保持不变。事件数固定为 2000，不能用点数比较频率。");
    if(populationMode) {
      histogram("rate-chart",lab.samples.map(s=>s.g),lab.law.lo,lab.law.hi,15,"碰撞事件的入射相对速率 / v₀",(a,b)=>lab.law.cdf(b)-lab.law.cdf(a),300,1/15);
      $("rate-title").textContent="哪些粒子更容易参与碰撞？";
      $("rate-note").textContent="蓝虚线：均匀入射总体；绿色：已发生碰撞的事件。";
      $("rate-chart").setAttribute("aria-label","入射库与碰撞事件的相对速率各区间概率");
    }else{
      rateCurve(heavy);$("rate-title").textContent="碰撞核随相对速率变化";$("rate-note").textContent="橙点表示当前输入：相对能量和粒子质量决定横坐标 g₀/v₀；曲线给出该速率的碰撞核，作为纵坐标。虚线对应两个坐标轴。右侧 2000 次独立碰撞共用这个 g₀。";
      $("rate-chart").setAttribute("aria-label","碰撞核随相对速率的曲线，橙点的横坐标为当前入射相对速率，纵坐标为对应碰撞核，虚线投影到两个坐标轴");
    }
    if(heavy&&populationMode){
      const exponent=labConfig.elastic==="HS"?1:2-2*labConfig.omega,qSlow=Math.pow(.25,exponent),qFast=Math.pow(4,exponent);
      $("rate-summary").innerHTML="<p>q(4) / q(0.25) = <strong>"+n(qFast/qSlow,2)+"</strong>；相同密度下，快速对平均等待时间是慢速对的 "+n(qSlow/qFast,3)+" 倍。</p><p class=\"hint\">黏度温度指数 ω：η(T)/η(Tref) = (T/Tref)<sup>ω</sup>。</p>";
    }else $("rate-summary").textContent=heavy?"q = σg 是碰撞核；乘目标数密度才得到频率。比较固定参考核，实际黏度拟合还需联合标定参数。":"";
    const parts=['<circle cx="180" cy="146" r="112" fill="#f4f7f3" stroke="#b8c9c0"/><path d="M68,146 h224 M180,34 v224" stroke="#c4d2ca" stroke-dasharray="4 4"/>'];
    lab.samples.forEach(s=>parts.push('<circle cx="'+(180+112*s.direction[0])+'" cy="'+(146-112*s.direction[1])+'" r="1.7" fill="#16786b" opacity=".23"/>'));
    arrow(parts,[180,146],[1,0,0],"#b56d28",65);
    parts.push('<circle id="sample-point" cx="0" cy="0" r="6" fill="none" stroke="#bc651f" stroke-width="2"/><text x="195" y="136" font-size="12">入射 +x</text><text x="180" y="284" text-anchor="middle" font-size="12">三维单位方向的 x–y 投影</text>');
    $("angular-cloud").innerHTML=parts.join("");
    histogram("angle-hist",lab.samples.map(s=>s.mu),-1,1,20,"cosχ",theory);
    const pair=lab.initial,ma=D.mass(pair[0],labConfig),mb=D.mass(pair[1],labConfig),speed=pair[0].v[0];
    histogram("speed-hist",lab.samples.map(s=>s.speed),populationMode?0:Math.abs(ma-mb)/(ma+mb)*speed,populationMode?lab.law.hi:speed,20,"入射粒子碰后速率 / v₀",null,270);
    $("speed-note").textContent = populationMode
      ? "统计入射粒子在实验室坐标中的碰后速率。分布同时取决于哪些入射速率被选中，以及碰撞后的能量转移。"
      : key === "AA"
        ? "相对速率保持 g₀，单粒子可向目标转移能量。等质量、目标初始静止时，入射粒子碰后速率从 0（反向散射）到 g₀（不偏转）。绿色为各区间的样本比例。"
        : "相对速率保持 g₀，入射粒子的实验室速率可因向目标转移能量而变化。这里只统计入射粒子的碰后速率；绿色为各区间的样本比例。";
    const mean=lab.samples.reduce((sum,s)=>sum+s.mu,0)/lab.samples.length;
    $("lab-stats").textContent="2000 次独立事件 · "+(populationMode?"总体平均弹性核 ⟨q⟩":"弹性核 q")+" = "+n(lab.rate,5)+" · ⟨cosχ⟩ = "+n(mean)+" · 最大能量残差 "+small(lab.maxError)+" eV";
    updateSample();
  }

  function filter() {
    return {key:$("filter-channel").value,pair:$("filter-pair").value,
      cell:$("filter-cell").value===""?undefined:Number($("filter-cell").value)-1};
  }
  function eventLabel(e) {return "步 "+e.step+" · 胞元 "+(e.cell+1)+" · "+D.PAIRS[e.pair].label+" "+names[e.key]+" · #"+e.ids.join(" / #");}
  function renderJournal() {
    const f=filter(),report=live.steps.find(s=>s.number===sim.step),matches=live.records.filter(e=>D.matchesEvent(e,f));
    $("return-live").hidden=!reviewing;
    $("record-step").innerHTML=live.steps.length?live.steps.map(s=>'<option value="'+s.number+'"'+(s.number===sim.step?' selected':"")+'>第 '+s.number+" 步 · "+s.events.length+" 次"+(s.complete?"":"（未结束）")+"</option>").join(""):'<option value="">尚未开始</option>';
    $("record-target").innerHTML='<option value="">'+(matches.length?"选择事件（"+matches.length+" 个匹配）":"没有匹配事件")+"</option>"+matches.map(e=>'<option value="'+e.id+'"'+(e.id===reviewId?' selected':"")+">"+eventLabel(e)+"</option>").join("");
    $("first-match").disabled=!matches.length;
    if(!report){$("step-summary").textContent="尚未推进。点击“下一碰撞 / 步末”或运行有限步。";$("step-cells").textContent="";$("step-events").innerHTML="";}
    else {
      const count=report.events.length,shown=report.events.filter(e=>D.matchesEvent(e,f));
      const tested=report.cells.reduce((s,c)=>s+c.tested,0),rejected=report.cells.reduce((s,c)=>s+c.rejected,0);
      $("step-summary").textContent="第 "+report.number+" 步"+(report.complete?"已结束：":"尚未结束：")+(count?"发生 "+count+" 次真实碰撞。":report.complete?"没有发生粒子间碰撞。":"截至目前尚未发生粒子间碰撞。")+" 候选 "+tested+"，空候选 "+rejected+"；撞壁 "+report.hits+" 次，吸收 "+report.absorbed+" 个。";
      $("step-cells").textContent=Array.from({length:6},(_,i)=>"胞元 "+(i+1)+"："+report.events.filter(e=>e.cell===i).length+" 次").join(" · ");
      $("step-events").innerHTML=shown.length?shown.map(e=>{
        const changed=e.frame.event.after.map(p=>"#"+p.id+" "+D.label(p)+(e.ids.includes(p.id)?"":"（新增）")).join("、");
        const selected=e.id===reviewId||(!reviewing&&live.phase==="commit"&&e===live.records.at(-1));
        return '<button class="event-row'+(selected?" selected":"")+'" data-event="'+e.id+'" aria-pressed="'+selected+'"><strong>'+eventLabel(e)+"</strong><span>碰后："+changed+" · 查看前后状态</span></button>";
      }).join(""):count?'<p class="hint">本步发生了碰撞，但没有符合当前通道、配对与胞元筛选的事件。</p>':"";
    }
    const stats=D.cellStatistics(live),keys=["AA","AI","Ae","excitation","ionization","cex","coulomb","total","rejected"];
    $("cell-statistics").innerHTML=stats.map((s,i)=>"<tr><th>"+(i+1)+"</th>"+keys.map(k=>"<td>"+s[k]+"</td>").join("")+"</tr>").join("")+"<tr class=\"total-row\"><th>合计</th>"+keys.map(k=>"<td>"+stats.reduce((sum,s)=>sum+s[k],0)+"</td>").join("")+"</tr>";
    $("run-summary").textContent="种子 "+live.c.seed+" · Δt = "+n(live.c.dt)+" · 已完成 "+live.steps.filter(s=>s.complete).length+" 步"+(live.phase!=="ready"&&live.phase!=="sample"?"，第 "+live.step+" 步进行中":"")+" · 真实碰撞 "+live.records.length+" 次";
  }
  function resumeLive() {
    if(reviewing&&liveView){age=liveView.age;progress=liveView.progress;focusId=liveView.focusId;}
    sim=live;reviewing=false;reviewId=null;liveView=null;
  }
  function showFrame(frame,id=null) {
    stop();if(!reviewing)liveView={age,progress,focusId};
    sim=structuredClone(frame);sim.balance=function(){return this.balanceValue;};reviewing=true;reviewId=id;
    focusId=sim.event?sim.event.ids[0]:null;age=duration;progress=1;render();
  }
  function showEvent(id) {
    const event=live.records.find(e=>e.id===Number(id));
    if(event){
      showFrame(event.frame,event.id);$("run-status").textContent="回看 "+eventLabel(event)+"。继续推进将从最新运行现场开始，不改写历史。";
      // Let the embedding document apply the new iframe height before scrolling to the table.
      requestAnimationFrame(()=>requestAnimationFrame(()=>{if(reviewId===event.id)$("event-preview").scrollIntoView({block:"start"});}));
    }
  }
  function showStep(number) {
    const report=live.steps.find(s=>s.number===Number(number));if(!report)return;
    if(report.complete){showFrame(report.frame);$("run-status").textContent="回看第 "+report.number+" 步末；点击事件行查看该次碰撞。";}
    else {resumeLive();render();}
  }
  function nextPhysical() {
    stop();resumeLive();do{live.nextResult();}while(live.phase==="reject");age=duration;progress=1;render();
    $("run-status").textContent=live.phase==="commit"?"已定位 "+eventLabel(live.records.at(-1))+"。":
      "第 "+live.step+" 步已结束。"+(live.stepReport().events.length?"所有事件保留在本步清单中。":"没有发生粒子间碰撞。");
  }
  function lockRun(locked) {
    document.querySelectorAll("#flow-view button, #flow-view input, #flow-view select, #lab-tab").forEach(el=>{
      if(el.id==="cancel-run")return;
      if(locked){el.dataset.wasDisabled=String(el.disabled);el.disabled=true;}
      else if(el.dataset.wasDisabled!==undefined){el.disabled=el.dataset.wasDisabled==="true";delete el.dataset.wasDisabled;}
    });
    $("cancel-run").hidden=!locked;
  }
  async function runFinite(search=false) {
    if(busy)return;
    try {
      stop();const input=$("run-steps"),steps=Number(input.value);
      if(!input.checkValidity()||!Number.isInteger(steps)||steps<1)throw new Error("有限步数应为 1–500 的整数");
      if(search){
        const f=filter(),cursor=reviewing?(reviewId===null?null:reviewId):live.records.length;
        const stored=live.records.find(e=>D.matchesEvent(e,f)&&(cursor===null?e.step>sim.step:e.id>cursor));
        if(stored){showEvent(stored.id);return;}
        resumeLive();
      }else reset();
      const scan=new D.Scan(live,{steps,filter:search?filter():null});
      cancelRun=false;busy=true;lockRun(true);$("error").hidden=true;
      while(!scan.done&&!cancelRun){
        scan.tick();$("run-status").textContent=(search?"搜索":"运行")+"中：第 "+live.step+" / "+scan.endStep+" 步，已记录 "+live.records.length+" 次真实碰撞。";
        if(!scan.done)await new Promise(resolve=>setTimeout(resolve,0));
      }
      resumeLive();age=duration;progress=1;
      if(cancelRun)$("run-status").textContent="已停止；保留到第 "+live.step+" 步的已处理结果，未结束的步骤明确标记。";
      else if(scan.match)$("run-status").textContent="找到 "+eventLabel(scan.match)+"。中间发生的其他碰撞均已记录。";
      else if(search)$("run-status").textContent="第 "+scan.startStep+"–"+scan.endStep+" 步的剩余搜索范围内未找到目标碰撞；该范围内的其他事件已保留。";
      else $("run-status").textContent="种子 "+live.c.seed+"：完成 "+live.step+" 步，共 "+live.records.length+" 次真实碰撞。可按类型筛选并回看。";
    }catch(error){resumeLive();fail(error);}
    finally {busy=false;lockRun(false);render();}
  }
  function stop(){running=false;cancelAnimationFrame(frame);$("play").textContent="播放";if(sim)draw();}
  function fail(error){stop();$("error").hidden=false;$("error").textContent=error.message;}
  function guarded(fn){try{fn();$("error").hidden=true;}catch(error){fail(error);}}
  function render(){updateText();draw();renderJournal();}
  function advance(animated=false){sim.advance();age=animated?0:duration;progress=animated&&sim.phase==="flight"?0:1;render();}
  function animate(now) {
    if(!running)return;
    try{
      age+=(now-lastFrame)*Number($("speed").value);lastFrame=now;
      if(age>=duration)advance(true);
      progress=sim.phase==="flight"&&!reduced.matches?Math.min(1,age/(duration*.8)):1;
      draw();frame=requestAnimationFrame(animate);
    }catch(error){fail(error);}
  }
  function reset() {
    stop();
    for(const id of ["dt","seed","omega","alpha"])if(!$(id).checkValidity()||$(id).value==="")throw new Error("请填写有效的时间步和模型参数");
    live=new D.Simulation({scenario:$("scenario").value,wall:$("wall").value,elastic:$("elastic").value,massRatio:Number($("mass").value),dt:Number($("dt").value),seed:Number($("seed").value),omega:Number($("omega").value),alpha:Number($("alpha").value)});
    resumeLive();$("run-status").textContent="新运行 · 种子 "+live.c.seed+"。筛选仅用于定位，不改变物理过程。";
    unit=D.velocityScale(sim.initial);focusId=sim.c.scenario==="walls"?4:null;age=duration;progress=1;
    $("alpha").disabled=sim.c.elastic!=="VSS";$("omega").disabled=sim.c.elastic==="HS";
    render();
  }
  $("play").addEventListener("click",()=>guarded(()=>{
    if(running){stop();return;}resumeLive();if(age>=duration)advance(true);running=true;$("play").textContent="暂停";lastFrame=performance.now();frame=requestAnimationFrame(animate);
  }));
  $("next").addEventListener("click",()=>guarded(()=>{stop();resumeLive();advance();}));
  $("result").addEventListener("click",()=>guarded(nextPhysical));
  $("finish").addEventListener("click",()=>guarded(()=>{stop();resumeLive();sim.finishStep();age=duration;progress=1;render();$("run-status").textContent="第 "+sim.step+" 步已结束；本步记录显示全部真实碰撞。";}));
  $("run-batch").addEventListener("click",()=>runFinite());
  $("seek-event").addEventListener("click",()=>runFinite(true));
  $("cancel-run").addEventListener("click",()=>{cancelRun=true;});
  $("return-live").addEventListener("click",()=>guarded(()=>{stop();resumeLive();render();$("run-status").textContent="已返回最新运行现场。";}));
  ["filter-channel","filter-pair","filter-cell"].forEach(id=>$(id).addEventListener("change",()=>guarded(renderJournal)));
  $("record-target").addEventListener("change",()=>guarded(()=>showEvent($("record-target").value)));
  $("record-step").addEventListener("change",()=>guarded(()=>showStep($("record-step").value)));
  $("back-to-events").addEventListener("click",()=>document.querySelector(".run-controls").scrollIntoView({block:"start"}));
  $("first-match").addEventListener("click",()=>guarded(()=>{const first=live.records.find(e=>D.matchesEvent(e,filter()));if(first)showEvent(first.id);}));
  $("step-events").addEventListener("click",event=>guarded(()=>{const row=event.target.closest("[data-event]");if(row)showEvent(row.dataset.event);}));
  $("reset").addEventListener("click",()=>guarded(reset));
  ["wall","elastic","mass","dt","seed","omega","alpha"].forEach(id=>$(id).addEventListener("change",()=>guarded(reset)));
  $("scenario").addEventListener("change",()=>guarded(()=>{
    if($("scenario").value==="ionization"){
      $("seed").value=39;$("mass").value=100;$("dt").value=.06;$("wall").value="reflect";$("elastic").value="VSS";$("omega").value=.75;$("alpha").value=3;
    }else{$("seed").value=2026;$("dt").value=.06;}
    reset();
  }));
  $("arrows").addEventListener("change",draw);
  const chooseParticle=event=>{
    const target=event.target.closest("[data-particle]");
    if(target){focusId=Number(target.dataset.particle);draw();}
  };
  $("scene").addEventListener("click",chooseParticle);
  $("scene").addEventListener("keydown",event=>{if(event.key==="Enter"||event.key===" "){event.preventDefault();chooseParticle(event);}});
  ["flow","lab"].forEach(view=>$(view+"-tab").addEventListener("click",()=>guarded(()=>{
    stop();for(const name of ["flow","lab"]){$(name+"-view").hidden=name!==view;$(name+"-tab").classList.toggle("active",name===view);$(name+"-tab").setAttribute("aria-pressed",name===view?"true":"false");}
    if(view==="lab")drawLab();
  })));
  ["lab-pair","lab-model","lab-mode","lab-mass","lab-energy","lab-alpha","lab-omega"].forEach(id=>$(id).addEventListener("change",()=>guarded(drawLab)));
  $("resample").addEventListener("click",()=>guarded(()=>{labSeed=(labSeed+104729)>>>0;drawLab();}));
  $("sample-index").addEventListener("input",updateSample);
  document.addEventListener("visibilitychange",()=>{if(document.hidden)stop();});
  new ResizeObserver(()=>{
    if(window.parent!==window)window.parent.postMessage({type:"g03-demo-height",height:Math.ceil(document.querySelector("main").getBoundingClientRect().height)+4},window.location.origin==="null"?"*":window.location.origin);
  }).observe(document.querySelector("main"));
  guarded(reset);
})();
