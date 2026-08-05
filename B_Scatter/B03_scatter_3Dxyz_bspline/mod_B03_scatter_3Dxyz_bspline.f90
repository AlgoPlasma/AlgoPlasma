!> @file mod_B03_scatter_3Dxyz_bspline.f90
!> @brief Collects arbitrary-order 3D Cartesian B-spline scatter routines.
!> @details
!> This source-level module provides particle-to-grid scatter with centered
!> cardinal B-spline weights. Separate top-level routines deposit particle
!> number and one selected particle-array component to a Cartesian grid.
!> The module is intended to be compiled with C preprocessing enabled so that
!> the included source files are visible to the compiler.
!> @author Zhongping ZHAO (2026/06/06)

module mod_B03_scatter_3Dxyz_bspline

    implicit none

contains

#   include "sub_B03_scatter_3Dxyz_bspline.f90"
#   include "sub_B03_scatter_3Dxyz_bspline_v.f90"
#   include "sub_B03_bspline_stencil_1d.f90"
#   include "fun_B03_bspline_shape.f90"

end module mod_B03_scatter_3Dxyz_bspline
