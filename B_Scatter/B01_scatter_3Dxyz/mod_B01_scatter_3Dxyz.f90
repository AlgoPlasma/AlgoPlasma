!> @file mod_B01_scatter_3Dxyz.f90
!> @brief Module containing ``sub_B01_scatter_3Dxyz``.
!> @details This module provides the scatter subroutine implementation
!> for 3D Cartesian coordinates through file inclusion.
!> @author Zilong PENG (2026/04/06)



module mod_B01_scatter_3Dxyz

    contains

#   include "sub_B01_scatter_3Dxyz.f90"
#   include "sub_B01_scatter_3Dxyz_v.f90"
#   include "sub_B01_scatter_3Dxyz_T.f90"

end 