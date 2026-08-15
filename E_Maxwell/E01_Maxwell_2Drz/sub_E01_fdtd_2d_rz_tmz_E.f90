!> @file sub_E01_fdtd_2d_rz_tmz_E.f90
!> @brief Updates the E01 TMz electric fields ``Er`` and ``Ez``.
!> @details This routine advances ``Er`` and ``Ez`` with Yee-staggered finite
!> differences. The ``Ez`` axis point uses the cylindrical closure formula at
!> ``i=0``.
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
!> @param[in] Ha: real 2D array, ``Hphi`` field at half step.
!> @param[in,out] Er: real 2D array, radial electric field.
!> @param[in,out] Ez: real 2D array, axial electric field.
!> @param[in] dt: real, time step.
!> @param[in] dr: real, radial grid spacing.
!> @param[in] dz: real, axial grid spacing.
!> @param[in] ep: real, permittivity.

subroutine sub_E01_fdtd_2d_rz_tmz_E(ilo_f,ihi_f,klo_f,khi_f,il,iu,kl,ku, &
    Ha,Er,Ez,dt,dr,dz,ep)

    implicit none

    integer :: ilo_f,ihi_f,klo_f,khi_f,il,iu,kl,ku
    real :: Ha(ilo_f:ihi_f,klo_f:khi_f)
    real :: Er(ilo_f:ihi_f,klo_f:khi_f)
    real :: Ez(ilo_f:ihi_f,klo_f:khi_f)
    real :: dt,dr,dz,ep

    integer :: i,k

    do k = kl,ku
    do i = il,iu
        Er(i,k) = Er(i,k)-dt/ep*(Ha(i,k)-Ha(i,k-1))/dz
    end do
    end do

    do k = kl,ku
    do i = il,iu
        if (i/=0) then
            Ez(i,k) = Ez(i,k)+dt/ep/(real(i)*dr)* &
                ((real(i)+0.5)*Ha(i,k)-(real(i)-0.5)*Ha(i-1,k))
        else
            Ez(i,k) = Ez(i,k)+4.0*dt/(ep*dr)*Ha(i,k)
        end if
    end do
    end do

end subroutine sub_E01_fdtd_2d_rz_tmz_E
