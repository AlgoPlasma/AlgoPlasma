/* SI fields sampled on a periodic spatial grid and a finite time record.
 * Forward in x and inverse-sign in t project onto exp[i(kx - omega*t)]. */
(() => {
  'use strict';
  const model = PlasmaDerivationModel;
  const thermalSpeed = energyEV => Math.sqrt(model.E * energyEV / model.ME);
  const warmOmega = (k, energyEV) => model.omega(k, model.NREF, Math.sqrt(3) * thermalSpeed(energyEV));
  const nx = 128, nt = 4096, length = 2 * Math.PI, dw = 2.5e5;
  const dx = length / nx, dt = 2 * Math.PI / (dw * nt);

  function modesFor(kind, amplitude = 0.5) {
    if (kind === 'band') {
      return Array.from({length:20}, (_, index) => ({
        k:index + 5, w:warmOmega(index + 5, 4), a:0.05, phase:index * index * 0.7
      }));
    }
    const modes = [{k:12, w:1.015e8, a:1, phase:0}];
    if (kind === 'pair') modes.push({k:20, w:1.04e8, a:amplitude, phase:0});
    return modes;
  }

  function sampleField(modes) {
    const samples = new Float64Array(nx * nt);
    // Separate space and time phases to avoid evaluating a cosine at every cell.
    for (const {k, w, a, phase} of modes) {
      const cosX = Float64Array.from({length:nx}, (_, j) => a * Math.cos(k*j*dx + phase));
      const sinX = Float64Array.from({length:nx}, (_, j) => a * Math.sin(k*j*dx + phase));
      for (let t = 0; t < nt; t++) {
        const c = Math.cos(w*t*dt), s = Math.sin(w*t*dt);
        for (let x = 0; x < nx; x++) samples[t*nx+x] += cosX[x]*c + sinX[x]*s;
      }
    }
    return samples;
  }

  // Iterative radix-2 transform. Both directions are unnormalized here.
  function fft(re, im, sign) {
    const n = re.length;
    for (let i = 1, j = 0; i < n; i++) {
      let bit = n >> 1;
      while (j & bit) { j ^= bit; bit >>= 1; }
      j ^= bit;
      if (i < j) {
        [re[i], re[j]] = [re[j], re[i]];
        [im[i], im[j]] = [im[j], im[i]];
      }
    }
    for (let span = 2; span <= n; span *= 2) {
      const angle = sign * 2 * Math.PI / span;
      const cr = Math.cos(angle), ci = Math.sin(angle);
      for (let base = 0; base < n; base += span) {
        let wr = 1, wi = 0;
        for (let j = base; j < base + span/2; j++) {
          const other = j + span/2;
          const r = wr*re[other] - wi*im[other], v = wr*im[other] + wi*re[other];
          re[other] = re[j] - r; im[other] = im[j] - v;
          re[j] += r; im[j] += v;
          const nr = wr*cr - wi*ci;
          wi = wr*ci + wi*cr; wr = nr;
        }
      }
    }
  }

  const kMax = 26, binMin = 392, binMax = 432;
  function spectrum(samples) {
    const re = samples.slice(), im = new Float64Array(re.length);
    for (let t = 0; t < nt; t++) {
      fft(re.subarray(t*nx, (t+1)*nx), im.subarray(t*nx, (t+1)*nx), -1);
    }
    const colR = new Float64Array(nt), colI = new Float64Array(nt);
    const power = [];
    for (let k = 0; k <= kMax; k++) {
      for (let t = 0; t < nt; t++) {
        colR[t] = re[t*nx+k]; colI[t] = im[t*nx+k];
      }
      fft(colR, colI, 1);
      const column = [];
      for (let b = binMin; b <= binMax; b++) column.push((colR[b]**2 + colI[b]**2)/(nx*nt)**2);
      power.push(column);
    }
    return power;
  }
  globalThis.WaveLabModel = {warmOmega, modesFor, sampleField, spectrum, nx, nt, dx, dt, dw, binMin, binMax, kMax};
})();

/* Plasma-wave contribution history (Git author dates; edit time includes timezone).
 * 2026-11-19 15:26 +08:00 | Yinjian Zhao | git b9e33596c00f
 * 2026-11-19 16:28 +08:00 | Yinjian Zhao | edit (Codex-assisted)
 */
