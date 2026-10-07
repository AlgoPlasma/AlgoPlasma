! Scale invariance and unresolved thermal-wall regressions from PR review.
program test_J02_review_regressions
    use mod_J02_neutral_sn_transport_2Drz
    implicit none
    type(sn_mesh_2drz_type) :: mesh
    type(sn_geometry_2drz_type) :: geo
    type(sn_quadrature_type) :: quad
    type(sn_boundary_2drz_type) :: bc
    real, allocatable :: sig(:,:,:), inlet(:,:,:,:), wall(:), psi(:,:,:,:), reference(:,:,:,:), dc(:,:,:)
    real, allocatable :: den(:,:), vr(:,:), vz(:,:), fin(:,:,:), fout(:,:,:)
    real :: amp, change, balance, incoming, lo(1), hi(1)
    integer :: ierr, m, j, iterations, reference_iterations, failures
    logical :: converged
    failures = 0
    call sub_J02_initialize_mesh([1.0,2.0], [0.0,1.0], reshape([.true.],[1,1]), mesh, ierr)
    call sub_J02_build_geometry(mesh, 2*acos(-1.0), geo, ierr)
    call sub_J02_initialize_boundary_types(mesh, bc, ierr)
    call sub_J02_build_phase_quadrature(8, 2, 'midpoint', 4.0, quad, ierr)
    call sub_J02_build_sigma_from_frequency(quad, reshape([0.2],[1,1]), sig, ierr)
    call sub_J02_build_wall_maxwell_shape(quad, 4.0/9.0, 1.380649e-23, wall, ierr)
    allocate(inlet(4,1,1,quad%n_dir))
    bc%face_r_lo = SN_FACE_WALL
    bc%face_r_hi = SN_FACE_WALL
    bc%face_z_hi = SN_FACE_WALL
    lo = -0.5
    hi = 0.5
    do j = 1, 3
        amp = 1.0
        if (j == 2) amp = 1.e-20
        if (j == 3) amp = 1.e20
        inlet = 0.0
        do m = 1, quad%n_dir
            if (quad%eta(m) > 0.0) inlet(SN_Z_LO,1,1,m) = amp
        end do
        call sub_J02_solve_source_iteration(mesh, geo, quad, sig, inlet, bc, wall, 0.7, 800, 1.e-10, &
            psi, converged, iterations, change, ierr, zlo_source_xi_lo=lo, zlo_source_xi_hi=hi)
        call check(ierr == SN_SUCCESS .and. converged, 'scaled solve converges')
        if (j == 1) then
            reference = psi
            reference_iterations = iterations
        else
            call check(abs(iterations-reference_iterations) <= 1, 'iteration count independent of amplitude')
            call check(maxval(abs(psi/amp-reference))/maxval(abs(reference)) < 1.e-8, 'scaled field agrees')
        end if
        call sub_J02_reconstruct_cell_moments(mesh, geo, quad, psi, den, vr, vz, ierr)
        call sub_J02_reconstruct_open_boundary_fluxes(mesh, geo, bc, quad, psi, inlet, fin, fout, ierr, lo, hi)
        incoming = -geo%area_z_lo(1,1)*fin(SN_Z_LO,1,1)
        balance = -geo%area_z_lo(1,1)*(fin(SN_Z_LO,1,1)+fout(SN_Z_LO,1,1)) &
            +0.2*den(1,1)*geo%volume(1,1)
        call check(abs(balance/incoming) < 1.e-8, 'scaled particle balance')
        write(*,'(a,es12.3,i6,3es24.15)') 'VALUE: amplitude/iterations/change/scaled field error/relative balance: ', &
            amp,iterations,change,maxval(abs(psi/amp-reference))/maxval(abs(reference)),abs(balance/incoming)
    end do
    inlet = 0.0
    call sub_J02_solve_source_iteration(mesh, geo, quad, sig, inlet, bc, wall, 0.7, 800, 1.e-10, &
        psi, converged, iterations, change, ierr)
    call check(ierr == SN_SUCCESS .and. converged .and. maxval(abs(psi)) <= tiny(1.0), 'zero field fixed point')
    call sub_J02_build_wall_maxwell_shape(quad, 1.e-6, 1.380649e-23, wall, ierr)
    call check(ierr == SN_ERR_WALL_NORMALIZATION, 'underresolved Maxwell reports error')
    write(*,'(a,2i8)') 'STATUS: unresolved Maxwell actual/expected: ',ierr,SN_ERR_WALL_NORMALIZATION
    call check(index(fun_J02_error_message(ierr), 'velocity grid') > 0, 'error explains remedy')
    psi = 0.0
    psi(1,:,:,:) = 1.0
    call sub_J02_compute_diffuse_wall_constants(mesh, geo, quad, bc, wall, psi, dc, ierr)
    call check(ierr == SN_ERR_WALL_NORMALIZATION, 'full wall rejects zero normalization')
    bc%face_r_lo = SN_FACE_OPEN
    bc%face_r_hi = SN_FACE_OPEN
    bc%face_z_hi = SN_FACE_OPEN
    call sub_J02_compute_diffuse_wall_constants(mesh, geo, quad, bc, wall, psi, dc, ierr, lo, hi)
    call check(ierr == SN_ERR_WALL_NORMALIZATION, 'partial inlet wall rejects zero normalization')
    bc%face_z_hi = SN_FACE_WALL
    call sub_J02_sweep(mesh, geo, quad, sig, bc, reference, ierr, boundary_inflow=inlet, &
            wall_shape=wall, diffuse_fraction=0.0, psi_old=psi)
    call check(ierr == SN_SUCCESS, 'pure specular reflection does not require thermal shape')
    if (failures > 0) error stop 1
    print *, 'RESULT: PASS'
contains
    subroutine check(ok, label)
        logical, intent(in) :: ok
        character(*), intent(in) :: label
        if (.not. ok) then
            print *, 'FAIL: ', label
            failures = failures+1
        end if
    end subroutine
end program
