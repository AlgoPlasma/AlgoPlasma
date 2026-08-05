!> @file sub_C02_bspline_stencil_1d.f90
!> @brief Builds a compact 1D B-spline gather stencil.
!> @details
!> ``sub_C02_bspline_stencil_1d`` chooses the first grid index
!> ``i0=floor(xp-0.5*(order-1))`` and evaluates ``order+1`` centered
!> B-spline weights. The returned arrays use lower bound zero, so the
!> physical grid index for entry ``a`` is ``idx(a)=i0+a``.
!> @author Xin LUO (2025/12/23), Zhongping ZHAO (2026/05/30)

!> @param[in] order: integer, non-negative B-spline degree.
!> @param[in] xp: real, particle position in grid-index space.
!> @param[out] idx: integer (0:order), grid indices in the 1D stencil.
!> @param[out] w: real (0:order), normalized B-spline weights.

subroutine sub_C02_bspline_stencil_1d(order,xp,idx,w)

    implicit none

    integer :: order
    real :: xp
    integer,dimension(0:order) :: idx
    real,dimension(0:order) :: w

    integer :: a,i0
    real :: r,sw

    if (order < 0) then
        stop "sub_C02_bspline_stencil_1d: order must be non-negative"
    end if

    i0 = floor(xp - 0.5*real(order-1))

    do a = 0, order
        idx(a) = i0 + a
        r = xp - real(idx(a))
        w(a) = fun_C02_bspline_shape(order,r)
    end do

    sw = sum(w)

    if (sw > 0.0) then
        w = w / sw
    end if

end subroutine sub_C02_bspline_stencil_1d
