!> @brief Updates the E01 TEz magnetic fields ``Hr`` and ``Hz`` with CPML terms.
!> @details This routine applies split-field CPML corrections to ``Hr`` and
!> ``Hz`` in cylindrical ``r-z`` coordinates.
!> @author Zhe LIU (2026/05/22)

!> @param[in] ilo_f: integer, lower ``r`` index bound of field arrays.
!> @param[in] ihi_f: integer, upper ``r`` index bound of field arrays.
!> @param[in] klo_f: integer, lower ``z`` index bound of field arrays.
!> @param[in] khi_f: integer, upper ``z`` index bound of field arrays.
!> @param[in] il: integer, lower update ``r`` index.
!> @param[in] iu: integer, upper update ``r`` index.
!> @param[in] kl: integer, lower update ``z`` index.
!> @param[in] ku: integer, upper update ``z`` index.
!> @param[in] Ephi: real 2D array, azimuthal electric field.
!> @param[in,out] Hr: real 2D array, radial magnetic field.
!> @param[in,out] Hz: real 2D array, axial magnetic field.
!> @param[in] dt: real, time step.
!> @param[in] dr: real, radial grid spacing.
!> @param[in] dz: real, axial grid spacing.
!> @param[in] mu: real, permeability.
!> @param[in] ahr_z: real 1D array, CPML ``a`` for ``z`` in ``Hr``.
!> @param[in] bhr_z: real 1D array, CPML ``b`` for ``z`` in ``Hr``.
!> @param[in] khr_z: real 1D array, CPML ``k`` for ``z`` in ``Hr``.
!> @param[in] ahz_r: real 1D array, CPML ``a`` for ``r`` in ``Hz``.
!> @param[in] bhz_r: real 1D array, CPML ``b`` for ``r`` in ``Hz``.
!> @param[in] khz_r: real 1D array, CPML ``k`` for ``r`` in ``Hz``.
!> @param[in,out] psi_hr_z: real 2D array, CPML memory term for ``Hr``.
!> @param[in,out] psi_hz_r: real 2D array, CPML memory term for ``Hz``.

subroutine sub_E01_cpml_2d_rz_tez_H(ilo_f,ihi_f,klo_f,khi_f,il,iu,kl,ku, &
    Ephi,Hr,Hz,dt,dr,dz,mu,ahr_z,bhr_z,khr_z,ahz_r,bhz_r,khz_r,psi_hr_z, &
    psi_hz_r)

    implicit none

    integer :: ilo_f,ihi_f,klo_f,khi_f,il,iu,kl,ku
    real :: Ephi(ilo_f:ihi_f,klo_f:khi_f)
    real :: Hr(ilo_f:ihi_f,klo_f:khi_f)
    real :: Hz(ilo_f:ihi_f,klo_f:khi_f)
    real :: dt,dr,dz,mu
    real :: ahr_z(klo_f:khi_f),bhr_z(klo_f:khi_f),khr_z(klo_f:khi_f)
    real :: ahz_r(ilo_f:ihi_f),bhz_r(ilo_f:ihi_f),khz_r(ilo_f:ihi_f)
    real :: psi_hr_z(ilo_f:ihi_f,klo_f:khi_f)
    real :: psi_hz_r(ilo_f:ihi_f,klo_f:khi_f)

    integer :: i,k
    real :: ri
    real :: term_z
    real :: dEphi_dr, metric_r, term_r_cpml

    ! ------------------------------------------------------------
    ! Hr update:
    ! Hr = Hr + dt/mu * dEphi/dz
    !
    ! CPML acts on the z derivative.
    ! ------------------------------------------------------------
    do k = kl,ku
    do i = il,iu

        term_z = (Ephi(i,k+1)-Ephi(i,k))/dz

        psi_hr_z(i,k) = bhr_z(k)*psi_hr_z(i,k) + ahr_z(k)*term_z

        Hr(i,k) = Hr(i,k) + dt/mu*(term_z/khr_z(k) + psi_hr_z(i,k))

    end do
    end do


    ! ------------------------------------------------------------
    ! Hz update:
    !
    ! Original cylindrical operator:
    !
    !   (1/r) d(r Ephi)/dr
    !
    ! is written as:
    !
    !   dEphi/dr + Ephi/r
    !
    ! CPML should act on dEphi/dr only.
    ! The metric term Ephi/r should NOT enter psi_hz_r.
    ! ------------------------------------------------------------
    do k = kl,ku
    do i = il,iu

        ri = max((real(i)+0.5)*dr,0.5*dr)

        dEphi_dr = (Ephi(i+1,k)-Ephi(i,k))/dr

        ! This metric term is equivalent to Ephi/r at the H_z location.
        ! It is kept outside the CPML memory variable.
        metric_r = 0.5*(Ephi(i+1,k)+Ephi(i,k))/ri

        psi_hz_r(i,k) = bhz_r(i)*psi_hz_r(i,k) + ahz_r(i)*dEphi_dr

        term_r_cpml = dEphi_dr/khz_r(i) + psi_hz_r(i,k) + metric_r

        Hz(i,k) = Hz(i,k) - dt/mu*term_r_cpml

    end do
    end do

end subroutine sub_E01_cpml_2d_rz_tez_H
