// Run with: node docs/tests/test_wave_packet.cjs (no npm dependencies).
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const context = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname, '../source/_static/plasma_waves/wave-packet-model.js'), 'utf8'), context);
const M = context.PlasmaPacketModel;
const near = (actual, expected, tolerance, name) => assert.ok(Math.abs(actual - expected) <= tolerance,
  `${name}: got ${actual}, expected ${expected}, tolerance ${tolerance}`);

const h = .001;
near((M.frequency(M.KC + h) - M.frequency(M.KC - h)) / (2 * h), M.VG, .01, 'group speed from dispersion derivative');
near(M.VP * M.VG / (M.U * M.U), 1, 1e-14, 'warm-branch phase/group identity');
for (const linear of [false, true]) {
  const modes = M.modes(linear);
  assert.equal(modes.length, 31);
  near(modes.reduce((sum, v) => sum + v.a, 0), M.AMPLITUDE, 1e-15, 'spectrum normalization');
  near(M.sample(0, 0, modes).re, .18, 1e-15, 'initial constructive interference');
  for (const v of modes) {
    const dispersion = linear ? M.VP * v.k : Math.sqrt(M.W0 ** 2 + M.U ** 2 * v.k ** 2);
    near(v.w / dispersion, 1, 1e-14, 'component frequency');
  }
  for (const time of [0, 4e-8, 1e-7, M.TMAX]) {
    const center = M.peak(time, linear);
    const peak = M.sample(center, time, modes).envelope;
    assert.ok(peak >= M.sample(center - .001, time, modes).envelope);
    assert.ok(peak >= M.sample(center + .001, time, modes).envelope);
    for (let j = 0; j <= 60; j++) {
      const q = M.XMIN + (M.XMAX - M.XMIN) * j / 60;
      const field = M.sample(q, time, modes);
      assert.ok(field.envelope >= Math.abs(field.re) - 1e-15);
      assert.ok(field.envelope <= .18 + 1e-14);
      assert.ok(1 + field.re >= .82 - 1e-14);
      if (linear) {
        const initial = M.sample(q - M.VP * time, 0, modes);
        near(field.re, initial.re, 5e-15, 'nondispersive shape translation');
        near(field.envelope, initial.envelope, 5e-15, 'nondispersive envelope translation');
      }
      const x = M.position(q, time, modes);
      const mass = x + modes.reduce((sum, v) => sum + v.a / v.k * Math.sin(v.k * x - v.w * time), 0);
      near(mass, q, 1e-13, 'mass-coordinate inversion');
      const jacobian = (M.position(q + 1e-6, time, modes) - M.position(q - 1e-6, time, modes)) / 2e-6;
      near(jacobian, 1 / (1 + M.sample(x, time, modes).re), 1e-7, 'dot spacing matches density');
    }
  }
}
const measuredGroupSpeed = (M.peak(M.TMAX, false) - M.peak(0, false)) / M.TMAX;
assert.ok(Math.abs(measuredGroupSpeed / M.VG - 1) < .01, 'narrow-band envelope speed within 1% of group speed');
assert.ok(M.VP > 3 * measuredGroupSpeed, 'phase marker visibly overtakes the envelope');
console.log(`Wave-packet physics checks passed. vph=${M.VP.toFixed(1)} m/s; vg=${M.VG.toFixed(1)} m/s; envelope=${measuredGroupSpeed.toFixed(1)} m/s.`);
