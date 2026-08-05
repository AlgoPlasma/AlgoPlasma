!> @brief Updates the E01 TEz electric field ``Ephi`` with CPML terms.
!> @details This routine applies split-field CPML corrections to ``Ephi``.
!> It has no explicit ``i=0`` axis-closure branch; callers must provide the
!> neighboring cells touched by the finite differences.
!> @author Zhe LIU (2026/05/22)

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
!> @param[in] aephi_r: real 1D array, CPML ``a`` for ``r`` in ``Ephi``.
!> @param[in] bephi_r: real 1D array, CPML ``b`` for ``r`` in ``Ephi``.
!> @param[in] kephi_r: real 1D array, CPML ``k`` for ``r`` in ``Ephi``.
!> @param[in] aephi_z: real 1D array, CPML ``a`` for ``z`` in ``Ephi``.
!> @param[in] bephi_z: real 1D array, CPML ``b`` for ``z`` in ``Ephi``.
!> @param[in] kephi_z: real 1D array, CPML ``k`` for ``z`` in ``Ephi``.
!> @param[in,out] psi_ephi_r: real 2D array, CPML memory term in ``r``.
!> @param[in,out] psi_ephi_z: real 2D array, CPML memory term in ``z``.

subroutine sub_E01_cpml_2d_rz_tez_E(ilo_f,ihi_f,klo_f,khi_f,il,iu,kl,ku, &
    Ephi,Hr,Hz,dt,dr,dz,ep,aephi_r,bephi_r,kephi_r,aephi_z,bephi_z, &
    kephi_z,psi_ephi_r,psi_ephi_z)

    implicit none

    integer :: ilo_f,ihi_f,klo_f,khi_f,il,iu,kl,ku
    real :: Ephi(ilo_f:ihi_f,klo_f:khi_f)
    real :: Hr(ilo_f:ihi_f,klo_f:khi_f)
    real :: Hz(ilo_f:ihi_f,klo_f:khi_f)
    real :: dt,dr,dz,ep
    real :: aephi_r(ilo_f:ihi_f),bephi_r(ilo_f:ihi_f),kephi_r(ilo_f:ihi_f)
    real :: aephi_z(klo_f:khi_f),bephi_z(klo_f:khi_f),kephi_z(klo_f:khi_f)
    real :: psi_ephi_r(ilo_f:ihi_f,klo_f:khi_f)
    real :: psi_ephi_z(ilo_f:ihi_f,klo_f:khi_f)

    integer :: i,k
    real :: term_r,term_z

    do k = kl,ku
    do i = il,iu
        term_z = (Hr(i,k)-Hr(i,k-1))/dz
        term_r = (Hz(i,k)-Hz(i-1,k))/dr
        psi_ephi_z(i,k) = bephi_z(k)*psi_ephi_z(i,k)+aephi_z(k)*term_z
        psi_ephi_r(i,k) = bephi_r(i)*psi_ephi_r(i,k)+aephi_r(i)*term_r
        Ephi(i,k) = Ephi(i,k)+dt/ep*(term_z/kephi_z(k)- &
            term_r/kephi_r(i)+psi_ephi_z(i,k)-psi_ephi_r(i,k))
    end do
    end do

end subroutine sub_E01_cpml_2d_rz_tez_E
