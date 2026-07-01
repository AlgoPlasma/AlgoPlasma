!> @file sub_F04_field_output_3d_dat.f90
!> @brief Output a 3D cell-centered field to per-rank ASCII files.
!>
!> @details
!> Each MPI rank writes its local subdomain array ``F`` to an ASCII
!> ``.dat`` file under directory ``trim(label)``. Rank 0 creates the
!> output directory using ``mkdir -p``, then all ranks synchronize with
!> ``mpi_barrier`` before writing files.
!>
!> The output file name has the form
!> ``label/label_time_rank.dat``,
!> where ``time`` is ``it`` formatted as ``I10.10`` and ``rank`` is the
!> MPI rank formatted as ``I5.5``. The first six lines store ``il`` and
!> ``iu`` (one integer per line). Field values are then written in
!> Fortran array element order (i fastest, then j, then k),
!> equivalent to nested loops ``k``, ``j``, ``i``. The Fortran unit
!> number is ``mpi_i + 1000``.
!>
!> For consistent directory and file naming, ``label`` is expected to be a
!> simple name such as ``Ey`` or ``phi``.
!> Do not pass a string containing ``/``, since ``label`` is used
!> both as the output directory name and as the file name prefix.
!>
!> @note This routine can also be used to output a grid-defined 3D array
!>   without interpolation or averaging.
!>   In that case, pass the actual index bounds of the grid-defined array
!>   as ``il`` and ``iu``. For example, if a grid-defined array spans
!>   ``(il_cell(1)-1:iu_cell(1), il_cell(2)-1:iu_cell(2),
!>   il_cell(3)-1:iu_cell(3))``, then call this routine with
!>   ``il = il_cell - 1`` and ``iu = iu_cell``.
!>   The array will then be written exactly as stored, in Fortran array
!>   element order.
!>
!> @author Yinjian ZHAO (2025/05/14), Zhe LIU (2025/12/28).
!>
!> @param[in] label: character(*), output directory and file name prefix;
!>   should be a simple name and must not contain ``/``.
!> @param[in] it: integer, time step index encoded in the file name.
!> @param[in] il: integer (1:3), cell-center lower indices in x,y,z.
!> @param[in] iu: integer (1:3), cell-center upper indices in x,y,z.
!> @param[in] F: real (il(1):iu(1),il(2):iu(2),il(3):iu(3)), 3D field.

subroutine sub_F04_field_output_3d_dat(label,it,il,iu,F)

    use mpi

    implicit none

    character(len=*) :: label
    integer :: it
    integer,dimension(1:3) :: il,iu
    real,dimension(il(1):iu(1),il(2):iu(2),il(3):iu(3)) :: F

    integer :: ierr,mpi_i,unit,i,j,k
    character(len=10) :: time
    character(len=5) :: rank
    character(len=512) :: filename

    call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)

    if (mpi_i == 0) call execute_command_line('mkdir -p ' // trim(label))
    call mpi_barrier(mpi_comm_world,ierr)

    write(time,'(I10.10)') it
    write(rank,'(I5.5)') mpi_i
    filename = trim(label)//'/'//trim(label)//'_'//time//'_'//rank//'.dat'

    unit = mpi_i + 1000
    open(unit,file=trim(filename),status='replace')

    write(unit,*) il(1)
    write(unit,*) il(2)
    write(unit,*) il(3)
    write(unit,*) iu(1)
    write(unit,*) iu(2)
    write(unit,*) iu(3)

    do k = il(3),iu(3)
    do j = il(2),iu(2)
    do i = il(1),iu(1)
        write(unit,*) F(i,j,k)
    end do
    end do
    end do

    close(unit)

end subroutine sub_F04_field_output_3d_dat
