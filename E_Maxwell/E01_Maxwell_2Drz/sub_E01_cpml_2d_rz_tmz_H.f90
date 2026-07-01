!> @brief Updates the E01 TMz magnetic field ``Ha`` with CPML terms.
!> @details This routine applies split-field CPML corrections to the TMz
!> magnetic update in cylindrical ``r-z`` coordinates.
!> @author Zhe LIU (2026/05/22)

!> @param[in] ilo_f: integer, lower ``r`` index bound of field arrays.
!> @param[in] ihi_f: integer, upper ``r`` index bound of field arrays.
!> @param[in] klo_f: integer, lower ``z`` index bound of field arrays.
!> @param[in] khi_f: integer, upper ``z`` index bound of field arrays.
!> @param[in] il: integer, lower update ``r`` index.
!> @param[in] iu: integer, upper update ``r`` index.
!> @param[in] kl: integer, lower update ``z`` index.
!> @param[in] ku: integer, upper update ``z`` index.
!> @param[in,out] Ha: real 2D array, azimuthal magnetic field.
!> @param[in] Er: real 2D array, radial electric field.
!> @param[in] Ez: real 2D array, axial electric field.
!> @param[in] dt: real, time step.
!> @param[in] dr: real, radial grid spacing.
!> @param[in] dz: real, axial grid spacing.
!> @param[in] mu: real, permeability.
!> @param[in] ahr: real 1D array, CPML ``a`` coefficient for ``r`` in ``H``.
!> @param[in] bhr: real 1D array, CPML ``b`` coefficient for ``r`` in ``H``.
!> @param[in] khr: real 1D array, CPML ``k`` coefficient for ``r`` in ``H``.
!> @param[in] ahz: real 1D array, CPML ``a`` coefficient for ``z`` in ``H``.
!> @param[in] bhz: real 1D array, CPML ``b`` coefficient for ``z`` in ``H``.
!> @param[in] khz: real 1D array, CPML ``k`` coefficient for ``z`` in ``H``.
!> @param[in,out] psi_ha_r: real 2D array, CPML memory term for ``Ha``.
!> @param[in,out] psi_ha_z: real 2D array, CPML memory term for ``Ha``.

subroutine sub_E01_cpml_2d_rz_tmz_H(ilo_f,ihi_f,klo_f,khi_f,il,iu,kl,ku, &
    Ha,Er,Ez,dt,dr,dz,mu,ahr,bhr,khr,ahz,bhz,khz,psi_ha_r,psi_ha_z)

    implicit none

    integer :: ilo_f,ihi_f,klo_f,khi_f,il,iu,kl,ku
    real :: Ha(ilo_f:ihi_f,klo_f:khi_f)
    real :: Er(ilo_f:ihi_f,klo_f:khi_f)
    real :: Ez(ilo_f:ihi_f,klo_f:khi_f)
    real :: dt,dr,dz,mu
    real :: ahr(ilo_f:ihi_f),bhr(ilo_f:ihi_f),khr(ilo_f:ihi_f)
    real :: ahz(klo_f:khi_f),bhz(klo_f:khi_f),khz(klo_f:khi_f)
    real :: psi_ha_r(ilo_f:ihi_f,klo_f:khi_f)
    real :: psi_ha_z(ilo_f:ihi_f,klo_f:khi_f)

    integer :: i,k
    real :: term_r,term_z

    do k = kl,ku
    do i = il,iu
        term_r = (Ez(i+1,k)-Ez(i,k))/dr
        term_z = (Er(i,k+1)-Er(i,k))/dz
        psi_ha_r(i,k) = bhr(i)*psi_ha_r(i,k)+ahr(i)*term_r
        psi_ha_z(i,k) = bhz(k)*psi_ha_z(i,k)+ahz(k)*term_z
        Ha(i,k) = Ha(i,k)+dt/mu*(term_r/khr(i)-term_z/khz(k)+ &
            psi_ha_r(i,k)-psi_ha_z(i,k))
    end do
    end do

end subroutine sub_E01_cpml_2d_rz_tmz_H
