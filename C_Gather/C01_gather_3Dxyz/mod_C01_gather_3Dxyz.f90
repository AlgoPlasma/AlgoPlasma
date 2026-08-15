!> @file mod_C01_gather_3Dxyz.f90
!> @author Yinjian ZHAO
!> @brief Source-level module entry for C01 3D Cartesian field gather routines.
!> @details
!>   The module collects the single-particle trilinear gather routine and the
!>   fused gather-and-push particle loop through source ``#include`` files.

module mod_C01_gather_3Dxyz

    contains

#   include "sub_C01_gather_3Dxyz.f90"
#   include "sub_C01_gather_3Dxyz_push.f90"

end module mod_C01_gather_3Dxyz
