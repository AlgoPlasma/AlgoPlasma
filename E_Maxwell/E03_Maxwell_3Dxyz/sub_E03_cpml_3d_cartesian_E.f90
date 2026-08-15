!> @file sub_E03_cpml_3d_cartesian_E.f90
!> @brief Updates Cartesian electric fields with CPML terms.
!> @details This routine applies split-field CPML corrections to ``Ex``,
!> ``Ey``, and ``Ez``.
!> @author Zhe LIU (2026/04/09)

!> @param[in] ilo_f: integer, lower ``x`` index bound of field arrays.
!> @param[in] ihi_f: integer, upper ``x`` index bound of field arrays.
!> @param[in] jlo_f: integer, lower ``y`` index bound of field arrays.
!> @param[in] jhi_f: integer, upper ``y`` index bound of field arrays.
!> @param[in] klo_f: integer, lower ``z`` index bound of field arrays.
!> @param[in] khi_f: integer, upper ``z`` index bound of field arrays.
!> @param[in] il: integer, lower update ``x`` index.
!> @param[in] iu: integer, upper update ``x`` index.
!> @param[in] jl: integer, lower update ``y`` index.
!> @param[in] ju: integer, upper update ``y`` index.
!> @param[in] kl: integer, lower update ``z`` index.
!> @param[in] ku: integer, upper update ``z`` index.
!> @param[in,out] Ex: real 3D array, ``x`` electric field.
!> @param[in,out] Ey: real 3D array, ``y`` electric field.
!> @param[in,out] Ez: real 3D array, ``z`` electric field.
!> @param[in] Hx: real 3D array, ``x`` magnetic field.
!> @param[in] Hy: real 3D array, ``y`` magnetic field.
!> @param[in] Hz: real 3D array, ``z`` magnetic field.
!> @param[in] dt: real, time step.
!> @param[in] dx: real, grid spacing in ``x``.
!> @param[in] dy: real, grid spacing in ``y``.
!> @param[in] dz: real, grid spacing in ``z``.
!> @param[in] ep: real, permittivity.
!> @param[in] aex: real 1D array, CPML ``a`` for ``x`` in ``E`` update.
!> @param[in] bex: real 1D array, CPML ``b`` for ``x`` in ``E`` update.
!> @param[in] kex: real 1D array, CPML ``k`` for ``x`` in ``E`` update.
!> @param[in] aey: real 1D array, CPML ``a`` for ``y`` in ``E`` update.
!> @param[in] bey: real 1D array, CPML ``b`` for ``y`` in ``E`` update.
!> @param[in] key: real 1D array, CPML ``k`` for ``y`` in ``E`` update.
!> @param[in] aez: real 1D array, CPML ``a`` for ``z`` in ``E`` update.
!> @param[in] bez: real 1D array, CPML ``b`` for ``z`` in ``E`` update.
!> @param[in] kez: real 1D array, CPML ``k`` for ``z`` in ``E`` update.
!> @param[in,out] psi_ex_y: real 3D array, CPML memory term for ``Ex``.
!> @param[in,out] psi_ex_z: real 3D array, CPML memory term for ``Ex``.
!> @param[in,out] psi_ey_z: real 3D array, CPML memory term for ``Ey``.
!> @param[in,out] psi_ey_x: real 3D array, CPML memory term for ``Ey``.
!> @param[in,out] psi_ez_x: real 3D array, CPML memory term for ``Ez``.
!> @param[in,out] psi_ez_y: real 3D array, CPML memory term for ``Ez``.

subroutine sub_E03_cpml_3d_cartesian_E(ilo_f,ihi_f,jlo_f,jhi_f,klo_f,khi_f, &
    il,iu,jl,ju,kl,ku,Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,ep,aex,bex,kex,aey, &
    bey,key,aez,bez,kez,psi_ex_y,psi_ex_z,psi_ey_z,psi_ey_x,psi_ez_x, &
    psi_ez_y)

    implicit none

    integer :: ilo_f,ihi_f,jlo_f,jhi_f,klo_f,khi_f,il,iu,jl,ju,kl,ku
    real :: Ex(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Ey(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Ez(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Hx(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Hy(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Hz(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: dt,dx,dy,dz,ep
    real :: aex(ilo_f:ihi_f),bex(ilo_f:ihi_f),kex(ilo_f:ihi_f)
    real :: aey(jlo_f:jhi_f),bey(jlo_f:jhi_f),key(jlo_f:jhi_f)
    real :: aez(klo_f:khi_f),bez(klo_f:khi_f),kez(klo_f:khi_f)
    real :: psi_ex_y(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_ex_z(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_ey_z(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_ey_x(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_ez_x(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_ez_y(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)

    integer :: i,j,k
    real :: dHz_dy,dHy_dz,dHx_dz,dHz_dx,dHy_dx,dHx_dy

    do k = kl,ku
    do j = jl,ju
    do i = il,iu
        dHz_dy = (Hz(i,j,k)-Hz(i,j-1,k))/dy
        dHy_dz = (Hy(i,j,k)-Hy(i,j,k-1))/dz
        psi_ex_y(i,j,k) = bey(j)*psi_ex_y(i,j,k)+aey(j)*dHz_dy
        psi_ex_z(i,j,k) = bez(k)*psi_ex_z(i,j,k)+aez(k)*dHy_dz
        Ex(i,j,k) = Ex(i,j,k)+dt/ep*(dHz_dy/key(j)-dHy_dz/kez(k)+ &
            psi_ex_y(i,j,k)-psi_ex_z(i,j,k))

        dHx_dz = (Hx(i,j,k)-Hx(i,j,k-1))/dz
        dHz_dx = (Hz(i,j,k)-Hz(i-1,j,k))/dx
        psi_ey_z(i,j,k) = bez(k)*psi_ey_z(i,j,k)+aez(k)*dHx_dz
        psi_ey_x(i,j,k) = bex(i)*psi_ey_x(i,j,k)+aex(i)*dHz_dx
        Ey(i,j,k) = Ey(i,j,k)+dt/ep*(dHx_dz/kez(k)-dHz_dx/kex(i)+ &
            psi_ey_z(i,j,k)-psi_ey_x(i,j,k))

        dHy_dx = (Hy(i,j,k)-Hy(i-1,j,k))/dx
        dHx_dy = (Hx(i,j,k)-Hx(i,j-1,k))/dy
        psi_ez_x(i,j,k) = bex(i)*psi_ez_x(i,j,k)+aex(i)*dHy_dx
        psi_ez_y(i,j,k) = bey(j)*psi_ez_y(i,j,k)+aey(j)*dHx_dy
        Ez(i,j,k) = Ez(i,j,k)+dt/ep*(dHy_dx/kex(i)-dHx_dy/key(j)+ &
            psi_ez_x(i,j,k)-psi_ez_y(i,j,k))
    end do
    end do
    end do

end subroutine sub_E03_cpml_3d_cartesian_E
