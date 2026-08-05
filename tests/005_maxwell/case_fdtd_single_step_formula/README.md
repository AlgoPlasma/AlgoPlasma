# FDTD Single-Step Formula Tests

This directory validates one-step FDTD update formulas for core Maxwell kernels.
It does not include CPML, particles, current sources, collisions, or filtering.

## Validation Method

- Deterministic probe points are selected per case.
- For each component, one-step kernel output is compared against an explicit reference formula.
- Each test prints `max_abs_err`, `max_rel_err`, and `n_failed`.
- Each test also writes error maps as `*.pgm` images.

## Error Map Notes

- `2D r-z` cases output direct `r-z` maps.
- `3D Cartesian` cases output `x-y (max_z)` projection maps.
- `3D Cyl` cases output `r-z (max_phi)` projection maps.
- Images use `P2` grayscale PGM: `0` is minimum error and `255` is maximum error.

## Case Definitions and Reference Updates

### 1) `test_3d_cartesian_single_step.f90`

Initial fields:

- `Ex0 = 0.26*sin(kx*x+0.2)*cos(ky*y+0.3)*cos(kz*z+0.1) + 0.08*cos(2*kx*x-0.4)*sin(ky*y)*sin(kz*z+0.5)`
- `Ey0 = 0.31*cos(kx*x+0.1)*sin(ky*y+0.2)*cos(kz*z+0.4) + 0.06*sin(2*ky*y+0.7)*sin(kx*x)*cos(kz*z)`
- `Ez0 = 0.29*cos(kx*x+0.5)*cos(ky*y+0.6)*sin(kz*z+0.3) + 0.09*sin(kx*x-0.2)*sin(2*ky*y)*cos(kz*z+0.2)`
- `Hx0 = 0.23*sin(kx*x+0.15)*cos(ky*y+0.35)*sin(kz*z+0.55) + 0.07*cos(2*kz*z+0.2)*cos(kx*x)*sin(ky*y)`
- `Hy0 = 0.27*cos(kx*x+0.45)*sin(ky*y+0.25)*sin(kz*z+0.05) + 0.05*sin(2*kx*x)*cos(ky*y)*cos(kz*z+0.3)`
- `Hz0 = 0.24*sin(kx*x+0.65)*sin(ky*y+0.15)*cos(kz*z+0.45) + 0.08*cos(2*ky*y-0.1)*sin(kx*x+0.3)*sin(kz*z)`

Reference formulas:

- `Ex^{n+1} = Ex^n + dt/ep * [ (Hz(i,j,k)-Hz(i,j-1,k))/dy - (Hy(i,j,k)-Hy(i,j,k-1))/dz ]`
- `Ey^{n+1} = Ey^n + dt/ep * [ (Hx(i,j,k)-Hx(i,j,k-1))/dz - (Hz(i,j,k)-Hz(i-1,j,k))/dx ]`
- `Ez^{n+1} = Ez^n + dt/ep * [ (Hy(i,j,k)-Hy(i-1,j,k))/dx - (Hx(i,j,k)-Hx(i,j-1,k))/dy ]`
- `Hx^{n+1} = Hx^n - dt/mu * [ (Ez(i,j+1,k)-Ez(i,j,k))/dy - (Ey(i,j,k+1)-Ey(i,j,k))/dz ]`
- `Hy^{n+1} = Hy^n - dt/mu * [ (Ex(i,j,k+1)-Ex(i,j,k))/dz - (Ez(i+1,j,k)-Ez(i,j,k))/dx ]`
- `Hz^{n+1} = Hz^n - dt/mu * [ (Ey(i+1,j,k)-Ey(i,j,k))/dx - (Ex(i,j+1,k)-Ex(i,j,k))/dy ]`

### 2) `test_2d_rz_tmz_single_step.f90`

Initial fields:

- `Er0 = r*(0.34 + 0.12*r/lr) * sin(2*pi*z/lz + 0.2)`
- `Ez0 = (1 + 0.08*(r/lr)^2) * cos(2*pi*z/lz + 0.1) + 0.03*cos(4*pi*z/lz)`
- `Hphi0 = r*(0.28 + 0.10*r/lr) * cos(2*pi*z/lz + 0.35)`

Reference formulas:

- `Er^{n+1} = Er^n - dt/ep * (Hphi(i,k)-Hphi(i,k-1))/dz`
- `Ez^{n+1}(i=0) = Ez^n + 4*dt/(ep*dr)*Hphi(0,k)`
- `Ez^{n+1}(i>0) = Ez^n + dt/ep * [ ((i+0.5)Hphi(i,k)-(i-0.5)Hphi(i-1,k)) / (i*dr) ]`
- `Hphi^{n+1} = Hphi^n + dt/mu * [ (Ez(i+1,k)-Ez(i,k))/dr - (Er(i,k+1)-Er(i,k))/dz ]`

### 3) `test_2d_rz_tez_single_step.f90`

Initial fields:

- `Ephi0 = r*(0.25 + 0.09*r/lr) * sin(2*pi*z/lz + 0.30)`
- `Hr0 = r*(0.18 + 0.05*r/lr) * cos(2*pi*z/lz + 0.20)`
- `Hz0 = (0.72 + 0.06*(r/lr)^2) * sin(2*pi*z/lz + 0.15)`

Reference formulas:

- `Ephi^{n+1}(i=0) = 0`
- `Ephi^{n+1}(i>0) = Ephi^n + dt/ep * [ (Hr(i,k)-Hr(i,k-1))/dz - (Hz(i,k)-Hz(i-1,k))/dr ]`
- `Hr^{n+1}(i=0) = 0`
- `Hr^{n+1}(i>0) = Hr^n + dt/mu * (Ephi(i,k+1)-Ephi(i,k))/dz`
- `Hz^{n+1} = Hz^n - dt/mu * [ (r_{i+1/2}Ephi(i+1,k)-r_{i-1/2}Ephi(i,k)) / (r_i*dr) ]`

### 4) `test_3d_cyl_m0_single_step.f90`

Initial fields (`m=0`, no `phi` dependence):

- `Er0 = r*(0.22 + 0.07*r/lr) * sin(2*pi*z/lz + 0.10)`
- `Ephi0 = r*(0.20 + 0.05*r/lr) * cos(2*pi*z/lz + 0.25)`
- `Ez0 = (0.90 + 0.06*(r/lr)^2) * cos(2*pi*z/lz + 0.40)`
- `Hr0 = r*(0.17 + 0.04*r/lr) * sin(2*pi*z/lz + 0.35)`
- `Hphi0 = r*(0.18 + 0.05*r/lr) * cos(2*pi*z/lz + 0.15)`
- `Hz0 = (0.65 + 0.04*(r/lr)^2) * sin(2*pi*z/lz + 0.20)`

Reference formulas:

- `Er^{n+1} = Er^n + dt/ep * [ (Hz(i,j,k)-Hz(i,j-1,k))/(r_{i+1/2}*dphi) - (Hphi(i,j,k)-Hphi(i,j,k-1))/dz ]`
- `Ephi^{n+1}(i=0) = Er^{n+1}(i=0)`
- `Ephi^{n+1}(i>0) = Ephi^n + dt/ep * [ (Hr(i,j,k)-Hr(i,j,k-1))/dz - (Hz(i,j,k)-Hz(i-1,j,k))/dr ]`
- `Ez^{n+1}(i=0) = Ez^n + 4*dt/(ep*dr) * <Hphi_axis>`
- `Ez^{n+1}(i>0) = Ez^n + dt/ep * [ (r_{i+1/2}Hphi(i,j,k)-r_{i-1/2}Hphi(i-1,j,k))/(r_i*dr) - (Hr(i,j,k)-Hr(i,j-1,k))/(r_i*dphi) ]`
- `Hr^{n+1}(i=0) = Hphi^n(i=0)` with enforced `Hr(0,j,k)=Hphi(0,j,k)`
- `Hr^{n+1}(i>0) = Hr^n - dt/mu * [ (Ez(i,j+1,k)-Ez(i,j,k))/(r_i*dphi) - (Ephi(i,j,k+1)-Ephi(i,j,k))/dz ]`
- `Hphi^{n+1} = Hphi^n - dt/mu * [ (Er(i,j,k+1)-Er(i,j,k))/dz - (Ez(i+1,j,k)-Ez(i,j,k))/dr ]`
- `Hz^{n+1} = Hz^n - dt/mu * [ (r_{i+1}Ephi(i+1,j,k)-r_iEphi(i,j,k))/(r_{i+1/2}*dr) - (Er(i,j+1,k)-Er(i,j,k))/(r_{i+1/2}*dphi) ]`

### 5) `test_3d_cyl_m1_single_step.f90`

Initial fields (`m=1`, with `phi` dependence):

- `Er0 = r*(0.24 + 0.06*r/lr) * cos(phi_n) * sin(2*pi*z/lz + 0.12)`
- `Ephi0 = r*(0.21 + 0.05*r/lr) * sin(phi_h) * cos(2*pi*z/lz + 0.34)`
- `Ez0 = (0.86 + 0.07*r/lr) * cos(phi_n) * cos(2*pi*z/lz + 0.22)`
- `Hr0 = r*(0.16 + 0.04*r/lr) * sin(phi_h+0.11) * sin(2*pi*z/lz + 0.18)`
- `Hphi0 = r*(0.17 + 0.05*r/lr) * cos(phi_n+0.15) * cos(2*pi*z/lz + 0.29)`
- `Hz0 = (0.62 + 0.05*r/lr) * sin(phi_h) * sin(2*pi*z/lz + 0.41)`

Reference notes:

- The same update formulas as `m=0` are used, including `i=0` axis handling.
- `m=1` validation also checks `phi` phase consistency and seam coverage (`j=1` and `j=nphi`).

## Latest Run Result

Run date: `2026-04-07`

Run command:

```bash
bash run.sh
```

Summary:

- 3D Cartesian
  - `E-step`: `max_abs_err=0`, `max_rel_err=0`, `n_failed=0`
  - `H-step`: `max_abs_err=0`, `max_rel_err=0`, `n_failed=0`
  - `full-step`: `max_abs_err=0`, `max_rel_err=0`, `n_failed=0`
- 2D r-z TMz
  - `E-step`: `max_abs_err=1.7764e-15`, `max_rel_err=1.2669e-14`, `n_failed=0`
  - `H-step`: `max_abs_err=0`, `max_rel_err=0`, `n_failed=0`
  - `full-step`: `max_abs_err=1.7764e-15`, `max_rel_err=1.2669e-14`, `n_failed=0`
- 2D r-z TEz
  - `E-step`: `max_abs_err=0`, `max_rel_err=0`, `n_failed=0`
  - `H-step`: `max_abs_err=0`, `max_rel_err=0`, `n_failed=0`
  - `full-step`: `max_abs_err=0`, `max_rel_err=0`, `n_failed=0`
- 3D Cyl m=0
  - `E-step`: `max_abs_err=0`, `max_rel_err=0`, `n_failed=0`
  - `H-step`: `max_abs_err=0`, `max_rel_err=0`, `n_failed=0`
  - `full-step`: `max_abs_err=0`, `max_rel_err=0`, `n_failed=0`
- 3D Cyl m=1
  - `E-step`: `max_abs_err=0`, `max_rel_err=0`, `n_failed=0`
  - `H-step`: `max_abs_err=0`, `max_rel_err=0`, `n_failed=0`
  - `full-step`: `max_abs_err=0`, `max_rel_err=0`, `n_failed=0`

## Generated Error Maps

- `err_3d_cartesian_E_step_xy_maxz.pgm`
- `err_3d_cartesian_H_step_xy_maxz.pgm`
- `err_3d_cartesian_full_step_xy_maxz.pgm`
- `err_2d_rz_tmz_E_step_rz.pgm`
- `err_2d_rz_tmz_H_step_rz.pgm`
- `err_2d_rz_tmz_full_step_rz.pgm`
- `err_2d_rz_tez_E_step_rz.pgm`
- `err_2d_rz_tez_H_step_rz.pgm`
- `err_2d_rz_tez_full_step_rz.pgm`
- `err_3d_cyl_m0_E_step_rz_maxphi.pgm`
- `err_3d_cyl_m0_H_step_rz_maxphi.pgm`
- `err_3d_cyl_m0_full_step_rz_maxphi.pgm`
- `err_3d_cyl_m1_E_step_rz_maxphi.pgm`
- `err_3d_cyl_m1_H_step_rz_maxphi.pgm`
- `err_3d_cyl_m1_full_step_rz_maxphi.pgm`

## Build / Run / Clean

```bash
bash make.sh
bash run.sh
bash clean.sh
```
