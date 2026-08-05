!> @brief Updates the E01 TMz electric fields ``Er`` and ``Ez`` with CPML terms.
!> @details This routine applies split-field CPML corrections to electric
!> updates. It has no explicit ``i=0`` axis branch for ``Ez``; callers should
!> keep the CPML update range away from the physical radial axis unless they
!> have supplied a valid local discretization for the required neighbor cells.
!> @author Zhe LIU (2026/05/22)

!> @param[in] ilo_f: integer, lower ``r`` index bound of field arrays.
!> @param[in] ihi_f: integer, upper ``r`` index bound of field arrays.
!> @param[in] klo_f: integer, lower ``z`` index bound of field arrays.
!> @param[in] khi_f: integer, upper ``z`` index bound of field arrays.
!> @param[in] il: integer, lower update ``r`` index.
!> @param[in] iu: integer, upper update ``r`` index.
!> @param[in] kl: integer, lower update ``z`` index.
!> @param[in] ku: integer, upper update ``z`` index.
!> @param[in] Ha: real 2D array, azimuthal magnetic field.
!> @param[in,out] Er: real 2D array, radial electric field.
!> @param[in,out] Ez: real 2D array, axial electric field.
!> @param[in] dt: real, time step.
!> @param[in] dr: real, radial grid spacing.
!> @param[in] dz: real, axial grid spacing.
!> @param[in] ep: real, permittivity.
!> @param[in] aer: real 1D array, CPML ``a`` coefficient for ``r`` in ``E``.
!> @param[in] ber: real 1D array, CPML ``b`` coefficient for ``r`` in ``E``.
!> @param[in] ker: real 1D array, CPML ``k`` coefficient for ``r`` in ``E``.
!> @param[in] aez: real 1D array, CPML ``a`` coefficient for ``z`` in ``E``.
!> @param[in] bez: real 1D array, CPML ``b`` coefficient for ``z`` in ``E``.
!> @param[in] kez: real 1D array, CPML ``k`` coefficient for ``z`` in ``E``.
!> @param[in,out] psi_ez_r: real 2D array, CPML memory term for ``Ez``.
!> @param[in,out] psi_er_z: real 2D array, CPML memory term for ``Er``.

subroutine sub_E01_cpml_2d_rz_tmz_E(ilo_f,ihi_f,klo_f,khi_f,il,iu,kl,ku, &
    Ha,Er,Ez,dt,dr,dz,ep,aer,ber,ker,aez,bez,kez,psi_ez_r,psi_er_z)

    implicit none

    integer :: ilo_f,ihi_f,klo_f,khi_f,il,iu,kl,ku
    real :: Ha(ilo_f:ihi_f,klo_f:khi_f)
    real :: Er(ilo_f:ihi_f,klo_f:khi_f)
    real :: Ez(ilo_f:ihi_f,klo_f:khi_f)
    real :: dt,dr,dz,ep
    real :: aer(ilo_f:ihi_f),ber(ilo_f:ihi_f),ker(ilo_f:ihi_f)
    real :: aez(klo_f:khi_f),bez(klo_f:khi_f),kez(klo_f:khi_f)
    real :: psi_ez_r(ilo_f:ihi_f,klo_f:khi_f)
    real :: psi_er_z(ilo_f:ihi_f,klo_f:khi_f)

    integer :: i,k
    real :: ri,dHa_dr,metric_Ha_over_r,term_z

    do k = kl,ku
    do i = il,iu
        term_z = (Ha(i,k)-Ha(i,k-1))/dz
        psi_er_z(i,k) = bez(k)*psi_er_z(i,k)+aez(k)*term_z
        Er(i,k) = Er(i,k)-dt/ep*(term_z/kez(k)+psi_er_z(i,k))
    end do
    end do

    do k = kl,ku
    do i = il,iu
        ri = real(i)*dr
        dHa_dr = (Ha(i,k)-Ha(i-1,k))/dr
        metric_Ha_over_r = 0.5*(Ha(i,k)+Ha(i-1,k))/ri
        psi_ez_r(i,k) = ber(i)*psi_ez_r(i,k)+aer(i)*dHa_dr
        Ez(i,k) = Ez(i,k)+dt/ep*(dHa_dr/ker(i)+psi_ez_r(i,k)+ &
            metric_Ha_over_r)
    end do
    end do

end subroutine sub_E01_cpml_2d_rz_tmz_E
