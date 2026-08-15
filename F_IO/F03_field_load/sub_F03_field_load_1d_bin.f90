!> @file sub_F03_field_load_1d_bin.f90
!> @brief Load a 3D cell-centered field stored as a 1D vector from per-rank
!>   binary files.
!>
!> @details
!> Each MPI rank reads its local field vector ``F`` from an unformatted,
!> stream-access ``.bin`` file under directory ``trim(label)``.
!>
!> The input file name has the form
!> ``label/label_time_rank.bin``,
!> where ``time`` is ``it`` formatted as ``I10.10`` and ``rank`` is the
!> MPI rank formatted as ``I5.5``.
!>
!> The file format must match that written by
!> ``sub_F04_field_output_1d_bin``.
!> The file is read with ``form='unformatted'`` and ``access='stream'``,
!> so no Fortran record markers are present.
!> It stores 6 integers first: ``il(1:3)`` followed by ``iu(1:3)``,
!> then ``N`` real values ``F(1:N)``, where
!> ``N = (iu(1)-il(1)+1)*(iu(2)-il(2)+1)*(iu(3)-il(3)+1)``.
!>
!> The ordering of ``F`` is the same as in the file written by
!> ``sub_F04_field_output_1d_bin``: it is the caller's 1D layout,
!> typically corresponding to nested loop order ``k``, ``j``, ``i`` with
!> a linear index from 1 to ``N``.
!>
!> For consistent directory and file naming, ``label`` is expected to be a
!> simple name such as ``Ey`` or ``phi``.
!> Do not pass a string containing ``/``, since ``label`` is used
!> both as the input directory name and as the file name prefix.
!>
!> Since this routine reads raw binary data using default Fortran
!> ``integer`` and ``real`` types, the file must have matching type sizes
!> and endianness.
!>
!> @note This routine can also be used to load a grid-defined 3D field
!> previously written by the corresponding 1D output routine, provided
!> that the stored data represent a caller-defined 1D packing of the
!> grid-defined array.
!> In that case, the header indices ``il`` and ``iu`` represent the
!> actual index bounds of the grid-defined array rather than necessarily
!> cell-centered bounds.
!> For example, if the stored grid-defined array spans
!> ``(il_cell(1)-1:iu_cell(1), il_cell(2)-1:iu_cell(2),
!> il_cell(3)-1:iu_cell(3))``, then the file may be read with
!> ``il = il_cell - 1`` and ``iu = iu_cell``.
!> The 1D vector ``F`` is read back exactly as stored, and the caller is
!> responsible for interpreting or unpacking it into the desired
!> grid-defined layout.
!>
!> @author Zhe LIU (2026/01/10).
!>
!> @param[in] label: character(*), input directory and file name prefix;
!>   should be a simple name and must not contain ``/``.
!> @param[in] it: integer, time step index encoded in the file name.
!> @param[out] il: integer (1:3), cell-centered lower indices in x,y,z,
!>   read from file.
!> @param[out] iu: integer (1:3), cell-centered upper indices in x,y,z,
!>   read from file.
!> @param[out] F: real, allocatable (1:N), 1D field vector read from file.

subroutine sub_F03_field_load_1d_bin(label,it,il,iu,F)

    use mpi

    implicit none

    character(len=*) :: label
    integer :: it
    integer,dimension(1:3) :: il,iu
    real,allocatable :: F(:)

    integer :: ierr,mpi_i,unit
    integer :: ios,ncell
    character(len=10) :: time
    character(len=5) :: rank
    character(len=512) :: filename
    character(len=256) :: iomsg

    call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)
    unit = mpi_i + 1000

    write(time,'(I10.10)') it
    write(rank,'(I5.5)') mpi_i
    filename = trim(label)//'/'//trim(label)//'_'//time//'_'//rank//'.bin'

    open(unit,file=trim(filename),status='old',form='unformatted', &
        access='stream',action='read',iostat=ios,iomsg=iomsg)
    if (ios /= 0) then
        write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
            '): cannot open file: ', trim(filename)
        write(*,'(A)') trim(iomsg)
        call mpi_abort(mpi_comm_world,2101,ierr)
    end if

    read(unit,iostat=ios,iomsg=iomsg) il
    if (ios /= 0) then
        write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
            '): failed reading il from: ', trim(filename)
        write(*,'(A)') trim(iomsg)
        close(unit)
        call mpi_abort(mpi_comm_world,2102,ierr)
    end if

    read(unit,iostat=ios,iomsg=iomsg) iu
    if (ios /= 0) then
        write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
            '): failed reading iu from: ', trim(filename)
        write(*,'(A)') trim(iomsg)
        close(unit)
        call mpi_abort(mpi_comm_world,2103,ierr)
    end if

    ncell = (iu(1)-il(1)+1)*(iu(2)-il(2)+1)*(iu(3)-il(3)+1)
    if (ncell <= 0) then
        write(*,'(A,I0,A,3(I0,1X),A,3(I0,1X))') &
            'ERROR(rank=', mpi_i, '): invalid il/iu. il=', &
            il(1), il(2), il(3), ' iu=', iu(1), iu(2), iu(3)
        close(unit)
        call mpi_abort(mpi_comm_world,2104,ierr)
    end if

    if (allocated(F)) deallocate(F)
    allocate(F(1:ncell), stat=ios)
    if (ios /= 0) then
        write(*,'(A,I0,A,I0)') 'ERROR(rank=', mpi_i, &
            '): allocation failed, ncell=', ncell
        close(unit)
        call mpi_abort(mpi_comm_world,2105,ierr)
    end if

    read(unit,iostat=ios,iomsg=iomsg) F
    if (ios /= 0) then
        write(*,'(A,I0,2A)') 'ERROR(rank=', mpi_i, &
            '): failed reading F from: ', trim(filename)
        write(*,'(A)') trim(iomsg)
        close(unit)
        call mpi_abort(mpi_comm_world,2106,ierr)
    end if

    close(unit)

end subroutine sub_F03_field_load_1d_bin
