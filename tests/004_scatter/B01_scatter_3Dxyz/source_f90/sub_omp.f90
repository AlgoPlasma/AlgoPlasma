subroutine sub_omp_test(il, iu, np, par, nthread, speedup_out, parallel_time_out, verbose)

    implicit none

    integer, dimension(1:3), intent(in) :: il, iu
    integer, intent(in) :: np, nthread
    real, dimension(1:3,1:np), intent(in) :: par
    double precision, intent(out) :: speedup_out
    double precision, intent(out) :: parallel_time_out
    logical, intent(in) :: verbose

    real, allocatable :: den(:,:,:), den_serial(:,:,:), den_parallel(:,:,:)
    real :: w, total, max_diff
    double precision :: t_serial_start, t_serial_end
    double precision :: t_parallel_start, t_parallel_end
    double precision :: serial_time, parallel_time, speedup
    integer :: p

    w = 2.0

    allocate(den(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    allocate(den_serial(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    allocate(den_parallel(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))

    if (verbose) then
        print *, '  np      = ', np
        print *, '  nthread = ', nthread
        print *, '  w       = ', w
        print *, '  conservation check:'
    end if

    ! --- Test 1: conservation ---
    den = 0.0
    call omp_set_num_threads(nthread)
    call sub_B01_scatter_3Dxyz(il, iu, den, np, par, w)
    total = sum(den)
    if (verbose) then
        print *, '    sum(den)   = ', total
        print *, '    expected   = ', real(np) * w
        print *, '    difference = ', abs(total - real(np)*w)
        if (abs(total - real(np)*w) < 1.0e-4) then
            print *, '    status     = PASS'
        else
            print *, '    status     = FAIL'
        end if
    end if

    ! --- Test 2: serial vs parallel consistency ---
    den_serial = 0.0
    call omp_set_num_threads(1)
    t_serial_start = omp_get_wtime()
    call sub_B01_scatter_3Dxyz(il, iu, den_serial, np, par, w)
    t_serial_end = omp_get_wtime()
    serial_time = t_serial_end - t_serial_start

    den_parallel = 0.0
    call omp_set_num_threads(nthread)
    t_parallel_start = omp_get_wtime()
    call sub_B01_scatter_3Dxyz(il, iu, den_parallel, np, par, w)
    t_parallel_end = omp_get_wtime()
    parallel_time = t_parallel_end - t_parallel_start

    max_diff = maxval(abs(den_serial - den_parallel))
    if (verbose) then
        print *, '  serial/parallel consistency:'
        print *, '    max|den_serial - den_parallel| = ', max_diff
        if (max_diff < 1.0e-10) then
            print *, '    status                        = PASS'
        else
            print *, '    status                        = NOTE: floating-point order differs'
        end if
    end if
    if (parallel_time > 0.0d0) then
        speedup = serial_time / parallel_time
    else
        speedup = 0.0d0
    end if
    speedup_out = speedup
    parallel_time_out = parallel_time
    if (verbose) then
        print *, '  performance comparison:'
        write(*,'(A,F10.4,A)') '    serial time   = ', serial_time * 1.0d3, ' ms'
        write(*,'(A,F10.4,A)') '    parallel time = ', parallel_time * 1.0d3, ' ms'
        write(*,'(A,F8.3)')    '    speedup       = ', speedup
    end if

    deallocate(den, den_serial, den_parallel)

end subroutine sub_omp_test
