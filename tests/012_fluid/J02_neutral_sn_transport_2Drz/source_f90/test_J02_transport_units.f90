! Local J02 geometry, loss, DG and reconstruction checks (no J03 dependency).
program test_J02_transport_units
    use mod_J02_neutral_sn_transport_2Drz
    implicit none
    type(sn_boundary_2drz_type) :: sweep_boundary
    integer :: n_failed
    n_failed = 0
    write(*, '(a)') '=== J02 neutral SN transport unit tests ==='
    call test_axis_geometry(n_failed)
    call test_face_topology(n_failed)
    call test_partial_inlet_boundary(n_failed)
    call test_absorption_matrix(n_failed)
    call test_frequency_conversion(n_failed)
    call test_crossing_representations(n_failed)
    call test_four_boundary_signs(n_failed)
    call test_negative_sigma_error(n_failed)
    write(*, '(a,i0)') 'n_failed = ', n_failed
    if (n_failed == 0) then
        write(*, '(a)') 'RESULT: PASS'
    else
        write(*, '(a)') 'RESULT: FAIL'
        error stop 1
    end if
contains
    subroutine close(actual, expected, tol, label, n_failed)
        real, intent(in) :: actual, expected, tol
        character(len = *), intent(in) :: label
        integer, intent(inout) :: n_failed
        write(*, '(a,4es24.15)') 'VALUE: '//trim(label)//' actual/reference/error/limit: ', &
            actual, expected, abs(actual-expected), tol
        if (.not. (abs(actual-expected) <= tol)) then
            write(*, '(a)') 'FAIL: '//trim(label)
            n_failed = n_failed+1
        end if
    end subroutine close
    subroutine truth(condition, label, n_failed)
        logical, intent(in) :: condition
        character(len = *), intent(in) :: label
        integer, intent(inout) :: n_failed
        if (.not. condition) then
            write(*, '(a)') 'FAIL: '//trim(label)
            n_failed = n_failed+1
        end if
    end subroutine truth

    subroutine test_axis_geometry(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_mesh_2drz_type) :: mesh
        type(sn_geometry_2drz_type) :: geom
        logical :: active(1, 1)
        real :: re(2), ze(2), pi
        integer :: ierr
        pi = acos(-1.0)
        re = [0.0, 1.0]
        ze = [0.0, 2.0]
        active = .true.
        call sub_J02_initialize_mesh(re, ze, active, mesh, ierr)
        call sub_J02_build_geometry(mesh, 2*pi, geom, ierr)
        call truth(ierr == SN_SUCCESS, 'axis-touching cell geometry is accepted', n_failed)
        call close(geom%area_r_lo(1, 1), 0.0, 1.0e-14, 'axis radial-face area is zero', n_failed)
        call close(geom%volume(1, 1), 2*pi, 1.0e-13, 'axis annular-cell volume', n_failed)
        call close(geom%xi_bar(1), 1.0/3.0, 1.0e-14, 'axis radial mean correction', n_failed)
    end subroutine test_axis_geometry

    subroutine test_face_topology(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_mesh_2drz_type) :: mesh
        type(sn_boundary_2drz_type) :: boundary
        logical :: active(2, 1)
        real :: re(3), ze(2)
        integer :: ierr
        re = [0.0, 1.0, 2.0]
        ze = [0.0, 1.0]
        active = .true.
        call sub_J02_initialize_mesh(re, ze, active, mesh, ierr)
        call sub_J02_initialize_boundary_types(mesh, boundary, ierr)
        call truth(boundary%face_r_hi(1, 1) == SN_FACE_INTERIOR .and. &
            boundary%face_r_lo(2, 1) == SN_FACE_INTERIOR, &
            'active neighbors create matching internal faces', n_failed)
        call truth(boundary%face_r_lo(1, 1) == SN_FACE_OPEN .and. &
            boundary%face_r_hi(2, 1) == SN_FACE_OPEN, &
            'domain edges default to open faces', n_failed)
        active(2, 1) = .false.
        call sub_J02_initialize_mesh(re, ze, active, mesh, ierr)
        call sub_J02_initialize_boundary_types(mesh, boundary, ierr)
        call truth(boundary%face_r_hi(1, 1) == SN_FACE_WALL, &
            'an inactive neighboring cell creates a reflecting wall', n_failed)
    end subroutine test_face_topology

    subroutine test_partial_inlet_boundary(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_mesh_2drz_type) :: mesh
        type(sn_boundary_2drz_type) :: boundary
        logical :: active(2, 1)
        real :: re(3), ze(2), fraction(2)
        integer :: ierr
        re = [1.0, 2.0, 3.0]
        ze = [0.0, 1.0]
        active = .true.
        fraction = [0.0, 0.25]
        call sub_J02_initialize_mesh(re, ze, active, mesh, ierr)
        call sub_J02_initialize_boundary_types(mesh, boundary, ierr)
        call sub_J02_configure_zlo_partial_inlet_boundary(mesh, fraction, boundary, ierr)
        call truth(ierr == SN_SUCCESS .and. boundary%face_z_lo(1, 1) == SN_FACE_WALL .and. &
            boundary%face_z_lo(2, 1) == SN_FACE_OPEN, &
            'z-low boundary is open only where the partial inlet has area', n_failed)
    end subroutine test_partial_inlet_boundary

    subroutine test_absorption_matrix(n_failed)
        integer, intent(inout) :: n_failed
        real :: a(3, 3), expected(3, 3)
        a = 0.0
        expected = 0.0
        call sub_J02_add_absorption_matrix(a, 2.0, 3.0, 0.5, 0.25)
        expected(1, 1) = 3.0
        expected(1, 2) = 1.0/6.0
        expected(2, 1) = 1.0/6.0
        expected(2, 2) = 1.0
        expected(3, 3) = 1.0
        call close(maxval(abs(a-expected)), 0.0, 1.0e-14, &
            'cylindrical P1 absorption mass matrix', n_failed)
    end subroutine test_absorption_matrix

    subroutine test_frequency_conversion(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_quadrature_type) :: quad
        real :: nu(1, 1)
        real, allocatable :: sigma(:, :, :)
        integer :: ierr
        call sub_J02_build_phase_quadrature(8, 2, 'midpoint', 4.0, quad, ierr)
        nu = 6.0
        call sub_J02_build_sigma_from_frequency(quad, nu, sigma, ierr)
        call close(sigma(1, 1, 1), 6.0, 1.0e-13, 'low-speed sigma_t=nu/v', n_failed)
        call close(sigma(1, 1, 9), 2.0, 1.0e-13, 'high-speed sigma_t=nu/v', n_failed)
        nu = -1.0
        call sub_J02_build_sigma_from_frequency(quad, nu, sigma, ierr)
        call truth(ierr == SN_ERR_SIGMA_NEGATIVE_FREQUENCY, &
            'negative ionization frequency returns a specific error', n_failed)
        write(*,'(a,2i8)') 'STATUS: negative frequency actual/expected: ', ierr, SN_ERR_SIGMA_NEGATIVE_FREQUENCY
    end subroutine test_frequency_conversion

    subroutine test_four_boundary_signs(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_mesh_2drz_type) :: mesh
        type(sn_geometry_2drz_type) :: geom
        type(sn_quadrature_type) :: quad
        type(sn_boundary_2drz_type) :: boundary
        logical :: active(1, 1)
        real :: re(2), ze(2), pi
        real, allocatable :: psi(:, :, :, :), given(:, :, :, :), fin(:, :, :), fout(:, :, :)
        integer :: ierr
        pi = acos(-1.0)
        re = [1.0, 2.0]
        ze = [0.0, 1.0]
        active = .true.
        call sub_J02_initialize_mesh(re, ze, active, mesh, ierr)
        call sub_J02_build_geometry(mesh, 2*pi, geom, ierr)
        call sub_J02_initialize_boundary_types(mesh, boundary, ierr)
        call sub_J02_build_phase_quadrature(8, 1, 'midpoint', 2.0, quad, ierr)
        allocate(psi(3, 1, 1, quad%n_dir), given(4, 1, 1, quad%n_dir))
        psi = 0.0
        psi(1, :, :, :) = 2.0
        given = 3.0
        call sub_J02_reconstruct_open_boundary_fluxes(mesh, geom, boundary, quad, psi, given, &
            fin, fout, ierr)
        call truth(fin(SN_R_LO, 1, 1) > 0.0 .and. fout(SN_R_LO, 1, 1) < 0.0, &
            'r-lo signed inflow/outflow', n_failed)
        call truth(fin(SN_R_HI, 1, 1) < 0.0 .and. fout(SN_R_HI, 1, 1) > 0.0, &
            'r-hi signed inflow/outflow', n_failed)
        call truth(fin(SN_Z_LO, 1, 1) > 0.0 .and. fout(SN_Z_LO, 1, 1) < 0.0, &
            'z-lo signed inflow/outflow', n_failed)
        call truth(fin(SN_Z_HI, 1, 1) < 0.0 .and. fout(SN_Z_HI, 1, 1) > 0.0, &
            'z-hi signed inflow/outflow', n_failed)
        write(*,'(a,4es24.15)') 'VALUE: rlo/rhi/zlo/zhi incoming flux: ',fin(:,1,1)
        write(*,'(a,4es24.15)') 'VALUE: rlo/rhi/zlo/zhi outgoing flux: ',fout(:,1,1)
    end subroutine test_four_boundary_signs

    subroutine test_negative_sigma_error(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_mesh_2drz_type) :: mesh
        type(sn_geometry_2drz_type) :: geom
        type(sn_quadrature_type) :: quad
        logical :: active(1, 1)
        real :: re(2), ze(2), pi
        real, allocatable :: sigma(:, :, :), given(:, :, :, :), psi(:, :, :, :)
        integer :: ierr
        pi = acos(-1.0)
        re = [1.0, 2.0]
        ze = [0.0, 1.0]
        active = .true.
        call sub_J02_initialize_mesh(re, ze, active, mesh, ierr)
        call sub_J02_build_geometry(mesh, 2*pi, geom, ierr)
        call sub_J02_build_phase_quadrature(8, 1, 'midpoint', 2.0, quad, ierr)
        allocate(sigma(1, 1, quad%n_dir), given(4, 1, 1, quad%n_dir))
        sigma = -1.0
        given = 0.0
        call sub_J02_initialize_boundary_types(mesh, sweep_boundary, ierr)
        call sub_J02_sweep(mesh, geom, quad, sigma, sweep_boundary, psi, ierr, boundary_inflow=given)
        call truth(ierr == SN_ERR_SWEEP_NEGATIVE_SIGMA, &
            'negative removal coefficient returns a specific error', n_failed)
        write(*,'(a,2i8)') 'STATUS: negative sigma actual/expected: ', ierr, SN_ERR_SWEEP_NEGATIVE_SIGMA
    end subroutine test_negative_sigma_error
    ! Preserve the unique inlet-representation check formerly mixed into J03.
    subroutine test_crossing_representations(n_failed)
        integer, intent(inout) :: n_failed
        type(sn_quadrature_type) :: quad
        real, allocatable :: pdf(:), bins(:), from_pdf(:), from_bins(:)
        integer :: ierr, m
        call sub_J02_build_phase_quadrature(8, 1, 'midpoint', 2.0, quad, ierr)
        allocate(pdf(quad%n_dir))
        pdf = 0.0
        do m = 1, quad%n_dir
            if (quad%eta(m) > 0.0) pdf(m) = real(m)
        end do
        bins = pdf*quad%weight
        call sub_J02_build_mc_crossing_pdf_inflow_shape(quad, 0.0, -1.0, pdf, from_pdf, ierr)
        call truth(ierr == SN_SUCCESS, 'crossing PDF conversion succeeds', n_failed)
        if (ierr /= SN_SUCCESS) return
        call sub_J02_build_mc_crossing_bins_inflow_shape(quad, 0.0, -1.0, bins, from_bins, ierr)
        call truth(ierr == SN_SUCCESS, 'crossing probability conversion succeeds', n_failed)
        if (ierr /= SN_SUCCESS) return
        call close(maxval(abs(from_pdf-from_bins)), 0.0, 1.0e-13, &
            'continuous PDF and weighted probabilities describe the same inflow', n_failed)
    end subroutine test_crossing_representations
end program test_J02_transport_units
