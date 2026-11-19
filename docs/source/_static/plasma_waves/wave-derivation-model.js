/* Linear electron-fluid mode in SI units. Dots are a density map, not particles advanced by forces. */
(() => {
  'use strict';
  const E = 1.602176634e-19, ME = 9.1093837e-31, EPS0 = 8.8541878e-12;
  const W0 = 1e8, NREF = EPS0 * ME * W0 * W0 / (E * E), A = .08, XMAX = .24;
  const plasmaFrequency = n0 => Math.sqrt(n0 * E * E / (ME * EPS0));
  const omega = (k,n0=NREF,u=0) => Math.hypot(plasmaFrequency(n0),u*k);
  function sample(x,t,k,n0=NREF,u=0) {
    const w=omega(k,n0,u), theta=k*x-w*t, N=A*n0;
    return { n1:N*Math.cos(theta), v1:w*A/k*Math.cos(theta),
      E1:-E*N/(EPS0*k)*Math.sin(theta), p1:ME*u*u*N*Math.cos(theta) };
  }
  function position(q,t,k) {
    const w=omega(k); let x=q;
    for(let j=0;j<6;j++) x-=(x+A/k*Math.sin(k*x-w*t)-q)/(1+A*Math.cos(k*x-w*t));
    return x;
  }
  globalThis.PlasmaDerivationModel={E,ME,EPS0,W0,NREF,A,XMAX,plasmaFrequency,omega,sample,position};
})();

/* Plasma-wave contribution history (Git author dates; edit time includes timezone).
 * 2026-11-19 11:06 +08:00 | Yinjian Zhao | git 3242c1a909ef
 * 2026-11-19 16:28 +08:00 | Yinjian Zhao | edit (Codex-assisted)
 */
