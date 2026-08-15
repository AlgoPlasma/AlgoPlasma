!> @file mod_H01_mpi_exchange_field.f90
!> @brief Module wrapper for scalar-field MPI halo exchange.
!>
!> @details
!> Includes ``sub_H01_mpi_exchange_field.f90`` so callers can import the field
!> exchange routine through ``mod_H01_mpi_exchange_field``. The included routine
!> exchanges one ghost layer for a scalar field in x, y, and z directions.

module mod_H01_mpi_exchange_field

    contains

#   include "sub_H01_mpi_exchange_field.f90"

end module mod_H01_mpi_exchange_field
