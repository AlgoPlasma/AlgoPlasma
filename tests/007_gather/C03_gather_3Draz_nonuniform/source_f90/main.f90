! Deterministic C03 fixtures. References are evaluated separately in Python.
program test_c03
    use mod_C03_gather_3Draz_nonuniform
    use, intrinsic :: ieee_arithmetic, only: ieee_value, ieee_quiet_nan
    implicit none
    integer, parameter :: nsample=96
    integer :: il(3),iu(3),n,unit,i,j,k,m,p,cell(3),q,d,lev
    real, allocatable :: rf(:),af(:),zf(:),dr(:),da(:),dz(:),field(:,:,:,:)
    real, allocatable :: face(:,:),center(:,:),width(:,:)
    real :: x(3),raw(3),e(3),b(3),par(6,2),t,period
    character(40) :: mode

    call get_command_argument(1,mode)
    if (len_trim(mode)>0) then
        call invalid_input(trim(mode))
        ! Returning normally is intentional: Python must reject a missing error stop.
        stop
    end if
    open(newunit=unit,file='output/c03_gather.csv',status='replace')
    write(unit,'(a)') 'case,level,sample,component,r,alpha,z,value'
    call run_case('constant',4,0)
    call run_case('uniform',4,1)
    call run_case('nonuniform',4,1)
    call run_case('wrapper',4,1)
    call run_case('cached',4,1)
    call run_case('periodic',4,1)
    call run_case('periodic_cached',4,1)
    call run_case('local_box',4,1)
    call run_case('single_cell_axis',1,1)
    do lev=1,3
        call run_case('smooth',2**(lev+2),2)
    end do
    close(unit)
contains
    subroutine setup(count,case_name,kind)
        integer,intent(in) :: count,kind
        character(*),intent(in) :: case_name
        real :: origin(3),length(3),u,pos(3)
        if (allocated(rf)) deallocate(rf,af,zf,dr,da,dz,field,face,center,width)
        n=count
        ! Non-unit, mixed-sign indices exercise rank-local explicit-shape mapping.
        il=[-2,3,7]; iu=il+n-1
        origin=[0.0,0.2,-0.4]; length=[2.0,1.2,1.6]
        if (case_name=='local_box') origin=[1.3,2.1,3.2]
        if (index(case_name,'periodic')==1) then
            origin(2)=6.0; length(2)=0.6
        end if
        allocate(face(0:n+1,3),center(0:n+1,3),width(0:n+1,3))
        do d=1,3
            do q=0,n
                u=real(q)/real(n)
                if (case_name/='uniform') u=0.65*u+0.35*u*u
                face(q,d)=origin(d)+length(d)*u
            end do
            width(1:n,d)=face(1:n,d)-face(0:n-1,d)
            ! Deliberately unequal ghost widths reveal incorrect boundary distances.
            width(0,d)=0.7*width(1,d)
            width(n+1,d)=1.3*width(n,d)
            center(0,d)=face(0,d)-0.5*width(0,d)
            center(1:n,d)=0.5*(face(0:n-1,d)+face(1:n,d))
            center(n+1,d)=face(n,d)+0.5*width(n+1,d)
            face(n+1,d)=face(n,d)+width(n+1,d)
        end do
        allocate(rf(il(1)-1:iu(1)),af(il(2)-1:iu(2)),zf(il(3)-1:iu(3)))
        allocate(dr(il(1)-1:iu(1)+1),da(il(2)-1:iu(2)+1),dz(il(3)-1:iu(3)+1))
        rf=face(0:n,1); af=face(0:n,2); zf=face(0:n,3)
        dr=width(:,1); da=width(:,2); dz=width(:,3)
        call sub_C03_check_grid(il(1),iu(1),rf,dr)
        call sub_C03_check_grid(il(2),iu(2),af,da)
        call sub_C03_check_grid(il(3),iu(3),zf,dz)
        allocate(field(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1,6))
        ! Sample the analytic function at each component's PHYSICAL location.
        do m=1,6
            do k=il(3)-1,iu(3)+1
                do j=il(2)-1,iu(2)+1
                    do i=il(1)-1,iu(1)+1
                        cell=[i,j,k]-il+1
                        do d=1,3
                            if (m>=4 .or. m==d) then
                                pos(d)=face(cell(d),d)
                            else
                                pos(d)=center(cell(d),d)
                            end if
                        end do
                        field(i,j,k,m)=analytic(pos,m,kind)
                    end do
                end do
            end do
        end do
    end subroutine setup

    real function analytic(pos,component,kind) result(value)
        real,intent(in) :: pos(3)
        integer,intent(in) :: component,kind
        real :: r,a,z,c
        r=pos(1); a=pos(2); z=pos(3); c=real(component)
        select case(kind)
        case(0)
            value=0.25*c-1.0
        case(1)
            value=c+0.1*c*r-0.07*(c+1)*a+0.03*(c+2)*z+0.02*r*a &
                -0.01*c*a*z+0.005*(c+1)*r*z+0.004*c*r*a*z
        case(2)
            value=c+sin(0.7*r+0.2*c)*cos(0.6*a-0.1*c)+0.2*sin(0.8*z+0.3*c)
        case default
            error stop 'test: invalid field kind'
        end select
    end function analytic

    subroutine gather(pos,cache,per,org)
        real,intent(in) :: pos(3)
        integer,intent(in),optional :: cache(3)
        real,intent(in),optional :: per,org
        call sub_C03_gather_3Draz_nonuniform_point( &
            pos,il,iu,rf,af,zf,dr,da,dz,field(:,:,:,1),field(:,:,:,2),field(:,:,:,3), &
            field(:,:,:,4),field(:,:,:,5),field(:,:,:,6),e,b,cache,per,org)
    end subroutine gather

    subroutine wrapper_call(particle,cache,per,org)
        integer,intent(in) :: particle
        integer,intent(in),optional :: cache(3)
        real,intent(in),optional :: per,org
        call sub_C03_gather_3Draz_nonuniform( &
            particle,2,par,il,iu,rf,af,zf,dr,da,dz,field(:,:,:,1),field(:,:,:,2),field(:,:,:,3), &
            field(:,:,:,4),field(:,:,:,5),field(:,:,:,6),e,b,cache,per,org)
    end subroutine wrapper_call

    subroutine run_case(case_name,count,kind)
        character(*),intent(in) :: case_name
        integer,intent(in) :: count,kind
        real :: values(6),par_before(6,2)
        call setup(count,case_name,kind)
        period=2.0*acos(-1.0)
        do p=1,nsample
            do d=1,3
                if (case_name/='smooth' .and. p<=27) then
                    ! Corners, edges, and face interiors of the owned box.
                    t=0.5*real(mod((p-1)/3**(d-1),3))
                    x(d)=face(0,d)+t*(face(n,d)-face(0,d))
                else if (case_name/='smooth' .and. p==28) then
                    x(d)=face(max(1,n/2),d)
                else if (case_name/='smooth' .and. p==29) then
                    x(d)=center(max(1,n/2),d)
                else
                    t=real(mod(p*(13+4*d),101))/101.0
                    if (case_name=='smooth') t=0.1+0.8*t
                    x(d)=face(0,d)+t*(face(n,d)-face(0,d))
                end if
                ! Fixture cache uses an independent linear scan, not C03's search.
                cell(d)=iu(d)
                do q=1,n
                    if (x(d)<=face(q,d)) then
                        cell(d)=il(d)+q-1
                        exit
                    end if
                end do
            end do
            raw=x
            par=-123.0; par(1:3,2)=x
            par_before=par
            select case(case_name)
            case('wrapper')
                call wrapper_call(2)
            case('cached')
                call gather(x,cache=cell)
            case('periodic')
                raw(2)=x(2)+real(mod(p,5)-2)*period
                call gather(raw,per=period,org=0.25)
            case('periodic_cached')
                raw(2)=x(2)+real(mod(p,5)-2)*period
                par(1:3,2)=raw; par_before=par
                call wrapper_call(2,cache=cell,per=period,org=0.25)
            case default
                call gather(x)
            end select
            if (any(abs(par-par_before)>0.0)) error stop 'test: particle data modified'
            values(1:3)=e; values(4:6)=b
            do m=1,6
                write(unit,'(a,3(",",i0),4(",",es24.16e3))') trim(case_name),n,p,m,x,values(m)
            end do
        end do
    end subroutine run_case

    subroutine invalid_input(case_name)
        character(*),intent(in) :: case_name
        call setup(4,'nonuniform',1)
        x=center(2,:);cell=il+1
        par=0.0;par(1:3,2)=x
        select case(case_name)
        case('bad_particle')
            call wrapper_call(3)
        case('negative_radius')
            x(1)=-1.0;call gather(x)
        case('outside')
            x(3)=face(n,3)+0.5;call gather(x)
        case('stale_cell')
            cell(1)=iu(1);call gather(x,cache=cell)
        case('outside_cell')
            cell(1)=il(1)-1;call gather(x,cache=cell)
        case('bad_period')
            call gather(x,per=0.0)
        case('origin_only')
            call gather(x,org=0.5)
        case('bad_width')
            dr(il(1)-1)=0.0;call sub_C03_check_grid(il(1),iu(1),rf,dr)
        case('nan_width')
            dr(il(1))=ieee_value(0.0,ieee_quiet_nan)
            call sub_C03_check_grid(il(1),iu(1),rf,dr)
        case('inconsistent_width')
            dr(il(1))=2.0*dr(il(1));call sub_C03_check_grid(il(1),iu(1),rf,dr)
        case('nonmonotone')
            rf(il(1))=rf(il(1)-1);call sub_C03_check_grid(il(1),iu(1),rf,dr)
        case default
            error stop 'test: unknown negative case'
        end select
    end subroutine invalid_input
end program test_c03
