!> @file sub_C02_gather_3Dxyz_bspline.f90
!> @brief Gathers 3D Cartesian electromagnetic fields with B-spline weights.
!> @details
!> ``sub_C02_gather_3Dxyz_bspline`` maps the particle position
!> ``par(1:3,p)`` to cell-centered grid-index space by adding ``0.5`` in
!> each direction. It then builds one compact B-spline stencil per coordinate
!> direction and applies the tensor-product weights to ``Ex``, ``Ey``,
!> ``Ez``, ``Bx``, ``By``, and ``Bz``. For ``order=1``, the stencil is the
!> same linear interpolation stencil used by ``sub_C01_gather_3Dxyz``.
!> @author Xin LUO (2025/12/23), Zhongping ZHAO (2026/05/30)

!> @param[in] p: integer, particle index whose field is gathered.
!> @param[in] np: integer, total number of particles in ``par``.
!> @param[in] par: real (1:6,1:np), particle phase-space array.
!> @param[in] il: integer (1:3), cell-center lower indices in x,y,z.
!> @param[in] iu: integer (1:3), cell-center upper indices in x,y,z.
!> @param[in] Ex: real 3D array, x electric-field component.
!> @param[in] Ey: real 3D array, y electric-field component.
!> @param[in] Ez: real 3D array, z electric-field component.
!> @param[in] Bx: real 3D array, x magnetic-field component.
!> @param[in] By: real 3D array, y magnetic-field component.
!> @param[in] Bz: real 3D array, z magnetic-field component.
!> @param[out] E: real (1:3), gathered electric field at particle ``p``.
!> @param[out] B: real (1:3), gathered magnetic field at particle ``p``.
!> @param[in] order: integer, non-negative B-spline degree.

subroutine sub_C02_gather_3Dxyz_bspline(p,np,par,il,iu,Ex,Ey,Ez, &
    Bx,By,Bz,E,B,order)

    implicit none

    integer :: p,np,order
    real,dimension(1:6,1:np) :: par
    integer,dimension(1:3) :: il,iu
    real,dimension(il(1)-((order+2)/2):iu(1)+((order+2)/2), &
        il(2)-((order+2)/2):iu(2)+((order+2)/2), &
        il(3)-((order+2)/2):iu(3)+((order+2)/2)) :: Ex,Ey,Ez
    real,dimension(il(1)-((order+2)/2):iu(1)+((order+2)/2), &
        il(2)-((order+2)/2):iu(2)+((order+2)/2), &
        il(3)-((order+2)/2):iu(3)+((order+2)/2)) :: Bx,By,Bz
    real,dimension(1:3) :: E,B

    integer :: ng
    real :: x,y,z
    integer,dimension(0:order) :: ix,iy,iz
    real,dimension(0:order) :: wx,wy,wz

    ng = (order + 2) / 2

    x = par(1,p) + 0.5
    y = par(2,p) + 0.5
    z = par(3,p) + 0.5

    call sub_C02_bspline_stencil_1d(order,x,ix,wx)
    call sub_C02_bspline_stencil_1d(order,y,iy,wy)
    call sub_C02_bspline_stencil_1d(order,z,iz,wz)

    E(1) = fun_C02_gather_scalar_bspline(order,ng,il,iu,Ex,ix,iy,iz, &
        wx,wy,wz)
    E(2) = fun_C02_gather_scalar_bspline(order,ng,il,iu,Ey,ix,iy,iz, &
        wx,wy,wz)
    E(3) = fun_C02_gather_scalar_bspline(order,ng,il,iu,Ez,ix,iy,iz, &
        wx,wy,wz)

    B(1) = fun_C02_gather_scalar_bspline(order,ng,il,iu,Bx,ix,iy,iz, &
        wx,wy,wz)
    B(2) = fun_C02_gather_scalar_bspline(order,ng,il,iu,By,ix,iy,iz, &
        wx,wy,wz)
    B(3) = fun_C02_gather_scalar_bspline(order,ng,il,iu,Bz,ix,iy,iz, &
        wx,wy,wz)

end subroutine sub_C02_gather_3Dxyz_bspline
