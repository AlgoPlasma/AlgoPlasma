# J03 face-flux continuity tests

Five executables validate local formulas and interfaces:

- test_J02_transport_units: geometry, topology, absorption and boundary signs.
- test_J03_continuity_units: closure, timestep, update, residual and errors.
- test_J03_neutral_continuity_faceflux_2Drz: interfaces, equilibria and conservation.

Additional tests: test_J03_transient covers physical-time evolution, topology and residual convergence; test_application_case checks the shared mask and ION profile.

Run from the repository root:

```bash
bash tests/011_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh
```

The separate application_reference_J01 (FM) and application_reference (SN) cases show preprocessing and its J03 density, using case geometry and optional loss data. clean.sh removes generated outputs.
