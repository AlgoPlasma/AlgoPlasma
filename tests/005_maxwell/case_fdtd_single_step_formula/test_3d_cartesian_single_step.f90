program test_3d_cartesian_single_step

    use mod_E03_fdtd_3d_cartesian
    use test_single_step_utils
    implicit none

    integer, parameter :: nx = 10, ny = 9, nz = 8
    real, parameter :: pi = 3.14159265358979323846
    real, parameter :: dx = 0.08, dy = 0.11, dz = 0.09
    real, parameter :: dt = 0.35e-10
    real, parameter :: ep = 8.854187817e-12
    real, parameter :: mu = 1.2566370614e-6
    real, parameter :: tol_interior = 1.0e-11
    real, parameter :: tol_boundary = 1.0e-10

    real :: Ex0(0:nx,0:ny,0:nz), Ey0(0:nx,0:ny,0:nz), Ez0(0:nx,0:ny,0:nz)
    real :: Hx0(0:nx,0:ny,0:nz), Hy0(0:nx,0:ny,0:nz), Hz0(0:nx,0:ny,0:nz)
    real :: Ex_num(0:nx,0:ny,0:nz), Ey_num(0:nx,0:ny,0:nz), Ez_num(0:nx,0:ny,0:nz)
    real :: Hx_num(0:nx,0:ny,0:nz), Hy_num(0:nx,0:ny,0:nz), Hz_num(0:nx,0:ny,0:nz)
    real :: Ex_ref(0:nx,0:ny,0:nz), Ey_ref(0:nx,0:ny,0:nz), Ez_ref(0:nx,0:ny,0:nz)
    real :: Hx_ref(0:nx,0:ny,0:nz), Hy_ref(0:nx,0:ny,0:nz), Hz_ref(0:nx,0:ny,0:nz)
    real :: err3d(0:nx,0:ny,0:nz), err2d(0:nx,0:ny)
    type(report_t) :: rep
    logical :: all_ok

    all_ok = .true.
    call init_staggered_periodic_fields(nx,ny,nz,dx,dy,dz,Ex0,Ey0,Ez0,Hx0,Hy0,Hz0)

    write(*,'(A)') '=== 3D Cartesian FDTD Single-Step Formula Test ==='

    call report_init(rep)
    Ex_num = Ex0; Ey_num = Ey0; Ez_num = Ez0
    Hx_num = Hx0; Hy_num = Hy0; Hz_num = Hz0
    call sub_E03_fdtd_3d_cartesian_E(0,nx,0,ny,0,nz,1,nx-1,1,ny-1,1,nz-1, &
        Ex_num,Ey_num,Ez_num,Hx_num,Hy_num,Hz_num,dt,dx,dy,dz,ep)

    Ex_ref = Ex0; Ey_ref = Ey0; Ez_ref = Ez0
    call ref_update_cartesian_E(nx,ny,nz,1,nx-1,1,ny-1,1,nz-1, &
        Ex0,Ey0,Ez0,Hx0,Hy0,Hz0,dt,dx,dy,dz,ep,Ex_ref,Ey_ref,Ez_ref)

    call check_cartesian_E_domain(nx,ny,nz,Ex_ref,Ey_ref,Ez_ref,Ex_num,Ey_num,Ez_num,rep)
    call build_cartesian_E_error(nx,ny,nz,Ex_ref,Ey_ref,Ez_ref,Ex_num,Ey_num,Ez_num,err3d)
    call project_max_over_k(nx,ny,nz,err3d,err2d)
    call write_pgm_2d('err_3d_cartesian_E_step_xy_maxz.pgm',nx,ny,err2d)
    call report_print('E-step', rep)
    all_ok = all_ok .and. (rep%n_failed == 0)

    call report_init(rep)
    Ex_num = Ex0; Ey_num = Ey0; Ez_num = Ez0
    Hx_num = Hx0; Hy_num = Hy0; Hz_num = Hz0
    call sub_E03_fdtd_3d_cartesian_H(0,nx,0,ny,0,nz,0,nx-1,0,ny-1,0,nz-1, &
        Ex_num,Ey_num,Ez_num,Hx_num,Hy_num,Hz_num,dt,dx,dy,dz,mu)

    Hx_ref = Hx0; Hy_ref = Hy0; Hz_ref = Hz0
    call ref_update_cartesian_H(nx,ny,nz,0,nx-1,0,ny-1,0,nz-1, &
        Ex0,Ey0,Ez0,Hx0,Hy0,Hz0,dt,dx,dy,dz,mu,Hx_ref,Hy_ref,Hz_ref)

    call check_cartesian_H_domain(nx,ny,nz,Hx_ref,Hy_ref,Hz_ref,Hx_num,Hy_num,Hz_num,rep)
    call build_cartesian_H_error(nx,ny,nz,Hx_ref,Hy_ref,Hz_ref,Hx_num,Hy_num,Hz_num,err3d)
    call project_max_over_k(nx,ny,nz,err3d,err2d)
    call write_pgm_2d('err_3d_cartesian_H_step_xy_maxz.pgm',nx,ny,err2d)
    call report_print('H-step', rep)
    all_ok = all_ok .and. (rep%n_failed == 0)

    call report_init(rep)
    Ex_num = Ex0; Ey_num = Ey0; Ez_num = Ez0
    Hx_num = Hx0; Hy_num = Hy0; Hz_num = Hz0
    call sub_E03_fdtd_3d_cartesian_E(0,nx,0,ny,0,nz,1,nx-1,1,ny-1,1,nz-1, &
        Ex_num,Ey_num,Ez_num,Hx_num,Hy_num,Hz_num,dt,dx,dy,dz,ep)
    call sub_E03_fdtd_3d_cartesian_H(0,nx,0,ny,0,nz,0,nx-1,0,ny-1,0,nz-1, &
        Ex_num,Ey_num,Ez_num,Hx_num,Hy_num,Hz_num,dt,dx,dy,dz,mu)

    Ex_ref = Ex0; Ey_ref = Ey0; Ez_ref = Ez0
    Hx_ref = Hx0; Hy_ref = Hy0; Hz_ref = Hz0
    call ref_update_cartesian_E(nx,ny,nz,1,nx-1,1,ny-1,1,nz-1, &
        Ex0,Ey0,Ez0,Hx0,Hy0,Hz0,dt,dx,dy,dz,ep,Ex_ref,Ey_ref,Ez_ref)
    call ref_update_cartesian_H(nx,ny,nz,0,nx-1,0,ny-1,0,nz-1, &
        Ex_ref,Ey_ref,Ez_ref,Hx0,Hy0,Hz0,dt,dx,dy,dz,mu,Hx_ref,Hy_ref,Hz_ref)

    call check_cartesian_E_domain(nx,ny,nz,Ex_ref,Ey_ref,Ez_ref,Ex_num,Ey_num,Ez_num,rep)
    call check_cartesian_H_domain(nx,ny,nz,Hx_ref,Hy_ref,Hz_ref,Hx_num,Hy_num,Hz_num,rep)
    call build_cartesian_full_error(nx,ny,nz,Ex_ref,Ey_ref,Ez_ref,Hx_ref,Hy_ref,Hz_ref, &
        Ex_num,Ey_num,Ez_num,Hx_num,Hy_num,Hz_num,err3d)
    call project_max_over_k(nx,ny,nz,err3d,err2d)
    call write_pgm_2d('err_3d_cartesian_full_step_xy_maxz.pgm',nx,ny,err2d)
    call report_print('Full-step (E then H)', rep)
    all_ok = all_ok .and. (rep%n_failed == 0)

    if (all_ok) then
        write(*,'(A)') 'RESULT: PASS'
    else
        write(*,'(A)') 'RESULT: FAIL'
        stop 1
    end if

contains

    subroutine init_staggered_periodic_fields(nx0,ny0,nz0,dx0,dy0,dz0,Ex,Ey,Ez,Hx,Hy,Hz)
        implicit none
        integer, intent(in) :: nx0, ny0, nz0
        real, intent(in) :: dx0, dy0, dz0
        real, intent(out) :: Ex(0:nx0,0:ny0,0:nz0), Ey(0:nx0,0:ny0,0:nz0), Ez(0:nx0,0:ny0,0:nz0)
        real, intent(out) :: Hx(0:nx0,0:ny0,0:nz0), Hy(0:nx0,0:ny0,0:nz0), Hz(0:nx0,0:ny0,0:nz0)
        integer :: i, j, k
        real :: x, y, z, lx, ly, lz, kx, ky, kz

        lx = real(nx0)*dx0
        ly = real(ny0)*dy0
        lz = real(nz0)*dz0
        kx = 2.0*pi/lx
        ky = 2.0*pi/ly
        kz = 2.0*pi/lz

        do k = 0, nz0
        do j = 0, ny0
        do i = 0, nx0
            x = real(i)*dx0
            y = (real(j)+0.5)*dy0
            z = (real(k)+0.5)*dz0
            Ex(i,j,k) = 0.26*sin(kx*x+0.2)*cos(ky*y+0.3)*cos(kz*z+0.1) + &
                        0.08*cos(2.0*kx*x-0.4)*sin(ky*y)*sin(kz*z+0.5)

            x = (real(i)+0.5)*dx0
            y = real(j)*dy0
            z = (real(k)+0.5)*dz0
            Ey(i,j,k) = 0.31*cos(kx*x+0.1)*sin(ky*y+0.2)*cos(kz*z+0.4) + &
                        0.06*sin(2.0*ky*y+0.7)*sin(kx*x)*cos(kz*z)

            x = (real(i)+0.5)*dx0
            y = (real(j)+0.5)*dy0
            z = real(k)*dz0
            Ez(i,j,k) = 0.29*cos(kx*x+0.5)*cos(ky*y+0.6)*sin(kz*z+0.3) + &
                        0.09*sin(kx*x-0.2)*sin(2.0*ky*y)*cos(kz*z+0.2)

            x = (real(i)+0.5)*dx0
            y = real(j)*dy0
            z = real(k)*dz0
            Hx(i,j,k) = 0.23*sin(kx*x+0.15)*cos(ky*y+0.35)*sin(kz*z+0.55) + &
                        0.07*cos(2.0*kz*z+0.2)*cos(kx*x)*sin(ky*y)

            x = real(i)*dx0
            y = (real(j)+0.5)*dy0
            z = real(k)*dz0
            Hy(i,j,k) = 0.27*cos(kx*x+0.45)*sin(ky*y+0.25)*sin(kz*z+0.05) + &
                        0.05*sin(2.0*kx*x)*cos(ky*y)*cos(kz*z+0.3)

            x = real(i)*dx0
            y = real(j)*dy0
            z = (real(k)+0.5)*dz0
            Hz(i,j,k) = 0.24*sin(kx*x+0.65)*sin(ky*y+0.15)*cos(kz*z+0.45) + &
                        0.08*cos(2.0*ky*y-0.1)*sin(kx*x+0.3)*sin(kz*z)
        end do
        end do
        end do
    end subroutine init_staggered_periodic_fields


    subroutine ref_update_cartesian_E(nx0,ny0,nz0,il,iu,jl,ju,kl,ku, &
        Ex_old,Ey_old,Ez_old,Hx_old,Hy_old,Hz_old,dt0,dx0,dy0,dz0,ep0,Ex_new,Ey_new,Ez_new)
        implicit none
        integer, intent(in) :: nx0, ny0, nz0, il, iu, jl, ju, kl, ku
        real, intent(in) :: dt0, dx0, dy0, dz0, ep0
        real, intent(in) :: Ex_old(0:nx0,0:ny0,0:nz0), Ey_old(0:nx0,0:ny0,0:nz0), Ez_old(0:nx0,0:ny0,0:nz0)
        real, intent(in) :: Hx_old(0:nx0,0:ny0,0:nz0), Hy_old(0:nx0,0:ny0,0:nz0), Hz_old(0:nx0,0:ny0,0:nz0)
        real, intent(inout) :: Ex_new(0:nx0,0:ny0,0:nz0), Ey_new(0:nx0,0:ny0,0:nz0), Ez_new(0:nx0,0:ny0,0:nz0)
        integer :: i, j, k
        real :: curl_x, curl_y, curl_z

        Ex_new = Ex_old
        Ey_new = Ey_old
        Ez_new = Ez_old

        do k = kl, ku
        do j = jl, ju
        do i = il, iu
            curl_x = (Hz_old(i,j,k)-Hz_old(i,j-1,k))/dy0 - (Hy_old(i,j,k)-Hy_old(i,j,k-1))/dz0
            Ex_new(i,j,k) = Ex_old(i,j,k) + dt0/ep0*curl_x

            curl_y = (Hx_old(i,j,k)-Hx_old(i,j,k-1))/dz0 - (Hz_old(i,j,k)-Hz_old(i-1,j,k))/dx0
            Ey_new(i,j,k) = Ey_old(i,j,k) + dt0/ep0*curl_y

            curl_z = (Hy_old(i,j,k)-Hy_old(i-1,j,k))/dx0 - (Hx_old(i,j,k)-Hx_old(i,j-1,k))/dy0
            Ez_new(i,j,k) = Ez_old(i,j,k) + dt0/ep0*curl_z
        end do
        end do
        end do
    end subroutine ref_update_cartesian_E


    subroutine ref_update_cartesian_H(nx0,ny0,nz0,il,iu,jl,ju,kl,ku, &
        Ex_old,Ey_old,Ez_old,Hx_old,Hy_old,Hz_old,dt0,dx0,dy0,dz0,mu0,Hx_new,Hy_new,Hz_new)
        implicit none
        integer, intent(in) :: nx0, ny0, nz0, il, iu, jl, ju, kl, ku
        real, intent(in) :: dt0, dx0, dy0, dz0, mu0
        real, intent(in) :: Ex_old(0:nx0,0:ny0,0:nz0), Ey_old(0:nx0,0:ny0,0:nz0), Ez_old(0:nx0,0:ny0,0:nz0)
        real, intent(in) :: Hx_old(0:nx0,0:ny0,0:nz0), Hy_old(0:nx0,0:ny0,0:nz0), Hz_old(0:nx0,0:ny0,0:nz0)
        real, intent(inout) :: Hx_new(0:nx0,0:ny0,0:nz0), Hy_new(0:nx0,0:ny0,0:nz0), Hz_new(0:nx0,0:ny0,0:nz0)
        integer :: i, j, k
        real :: curl_x, curl_y, curl_z

        Hx_new = Hx_old
        Hy_new = Hy_old
        Hz_new = Hz_old

        do k = kl, ku
        do j = jl, ju
        do i = il, iu
            curl_x = (Ez_old(i,j+1,k)-Ez_old(i,j,k))/dy0 - (Ey_old(i,j,k+1)-Ey_old(i,j,k))/dz0
            Hx_new(i,j,k) = Hx_old(i,j,k) - dt0/mu0*curl_x

            curl_y = (Ex_old(i,j,k+1)-Ex_old(i,j,k))/dz0 - (Ez_old(i+1,j,k)-Ez_old(i,j,k))/dx0
            Hy_new(i,j,k) = Hy_old(i,j,k) - dt0/mu0*curl_y

            curl_z = (Ey_old(i+1,j,k)-Ey_old(i,j,k))/dx0 - (Ex_old(i,j+1,k)-Ex_old(i,j,k))/dy0
            Hz_new(i,j,k) = Hz_old(i,j,k) - dt0/mu0*curl_z
        end do
        end do
        end do
    end subroutine ref_update_cartesian_H


    subroutine check_cartesian_E_domain(nx0,ny0,nz0,Ex_ref,Ey_ref,Ez_ref,Ex_num,Ey_num,Ez_num,rep)
        implicit none
        integer, intent(in) :: nx0, ny0, nz0
        real, intent(in) :: Ex_ref(0:nx0,0:ny0,0:nz0), Ey_ref(0:nx0,0:ny0,0:nz0), Ez_ref(0:nx0,0:ny0,0:nz0)
        real, intent(in) :: Ex_num(0:nx0,0:ny0,0:nz0), Ey_num(0:nx0,0:ny0,0:nz0), Ez_num(0:nx0,0:ny0,0:nz0)
        type(report_t), intent(inout) :: rep
        integer :: i, j, k
        real :: tol

        do k = 0, nz0
        do j = 0, ny0
        do i = 0, nx0
            tol = tol_interior
            if (i == 0 .or. i == nx0 .or. j == 0 .or. j == ny0 .or. k == 0 .or. k == nz0) tol = tol_boundary
            call report_check(rep,'domain','Ex',i,j,k,Ex_ref(i,j,k),Ex_num(i,j,k),tol,tol)
            call report_check(rep,'domain','Ey',i,j,k,Ey_ref(i,j,k),Ey_num(i,j,k),tol,tol)
            call report_check(rep,'domain','Ez',i,j,k,Ez_ref(i,j,k),Ez_num(i,j,k),tol,tol)
        end do
        end do
        end do
    end subroutine check_cartesian_E_domain


    subroutine check_cartesian_H_domain(nx0,ny0,nz0,Hx_ref,Hy_ref,Hz_ref,Hx_num,Hy_num,Hz_num,rep)
        implicit none
        integer, intent(in) :: nx0, ny0, nz0
        real, intent(in) :: Hx_ref(0:nx0,0:ny0,0:nz0), Hy_ref(0:nx0,0:ny0,0:nz0), Hz_ref(0:nx0,0:ny0,0:nz0)
        real, intent(in) :: Hx_num(0:nx0,0:ny0,0:nz0), Hy_num(0:nx0,0:ny0,0:nz0), Hz_num(0:nx0,0:ny0,0:nz0)
        type(report_t), intent(inout) :: rep
        integer :: i, j, k
        real :: tol

        do k = 0, nz0
        do j = 0, ny0
        do i = 0, nx0
            tol = tol_interior
            if (i == 0 .or. i == nx0 .or. j == 0 .or. j == ny0 .or. k == 0 .or. k == nz0) tol = tol_boundary
            call report_check(rep,'domain','Hx',i,j,k,Hx_ref(i,j,k),Hx_num(i,j,k),tol,tol)
            call report_check(rep,'domain','Hy',i,j,k,Hy_ref(i,j,k),Hy_num(i,j,k),tol,tol)
            call report_check(rep,'domain','Hz',i,j,k,Hz_ref(i,j,k),Hz_num(i,j,k),tol,tol)
        end do
        end do
        end do
    end subroutine check_cartesian_H_domain


    subroutine build_cartesian_E_error(nx0,ny0,nz0,Ex_ref,Ey_ref,Ez_ref,Ex_num,Ey_num,Ez_num,err)
        implicit none
        integer, intent(in) :: nx0, ny0, nz0
        real, intent(in) :: Ex_ref(0:nx0,0:ny0,0:nz0), Ey_ref(0:nx0,0:ny0,0:nz0), Ez_ref(0:nx0,0:ny0,0:nz0)
        real, intent(in) :: Ex_num(0:nx0,0:ny0,0:nz0), Ey_num(0:nx0,0:ny0,0:nz0), Ez_num(0:nx0,0:ny0,0:nz0)
        real, intent(out) :: err(0:nx0,0:ny0,0:nz0)
        integer :: i, j, k

        do k = 0, nz0
        do j = 0, ny0
        do i = 0, nx0
            err(i,j,k) = max(abs(Ex_num(i,j,k)-Ex_ref(i,j,k)), &
                         max(abs(Ey_num(i,j,k)-Ey_ref(i,j,k)), abs(Ez_num(i,j,k)-Ez_ref(i,j,k))))
        end do
        end do
        end do
    end subroutine build_cartesian_E_error


    subroutine build_cartesian_H_error(nx0,ny0,nz0,Hx_ref,Hy_ref,Hz_ref,Hx_num,Hy_num,Hz_num,err)
        implicit none
        integer, intent(in) :: nx0, ny0, nz0
        real, intent(in) :: Hx_ref(0:nx0,0:ny0,0:nz0), Hy_ref(0:nx0,0:ny0,0:nz0), Hz_ref(0:nx0,0:ny0,0:nz0)
        real, intent(in) :: Hx_num(0:nx0,0:ny0,0:nz0), Hy_num(0:nx0,0:ny0,0:nz0), Hz_num(0:nx0,0:ny0,0:nz0)
        real, intent(out) :: err(0:nx0,0:ny0,0:nz0)
        integer :: i, j, k

        do k = 0, nz0
        do j = 0, ny0
        do i = 0, nx0
            err(i,j,k) = max(abs(Hx_num(i,j,k)-Hx_ref(i,j,k)), &
                         max(abs(Hy_num(i,j,k)-Hy_ref(i,j,k)), abs(Hz_num(i,j,k)-Hz_ref(i,j,k))))
        end do
        end do
        end do
    end subroutine build_cartesian_H_error


    subroutine build_cartesian_full_error(nx0,ny0,nz0,Ex_ref,Ey_ref,Ez_ref,Hx_ref,Hy_ref,Hz_ref, &
        Ex_num,Ey_num,Ez_num,Hx_num,Hy_num,Hz_num,err)
        implicit none
        integer, intent(in) :: nx0, ny0, nz0
        real, intent(in) :: Ex_ref(0:nx0,0:ny0,0:nz0), Ey_ref(0:nx0,0:ny0,0:nz0), Ez_ref(0:nx0,0:ny0,0:nz0)
        real, intent(in) :: Hx_ref(0:nx0,0:ny0,0:nz0), Hy_ref(0:nx0,0:ny0,0:nz0), Hz_ref(0:nx0,0:ny0,0:nz0)
        real, intent(in) :: Ex_num(0:nx0,0:ny0,0:nz0), Ey_num(0:nx0,0:ny0,0:nz0), Ez_num(0:nx0,0:ny0,0:nz0)
        real, intent(in) :: Hx_num(0:nx0,0:ny0,0:nz0), Hy_num(0:nx0,0:ny0,0:nz0), Hz_num(0:nx0,0:ny0,0:nz0)
        real, intent(out) :: err(0:nx0,0:ny0,0:nz0)
        integer :: i, j, k

        do k = 0, nz0
        do j = 0, ny0
        do i = 0, nx0
            err(i,j,k) = max(abs(Ex_num(i,j,k)-Ex_ref(i,j,k)), abs(Ey_num(i,j,k)-Ey_ref(i,j,k)))
            err(i,j,k) = max(err(i,j,k), abs(Ez_num(i,j,k)-Ez_ref(i,j,k)))
            err(i,j,k) = max(err(i,j,k), abs(Hx_num(i,j,k)-Hx_ref(i,j,k)))
            err(i,j,k) = max(err(i,j,k), abs(Hy_num(i,j,k)-Hy_ref(i,j,k)))
            err(i,j,k) = max(err(i,j,k), abs(Hz_num(i,j,k)-Hz_ref(i,j,k)))
        end do
        end do
        end do
    end subroutine build_cartesian_full_error

end program test_3d_cartesian_single_step
