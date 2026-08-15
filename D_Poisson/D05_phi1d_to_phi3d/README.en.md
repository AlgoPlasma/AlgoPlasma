# D05_phi1d_to_phi3d

[中文](README.zh-CN.md) | [English](README.en.md)

Unpacks the 1D solution vector from the HYPRE Poisson solver into a 3D ghost-cell array, and performs MPI halo exchange for the phi field.

## Files

- `mod_D05_phi1d_to_phi3d.f90`: Module wrapper.
- `sub_D05_phi1d_to_phi3d.f90`: Main subroutine.
- `inc_exchange_in_x/y/z.f90`: MPI halo exchange in each Cartesian direction.
- `inc_send_recv.f90`: Send-then-receive point-to-point pattern (odd ranks).
- `inc_recv_send.f90`: Receive-then-send point-to-point pattern (even ranks).

## Main Interface

```fortran
call sub_D05_phi1d_to_phi3d(il, iu, phi1d, phi3d, &
    mpi_n, rank_to_ijk, domain_split, ijk_to_rank, l)
```

- `phi1d(1:nx*ny*nz)`: 1D solution from HYPRE, loop order `i, j, k`.
- `phi3d(il(1)-1:iu(1)+1, ...)`: 3D output array including one ghost layer per side.
- `l(1:3)`: Physical domain length per direction; used to detect periodic BC.

After the call, ghost cells of `phi3d` are filled with values from neighbouring MPI ranks. Non-periodic boundary ghost cells must be set by the caller afterward.

## Ghost Cell Convention

Each rank's ghost cell `phi3d(iu(1)+1,:,:)` receives `phi3d(il(1),:,:)` from the right neighbour, and `phi3d(il(1)-1,:,:)` receives `phi3d(iu(1),:,:)` from the left neighbour. This differs from the E-field exchange (H01), which uses the second-from-boundary cell.

## Dependencies

Requires MPI.
