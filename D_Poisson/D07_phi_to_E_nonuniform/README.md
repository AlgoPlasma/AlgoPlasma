# D07_phi_to_E_nonuniform

[简体中文](README.zh-CN.md)

Compute cell-centered cylindrical fields from D04 nonuniform-grid potentials.

```fortran
use mod_D07_phi_to_E_nonuniform
call sub_D07_phi_to_E_nonuniform(il,iu,rface_lo,dr,da,dz,phi,Er,Ea,Ez)
```

`il/iu(3)` are local owned bounds in r,alpha,z order. `rface_lo` is the
global radius of the lower LOCAL radial face, matching D04 A_mpi.
Positive one-dimensional `dr/da/dz` arrays span `il(d)-1:iu(d)+1`.
Angular widths are radians; all lengths use D04 units.
`phi/Er/Ea/Ez` span those bounds in all three dimensions.
Only owned output cells are overwritten; output halos are preserved.

Three-point quadratic interpolation uses center distances equal to half
the sum of adjacent widths. It is exact for quadratic potentials and has
second-order truncation error as neighbor distances shrink.
`Er=-dphi/dr`, `Ea=-(1/r)*dphi/dalpha`, `Ez=-dphi/dz`.
Ea is a physical cylindrical component, not Cartesian Ey.
Output units are potential/length, without unit-grid scaling.

Workflow: D04 solve, D05 unpack/exchange, physical boundary correction,
D07, then electric-field halo exchange. Fill potential AND width halos
before calling. Periodic width halos wrap from the opposite end.
Single-domain D04 widths need an added halo layer. This module performs
no MPI communication or boundary reconstruction. Boundary accuracy depends
on the supplied ghost potentials. An axis is a face, not a cell center;
the first center is dr/2. Axis ghosts require cylindrical regularity,
not same-angle even reflection for a general non-axisymmetric potential.
No r=0 point values are computed.

The module entry is `mod_D07_phi_to_E_nonuniform.f90`, and the algorithm is implemented in `sub_D07_phi_to_E_nonuniform.f90`. There is no MPI or HYPRE dependency.
Compile with preprocessing, e.g. `-cpp -fdefault-real-8`.

All outputs are cell-centered and cannot be passed directly to the staggered-field C03 interface.
