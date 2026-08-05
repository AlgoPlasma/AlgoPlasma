!> @file mod_D03_hypre_3Draz_uniform.f90
!> @brief Module that groups the cylindrical 3D uniform HYPRE Poisson solver routines.
!> @details
!> This module groups the cylindrical 3D uniform HYPRE Poisson solver routines
!> by including:
!> - `sub_D03_hypre_3Draz_uniform`: solver driver for the structured HYPRE solve.
!> - `sub_D03_hypre_3Draz_uniform_A`: single-domain matrix and right-hand-side assembly routine.
!> - `sub_D03_hypre_3Draz_uniform_A_mpi`: MPI-local matrix and right-hand-side assembly routine
!>   with explicit neighbor flags.
!> - `sub_D03_hypre_3Draz_uniform_bc_A_dielectric`: dielectric / surface-charge boundary
!>   correction routine.
!> - `sub_D03_hypre_3Draz_uniform_bc_A_outflow`: outflow / Robin-type boundary correction routine.

module mod_D03_hypre_3Draz_uniform
    implicit none
    contains

#   include "sub_D03_hypre_3Draz_uniform.f90"
#   include "sub_D03_hypre_3Draz_uniform_A.f90"
#   include "sub_D03_hypre_3Draz_uniform_A_mpi.f90"
#   include "sub_D03_hypre_3Draz_uniform_bc_A_dielectric.f90"
#   include "sub_D03_hypre_3Draz_uniform_bc_A_outflow.f90"

end module mod_D03_hypre_3Draz_uniform