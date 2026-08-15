!> @file sub_B02_average_axis_charge_3d_cyl.f90
!> @brief Average charge density values on the cylindrical axis.
!> @details In the 3D cylindrical grid, all indices ``j=0...nphi`` at
!>          ``i=0`` denote the same physical point on the axis. This
!>          routine should be called after the particle loop to replace
!>          all ``rho(0,j,k)`` by their azimuthal average for each axial
!>          index ``k``.
!> @author Zhijun ZHOU (2026/04/23)
!
!> @param[in] nr: integer, number of radial cells.
!> @param[in] nphi: integer, maximum phi node index.
!> @param[in] nz: integer, number of axial cells.
!> @param[inout] rho: real (0:nr,0:nphi,0:nz), node charge density.
subroutine sub_B02_average_axis_charge_3d_cyl(nr,nphi,nz,rho)

    implicit none
    integer :: nr,nphi,nz
    real,dimension(0:nr,0:nphi,0:nz) :: rho

    integer :: j,k
    real :: axis_mean

    do k = 0,nz
        axis_mean = sum(rho(0,:,k))/real(nphi+1)
        do j = 0,nphi
            rho(0,j,k) = axis_mean
        end do
    end do

end subroutine sub_B02_average_axis_charge_3d_cyl
