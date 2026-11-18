/* Force-free transport and local stochastic collisions for the DSMC walkthrough. */
(function (root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory(require("./collision-engine.js"));
  else Object.assign(root.DsmcDemo, factory(root.DsmcDemo));
})(typeof globalThis !== "undefined" ? globalThis : this, function (D) {
  "use strict";
  const {add,sub,scale,clone,budget}=D;
  const MAX_STEPS=500,MAX_EVENTS=5000;
  const matchesEvent=(event,filter={})=>(!filter.key||event.key===filter.key)&&(!filter.pair||event.pair===filter.pair)&&(filter.cell===undefined||event.cell===filter.cell);
  const cellOf=p=>Math.min(2,Math.max(0,Math.floor(p.x[0])))+3*Math.min(1,Math.max(0,Math.floor(p.x[1])));
  function traceParticle(p,dt,wall) {
    const q=clone(p),before=clone(p),segments=[],hits=[];
    let time=0,alive=true;
    for(let iteration=0;time<dt-1e-14;iteration++) {
      if(iteration>1000) throw new Error("单步撞壁次数过多，请减小时间步");
      const remaining=dt-time;
      const times=[0,1].map(k=>q.v[k]===0?Infinity:Math.max(0,((q.v[k]>0?D.BOX[k]:0)-q.x[k])/q.v[k]));
      const hitTime=Math.min(...times);
      const elapsed=Math.min(remaining,hitTime);
      const start=q.x.slice();
      q.x=add(q.x,scale(q.v,elapsed));
      segments.push({start,end:q.x.slice(),velocity:q.v.slice(),t0:time,t1:time+elapsed});
      time+=elapsed;
      if(hitTime>remaining+1e-12) break;
      const axes=[0,1].filter(k=>Math.abs(times[k]-hitTime)<1e-12);
      axes.forEach(k=>{q.x[k]=q.v[k]>0?D.BOX[k]:0;});
      hits.push({time,point:q.x.slice(),axes,kind:wall,id:p.id});
      if(wall==="absorb") {alive=false;break;}
      axes.forEach(k=>{q.v[k]*=-1;});
    }
    q.x[2]=((q.x[2]%1)+1)%1;
    return {before,after:q,segments,hits,alive,dt};
  }
  function stateAt(trace,time) {
    if(!trace.alive && time>=trace.hits[0].time) return null;
    if(time>=trace.dt) return clone(trace.after);
    const segment=trace.segments.find(s=>time<s.t1);
    if(!segment) return clone(trace.after);
    const p=clone(trace.before);
    p.x=add(segment.start,scale(segment.velocity,Math.max(0,time-segment.t0)));
    p.x[2]=((p.x[2]%1)+1)%1;
    p.v=segment.velocity.slice();
    return p;
  }
  // With no field work and nonnegative internal energy, no supported event exceeds this scale.
  function velocityScale(initial) { return 64/Math.sqrt(Math.max(1,2*initial.total)); }
  function initialParticles(rng,c) {
    const ps=[];
    const make=(species,x,v)=>({id:ps.length+1,species,eps:0,x,v});
    if(c.scenario==="ionization") {
      ps.push(make("atom",[0.6,0.5,0.5],[0,0,0]));
      ps.push(make("electron",[0.2,0.5,0.5],[10,0,0]));
      return ps;
    }
    for(let cell=0;cell<6;cell++) {
      ["atom","atom","ion","electron"].forEach((species,slot)=>{
        const m=species==="electron"?1:c.massRatio+(species==="atom"?1:0);
        const speed=species==="electron"?8:Math.sqrt(2/m);
        ps.push(make(species,[cell%3+0.28+(slot%2)*0.43,Math.floor(cell/3)+0.28+Math.floor(slot/2)*0.42,rng.uniform("z")],
          [speed*(2*rng.uniform("vx")-1),speed*(2*rng.uniform("vy")-1),speed*(2*rng.uniform("vz")-1)]));
      });
    }
    if(c.scenario==="walls") {
      const e=ps.find(p=>p.species==="electron");
      e.x=[0.05,0.7,0.5];e.v=[-25,5,0];
      const i=ps.find(p=>p.species==="ion");
      i.x=[2.97,1.2,0.5];i.v=[1,0.2,0];
      const atom=ps[0];atom.x=[0.98,0.45,0.5];atom.v=[0.9,0,0];
    }
    return ps;
  }
  class Simulation {
    constructor(options={}) {
      this.c=D.config(options);
      this.rng=new D.Random(this.c.seed);
      this.particles=initialParticles(this.rng,this.c);
      this.nextId=this.particles.length+1;
      this.initial=budget(this.particles,this.c);
      this.phase="ready";this.step=0;this.cell=-1;this.event=null;
      this.draws=[];this.traces=[];this.moves=[];this.steps=[];this.records=[];
      this.ledger={wallEnergy:0,wallMomentum:[0,0,0],wallCharge:0,wallMass:0,wallNuclei:0,hits:0,absorbed:0};
      this.counts={tested:0,rejected:0,elastic:0,coulomb:0,excitation:0,ionization:0,cex:0};
      this.pairCounts=Object.fromEntries(Object.keys(D.PAIRS).map(k=>[k,0]));
      this.group();
    }
    group() {
      this.cells=Array.from({length:6},()=>[]);
      this.particles.forEach(p=>this.cells[cellOf(p)].push(p));
    }
    selectCell() {
      this.cell++;this.tau=0;this.event=null;this.draws=[];this.candidate=0;
      this.phase=this.cell<6?"cell":"sample";
      if(this.phase==="sample") {
        const report=this.stepReport();report.complete=true;report.frame=this.snapshot();
      }
    }
    stepReport() {
      if(this.steps.at(-1)?.number!==this.step) this.steps.push({number:this.step,complete:false,events:[],
        cells:Array.from({length:6},()=>({tested:0,rejected:0})),hits:0,absorbed:0,frame:null});
      return this.steps.at(-1);
    }
    snapshot() {
      // No RNG or journal references: reviewing a frame cannot advance or rewrite the run.
      return structuredClone({c:this.c,initial:this.initial,particles:this.particles,cells:this.cells,
        phase:this.phase,step:this.step,cell:this.cell,candidate:this.candidate,event:this.event,
        counts:this.counts,pairCounts:this.pairCounts,ledger:this.ledger,draws:this.draws,
        traces:[],moves:[],balanceValue:this.balance()});
    }
    clock() {
      const ps=this.cells[this.cell];
      this.event=null;this.draws=[];
      this.bound=D.majorant(ps,this.c);
      this.frequency=ps.length*(ps.length-1)/2*this.bound;
      this.remaining=this.c.dt-this.tau;
      this.waiting=this.frequency ? -Math.log1p(-this.rng.uniform("R等待",this.draws))/this.frequency : Infinity;
      this.hasCandidate=this.waiting<this.remaining;
      if(this.hasCandidate) this.tau+=this.waiting;
      this.phase="clock";
    }
    record(key) {
      const report=this.stepReport();
      if(key==="rejected") {report.cells[this.cell].rejected++;return;}
      const entry={id:this.records.length+1,step:this.step,cell:this.cell,tau:this.tau,
        pair:this.event.rates.key,key,ids:this.event.ids.slice(),frame:this.snapshot()};
      report.events.push(entry);this.records.push(entry);
    }
    advance() {
      switch(this.phase) {
        case "ready":case "sample": {
          if(this.steps.length>=MAX_STEPS) throw new Error("已达到 500 步记录上限，请重置后开始新运行。");
          this.step++;this.cell=-1;this.event=null;this.draws=[];this.moves=[];this.traces=[];
          const report=this.stepReport();
          this.particles.forEach(p=>{p.born=false;});
          this.beforeCells=new Map(this.particles.map(p=>[p.id,cellOf(p)]));
          const before=budget(this.particles,this.c);
          this.traces=this.particles.map(p=>traceParticle(p,this.c.dt,this.c.wall));
          this.particles=this.traces.filter(t=>t.alive).map(t=>t.after);
          const after=budget(this.particles,this.c);
          this.ledger.wallEnergy+=before.total-after.total;
          this.ledger.wallMomentum=add(this.ledger.wallMomentum,sub(before.momentum,after.momentum));
          this.ledger.wallCharge+=before.charge-after.charge;
          this.ledger.wallMass+=before.mass-after.mass;
          this.ledger.wallNuclei+=before.nuclei-after.nuclei;
          this.ledger.hits+=this.traces.reduce((s,t)=>s+t.hits.length,0);
          this.ledger.absorbed+=this.traces.filter(t=>!t.alive).length;
          report.hits=this.traces.reduce((s,t)=>s+t.hits.length,0);report.absorbed=this.traces.filter(t=>!t.alive).length;
          this.phase="flight";break;
        }
        case "flight":
          this.group();
          this.moves=this.particles.map(p=>({id:p.id,from:this.beforeCells.get(p.id),to:cellOf(p)})).filter(x=>x.from!==x.to);
          this.phase="regroup";break;
        case "regroup":this.selectCell();break;
        case "cell":case "commit":case "reject":this.clock();break;
        case "clock": {
          if(!this.hasCandidate) {this.selectCell();break;}
          const ps=this.cells[this.cell];
          const i=this.rng.integer(ps.length,"Ri",this.draws),j0=this.rng.integer(ps.length-1,"Rj",this.draws),j=j0>=i?j0+1:j0;
          this.candidate++;
          this.event={ids:[ps[i].id,ps[j].id],before:[clone(ps[i]),clone(ps[j])],rates:D.rates(ps[i],ps[j],this.c)};
          this.phase="pair";break;
        }
        case "pair": {
          const e=this.event;
          e.probability=e.rates.total/this.bound;
          if(!(e.probability>=0&&e.probability<=1)) throw new Error("碰撞核上界失效");
          e.acceptanceDraw=this.rng.uniform("R接受",this.draws);
          e.accepted=e.acceptanceDraw<e.probability;
          this.counts.tested++;this.stepReport().cells[this.cell].tested++;this.phase="accept";break;
        }
        case "accept": {
          const e=this.event;
          if(!e.accepted) {
            e.after=e.before.map(clone);this.counts.rejected++;this.record("rejected");this.phase="reject";break;
          }
          e.channelDraw=this.rng.uniform("R通道",this.draws);
          let cumulative=0;
          const target=e.channelDraw*e.rates.total;
          e.channel=e.rates.channels.filter(c=>c.rate>0).at(-1);
          for(const ch of e.rates.channels) {cumulative+=ch.rate;if(target<cumulative){e.channel=ch;break;}}
          this.phase="channel";break;
        }
        case "channel": {
          const e=this.event;
          e.outcome=D.scatter(...e.before,e.channel.key,this.c,this.rng,this.draws,this.nextId);
          e.after=e.outcome.particles;this.phase="scatter";break;
        }
        case "scatter": {
          if(this.records.length>=MAX_EVENTS) throw new Error("已达到 5000 次碰撞记录上限，请重置后开始新运行。");
          const e=this.event,byId=new Map(this.particles.map(p=>[p.id,p]));
          for(const p of e.after) {
            if(byId.has(p.id)) Object.assign(byId.get(p.id),clone(p));
            else {this.particles.push(clone(p));this.nextId++;}
          }
          this.group();
          this.counts[e.channel.key]++;this.pairCounts[e.rates.key]++;
          this.phase="commit";this.record(e.channel.key);break;
        }
        default:throw new Error("未知 DSMC 阶段");
      }
      return this;
    }
    nextResult() {
      for(let k=0;k<100000;k++) {
        this.advance();
        if(["commit","reject","sample"].includes(this.phase)) return;
      }
      throw new Error("候选数超过教学上限，请减小步长");
    }
    finishStep() {
      for(let k=0;k<100000;k++) {this.advance();if(this.phase==="sample")return;}
      throw new Error("时间步未完成");
    }
    balance() {
      const b=budget(this.particles,this.c),l=this.ledger;
      return {energy:b.total-this.initial.total+l.wallEnergy,
        momentum:sub(add(b.momentum,l.wallMomentum),this.initial.momentum),
        charge:b.charge+l.wallCharge-this.initial.charge,
        mass:b.mass+l.wallMass-this.initial.mass,
        nuclei:b.nuclei+l.wallNuclei-this.initial.nuclei};
    }
  }
  function cellStatistics(sim) {
    return Array.from({length:6},(_,cell)=>{
      const counts={elastic:0,excitation:0,ionization:0,cex:0,coulomb:0,AA:0,AI:0,Ae:0,tested:0,rejected:0,total:0};
      for(const step of sim.steps){counts.tested+=step.cells[cell].tested;counts.rejected+=step.cells[cell].rejected;}
      for(const event of sim.records)if(event.cell===cell){counts.total++;counts[event.key]++;if(event.key==="elastic")counts[event.pair]++;}
      return counts;
    });
  }
  // Bounded incremental scanning keeps the same physics/RNG path as manual stepping.
  class Scan {
    constructor(sim,{steps=50,filter=null}={}) {
      if(!Number.isInteger(steps)||steps<1||steps>MAX_STEPS)throw new Error("步数应为 1–500 的整数");
      this.sim=sim;this.filter=filter;this.startStep=sim.step+(sim.phase==="ready"||sim.phase==="sample"?1:0);
      if(this.startStep>MAX_STEPS)throw new Error("已达到 500 步记录上限，请重置后开始新运行。");
      this.endStep=Math.min(MAX_STEPS,this.startStep+steps-1);this.startEvents=sim.records.length;
      this.done=false;this.match=null;this.transitions=0;
    }
    tick(limit=300) {
      for(let k=0;k<limit&&!this.done;k++) {
        if(this.sim.phase==="sample"&&this.sim.step>=this.endStep){this.done=true;break;}
        if(++this.transitions>2000000)throw new Error("本次扫描达到计算上限；保留已完成记录，请减小步数或时间步。");
        this.sim.advance();
        if(this.filter&&this.sim.phase==="commit"&&matchesEvent(this.sim.records.at(-1),this.filter)){
          this.match=this.sim.records.at(-1);this.done=true;
        }else if(this.sim.phase==="sample"&&this.sim.step>=this.endStep)this.done=true;
      }
      return this.done;
    }
  }
  return {Simulation,Scan,matchesEvent,cellStatistics,MAX_STEPS,traceParticle,stateAt,velocityScale,cellOf};
});
