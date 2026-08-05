!> @file mod_C02_gather_3Dxyz_bspline.f90
!> @brief Collects direct 3D Cartesian B-spline gather routines.
!> @details
!> This source-level module gathers the single-particle electromagnetic-field
!> interpolation routine, the 1D B-spline stencil builder, the centered
!> B-spline shape function, and the scalar tensor-product gather helper.
!> The module is intended to be compiled with C preprocessing enabled so that
!> the included source files are visible to the compiler.
!> @author Xin LUO (2025/12/23), Zhongping ZHAO (2026/05/30)

module mod_C02_gather_3Dxyz_bspline

    implicit none

contains

#   include "sub_C02_gather_3Dxyz_bspline.f90"
#   include "sub_C02_bspline_stencil_1d.f90"
#   include "fun_C02_bspline_shape.f90"
#   include "fun_C02_gather_scalar_bspline.f90"

end module mod_C02_gather_3Dxyz_bspline
