!> @file mod_C03_gather_3Draz_nonuniform.f90
!> @brief AlgoPlasma/D04-indexed particle gather on a nonuniform 3D RAZ mesh.
!> @details Geometry uses cell i=[face(i-1),face(i)]. Electrostatic E staggering is fixed:
!> Er:(face,center,center), Ea:(center,face,center), Ez:(center,center,face),
!> and prescribed Br/Ba/Bz:(face,face,face). The module is stateless and MPI-agnostic;
!> ghost values and physical boundary conditions are prepared by the caller.
module mod_C03_gather_3Draz_nonuniform
    implicit none
    private

    public :: sub_C03_gather_3Draz_nonuniform
    public :: sub_C03_gather_3Draz_nonuniform_point
    public :: sub_C03_check_grid

contains
#include "sub_C03_gather_helpers.f90"
#include "sub_C03_gather_3Draz_nonuniform_point.f90"
#include "sub_C03_gather_3Draz_nonuniform.f90"
end module mod_C03_gather_3Draz_nonuniform
