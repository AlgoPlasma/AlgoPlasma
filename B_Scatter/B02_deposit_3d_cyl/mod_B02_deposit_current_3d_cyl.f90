!> @file mod_B02_deposit_current_3d_cyl.f90
!> @brief 3D cylindrical current deposition on Yee edges.
!> @details Only one necessary helper is kept: one routine for splitting
!>          a trajectory into single-cell segments, and one routine for
!>          depositing one single-cell segment. All small utilities are
!>          written inline.
!> @author Zhijun ZHOU (2026/04/13)
module mod_B02_deposit_current_3d_cyl
    implicit none

contains

#   include "sub_B02_deposit_current_3d_cyl.f90"

end module mod_B02_deposit_current_3d_cyl
