# K05 · Bispectral transfer

[简体中文](README.zh-CN.md) | [Overview](../../docs/source/rst_files/K_Diagnostics/K05_bispectral_transfer.rst)

Follow Brown & Jorns, *Physical Review Letters* **130**, 115101 (2023),
[doi:10.1103/PhysRevLett.130.115101](https://doi.org/10.1103/PhysRevLett.130.115101),
from the wave equation to analysis of synchronous ion-current probe records.
The nine peer pages are:

01. [Wave growth and coupling](../../docs/source/rst_files/K_Diagnostics/K05_wave_growth.rst)
02. [The envelope equation](../../docs/source/rst_files/K_Diagnostics/K05_envelope_coefficients.rst)
03. [Waves and probe records](../../docs/source/rst_files/K_Diagnostics/K05_probe_signals.rst)
04. [Spectral statistics](../../docs/source/rst_files/K_Diagnostics/K05_spectral_statistics.rst)
05. [Coefficient inference](../../docs/source/rst_files/K_Diagnostics/K05_coefficient_inference.rst)
06. [Measured records to statistics](../../docs/source/rst_files/K_Diagnostics/K05_experimental_signals.rst)
07. [Measured moments to L and Q](../../docs/source/rst_files/K_Diagnostics/K05_experimental_coefficients.rst)
08. [Growth and transfer comparison](../../docs/source/rst_files/K_Diagnostics/K05_growth_transfer.rst)
09. [Scripts and reproduction guide](../../docs/source/rst_files/K_Diagnostics/K05_scripts.rst)

## Reproduction and conventions

Use [EXPERIMENT.md](EXPERIMENT.md) for the complete dependency order and commands.
The raw captures and full numerical arrays are external inputs. Pages 06–08 use
saved, traceable figures; opening HTML does not run the analyses.

| Script | Role |
| --- | --- |
| `analyze_spectral_walkthrough.py` | Page 06: signals and complex statistics |
| `analyze_coefficient_walkthrough.py` | Page 07: measured matrices, coefficients and held-out predictions |
| `analyze_extended_comparison.py` | Page 08: common 20 MHz input basis and four whole-capture holdouts |
| `analyze_physical_scenario.py` | Selected moving cold-ion scenario and conditional group velocity |
| `plot_physical_comparison.py` | Paired reference redraws and experimental results |

Shared readers, validation and budget scripts supply the parent results. Page 07 uses
5 MHz inputs; page 08 refits 20 MHz inputs. Do not splice their coefficients.
K05 uses positive-exponent/N Fourier coefficients and `<Y conj(X)>` cross power;
reconcile these conventions explicitly when using K01 outputs.

The statistical model closes for specified predictors and identifiable matrices.
Physical rates additionally depend on response calibration, propagation direction,
wave-variable normalization and a supported dispersion branch. The selected
1 cm acceleration length and 15 degree tilt are assumptions. Reference panels
are attributed image-derived redraws, not the authors' original data; see
[provenance](reference_digitization/README.md).

## Run and check

These are dataset-specific command-line examples with reusable numerical helpers,
not an installed Python package. Keep the module folder intact. The supported
SIGLENT layout, array contracts and optional tools are linked from page09.
From the repository root, install the runtime dependencies and inspect a command:

```bash
python -m pip install -r K_Diagnostics/K05_bispectral_transfer/requirements.txt
python K_Diagnostics/K05_bispectral_transfer/analyze_spectral_walkthrough.py --help
python -m unittest discover -s K_Diagnostics/K05_bispectral_transfer -p 'test_*.py' -v
```

The colocated `test_*.py` files are deterministic maintainer checks, independent of
private recordings. They cover readers, Fourier/PSD normalization, coefficient
recovery, leakage prevention, Kim moments, power budgets and kinetic derivatives.
The walkthroughs are user examples; saved plot inputs are described in EXPERIMENT.md.
Runtime checked with Python3.12.3, NumPy2.3.4, SciPy1.16.3 and Matplotlib3.10.7;
this is not an exhaustive version or operating-system compatibility matrix.

## Build and maintain

Install the repository's `docs/requirements.txt` in a suitable environment;
the documentation configuration also invokes Doxygen. From the repository root:

```bash
python K_Diagnostics/K05_bispectral_transfer/renumber_equations.py --check
python -m sphinx -b html -E -a -W --keep-going docs/source docs/build/html
python -m http.server 8055 --bind 127.0.0.1 --directory docs/build/html
```

Edit `docs/source/rst_files/K_Diagnostics/K05_*.rst`, not generated HTML.
English views are pure English; Chinese views may include English terminology.
Use [EQUATIONS.md](EQUATIONS.md) for consecutive bilingual numbering and stable IDs.
Interactive teaching assets remain in `docs/source/_static/K_Diagnostics`;
the wave-packet, packet-band and probe illustrations use schematic values.

See [tracked data files](DATA_FILES.md) for the purpose of each retained JSON.
