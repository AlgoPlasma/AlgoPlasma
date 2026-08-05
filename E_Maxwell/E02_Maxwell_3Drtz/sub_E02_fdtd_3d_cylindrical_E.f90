!> @file sub_E02_fdtd_3d_cylindrical_E.f90
!> @brief Updates cylindrical electric fields ``Er``, ``Ephi``, and ``Ez``.
!> @details This routine applies Yee-staggered cylindrical FDTD updates for
!> ``Er``, ``Ephi``, and ``Ez`` on an ``r-phi-z`` grid. Axis closures are
!> handled explicitly for ``Ephi`` and ``Ez``.
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

subroutine sub_E02_fdtd_3d_cylindrical_E(ilo_f,ihi_f,jlo_f,jhi_f,klo_f,khi_f, &
    il,iu,jl,ju,kl,ku,Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,ep)

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

    integer :: i,j,k,nphi
    real :: ri,riph,rimh,term_r,term_phi,term_z
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
        term_phi = (Hz(i,j,k)-Hz(i,j-1,k))/(ri*dphi)
        term_z = (Hphi(i,j,k)-Hphi(i,j,k-1))/dz
        Er(i,j,k) = Er(i,j,k)+dt/ep*(term_phi-term_z)
    end do
    end do
    end do

    do k = kl,ku
    do j = jl,ju
    do i = il,iu
        if (i==0) then
            Ephi(i,j,k) = Er(i,j,k)
        else
            term_z = (Hr(i,j,k)-Hr(i,j,k-1))/dz
            term_r = (Hz(i,j,k)-Hz(i-1,j,k))/dr
            Ephi(i,j,k) = Ephi(i,j,k)+dt/ep*(term_z-term_r)
        end if
    end do
    end do
    end do

    do k = kl,ku
    do j = jl,ju
    do i = il,iu
        if (i==0) then
            Ez(i,j,k) = Ez(i,j,k)+4.0*dt/(ep*dr)*axis_hphi_avg(k)
        else
            ri = real(i)*dr
            riph = (real(i)+0.5)*dr
            rimh = (real(i)-0.5)*dr
            term_r = (riph*Hphi(i,j,k)-rimh*Hphi(i-1,j,k))/(ri*dr)
            term_phi = (Hr(i,j,k)-Hr(i,j-1,k))/(ri*dphi)
            Ez(i,j,k) = Ez(i,j,k)+dt/ep*(term_r-term_phi)
        end if
    end do
    end do
    end do

end subroutine sub_E02_fdtd_3d_cylindrical_E
