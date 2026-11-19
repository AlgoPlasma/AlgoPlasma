/* Prescribed linear density packet in SI units; no particle-force solver. */
(() => {
  'use strict';
  const W0 = 1e8, U = 1e6, KC = 60, SIGMA = 6, AMPLITUDE = .18;
  const XMIN = -.5, XMAX = .9, TMAX = 2e-7;
  const omega = k => Math.hypot(W0, U * k);
  const WC = omega(KC), VP = WC / KC, VG = U * U * KC / WC;
  const frequency = (k, linear = false) => linear ? VP * k : omega(k);
  const groupSpeed = (k, linear = false) => linear ? VP : U * U * k / omega(k);
  const weights = Array.from({ length: 31 }, (_, j) => {
    const k = KC + (j - 15) * 1.2;
    return { k, weight: Math.exp(-.5 * ((k - KC) / SIGMA) ** 2) };
  });
  const total = weights.reduce((sum, v) => sum + v.weight, 0);
  const branches = [false, true].map(linear => weights.map(v => ({
    k: v.k, w: frequency(v.k, linear), a: AMPLITUDE * v.weight / total
  })));
  const modes = linear => branches[linear ? 1 : 0];
  function sample(x, t, selected) {
    let re = 0, im = 0;
    for (const v of selected) {
      const phase = v.k * x - v.w * t;
      re += v.a * Math.cos(phase); im += v.a * Math.sin(phase);
    }
    return { re, im, envelope: Math.hypot(re, im) };
  }
  // q(x,t) is cumulative density in units of n0. dq/dx = n/n0 > 0.
  function position(q, t, selected) {
    let x = q;
    for (let step = 0; step < 6; step++) {
      let residual = x - q, derivative = 1;
      for (const v of selected) {
        const phase = v.k * x - v.w * t;
        residual += v.a / v.k * Math.sin(phase);
        derivative += v.a * Math.cos(phase);
      }
      x -= residual / derivative;
    }
    return x;
  }
  function peak(t, linear = false) {
    if (linear) return VP * t;
    let lo = VG * t - .25, hi = VG * t + .25;
    const selected = modes(false);
    for (let step = 0; step < 32; step++) {
      const a = lo + (hi - lo) / 3, b = hi - (hi - lo) / 3;
      if (sample(a, t, selected).envelope < sample(b, t, selected).envelope) lo = a;
      else hi = b;
    }
    return (lo + hi) / 2;
  }
  globalThis.PlasmaPacketModel = { W0, U, KC, SIGMA, AMPLITUDE, XMIN, XMAX, TMAX,
    WC, VP, VG, frequency, groupSpeed, modes, sample, position, peak };
})();

/* Plasma-wave contribution history (Git author dates; edit time includes timezone).
 * 2026-11-18 16:36 +08:00 | Yinjian Zhao | git 4be5f6b5764f
 * 2026-11-19 16:28 +08:00 | Yinjian Zhao | edit (Codex-assisted)
 */
