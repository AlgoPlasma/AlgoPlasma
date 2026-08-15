!> @file sub_B01_scatter_3Dxyz_T.f90
!> @author Zilong PENG (2026/04/16)
!> @brief Compute the variance of a particle quantity component
!>        onto a 3D grid (cell-averaged temperature-like field).
!>
!> @details This subroutine computes, for each grid cell, the variance
!>     of component ``d`` of the particle array ``par``, defined as
!>     ``T = <(par(d,p) - <par(d,p)>)^2>``, where the average is taken
!>     over all particles whose nearest grid point maps to that cell.
!>     The nearest grid point is determined by
!>     ``i = floor(par(1,p)) + 1``, and similarly for j and k.
!>     Two OpenMP-parallelized passes are made: the first accumulates
!>     the sum and count to compute the mean ``v1``; the second
!>     accumulates the squared deviations to form ``T``.
!>     The caller is responsible for any further scaling of ``T``
!>     (e.g., by particle mass or Boltzmann constant).

!> @param[in] il: integer (1:3), cell-center lower indices in x, y, z
!> @param[in] iu: integer (1:3), cell-center upper indices in x, y, z
!> @param[out] T: real (il(1):iu(1), il(2):iu(2), il(3):iu(3)),
!>     output variance array
!> @param[in] np: integer, maximum number of particles in the partition
!> @param[in] par: real (1:6, 1:np), particle phase-space array;
!>     ``par(1:3, p)`` are x, y, z positions and
!>     ``par(d, p)`` is the quantity whose variance is computed
!> @param[in] d: integer, index (1--6) selecting the component of
!>     ``par`` for the variance computation

subroutine sub_B01_scatter_3Dxyz_T(il,iu,T,np,par,d)

    implicit none

    integer :: il(1:3),iu(1:3)
    real    :: T(il(1):iu(1),il(2):iu(2),il(3):iu(3))
    integer :: np
    real    :: par(1:6,1:np)
    integer :: d

    integer :: p,i,j,k
    real,allocatable    :: v1(:,:,:)
    integer,allocatable :: n(:,:,:)

    allocate(v1(il(1):iu(1),il(2):iu(2),il(3):iu(3)))
    v1 = 0.0
    allocate(n(il(1):iu(1),il(2):iu(2),il(3):iu(3)))
    n = 0

    !$omp parallel default(firstprivate) reduction(+:v1) reduction(+:n)
    !$omp do
    do p = 1,np
        i = floor(par(1,p))+1
        j = floor(par(2,p))+1
        k = floor(par(3,p))+1
        v1(i,j,k) = v1(i,j,k) + par(d,p)
        n(i,j,k) = n(i,j,k) + 1
    end do
    !$omp end do
    !$omp end parallel

    !$omp parallel default(firstprivate) shared(n,v1)
    !$omp do
    do k = il(3),iu(3)
    do j = il(2),iu(2)
    do i = il(1),iu(1)
        if (n(i,j,k)/=0) v1(i,j,k)=v1(i,j,k)/real(n(i,j,k))
    end do
    end do
    end do
    !$omp end do
    !$omp end parallel

    T = 0.0
    !$omp parallel default(firstprivate) reduction(+:T)
    !$omp do
    do p = 1,np
        i = floor(par(1,p))+1
        j = floor(par(2,p))+1
        k = floor(par(3,p))+1
        T(i,j,k) = T(i,j,k) + (par(d,p)-v1(i,j,k))**2
    end do
    !$omp end do
    !$omp end parallel

    !$omp parallel default(firstprivate) shared(n,T)
    !$omp do
    do k = il(3),iu(3)
    do j = il(2),iu(2)
    do i = il(1),iu(1)
        if (n(i,j,k)/=0) T(i,j,k)=T(i,j,k)/real(n(i,j,k))
    end do
    end do
    end do
    !$omp end do
    !$omp end parallel

    deallocate(v1,n)

end subroutine sub_B01_scatter_3Dxyz_T