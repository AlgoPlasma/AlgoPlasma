!> @file sub_B02_average_axis_jz_3d_cyl.f90
!> @brief Average axial current density values on the cylindrical axis.
!> @details In the 3D cylindrical Yee grid, all indices ``j=0...nphi``
!>          at ``i=0`` denote the same physical point on the axis. This
!>          routine should be called after the particle loop to replace
!>          all ``jz(0,j,k)`` by their azimuthal average for each axial
!>          index ``k``. This treatment follows the axis handling used
!>          in the paper for full PIC tests.
!> @author Zhijun ZHOU (2026/04/23)
!
!> @param[in] nr: integer, number of radial cells.
!> @param[in] nphi: integer, maximum phi node index.
!> @param[in] nz: integer, number of axial cells.
!> @param[inout] jz: real (0:nr,0:nphi,0:nz), axial current density.
subroutine sub_B02_average_axis_jz_3d_cyl(nr,nphi,nz,jz)

    implicit none
    integer :: nr,nphi,nz
    real,dimension(0:nr,0:nphi,0:nz) :: jz

    integer :: j,k
    real :: axis_mean

    do k = 0,nz
        axis_mean = sum(jz(0,:,k))/real(nphi+1)
        do j = 0,nphi
            jz(0,j,k) = axis_mean
        end do
    end do

end subroutine sub_B02_average_axis_jz_3d_cyl
