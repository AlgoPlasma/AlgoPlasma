# J03 continuity tests

The runner executes local/setup checks before actual preprocessing-to-continuity integration:

- `test_J03_continuity_units`: closure, timestep, single-step formulas, residuals and errors.
- `test_J03_equilibrium`: artificial-flux boundary equilibrium, source/loss equilibrium and conservation.
- `test_J03_transient`: analytical time evolution, temporal convergence, shared faces, transient balance and steady criteria.
- `test_application_case`: application mask and ION loss window.
- `test_J01_J03_channel`: actual trajectories and tallies passed to J03, two-cell analytical evolution, and a complete sampled FM solve.
- `test_J02_J03_analytic`: spatial refinement against an exact SN distribution, followed by filling from zero with actual reconstructed fluxes.

Independent J01 and J02 tests live in their own directories. These integration checks do not read application outputs.

From the repository root:

```bash
bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh
```

All assertions and exit statuses must indicate success. Logs are written to `build/*.log`.
The Sphinx J03 module, transient and Integration tests pages explain references and tolerances.

Full applications remain separate in `application_reference_J01` (FM→J03) and
`application_reference` (SN→J03). The clean script also removes application
outputs; preserve any needed results first.

Application input and acceptance checks:

```bash
python3 tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/test_application_checks.py
```
