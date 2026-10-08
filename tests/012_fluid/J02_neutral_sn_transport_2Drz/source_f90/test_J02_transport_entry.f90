program test_J02_transport_entry
    use mod_J02_neutral_sn_transport_2Drz
    implicit none
    type(sn_mesh_2drz_type) :: mesh
    type(sn_geometry_2drz_type) :: geometry
    type(sn_quadrature_type) :: quadrature
    type(sn_boundary_2drz_type) :: boundary
    type(sn_transport_result_type) :: result
    type(sn_transport_options_type) :: options
    real, allocatable :: sigma(:,:,:), inflow(:,:,:,:)
    real, allocatable :: wall(:), psi(:,:,:,:), density(:,:), vr(:,:), vz(:,:), fr(:,:), fz(:,:)
    real, allocatable :: fin(:,:,:), fout(:,:,:)
    real :: change, lo(1), hi(1), incoming, outgoing
    integer :: iterations, m
    logical :: converged
    integer :: ierr
    call sub_J02_initialize_mesh([1.0,2.0], [0.0,1.0], reshape([.true.],[1,1]), mesh, ierr)
    call sub_J02_build_geometry(mesh, 1.0, geometry, ierr)
    call sub_J02_build_phase_quadrature(8, 2, 'midpoint', 4.0, quadrature, ierr)
    call sub_J02_initialize_boundary_types(mesh, boundary, ierr)
    allocate(sigma(1,1,quadrature%n_dir), inflow(4,1,1,quadrature%n_dir))
    sigma = 0.0
    inflow = 0.0
    call sub_J02_solve_transport(mesh, geometry, quadrature, boundary, sigma, result, ierr, &
        boundary_inflow=inflow)
    if (ierr /= SN_SUCCESS .or. .not. result%converged) error stop 'zero-input solve failed'
    if (.not. allocated(result%density)) error stop 'missing reconstructed field'
    if (maxval(abs(result%density)) > tiny(1.0)) error stop 'zero input created particles'
    if (maxval(abs(result%outflow_flux)) > tiny(1.0)) error stop 'zero input created outflow'
    write(*,'(a,2es24.15)') 'VALUE: zero solve max density/outflow: ', &
        maxval(abs(result%density)),maxval(abs(result%outflow_flux))
    print *, 'PASS: zero-input transport returns complete zero reference field'
    boundary%face_r_lo = SN_FACE_WALL
    boundary%face_r_hi = SN_FACE_WALL
    boundary%face_z_hi = SN_FACE_WALL
    do m = 1, quadrature%n_dir
        if (quadrature%eta(m) > 0.0) inflow(SN_Z_LO,1,1,m) = 1.0
    end do
    call sub_J02_build_wall_maxwell_shape(quadrature, 4.0/9.0, 1.380649e-23, wall, ierr)
    options%diffuse_fraction = 0.7
    options%tolerance = 1.e-10
    options%max_iterations = 800
    lo = -0.5
    hi = 0.5
    call sub_J02_solve_transport(mesh, geometry, quadrature, boundary, sigma, result, ierr, &
        boundary_inflow=inflow, wall_shape=wall, options=options, zlo_source_xi_lo=lo, zlo_source_xi_hi=hi)
    if (ierr /= SN_SUCCESS .or. .not. result%converged) error stop 'reflecting transport failed'
    call sub_J02_solve_source_iteration(mesh, geometry, quadrature, sigma, inflow, &
        boundary, wall, 0.7, 800, 1.e-10, psi, converged, iterations, change, ierr, &
        zlo_source_xi_lo=lo, zlo_source_xi_hi=hi)
    call sub_J02_reconstruct_cell_moments(mesh, geometry, quadrature, psi, density, vr, vz, ierr)
    call sub_J02_reconstruct_internal_face_fluxes(mesh, geometry, quadrature, psi, fr, fz, ierr)
    call sub_J02_reconstruct_open_boundary_fluxes(mesh, geometry, boundary, quadrature, &
        psi, inflow, fin, fout, ierr, lo, hi)
    if (maxval(abs(result%psi-psi)) > 1.e-12) error stop 'distribution differs from existing path'
    if (maxval(abs(result%density-density)) > 1.e-12) error stop 'density differs from existing path'
    if (maxval(abs(result%inflow_flux-fin)) > 1.e-12) error stop 'inflow differs from existing path'
    if (maxval(abs(result%outflow_flux-fout)) > 1.e-12) error stop 'outflow differs from existing path'
    incoming = fin(SN_Z_LO,1,1)
    outgoing = -fout(SN_Z_LO,1,1)
    if (incoming <= 0.0) error stop 'positive inlet flux expected'
    if (abs(incoming-outgoing)/incoming > 1.e-8) error stop 'source-free particle balance failed'
    write(*,'(a,i6,2es24.15)') 'VALUE: transport iterations/change/relative balance: ', &
        result%iterations,result%relative_change,abs(incoming-outgoing)/incoming
    write(*,'(a,4es24.15)') 'VALUE: transport vs assembled max psi/density/inflow/outflow differences: ', &
        maxval(abs(result%psi-psi)),maxval(abs(result%density-density)), &
        maxval(abs(result%inflow_flux-fin)),maxval(abs(result%outflow_flux-fout))
    print *, 'PASS: partial reflecting inlet agrees with original path and conserves particles'
    call sub_J02_solve_transport(mesh, geometry, quadrature, boundary, sigma, result, ierr, &
        zlo_inflow=inflow(SN_Z_LO,1,1,:), wall_shape=wall, options=options, &
        zlo_source_xi_lo=lo, zlo_source_xi_hi=hi)
    if (ierr /= SN_SUCCESS) error stop 'compact input failed'
    if (maxval(abs(result%density-density)) > 1.e-12) error stop 'compact input changed field'
    write(*,'(a,es24.15)') 'VALUE: compact reflecting density difference: ', maxval(abs(result%density-density))
    options%max_iterations = 2
    call sub_J02_solve_transport(mesh, geometry, quadrature, boundary, sigma, result, ierr, &
        boundary_inflow=inflow, wall_shape=wall, options=options, zlo_source_xi_lo=lo, zlo_source_xi_hi=hi)
    if (ierr /= SN_ERR_SOURCE_ITERATION_NOT_CONVERGED) error stop 'failure was hidden'
    if (result%converged .or. allocated(result%density)) error stop 'failed solve exposed stale fields'
    write(*,'(a,2i8,2l3)') 'STATUS: iteration limit ierr/expected/converged/density allocated: ', &
        ierr,SN_ERR_SOURCE_ITERATION_NOT_CONVERGED,result%converged,allocated(result%density)
    print *, 'PASS: compact inlet is equivalent; failed repeated call has no stale density'

    ! A nonzero multi-cell case exercises both internal face arrays.
    call sub_J02_initialize_mesh([1.0,2.0,3.0], [0.0,1.0,2.0], &
        reshape([.true.,.true.,.true.,.true.],[2,2]), mesh, ierr)
    call sub_J02_build_geometry(mesh, 1.0, geometry, ierr)
    call sub_J02_initialize_boundary_types(mesh, boundary, ierr)
    deallocate(sigma, inflow)
    allocate(sigma(2,2,quadrature%n_dir), inflow(4,2,2,quadrature%n_dir))
    sigma = 0.0
    inflow = 0.0
    do m = 1, quadrature%n_dir
        if (quadrature%eta(m) > 0.0) inflow(SN_Z_LO,:,1,m) = 1.0
    end do
    call sub_J02_solve_transport(mesh, geometry, quadrature, boundary, sigma, result, ierr, &
        boundary_inflow=inflow)
    if (ierr /= SN_SUCCESS) error stop 'multi-cell open solve failed'
    density = result%density
    fr = result%flux_r
    fz = result%flux_z
    if (size(fr) == 0 .or. size(fz) == 0) error stop 'internal faces were not reconstructed'
    if (maxval(abs(fz)) <= tiny(1.0)) error stop 'nonzero inlet produced no axial transport'
    call sub_J02_solve_transport(mesh, geometry, quadrature, boundary, sigma, result, ierr, &
        zlo_inflow=inflow(SN_Z_LO,1,1,:))
    if (ierr /= SN_SUCCESS) error stop 'multi-cell compact solve failed'
    if (maxval(abs(result%density-density)) > 1.e-12) error stop 'open inlet density mismatch'
    if (maxval(abs(result%flux_r-fr)) > 1.e-12) error stop 'open inlet radial flux mismatch'
    if (maxval(abs(result%flux_z-fz)) > 1.e-12) error stop 'open inlet axial flux mismatch'
    write(*,'(a,3es24.15)') 'VALUE: multi-cell compact max density/radial flux/axial flux differences: ', &
        maxval(abs(result%density-density)),maxval(abs(result%flux_r-fr)),maxval(abs(result%flux_z-fz))
    print *, 'PASS: nonzero multi-cell full and compact inlets give identical fields and face fluxes'

    call sub_J02_solve_transport(mesh, geometry, quadrature, boundary, sigma, result, ierr)
    if (ierr /= SN_ERR_REFLECTION_INPUT) error stop 'missing inlet was accepted'
    if (result%converged .or. allocated(result%density)) error stop 'invalid input retained result'
    call sub_J02_solve_transport(mesh, geometry, quadrature, boundary, sigma, result, ierr, &
        boundary_inflow=inflow, zlo_inflow=inflow(SN_Z_LO,1,1,:))
    if (ierr /= SN_ERR_REFLECTION_INPUT) error stop 'ambiguous inlet was accepted'
    call sub_J02_solve_transport(mesh, geometry, quadrature, boundary, sigma, result, ierr, &
        boundary_inflow=inflow, zlo_source_xi_lo=lo)
    if (ierr /= SN_ERR_REFLECTION_INPUT) error stop 'unpaired partial-inlet interval was accepted'
    print *, 'PASS: invalid inlet combinations return errors without stale output'
end program test_J02_transport_entry
