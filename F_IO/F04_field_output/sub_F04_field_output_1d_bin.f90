!> @file sub_F04_field_output_1d_bin.f90
!> @brief Output a 3D cell-centered field stored as a 1D array to a binary
!>   stream file.
!>
!> @details
!> Each MPI rank writes its local field vector ``F`` to a binary
!> ``.bin`` file under directory ``trim(label)``. Rank 0 creates the
!> output directory using ``mkdir -p``, then all ranks synchronize with
!> ``mpi_barrier`` before writing files.
!>
!> The output file name has the form
!> ``label/label_time_rank.bin``,
!> where ``time`` is ``it`` formatted as ``I10.10`` and ``rank`` is the
!> MPI rank formatted as ``I5.5``.
!>
!> The file is opened with ``access='stream'`` and
!> ``form='unformatted'``, so no Fortran record markers are written.
!> The binary layout is:
!> 6 default integers first, namely ``il(1:3)`` followed by ``iu(1:3)``,
!> then ``N`` default real values ``F(1:N)``.
!>
!> The ordering of ``F`` is the caller's 1D layout, typically
!> corresponding to nested loop order ``k``, ``j``, ``i`` with a linear
!> index from 1 to ``N``.
!>
!> For consistent directory and file naming, ``label`` is expected to be a
!> simple name such as ``Ey`` or ``phi``.
!> Do not pass a string containing ``/``, since ``label`` is used
!> both as the output directory name and as the file name prefix.
!>
!> Since this routine writes raw binary data using default Fortran
!> ``integer`` and ``real`` types, the reader must use matching type sizes
!> and endianness.
!>
!> @note This routine can also be used to output a grid-defined 3D field
!> without interpolation or averaging, provided that the caller first
!> packs the grid-defined data into a 1D vector ``F(1:N)``.
!> In that case, pass the actual index bounds of the grid-defined array
!> as ``il`` and ``iu``.
!> For example, if a grid-defined array spans
!> ``(il_cell(1)-1:iu_cell(1), il_cell(2)-1:iu_cell(2),
!> il_cell(3)-1:iu_cell(3))``, then call this routine with
!> ``il = il_cell - 1`` and ``iu = iu_cell``.
!> The vector ``F`` will then be written exactly as provided by the
!> caller, with no additional reordering, interpolation, or averaging
!> performed inside this routine.
!>
!> @author Yinjian ZHAO (2025/05/14), Zhe LIU (2025/12/28).
!>
!> @param[in] label: character(*), output directory and file name prefix;
!>   should be a simple name and must not contain ``/``.
!> @param[in] it: integer, time step index encoded in the file name.
!> @param[in] il: integer (1:3), cell-center lower indices in x,y,z.
!> @param[in] iu: integer (1:3), cell-center upper indices in x,y,z.
!> @param[in] F: real (1:N), 1D field vector with ``N = nx*ny*nz``.

subroutine sub_F04_field_output_1d_bin(label,it,il,iu,F)

    use mpi

    implicit none

    character(len=*) :: label
    integer :: it
    integer,dimension(1:3) :: il,iu
    real,dimension(1:(iu(1)-il(1)+1)*(iu(2)-il(2)+1)*(iu(3)-il(3)+1)) :: F

    integer :: ierr,mpi_i,unit
    character(len=10) :: time
    character(len=5) :: rank
    character(len=512) :: filename

    call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)
    unit = mpi_i + 1000

    if (mpi_i == 0) call execute_command_line('mkdir -p ' // trim(label))
    call mpi_barrier(mpi_comm_world,ierr)

    write(time,'(I10.10)') it
    write(rank,'(I5.5)') mpi_i
    filename = trim(label)//'/'//trim(label)//'_'//time//'_'//rank//'.bin'

    open(unit,file=trim(filename),status='replace',&
        form='unformatted',access='stream',action='write')

    write(unit) il
    write(unit) iu
    write(unit) F

    close(unit)

end subroutine sub_F04_field_output_1d_bin
