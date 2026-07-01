# D04_hypre_3Draz_nonuniform — Multi-MPI Nonuniform Cylindrical Poisson Test

This directory provides a **multi-MPI-rank** regression test for the 3D
cylindrical Poisson solver on a nonuniform orthogonal grid in
\f$(r,\alpha,z)\f$.

The test builds a known analytic solution, constructs the corresponding
right-hand side, solves the Poisson equation with HYPRE, writes the
pointwise comparison data to `phi_compare.dat`, and then generates plots for
`phi_num`, `phi_exact`, and `abs_error`.

---

## What this test is for

This test is intended to verify that:

- the nonuniform cylindrical discretization is assembled correctly,
- the HYPRE-based solver pipeline works correctly,
- the MPI decomposition in `r`, `alpha`, and `z` works correctly,
- the numerical solution matches the analytic solution,
- the error distribution is reasonable on the nonuniform mesh.

This is mainly a **correctness / regression test**, not a performance benchmark.

---

## Contents

- `main_D04_test_multi_mpi_raz.f90`  
  Main test program. It builds the global mesh, partitions the domain across
  MPI ranks, constructs the analytic right-hand side, calls the HYPRE solver,
  and writes `phi_compare.dat`.

- `run_multi_raz.sh`  
  Build-run-plot script. It compiles the MPI test, runs it, and then calls the
  Python plotting script.

- `clean.sh`  
  Cleanup script. It removes the executable, compiler-generated files,
  `phi_compare.dat`, and generated figures.

- `plot_phi_compare.py`  
  Python plotting script. It reads `phi_compare.dat` and generates comparison
  figures.

- `fig_phi_compare/`  
  Output directory for all generated PNG figures.

---

## Main output files

After running the test, the main outputs are:

- `phi_compare.dat`  
  Pointwise comparison data containing:
  - grid indices,
  - physical coordinates,
  - numerical solution `phi_num`,
  - exact solution `phi_exact`,
  - absolute error `abs_error`.

- `fig_phi_compare/*.png`  
  Generated plots, including:
  - `r`-line comparisons,
  - `z`-line comparisons,
  - `r-z` slice scatter plots,
  - `r-z` slice pcolormesh plots,
  - `x-y` slice scatter plots,
  - corresponding `phi_num`, `phi_exact`, and `abs_error` figures.

---

## Requirements

The test requires:

- MPI Fortran compiler, such as `mpif90`
- `mpirun`
- HYPRE
- Python 3
- `numpy`
- `matplotlib`

You can quickly check the Python plotting dependencies with:

```bash
python3 -c "import numpy, matplotlib"
```

---

## How to run

```bash
bash run_multi_raz.sh
```

In the current simple test setup:

- the main program fixes `dims = (/2,2,2/)`
- the run script should therefore use `NPROC=8`

So this version is a **fixed 2 x 2 x 2 MPI decomposition test**.

---

## Detailed explanation of `main_D04_test_multi_mpi_raz.f90`

The explanation below follows the **actual execution order** of the program.
That is, it starts from the first MPI calls and only introduces variables when
that part of the code really needs them.

The line numbers below refer to the current `main_D04_test_multi_mpi_raz.f90`.

---

## 1. Start MPI and obtain the basic process information

The program begins with

```fortran
call mpi_init(ierr)
call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)
call mpi_comm_size(mpi_comm_world,mpi_n,ierr)
```

(lines 59-61).

This is the real starting point of the program logic.

### What each call does

- `mpi_init` initializes the MPI runtime.
- `mpi_comm_rank` asks: **which rank am I** inside `MPI_COMM_WORLD`?
- `mpi_comm_size` asks: **how many total MPI ranks are participating**?

### Variables that first matter here

These calls make the following variables relevant:

```fortran
integer :: ierr,ierr_h
integer :: mpi_i,mpi_n
```

(lines 19-20).

Their meanings are:

- `ierr`: MPI error code
- `ierr_h`: HYPRE error code, used later and separate from `ierr`
- `mpi_i`: current MPI rank ID
- `mpi_n`: total number of MPI ranks

At this point, the program has not yet defined the mesh or the Poisson problem.
It only knows **how many processes exist** and **which one this process is**.

---

## 2. Define the global test size

After MPI is ready, the code sets

```fortran
nr = 32
na = 16
nz = 32
```

(lines 73-75).

These are the **global** grid sizes of the whole problem:

- `nr`: number of radial cells
- `na`: number of azimuthal cells
- `nz`: number of axial cells

The declarations are

```fortran
integer :: nr,na,nz
```

(line 23).

So the total number of global cells is

\f[
N_{\mathrm{cell}} = n_r \cdot n_{\alpha} \cdot n_z = 32 \cdot 16 \cdot 32.
\f]

Nothing is local yet. These numbers still describe the whole domain.

---

## 3. Fix the MPI decomposition directly

The next key line is

```fortran
dims = (/2,2,2/)
```

(line 77).

This is different from the older version of the test that searched for a
factorization automatically. In the current simplified version, the MPI
partition is given directly.

### Meaning of `dims`

The declaration is

```fortran
integer :: dims(1:3),coords(1:3),coords_p(1:3)
```

(line 29).

Here `dims` means:

- `dims(1) = 2`: split the `r` direction into 2 parts
- `dims(2) = 2`: split the `alpha` direction into 2 parts
- `dims(3) = 2`: split the `z` direction into 2 parts

So the total number of Cartesian MPI blocks is

\f[
2 \cdot 2 \cdot 2 = 8.
\f]

That is why this simple test should be run with **8 MPI ranks**.

---

## 4. Build the Cartesian communicator

The next block is

```fortran
periods_log = (/ .false., .true., .false. /)
reorder = .false.
call mpi_cart_create(mpi_comm_world,3,dims,periods_log,reorder,cart_comm,ierr)
fcomm = cart_comm
```

(lines 79-82).

### Variables introduced here

These declarations are now relevant:

```fortran
integer :: cart_comm,fcomm
logical :: periods_log(1:3),reorder
```

(lines 21 and 33).

### Meaning

- `cart_comm` is the new Cartesian communicator.
- `fcomm` is simply set equal to `cart_comm` and later passed into the D04 solver.
- `periods_log` tells MPI which topology directions are periodic.
- `reorder` tells MPI whether it may reorder rank numbering.

### Why `periods_log = (/ .false., .true., .false. /)`

The three logical directions are ordered as

\f$(r,\alpha,z)\f$.

So

```fortran
periods_log = (/ .false., .true., .false. /)
```

means:

- `r` is not periodic,
- `alpha` is periodic,
- `z` is not periodic.

This matches the physics of the problem.

---

## 5. Ask MPI where this rank sits in the Cartesian grid

The code next does

```fortran
call mpi_comm_rank(cart_comm,mpi_i,ierr)
call mpi_cart_coords(cart_comm,mpi_i,3,coords,ierr)
```

(lines 84-85).

### Why query the rank again?

The first `mpi_comm_rank` was done on `MPI_COMM_WORLD`.
Now the code asks for the rank inside `cart_comm`, because the Cartesian
communicator is the communicator that will actually be used for the remainder
of the test.

### Meaning of `coords`

`coords(1:3)` gives the logical Cartesian position of the current rank:

- `coords(1)`: rank coordinate in the `r` split
- `coords(2)`: rank coordinate in the `alpha` split
- `coords(3)`: rank coordinate in the `z` split

For example, if a rank has

```text
coords = (1,0,1)
```

then that rank is in:

- the second block in `r`,
- the first block in `alpha`,
- the second block in `z`.

---

## 6. Convert the Cartesian coordinates into owned index ranges

The next three calls are

```fortran
call partition_1d(nr,dims(1),coords(1),il_loc(1),iu_loc(1))
call partition_1d(na,dims(2),coords(2),il_loc(2),iu_loc(2))
call partition_1d(nz,dims(3),coords(3),il_loc(3),iu_loc(3))
```

(lines 87-89).

This is where the program translates the MPI topology into actual global index
ranges owned by the current rank.

### Variables that matter here

```fortran
integer :: il_loc(1:3),iu_loc(1:3),periodic(1:3)
integer :: nloc,nr_loc,na_loc,nz_loc
```

(lines 25 and 30).

The meanings are:

- `il_loc(d)`: lower global index owned in direction `d`
- `iu_loc(d)`: upper global index owned in direction `d`
- `nr_loc`, `na_loc`, `nz_loc`: local sizes
- `nloc`: total number of local cells on this rank

After the three calls, the code computes

```fortran
nr_loc = iu_loc(1)-il_loc(1)+1
na_loc = iu_loc(2)-il_loc(2)+1
nz_loc = iu_loc(3)-il_loc(3)+1
nloc = nr_loc*na_loc*nz_loc
```

(lines 91-94).

So if this rank owns

```text
[i_min, i_max] x [j_min, j_max] x [k_min, k_max]
```

then

\f[
n_{r,\mathrm{loc}} = i_{\max} - i_{\min} + 1,
\f]

\f[
n_{\alpha,\mathrm{loc}} = j_{\max} - j_{\min} + 1,
\f]

\f[
n_{z,\mathrm{loc}} = k_{\max} - k_{\min} + 1,
\f]

and

\f[
n_{\mathrm{loc}} = n_{r,\mathrm{loc}} \cdot n_{\alpha,\mathrm{loc}} \cdot n_{z,\mathrm{loc}}.
\f]

---

## 7. How `partition_1d` works

This helper subroutine is defined in lines 387-403 and is one of the key pieces
of the MPI layout.

The code is

```fortran
subroutine partition_1d(n_global,n_parts,coord,ilo,ihi)
    implicit none
    integer :: n_global,n_parts,coord,ilo,ihi
    integer :: base,rem_1d,n_local

    base = n_global/n_parts
    rem_1d = mod(n_global,n_parts)

    if (coord < rem_1d) then
        n_local = base + 1
        ilo = coord*n_local + 1
    else
        n_local = base
        ilo = rem_1d*(base+1) + (coord-rem_1d)*base + 1
    end if
    ihi = ilo + n_local - 1
end subroutine partition_1d
```

### Step 1: split `n_global` into quotient and remainder

The subroutine first computes

\f[
n_{\mathrm{global}} = \mathrm{base} \cdot n_{\mathrm{parts}} + \mathrm{rem}_{1d},
\f]

with

\f[
0 \le \mathrm{rem}_{1d} < n_{\mathrm{parts}}.
\f]

Here:

- `base = n_global / n_parts`
- `rem_1d = mod(n_global,n_parts)`

So `base` is the minimum number of cells every part gets, and `rem_1d` tells
how many extra cells are left over.

### Step 2: give the remainder cells to the first few parts

If

```fortran
coord < rem_1d
```

then this partition gets one extra cell:

\f[
n_{\mathrm{local}} = \mathrm{base} + 1.
\f]

Otherwise it gets only the base size:

\f[
n_{\mathrm{local}} = \mathrm{base}.
\f]

So the decomposition is as balanced as possible, and the local sizes differ by
at most one.

### Step 3: compute the first owned index `ilo`

For the first `rem_1d` partitions, each one has size `base+1`, so the starting
index is

\f[
i_{\mathrm{lo}} = \mathrm{coord} \cdot (\mathrm{base} + 1) + 1.
\f]

That is exactly what the code writes as

```fortran
ilo = coord*n_local + 1
```

because in that branch `n_local = base + 1`.

For the later partitions, all larger blocks have already been assigned first.
So the starting index must skip:

- `rem_1d` large blocks of size `base+1`, and then
- `(coord-rem_1d)` regular blocks of size `base`.

That gives

\f[
i_{\mathrm{lo}} = \mathrm{rem}_{1d} \cdot (\mathrm{base} + 1) + (\mathrm{coord} - \mathrm{rem}_{1d}) \cdot \mathrm{base} + 1,
\f]

which is exactly the formula in line 400.

### Step 4: compute the last owned index `ihi`

Once `ilo` and `n_local` are known, the end index is simply

\f[
i_{\mathrm{hi}} = i_{\mathrm{lo}} + n_{\mathrm{local}} - 1.
\f]

That is line 402.

### Concrete example

Suppose

\f[
n_{\mathrm{global}} = 10, \qquad n_{\mathrm{parts}} = 3.
\f]

Then

\f[
\mathrm{base} = 3, \qquad \mathrm{rem}_{1d} = 1.
\f]

So the sizes are distributed as

\f[
4,\ 3,\ 3.
\f]

Then:

- `coord = 0` gets `ilo = 1`, `ihi = 4`
- `coord = 1` gets `ilo = 5`, `ihi = 7`
- `coord = 2` gets `ilo = 8`, `ihi = 10`

This is exactly the kind of nearly-even block partitioning we want.

---

## 8. Define physical and boundary-condition parameters

Once the current rank knows its owned box, the program sets

```fortran
eps0 = 1.0
rmin = 0.0
rmax = 1.0
lz = 1.0
tolerance = 1.0e-10
```

(lines 96-100), then

```fortran
periodic = (/0,na,0/)
bc_type = (/BC_AXIS,BC_DIRICHLET,BC_NONE,BC_NONE,BC_DIRICHLET,BC_DIRICHLET/)
bc_value = 0.0
```

(lines 102-104).

### Meanings

The declarations are:

```fortran
real :: eps0,rmin,rmax,lz,tolerance
real :: bc_value(1:6)
integer :: bc_type(1:6)
integer :: il_loc(1:3),iu_loc(1:3),periodic(1:3)
```

So:

- `eps0`: permittivity constant in Poisson's equation
- `rmin`, `rmax`: radial domain bounds
- `lz`: domain length in `z`
- `tolerance`: solver tolerance
- `periodic`: periodicity description for HYPRE
- `bc_type`: boundary type on the six faces
- `bc_value`: boundary value array

### Boundary ordering in `bc_type`

The six entries correspond to

1. low-`r`
2. high-`r`
3. low-`alpha`
4. high-`alpha`
5. low-`z`
6. high-`z`

So

```fortran
bc_type = (/BC_AXIS,BC_DIRICHLET,BC_NONE,BC_NONE,BC_DIRICHLET,BC_DIRICHLET/)
```

means:

- axis treatment at `r = 0`
- Dirichlet at the outer radius
- no explicit boundary in `alpha` because that direction is periodic
- Dirichlet at both `z` ends

### Meaning of `periodic = (/0,na,0/)`

This is the HYPRE periodic-shift representation.
It says:

- no periodicity in `r`
- periodicity in `alpha` over the full azimuthal length `na`
- no periodicity in `z`

---

## 9. Find the neighboring ranks with `mpi_cart_shift`

The next important block is

```fortran
call mpi_cart_shift(cart_comm,0,1,nbr_r_lo,nbr_r_hi,ierr)
call mpi_cart_shift(cart_comm,1,1,nbr_a_lo,nbr_a_hi,ierr)
call mpi_cart_shift(cart_comm,2,1,nbr_z_lo,nbr_z_hi,ierr)
```

(lines 106-108).

### Variables introduced here

```fortran
integer :: nbr_r_lo,nbr_r_hi,nbr_a_lo,nbr_a_hi,nbr_z_lo,nbr_z_hi
logical :: has_neighbor(1:6)
```

(lines 27 and 34).

### Meaning of the arguments in `mpi_cart_shift`

The MPI interface is

```fortran
call mpi_cart_shift(comm,direction,disp,rank_source,rank_dest,ierr)
```

For this program:

- `comm = cart_comm`: use the Cartesian communicator
- `direction = 0,1,2`: choose which logical direction to inspect
- `disp = 1`: shift by **one neighboring block**
- `rank_source`: returned neighbor on the negative side
- `rank_dest`: returned neighbor on the positive side

Now connect that to the actual three calls.

### First call

```fortran
call mpi_cart_shift(cart_comm,0,1,nbr_r_lo,nbr_r_hi,ierr)
```

Here:

- `0` means the **first Cartesian direction**, which in this program is `r`
- `1` means **one-step shift**
- `nbr_r_lo` receives the lower-side `r` neighbor
- `nbr_r_hi` receives the upper-side `r` neighbor

### Second call

```fortran
call mpi_cart_shift(cart_comm,1,1,nbr_a_lo,nbr_a_hi,ierr)
```

Here:

- `1` means the **second Cartesian direction**, which is `alpha`
- the second `1` again means **one-step shift**
- `nbr_a_lo` and `nbr_a_hi` are the lower/high neighbors in `alpha`

Because `alpha` is periodic, these neighbors wrap around when needed.

### Third call

```fortran
call mpi_cart_shift(cart_comm,2,1,nbr_z_lo,nbr_z_hi,ierr)
```

Here:

- `2` means the **third Cartesian direction**, which is `z`
- `1` again means a **one-block shift**
- `nbr_z_lo` and `nbr_z_hi` are the lower/high neighbors in `z`

### Why this is useful

After these calls, the program knows whether each face of the local MPI block
is connected to another rank or lies on a physical boundary.

That information is converted into

```fortran
has_neighbor(1) = (nbr_r_lo /= MPI_PROC_NULL)
has_neighbor(2) = (nbr_r_hi /= MPI_PROC_NULL)
has_neighbor(3) = (nbr_a_lo /= MPI_PROC_NULL)
has_neighbor(4) = (nbr_a_hi /= MPI_PROC_NULL)
has_neighbor(5) = (nbr_z_lo /= MPI_PROC_NULL)
has_neighbor(6) = (nbr_z_hi /= MPI_PROC_NULL)
```

(lines 110-115).

So `has_neighbor(face)` is a Boolean answer to the question:

> Is this local face connected to another MPI rank?

This is essential for matrix assembly.

---

## 10. Define the azimuthal spacing

The next line is

```fortran
da0 = 2.0*pi/real(na)
```

(line 117).

The relevant declarations are

```fortran
real,parameter :: pi = 3.14159265358979323846
real :: da0
```

(lines 16 and 37).

This means the azimuthal spacing is uniform and equal to

\f[
\Delta \alpha = \frac{2\pi}{n_{\alpha}}.
\f]

So later, the azimuthal cell-center coordinate will be

\f[
\alpha_j = \left(j - \frac{1}{2}\right)\Delta \alpha.
\f]

---

## 11. Allocate the global mesh arrays

The code then allocates

```fortran
allocate(dr_global(1:nr))
allocate(da_global(1:na))
allocate(dz_global(1:nz))
allocate(wr(1:nr))
allocate(wz(1:nz))
allocate(rcell_global(1:nr))
allocate(zcell_global(1:nz))
allocate(rface_global(0:nr))
allocate(zface_global(0:nz))
```

(lines 119-127).

### What these arrays represent

From the declarations in lines 47-50:

- `dr_global(i)`: global radial cell width
- `da_global(j)`: global azimuthal cell width
- `dz_global(k)`: global axial cell width
- `wr(i)`: temporary radial weights
- `wz(k)`: temporary axial weights
- `rface_global(0:nr)`: radial face coordinates
- `zface_global(0:nz)`: axial face coordinates
- `rcell_global(i)`: radial cell-center coordinates
- `zcell_global(k)`: axial cell-center coordinates

Every rank builds the same global mesh description. Then each rank extracts only
its owned part and exchanges one ghost layer of widths.

---

## 12. Build the nonuniform radial mesh

The radial mesh is generated in lines 133-155.

The first key line is

```fortran
beta_r = 4.0
```

(line 133), where `beta_r` is declared in line 38.

### Step 1: define the radial weights

The code uses

```fortran
s = real(i-1)/real(nr-1)
wr(i) = 1.0 + beta_r*s*s
```

(lines 138-139).

So `s` runs from 0 to 1, and the weight grows quadratically with radius.
That means larger-`r` cells become wider.

### Step 2: normalize the weights into actual cell widths

The code then computes

```fortran
wsum = sum(wr(1:nr))
dr_global(i) = (rmax-rmin)*wr(i)/wsum
```

(lines 143-146).

This guarantees

\f[
\sum_{i=1}^{n_r} \Delta r_i = r_{\max} - r_{\min}.
\f]

### Step 3: build face coordinates

The code accumulates the widths:

```fortran
rface_global(0) = rmin
do i = 1,nr
    rface_global(i) = rface_global(i-1) + dr_global(i)
end do
```

(lines 148-151).

So

\f[
r_{i+1/2} = r_{i-1/2} + \Delta r_i.
\f]

### Step 4: build cell centers

Finally,

```fortran
rcell_global(i) = 0.5*(rface_global(i-1) + rface_global(i))
```

(lines 153-155), so

\f[
r_i = 0.5 \cdot \left(r_{i-1/2} + r_{i+1/2}\right).
\f]

---

## 13. Build the azimuthal mesh

This part is simple:

```fortran
do j = 1,na
    da_global(j) = da0
end do
```

(lines 157-159).

So every azimuthal cell has the same width

\f[
\Delta \alpha_j = \Delta \alpha = \frac{2\pi}{n_{\alpha}}.
\f]

---

## 14. Build the nonuniform axial mesh

The axial mesh is constructed in lines 161-183.

First the code sets

```fortran
beta_z = 4.0
```

(line 161).

Then it defines weights using

```fortran
s = real(k-1)/real(nz-1)
wz(k) = 1.0 + beta_z*(1.0 - (2.0*s - 1.0)**2)
```

(lines 166-167).

### What this shape means

The function

\f[
1 - (2s - 1)^2
\f]

is largest near the middle of the interval and smaller near the ends.
So the `z` spacing distribution is different from the radial one: here the
weights are emphasized near the center of the domain.

Then the code normalizes the widths:

```fortran
wsum = sum(wz(1:nz))
dz_global(k) = lz*wz(k)/wsum
```

(lines 171-174), ensuring

\f[
\sum_{k=1}^{n_z} \Delta z_k = L_z.
\f]

Finally it builds the face and center coordinates:

```fortran
zface_global(0) = 0.0
do k = 1,nz
    zface_global(k) = zface_global(k-1) + dz_global(k)
end do

do k = 1,nz
    zcell_global(k) = 0.5*(zface_global(k-1) + zface_global(k))
end do
```

(lines 176-182).

---

## 15. Allocate the local spacing arrays, including one ghost width on each side

The next allocations are

```fortran
allocate(dr(il_loc(1)-1:iu_loc(1)+1))
allocate(da(il_loc(2)-1:iu_loc(2)+1))
allocate(dz(il_loc(3)-1:iu_loc(3)+1))
```

(lines 185-187).

These arrays are declared in line 51.

### Why the bounds extend by `-1` and `+1`

Each rank stores:

- its owned widths,
- one ghost width on the lower side,
- one ghost width on the upper side.

That is why the array bounds are extended beyond the owned interval.

The code then zeroes the arrays and copies only the owned values from the
corresponding global arrays (lines 189-200).

---

## 16. Exchange one layer of ghost widths

The next calls are

```fortran
call exchange_ghost_width(cart_comm,nbr_r_lo,nbr_r_hi,101,102,dr,il_loc(1),iu_loc(1))
call exchange_ghost_width(cart_comm,nbr_a_lo,nbr_a_hi,201,202,da,il_loc(2),iu_loc(2))
call exchange_ghost_width(cart_comm,nbr_z_lo,nbr_z_hi,301,302,dz,il_loc(3),iu_loc(3))
```

(lines 203-205).

This fills the one-cell ghost widths on both sides.

### Why this is needed

The matrix assembly near an MPI subdomain interface still needs the adjacent
cell size across that interface.
So even though each rank owns only a local box, it still needs one neighbor
width in each direction.

The helper routine `exchange_ghost_width` is defined in lines 405-418 and uses
`mpi_sendrecv`, which cleanly exchanges one scalar width from each side.

---

## 17. Define the local radial face origin

The line

```fortran
rface_lo = rface_global(il_loc(1)-1)
```

(line 207) sets the physical position of the lower radial face of the first
local cell.

The declaration is

```fortran
real :: rface_lo
```

(line 44).

This value is later passed into the local matrix assembly routine so that the
local block knows where it starts in physical space.

---

## 18. Allocate the solution, exact-solution, RHS, and matrix arrays

The code next allocates

```fortran
allocate(phi1d(1:nloc))
allocate(phi_exact(1:nloc))
allocate(rho1d(1:nloc))
allocate(RHS(1:nloc))
allocate(A_values(1:7*nloc))
```

(lines 209-213).

### Meaning of each array

From line 52:

- `phi1d`: numerical solution returned by the solver
- `phi_exact`: analytic exact solution sampled on local cells
- `rho1d`: analytic source term sampled on local cells
- `RHS`: right-hand side actually sent to HYPRE
- `A_values`: local matrix stencil coefficients

### Why `A_values` has size `7*nloc`

This program uses a 7-point structured stencil:

- center
- `-r`, `+r`
- `-alpha`, `+alpha`
- `-z`, `+z`

So each local cell contributes 7 coefficients.

---

## 19. Initialize the HYPRE control flags and handles

The next block is

```fortran
do_init = .false.
do_updateA = .false.
do_finalize = .false.
grid = 0_8
stencil = 0_8
A = 0_8
b = 0_8
x = 0_8
```

(lines 221-228).

These variables are declared in lines 56-57.

### Meaning

The wrapper `sub_D04_hypre_3Draz_nonuniform` uses the logical flags to decide
what action to take:

- `do_init`: create and initialize HYPRE objects
- `do_updateA`: update the matrix without rebuilding everything
- `do_finalize`: destroy HYPRE objects

The integer(8) variables are HYPRE handles:

- `grid`
- `stencil`
- `A`
- `b`
- `x`

They are initialized to zero before the first call.

---

## 20. Define the analytic solution parameters

The next lines are

```fortran
kappa = j1_zero_1/rmax
mu = pi/lz
```

(lines 230-231).

The declarations are

```fortran
real,parameter :: j1_zero_1 = 3.8317059702075123156
real,parameter :: pi = 3.14159265358979323846
real :: kappa,mu
```

(lines 16-17 and 40).

The analytic solution used in this test is

\f[
\phi(r,\alpha,z) = J_1(\kappa r) \cdot \cos(\alpha) \cdot \sin(\mu z),
\f]

with

\f[
\kappa = \frac{j_{1,1}}{r_{\max}},
\f]

\f[
\mu = \frac{\pi}{L_z},
\f]

where \f$j_{1,1}\f$ is the first zero of \f$J_1\f$.

---

## 21. Sample the analytic solution and source term on local cell centers

The main sampling loop is in lines 233-249:

```fortran
l = 1
do k = il_loc(3),iu_loc(3)
do j = il_loc(2),iu_loc(2)
do i = il_loc(1),iu_loc(1)
    r = rcell_global(i)
    alpha = (real(j)-0.5)*da0
    z = zcell_global(k)

    phi_ex = bessel_j1(kappa*r)*cos(alpha)*sin(mu*z)
    rho_ex = eps0*(kappa*kappa + mu*mu)*phi_ex

    phi_exact(l) = phi_ex
    rho1d(l) = rho_ex
    l = l + 1
end do
end do
end do
```

### Why the coordinates are defined this way

The code samples at **cell centers**:

\f[
r = r_i,
\f]

\f[
\alpha = \left(j - \frac{1}{2}\right)\Delta \alpha,
\f]

\f[
z = z_k.
\f]

So the exact field is evaluated at the same physical locations where the
cell-centered unknowns live.

### Why the source term has this form

For the Poisson equation

\f[
\nabla^2 \phi = -\rho / \varepsilon_0,
\f]

this analytic mode is chosen so that

\f[
\rho = \varepsilon_0 \cdot (\kappa^2 + \mu^2) \cdot \phi.
\f]

So `rho_ex` is the source corresponding to the chosen exact solution.

### Meaning of `l`

The solver stores the local block as a 1D vector, so `l` is the flattened local
index associated with the nested `(i,j,k)` loops.

---

## 22. Initialize HYPRE and assemble the local system

The code then calls

```fortran
call HYPRE_Initialize(ierr_h)
```

(line 251), followed by

```fortran
call sub_D04_hypre_3Draz_nonuniform_A_mpi(il_loc,iu_loc,rface_lo,eps0,dr,da,dz, &
    periodic,has_neighbor,bc_type,bc_value,A_values,rho1d,RHS)
```

(lines 253-254).

### What the assembly routine uses

This routine receives:

- the local owned index box `il_loc:iu_loc`
- the local radial origin `rface_lo`
- local spacings `dr, da, dz` including ghost widths
- periodicity information
- neighbor flags `has_neighbor`
- boundary types and values
- the analytic source `rho1d`

and produces:

- `A_values`: local stencil coefficients
- `RHS`: local right-hand side

This is the step where the discrete linear system is actually built.

---

## 23. Solve with the D04 HYPRE wrapper

The next two calls are the actual solve phase.

### First call: initialize objects and solve

```fortran
do_init = .true.
do_updateA = .false.
do_finalize = .false.
call sub_D04_hypre_3Draz_nonuniform(fcomm,il_loc,iu_loc,phi1d,RHS, &
    tolerance,A_values,periodic,do_init,do_updateA,do_finalize, &
    grid,stencil,A,b,x)
```

(lines 256-261).

This creates the HYPRE objects, loads the matrix and vectors, performs the
solve, and returns the local numerical solution in `phi1d`.

### Second call: finalize the HYPRE objects

```fortran
do_init = .false.
do_updateA = .false.
do_finalize = .true.
call sub_D04_hypre_3Draz_nonuniform(fcomm,il_loc,iu_loc,phi1d,RHS, &
    tolerance,A_values,periodic,do_init,do_updateA,do_finalize, &
    grid,stencil,A,b,x)
```

(lines 263-268).

This destroys the objects cleanly through the same wrapper interface.

After that,

```fortran
call HYPRE_Finalize(ierr_h)
```

(line 270) finalizes the HYPRE library itself.

---

## 24. Compute the local error norms

The next step is the local error analysis in lines 275-293.

The code resets

```fortran
err_linf_loc = 0.0
err_l2_loc = 0.0
ref_l2_loc = 0.0
```

and then loops over the owned cells again.

The key formulas are

```fortran
diff = phi1d(l)-phi_exact(l)
vol = rcell_global(i)*dr_global(i)*da_global(j)*dz_global(k)
```

(lines 283-284).

### Why the cell volume has this form

In cylindrical coordinates, the volume element is

\f[
dV = r \cdot dr \cdot d(\alpha) \cdot dz.
\f]

So the code uses the cell-center approximation

\f[
V_{ijk} \approx r_i \cdot \Delta r_i \cdot \Delta \alpha_j \cdot \Delta z_k.
\f]

That is exactly what line 284 computes.

Then the code accumulates

```fortran
err_linf_loc = max(err_linf_loc,abs(diff))
err_l2_loc = err_l2_loc + diff*diff*vol
ref_l2_loc = ref_l2_loc + phi_exact(l)*phi_exact(l)*vol
```

(lines 286-288).

So locally:

- `err_linf_loc` is the maximum absolute error
- `err_l2_loc` is the weighted squared error integral
- `ref_l2_loc` is the weighted squared exact-solution integral

---

## 25. Reduce the local errors to the root rank

The code combines the local contributions with

```fortran
call mpi_reduce(err_linf_loc,err_linf,1,MPI_DOUBLE_PRECISION,MPI_MAX,0,cart_comm,ierr)
call mpi_reduce(err_l2_loc,err_l2,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,cart_comm,ierr)
call mpi_reduce(ref_l2_loc,ref_l2,1,MPI_DOUBLE_PRECISION,MPI_SUM,0,cart_comm,ierr)
```

(lines 295-297).

### Meaning

- the global `L_inf` error uses `MPI_MAX`
- the global weighted `L2` numerator uses `MPI_SUM`
- the global weighted reference norm uses `MPI_SUM`

Then on rank 0 the code forms

```fortran
err_l2 = sqrt(err_l2/max(ref_l2,tiny(1.0)))
```

(line 300), which corresponds to the relative norm

\f[
\lVert \phi_h - \phi \rVert_{L2} / \lVert \phi \rVert_{L2}.
\f]

---

## 26. Print the global summary and the rank ownership table

Inside

```fortran
if (mpi_i == 0) then
```

(lines 299-326), rank 0 prints:

- the analytic formula
- the fact that the `r` and `z` grids are nonuniform
- the total number of MPI ranks
- the fixed decomposition `dims`
- `beta_r`, `beta_z`, `kappa`
- `nr,na,nz`
- `min(dr), max(dr)`
- `min(dz), max(dz)`
- the error norms

It also loops over all ranks, reconstructs their Cartesian coordinates, calls
`partition_1d` again for each direction, and prints which global box each rank owns.

This is a very useful debugging printout because it lets you verify the actual
3D MPI block layout.

---

## 27. Gather the distributed solution to rank 0

To write a single global output file, rank 0 allocates

```fortran
allocate(phi_all(1:nr,1:na,1:nz))
allocate(phi_exact_all(1:nr,1:na,1:nz))
```

(lines 329-330).

These arrays are declared in line 54.

They store the full global numerical and exact solutions.

Rank 0 first inserts its own local block via

```fortran
call unpack_block(phi1d,phi_all,il_loc,iu_loc)
call unpack_block(phi_exact,phi_exact_all,il_loc,iu_loc)
```

(lines 334-335).

Then, for each other rank, it receives:

1. a header containing the global box limits,
2. the local numerical block,
3. the local exact block.

This is implemented in lines 337-348.

---

## 28. How the explicit gather format works

For non-root ranks, the code sends

```fortran
header = (/il_loc(1),iu_loc(1),il_loc(2),iu_loc(2),il_loc(3),iu_loc(3)/)
call mpi_send(header,6,MPI_INTEGER,0,401,cart_comm,ierr)
call mpi_send(phi1d,nloc,MPI_DOUBLE_PRECISION,0,402,cart_comm,ierr)
call mpi_send(phi_exact,nloc,MPI_DOUBLE_PRECISION,0,403,cart_comm,ierr)
```

(lines 367-370).

So the `header` encodes the exact global box occupied by that rank.
Once rank 0 receives the header, it knows the shape of the incoming block and
where to place it in the global 3D arrays.

This is a manual gather strategy. It is simple, transparent, and very suitable
for a regression test.

---

## 29. Write `phi_compare.dat`

Once rank 0 has collected all local blocks, it writes

```fortran
open(unit=1001,file='phi_compare.dat',status='replace')
write(1001,*) '# i j k r alpha z phi_num phi_exact abs_error'
```

(lines 351-352).

Then it loops over all global cells and writes

- `i, j, k`
- `r, alpha, z`
- `phi_num`
- `phi_exact`
- `abs_error`

using the same cell-center coordinate formulas as before (lines 354-361).

This is why the plotting script can reconstruct global slices directly from a
single file.

---

## 30. Deallocate arrays and finalize MPI

Finally, the program deallocates all arrays (lines 373-381) and calls

```fortran
call mpi_finalize(ierr)
```

(line 383).

That cleanly ends the MPI program.

---

## 31. Helper subroutine: `exchange_ghost_width`

This helper is defined in lines 405-418.

Its job is to exchange one scalar width on each side of a local spacing array.
For an array

```text
arr(ilo-1 : ihi+1)
```

the owned data live in `arr(ilo:ihi)`, while the two ghost locations are:

- `arr(ilo-1)` on the lower side
- `arr(ihi+1)` on the upper side

The routine performs two `mpi_sendrecv` calls:

1. send the lower owned boundary value `arr(ilo)` to the lower neighbor and
   receive the upper ghost value into `arr(ihi+1)` from the upper neighbor,
2. send the upper owned boundary value `arr(ihi)` to the upper neighbor and
   receive the lower ghost value into `arr(ilo-1)` from the lower neighbor.

This is exactly the mesh-width information needed by the local finite-volume
assembly near MPI interfaces.

---

## 32. Helper subroutine: `unpack_block`

This helper is defined in lines 420 onward.

It converts a local 1D buffer into a 3D global array block. It receives:

- `buf(:)`: flattened local data
- `field(:,:,:)`: destination global 3D array
- `il_box(1:3), iu_box(1:3)`: the global box where the data belong

It then loops in the order

```fortran
kk -> jj -> ii
```

and fills the target box entry by entry.

This is the reverse of the local flattening logic used by the solver vectors.

---

## 33. Program logic in one compact view

If you want the whole main program in one compact list, the execution order is:

1. initialize MPI,
2. define the global problem size,
3. fix the MPI decomposition `dims = (/2,2,2/)`,
4. create the Cartesian communicator,
5. get this rank's Cartesian coordinates,
6. convert those coordinates into owned global index ranges,
7. define the physical parameters and boundary-condition types,
8. obtain neighboring ranks with `mpi_cart_shift`,
9. build the global nonuniform mesh,
10. extract local widths and exchange one ghost layer,
11. sample the analytic exact solution and source term,
12. assemble the local matrix and RHS,
13. solve with HYPRE,
14. compute the error norms,
15. gather the distributed solution to rank 0,
16. write `phi_compare.dat`,
17. finalize HYPRE and MPI.

That is the actual logical flow of `main_D04_test_multi_mpi_raz.f90`.