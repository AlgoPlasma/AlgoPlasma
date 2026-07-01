#include "../../../../C_Gather/C01_gather_3Dxyz/mod_C01_gather_3Dxyz.f90"

program main
    use mod_C01_gather_3Dxyz
    implicit none

    call run_exact_trilinear_case()
    call run_smooth_convergence_case()
    call run_fused_push_case()

contains

subroutine run_exact_trilinear_case()
    implicit none

    integer, parameter :: np = 60
    integer :: il(1:3), iu(1:3)
    real, allocatable :: Ex(:,:,:), Ey(:,:,:), Ez(:,:,:)
    real, allocatable :: Bx(:,:,:), By(:,:,:), Bz(:,:,:)
    real :: par(1:6,1:np)
    real :: E(1:3), B(1:3)
    integer :: p, i, j, k, unit

    il = (/1, 1, 1/)
    iu = (/14, 13, 12/)

    allocate(Ex(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    allocate(Ey(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    allocate(Ez(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    allocate(Bx(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    allocate(By(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    allocate(Bz(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))

    do k = il(3)-1, iu(3)+1
    do j = il(2)-1, iu(2)+1
    do i = il(1)-1, iu(1)+1
        Ex(i,j,k) = exact_poly_component(1, real(i), real(j), real(k))
        Ey(i,j,k) = exact_poly_component(2, real(i), real(j), real(k))
        Ez(i,j,k) = exact_poly_component(3, real(i), real(j), real(k))
        Bx(i,j,k) = exact_poly_component(4, real(i), real(j), real(k))
        By(i,j,k) = exact_poly_component(5, real(i), real(j), real(k))
        Bz(i,j,k) = exact_poly_component(6, real(i), real(j), real(k))
    end do
    end do
    end do

    call fill_exact_particles(np, par)

    open(newunit=unit, file='output/c01_exact.csv', status='replace', action='write')
    write(unit,'(a)') 'p,px,py,pz,Ex,Ey,Ez,Bx,By,Bz'

    do p = 1, np
        call sub_C01_gather_3Dxyz(p, np, par, il, iu, Ex, Ey, Ez, Bx, By, Bz, E, B)
        write(unit,'(i0,9(",",es24.16))') p, par(1,p), par(2,p), par(3,p), &
            E(1), E(2), E(3), B(1), B(2), B(3)
    end do

    close(unit)

    deallocate(Ex, Ey, Ez, Bx, By, Bz)
end subroutine run_exact_trilinear_case

subroutine run_smooth_convergence_case()
    implicit none

    integer, parameter :: np = 125
    integer, parameter :: nlevel = 3
    integer :: levels(1:nlevel)
    integer :: il(1:3), iu(1:3)
    real, allocatable :: Ex(:,:,:), Ey(:,:,:), Ez(:,:,:)
    real, allocatable :: Bx(:,:,:), By(:,:,:), Bz(:,:,:)
    real :: par(1:6,1:np), xphys(1:np), yphys(1:np), zphys(1:np)
    real :: E(1:3), B(1:3)
    real :: h
    integer :: lev, n, p, i, j, k, unit

    levels = (/12, 24, 48/)

    open(newunit=unit, file='output/c01_convergence.csv', status='replace', action='write')
    write(unit,'(a)') 'n,h,p,x,y,z,Ex,Ey,Ez,Bx,By,Bz'

    do lev = 1, nlevel
        n = levels(lev)
        h = 1.0 / real(n)
        il = (/1, 1, 1/)
        iu = (/n, n, n/)

        allocate(Ex(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
        allocate(Ey(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
        allocate(Ez(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
        allocate(Bx(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
        allocate(By(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
        allocate(Bz(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))

        do k = il(3)-1, iu(3)+1
        do j = il(2)-1, iu(2)+1
        do i = il(1)-1, iu(1)+1
            Ex(i,j,k) = smooth_component(1, real(i)*h, real(j)*h, real(k)*h)
            Ey(i,j,k) = smooth_component(2, real(i)*h, real(j)*h, real(k)*h)
            Ez(i,j,k) = smooth_component(3, real(i)*h, real(j)*h, real(k)*h)
            Bx(i,j,k) = smooth_component(4, real(i)*h, real(j)*h, real(k)*h)
            By(i,j,k) = smooth_component(5, real(i)*h, real(j)*h, real(k)*h)
            Bz(i,j,k) = smooth_component(6, real(i)*h, real(j)*h, real(k)*h)
        end do
        end do
        end do

        call fill_physical_particles(np, h, par, xphys, yphys, zphys)

        do p = 1, np
            call sub_C01_gather_3Dxyz(p, np, par, il, iu, Ex, Ey, Ez, Bx, By, Bz, E, B)
            write(unit,'(i0,",",es24.16,",",i0,9(",",es24.16))') n, h, p, &
                xphys(p), yphys(p), zphys(p), E(1), E(2), E(3), B(1), B(2), B(3)
        end do

        deallocate(Ex, Ey, Ez, Bx, By, Bz)
    end do

    close(unit)
end subroutine run_smooth_convergence_case

subroutine run_fused_push_case()
    implicit none

    integer, parameter :: np = 16
    integer :: il(1:3), iu(1:3)
    real, allocatable :: Ex(:,:,:), Ey(:,:,:), Ez(:,:,:)
    real, allocatable :: Bx(:,:,:), By(:,:,:), Bz(:,:,:)
    real :: par(1:6,1:np), par0(1:6,1:np)
    real :: q, m, dt
    integer :: p, i, j, k, unit

    il = (/1, 1, 1/)
    iu = (/10, 10, 10/)
    q = 1.7
    m = 2.3
    dt = 0.075

    allocate(Ex(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    allocate(Ey(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    allocate(Ez(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    allocate(Bx(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    allocate(By(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))
    allocate(Bz(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1))

    do k = il(3)-1, iu(3)+1
    do j = il(2)-1, iu(2)+1
    do i = il(1)-1, iu(1)+1
        Ex(i,j,k) = exact_poly_component(1, real(i), real(j), real(k))
        Ey(i,j,k) = exact_poly_component(2, real(i), real(j), real(k))
        Ez(i,j,k) = exact_poly_component(3, real(i), real(j), real(k))
        Bx(i,j,k) = 0.0
        By(i,j,k) = 0.0
        Bz(i,j,k) = 0.0
    end do
    end do
    end do

    call fill_push_particles(np, par)
    par0 = par

    call sub_C01_gather_3Dxyz_push(np, par, il, iu, Ex, Ey, Ez, Bx, By, Bz, q, m, dt)

    open(newunit=unit, file='output/c01_push.csv', status='replace', action='write')
    write(unit,'(a)') 'p,q,m,dt,x0,y0,z0,vx0,vy0,vz0,x1,y1,z1,vx1,vy1,vz1'

    do p = 1, np
        write(unit,'(i0,15(",",es24.16))') p, q, m, dt, &
            par0(1,p), par0(2,p), par0(3,p), par0(4,p), par0(5,p), par0(6,p), &
            par(1,p), par(2,p), par(3,p), par(4,p), par(5,p), par(6,p)
    end do

    close(unit)

    deallocate(Ex, Ey, Ez, Bx, By, Bz)
end subroutine run_fused_push_case

subroutine fill_exact_particles(np, par)
    implicit none

    integer, intent(in) :: np
    real, intent(out) :: par(1:6,1:np)
    integer :: p, ii, jj, kk

    par = 0.0
    p = 0
    do kk = 1, 3
    do jj = 1, 4
    do ii = 1, 5
        p = p + 1
        par(1,p) = 0.35 + 1.65*real(ii-1) + 0.07*real(jj)
        par(2,p) = 0.45 + 1.25*real(jj-1) + 0.05*real(kk)
        par(3,p) = 0.55 + 1.15*real(kk-1) + 0.03*real(ii)
    end do
    end do
    end do
end subroutine fill_exact_particles

subroutine fill_physical_particles(np, h, par, xphys, yphys, zphys)
    implicit none

    integer, intent(in) :: np
    real, intent(in) :: h
    real, intent(out) :: par(1:6,1:np), xphys(1:np), yphys(1:np), zphys(1:np)
    integer :: p, ii, jj, kk

    par = 0.0
    p = 0
    do kk = 1, 5
    do jj = 1, 5
    do ii = 1, 5
        p = p + 1
        xphys(p) = 0.11 + 0.18*real(ii-1) + 0.007*real(jj-1)
        yphys(p) = 0.13 + 0.17*real(jj-1) + 0.006*real(kk-1)
        zphys(p) = 0.15 + 0.16*real(kk-1) + 0.005*real(ii-1)
        par(1,p) = xphys(p)/h - 0.5
        par(2,p) = yphys(p)/h - 0.5
        par(3,p) = zphys(p)/h - 0.5
    end do
    end do
    end do
end subroutine fill_physical_particles

subroutine fill_push_particles(np, par)
    implicit none

    integer, intent(in) :: np
    real, intent(out) :: par(1:6,1:np)
    integer :: p

    par = 0.0
    do p = 1, np
        par(1,p) = 0.55 + 0.41*real(p-1)
        par(2,p) = 0.70 + 0.13*real(mod(3*p, 7))
        par(3,p) = 0.60 + 0.17*real(mod(5*p, 9))
        par(4,p) = 0.020*real(p) - 0.11
        par(5,p) = -0.015*real(p) + 0.08
        par(6,p) = 0.010*real(mod(p, 5)) - 0.02
    end do
end subroutine fill_push_particles

real function exact_poly_component(comp, x, y, z)
    implicit none

    integer, intent(in) :: comp
    real, intent(in) :: x, y, z
    real :: c

    c = real(comp)
    exact_poly_component = 0.11*c + 0.031*c*x - 0.017*(c+1.0)*y + &
        0.013*(c+2.0)*z + 0.0011*(c+0.5)*x*y - 0.0007*(c+1.0)*x*z + &
        0.0009*(c+1.5)*y*z + 0.00012*(c+0.25)*x*y*z
end function exact_poly_component

real function smooth_component(comp, x, y, z)
    implicit none

    integer, intent(in) :: comp
    real, intent(in) :: x, y, z
    real, parameter :: twopi = 6.2831853071795864769
    real :: c

    c = real(comp)
    smooth_component = sin(twopi*(x + 0.013*c)) + &
        0.27*cos(twopi*(y - 0.011*c)) + &
        0.19*sin(twopi*(z + 0.007*c)) + &
        0.08*c*x*y - 0.05*(c+1.0)*y*z + 0.03*(c+2.0)*x*z
end function smooth_component

end program main
