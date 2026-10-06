program test_J02_neutral_sn_transport_2Drz
    use mod_J02_neutral_sn_transport_2Drz
    implicit none
    type(sn_boundary_2drz_type) :: sweep_boundary

    integer :: n_failed
    n_failed = 0

    write(*, '(a)') '=== J02 neutral SN transport tests ==='
    call test_quadrature(n_failed)
    call test_geometry(n_failed)
    call test_local_volume_operator(n_failed)
    call test_inflow_normalization(n_failed)
    call test_source_shapes(n_failed)
    call test_error_diagnostics(n_failed)
    call test_reconstruction(n_failed)

    write(*, '(a,i0)') 'n_failed = ', n_failed
    if (n_failed == 0) then
        write(*, '(a)') 'RESULT: PASS'
    else
        write(*, '(a)') 'RESULT: FAIL'
        error stop 1
    end if

contains

    ! Report numerical evidence even when the existing assertion passes.
    subroutine value(label, actual, reference, limit)
        character(len=*), intent(in) :: label
        real, intent(in) :: actual, reference, limit
        write(*,'(a,4es24.15)') 'VALUE: '//label//' actual/reference/error/limit: ', &
            actual, reference, abs(actual-reference), limit
    end subroutine value


    subroutine check(condition, label, n_failed)
        logical, intent(in) :: condition
        character(len = *), intent(in) :: label
        integer, intent(inout) :: n_failed
        if (.not. condition) then
            write(*, '(a)') 'FAIL: '//trim(label)
            n_failed = n_failed + 1
        end if
    end subroutine check

    subroutine check_ierr(ierr, expected_ierr, label, n_failed)
        integer, intent(in) :: ierr, expected_ierr
        character(len = *), intent(in) :: label
        integer, intent(inout) :: n_failed

        write(*,'(a,2i8)') 'STATUS: '//trim(label)//' actual/expected: ', ierr, expected_ierr
        if (ierr /= expected_ierr) then
            write(*, '(a)') 'FAIL: '//trim(label)
            write(*, '(a,i0,2a)') '  actual ierr = ', ierr, ': ', &
                trim(fun_J02_error_message(ierr))
            write(*, '(a,i0,2a)') '  expected ierr = ', expected_ierr, ': ', &
                trim(fun_J02_error_message(expected_ierr))
            n_failed = n_failed+1
        end if
    end subroutine check_ierr

    subroutine test_quadrature(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_quadrature_type) :: quad
        integer :: ierr
        real :: pi, expected
        real, allocatable :: midpoint_mu(:), midpoint_eta(:), midpoint_weight(:)

        pi = acos(-1.0)
        call sub_J02_build_phase_quadrature(8, 2, 'midpoint', 4.0, quad, ierr)
        expected = pi*4.0**2
        call check_ierr(ierr, SN_SUCCESS, 'phase quadrature construction', n_failed)
        call check(quad%n_dir == 16, 'flattened speed-angle direction count', n_failed)
        call check(abs(sum(quad%weight)-expected) < 1.0e-12, &
            'phase weights integrate v dv dtheta', n_failed)
        call check(abs(sum(quad%weight*quad%mu)) < 1.0e-13 .and. &
            abs(sum(quad%weight*quad%eta)) < 1.0e-13, &
            'angular first moments are symmetric', n_failed)
        call value('quadrature weight sum',sum(quad%weight),expected,1.e-12)
        call value('quadrature mu moment',sum(quad%weight*quad%mu),0.0,1.e-13)
        call value('quadrature eta moment',sum(quad%weight*quad%eta),0.0,1.e-13)
        midpoint_mu = quad%mu
        midpoint_eta = quad%eta
        midpoint_weight = quad%weight
        call sub_J02_build_phase_quadrature(8, 2, 'gauss-chebyshev', &
            4.0, quad, ierr)
        call check(ierr == SN_SUCCESS .and. &
            maxval(abs(quad%mu-midpoint_mu)) < tiny(1.0) .and. &
            maxval(abs(quad%eta-midpoint_eta)) < tiny(1.0) .and. &
            maxval(abs(quad%weight-midpoint_weight)) < tiny(1.0), &
            'Gauss-Chebyshev is an exact alias of midpoint nodes', n_failed)
        call value('quadrature alias max difference',max(maxval(abs(quad%mu-midpoint_mu)), &
            maxval(abs(quad%eta-midpoint_eta)),maxval(abs(quad%weight-midpoint_weight))),0.0,0.0)
    end subroutine test_quadrature

    subroutine test_geometry(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_mesh_2drz_type) :: mesh
        type(sn_geometry_2drz_type) :: geometry
        real :: r_edge(3), z_edge(2), pi
        logical :: active(2, 1)
        integer :: ierr

        pi = acos(-1.0)
        r_edge = [1.0, 2.0, 4.0]
        z_edge = [0.0, 2.0]
        active = .true.
        call sub_J02_initialize_mesh(r_edge, z_edge, active, mesh, ierr)
        call check_ierr(ierr, SN_SUCCESS, 'mesh validation', n_failed)
        call sub_J02_build_geometry(mesh, 2*pi, geometry, ierr)
        call check_ierr(ierr, SN_SUCCESS, 'cylindrical geometry construction', n_failed)
        call check(abs(geometry%volume(1, 1)-6*pi) < 1.0e-12, &
            'annular cell volume', n_failed)
        call check(abs(geometry%area_r_lo(1, 1)-4*pi) < 1.0e-12 .and. &
            abs(geometry%area_r_hi(1, 1)-8*pi) < 1.0e-12, &
            'radial face areas', n_failed)
        call check(abs(geometry%xi_bar(1)-1.0/9.0) < 1.0e-14, &
            'cylindrical radial mean correction', n_failed)
        call value('annular volume',geometry%volume(1,1),6*pi,1.e-12)
        call value('radial low area',geometry%area_r_lo(1,1),4*pi,1.e-12)
        call value('radial high area',geometry%area_r_hi(1,1),8*pi,1.e-12)
        call value('radial mean correction',geometry%xi_bar(1),1.0/9.0,1.e-14)
    end subroutine test_geometry

    subroutine test_local_volume_operator(n_failed)
        integer, intent(inout) :: n_failed
        real :: a(3, 3), expected(3, 3)

        a = 0.0
        expected = 0.0
        call sub_J02_add_volume_matrix(a, 0.3, -0.4, &
            2.0, 0.5, 0.25)
        expected(2, 1) = -0.6
        expected(2, 2) = -0.05
        expected(3, 1) = 1.6
        expected(3, 2) = 2.0/15.0
        call check(maxval(abs(a-expected)) < 1.0e-14, &
            'cylindrical P1-DG volume matrix entries', n_failed)
        call value('streaming matrix max error',maxval(abs(a-expected)),0.0,1.e-14)
    end subroutine test_local_volume_operator

    subroutine test_inflow_normalization(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_quadrature_type) :: quad
        real, allocatable :: inflow_shape(:), psi_in(:)
        real :: flux, ndot
        integer :: ierr, m

        call sub_J02_build_phase_quadrature(8, 2, 'midpoint', 4.0, quad, ierr)
        allocate(inflow_shape(quad%n_dir))
        inflow_shape = 1.0
        call sub_J02_normalize_inflow_flux(quad, 0.0, -1.0, &
            7.0, inflow_shape, psi_in, ierr)
        call check_ierr(ierr, SN_SUCCESS, 'prescribed inflow normalization call', n_failed)
        flux = 0.0
        do m = 1, quad%n_dir
            ndot = -quad%eta(m)
            if (ndot < 0.0) flux = flux+quad%weight(m)*quad%speed(m)*(-ndot)*psi_in(m)
        end do
        call check(abs(flux-7.0) < 1.0e-12, &
            'prescribed open-boundary flux normalization', n_failed)
        call value('constant-shape inlet flux',flux,7.0,1.e-12)
    end subroutine test_inflow_normalization

    subroutine test_source_shapes(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_quadrature_type) :: quad
        real, allocatable :: inflow_shape(:), drifted_shape(:), psi_in(:)
        real, allocatable :: crossing_probability(:), crossing_shape(:)
        real :: temperature, particle_mass, alpha, expected, flux, ndot, contribution
        integer :: ierr, m

        temperature = 300.0
        particle_mass = 6.6335209e-26
        call sub_J02_build_phase_quadrature(8, 4, 'midpoint', 2000.0, quad, ierr)
        call check_ierr(ierr, SN_SUCCESS, 'source-test quadrature construction', n_failed)

        call sub_J02_build_drifted_maxwellian_inflow_shape(quad, temperature, particle_mass, 0.0, 0.0, &
            inflow_shape, ierr)
        call check_ierr(ierr, SN_SUCCESS, 'two-dimensional Maxwell shape construction', &
            n_failed)
        alpha = particle_mass/(2.0*1.380649e-23*temperature)
        expected = alpha/acos(-1.0)*exp(-alpha*quad%speed(1)**2)
        call check(abs(inflow_shape(1)-expected) <= 1.0e-13*expected .and. &
            maxval(abs(inflow_shape(1:8)-inflow_shape(1))) <= 1.0e-13*expected, &
            'zero-drift Maxwell shape is isotropic and follows the 2D formula', n_failed)

        call value('Maxwell shape at first velocity',inflow_shape(1),expected,1.e-13*expected)
        call value('Maxwell isotropy max difference',maxval(abs(inflow_shape(1:8)-inflow_shape(1))), &
            0.0,1.e-13*expected)

        call sub_J02_build_drifted_maxwellian_inflow_shape(quad, temperature, &
            particle_mass, 300.0, 0.0, drifted_shape, ierr)
        call check_ierr(ierr, SN_SUCCESS, 'drifted Maxwell shape construction', n_failed)
        call check(drifted_shape(1) > drifted_shape(4) .and. &
            drifted_shape(8) > drifted_shape(5), &
            'positive radial drift biases the Maxwell shape toward positive mu', n_failed)
        call sub_J02_normalize_inflow_flux(quad, 0.0, -1.0, 12.0, drifted_shape, &
            psi_in, ierr)
        call check_ierr(ierr, SN_SUCCESS, 'drifted reservoir normalization call', n_failed)
        flux = 0.0
        do m = 1, quad%n_dir
            ndot = -quad%eta(m)
            if (ndot < 0.0) flux = flux+quad%weight(m)*quad%speed(m)*(-ndot)*psi_in(m)
        end do
        call check(abs(flux-12.0) < 1.0e-12, &
            'drifted reservoir shape normalizes to the requested flux', n_failed)

        call value('drifted inlet flux',flux,12.0,1.e-12)
        write(*,'(a,4es24.15)') 'VALUE: drift shapes directions 1/4/8/5: ', &
            drifted_shape(1),drifted_shape(4),drifted_shape(8),drifted_shape(5)
        allocate(crossing_probability(quad%n_dir))
        crossing_probability = 0.0
        crossing_probability(1:4) = [1.0, 2.0, 3.0, 4.0]
        call sub_J02_build_mc_crossing_bins_inflow_shape(quad, 0.0, -1.0, &
            crossing_probability, crossing_shape, ierr)
        call check_ierr(ierr, SN_SUCCESS, 'MC crossing-sampled shape conversion', n_failed)
        call sub_J02_normalize_inflow_flux(quad, 0.0, -1.0, 10.0, crossing_shape, &
            psi_in, ierr)
        call check_ierr(ierr, SN_SUCCESS, 'MC crossing-sampled shape normalization', &
            n_failed)
        flux = 0.0
        do m = 1, 4
            ndot = -quad%eta(m)
            contribution = quad%weight(m)*quad%speed(m)*(-ndot)*psi_in(m)
            flux = max(flux, abs(contribution-crossing_probability(m)))
        end do
        call check(flux < 1.0e-12, &
            'MC conversion preserves incoming discrete-bin flux probabilities', n_failed)
        call value('crossing-bin flux max error',flux,0.0,1.e-12)
    end subroutine test_source_shapes

    subroutine test_error_diagnostics(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_quadrature_type) :: quad
        type(sn_mesh_2drz_type) :: mesh
        type(sn_geometry_2drz_type) :: geometry
        real, allocatable :: inflow_shape(:), sigma_t(:, :, :), boundary(:, :, :, :), psi(:, :, :, :)
        real :: r_edge(2), z_edge(2), pi
        logical :: active(1, 1)
        integer :: ierr, failed_direction, failed_i, failed_k

        call sub_J02_build_phase_quadrature(8, 1, 'midpoint', 2.0, quad, ierr)
        call sub_J02_build_drifted_maxwellian_inflow_shape(quad, 0.0, 1.0, 0.0, 0.0, inflow_shape, ierr)
        call check_ierr(ierr, SN_ERR_SOURCE_TEMPERATURE, &
            'invalid temperature returns a specific error', n_failed)
        call check(index(fun_J02_error_message(ierr), 'temperature') > 0, &
            'error code maps to a specific human-readable message', n_failed)

        pi = acos(-1.0)
        r_edge = [1.0, 2.0]
        z_edge = [0.0, 1.0]
        active = .true.
        call sub_J02_initialize_mesh(r_edge, z_edge, active, mesh, ierr)
        call sub_J02_build_geometry(mesh, 2*pi, geometry, ierr)
! Preserve valid array extents but force the first local matrix singular.
        geometry%hr = 0.0
        geometry%hz = 0.0
        allocate(sigma_t(1, 1, quad%n_dir), boundary(4, 1, 1, quad%n_dir))
        sigma_t = 0.0
        boundary = 0.0
        call sub_J02_initialize_boundary_types(mesh, sweep_boundary, ierr)
        call sub_J02_sweep(mesh, geometry, quad, sigma_t, sweep_boundary, psi, ierr, &
            boundary_inflow=boundary, failed_direction=failed_direction, failed_i=failed_i, &
            failed_k=failed_k)
        call check_ierr(ierr, SN_ERR_SWEEP_LOCAL_SOLVE, &
            'sweep local-solve failure returns a specific error', n_failed)
        call check(failed_direction == 1 .and. failed_i == 1 .and. failed_k == 1, &
            'sweep reports failed direction and cell indices separately', n_failed)
        write(*,'(a,3i8)') 'STATUS: failed direction/i/k: ',failed_direction,failed_i,failed_k
    end subroutine test_error_diagnostics

    subroutine test_reconstruction(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_mesh_2drz_type) :: mesh
        type(sn_geometry_2drz_type) :: geometry
        type(sn_quadrature_type) :: quad
        real :: r_edge(3), z_edge(3), pi, mean_value, expected
        logical :: active(2, 2)
        real, allocatable :: psi(:, :, :, :), density(:, :), ur(:, :), uz(:, :)
        real, allocatable :: flux_r(:, :), flux_z(:, :)
        integer :: ierr

        pi = acos(-1.0)
        r_edge = [1.0, 2.0, 3.0]
        z_edge = [0.0, 1.0, 2.0]
        active = .true.
        call sub_J02_initialize_mesh(r_edge, z_edge, active, mesh, ierr)
        call sub_J02_build_geometry(mesh, 2*pi, geometry, ierr)
        call sub_J02_build_phase_quadrature(8, 1, 'midpoint', 2.0, quad, ierr)
        allocate(psi(3, mesh%nr, mesh%nz, quad%n_dir))
        psi = 0.0
        psi(:, 1, 1, 1) = [2.0, 3.0, 4.0]

        call sub_J02_reconstruct_cell_moments(mesh, geometry, quad, psi, density, ur, uz, ierr)
        call check_ierr(ierr, SN_SUCCESS, 'cell-moment reconstruction call', n_failed)
        mean_value = 2.0+geometry%xi_bar(1)*3.0
        expected = quad%weight(1)*mean_value
        call check(abs(density(1, 1)-expected) < 1.0e-13 .and. &
            maxval(abs(density(2:2, :))) < 1.0e-13 .and. &
            abs(density(1, 2)) < 1.0e-13, &
            'cylindrical cell-moment reconstruction', n_failed)
        call check(abs(ur(1, 1)-quad%speed(1)*quad%mu(1)) < 1.0e-13 .and. &
            abs(uz(1, 1)-quad%speed(1)*quad%eta(1)) < 1.0e-13, &
            'mean-velocity reconstruction', n_failed)

        call value('reconstructed density',density(1,1),expected,1.e-13)
        call value('reconstructed radial velocity',ur(1,1),quad%speed(1)*quad%mu(1),1.e-13)
        call value('reconstructed axial velocity',uz(1,1),quad%speed(1)*quad%eta(1),1.e-13)

        call sub_J02_reconstruct_internal_face_fluxes(mesh, geometry, quad, psi, flux_r, flux_z, ierr)
        call check_ierr(ierr, SN_SUCCESS, 'face-flux reconstruction call', n_failed)
        expected = quad%weight(1)*quad%speed(1)*quad%mu(1)*5.0
        call check(abs(flux_r(1, 1)-expected) < 1.0e-13, &
            'radial upwind face-flux reconstruction', n_failed)
        call value('radial face flux',flux_r(1,1),expected,1.e-13)
        expected = quad%weight(1)*quad%speed(1)*quad%eta(1)* &
            (mean_value+4.0)
        call check(abs(flux_z(1, 1)-expected) < 1.0e-13, &
            'axial upwind face-flux reconstruction', n_failed)
        call value('axial face flux',flux_z(1,1),expected,1.e-13)
    end subroutine test_reconstruction

end program test_J02_neutral_sn_transport_2Drz
