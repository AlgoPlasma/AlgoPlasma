program test_b04
    use mod_B04_scatter_3d_raz_nonuniform
    use mod_B02_deposit_charge_3d_cyl
    use, intrinsic :: ieee_arithmetic, only: ieee_value, ieee_quiet_nan, ieee_is_finite
    implicit none
    integer :: checks = 0
    real, parameter :: tol = 2048.0*epsilon(1.0)
    real :: pi, r_axis(0:4), r_ring(0:4), angles(0:4), zz(0:3)
    character(len=1024) :: export_dir
    logical :: export_data
    integer :: nodes_unit, metrics_unit, totals_unit

    ! Optional result export; all existing numerical cases and assertions are retained.
    call get_command_argument(1,export_dir)
    export_data=len_trim(export_dir)>0
    if (export_data) then
        open(newunit=nodes_unit,file=trim(export_dir)//'/axis_nodes.csv',status='replace')
        open(newunit=metrics_unit,file=trim(export_dir)//'/axis_metrics.csv',status='replace')
        open(newunit=totals_unit,file=trim(export_dir)//'/axis_totals.csv',status='replace')
        write(nodes_unit,'(a)') 'j,k,angular_width,phi_measure,density_before,density_after,reference'
        write(metrics_unit,'(a)') 'case,metric,error,limit'
        write(totals_unit,'(a)') 'case,k,before,after'
    end if
    pi = acos(-1.0)
    r_axis = [0.0,0.1,0.23,0.7,1.0]
    r_ring = [0.2,0.28,0.5,0.65,1.2]
    angles = [0.0,0.2,1.1,3.0,2.0*pi]
    zz = [-0.3,0.05,0.6,1.0]
    call hand_case()
    call physical_endpoints_case()
    call linear_projection_case()
    call quadrature_case(r_axis,angles,zz,.true.,'axis/periodic')
    call quadrature_case(r_ring,angles+0.4,zz,.true.,'annulus/periodic')
    call quadrature_case(r_ring,angles*0.1+0.4,zz,.false.,'annulus/angular faces')
    call quadrature_case([0.0,1.0],[0.0,2.0*pi],[0.0,1.0],.true.,'one angular cell')
    call axis_case()
    call uniform_b02_case()
    call rejection_cases()
    call range_guard_cases()
    call projection_range_cases()
    if (export_data) then
        close(nodes_unit)
        close(metrics_unit)
        close(totals_unit)
    end if
    write(*,'(a,i0,a,i0)') 'B04 PASS: checks=',checks,', real_bits=',storage_size(1.0)

contains

    subroutine require(condition,label)
        logical, intent(in) :: condition
        character(*), intent(in) :: label
        if (.not. condition) then
            write(*,'(a)') 'FAIL: '//label
            error stop 1
        end if
        checks = checks+1
        write(*,'(a)') 'PASS: '//label
    end subroutine require

    subroutine close_value(actual,expected,label)
        real, intent(in) :: actual,expected
        character(*), intent(in) :: label
        call require(abs(actual-expected) <= tol*max(1.0,abs(expected)),label)
    end subroutine close_value

    subroutine metric(value,label)
        real, intent(in) :: value
        character(*), intent(in) :: label
        write(*,'(a,es24.16)') 'METRIC: '//label//' = ',value
    end subroutine metric

    subroutine success(ierr,label)
        integer, intent(in) :: ierr
        character(*), intent(in) :: label
        if (ierr /= B04_OK) then
            write(*,'(a,i0)') 'unexpected status '//label//': ',ierr
            error stop 2
        end if
    end subroutine success

    subroutine hand_case()
        real :: r(0:2), a(0:2), z(0:2), v(0:2,0:2,0:2), va(0:2)
        real :: density(0:2,0:2,0:2), mass(0:2,0:2,0:2), pos(3), cc(0:1,0:1,0:1)
        real :: relocated(-3:-1,4:6,9:11), other(0:2,0:2,0:2)
        integer :: ierr
        r=[1.0,2.0,4.0]; a=[0.0,1.0,3.0]; z=[0.0,2.0,3.0]
        call sub_B04_build_geometry(r,a,z,.false.,v,va,ierr)
        call success(ierr,'hand geometry')
        call close_value(1.0/v(0,0,0),1.0/3.0,'hand boundary volume')
        call close_value(1.0/v(1,0,0),7.0/4.0,'hand interior radial volume')
        mass=0.0
        mass(0:1,0:1,0)=reshape([2.25,0.75,2.25,0.75],[2,2])
        mass(0:1,0:1,1)=reshape([0.75,0.25,0.75,0.25],[2,2])
        pos=[1.25,0.5,0.5]
        density=0.0
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.false.,[0,0,0],pos,8.0,v,density,ierr)
        call success(ierr,'hand scatter')
        call require(maxval(abs(density-mass*v)) <= tol*maxval(abs(mass*v)),'eight hand-computed contributions')
        call close_value(sum(density/v),8.0,'hand total amount')
        if (export_data) call export_hand(r,a,z,v,density,mass,pos)
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.false.,[0,0,0],pos,-8.0,v,density,ierr)
        call success(ierr,'opposite charge')
        call close_value(maxval(abs(density)),0.0,'signed amount cancels without clearing')
        density=2.0
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.false.,[0,0,0],pos,0.0,v,density,ierr)
        call success(ierr,'zero amount')
        call close_value(maxval(abs(density-2.0)),0.0,'zero amount preserves existing density')
        relocated=0.0
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.false.,[0,0,0],pos,8.0,v,relocated,ierr)
        call success(ierr,'actual array lower bounds')
        call require(maxval(abs(relocated-mass*v)) <= tol*maxval(abs(mass*v)),'actual array lower bounds are positional')
        density=0.0; other=0.0
        pos=[2.0,0.4,0.6]
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.false.,[0,0,0],pos,1.0,v,density,ierr)
        call success(ierr,'left cell endpoint')
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.false.,[1,0,0],pos,1.0,v,other,ierr)
        call success(ierr,'right cell endpoint')
        call require(maxval(abs(density-other)) <= tol,'internal face agrees from adjacent cells')
        density=1.0
        call sub_B04_project_density(r,.false.,density,cc,ierr)
        call success(ierr,'constant projection')
        call require(maxval(abs(cc-1.0)) <= tol,'projection preserves constant field')
    end subroutine hand_case

    subroutine physical_endpoints_case()
        real :: r(0:1),a(0:1),z(0:1),v(0:1,0:1,0:1),va(0:1),density(0:1,0:1,0:1)
        real :: expected(0:1,0:1,0:1)
        integer :: ierr
        r=[1.0,3.0]; a=[0.2,0.7]; z=[-0.4,0.6]
        call sub_B04_build_geometry(r,a,z,.false.,v,va,ierr)
        call success(ierr,'physical corner geometry')
        density=0.0
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.false.,[0,0,0],[r(0),a(0),z(0)], &
            2.0,v,density,ierr)
        call success(ierr,'lower physical corner')
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.false.,[0,0,0],[r(1),a(1),z(1)], &
            3.0,v,density,ierr)
        call success(ierr,'upper physical corner')
        expected=0.0
        expected(0,0,0)=2.0; expected(1,1,1)=3.0
        call require(maxval(abs(density/v-expected)) <= tol,'physical corners update only their endpoint nodes')
        call close_value(sum(density/v),5.0,'physical corners retain total amount')
    end subroutine physical_endpoints_case

    subroutine linear_projection_case()
        real :: r(0:2),a(0:2),z(0:2),density(0:2,0:2,0:2),cc(0:1,0:1,0:1)
        real :: expected(0:1,0:1,0:1),rmean
        integer :: i,j,k,ierr
        r=[0.0,0.3,1.0]; a=[0.2,0.4,1.1]; z=[-0.4,0.1,0.6]
        do k=0,2
        do j=0,2
        do i=0,2
            density(i,j,k)=2.0+3.0*r(i)-0.7*a(j)+0.4*z(k)
        end do
        end do
        end do
        do k=0,1
        do j=0,1
        do i=0,1
            ! Integrate the physical linear field against r dr dphi dz directly.
            rmean=(2.0/3.0)*(r(i+1)**3-r(i)**3)/(r(i+1)**2-r(i)**2)
            expected(i,j,k)=2.0+3.0*rmean-0.7*(a(j)+a(j+1))/2.0+0.4*(z(k)+z(k+1))/2.0
        end do
        end do
        end do
        call sub_B04_project_density(r,.false.,density,cc,ierr)
        call success(ierr,'linear field projection')
        call metric(maxval(abs(cc-expected))/maxval(abs(expected)),'linear projection relative Linf')
        call require(maxval(abs(cc-expected)) <= tol*maxval(abs(expected)), &
            'projection matches analytic cell-volume average of linear field')
    end subroutine linear_projection_case

    subroutine quadrature_case(r,a,z,periodic,label)
        real, intent(in) :: r(0:),a(0:),z(0:)
        logical, intent(in) :: periodic
        character(*), intent(in) :: label
        real, allocatable :: v(:,:,:),va(:),density(:,:,:),cc(:,:,:),omega(:,:,:),other(:,:,:)
        real :: g(0:1),pos(3),h(3),amount,total,expected,scale,volume,before
        integer :: nr,na,nz,nj,i,j,k,u,w,t,ierr
        nr=size(r)-1; na=size(a)-1; nz=size(z)-1
        nj=na+1
        if (periodic) nj=na
        allocate(v(0:nr,0:nj-1,0:nz),va(0:nj-1),density(0:nr,0:nj-1,0:nz))
        allocate(cc(0:nr-1,0:na-1,0:nz-1),omega(0:nr-1,0:na-1,0:nz-1))
        allocate(other(0:nr,0:nj-1,0:nz))
        call sub_B04_build_geometry(r,a,z,periodic,v,va,ierr)
        call success(ierr,label//' geometry')
        volume=(r(nr)-r(0))*(r(nr)+r(0))/2.0*(a(na)-a(0))*(z(nz)-z(0))
        call close_value(sum(1.0/v),volume,label//' total nodal volume')
        call close_value(sum(va),a(na)-a(0),label//' angular total measure')
        g=[-1.0,1.0]/sqrt(3.0)
        density=0.0
        ! Exact tensor Gauss integration of r times each piecewise linear basis.
        do k=0,nz-1
        do j=0,na-1
        do i=0,nr-1
            h=[r(i+1)-r(i),a(j+1)-a(j),z(k+1)-z(k)]
            omega(i,j,k)=(r(i)+r(i+1))/2.0*product(h)
            do t=0,1
            do w=0,1
            do u=0,1
                pos=[r(i),a(j),z(k)]+h*([g(u),g(w),g(t)]+1.0)/2.0
                amount=3.25*pos(1)*product(h)/8.0
                call sub_B04_scatter_3d_raz_nonuniform(r,a,z,periodic,[i,j,k],pos,amount,v,density,ierr)
                call success(ierr,label//' Gauss scatter')
            end do
            end do
            end do
        end do
        end do
        end do
        call metric(maxval(abs(density-3.25))/3.25,label//' quadrature relative Linf')
        call require(maxval(abs(density-3.25)) <= tol*3.25,label//' uniform physical density by quadrature')
        if (export_data .and. label == 'axis/periodic') call export_uniform(r,a,z,v,density)
        density=0.0; total=0.0; scale=0.0
        do k=0,nz-1
        do j=0,na-1
        do i=0,nr-1
            h=[r(i+1)-r(i),a(j+1)-a(j),z(k+1)-z(k)]
            pos=[r(i),a(j),z(k)]+h*[0.23,0.61,0.47]
            amount=real((-1)**(i+j+k))*(1.0+real(i+2*j+3*k)/13.0)
            call sub_B04_scatter_3d_raz_nonuniform(r,a,z,periodic,[i,j,k],pos,amount,v,density,ierr)
            call success(ierr,label//' signed scatter')
            total=total+amount
            scale=scale+abs(amount)
        end do
        end do
        end do
        call metric(abs(sum(density/v)-total)/scale,label//' signed total normalized error')
        call require(abs(sum(density/v)-total) <= tol*scale,label//' signed total amount')
        if (r(0) <= 0.0) then
            before=sum(density/v)
            call sub_B04_average_axis(va,density(0,:,:),ierr)
            call success(ierr,label//' axis')
            call require(abs(sum(density/v)-before) <= tol*scale,label//' axis preserves amount')
            call require(maxval(abs(density(0,:,:)-spread(density(0,0,:),1,nj))) <= tol, &
                label//' axis single value')
            call axis_metric(label,'total_normalized',abs(sum(density/v)-before)/scale,tol)
            call axis_metric(label,'angular_spread', &
                maxval(abs(density(0,:,:)-spread(density(0,0,:),1,nj))),tol)
            if (export_data) write(totals_unit,'(a,a,i0,2(a,es25.17e3))') &
                trim(label),',',-1,',',before,',',sum(density/v)
        end if
        call sub_B04_project_density(r,periodic,density,cc,ierr)
        call success(ierr,label//' projection')
        call metric(abs(sum(cc*omega)-sum(density/v))/scale,label//' projection total normalized error')
        call require(abs(sum(cc*omega)-sum(density/v)) <= tol*scale,label//' node-to-cell conserves amount')
        if (periodic) then
            density=0.0; other=0.0
            pos=[(r(0)+r(1))/2.0,a(na),(z(0)+z(1))/2.0]
            call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.true.,[0,na-1,0],pos,2.0,v,density,ierr)
            call success(ierr,label//' upper seam')
            pos(2)=a(0)
            call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.true.,[0,0,0],pos,2.0,v,other,ierr)
            call success(ierr,label//' lower seam')
            call require(maxval(abs(density-other)) <= tol*max(1.0,maxval(abs(other))), &
                label//' periodic seam equivalence')
            call close_value(sum(density/v),2.0,label//' seam counted once')
        else
            expected=(a(1)-a(0))/2.0
            call close_value(va(0),expected,label//' physical lower half volume')
            call close_value(va(na),(a(na)-a(na-1))/2.0,label//' physical upper half volume')
        end if
    end subroutine quadrature_case

    subroutine axis_case()
        real :: va(0:3),widths(0:3),rho(0:3,0:1),reference,before(0:1),rho_before(0:3,0:1)
        integer :: j,k,ierr
        widths=[0.2,0.9,1.9,2.0*pi-3.0]
        do j=0,3
            va(j)=(widths(modulo(j-1,4))+widths(j))/2.0
        end do
        rho(:,0)=[1.0,2.0,4.0,8.0]
        rho(:,1)=-rho(:,0)
        rho_before=rho
        before=[sum(va*rho(:,0)),sum(va*rho(:,1))]
        reference=4.6432394487827064
        call sub_B04_average_axis(va,rho,ierr)
        call success(ierr,'nonuniform axis example')
        call close_value(rho(0,0),reference,'axis weighted hand reference')
        call close_value(sum(va*rho(:,0)),before(0),'axis weighted amount')
        call close_value(sum(va*rho(:,1)),before(1),'axis negative charge amount')
        call require(abs(rho(0,0)-3.75) > 0.1,'axis uses volume weighting rather than node count')
        call axis_metric('hand','mean_absolute',abs(rho(0,0)-reference),tol*max(1.0,abs(reference)))
        call axis_metric('hand','positive_total_absolute', &
            abs(sum(va*rho(:,0))-before(0)),tol*max(1.0,abs(before(0))))
        call axis_metric('hand','negative_total_absolute', &
            abs(sum(va*rho(:,1))-before(1)),tol*max(1.0,abs(before(1))))
        if (export_data) then
            do k=0,1
                write(totals_unit,'(a,a,i0,2(a,es25.17e3))') &
                    'hand',',',k,',',before(k),',',sum(va*rho(:,k))
                do j=0,3
                    write(nodes_unit,'(i0,a,i0,5(a,es25.17e3))') j,',',k,',',widths(j),',',va(j), &
                        ',',rho_before(j,k),',',rho(j,k),',',real((-1)**k)*reference
                end do
            end do
        end if
    end subroutine axis_case

    subroutine axis_metric(case_name,name,error,limit)
        character(*), intent(in) :: case_name,name
        real, intent(in) :: error,limit
        if (export_data) write(metrics_unit,'(a,a,a,2(a,es25.17e3))') &
            trim(case_name),',',trim(name),',',error,',',limit
    end subroutine axis_metric

    subroutine uniform_b02_case()
        integer, parameter :: nr=4,na=6,nz=3
        real :: r(0:nr),a(0:na),z(0:nz),v(0:nr,0:na-1,0:nz),va(0:na-1)
        real :: rho(0:nr,0:na-1,0:nz),old(0:nr,0:na-1,0:nz),pos(3)
        real :: dr,dphi,dz,qp,wp,f(3)
        integer :: i,p,cell(3),ierr
        dr=0.17; dphi=2.0*pi/real(na); dz=0.23
        do i=0,nr
            r(i)=real(i)*dr
        end do
        do i=0,na
            a(i)=real(i)*dphi
        end do
        do i=0,nz
            z(i)=real(i)*dz
        end do
        call sub_B04_build_geometry(r,a,z,.true.,v,va,ierr)
        call success(ierr,'uniform geometry')
        rho=0.0; old=0.0
        do p=1,71
            cell=[modulo(p,nr),modulo(3*p+1,na),modulo(p+1,nz)]
            f=[0.13+0.01*real(modulo(p,61)),0.27,0.65]
            pos=[r(cell(1)),a(cell(2)),z(cell(3))]+f*[dr,dphi,dz]
            qp=real((-1)**p)*0.3
            wp=1.0+0.1*real(p)
            call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.true.,cell,pos,qp*wp,v,rho,ierr)
            call success(ierr,'uniform B04 call')
            call sub_B02_deposit_charge_3d_cyl(pos(1),pos(2),pos(3),qp,wp,dr,dphi,dz,nr,na-1,nz,old)
        end do
        call metric(maxval(abs(rho-old))/max(1.0,maxval(abs(old))),'B02 comparison relative Linf')
        call require(maxval(abs(rho-old)) <= tol*max(1.0,maxval(abs(old))), &
            'uniform limit agrees with exact public B02 routine')
    end subroutine uniform_b02_case

    subroutine rejection_cases()
        real :: r(0:2),a(0:2),z(0:2),v(0:2,0:2,0:2),va(0:2),rho(0:2,0:2,0:2)
        real :: badr(0:2),badv(0:2,0:2,0:2),badva(0:2),cc(0:1,0:1,0:1),axis(0:2,0:1),pos(3)
        integer :: ierr
        r=[1.0,2.0,4.0]; a=[0.0,1.0,3.0]; z=[0.0,2.0,3.0]
        call sub_B04_build_geometry(r,a,z,.false.,v,va,ierr)
        call success(ierr,'rejection setup')
        badr=[1.0,1.0,4.0]; badv=-7.0; badva=-7.0
        call sub_B04_build_geometry(badr,a,z,.false.,badv,badva,ierr)
        call require(ierr==B04_BAD_GRID .and. all(badv==-7.0) .and. all(badva==-7.0), &
            'reject nonmonotone grid without output writes')
        badr=r; badr(1)=ieee_value(1.0,ieee_quiet_nan)
        call sub_B04_build_geometry(badr,a,z,.false.,badv,badva,ierr)
        call require(ierr==B04_BAD_GRID .and. all(badv==-7.0),'reject nonfinite grid')
        call sub_B04_build_geometry(r,a,z,.true.,badv,badva,ierr)
        call require(ierr==B04_BAD_SHAPE .and. all(badv==-7.0),'reject periodic array shape mismatch')
        rho=5.0; pos=[1.25,0.5,0.5]
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.false.,[-1,0,0],pos,1.0,v,rho,ierr)
        call require(ierr==B04_BAD_CELL .and. all(rho==5.0),'reject invalid cell before indexing')
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.false.,[0,0,0],[2.5,0.5,0.5],1.0,v,rho,ierr)
        call require(ierr==B04_BAD_VALUE .and. all(rho==5.0),'reject position outside supplied cell')
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.false.,[0,0,0],pos, &
            ieee_value(1.0,ieee_quiet_nan),v,rho,ierr)
        call require(ierr==B04_BAD_VALUE .and. all(rho==5.0),'reject nonfinite particle amount')
        badv=v; badv(1,1,1)=0.0
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.false.,[0,0,0],pos,1.0,badv,rho,ierr)
        call require(ierr==B04_BAD_VOLUME .and. all(rho==5.0),'reject bad last volume without partial scatter')
        axis=6.0; badva=va; badva(2)=-1.0
        call sub_B04_average_axis(badva,axis,ierr)
        call require(ierr==B04_BAD_VOLUME .and. all(axis==6.0),'reject bad axis measure without writes')
        call sub_B04_average_axis(va(0:1),axis,ierr)
        call require(ierr==B04_BAD_SHAPE .and. all(axis==6.0),'reject axis shape mismatch')
        cc=7.0
        call sub_B04_project_density(r,.true.,rho,cc,ierr)
        call require(ierr==B04_BAD_SHAPE .and. all(cc==7.0),'reject projection shape without writes')
        rho(2,2,2)=ieee_value(1.0,ieee_quiet_nan)
        call sub_B04_project_density(r,.false.,rho,cc,ierr)
        call require(ierr==B04_BAD_VALUE .and. all(cc==7.0), &
            'reject nonfinite last projection node without partial writes')
    end subroutine rejection_cases

    subroutine range_guard_cases()
        real :: r(0:1),a(0:1),z(0:1),v(0:1,0:1,0:1),va(0:1)
        real :: rho(0:1,0:1,0:1),saved(0:1,0:1,0:1),expected(0:1,0:1,0:1)
        real :: vp(0:1,0:0,0:1),vap(0:0),periodic_rho(0:1,0:0,0:1),periodic_saved(0:1,0:0,0:1)
        real :: limit,amount,increment,reference
        integer :: ierr

        limit=huge(1.0)
        r=[0.0,1.0]; a=[0.0,6.0]; z=[0.0,4.0/limit]
        v=-7.0; va=-7.0
        call sub_B04_build_geometry(r,a,z,.false.,v,va,ierr)
        call require(ierr==B04_BAD_VOLUME .and. all(v==-7.0) .and. all(va==-7.0), &
            'reject reciprocal limit without output writes')

        z(1)=4.0*nearest(1.0/limit,1.0)
        call sub_B04_build_geometry(r,a,z,.false.,v,va,ierr)
        call require(ierr==B04_OK .and. all(ieee_is_finite(v)) .and. all(v>0.0), &
            'accept representable inverse volume adjacent to limit')

        z=[0.0,1.0]
        call sub_B04_build_geometry(r,a,z,.false.,v,va,ierr)
        call success(ierr,'range-check normal geometry')
        ! All eight increments are nonzero; only the last destination overflows.
        rho=7.0; rho(1,1,1)=0.875*limit; saved=rho
        amount=limit
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.false.,[0,0,0], &
            [0.5,3.0,0.5],amount,v,rho,ierr)
        call require(ierr==B04_BAD_VALUE .and. all(rho==saved), &
            'reject positive density sum overflow without partial writes')

        rho=7.0; rho(1,1,1)=-0.875*limit; saved=rho
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.false.,[0,0,0], &
            [0.5,3.0,0.5],-amount,v,rho,ierr)
        call require(ierr==B04_BAD_VALUE .and. all(rho==saved), &
            'reject negative density sum overflow without partial writes')

        ! Here v(1,1,1)=2, so endpoint amount-to-increment scaling is exact.
        rho=7.0; rho(1,1,1)=0.5*limit; expected=rho
        amount=(0.25*limit)/v(1,1,1)
        expected(1,1,1)=rho(1,1,1)+amount*v(1,1,1)
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.false.,[0,0,0], &
            [r(1),a(1),z(1)],amount,v,rho,ierr)
        call require(ierr==B04_OK .and. all(rho==expected), &
            'accept finite density sum near upper range')

        rho=7.0; rho(1,1,1)=limit; expected=rho; expected(1,1,1)=0.0
        amount=-limit/v(1,1,1)
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.false.,[0,0,0], &
            [r(1),a(1),z(1)],amount,v,rho,ierr)
        call require(ierr==B04_OK .and. all(rho==expected), &
            'accept opposite-sign cancellation at largest finite density')

        ! Subtracting the smaller addend from huge() can round the bound upward.
        rho=7.0; rho(1,1,1)=1.5*spacing(limit); saved=rho
        increment=nearest(limit,-1.0)
        amount=increment/v(1,1,1)
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.false.,[0,0,0], &
            [r(1),a(1),z(1)],amount,v,rho,ierr)
        call require(ierr==B04_BAD_VALUE .and. all(rho==saved), &
            'reject density overflow at rounded addition bound')

        call sub_B04_build_geometry(r,a,z,.true.,vp,vap,ierr)
        call success(ierr,'single-periodic-cell range geometry')
        periodic_rho=7.0; periodic_rho(1,0,1)=0.625*limit; periodic_saved=periodic_rho
        amount=(0.5*limit)/vp(1,0,1)
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.true.,[0,0,0], &
            [r(1),3.0,z(1)],amount,vp,periodic_rho,ierr)
        call require(ierr==B04_BAD_VALUE .and. all(periodic_rho==periodic_saved), &
            'reject overflow on second periodic contribution without writes')

        periodic_rho=7.0; periodic_rho(1,0,1)=-0.625*limit; periodic_saved=periodic_rho
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.true.,[0,0,0], &
            [r(1),3.0,z(1)],-amount,vp,periodic_rho,ierr)
        call require(ierr==B04_BAD_VALUE .and. all(periodic_rho==periodic_saved), &
            'reject negative overflow on repeated periodic target')

        periodic_rho=7.0; periodic_rho(1,0,1)=0.25*limit; periodic_saved=periodic_rho
        increment=amount*0.5*vp(1,0,1)
        reference=(periodic_rho(1,0,1)+increment)+increment
        periodic_saved(1,0,1)=reference
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.true.,[0,0,0], &
            [r(1),3.0,z(1)],amount,vp,periodic_rho,ierr)
        call require(ierr==B04_OK .and. all(periodic_rho==periodic_saved), &
            'finite periodic accumulation keeps both contributions and order')

        rho=7.0; rho(1,1,1)=limit; saved=rho
        call sub_B04_scatter_3d_raz_nonuniform(r,a,z,.false.,[0,0,0], &
            [r(1),a(1),z(1)],0.0,v,rho,ierr)
        call require(ierr==B04_OK .and. all(rho==saved), &
            'zero amount preserves largest finite density')
    end subroutine range_guard_cases

    subroutine projection_range_cases()
        real :: r(0:1),rho(0:1,0:1,0:1),cc(0:0,0:0,0:0)
        real :: periodic_rho(0:1,0:0,0:1),limit,expected,roundoff
        integer :: n,ierr

        limit=huge(1.0)
        roundoff=16.0*epsilon(1.0)
        ! These radii reproduce upper-range rounding overflow in the original
        ! direct sum in double and single precision, respectively.
        do n=2,3
            r=[real(n)/1000.0,1.0]
            rho=limit
            call sub_B04_project_density(r,.false.,rho,cc,ierr)
            call success(ierr,'largest positive constant projection')
            call require(all(ieee_is_finite(cc)) .and. abs(cc(0,0,0)/limit-1.0)<=roundoff, &
                'largest positive constant retains its finite average')

            rho=-limit
            call sub_B04_project_density(r,.false.,rho,cc,ierr)
            call success(ierr,'largest negative constant projection')
            call require(all(ieee_is_finite(cc)) .and. abs(cc(0,0,0)/limit+1.0)<=roundoff, &
                'largest negative constant retains its finite average')
        end do

        ! D(r)=limit*(2*r-1) on [0,1] has cylindrical volume average limit/3.
        r=[0.0,1.0]; rho(0,:,:)=-limit; rho(1,:,:)=limit
        call sub_B04_project_density(r,.false.,rho,cc,ierr)
        call success(ierr,'signed radial projection near floating limit')
        expected=1.0/3.0
        call require(all(ieee_is_finite(cc)) .and. abs(cc(0,0,0)/limit-expected)<=roundoff, &
            'large signed radial field matches analytic cylindrical average')

        ! Two angular vertices share one periodic node; a linear axial field
        ! from +limit to -limit has zero volume average.
        periodic_rho(:,:,0)=limit; periodic_rho(:,:,1)=-limit
        call sub_B04_project_density(r,.true.,periodic_rho,cc,ierr)
        call success(ierr,'large periodic projection')
        call require(all(ieee_is_finite(cc)) .and. abs(cc(0,0,0)/limit)<=roundoff, &
            'large opposite signs cancel in one periodic angular cell')

        r=[0.002,1.0]; rho=limit/2.0
        call sub_B04_project_density(r,.false.,rho,cc,ierr)
        call success(ierr,'projection at direct-sum range boundary')
        call require(all(ieee_is_finite(cc)) .and. abs(cc(0,0,0)/limit-0.5)<=roundoff, &
            'finite constant at direct-sum range boundary')

        rho=0.0
        call sub_B04_project_density(r,.false.,rho,cc,ierr)
        call require(ierr==B04_OK .and. all(cc==0.0),'zero nodal field has zero cell average')
    end subroutine projection_range_cases
    subroutine export_hand(r,a,z,v,density,expected,pos)
        real, intent(in) :: r(0:),a(0:),z(0:),v(0:,0:,0:),density(0:,0:,0:)
        real, intent(in) :: expected(0:,0:,0:),pos(3)
        integer :: unit,i,j,k
        open(newunit=unit,file=trim(export_dir)//'/hand_nodes.csv',status='replace',action='write')
        write(unit,'(a)') 'i,j,k,r,phi,z,volume,density,amount,amount_reference'
        do k=0,size(density,3)-1
        do j=0,size(density,2)-1
        do i=0,size(density,1)-1
            write(unit,'(i0,2(",",i0),7(",",es25.17e3))') &
                i,j,k,r(i),a(j),z(k),1.0/v(i,j,k),density(i,j,k),density(i,j,k)/v(i,j,k),expected(i,j,k)
        end do
        end do
        end do
        close(unit)
        open(newunit=unit,file=trim(export_dir)//'/hand_particle.csv',status='replace',action='write')
        write(unit,'(a)') 'r,phi,z,amount'
        write(unit,'(es25.17e3,3(",",es25.17e3))') pos,8.0
        close(unit)
    end subroutine export_hand

    subroutine export_uniform(r,a,z,v,density)
        real, intent(in) :: r(0:),a(0:),z(0:),v(0:,0:,0:),density(0:,0:,0:)
        integer :: unit,i,j,k
        open(newunit=unit,file=trim(export_dir)//'/uniform_nodes.csv',status='replace',action='write')
        write(unit,'(a)') 'i,j,k,r,phi,z,volume,density,density_reference,relative_error'
        do k=0,size(density,3)-1
        do j=0,size(density,2)-1
        do i=0,size(density,1)-1
            write(unit,'(i0,2(",",i0),7(",",es25.17e3))') &
                i,j,k,r(i),a(j),z(k),1.0/v(i,j,k),density(i,j,k),3.25,(density(i,j,k)-3.25)/3.25
        end do
        end do
        end do
        close(unit)
        open(newunit=unit,file=trim(export_dir)//'/uniform_coordinates.csv',status='replace',action='write')
        write(unit,'(a)') 'axis,index,coordinate'
        do i=0,size(r)-1
            write(unit,'(a,i0,a,es25.17e3)') 'r,',i,',',r(i)
        end do
        do i=0,size(a)-1
            write(unit,'(a,i0,a,es25.17e3)') 'phi,',i,',',a(i)
        end do
        do i=0,size(z)-1
            write(unit,'(a,i0,a,es25.17e3)') 'z,',i,',',z(i)
        end do
        close(unit)
    end subroutine export_uniform
end program test_b04
