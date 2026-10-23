# K05 · Bispectral transfer

[中文](README.zh-CN.md) | [English](README.en.md)

Learn how wave growth and coupling lead to the probe-data analysis in Brown &
Jorns, *Physical Review Letters* **130**, 115101 (2023),
[doi:10.1103/PhysRevLett.130.115101](https://doi.org/10.1103/PhysRevLett.130.115101).

## Available now

The [first page](../../docs/source/rst_files/K_Diagnostics/K05_bispectral_transfer.rst)
derives the structure of Eq. (1) of Brown & Jorns (2023). It introduces a real wave, its complex
envelope, motion of that envelope, quadratic coupling, and restoration of the
fast phase. Optional derivations fold away. An interactive wave packet separates
crest motion, envelope motion, and amplitude growth. Its values are illustrative,
not measurements or a kinetic EDI calculation.

The English view uses English only; the Chinese view includes English terms.
Revision 4 expands the carrier-phase derivative, proves the matched phase-product
identity, and gives the one-dimensional full-wave equation before extending it
to three dimensions. Detailed differentiation, substitution and ordered-pair
counting fold away. The maintained-input coupling example has been removed.
Only this revision's changes are colored. See [equation authoring](EQUATIONS.md)
before adding another K05 page or equation.

**Status: documentation only.** There are no K05 numerical routines, probe-data
scripts, numerical examples, or numerical tests yet. The illustration is a
browser teaching aid, not an analysis API. No experimental figures have been
reproduced.

## Planned path from data to figures

1. Specify synchronized probe voltages, sampling rate, probe order, separation,
   calibration, stationarity windows, and uncertainty inputs.
2. Connect to K01 spectra after explicitly reconciling the Fourier sign,
   amplitude normalization, and positive/negative frequency conventions.
3. Calculate third- and fourth-order statistics, and estimate the linear and
   quadratic coefficients with conditioning and synthetic-data checks.
4. Convert spatial coefficients into growth and transfer rates using the
   required propagation information. Distinguish amplitude from power growth.
5. Produce spectra, growth-rate curves and transfer maps with uncertainty and
   provenance. Matching the published figures requires appropriate experimental
   data and parameters; none are bundled here.

These are future steps, not implemented commands. Resolve the article's phase,
normalization, pair-counting and factor-of-two conventions before implementation.
K01 currently uses NumPy's forward `exp(-i omega t)` transform and the cross
spectrum `X1 * conj(X2)`; do not change that convention implicitly.

## Edit, build, and continue

- Page: `docs/source/rst_files/K_Diagnostics/K05_bispectral_transfer.rst`.
- Teaching assets: `docs/source/_static/K_Diagnostics/k05-wave-packet.{js,css,svg}`.
- Numbering and link infrastructure: see [EQUATIONS.md](EQUATIONS.md).
- Navigation: `docs/source/rst_files/K_Diagnostics.rst` and the K-group READMEs.
- Install the existing `docs/requirements.txt` in a suitable environment; the
  documentation configuration also invokes Doxygen. From the repository root:

```sh
python -m sphinx -b html -W --keep-going docs/source docs/build/html
python -m http.server 8055 --bind 127.0.0.1 --directory docs/build/html
```

Open `http://localhost:8055/rst_files/K_Diagnostics/K05_bispectral_transfer.html`.
Do not edit the generated HTML. Check both language views, equations, disclosures,
and the time/growth/play controls after edits.

Continuation note (2026-10-23): the first review should improve this short lesson
using the reader's questions. Then explain the time Fourier transform from Eq.
(1) to Eq. (2), before implementing inversion. Keep the main narrative simple;
put technical qualifications in optional disclosures. Check equations against
the original paper, printed page 115101-2. The local literature study project's
shared `HANDOFF.md` records the wider reading history; this checkout and that
project require their own actual synchronization to be available on another PC.
