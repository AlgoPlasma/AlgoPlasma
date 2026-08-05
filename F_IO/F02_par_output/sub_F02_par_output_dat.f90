!> @file sub_F02_par_output_dat.f90
!> @brief Write particle data to per-rank ASCII files.
!>
!> @details
!> Each MPI rank writes its local particle data to an ASCII ``.dat`` file
!> under directory ``trim(label)``. Rank 0 creates the output directory
!> using ``mkdir -p``, then all ranks synchronize with ``mpi_barrier``
!> before writing files.
!>
!> The output file name has the form
!> ``label/label_time_rank.dat``,
!> where ``time`` is ``it`` formatted as ``I10.10`` and ``rank`` is the
!> MPI rank formatted as ``I5.5``.
!>
!> Each particle is written as one record (one line), using one column of
!> the particle array, i.e., ``par(:,p)`` for ``p = 1..np``.
!> The file is opened with ``status='replace'`` and ``action='write'``,
!> so any existing file with the same name is overwritten.
!>
!> For consistent directory and file naming, ``label`` is expected to be a
!> simple name such as ``e`` or ``ion``.
!> Do not pass a string containing ``/``, since ``label`` is used
!> both as the output directory name and as the file name prefix.
!>
!> @note
!> 1. Requires the MPI module.
!> 2. Assumes ``par`` stores particle properties column-wise.
!> 3. The Fortran unit number is ``mpi_i + 1000``.
!>
!> @author Yinjian ZHAO (2025/04/16), Zhe LIU (2025/11/04).
!>
!> @param[in] label: character(*), output directory and file name prefix;
!>   should be a simple name and must not contain ``/``.
!> @param[in] it: integer, time step index encoded in the file name.
!> @param[in] np: integer, number of particles owned by the current MPI rank.
!> @param[in] par: real,dimension(:,:), particle data array stored
!>   column-wise as ``par(:,p)`` for ``p = 1..np``.

subroutine sub_F02_par_output_dat(label,it,np,par)

    use mpi

    implicit none

    character(len=*) :: label
    integer :: it,np
    real,dimension(:,:) :: par

    integer :: mpi_i,ierr
    integer :: unit,p,ios
    character(len=10) :: time
    character(len=5) :: rank
    character(len=512) :: filename
    character(len=256) :: iomsg

    call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)

    if (np < 0 .or. np > size(par,2)) then
        write(*,'(A,I0,A,I0,A,I0)') 'ERROR(rank=', mpi_i, &
            '): invalid np=', np, ', size(par,2)=', size(par,2)
        call mpi_abort(mpi_comm_world,1201,ierr)
    end if

    if (mpi_i == 0) call execute_command_line('mkdir -p ' // trim(label))
    call mpi_barrier(mpi_comm_world,ierr)

    write(time,'(I10.10)') it
    write(rank,'(I5.5)') mpi_i
    filename = trim(label)//'/'//trim(label)//'_'//time//'_'//rank//'.dat'

    unit = mpi_i + 1000
    open(unit,file=trim(filename),status='replace',action='write', &
        iostat=ios,iomsg=iomsg)
    if (ios /= 0) then
        write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
            '): cannot open file: ', trim(filename)
        write(*,'(A)') trim(iomsg)
        call mpi_abort(mpi_comm_world,1202,ierr)
    end if

    do p = 1,np
        write(unit,*) par(:,p)
    end do

    close(unit)

end subroutine sub_F02_par_output_dat
