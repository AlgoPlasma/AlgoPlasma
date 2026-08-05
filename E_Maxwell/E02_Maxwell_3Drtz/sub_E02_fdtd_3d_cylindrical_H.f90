!> @file sub_E02_fdtd_3d_cylindrical_H.f90
!> @brief Updates cylindrical magnetic fields ``Hr``, ``Hphi``, and ``Hz``.
!> @details This routine applies Yee-staggered cylindrical FDTD updates for
!> ``Hr``, ``Hphi``, and ``Hz`` on an ``r-phi-z`` grid. Axis closure is
!> enforced for ``Hr`` at ``i=0``.
!> @author Zhe LIU (2026/04/09)
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

subroutine sub_E02_fdtd_3d_cylindrical_H(ilo_f,ihi_f,jlo_f,jhi_f,klo_f,khi_f, &
    il,iu,jl,ju,kl,ku,Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,mu)

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

    integer :: i,j,k
    real :: ri,riph,rimh,term_r,term_phi,term_z

    do k = kl,ku
    do j = jl,ju
    do i = il,iu
        if (i==0) then
            Hr(i,j,k) = Hphi(i,j,k)
        else
            ri = real(i)*dr
            term_phi = (Ez(i,j+1,k)-Ez(i,j,k))/(ri*dphi)
            term_z = (Ephi(i,j,k+1)-Ephi(i,j,k))/dz
            Hr(i,j,k) = Hr(i,j,k)-dt/mu*(term_phi-term_z)
        end if
    end do
    end do
    end do

    do k = kl,ku
    do j = jl,ju
    do i = il,iu
        term_z = (Er(i,j,k+1)-Er(i,j,k))/dz
        term_r = (Ez(i+1,j,k)-Ez(i,j,k))/dr
        Hphi(i,j,k) = Hphi(i,j,k)-dt/mu*(term_z-term_r)
    end do
    end do
    end do

    do k = kl,ku
    do j = jl,ju
    do i = il,iu
        ri = max((real(i)+0.5)*dr,0.5*dr)
        riph = (real(i)+1.0)*dr
        rimh = real(i)*dr
        term_r = (riph*Ephi(i+1,j,k)-rimh*Ephi(i,j,k))/(ri*dr)
        term_phi = (Er(i,j+1,k)-Er(i,j,k))/(ri*dphi)
        Hz(i,j,k) = Hz(i,j,k)-dt/mu*(term_r-term_phi)
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

end subroutine sub_E02_fdtd_3d_cylindrical_H
