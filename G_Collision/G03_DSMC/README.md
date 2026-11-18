# G03_DSMC

[简体中文](README.zh-CN.md)

A serial C++20 numerical library for equal-weight, single-species elastic collisions
of neutral monatomic particles using HS, VHS or VSS models. The public interface
accepts cylindrical particles and a nonuniform three-dimensional `r/theta/z` grid.
The calling program supplies input parsing, initialization, particle transport,
physical boundaries, fields, the time loop and output. The library advances cell
collisions over a specified interval and returns collision statistics and conservation reports.

## Interface and usage

Include `dsmc.hpp` to access models, calibration functions, cylindrical grids,
particles and the stepper. Construct a model with
`DsmcModel(species, weight, parameters)`; it selects the HS/VHS/VSS collision kernel
and scattering law internally. When a reference dynamic viscosity is known,
use `reference_diameter()` to obtain the reference diameter first.

The following example performs one collision step. Examples and applications
organize initialization and the complete time loop:

```cpp
#include "dsmc.hpp"
#include <utility>
#include <vector>

int main() {
    using namespace algoplasma::dsmc;

    Species argon{0, "Ar", 6.6335209e-26, 0};
    ElasticModelParameters parameters{ElasticModel::VSS, 4.17e-10, 273.0, 0.81, 1.4};
    DsmcModel model(argon, 1.0e7, parameters);

    CylindricalGrid grid(
        {0.0, 1.0e-3, 3.0e-3},
        {0.0, pi, 2.0 * pi},
        {0.0, 1.0e-3, 4.0e-3},
        AngularBoundary::periodic);
    std::vector<CylindricalParticleState> particles{
        {1, 0, {0.5e-3, 0.25 * pi, 0.5e-3}, {150.0, 20.0, 0.0}},
        {2, 0, {0.6e-3, 0.40 * pi, 0.5e-3}, {-150.0, 0.0, 10.0}}
    };

    StepOptions options; // RoundedNtc is the default.
    DsmcStepper stepper(std::move(model), options);
    DsmcWorkspace workspace;
    StepContext context{1.0e-8, 0, 42, 0}; // dt_s, global_step, seed, substep.
    const auto report = stepper.step(particles, grid, context, workspace);
    (void)report;
}
```

Use metres, radians, metres per second, kilograms and kelvin.
`vtheta_mps` is the tangential linear velocity `r*dtheta/dt`. Supply three strictly
increasing arrays of cell-face coordinates. A periodic angular grid spans a full
`2*pi`; the same face arrays determine particle membership and physical cell volumes.
Particle IDs must be unique, species IDs must match the model, and positions must
lie inside the grid.

Inputs are C++ numerical data. The calling program chooses file formats such as CSV
or text, implements their readers, and selects its compilation and linking workflow.

## Candidate schedules and writeback

`StepOptions::candidate_schedule` selects one of two schedules:

- `RoundedNtc` (default): the expected candidate count is
  `A = N(N-1)/2 * W * K_max * dt / V`. Take `floor(A)`, then add one candidate
  with probability equal to the fractional part.
- `ContinuousClock`: accumulate `-log(U)` in integrated-intensity coordinates;
  the candidate count follows a Poisson distribution. Both accepted and rejected
  candidates advance the clock. Set
  `options.candidate_schedule = CandidateSchedule::ContinuousClock` before constructing the stepper.

Both schedules use a collision-kernel bound valid for the entire substep, uniform
pair selection, `K(g)/K_max` acceptance and elastic scattering. Cell membership,
volume and the common particle weight remain fixed during a substep.
Enable `record_events` to log accepted events. The clock's `time_offset_s` is an
approximate time within the substep; NTC reports `nullopt`. Collisions continue
after the event-log limit is reached. Exceeding a candidate budget fails the whole step.

`step()` validates particles, creates internal snapshots in a common Cartesian
xyz basis, sorts by cell and particle ID, and processes collisions. Once every cell
and conservation check succeeds, it prepares all local cylindrical velocities and
commits them to the original array together. Exceptions during input validation,
collisions or writeback preparation leave the original velocities unchanged.
Unchanged snapshot velocities retain their original local components, avoiding
coordinate round-trip rounding when no velocity update occurs.

During a call, particle storage and the grid must remain valid; particle membership,
IDs, positions and storage order must remain fixed and free of concurrent mutation.
A workspace or particle array must participate in only one `step()` at a time.
The workspace can be reused on subsequent steps, each of which reads the current particle state.

## Files

The library consists of 11 headers and 8 `.cpp` files:

| Role | Header | Implementation |
| --- | --- | --- |
| Public interface collection | `dsmc.hpp` | — |
| Physical types, IDs, vectors and common numerical checks | `common.hpp` | Header implementation |
| HS/VHS collision kernels and interval bounds | `rate.hpp` | `fun_G03_dsmc_rate.cpp` |
| Isotropic and VSS scattering | `scattering.hpp` | `fun_G03_dsmc_scatter.cpp` |
| Reference dynamic-viscosity/diameter conversion | `calibration.hpp` | `fun_G03_dsmc_calibration.cpp` |
| Random streams and unbiased integer sampling | `random.hpp` | Header implementation |
| Parameter validation, model construction and properties | `model.hpp` | `fun_G03_dsmc_model.cpp` |
| Cylindrical grid, cell volumes, location and velocity transforms | `cylindrical.hpp` | `fun_G03_dsmc_cylindrical.cpp` |
| Cylindrical particles, snapshot input and writeback preparation | `particles.hpp` | `fun_G03_dsmc_particles.cpp` |
| Internal declarations and cell collisions | `collision_kernel.hpp` | `fun_G03_dsmc_collision.cpp` |
| Step orchestration, internal `CollisionParticle`, workspace and reports | `stepper.hpp` | `fun_G03_dsmc_stepper.cpp` |

`particles.hpp` defines the public `CylindricalParticleState`; its implementation
provides internal `snapshot_particles()` and `prepare_particle_velocities()` functions.
`cylindrical.hpp` defines `CollisionCell`; `collision_kernel.hpp` collects internal
collision-function declarations. The public computation entry is `DsmcStepper::step()`.

## Tests and documentation

[tests/009_collision/G03_DSMC](../../tests/009_collision/G03_DSMC/README.md)
provides eight core groups and six collision-relaxation checks. Run from the repository root:

```bash
bash tests/009_collision/G03_DSMC/run.sh
```

The tests use the cylindrical interface and clean up their temporary build directory
by default. See the test README for dependencies, run groups and output locations.

- [Theory & Algorithm](../../docs/source/rst_files/G_Collision/G03_DSMC/fundamentals.rst): models, calibration, pair rates, candidate schedules and cylindrical cells, with actual source next to the equations.
- [Source Guide](../../docs/source/rst_files/G_Collision/G03_DSMC/implementation.rst): data, grouping, workspace and writeback along `step()`.
- [G03_DSMC Validation](../../docs/source/tests/009_collision/G03_DSMC.rst): call examples, analytical references, statistical tolerances and verification scope.

Random-key field order, position tags, purpose IDs 0–4 and sampling order form part
of the replay convention; changing these rules changes collision trajectories.
Documentation includes current source through `literalinclude`.
