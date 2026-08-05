# H_MPI_Exchange

[中文](README.zh-CN.md) | [English](README.md)

`H_MPI_Exchange` provides data-exchange routines used by AlgoPlasma in MPI domain
decomposition.

## Subdirectories

- `H01_mpi_exchange_field`: one-layer scalar-field ghost/halo exchange; receive overwrites local ghost cells.
- `H02_mpi_exchange_par`: multi-species particle migration across MPI subdomains; receive transfers particle ownership.
- `H03_mpi_exchange_den`: post-scatter density boundary accumulation; receive adds neighbor contributions into local boundary nodes.

## Dependencies

- All routines depend on MPI and use `MPI_COMM_WORLD` directly.
- Sources are organized with Fortran `include`; builds need preprocessing and the proper include path.
- H01 and H03 use odd-even ordering for blocking send/recv. H02 uses a two-phase nonblocking protocol.

## Documentation

Detailed index conventions, communication workflows, test expectations, and API
notes live in the Sphinx `H_MPI_Exchange` pages.
