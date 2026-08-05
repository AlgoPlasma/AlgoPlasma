!> @file sub_F04_field_output_3d_grid_dat.f90
!> @brief Output a cell-centered 3D field reconstructed from a grid-defined
!>   array to per-rank ASCII files.
!>
!> @details
!> ``il`` and ``iu`` are cell-centered indices. The input array ``F`` is
!> defined on the grid from ``il-1`` to ``iu`` in each direction.
!> For each cell center ``(i,j,k)``, this routine writes the arithmetic
!> mean of the eight surrounding grid values, i.e., the average over
!> ``F(i-1:i,j-1:j,k-1:k)``.
!>
!> Each MPI rank writes its local data to an ASCII ``.dat`` file under
!> directory ``trim(label)``. Rank 0 creates the output directory using
!> ``mkdir -p``, then all ranks synchronize with ``mpi_barrier`` before
!> writing files.
!>
!> The output file name has the form
!> ``label/label_time_rank.dat``,
!> where ``time`` is ``it`` formatted as ``I10.10`` and ``rank`` is the
!> MPI rank formatted as ``I5.5``. The first six lines store ``il`` and
!> ``iu`` (one integer per line), followed by the reconstructed
!> cell-centered values in loop order ``k``, ``j``, ``i``.
!>
!> For consistent directory and file naming, ``label`` is expected to be a
!> simple name such as ``Ey`` or ``phi``.
!> Do not pass a string containing ``/``, since ``label`` is used
!> both as the output directory name and as the file name prefix.
!>
!> @author Yinjian ZHAO (2025/12/28).
!>
!> @param[in] label: character(*), output directory and file name prefix;
!>   should be a simple name and must not contain ``/``.
!> @param[in] it: integer, time step index encoded in the file name.
!> @param[in] il: integer (1:3), cell-centered lower indices in x,y,z.
!> @param[in] iu: integer (1:3), cell-centered upper indices in x,y,z.
!> @param[in] F: real (il(1)-1:iu(1),il(2)-1:iu(2),il(3)-1:iu(3)),
!>   grid-defined field.

subroutine sub_F04_field_output_3d_grid_dat(label,it,il,iu,F)

    use mpi

    implicit none

    character(len=*) :: label
    integer :: it
    integer,dimension(1:3) :: il,iu
    real,dimension(il(1)-1:iu(1),il(2)-1:iu(2),il(3)-1:iu(3)) :: F

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
        write(unit,*) 0.125*( &
            F(i,j,k) + F(i-1,j,k) + F(i,j-1,k) + F(i,j,k-1) + &
            F(i-1,j-1,k) + F(i-1,j,k-1) + F(i,j-1,k-1) + &
            F(i-1,j-1,k-1) )
    end do
    end do
    end do

    close(unit)

end subroutine sub_F04_field_output_3d_grid_dat
