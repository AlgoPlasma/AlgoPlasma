!> @file sub_F03_field_load_3d_dat.f90
!> @brief Load a 3D cell-centered field from per-rank ASCII files.
!>
!> @details
!> Each MPI rank reads its local subdomain array ``F`` from an ASCII
!> ``.dat`` file under directory ``trim(label)``.
!>
!> The input file name has the form
!> ``label/label_time_rank.dat``,
!> where ``time`` is ``it`` formatted as ``I10.10`` and ``rank`` is the
!> MPI rank formatted as ``I5.5``.
!>
!> The file format must match that written by
!> ``sub_F04_field_output_3d_dat``:
!> the first six lines store ``il(1:3)`` then ``iu(1:3)``
!> (one integer per line), followed by the 3D field values written in
!> Fortran array element order (i fastest, then j, then k),
!> equivalent to nested loops ``k``, ``j``, ``i``.
!>
!> The header indices stored in the file are validated against the input
!> arguments ``il`` and ``iu``.
!>
!> For consistent directory and file naming, ``label`` is expected to be a
!> simple name such as ``Ey`` or ``phi``.
!> Do not pass a string containing ``/``, since ``label`` is used
!> both as the input directory name and as the file name prefix.
!>
!> @note This routine can also be used to load a grid-defined 3D array
!>   previously written by ``sub_F04_field_output_3d_dat`` without
!>   interpolation or averaging.
!>   In that case, the input arguments ``il`` and ``iu`` must be the
!>   actual index bounds used when writing the grid-defined array.
!>   For example, if the stored grid-defined array spans
!>   ``(il_cell(1)-1:iu_cell(1), il_cell(2)-1:iu_cell(2),
!>   il_cell(3)-1:iu_cell(3))``, then call this routine with
!>   ``il = il_cell - 1`` and ``iu = iu_cell``.
!>   The array will then be read back exactly as stored.
!>
!> @author Zhe LIU (2025/12/29), Yinjian ZHAO (2026/02/27).
!>
!> @param[in] label: character(*), input directory and file name prefix;
!>   should be a simple name and must not contain ``/``.
!> @param[in] it: integer, time step index encoded in the file name.
!> @param[in] il: integer (1:3), cell-centered lower indices in x,y,z.
!> @param[in] iu: integer (1:3), cell-centered upper indices in x,y,z.
!> @param[out] F: real (il(1):iu(1),il(2):iu(2),il(3):iu(3)), loaded field.

subroutine sub_F03_field_load_3d_dat(label,it,il,iu,F)

    use mpi

    implicit none

    character(len=*) :: label
    integer :: it
    integer,dimension(1:3) :: il,iu
    real,dimension(il(1):iu(1),il(2):iu(2),il(3):iu(3)) :: F

    integer :: ierr,mpi_i,unit
    integer :: ios
    integer,dimension(1:3) :: ilf,iuf
    character(len=10) :: time
    character(len=5) :: rank
    character(len=512) :: filename
    character(len=256) :: iomsg

    call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)
    unit = mpi_i + 1000

    write(time,'(I10.10)') it
    write(rank,'(I5.5)') mpi_i
    filename = trim(label)//'/'//trim(label)//'_'//time//'_'//rank//'.dat'

    open(unit,file=trim(filename),status='old',action='read', &
        iostat=ios,iomsg=iomsg)
    if (ios /= 0) then
        write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
            '): cannot open file: ', trim(filename)
        write(*,'(A)') trim(iomsg)
        call mpi_abort(mpi_comm_world,2201,ierr)
    end if

    read(unit,*,iostat=ios,iomsg=iomsg) ilf
    if (ios /= 0) then
        write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
            '): failed reading il from: ', trim(filename)
        write(*,'(A)') trim(iomsg)
        close(unit)
        call mpi_abort(mpi_comm_world,2202,ierr)
    end if

    read(unit,*,iostat=ios,iomsg=iomsg) iuf
    if (ios /= 0) then
        write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
            '): failed reading iu from: ', trim(filename)
        write(*,'(A)') trim(iomsg)
        close(unit)
        call mpi_abort(mpi_comm_world,2203,ierr)
    end if

    if (any(ilf /= il) .or. any(iuf /= iu)) then
        write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
            '): header indices mismatch in: ', trim(filename)
        write(*,'(A,3(I0,1X))') '  il(file)=', ilf
        write(*,'(A,3(I0,1X))') '  il(arg) =', il
        write(*,'(A,3(I0,1X))') '  iu(file)=', iuf
        write(*,'(A,3(I0,1X))') '  iu(arg) =', iu
        close(unit)
        call mpi_abort(mpi_comm_world,2204,ierr)
    end if

    read(unit,*,iostat=ios,iomsg=iomsg) F
    if (ios /= 0) then
        write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
            '): failed reading F from: ', trim(filename)
        write(*,'(A)') trim(iomsg)
        close(unit)
        call mpi_abort(mpi_comm_world,2205,ierr)
    end if

    close(unit)

end subroutine sub_F03_field_load_3d_dat
