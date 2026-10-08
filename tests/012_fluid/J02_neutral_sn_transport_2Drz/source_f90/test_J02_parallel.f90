! Public-interface fixture; run_parallel.sh compares serial and OpenMP records.
program test_J02_parallel
    use mod_J02_neutral_sn_transport_2Drz
    implicit none
    type(sn_mesh_2drz_type) :: mesh
    type(sn_geometry_2drz_type) :: geo
    type(sn_quadrature_type) :: quad
    type(sn_boundary_2drz_type) :: boundary
    real, allocatable :: sigma(:,:,:), inlet(:), psi(:,:,:,:), fin(:,:,:), fout(:,:,:)
    type(sn_transport_result_type) :: result, full_result
    type(sn_transport_options_type) :: options
    real, allocatable :: fraction(:), lo(:), hi(:), wall(:), full(:,:,:,:)
    real :: incoming, outgoing, lost, frequency(2,2), tol
    integer :: ierr, unit, m, mode, fd, fi, fk
    logical :: save_records
    character(len=512) :: record_path

    tol = max(1.e-12, 100.0*epsilon(1.0))
    call get_command_argument(1,record_path)
    save_records = len_trim(record_path) > 0
    if (save_records) open(newunit=unit,file=trim(record_path),status='replace',action='write')

    call sub_J02_initialize_mesh([1.0,1.3,2.0], [0.0,0.4,1.0], &
        reshape([.true.,.true.,.true.,.true.],[2,2]), mesh, ierr)
    call require_success('mesh')
    call sub_J02_build_geometry(mesh, 1.0, geo, ierr)
    call require_success('geometry')
    call sub_J02_build_phase_quadrature(16, 3, 'midpoint', 4.0, quad, ierr)
    call require_success('quadrature')
    call sub_J02_initialize_boundary_types(mesh, boundary, ierr)
    call require_success('boundary')
    allocate(sigma(2,2,quad%n_dir), inlet(quad%n_dir))
    sigma = 0.0
    inlet = merge(1.0,0.0,quad%eta > 0.0)
    call sub_J02_sweep(mesh, geo, quad, sigma, boundary, psi, ierr, &
        zlo_inflow=inlet, progress_interval=16)
    call require_success('open sweep')
    if (minval(psi(1,:,:,:)-abs(psi(2,:,:,:))-abs(psi(3,:,:,:))) < -tol) &
        error stop 'negative corner value'
    call sub_J02_reconstruct_open_boundary_fluxes(mesh,geo,boundary,quad,psi, &
        inflow_flux=fin,outflow_flux=fout,ierr=ierr,zlo_inflow=inlet)
    call require_success('open boundary reconstruction')
    incoming = sum(fin(SN_Z_LO,:,1)*geo%area_z_lo(:,1))
    outgoing = -sum(fout(SN_R_LO,1,:)*geo%area_r_lo(1,:)) &
        +sum(fout(SN_R_HI,2,:)*geo%area_r_hi(2,:)) &
        -sum(fout(SN_Z_LO,:,1)*geo%area_z_lo(:,1)) &
        +sum(fout(SN_Z_HI,:,2)*geo%area_z_hi(:,2))
    if (incoming <= 0.0 .or. abs(outgoing-incoming)/incoming > tol) &
        error stop 'open sweep particle balance'
    write(*,'(a,4es24.15)') 'VALUE: threaded open incoming/outgoing/relative balance/min corner: ', &
        incoming,outgoing,abs(outgoing-incoming)/incoming, &
        minval(psi(1,:,:,:)-abs(psi(2,:,:,:))-abs(psi(3,:,:,:)))
    if (save_records) write(unit,'(es26.17e3)') psi, fin, fout
    print *, 'PASS: parallel fixture has nonnegative distribution and conservative open flux'

    ! An inactive cell creates internal solid boundaries in addition to exterior walls.
    mesh%active(2,2) = .false.
    call sub_J02_build_geometry(mesh, 1.0, geo, ierr)
    call require_success('masked geometry')
    call sub_J02_initialize_boundary_types(mesh, boundary, ierr)
    call require_success('masked boundary')
    boundary%face_r_lo(1,:) = SN_FACE_WALL
    boundary%face_r_hi(2,:) = SN_FACE_WALL
    call sub_J02_build_partial_zlo_inlet(mesh,1.1,1.75,fraction,lo,hi,ierr)
    call require_success('partial inlet')
    call sub_J02_configure_zlo_partial_inlet_boundary(mesh,fraction,boundary,ierr)
    call require_success('partial face types')
    call sub_J02_build_wall_maxwell_shape(quad,0.7,1.380649e-23,wall,ierr)
    call require_success('wall shape')
    frequency = reshape([0.2,0.3,0.4,0.0],[2,2])
    call sub_J02_build_sigma_from_frequency(quad,frequency,sigma,ierr)
    call require_success('loss')
    allocate(full(4,2,2,quad%n_dir))
    full = 0.0
    do m = 1, quad%n_dir
        full(SN_Z_LO,:,1,m) = inlet(m)
    end do
    options%tolerance = max(1.e-10,8.0*epsilon(1.0))
    options%max_iterations = 600
    do mode = 0, 2
        options%diffuse_fraction = 0.5*real(mode)
        call sub_J02_solve_transport(mesh,geo,quad,boundary,sigma,result,ierr, &
            zlo_inflow=inlet,wall_shape=wall,options=options, &
            zlo_source_xi_lo=lo,zlo_source_xi_hi=hi)
        call require_success('reflecting transport')
        if (.not. result%converged) error stop 'missing convergence flag'
        if (maxval(result%density) <= 0.0) error stop 'empty reflecting field'
        if (abs(result%density(2,2)) > tiny(1.0)) error stop 'inactive cell populated'
        if (minval(result%psi(1,:,:,:)-abs(result%psi(2,:,:,:))-abs(result%psi(3,:,:,:))) < -tol) &
            error stop 'reflecting polynomial is negative'
        incoming = sum(result%inflow_flux(SN_Z_LO,:,1)*geo%area_z_lo(:,1))
        outgoing = sum(result%outflow_flux(SN_Z_HI,:,2)*geo%area_z_hi(:,2)) &
            -sum(result%outflow_flux(SN_Z_LO,:,1)*geo%area_z_lo(:,1))
        lost = sum(frequency*result%density*geo%volume)
        if (lost <= 0.0) error stop 'volume loss was not exercised'
        if (abs(incoming-outgoing-lost)/incoming > 100.0*options%tolerance) &
            error stop 'reflecting particle balance'
        if (save_records) then
            write(unit,'(i8,l2)') result%iterations,result%converged
            write(unit,'(es26.17e3)') result%relative_change,result%psi,result%density, &
                result%velocity_r,result%velocity_z,result%flux_r,result%flux_z, &
                result%inflow_flux,result%outflow_flux
        end if
        call sub_J02_solve_transport(mesh,geo,quad,boundary,sigma,full_result,ierr, &
            boundary_inflow=full,wall_shape=wall,options=options, &
            zlo_source_xi_lo=lo,zlo_source_xi_hi=hi)
        call require_success('full reflecting inlet')
        if (maxval(abs(result%psi-full_result%psi)) > tol) error stop 'inlet representation changed solve'
        write(*,'(a,f4.1,i6,3es24.15)') 'VALUE: threaded d/iterations/change/balance/compact difference: ', &
            options%diffuse_fraction,result%iterations,result%relative_change, &
            abs(incoming-outgoing-lost)/incoming,maxval(abs(result%psi-full_result%psi))
        print *, 'PASS: reflecting transport, diffuse fraction=', options%diffuse_fraction
    end do

    ! Several nodes fail concurrently; always report the lowest failing index.
    ! This malformed ordinate is legal to the layout validator but not to the sweep.
    quad%mu(3) = 0.0
    quad%mu(19) = 0.0
    call sub_J02_sweep(mesh,geo,quad,sigma,boundary,psi,ierr,zlo_inflow=inlet, &
        psi_old=result%psi,wall_shape=wall,diffuse_fraction=0.0, &
        zlo_source_xi_lo=lo,zlo_source_xi_hi=hi,failed_direction=fd,failed_i=fi,failed_k=fk)
    if (ierr /= SN_ERR_SWEEP_AXIS_DIRECTION .or. fd /= 3 .or. fi /= 0 .or. fk /= 0) &
        error stop 'nondeterministic failing direction'
    write(*,'(a,4i8)') 'STATUS: threaded ierr/direction/i/k: ',ierr,fd,fi,fk
    if (save_records) write(unit,'(4i8)') ierr,fd,fi,fk
    call sub_J02_build_phase_quadrature(16,3,'midpoint',4.0,quad,ierr)
    call require_success('restore quadrature')

    ! A negative prescribed incoming field reaches the public positivity failure path.
    mesh%active = .true.
    call sub_J02_build_geometry(mesh,1.0,geo,ierr)
    call require_success('restore geometry')
    call sub_J02_initialize_boundary_types(mesh,boundary,ierr)
    call require_success('restore boundary')
    full = -1.0
    call sub_J02_sweep(mesh,geo,quad,sigma,boundary,psi,ierr,boundary_inflow=full, &
        failed_direction=fd,failed_i=fi,failed_k=fk)
    if (ierr /= SN_ERR_LOCAL_POSITIVITY .or. fd /= 1 .or. fi /= 1 .or. fk /= 1) &
        error stop 'nondeterministic local positivity error'
    write(*,'(a,4i8)') 'STATUS: threaded ierr/direction/i/k: ',ierr,fd,fi,fk
    if (save_records) write(unit,'(4i8)') ierr,fd,fi,fk
    print *, 'PASS: direction and local positivity failures retain deterministic locations'

    ! Failed repeated calls must not expose a stale reconstructed field.
    options%max_iterations = 2
    options%tolerance = tiny(1.0)
    boundary%face_r_lo(1,:) = SN_FACE_WALL
    boundary%face_r_hi(2,:) = SN_FACE_WALL
    call sub_J02_solve_transport(mesh,geo,quad,boundary,sigma,result,ierr,zlo_inflow=inlet, &
        wall_shape=wall,options=options,zlo_source_xi_lo=lo,zlo_source_xi_hi=hi)
    if (ierr /= SN_ERR_SOURCE_ITERATION_NOT_CONVERGED) error stop 'iteration limit hidden'
    if (result%converged .or. allocated(result%density)) error stop 'failure retained stale density'
    if (save_records) write(unit,'(i8,l2)') ierr,result%converged
    if (save_records) close(unit)
    print *, 'PASS: iteration-limit failure has no stale reconstructed result'
    print *, 'RESULT: PASS'
contains
    subroutine require_success(stage)
        character(len=*), intent(in) :: stage
        if (ierr == SN_SUCCESS) return
        write(*,'(a)') stage//': '//trim(fun_J02_error_message(ierr))
        error stop 1
    end subroutine require_success
end program test_J02_parallel
