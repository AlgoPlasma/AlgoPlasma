!> @file mod_D01_hypre_3Dxyz_bc.f90
!> @brief Module wrapper for the D01 Cartesian HYPRE Poisson interface.
!> @details
!> This module exposes the Fortran-C bridge routine
!> `sub_D01_hypre_3Dxyz_interface`, which forwards flattened Cartesian
!> Poisson data to the C/HYPRE Struct solver.

module mod_D01_hypre_3Dxyz_bc

    contains

#   include "sub_D01_hypre_3Dxyz_interface.f90"

end module
