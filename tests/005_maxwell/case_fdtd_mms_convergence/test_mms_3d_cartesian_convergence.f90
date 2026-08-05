program test_mms_3d_cartesian_convergence

    use, intrinsic :: iso_fortran_env, only: output_unit
    use mod_E03_fdtd_3d_cartesian
    use mms_exact_sources
    use mms_convergence_utils
    implicit none

    integer, parameter :: nlev = 3, ncomp = 6, nhot = 5
    integer, parameter :: nx_list(nlev) = (/16, 32, 64/)
    integer, parameter :: ny_list(nlev) = (/16, 32, 64/)
    integer, parameter :: nz_list(nlev) = (/16, 32, 64/)
    character(len=8), parameter :: comp_names(ncomp) = [character(len=8) :: 'Ex','Ey','Ez','Hx','Hy','Hz']

    real, parameter :: ep = 1.0
    real, parameter :: mu = 1.0
    real, parameter :: lx = 1.0, ly = 1.0, lz = 1.0
    real, parameter :: cfl = 0.20
    integer, parameter :: nstep_base = 1000
    real, parameter :: l2_order_min = 1.8
    real, parameter :: linf_order_min = 1.5

    integer :: ilev, ic
    integer :: nsteps(nlev)
    real :: dt_levels(nlev), tfinal
    real :: l2_comp(ncomp,nlev), linf_comp(ncomp,nlev)
    real :: l2_comb(nlev), linf_comb(nlev)
    real :: l2_comb_e(nlev), l2_comb_h(nlev), linf_comb_e(nlev), linf_comb_h(nlev)
    real :: p_l2_12, p_l2_23, p_linf_12, p_linf_23
    real :: p_l2e_12, p_l2e_23, p_linfe_12, p_linfe_23
    real :: p_l2h_12, p_l2h_23, p_linfh_12, p_linfh_23
    real :: p_comp_l2_12(ncomp), p_comp_l2_23(ncomp), p_comp_linf_12(ncomp), p_comp_linf_23(ncomp)
    real :: c0, omega
    logical :: pass_ok

    c0 = 1.0/sqrt(ep*mu)
    omega = 0.7*c0*(2.0*acos(-1.0)/lx)

    do ilev = 1, nlev
        dt_levels(ilev) = compute_dt(nx_list(ilev),ny_list(ilev),nz_list(ilev),c0)
    end do
    tfinal = real(nstep_base)*dt_levels(1)

    do ilev = 1, nlev
        nsteps(ilev) = nint(tfinal/dt_levels(ilev))
    end do

    write(*,'(A)') '=== MMS Convergence: 3D Cartesian periodic ==='
    write(*,'(A,1PE12.4)') 'target T = ', tfinal

    do ilev = 1, nlev
        call run_level(nx_list(ilev),ny_list(ilev),nz_list(ilev),dt_levels(ilev),nsteps(ilev),omega, &
            l2_comp(:,ilev),linf_comp(:,ilev),l2_comb(ilev),linf_comb(ilev), &
            l2_comb_e(ilev),l2_comb_h(ilev),linf_comb_e(ilev),linf_comb_h(ilev))
    end do

    do ic = 1, ncomp
        p_comp_l2_12(ic) = observed_order(l2_comp(ic,1),l2_comp(ic,2))
        p_comp_l2_23(ic) = observed_order(l2_comp(ic,2),l2_comp(ic,3))
        p_comp_linf_12(ic) = observed_order(linf_comp(ic,1),linf_comp(ic,2))
        p_comp_linf_23(ic) = observed_order(linf_comp(ic,2),linf_comp(ic,3))
    end do

    p_l2_12 = observed_order(l2_comb(1),l2_comb(2))
    p_l2_23 = observed_order(l2_comb(2),l2_comb(3))
    p_linf_12 = observed_order(linf_comb(1),linf_comb(2))
    p_linf_23 = observed_order(linf_comb(2),linf_comb(3))
    p_l2e_12 = observed_order(l2_comb_e(1),l2_comb_e(2))
    p_l2e_23 = observed_order(l2_comb_e(2),l2_comb_e(3))
    p_linfe_12 = observed_order(linf_comb_e(1),linf_comb_e(2))
    p_linfe_23 = observed_order(linf_comb_e(2),linf_comb_e(3))
    p_l2h_12 = observed_order(l2_comb_h(1),l2_comb_h(2))
    p_l2h_23 = observed_order(l2_comb_h(2),l2_comb_h(3))
    p_linfh_12 = observed_order(linf_comb_h(1),linf_comb_h(2))
    p_linfh_23 = observed_order(linf_comb_h(2),linf_comb_h(3))

    write(*,'(A)') '--- Component-wise errors ---'
    do ic = 1, ncomp
        write(*,'(A,A,A,3(1PE11.3,1X),A,0P,2(F6.3,1X),A,2(F6.3,1X))') &
            '  ',trim(comp_names(ic)), ' L2=',l2_comp(ic,1),l2_comp(ic,2),l2_comp(ic,3), &
            ' p(L2)=',p_comp_l2_12(ic),p_comp_l2_23(ic), &
            ' p(Linf)=',p_comp_linf_12(ic),p_comp_linf_23(ic)
        write(*,'(A,3(1PE11.3,1X))') '      Linf=',linf_comp(ic,1),linf_comp(ic,2),linf_comp(ic,3)
    end do

    write(*,'(A)') '--- Combined errors ---'
    write(*,'(A,3(1PE11.3,1X))') '  L2  : ', l2_comb(1), l2_comb(2), l2_comb(3)
    write(*,'(A,3(1PE11.3,1X))') '  Linf: ', linf_comb(1), linf_comb(2), linf_comb(3)
    write(*,'(A,3(1PE11.3,1X),A,0P,2(F6.3,1X),A,2(F6.3,1X))') '  combined_E L2=', &
        l2_comb_e(1),l2_comb_e(2),l2_comb_e(3), ' p=',p_l2e_12,p_l2e_23, ' Linf p=',p_linfe_12,p_linfe_23
    write(*,'(A,3(1PE11.3,1X),A,0P,2(F6.3,1X),A,2(F6.3,1X))') '  combined_H L2=', &
        l2_comb_h(1),l2_comb_h(2),l2_comb_h(3), ' p=',p_l2h_12,p_l2h_23, ' Linf p=',p_linfh_12,p_linfh_23
    write(*,'(A,3(1PE11.3,1X))') '  combined_E Linf: ', linf_comb_e(1),linf_comb_e(2),linf_comb_e(3)
    write(*,'(A,3(1PE11.3,1X))') '  combined_H Linf: ', linf_comb_h(1),linf_comb_h(2),linf_comb_h(3)
    write(*,'(A,0P,2(F6.3,1X))') '  Observed order L2  (h->h/2): ', p_l2_12, p_l2_23
    write(*,'(A,0P,2(F6.3,1X))') '  Observed order Linf(h->h/2): ', p_linf_12, p_linf_23

    pass_ok = min(p_l2_12,p_l2_23) >= l2_order_min .and. min(p_linf_12,p_linf_23) >= linf_order_min

    if (pass_ok) then
        write(*,'(A)') 'RESULT: PASS'
    else
        write(*,'(A)') 'RESULT: FAIL'

    end if

contains

    real function compute_dt(nx,ny,nz,c0)
        implicit none
        integer, intent(in) :: nx, ny, nz
        real, intent(in) :: c0
        real :: dx, dy, dz
        dx = lx/real(nx)
        dy = ly/real(ny)
        dz = lz/real(nz)
        compute_dt = cfl/(c0*sqrt((1.0/dx)**2 + (1.0/dy)**2 + (1.0/dz)**2))
    end function compute_dt


    subroutine run_level(nx,ny,nz,dt,nsteps,omega0,l2_out,linf_out,l2_comb_out,linf_comb_out, &
        l2_comb_e_out,l2_comb_h_out,linf_comb_e_out,linf_comb_h_out)
        implicit none
        integer, intent(in) :: nx, ny, nz, nsteps
        real, intent(in) :: dt, omega0
        real, intent(out) :: l2_out(ncomp), linf_out(ncomp), l2_comb_out, linf_comb_out
        real, intent(out) :: l2_comb_e_out, l2_comb_h_out, linf_comb_e_out, linf_comb_h_out
        real, allocatable :: Ex(:,:,:), Ey(:,:,:), Ez(:,:,:), Hx(:,:,:), Hy(:,:,:), Hz(:,:,:)
        integer :: n, progress_stride
        real :: t_n, dx, dy, dz, xw, yw, zw
        integer :: wi(ncomp), wj(ncomp), wk(ncomp)
        integer :: hi(ncomp,nhot), hj(ncomp,nhot), hk(ncomp,nhot)
        real :: werr(ncomp), herr(ncomp,nhot)
        integer :: viz_unit, viz_stride
        logical :: viz_on, viz_open

        dx = lx/real(nx)
        dy = ly/real(ny)
        dz = lz/real(nz)
        viz_on = (nx == nx_list(nlev) .and. ny == ny_list(nlev) .and. nz == nz_list(nlev))

        allocate(Ex(0:nx+1,0:ny+1,0:nz+1), Ey(0:nx+1,0:ny+1,0:nz+1), Ez(0:nx+1,0:ny+1,0:nz+1))
        allocate(Hx(0:nx+1,0:ny+1,0:nz+1), Hy(0:nx+1,0:ny+1,0:nz+1), Hz(0:nx+1,0:ny+1,0:nz+1))

        call init_fields(nx,ny,nz,dx,dy,dz,dt,omega0,Ex,Ey,Ez,Hx,Hy,Hz)
        call fill_periodic_all(nx,ny,nz,Ex,Ey,Ez,Hx,Hy,Hz)

        viz_open = .false.
        if (viz_on) then
            viz_stride = max(1,nsteps/90)
            open(newunit=viz_unit,file='mms_cart3d_viz_fine.bin',form='unformatted',access='stream',status='replace')
            write(viz_unit) nx
            write(viz_unit) nz
            write(viz_unit) viz_stride
            call write_viz_frame(viz_unit,nx,ny,nz,dx,dy,dz,0,0.0,omega0,Ez)
            viz_open = .true.
        end if

        progress_stride = max(1, min(100, nsteps))
        write(*,'(A,I0,A,I0,A,I0,A,I0)') &
            '  running level nx=',nx,', ny=',ny,', nz=',nz,', nsteps=',nsteps
        flush(output_unit)

        t_n = 0.0
        do n = 1, nsteps
            call sub_E03_fdtd_3d_cartesian_H(0,nx+1,0,ny+1,0,nz+1,1,nx,1,ny,1,nz, &
                Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu)
            call add_h_source(nx,ny,nz,dx,dy,dz,dt,t_n,omega0,Hx,Hy,Hz)
            call fill_periodic_only_h(nx,ny,nz,Hx,Hy,Hz)

            call sub_E03_fdtd_3d_cartesian_E(0,nx+1,0,ny+1,0,nz+1,1,nx,1,ny,1,nz, &
                Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,ep)
            call add_e_source(nx,ny,nz,dx,dy,dz,dt,t_n+0.5*dt,omega0,Ex,Ey,Ez)
            call fill_periodic_only_e(nx,ny,nz,Ex,Ey,Ez)

            t_n = t_n + dt

            if (viz_on .and. (mod(n,viz_stride) == 0 .or. n == nsteps)) then
                call write_viz_frame(viz_unit,nx,ny,nz,dx,dy,dz,n,t_n,omega0,Ez)
            end if
            if (mod(n, progress_stride) == 0 .or. n == nsteps) then
                write(*,'(A,I0,A,I0,A)') '    progress ',n,'/',nsteps,' steps'
                flush(output_unit)
            end if
        end do

        call compute_errors(nx,ny,nz,dx,dy,dz,t_n,t_n-0.5*dt,omega0,Ex,Ey,Ez,Hx,Hy,Hz, &
            l2_out,linf_out,l2_comb_out,linf_comb_out,l2_comb_e_out,l2_comb_h_out, &
            linf_comb_e_out,linf_comb_h_out,wi,wj,wk,werr,hi,hj,hk,herr)

        write(*,'(A,I0,A,I0,A,I0,A,1PE11.3,A,I0)') '  level nx=',nx,', ny=',ny,', nz=',nz,', dt=',dt,', nsteps=',nsteps
        write(*,'(A)') '    worst points by component:'
        do n = 1, ncomp
            call component_xyz(n,wi(n),wj(n),wk(n),dx,dy,dz,xw,yw,zw)
            write(*,'(A,A,A,3(I0,1X),A,3(1PE11.3,1X),A,1PE11.3)') '      ',trim(comp_names(n)), &
                ' idx=',wi(n),wj(n),wk(n), ' xyz=',xw,yw,zw, &
                ' err=',werr(n)
        end do
        if (nx == nx_list(nlev) .and. ny == ny_list(nlev) .and. nz == nz_list(nlev)) then
            write(*,'(A,I0,A)') '    top ',nhot,' points by component (finest level):'
            do n = 1, ncomp
                write(*,'(A,A)') '      ',trim(comp_names(n))
                call print_hot_list(n,nhot,herr(n,:),hi(n,:),hj(n,:),hk(n,:),dx,dy,dz)
            end do
        end if

        if (viz_open) close(viz_unit)
        deallocate(Ex,Ey,Ez,Hx,Hy,Hz)
    end subroutine run_level


    subroutine init_fields(nx,ny,nz,dx,dy,dz,dt,omega0,Ex,Ey,Ez,Hx,Hy,Hz)
        implicit none
        integer, intent(in) :: nx, ny, nz
        real, intent(in) :: dx, dy, dz, dt, omega0
        real, intent(inout) :: Ex(0:nx+1,0:ny+1,0:nz+1), Ey(0:nx+1,0:ny+1,0:nz+1), Ez(0:nx+1,0:ny+1,0:nz+1)
        real, intent(inout) :: Hx(0:nx+1,0:ny+1,0:nz+1), Hy(0:nx+1,0:ny+1,0:nz+1), Hz(0:nx+1,0:ny+1,0:nz+1)
        integer :: i, j, k
        real :: x, y, z
        real :: ex0, ey0, ez0, hx0, hy0, hz0, sex, sey, sez, shx, shy, shz

        Ex = 0.0; Ey = 0.0; Ez = 0.0
        Hx = 0.0; Hy = 0.0; Hz = 0.0

        do k = 1, nz
        do j = 1, ny
        do i = 1, nx
            x = (real(i)-0.5)*dx
            y = (real(j)-1.0)*dy
            z = (real(k)-1.0)*dz
            call cartesian_exact_and_sources(x,y,z,0.0,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            Ex(i,j,k) = ex0

            x = (real(i)-1.0)*dx
            y = (real(j)-0.5)*dy
            z = (real(k)-1.0)*dz
            call cartesian_exact_and_sources(x,y,z,0.0,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            Ey(i,j,k) = ey0

            x = (real(i)-1.0)*dx
            y = (real(j)-1.0)*dy
            z = (real(k)-0.5)*dz
            call cartesian_exact_and_sources(x,y,z,0.0,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            Ez(i,j,k) = ez0

            x = (real(i)-1.0)*dx
            y = (real(j)-0.5)*dy
            z = (real(k)-0.5)*dz
            call cartesian_exact_and_sources(x,y,z,-0.5*dt,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            Hx(i,j,k) = hx0

            x = (real(i)-0.5)*dx
            y = (real(j)-1.0)*dy
            z = (real(k)-0.5)*dz
            call cartesian_exact_and_sources(x,y,z,-0.5*dt,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            Hy(i,j,k) = hy0

            x = (real(i)-0.5)*dx
            y = (real(j)-0.5)*dy
            z = (real(k)-1.0)*dz
            call cartesian_exact_and_sources(x,y,z,-0.5*dt,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            Hz(i,j,k) = hz0
        end do
        end do
        end do
    end subroutine init_fields


    subroutine add_h_source(nx,ny,nz,dx,dy,dz,dt,t_src,omega0,Hx,Hy,Hz)
        implicit none
        integer, intent(in) :: nx, ny, nz
        real, intent(in) :: dx, dy, dz, dt, t_src, omega0
        real, intent(inout) :: Hx(0:nx+1,0:ny+1,0:nz+1), Hy(0:nx+1,0:ny+1,0:nz+1), Hz(0:nx+1,0:ny+1,0:nz+1)
        integer :: i, j, k
        real :: x, y, z
        real :: ex0, ey0, ez0, hx0, hy0, hz0, sex, sey, sez, shx, shy, shz

        do k = 1, nz
        do j = 1, ny
        do i = 1, nx
            x = (real(i)-1.0)*dx
            y = (real(j)-0.5)*dy
            z = (real(k)-0.5)*dz
            call cartesian_exact_and_sources(x,y,z,t_src,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            Hx(i,j,k) = Hx(i,j,k) + dt*shx

            x = (real(i)-0.5)*dx
            y = (real(j)-1.0)*dy
            z = (real(k)-0.5)*dz
            call cartesian_exact_and_sources(x,y,z,t_src,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            Hy(i,j,k) = Hy(i,j,k) + dt*shy

            x = (real(i)-0.5)*dx
            y = (real(j)-0.5)*dy
            z = (real(k)-1.0)*dz
            call cartesian_exact_and_sources(x,y,z,t_src,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            Hz(i,j,k) = Hz(i,j,k) + dt*shz
        end do
        end do
        end do
    end subroutine add_h_source


    subroutine add_e_source(nx,ny,nz,dx,dy,dz,dt,t_src,omega0,Ex,Ey,Ez)
        implicit none
        integer, intent(in) :: nx, ny, nz
        real, intent(in) :: dx, dy, dz, dt, t_src, omega0
        real, intent(inout) :: Ex(0:nx+1,0:ny+1,0:nz+1), Ey(0:nx+1,0:ny+1,0:nz+1), Ez(0:nx+1,0:ny+1,0:nz+1)
        integer :: i, j, k
        real :: x, y, z
        real :: ex0, ey0, ez0, hx0, hy0, hz0, sex, sey, sez, shx, shy, shz

        do k = 1, nz
        do j = 1, ny
        do i = 1, nx
            x = (real(i)-0.5)*dx
            y = (real(j)-1.0)*dy
            z = (real(k)-1.0)*dz
            call cartesian_exact_and_sources(x,y,z,t_src,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            Ex(i,j,k) = Ex(i,j,k) + dt*sex

            x = (real(i)-1.0)*dx
            y = (real(j)-0.5)*dy
            z = (real(k)-1.0)*dz
            call cartesian_exact_and_sources(x,y,z,t_src,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            Ey(i,j,k) = Ey(i,j,k) + dt*sey

            x = (real(i)-1.0)*dx
            y = (real(j)-1.0)*dy
            z = (real(k)-0.5)*dz
            call cartesian_exact_and_sources(x,y,z,t_src,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            Ez(i,j,k) = Ez(i,j,k) + dt*sez
        end do
        end do
        end do
    end subroutine add_e_source


    subroutine compute_errors(nx,ny,nz,dx,dy,dz,t_e,t_h,omega0,Ex,Ey,Ez,Hx,Hy,Hz,l2c,linfc,l2all,linfall, &
        l2e,l2h,linfe,linfh,wi,wj,wk,werr,hi,hj,hk,herr)
        implicit none
        integer, intent(in) :: nx, ny, nz
        real, intent(in) :: dx, dy, dz, t_e, t_h, omega0
        real, intent(in) :: Ex(0:nx+1,0:ny+1,0:nz+1), Ey(0:nx+1,0:ny+1,0:nz+1), Ez(0:nx+1,0:ny+1,0:nz+1)
        real, intent(in) :: Hx(0:nx+1,0:ny+1,0:nz+1), Hy(0:nx+1,0:ny+1,0:nz+1), Hz(0:nx+1,0:ny+1,0:nz+1)
        real, intent(out) :: l2c(ncomp), linfc(ncomp), l2all, linfall
        real, intent(out) :: l2e, l2h, linfe, linfh
        integer, intent(out) :: wi(ncomp), wj(ncomp), wk(ncomp)
        integer, intent(out) :: hi(ncomp,nhot), hj(ncomp,nhot), hk(ncomp,nhot)
        real, intent(out) :: werr(ncomp)
        real, intent(out) :: herr(ncomp,nhot)

        integer :: i, j, k
        real :: x, y, z, err, w, vol
        real :: ex0, ey0, ez0, hx0, hy0, hz0, sex, sey, sez, shx, shy, shz
        real :: sumsq(ncomp)

        w = dx*dy*dz
        vol = real(nx*ny*nz)*w
        sumsq = 0.0
        linfc = 0.0
        wi = 1; wj = 1; wk = 1
        werr = -1.0
        hi = 1; hj = 1; hk = 1
        herr = -1.0

        do k = 1, nz
        do j = 1, ny
        do i = 1, nx
            x = (real(i)-0.5)*dx
            y = (real(j)-1.0)*dy
            z = (real(k)-1.0)*dz
            call cartesian_exact_and_sources(x,y,z,t_e,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            err = abs(Ex(i,j,k)-ex0)
            sumsq(1) = sumsq(1) + err*err*w
            linfc(1) = max(linfc(1), err)
            call update_hot_list(1,err,i,j,k,hi,hj,hk,herr)
            if (err > werr(1)) then
                werr(1) = err; wi(1) = i; wj(1) = j; wk(1) = k
            end if

            x = (real(i)-1.0)*dx
            y = (real(j)-0.5)*dy
            z = (real(k)-1.0)*dz
            call cartesian_exact_and_sources(x,y,z,t_e,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            err = abs(Ey(i,j,k)-ey0)
            sumsq(2) = sumsq(2) + err*err*w
            linfc(2) = max(linfc(2), err)
            call update_hot_list(2,err,i,j,k,hi,hj,hk,herr)
            if (err > werr(2)) then
                werr(2) = err; wi(2) = i; wj(2) = j; wk(2) = k
            end if

            x = (real(i)-1.0)*dx
            y = (real(j)-1.0)*dy
            z = (real(k)-0.5)*dz
            call cartesian_exact_and_sources(x,y,z,t_e,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            err = abs(Ez(i,j,k)-ez0)
            sumsq(3) = sumsq(3) + err*err*w
            linfc(3) = max(linfc(3), err)
            call update_hot_list(3,err,i,j,k,hi,hj,hk,herr)
            if (err > werr(3)) then
                werr(3) = err; wi(3) = i; wj(3) = j; wk(3) = k
            end if

            x = (real(i)-1.0)*dx
            y = (real(j)-0.5)*dy
            z = (real(k)-0.5)*dz
            call cartesian_exact_and_sources(x,y,z,t_h,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            err = abs(Hx(i,j,k)-hx0)
            sumsq(4) = sumsq(4) + err*err*w
            linfc(4) = max(linfc(4), err)
            call update_hot_list(4,err,i,j,k,hi,hj,hk,herr)
            if (err > werr(4)) then
                werr(4) = err; wi(4) = i; wj(4) = j; wk(4) = k
            end if

            x = (real(i)-0.5)*dx
            y = (real(j)-1.0)*dy
            z = (real(k)-0.5)*dz
            call cartesian_exact_and_sources(x,y,z,t_h,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            err = abs(Hy(i,j,k)-hy0)
            sumsq(5) = sumsq(5) + err*err*w
            linfc(5) = max(linfc(5), err)
            call update_hot_list(5,err,i,j,k,hi,hj,hk,herr)
            if (err > werr(5)) then
                werr(5) = err; wi(5) = i; wj(5) = j; wk(5) = k
            end if

            x = (real(i)-0.5)*dx
            y = (real(j)-0.5)*dy
            z = (real(k)-1.0)*dz
            call cartesian_exact_and_sources(x,y,z,t_h,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            err = abs(Hz(i,j,k)-hz0)
            sumsq(6) = sumsq(6) + err*err*w
            linfc(6) = max(linfc(6), err)
            call update_hot_list(6,err,i,j,k,hi,hj,hk,herr)
            if (err > werr(6)) then
                werr(6) = err; wi(6) = i; wj(6) = j; wk(6) = k
            end if
        end do
        end do
        end do

        l2c = sqrt(sumsq/vol)
        l2all = sqrt(sum(sumsq)/(real(ncomp)*vol))
        linfall = maxval(linfc)
        l2e = sqrt(sum(sumsq(1:3))/(3.0*vol))
        l2h = sqrt(sum(sumsq(4:6))/(3.0*vol))
        linfe = maxval(linfc(1:3))
        linfh = maxval(linfc(4:6))
    end subroutine compute_errors


    subroutine update_hot_list(ic,err,i,j,k,hi,hj,hk,herr)
        implicit none
        integer, intent(in) :: ic, i, j, k
        integer, intent(inout) :: hi(ncomp,nhot), hj(ncomp,nhot), hk(ncomp,nhot)
        real, intent(in) :: err
        real, intent(inout) :: herr(ncomp,nhot)
        integer :: p, q

        if (err <= herr(ic,nhot)) return

        p = nhot
        do while (p >= 1 .and. err > herr(ic,p))
            p = p - 1
        end do

        do q = nhot, p+2, -1
            herr(ic,q) = herr(ic,q-1)
            hi(ic,q) = hi(ic,q-1)
            hj(ic,q) = hj(ic,q-1)
            hk(ic,q) = hk(ic,q-1)
        end do

        herr(ic,p+1) = err
        hi(ic,p+1) = i
        hj(ic,p+1) = j
        hk(ic,p+1) = k
    end subroutine update_hot_list


    subroutine print_hot_list(ic,nhot_local,herr_local,hi_local,hj_local,hk_local,dx,dy,dz)
        implicit none
        integer, intent(in) :: ic, nhot_local
        integer, intent(in) :: hi_local(nhot_local), hj_local(nhot_local), hk_local(nhot_local)
        real, intent(in) :: herr_local(nhot_local), dx, dy, dz
        integer :: p
        real :: x, y, z

        do p = 1, nhot_local
            call component_xyz(ic,hi_local(p),hj_local(p),hk_local(p),dx,dy,dz,x,y,z)
            write(*,'(A,I0,A,3(I0,1X),A,3(1PE11.3,1X),A,1PE11.3)') '        #',p,' idx=', &
                hi_local(p),hj_local(p),hk_local(p), ' xyz=',x,y,z, ' err=',herr_local(p)
        end do
    end subroutine print_hot_list


    subroutine component_xyz(ic,i,j,k,dx,dy,dz,x,y,z)
        implicit none
        integer, intent(in) :: ic, i, j, k
        real, intent(in) :: dx, dy, dz
        real, intent(out) :: x, y, z

        select case (ic)
        case (1) ! Ex(i+1/2,j,k)
            x = (real(i)-0.5)*dx
            y = (real(j)-1.0)*dy
            z = (real(k)-1.0)*dz
        case (2) ! Ey(i,j+1/2,k)
            x = (real(i)-1.0)*dx
            y = (real(j)-0.5)*dy
            z = (real(k)-1.0)*dz
        case (3) ! Ez(i,j,k+1/2)
            x = (real(i)-1.0)*dx
            y = (real(j)-1.0)*dy
            z = (real(k)-0.5)*dz
        case (4) ! Hx(i,j+1/2,k+1/2)
            x = (real(i)-1.0)*dx
            y = (real(j)-0.5)*dy
            z = (real(k)-0.5)*dz
        case (5) ! Hy(i+1/2,j,k+1/2)
            x = (real(i)-0.5)*dx
            y = (real(j)-1.0)*dy
            z = (real(k)-0.5)*dz
        case (6) ! Hz(i+1/2,j+1/2,k)
            x = (real(i)-0.5)*dx
            y = (real(j)-0.5)*dy
            z = (real(k)-1.0)*dz
        end select
    end subroutine component_xyz


    subroutine write_viz_frame(unit,nx,ny,nz,dx,dy,dz,step,t_e,omega0,Ez)
        implicit none
        integer, intent(in) :: unit, nx, ny, nz, step
        real, intent(in) :: dx, dy, dz, t_e, omega0
        real, intent(in) :: Ez(0:nx+1,0:ny+1,0:nz+1)
        integer :: i, k, j_mid
        real :: x, y, z
        real :: ex0, ey0, ez0, hx0, hy0, hz0, sex, sey, sez, shx, shy, shz
        real :: Ez_num(1:nx,1:nz), Ez_exact(1:nx,1:nz)

        j_mid = (ny+1)/2
        do k = 1, nz
        do i = 1, nx
            Ez_num(i,k) = Ez(i,j_mid,k)
            x = (real(i)-1.0)*dx
            y = (real(j_mid)-1.0)*dy
            z = (real(k)-0.5)*dz
            call cartesian_exact_and_sources(x,y,z,t_e,ep,mu,lx,ly,lz,omega0, &
                ex0,ey0,ez0,hx0,hy0,hz0,sex,sey,sez,shx,shy,shz)
            Ez_exact(i,k) = ez0
        end do
        end do

        write(unit) step
        write(unit) t_e
        write(unit) Ez_num
        write(unit) Ez_exact
    end subroutine write_viz_frame


    subroutine fill_periodic_scalar(nx,ny,nz,A)
        implicit none
        integer, intent(in) :: nx, ny, nz
        real, intent(inout) :: A(0:nx+1,0:ny+1,0:nz+1)
        integer :: i, j, k

        do k = 1, nz
        do j = 1, ny
            A(0,j,k) = A(nx,j,k)
            A(nx+1,j,k) = A(1,j,k)
        end do
        end do

        do k = 1, nz
        do i = 0, nx+1
            A(i,0,k) = A(i,ny,k)
            A(i,ny+1,k) = A(i,1,k)
        end do
        end do

        do j = 0, ny+1
        do i = 0, nx+1
            A(i,j,0) = A(i,j,nz)
            A(i,j,nz+1) = A(i,j,1)
        end do
        end do
    end subroutine fill_periodic_scalar


    subroutine fill_periodic_all(nx,ny,nz,Ex,Ey,Ez,Hx,Hy,Hz)
        implicit none
        integer, intent(in) :: nx, ny, nz
        real, intent(inout) :: Ex(0:nx+1,0:ny+1,0:nz+1), Ey(0:nx+1,0:ny+1,0:nz+1), Ez(0:nx+1,0:ny+1,0:nz+1)
        real, intent(inout) :: Hx(0:nx+1,0:ny+1,0:nz+1), Hy(0:nx+1,0:ny+1,0:nz+1), Hz(0:nx+1,0:ny+1,0:nz+1)
        call fill_periodic_scalar(nx,ny,nz,Ex)
        call fill_periodic_scalar(nx,ny,nz,Ey)
        call fill_periodic_scalar(nx,ny,nz,Ez)
        call fill_periodic_scalar(nx,ny,nz,Hx)
        call fill_periodic_scalar(nx,ny,nz,Hy)
        call fill_periodic_scalar(nx,ny,nz,Hz)
    end subroutine fill_periodic_all


    subroutine fill_periodic_only_h(nx,ny,nz,Hx,Hy,Hz)
        implicit none
        integer, intent(in) :: nx, ny, nz
        real, intent(inout) :: Hx(0:nx+1,0:ny+1,0:nz+1), Hy(0:nx+1,0:ny+1,0:nz+1), Hz(0:nx+1,0:ny+1,0:nz+1)
        call fill_periodic_scalar(nx,ny,nz,Hx)
        call fill_periodic_scalar(nx,ny,nz,Hy)
        call fill_periodic_scalar(nx,ny,nz,Hz)
    end subroutine fill_periodic_only_h


    subroutine fill_periodic_only_e(nx,ny,nz,Ex,Ey,Ez)
        implicit none
        integer, intent(in) :: nx, ny, nz
        real, intent(inout) :: Ex(0:nx+1,0:ny+1,0:nz+1), Ey(0:nx+1,0:ny+1,0:nz+1), Ez(0:nx+1,0:ny+1,0:nz+1)
        call fill_periodic_scalar(nx,ny,nz,Ex)
        call fill_periodic_scalar(nx,ny,nz,Ey)
        call fill_periodic_scalar(nx,ny,nz,Ez)
    end subroutine fill_periodic_only_e

end program test_mms_3d_cartesian_convergence
