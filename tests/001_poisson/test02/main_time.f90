program main

    use mpi
    use mod_D02_hypre_3Dxyz_bc
    implicit none
    include "HYPREf.h"

    ! ============================================================
    ! D02 analytic BC suite with arbitrary MPI size and coarse timing.
    !
    ! Main changes compared with the original test01_1:
    !   1. Supports arbitrary mpi_n, not only 4 ranks.
    !   2. Builds a 2D Cartesian-like decomposition in x-y, full z.
    !   3. Keeps MPI subdomain interfaces as bc=0 inner boundaries.
    !   4. Keeps default real declarations unchanged.
    !   5. Reports coarse timing blocks:
    !        prepare_time
    !        assembly_time
    !        hypre_total_time
    !        hypre_solve_time
    !        hypre_overhead_time
    !        error_reduce_time
    !        output_time
    !        postprocess_time
    !        case_total_time
    ! ============================================================

    integer,parameter :: nx = 160, ny = 160, nz = 160
    real,parameter :: tol = 1.0e-10
    real,parameter :: phi0 = 0.5
    real,parameter :: gx = 0.2
    real,parameter :: gy = -0.15
    real,parameter :: gz = 0.1
    real,parameter :: phi_inf_out = 0.75
    real,parameter :: zero_vec(1:3) = (/0.0, 0.0, 0.0/)
    real,parameter :: outflow_r0(1:3) = (/0.5*real(nx), &
                                           0.5*real(ny), &
                                           0.5*real(nz)/)

    integer :: ierr, ierr_h, mpi_i, mpi_n
    integer :: fcomm

    integer,dimension(1:3) :: il, iu, period
    integer :: px, py
    integer :: n, nvalues, n_global
    integer :: i, j, k, l

    real,dimension(:),allocatable :: phi1d, phi_exact, rho1d, A_values
    real,dimension(:,:),allocatable :: sx1, sx2, sy1, sy2, sz1, sz2

    real :: err_inf_loc, err_inf
    real :: err_l2_loc, err_l2
    real :: ref_l2_loc, ref_l2
    real :: diff, xcell, ycell, zcell

    logical :: do_init, do_updateA, do_finalize
    integer(8) :: grid, stencil, A, b, x

    call mpi_init(ierr)
    call mpi_comm_rank(mpi_comm_world, mpi_i, ierr)
    call mpi_comm_size(mpi_comm_world, mpi_n, ierr)
    fcomm = MPI_COMM_WORLD

    call choose_2d_decomposition(mpi_n, nx, ny, px, py)
    call setup_partition_2d(mpi_i, px, py, il, iu)
    period = (/0, 0, 0/)

    n = (iu(1)-il(1)+1)*(iu(2)-il(2)+1)*(iu(3)-il(3)+1)
    nvalues = 7*n
    call mpi_allreduce(n, n_global, 1, MPI_INTEGER, MPI_SUM, mpi_comm_world, ierr)

    allocate(phi1d(1:n), phi_exact(1:n), rho1d(1:n), A_values(1:nvalues))

    if (mpi_i == 0) then
        write(*,*) '======================================================'
        write(*,*) 'D02 analytic BC suite on Cartesian MPI partition'
        write(*,*) 'MPI ranks = ', mpi_n
        write(*,*) 'grid      = ', nx, ny, nz
        write(*,*) 'partition = ', px, ' x ', py, ' x 1'
        write(*,*) 'n_global  = ', n_global
        write(*,*) '======================================================'
    end if

    call run_linear_case('x', 'z', (/1,1,2,2,3,3/), &
        'case 1: linear-x, Dirichlet-x + Neumann-y + dielectric-z', &
        'case1_linear_x_compare.dat')

    call run_linear_case('y', 'x', (/3,3,1,1,2,2/), &
        'case 2: linear-y, dielectric-x + Dirichlet-y + Neumann-z', &
        'case2_linear_y_compare.dat')

    call run_linear_case('z', 'y', (/2,2,3,3,1,1/), &
        'case 3: linear-z, Neumann-x + dielectric-y + Dirichlet-z', &
        'case3_linear_z_compare.dat')

    call run_case_outflow()

    call release_dielectric_buffers()
    deallocate(phi1d, phi_exact, rho1d, A_values)
    call mpi_finalize(ierr)

contains

    subroutine choose_2d_decomposition(nproc, nx_in, ny_in, px_out, py_out)
        implicit none
        integer,intent(in) :: nproc, nx_in, ny_in
        integer,intent(out) :: px_out, py_out
        integer :: p, best_px, best_py
        real :: aspect_grid, aspect_part, score, best_score

        ! Choose px*py=nproc with a shape close to the global x-y aspect ratio.
        ! Also prefer px <= nx and py <= ny so no rank gets an empty box.
        aspect_grid = real(nx_in) / real(ny_in)
        best_px = 1
        best_py = nproc
        best_score = huge(1.0)

        do p = 1, nproc
            if (mod(nproc,p) == 0) then
                if (p <= nx_in .and. nproc/p <= ny_in) then
                    aspect_part = real(p) / real(nproc/p)
                    score = abs(log(aspect_part/aspect_grid))
                    if (score < best_score) then
                        best_score = score
                        best_px = p
                        best_py = nproc/p
                    end if
                end if
            end if
        end do

        px_out = best_px
        py_out = best_py

        if (px_out > nx_in .or. py_out > ny_in) then
            if (mpi_i == 0) then
                write(*,*) 'ERROR: too many MPI ranks for this grid.'
                write(*,*) 'Need px <= nx and py <= ny.'
                write(*,*) 'mpi_n, nx, ny = ', nproc, nx_in, ny_in
            end if
            call mpi_finalize(ierr)
            stop
        end if
    end subroutine choose_2d_decomposition

    subroutine setup_partition_2d(rank, px_in, py_in, il_box, iu_box)
        implicit none
        integer,intent(in) :: rank, px_in, py_in
        integer,intent(out) :: il_box(1:3), iu_box(1:3)
        integer :: ix_rank, iy_rank

        ix_rank = mod(rank, px_in)
        iy_rank = rank / px_in

        call split_1d(nx, px_in, ix_rank, il_box(1), iu_box(1))
        call split_1d(ny, py_in, iy_rank, il_box(2), iu_box(2))

        il_box(3) = 1
        iu_box(3) = nz
    end subroutine setup_partition_2d

    subroutine split_1d(ncell, npart, ipart, ilo, ihi)
        implicit none
        integer,intent(in) :: ncell, npart, ipart
        integer,intent(out) :: ilo, ihi
        integer :: base, rem, nloc

        base = ncell / npart
        rem  = mod(ncell, npart)

        if (ipart < rem) then
            nloc = base + 1
            ilo = ipart*nloc + 1
        else
            nloc = base
            ilo = rem*(base+1) + (ipart-rem)*base + 1
        end if

        ihi = ilo + nloc - 1
    end subroutine split_1d

    subroutine run_linear_case(axis_name, dielectric_axis, bc_global, case_title, filename)
        implicit none
        character(len=1),intent(in) :: axis_name, dielectric_axis
        integer,intent(in) :: bc_global(1:6)
        character(len=*),intent(in) :: case_title, filename
        integer :: bc(1:6)
        real :: phibc_global(1:6), phibc(1:6)
        real :: t_case0, t_case1
        real :: t0, t1
        real :: t_reset, t_bc, t_dielectric, t_exact
        real :: t_hinit, t_assemble_base, t_assemble_dielectric, t_assemble_outflow
        real :: t_solve, t_solver_finalize, t_hfinalize
        real :: t_error, t_write

        call mpi_barrier(mpi_comm_world, ierr)
        t_case0 = mpi_wtime()

        t0 = mpi_wtime()
        call reset_case_state()
        t1 = mpi_wtime(); t_reset = t1 - t0

        t0 = mpi_wtime()
        call set_linear_dirichlet_values(axis_name, phibc_global)
        call build_local_bc(bc_global, phibc_global, bc, phibc)
        t1 = mpi_wtime(); t_bc = t1 - t0

        t0 = mpi_wtime()
        call prepare_zero_sigma_dielectric(dielectric_axis)
        t1 = mpi_wtime(); t_dielectric = t1 - t0

        t0 = mpi_wtime()
        call fill_exact_linear(axis_name)
        t1 = mpi_wtime(); t_exact = t1 - t0

        call solve_linear_case(dielectric_axis, bc, phibc, &
            t_hinit, t_assemble_base, t_assemble_dielectric, t_assemble_outflow, &
            t_solve, t_solver_finalize, t_hfinalize)

        t0 = mpi_wtime()
        call compute_errors(case_title)
        t1 = mpi_wtime(); t_error = t1 - t0

        t0 = mpi_wtime()
        call write_compare_file_mpi(filename, mpi_comm_world, mpi_i, mpi_n, il, iu, phi1d, phi_exact)
        t1 = mpi_wtime(); t_write = t1 - t0

        call mpi_barrier(mpi_comm_world, ierr)
        t_case1 = mpi_wtime()

        if (mpi_i == 0) then
            write(*,*) '------------------------------------------------------'
            write(*,*) trim(case_title)
            write(*,*) 'L_inf error     = ', err_inf
            write(*,*) 'relative L2 err = ', err_l2
        end if

        call report_case_timing(case_title, &
            t_reset, t_bc, t_dielectric, t_exact, t_hinit, &
            t_assemble_base, t_assemble_dielectric, t_assemble_outflow, &
            t_solve, t_solver_finalize, t_hfinalize, t_error, t_write, &
            t_case1-t_case0)
    end subroutine run_linear_case

    subroutine run_case_outflow()
        implicit none
        integer :: bc_global(1:6), bc(1:6)
        real :: phibc_global(1:6), phibc(1:6)
        character(len=*),parameter :: case_title = 'case 4: constant field with D02 outflow on all faces'
        character(len=*),parameter :: fname = 'case4_outflow_compare.dat'
        real :: t_case0, t_case1
        real :: t0, t1
        real :: t_reset, t_bc, t_dielectric, t_exact
        real :: t_hinit, t_assemble_base, t_assemble_dielectric, t_assemble_outflow
        real :: t_solve, t_solver_finalize, t_hfinalize
        real :: t_error, t_write

        call mpi_barrier(mpi_comm_world, ierr)
        t_case0 = mpi_wtime()

        t0 = mpi_wtime()
        call reset_case_state()
        t1 = mpi_wtime(); t_reset = t1 - t0

        t0 = mpi_wtime()
        bc_global = 4
        phibc_global = 0.0
        call build_local_bc(bc_global, phibc_global, bc, phibc)
        t1 = mpi_wtime(); t_bc = t1 - t0

        t0 = mpi_wtime()
        ! No dielectric buffers are required for the pure outflow case.
        t1 = mpi_wtime(); t_dielectric = t1 - t0

        t0 = mpi_wtime()
        call fill_exact_constant(phi_inf_out)
        t1 = mpi_wtime(); t_exact = t1 - t0

        call assemble_and_solve(bc, phibc, phi_inf_out, outflow_r0, &
            t_hinit, t_assemble_base, t_assemble_dielectric, t_assemble_outflow, &
            t_solve, t_solver_finalize, t_hfinalize)

        t0 = mpi_wtime()
        call compute_errors(case_title)
        t1 = mpi_wtime(); t_error = t1 - t0

        t0 = mpi_wtime()
        call write_compare_file_mpi(fname, mpi_comm_world, mpi_i, mpi_n, il, iu, phi1d, phi_exact)
        t1 = mpi_wtime(); t_write = t1 - t0

        call mpi_barrier(mpi_comm_world, ierr)
        t_case1 = mpi_wtime()

        if (mpi_i == 0) then
            write(*,*) '------------------------------------------------------'
            write(*,*) trim(case_title)
            write(*,*) 'L_inf error     = ', err_inf
            write(*,*) 'relative L2 err = ', err_l2
        end if

        call report_case_timing(case_title, &
            t_reset, t_bc, t_dielectric, t_exact, t_hinit, &
            t_assemble_base, t_assemble_dielectric, t_assemble_outflow, &
            t_solve, t_solver_finalize, t_hfinalize, t_error, t_write, &
            t_case1-t_case0)
    end subroutine run_case_outflow

    subroutine reset_case_state()
        implicit none
        phi1d = 0.0
        phi_exact = 0.0
        rho1d = 0.0
        A_values = 0.0
        call release_dielectric_buffers()
    end subroutine reset_case_state

    subroutine set_linear_dirichlet_values(axis_name, phibc_global)
        implicit none
        character(len=1),intent(in) :: axis_name
        real,intent(out) :: phibc_global(1:6)

        phibc_global = 0.0

        select case (axis_name)
        case ('x')
            phibc_global(1) = phi0
            phibc_global(2) = phi0 + gx*real(nx)
        case ('y')
            phibc_global(3) = phi0
            phibc_global(4) = phi0 + gy*real(ny)
        case ('z')
            phibc_global(5) = phi0
            phibc_global(6) = phi0 + gz*real(nz)
        case default
            write(*,*) 'ERROR: unsupported linear axis.'
            stop
        end select
    end subroutine set_linear_dirichlet_values

    subroutine prepare_zero_sigma_dielectric(axis_name)
        implicit none
        character(len=1),intent(in) :: axis_name

        call release_dielectric_buffers()

        select case (axis_name)
        case ('x')
            allocate(sx1(il(2)-1:iu(2),il(3)-1:iu(3)))
            allocate(sx2(il(2)-1:iu(2),il(3)-1:iu(3)))
            sx1 = 0.0
            sx2 = 0.0
        case ('y')
            allocate(sy1(il(1)-1:iu(1),il(3)-1:iu(3)))
            allocate(sy2(il(1)-1:iu(1),il(3)-1:iu(3)))
            sy1 = 0.0
            sy2 = 0.0
        case ('z')
            allocate(sz1(il(1)-1:iu(1),il(2)-1:iu(2)))
            allocate(sz2(il(1)-1:iu(1),il(2)-1:iu(2)))
            sz1 = 0.0
            sz2 = 0.0
        case default
            write(*,*) 'ERROR: unsupported dielectric axis.'
            stop
        end select
    end subroutine prepare_zero_sigma_dielectric

    subroutine release_dielectric_buffers()
        implicit none
        if (allocated(sx1)) deallocate(sx1)
        if (allocated(sx2)) deallocate(sx2)
        if (allocated(sy1)) deallocate(sy1)
        if (allocated(sy2)) deallocate(sy2)
        if (allocated(sz1)) deallocate(sz1)
        if (allocated(sz2)) deallocate(sz2)
    end subroutine release_dielectric_buffers

    subroutine solve_linear_case(dielectric_axis, bc, phibc, &
        t_hinit, t_assemble_base, t_assemble_dielectric, t_assemble_outflow, &
        t_solve, t_solver_finalize, t_hfinalize)
        implicit none
        character(len=1),intent(in) :: dielectric_axis
        integer,intent(in) :: bc(1:6)
        real,intent(in) :: phibc(1:6)
        real,intent(out) :: t_hinit, t_assemble_base, t_assemble_dielectric, t_assemble_outflow
        real,intent(out) :: t_solve, t_solver_finalize, t_hfinalize

        select case (dielectric_axis)
        case ('x')
            call assemble_and_solve(bc, phibc, 0.0, zero_vec, &
                t_hinit, t_assemble_base, t_assemble_dielectric, t_assemble_outflow, &
                t_solve, t_solver_finalize, t_hfinalize, &
                use_sx1=.true., use_sx2=.true.)
        case ('y')
            call assemble_and_solve(bc, phibc, 0.0, zero_vec, &
                t_hinit, t_assemble_base, t_assemble_dielectric, t_assemble_outflow, &
                t_solve, t_solver_finalize, t_hfinalize, &
                use_sy1=.true., use_sy2=.true.)
        case ('z')
            call assemble_and_solve(bc, phibc, 0.0, zero_vec, &
                t_hinit, t_assemble_base, t_assemble_dielectric, t_assemble_outflow, &
                t_solve, t_solver_finalize, t_hfinalize, &
                use_sz1=.true., use_sz2=.true.)
        case default
            write(*,*) 'ERROR: unsupported dielectric axis.'
            stop
        end select
    end subroutine solve_linear_case

    subroutine build_local_bc(bc_global, phibc_global, bc_local, phibc_local)
        implicit none
        integer,intent(in) :: bc_global(1:6)
        real,intent(in) :: phibc_global(1:6)
        integer,intent(out) :: bc_local(1:6)
        real,intent(out) :: phibc_local(1:6)

        bc_local = 0
        phibc_local = 0.0

        if (il(1) == 1) then
            bc_local(1) = bc_global(1)
            phibc_local(1) = phibc_global(1)
        end if
        if (iu(1) == nx) then
            bc_local(2) = bc_global(2)
            phibc_local(2) = phibc_global(2)
        end if
        if (il(2) == 1) then
            bc_local(3) = bc_global(3)
            phibc_local(3) = phibc_global(3)
        end if
        if (iu(2) == ny) then
            bc_local(4) = bc_global(4)
            phibc_local(4) = phibc_global(4)
        end if
        if (il(3) == 1) then
            bc_local(5) = bc_global(5)
            phibc_local(5) = phibc_global(5)
        end if
        if (iu(3) == nz) then
            bc_local(6) = bc_global(6)
            phibc_local(6) = phibc_global(6)
        end if
    end subroutine build_local_bc

    subroutine fill_exact_linear(axis_name)
        implicit none
        character(len=1),intent(in) :: axis_name

        l = 1
        do k = il(3), iu(3)
        do j = il(2), iu(2)
        do i = il(1), iu(1)
            xcell = real(i) - 0.5
            ycell = real(j) - 0.5
            zcell = real(k) - 0.5
            select case (axis_name)
            case ('x')
                phi_exact(l) = phi0 + gx*xcell
            case ('y')
                phi_exact(l) = phi0 + gy*ycell
            case ('z')
                phi_exact(l) = phi0 + gz*zcell
            end select
            l = l + 1
        end do
        end do
        end do
    end subroutine fill_exact_linear

    subroutine fill_exact_constant(value)
        implicit none
        real,intent(in) :: value
        phi_exact = value
    end subroutine fill_exact_constant

    subroutine assemble_and_solve(bc, phibc, phi_infty, r0, &
        t_hinit, t_assemble_base, t_assemble_dielectric, t_assemble_outflow, &
        t_solve, t_solver_finalize, t_hfinalize, &
        use_sx1, use_sx2, use_sy1, use_sy2, use_sz1, use_sz2)
        implicit none
        integer,intent(in) :: bc(1:6)
        real,intent(in) :: phibc(1:6), phi_infty, r0(1:3)
        real,intent(out) :: t_hinit, t_assemble_base, t_assemble_dielectric, t_assemble_outflow
        real,intent(out) :: t_solve, t_solver_finalize, t_hfinalize
        logical,intent(in),optional :: use_sx1, use_sx2, use_sy1, use_sy2, use_sz1, use_sz2
        logical :: lsx1, lsx2, lsy1, lsy2, lsz1, lsz2
        real :: t0, t1

        lsx1 = .false.; if (present(use_sx1)) lsx1 = use_sx1
        lsx2 = .false.; if (present(use_sx2)) lsx2 = use_sx2
        lsy1 = .false.; if (present(use_sy1)) lsy1 = use_sy1
        lsy2 = .false.; if (present(use_sy2)) lsy2 = use_sy2
        lsz1 = .false.; if (present(use_sz1)) lsz1 = use_sz1
        lsz2 = .false.; if (present(use_sz2)) lsz2 = use_sz2

        call mpi_barrier(mpi_comm_world, ierr)
        t0 = mpi_wtime()
        call HYPRE_Initialize(ierr_h)
        call mpi_barrier(mpi_comm_world, ierr)
        t1 = mpi_wtime(); t_hinit = t1 - t0

        t0 = mpi_wtime()
        call sub_D02_hypre_3Dxyz_bc_A(il, iu, A_values, rho1d, bc, phibc)
        t1 = mpi_wtime(); t_assemble_base = t1 - t0

        t0 = mpi_wtime()
        select case (count((/lsx1, lsx2, lsy1, lsy2, lsz1, lsz2/)))
        case (0)
            call sub_D02_hypre_3Dxyz_bc_A_dielectric(il, iu, A_values, rho1d, bc)
        case default
            call call_dielectric_with_keywords(bc, lsx1, lsx2, lsy1, lsy2, lsz1, lsz2)
        end select
        t1 = mpi_wtime(); t_assemble_dielectric = t1 - t0

        t0 = mpi_wtime()
        call sub_D02_hypre_3Dxyz_bc_A_outflow(il, iu, A_values, rho1d, bc, phi_infty, r0)
        t1 = mpi_wtime(); t_assemble_outflow = t1 - t0

        do_init = .true.
        do_updateA = .false.
        do_finalize = .false.
        grid = 0_8
        stencil = 0_8
        A = 0_8
        b = 0_8
        x = 0_8

        call mpi_barrier(mpi_comm_world, ierr)
        t0 = mpi_wtime()
        call sub_D02_hypre_3Dxyz_bc_fortran(fcomm, il, iu, phi1d, rho1d, &
            tol, A_values, period, do_init, do_updateA, do_finalize, &
            grid, stencil, A, b, x)
        call mpi_barrier(mpi_comm_world, ierr)
        t1 = mpi_wtime(); t_solve = t1 - t0

        do_init = .false.
        do_updateA = .false.
        do_finalize = .true.

        call mpi_barrier(mpi_comm_world, ierr)
        t0 = mpi_wtime()
        call sub_D02_hypre_3Dxyz_bc_fortran(fcomm, il, iu, phi1d, rho1d, &
            tol, A_values, period, do_init, do_updateA, do_finalize, &
            grid, stencil, A, b, x)
        call mpi_barrier(mpi_comm_world, ierr)
        t1 = mpi_wtime(); t_solver_finalize = t1 - t0

        call mpi_barrier(mpi_comm_world, ierr)
        t0 = mpi_wtime()
        call HYPRE_Finalize(ierr_h)
        call mpi_barrier(mpi_comm_world, ierr)
        t1 = mpi_wtime(); t_hfinalize = t1 - t0
    end subroutine assemble_and_solve

    subroutine call_dielectric_with_keywords(bc, lsx1, lsx2, lsy1, lsy2, lsz1, lsz2)
        implicit none
        integer,intent(in) :: bc(1:6)
        logical,intent(in) :: lsx1, lsx2, lsy1, lsy2, lsz1, lsz2

        if (lsx1 .and. lsx2 .and. .not.lsy1 .and. .not.lsy2 .and. .not.lsz1 .and. .not.lsz2) then
            call sub_D02_hypre_3Dxyz_bc_A_dielectric(il, iu, A_values, rho1d, bc, sx1=sx1, sx2=sx2)
        else if (.not.lsx1 .and. .not.lsx2 .and. lsy1 .and. lsy2 .and. .not.lsz1 .and. .not.lsz2) then
            call sub_D02_hypre_3Dxyz_bc_A_dielectric(il, iu, A_values, rho1d, bc, sy1=sy1, sy2=sy2)
        else if (.not.lsx1 .and. .not.lsx2 .and. .not.lsy1 .and. .not.lsy2 .and. lsz1 .and. lsz2) then
            call sub_D02_hypre_3Dxyz_bc_A_dielectric(il, iu, A_values, rho1d, bc, sz1=sz1, sz2=sz2)
        else
            write(*,*) 'ERROR: unsupported dielectric keyword combination.'
            stop
        end if
    end subroutine call_dielectric_with_keywords

    subroutine compute_errors(case_title)
        implicit none
        character(len=*),intent(in) :: case_title

        err_inf_loc = 0.0
        err_l2_loc = 0.0
        ref_l2_loc = 0.0

        do l = 1, n
            diff = phi1d(l) - phi_exact(l)
            err_inf_loc = max(err_inf_loc, abs(diff))
            err_l2_loc = err_l2_loc + diff*diff
            ref_l2_loc = ref_l2_loc + phi_exact(l)*phi_exact(l)
        end do

        call mpi_reduce(err_inf_loc, err_inf, 1, MPI_DOUBLE_PRECISION, MPI_MAX, 0, mpi_comm_world, ierr)
        call mpi_reduce(err_l2_loc, err_l2, 1, MPI_DOUBLE_PRECISION, MPI_SUM, 0, mpi_comm_world, ierr)
        call mpi_reduce(ref_l2_loc, ref_l2, 1, MPI_DOUBLE_PRECISION, MPI_SUM, 0, mpi_comm_world, ierr)

        if (mpi_i == 0) then
            err_l2 = sqrt(err_l2 / max(ref_l2, tiny(1.0)))
        end if
    end subroutine compute_errors

    subroutine report_case_timing(case_title, &
        t_reset, t_bc, t_dielectric, t_exact, t_hinit, &
        t_assemble_base, t_assemble_dielectric, t_assemble_outflow, &
        t_solve, t_solver_finalize, t_hfinalize, t_error, t_write, t_total)
        implicit none
        character(len=*),intent(in) :: case_title
        real,intent(in) :: t_reset, t_bc, t_dielectric, t_exact, t_hinit
        real,intent(in) :: t_assemble_base, t_assemble_dielectric, t_assemble_outflow
        real,intent(in) :: t_solve, t_solver_finalize, t_hfinalize
        real,intent(in) :: t_error, t_write, t_total

        real :: t_prepare
        real :: t_assembly
        real :: t_hypre_total
        real :: t_hypre_solve
        real :: t_hypre_overhead
        real :: t_output
        real :: t_postprocess

        t_prepare = t_reset + t_bc + t_dielectric + t_exact

        t_assembly = t_assemble_base + &
                     t_assemble_dielectric + &
                     t_assemble_outflow

        t_hypre_solve = t_solve

        t_hypre_overhead = t_hinit + &
                           t_solver_finalize + &
                           t_hfinalize

        t_hypre_total = t_hypre_overhead + t_hypre_solve

        t_output = t_write
        t_postprocess = t_error + t_write

        if (mpi_i == 0) then
            write(*,*) '[TIME] ', trim(case_title)
            write(*,*) 'block                         min(s)          avg(s)          max(s)'
        end if

        call report_time_line('prepare_time          ', t_prepare)
        call report_time_line('assembly_time         ', t_assembly)
        call report_time_line('hypre_total_time      ', t_hypre_total)
        call report_time_line('hypre_solve_time      ', t_hypre_solve)
        call report_time_line('hypre_overhead_time   ', t_hypre_overhead)
        call report_time_line('error_reduce_time     ', t_error)
        call report_time_line('output_time           ', t_output)
        call report_time_line('postprocess_time      ', t_postprocess)
        call report_time_line('case_total_time       ', t_total)
    end subroutine report_case_timing

    subroutine report_time_line(label, tloc)
        implicit none
        character(len=*),intent(in) :: label
        real,intent(in) :: tloc
        real :: tmin, tmax, tsum, tavg

        call mpi_reduce(tloc, tmin, 1, MPI_DOUBLE_PRECISION, MPI_MIN, 0, mpi_comm_world, ierr)
        call mpi_reduce(tloc, tmax, 1, MPI_DOUBLE_PRECISION, MPI_MAX, 0, mpi_comm_world, ierr)
        call mpi_reduce(tloc, tsum, 1, MPI_DOUBLE_PRECISION, MPI_SUM, 0, mpi_comm_world, ierr)

        if (mpi_i == 0) then
            tavg = tsum / real(mpi_n)
            write(*,'(A28,3ES16.8)') trim(label), tmin, tavg, tmax
        end if
    end subroutine report_time_line

    subroutine write_compare_file_mpi(filename, comm, rank, nproc, il_box, iu_box, phi_local, phi_ref_local)
        implicit none
        character(len=*),intent(in) :: filename
        integer,intent(in) :: comm, rank, nproc
        integer,intent(in) :: il_box(1:3), iu_box(1:3)
        real,dimension(:),intent(in) :: phi_local, phi_ref_local

        integer :: ierr_loc
        integer :: p, ii, jj, kk, ll
        integer :: header_loc(6), status_loc(MPI_STATUS_SIZE)
        integer :: nbuf
        real,dimension(:),allocatable :: phi_recv, ref_recv

        if (rank == 0) then
            open(unit=201, file=filename, status='replace', action='write')
            write(201,'(A)') '# i j k phi_num phi_exact abs_error'

            ll = 1
            do kk = il_box(3), iu_box(3)
            do jj = il_box(2), iu_box(2)
            do ii = il_box(1), iu_box(1)
                write(201,'(3I6,1X,3ES24.14)') ii, jj, kk, &
                    phi_local(ll), phi_ref_local(ll), abs(phi_local(ll)-phi_ref_local(ll))
                ll = ll + 1
            end do
            end do
            end do

            do p = 1, nproc-1
                call mpi_recv(header_loc, 6, MPI_INTEGER, p, 401, comm, status_loc, ierr_loc)
                nbuf = (header_loc(2)-header_loc(1)+1) * &
                       (header_loc(4)-header_loc(3)+1) * &
                       (header_loc(6)-header_loc(5)+1)
                allocate(phi_recv(1:nbuf), ref_recv(1:nbuf))
                call mpi_recv(phi_recv, nbuf, MPI_DOUBLE_PRECISION, p, 402, comm, status_loc, ierr_loc)
                call mpi_recv(ref_recv, nbuf, MPI_DOUBLE_PRECISION, p, 403, comm, status_loc, ierr_loc)

                ll = 1
                do kk = header_loc(5), header_loc(6)
                do jj = header_loc(3), header_loc(4)
                do ii = header_loc(1), header_loc(2)
                    write(201,'(3I6,1X,3ES24.14)') ii, jj, kk, &
                        phi_recv(ll), ref_recv(ll), abs(phi_recv(ll)-ref_recv(ll))
                    ll = ll + 1
                end do
                end do
                end do

                deallocate(phi_recv, ref_recv)
            end do

            close(201)
        else
            header_loc = (/il_box(1), iu_box(1), il_box(2), iu_box(2), il_box(3), iu_box(3)/)
            call mpi_send(header_loc, 6, MPI_INTEGER, 0, 401, comm, ierr_loc)
            call mpi_send(phi_local, size(phi_local), MPI_DOUBLE_PRECISION, 0, 402, comm, ierr_loc)
            call mpi_send(phi_ref_local, size(phi_ref_local), MPI_DOUBLE_PRECISION, 0, 403, comm, ierr_loc)
        end if
    end subroutine write_compare_file_mpi

end program main
