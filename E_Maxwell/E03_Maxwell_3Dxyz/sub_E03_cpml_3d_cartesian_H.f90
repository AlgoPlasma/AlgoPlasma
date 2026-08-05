!> @file sub_E03_cpml_3d_cartesian_H.f90
!> @brief Updates Cartesian magnetic fields with CPML terms.
!> @details This routine applies split-field CPML corrections to ``Hx``,
!> ``Hy``, and ``Hz``.
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
!> @param[in] Ex: real 3D array, ``x`` electric field.
!> @param[in] Ey: real 3D array, ``y`` electric field.
!> @param[in] Ez: real 3D array, ``z`` electric field.
!> @param[in,out] Hx: real 3D array, ``x`` magnetic field.
!> @param[in,out] Hy: real 3D array, ``y`` magnetic field.
!> @param[in,out] Hz: real 3D array, ``z`` magnetic field.
!> @param[in] dt: real, time step.
!> @param[in] dx: real, grid spacing in ``x``.
!> @param[in] dy: real, grid spacing in ``y``.
!> @param[in] dz: real, grid spacing in ``z``.
!> @param[in] mu: real, permeability.
!> @param[in] ahx: real 1D array, CPML ``a`` for ``x`` in ``H`` update.
!> @param[in] bhx: real 1D array, CPML ``b`` for ``x`` in ``H`` update.
!> @param[in] khx: real 1D array, CPML ``k`` for ``x`` in ``H`` update.
!> @param[in] ahy: real 1D array, CPML ``a`` for ``y`` in ``H`` update.
!> @param[in] bhy: real 1D array, CPML ``b`` for ``y`` in ``H`` update.
!> @param[in] khy: real 1D array, CPML ``k`` for ``y`` in ``H`` update.
!> @param[in] ahz: real 1D array, CPML ``a`` for ``z`` in ``H`` update.
!> @param[in] bhz: real 1D array, CPML ``b`` for ``z`` in ``H`` update.
!> @param[in] khz: real 1D array, CPML ``k`` for ``z`` in ``H`` update.
!> @param[in,out] psi_hx_y: real 3D array, CPML memory term for ``Hx``.
!> @param[in,out] psi_hx_z: real 3D array, CPML memory term for ``Hx``.
!> @param[in,out] psi_hy_z: real 3D array, CPML memory term for ``Hy``.
!> @param[in,out] psi_hy_x: real 3D array, CPML memory term for ``Hy``.
!> @param[in,out] psi_hz_x: real 3D array, CPML memory term for ``Hz``.
!> @param[in,out] psi_hz_y: real 3D array, CPML memory term for ``Hz``.

subroutine sub_E03_cpml_3d_cartesian_H(ilo_f,ihi_f,jlo_f,jhi_f,klo_f,khi_f, &
    il,iu,jl,ju,kl,ku,Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu,ahx,bhx,khx,ahy, &
    bhy,khy,ahz,bhz,khz,psi_hx_y,psi_hx_z,psi_hy_z,psi_hy_x,psi_hz_x, &
    psi_hz_y)

    implicit none

    integer :: ilo_f,ihi_f,jlo_f,jhi_f,klo_f,khi_f,il,iu,jl,ju,kl,ku
    real :: Ex(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Ey(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Ez(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Hx(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Hy(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Hz(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: dt,dx,dy,dz,mu
    real :: ahx(ilo_f:ihi_f),bhx(ilo_f:ihi_f),khx(ilo_f:ihi_f)
    real :: ahy(jlo_f:jhi_f),bhy(jlo_f:jhi_f),khy(jlo_f:jhi_f)
    real :: ahz(klo_f:khi_f),bhz(klo_f:khi_f),khz(klo_f:khi_f)
    real :: psi_hx_y(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_hx_z(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_hy_z(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_hy_x(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_hz_x(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_hz_y(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)

    integer :: i,j,k
    real :: dEz_dy,dEy_dz,dEx_dz,dEz_dx,dEy_dx,dEx_dy

    do k = kl,ku
    do j = jl,ju
    do i = il,iu
        dEz_dy = (Ez(i,j+1,k)-Ez(i,j,k))/dy
        dEy_dz = (Ey(i,j,k+1)-Ey(i,j,k))/dz
        psi_hx_y(i,j,k) = bhy(j)*psi_hx_y(i,j,k)+ahy(j)*dEz_dy
        psi_hx_z(i,j,k) = bhz(k)*psi_hx_z(i,j,k)+ahz(k)*dEy_dz
        Hx(i,j,k) = Hx(i,j,k)-dt/mu*(dEz_dy/khy(j)-dEy_dz/khz(k)+ &
            psi_hx_y(i,j,k)-psi_hx_z(i,j,k))

        dEx_dz = (Ex(i,j,k+1)-Ex(i,j,k))/dz
        dEz_dx = (Ez(i+1,j,k)-Ez(i,j,k))/dx
        psi_hy_z(i,j,k) = bhz(k)*psi_hy_z(i,j,k)+ahz(k)*dEx_dz
        psi_hy_x(i,j,k) = bhx(i)*psi_hy_x(i,j,k)+ahx(i)*dEz_dx
        Hy(i,j,k) = Hy(i,j,k)-dt/mu*(dEx_dz/khz(k)-dEz_dx/khx(i)+ &
            psi_hy_z(i,j,k)-psi_hy_x(i,j,k))

        dEy_dx = (Ey(i+1,j,k)-Ey(i,j,k))/dx
        dEx_dy = (Ex(i,j+1,k)-Ex(i,j,k))/dy
        psi_hz_x(i,j,k) = bhx(i)*psi_hz_x(i,j,k)+ahx(i)*dEy_dx
        psi_hz_y(i,j,k) = bhy(j)*psi_hz_y(i,j,k)+ahy(j)*dEx_dy
        Hz(i,j,k) = Hz(i,j,k)-dt/mu*(dEy_dx/khx(i)-dEx_dy/khy(j)+ &
            psi_hz_x(i,j,k)-psi_hz_y(i,j,k))
    end do
    end do
    end do

end subroutine sub_E03_cpml_3d_cartesian_H
