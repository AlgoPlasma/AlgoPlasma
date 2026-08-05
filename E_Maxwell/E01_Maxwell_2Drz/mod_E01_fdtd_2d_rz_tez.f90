!> @file mod_E01_fdtd_2d_rz_tez.f90
!> @brief Module wrapper for the E01 TEz component group.
!> @details Includes the ``Ephi`` electric update and ``Hr/Hz`` magnetic
!> update kernels.
!> @author Zhe LIU (2026/05/22)
module mod_E01_fdtd_2d_rz_tez

contains

#include "sub_E01_fdtd_2d_rz_tez_H.f90"
#include "sub_E01_fdtd_2d_rz_tez_E.f90"

end module mod_E01_fdtd_2d_rz_tez
