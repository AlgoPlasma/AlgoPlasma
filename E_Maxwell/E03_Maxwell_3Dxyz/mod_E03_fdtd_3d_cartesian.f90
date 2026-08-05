!> @file mod_E03_fdtd_3d_cartesian.f90
!> @brief Module wrapper for 3D Cartesian FDTD updates.
!> @details Includes six-component electric and magnetic Yee update kernels on
!> a Cartesian grid.
!> @author Zhe LIU (2026/05/22)
module mod_E03_fdtd_3d_cartesian

contains

#include "sub_E03_fdtd_3d_cartesian_H.f90"
#include "sub_E03_fdtd_3d_cartesian_E.f90"
#include "sub_E03_fdtd_3d_cartesian_H_ompdo.f90"
#include "sub_E03_fdtd_3d_cartesian_E_ompdo.f90"

end module mod_E03_fdtd_3d_cartesian
