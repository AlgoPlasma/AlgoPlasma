/* Check the plotted quadrant, signs, normalization and thermal frequencies. */
const assert = require('node:assert/strict');
require('../source/_static/plasma_waves/wave-derivation-model.js');
require('../source/_static/plasma_waves/wave-spectrum-model.js');
const M = WaveLabModel;
const model = PlasmaDerivationModel;
function near(actual, expected, tolerance) {
  assert.ok(Math.abs(actual-expected)<=tolerance, actual+' vs '+expected);
}
near(M.warmOmega(0,4),1e8,1e-6);
near(M.warmOmega(24,0),1e8,1e-6);
near(M.warmOmega(24,4)**2,1e16 + 3*24**2*4*model.E/model.ME,10);
function peak(column) {return column.indexOf(Math.max(...column))+M.binMin;}
const pair=M.spectrum(M.sampleField(M.modesFor('pair',0.5)));
assert.equal(peak(pair[12]),406);
assert.equal(peak(pair[20]),416);
near(Math.max(...pair[12]),0.25,1e-12);
near(Math.max(...pair[20]),0.0625,1e-12);
const reverse=M.spectrum(M.sampleField([{k:12,w:-1.015e8,a:1,phase:0}]));
assert.ok(Math.max(...reverse.flat()) < 1e-22);
const band=M.spectrum(M.sampleField(M.modesFor('band')));
for (let k=5;k<=24;k++) near(peak(band[k])*M.dw,M.warmOmega(k,4),M.dw/2);
for (const k of [0,4,25,26]) assert.ok(Math.max(...band[k]) < 1e-22);
console.log('Thermal branch, FFT signs, peak coordinates, relative power and twenty off-grid modes passed.');
