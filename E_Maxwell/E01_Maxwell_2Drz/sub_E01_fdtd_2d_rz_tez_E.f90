!> @file sub_E01_fdtd_2d_rz_tez_E.f90
!> @brief Updates the E01 TEz electric field ``Ephi``.
!> @details This routine advances ``Ephi`` from ``Hr`` and ``Hz``. The axis
!> point ``i=0`` is constrained by the cylindrical closure.
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
!> @param[in,out] Ephi: real 2D array, azimuthal electric field.
!> @param[in] Hr: real 2D array, radial magnetic field.
!> @param[in] Hz: real 2D array, axial magnetic field.
!> @param[in] dt: real, time step.
!> @param[in] dr: real, radial grid spacing.
!> @param[in] dz: real, axial grid spacing.
!> @param[in] ep: real, permittivity.

subroutine sub_E01_fdtd_2d_rz_tez_E(ilo_f,ihi_f,klo_f,khi_f,il,iu,kl,ku, &
    Ephi,Hr,Hz,dt,dr,dz,ep)

    implicit none

    integer :: ilo_f,ihi_f,klo_f,khi_f,il,iu,kl,ku
    real :: Ephi(ilo_f:ihi_f,klo_f:khi_f)
    real :: Hr(ilo_f:ihi_f,klo_f:khi_f)
    real :: Hz(ilo_f:ihi_f,klo_f:khi_f)
    real :: dt,dr,dz,ep

    integer :: i,k
    real :: term_r,term_z

    do k = kl,ku
    do i = il,iu
        if (i==0) then
            Ephi(i,k) = 0.0
        else
            term_z = (Hr(i,k)-Hr(i,k-1))/dz
            term_r = (Hz(i,k)-Hz(i-1,k))/dr
            Ephi(i,k) = Ephi(i,k)+dt/ep*(term_z-term_r)
        end if
    end do
    end do

end subroutine sub_E01_fdtd_2d_rz_tez_E
