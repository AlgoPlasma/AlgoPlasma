! Explicit-speed-grid invariants and transport integration, in either real precision.
program test_J02_nonuniform_quadrature
    use mod_J02_neutral_sn_transport_2Drz
    use, intrinsic :: ieee_arithmetic, only: ieee_value, ieee_quiet_nan, ieee_positive_inf
    implicit none
    type(sn_quadrature_type) :: quad, uniform, explicit_uniform
    type(sn_mesh_2drz_type) :: mesh
    type(sn_geometry_2drz_type) :: geo
    type(sn_boundary_2drz_type) :: boundary
    type(sn_transport_result_type) :: result, reference
    type(sn_transport_options_type) :: options
    real, allocatable :: speed(:), weight(:), shape(:), inlet(:), wall(:), sigma(:,:,:)
    real, allocatable :: lo(:), hi(:), fraction(:)
    real :: edge(6), bad(3), pi, tol, incoming, outgoing, lost, balance, frequency(2,2), err
    integer :: ierr, m, f, reflected, mode

    pi=acos(-1.0)
    tol=max(2.e-12,100.0*epsilon(1.0))
    edge=[0.0,0.125,0.5,1.0,2.0,4.0]
    call sub_J02_build_speed_groups_from_edges(edge,speed,weight,ierr)
    call success('explicit speed groups')
    call require(all(speed>0.0).and.all(weight>0.0),'positive nodes and weights')
    call require(maxval(abs(speed-[0.0625,0.3125,0.75,1.5,3.0]))<tol,'midpoint locations')
    call require(maxval(abs(weight-[0.0078125,0.1171875,0.375,1.5,6.0]))<tol,'annular velocity areas')
    call require(abs(sum(weight)-8.0)<tol,'radial integral of constant')
    call sub_J02_build_phase_quadrature_from_edges(16,edge,'midpoint',quad,ierr)
    call success('phase quadrature')
    call require(quad%n_speeds==5.and.quad%n_dir==80,'inferred group counts')
    call require(abs(quad%speed_max-4.0)<tol,'inferred cutoff')
    call require(abs(sum(quad%weight)/(16*pi)-1.0)<tol,'disk area')
    call require(abs(sum(quad%weight*quad%mu))/sum(quad%weight)<tol,'angular radial symmetry')
    call require(abs(sum(quad%weight*quad%eta))/sum(quad%weight)<tol,'angular axial symmetry')
    do m=1,quad%n_dir
        do f=1,4
            select case(f)
            case(1)
                reflected=fun_J02_reflected_direction_index(quad,m,-1.0,0.0)
            case(2)
                reflected=fun_J02_reflected_direction_index(quad,m,1.0,0.0)
            case(3)
                reflected=fun_J02_reflected_direction_index(quad,m,0.0,-1.0)
            case(4)
                reflected=fun_J02_reflected_direction_index(quad,m,0.0,1.0)
            end select
            call require(abs(quad%speed(reflected)-quad%speed(m))<tol,'reflection stays in speed group')
            call require(abs(quad%weight(reflected)-quad%weight(m))<tol,'reflection preserves measure')
            if (f<=2) then
                call require(abs(quad%mu(reflected)+quad%mu(m))<tol,'radial reflection pairing')
            else
                call require(abs(quad%eta(reflected)+quad%eta(m))<tol,'axial reflection pairing')
            end if
        end do
    end do

    ! Intent(out) clears previous successful outputs on every invalid call.
    call invalid([0.0],SN_ERR_SPEED_EDGES)
    call invalid([real ::],SN_ERR_SPEED_EDGES)
    call invalid([-0.1,1.0],SN_ERR_SPEED_EDGES)
    call invalid([0.1,1.0],SN_ERR_SPEED_EDGES)
    call invalid([0.0,1.0,1.0],SN_ERR_SPEED_EDGES)
    call invalid([0.0,2.0,1.0],SN_ERR_SPEED_EDGES)
    bad=[0.0,1.0,ieee_value(0.0,ieee_quiet_nan)]
    call invalid(bad,SN_ERR_SPEED_EDGES)
    bad(3)=ieee_value(0.0,ieee_positive_inf)
    call invalid(bad,SN_ERR_SPEED_EDGES)
    call invalid([0.0,huge(1.0)],SN_ERR_SPEED_RANGE)
    call invalid([0.0,tiny(1.0)],SN_ERR_SPEED_RANGE)
    call sub_J02_build_phase_quadrature_from_edges(16,[0.0,0.0],'midpoint',quad,ierr)
    call require(ierr==SN_ERR_SPEED_EDGES,'invalid edges propagated')
    call require(quad%n_dir==0.and..not.allocated(quad%speed),'no stale phase object after failure')
    call sub_J02_build_phase_quadrature_from_edges(7,edge,'midpoint',quad,ierr)
    call require(ierr==SN_ERR_ANGLE_COUNT,'angle constraint retained')
    call sub_J02_build_phase_quadrature_from_edges(16,edge,'unsupported',quad,ierr)
    call require(ierr==SN_ERR_ANGLE_SCHEME,'angle scheme constraint retained')

    ! Explicit uniform edges reproduce the original interface (up to roundoff).
    call sub_J02_build_phase_quadrature(16,5,'midpoint',4.0,uniform,ierr)
    call success('original uniform interface')
    edge=[(real(m)*0.8,m=0,5)]
    call sub_J02_build_phase_quadrature_from_edges(16,edge,'midpoint',explicit_uniform,ierr)
    call success('explicit uniform interface')
    call require(maxval(abs(uniform%speed-explicit_uniform%speed))<tol,'uniform node compatibility')
    call require(maxval(abs(uniform%weight-explicit_uniform%weight))<tol,'uniform weight compatibility')
    call sub_J02_initialize_mesh([1.0,1.3,2.0],[0.0,0.4,1.0], &
        reshape([.true.,.true.,.true.,.true.],[2,2]),mesh,ierr)
    call success('mesh')
    call sub_J02_build_geometry(mesh,1.0,geo,ierr)
    call success('geometry')
    call sub_J02_initialize_boundary_types(mesh,boundary,ierr)
    call success('boundary')
    frequency=reshape([0.2,0.3,0.4,0.1],[2,2])
    do mode=1,2
        quad=uniform
        if (mode==2) quad=explicit_uniform
        call inputs()
        call sub_J02_solve_transport(mesh,geo,quad,boundary,sigma,result,ierr,zlo_inflow=inlet)
        call success('uniform transport compatibility')
        if (mode==1) reference=result
    end do
    err=maxval(abs(result%psi-reference%psi))/maxval(abs(reference%psi))
    call require(err<tol,'uniform edges preserve transport distribution')
    call require(maxval(abs(result%density-reference%density))/maxval(reference%density)<tol, &
        'uniform edges preserve reconstructed density')
    write(*,'(a,es24.15)') 'VALUE: explicit/uniform transport relative difference: ',err

    ! Exercise nonuniform groups with partial inlet, all wall models and nu/v.
    edge=[0.0,0.125,0.5,1.0,2.0,4.0]
    call sub_J02_build_phase_quadrature_from_edges(16,edge,'midpoint',quad,ierr)
    call success('nonuniform transport grid')
    call inputs()
    boundary%face_r_lo(1,:)=SN_FACE_WALL
    boundary%face_r_hi(2,:)=SN_FACE_WALL
    call sub_J02_build_partial_zlo_inlet(mesh,1.1,1.75,fraction,lo,hi,ierr)
    call success('partial inlet')
    call sub_J02_configure_zlo_partial_inlet_boundary(mesh,fraction,boundary,ierr)
    call success('partial boundary')
    options%max_iterations=1000
    options%tolerance=max(1.e-11,8.0*epsilon(1.0))
    do mode=0,2
        options%diffuse_fraction=0.5*real(mode)
        call sub_J02_solve_transport(mesh,geo,quad,boundary,sigma,result,ierr,zlo_inflow=inlet, &
            wall_shape=wall,options=options,zlo_source_xi_lo=lo,zlo_source_xi_hi=hi)
        call success('nonuniform reflecting transport')
        call require(result%converged,'reflection converged')
        incoming=sum(result%inflow_flux(SN_Z_LO,:,1)*geo%area_z_lo(:,1))
        outgoing=sum(result%outflow_flux(SN_Z_HI,:,2)*geo%area_z_hi(:,2)) &
            -sum(result%outflow_flux(SN_Z_LO,:,1)*geo%area_z_lo(:,1))
        lost=sum(frequency*result%density*geo%volume)
        balance=abs(incoming-outgoing-lost)/incoming
        call require(balance<100.0*options%tolerance,'nonuniform inlet/outlet/loss balance')
        call require(minval(result%psi(1,:,:,:)-abs(result%psi(2,:,:,:))-abs(result%psi(3,:,:,:)))>=-tol, &
            'nonuniform transport positivity')
        write(*,'(a,i2,i5,2es24.15)') 'VALUE: wall mode/iterations/balance/inventory: ',mode,result%iterations, &
            balance,sum(result%density*geo%volume)
    end do
    print *, 'RESULT: PASS'
contains
    subroutine require(condition,label)
        logical,intent(in)::condition
        character(len=*),intent(in)::label
        if (.not.condition) then
            print *, 'FAIL: ',label
            error stop 1
        end if
    end subroutine require
    subroutine success(label)
        character(len=*),intent(in)::label
        if (ierr/=SN_SUCCESS) then
            print *,label,': ',trim(fun_J02_error_message(ierr))
            error stop 1
        end if
    end subroutine success
    subroutine invalid(edges,expected)
        real,intent(in)::edges(:)
        integer,intent(in)::expected
        call sub_J02_build_speed_groups_from_edges(edges,speed,weight,ierr)
        call require(ierr==expected,'explicit-grid error code')
        call require(.not.allocated(speed).and..not.allocated(weight),'no outputs on invalid grid')
    end subroutine invalid
    subroutine inputs()
        call sub_J02_build_drifted_maxwellian_inflow_shape(quad,0.7,1.380649e-23,0.0,0.5,shape,ierr)
        call success('inlet shape')
        call sub_J02_normalize_inflow_flux(quad,0.0,-1.0,1.0,shape,inlet,ierr)
        call success('inlet normalization')
        call sub_J02_build_wall_maxwell_shape(quad,0.7,1.380649e-23,wall,ierr)
        call success('wall shape')
        call sub_J02_build_sigma_from_frequency(quad,frequency,sigma,ierr)
        call success('speed-dependent removal')
    end subroutine inputs
end program test_J02_nonuniform_quadrature
