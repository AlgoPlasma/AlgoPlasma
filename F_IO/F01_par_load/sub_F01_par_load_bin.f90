!> @file sub_F01_par_load_bin.f90
!> @brief Load particle data from per-rank binary files.
!>
!> @details
!> Each MPI rank reads its local particle data from an unformatted,
!> stream-access ``.bin`` file under directory ``trim(label)``.
!>
!> The input file name has the form
!> ``label/label_time_rank.bin``,
!> where ``time`` is ``it`` formatted as ``I10.10`` and ``rank`` is the
!> MPI rank formatted as ``I5.5``.
!>
!> The file format must match that written by
!> ``sub_F02_par_output_bin``.
!> The file is read with ``form='unformatted'``,
!> ``access='stream'``, and ``action='read'``, so no Fortran record
!> markers are present.
!> The payload consists only of the particle data block ``par(:,1:np)``
!> written in Fortran array element order
!> (column-major, first index varying fastest).
!> No additional header metadata such as ``np`` or ``size(par,1)``
!> is stored in the file.
!>
!> For consistent directory and file naming, ``label`` is expected to be a
!> simple name such as ``e`` or ``ion``.
!> Do not pass a string containing ``/``, since ``label`` is used
!> both as the input directory name and as the file name prefix.
!>
!> @note
!> 1. Requires the MPI module.
!> 2. Assumes ``par`` stores particle properties column-wise.
!> 3. The Fortran unit number is ``mpi_i + 1000``.
!> 4. Since this routine reads raw default Fortran ``real`` data,
!>    the file must be read with matching type sizes and endianness.
!> 5. The caller must already know both ``np`` and ``size(par,1)``.
!>
!> @author Zhe LIU, Yinjian ZHAO (2025/12/02).
!>
!> @param[in] label: character(*), input directory and file name prefix;
!>   should be a simple name and must not contain ``/``.
!> @param[in] it: integer, time step or iteration index encoded in the
!>   file name.
!> @param[in] np: integer, number of particle columns to read.
!> @param[out] par: real,dimension(:,:), particle data array filled from
!>   the binary file, read into ``par(:,1:np)``.

subroutine sub_F01_par_load_bin(label,it,np,par)

    use mpi

    implicit none

    character(len=*) :: label
    integer :: it,np
    real,dimension(:,:) :: par

    integer :: mpi_i,ierr
    integer :: unit,ios,nvar,ncol
    character(len=10) :: time
    character(len=5) :: rank
    character(len=512) :: filename
    character(len=256) :: iomsg

    call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)

    nvar = size(par,1)
    ncol = size(par,2)

    if (nvar < 1) then
        write(*,'(A,I0,A,I0)') 'ERROR(rank=', mpi_i, &
            '): invalid size(par,1)=', nvar
        call mpi_abort(mpi_comm_world,1101,ierr)
    end if

    if (np < 0 .or. np > ncol) then
        write(*,'(A,I0,A,I0,A,I0)') 'ERROR(rank=', mpi_i, &
            '): invalid np=', np, ', size(par,2)=', ncol
        call mpi_abort(mpi_comm_world,1102,ierr)
    end if

    write(time,'(I10.10)') it
    write(rank,'(I5.5)') mpi_i
    filename = trim(label)//'/'//trim(label)//'_'//time//'_'//rank//'.bin'

    unit = mpi_i + 1000
    open(unit,file=trim(filename),status='old',form='unformatted', &
        access='stream',action='read',iostat=ios,iomsg=iomsg)
    if (ios /= 0) then
        write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
            '): cannot open file: ', trim(filename)
        write(*,'(A)') trim(iomsg)
        call mpi_abort(mpi_comm_world,1103,ierr)
    end if

    if (np > 0) then
        read(unit,iostat=ios,iomsg=iomsg) par(:,1:np)
        if (ios /= 0) then
            write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
                '): failed reading file: ', trim(filename)
            write(*,'(A)') trim(iomsg)
            close(unit)
            call mpi_abort(mpi_comm_world,1104,ierr)
        end if
    end if

    close(unit)

end subroutine sub_F01_par_load_bin
