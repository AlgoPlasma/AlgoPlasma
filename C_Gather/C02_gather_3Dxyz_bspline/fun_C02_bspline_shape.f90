!> @file fun_C02_bspline_shape.f90
!> @brief Evaluates a centered cardinal B-spline shape function.
!> @details
!> ``fun_C02_bspline_shape`` evaluates the degree ``order`` centered B-spline
!> shape function ``S_order(r)`` by recursion. The zero-order case is the
!> top-hat function on ``[-0.5,0.5)``. Higher orders use the centered
!> two-term recurrence used by the B-spline gather stencil.
!> @author Xin LUO (2025/12/23), Zhongping ZHAO (2026/05/30)

!> @param[in] order: integer, non-negative B-spline degree.
!> @param[in] r: real, distance from the particle position to a grid index.
!> @return real scalar, centered B-spline shape value ``S_order(r)``.

recursive real function fun_C02_bspline_shape(order,r) result(s)

    implicit none

    integer :: order
    real :: r
    real :: h

    if (order < 0) then
        stop "fun_C02_bspline_shape: order must be non-negative"
    end if

    if (order == 0) then

        if (r >= -0.5 .and. r < 0.5) then
            s = 1.0
        else
            s = 0.0
        end if

    else

        h = 0.5 * real(order + 1)

        if (r <= -h .or. r >= h) then

            s = 0.0

        else

            s = ((r + h) / real(order)) * &
                fun_C02_bspline_shape(order-1,r+0.5) + &
                ((h - r) / real(order)) * &
                fun_C02_bspline_shape(order-1,r-0.5)

        end if

    end if

end function fun_C02_bspline_shape
