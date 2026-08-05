program benchmark_F_IO_mpi

    use mpi
    use mod_F01_par_load
    use mod_F02_par_output

    implicit none

    integer :: ierr, mpi_i, mpi_n
    integer :: np, nrepeat, nvar
    integer :: real_bytes
    real, allocatable :: par(:,:), buf(:,:)
    character(len=3), dimension(3) :: formats
    integer :: f

    call mpi_init(ierr)
    call mpi_comm_rank(mpi_comm_world, mpi_i, ierr)
    call mpi_comm_size(mpi_comm_world, mpi_n, ierr)

    call parse_args(np, nrepeat, nvar)
    allocate(par(nvar,np), buf(nvar,np))
    call fill_particles(par)

    real_bytes = storage_size(par(1,1)) / 8
    formats = (/ 'dat', 'bin', 'h5 ' /)

    if (mpi_i == 0) then
        write(*,'(A,I0)') 'MPI ranks        = ', mpi_n
        write(*,'(A,I0)') 'np per rank      = ', np
        write(*,'(A,I0)') 'particle nvar    = ', nvar
        write(*,'(A,I0)') 'repeat count     = ', nrepeat
        write(*,'(A,I0)') 'real bytes       = ', real_bytes
        write(*,'(A)') 'CSV_HEADER,format,ranks,nvar,np_per_rank,total_particles,' // &
            'real_bytes,payload_MB,write_seconds,read_seconds,write_MB_s,read_MB_s,max_abs_diff'
    end if

    do f = 1, size(formats)
        call benchmark_format(trim(formats(f)), par, buf, np, nrepeat, nvar, real_bytes)
    end do

    deallocate(par, buf)
    call mpi_finalize(ierr)

contains

    subroutine parse_args(np_out, nrepeat_out, nvar_out)

        implicit none

        integer, intent(out) :: np_out, nrepeat_out, nvar_out
        character(len=64) :: arg
        integer :: stat

        np_out = 250000
        nrepeat_out = 3
        nvar_out = 6

        call get_command_argument(1, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) read(arg,*) np_out

        call get_command_argument(2, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) read(arg,*) nrepeat_out

        call get_command_argument(3, arg, status=stat)
        if (stat == 0 .and. len_trim(arg) > 0) read(arg,*) nvar_out

        if (np_out < 1 .or. nrepeat_out < 1 .or. nvar_out < 1) then
            if (mpi_i == 0) write(*,'(A)') 'ERROR: np, nrepeat, and nvar must be positive.'
            call mpi_abort(mpi_comm_world, 3001, ierr)
        end if

    end subroutine parse_args


    subroutine fill_particles(a)

        implicit none

        real, dimension(:,:), intent(out) :: a
        integer :: v, p

        do p = 1, size(a,2)
        do v = 1, size(a,1)
            a(v,p) = real(1000000*mpi_i + 100*v + mod(p,100000))
        end do
        end do

    end subroutine fill_particles


    subroutine benchmark_format(fmt, a, b, np_local, nrepeat_local, nvar_local, real_bytes_local)

        implicit none

        character(len=*), intent(in) :: fmt
        real, dimension(:,:), intent(in) :: a
        real, dimension(:,:), intent(inout) :: b
        integer, intent(in) :: np_local, nrepeat_local, nvar_local, real_bytes_local

        integer :: r, it
        character(len=32) :: label
        real(kind=8) :: t0, t1
        real(kind=8) :: local_write, local_read, local_diff
        real(kind=8) :: max_write, max_read, max_diff
        real(kind=8) :: write_sum, read_sum, diff_max
        real(kind=8) :: payload_mb, write_mbs, read_mbs
        integer(kind=8) :: total_particles, payload_bytes

        label = 'B_' // trim(fmt)
        call cleanup_label(label)

        write_sum = 0.0_8
        read_sum = 0.0_8
        diff_max = 0.0_8

        do r = 1, nrepeat_local
            it = 1000 + r

            call mpi_barrier(mpi_comm_world, ierr)
            t0 = mpi_wtime()
            call write_format(fmt, label, it, np_local, a)
            call mpi_barrier(mpi_comm_world, ierr)
            t1 = mpi_wtime()
            local_write = t1 - t0
            call mpi_reduce(local_write, max_write, 1, mpi_double_precision, mpi_max, 0, mpi_comm_world, ierr)

            b = -1.0
            call mpi_barrier(mpi_comm_world, ierr)
            t0 = mpi_wtime()
            call read_format(fmt, label, it, np_local, b)
            call mpi_barrier(mpi_comm_world, ierr)
            t1 = mpi_wtime()
            local_read = t1 - t0
            call mpi_reduce(local_read, max_read, 1, mpi_double_precision, mpi_max, 0, mpi_comm_world, ierr)

            local_diff = real(maxval(abs(a - b)), kind=8)
            call mpi_reduce(local_diff, max_diff, 1, mpi_double_precision, mpi_max, 0, mpi_comm_world, ierr)

            if (mpi_i == 0) then
                write_sum = write_sum + max_write
                read_sum = read_sum + max_read
                diff_max = max(diff_max, max_diff)
            end if
        end do

        if (mpi_i == 0) then
            total_particles = int(np_local,8) * int(mpi_n,8)
            payload_bytes = int(nvar_local,8) * int(np_local,8) * int(real_bytes_local,8) * int(mpi_n,8)
            payload_mb = real(payload_bytes,8) / (1024.0_8 * 1024.0_8)
            max_write = write_sum / real(nrepeat_local,8)
            max_read = read_sum / real(nrepeat_local,8)
            write_mbs = payload_mb / max(max_write, 1.0e-300_8)
            read_mbs = payload_mb / max(max_read, 1.0e-300_8)

            write(*,'(A,A,",",I0,",",I0,",",I0,",",I0,",",I0,",",F12.4,' // &
                '",",ES16.8,",",ES16.8,",",F12.4,",",F12.4,",",ES16.8)') &
                'RESULT_CSV,', trim(fmt), mpi_n, nvar_local, np_local, total_particles, real_bytes_local, &
                payload_mb, max_write, max_read, write_mbs, read_mbs, diff_max
        end if

    end subroutine benchmark_format


    subroutine cleanup_label(label)

        implicit none

        character(len=*), intent(in) :: label

        if (mpi_i == 0) call execute_command_line('rm -rf ' // trim(label))
        call mpi_barrier(mpi_comm_world, ierr)

    end subroutine cleanup_label


    subroutine write_format(fmt, label, it, np_local, a)

        implicit none

        character(len=*), intent(in) :: fmt, label
        integer, intent(in) :: it, np_local
        real, dimension(:,:), intent(in) :: a

        select case (trim(fmt))
        case ('dat')
            call sub_F02_par_output_dat(label, it, np_local, a)
        case ('bin')
            call sub_F02_par_output_bin(label, it, np_local, a)
        case ('h5')
            call sub_F02_par_output_h5(label, it, np_local, a)
        case default
            if (mpi_i == 0) write(*,'(A,A)') 'ERROR: unsupported format ', trim(fmt)
            call mpi_abort(mpi_comm_world, 3002, ierr)
        end select

    end subroutine write_format


    subroutine read_format(fmt, label, it, np_local, b)

        implicit none

        character(len=*), intent(in) :: fmt, label
        integer, intent(in) :: it, np_local
        real, dimension(:,:), intent(inout) :: b

        select case (trim(fmt))
        case ('dat')
            call sub_F01_par_load_dat(label, it, np_local, b)
        case ('bin')
            call sub_F01_par_load_bin(label, it, np_local, b)
        case ('h5')
            call sub_F01_par_load_h5(label, it, np_local, b)
        case default
            if (mpi_i == 0) write(*,'(A,A)') 'ERROR: unsupported format ', trim(fmt)
            call mpi_abort(mpi_comm_world, 3003, ierr)
        end select

    end subroutine read_format

end program benchmark_F_IO_mpi
