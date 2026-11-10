# B04: nonuniform cylindrical nodal density deposition

[简体中文](README.zh-CN.md)

Linear cloud-in-cell (CIC) deposition on a 3D structured tensor-product cylindrical
grid, with independently nonuniform spacing in each coordinate direction. Each
call to the scatter routine accumulates the number or charge represented by one
macroparticle into nodal density. In the name, `raz` denotes radial, angular and
axial directions; the angular coordinate is named `phi` in the interfaces.

## Files

| File | Role |
| --- | --- |
| [mod_B04_scatter_3d_raz_nonuniform.f90](mod_B04_scatter_3d_raz_nonuniform.f90) | Module entry and shared status codes |
| [sub_B04_build_geometry.f90](sub_B04_build_geometry.f90) | Inverse effective nodal volumes and angular integration weights |
| [sub_B04_scatter_3d_raz_nonuniform.f90](sub_B04_scatter_3d_raz_nonuniform.f90) | Single-particle nodal density accumulation |
| [sub_B04_average_axis.f90](sub_B04_average_axis.f90) | Weighted axis averaging for a full-circle grid |
| [sub_B04_project_density.f90](sub_B04_project_density.f90) | Optional cell-volume averages |

## Minimal call sequence

With arrays allocated and grid and particle data prepared:

```fortran
use mod_B04_scatter_3d_raz_nonuniform
call sub_B04_build_geometry(r, phi, z, periodic_phi, inv_volume, phi_measure, ierr)
if (ierr /= B04_OK) error stop 'B04 geometry failed'
density = 0.0
call sub_B04_scatter_3d_raz_nonuniform(r, phi, z, periodic_phi, &
    cell, position, amount, inv_volume, density, ierr)
if (ierr /= B04_OK) error stop 'B04 scatter failed'
```

- The caller allocates arrays, applies particle boundary rules and locates each
  particle's cell using the same coordinate arrays.
- Use `amount=wp` for number density or `amount=qp*wp` for charge density, where
  `wp` is the represented particle count and `qp` is the signed charge of one real particle.
- Prepare geometry initially and whenever the grid or periodic setting changes.
  At each new deposition stage, clear density once before the particle loop and
  check `ierr` after each call.
- For MPI shared nodes, use complete effective nodal volumes and sum contributions
  in the caller. On a full-circle grid containing `r=0`, average the axis after
  collecting these contributions.

## Compilation

Requires a Fortran 2008 compiler, preprocessing and the intrinsic
`ieee_arithmetic` module. Compile the module entry with this directory on the
include path (GNU Fortran: `-cpp -I ...`); it includes the four implementation
files. Use matching real precision for the module and caller; GNU Fortran can
use `-fdefault-real-8` for double precision.

## Examples, tests and documentation

- [Calling example and build command](../../examples/B04_scatter_3d_raz_nonuniform/README.md) · [complete example source](../../examples/B04_scatter_3d_raz_nonuniform/main.f90)
- [Test coverage and execution](../../tests/004_scatter/B04_scatter_3d_raz_nonuniform/README.md)
- [B04 algorithm overview](../../docs/source/rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform.rst) · [usage guide](../../docs/source/rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform/usage.rst) (bilingual Sphinx sources)

Run the regression from the repository root in Bash:

```bash
bash tests/004_scatter/B04_scatter_3d_raz_nonuniform/run.sh double debug
```

After building the documentation, open the repository-relative local file
`docs/build/html/rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform.html`.

Reference: Liu, Zhou, Zhao (2026), [preprint v1](https://arxiv.org/abs/2606.09168v1), Sections II.A–B and II.E.

Author: Xin Luo.
