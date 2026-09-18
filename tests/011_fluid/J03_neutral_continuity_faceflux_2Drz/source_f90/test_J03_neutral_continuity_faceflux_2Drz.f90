program test_J03_neutral_continuity_faceflux_2Drz
    use mod_J01_continuity_freeflow, only: sub_J01_build_faceflux_2Drz, &
        J01_SUCCESS, J01_FACE_OPEN, J01_FACE_INTERIOR, J01_R_LO, J01_R_HI
    use mod_J02_neutral_sn_transport_2Drz, only: sn_mesh_2drz_type, &
        sn_geometry_2drz_type, sn_quadrature_type, sn_boundary_2drz_type, &
        sub_J02_initialize_mesh, sub_J02_build_geometry, &
        sub_J02_initialize_boundary_types, sub_J02_build_phase_quadrature, &
        sub_J02_build_sigma_from_frequency, sub_J02_build_mc_crossing_pdf_inflow_shape, &
        sub_J02_build_mc_crossing_bins_inflow_shape, &
        sub_J02_reconstruct_open_boundary_fluxes, sub_J02_sweep_all_directions, &
        SN_SUCCESS, SN_N_FACES, SN_Z_LO, SN_FACE_WALL, SN_ERR_SWEEP_WALL_UNSUPPORTED
    use mod_J03_neutral_continuity_faceflux_2Drz
    implicit none
    integer :: n_failed
    n_failed = 0
    write(*, '(a)') '=== J01/J02 to J03 face-flux continuity tests ==='
    call test_j01_faceflux(n_failed)
    call test_j02_contract(n_failed)
    call test_j03_boundary_equilibrium(n_failed)
    call test_j03_ionization_equilibrium(n_failed)
    call test_j03_closed_conservation(n_failed)
    write(*, '(a,i0)') 'n_failed = ', n_failed
    if (n_failed == 0) then
        write(*, '(a)') 'RESULT: PASS'
    else
        write(*, '(a)') 'RESULT: FAIL'
        error stop 1
    end if
contains
    subroutine check(condition, label, n_failed)
        logical, intent(in) :: condition
        character(len = *), intent(in) :: label
        integer, intent(inout) :: n_failed
        if (condition) then
            write(*, '(a)') 'PASS: '//trim(label)
        else
            write(*, '(a)') 'FAIL: '//trim(label)
            n_failed = n_failed+1
        end if
    end subroutine check

    subroutine check_close(actual, expected, tolerance, label, n_failed)
        real, intent(in) :: actual, expected, tolerance
        character(len = *), intent(in) :: label
        integer, intent(inout) :: n_failed
        if (abs(actual-expected) <= tolerance) then
            write(*, '(a)') 'PASS: '//trim(label)
        else
            write(*, '(a)') 'FAIL: '//trim(label)
            write(*, '(a,es14.6)') '  actual   = ', actual
            write(*, '(a,es14.6)') '  expected = ', expected
            write(*, '(a,es14.6)') '  tolerance= ', tolerance
            n_failed = n_failed+1
        end if
    end subroutine check_close

    subroutine test_j01_faceflux(n_failed)
        integer, intent(inout) :: n_failed
        logical :: active(2, 1)
        integer :: face_type(4, 2, 1), ierr
        real :: density(2, 1), ur(2, 1), uz(2, 1), bin(4, 2, 1)
        real, allocatable :: fr(:, :), fz(:, :), bout(:, :, :)
        active = .true.
        face_type = J01_FACE_OPEN
        face_type(J01_R_HI, 1, 1) = J01_FACE_INTERIOR
        face_type(J01_R_LO, 2, 1) = J01_FACE_INTERIOR
        density(:, 1) = [2.0, 4.0]
        ur = 1.0
        uz = 0.0
        bin = 0.0
        call sub_J01_build_faceflux_2Drz(active, face_type, density, ur, uz, bin, &
            fr, fz, bout, ierr)
        call check(ierr == J01_SUCCESS, 'J01 2D r-z face-flux construction', n_failed)
        call check_close(fr(1, 1), 2.0, 1.0e-13, &
            'J01 Lax-Friedrichs internal face flux', n_failed)
        call check_close(bout(J01_R_HI, 2, 1), 4.0, 1.0e-13, &
            'J01 open-boundary outflow flux', n_failed)
    end subroutine test_j01_faceflux

    subroutine test_j02_contract(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_mesh_2drz_type) :: mesh
        type(sn_geometry_2drz_type) :: geom
        type(sn_quadrature_type) :: quad
        type(sn_boundary_2drz_type) :: boundary
        logical :: active(1, 1)
        real :: re(2), ze(2), nu(1, 1), pi, ein, eout, ndot
        real, allocatable :: sigma(:, :, :), pdf(:), bins(:), shape_pdf(:), shape_bins(:)
        real, allocatable :: psi(:, :, :, :), psi_sweep(:, :, :, :), prescribed(:, :, :, :), &
            fin(:, :, :), fout(:, :, :)
        integer :: ierr, m
        pi = acos(-1.0)
        re = [1.0, 2.0]
        ze = [0.0, 1.0]
        active = .true.
        call sub_J02_initialize_mesh(re, ze, active, mesh, ierr)
        call sub_J02_build_geometry(mesh, 2*pi, geom, ierr)
        call sub_J02_initialize_boundary_types(mesh, boundary, ierr)
        call sub_J02_build_phase_quadrature(8, 1, 'midpoint', 2.0, quad, ierr)
        nu = 3.0
        call sub_J02_build_sigma_from_frequency(quad, nu, sigma, ierr)
        call check(ierr == SN_SUCCESS, 'J02 ionization-frequency conversion', n_failed)
        call check_close(maxval(abs(sigma-3.0)), 0.0, 1.0e-13, &
            'J02 sigma_t equals nu/speed', n_failed)
        allocate(pdf(quad%n_dir), bins(quad%n_dir))
        pdf = 0.0
        do m = 1, quad%n_dir
            ndot = -quad%eta(m)
            if (ndot < 0.0) pdf(m) = real(m)
        end do
        bins = pdf*quad%weight
        call sub_J02_build_mc_crossing_pdf_inflow_shape(quad, 0.0, -1.0, pdf, shape_pdf, ierr)
        call sub_J02_build_mc_crossing_bins_inflow_shape(quad, 0.0, -1.0, bins, shape_bins, ierr)
        call check_close(maxval(abs(shape_pdf-shape_bins)), 0.0, 1.0e-13, &
            'continuous-PDF and weighted-bin MC definitions agree', n_failed)
        allocate(psi(3, 1, 1, quad%n_dir), prescribed(SN_N_FACES, 1, 1, quad%n_dir))
        psi = 0.0
        psi(1, :, :, :) = 2.0
        prescribed = 3.0
        call sub_J02_reconstruct_open_boundary_fluxes(mesh, geom, boundary, quad, psi, &
            prescribed, fin, fout, ierr)
        call check(ierr == SN_SUCCESS, 'J02 open-boundary flux reconstruction', n_failed)
        ein = 0.0
        eout = 0.0
        do m = 1, quad%n_dir
            ndot = -quad%eta(m)
            if (ndot < 0.0) ein = ein+quad%weight(m)*quad%speed(m)*quad%eta(m)*3.0
            if (ndot > 0.0) eout = eout+quad%weight(m)*quad%speed(m)*quad%eta(m)*2.0
        end do
        call check_close(fin(SN_Z_LO, 1, 1), ein, 1.0e-13, 'J02 signed boundary inflow', n_failed)
        call check_close(fout(SN_Z_LO, 1, 1), eout, 1.0e-13, 'J02 signed boundary outflow', n_failed)
        boundary%face_z_lo(1, 1) = SN_FACE_WALL
        call sub_J02_sweep_all_directions(mesh, geom, quad, sigma, prescribed, psi_sweep, &
            ierr, boundary = boundary)
        call check(ierr == SN_ERR_SWEEP_WALL_UNSUPPORTED, &
            'open-only J02 sweep requires the reflecting source-iteration interface for walls', &
            n_failed)
    end subroutine test_j02_contract

    subroutine test_j03_boundary_equilibrium(n_failed)
        integer, intent(inout) :: n_failed
        type(neutral_transport_closure_2drz_type) :: c1, c2
        real :: bin(4, 1, 1), bout(4, 1, 1), src(1, 1), change, resid, balance
        real, allocatable :: density(:, :)
        integer :: ierr, it
        logical :: converged
        bin = 0.0
        bout = 0.0
        bin(J03_Z_LO, 1, 1) = 2.0
        bout(J03_Z_HI, 1, 1) = 2.0
        call initialize_one_cell_from_flux(bin, bout, 0.0, c1, ierr, .false.)
        call initialize_one_cell_from_flux(bin, bout, 0.0, c2, ierr, .true.)
        call check_close(c1%boundary_outflow_velocity(J03_Z_HI, 1, 1), &
            c2%boundary_outflow_velocity(J03_Z_HI, 1, 1), 1.0e-14, &
            'J01 and J02 import paths create identical closure', n_failed)
        src = 0.0
        call sub_J03_solve_steady(c1, src, 0.8, 1.0e-13, 20, .true., density, converged, it, &
            change, resid, balance, ierr)
        call check(ierr == J03_SUCCESS .and. converged, 'J03 boundary equilibrium converges', n_failed)
        call check_close(density(1, 1), 2.0, 1.0e-12, 'J03 preserves balanced reference density', n_failed)
        call check_close(resid, 0.0, 1.0e-12, 'J03 balanced-boundary residual', n_failed)
    end subroutine test_j03_boundary_equilibrium

    subroutine initialize_one_cell_from_flux(bin, bout, loss, closure, ierr, use_j02)
        real, intent(in) :: bin(4, 1, 1), bout(4, 1, 1), loss
        type(neutral_transport_closure_2drz_type), intent(out) :: closure
        integer, intent(out) :: ierr
        logical, intent(in) :: use_j02
        logical :: active(1, 1)
        integer :: ft(4, 1, 1)
        real :: vol(1, 1), area(4, 1, 1), dens(1, 1), nu(1, 1), fr(0, 1), fz(1, 0)
        active = .true.
        ft = J03_FACE_WALL
        ft(J03_Z_LO, 1, 1) = J03_FACE_OPEN
        ft(J03_Z_HI, 1, 1) = J03_FACE_OPEN
        vol = 1.0
        area = 1.0
        dens = 2.0
        nu = loss
        if (use_j02) then
            call sub_J03_import_J02_closure(active, ft, vol, area, dens, fr, fz, bin, bout, nu, &
                1.0e-12, closure, ierr)
        else
            call sub_J03_import_J01_closure(active, ft, vol, area, dens, fr, fz, bin, bout, nu, &
                1.0e-12, closure, ierr)
        end if
    end subroutine initialize_one_cell_from_flux

    subroutine test_j03_ionization_equilibrium(n_failed)
        integer, intent(inout) :: n_failed
        type(neutral_transport_closure_2drz_type) :: closure
        real :: bin(4, 1, 1), bout(4, 1, 1), src(1, 1), change, resid, balance
        real, allocatable :: density(:, :)
        integer :: ierr, it
        logical :: converged
        bin = 0.0
        bout = 0.0
        call initialize_one_cell_from_flux(bin, bout, 2.0, closure, ierr, .true.)
        src = 4.0
        call sub_J03_solve_steady(closure, src, 0.8, 1.0e-12, 200, .true., density, converged, it, &
            change, resid, balance, ierr)
        call check(ierr == J03_SUCCESS .and. converged, 'J03 ionization case converges', n_failed)
        call check_close(density(1, 1), 2.0, 2.0e-11, 'J03 source-loss equilibrium S/nu', n_failed)
    end subroutine test_j03_ionization_equilibrium

    subroutine test_j03_closed_conservation(n_failed)
        integer, intent(inout) :: n_failed
        type(neutral_transport_closure_2drz_type) :: closure
        logical :: active(2, 1)
        integer :: ft(4, 2, 1), ierr
        real :: vol(2, 1), area(4, 2, 1), dens(2, 1), fr(1, 1), fz(2, 0), bin(4, 2, 1), &
            bout(4, 2, 1), nu(2, 1), src(2, 1)
        real, allocatable :: next(:, :)
        active = .true.
        ft = J03_FACE_WALL
        ft(J03_R_HI, 1, 1) = J03_FACE_INTERIOR
        ft(J03_R_LO, 2, 1) = J03_FACE_INTERIOR
        vol = 1.0
        area = 1.0
        dens(:, 1) = [1.0, 2.0]
        fr = 1.0
        bin = 0.0
        bout = 0.0
        nu = 0.0
        src = 0.0
        call sub_J03_initialize_transport_closure(active, ft, vol, area, dens, fr, fz, bin, bout, &
            nu, 1.0e-12, closure, ierr)
        call sub_J03_continuity_step(closure, dens, src, 0.1, .true., next, ierr)
        call check_close(sum(next), sum(dens), 1.0e-13, &
            'J03 closed-domain finite-volume conservation', n_failed)
    end subroutine test_j03_closed_conservation
end program test_J03_neutral_continuity_faceflux_2Drz
