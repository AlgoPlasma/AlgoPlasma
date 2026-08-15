!> @file mod_D02_hypre_3Dxyz_bc.f90
!> @brief Module wrapper for the D02 Cartesian HYPRE Poisson routines.
!> @details
!> This module collects the Cartesian 3D Poisson solver wrapper, matrix/RHS
!> assembly routines, dielectric and outflow boundary corrections, and the
!> Fortran HYPRE Struct interface.

module mod_D02_hypre_3Dxyz_bc

    contains

#   include "sub_D02_hypre_3Dxyz_bc.f90"
#   include "sub_D02_hypre_3Dxyz_bc_A.f90"
#   include "sub_D02_hypre_3Dxyz_bc_A_dielectric.f90"
#   include "sub_D02_hypre_3Dxyz_bc_A_outflow.f90"
#   include "sub_D02_hypre_3Dxyz_bc_fortran.f90"

end
