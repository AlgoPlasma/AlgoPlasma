!> @file sub_F02_par_output_bin.f90
!> @brief Write particle data to per-rank binary files.
!>
!> @details
!> Each MPI rank writes its local particle data to an unformatted,
!> stream-access ``.bin`` file under directory ``trim(label)``.
!> Rank 0 creates the output directory using ``mkdir -p``, then all ranks
!> synchronize with ``mpi_barrier`` before writing files.
!>
!> The output file name has the form
!> ``label/label_time_rank.bin``,
!> where ``time`` is ``it`` formatted as ``I10.10`` and ``rank`` is the
!> MPI rank formatted as ``I5.5``.
!>
!> The file is opened with ``form='unformatted'``,
!> ``access='stream'``, and ``action='write'``, so no Fortran record
!> markers are inserted.
!> The payload consists only of the particle data block
!> ``par(:,1:np)``, written in Fortran array element order
!> (column-major, first index varying fastest).
!> No additional header metadata such as ``np`` or ``size(par,1)`` is
!> written to the file.
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
!> 4. Since this routine writes raw default Fortran ``real`` data,
!>    any reader must use matching type sizes and endianness, and must
!>    already know both ``np`` and ``size(par,1)``.
!>
!> @author Zhe LIU, Yinjian ZHAO (2025/12/02).
!>
!> @param[in] label: character(*), output directory and file name prefix;
!>   should be a simple name and must not contain ``/``.
!> @param[in] it: integer, current iteration index encoded in the file name.
!> @param[in] np: integer, number of particle columns to write.
!> @param[in] par: real,dimension(:,:), particle data array stored
!>   column-wise as ``par(:,p)`` for ``p = 1..np``.

subroutine sub_F02_par_output_bin(label,it,np,par)

    use mpi

    implicit none

    character(len=*) :: label
    integer :: it,np
    real,dimension(:,:) :: par

    integer :: mpi_i,ierr
    integer :: unit,ios,ncol
    character(len=10) :: time
    character(len=5) :: rank
    character(len=512) :: filename
    character(len=256) :: iomsg

    call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)

    ncol = size(par,2)
    if (np < 0 .or. np > ncol) then
        write(*,'(A,I0,A,I0,A,I0)') 'ERROR(rank=', mpi_i, &
            '): invalid np=', np, ', size(par,2)=', ncol
        call mpi_abort(mpi_comm_world,1201,ierr)
    end if

    if (mpi_i == 0) call execute_command_line('mkdir -p ' // trim(label))
    call mpi_barrier(mpi_comm_world,ierr)

    write(time,'(I10.10)') it
    write(rank,'(I5.5)') mpi_i
    filename = trim(label)//'/'//trim(label)//'_'//time//'_'//rank//'.bin'

    unit = mpi_i + 1000
    open(unit,file=trim(filename),status='replace',form='unformatted', &
        access='stream',action='write',iostat=ios,iomsg=iomsg)
    if (ios /= 0) then
        write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
            '): cannot open file: ', trim(filename)
        write(*,'(A)') trim(iomsg)
        call mpi_abort(mpi_comm_world,1202,ierr)
    end if

    if (np > 0) then
        write(unit,iostat=ios,iomsg=iomsg) par(:,1:np)
        if (ios /= 0) then
            write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
                '): failed writing file: ', trim(filename)
            write(*,'(A)') trim(iomsg)
            close(unit)
            call mpi_abort(mpi_comm_world,1203,ierr)
        end if
    end if

    close(unit)

end subroutine sub_F02_par_output_bin
