!> @file sub_E03_fdtd_3d_cartesian_H.f90
!> @brief Updates Cartesian magnetic fields ``Hx``, ``Hy``, and ``Hz``.
!> @details This routine advances the magnetic fields with standard
!> Yee-staggered FDTD curl operators in ``x-y-z`` coordinates.
!> @author Zhe LIU (2026/04/09)
!
!> @param[in] ilo_f: integer, lower ``x`` index bound of field arrays.
!> @param[in] ihi_f: integer, upper ``x`` index bound of field arrays.
!> @param[in] jlo_f: integer, lower ``y`` index bound of field arrays.
!> @param[in] jhi_f: integer, upper ``y`` index bound of field arrays.
!> @param[in] klo_f: integer, lower ``z`` index bound of field arrays.
!> @param[in] khi_f: integer, upper ``z`` index bound of field arrays.
!> @param[in] il: integer, lower update ``x`` index.
!> @param[in] iu: integer, upper update ``x`` index.
!> @param[in] jl: integer, lower update ``y`` index.
!> @param[in] ju: integer, upper update ``y`` index.
!> @param[in] kl: integer, lower update ``z`` index.
!> @param[in] ku: integer, upper update ``z`` index.
!> @param[in] Ex: real 3D array, ``x`` electric field component.
!> @param[in] Ey: real 3D array, ``y`` electric field component.
!> @param[in] Ez: real 3D array, ``z`` electric field component.
!> @param[in,out] Hx: real 3D array, ``x`` magnetic field component.
!> @param[in,out] Hy: real 3D array, ``y`` magnetic field component.
!> @param[in,out] Hz: real 3D array, ``z`` magnetic field component.
!> @param[in] dt: real, time step.
!> @param[in] dx: real, grid spacing in ``x``.
!> @param[in] dy: real, grid spacing in ``y``.
!> @param[in] dz: real, grid spacing in ``z``.
!> @param[in] mu: real, permeability.

subroutine sub_E03_fdtd_3d_cartesian_H(ilo_f,ihi_f,jlo_f,jhi_f,klo_f,khi_f, &
    il,iu,jl,ju,kl,ku,Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu)

    implicit none

    integer :: ilo_f,ihi_f,jlo_f,jhi_f,klo_f,khi_f
    integer :: il,iu,jl,ju,kl,ku
    real :: Ex(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Ey(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Ez(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Hx(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Hy(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Hz(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: dt,dx,dy,dz,mu

    integer :: i,j,k

    !$omp parallel do collapse(3) private(i,j,k) schedule(static)
    do k = kl,ku
    do j = jl,ju
    do i = il,iu
        Hx(i,j,k) = Hx(i,j,k)-dt/mu*((Ez(i,j+1,k)-Ez(i,j,k))/dy- &
            (Ey(i,j,k+1)-Ey(i,j,k))/dz)
        Hy(i,j,k) = Hy(i,j,k)-dt/mu*((Ex(i,j,k+1)-Ex(i,j,k))/dz- &
            (Ez(i+1,j,k)-Ez(i,j,k))/dx)
        Hz(i,j,k) = Hz(i,j,k)-dt/mu*((Ey(i+1,j,k)-Ey(i,j,k))/dx- &
            (Ex(i,j+1,k)-Ex(i,j,k))/dy)
    end do
    end do
    end do
    !$omp end parallel do

end subroutine sub_E03_fdtd_3d_cartesian_H
