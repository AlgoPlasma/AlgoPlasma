program main

    use mpi
    use mod_D01_hypre_3Dxyz_bc
    implicit none

    ! mpi_i: The ith MPI rank.
    ! mpi_n: The MPI size.
    integer :: ierr, mpi_i, mpi_n

    ! Local, global lower and upper indices.
    integer, dimension(1:3) :: il, iu, il0, iu0

    ! Boundary condition flag in x,z small and big.
    ! 0: inner.
    ! 1: Dirichlet.
    ! 2: Neumann.
    ! y is set to be periodic.
    integer :: bc(1:4)

    ! Potential and charge density array.
    real, dimension(:), allocatable :: phi1d
    real, dimension(:), allocatable :: rho1d

    integer :: n, n_global
    integer :: i, j, k, l
    real :: tolerance
    real :: xc, zc, sigma

    ! Timing variables.
    real :: t_total0, t_total1
    real :: t0, t1
    real :: t_init_rho
    real :: t_hypre
    real :: t_gather_write
    real :: t_total
    real :: t_hypre_min, t_hypre_max, t_hypre_sum, t_hypre_avg

    ! Diagnostics.
    real :: rho_l2_local, rho_l2_global
    real :: phi_l2_local, phi_l2_global
    real :: phi_absmax_local, phi_absmax_global
    real :: phi_min_local, phi_min_global
    real :: phi_max_local, phi_max_global

    character(len=512) :: hypre_dir
    integer :: env_len, env_status

    call mpi_init(ierr)
    call mpi_comm_rank(mpi_comm_world, mpi_i, ierr)
    call mpi_comm_size(mpi_comm_world, mpi_n, ierr)

    call mpi_barrier(mpi_comm_world, ierr)
    t_total0 = mpi_wtime()

    if (mpi_n /= 4) then
        if (mpi_i == 0) then
            write(*,*) 'ERROR: this test is intended for 4 MPI ranks only.'
        end if
        call mpi_finalize(ierr)
        stop
    end if

    if (mpi_i == 0) then
        il(1:3) = (/ 9, 1, 1/)
        iu(1:3) = (/24, 8,16/)
        bc(1:4) = (/2,2,1,0/)
    else if (mpi_i == 1) then
        il(1:3) = (/ 1, 1,17/)
        iu(1:3) = (/ 8, 8,32/)
        bc(1:4) = (/1,0,1,1/)
    else if (mpi_i == 2) then
        il(1:3) = (/ 9, 1,17/)
        iu(1:3) = (/24, 8,32/)
        bc(1:4) = (/0,0,0,1/)
    else if (mpi_i == 3) then
        il(1:3) = (/25, 1,17/)
        iu(1:3) = (/32, 8,32/)
        bc(1:4) = (/0,1,1,1/)
    end if

    il0(1:3) = (/ 1, 1, 1/)
    iu0(1:3) = (/32, 8,32/)

    n = (iu(1)-il(1)+1) * (iu(2)-il(2)+1) * (iu(3)-il(3)+1)

    call mpi_allreduce(n, n_global, 1, MPI_INTEGER, MPI_SUM, mpi_comm_world, ierr)

    allocate(phi1d(1:n))
    allocate(rho1d(1:n))

    phi1d = 0.0
    rho1d = 0.0

    ! ----------------------------
    ! Initialize rho.
    ! ----------------------------
    call mpi_barrier(mpi_comm_world, ierr)
    t0 = mpi_wtime()

    if (mpi_i == 0) then
        l = 1
        do k = il(3), iu(3)
        do j = il(2), iu(2)
        do i = il(1), iu(1)
            if (k == il(3)) rho1d(l) = 1.0
            l = l + 1
        end do
        end do
        end do
    end if

!    xc = 16.5
!    zc = 16.5
!    sigma = 4.0
!
!    l = 1
!    do k = il(3), iu(3)
!    do j = il(2), iu(2)
!    do i = il(1), iu(1)
!        rho1d(l) = exp(-((real(i)-xc)**2 + (real(k)-zc)**2)/(2.0*sigma**2))
!        l = l + 1
!    end do
!    end do
!    end do

    call mpi_barrier(mpi_comm_world, ierr)
    t1 = mpi_wtime()
    t_init_rho = t1 - t0

    tolerance = 1.0e-6

    ! ----------------------------
    ! HYPRE solve.
    ! ----------------------------
    call mpi_barrier(mpi_comm_world, ierr)
    t0 = mpi_wtime()

    call sub_D01_hypre_3Dxyz_interface(n, phi1d, rho1d, il, iu, il0, iu0, tolerance, bc)

    call mpi_barrier(mpi_comm_world, ierr)
    t1 = mpi_wtime()
    t_hypre = t1 - t0

    call mpi_reduce(t_hypre, t_hypre_min, 1, MPI_DOUBLE_PRECISION, MPI_MIN, 0, mpi_comm_world, ierr)
    call mpi_reduce(t_hypre, t_hypre_max, 1, MPI_DOUBLE_PRECISION, MPI_MAX, 0, mpi_comm_world, ierr)
    call mpi_reduce(t_hypre, t_hypre_sum, 1, MPI_DOUBLE_PRECISION, MPI_SUM, 0, mpi_comm_world, ierr)

    if (mpi_i == 0) then
        t_hypre_avg = t_hypre_sum / real(mpi_n)
    end if

    ! ----------------------------
    ! Norm diagnostics.
    ! ----------------------------
    rho_l2_local = sum(rho1d * rho1d)
    phi_l2_local = sum(phi1d * phi1d)

    if (n > 0) then
        phi_absmax_local = maxval(abs(phi1d))
        phi_min_local = minval(phi1d)
        phi_max_local = maxval(phi1d)
    else
        phi_absmax_local = 0.0
        phi_min_local = 0.0
        phi_max_local = 0.0
    end if

    call mpi_reduce(rho_l2_local, rho_l2_global, 1, MPI_DOUBLE_PRECISION, MPI_SUM, 0, mpi_comm_world, ierr)
    call mpi_reduce(phi_l2_local, phi_l2_global, 1, MPI_DOUBLE_PRECISION, MPI_SUM, 0, mpi_comm_world, ierr)
    call mpi_reduce(phi_absmax_local, phi_absmax_global, 1, MPI_DOUBLE_PRECISION, MPI_MAX, 0, mpi_comm_world, ierr)
    call mpi_reduce(phi_min_local, phi_min_global, 1, MPI_DOUBLE_PRECISION, MPI_MIN, 0, mpi_comm_world, ierr)
    call mpi_reduce(phi_max_local, phi_max_global, 1, MPI_DOUBLE_PRECISION, MPI_MAX, 0, mpi_comm_world, ierr)

    if (mpi_i == 0) then
        rho_l2_global = sqrt(rho_l2_global)
        phi_l2_global = sqrt(phi_l2_global)
    end if

    ! ----------------------------
    ! Gather phi and write phi.dat.
    ! ----------------------------
    call mpi_barrier(mpi_comm_world, ierr)
    t0 = mpi_wtime()

    block
        real, dimension(:,:,:), allocatable :: phi0, phi
        integer :: ni, nj, nk

        allocate(phi (il0(1):iu0(1), il0(2):iu0(2), il0(3):iu0(3)))
        allocate(phi0(il0(1):iu0(1), il0(2):iu0(2), il0(3):iu0(3)))

        phi  = 0.0
        phi0 = 0.0

        l = 1
        do k = il(3), iu(3)
        do j = il(2), iu(2)
        do i = il(1), iu(1)
            phi(i,j,k) = phi1d(l)
            l = l + 1
        end do
        end do
        end do

        ni = iu0(1) - il0(1) + 1
        nj = iu0(2) - il0(2) + 1
        nk = iu0(3) - il0(3) + 1

        call mpi_allreduce(phi, phi0, ni*nj*nk, MPI_DOUBLE_PRECISION, MPI_SUM, mpi_comm_world, ierr)

        if (mpi_i == 0) then
            open(unit=1000, file='phi.dat', status='replace')
            do k = il0(3), iu0(3)
            do j = il0(2), iu0(2)
            do i = il0(1), iu0(1)
                write(1000,*) phi0(i,j,k)
            end do
            end do
            end do
            close(1000)
        end if

        deallocate(phi, phi0)
    end block

    call mpi_barrier(mpi_comm_world, ierr)
    t1 = mpi_wtime()
    t_gather_write = t1 - t0

    ! ----------------------------
    ! Total time and benchmark output.
    ! ----------------------------
    call mpi_barrier(mpi_comm_world, ierr)
    t_total1 = mpi_wtime()
    t_total = t_total1 - t_total0

    if (mpi_i == 0) then
        call get_environment_variable('HYPRE_DIR', hypre_dir, length=env_len, status=env_status)

        if (env_status /= 0) then
            hypre_dir = 'HYPRE_DIR is not set'
            env_len = len_trim(hypre_dir)
        end if

        write(*,*)
        write(*,*) '================ Poisson HYPRE Benchmark ================'
        write(*,'(A,I0)')       '[RESULT] mpi_size              = ', mpi_n
        write(*,'(A,I0)')       '[RESULT] n_global              = ', n_global
        write(*,'(A,3(I0,1X))') '[RESULT] global_grid           = ', &
                                 iu0(1)-il0(1)+1, iu0(2)-il0(2)+1, iu0(3)-il0(3)+1
        write(*,'(A,ES16.8)')   '[RESULT] tolerance             = ', tolerance
        write(*,'(A,A)')        '[RESULT] HYPRE_DIR             = ', trim(hypre_dir(1:env_len))

        write(*,'(A,ES16.8,A)') '[TIME] rho_init_time           = ', t_init_rho, ' s'
        write(*,'(A,ES16.8,A)') '[TIME] hypre_time_min          = ', t_hypre_min, ' s'
        write(*,'(A,ES16.8,A)') '[TIME] hypre_time_avg          = ', t_hypre_avg, ' s'
        write(*,'(A,ES16.8,A)') '[TIME] hypre_time_max          = ', t_hypre_max, ' s'
        write(*,'(A,ES16.8,A)') '[TIME] gather_write_time       = ', t_gather_write, ' s'
        write(*,'(A,ES16.8,A)') '[TIME] total_time              = ', t_total, ' s'

        write(*,'(A,ES16.8)')   '[NORM] rho_l2                 = ', rho_l2_global
        write(*,'(A,ES16.8)')   '[NORM] phi_l2                 = ', phi_l2_global
        write(*,'(A,ES16.8)')   '[NORM] phi_absmax             = ', phi_absmax_global
        write(*,'(A,ES16.8)')   '[NORM] phi_min                = ', phi_min_global
        write(*,'(A,ES16.8)')   '[NORM] phi_max                = ', phi_max_global
        write(*,*) '=========================================================='
        write(*,*)
    end if

    deallocate(phi1d, rho1d)

    call mpi_finalize(ierr)

end program main
