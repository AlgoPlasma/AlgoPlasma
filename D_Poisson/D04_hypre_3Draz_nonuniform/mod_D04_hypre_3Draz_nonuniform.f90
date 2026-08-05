!> @file mod_D04_hypre_3Draz_nonuniform.f90
!> @brief Group the cylindrical 3D nonuniform HYPRE Poisson routines.
!> @details
!> This module includes:
!> - `sub_D04_hypre_3Draz_nonuniform`: HYPRE solver driver.
!> - `sub_D04_hypre_3Draz_nonuniform_A`: single-domain matrix/RHS assembly.
!> - `sub_D04_hypre_3Draz_nonuniform_A_mpi`: MPI-local matrix/RHS assembly
!>   with one ghost layer and explicit neighbor flags.
!> - `sub_D04_hypre_3Draz_nonuniform_bc_A_dielectric`: dielectric / surface-charge
!>   boundary correction routine.
!> - `sub_D04_hypre_3Draz_nonuniform_bc_A_outflow`: outflow / Robin-type
!>   boundary correction routine.

module mod_D04_hypre_3Draz_nonuniform

    contains

#   include "sub_D04_hypre_3Draz_nonuniform.f90"
#   include "sub_D04_hypre_3Draz_nonuniform_A.f90"
#   include "sub_D04_hypre_3Draz_nonuniform_A_mpi.f90"
#   include "sub_D04_hypre_3Draz_nonuniform_bc_A_dielectric.f90"
#   include "sub_D04_hypre_3Draz_nonuniform_bc_A_outflow.f90"

end
