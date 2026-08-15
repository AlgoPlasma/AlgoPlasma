#include "../../../../C_Gather/C01_gather_3Dxyz/mod_C01_gather_3Dxyz.f90"
#include "../../../../C_Gather/C02_gather_3Dxyz_bspline/mod_C02_gather_3Dxyz_bspline.f90"

program main
    use mod_C01_gather_3Dxyz, only: sub_C01_gather_3Dxyz
    use mod_C02_gather_3Dxyz_bspline, only: sub_C02_gather_3Dxyz_bspline
    implicit none

    integer :: unit

    open(newunit=unit, file='output/c02_bspline_gather.csv', status='replace', action='write')
    write(unit,'(a)') 'case,order,p,component,reference,value,abs_error'

    call run_order1_c01_case(unit)
    call run_constant_case(unit)
    call run_linear_case(unit)

    close(unit)

contains

subroutine run_order1_c01_case(unit)
    implicit none

    integer :: unit

    integer, parameter :: order = 1
    integer, parameter :: np = 64
    integer :: il(1:3), iu(1:3)
    real, allocatable :: Ex(:,:,:), Ey(:,:,:), Ez(:,:,:)
    real, allocatable :: Bx(:,:,:), By(:,:,:), Bz(:,:,:)
    real :: par(1:6,1:np)
    real :: E_c01(1:3), B_c01(1:3)
    real :: E_bs(1:3), B_bs(1:3)
    integer :: p, i, j, k

    il = (/1, 1, 1/)
    iu = (/9, 8, 7/)

    allocate(Ex(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    allocate(Ey(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    allocate(Ez(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    allocate(Bx(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    allocate(By(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    allocate(Bz(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))

    do k = il(3)-1, iu(3)+1
    do j = il(2)-1, iu(2)+1
    do i = il(1)-1, iu(1)+1
        Ex(i,j,k) = nonlinear_component(1,i,j,k)
        Ey(i,j,k) = nonlinear_component(2,i,j,k)
        Ez(i,j,k) = nonlinear_component(3,i,j,k)
        Bx(i,j,k) = nonlinear_component(4,i,j,k)
        By(i,j,k) = nonlinear_component(5,i,j,k)
        Bz(i,j,k) = nonlinear_component(6,i,j,k)
    end do
    end do
    end do

    call fill_c01_particles(np,par)

    do p = 1, np
        call sub_C01_gather_3Dxyz(p,np,par,il,iu,Ex,Ey,Ez,Bx,By,Bz,E_c01,B_c01)
        call sub_C02_gather_3Dxyz_bspline(p,np,par,il,iu,Ex,Ey,Ez,Bx,By,Bz, &
            E_bs,B_bs,order)
        call write_case_rows(unit,'order1_c01',order,p,E_c01,B_c01,E_bs,B_bs)
    end do

    deallocate(Ex,Ey,Ez,Bx,By,Bz)
end subroutine run_order1_c01_case

subroutine run_constant_case(unit)
    implicit none

    integer :: unit

    integer, parameter :: np = 27
    integer :: order, ng
    integer :: il(1:3), iu(1:3)
    real, allocatable :: Ex(:,:,:), Ey(:,:,:), Ez(:,:,:)
    real, allocatable :: Bx(:,:,:), By(:,:,:), Bz(:,:,:)
    real :: par(1:6,1:np)
    real :: E_ref(1:3), B_ref(1:3)
    real :: E_bs(1:3), B_bs(1:3)
    integer :: p, i, j, k

    il = (/1, 1, 1/)
    iu = (/12, 11, 10/)
    call fill_property_particles(np,par)

    do order = 0, 4
        ng = (order + 2) / 2

        allocate(Ex(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng))
        allocate(Ey(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng))
        allocate(Ez(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng))
        allocate(Bx(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng))
        allocate(By(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng))
        allocate(Bz(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng))

        E_ref = (/constant_component(1), constant_component(2), constant_component(3)/)
        B_ref = (/constant_component(4), constant_component(5), constant_component(6)/)

        do k = il(3)-ng, iu(3)+ng
        do j = il(2)-ng, iu(2)+ng
        do i = il(1)-ng, iu(1)+ng
            Ex(i,j,k) = E_ref(1)
            Ey(i,j,k) = E_ref(2)
            Ez(i,j,k) = E_ref(3)
            Bx(i,j,k) = B_ref(1)
            By(i,j,k) = B_ref(2)
            Bz(i,j,k) = B_ref(3)
        end do
        end do
        end do

        do p = 1, np
            call sub_C02_gather_3Dxyz_bspline(p,np,par,il,iu,Ex,Ey,Ez,Bx,By,Bz, &
                E_bs,B_bs,order)
            call write_case_rows(unit,'constant',order,p,E_ref,B_ref,E_bs,B_bs)
        end do

        deallocate(Ex,Ey,Ez,Bx,By,Bz)
    end do
end subroutine run_constant_case

subroutine run_linear_case(unit)
    implicit none

    integer :: unit

    integer, parameter :: np = 27
    integer :: order, ng
    integer :: il(1:3), iu(1:3)
    real, allocatable :: Ex(:,:,:), Ey(:,:,:), Ez(:,:,:)
    real, allocatable :: Bx(:,:,:), By(:,:,:), Bz(:,:,:)
    real :: par(1:6,1:np)
    real :: E_ref(1:3), B_ref(1:3)
    real :: E_bs(1:3), B_bs(1:3)
    real :: x, y, z
    integer :: p, i, j, k

    il = (/1, 1, 1/)
    iu = (/12, 11, 10/)
    call fill_property_particles(np,par)

    do order = 1, 4
        ng = (order + 2) / 2

        allocate(Ex(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng))
        allocate(Ey(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng))
        allocate(Ez(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng))
        allocate(Bx(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng))
        allocate(By(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng))
        allocate(Bz(il(1)-ng:iu(1)+ng, il(2)-ng:iu(2)+ng, il(3)-ng:iu(3)+ng))

        do k = il(3)-ng, iu(3)+ng
        do j = il(2)-ng, iu(2)+ng
        do i = il(1)-ng, iu(1)+ng
            Ex(i,j,k) = linear_component(1,real(i),real(j),real(k))
            Ey(i,j,k) = linear_component(2,real(i),real(j),real(k))
            Ez(i,j,k) = linear_component(3,real(i),real(j),real(k))
            Bx(i,j,k) = linear_component(4,real(i),real(j),real(k))
            By(i,j,k) = linear_component(5,real(i),real(j),real(k))
            Bz(i,j,k) = linear_component(6,real(i),real(j),real(k))
        end do
        end do
        end do

        do p = 1, np
            x = par(1,p) + 0.5
            y = par(2,p) + 0.5
            z = par(3,p) + 0.5

            E_ref = (/linear_component(1,x,y,z), linear_component(2,x,y,z), &
                linear_component(3,x,y,z)/)
            B_ref = (/linear_component(4,x,y,z), linear_component(5,x,y,z), &
                linear_component(6,x,y,z)/)

            call sub_C02_gather_3Dxyz_bspline(p,np,par,il,iu,Ex,Ey,Ez,Bx,By,Bz, &
                E_bs,B_bs,order)
            call write_case_rows(unit,'linear',order,p,E_ref,B_ref,E_bs,B_bs)
        end do

        deallocate(Ex,Ey,Ez,Bx,By,Bz)
    end do
end subroutine run_linear_case

subroutine fill_c01_particles(np,par)
    implicit none

    integer :: np
    real :: par(1:6,1:np)
    real :: xg(1:4), yg(1:4), zg(1:4)
    integer :: p, ii, jj, kk

    xg = (/0.20, 2.35, 5.00, 9.85/)
    yg = (/0.30, 1.75, 4.00, 8.70/)
    zg = (/0.40, 2.20, 3.00, 7.80/)

    par = 0.0
    p = 0
    do kk = 1, 4
    do jj = 1, 4
    do ii = 1, 4
        p = p + 1
        par(1,p) = xg(ii) - 0.5
        par(2,p) = yg(jj) - 0.5
        par(3,p) = zg(kk) - 0.5
        par(4,p) = 0.01*real(p)
        par(5,p) = -0.02*real(p)
        par(6,p) = 0.03*real(p)
    end do
    end do
    end do
end subroutine fill_c01_particles

subroutine fill_property_particles(np,par)
    implicit none

    integer :: np
    real :: par(1:6,1:np)
    real :: xg(1:3), yg(1:3), zg(1:3)
    integer :: p, ii, jj, kk

    xg = (/2.20, 5.45, 9.65/)
    yg = (/2.10, 5.20, 8.40/)
    zg = (/2.30, 4.70, 7.60/)

    par = 0.0
    p = 0
    do kk = 1, 3
    do jj = 1, 3
    do ii = 1, 3
        p = p + 1
        par(1,p) = xg(ii) - 0.5
        par(2,p) = yg(jj) - 0.5
        par(3,p) = zg(kk) - 0.5
    end do
    end do
    end do
end subroutine fill_property_particles

subroutine write_case_rows(unit,case_name,order,p,E_ref,B_ref,E_val,B_val)
    implicit none

    integer :: unit, order, p
    character(len=*) :: case_name
    real :: E_ref(1:3), B_ref(1:3)
    real :: E_val(1:3), B_val(1:3)
    integer :: c

    do c = 1, 3
        call write_row(unit,case_name,order,p,component_name(c),E_ref(c),E_val(c))
        call write_row(unit,case_name,order,p,component_name(c+3),B_ref(c),B_val(c))
    end do
end subroutine write_case_rows

subroutine write_row(unit,case_name,order,p,component,reference,value)
    implicit none

    integer :: unit, order, p
    character(len=*) :: case_name, component
    real :: reference, value

    write(unit,'(a,",",i0,",",i0,",",a,",",es24.16,",",es24.16,",",es24.16)') &
        trim(case_name), order, p, trim(component), reference, value, abs(reference-value)
end subroutine write_row

character(len=2) function component_name(c)
    implicit none

    integer :: c

    select case (c)
    case (1)
        component_name = 'Ex'
    case (2)
        component_name = 'Ey'
    case (3)
        component_name = 'Ez'
    case (4)
        component_name = 'Bx'
    case (5)
        component_name = 'By'
    case default
        component_name = 'Bz'
    end select
end function component_name

real function constant_component(comp)
    implicit none

    integer :: comp

    constant_component = 0.125*real(comp) - 0.03
end function constant_component

real function linear_component(comp,x,y,z)
    implicit none

    integer :: comp
    real :: x, y, z
    real :: c

    c = real(comp)
    linear_component = 0.07*c + 0.021*(c+1.0)*x - 0.013*(c+2.0)*y + &
        0.017*(c+3.0)*z
end function linear_component

real function nonlinear_component(comp,i,j,k)
    implicit none

    integer :: comp, i, j, k
    real :: c, x, y, z

    c = real(comp)
    x = real(i)
    y = real(j)
    z = real(k)

    nonlinear_component = 0.19*c + 0.037*c*x - 0.021*(c+1.0)*y + &
        0.014*(c+2.0)*z + 0.0023*(c+0.5)*x*y - &
        0.0017*(c+1.0)*x*z + 0.0011*(c+1.5)*y*z + &
        0.00013*(c+0.25)*x*y*z
end function nonlinear_component

end program main
