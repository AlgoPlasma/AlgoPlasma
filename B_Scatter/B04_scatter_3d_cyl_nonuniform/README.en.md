# B04: nonuniform cylindrical nodal density deposition

[中文](README.zh-CN.md) | [English](README.en.md)

Linear CIC on a 3D structured tensor-product cylindrical grid with independently nonuniform spacing. Each call adds the number or charge represented by one macroparticle to nodal density.

See the [Sphinx module page](../../docs/source/rst_files/B_Scatter/B04_scatter_3d_cyl_nonuniform.rst) for formulas, parameters and data flow, or the [local HTML](../../docs/build/html/rst_files/B_Scatter/B04_scatter_3d_cyl_nonuniform.html) after building.

| File | Role |
|---|---|
| [mod_B04_scatter_3d_cyl_nonuniform.f90](mod_B04_scatter_3d_cyl_nonuniform.f90) | Module entry and shared status codes |
| [sub_B04_build_geometry.f90](sub_B04_build_geometry.f90) | Inverse nodal volumes and angular measures |
| [sub_B04_scatter_3d_cyl_nonuniform.f90](sub_B04_scatter_3d_cyl_nonuniform.f90) | Single-particle nodal density accumulation |
| [sub_B04_average_axis.f90](sub_B04_average_axis.f90) | Full-circle axis averaging |
| [sub_B04_project_density.f90](sub_B04_project_density.f90) | Optional cell-volume averages |

```fortran
use mod_B04_scatter_3d_cyl_nonuniform
call sub_B04_build_geometry(r, phi, z, periodic_phi, inv_volume, phi_measure, ierr)
! Check ierr; initialize density once before accumulating particles.
call sub_B04_scatter_3d_cyl_nonuniform(r, phi, z, periodic_phi, &
    cell, position, amount, inv_volume, density, ierr)
```

The caller allocates arrays, locates cells and handles particle boundaries. Use `amount=wp` for number density or `amount=qp*wp` for charge density. Check `ierr` after each call. MPI shared nodes require complete volumes; average a full-circle axis after contribution summation.

Compile the module entry with preprocessing and this directory on the include path (GNU Fortran: `-cpp -I ...`). Use the same precision for module and caller; double precision can use `-fdefault-real-8`.

- [Calling example / 完整调用示例](../../examples/B04_scatter_3d_cyl_nonuniform/main.f90)
- [Usage page / 使用说明](../../docs/source/rst_files/B_Scatter/B04_scatter_3d_cyl_nonuniform/usage.rst)
- [Tests / 测试](../../tests/004_scatter/B04_scatter_3d_cyl_nonuniform/README.md)

```bash
bash tests/004_scatter/B04_scatter_3d_cyl_nonuniform/run.sh double debug
```

Liu, Zhou, Zhao (2026), [preprint v1](https://arxiv.org/abs/2606.09168v1), Sections II.A–B and II.E.

Author: Xin Luo.
