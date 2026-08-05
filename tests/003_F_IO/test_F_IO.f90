program test_F_IO

    use mpi
    use mod_F01_par_load
    use mod_F02_par_output
    use mod_F03_field_load
    use mod_F04_field_output

    implicit none

    integer :: ierr, mpi_i, mpi_n

    !------------------------------------------------------------
    ! MPI init + basic info
    !------------------------------------------------------------
    call mpi_init(ierr)
    call mpi_comm_rank(mpi_comm_world, mpi_i, ierr)
    call mpi_comm_size(mpi_comm_world, mpi_n, ierr)

    ! Only rank 0 prints global status to avoid duplicated messages.
    if (mpi_i == 0) then
        write(*,'(A,I0)') 'Running F_IO tests with MPI ranks = ', mpi_n
    end if

    ! Test particle I/O (F01/F02) and field I/O (F03/F04).
    call test_particles
    call test_fields

    if (mpi_i == 0) write(*,'(A)') 'ALL TESTS PASSED.'

    call mpi_finalize(ierr)

contains

    subroutine test_particles

        implicit none

        integer :: it, np, nvar
        integer :: v, p
        real, allocatable :: par(:,:), buf(:,:)

        !------------------------------------------------------------
        ! Small but non-trivial test size:
        !   nvar: number of properties per particle (rows)
        !   np  : number of particles (columns)
        !------------------------------------------------------------
        nvar = 6
        np   = 8

        allocate(par(nvar,np), buf(nvar,np))

        !------------------------------------------------------------
        ! Fill par with a rank-dependent pattern so that:
        !   1) each MPI rank writes a different file content
        !   2) round-trip read-back can detect cross-rank mix-ups
        !------------------------------------------------------------
        do p = 1, np
        do v = 1, nvar
            par(v,p) = real(1000*mpi_i + 10*v + p)
        end do
        end do

        !============================================================
        ! Low-level routines: directly test each concrete format
        !============================================================

        !-------------------------
        ! DAT: write -> barrier -> read -> compare
        !-------------------------
        it = 101
        call cleanup_label('T_par_dat_low')
        call sub_F02_par_output_dat('T_par_dat_low', it, np, par)

        ! Barrier is important: ensure all ranks finish writing before any rank reads.
        call mpi_barrier(mpi_comm_world, ierr)

        buf = -1.0
        call sub_F01_par_load_dat('T_par_dat_low', it, np, buf)

        ! Element-wise check with a small tolerance.
        call assert_close_2d('par dat low-level', par, buf)

        !-------------------------
        ! BIN
        !-------------------------
        it = 102
        call cleanup_label('T_par_bin_low')
        call sub_F02_par_output_bin('T_par_bin_low', it, np, par)
        call mpi_barrier(mpi_comm_world, ierr)
        buf = -1.0
        call sub_F01_par_load_bin('T_par_bin_low', it, np, buf)
        call assert_close_2d('par bin low-level', par, buf)

        !-------------------------
        ! H5
        !-------------------------
        it = 103
        call cleanup_label('T_par_h5_low')
        call sub_F02_par_output_h5('T_par_h5_low', it, np, par)
        call mpi_barrier(mpi_comm_world, ierr)
        buf = -1.0
        call sub_F01_par_load_h5('T_par_h5_low', it, np, buf)
        call assert_close_2d('par h5 low-level', par, buf)

        !============================================================
        ! Dispatcher routines: test the tag-based wrapper entry points
        !============================================================

        it = 201
        call cleanup_label('T_par_dat_dis')
        call sub_F02_par_output('dat', 'T_par_dat_dis', it, np, par)
        call mpi_barrier(mpi_comm_world, ierr)
        buf = -1.0
        call sub_F01_par_load('dat', 'T_par_dat_dis', it, np, buf)
        call assert_close_2d('par dat dispatcher', par, buf)

        it = 202
        call cleanup_label('T_par_bin_dis')
        call sub_F02_par_output('bin', 'T_par_bin_dis', it, np, par)
        call mpi_barrier(mpi_comm_world, ierr)
        buf = -1.0
        call sub_F01_par_load('bin', 'T_par_bin_dis', it, np, buf)
        call assert_close_2d('par bin dispatcher', par, buf)

        it = 203
        call cleanup_label('T_par_h5_dis')
        call sub_F02_par_output('h5', 'T_par_h5_dis', it, np, par)
        call mpi_barrier(mpi_comm_world, ierr)
        buf = -1.0
        call sub_F01_par_load('h5', 'T_par_h5_dis', it, np, buf)
        call assert_close_2d('par h5 dispatcher', par, buf)

        !------------------------------------------------------------
        ! Unknown tag fallback:
        !   Intentionally pass an invalid tag to verify that the dispatcher
        !   falls back to "dat" (your library prints a warning/error string).
        !------------------------------------------------------------
        it = 299
        call cleanup_label('T_par_badtag')
        call sub_F02_par_output('badtag', 'T_par_badtag', it, np, par)
        call mpi_barrier(mpi_comm_world, ierr)
        buf = -1.0
        call sub_F01_par_load('badtag', 'T_par_badtag', it, np, buf)
        call assert_close_2d('par unknown-tag fallback', par, buf)

        deallocate(par, buf)

    end subroutine test_particles


    subroutine test_fields

        implicit none

        integer :: it
        integer, dimension(1:3) :: il, iu
        integer :: i, j, k, l, n

        real, allocatable :: F3(:,:,:), G3(:,:,:)
        real, allocatable :: F1(:), G1(:)
        real, allocatable :: Fg(:,:,:), Fc(:,:,:)

        !------------------------------------------------------------
        ! Define a small cell-centered index range [il:iu].
        ! This mimics per-rank local subdomain indices.
        !------------------------------------------------------------
        il = (/1,1,1/)
        iu = (/4,3,2/)

        allocate(F3(il(1):iu(1), il(2):iu(2), il(3):iu(3)))
        allocate(G3(il(1):iu(1), il(2):iu(2), il(3):iu(3)))

        ! Rank-dependent, index-dependent pattern for robust checking.
        do k = il(3), iu(3)
        do j = il(2), iu(2)
        do i = il(1), iu(1)
            F3(i,j,k) = real(1000*mpi_i + 100*k + 10*j + i)
        end do
        end do
        end do

        !============================================================
        ! 3D cell-centered field: dat/bin round-trip
        !============================================================

        it = 301
        call cleanup_label('T_F3_dat')
        call sub_F04_field_output_3d_dat('T_F3_dat', it, il, iu, F3)
        call mpi_barrier(mpi_comm_world, ierr)
        G3 = -1.0
        call sub_F03_field_load_3d_dat('T_F3_dat', it, il, iu, G3)
        call assert_close_3d('field 3d dat', F3, G3)

        it = 302
        call cleanup_label('T_F3_bin')
        call sub_F04_field_output_3d_bin('T_F3_bin', it, il, iu, F3)
        call mpi_barrier(mpi_comm_world, ierr)
        G3 = -1.0
        call sub_F03_field_load_3d_bin('T_F3_bin', it, il, iu, G3)
        call assert_close_3d('field 3d bin', F3, G3)

        !============================================================
        ! 1D packed field: verify packing order + dat/bin I/O
        !============================================================

        ! Total number of cells in the local [il:iu] box.
        n = (iu(1)-il(1)+1)*(iu(2)-il(2)+1)*(iu(3)-il(3)+1)
        allocate(F1(n), G1(n))

        ! Pack order here is (k, j, i) with i varying fastest.
        ! This must match the library convention for 1D <-> 3D mapping.
        l = 1
        do k = il(3), iu(3)
        do j = il(2), iu(2)
        do i = il(1), iu(1)
            F1(l) = F3(i,j,k)
            l = l + 1
        end do
        end do
        end do

        it = 311
        call cleanup_label('T_F1_dat')
        call sub_F04_field_output_1d_dat('T_F1_dat', it, il, iu, F1)
        call mpi_barrier(mpi_comm_world, ierr)
        G1 = -1.0
        call sub_F03_field_load_1d_dat('T_F1_dat', it, il, iu, G1)
        call assert_close_1d('field 1d dat', F1, G1)

        it = 312
        call cleanup_label('T_F1_bin')
        call sub_F04_field_output_1d_bin('T_F1_bin', it, il, iu, F1)
        call mpi_barrier(mpi_comm_world, ierr)
        G1 = -1.0
        call sub_F03_field_load_1d_bin('T_F1_bin', it, il, iu, G1)
        call assert_close_1d('field 1d bin', F1, G1)

        deallocate(F1, G1)

        !============================================================
        ! 3D grid-defined -> output -> load as cell-centered
        !============================================================

        ! Grid-defined array spans [il-1:iu] so each cell has 8 surrounding nodes.
        allocate(Fg(il(1)-1:iu(1), il(2)-1:iu(2), il(3)-1:iu(3)))
        allocate(Fc(il(1):iu(1),   il(2):iu(2),   il(3):iu(3)))

        ! Fill Fg with multiples of 8 so that 1/8 averaging is exact in floating point.
        do k = il(3)-1, iu(3)
        do j = il(2)-1, iu(2)
        do i = il(1)-1, iu(1)
            Fg(i,j,k) = real(8*(1000*mpi_i + 100*k + 10*j + i))
        end do
        end do
        end do

        ! Expected cell-centered value from node-based Fg via 8-point average.
        do k = il(3), iu(3)
        do j = il(2), iu(2)
        do i = il(1), iu(1)
            Fc(i,j,k) = 0.125*( &
                Fg(i,  j,  k)   + Fg(i-1,j,  k)   + Fg(i,  j-1,k)   + Fg(i,  j,  k-1) + &
                Fg(i-1,j-1,k)   + Fg(i-1,j,  k-1) + Fg(i,  j-1,k-1) + Fg(i-1,j-1,k-1) )
        end do
        end do
        end do

        ! grid-output routines write cell-centered fields computed from Fg.
        ! We then read back using standard 3D cell-centered loaders and compare to Fc.
        it = 321
        call cleanup_label('T_Fgrid_dat')
        call sub_F04_field_output_3d_grid_dat('T_Fgrid_dat', it, il, iu, Fg)
        call mpi_barrier(mpi_comm_world, ierr)
        G3 = -1.0
        call sub_F03_field_load_3d_dat('T_Fgrid_dat', it, il, iu, G3)
        call assert_close_3d('field 3d_grid dat', Fc, G3)

        it = 322
        call cleanup_label('T_Fgrid_bin')
        call sub_F04_field_output_3d_grid_bin('T_Fgrid_bin', it, il, iu, Fg)
        call mpi_barrier(mpi_comm_world, ierr)
        G3 = -1.0
        call sub_F03_field_load_3d_bin('T_Fgrid_bin', it, il, iu, G3)
        call assert_close_3d('field 3d_grid bin', Fc, G3)

        deallocate(F3, G3, Fg, Fc)

    end subroutine test_fields


    subroutine cleanup_label(label)

        implicit none

        character(len=* ) :: label

        !------------------------------------------------------------
        ! Clean previous output to avoid mixing old/new results.
        ! Only rank 0 deletes; then barrier to synchronize.
        !------------------------------------------------------------
        if (mpi_i == 0) then
            call execute_command_line('rm -rf ' // trim(label))
        end if
        call mpi_barrier(mpi_comm_world, ierr)

    end subroutine cleanup_label


    subroutine assert_close_1d(tag, a, b)

        implicit none

        character(len=* ) :: tag
        real, dimension(:) :: a, b
        real :: diff, tol

        !------------------------------------------------------------
        ! Compare using max absolute difference.
        ! tol is set to a small multiple of machine epsilon to tolerate
        ! tiny round-off differences (especially for binary/HDF5).
        !------------------------------------------------------------
        tol = 100.0*epsilon(1.0)
        diff = maxval(abs(a - b))

        if (diff > tol) then
            write(*,'(A,I0,2A,ES12.5)') 'FAIL(rank=', mpi_i, '): ', trim(tag), '  diff=', diff
            call mpi_abort(mpi_comm_world, 9001, ierr)
        end if
        if (mpi_i == 0) write(*,'(A)') 'PASS: ' // trim(tag)

    end subroutine assert_close_1d


    subroutine assert_close_2d(tag, a, b)

        implicit none

        character(len=* ) :: tag
        real, dimension(:,:) :: a, b
        real :: diff, tol

        tol = 100.0*epsilon(1.0)
        diff = maxval(abs(a - b))

        if (diff > tol) then
            write(*,'(A,I0,2A,ES12.5)') 'FAIL(rank=', mpi_i, '): ', trim(tag), '  diff=', diff
            call mpi_abort(mpi_comm_world, 9002, ierr)
        end if
        if (mpi_i == 0) write(*,'(A)') 'PASS: ' // trim(tag)

    end subroutine assert_close_2d


    subroutine assert_close_3d(tag, a, b)

        implicit none

        character(len=* ) :: tag
        real, dimension(:,:,:) :: a, b
        real :: diff, tol

        tol = 100.0*epsilon(1.0)
        diff = maxval(abs(a - b))

        if (diff > tol) then
            write(*,'(A,I0,2A,ES12.5)') 'FAIL(rank=', mpi_i, '): ', trim(tag), '  diff=', diff
            call mpi_abort(mpi_comm_world, 9003, ierr)
        end if
        if (mpi_i == 0) write(*,'(A)') 'PASS: ' // trim(tag)

    end subroutine assert_close_3d

end program test_F_IO
