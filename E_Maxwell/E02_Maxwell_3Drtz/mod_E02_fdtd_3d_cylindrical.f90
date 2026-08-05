!> @file mod_E02_fdtd_3d_cylindrical.f90
!> @brief Module wrapper for 3D cylindrical-coordinate FDTD updates.
!> @details Includes six-component electric and magnetic Yee update kernels in
!> cylindrical coordinates.
!> @author Zhe LIU (2026/05/22)
module mod_E02_fdtd_3d_cylindrical

contains

#include "sub_E02_fdtd_3d_cylindrical_H.f90"
#include "sub_E02_fdtd_3d_cylindrical_E.f90"

end module mod_E02_fdtd_3d_cylindrical
