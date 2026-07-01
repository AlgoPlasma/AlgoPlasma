!> @file sub_E03_fdtd_3d_cartesian_H_ompdo.f90
!> @brief Updates Cartesian magnetic fields inside an existing OpenMP region.
!> @details This routine uses an orphaned OpenMP ``do`` region. It should be
!> called by all threads in an enclosing ``!$omp parallel`` region.

subroutine sub_E03_fdtd_3d_cartesian_H_ompdo(ilo_f,ihi_f,jlo_f,jhi_f,klo_f,khi_f, &
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

    !$omp do collapse(2) schedule(static)
    do k = kl,ku
    do j = jl,ju
        !$omp simd
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
    !$omp end do

end subroutine sub_E03_fdtd_3d_cartesian_H_ompdo
