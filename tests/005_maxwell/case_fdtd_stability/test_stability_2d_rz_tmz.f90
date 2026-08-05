program test_stability_2d_rz_tmz

    use mod_E01_fdtd_2d_rz_tmz
    use stability_common
    use, intrinsic :: ieee_arithmetic
    implicit none

    integer, parameter :: nr = 80, nz = 128
    real, parameter :: ep = 1.0, mu = 1.0
    real, parameter :: rmax = 1.0, lz = 1.0
    real, parameter :: cfl_scale = 0.8
    real, parameter :: amp0 = 1.0e-4
    integer, parameter :: nsteps_default = 20000
    integer, parameter :: monitor_every_default = 100
    integer, parameter :: axis_band_cells = 2
    real, parameter :: growth_tol = 1.0e-2

    integer :: nsteps, monitor_every, n
    real :: dr, dz, c0, dt_crit, dt, t_n
    real, allocatable :: Er(:,:), Ez(:,:), Ha(:,:)
    real :: max_abs_e, max_abs_h, total_energy, axis_band_max, first_ring_max, i0_active_max, i1_active_max
    real :: max_abs_e0, max_abs_h0, energy0
    real :: max_abs_e_final, max_abs_h_final, energy_final
    real :: max_e_ratio, max_h_ratio, final_energy_ratio
    real :: prev_energy, prev_axis_band
    integer :: energy_growth_counter, axis_growth_counter
    logical :: has_naninf, local_nan
    character(len=16) :: result

    call parse_int_arg(1, nsteps_default, nsteps)
    call parse_int_arg(2, monitor_every_default, monitor_every)
    nsteps = max(1, nsteps)
    monitor_every = max(1, min(monitor_every, nsteps))

    dr = rmax/real(nr)
    dz = lz/real(nz)
    c0 = 1.0/sqrt(ep*mu)
    dt_crit = 1.0/(c0*sqrt((1.0/dr)**2 + (1.0/dz)**2))
    dt = cfl_scale*dt_crit

    allocate(Er(0:nr,0:nz), Ez(0:nr,0:nz), Ha(0:nr,0:nz))

    call init_fields(nr,nz,dr,dz,amp0,Er,Ez,Ha)
    call fill_boundaries_all(nr,nz,Er,Ez,Ha)

    has_naninf = .false.
    energy_growth_counter = 0
    axis_growth_counter = 0

    call compute_metrics(nr,nz,dr,dz,ep,mu,axis_band_cells,Er,Ez,Ha, &
        max_abs_e0,max_abs_h0,energy0,axis_band_max,first_ring_max,i0_active_max,i1_active_max,local_nan)
    has_naninf = has_naninf .or. local_nan

    prev_energy = energy0
    prev_axis_band = axis_band_max
    max_abs_e = max_abs_e0
    max_abs_h = max_abs_h0
    total_energy = energy0

    write(*,'(A)') '=== Stability Test: 2D RZ TMz (no source, long run) ==='
    write(*,'(A,I0,A,I0,A,F6.3,A,1PE12.4)') 'nr=',nr,', nz=',nz,', cfl=',cfl_scale,', dt=',dt
    write(*,'(A,I0,A,I0)') 'nsteps=',nsteps,', monitor_every=',monitor_every
    write(*,'(A)') '# step,time,max_abs_E,max_abs_H,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_first_ring_max'
    call write_monitor_row(0,0.0,max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_active_max)

    t_n = 0.0
    do n = 1, nsteps
        call sub_E01_fdtd_2d_rz_tmz_H(0,nr,0,nz,0,nr-1,0,nz-1,Ha,Er,Ez,dt,dr,dz,mu)
        call fill_h_boundaries(nr,nz,Ha)

        call sub_E01_fdtd_2d_rz_tmz_E(0,nr,0,nz,0,nr-1,1,nz-1,Ha,Er,Ez,dt,dr,dz,ep)
        call fill_e_boundaries(nr,nz,Er,Ez)

        t_n = t_n + dt

        if (mod(n,monitor_every) == 0 .or. n == nsteps) then
            call compute_metrics(nr,nz,dr,dz,ep,mu,axis_band_cells,Er,Ez,Ha, &
                max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_active_max,local_nan)
            has_naninf = has_naninf .or. local_nan

            call write_monitor_row(n,t_n,max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_active_max)

            call update_growth_counter(prev_energy,total_energy,growth_tol,energy_growth_counter)
            call update_growth_counter(prev_axis_band,axis_band_max,growth_tol,axis_growth_counter)
            prev_energy = total_energy
            prev_axis_band = axis_band_max
        end if
    end do

    max_abs_e_final = max_abs_e
    max_abs_h_final = max_abs_h
    energy_final = total_energy
    max_e_ratio = safe_ratio(max_abs_e_final, max_abs_e0)
    max_h_ratio = safe_ratio(max_abs_h_final, max_abs_h0)
    final_energy_ratio = safe_ratio(energy_final, energy0)

    call classify_stability(has_naninf,final_energy_ratio,max_e_ratio,max_h_ratio, &
        energy_growth_counter,axis_growth_counter,result)

    write(*,'(A)') '--- Final Summary ---'
    write(*,'(A,1PE12.4)') 'final_energy_ratio=', final_energy_ratio
    write(*,'(A,1PE12.4)') 'max_abs_E_final=', max_abs_e_final
    write(*,'(A,1PE12.4)') 'max_abs_H_final=', max_abs_h_final
    write(*,'(A,A)') 'result=', trim(result)
    write(*,'("SUMMARY_CSV,2D_RZ_TMz,",F5.3,",",I0,",",1PE12.4,",",1PE12.4,",",1PE12.4,",",A)') &
        cfl_scale, nsteps, final_energy_ratio, max_abs_e_final, max_abs_h_final, trim(result)

    deallocate(Er,Ez,Ha)

contains

    subroutine write_monitor_row(step,time,maxe,maxh,energy,axismax,ringmax,i0max,i1max)
        implicit none
        integer, intent(in) :: step
        real, intent(in) :: time,maxe,maxh,energy,axismax,ringmax,i0max,i1max
        write(*,'(I0,",",1PE14.6,",",1PE14.6,",",1PE14.6,",",1PE14.6,",",1PE14.6,",",1PE14.6,",",1PE14.6,",",1PE14.6)') &
            step,time,maxe,maxh,energy,axismax,ringmax,i0max,i1max
    end subroutine write_monitor_row


    subroutine init_fields(nr,nz,dr,dz,amp,Er,Ez,Ha)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(in) :: dr, dz, amp
        real, intent(inout) :: Er(0:nr,0:nz), Ez(0:nr,0:nz), Ha(0:nr,0:nz)
        integer :: i, k
        real :: r_er, r_ez, r_h, z_er, z_ez, z_h, f_er, f_ez, f_h, kz

        kz = 2.0*acos(-1.0)/lz
        Er = 0.0
        Ez = 0.0
        Ha = 0.0

        do k = 0, nz
        do i = 0, nr
            r_er = (real(i)+0.5)*dr
            r_ez = real(i)*dr
            r_h = (real(i)+0.5)*dr

            z_er = real(k)*dz
            z_ez = (real(k)+0.5)*dz
            z_h = (real(k)+0.5)*dz

            f_er = max(0.0,1.0-(r_er/rmax)**2)
            f_ez = max(0.0,1.0-(r_ez/rmax)**2)
            f_h  = max(0.0,1.0-(r_h /rmax)**2)

            Er(i,k) = amp*r_er*f_er*sin(kz*z_er)
            Ez(i,k) = amp*(f_ez**2)*cos(kz*z_ez)
            Ha(i,k) = amp*r_h*f_h*cos(kz*z_h)
        end do
        end do
    end subroutine init_fields


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
        max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_active_max,has_nan)
        implicit none
        integer, intent(in) :: nr, nz, axis_cells
        real, intent(in) :: dr, dz, ep, mu
        real, intent(in) :: Er(0:nr,0:nz), Ez(0:nr,0:nz), Ha(0:nr,0:nz)
        real, intent(out) :: max_abs_e, max_abs_h, total_energy, axis_band_max, first_ring_max
        real, intent(out) :: i0_active_max, i1_active_max
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
                r = (real(i)+0.5)*dr
                w = r*dr*dz
                total_energy = total_energy + mu*av*av*w
            end if
        end do
        end do
    end subroutine compute_metrics

end program test_stability_2d_rz_tmz
