program test_pulse_2d_rz_tmz

    use mod_E01_fdtd_2d_rz_tmz
    use pulse_common
    use, intrinsic :: ieee_arithmetic
    implicit none

    integer, parameter :: nr = 80, nz = 128
    real, parameter :: ep = 1.0, mu = 1.0
    real, parameter :: rmax = 1.0, lz = 1.0
    real, parameter :: cfl_scale = 0.8
    integer, parameter :: nsteps_default = 20000
    integer, parameter :: npulse_default = 60
    integer, parameter :: monitor_every_default = 100
    real, parameter :: pulse_amp_default = 1.0e-4
    integer, parameter :: axis_band_cells = 2
    real, parameter :: growth_tol = 1.0e-2

    integer :: nsteps, npulse, monitor_every, n, pulse_on
    real :: pulse_amp
    real :: dr, dz, c0, dt_crit, dt, t_n
    real, allocatable :: Er(:,:), Ez(:,:), Ha(:,:)
    real :: max_abs_e, max_abs_h, total_energy, axis_band_max, first_ring_max, i0_active_max, i1_active_max
    real :: axis_near_ez_max, axis_near_ha_max
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

    dr = rmax/real(nr)
    dz = lz/real(nz)
    c0 = 1.0/sqrt(ep*mu)
    dt_crit = 1.0/(c0*sqrt((1.0/dr)**2 + (1.0/dz)**2))
    dt = cfl_scale*dt_crit

    allocate(Er(0:nr,0:nz), Ez(0:nr,0:nz), Ha(0:nr,0:nz))
    Er = 0.0
    Ez = 0.0
    Ha = 0.0
    call fill_boundaries_all(nr,nz,Er,Ez,Ha)

    has_naninf = .false.
    post_energy_growth_counter = 0
    post_axis_growth_counter = 0
    pulse_end_ready = .false.

    call compute_metrics(nr,nz,dr,dz,ep,mu,axis_band_cells,Er,Ez,Ha, &
        max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_active_max, &
        axis_near_ez_max,axis_near_ha_max,local_nan)
    has_naninf = has_naninf .or. local_nan

    energy_pulse_end = total_energy
    axis_pulse_end = axis_band_max
    t_pulse_end = 0.0
    prev_post_energy = total_energy
    prev_post_axis = axis_band_max
    if (npulse == 0) pulse_end_ready = .true.

    write(*,'(A)') '=== Pulse Long-Run Stability: 2D RZ TMz ==='
    write(*,'(A,I0,A,I0,A,F6.3,A,1PE12.4)') 'nr=',nr,', nz=',nz,', cfl=',cfl_scale,', dt=',dt
    write(*,'(A,I0,A,I0,A,I0,A,1PE12.4)') 'Ntotal=',nsteps,', Npulse=',npulse, &
        ', monitor_every=',monitor_every,', pulse_amp=',pulse_amp
    write(*,'(A)') '# step,time,pulse_on,max_abs_E,max_abs_H,total_energy,axis_band_max,first_ring_max,' // &
        'i0_active_max,i1_first_ring_max,axis_near_Ez_max,axis_near_Ha_max'
    pulse_on = merge(1,0,npulse > 0)
    call write_monitor_row(0,0.0,pulse_on,max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max, &
        i0_active_max,i1_active_max,axis_near_ez_max,axis_near_ha_max)

    t_n = 0.0
    do n = 1, nsteps
        call sub_E01_fdtd_2d_rz_tmz_H(0,nr,0,nz,0,nr-1,0,nz-1,Ha,Er,Ez,dt,dr,dz,mu)
        call fill_h_boundaries(nr,nz,Ha)

        call sub_E01_fdtd_2d_rz_tmz_E(0,nr,0,nz,0,nr-1,1,nz-1,Ha,Er,Ez,dt,dr,dz,ep)
        if (n <= npulse) call add_pulse_source(n,npulse,pulse_amp,nr,nz,dr,dz,Ez)
        call fill_e_boundaries(nr,nz,Er,Ez)

        t_n = t_n + dt

        if ((n == npulse) .and. (.not. pulse_end_ready)) then
            call compute_metrics(nr,nz,dr,dz,ep,mu,axis_band_cells,Er,Ez,Ha, &
                max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_active_max, &
                axis_near_ez_max,axis_near_ha_max,local_nan)
            has_naninf = has_naninf .or. local_nan
            energy_pulse_end = total_energy
            axis_pulse_end = axis_band_max
            t_pulse_end = t_n
            prev_post_energy = total_energy
            prev_post_axis = axis_band_max
            pulse_end_ready = .true.
        end if

        if (mod(n,monitor_every) == 0 .or. n == nsteps) then
            call compute_metrics(nr,nz,dr,dz,ep,mu,axis_band_cells,Er,Ez,Ha, &
                max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_active_max, &
                axis_near_ez_max,axis_near_ha_max,local_nan)
            has_naninf = has_naninf .or. local_nan

            pulse_on = merge(1,0,n <= npulse)
            call write_monitor_row(n,t_n,pulse_on,max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max, &
                i0_active_max,i1_active_max,axis_near_ez_max,axis_near_ha_max)

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
    write(*,'(A,A)') 'result=', trim(result)
    write(*,'("SUMMARY_CSV,2D_RZ_TMz,",F5.3,",",I0,",",I0,",",1PE12.4,",",1PE12.4,",",A)') &
        cfl_scale, npulse, nsteps, final_energy_ratio, post_pulse_growth_rate, trim(result)

    deallocate(Er,Ez,Ha)

contains

    subroutine write_monitor_row(step,time,pulse_on,maxe,maxh,energy,axismax,ringmax,i0max,i1max,ezax,hax)
        implicit none
        integer, intent(in) :: step, pulse_on
        real, intent(in) :: time,maxe,maxh,energy,axismax,ringmax,i0max,i1max,ezax,hax
        write(*,'(*(g0,:,","))') &
            step,time,pulse_on,maxe,maxh,energy,axismax,ringmax,i0max,i1max,ezax,hax
    end subroutine write_monitor_row


    subroutine add_pulse_source(n,npulse,amp,nr,nz,dr,dz,Ez)
        implicit none
        integer, intent(in) :: n, npulse, nr, nz
        real, intent(in) :: amp, dr, dz
        real, intent(inout) :: Ez(0:nr,0:nz)
        integer :: i, k
        real :: pulse_t, r, z, r0, z0, wr, wz, shape, phase

        pulse_t = smooth_pulse_envelope(n,npulse,amp)
        if (pulse_t == 0.0) return

        r0 = 0.35*rmax
        z0 = 0.45*lz
        wr = 0.10*rmax
        wz = 0.10*lz

        do k = 2, nz-2
        do i = 2, nr-2
            r = real(i)*dr
            z = (real(k)+0.5)*dz
            phase = cos(2.0*acos(-1.0)*(z-z0)/lz)
            shape = exp(-((r-r0)/wr)**2 - ((z-z0)/wz)**2) * phase
            Ez(i,k) = Ez(i,k) + pulse_t*shape
        end do
        end do
    end subroutine add_pulse_source


    subroutine fill_periodic_z(nr,nz,A)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(inout) :: A(0:nr,0:nz)
        integer :: i

        do i = 0, nr
            A(i,0) = A(i,nz-1)
            A(i,nz) = A(i,1)
        end do
    end subroutine fill_periodic_z


    subroutine fill_outer_r_copy(nr,nz,A)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(inout) :: A(0:nr,0:nz)
        integer :: k

        do k = 0, nz
            A(nr,k) = A(nr-1,k)
        end do
    end subroutine fill_outer_r_copy


    subroutine fill_h_boundaries(nr,nz,Ha)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(inout) :: Ha(0:nr,0:nz)
        call fill_periodic_z(nr,nz,Ha)
        call fill_outer_r_copy(nr,nz,Ha)
    end subroutine fill_h_boundaries


    subroutine fill_e_boundaries(nr,nz,Er,Ez)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(inout) :: Er(0:nr,0:nz), Ez(0:nr,0:nz)
        call fill_periodic_z(nr,nz,Er)
        call fill_periodic_z(nr,nz,Ez)
        call fill_outer_r_copy(nr,nz,Er)
        call fill_outer_r_copy(nr,nz,Ez)
    end subroutine fill_e_boundaries


    subroutine fill_boundaries_all(nr,nz,Er,Ez,Ha)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(inout) :: Er(0:nr,0:nz), Ez(0:nr,0:nz), Ha(0:nr,0:nz)
        call fill_h_boundaries(nr,nz,Ha)
        call fill_e_boundaries(nr,nz,Er,Ez)
    end subroutine fill_boundaries_all


    subroutine compute_metrics(nr,nz,dr,dz,ep,mu,axis_cells,Er,Ez,Ha, &
        max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_active_max, &
        axis_near_ez_max,axis_near_ha_max,has_nan)
        implicit none
        integer, intent(in) :: nr, nz, axis_cells
        real, intent(in) :: dr, dz, ep, mu
        real, intent(in) :: Er(0:nr,0:nz), Ez(0:nr,0:nz), Ha(0:nr,0:nz)
        real, intent(out) :: max_abs_e, max_abs_h, total_energy, axis_band_max, first_ring_max
        real, intent(out) :: i0_active_max, i1_active_max, axis_near_ez_max, axis_near_ha_max
        logical, intent(out) :: has_nan

        integer :: i, k
        real :: v, av, r, w

        has_nan = .false.
        max_abs_e = 0.0
        max_abs_h = 0.0
        total_energy = 0.0
        axis_band_max = 0.0
        first_ring_max = 0.0
        i0_active_max = 0.0
        i1_active_max = 0.0
        axis_near_ez_max = 0.0
        axis_near_ha_max = 0.0

        do k = 1, nz-1
        do i = 0, nr-1
            v = Er(i,k)
            if (.not. ieee_is_finite(v)) then
                has_nan = .true.
            else
                av = abs(v)
                max_abs_e = max(max_abs_e,av)
                if (i <= axis_cells) axis_band_max = max(axis_band_max,av)
                if (i == 1) first_ring_max = max(first_ring_max,av)
                if (i == 0) i0_active_max = max(i0_active_max,av)
                if (i == 1) i1_active_max = max(i1_active_max,av)
                r = (real(i)+0.5)*dr
                w = r*dr*dz
                total_energy = total_energy + ep*av*av*w
            end if

            v = Ez(i,k)
            if (.not. ieee_is_finite(v)) then
                has_nan = .true.
            else
                av = abs(v)
                max_abs_e = max(max_abs_e,av)
                if (i <= axis_cells) axis_band_max = max(axis_band_max,av)
                if (i == 1) first_ring_max = max(first_ring_max,av)
                if (i == 0) i0_active_max = max(i0_active_max,av)
                if (i == 1) i1_active_max = max(i1_active_max,av)
                if (i <= 1) axis_near_ez_max = max(axis_near_ez_max,av)
                r = real(i)*dr
                w = r*dr*dz
                total_energy = total_energy + ep*av*av*w
            end if
        end do
        end do

        do k = 0, nz-1
        do i = 0, nr-1
            v = Ha(i,k)
            if (.not. ieee_is_finite(v)) then
                has_nan = .true.
            else
                av = abs(v)
                max_abs_h = max(max_abs_h,av)
                if (i <= axis_cells) axis_band_max = max(axis_band_max,av)
                if (i == 1) first_ring_max = max(first_ring_max,av)
                if (i == 0) i0_active_max = max(i0_active_max,av)
                if (i == 1) i1_active_max = max(i1_active_max,av)
                if (i <= 1) axis_near_ha_max = max(axis_near_ha_max,av)
                r = (real(i)+0.5)*dr
                w = r*dr*dz
                total_energy = total_energy + mu*av*av*w
            end if
        end do
        end do
    end subroutine compute_metrics

end program test_pulse_2d_rz_tmz
