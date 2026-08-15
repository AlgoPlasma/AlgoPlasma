!> @file sub_E02_cpml_3d_cylindrical_E.f90
!> @brief Updates cylindrical electric fields ``Er``, ``Ephi``, and ``Ez``
!> with CPML terms.
!> @details This routine applies split-field CPML corrections to electric
!> updates on an ``r-phi-z`` grid. Axis closures follow the non-CPML
!> cylindrical FDTD update at ``i=0``.
!> @author Zhe LIU (2026/04/26)
!
!> @param[in] ilo_f: integer, lower ``r`` index bound of field arrays.
!> @param[in] ihi_f: integer, upper ``r`` index bound of field arrays.
!> @param[in] jlo_f: integer, lower ``phi`` index bound of field arrays.
!> @param[in] jhi_f: integer, upper ``phi`` index bound of field arrays.
!> @param[in] klo_f: integer, lower ``z`` index bound of field arrays.
!> @param[in] khi_f: integer, upper ``z`` index bound of field arrays.
!> @param[in] il: integer, lower update ``r`` index.
!> @param[in] iu: integer, upper update ``r`` index.
!> @param[in] jl: integer, lower update ``phi`` index.
!> @param[in] ju: integer, upper update ``phi`` index.
!> @param[in] kl: integer, lower update ``z`` index.
!> @param[in] ku: integer, upper update ``z`` index.
!> @param[in,out] Er: real 3D array, radial electric field.
!> @param[in,out] Ephi: real 3D array, azimuthal electric field.
!> @param[in,out] Ez: real 3D array, axial electric field.
!> @param[in] Hr: real 3D array, radial magnetic field.
!> @param[in] Hphi: real 3D array, azimuthal magnetic field.
!> @param[in] Hz: real 3D array, axial magnetic field.
!> @param[in] dt: real, time step.
!> @param[in] dr: real, radial grid spacing.
!> @param[in] dphi: real, azimuthal grid spacing.
!> @param[in] dz: real, axial grid spacing.
!> @param[in] ep: real, permittivity.
!> @param[in] a_E_r_phi: real 1D array, CPML ``a`` for ``phi`` in ``Er``.
!> @param[in] b_E_r_phi: real 1D array, CPML ``b`` for ``phi`` in ``Er``.
!> @param[in] k_E_r_phi: real 1D array, CPML ``k`` for ``phi`` in ``Er``.
!> @param[in] a_E_r_z: real 1D array, CPML ``a`` for ``z`` in ``Er``.
!> @param[in] b_E_r_z: real 1D array, CPML ``b`` for ``z`` in ``Er``.
!> @param[in] k_E_r_z: real 1D array, CPML ``k`` for ``z`` in ``Er``.
!> @param[in] a_E_phi_z: real 1D array, CPML ``a`` for ``z`` in ``Ephi``.
!> @param[in] b_E_phi_z: real 1D array, CPML ``b`` for ``z`` in ``Ephi``.
!> @param[in] k_E_phi_z: real 1D array, CPML ``k`` for ``z`` in ``Ephi``.
!> @param[in] a_E_phi_r: real 1D array, CPML ``a`` for ``r`` in ``Ephi``.
!> @param[in] b_E_phi_r: real 1D array, CPML ``b`` for ``r`` in ``Ephi``.
!> @param[in] k_E_phi_r: real 1D array, CPML ``k`` for ``r`` in ``Ephi``.
!> @param[in] a_E_z_r: real 1D array, CPML ``a`` for ``r`` in ``Ez``.
!> @param[in] b_E_z_r: real 1D array, CPML ``b`` for ``r`` in ``Ez``.
!> @param[in] k_E_z_r: real 1D array, CPML ``k`` for ``r`` in ``Ez``.
!> @param[in] a_E_z_phi: real 1D array, CPML ``a`` for ``phi`` in ``Ez``.
!> @param[in] b_E_z_phi: real 1D array, CPML ``b`` for ``phi`` in ``Ez``.
!> @param[in] k_E_z_phi: real 1D array, CPML ``k`` for ``phi`` in ``Ez``.
!> @param[in,out] psi_E_r_phi: real 3D array, CPML memory term for ``Er``.
!> @param[in,out] psi_E_r_z: real 3D array, CPML memory term for ``Er``.
!> @param[in,out] psi_E_phi_z: real 3D array, CPML memory term for ``Ephi``.
!> @param[in,out] psi_E_phi_r: real 3D array, CPML memory term for ``Ephi``.
!> @param[in,out] psi_E_z_r: real 3D array, CPML memory term for ``Ez``.
!> @param[in,out] psi_E_z_phi: real 3D array, CPML memory term for ``Ez``.

subroutine sub_E02_cpml_3d_cylindrical_E(ilo_f,ihi_f,jlo_f,jhi_f,klo_f,khi_f, &
    il,iu,jl,ju,kl,ku,Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,ep,a_E_r_phi, &
    b_E_r_phi,k_E_r_phi,a_E_r_z,b_E_r_z,k_E_r_z,a_E_phi_z,b_E_phi_z,k_E_phi_z,a_E_phi_r, &
    b_E_phi_r,k_E_phi_r,a_E_z_r,b_E_z_r,k_E_z_r,a_E_z_phi,b_E_z_phi,k_E_z_phi, &
    psi_E_r_phi,psi_E_r_z,psi_E_phi_z,psi_E_phi_r,psi_E_z_r,psi_E_z_phi)

    implicit none

    integer :: ilo_f,ihi_f,jlo_f,jhi_f,klo_f,khi_f
    integer :: il,iu,jl,ju,kl,ku
    real :: Er(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Ephi(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Ez(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Hr(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Hphi(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Hz(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: dt,dr,dphi,dz,ep
    real :: a_E_r_phi(jlo_f:jhi_f),b_E_r_phi(jlo_f:jhi_f),k_E_r_phi(jlo_f:jhi_f)
    real :: a_E_r_z(klo_f:khi_f),b_E_r_z(klo_f:khi_f),k_E_r_z(klo_f:khi_f)
    real :: a_E_phi_z(klo_f:khi_f),b_E_phi_z(klo_f:khi_f),k_E_phi_z(klo_f:khi_f)
    real :: a_E_phi_r(ilo_f:ihi_f),b_E_phi_r(ilo_f:ihi_f),k_E_phi_r(ilo_f:ihi_f)
    real :: a_E_z_r(ilo_f:ihi_f),b_E_z_r(ilo_f:ihi_f),k_E_z_r(ilo_f:ihi_f)
    real :: a_E_z_phi(jlo_f:jhi_f),b_E_z_phi(jlo_f:jhi_f),k_E_z_phi(jlo_f:jhi_f)
    real :: psi_E_r_phi(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_E_r_z(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_E_phi_z(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_E_phi_r(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_E_z_r(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_E_z_phi(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)

    integer :: i,j,k,nphi
    real :: ri,dHz_dphi,dHphi_dz,dHr_dz,dHz_dr,dHphi_dr
    real :: metric_Hphi_over_r
    real :: dHr_dphi
    real :: axis_hphi_avg(klo_f:khi_f)

    axis_hphi_avg = 0.0
    if (il==0) then
        nphi = ju-jl+1
        do k = kl,ku
        do j = jl,ju
            axis_hphi_avg(k) = axis_hphi_avg(k)+Hphi(0,j,k)
        end do
            axis_hphi_avg(k) = axis_hphi_avg(k)/real(nphi)
        end do
    end if

    do k = kl,ku
    do j = jl,ju
    do i = il,iu
        ri = max((real(i)+0.5)*dr,0.5*dr)
        dHz_dphi = (Hz(i,j,k)-Hz(i,j-1,k))/dphi
        dHphi_dz = (Hphi(i,j,k)-Hphi(i,j,k-1))/dz
        psi_E_r_phi(i,j,k) = b_E_r_phi(j)*psi_E_r_phi(i,j,k)+ &
            a_E_r_phi(j)*dHz_dphi
        psi_E_r_z(i,j,k) = b_E_r_z(k)*psi_E_r_z(i,j,k)+a_E_r_z(k)*dHphi_dz
        Er(i,j,k) = Er(i,j,k) &
                    + dt/ep*( &
                    (dHz_dphi/k_E_r_phi(j) + psi_E_r_phi(i,j,k))/ri &
                    - dHphi_dz/k_E_r_z(k) - psi_E_r_z(i,j,k) &
                    )

        if (i==0) then
            Ephi(i,j,k) = Er(i,j,k)
        else
            dHr_dz = (Hr(i,j,k)-Hr(i,j,k-1))/dz
            dHz_dr = (Hz(i,j,k)-Hz(i-1,j,k))/dr
            psi_E_phi_z(i,j,k) = b_E_phi_z(k)*psi_E_phi_z(i,j,k)+ &
                a_E_phi_z(k)*dHr_dz
            psi_E_phi_r(i,j,k) = b_E_phi_r(i)*psi_E_phi_r(i,j,k)+ &
                a_E_phi_r(i)*dHz_dr
            Ephi(i,j,k) = Ephi(i,j,k) &
                            + dt/ep*( &
                            dHr_dz/k_E_phi_z(k) + psi_E_phi_z(i,j,k) &
                            - dHz_dr/k_E_phi_r(i) - psi_E_phi_r(i,j,k) &
                            )
        end if

        if (i==0) then
            Ez(i,j,k) = Ez(i,j,k)+4.0*dt/(ep*dr)*axis_hphi_avg(k)
        else
            ri = real(i)*dr
            dHphi_dr = (Hphi(i,j,k)-Hphi(i-1,j,k))/dr
            metric_Hphi_over_r = 0.5*(Hphi(i,j,k)+Hphi(i-1,j,k))/ri
            dHr_dphi = (Hr(i,j,k)-Hr(i,j-1,k))/dphi
            psi_E_z_r(i,j,k) = b_E_z_r(i)*psi_E_z_r(i,j,k)+ &
                a_E_z_r(i)*dHphi_dr
            psi_E_z_phi(i,j,k) = b_E_z_phi(j)*psi_E_z_phi(i,j,k)+ &
                a_E_z_phi(j)*dHr_dphi
            Ez(i,j,k) = Ez(i,j,k) &
                        + dt/ep*( &
                        dHphi_dr/k_E_z_r(i) + psi_E_z_r(i,j,k) + metric_Hphi_over_r &
                        - (dHr_dphi/k_E_z_phi(j) + psi_E_z_phi(i,j,k))/ri &
                        )
        end if
    end do
    end do
    end do

end subroutine sub_E02_cpml_3d_cylindrical_E
