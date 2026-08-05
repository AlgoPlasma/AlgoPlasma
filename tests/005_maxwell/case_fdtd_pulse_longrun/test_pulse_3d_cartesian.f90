program test_pulse_3d_cartesian

    use mod_E03_fdtd_3d_cartesian
    use pulse_common
    use, intrinsic :: ieee_arithmetic
    implicit none

    integer, parameter :: nx = 32, ny = 32, nz = 32
    real, parameter :: ep = 1.0, mu = 1.0
    real, parameter :: lx = 1.0, ly = 1.0, lz = 1.0
    real, parameter :: cfl_scale = 0.8
    integer, parameter :: nsteps_default = 20000
    integer, parameter :: npulse_default = 60
    integer, parameter :: monitor_every_default = 100
    real, parameter :: pulse_amp_default = 1.0e-4
    integer, parameter :: axis_band_cells = 2
    real, parameter :: growth_tol = 1.0e-2

    integer :: nsteps, npulse, monitor_every, n, pulse_on
    real :: pulse_amp
    real :: dx, dy, dz, c0, dt_crit, dt, t_n
    real, allocatable :: Ex(:,:,:), Ey(:,:,:), Ez(:,:,:), Hx(:,:,:), Hy(:,:,:), Hz(:,:,:)
    real :: max_abs_e, max_abs_h, total_energy, axis_band_max, first_ring_max, i0_active_max, i1_active_max
    real :: plane1_ez_max, plane1_hz_max
    real :: max_abs_e_final, max_abs_h_final, energy_final
    real :: energy_pulse_end, axis_pulse_end, t_pulse_end
    real :: final_energy_ratio, post_pulse_growth_rate
    real :: prev_post_energy, prev_post_axis
    integer :: post_energy_growth_counter, post_axis_growth_counter
    logical :: has_naninf, local_nan, pulse_end_ready
    character(len=16) :: result

    call parse_int_arg(1, nsteps_default, nsteps)
    call parse_int_arg(2, monitor_every_default, monitor_every)
    call parse_int_arg(3, npulse_default, npulse)
    call parse_real_arg(4, pulse_amp_default, pulse_amp)

    nsteps = max(1, nsteps)
    monitor_every = max(1, min(monitor_every, nsteps))
    npulse = max(0, min(npulse, nsteps))
    pulse_amp = abs(pulse_amp)

    dx = lx/real(nx)
    dy = ly/real(ny)
    dz = lz/real(nz)
    c0 = 1.0/sqrt(ep*mu)
    dt_crit = 1.0/(c0*sqrt((1.0/dx)**2 + (1.0/dy)**2 + (1.0/dz)**2))
    dt = cfl_scale*dt_crit

    allocate(Ex(0:nx+1,0:ny+1,0:nz+1), Ey(0:nx+1,0:ny+1,0:nz+1), Ez(0:nx+1,0:ny+1,0:nz+1))
    allocate(Hx(0:nx+1,0:ny+1,0:nz+1), Hy(0:nx+1,0:ny+1,0:nz+1), Hz(0:nx+1,0:ny+1,0:nz+1))
    Ex = 0.0
    Ey = 0.0
    Ez = 0.0
    Hx = 0.0
    Hy = 0.0
    Hz = 0.0
    call fill_periodic_all(nx,ny,nz,Ex,Ey,Ez,Hx,Hy,Hz)

    has_naninf = .false.
    post_energy_growth_counter = 0
    post_axis_growth_counter = 0
    pulse_end_ready = .false.

    call compute_metrics(nx,ny,nz,dx,dy,dz,ep,mu,axis_band_cells,Ex,Ey,Ez,Hx,Hy,Hz, &
        max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_active_max, &
        plane1_ez_max,plane1_hz_max,local_nan)
    has_naninf = has_naninf .or. local_nan

    energy_pulse_end = total_energy
    axis_pulse_end = axis_band_max
    t_pulse_end = 0.0
    prev_post_energy = total_energy
    prev_post_axis = axis_band_max
    if (npulse == 0) pulse_end_ready = .true.

    write(*,'(A)') '=== Pulse Long-Run Stability: 3D Cartesian ==='
    write(*,'(A,I0,A,I0,A,I0,A,F6.3,A,1PE12.4)') 'nx=',nx,', ny=',ny,', nz=',nz,', cfl=',cfl_scale,', dt=',dt
    write(*,'(A,I0,A,I0,A,I0,A,1PE12.4)') 'Ntotal=',nsteps,', Npulse=',npulse, &
        ', monitor_every=',monitor_every,', pulse_amp=',pulse_amp
    write(*,'(A)') '# step,time,pulse_on,max_abs_E,max_abs_H,total_energy,axis_band_max,first_ring_max,' // &
        'i0_active_max,i1_first_ring_max,plane1_Ez_max,plane1_Hz_max'
    pulse_on = merge(1,0,npulse > 0)
    call write_monitor_row(0,0.0,pulse_on,max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max, &
        i0_active_max,i1_active_max,plane1_ez_max,plane1_hz_max)

    t_n = 0.0
    do n = 1, nsteps
        call sub_E03_fdtd_3d_cartesian_H(0,nx+1,0,ny+1,0,nz+1,1,nx,1,ny,1,nz, &
            Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu)
        call fill_periodic_only_h(nx,ny,nz,Hx,Hy,Hz)

        call sub_E03_fdtd_3d_cartesian_E(0,nx+1,0,ny+1,0,nz+1,1,nx,1,ny,1,nz, &
            Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,ep)
        if (n <= npulse) call add_pulse_source(n,npulse,pulse_amp,nx,ny,nz,dx,dy,dz,Ez)
        call fill_periodic_only_e(nx,ny,nz,Ex,Ey,Ez)

        t_n = t_n + dt

        if ((n == npulse) .and. (.not. pulse_end_ready)) then
            call compute_metrics(nx,ny,nz,dx,dy,dz,ep,mu,axis_band_cells,Ex,Ey,Ez,Hx,Hy,Hz, &
                max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_active_max, &
                plane1_ez_max,plane1_hz_max,local_nan)
            has_naninf = has_naninf .or. local_nan
            energy_pulse_end = total_energy
            axis_pulse_end = axis_band_max
            t_pulse_end = t_n
            prev_post_energy = total_energy
            prev_post_axis = axis_band_max
            pulse_end_ready = .true.
        end if

        if (mod(n,monitor_every) == 0 .or. n == nsteps) then
            call compute_metrics(nx,ny,nz,dx,dy,dz,ep,mu,axis_band_cells,Ex,Ey,Ez,Hx,Hy,Hz, &
                max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_active_max, &
                plane1_ez_max,plane1_hz_max,local_nan)
            has_naninf = has_naninf .or. local_nan

            pulse_on = merge(1,0,n <= npulse)
            call write_monitor_row(n,t_n,pulse_on,max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max, &
                i0_active_max,i1_active_max,plane1_ez_max,plane1_hz_max)

            if (n > npulse .and. pulse_end_ready) then
                call update_growth_counter(prev_post_energy,total_energy,growth_tol,post_energy_growth_counter)
                call update_growth_counter(prev_post_axis,axis_band_max,growth_tol,post_axis_growth_counter)
                prev_post_energy = total_energy
                prev_post_axis = axis_band_max
            end if
        end if
    end do

    if (.not. pulse_end_ready) then
        energy_pulse_end = total_energy
        axis_pulse_end = axis_band_max
        t_pulse_end = t_n
        pulse_end_ready = .true.
    end if

    max_abs_e_final = max_abs_e
    max_abs_h_final = max_abs_h
    energy_final = total_energy
    final_energy_ratio = safe_ratio(energy_final, energy_pulse_end)
    post_pulse_growth_rate = compute_post_pulse_growth_rate(energy_pulse_end, energy_final, t_pulse_end, t_n)

    call classify_pulse_stability(has_naninf,final_energy_ratio,post_pulse_growth_rate, &
        post_energy_growth_counter,post_axis_growth_counter,result)

    write(*,'(A)') '--- Final Summary ---'
    write(*,'(A,1PE12.4)') 'pulse_end_energy=', energy_pulse_end
    write(*,'(A,1PE12.4)') 'final_energy_ratio=', final_energy_ratio
    write(*,'(A,1PE12.4)') 'post_pulse_growth_rate=', post_pulse_growth_rate
    write(*,'(A,1PE12.4)') 'max_abs_E_final=', max_abs_e_final
    write(*,'(A,1PE12.4)') 'max_abs_H_final=', max_abs_h_final
    write(*,'(A,1PE12.4)') 'plane1_Ez_max_final=', plane1_ez_max
    write(*,'(A,1PE12.4)') 'plane1_Hz_max_final=', plane1_hz_max
    write(*,'(A,A)') 'result=', trim(result)
    write(*,'("SUMMARY_CSV,3D_CART,",F5.3,",",I0,",",I0,",",1PE12.4,",",1PE12.4,",",A)') &
        cfl_scale, npulse, nsteps, final_energy_ratio, post_pulse_growth_rate, trim(result)

    deallocate(Ex,Ey,Ez,Hx,Hy,Hz)

contains

    subroutine write_monitor_row(step,time,pulse_on,maxe,maxh,energy,axismax,ringmax,i0max,i1max,ez1,hz1)
        implicit none
        integer, intent(in) :: step, pulse_on
        real, intent(in) :: time,maxe,maxh,energy,axismax,ringmax,i0max,i1max,ez1,hz1
        write(*,'(*(g0,:,","))') &
            step,time,pulse_on,maxe,maxh,energy,axismax,ringmax,i0max,i1max,ez1,hz1
    end subroutine write_monitor_row


    subroutine add_pulse_source(n,npulse,amp,nx,ny,nz,dx,dy,dz,Ez)
        implicit none
        integer, intent(in) :: n, npulse, nx, ny, nz
        real, intent(in) :: amp, dx, dy, dz
        real, intent(inout) :: Ez(0:nx+1,0:ny+1,0:nz+1)
        integer :: i, j, k
        real :: pulse_t, x, y, z, x0, y0, z0, wx, wy, wz, shape

        pulse_t = smooth_pulse_envelope(n,npulse,amp)
        if (pulse_t == 0.0) return

        x0 = 0.35*lx
        y0 = 0.45*ly
        z0 = 0.40*lz
        wx = 0.10*lx
        wy = 0.10*ly
        wz = 0.10*lz

        do k = 2, nz-1
        do j = 2, ny-1
        do i = 2, nx-1
            x = (real(i)-1.0)*dx
            y = (real(j)-1.0)*dy
            z = (real(k)-0.5)*dz
            shape = exp(-((x-x0)/wx)**2 - ((y-y0)/wy)**2 - ((z-z0)/wz)**2) * &
                cos(2.0*acos(-1.0)*(x-x0)/lx)
            Ez(i,j,k) = Ez(i,j,k) + pulse_t*shape
        end do
        end do
        end do
    end subroutine add_pulse_source


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


    subroutine compute_metrics(nx,ny,nz,dx,dy,dz,ep,mu,axis_cells,Ex,Ey,Ez,Hx,Hy,Hz, &
        max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_active_max, &
        plane1_ez_max,plane1_hz_max,has_nan)
        implicit none
        integer, intent(in) :: nx, ny, nz, axis_cells
        real, intent(in) :: dx, dy, dz, ep, mu
        real, intent(in) :: Ex(0:nx+1,0:ny+1,0:nz+1), Ey(0:nx+1,0:ny+1,0:nz+1), Ez(0:nx+1,0:ny+1,0:nz+1)
        real, intent(in) :: Hx(0:nx+1,0:ny+1,0:nz+1), Hy(0:nx+1,0:ny+1,0:nz+1), Hz(0:nx+1,0:ny+1,0:nz+1)
        real, intent(out) :: max_abs_e, max_abs_h, total_energy, axis_band_max, first_ring_max
        real, intent(out) :: i0_active_max, i1_active_max, plane1_ez_max, plane1_hz_max
        logical, intent(out) :: has_nan

        integer :: i, j, k
        real :: v, av, w

        has_nan = .false.
        max_abs_e = 0.0
        max_abs_h = 0.0
        total_energy = 0.0
        axis_band_max = 0.0
        first_ring_max = 0.0
        i0_active_max = 0.0
        i1_active_max = 0.0
        plane1_ez_max = 0.0
        plane1_hz_max = 0.0
        w = dx*dy*dz

        do k = 1, nz
        do j = 1, ny
        do i = 1, nx
            v = Ex(i,j,k)
            if (.not. ieee_is_finite(v)) then
                has_nan = .true.
            else
                av = abs(v)
                max_abs_e = max(max_abs_e,av)
                if (i <= axis_cells) axis_band_max = max(axis_band_max,av)
                if (i == 1) then
                    first_ring_max = max(first_ring_max,av)
                    i0_active_max = max(i0_active_max,av)
                end if
                if (i == 2) i1_active_max = max(i1_active_max,av)
                total_energy = total_energy + ep*av*av*w
            end if

            v = Ey(i,j,k)
            if (.not. ieee_is_finite(v)) then
                has_nan = .true.
            else
                av = abs(v)
                max_abs_e = max(max_abs_e,av)
                if (i <= axis_cells) axis_band_max = max(axis_band_max,av)
                if (i == 1) then
                    first_ring_max = max(first_ring_max,av)
                    i0_active_max = max(i0_active_max,av)
                end if
                if (i == 2) i1_active_max = max(i1_active_max,av)
                total_energy = total_energy + ep*av*av*w
            end if

            v = Ez(i,j,k)
            if (.not. ieee_is_finite(v)) then
                has_nan = .true.
            else
                av = abs(v)
                max_abs_e = max(max_abs_e,av)
                if (i <= axis_cells) axis_band_max = max(axis_band_max,av)
                if (i == 1) then
                    first_ring_max = max(first_ring_max,av)
                    i0_active_max = max(i0_active_max,av)
                    plane1_ez_max = max(plane1_ez_max,av)
                end if
                if (i == 2) i1_active_max = max(i1_active_max,av)
                total_energy = total_energy + ep*av*av*w
            end if

            v = Hx(i,j,k)
            if (.not. ieee_is_finite(v)) then
                has_nan = .true.
            else
                av = abs(v)
                max_abs_h = max(max_abs_h,av)
                if (i <= axis_cells) axis_band_max = max(axis_band_max,av)
                if (i == 1) then
                    first_ring_max = max(first_ring_max,av)
                    i0_active_max = max(i0_active_max,av)
                end if
                if (i == 2) i1_active_max = max(i1_active_max,av)
                total_energy = total_energy + mu*av*av*w
            end if

            v = Hy(i,j,k)
            if (.not. ieee_is_finite(v)) then
                has_nan = .true.
            else
                av = abs(v)
                max_abs_h = max(max_abs_h,av)
                if (i <= axis_cells) axis_band_max = max(axis_band_max,av)
                if (i == 1) then
                    first_ring_max = max(first_ring_max,av)
                    i0_active_max = max(i0_active_max,av)
                end if
                if (i == 2) i1_active_max = max(i1_active_max,av)
                total_energy = total_energy + mu*av*av*w
            end if

            v = Hz(i,j,k)
            if (.not. ieee_is_finite(v)) then
                has_nan = .true.
            else
                av = abs(v)
                max_abs_h = max(max_abs_h,av)
                if (i <= axis_cells) axis_band_max = max(axis_band_max,av)
                if (i == 1) then
                    first_ring_max = max(first_ring_max,av)
                    i0_active_max = max(i0_active_max,av)
                    plane1_hz_max = max(plane1_hz_max,av)
                end if
                if (i == 2) i1_active_max = max(i1_active_max,av)
                total_energy = total_energy + mu*av*av*w
            end if
        end do
        end do
        end do
    end subroutine compute_metrics

end program test_pulse_3d_cartesian
