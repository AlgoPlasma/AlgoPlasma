! Complete teaching problem: partial event inlet, mixed walls, open outlet and loss.
! The numbered blocks follow the J02 documentation; no solver internals are copied.
program sn_channel
#ifdef J02_USE_MPI
    use mpi
#endif
    use mod_J02_neutral_sn_transport_2Drz
    implicit none
    integer, parameter :: global_nr = 4, global_nz = 6
    integer :: nr, nz, first(2), rank
    real, parameter :: particle_mass = 6.6335e-26
    real, parameter :: boltzmann = 1.380649e-23
    real, parameter :: inlet_temperature = 300.0, wall_temperature = 300.0
    real, parameter :: drift_r = 0.0, drift_z = 200.0, particle_rate = 1.0e15
    type(sn_mesh_2drz_type) :: mesh
    type(sn_geometry_2drz_type) :: geo
    type(sn_quadrature_type) :: quad
    type(sn_boundary_2drz_type) :: boundary
    type(sn_transport_options_type) :: options
    type(sn_transport_result_type) :: result
    real, allocatable :: r_edge(:), z_edge(:), frequency(:,:)
    real, allocatable :: fraction(:), xi_lo(:), xi_hi(:)
    real, allocatable :: event_pdf(:), shape(:), inlet(:), wall(:), sigma_t(:,:,:)
    real :: inlet_area, thermal_variance, vr, vz, incoming_rate, outgoing_rate, loss_rate
    real :: density_min, density_max, inlet_r_lo, inlet_r_hi
    integer :: i, k, m, ierr
    type(sn_partition_type), allocatable :: part
#ifdef J02_USE_MPI
    integer :: provided, ec, communicator, n_ranks, dims(2)
    real :: reduced
    call MPI_Init_thread(MPI_THREAD_FUNNELED,provided,ec)
    call MPI_Comm_size(MPI_COMM_WORLD,n_ranks,ec)
    dims=0
    call MPI_Dims_create(n_ranks,2,dims,ec)
    call MPI_Cart_create(MPI_COMM_WORLD,2,dims,[.false.,.false.],.true.,communicator,ec)
    call MPI_Comm_rank(communicator,rank,ec)
    allocate(part)
    call sub_J02_initialize_partition(communicator,[global_nr,global_nz],part,ierr)
    call require_success('initialize spatial partition')
    first=part%first
    nr=part%count(1); nz=part%count(2)
#else
    rank=0
    first=1
    nr=global_nr; nz=global_nz
#endif
    allocate(r_edge(nr+1),z_edge(nz+1),frequency(nr,nz))

    ! 1. Space and velocity discretization.
    do i = 1, nr+1
        r_edge(i) = 0.01+0.01*real(first(1)+i-2)/real(global_nr)
    end do
    do k = 1, nz+1
        z_edge(k) = 0.04*real(first(2)+k-2)/real(global_nz)
    end do
    call sub_J02_initialize_mesh(r_edge, z_edge, spread(spread(.true.,1,nr),2,nz), mesh, ierr)
    call require_success('initialize mesh')
    call sub_J02_build_geometry(mesh, 2.0*acos(-1.0), geo, ierr)
    call require_success('build geometry')
    call sub_J02_build_phase_quadrature(16, 12, 'midpoint', 1800.0, quad, ierr)
    call require_success('build velocity quadrature')

    ! 2. Domain walls, open outlet, and the partial inlet band on the lower face.
    call sub_J02_initialize_boundary_types(mesh, boundary, ierr, partition=part)
    call require_success('initialize boundary types')
    if (first(1)==1) boundary%face_r_lo(1,:) = SN_FACE_WALL
    if (first(1)+nr-1==global_nr) boundary%face_r_hi(nr,:) = SN_FACE_WALL
    inlet_area=0.0
    if (first(2)==1) then
        ! The local geometry helper accepts an interval contained in this block.
        inlet_r_lo=max(0.012,r_edge(1))
        inlet_r_hi=min(0.018,r_edge(nr+1))
        if (inlet_r_hi>inlet_r_lo) then
            call sub_J02_build_partial_zlo_inlet(mesh, inlet_r_lo, inlet_r_hi, fraction, xi_lo, xi_hi, ierr)
            call require_success('intersect inlet band')
        else
            allocate(fraction(nr),xi_lo(nr),xi_hi(nr))
            fraction=0.0; xi_lo=0.0; xi_hi=0.0
        end if
        call sub_J02_configure_zlo_partial_inlet_boundary(mesh, fraction, boundary, ierr)
        call require_success('configure lower faces')
        inlet_area = sum(fraction*geo%area_z_lo(:,1))
    end if
#ifdef J02_USE_MPI
    ! Normalize by the whole physical inlet area, not each block's local area.
    call MPI_Allreduce(inlet_area,reduced,1,part%real_type,MPI_SUM,communicator,ec)
    inlet_area=reduced
#endif

    ! 3. Crossing-event PDF -> phase-density shape -> prescribed number flux.
    thermal_variance = boltzmann*inlet_temperature/particle_mass
    allocate(event_pdf(quad%n_dir))
    event_pdf = 0.0
    do m = 1, quad%n_dir
        if (quad%eta(m) <= 0.0) cycle
        vr = quad%speed(m)*quad%mu(m)
        vz = quad%speed(m)*quad%eta(m)
        event_pdf(m) = exp(-((vr-drift_r)**2+(vz-drift_z)**2)/(2.0*thermal_variance))
    end do
    call sub_J02_build_mc_crossing_pdf_inflow_shape(quad, 0.0, -1.0, event_pdf, shape, ierr)
    call require_success('convert event PDF')
    call sub_J02_normalize_inflow_flux(quad, 0.0, -1.0, particle_rate/inlet_area, shape, inlet, ierr)
    call require_success('normalize inlet flux')

    ! 4. Wall shape and volume loss are independent physical inputs.
    call sub_J02_build_wall_maxwell_shape(quad, wall_temperature, particle_mass, wall, ierr)
    call require_success('build wall shape')
    frequency = 2000.0
    call sub_J02_build_sigma_from_frequency(quad, frequency, sigma_t, ierr)
    call require_success('convert loss frequency')

    ! 5. The application entry owns reflection iteration and reconstruction.
    options%diffuse_fraction = 0.5
    options%tolerance = 1.0e-9
    options%max_iterations = 500
    call sub_J02_solve_transport(mesh, geo, quad, boundary, sigma_t, result, ierr, &
        zlo_inflow=inlet, wall_shape=wall, options=options, &
        zlo_source_xi_lo=xi_lo, zlo_source_xi_hi=xi_hi, partition=part)
    if (ierr /= SN_SUCCESS) then
        write(*,'(a,3(i0,1x))') 'failed direction/i/k: ', &
            result%failed_direction, result%failed_i, result%failed_k
    end if
    call require_success('solve and reconstruct')

    ! 6. Read the reference field and physical particle rates.
    ! Flux arrays use coordinate signs, and partial fluxes use the FULL face area.
    incoming_rate = sum(result%inflow_flux(SN_Z_LO,:,1)*geo%area_z_lo(:,1))
    outgoing_rate = sum(result%outflow_flux(SN_Z_HI,:,nz)*geo%area_z_hi(:,nz)) &
        -sum(result%outflow_flux(SN_Z_LO,:,1)*geo%area_z_lo(:,1))
    loss_rate = sum(frequency*result%density*geo%volume)
    density_min=minval(result%density)
    density_max=maxval(result%density)
#ifdef J02_USE_MPI
    call MPI_Allreduce(incoming_rate,reduced,1,part%real_type,MPI_SUM,communicator,ec)
    incoming_rate=reduced
    call MPI_Allreduce(outgoing_rate,reduced,1,part%real_type,MPI_SUM,communicator,ec)
    outgoing_rate=reduced
    call MPI_Allreduce(loss_rate,reduced,1,part%real_type,MPI_SUM,communicator,ec)
    loss_rate=reduced
    call MPI_Allreduce(density_min,reduced,1,part%real_type,MPI_MIN,communicator,ec)
    density_min=reduced
    call MPI_Allreduce(density_max,reduced,1,part%real_type,MPI_MAX,communicator,ec)
    density_max=reduced
#endif
    if (rank==0) then
    write(*,'(a,i0)') 'reflection iterations: ', result%iterations
    write(*,'(a,es12.4)') 'relative field change: ', result%relative_change
    write(*,'(a,2es15.6)') 'density min/max [m^-3]: ', density_min, density_max
    write(*,'(a,es15.6)') 'incoming rate [s^-1]: ', incoming_rate
    write(*,'(a,es15.6)') 'open outgoing rate [s^-1]: ', outgoing_rate
    write(*,'(a,es15.6)') 'volume loss rate [s^-1]: ', loss_rate
    write(*,'(a,es12.4)') 'relative particle imbalance: ', &
        abs(incoming_rate-outgoing_rate-loss_rate)/incoming_rate
    end if
#ifdef J02_USE_MPI
    call MPI_Comm_free(communicator,ec)
    call MPI_Finalize(ec)
#endif
contains
    subroutine require_success(stage)
        character(len=*), intent(in) :: stage
        if (ierr == SN_SUCCESS) return
        write(*,'(a)') trim(stage)//': '//trim(fun_J02_error_message(ierr))
#ifdef J02_USE_MPI
        call MPI_Abort(MPI_COMM_WORLD,1,ec)
#else
        error stop 1
#endif
    end subroutine require_success
end program sn_channel
