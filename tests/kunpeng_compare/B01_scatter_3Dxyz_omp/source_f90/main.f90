#include "../../../../B_Scatter/B01_scatter_3Dxyz/mod_B01_scatter_3Dxyz.f90"
program scatter_omp_sweep

    use omp_lib
    use mod_B01_scatter_3Dxyz
    implicit none

    ! -------------------------------------------------------------------------
    ! Sweep axes
    ! -------------------------------------------------------------------------
    integer, parameter :: n_np      = 4
    integer, parameter :: n_thread  = 13
    integer, parameter :: nrepeat   = 10

    integer, parameter :: np_list(n_np) = &
        (/ 10000, 100000, 1000000, 10000000 /)
    integer, parameter :: thread_list(n_thread) = &
        (/ 1, 2, 4, 6, 7, 8, 9, 10, 12, 14, 16, 32, 64 /)

    real, parameter :: w = 2.0

    integer, dimension(1:3), parameter :: il = (/  1,  1,  1 /)
    integer, dimension(1:3), parameter :: iu = (/ 12, 12, 12 /)

    ! -------------------------------------------------------------------------
    ! Working storage
    ! -------------------------------------------------------------------------
    real, allocatable :: par(:, :)
    real, allocatable :: den(:, :, :)

    integer :: i_np, i_thread, i_rep, p, np_cur, nthread
    integer :: omp_max
    double precision :: t_start, t_end, t_run
    double precision :: t_sum, t_avg, t_best, t_worst

    ! -------------------------------------------------------------------------
    ! Header
    ! -------------------------------------------------------------------------
    omp_max = omp_get_max_threads()

    print '(A)', '===================================================='
    print '(A)', 'B01 Scatter OMP sweep benchmark'
    print '(A,*(I10,1X))',   'np_list     = ', np_list
    print '(A,*(I4,1X))',    'thread_list = ', thread_list
    print '(A,I0)',          'nrepeat     = ', nrepeat
    print '(A,3I4)',         'grid_il     = ', il
    print '(A,3I4)',         'grid_iu     = ', iu
    print '(A,F8.3)',        'w           = ', w
    print '(A,I0)',          'OMP max     = ', omp_max
    print '(A)', '===================================================='

    allocate(den(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))

    ! -------------------------------------------------------------------------
    ! Outer loop: particle count
    ! -------------------------------------------------------------------------
    do i_np = 1, n_np
        np_cur = np_list(i_np)
        allocate(par(1:3, 1:np_cur))

        call random_seed()
        call random_number(par)
        do p = 1, np_cur
            par(1, p) = real(il(1)) + par(1, p) * real(iu(1) - il(1))
            par(2, p) = real(il(2)) + par(2, p) * real(iu(2) - il(2))
            par(3, p) = real(il(3)) + par(3, p) * real(iu(3) - il(3))
        end do

        print '(A,I0,A)', '--- np = ', np_cur, ' ---'

        ! ---------------------------------------------------------------------
        ! Inner loop: thread count
        ! ---------------------------------------------------------------------
        do i_thread = 1, n_thread
            nthread = thread_list(i_thread)
            call omp_set_num_threads(nthread)

            t_sum   = 0.0d0
            t_best  =  huge(1.0d0)
            t_worst = -huge(1.0d0)

            do i_rep = 1, nrepeat
                ! Reset den outside the timed region so we measure pure scatter
                den = 0.0

                t_start = omp_get_wtime()
                call sub_B01_scatter_3Dxyz(il, iu, den, np_cur, par, w)
                t_end = omp_get_wtime()

                t_run  = t_end - t_start
                t_sum  = t_sum + t_run
                if (t_run < t_best)  t_best  = t_run
                if (t_run > t_worst) t_worst = t_run
            end do

            t_avg = t_sum / real(nrepeat, kind=8)

            write(*, '(A,I4,A,ES14.6,A,ES14.6,A,ES14.6)') &
                'nthread=', nthread, &
                '  avg_s=',   t_avg, &
                '  best_s=',  t_best, &
                '  worst_s=', t_worst
        end do

        deallocate(par)
    end do

    deallocate(den)

    print '(A)', '===================================================='
    print '(A)', 'Done.'

end program scatter_omp_sweep
