program test_stability_3d_cyl_m1

    use mod_E02_fdtd_3d_cylindrical
    use stability_common
    use, intrinsic :: ieee_arithmetic
    implicit none

    integer, parameter :: nr = 40, nphi = 32, nz = 64
    real, parameter :: ep = 1.0, mu = 1.0
    real, parameter :: rmax = 1.0, lz = 1.0
    real, parameter :: cfl_scale = 0.8
    real, parameter :: amp0 = 1.0e-4
    integer, parameter :: nsteps_default = 20000
    integer, parameter :: monitor_every_default = 100
    integer, parameter :: axis_band_cells = 2
    real, parameter :: growth_tol = 1.0e-2

    integer :: nsteps, monitor_every, n
    real :: dr, dphi, dz, c0, dt_crit, dt, t_n
    real, allocatable :: Er(:,:,:), Ephi(:,:,:), Ez(:,:,:), Hr(:,:,:), Hphi(:,:,:), Hz(:,:,:)
    real :: max_abs_e, max_abs_h, total_energy, axis_band_max, first_ring_max, i0_active_max, i1_active_max
    real :: axis_near_ez_max, axis_near_hz_max
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
    dphi = 2.0*acos(-1.0)/real(nphi)
    dz = lz/real(nz)
    c0 = 1.0/sqrt(ep*mu)
    dt_crit = 1.0/(c0*sqrt((1.0/dr)**2 + (1.0/dz)**2 + (1.0/(0.5*dr*dphi))**2))
    dt = cfl_scale*dt_crit

    allocate(Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz))
    allocate(Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz))

    call init_fields(nr,nphi,nz,dr,dphi,dz,amp0,Er,Ephi,Ez,Hr,Hphi,Hz)
    call fill_boundaries_all(nr,nphi,nz,Er,Ephi,Ez,Hr,Hphi,Hz)

    has_naninf = .false.
    energy_growth_counter = 0
    axis_growth_counter = 0

    call compute_metrics(nr,nphi,nz,dr,dphi,dz,ep,mu,axis_band_cells,Er,Ephi,Ez,Hr,Hphi,Hz, &
        max_abs_e0,max_abs_h0,energy0,axis_band_max,first_ring_max,i0_active_max,i1_active_max, &
        axis_near_ez_max,axis_near_hz_max,local_nan)
    has_naninf = has_naninf .or. local_nan

    prev_energy = energy0
    prev_axis_band = axis_band_max
    max_abs_e = max_abs_e0
    max_abs_h = max_abs_h0
    total_energy = energy0

    write(*,'(A)') '=== Stability Test: 3D cylindrical m=1 (no source, long run) ==='
    write(*,'(A,I0,A,I0,A,I0,A,F6.3,A,1PE12.4)') 'nr=',nr,', nphi=',nphi,', nz=',nz,', cfl=',cfl_scale,', dt=',dt
    write(*,'(A,I0,A,I0)') 'nsteps=',nsteps,', monitor_every=',monitor_every
    write(*,'(A)') '# step,time,max_abs_E,max_abs_H,total_energy,' // &
        'axis_band_max,first_ring_max,i0_active_max,i1_first_ring_max,' // &
        'axis_near_Ez_max,axis_near_Hz_max'
    call write_monitor_row(0,0.0,max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max, &
        i0_active_max,i1_active_max,axis_near_ez_max,axis_near_hz_max)

    t_n = 0.0
    do n = 1, nsteps
        call sub_E02_fdtd_3d_cylindrical_H(0,nr,0,nphi+1,0,nz,0,nr-1,1,nphi,0,nz-1, &
            Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,mu)
        call enforce_hr_axis(nr,nphi,nz,Hr,Hphi)
        call fill_h_boundaries(nr,nphi,nz,Hr,Hphi,Hz)

        call sub_E02_fdtd_3d_cylindrical_E(0,nr,0,nphi+1,0,nz,0,nr-1,1,nphi,1,nz-1, &
            Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,ep)
        call enforce_e_axis(nr,nphi,nz,Er,Ephi)
        call fill_e_boundaries(nr,nphi,nz,Er,Ephi,Ez)

        t_n = t_n + dt

        if (mod(n,monitor_every) == 0 .or. n == nsteps) then
            call compute_metrics(nr,nphi,nz,dr,dphi,dz,ep,mu,axis_band_cells,Er,Ephi,Ez,Hr,Hphi,Hz, &
                max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_active_max, &
                axis_near_ez_max,axis_near_hz_max,local_nan)
            has_naninf = has_naninf .or. local_nan

            call write_monitor_row(n,t_n,max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max, &
                i0_active_max,i1_active_max,axis_near_ez_max,axis_near_hz_max)

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
    write(*,'(A,1PE12.4)') 'axis_near_Ez_max_final=', axis_near_ez_max
    write(*,'(A,1PE12.4)') 'axis_near_Hz_max_final=', axis_near_hz_max
    write(*,'(A,A)') 'result=', trim(result)
    write(*,'("SUMMARY_CSV,3D_CYL_M1,",F5.3,",",I0,",",1PE12.4,",",1PE12.4,",",1PE12.4,",",A)') &
        cfl_scale, nsteps, final_energy_ratio, max_abs_e_final, max_abs_h_final, trim(result)
    call print_growth_source(nr,nphi,nz,axis_band_cells,Er,Ephi,Ez,Hr,Hphi,Hz)

    deallocate(Er,Ephi,Ez,Hr,Hphi,Hz)

contains

    subroutine write_monitor_row(step,time,maxe,maxh,energy,axismax,ringmax,i0max,i1max,ezax,hzax)
        implicit none
        integer, intent(in) :: step
        real, intent(in) :: time,maxe,maxh,energy,axismax,ringmax,i0max,i1max,ezax,hzax
        write(*,'(I0,10(",",1PE14.6))') &
            step,time,maxe,maxh,energy,axismax,ringmax,i0max,i1max,ezax,hzax
    end subroutine write_monitor_row


    subroutine init_fields(nr,nphi,nz,dr,dphi,dz,amp,Er,Ephi,Ez,Hr,Hphi,Hz)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(in) :: dr, dphi, dz, amp
        real, intent(inout) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)
        real, intent(inout) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)
        integer :: i, j, k
        real :: r1, r0, z0, zh, phi0, phih, g1, g0, kz

        kz = 2.0*acos(-1.0)/lz
        Er = 0.0
        Ephi = 0.0
        Ez = 0.0
        Hr = 0.0
        Hphi = 0.0
        Hz = 0.0

        do k = 0, nz
        do j = 0, nphi+1
        do i = 0, nr
            r1 = (real(i)+0.5)*dr
            r0 = real(i)*dr
            z0 = real(k)*dz
            zh = (real(k)+0.5)*dz
            phi0 = (real(j)-1.0)*dphi
            phih = (real(j)-0.5)*dphi

            g1 = r1*max(0.0,1.0-(r1/rmax)**2)
            g0 = r0*max(0.0,1.0-(r0/rmax)**2)

            Er(i,j,k) = amp*g1*sin(kz*z0)*cos(phi0)
            Ephi(i,j,k) = amp*g0*sin(kz*z0)*sin(phih)
            Ez(i,j,k) = amp*g0*cos(kz*zh)*cos(phi0)

            Hr(i,j,k) = amp*g0*cos(kz*zh)*cos(phih)
            Hphi(i,j,k) = -amp*g1*cos(kz*zh)*sin(phi0)
            Hz(i,j,k) = amp*g1*sin(kz*z0)*cos(phih)
        end do
        end do
        end do

        call enforce_hr_axis(nr,nphi,nz,Hr,Hphi)
        call enforce_e_axis(nr,nphi,nz,Er,Ephi)
    end subroutine init_fields


    subroutine fill_periodic_phi(nr,nphi,nz,A)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(inout) :: A(0:nr,0:nphi+1,0:nz)
        integer :: i, k
        do k = 0, nz
        do i = 0, nr
            A(i,0,k) = A(i,nphi,k)
            A(i,nphi+1,k) = A(i,1,k)
        end do
        end do
    end subroutine fill_periodic_phi


    subroutine fill_periodic_z(nr,nphi,nz,A)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(inout) :: A(0:nr,0:nphi+1,0:nz)
        integer :: i, j
        do j = 0, nphi+1
        do i = 0, nr
            A(i,j,0) = A(i,j,nz-1)
            A(i,j,nz) = A(i,j,1)
        end do
        end do
    end subroutine fill_periodic_z


    subroutine fill_outer_r_copy(nr,nphi,nz,A)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(inout) :: A(0:nr,0:nphi+1,0:nz)
        integer :: j, k
        do k = 0, nz
        do j = 0, nphi+1
            A(nr,j,k) = A(nr-1,j,k)
        end do
        end do
    end subroutine fill_outer_r_copy


    subroutine fill_outer_r_ephi_metric(nr,nphi,nz,Ephi)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(inout) :: Ephi(0:nr,0:nphi+1,0:nz)
        integer :: j, k
        real :: scale

        if (nr <= 0) return
        scale = real(nr-1)/real(nr)
        do k = 0, nz
        do j = 0, nphi+1
            Ephi(nr,j,k) = scale*Ephi(nr-1,j,k)
        end do
        end do
    end subroutine fill_outer_r_ephi_metric


    subroutine enforce_hr_axis(nr,nphi,nz,Hr,Hphi)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(inout) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz)
        integer :: j, k
        do k = 0, nz
        do j = 1, nphi
            Hr(0,j,k) = Hphi(0,j,k)
        end do
        end do
    end subroutine enforce_hr_axis


    subroutine enforce_e_axis(nr,nphi,nz,Er,Ephi)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(inout) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz)
        integer :: j, k
        do k = 0, nz
        do j = 1, nphi
            Ephi(0,j,k) = Er(0,j,k)
        end do
        end do
    end subroutine enforce_e_axis


    subroutine fill_h_boundaries(nr,nphi,nz,Hr,Hphi,Hz)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(inout) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)
        call fill_periodic_phi(nr,nphi,nz,Hr)
        call fill_periodic_phi(nr,nphi,nz,Hphi)
        call fill_periodic_phi(nr,nphi,nz,Hz)
        call fill_periodic_z(nr,nphi,nz,Hr)
        call fill_periodic_z(nr,nphi,nz,Hphi)
        call fill_periodic_z(nr,nphi,nz,Hz)
        call fill_outer_r_copy(nr,nphi,nz,Hr)
        call fill_outer_r_copy(nr,nphi,nz,Hphi)
        call fill_outer_r_copy(nr,nphi,nz,Hz)
        call enforce_hr_axis(nr,nphi,nz,Hr,Hphi)
    end subroutine fill_h_boundaries


    subroutine fill_e_boundaries(nr,nphi,nz,Er,Ephi,Ez)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(inout) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)
        call fill_periodic_phi(nr,nphi,nz,Er)
        call fill_periodic_phi(nr,nphi,nz,Ephi)
        call fill_periodic_phi(nr,nphi,nz,Ez)
        call fill_periodic_z(nr,nphi,nz,Er)
        call fill_periodic_z(nr,nphi,nz,Ephi)
        call fill_periodic_z(nr,nphi,nz,Ez)
        call fill_outer_r_copy(nr,nphi,nz,Er)
        call fill_outer_r_ephi_metric(nr,nphi,nz,Ephi)
        call fill_outer_r_copy(nr,nphi,nz,Ez)
        call enforce_e_axis(nr,nphi,nz,Er,Ephi)
    end subroutine fill_e_boundaries


    subroutine fill_boundaries_all(nr,nphi,nz,Er,Ephi,Ez,Hr,Hphi,Hz)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(inout) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)
        real, intent(inout) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)
        call fill_h_boundaries(nr,nphi,nz,Hr,Hphi,Hz)
        call fill_e_boundaries(nr,nphi,nz,Er,Ephi,Ez)
    end subroutine fill_boundaries_all


    subroutine compute_metrics(nr,nphi,nz,dr,dphi,dz,ep,mu,axis_cells,Er,Ephi,Ez,Hr,Hphi,Hz, &
        max_abs_e,max_abs_h,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_active_max, &
        axis_near_ez_max,axis_near_hz_max,has_nan)
        implicit none
        integer, intent(in) :: nr, nphi, nz, axis_cells
        real, intent(in) :: dr, dphi, dz, ep, mu
        real, intent(in) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)
        real, intent(in) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)
        real, intent(out) :: max_abs_e, max_abs_h, total_energy, axis_band_max, first_ring_max
        real, intent(out) :: i0_active_max, i1_active_max, axis_near_ez_max, axis_near_hz_max
        logical, intent(out) :: has_nan

        integer :: i, j, k
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
        axis_near_hz_max = 0.0

        do k = 1, nz-1
        do j = 1, nphi
        do i = 0, nr-1
            v = Er(i,j,k)
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
                w = r*dr*dphi*dz
                total_energy = total_energy + ep*av*av*w
            end if

            v = Ez(i,j,k)
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
                w = r*dr*dphi*dz
                total_energy = total_energy + ep*av*av*w
            end if
        end do
        end do
        end do

        do k = 1, nz-1
        do j = 1, nphi
        do i = 1, nr-1
            v = Ephi(i,j,k)
            if (.not. ieee_is_finite(v)) then
                has_nan = .true.
            else
                av = abs(v)
                max_abs_e = max(max_abs_e,av)
                if (i <= axis_cells) axis_band_max = max(axis_band_max,av)
                if (i == 1) first_ring_max = max(first_ring_max,av)
                if (i == 1) i1_active_max = max(i1_active_max,av)
                r = real(i)*dr
                w = r*dr*dphi*dz
                total_energy = total_energy + ep*av*av*w
            end if
        end do
        end do
        end do

        do k = 0, nz-1
        do j = 1, nphi
        do i = 1, nr-1
            v = Hr(i,j,k)
            if (.not. ieee_is_finite(v)) then
                has_nan = .true.
            else
                av = abs(v)
                max_abs_h = max(max_abs_h,av)
                if (i <= axis_cells) axis_band_max = max(axis_band_max,av)
                if (i == 1) first_ring_max = max(first_ring_max,av)
                if (i == 1) i1_active_max = max(i1_active_max,av)
                r = real(i)*dr
                w = r*dr*dphi*dz
                total_energy = total_energy + mu*av*av*w
            end if
        end do
        end do
        end do

        do k = 0, nz-1
        do j = 1, nphi
        do i = 0, nr-1
            v = Hphi(i,j,k)
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
                w = r*dr*dphi*dz
                total_energy = total_energy + mu*av*av*w
            end if

            v = Hz(i,j,k)
            if (.not. ieee_is_finite(v)) then
                has_nan = .true.
            else
                av = abs(v)
                max_abs_h = max(max_abs_h,av)
                if (i <= axis_cells) axis_band_max = max(axis_band_max,av)
                if (i == 1) first_ring_max = max(first_ring_max,av)
                if (i == 0) i0_active_max = max(i0_active_max,av)
                if (i == 1) i1_active_max = max(i1_active_max,av)
                if (i <= 1) axis_near_hz_max = max(axis_near_hz_max,av)
                r = (real(i)+0.5)*dr
                w = r*dr*dphi*dz
                total_energy = total_energy + mu*av*av*w
            end if
        end do
        end do
        end do
    end subroutine compute_metrics


    subroutine print_growth_source(nr,nphi,nz,axis_cells,Er,Ephi,Ez,Hr,Hphi,Hz)
        implicit none
        integer, intent(in) :: nr, nphi, nz, axis_cells
        real, intent(in) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)
        real, intent(in) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)

        integer, parameter :: ncomp_all = 6, nreg = 4
        character(len=8), parameter :: comp_names(ncomp_all) = [character(len=8) :: 'Er','Ephi','Ez','Hr','Hphi','Hz']
        character(len=16), parameter :: reg_names(nreg) = [character(len=16) :: 'interior','axis_band','first_ring','boundary_band']
        real :: comp_max(ncomp_all), reg_max(nreg)
        integer :: comp_i(ncomp_all), comp_j(ncomp_all), comp_k(ncomp_all)
        integer :: reg_comp(nreg), reg_i(nreg), reg_j(nreg), reg_k(nreg)
        integer :: i, j, k, reg, ic
        real :: av, max_h_comp
        integer :: max_h_comp_id

        comp_max = -1.0
        reg_max = -1.0
        comp_i = -1; comp_j = -1; comp_k = -1
        reg_comp = -1; reg_i = -1; reg_j = -1; reg_k = -1

        do k = 1, nz-1
        do j = 1, nphi
        do i = 0, nr-1
            call update_comp_and_regions(1,Er(i,j,k),i,j,k,nr,axis_cells,comp_max,comp_i,comp_j,comp_k, &
                reg_max,reg_comp,reg_i,reg_j,reg_k)
            call update_comp_and_regions(3,Ez(i,j,k),i,j,k,nr,axis_cells,comp_max,comp_i,comp_j,comp_k, &
                reg_max,reg_comp,reg_i,reg_j,reg_k)
        end do
        end do
        end do

        do k = 1, nz-1
        do j = 1, nphi
        do i = 1, nr-1
            call update_comp_and_regions(2,Ephi(i,j,k),i,j,k,nr,axis_cells,comp_max,comp_i,comp_j,comp_k, &
                reg_max,reg_comp,reg_i,reg_j,reg_k)
        end do
        end do
        end do

        do k = 0, nz-1
        do j = 1, nphi
        do i = 1, nr-1
            call update_comp_and_regions(4,Hr(i,j,k),i,j,k,nr,axis_cells,comp_max,comp_i,comp_j,comp_k, &
                reg_max,reg_comp,reg_i,reg_j,reg_k)
        end do
        end do
        end do

        do k = 0, nz-1
        do j = 1, nphi
        do i = 0, nr-1
            call update_comp_and_regions(5,Hphi(i,j,k),i,j,k,nr,axis_cells,comp_max,comp_i,comp_j,comp_k, &
                reg_max,reg_comp,reg_i,reg_j,reg_k)
            call update_comp_and_regions(6,Hz(i,j,k),i,j,k,nr,axis_cells,comp_max,comp_i,comp_j,comp_k, &
                reg_max,reg_comp,reg_i,reg_j,reg_k)
        end do
        end do
        end do

        write(*,'(A)') '--- Growth Source Diagnostics (final field) ---'
        write(*,'(A)') '  component maxima:'
        do ic = 1, ncomp_all
            write(*,'(A,A,A,1PE12.4,A,3(I0,1X))') '    ',trim(comp_names(ic)), ' max=', comp_max(ic), &
                ' idx(i,j,k)=', comp_i(ic), comp_j(ic), comp_k(ic)
        end do

        write(*,'(A)') '  region maxima (combined):'
        do reg = 1, nreg
            if (reg_comp(reg) > 0) then
                write(*,'(A,A,A,A,A,1PE12.4,A,3(I0,1X))') '    ',trim(reg_names(reg)), ' comp=', &
                    trim(comp_names(reg_comp(reg))), ' max=', reg_max(reg), ' idx(i,j,k)=', &
                    reg_i(reg), reg_j(reg), reg_k(reg)
            end if
        end do

        max_h_comp = -1.0
        max_h_comp_id = -1
        do ic = 4, 6
            if (comp_max(ic) > max_h_comp) then
                max_h_comp = comp_max(ic)
                max_h_comp_id = ic
            end if
        end do
        if (max_h_comp_id > 0) then
            write(*,'(A,A,A,1PE12.4,A,3(I0,1X))') '  dominant H component: ', trim(comp_names(max_h_comp_id)), &
                ' max=', max_h_comp, ' idx(i,j,k)=', comp_i(max_h_comp_id), comp_j(max_h_comp_id), comp_k(max_h_comp_id)
        end if
    end subroutine print_growth_source


    subroutine update_comp_and_regions(ic,v,i,j,k,nr,axis_cells,comp_max,comp_i,comp_j,comp_k, &
        reg_max,reg_comp,reg_i,reg_j,reg_k)
        implicit none
        integer, intent(in) :: ic, i, j, k, nr, axis_cells
        real, intent(in) :: v
        real, intent(inout) :: comp_max(:), reg_max(:)
        integer, intent(inout) :: comp_i(:), comp_j(:), comp_k(:)
        integer, intent(inout) :: reg_comp(:), reg_i(:), reg_j(:), reg_k(:)
        real :: av

        if (.not. ieee_is_finite(v)) return
        av = abs(v)

        if (av > comp_max(ic)) then
            comp_max(ic) = av
            comp_i(ic) = i
            comp_j(ic) = j
            comp_k(ic) = k
        end if

        if (i <= axis_cells) then
            call update_region_slot(2,ic,av,i,j,k,reg_max,reg_comp,reg_i,reg_j,reg_k)
        end if
        if (i == 1) then
            call update_region_slot(3,ic,av,i,j,k,reg_max,reg_comp,reg_i,reg_j,reg_k)
        end if
        if (i >= nr-2) then
            call update_region_slot(4,ic,av,i,j,k,reg_max,reg_comp,reg_i,reg_j,reg_k)
        end if
        if (i >= axis_cells+1 .and. i <= nr-3) then
            call update_region_slot(1,ic,av,i,j,k,reg_max,reg_comp,reg_i,reg_j,reg_k)
        end if
    end subroutine update_comp_and_regions


    subroutine update_region_slot(regid,ic,av,i,j,k,reg_max,reg_comp,reg_i,reg_j,reg_k)
        implicit none
        integer, intent(in) :: regid, ic, i, j, k
        real, intent(in) :: av
        real, intent(inout) :: reg_max(:)
        integer, intent(inout) :: reg_comp(:), reg_i(:), reg_j(:), reg_k(:)
        if (av > reg_max(regid)) then
            reg_max(regid) = av
            reg_comp(regid) = ic
            reg_i(regid) = i
            reg_j(regid) = j
            reg_k(regid) = k
        end if
    end subroutine update_region_slot

end program test_stability_3d_cyl_m1
