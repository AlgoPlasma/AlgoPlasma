!> @file sub_B03_scatter_3Dxyz_bspline.f90
!> @brief Deposits particle number to a 3D Cartesian grid with B-spline weights.
!> @details
!> ``sub_B03_scatter_3Dxyz_bspline`` builds one compact B-spline stencil in
!> each coordinate direction from ``par(1:3,p)`` and accumulates the tensor
!> product weights into ``den``. Each particle contributes ``w`` in total,
!> so ``den`` receives a number-density-like field. The target grid follows
!> the B01 scatter convention, so particle coordinates are used directly in
!> grid-index space. For ``order=1``, the weights reduce to the same CIC
!> stencil used by ``sub_B01_scatter_3Dxyz``. The caller should initialize
!> ``den`` before calling this routine.
!> @author Zhongping ZHAO (2026/06/06)

!> @param[in] il: integer (1:3), lower valid grid indices in x,y,z.
!> @param[in] iu: integer (1:3), upper valid grid indices in x,y,z.
!> @param[inout] den: real 3D array, target field receiving scatter contributions.
!> @param[in] np: integer, total number of particles in ``par``.
!> @param[in] par: real (1:6,1:np), particle phase-space array.
!> @param[in] w: real, global particle weight applied to each contribution.
!> @param[in] order: integer, non-negative B-spline degree.

subroutine sub_B03_scatter_3Dxyz_bspline(il,iu,den,np,par,w,order)

    implicit none

    integer,dimension(1:3) :: il,iu
    integer :: np
    integer :: order
    real :: w
    real,dimension(il(1)-((order+2)/2):iu(1)+((order+2)/2), &
        il(2)-((order+2)/2):iu(2)+((order+2)/2), &
        il(3)-((order+2)/2):iu(3)+((order+2)/2)) :: den
    real,dimension(1:6,1:np) :: par

    integer :: p,a,b,c
    integer,dimension(0:order) :: ix,iy,iz
    real,dimension(0:order) :: wx,wy,wz
    real :: wt

    if (order < 0) then
        stop "sub_B03_scatter_3Dxyz_bspline: order must be non-negative"
    end if

    !$omp parallel default(firstprivate) reduction(+:den)
    !$omp do
    do p = 1, np
        call sub_B03_bspline_stencil_1d(order,par(1,p),ix,wx)
        call sub_B03_bspline_stencil_1d(order,par(2,p),iy,wy)
        call sub_B03_bspline_stencil_1d(order,par(3,p),iz,wz)

        do c = 0, order
        do b = 0, order
        do a = 0, order
            wt = wx(a) * wy(b) * wz(c)
            den(ix(a),iy(b),iz(c)) = den(ix(a),iy(b),iz(c)) + w * wt
        end do
        end do
        end do
    end do
    !$omp end do
    !$omp end parallel

end subroutine sub_B03_scatter_3Dxyz_bspline
