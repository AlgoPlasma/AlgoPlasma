#include "../../../../B_Scatter/B01_scatter_3Dxyz/mod_B01_scatter_3Dxyz.f90"
#include "mod_manageProcedures.f90"

program main 

    use mod_B01_scatter_3Dxyz
    use mod_manageProcedures
    use omp_lib, only: omp_get_wtime

    implicit none

    integer, dimension(1:3) :: il, iu
    integer, dimension(1:13) :: thread_list
    integer, parameter :: nrepeat = 10
    real :: xp, yp, zp, w, vp
    integer :: d
    character(len=128) :: outfile_T
    real :: t_start, t_end
    double precision :: omp_t_start, omp_t_end
    double precision, dimension(1:13) :: speedup_list
    double precision, dimension(1:13) :: parallel_time_avg
    double precision, dimension(1:13) :: speedup_best
    double precision, dimension(1:13) :: speedup_worst
    double precision :: speedup_sum, parallel_time_sum, parallel_time_current
    integer :: np, it, ir, np_omp
    character(len=128) :: outfile
    real, allocatable, dimension(:,:) :: par
    real, allocatable, dimension(:,:) :: par_omp
    character(len=128) :: outfile_den, outfile_par

    !---------------------------------
    ! case 01: single particle center
    !---------------------------------
    il = (/1, 1, 1/)
    iu = (/12, 12, 12/)

    xp = 2.5
    yp = 3.5
    zp = 4.5
    w = 1.0

    outfile = 'output_case01.dat'

    print *, '------------------------------------------'
    print *, 'Case 01: single particle center test'
    print *, '------------------------------------------'
    call cpu_time(t_start)
    call sub_single(il, iu, xp, yp, zp, w, outfile)
    call cpu_time(t_end)
    print *, 'Case 01 elapsed time = ', t_end - t_start, ' seconds'
    print *
    !---------------------------------
    ! case 02: single particle no-center
    !---------------------------------
    il = (/1, 1, 1/)
    iu = (/12, 12, 12/)

    xp = 2.2
    yp = 3.3
    zp = 4.4
    w = 1.0

    outfile = 'output_case02.dat'

    print *, '------------------------------------------'
    print *, 'Case 02: single particle no-center test'
    print *, '------------------------------------------'
    call cpu_time(t_start)
    call sub_single(il, iu, xp, yp, zp, w, outfile)
    call cpu_time(t_end)
    print *, 'Case 02 elapsed time = ', t_end - t_start, ' seconds'
    print *
    !---------------------------------
    ! case 03: multi particle 
    !---------------------------------
    np = 3
    allocate(par(1:3,1:np))
    par = 0.0

    par(1,1) = 2.5
    par(2,1) = 3.5
    par(3,1) = 4.5

    par(1,2) = 2.2
    par(2,2) = 3.3
    par(3,2) = 4.4

    par(1,3) = 3.1
    par(2,3) = 2.7
    par(3,3) = 1.8

    outfile = 'output_case03.dat'
    print *, '------------------------------------------'
    print *, 'Case 03: multi-particle scatter test'
    print *, '------------------------------------------'
    call cpu_time(t_start)
    call sub_multi(il, iu, np, par, w, outfile)
    call cpu_time(t_end)
    print *, 'Case 03 elapsed time = ', t_end - t_start, ' seconds'
    print *

    deallocate(par)

    !---------------------------------
    ! Case 04: hollow H shape structure
    !---------------------------------
    outfile_den = 'output_case04_hollowH_den.dat'
    outfile_par = 'output_case04_hollowH_par.dat'
    print *, '------------------------------------------'
    print *, 'Case 04: hollow H shape structure'
    print *, '------------------------------------------'
    call cpu_time(t_start)
    call sub_many(il, iu, w, outfile_den, outfile_par)
    call cpu_time(t_end)
    print *, 'Case 04 elapsed time = ', t_end - t_start, ' seconds'
    print *


    !---------------------------------
    ! Case 05/06: OMP parallel benchmark
    !---------------------------------
    il = (/1, 1, 1/)
    iu = (/12, 12, 12/)
    np_omp = 100000
    thread_list = (/ 1, 2, 4, 6, 7, 8, 9, 10, 12, 14, 16, 32, 64 /)
    allocate(par_omp(1:3, 1:np_omp))
    call random_seed()
    do ir = 1, np_omp
        call random_number(par_omp(1,ir))
        call random_number(par_omp(2,ir))
        call random_number(par_omp(3,ir))
        par_omp(1,ir) = il(1) + par_omp(1,ir) * (iu(1) - il(1))
        par_omp(2,ir) = il(2) + par_omp(2,ir) * (iu(2) - il(2))
        par_omp(3,ir) = il(3) + par_omp(3,ir) * (iu(3) - il(3))
    end do
    print *, '------------------------------------------'
    print *, 'Case 05: OMP parallel correctness'
    print *, '------------------------------------------'
    do it = 1, size(thread_list)
        print *, 'nthread sweep = ', thread_list(it)
        omp_t_start = omp_get_wtime()
        call sub_omp_test(il, iu, np=np_omp, par=par_omp, &
            nthread=thread_list(it), speedup_out=speedup_list(it), &
            parallel_time_out=parallel_time_current, verbose=.true.)
        omp_t_end = omp_get_wtime()
        write(*,'(A,F10.4,A)') 'Case 05 total wall time = ', &
            (omp_t_end - omp_t_start) * 1.0d3, ' ms'
        print *, '------------------------------------------'
    end do
    print *, 'Case 05 speedup summary:'
    do it = 1, size(thread_list)
        write(*,'(A,I3,A,F8.3)') '  nthread = ', thread_list(it), &
            '  speedup = ', speedup_list(it)
    end do

    print *
    print *, '------------------------------------------'
    print *, 'Case 06: OMP repeated benchmark'
    print *, '------------------------------------------'
    do it = 1, size(thread_list)
        speedup_sum = 0.0d0
        parallel_time_sum = 0.0d0
        speedup_best(it) = 0.0d0
        speedup_worst(it) = huge(1.0d0)
        do ir = 1, nrepeat
            call sub_omp_test(il, iu, np=np_omp, par=par_omp, &
                nthread=thread_list(it), speedup_out=speedup_list(it), &
                parallel_time_out=parallel_time_current, verbose=.false.)
            speedup_sum = speedup_sum + speedup_list(it)
            parallel_time_sum = parallel_time_sum + parallel_time_current
            speedup_best(it) = max(speedup_best(it), speedup_list(it))
            speedup_worst(it) = min(speedup_worst(it), speedup_list(it))
        end do
        speedup_list(it) = speedup_sum / real(nrepeat, kind=8)
        parallel_time_avg(it) = parallel_time_sum / real(nrepeat, kind=8)
    end do
    print *, 'Case 06 speedup summary:'
    do it = 1, size(thread_list)
        write(*,'(A,I3,A,F8.3)') '  nthread = ', thread_list(it), &
            '  avg speedup   = ', speedup_list(it)
        write(*,'(A,F10.4,A)') '             avg parallel time = ', &
            parallel_time_avg(it) * 1.0d3, ' ms'
        write(*,'(A,F8.3)') '             best speedup  = ', speedup_best(it)
        write(*,'(A,F8.3)') '             worst speedup = ', speedup_worst(it)
    end do
    deallocate(par_omp)

    !---------------------------------
    ! Case 07: single particle _v, center position
    !---------------------------------
    il = (/1, 1, 1/)
    iu = (/12, 12, 12/)

    xp = 2.5;  yp = 3.5;  zp = 4.5
    vp = 2.0;  w = 1.0;   d = 4

    outfile = 'output_case07.dat'

    print *, '------------------------------------------'
    print *, 'Case 07: single particle _v (center, d=4, vp=2.0)'
    print *, '------------------------------------------'
    call cpu_time(t_start)
    call sub_single_v(il, iu, xp, yp, zp, vp, w, d, outfile)
    call cpu_time(t_end)
    print *, 'Case 07 elapsed time = ', t_end - t_start, ' seconds'
    print *

    !---------------------------------
    ! Case 08: single particle _v, off-center position
    !---------------------------------
    xp = 2.2;  yp = 3.3;  zp = 4.4
    vp = -1.5;  w = 1.0;  d = 5

    outfile = 'output_case08.dat'

    print *, '------------------------------------------'
    print *, 'Case 08: single particle _v (off-center, d=5, vp=-1.5)'
    print *, '------------------------------------------'
    call cpu_time(t_start)
    call sub_single_v(il, iu, xp, yp, zp, vp, w, d, outfile)
    call cpu_time(t_end)
    print *, 'Case 08 elapsed time = ', t_end - t_start, ' seconds'
    print *

    !---------------------------------
    ! Case 09: many particles _v, geometric pattern
    !---------------------------------
    w = 1.0;  d = 4

    outfile_den = 'output_case09_v_den.dat'
    outfile_par = 'output_case09_v_par.dat'

    print *, '------------------------------------------'
    print *, 'Case 09: many particles _v (box+H+cross, d=4)'
    print *, '------------------------------------------'
    call cpu_time(t_start)
    call sub_many_v(il, iu, w, d, outfile_den, outfile_par)
    call cpu_time(t_end)
    print *, 'Case 09 elapsed time = ', t_end - t_start, ' seconds'
    print *

    !---------------------------------
    ! Case 10: analytical unit tests for _T
    !---------------------------------
    d = 4

    print *, '------------------------------------------'
    print *, 'Case 10: analytical unit tests _T (d=4)'
    print *, '------------------------------------------'
    call cpu_time(t_start)
    call sub_single_T(il, iu, d)
    call cpu_time(t_end)
    print *, 'Case 10 elapsed time = ', t_end - t_start, ' seconds'
    print *

    !---------------------------------
    ! Case 11: spatial pattern test for _T
    !---------------------------------
    d = 4

    outfile_T   = 'output_case11_T.dat'
    outfile_par = 'output_case11_T_par.dat'

    print *, '------------------------------------------'
    print *, 'Case 11: spatial pattern _T (3-layer 5x5, d=4)'
    print *, '------------------------------------------'
    call cpu_time(t_start)
    call sub_many_T(il, iu, d, outfile_T, outfile_par)
    call cpu_time(t_end)
    print *, 'Case 11 elapsed time = ', t_end - t_start, ' seconds'
    print *

    end program main
