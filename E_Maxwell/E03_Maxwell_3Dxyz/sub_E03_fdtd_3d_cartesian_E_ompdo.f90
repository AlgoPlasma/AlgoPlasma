!> @file sub_E03_fdtd_3d_cartesian_E_ompdo.f90
!> @brief Updates Cartesian electric fields inside an existing OpenMP region.
!> @details This routine uses an orphaned OpenMP ``do`` region. It should be
!> called by all threads in an enclosing ``!$omp parallel`` region.

subroutine sub_E03_fdtd_3d_cartesian_E_ompdo(ilo_f,ihi_f,jlo_f,jhi_f,klo_f,khi_f, &
    il,iu,jl,ju,kl,ku,Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,ep)

    implicit none

    integer :: ilo_f,ihi_f,jlo_f,jhi_f,klo_f,khi_f
    integer :: il,iu,jl,ju,kl,ku
    real :: Ex(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Ey(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Ez(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Hx(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Hy(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: Hz(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)
    real :: dt,dx,dy,dz,ep

    integer :: i,j,k

    !$omp do collapse(2) schedule(static)
    do k = kl,ku
    do j = jl,ju
        !$omp simd
        do i = il,iu
            Ex(i,j,k) = Ex(i,j,k)+dt/ep*((Hz(i,j,k)-Hz(i,j-1,k))/dy- &
                (Hy(i,j,k)-Hy(i,j,k-1))/dz)
            Ey(i,j,k) = Ey(i,j,k)+dt/ep*((Hx(i,j,k)-Hx(i,j,k-1))/dz- &
                (Hz(i,j,k)-Hz(i-1,j,k))/dx)
            Ez(i,j,k) = Ez(i,j,k)+dt/ep*((Hy(i,j,k)-Hy(i-1,j,k))/dx- &
                (Hx(i,j,k)-Hx(i,j-1,k))/dy)
        end do
    end do
    end do
    !$omp end do

end subroutine sub_E03_fdtd_3d_cartesian_E_ompdo
