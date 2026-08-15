#include "../../../../../E_Maxwell/E03_Maxwell_3Dxyz/mod_E03_fdtd_3d_cartesian.f90"

program e03_fdtd_3d_cartesian_benchmark

    use omp_lib
    use mod_E03_fdtd_3d_cartesian
    implicit none

    integer :: nx, ny, nz, nsteps, repeats
    integer :: ilo, ihi, jlo, jhi, klo, khi
    integer :: il, iu, jl, ju, kl, ku
    integer :: rep, n, threads, timing_unit
    real :: dx, dy, dz, dt, ep, mu
    real, allocatable :: Ex(:,:,:), Ey(:,:,:), Ez(:,:,:)
    real, allocatable :: Hx(:,:,:), Hy(:,:,:), Hz(:,:,:)
    real(kind=8) :: t0, t1, elapsed
    real(kind=8) :: t_sum, t_best, t_worst, t_avg
    real(kind=8) :: cells_per_step, total_component_updates, component_updates_per_s
    real(kind=8) :: checksum_e, checksum_h, total_energy

    call parse_int_arg(1, 96, nx)
    call parse_int_arg(2, 96, ny)
    call parse_int_arg(3, 96, nz)
    call parse_int_arg(4, 40, nsteps)
    call parse_int_arg(5, 3, repeats)

    if (nx < 6 .or. ny < 6 .or. nz < 6) then
        stop "nx, ny, nz must be at least 6"
    end if
    if (nsteps < 1) nsteps = 1
    if (repeats < 1) repeats = 1

    ilo = 0
    ihi = nx + 1
    jlo = 0
    jhi = ny + 1
    klo = 0
    khi = nz + 1

    il = 2
    iu = nx - 1
    jl = 2
    ju = ny - 1
    kl = 2
    ku = nz - 1

    ep = 1.0
    mu = 1.0
    dx = 1.0 / real(nx)
    dy = 1.0 / real(ny)
    dz = 1.0 / real(nz)
    dt = 0.35 / sqrt((1.0/dx)**2 + (1.0/dy)**2 + (1.0/dz)**2)

    allocate(Ex(ilo:ihi,jlo:jhi,klo:khi), Ey(ilo:ihi,jlo:jhi,klo:khi), Ez(ilo:ihi,jlo:jhi,klo:khi))
    allocate(Hx(ilo:ihi,jlo:jhi,klo:khi), Hy(ilo:ihi,jlo:jhi,klo:khi), Hz(ilo:ihi,jlo:jhi,klo:khi))

    threads = omp_get_max_threads()
    cells_per_step = real(iu - il + 1, kind=8) * real(ju - jl + 1, kind=8) * real(ku - kl + 1, kind=8)
    total_component_updates = 6.0_8 * cells_per_step * real(nsteps, kind=8)

    open(newunit=timing_unit, file="output/timings.csv", status="replace", action="write")
    write(timing_unit,'(A)') "repeat,elapsed_s,component_updates_per_s,checksum_e,checksum_h,total_energy"

    write(*,'(A)') "E03 FDTD 3D Cartesian benchmark"
    write(*,'(A,I0,A,I0,A,I0)') "grid=", nx, " x ", ny, " x ", nz
    write(*,'(A,I0,A,I0,A,I0)') "nsteps=", nsteps, ", repeats=", repeats, ", omp_max_threads=", threads
    write(*,'(A,ES14.6,A,ES14.6,A,ES14.6,A,ES14.6)') "dx=", dx, ", dy=", dy, ", dz=", dz, ", dt=", dt
#ifdef ALGOPLASMA_E03_USE_OMPDO
    write(*,'(A)') "kernel_mode=ompdo_outer_parallel"
#else
    write(*,'(A)') "kernel_mode=parallel_do"
#endif

    t_sum = 0.0_8
    t_best = huge(1.0_8)
    t_worst = -huge(1.0_8)
    checksum_e = 0.0_8
    checksum_h = 0.0_8
    total_energy = 0.0_8

    do rep = 1, repeats
        call initialize_fields(nx, ny, nz, Ex, Ey, Ez, Hx, Hy, Hz)

        t0 = omp_get_wtime()
#ifdef ALGOPLASMA_E03_USE_OMPDO
        !$omp parallel default(shared) private(n)
        do n = 1, nsteps
            call sub_E03_fdtd_3d_cartesian_H_ompdo(ilo,ihi,jlo,jhi,klo,khi, &
                il,iu,jl,ju,kl,ku,Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu)
            call sub_E03_fdtd_3d_cartesian_E_ompdo(ilo,ihi,jlo,jhi,klo,khi, &
                il,iu,jl,ju,kl,ku,Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,ep)
        end do
        !$omp end parallel
#else
        do n = 1, nsteps
            call sub_E03_fdtd_3d_cartesian_H(ilo,ihi,jlo,jhi,klo,khi, &
                il,iu,jl,ju,kl,ku,Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu)
            call sub_E03_fdtd_3d_cartesian_E(ilo,ihi,jlo,jhi,klo,khi, &
                il,iu,jl,ju,kl,ku,Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,ep)
        end do
#endif
        t1 = omp_get_wtime()

        elapsed = t1 - t0
        call compute_metrics(nx, ny, nz, Ex, Ey, Ez, Hx, Hy, Hz, ep, mu, checksum_e, checksum_h, total_energy)
        component_updates_per_s = total_component_updates / elapsed

        write(timing_unit,'(I0,",",ES24.16,",",ES24.16,",",ES24.16,",",ES24.16,",",ES24.16)') &
            rep, elapsed, component_updates_per_s, checksum_e, checksum_h, total_energy
        write(*,'(A,I0,A,ES12.4,A,ES12.4)') "repeat=", rep, ", elapsed_s=", elapsed, &
            ", component_updates_per_s=", component_updates_per_s

        t_sum = t_sum + elapsed
        t_best = min(t_best, elapsed)
        t_worst = max(t_worst, elapsed)
    end do

    close(timing_unit)

    t_avg = t_sum / real(repeats, kind=8)
    component_updates_per_s = total_component_updates / t_avg

    write(*,'(A)') "Final metrics"
    write(*,'(A,ES14.6)') "avg_s=", t_avg
    write(*,'(A,ES14.6)') "best_s=", t_best
    write(*,'(A,ES14.6)') "worst_s=", t_worst
    write(*,'(A,ES14.6)') "component_updates_per_s=", component_updates_per_s
    write(*,'(A,ES14.6)') "checksum_e=", checksum_e
    write(*,'(A,ES14.6)') "checksum_h=", checksum_h
    write(*,'(A,ES14.6)') "total_energy=", total_energy
    write(*,'("SUMMARY_CSV,",I0,",",I0,",",I0,",",I0,",",I0,",",I0,",",ES24.16,",",ES24.16,",",ES24.16,",",ES24.16,",",ES24.16,",",ES24.16,",",ES24.16,",",ES24.16,",",ES24.16)') &
        nx, ny, nz, nsteps, repeats, threads, cells_per_step, total_component_updates, &
        t_avg, t_best, t_worst, component_updates_per_s, checksum_e, checksum_h, total_energy

    deallocate(Ex, Ey, Ez, Hx, Hy, Hz)

contains

    subroutine parse_int_arg(pos, default_value, value)
        implicit none
        integer, intent(in) :: pos, default_value
        integer, intent(out) :: value
        character(len=64) :: arg
        integer :: stat

        value = default_value
        call get_command_argument(pos, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) then
            read(arg, *, iostat=stat) value
            if (stat /= 0) value = default_value
        end if
    end subroutine parse_int_arg

    subroutine initialize_fields(nx, ny, nz, Ex, Ey, Ez, Hx, Hy, Hz)
        implicit none
        integer, intent(in) :: nx, ny, nz
        real, intent(out) :: Ex(0:nx+1,0:ny+1,0:nz+1), Ey(0:nx+1,0:ny+1,0:nz+1), Ez(0:nx+1,0:ny+1,0:nz+1)
        real, intent(out) :: Hx(0:nx+1,0:ny+1,0:nz+1), Hy(0:nx+1,0:ny+1,0:nz+1), Hz(0:nx+1,0:ny+1,0:nz+1)
        integer :: i, j, k
        real :: x, y, z, pi

        pi = acos(-1.0)
        do k = 0, nz + 1
        do j = 0, ny + 1
        do i = 0, nx + 1
            x = real(i) / real(max(nx, 1))
            y = real(j) / real(max(ny, 1))
            z = real(k) / real(max(nz, 1))
            Ex(i,j,k) = sin(2.0*pi*x) + 0.125*cos(2.0*pi*(y + z))
            Ey(i,j,k) = cos(2.0*pi*y) + 0.125*sin(2.0*pi*(z + x))
            Ez(i,j,k) = sin(2.0*pi*z) + 0.125*cos(2.0*pi*(x + y))
            Hx(i,j,k) = cos(2.0*pi*(x + 0.25*y)) + 0.0625*sin(2.0*pi*z)
            Hy(i,j,k) = sin(2.0*pi*(y + 0.25*z)) + 0.0625*cos(2.0*pi*x)
            Hz(i,j,k) = cos(2.0*pi*(z + 0.25*x)) + 0.0625*sin(2.0*pi*y)
        end do
        end do
        end do
    end subroutine initialize_fields

    subroutine compute_metrics(nx, ny, nz, Ex, Ey, Ez, Hx, Hy, Hz, ep, mu, checksum_e, checksum_h, total_energy)
        implicit none
        integer, intent(in) :: nx, ny, nz
        real, intent(in) :: Ex(0:nx+1,0:ny+1,0:nz+1), Ey(0:nx+1,0:ny+1,0:nz+1), Ez(0:nx+1,0:ny+1,0:nz+1)
        real, intent(in) :: Hx(0:nx+1,0:ny+1,0:nz+1), Hy(0:nx+1,0:ny+1,0:nz+1), Hz(0:nx+1,0:ny+1,0:nz+1)
        real, intent(in) :: ep, mu
        real(kind=8), intent(out) :: checksum_e, checksum_h, total_energy
        integer :: i, j, k
        real(kind=8) :: weight

        checksum_e = 0.0_8
        checksum_h = 0.0_8
        total_energy = 0.0_8
        do k = 1, nz
        do j = 1, ny
        do i = 1, nx
            weight = 1.0_8 + 0.0001_8*real(i, kind=8) + 0.0002_8*real(j, kind=8) + 0.0003_8*real(k, kind=8)
            checksum_e = checksum_e + weight * real(abs(Ex(i,j,k)) + abs(Ey(i,j,k)) + abs(Ez(i,j,k)), kind=8)
            checksum_h = checksum_h + weight * real(abs(Hx(i,j,k)) + abs(Hy(i,j,k)) + abs(Hz(i,j,k)), kind=8)
            total_energy = total_energy + 0.5_8 * real( &
                ep*(Ex(i,j,k)**2 + Ey(i,j,k)**2 + Ez(i,j,k)**2) + &
                mu*(Hx(i,j,k)**2 + Hy(i,j,k)**2 + Hz(i,j,k)**2), kind=8)
        end do
        end do
        end do
    end subroutine compute_metrics

end program e03_fdtd_3d_cartesian_benchmark
