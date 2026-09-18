# J01_free_molecular

All J01 sources share this directory. Two Fortran modules keep their original names and responsibilities:

- `mod_J01_continuity_freeflow`: the existing 3D continuity API and prescribed-velocity 2D flux/update routines.
- `mod_J01_neutral_free_molecular_2Drz`: particle preprocessing from mesh, inlet and wall conditions to density, velocity and signed face fluxes.

The particle implementation has five include files: `sub_J01_free_molecular_mc_2Drz.f90` orchestrates validation and histories; `sub_J01_fm_sampling.f90` prepares and samples injection; `sub_J01_fm_trajectory.f90` tracks crossings; `sub_J01_fm_reflection.f90` handles wall velocities; `sub_J01_fm_statistics.f90` normalizes residence and crossing tallies.

The application supplies matching boundary inflow and passes reference fields to `sub_J03_initialize_transport_closure`. J03 keeps face velocity fixed and updates flux using current upwind density. Case geometry, I/O and plots remain in application drivers.

The model uses straight two-velocity r-z trajectories, without azimuthal motion, volume ionization or intermolecular collisions. Its truncated-normal inlet-event sampling is not reservoir flux-weighted Maxwell sampling. Density uses residence times; flux uses signed crossings, not cell-average velocity times density.

Compile the required `mod_*.f90` with preprocessing and this include path. Do not compile sub files separately. Use `only` imports if both modules are needed, since constants share names. Legacy 3D APIs remain unchanged; positive `s` is a per-step density decrement.

Run all J01 unit tests from the repository root:

```bash
bash tests/011_fluid/J01_free_molecular/run.sh
```

The Sphinx `J01_free_molecular` section documents formulas, parameters and matching tests.
