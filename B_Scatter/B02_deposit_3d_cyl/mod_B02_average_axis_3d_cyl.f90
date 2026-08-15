!> @file mod_B02_average_axis_3d_cyl.f90
!> @brief Axis-average utilities for 3D cylindrical deposition arrays.
!> @details This module provides two post-processing routines for values
!>          located on the cylindrical axis: one for node charge density
!>          and one for axial current density.
!> @author Zhijun ZHOU (2026/04/23)
module mod_B02_average_axis_3d_cyl
    implicit none

contains

#   include "sub_B02_average_axis_charge_3d_cyl.f90"
#   include "sub_B02_average_axis_jz_3d_cyl.f90"

end module mod_B02_average_axis_3d_cyl
