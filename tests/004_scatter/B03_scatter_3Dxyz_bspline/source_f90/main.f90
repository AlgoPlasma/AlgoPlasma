#include "../../../../B_Scatter/B01_Scatter_3Dxyz/mod_B01_Scatter_3Dxyz.f90"
#include "../../../../B_Scatter/B03_scatter_3Dxyz_bspline/mod_B03_scatter_3Dxyz_bspline.f90"

program main
    use mod_B01_Scatter_3Dxyz
    use mod_B03_scatter_3Dxyz_bspline
    implicit none

    integer :: unit

    open(newunit=unit, file='output/b03_bspline_scatter.csv', &
        status='replace', action='write')
    write(unit,'(a)') 'case,order,d,metric,reference,value,abs_error,tolerance'

    call run_order1_b01_case(unit)
    call run_conservation_case(unit)
    call run_first_moment_case(unit)
    call run_accumulation_case(unit)

    close(unit)

contains

subroutine run_order1_b01_case(unit)
    implicit none

    integer :: unit

    integer,parameter :: np = 64
    integer,parameter :: order = 1
    integer,parameter :: d = 4
    integer :: il(1:3),iu(1:3)
    real,allocatable :: den_b01(:,:,:),den_b03(:,:,:)
    real :: par3(1:3,1:np),par6(1:6,1:np)
    real :: w,err

    il = (/1,1,1/)
    iu = (/12,11,10/)
    w = 0.375

    allocate(den_b01(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1))
    allocate(den_b03(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1))

    call fill_particles(np,par6)
    par3 = par6(1:3,:)

    den_b01 = 0.0
    den_b03 = 0.0
    call sub_B01_Scatter_3Dxyz(il,iu,den_b01,np,par3,w)
    call sub_B03_scatter_3Dxyz_bspline(il,iu,den_b03,np,par6,w,order)
    err = maxval(abs(den_b03-den_b01))
    call write_metric(unit,'order1_b01_number',order,0,'max_abs_grid', &
        0.0,err,1.0e-12)

    den_b01 = 0.0
    den_b03 = 0.0
    call sub_B01_Scatter_3Dxyz_v(il,iu,den_b01,np,par6,w,d)
    call sub_B03_scatter_3Dxyz_bspline_v(il,iu,den_b03,np,par6,d,w,order)
    err = maxval(abs(den_b03-den_b01))
    call write_metric(unit,'order1_b01_component',order,d,'max_abs_grid', &
        0.0,err,1.0e-12)

    deallocate(den_b01,den_b03)
end subroutine run_order1_b01_case

subroutine run_conservation_case(unit)
    implicit none

    integer :: unit

    integer,parameter :: np = 64
    integer,parameter :: d = 4
    integer :: il(1:3),iu(1:3)
    integer :: order,ng
    real,allocatable :: den(:,:,:)
    real :: par(1:6,1:np)
    real :: w,reference,value

    il = (/1,1,1/)
    iu = (/12,11,10/)
    w = 0.375

    call fill_particles(np,par)

    do order = 0, 4
        ng = (order + 2) / 2
        allocate(den(il(1)-ng:iu(1)+ng,il(2)-ng:iu(2)+ng, &
            il(3)-ng:iu(3)+ng))

        den = 0.0
        call sub_B03_scatter_3Dxyz_bspline(il,iu,den,np,par,w,order)
        reference = w * real(np)
        value = sum(den)
        call write_metric(unit,'number_conservation',order,0,'sum', &
            reference,value,1.0e-11)

        den = 0.0
        call sub_B03_scatter_3Dxyz_bspline_v(il,iu,den,np,par,d,w,order)
        reference = w * sum(par(d,:))
        value = sum(den)
        call write_metric(unit,'component_conservation',order,d,'sum', &
            reference,value,1.0e-11)

        deallocate(den)
    end do
end subroutine run_conservation_case

subroutine run_first_moment_case(unit)
    implicit none

    integer :: unit

    integer,parameter :: np = 64
    integer,parameter :: d = 4
    integer :: il(1:3),iu(1:3)
    integer :: order,ng
    real,allocatable :: den(:,:,:)
    real :: par(1:6,1:np)
    real :: w,m0,mx,my,mz
    real :: refx,refy,refz

    il = (/1,1,1/)
    iu = (/12,11,10/)
    w = 0.375

    call fill_particles(np,par)

    do order = 1, 4
        ng = (order + 2) / 2
        allocate(den(il(1)-ng:iu(1)+ng,il(2)-ng:iu(2)+ng, &
            il(3)-ng:iu(3)+ng))

        den = 0.0
        call sub_B03_scatter_3Dxyz_bspline(il,iu,den,np,par,w,order)
        call compute_moments(order,il,iu,den,m0,mx,my,mz)
        refx = w * sum(par(1,:))
        refy = w * sum(par(2,:))
        refz = w * sum(par(3,:))
        call write_metric(unit,'number_first_moment',order,0,'x_moment', &
            refx,mx,1.0e-10)
        call write_metric(unit,'number_first_moment',order,0,'y_moment', &
            refy,my,1.0e-10)
        call write_metric(unit,'number_first_moment',order,0,'z_moment', &
            refz,mz,1.0e-10)

        den = 0.0
        call sub_B03_scatter_3Dxyz_bspline_v(il,iu,den,np,par,d,w,order)
        call compute_moments(order,il,iu,den,m0,mx,my,mz)
        refx = w * sum(par(d,:) * par(1,:))
        refy = w * sum(par(d,:) * par(2,:))
        refz = w * sum(par(d,:) * par(3,:))
        call write_metric(unit,'component_first_moment',order,d,'x_moment', &
            refx,mx,1.0e-10)
        call write_metric(unit,'component_first_moment',order,d,'y_moment', &
            refy,my,1.0e-10)
        call write_metric(unit,'component_first_moment',order,d,'z_moment', &
            refz,mz,1.0e-10)

        deallocate(den)
    end do
end subroutine run_first_moment_case

subroutine run_accumulation_case(unit)
    implicit none

    integer :: unit

    integer,parameter :: np = 64
    integer,parameter :: order = 3
    integer,parameter :: d = 4
    integer :: il(1:3),iu(1:3)
    integer :: ng,nleft
    real,allocatable :: den_full(:,:,:),den_split(:,:,:)
    real :: par(1:6,1:np)
    real :: w,err

    il = (/1,1,1/)
    iu = (/12,11,10/)
    w = 0.375
    ng = (order + 2) / 2
    nleft = np / 2

    allocate(den_full(il(1)-ng:iu(1)+ng,il(2)-ng:iu(2)+ng, &
        il(3)-ng:iu(3)+ng))
    allocate(den_split(il(1)-ng:iu(1)+ng,il(2)-ng:iu(2)+ng, &
        il(3)-ng:iu(3)+ng))

    call fill_particles(np,par)

    den_full = 0.0
    den_split = 0.0
    call sub_B03_scatter_3Dxyz_bspline(il,iu,den_full,np,par,w,order)
    call sub_B03_scatter_3Dxyz_bspline(il,iu,den_split,nleft, &
        par(:,1:nleft),w,order)
    call sub_B03_scatter_3Dxyz_bspline(il,iu,den_split,np-nleft, &
        par(:,nleft+1:np),w,order)
    err = maxval(abs(den_split-den_full))
    call write_metric(unit,'number_accumulation',order,0,'max_abs_grid', &
        0.0,err,1.0e-12)

    den_full = 0.0
    den_split = 0.0
    call sub_B03_scatter_3Dxyz_bspline_v(il,iu,den_full,np,par,d,w,order)
    call sub_B03_scatter_3Dxyz_bspline_v(il,iu,den_split,nleft, &
        par(:,1:nleft),d,w,order)
    call sub_B03_scatter_3Dxyz_bspline_v(il,iu,den_split,np-nleft, &
        par(:,nleft+1:np),d,w,order)
    err = maxval(abs(den_split-den_full))
    call write_metric(unit,'component_accumulation',order,d,'max_abs_grid', &
        0.0,err,1.0e-12)

    deallocate(den_full,den_split)
end subroutine run_accumulation_case

subroutine fill_particles(np,par)
    implicit none

    integer :: np
    real :: par(1:6,1:np)
    real :: xg(1:4),yg(1:4),zg(1:4)
    integer :: p,ii,jj,kk

    xg = (/2.15,4.35,7.60,10.45/)
    yg = (/2.25,4.80,7.15,9.35/)
    zg = (/2.40,4.55,6.85,8.30/)

    par = 0.0
    p = 0
    do kk = 1, 4
    do jj = 1, 4
    do ii = 1, 4
        p = p + 1
        par(1,p) = xg(ii) + 0.013*real(jj-2) - 0.007*real(kk-2)
        par(2,p) = yg(jj) - 0.011*real(ii-2) + 0.009*real(kk-2)
        par(3,p) = zg(kk) + 0.015*real(ii-2) - 0.005*real(jj-2)
        par(4,p) = 0.35 + 0.021*real(p) - 0.012*real(ii*kk)
        par(5,p) = -0.20 + 0.017*real(jj) + 0.003*real(p)
        par(6,p) = 0.10 - 0.019*real(kk) + 0.002*real(ii*jj)
    end do
    end do
    end do
end subroutine fill_particles

subroutine compute_moments(order,il,iu,den,m0,mx,my,mz)
    implicit none

    integer :: order
    integer :: il(1:3),iu(1:3)
    real,dimension(il(1)-((order+2)/2):iu(1)+((order+2)/2), &
        il(2)-((order+2)/2):iu(2)+((order+2)/2), &
        il(3)-((order+2)/2):iu(3)+((order+2)/2)) :: den
    real :: m0,mx,my,mz

    integer :: i,j,k

    m0 = 0.0
    mx = 0.0
    my = 0.0
    mz = 0.0

    do k = lbound(den,3), ubound(den,3)
    do j = lbound(den,2), ubound(den,2)
    do i = lbound(den,1), ubound(den,1)
        m0 = m0 + den(i,j,k)
        mx = mx + real(i) * den(i,j,k)
        my = my + real(j) * den(i,j,k)
        mz = mz + real(k) * den(i,j,k)
    end do
    end do
    end do
end subroutine compute_moments

subroutine write_metric(unit,case_name,order,d,metric,reference,value,tolerance)
    implicit none

    integer :: unit,order,d
    character(len=*) :: case_name,metric
    real :: reference,value,tolerance
    real :: err

    err = abs(reference - value)
    write(unit,'(a,",",i0,",",i0,",",a,",",es24.16,",",es24.16,",",es24.16,",",es24.16)') &
        trim(case_name),order,d,trim(metric),reference,value,err,tolerance
end subroutine write_metric

end program main
