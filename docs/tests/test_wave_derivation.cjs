// node docs/tests/test_wave_derivation.cjs; no external dependencies.
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const sandbox={};vm.runInNewContext(fs.readFileSync(path.join(__dirname,'../source/_static/plasma_waves/wave-derivation-model.js'),'utf8'),sandbox);
const M=sandbox.PlasmaDerivationModel;
const near=(a,b,tol,label)=>assert.ok(Math.abs(a-b)<=tol,label+': '+a+' vs '+b);
near(M.plasmaFrequency(M.NREF)/M.W0,1,1e-14,'reference frequency');
near(M.plasmaFrequency(4*M.NREF)/M.W0,2,1e-14,'density square-root scaling');
for(const k of [30,60,120])for(const n0 of [M.NREF,4*M.NREF])for(const u of [0,1e6]){
  const w=M.omega(k,n0,u),N=M.A*n0,dt=1e-12,dx=1e-6;
  near(w*w/(M.plasmaFrequency(n0)**2+u*u*k*k),1,1e-14,'dispersion');
  for(const x of [.017,.071,.193])for(const t of [0,1.7e-8,4.3e-8]){
    const a=M.sample(x,t,k,n0,u),tp=M.sample(x,t+dt,k,n0,u),tm=M.sample(x,t-dt,k,n0,u),xp=M.sample(x+dx,t,k,n0,u),xm=M.sample(x-dx,t,k,n0,u);
    const nt=(tp.n1-tm.n1)/(2*dt),vx=(xp.v1-xm.v1)/(2*dx),vt=(tp.v1-tm.v1)/(2*dt),ex=(xp.E1-xm.E1)/(2*dx),px=(xp.p1-xm.p1)/(2*dx);
    near((nt+n0*vx)/(N*w),0,3e-8,'linear continuity');
    near((M.ME*vt+M.E*a.E1+px/n0)/(M.ME*w*w*M.A/k),0,3e-8,'momentum including pressure');
    near((ex+M.E*a.n1/M.EPS0)/(M.E*N/M.EPS0),0,3e-8,'Poisson sign');
  }
}
for(const k of [60,120])for(const t of [0,1.7e-8,2*Math.PI/M.W0]){
  for(const q of [0,.03,.1,.21]){
    const x=M.position(q,t,k);
    near(x+M.A/k*Math.sin(k*x-M.W0*t),q,1e-13,'conservative density map');
    assert.ok(1+M.sample(x,t,k).n1/M.NREF>0);
  }
}
console.log('Electron-fluid checks passed: dispersion, density scaling, continuity, momentum, Poisson and density map.');

/* Plasma-wave contribution history (Git author dates; edit time includes timezone).
 * 2026-11-19 11:06 +08:00 | Yinjian Zhao | git 3242c1a909ef
 * 2026-11-19 16:28 +08:00 | Yinjian Zhao | edit (Codex-assisted)
 */
