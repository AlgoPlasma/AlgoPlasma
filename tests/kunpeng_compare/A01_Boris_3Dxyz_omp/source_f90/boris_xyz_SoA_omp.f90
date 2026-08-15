#include "../../../../A_Pusher/A01_Boris_3Dxyz/mod_A01_Boris_3Dxyz.f90"
program boris_xyz_SoA_omp

    use omp_lib
    use mod_A01_Boris_3Dxyz
    implicit none

    ! -------------------------------------------------------------------------
    ! Basic parameters
    ! -------------------------------------------------------------------------
    integer :: np
    integer :: nt
    integer :: ip
    integer :: it
    integer :: nthreads

    real :: dt
    real :: qm
    real :: k

    ! -------------------------------------------------------------------------
    ! Timing
    ! -------------------------------------------------------------------------
    real :: t_total_start
    real :: t_total_end
    real :: t_comp_start
    real :: t_comp_end
    real :: t_comp

    ! -------------------------------------------------------------------------
    ! Particle arrays (SoA layout)
    ! -------------------------------------------------------------------------
    real, allocatable :: par_x(:)
    real, allocatable :: par_y(:)
    real, allocatable :: par_z(:)
    real, allocatable :: par_vx(:)
    real, allocatable :: par_vy(:)
    real, allocatable :: par_vz(:)

    ! -------------------------------------------------------------------------
    ! Global electromagnetic field in Cartesian components
    ! E_global = (Ex, Ey, Ez)
    ! B_global = (Bx, By, Bz)
    ! -------------------------------------------------------------------------
    real :: E_global(3)
    real :: B_global(3)

    ! -------------------------------------------------------------------------
    ! Single-particle temporary variables
    ! -------------------------------------------------------------------------
    real :: x(3)
    real :: v(3)
    real :: E(3)
    real :: B(3)

    ! -------------------------------------------------------------------------
    ! Set basic parameters
    ! -------------------------------------------------------------------------
    np = 10000000
    nt = 100000

    dt = 1.0e-8
    qm = -1.0
    k  = 0.5 * qm * dt

    ! -------------------------------------------------------------------------
    ! Set global fields
    ! -------------------------------------------------------------------------
    E_global(1) = 0.1
    E_global(2) = 0.0
    E_global(3) = 0.0

    B_global(1) = 0.0
    B_global(2) = 0.0
    B_global(3) = 0.1

    ! -------------------------------------------------------------------------
    ! Allocate particle arrays
    ! -------------------------------------------------------------------------
    allocate(par_x(np))
    allocate(par_y(np))
    allocate(par_z(np))
    allocate(par_vx(np))
    allocate(par_vy(np))
    allocate(par_vz(np))

    ! -------------------------------------------------------------------------
    ! Initialize particles
    ! -------------------------------------------------------------------------
    call random_seed()
    call random_number(par_x)
    call random_number(par_y)
    call random_number(par_z)

    call random_number(par_vx)
    call random_number(par_vy)
    call random_number(par_vz)

    ! -------------------------------------------------------------------------
    ! OpenMP and timing initialization
    ! -------------------------------------------------------------------------
    t_comp = 0.0

    nthreads = omp_get_max_threads()

    print *, '---------------------------------------------'
    print *, 'Program            = boris_xyz_SoA_omp'
    print *, 'OpenMP max threads = ', nthreads
    print *, 'np                 = ', np
    print *, 'nt                 = ', nt
    print *, 'dt                 = ', dt
    print *, 'qm                 = ', qm
    print *, 'E_global           = ', E_global
    print *, 'B_global           = ', B_global
    print *, '---------------------------------------------'

    t_total_start = omp_get_wtime()

    ! -------------------------------------------------------------------------
    ! Time integration
    ! -------------------------------------------------------------------------
    do it = 1, nt

        ! ---------------------------------------------------------------------
        ! Compute section timing
        ! ---------------------------------------------------------------------
        t_comp_start = omp_get_wtime()

        ! ---------------------------------------------------------------------
        ! Boris push + Cartesian position update
        ! ---------------------------------------------------------------------
        !$omp parallel do default(shared) &
        !$omp private(ip, x, v, E, B) &
        !$omp schedule(static)
        do ip = 1, np

            ! -----------------------------------------------------------------
            ! Load one particle
            ! -----------------------------------------------------------------
            x(1) = par_x(ip)
            x(2) = par_y(ip)
            x(3) = par_z(ip)

            v(1) = par_vx(ip)
            v(2) = par_vy(ip)
            v(3) = par_vz(ip)

            E = E_global
            B = B_global

            ! -----------------------------------------------------------------
            ! Boris velocity push in Cartesian coordinates
            ! -----------------------------------------------------------------
            call sub_A01_Boris_3Dxyz(v, E, B, k)

            ! -----------------------------------------------------------------
            ! Position update in Cartesian coordinates
            ! -----------------------------------------------------------------
            x(1) = x(1) + v(1) * dt
            x(2) = x(2) + v(2) * dt
            x(3) = x(3) + v(3) * dt

            ! -----------------------------------------------------------------
            ! Store back
            ! -----------------------------------------------------------------
            par_x(ip) = x(1)
            par_y(ip) = x(2)
            par_z(ip) = x(3)

            par_vx(ip) = v(1)
            par_vy(ip) = v(2)
            par_vz(ip) = v(3)

        end do
        !$omp end parallel do

        t_comp_end = omp_get_wtime()
        t_comp = t_comp + (t_comp_end - t_comp_start)

        if (mod(it, 100) == 0) then
            print '(f7.2,a,a,i10,a,f12.6)', 100.0 * real(it) / real(nt), '%        ', 'it = ', it, '        comp = ', t_comp
        end if

    end do

    t_total_end = omp_get_wtime()

    ! -------------------------------------------------------------------------
    ! Timing summary
    ! -------------------------------------------------------------------------
    print *, '============================================='
    print *, 'Total wall time   = ', t_total_end - t_total_start, ' s'
    print *, 'Compute wall time = ', t_comp, ' s'
    print *, '============================================='

    ! -------------------------------------------------------------------------
    ! Finalize
    ! -------------------------------------------------------------------------
    deallocate(par_x)
    deallocate(par_y)
    deallocate(par_z)
    deallocate(par_vx)
    deallocate(par_vy)
    deallocate(par_vz)

end program boris_xyz_SoA_omp

