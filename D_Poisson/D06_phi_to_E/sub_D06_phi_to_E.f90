!> @file sub_D06_phi_to_E.f90
!> @author Zilong PENG (2026/06/05)
!> @brief Compute electric field components from the electrostatic potential
!>        using second-order central differences (E = -∇φ, dx=dy=dz=1).
!> @details
!>   For each cell center ``(i,j,k)`` in the physical domain ``il:iu``,
!>   the three electric field components are computed as:
!>
!>   \f[
!>     E_x(i,j,k) = \frac{\phi(i-1,j,k) - \phi(i+1,j,k)}{2}, \quad
!>     E_y(i,j,k) = \frac{\phi(i,j-1,k) - \phi(i,j+1,k)}{2}, \quad
!>     E_z(i,j,k) = \frac{\phi(i,j,k-1) - \phi(i,j,k+1)}{2}.
!>   \f]
!>
!>   The stencil uses one ghost layer on each side, so ``phi3d`` must
!>   already have its ghost cells filled (e.g. by D05 and any subsequent
!>   boundary condition fixup) before this subroutine is called.
!>
!>   Only physical-domain values ``Ex/Ey/Ez(il:iu,:,:)`` are written;
!>   ghost cells of the output arrays are not touched. After the call,
!>   the electric field ghost cells should be filled by MPI exchange
!>   (e.g. H01) and boundary condition corrections.
!>
!>   The normalisation assumes unit grid spacing (dx=dy=dz=1); the caller
!>   is responsible for converting to physical units.

!> @param[in] il: integer(1:3), cell-center lower indices in x,y,z.
!> @param[in] iu: integer(1:3), cell-center upper indices in x,y,z.
!> @param[in] phi: real(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1,
!>   il(3)-1:iu(3)+1), electrostatic potential including one ghost layer
!>   per side; ghost cells must be filled before calling.
!> @param[out] Ex: real(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1,
!>   il(3)-1:iu(3)+1), x-component of the electric field; physical cells
!>   ``il(1):iu(1)`` are set on output.
!> @param[out] Ey: real(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1,
!>   il(3)-1:iu(3)+1), y-component of the electric field.
!> @param[out] Ez: real(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1,
!>   il(3)-1:iu(3)+1), z-component of the electric field.

subroutine sub_D06_phi_to_E(il,iu,phi,Ex,Ey,Ez)

    implicit none

    integer,dimension(1:3) :: il,iu
    real,dimension(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1) :: phi,Ex,Ey,Ez

    integer :: i,j,k

    do k = il(3),iu(3)
    do j = il(2),iu(2)
    do i = il(1),iu(1)
        Ex(i,j,k) = (phi(i-1,j,k)-phi(i+1,j,k))*0.5
        Ey(i,j,k) = (phi(i,j-1,k)-phi(i,j+1,k))*0.5
        Ez(i,j,k) = (phi(i,j,k-1)-phi(i,j,k+1))*0.5
    end do
    end do
    end do

end subroutine sub_D06_phi_to_E
