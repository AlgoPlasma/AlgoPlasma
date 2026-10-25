# J02 Nonuniform Speed-Group Tests

[中文](README.zh-CN.md) | [English](README.en.md)

Compare uniform, quadratic-edge and piecewise-uniform speed quadratures in
[J02](../../../../J_Fluid/J02_neutral_sn_transport_2Drz/README.en.md), checking distribution moments and transport errors on a fixed spatial mesh.
Velocity integration uses the reduced two-dimensional measure `v dv dtheta`.
The case includes a prescribed loss frequency; CEX collisions require separate verification.

## Environment and commands

GNU Fortran, Python 3, NumPy and Matplotlib are required. Run from the repository root:

```bash
python3 tests/012_fluid/J02_neutral_sn_transport_2Drz/nonuniform_speed/run_comparison.py
```

The script builds and runs [compare_speed_grids.f90](compare_speed_grids.f90) in serial with 8-byte real values,
array checks and floating-point traps. The reference transport solution uses 16384 speed groups;
peak memory is approximately 1.5 GB. Select a compatible Fortran compiler with `FC`
and a result directory with `--output`.

To redraw figures and regenerate the report from existing CSV files:

```bash
python3 tests/012_fluid/J02_neutral_sn_transport_2Drz/nonuniform_speed/run_comparison.py --analyze-only
```

Both commands must use the same output directory. For a custom location, add `--output /path/to/output` to both.

## Comparison design

The speed cutoff is fixed at 16000 m/s. Group counts are 16, 32, 64, 128, 256 and 512:

| Scheme | Edges or group allocation |
| --- | --- |
| `uniform` | Equal-width intervals |
| `power2` | `v_i = 16000*(i/N)^2` |
| `piecewise` | Edges `[0,1600,9000,15000,16000]` m/s, with group counts allocated in the ratio `8:2:5:1` |

Each node lies at the speed midpoint; its radial velocity-integration weight is `(v_hi-v_lo)*(v_hi+v_lo)/2`.
The test uses drifting two-dimensional Maxwellians with particle mass `2.18017e-25 kg`:

- Cold component: 550 K and axial drift 300 m/s.
- Fast component: axial drift 12000 m/s and thermal standard deviation 600 m/s for each velocity component.
- Mixture: 90% cold and 10% fast by particle number.

| Check | Reference |
| --- | --- |
| Raw distribution moments | With 512 angles, compare density, axial particle flux density, raw second moment and forward half-space flux before discrete normalization against infinite-domain two-dimensional analytical integrals |
| Open-channel transport | Fix a `2×6` spatial mesh, 128 angles, unit incoming particle flux density and loss frequency `2e4 s^-1`; use a cylindrical-volume-weighted relative L1 density error |
| Reference refinement | Compare 8192 and 16384 uniform speed groups on the same spatial and angular grids |
| Angle and cutoff sensitivity | Separately vary 128–1024 angles and cutoffs of 14000–18000 m/s; also compare transport with 128 and 256 angles |

Piecewise boundaries use prior knowledge of these distributions and must be reassessed for other inputs.
Reference refinement measures the change at this speed resolution; full transport accuracy requires separate spatial,
angular and cutoff checks. Reflection source iteration also needs its own convergence check on very coarse speed grids.

## Acceptance criteria

[run_comparison.py](run_comparison.py) checks the row counts and finiteness of all numerical CSV values, and requires:

- Maximum relative particle-balance error below `1e-10` in the channel cases.
- At 512 speed groups, relative analytical errors below `1e-3` for all four raw moments, three schemes and three distributions.
- Successful transport solves; failures return a nonzero process status.

Transport-field errors against the reference and the reference-refinement difference are retained as diagnostics.
Conservation and accuracy checks use their respective references.

## Outputs and interpretation

The default output directory is `build/nonuniform_speed/` under the parent test directory:

| File | Contents |
| --- | --- |
| `moments.csv` | 54 sets of raw moments and analytical values |
| `transport.csv` | 21 sets of transport errors, balances and timings |
| `angle_cutoff.csv` | 21 angle/cutoff checks |
| `speed_grids.png/.svg` | Speed edges, midpoints and distribution scales for the same 32 groups |
| `convergence.png/.svg` | Raw-moment and channel-density errors versus speed-group count |
| `report.md`, `summary.json` | Chinese analytical report and machine-readable summary |
| `compile/`, `compile.log`, `run.log` | Executable, module files and build/run records |

In `speed_grids`, compare node coverage around the cold and fast components.
In `convergence`, compare errors at equal group counts and use the reference-refinement line to interpret the low-error region.
The script retains existing directories and overwrites matching results on rerun.
`--analyze-only` reads existing CSV files and updates figures and the report.

## Module and parallel checks

The ordinary [J02 tests](../README.en.md) and `run_parallel.sh` include
[test_J02_nonuniform_quadrature.f90](../source_f90/test_J02_nonuniform_quadrature.f90).
The spatial MPI program accepts a fourth argument `nonuniform`, selecting four groups with edges
`[0,0.2,0.6,1.5,3]`. First run the parent directory's `run_mpi.sh` to build the parallel configurations,
then execute this selected combination from the repository root:

```bash
OMP_NUM_THREADS=2 OMP_DYNAMIC=FALSE mpiexec -np 4 \
  tests/012_fluid/J02_neutral_sn_transport_2Drz/build/mpi/r8/hybrid/test.out 2 2 custom nonuniform
```

This check requires MPI and an OpenMP-capable Fortran compiler.
