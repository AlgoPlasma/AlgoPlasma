program test_J02_reflection_partial_inlet
    use mod_J02_neutral_sn_transport_2Drz
    implicit none
    integer :: n_failed
    n_failed = 0
    write(*, '(a)') '=== J02 reflection and partial-inlet tests ==='
    call test_partial_inlet_geometry(n_failed)
    call test_reflection_map(n_failed)
    call test_interval_operators(n_failed)
    call test_diffuse_normalization(n_failed)
    call test_mixed_reflection_linearity(n_failed)
    call test_partial_inlet_source_iteration(n_failed)
    call test_compact_zlo_inflow(n_failed)
    call test_reflection_errors(n_failed)
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
        if (.not. condition) then
            write(*, '(a)') 'FAIL: '//trim(label)
            n_failed = n_failed+1
        end if
    end subroutine check

    subroutine check_error(error, tolerance, label, n_failed)
        real, intent(in) :: error, tolerance
        character(len = *), intent(in) :: label
        integer, intent(inout) :: n_failed
        write(*, '(a,2es24.15)') 'METRIC: '//trim(label)//' error/limit: ', error, tolerance
        if (.not. (error <= tolerance)) then
            write(*, '(a)') 'FAIL: '//trim(label)
            n_failed = n_failed+1
        end if
    end subroutine check_error

    subroutine make_case(mesh, geometry, quadrature, boundary, sigma_t, prescribed, wall_shape)
        type(sn_mesh_2drz_type), intent(out) :: mesh
        type(sn_geometry_2drz_type), intent(out) :: geometry
        type(sn_quadrature_type), intent(out) :: quadrature
        type(sn_boundary_2drz_type), intent(out) :: boundary
        real, allocatable, intent(out) :: sigma_t(:, :, :), prescribed(:, :, :, :), wall_shape(:)
        real :: r_edge(2), z_edge(2), frequency(1, 1)
        logical :: active(1, 1)
        integer :: ierr
        r_edge = [1.0, 2.0]
        z_edge = [0.0, 1.0]
        active = .true.
        call sub_J02_initialize_mesh(r_edge, z_edge, active, mesh, ierr)
        call sub_J02_build_geometry(mesh, 2.0*acos(-1.0), geometry, ierr)
        call sub_J02_initialize_boundary_types(mesh, boundary, ierr)
        call sub_J02_build_phase_quadrature(8, 2, 'midpoint', 4.0, quadrature, ierr)
        frequency = 0.2
        call sub_J02_build_sigma_from_frequency(quadrature, frequency, sigma_t, ierr)
        call sub_J02_build_wall_maxwell_shape(quadrature, 4.0/9.0, &
            1.380649e-23, wall_shape, ierr)
        allocate(prescribed(SN_N_FACES, 1, 1, quadrature%n_dir))
        prescribed = 0.0
    end subroutine make_case

    subroutine test_partial_inlet_geometry(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_mesh_2drz_type) :: mesh
        real :: r_edge(3), z_edge(2)
        logical :: active(2, 1)
        real, allocatable :: fraction(:), xi_lo(:), xi_hi(:)
        integer :: ierr
        r_edge = [1.0, 2.0, 3.0]
        z_edge = [0.0, 1.0]
        active = .true.
        call sub_J02_initialize_mesh(r_edge, z_edge, active, mesh, ierr)
        call sub_J02_build_partial_zlo_inlet(mesh, 1.5, 2.5, fraction, xi_lo, xi_hi, ierr)
        call check(ierr == SN_SUCCESS, 'partial inlet geometry accepts a two-cell band', n_failed)
        call check_error(maxval(abs(fraction-[7.0/12.0, 0.45])), 1.0e-14, &
            'partial inlet uses cylindrical area fractions', n_failed)
        call check_error(maxval(abs(xi_lo-[0.0, -1.0]))+ &
            maxval(abs(xi_hi-[1.0, 0.0])), 1.0e-14, &
            'partial inlet reports local xi intervals', n_failed)
        active(1, 1) = .false.
        call sub_J02_initialize_mesh(r_edge, z_edge, active, mesh, ierr)
        call sub_J02_build_partial_zlo_inlet(mesh, 1.1, 1.9, fraction, xi_lo, xi_hi, ierr)
        call check(ierr == SN_ERR_PARTIAL_INLET, &
            'partial inlet rejects overlap with inactive z-low cells only', n_failed)
    end subroutine test_partial_inlet_geometry

    subroutine test_reflection_map(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_quadrature_type) :: quadrature
        integer :: ierr, m, q
        real :: error
        call sub_J02_build_phase_quadrature(8, 2, 'midpoint', 4.0, quadrature, ierr)
        error = 0.0
        do m = 1, quadrature%n_dir
            q = fun_J02_reflected_direction_index(quadrature, m, 1.0, 0.0)
            error = max(error, abs(quadrature%mu(q)+quadrature%mu(m)), &
                abs(quadrature%eta(q)-quadrature%eta(m)), &
                abs(quadrature%speed(q)-quadrature%speed(m)))
            q = fun_J02_reflected_direction_index(quadrature, m, 0.0, 1.0)
            error = max(error, abs(quadrature%mu(q)-quadrature%mu(m)), &
                abs(quadrature%eta(q)+quadrature%eta(m)), &
                abs(quadrature%speed(q)-quadrature%speed(m)))
        end do
        call check_error(error, 2.0e-15, &
            'specular map reverses only the normal velocity in each speed group', n_failed)
    end subroutine test_reflection_map

    subroutine test_interval_operators(n_failed)
        integer, intent(inout) :: n_failed
        real :: full_rhs(3), interval_rhs(3), m0, m1, m2
        full_rhs = 0.0
        interval_rhs = 0.0
        call sub_J02_add_constant_rhs(full_rhs, SN_Z_LO, 0.7, 2.3, 2.0, 0.5, 0.4)
        call sub_J02_add_zface_constant_interval_rhs(interval_rhs, 0.7, 2.3, -1.0, &
            -1.0, 1.0, 2.0, 0.5)
        call check_error(maxval(abs(full_rhs-interval_rhs)), 1.0e-14, &
            'full z-face interval equals the established full-face operator', n_failed)
        call sub_J02_zface_interval_moments(2.0, 0.5, -0.5, 0.5, m0, m1, m2)
        call check_error(abs(m0-1.0)+abs(m1-1.0/48.0)+abs(m2-1.0/12.0), &
            1.0e-14, 'partial interval cylindrical moments are analytic', n_failed)
    end subroutine test_interval_operators

    subroutine test_diffuse_normalization(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_mesh_2drz_type) :: mesh
        type(sn_geometry_2drz_type) :: geometry
        type(sn_quadrature_type) :: quadrature
        type(sn_boundary_2drz_type) :: boundary
        real, allocatable :: sigma_t(:, :, :), prescribed(:, :, :, :), wall_shape(:)
        real, allocatable :: psi_old(:, :, :, :), constant(:, :, :)
        real :: outgoing, incoming, ndot, trace
        integer :: ierr, m
        call make_case(mesh, geometry, quadrature, boundary, sigma_t, prescribed, wall_shape)
        boundary%face_z_hi = SN_FACE_WALL
        allocate(psi_old(3, 1, 1, quadrature%n_dir))
        psi_old = 0.0
        do m = 1, quadrature%n_dir
            psi_old(:, 1, 1, m) = [2.0+0.03*m, 0.1, -0.2]
        end do
        call sub_J02_compute_diffuse_wall_constants(mesh, geometry, quadrature, boundary, &
            wall_shape, psi_old, constant, ierr)
        outgoing = 0.0
        incoming = 0.0
        do m = 1, quadrature%n_dir
            ndot = quadrature%eta(m)
            if (ndot > 0.0) then
                trace = psi_old(1, 1, 1, m)+geometry%xi_bar(1)*psi_old(2, 1, 1, m)+ &
                    psi_old(3, 1, 1, m)
                outgoing = outgoing+quadrature%weight(m)*quadrature%speed(m)*ndot*trace
            else if (ndot < 0.0) then
                incoming = incoming+quadrature%weight(m)*quadrature%speed(m)*(-ndot)* &
                    constant(SN_Z_HI, 1, 1)*wall_shape(m)
            end if
        end do
        call check(ierr == SN_SUCCESS, 'diffuse wall constant construction', n_failed)
        write(*,'(a,2es24.15)') 'VALUE: diffuse wall outgoing/returning flux: ',outgoing,incoming
        call check_error(abs(outgoing-incoming), 2.0e-13, &
            'diffuse reflection conserves discrete wall number flux', n_failed)
    end subroutine test_diffuse_normalization

    subroutine test_mixed_reflection_linearity(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_mesh_2drz_type) :: mesh
        type(sn_geometry_2drz_type) :: geometry
        type(sn_quadrature_type) :: quadrature
        type(sn_boundary_2drz_type) :: boundary
        real, allocatable :: sigma_t(:, :, :), prescribed(:, :, :, :), wall_shape(:)
        real, allocatable :: psi_old(:, :, :, :), specular(:, :, :, :), diffuse(:, :, :, :), mixed(:, :, :, :)
        integer :: ierr, m
        call make_case(mesh, geometry, quadrature, boundary, sigma_t, prescribed, wall_shape)
        boundary%face_r_lo = SN_FACE_WALL
        boundary%face_z_hi = SN_FACE_WALL
        allocate(psi_old(3, 1, 1, quadrature%n_dir))
        do m = 1, quadrature%n_dir
            psi_old(:, 1, 1, m) = [1.0+0.02*m, 0.03*m, -0.01*m]
        end do
        call sub_J02_sweep(mesh, geometry, quadrature, sigma_t, boundary, specular, ierr, &
            boundary_inflow=prescribed, wall_shape=wall_shape, diffuse_fraction=0.0, &
            psi_old=psi_old)
        call sub_J02_sweep(mesh, geometry, quadrature, sigma_t, boundary, diffuse, ierr, &
            boundary_inflow=prescribed, wall_shape=wall_shape, diffuse_fraction=1.0, &
            psi_old=psi_old)
        call sub_J02_sweep(mesh, geometry, quadrature, sigma_t, boundary, mixed, ierr, &
            boundary_inflow=prescribed, wall_shape=wall_shape, diffuse_fraction=0.35, &
            psi_old=psi_old)
        call check(ierr == SN_SUCCESS, 'mixed reflecting sweep executes', n_failed)
        call check_error(maxval(abs(mixed-(0.65*specular+0.35*diffuse))), 3.0e-13, &
            'one sweep mixes specular and diffuse boundary operators linearly', n_failed)
    end subroutine test_mixed_reflection_linearity

    subroutine test_partial_inlet_source_iteration(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_mesh_2drz_type) :: mesh
        type(sn_geometry_2drz_type) :: geometry
        type(sn_quadrature_type) :: quadrature
        type(sn_boundary_2drz_type) :: boundary
        real, allocatable :: sigma_t(:, :, :), prescribed(:, :, :, :), wall_shape(:), psi(:, :, :, :)
        real, allocatable :: density(:, :), ur(:, :), uz(:, :), fin(:, :, :), fout(:, :, :)
        real :: xi_lo(1), xi_hi(1), change, balance, area
        integer :: ierr, m, iterations, fd, fi, fk
        logical :: converged
        call make_case(mesh, geometry, quadrature, boundary, sigma_t, prescribed, wall_shape)
        boundary%face_r_lo = SN_FACE_WALL
        boundary%face_r_hi = SN_FACE_WALL
        boundary%face_z_hi = SN_FACE_WALL
        xi_lo = -0.5
        xi_hi = 0.5
        do m = 1, quadrature%n_dir
            if (quadrature%eta(m) > 0.0) prescribed(SN_Z_LO, 1, 1, m) = 1.0
        end do
        call sub_J02_solve_source_iteration(mesh, geometry, quadrature, sigma_t, prescribed, &
            boundary, wall_shape, 0.7, 800, 1.0e-14, psi, converged, iterations, change, ierr, &
            fd, fi, fk, xi_lo, xi_hi)
        write(*,'(a,i6,es24.15)') 'VALUE: partial reflection iterations/change: ',iterations,change
        call check(ierr == SN_SUCCESS .and. converged, &
            'partial-inlet reflecting source iteration converges', n_failed)
        call check(iterations > 2 .and. change <= 1.0e-14, &
            'source iteration reports a nontrivial converged history', n_failed)
        call sub_J02_reconstruct_cell_moments(mesh, geometry, quadrature, psi, density, ur, uz, ierr)
        call check(all(psi(1,:,:,:) >= abs(psi(2,:,:,:))+abs(psi(3,:,:,:))), &
            'reflecting solution is nonnegative at every polynomial corner', n_failed)
        call check(all(density >= 0.0), 'reflecting solution has nonnegative density', n_failed)
        call sub_J02_reconstruct_open_boundary_fluxes(mesh, geometry, boundary, quadrature, &
            psi, prescribed, fin, fout, ierr, xi_lo, xi_hi)
        area = geometry%area_z_lo(1, 1)
        balance = -area*(fin(SN_Z_LO, 1, 1)+fout(SN_Z_LO, 1, 1))+ &
            0.2*density(1, 1)*geometry%volume(1, 1)
        write(*,'(a,4es24.15)') 'VALUE: partial reflection incoming/outgoing/loss/min corner: ', &
            area*fin(SN_Z_LO,1,1),-area*fout(SN_Z_LO,1,1), &
            0.2*density(1,1)*geometry%volume(1,1),minval(psi(1,:,:,:)-abs(psi(2,:,:,:))-abs(psi(3,:,:,:)))
        call check_error(abs(balance), 2.0e-10, &
            'partial open inlet plus reflecting complement satisfies global balance', n_failed)
        call check_error(abs(fin(SN_Z_LO, 1, 1)-0.5*sum(quadrature%weight* &
            quadrature%speed*quadrature%eta, mask = quadrature%eta > 0.0)), 2.0e-13, &
            'partial inlet reconstruction applies its cylindrical area fraction', n_failed)
    end subroutine test_partial_inlet_source_iteration

    subroutine test_compact_zlo_inflow(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_mesh_2drz_type) :: mesh
        type(sn_geometry_2drz_type) :: geometry
        type(sn_quadrature_type) :: quadrature
        type(sn_boundary_2drz_type) :: boundary
        real, allocatable :: sigma_t(:, :, :), prescribed(:, :, :, :), wall_shape(:)
        real, allocatable :: psi_old(:, :, :, :), psi_full(:, :, :, :), psi_compact(:, :, :, :)
        real, allocatable :: fin_full(:, :, :), fout_full(:, :, :), fin_compact(:, :, :), fout_compact(:, :, :)
        real, allocatable :: zlo(:)
        integer :: ierr, m
        call make_case(mesh, geometry, quadrature, boundary, sigma_t, prescribed, wall_shape)
        allocate(psi_old(3, 1, 1, quadrature%n_dir), zlo(quadrature%n_dir))
        psi_old = 0.0
        zlo = 0.0
        do m = 1, quadrature%n_dir
            if (quadrature%eta(m) > 0.0) then
                zlo(m) = 1.0+0.01*m
                prescribed(SN_Z_LO, 1, 1, m) = zlo(m)
            end if
        end do
        call sub_J02_sweep(mesh, geometry, quadrature, sigma_t, boundary, psi_full, ierr, &
            boundary_inflow=prescribed, wall_shape=wall_shape, diffuse_fraction=0.5, &
            psi_old=psi_old)
        call sub_J02_sweep(mesh, geometry, quadrature, sigma_t, boundary, psi_compact, ierr, &
            wall_shape=wall_shape, diffuse_fraction=0.5, psi_old=psi_old, zlo_inflow=zlo)
        call check_error(maxval(abs(psi_full-psi_compact)), 2.0e-13, &
            'compact z-low inlet gives the same sweep as the full boundary array', n_failed)
        call sub_J02_reconstruct_open_boundary_fluxes(mesh, geometry, boundary, quadrature, &
            psi_full, prescribed, fin_full, fout_full, ierr)
        call sub_J02_reconstruct_open_boundary_fluxes(mesh = mesh, geometry = geometry, &
            boundary = boundary, quadrature = quadrature, psi = psi_compact, inflow_flux = fin_compact, &
            outflow_flux = fout_compact, ierr = ierr, zlo_inflow = zlo)
        call check_error(maxval(abs(fin_full-fin_compact))+maxval(abs(fout_full-fout_compact)), &
            2.0e-13, 'compact z-low inlet gives the same reconstructed flux', n_failed)
    end subroutine test_compact_zlo_inflow

    subroutine test_reflection_errors(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_mesh_2drz_type) :: mesh
        type(sn_geometry_2drz_type) :: geometry
        type(sn_quadrature_type) :: quadrature
        type(sn_boundary_2drz_type) :: boundary
        real, allocatable :: sigma_t(:, :, :), prescribed(:, :, :, :), wall_shape(:)
        real, allocatable :: psi_old(:, :, :, :), psi(:, :, :, :)
        integer :: ierr, dummy_iterations
        real :: dummy_change
        logical :: dummy_converged
        call make_case(mesh, geometry, quadrature, boundary, sigma_t, prescribed, wall_shape)
        boundary%face_r_lo = SN_FACE_WALL
        allocate(psi_old(3, 1, 1, quadrature%n_dir))
        psi_old = 0.0
        call sub_J02_sweep(mesh, geometry, quadrature, sigma_t, boundary, psi, ierr, &
            boundary_inflow=prescribed, wall_shape=wall_shape, diffuse_fraction=1.1, &
            psi_old=psi_old)
        call check(ierr == SN_ERR_REFLECTION_INPUT, &
            'diffuse fraction outside [0,1] returns a specific error', n_failed)
        call sub_J02_solve_source_iteration(mesh, geometry, quadrature, sigma_t, prescribed, &
            boundary, wall_shape, 0.5, 1, 1.0e-12, psi, dummy_converged, dummy_iterations, &
            dummy_change, ierr)
        call check(ierr == SN_ERR_SOURCE_ITERATION_OPTIONS, &
            'invalid source-iteration options return a specific error', n_failed)
    end subroutine test_reflection_errors
end program test_J02_reflection_partial_inlet
