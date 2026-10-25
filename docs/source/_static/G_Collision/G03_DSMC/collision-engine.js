/* Collision physics shared by the DSMC walkthrough and independent scattering lab. */
(function (root, factory) {
  const api = factory();
  if (typeof module === "object" && module.exports) module.exports = api;
  else root.DsmcDemo = api;
})(typeof globalThis !== "undefined" ? globalThis : this, function () {
  "use strict";
  const BOX = [3, 2, 1], IONIZATION = 15.76, EXCITATION = 11.55;
  const SPECIES = {
    atom: { label: "A", charge: 0, color: "#16786b" },
    ion: { label: "A⁺", charge: 1, color: "#bc611f" },
    electron: { label: "e⁻", charge: -1, color: "#326cc5" }
  };
  const PAIRS = {
    AA: { label: "A–A", types: ["atom", "atom"], description: "重粒子弹性：HS / VHS / VSS" },
    AI: { label: "A⁺–A", types: ["ion", "atom"], description: "重粒子弹性 + 共振电荷交换" },
    Ae: { label: "e⁻–A", types: ["electron", "atom"], description: "弹性 + 激发 + 单次电离" },
    ee: { label: "e⁻–e⁻", types: ["electron", "electron"], description: "屏蔽库仑教学核" },
    eI: { label: "e⁻–A⁺", types: ["electron", "ion"], description: "屏蔽库仑教学核；不含复合" },
    II: { label: "A⁺–A⁺", types: ["ion", "ion"], description: "屏蔽库仑教学核；不含二次电离" }
  };
  const DEFAULTS = { massRatio: 100, elastic: "VSS", omega: 0.75, alpha: 3, screening: 0.1, dt: 0.06, wall: "reflect", reactions: true, scenario: "mixed", seed: 2026 };
  function config(options = {}) {
    const c = { ...DEFAULTS, ...options };
    if (!["HS", "VHS", "VSS"].includes(c.elastic) || !["reflect", "absorb"].includes(c.wall)) throw new Error("未知模型或边界");
    if (!(c.massRatio >= 2 && c.massRatio <= 1e6 && c.alpha >= 1 && c.alpha <= 8 && c.omega >= 0.5 && c.omega <= 1 && c.screening > 0 && c.dt > 0 && c.dt <= 0.4)) throw new Error("参数超出演示范围");
    if (!Number.isInteger(c.seed) || c.seed < 0 || c.seed > 4294967295) throw new Error("种子应为 32 位无符号整数");
    return c;
  }
  const add = (a, b) => a.map((v, k) => v + b[k]);
  const sub = (a, b) => a.map((v, k) => v - b[k]);
  const scale = (a, s) => a.map(v => v * s);
  const dot = (a, b) => a.reduce((s, v, k) => s + v * b[k], 0);
  const norm2 = a => dot(a, a);
  const cross = (a, b) => [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]];
  const clone = p => ({ ...p, x: p.x.slice(), v: p.v.slice() });
  const mass = (p, c) => p.species === "electron" ? 1 : c.massRatio + (p.species === "atom" ? 1 : 0);
  const internal = p => p.species === "ion" ? IONIZATION : (p.eps || 0);
  const label = p => p.species === "atom" && p.eps > 0 ? "A*" : SPECIES[p.species].label;
  function pairKey(a, b) {
    const t = [a.species, b.species];
    if (t.every(x => x === "atom")) return "AA";
    if (t.includes("atom")) return t.includes("electron") ? "Ae" : "AI";
    if (t.every(x => x === "electron")) return "ee";
    return t.includes("electron") ? "eI" : "II";
  }
  class Random {
    constructor(seed) { this.state = seed >>> 0; }
    uint32() {
      this.state = (this.state + 0x6d2b79f5) >>> 0;
      let t = this.state;
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return (t ^ (t >>> 14)) >>> 0;
    }
    uniform(label, log = []) {
      const u = this.uint32() / 4294967296;
      log.push({ label, value: u });
      return u;
    }
    integer(n, label, log = []) {
      if (!Number.isInteger(n) || n < 1) throw new Error("非法整数抽样范围");
      const bucket = Math.floor(4294967296 / n);
      let x;
      do {
        x = this.uint32();
        log.push({ label, value: x / 4294967296, discarded: x >= bucket * n });
      } while (x >= bucket * n);
      return Math.floor(x / bucket);
    }
  }
  function budget(ps, c) {
    const b = { momentum: [0,0,0], kinetic: 0, internal: 0, mass: 0, charge: 0, nuclei: 0 };
    for (const p of ps) {
      const m = mass(p, c);
      b.momentum = add(b.momentum, scale(p.v, m));
      b.kinetic += 0.5 * m * norm2(p.v);
      b.internal += internal(p);
      b.mass += m;
      b.charge += SPECIES[p.species].charge;
      b.nuclei += p.species !== "electron" ? 1 : 0;
    }
    b.total = b.kinetic + b.internal;
    return b;
  }
  function relative(a, b, c) {
    const ma = mass(a,c), mb = mass(b,c);
    const vector = sub(a.v,b.v), g = Math.sqrt(norm2(vector));
    return { ma, mb, vector, g, mu: ma*mb/(ma+mb), energy: 0.5*ma*mb/(ma+mb)*g*g,
      com: scale(add(scale(a.v,ma),scale(b.v,mb)),1/(ma+mb)) };
  }
  function heavyKernel(g, c) {
    if (g === 0) return 0;
    return 0.12 * Math.pow(g, c.elastic === "HS" ? 1 : 2 - 2*c.omega);
  }
  function rates(a, b, c) {
    const r = relative(a,b,c), key = pairKey(a,b);
    const channels = [];
    const channel = (key, name, rate) => channels.push({ key, name, rate });
    if (key === "AA" || key === "AI") {
      channel("elastic", "重粒子弹性", heavyKernel(r.g,c));
      if (key === "AI" && c.reactions && ![a,b].some(p => p.eps > 0)) channel("cex", "共振电荷交换", 0.1*r.g);
    } else if (key === "Ae") {
      const atom = a.species === "atom" ? a : b;
      channel("elastic", "电子–原子弹性（各向同性教学模型）", 0.035*r.g);
      if (c.reactions) {
        const excitation = atom.eps ? 0 : (r.energy > EXCITATION ? 0.065*r.g*(1-EXCITATION/r.energy) : 0);
        const threshold = IONIZATION - (atom.eps || 0);
        const ionization = r.energy > threshold ? 0.12*r.g*Math.pow(1-threshold/r.energy, 1.5) : 0;
        channel("excitation", "电子碰撞激发", excitation);
        channel("ionization", "电子碰撞单次电离", ionization);
      }
    } else {
      const coefficient = { ee: 0.3, eI: 0.4, II: 0.2 }[key];
      channel("coulomb", "屏蔽库仑（有限核教学模型）", coefficient*r.g/Math.pow(1+r.g*r.g,2));
    }
    return { ...r, key, channels, total: channels.reduce((s,x)=>s+x.rate,0) };
  }
  function majorant(ps, c) {
    if (ps.length < 2) return 0;
    const b = budget(ps,c), u = scale(b.momentum,1/b.mass);
    const available = ps.reduce((s,p)=>s+0.5*mass(p,c)*norm2(sub(p.v,u))+internal(p),0);
    // Minimum reduced mass is 1/2. Chemical/internal energy stays in the bound after births.
    const gmax = Math.sqrt(4*available);
    const heavy = heavyKernel(gmax,c) + 0.1*gmax;
    const electronAtom = (0.035+0.065+0.12)*gmax;
    const coulomb = 0.4*9/(16*Math.sqrt(3));
    return Math.max(heavy,electronAtom,coulomb)*(1+1e-12);
  }
  function deflection(direction, mu, phi) {
    const norm = Math.sqrt(norm2(direction));
    const axis = norm ? scale(direction,1/norm) : [1,0,0];
    const helper = Math.abs(axis[2]) < 0.9 ? [0,0,1] : [0,1,0];
    const tmp = cross(helper,axis), t = scale(tmp,1/Math.sqrt(norm2(tmp))), b = cross(axis,t);
    const radial = Math.sqrt(Math.max(0,1-mu*mu));
    return add(scale(axis,mu),scale(add(scale(t,Math.cos(phi)),scale(b,Math.sin(phi))),radial));
  }
  function directionSample(g, kind, c, rng, log) {
    const r = rng.uniform("R角",log);
    let mu = 2*r-1;
    if (kind === "VSS") mu = 2*Math.pow(r,1/c.alpha)-1;
    if (kind === "coulomb") mu = 1 - 2*c.screening*r/(c.screening+2-2*r);
    return { direction: deflection(g,mu,2*Math.PI*rng.uniform("R方位",log)), mu };
  }
  function outgoingPair(out, com, gvec, c) {
    const m0 = mass(out[0],c), m1 = mass(out[1],c);
    out[0].v = add(com,scale(gvec,m1/(m0+m1)));
    out[1].v = sub(com,scale(gvec,m0/(m0+m1)));
    return out;
  }
  function scatter(a,b,key,c,rng,log=[],newId=0) {
    const r = relative(a,b,c), pair = pairKey(a,b), out = [clone(a),clone(b)];
    if (!rates(a,b,c).channels.some(x=>x.key===key && x.rate>0)) throw new Error("反应通道未开启");
    if (key === "ionization") {
      const ei = a.species === "electron" ? 0 : 1, ai = 1-ei;
      const excess = r.energy+(out[ai].eps||0)-IONIZATION;
      out[ai].species = "ion"; out[ai].eps = 0;
      const child = { id: newId, species:"electron", eps:0, x:out[ai].x.slice(), v:[0,0,0], born:true };
      // A Beta(3/2,3/2) phase-space split in Jacobi coordinates, not a measured electron spectrum.
      let share;
      do { share = rng.uniform("R能量份额",log); }
      while (rng.uniform("R份额接受",log) >= 2*Math.sqrt(share*(1-share)));
      const u = scale(directionSample([1,0,0],"HS",c,rng,log).direction,Math.sqrt(4*share*excess));
      const muCluster = 2*c.massRatio/(2+c.massRatio);
      const w = scale(directionSample([1,0,0],"HS",c,rng,log).direction,Math.sqrt(2*(1-share)*excess/muCluster));
      const electronCom = add(r.com,scale(w,c.massRatio/(2+c.massRatio)));
      out[ei].v = add(electronCom,scale(u,0.5));
      child.v = sub(electronCom,scale(u,0.5));
      out[ai].v = sub(r.com,scale(w,2/(2+c.massRatio)));
      return { particles:[...out,child], share, kind:"ionization" };
    }
    if (key === "cex") {
      out.forEach(p=>{ p.species=p.species==="atom"?"ion":"atom"; p.eps=0; });
      return { particles:outgoingPair(out,r.com,r.vector,c), mu:1, kind:"cex" };
    }
    let energy = r.energy;
    if (key === "excitation") {
      out[a.species==="atom"?0:1].eps = EXCITATION;
      energy -= EXCITATION;
    }
    const kind = key === "coulomb" ? "coulomb" : (key==="elastic" && ["AA","AI"].includes(pair) ? c.elastic : "HS");
    const angle = directionSample(r.vector,kind,c,rng,log);
    outgoingPair(out,r.com,scale(angle.direction,Math.sqrt(2*energy/r.mu)),c);
    return { particles:out,mu:angle.mu,kind };
  }
  function labPair(pair, energy, c) {
    const types = PAIRS[pair].types;
    const a={id:1,species:types[0],eps:0,x:[0.4,0.5,0.5],v:[0,0,0]};
    const b={id:2,species:types[1],eps:0,x:[0.6,0.5,0.5],v:[0,0,0]};
    const mu=mass(a,c)*mass(b,c)/(mass(a,c)+mass(b,c));
    a.v=[Math.sqrt(2*energy/mu),0,0];
    return [a,b];
  }
  function ensemble(pair,energy,c,seed=314159,count=2000) {
    const initial=labPair(pair,energy,c), rng=new Random(seed);
    const key=["ee","eI","II"].includes(pair)?"coulomb":"elastic";
    const samples=[];
    let maxError=0;
    for(let i=0;i<count;i++) {
      const event=scatter(...initial,key,c,rng);
      const rel=relative(...event.particles,c);
      const before=budget(initial,c),after=budget(event.particles,c);
      maxError=Math.max(maxError,Math.abs(before.total-after.total));
      samples.push({mu:event.mu,direction:scale(rel.vector,1/rel.g),speed:Math.sqrt(norm2(event.particles[0].v)),v:event.particles[0].v,g:rel.g,incoming:initial[0].v});
    }
    return {initial,samples,rate:rates(...initial,c).channels.find(x=>x.key===key).rate,maxError};
  }
  function populationLaw(c,lo=0.25,hi=4) {
    const exponent=c.elastic==="HS"?1:2-2*c.omega;
    const power=exponent+1,integral=(hi**power-lo**power)/power;
    return {
      lo,hi,exponent,meanRate:0.12*integral/(hi-lo),
      cdf:g=>(Math.max(lo,Math.min(hi,g))**power-lo**power)/(hi**power-lo**power),
      quantile:r=>(lo**power+r*(hi**power-lo**power))**(1/power)
    };
  }
  function populationEnsemble(pair,c,seed=314159,count=2000) {
    if(!["AA","AI"].includes(pair)) throw new Error("速率总体比较只用于重粒子弹性模型");
    const law=populationLaw(c),speedRng=new Random(seed^0x9e3779b9),angleRng=new Random(seed);
    const initial=labPair(pair,1,c),mu=relative(...initial,c).mu,samples=[];
    let maxError=0;
    for(let i=0;i<count;i++) {
      // Sample collision events from f(g)*q(g), not directly from the unweighted population.
      const g=law.quantile(speedRng.uniform("R速率"));
      const incoming=labPair(pair,0.5*mu*g*g,c);
      const event=scatter(...incoming,"elastic",c,angleRng);
      const rel=relative(...event.particles,c);
      maxError=Math.max(maxError,Math.abs(budget(incoming,c).total-budget(event.particles,c).total));
      samples.push({mu:event.mu,direction:scale(rel.vector,1/rel.g),speed:Math.sqrt(norm2(event.particles[0].v)),v:event.particles[0].v,g,incoming:incoming[0].v});
    }
    return {initial,samples,rate:law.meanRate,maxError,law};
  }
  return {BOX,IONIZATION,EXCITATION,SPECIES,PAIRS,DEFAULTS,config,add,sub,scale,dot,norm2,clone,mass,internal,label,pairKey,Random,budget,relative,rates,majorant,directionSample,scatter,labPair,ensemble,populationLaw,populationEnsemble};
});
