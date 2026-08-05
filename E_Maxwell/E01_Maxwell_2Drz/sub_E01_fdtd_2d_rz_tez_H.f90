!> @file sub_E01_fdtd_2d_rz_tez_H.f90
!> @brief Updates the E01 TEz magnetic fields ``Hr`` and ``Hz``.
!> @details This routine advances ``Hr`` and ``Hz`` from ``Ephi`` using
!> cylindrical Yee differences, including the ``(1/r) d(rEphi)/dr`` term.
!> @author Zhe LIU (2026/04/09)
!
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

subroutine sub_E01_fdtd_2d_rz_tez_H(ilo_f,ihi_f,klo_f,khi_f,il,iu,kl,ku, &
    Ephi,Hr,Hz,dt,dr,dz,mu)

    implicit none

    integer :: ilo_f,ihi_f,klo_f,khi_f,il,iu,kl,ku
    real :: Ephi(ilo_f:ihi_f,klo_f:khi_f)
    real :: Hr(ilo_f:ihi_f,klo_f:khi_f)
    real :: Hz(ilo_f:ihi_f,klo_f:khi_f)
    real :: dt,dr,dz,mu

    integer :: i,k
    real :: ri,riph,rimh,term_r,term_z

    do k = kl,ku
    do i = il,iu
        if (i==0) then
            Hr(i,k) = 0.0
        else
            term_z = (Ephi(i,k+1)-Ephi(i,k))/dz
            Hr(i,k) = Hr(i,k)+dt/mu*term_z
        end if
    end do
    end do

    do k = kl,ku
    do i = il,iu
        ri = max((real(i)+0.5)*dr,0.5*dr)
        riph = (real(i)+1.0)*dr
        rimh = real(i)*dr
        term_r = (riph*Ephi(i+1,k)-rimh*Ephi(i,k))/(ri*dr)
        Hz(i,k) = Hz(i,k)-dt/mu*term_r
    end do
    end do

end subroutine sub_E01_fdtd_2d_rz_tez_H
