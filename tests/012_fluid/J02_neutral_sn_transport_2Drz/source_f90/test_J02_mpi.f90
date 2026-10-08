! Spatial decomposition is tested only through the public sweep/transport entries.
program test_J02_mpi
    use mpi
    use, intrinsic :: ieee_arithmetic, only: ieee_value, ieee_quiet_nan
    use mod_J02_neutral_sn_transport_2Drz
    implicit none
    type(sn_partition_type) :: part
    type(sn_mesh_2drz_type) :: mesh, global_mesh
    type(sn_geometry_2drz_type) :: geo, global_geo
    type(sn_boundary_2drz_type) :: boundary, global_boundary
    type(sn_quadrature_type) :: quad
    real, allocatable :: sigma(:,:,:), full_sigma(:,:,:), inlet(:,:,:,:), full_inlet(:,:,:,:)
    real, allocatable :: psi(:,:,:,:), reference(:,:,:,:)
    type(sn_transport_result_type) :: result,ref_result
    type(sn_transport_options_type) :: options
    real, allocatable :: wall(:),fraction(:),glo(:),ghi(:),lo(:),hi(:)
    real :: r(6)=[0.0,0.1,0.3,0.7,1.0,1.5], z(4)=[0.0,0.2,0.6,1.1], tol, error
    integer :: comm, dims(2), coords(2), provided, mpierr, rank, ierr, a, b, c, d, m, mode
    integer :: fd, fi, fk, ec_ref, fd_ref, fi_ref, fk_ref, reverse_comm, n_ranks
    character(len=16) :: arg
    call MPI_Init_thread(MPI_THREAD_FUNNELED,provided,mpierr)
    call MPI_Comm_rank(MPI_COMM_WORLD,rank,mpierr)
    call get_command_argument(1,arg)
    read(arg,*) dims(1)
    call get_command_argument(2,arg)
    read(arg,*) dims(2)
    call MPI_Comm_size(MPI_COMM_WORLD,n_ranks,mpierr)
    call MPI_Comm_split(MPI_COMM_WORLD,0,n_ranks-1-rank,reverse_comm,mpierr)
    call MPI_Cart_create(reverse_comm,2,dims,[.false.,.false.],.true.,comm,mpierr)
    call MPI_Comm_rank(comm,m,mpierr)
    call MPI_Cart_coords(comm,m,2,coords,mpierr)
    call get_command_argument(3,arg)
    if (trim(arg)=='custom') then
        ! Unequal but conforming blocks, different from the default balanced tiling.
        a=1; b=5; c=1; d=3
        if (dims(1)==2) then
            if (coords(1)==0) then
                b=4
            else
                a=5
            end if
        end if
        if (dims(2)==2) then
            if (coords(2)==0) then
                d=2
            else
                c=3
            end if
        end if
        call sub_J02_initialize_partition(comm,[5,3],part,ierr,first=[a,c],count=[b-a+1,d-c+1])
    else
        call sub_J02_initialize_partition(comm,[5,3],part,ierr)
    end if
    call require_success('partition')
    a=part%first(1); b=a+part%count(1)-1
    c=part%first(2); d=c+part%count(2)-1
    call sub_J02_initialize_mesh(r(a:b+1),z(c:d+1),spread(spread(.true.,1,b-a+1),2,d-c+1),mesh,ierr)
    call require_success('local mesh')
    call sub_J02_build_geometry(mesh,1.0,geo,ierr)
    call require_success('local geometry')
    call sub_J02_initialize_boundary_types(mesh,boundary,ierr,partition=part)
    call require_success('partition faces')
    call sub_J02_build_phase_quadrature(16,2,'midpoint',3.0,quad,ierr)
    call require_success('quadrature')
    call sub_J02_initialize_mesh(r,z,spread(spread(.true.,1,5),2,3),global_mesh,ierr)
    call require_success('reference mesh')
    call sub_J02_build_geometry(global_mesh,1.0,global_geo,ierr)
    call require_success('reference geometry')
    call sub_J02_initialize_boundary_types(global_mesh,global_boundary,ierr)
    call require_success('reference boundary')
    allocate(full_sigma(5,3,quad%n_dir),full_inlet(4,5,3,quad%n_dir))
    full_sigma=0.4
    full_inlet=0.0
    do m=1,quad%n_dir
        full_inlet(SN_Z_LO,:,1,m)=1.0+0.1*real(m)
        full_inlet(SN_R_HI,5,:,m)=0.5+0.05*real(m)
        full_inlet(SN_Z_HI,:,3,m)=0.2
    end do
    sigma=full_sigma(a:b,c:d,:)
    inlet=full_inlet(:,a:b,c:d,:)
    call sub_J02_sweep(global_mesh,global_geo,quad,full_sigma,global_boundary,reference,ierr, &
        boundary_inflow=full_inlet)
    call require_success('reference sweep')
    call sub_J02_sweep(mesh,geo,quad,sigma,boundary,psi,ierr,boundary_inflow=inlet, &
        partition=part,progress_interval=16)
    call require_success('partition sweep')
    tol=max(1.e-12,100.0*epsilon(1.0))
    error=maxval(abs(psi-reference(:,a:b,c:d,:)))/maxval(abs(reference))
    if (error>tol) call fail('partition sweep differs from the unsplit grid')
    if (minval(psi(1,:,:,:)-abs(psi(2,:,:,:))-abs(psi(3,:,:,:))) < -tol) &
        call fail('negative local corner')
    call report_max('sweep distribution',[error])
    if (rank==0) print *, 'PASS: spatial sweep equals unsplit reference in all quadrants'

    call sub_J02_solve_transport(global_mesh,global_geo,quad,global_boundary,full_sigma,ref_result,ierr, &
        boundary_inflow=full_inlet)
    call require_success('reference open transport')
    call sub_J02_solve_transport(mesh,geo,quad,boundary,sigma,result,ierr, &
        boundary_inflow=inlet,partition=part)
    call require_success('partition open transport')
    call compare_results()
    call check_balance()
    if (rank==0) print *, 'PASS: open reconstruction and interface fluxes'

    ! The obstacle touches partition interfaces for the 2x2 layout.
    global_mesh%active(3,2)=.false.
    mesh%active=global_mesh%active(a:b,c:d)
    call sub_J02_build_geometry(global_mesh,1.0,global_geo,ierr)
    call require_success('masked reference geometry')
    call sub_J02_build_geometry(mesh,1.0,geo,ierr)
    call require_success('masked local geometry')
    call sub_J02_initialize_boundary_types(global_mesh,global_boundary,ierr)
    call require_success('masked reference boundary')
    call sub_J02_initialize_boundary_types(mesh,boundary,ierr,partition=part)
    call require_success('masked partition boundary')
    global_boundary%face_r_lo(1,:)=SN_FACE_WALL
    global_boundary%face_r_hi(5,:)=SN_FACE_WALL
    if (a==1) boundary%face_r_lo(1,:)=SN_FACE_WALL
    if (b==5) boundary%face_r_hi(mesh%nr,:)=SN_FACE_WALL
    call sub_J02_build_partial_zlo_inlet(global_mesh,0.06,0.95,fraction,glo,ghi,ierr)
    call require_success('partial inlet')
    call sub_J02_configure_zlo_partial_inlet_boundary(global_mesh,fraction,global_boundary,ierr)
    call require_success('partial boundary')
    if (c==1) then
        lo=glo(a:b); hi=ghi(a:b)
        boundary%face_z_lo(:,1)=global_boundary%face_z_lo(a:b,1)
    end if
    full_inlet=0.0
    do m=1,quad%n_dir
        full_inlet(SN_Z_LO,:,1,m)=merge(1.0,0.0,quad%eta(m)>0.0)
        full_sigma(:,:,m)=0.3/quad%speed(m)
    end do
    inlet=full_inlet(:,a:b,c:d,:)
    sigma=full_sigma(a:b,c:d,:)
    call sub_J02_build_wall_maxwell_shape(quad,0.7,1.380649e-23,wall,ierr)
    call require_success('wall shape')
    options%max_iterations=500
    options%tolerance=max(1.e-10,8.0*epsilon(1.0))
    do mode=0,2
        options%diffuse_fraction=0.5*real(mode)
        call sub_J02_solve_transport(global_mesh,global_geo,quad,global_boundary,full_sigma,ref_result,ierr, &
            boundary_inflow=full_inlet,wall_shape=wall,options=options,zlo_source_xi_lo=glo,zlo_source_xi_hi=ghi)
        call require_success('reference reflecting transport')
        call sub_J02_solve_transport(mesh,geo,quad,boundary,sigma,result,ierr, &
            boundary_inflow=inlet,wall_shape=wall,options=options,zlo_source_xi_lo=lo,zlo_source_xi_hi=hi,partition=part)
        call require_success('partition reflecting transport')
        call compare_results()
        call check_balance()
        if (rank==0) print *, 'PASS: reflecting spatial transport, diffuse fraction=',options%diffuse_fraction
    end do


    ! The compact inlet belongs to global z-low, not every process's local k=1.
    call sub_J02_solve_transport(mesh,geo,quad,boundary,sigma,result,ierr, &
        zlo_inflow=full_inlet(SN_Z_LO,1,1,:),wall_shape=wall,options=options, &
        zlo_source_xi_lo=lo,zlo_source_xi_hi=hi,partition=part)
    call require_success('compact distributed inlet')
    call compare_results()
    if (rank==0) print *, 'PASS: compact inlet applies only at global z-low'

    ! A single rank's bad input must return to all ranks, without stale output or waiting peers.
    if (part%rank==part%n_ranks-1) sigma(1,1,1)=-1.0
    call sub_J02_solve_transport(mesh,geo,quad,boundary,sigma,result,ierr, &
        boundary_inflow=inlet,wall_shape=wall,options=options, &
        zlo_source_xi_lo=lo,zlo_source_xi_hi=hi,partition=part)
    call expect_error(SN_ERR_SWEEP_NEGATIVE_SIGMA,'one-rank negative sigma')
    if (allocated(result%density) .or. result%converged) call fail('stale result after bad input')
    sigma=full_sigma(a:b,c:d,:)

    if (part%n_ranks>1) then
        if (part%rank==0) options%max_iterations=501
        call sub_J02_solve_transport(mesh,geo,quad,boundary,sigma,result,ierr, &
            boundary_inflow=inlet,wall_shape=wall,options=options, &
            zlo_source_xi_lo=lo,zlo_source_xi_hi=hi,partition=part)
        call expect_error(SN_ERR_MPI_INPUT,'mismatched iteration options')
        options%max_iterations=500
    end if
    if (part%rank==0) options%tolerance=ieee_value(1.0,ieee_quiet_nan)
    call sub_J02_solve_transport(mesh,geo,quad,boundary,sigma,result,ierr, &
        boundary_inflow=inlet,wall_shape=wall,options=options, &
        zlo_source_xi_lo=lo,zlo_source_xi_hi=hi,partition=part)
    call expect_error(SN_ERR_SOURCE_ITERATION_OPTIONS,'nonfinite iteration tolerance')
    options%tolerance=max(1.e-10,8.0*epsilon(1.0))
    if (part%rank==0) options%diffuse_fraction=ieee_value(1.0,ieee_quiet_nan)
    call sub_J02_solve_transport(mesh,geo,quad,boundary,sigma,result,ierr, &
        boundary_inflow=inlet,wall_shape=wall,options=options, &
        zlo_source_xi_lo=lo,zlo_source_xi_hi=hi,partition=part)
    call expect_error(SN_ERR_REFLECTION_INPUT,'nonfinite reflection fraction')
    options%diffuse_fraction=1.0
    options%max_iterations=2
    options%tolerance=tiny(1.0)
    call sub_J02_solve_transport(mesh,geo,quad,boundary,sigma,result,ierr, &
        boundary_inflow=inlet,wall_shape=wall,options=options, &
        zlo_source_xi_lo=lo,zlo_source_xi_hi=hi,partition=part)
    call expect_error(SN_ERR_SOURCE_ITERATION_NOT_CONVERGED,'global iteration limit')
    if (allocated(result%density) .or. result%converged) call fail('stale result after nonconvergence')
    if (result%iterations/=2) call fail('iteration count exceeds the requested limit')

    ! Restore the open grid before inducing failures inside the directional pipeline.
    mesh%active=.true.; global_mesh%active=.true.
    call sub_J02_build_geometry(mesh,1.0,geo,ierr)
    call require_success('restore geometry')
    call sub_J02_initialize_boundary_types(mesh,boundary,ierr,partition=part)
    call require_success('restore local boundary')
    call sub_J02_initialize_boundary_types(global_mesh,global_boundary,ierr)
    call require_success('restore reference boundary')
    if (part%n_ranks>1) then
        if (part%rank==0) quad%weight(1)=2.0*quad%weight(1)
        call sub_J02_sweep(mesh,geo,quad,sigma,boundary,psi,ierr,boundary_inflow=inlet,partition=part)
        call expect_error(SN_ERR_MPI_INPUT,'one-rank mismatched quadrature')
        call sub_J02_build_phase_quadrature(16,2,'midpoint',3.0,quad,ierr)
        call require_success('restore matching quadrature')
        if (part%rank==0) then
            where(boundary%face_r_lo==SN_FACE_REMOTE) boundary%face_r_lo=SN_FACE_OPEN
            where(boundary%face_r_hi==SN_FACE_REMOTE) boundary%face_r_hi=SN_FACE_OPEN
            where(boundary%face_z_lo==SN_FACE_REMOTE) boundary%face_z_lo=SN_FACE_OPEN
            where(boundary%face_z_hi==SN_FACE_REMOTE) boundary%face_z_hi=SN_FACE_OPEN
        end if
        call sub_J02_sweep(mesh,geo,quad,sigma,boundary,psi,ierr,boundary_inflow=inlet,partition=part)
        call expect_error(SN_ERR_MPI_LAYOUT,'partition face mislabeled as physical opening')
        call sub_J02_initialize_boundary_types(mesh,boundary,ierr,partition=part)
        call require_success('restore remote faces')
        if (part%rank==0) mesh%r_edge=mesh%r_edge+0.01
        call sub_J02_sweep(mesh,geo,quad,sigma,boundary,psi,ierr,boundary_inflow=inlet,partition=part)
        call expect_error(SN_ERR_MPI_LAYOUT,'one-rank mismatched interface geometry')
        mesh%r_edge=r(a:b+1)
    end if
    if (part%rank==0) mesh%r_edge=mesh%r_edge(:mesh%nr)
    call sub_J02_sweep(mesh,geo,quad,sigma,boundary,psi,ierr,boundary_inflow=inlet,partition=part)
    call expect_error(SN_ERR_GEOMETRY_MESH,'one-rank truncated edge array')
    mesh%r_edge=r(a:b+1)
    quad%mu(3)=0.0; quad%mu(19)=0.0
    call sub_J02_sweep(mesh,geo,quad,sigma,boundary,psi,ierr,boundary_inflow=inlet,partition=part, &
        failed_direction=fd,failed_i=fi,failed_k=fk)
    call expect_error(SN_ERR_SWEEP_AXIS_DIRECTION,'multiple failing directions')
    if (fd/=3 .or. fi/=0 .or. fk/=0) call fail('wrong global failing direction')
    call sub_J02_build_phase_quadrature(16,2,'midpoint',3.0,quad,ierr)
    call require_success('restore quadrature')
    full_inlet=-1.0
    inlet=full_inlet(:,a:b,c:d,:)
    call sub_J02_sweep(global_mesh,global_geo,quad,full_sigma,global_boundary,reference,ec_ref, &
        boundary_inflow=full_inlet,failed_direction=fd_ref,failed_i=fi_ref,failed_k=fk_ref)
    call sub_J02_sweep(mesh,geo,quad,sigma,boundary,psi,ierr,boundary_inflow=inlet,partition=part, &
        failed_direction=fd,failed_i=fi,failed_k=fk)
    call expect_error(SN_ERR_LOCAL_POSITIVITY,'negative incoming distribution')
    if (ec_ref/=ierr .or. fd/=fd_ref .or. fi/=fi_ref .or. fk/=fk_ref) &
        call fail('failed local solve is not reported at global serial location')

    ! Reject nonfinite nodes before grouping velocities or entering receive/send.
    quad%mu(3)=ieee_value(1.0,ieee_quiet_nan)
    call sub_J02_sweep(mesh,geo,quad,sigma,boundary,psi,ierr,boundary_inflow=inlet,partition=part)
    call expect_error(SN_ERR_QUADRATURE_LAYOUT,'nonfinite quadrature')
    if (rank==0) print *, 'PASS: collective input/iteration/local errors and global failure indices'
    call sub_J02_build_phase_quadrature(16,2,'midpoint',3.0,quad,ierr)
    call require_success('recover after collective error')
    ! A rank may own grid cells but no active cells; it must still participate.
    if (part%n_ranks>1) then
        if (trim(arg)=='custom') then
            global_mesh%active(5,3)=.false.
        else
            global_mesh%active(5*(dims(1)-1)/dims(1)+1:5,3*(dims(2)-1)/dims(2)+1:3)=.false.
        end if
    end if
    mesh%active=global_mesh%active(a:b,c:d)
    call sub_J02_build_geometry(global_mesh,1.0,global_geo,ierr)
    call require_success('inactive-block reference geometry')
    call sub_J02_build_geometry(mesh,1.0,geo,ierr)
    call require_success('inactive-block local geometry')
    call sub_J02_initialize_boundary_types(global_mesh,global_boundary,ierr)
    call require_success('inactive-block reference faces')
    call sub_J02_initialize_boundary_types(mesh,boundary,ierr,partition=part)
    call require_success('inactive-block remote faces')
    full_inlet=1.0
    inlet=full_inlet(:,a:b,c:d,:)
    options%max_iterations=500
    options%tolerance=max(1.e-10,8.0*epsilon(1.0))
    call sub_J02_solve_transport(global_mesh,global_geo,quad,global_boundary,full_sigma,ref_result,ierr, &
        boundary_inflow=full_inlet,wall_shape=wall,options=options)
    call require_success('inactive-block reference transport')
    call sub_J02_solve_transport(mesh,geo,quad,boundary,sigma,result,ierr, &
        boundary_inflow=inlet,wall_shape=wall,options=options,partition=part)
    call require_success('inactive-block distributed transport')
    call compare_results()
    call check_balance()
    if (part%n_ranks>1) then
        ! An inactive neighbor across a process edge is a wall, not an opening.
        if (part%neighbor(SN_R_LO)/=MPI_PROC_NULL) then
            where(mesh%active(1,:) .and. boundary%face_r_lo(1,:)==SN_FACE_WALL)
                boundary%face_r_lo(1,:)=SN_FACE_OPEN
            end where
        end if
        if (part%neighbor(SN_R_HI)/=MPI_PROC_NULL) then
            where(mesh%active(mesh%nr,:) .and. boundary%face_r_hi(mesh%nr,:)==SN_FACE_WALL)
                boundary%face_r_hi(mesh%nr,:)=SN_FACE_OPEN
            end where
        end if
        if (part%neighbor(SN_Z_LO)/=MPI_PROC_NULL) then
            where(mesh%active(:,1) .and. boundary%face_z_lo(:,1)==SN_FACE_WALL)
                boundary%face_z_lo(:,1)=SN_FACE_OPEN
            end where
        end if
        if (part%neighbor(SN_Z_HI)/=MPI_PROC_NULL) then
            where(mesh%active(:,mesh%nz) .and. boundary%face_z_hi(:,mesh%nz)==SN_FACE_WALL)
                boundary%face_z_hi(:,mesh%nz)=SN_FACE_OPEN
            end where
        end if
        call sub_J02_sweep(mesh,geo,quad,sigma,boundary,psi,ierr,boundary_inflow=inlet, &
            psi_old=result%psi,wall_shape=wall,diffuse_fraction=1.0,partition=part)
        call expect_error(SN_ERR_MPI_LAYOUT,'inactive remote neighbor mislabeled as opening')
    end if
    if (rank==0) print *, 'PASS: successful reuse after errors; wholly inactive blocks participate'
    if (rank==0) print *, 'RESULT: PASS'

    call MPI_Comm_free(comm,mpierr)
    call MPI_Comm_free(reverse_comm,mpierr)
    call MPI_Finalize(mpierr)
contains

    subroutine compare_results()
        integer :: i,k
        real :: scale, measured(6)
        if (.not.result%converged) call fail('distributed solve not converged')
        if (result%iterations/=ref_result%iterations) call fail('iteration count changed')
        measured = 0.0
        scale=maxval(abs(ref_result%psi))
        measured(1)=maxval(abs(result%psi-ref_result%psi(:,a:b,c:d,:)))/scale
        measured(2)=maxval(abs(result%density-ref_result%density(a:b,c:d)))/maxval(ref_result%density)
        measured(3)=max(maxval(abs(result%velocity_r-ref_result%velocity_r(a:b,c:d))), &
            maxval(abs(result%velocity_z-ref_result%velocity_z(a:b,c:d))))/quad%speed_max
        if (maxval(abs(result%psi-ref_result%psi(:,a:b,c:d,:)))>tol*scale) call fail('distribution changed')
        if (maxval(abs(result%density-ref_result%density(a:b,c:d)))>tol*maxval(ref_result%density)) &
            call fail('density changed')
        if (maxval(abs(result%velocity_r-ref_result%velocity_r(a:b,c:d)))>tol*quad%speed_max) &
            call fail('radial velocity changed')
        if (maxval(abs(result%velocity_z-ref_result%velocity_z(a:b,c:d)))>tol*quad%speed_max) &
            call fail('axial velocity changed')
        scale=maxval(ref_result%density)*quad%speed_max
        if (maxval(abs(result%flux_r-ref_result%flux_r(a:b-1,c:d)))>tol*scale) call fail('internal radial flux')
        if (maxval(abs(result%flux_z-ref_result%flux_z(a:b,c:d-1)))>tol*scale) call fail('internal axial flux')
        if (maxval(abs(result%inflow_flux-ref_result%inflow_flux(:,a:b,c:d)))>tol*scale) call fail('open inflow')
        if (maxval(abs(result%outflow_flux-ref_result%outflow_flux(:,a:b,c:d)))>tol*scale) call fail('open outflow')
        measured(4)=max(0.0,maxval(abs(result%flux_r-ref_result%flux_r(a:b-1,c:d))), &
            maxval(abs(result%flux_z-ref_result%flux_z(a:b,c:d-1))))/scale
        measured(5)=max(maxval(abs(result%inflow_flux-ref_result%inflow_flux(:,a:b,c:d))), &
            maxval(abs(result%outflow_flux-ref_result%outflow_flux(:,a:b,c:d))))/scale
        if (.not.allocated(result%partition_flux)) call fail('missing partition flux')
        do k=1,mesh%nz
            if (boundary%face_r_lo(1,k)==SN_FACE_REMOTE) then
                measured(6)=max(measured(6),abs(result%partition_flux(SN_R_LO,1,k)-ref_result%flux_r(a-1,c+k-1))/scale)
                if (abs(result%partition_flux(SN_R_LO,1,k)-ref_result%flux_r(a-1,c+k-1))>tol*scale) &
                    call fail('r-low partition flux')
            end if
            if (boundary%face_r_hi(mesh%nr,k)==SN_FACE_REMOTE) then
                measured(6)=max(measured(6),abs(result%partition_flux(SN_R_HI,mesh%nr,k)-ref_result%flux_r(b,c+k-1))/scale)
                if (abs(result%partition_flux(SN_R_HI,mesh%nr,k)-ref_result%flux_r(b,c+k-1))>tol*scale) &
                    call fail('r-high partition flux')
            end if
        end do
        do i=1,mesh%nr
            if (boundary%face_z_lo(i,1)==SN_FACE_REMOTE) then
                measured(6)=max(measured(6),abs(result%partition_flux(SN_Z_LO,i,1)-ref_result%flux_z(a+i-1,c-1))/scale)
                if (abs(result%partition_flux(SN_Z_LO,i,1)-ref_result%flux_z(a+i-1,c-1))>tol*scale) &
                    call fail('z-low partition flux')
            end if
            if (boundary%face_z_hi(i,mesh%nz)==SN_FACE_REMOTE) then
                measured(6)=max(measured(6),abs(result%partition_flux(SN_Z_HI,i,mesh%nz)-ref_result%flux_z(a+i-1,d))/scale)
                if (abs(result%partition_flux(SN_Z_HI,i,mesh%nz)-ref_result%flux_z(a+i-1,d))>tol*scale) &
                    call fail('z-high partition flux')
            end if
        end do
        call report_max('psi/density/velocity/internal/open/remote',measured)
        if (rank==0) write(*,'(a,2i6,2es24.15)') 'VALUE: mpi iterations/reference/change/limit: ', &
            result%iterations,ref_result%iterations,result%relative_change,options%tolerance
    end subroutine compare_results

    ! Reduce diagnostics as well as assertions: rank zero reports the whole domain.
    subroutine report_max(label, local)
        character(len=*), intent(in) :: label
        real, intent(in) :: local(:)
        real :: global(size(local))
        call MPI_Allreduce(local,global,size(local),part%real_type,MPI_MAX,comm,mpierr)
        if (rank==0) write(*,'(a,*(es24.15))') 'METRIC: mpi '//label//' scaled max: ',global
    end subroutine report_max

    subroutine check_balance()
        real :: net,loss,rate,global(3),local(3)
        integer :: m
        net=sum((result%inflow_flux(SN_R_HI,:,:)+result%outflow_flux(SN_R_HI,:,:))*geo%area_r_hi) &
            -sum((result%inflow_flux(SN_R_LO,:,:)+result%outflow_flux(SN_R_LO,:,:))*geo%area_r_lo) &
            +sum((result%inflow_flux(SN_Z_HI,:,:)+result%outflow_flux(SN_Z_HI,:,:))*geo%area_z_hi) &
            -sum((result%inflow_flux(SN_Z_LO,:,:)+result%outflow_flux(SN_Z_LO,:,:))*geo%area_z_lo)
        rate=sum(abs(result%inflow_flux(SN_R_HI,:,:))*geo%area_r_hi) &
            +sum(abs(result%inflow_flux(SN_R_LO,:,:))*geo%area_r_lo) &
            +sum(abs(result%inflow_flux(SN_Z_HI,:,:))*geo%area_z_hi) &
            +sum(abs(result%inflow_flux(SN_Z_LO,:,:))*geo%area_z_lo)
        loss=0.0
        do m=1,quad%n_dir
            loss=loss+quad%weight(m)*quad%speed(m)*sum(sigma(:,:,m)*geo%volume* &
                (result%psi(1,:,:,m)+spread(geo%xi_bar,2,mesh%nz)*result%psi(2,:,:,m)))
        end do
        local=[net,loss,rate]
        call MPI_Allreduce(local,global,3,part%real_type,MPI_SUM,comm,mpierr)
        if (global(3)<=0.0) call fail('zero input particle rate')
        if (abs(global(1)+global(2))/global(3)>100.0*max(tol,options%tolerance)) call fail('global particle balance')
        if (rank==0) write(*,'(a,5es24.15)') 'VALUE: mpi incoming/outgoing/loss/relative balance/limit: ', &
            global(3),global(1)+global(3),global(2),abs(global(1)+global(2))/global(3), &
            100.0*max(tol,options%tolerance)
    end subroutine check_balance
    subroutine expect_error(expected,stage)
        integer, intent(in) :: expected
        character(len=*), intent(in) :: stage
        if (rank==0) write(*,'(a,2i8)') 'STATUS: '//stage//' actual/expected: ',ierr,expected
        if (ierr/=expected) then
            write(*,'(a,2i8)') stage//': actual/expected=',ierr,expected
            call fail('incorrect collective error')
        end if
    end subroutine expect_error

    subroutine require_success(stage)
        character(len=*), intent(in) :: stage
        if (ierr==SN_SUCCESS) return
        write(*,'(a,i0,2a)') 'rank ',rank,': '//stage//': ',trim(fun_J02_error_message(ierr))
        call MPI_Abort(MPI_COMM_WORLD,1,mpierr)
    end subroutine
    subroutine fail(message)
        character(len=*), intent(in) :: message
        write(*,'(a,i0,2a)') 'rank ',rank,': ',message
        call MPI_Abort(MPI_COMM_WORLD,2,mpierr)
    end subroutine
end program test_J02_mpi
