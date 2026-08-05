# RZ 2D Uniform vs Nonuniform Grid MMS Test

## 1. Purpose

This test is designed to validate the cylindrical `r-z` Poisson solvers on:

- **uniform grids** (D03)
- **nonuniform grids** (D04)

using the **same manufactured solution**, without modifying the core solver implementation.

The test is intended to check:

- correctness of the `r-z` discretization
- correctness of the axis boundary treatment at `r = 0`
- correctness of the zero-Neumann boundary at `r = r_max`
- correctness of Dirichlet boundaries at `z = 0` and `z = z_max`
- error and convergence behavior on uniform and nonuniform meshes

---

## 2. Manufactured solution

The analytical solution used in this test is:

\f[
\phi(r,z)=\phi_0\left[\left(\frac{r}{L_r}\right)^2-\frac{1}{2}\left(\frac{r}{L_r}\right)^4\right]\sin\left(\pi z/L_z\right)
\f]

where:

- \f$L_r = r_{\max} - r_{\min}\f$
- \f$L_z = z_{\max} - z_{\min}\f$
- \f$\phi_0 = 1\f$

The governing equation is:

\f[
-\nabla^2 \phi = \rho / \varepsilon_0
\f]

The test program evaluates both:

- `phi_exact`
- `rho1d`

at cell centers from this analytical expression.

---

## 3. Boundary conditions

The following boundary conditions are used:

- `r_lo = BC_AXIS`
- `r_hi = BC_NEUMANN`, with `dphi/dn = 0`
- `z_lo = BC_DIRICHLET = 0`
- `z_hi = BC_DIRICHLET = 0`
- periodic in the `alpha` direction

This boundary setup is fully compatible with the current D03 / D04 assembly routines and does not require spatially varying Dirichlet data.

---

## 4. Relevant files

### Fortran main program

- `main_compare_uniform_nonuniform_rz_mms.f90`

This program:

- runs both uniform and nonuniform solvers
- computes `L_inf` and relative `L2` errors
- outputs fine-grid field data

### Python plotting script

- `plot_compare_uniform_nonuniform_rz_mms.py`

This script:

- reads the fine-grid field files
- plots 2D fields in **physical `(r,z)` coordinates**
- uses **cm** as the plotting unit

---

## 5. Output files

After the test runs, the following files are typically generated.

### Error summary

- `compare_uniform_nonuniform_rz_mms.dat`

Format:

```text
# N err_inf_uniform err_l2_uniform err_inf_nonuniform err_l2_nonuniform