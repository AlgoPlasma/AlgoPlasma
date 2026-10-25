! Controlled velocity-grid comparison; synthetic distributions, no CEX operator.
program compare_speed_grids
    use mod_J02_neutral_sn_transport_2Drz
    implicit none
    real,parameter :: kb=1.380649e-23, mass=2.18017e-25, cold_t=550.0
    real,parameter :: cold_u=300.0, fast_u=12000.0, fast_s=600.0, cutoff=16000.0
    integer,parameter :: counts(6)=[16,32,64,128,256,512]
    character(len=12),parameter :: schemes(3)=[character(len=12)::'uniform','power2','piecewise']
    character(len=12),parameter :: cases(3)=[character(len=12)::'cold','fast','mixture']
    type(sn_quadrature_type) :: quad
    type(sn_mesh_2drz_type) :: mesh
    type(sn_geometry_2drz_type) :: geo
    type(sn_boundary_2drz_type) :: boundary
    type(sn_transport_result_type) :: reference, result
    real,allocatable :: shape(:), inlet(:), sigma(:,:,:)
    real :: values(4), exact(4), cold_s, r(3), z(7), nu(2,6), vin,vout,lost,balance
    real :: density_error,flux_error, inventory_error,outflow_error,t0,t1,ref_out
    integer :: is,ig,ic,ia,j,ierr,u,ua,ut,nang
    character(len=1024) :: folder
    call get_command_argument(1,folder)
    if (len_trim(folder)==0) error stop 'supply an existing output directory'
    cold_s=sqrt(kb*cold_t/mass)
    open(newunit=u,file=trim(folder)//'/moments.csv',status='replace')
    write(u,'(a)') 'scheme,n_speeds,n_angles,case,density,jz,v2,forward_flux,'// &
        'density_exact,jz_exact,v2_exact,forward_flux_exact'
    do is=1,3
        do ig=1,size(counts)
            call build_grid(trim(schemes(is)),counts(ig),512,cutoff)
            do ic=1,3
                call distribution(ic)
                call integrate(values)
                call analytic(ic,exact)
                write(u,'(a,2(a,i0),3a,8(a,es25.16e3))') trim(schemes(is)),',',counts(ig),',',512, &
                    ',',trim(cases(ic)),'',(',',values(j),j=1,4),(',',exact(j),j=1,4)
            end do
        end do
    end do
    close(u)
    open(newunit=ua,file=trim(folder)//'/angle_cutoff.csv',status='replace')
    write(ua,'(a)') 'study,n_speeds,n_angles,cutoff,case,density,jz,v2,forward_flux'
    do ia=1,4
        nang=64*2**ia
        call build_grid('piecewise',512,nang,cutoff)
        do ic=1,3
            call distribution(ic)
            call integrate(values)
            write(ua,'(a,2(a,i0),a,es25.16e3,2a,4(a,es25.16e3))') 'angle',',',512,',',nang, &
                ',',cutoff,',',trim(cases(ic)),(',',values(j),j=1,4)
        end do
    end do
    do ig=1,3
        call build_grid('uniform',4096,512,12000.0+2000.0*ig)
        do ic=1,3
            call distribution(ic)
            call integrate(values)
            write(ua,'(a,2(a,i0),a,es25.16e3,2a,4(a,es25.16e3))') 'cutoff',',',4096,',',512, &
                ',',quad%speed_max,',',trim(cases(ic)),(',',values(j),j=1,4)
        end do
    end do
    close(ua)

    ! Fixed spatial/angle discretization isolates speed-grid error in a lossy open channel.
    r=[0.015,0.020,0.025]
    z=[(0.04*real(j)/6.0,j=0,6)]
    call sub_J02_initialize_mesh(r,z,spread(spread(.true.,1,2),2,6),mesh,ierr)
    call success('comparison mesh')
    call sub_J02_build_geometry(mesh,2*acos(-1.0),geo,ierr)
    call success('comparison geometry')
    call sub_J02_initialize_boundary_types(mesh,boundary,ierr)
    call success('comparison boundaries')
    nu=20000.0
    call solve('uniform',16384,128)
    reference=result
    deallocate(reference%psi)
    ref_out=vout
    open(newunit=ut,file=trim(folder)//'/transport.csv',status='replace')
    write(ut,'(a)') 'scheme,n_speeds,n_angles,density_L1,axial_flux_L1,inventory_error,'// &
        'outflow_error,balance,inventory,outflow,cpu_seconds'
    call row('reference',16384,128)
    call solve('uniform',8192,128)
    call row('reference_check',8192,128)
    do is=1,3
        do ig=1,size(counts)
            call solve(trim(schemes(is)),counts(ig),128)
            call row(trim(schemes(is)),counts(ig),128)
        end do
    end do
    ! Angular sensitivity is reported separately and not folded into speed-grid errors.
    call solve('piecewise',512,256)
    call row('angle_check',512,256)
    close(ut)
    print *, 'RESULT: PASS (all transport solves and particle balances)'
contains
    subroutine success(label)
        character(len=*),intent(in)::label
        if (ierr/=SN_SUCCESS) then
            print *, label,': ',trim(fun_J02_error_message(ierr))
            error stop 1
        end if
    end subroutine success
    subroutine build_grid(scheme,n,na,vmax)
        character(len=*),intent(in)::scheme
        integer,intent(in)::n,na
        real,intent(in)::vmax
        real,allocatable::edge(:)
        real::knots(5)
        integer::i,k,offset,segments(4)
        if (scheme=='uniform') then
            call sub_J02_build_phase_quadrature(na,n,'midpoint',vmax,quad,ierr)
        else
            allocate(edge(n+1))
            if (scheme=='power2') then
                edge=[(vmax*(real(i)/n)**2,i=0,n)]
            else if (scheme=='piecewise') then
                if (mod(n,16)/=0) error stop 'piecewise count must be divisible by 16'
                if (abs(vmax-cutoff)>epsilon(vmax)*vmax) error stop 'piecewise benchmark cutoff'
                knots=[0.0,1600.0,9000.0,15000.0,16000.0]
                segments=[8,2,5,1]*(n/16)
                edge(1)=0.0
                offset=0
                do k=1,4
                    do i=1,segments(k)
                        edge(offset+i+1)=knots(k)+(knots(k+1)-knots(k))*real(i)/segments(k)
                    end do
                    offset=offset+segments(k)
                end do
            else
                error stop 'unknown speed grid'
            end if
            call sub_J02_build_phase_quadrature_from_edges(na,edge,'midpoint',quad,ierr)
        end if
        call success('comparison quadrature')
    end subroutine build_grid
    subroutine distribution(icase)
        integer,intent(in)::icase
        real,allocatable::cold(:),fast(:)
        call sub_J02_build_drifted_maxwellian_inflow_shape(quad,cold_t,mass,0.0,cold_u,cold,ierr)
        call success('cold shape')
        call sub_J02_build_drifted_maxwellian_inflow_shape(quad,fast_s**2*mass/kb,mass,0.0,fast_u,fast,ierr)
        call success('fast shape')
        select case(icase)
        case(1)
            shape=cold
        case(2)
            shape=fast
        case(3)
            shape=0.9*cold+0.1*fast
        end select
    end subroutine distribution
    subroutine integrate(value)
        real,intent(out)::value(4)
        value(1)=sum(quad%weight*shape)
        value(2)=sum(quad%weight*quad%speed*quad%eta*shape)
        value(3)=sum(quad%weight*quad%speed**2*shape)
        value(4)=sum(quad%weight*quad%speed*max(quad%eta,0.0)*shape)
    end subroutine integrate
    subroutine analytic(icase,value)
        integer,intent(in)::icase
        real,intent(out)::value(4)
        real::c(4),f(4)
        c=[1.0,cold_u,cold_u**2+2*cold_s**2,positive_flux(cold_u,cold_s)]
        f=[1.0,fast_u,fast_u**2+2*fast_s**2,positive_flux(fast_u,fast_s)]
        select case(icase)
        case(1)
            value=c
        case(2)
            value=f
        case(3)
            value=0.9*c+0.1*f
        end select
    end subroutine analytic
    real function positive_flux(drift,thermal)
        real,intent(in)::drift,thermal
        positive_flux=0.5*drift*(1.0+erf(drift/(sqrt(2.0)*thermal))) &
            +thermal/sqrt(2*acos(-1.0))*exp(-0.5*(drift/thermal)**2)
    end function positive_flux
    subroutine solve(scheme,n,na)
        character(len=*),intent(in)::scheme
        integer,intent(in)::n,na
        call cpu_time(t0)
        call build_grid(scheme,n,na,cutoff)
        call distribution(3)
        ! Transport comparison fixes total inlet flux; raw moments above remain unnormalized.
        call sub_J02_normalize_inflow_flux(quad,0.0,-1.0,1.0,shape,inlet,ierr)
        call success('comparison inlet normalization')
        call sub_J02_build_sigma_from_frequency(quad,nu,sigma,ierr)
        call success('comparison loss')
        call sub_J02_solve_transport(mesh,geo,quad,boundary,sigma,result,ierr,zlo_inflow=inlet)
        call success('comparison transport')
        call cpu_time(t1)
        vin=sum(result%inflow_flux(SN_Z_LO,:,1)*geo%area_z_lo(:,1))
        vout=-sum(result%outflow_flux(SN_R_LO,1,:)*geo%area_r_lo(1,:)) &
            +sum(result%outflow_flux(SN_R_HI,2,:)*geo%area_r_hi(2,:)) &
            -sum(result%outflow_flux(SN_Z_LO,:,1)*geo%area_z_lo(:,1)) &
            +sum(result%outflow_flux(SN_Z_HI,:,6)*geo%area_z_hi(:,6))
        lost=sum(nu*result%density*geo%volume)
        balance=abs(vin-vout-lost)/vin
        if (balance>1.e-10) error stop 'comparison particle balance'
        if (minval(result%psi(1,:,:,:)-abs(result%psi(2,:,:,:))-abs(result%psi(3,:,:,:))) < -1.e-15) &
            error stop 'comparison negative distribution'
    end subroutine solve
    subroutine row(scheme,n,na)
        character(len=*),intent(in)::scheme
        integer,intent(in)::n,na
        density_error=sum(abs(result%density-reference%density)*geo%volume)/sum(reference%density*geo%volume)
        flux_error=sum(abs(result%flux_z-reference%flux_z))/sum(abs(reference%flux_z))
        inventory_error=abs(sum((result%density-reference%density)*geo%volume))/sum(reference%density*geo%volume)
        outflow_error=abs(vout-ref_out)/abs(ref_out)
        write(ut,'(a,2(a,i0),8(a,es25.16e3))') scheme,',',n,',',na,',',density_error,',',flux_error, &
            ',',inventory_error,',',outflow_error,',',balance,',',sum(result%density*geo%volume),',',vout,',',t1-t0
        write(*,'(a,a,i6,a,es12.4)') 'transport ',scheme,n,' density L1=',density_error
    end subroutine row
end program compare_speed_grids
