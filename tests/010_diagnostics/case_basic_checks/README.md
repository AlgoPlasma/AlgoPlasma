# Basic numerical tests

[简体中文](README.zh-CN.md)

Three groups check whether the diagnostic routines behave as defined on known inputs. Each group presents the test purpose, inputs and steps, expected behavior and its basis, recorded checks, and conclusion. The tables and their pass, fail, or not-run conclusions all come from the same run.

| Test | Purpose and passing conditions |
| --- | --- |
| Spectral power and cross phase | Power satisfies the Parseval relation. Cross phase agrees with an independent direct DFT and the analytical reference for a record spanning an integer number of periods. |
| Phase statistics | The mode-bin center and sample variance agree with hand calculations in two independent cases, one of which crosses ±180°. Each case has its own figure and compares methods on identical observations. |
| Beall weights and spectral peaks | The weights, spectrum values in each bin, and peak positions under two weighting schemes agree with hand calculations. |

- [Basic numerical tests](../../../docs/source/tests/010_diagnostics/case_basic_checks.rst) presents the three sets of result tables and collapsible figures.
- The [spectral leakage note](../../../docs/source/knowledge/spectral_leakage.rst) explains truncation, periodic extension, and the resulting spectrum using a six-panel figure. This test directory generates the same figure that the note displays.
- [Probe Diagnostics Foundations](../../../docs/source/rst_files/K_Diagnostics/diagnostics_foundations.rst) explains the underlying diagnostic methods.

The page and figures display phases in ° and variances in °², with values, errors, and absolute tolerances converted together. Code and full raw records use radians, and wavenumbers use rad/m. Rounded angle labels are for display only. The tests use the original input values.

Run this command from the repository root.

```bash
bash tests/010_diagnostics/case_basic_checks/run.sh
```

The 16 underlying deterministic regression checks record inputs, measurements, criteria, and outcomes, including failures, in `output/summary.json`. The full report is in `output/results.rst`. The files `output/checks_zh.rst` and `output/checks_en.rst` supply the page tables. Plotting reads the small arrays in `output/details/` and the report without rerunning the algorithms. Analytical waveform guides illustrate the recorded inputs. These vectorized checks use one worker and require no production data.

- `source_py/test_regressions.py` defines inputs and assertions.
- `source_py/report.py` generates the numerical report and source hashes and can publish the documentation.
- `source_py/plot_results.py` generates PNG figures from saved results.
- `clean.sh` removes only this case's generated `output/`.

PASS means the stated expectation was met. FAIL indicates a numerical or behavioral mismatch. NOT RUN means the check was not executed. A group passes only when all displayed checks and their parent tests pass. A failure identifies the unmet expectation.

For records spanning a non-integer number of periods, compare the result with an independent direct DFT. The difference from the input phase difference illustrates off-bin bias. A deviation greater than 5° is not a passing condition. Numerical tolerances are set explicitly from float64 machine precision, computation size, and physical units. The page explains these engineering margins for numerical checks. Physical accuracy requires separate evaluation. The phase and Beall figures can be expanded on demand.

Regression checks for wavevector recovery, geometry constraints, grid blocking, and invalid input remain in the full report. The report also includes four checks for unequal phase-variance weights, PSD scaling for odd and even lengths and different sampling rates, comparison against analytical coherence, and invalid Beall baselines. The phase-weighting case uses conflicting observations to verify that the more reliable observation has greater influence. The analytical weighted optimum is `kx` = 0.1 rad/m, and the equal-weight reference is 0.5 rad/m. These are likelihood weights, distinct from the Beall power weights in the third group. The page still presents three groups.

After a successful run, update the documentation snapshot with this command.

```bash
bash tests/010_diagnostics/case_basic_checks/run.sh --publish-docs
```

The command publishes the full report, bilingual page tables, source arrays, PNG figures, and provenance together under `docs/source/tests/010_diagnostics/_generated/case_basic_checks/`. The small snapshot goes into version control. The test generates the runtime `output/` directory. Source hashes identify the tested working tree, including any uncommitted changes. Sphinx reads the snapshot without running these tests.
