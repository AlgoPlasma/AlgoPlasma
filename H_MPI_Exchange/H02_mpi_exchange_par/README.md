# H02_mpi_exchange_par

[中文](README.zh-CN.md) | [English](README.md)

`H02_mpi_exchange_par` migrates multi-species particles in a 3D Cartesian MPI
domain decomposition.

## Files

- `mod_H02_mpi_exchange_par.f90`: owns neighbor metadata, tags, cached buffers, and `DIR_ID`.
- `sub_H02_mpi_exchange_par_init.f90`: initializes neighbor lists, tags, and cached buffers.
- `sub_H02_mpi_exchange_par.f90`: exchanges particle counts, exchanges payloads, and appends received particles.

## Main Interfaces

- `sub_H02_mpi_exchange_par_init(ns,npm,mpi_n,rank_to_ijk,domain_split,ijk_to_rank)`
- `sub_H02_mpi_exchange_par(ns,np,npmax,par,il,iu,il0,iu0,domain_split,l,nsmax,istat)`

## Notes

Initialize before exchanging. `npm` should be consistent on all ranks. If the
exchange routine returns `istat=1`, increase `npm`, reinitialize, and retry.
