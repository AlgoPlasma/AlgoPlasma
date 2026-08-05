!> @file sub_E02_cpml_3d_cylindrical_H.f90
!> @brief Updates cylindrical magnetic fields ``Hr``, ``Hphi``, and ``Hz``
!> with CPML terms.
!> @details This routine applies split-field CPML corrections to magnetic
!> updates on an ``r-phi-z`` grid. Axis closure follows the non-CPML
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
!> @param[in] Er: real 3D array, radial electric field.
!> @param[in] Ephi: real 3D array, azimuthal electric field.
!> @param[in] Ez: real 3D array, axial electric field.
!> @param[in,out] Hr: real 3D array, radial magnetic field.
!> @param[in,out] Hphi: real 3D array, azimuthal magnetic field.
!> @param[in,out] Hz: real 3D array, axial magnetic field.
!> @param[in] dt: real, time step.
!> @param[in] dr: real, radial grid spacing.
!> @param[in] dphi: real, azimuthal grid spacing.
!> @param[in] dz: real, axial grid spacing.
!> @param[in] mu: real, permeability.
!> @param[in] a_H_r_z: real 1D array, CPML ``a`` for ``z`` in ``Hr``.
!> @param[in] b_H_r_z: real 1D array, CPML ``b`` for ``z`` in ``Hr``.
!> @param[in] k_H_r_z: real 1D array, CPML ``k`` for ``z`` in ``Hr``.
!> @param[in] a_H_r_phi: real 1D array, CPML ``a`` for ``phi`` in ``Hr``.
!> @param[in] b_H_r_phi: real 1D array, CPML ``b`` for ``phi`` in ``Hr``.
!> @param[in] k_H_r_phi: real 1D array, CPML ``k`` for ``phi`` in ``Hr``.
!> @param[in] a_H_phi_r: real 1D array, CPML ``a`` for ``r`` in ``Hphi``.
!> @param[in] b_H_phi_r: real 1D array, CPML ``b`` for ``r`` in ``Hphi``.
!> @param[in] k_H_phi_r: real 1D array, CPML ``k`` for ``r`` in ``Hphi``.
!> @param[in] a_H_phi_z: real 1D array, CPML ``a`` for ``z`` in ``Hphi``.
!> @param[in] b_H_phi_z: real 1D array, CPML ``b`` for ``z`` in ``Hphi``.
!> @param[in] k_H_phi_z: real 1D array, CPML ``k`` for ``z`` in ``Hphi``.
!> @param[in] a_H_z_phi: real 1D array, CPML ``a`` for ``phi`` in ``Hz``.
!> @param[in] b_H_z_phi: real 1D array, CPML ``b`` for ``phi`` in ``Hz``.
!> @param[in] k_H_z_phi: real 1D array, CPML ``k`` for ``phi`` in ``Hz``.
!> @param[in] a_H_z_r: real 1D array, CPML ``a`` for ``r`` in ``Hz``.
!> @param[in] b_H_z_r: real 1D array, CPML ``b`` for ``r`` in ``Hz``.
!> @param[in] k_H_z_r: real 1D array, CPML ``k`` for ``r`` in ``Hz``.
!> @param[in,out] psi_H_r_z: real 3D array, CPML memory term for ``Hr``.
!> @param[in,out] psi_H_r_phi: real 3D array, CPML memory term for ``Hr``.
!> @param[in,out] psi_H_phi_r: real 3D array, CPML memory term for ``Hphi``.
!> @param[in,out] psi_H_phi_z: real 3D array, CPML memory term for ``Hphi``.
!> @param[in,out] psi_H_z_phi: real 3D array, CPML memory term for ``Hz``.
!> @param[in,out] psi_H_z_r: real 3D array, CPML memory term for ``Hz``.

subroutine sub_E02_cpml_3d_cylindrical_H(ilo_f,ihi_f,jlo_f,jhi_f,klo_f,khi_f, &
    il,iu,jl,ju,kl,ku,Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,mu,a_H_r_z, &
    b_H_r_z,k_H_r_z,a_H_r_phi,b_H_r_phi,k_H_r_phi,a_H_phi_r,b_H_phi_r,k_H_phi_r, &
    a_H_phi_z,b_H_phi_z,k_H_phi_z,a_H_z_phi,b_H_z_phi,k_H_z_phi,a_H_z_r,b_H_z_r,k_H_z_r, &
    psi_H_r_z,psi_H_r_phi,psi_H_phi_r,psi_H_phi_z,psi_H_z_phi,psi_H_z_r)

    implicit none

    integer :: ilo_f,ihi_f,jlo_f,jhi_f,klo_f,khi_f
    integer :: il,iu,jl,ju,kl,ku
    real :: Er(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Ephi(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Ez(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Hr(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Hphi(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Hz(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: dt,dr,dphi,dz,mu
    real :: a_H_r_z(klo_f:khi_f),b_H_r_z(klo_f:khi_f),k_H_r_z(klo_f:khi_f)
    real :: a_H_r_phi(jlo_f:jhi_f),b_H_r_phi(jlo_f:jhi_f),k_H_r_phi(jlo_f:jhi_f)
    real :: a_H_phi_r(ilo_f:ihi_f),b_H_phi_r(ilo_f:ihi_f),k_H_phi_r(ilo_f:ihi_f)
    real :: a_H_phi_z(klo_f:khi_f),b_H_phi_z(klo_f:khi_f),k_H_phi_z(klo_f:khi_f)
    real :: a_H_z_phi(jlo_f:jhi_f),b_H_z_phi(jlo_f:jhi_f),k_H_z_phi(jlo_f:jhi_f)
    real :: a_H_z_r(ilo_f:ihi_f),b_H_z_r(ilo_f:ihi_f),k_H_z_r(ilo_f:ihi_f)
    real :: psi_H_r_z(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_H_r_phi(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_H_phi_r(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_H_phi_z(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_H_z_phi(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: psi_H_z_r(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)

    integer :: i,j,k
    real :: ri,dEphi_dz,dEz_dphi,dEz_dr,dEr_dz,dEr_dphi
    real :: dEphi_dr,metric_Ephi_over_r

    do k = kl,ku
    do j = jl,ju
    do i = il,iu
        if (i==0) then
            Hr(i,j,k) = Hphi(i,j,k)
        else
            ri = real(i)*dr
            dEphi_dz = (Ephi(i,j,k+1)-Ephi(i,j,k))/dz
            dEz_dphi = (Ez(i,j+1,k)-Ez(i,j,k))/dphi
            psi_H_r_z(i,j,k) = b_H_r_z(k)*psi_H_r_z(i,j,k)+ &
                a_H_r_z(k)*dEphi_dz
            psi_H_r_phi(i,j,k) = b_H_r_phi(j)*psi_H_r_phi(i,j,k)+ &
                a_H_r_phi(j)*dEz_dphi
            Hr(i,j,k) = Hr(i,j,k) &
                        + dt/mu*( &
                        dEphi_dz/k_H_r_z(k) + psi_H_r_z(i,j,k) &
                        - (dEz_dphi/k_H_r_phi(j) + psi_H_r_phi(i,j,k))/ri &
                        )
        end if

        dEz_dr = (Ez(i+1,j,k)-Ez(i,j,k))/dr
        dEr_dz = (Er(i,j,k+1)-Er(i,j,k))/dz
        psi_H_phi_r(i,j,k) = b_H_phi_r(i)*psi_H_phi_r(i,j,k)+ &
            a_H_phi_r(i)*dEz_dr
        psi_H_phi_z(i,j,k) = b_H_phi_z(k)*psi_H_phi_z(i,j,k)+ &
            a_H_phi_z(k)*dEr_dz
        Hphi(i,j,k) = Hphi(i,j,k) &
                      + dt/mu*( &
                      dEz_dr/k_H_phi_r(i) + psi_H_phi_r(i,j,k) &
                      - dEr_dz/k_H_phi_z(k) - psi_H_phi_z(i,j,k) &
                      )

        ri = max((real(i)+0.5)*dr,0.5*dr)
        dEr_dphi = (Er(i,j+1,k)-Er(i,j,k))/dphi
        dEphi_dr = (Ephi(i+1,j,k)-Ephi(i,j,k))/dr
        metric_Ephi_over_r = 0.5*(Ephi(i+1,j,k)+Ephi(i,j,k))/ri
        psi_H_z_phi(i,j,k) = b_H_z_phi(j)*psi_H_z_phi(i,j,k)+ &
            a_H_z_phi(j)*dEr_dphi
        psi_H_z_r(i,j,k) = b_H_z_r(i)*psi_H_z_r(i,j,k)+a_H_z_r(i)*dEphi_dr
        Hz(i,j,k) = Hz(i,j,k) &
                    + dt/mu*( &
                    (dEr_dphi/k_H_z_phi(j) + psi_H_z_phi(i,j,k))/ri &
                    - dEphi_dr/k_H_z_r(i) - psi_H_z_r(i,j,k) - metric_Ephi_over_r &
                    )
    end do
    end do
    end do

    if (il==0) then
        do k = kl,ku
        do j = jl,ju
            Hr(0,j,k) = Hphi(0,j,k)
        end do
        end do
    end if

end subroutine sub_E02_cpml_3d_cylindrical_H
