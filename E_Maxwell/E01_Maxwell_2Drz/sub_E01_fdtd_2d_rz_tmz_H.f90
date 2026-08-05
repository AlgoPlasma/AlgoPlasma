!> @file sub_E01_fdtd_2d_rz_tmz_H.f90
!> @brief Updates the E01 TMz magnetic field ``Ha`` (``Hphi``).
!> @details This routine advances ``Ha`` with the standard Yee curl term
!> from ``Ez`` and ``Er``.
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
!> @param[in,out] Ha: real 2D array, azimuthal magnetic field.
!> @param[in] Er: real 2D array, radial electric field.
!> @param[in] Ez: real 2D array, axial electric field.
!> @param[in] dt: real, time step.
!> @param[in] dr: real, radial grid spacing.
!> @param[in] dz: real, axial grid spacing.
!> @param[in] mu: real, permeability.

subroutine sub_E01_fdtd_2d_rz_tmz_H(ilo_f,ihi_f,klo_f,khi_f,il,iu,kl,ku, &
    Ha,Er,Ez,dt,dr,dz,mu)

    implicit none

    integer :: ilo_f,ihi_f,klo_f,khi_f,il,iu,kl,ku
    real :: Ha(ilo_f:ihi_f,klo_f:khi_f)
    real :: Er(ilo_f:ihi_f,klo_f:khi_f)
    real :: Ez(ilo_f:ihi_f,klo_f:khi_f)
    real :: dt,dr,dz,mu

    integer :: i,k

    do k = kl,ku
    do i = il,iu
        Ha(i,k) = Ha(i,k)+dt/mu*((Ez(i+1,k)-Ez(i,k))/dr- &
            (Er(i,k+1)-Er(i,k))/dz)
    end do
    end do

end subroutine sub_E01_fdtd_2d_rz_tmz_H
