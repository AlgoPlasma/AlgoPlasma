!> @file fun_C02_gather_scalar_bspline.f90
!> @brief Gathers one scalar grid field with tensor-product B-spline weights.
!> @details
!> The function sums one scalar field component over the compact 3D stencil
!> described by ``ix``, ``iy``, ``iz`` and the corresponding 1D weights.
!> The tensor-product coefficient for grid point ``(ix(a),iy(b),iz(c))`` is
!> ``wx(a)*wy(b)*wz(c)``.
!> @author Xin LUO (2025/12/23), Zhongping ZHAO (2026/05/30)

!> @param[in] order: integer, non-negative B-spline degree.
!> @param[in] ng: integer, guard-cell width implied by ``order``.
!> @param[in] il: integer (1:3), cell-center lower indices in x,y,z.
!> @param[in] iu: integer (1:3), cell-center upper indices in x,y,z.
!> @param[in] field: real 3D array, scalar field component on the grid.
!> @param[in] ix: integer (0:order), x-direction stencil indices.
!> @param[in] iy: integer (0:order), y-direction stencil indices.
!> @param[in] iz: integer (0:order), z-direction stencil indices.
!> @param[in] wx: real (0:order), x-direction B-spline weights.
!> @param[in] wy: real (0:order), y-direction B-spline weights.
!> @param[in] wz: real (0:order), z-direction B-spline weights.
!> @return real scalar, gathered scalar field value at the particle position.

real function fun_C02_gather_scalar_bspline(order,ng,il,iu,field,ix,iy,iz, &
    wx,wy,wz)

    implicit none

    integer :: order,ng
    integer,dimension(1:3) :: il,iu
    real,dimension(il(1)-ng:iu(1)+ng, &
        il(2)-ng:iu(2)+ng, &
        il(3)-ng:iu(3)+ng) :: field
    integer,dimension(0:order) :: ix,iy,iz
    real,dimension(0:order) :: wx,wy,wz

    integer :: a,b,c
    integer :: ii,jj,kk
    real :: wt

    fun_C02_gather_scalar_bspline = 0.0

    do c = 0, order
        kk = iz(c)

        do b = 0, order
            jj = iy(b)

            do a = 0, order
                ii = ix(a)

                wt = wx(a) * wy(b) * wz(c)

                fun_C02_gather_scalar_bspline = fun_C02_gather_scalar_bspline + &
                    wt * field(ii,jj,kk)
            end do
        end do
    end do

end function fun_C02_gather_scalar_bspline
