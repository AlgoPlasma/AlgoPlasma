!> @file mod_B02_deposit_charge_3d_cyl.f90
!> @brief 3D cylindrical charge deposition on nodes.
!> @details This module keeps only one public deposition subroutine.
!>          Radial and axial dual-volume corrections are written
!>          directly in the routine to avoid unnecessary helpers.
!> @author Zhijun ZHOU (2026/04/13)
module mod_B02_deposit_charge_3d_cyl
    implicit none

contains

#   include "sub_B02_deposit_charge_3d_cyl.f90"

end module mod_B02_deposit_charge_3d_cyl
