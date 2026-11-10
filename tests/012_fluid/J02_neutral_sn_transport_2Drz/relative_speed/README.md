# J02 Relative-Speed and Coordinate-Conversion Tests

[简体中文](README.zh-CN.md)

Verify velocity-node reconstruction, relative speeds and cylindrical velocity conversion in
[J02](../../../../J_Fluid/J02_neutral_sn_transport_2Drz/README.md), and compare serial/OpenMP results in real4 and real8.
The checks concern kinematics at representative velocity nodes.
Cross sections, ion distributions and CEX frequencies are covered by the [coefficient tests](../cex_coefficients/README.md).

## Environment and commands

Python 3's standard library and an OpenMP-capable GNU Fortran compiler are required.
Run from the repository root:

```bash
python3 tests/012_fluid/J02_neutral_sn_transport_2Drz/relative_speed/run_test.py
```

The script builds four configurations: real4/real8 × serial/four threads.
It enables array checks, invalid/zero/overflow floating-point traps and compiler warnings.
Select a compiler with `--compiler` or `FC`, and a result directory with `--output`.

## Files and interfaces

| File | Purpose |
| --- | --- |
| [run_test.py](run_test.py) | Build and run four configurations; compare logs and CSV records |
| [test_J02_relative_speed.f90](../source_f90/test_J02_relative_speed.f90) | Analytical kinematics and all velocity-node pairs |
| [sub_J02_sn_relative_speed.f90](../../../../J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_relative_speed.f90) | Velocity vectors, relative speed and basis conversion |

Example call fragment:

```fortran
! neutral_velocity(:,m): (v_r,v_phi,v_z) in m/s; J02 sets v_phi=0.
call sub_J02_build_velocity_vectors(neutral_quadrature, neutral_velocity, ierr)
! Check ierr == SN_SUCCESS before using the velocity array.
g = fun_J02_relative_speed(neutral_velocity(:,m), ion_velocity)
! Both velocities above use the same local orthonormal basis.
v_xyz = fun_J02_velocity_cyl_to_cart(neutral_velocity(:,m), space_azimuth)
```

Velocity construction consumes successfully initialized quadrature objects.
Both pure functions require finite inputs and representable outputs; relative speed also requires representable component differences.
The pure functions return numerical values directly.
Local components at different spatial azimuths must first be converted to a common basis.
The three-component container supports general coordinate conversion; J02 transport remains a reduced 2D2V model with `v_phi=0`.

## Checks

| Check | Input or reference |
| --- | --- |
| Identical velocities or both at rest | Relative speed 0 |
| Stationary target | `(300,0,400)` against zero, giving 500 m/s |
| Equal opposite or orthogonal speeds | `2v` and `sqrt(2)*v`, respectively |
| Azimuthal velocity | `(0,300,0)` against `(0,-100,0)`, giving 400 m/s |
| Known rotation | `(3,4,5)` becomes `(-4,3,5)` at spatial azimuth `pi/2` |
| Common rotation | Compare local and converted Cartesian calculations at 17 positive/negative azimuths |
| Different local bases | Both local vectors are `(500,0,0)`, at azimuths 0 and `pi/2`, giving `500*sqrt(2)` |
| Nonuniform velocity nodes | Neutral: 16 angles × 5 speed groups; ion: 8 angles × 3 groups; check components, ordering, zero diagonal and opposite nodes in the same group |
| All node pairs | Compare 80 × 24 = 1920 pairs against the law of cosines; also check exchange symmetry, repeated calls and basis conversion |
| Numerical range | Speeds whose direct squares overflow/underflow while their norms remain representable, and adjacent large floating-point values |

Neutral speed edges are `[0,125,500,1000,2000,4000]` m/s;
ion edges are `[0,250,1500,5000]` m/s.
Ion nodes provide the second set of pairing velocities; this test supplies no ion distribution or density.

## Acceptance criteria

For node speeds `v_m,u_j` and velocity direction angles `alpha_m,beta_j`, use the independent law of cosines:

```text
g_ref = sqrt(v_m^2 + u_j^2 - 2*v_m*u_j*cos(alpha_m-beta_j))
E_pair = abs(g-g_ref) / max(v_m,u_j)
```

Pair errors and pair-rotation comparisons use this node-speed scale with tolerance `200*epsilon(1.0)`,
where `epsilon` corresponds to the compiled real precision.
Other analytical checks use their corresponding nonzero velocity scales;
common rotation, for example, uses the analytical relative speed. Zero references also retain a specified nonzero scale.

The script checks the actual real size, OpenMP worker count and `RESULT: PASS`,
then requires serial/threaded `pairs.csv` files at the same precision to match byte for byte.
Any failed check returns a nonzero status.
These criteria measure representative-node calculation errors; velocity-interval integration errors are addressed by the
[speed-quadrature tests](../nonuniform_speed/README.md).

## Outputs

The default output directory is `build/relative_speed/` under the parent test directory:

```text
r4_serial/   r4_omp4/   r8_serial/   r8_omp4/
  module_compile.log   test_compile.log   test.log
  commands.json        pairs.csv
  module.o             test_J02_relative_speed.out
summary.json
```

Each `pairs.csv` records all 1920 pairs: calculated relative speeds, cosine-law references and converted Cartesian values.
`summary.json` aggregates precision, actual worker counts and error metrics. This test produces no figures.
The script retains existing directories and overwrites matching build files and results on rerun.

The ordinary [J02 tests](../README.md) also include this Fortran program.
Their `make.sh` recreates the parent test directory's `build/`, so run it before the standalone comparison.
