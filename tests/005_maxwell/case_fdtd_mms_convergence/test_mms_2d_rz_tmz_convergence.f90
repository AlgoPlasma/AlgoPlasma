program test_mms_2d_rz_tmz_convergence

    use, intrinsic :: iso_fortran_env, only: output_unit
    use mod_E01_fdtd_2d_rz_tmz
    use mms_exact_sources
    use mms_convergence_utils
    implicit none

    integer, parameter :: nlev = 3, ncomp = 3, nregion = 4
    integer, parameter :: nr_list(nlev) = (/20, 40, 80/)
    integer, parameter :: nz_list(nlev) = (/32, 64, 128/)
    character(len=8), parameter :: comp_names(ncomp) = [character(len=8) :: 'Er', 'Ez', 'Hphi']
    character(len=16), parameter :: region_names(nregion) = [character(len=16) :: &
        'interior', 'axis_band', 'first_ring', 'boundary_band']

    real, parameter :: ep = 1.0
    real, parameter :: mu = 1.0
    real, parameter :: rmax = 1.0, lz = 1.0
    real, parameter :: cfl = 0.20
    integer, parameter :: nstep_base = 1000
    real, parameter :: axis_band_factor = 2.0
    real, parameter :: l2_order_min = 1.8
    real, parameter :: linf_order_min = 1.5

    integer :: ilev, ic
    integer :: nsteps(nlev)
    real :: dt_levels(nlev), tfinal
    real :: l2_comp(ncomp,nlev), linf_comp(ncomp,nlev), axis_linf_comp(ncomp,nlev)
    real :: l2_comb(nlev), linf_comb(nlev), axis_linf_comb(nlev)
    real :: l2_comb_e(nlev), l2_comb_h(nlev), linf_comb_e(nlev), linf_comb_h(nlev)
    real :: region_linf(nregion,nlev)
    real :: p_l2_12, p_l2_23, p_linf_12, p_linf_23
    real :: p_l2e_12, p_l2e_23, p_linfe_12, p_linfe_23
    real :: p_l2h_12, p_l2h_23, p_linfh_12, p_linfh_23
    real :: p_region_12(nregion), p_region_23(nregion)
    real :: p_comp_l2_12(ncomp), p_comp_l2_23(ncomp), p_comp_linf_12(ncomp), p_comp_linf_23(ncomp)
    real :: c0, omega
    logical :: pass_ok

    c0 = 1.0/sqrt(ep*mu)
    omega = 0.6*c0*(acos(-1.0)/lz)

    do ilev = 1, nlev
        dt_levels(ilev) = compute_dt(nr_list(ilev),nz_list(ilev),c0)
    end do
    tfinal = real(nstep_base)*dt_levels(1)

    do ilev = 1, nlev
        nsteps(ilev) = nint(tfinal/dt_levels(ilev))
    end do

    write(*,'(A)') '=== MMS Convergence: 2D RZ TMz ==='
    write(*,'(A,1PE12.4)') 'target T = ', tfinal

    do ilev = 1, nlev
        call run_level(nr_list(ilev),nz_list(ilev),dt_levels(ilev),nsteps(ilev),omega, &
            l2_comp(:,ilev),linf_comp(:,ilev),axis_linf_comp(:,ilev), &
            l2_comb(ilev),linf_comb(ilev),axis_linf_comb(ilev), &
            l2_comb_e(ilev),l2_comb_h(ilev),linf_comb_e(ilev),linf_comb_h(ilev),region_linf(:,ilev))
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
    do ic = 1, nregion
        p_region_12(ic) = observed_order(region_linf(ic,1),region_linf(ic,2))
        p_region_23(ic) = observed_order(region_linf(ic,2),region_linf(ic,3))
    end do

    write(*,'(A)') '--- Component-wise errors ---'
    do ic = 1, ncomp
        write(*,'(A,A,A,3(1PE11.3,1X),A,0P,2(F6.3,1X),A,2(F6.3,1X))') &
            '  ',trim(comp_names(ic)), ' L2=',l2_comp(ic,1),l2_comp(ic,2),l2_comp(ic,3), &
            ' p(L2)=',p_comp_l2_12(ic),p_comp_l2_23(ic), &
            ' p(Linf)=',p_comp_linf_12(ic),p_comp_linf_23(ic)
        write(*,'(A,3(1PE11.3,1X),A,3(1PE11.3,1X))') '      Linf=', &
            linf_comp(ic,1),linf_comp(ic,2),linf_comp(ic,3), ' axis_band_Linf=', &
            axis_linf_comp(ic,1),axis_linf_comp(ic,2),axis_linf_comp(ic,3)
    end do

    write(*,'(A)') '--- Combined errors ---'
    write(*,'(A,3(1PE11.3,1X))') '  L2  : ', l2_comb(1), l2_comb(2), l2_comb(3)
    write(*,'(A,3(1PE11.3,1X))') '  Linf: ', linf_comb(1), linf_comb(2), linf_comb(3)
    write(*,'(A,3(1PE11.3,1X))') '  axis_band_Linf: ', axis_linf_comb(1), axis_linf_comb(2), axis_linf_comb(3)
    write(*,'(A,3(1PE11.3,1X),A,0P,2(F6.3,1X),A,2(F6.3,1X))') '  combined_E L2=', &
        l2_comb_e(1),l2_comb_e(2),l2_comb_e(3), ' p=',p_l2e_12,p_l2e_23, ' Linf p=',p_linfe_12,p_linfe_23
    write(*,'(A,3(1PE11.3,1X),A,0P,2(F6.3,1X),A,2(F6.3,1X))') '  combined_H L2=', &
        l2_comb_h(1),l2_comb_h(2),l2_comb_h(3), ' p=',p_l2h_12,p_l2h_23, ' Linf p=',p_linfh_12,p_linfh_23
    write(*,'(A,3(1PE11.3,1X))') '  combined_E Linf: ', linf_comb_e(1),linf_comb_e(2),linf_comb_e(3)
    write(*,'(A,3(1PE11.3,1X))') '  combined_H Linf: ', linf_comb_h(1),linf_comb_h(2),linf_comb_h(3)
    write(*,'(A)') '  region Linf and order:'
    do ic = 1, nregion
        write(*,'(A,A,A,3(1PE11.3,1X),A,0P,2(F6.3,1X))') '    ',trim(region_names(ic)), ': ', &
            region_linf(ic,1),region_linf(ic,2),region_linf(ic,3), ' p=',p_region_12(ic),p_region_23(ic)
    end do
    write(*,'(A,0P,2(F6.3,1X))') '  Observed order L2  (h->h/2): ', p_l2_12, p_l2_23
    write(*,'(A,0P,2(F6.3,1X))') '  Observed order Linf(h->h/2): ', p_linf_12, p_linf_23

    pass_ok = min(p_l2_12,p_l2_23) >= l2_order_min .and. min(p_linf_12,p_linf_23) >= linf_order_min
    if (pass_ok) then
        write(*,'(A)') 'RESULT: PASS'
    else
        write(*,'(A)') 'RESULT: FAIL'

    end if

contains

    real function compute_dt(nr,nz,c0)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(in) :: c0
        real :: dr, dz
        dr = rmax/real(nr)
        dz = lz/real(nz)
        compute_dt = cfl/(c0*sqrt((1.0/dr)**2 + (1.0/dz)**2))
    end function compute_dt


    subroutine run_level(nr,nz,dt,nsteps,omega0,l2_out,linf_out,axis_linf_out,l2_comb_out,linf_comb_out,axis_linf_comb_out, &
        l2_comb_e_out,l2_comb_h_out,linf_comb_e_out,linf_comb_h_out,region_linf_out)
        implicit none
        integer, intent(in) :: nr, nz, nsteps
        real, intent(in) :: dt, omega0
        real, intent(out) :: l2_out(ncomp), linf_out(ncomp), axis_linf_out(ncomp)
        real, intent(out) :: l2_comb_out, linf_comb_out, axis_linf_comb_out
        real, intent(out) :: l2_comb_e_out, l2_comb_h_out, linf_comb_e_out, linf_comb_h_out
        real, intent(out) :: region_linf_out(nregion)
        real, allocatable :: Er(:,:), Ez(:,:), Ha(:,:)
        integer :: n, progress_stride
        real :: t_n, dr, dz, rw, zw
        integer :: wi(ncomp), wk(ncomp), rcomp(nregion), ri(nregion), rk(nregion)
        real :: werr(ncomp)
        integer :: viz_unit, viz_stride
        logical :: viz_on, viz_open

        dr = rmax/real(nr)
        dz = lz/real(nz)
        viz_on = (nr == nr_list(nlev) .and. nz == nz_list(nlev))

        allocate(Er(0:nr,0:nz), Ez(0:nr,0:nz), Ha(0:nr,0:nz))
        call init_fields(nr,nz,dr,dz,dt,omega0,Er,Ez,Ha)

        viz_open = .false.
        if (viz_on) then
            viz_stride = max(1,nsteps/90)
            open(newunit=viz_unit,file='mms_rz_tmz_viz_fine.bin',form='unformatted',access='stream',status='replace')
            write(viz_unit) nr
            write(viz_unit) nz
            write(viz_unit) viz_stride
            call write_viz_frame(viz_unit,nr,nz,dr,dz,0,0.0,omega0,Ez)
            viz_open = .true.
        end if

        progress_stride = max(1, min(100, nsteps))
        write(*,'(A,I0,A,I0,A,I0)') &
            '  running level nr=',nr,', nz=',nz,', nsteps=',nsteps
        flush(output_unit)

        t_n = 0.0
        do n = 1, nsteps
            call sub_E01_fdtd_2d_rz_tmz_H(0,nr,0,nz,0,nr-1,0,nz-1,Ha,Er,Ez,dt,dr,dz,mu)
            call add_h_source(nr,nz,dr,dz,dt,t_n,omega0,Ha)
            call enforce_h_ghosts(nr,nz,dr,dz,t_n+0.5*dt,omega0,Ha)

            call sub_E01_fdtd_2d_rz_tmz_E(0,nr,0,nz,0,nr-1,1,nz-1,Ha,Er,Ez,dt,dr,dz,ep)
            call add_e_source(nr,nz,dr,dz,dt,t_n+0.5*dt,omega0,Er,Ez)
            call enforce_e_ghosts(nr,nz,dr,dz,t_n+dt,omega0,Er,Ez)
            t_n = t_n + dt

            if (viz_on .and. (mod(n,viz_stride) == 0 .or. n == nsteps)) then
                call write_viz_frame(viz_unit,nr,nz,dr,dz,n,t_n,omega0,Ez)
            end if
            if (mod(n, progress_stride) == 0 .or. n == nsteps) then
                write(*,'(A,I0,A,I0,A)') '    progress ',n,'/',nsteps,' steps'
                flush(output_unit)
            end if
        end do

        call compute_errors(nr,nz,dr,dz,t_n,t_n-0.5*dt,omega0,Er,Ez,Ha, &
            l2_out,linf_out,axis_linf_out,l2_comb_out,linf_comb_out,axis_linf_comb_out, &
            l2_comb_e_out,l2_comb_h_out,linf_comb_e_out,linf_comb_h_out,region_linf_out, &
            wi,wk,werr,rcomp,ri,rk)

        write(*,'(A,I0,A,I0,A,1PE11.3,A,I0)') '  level nr=',nr,', nz=',nz,', dt=',dt,', nsteps=',nsteps
        write(*,'(A)') '    worst points by component:'
        do n = 1, ncomp
            call component_rz(n,wi(n),wk(n),dr,dz,rw,zw)
            write(*,'(A,A,A,2(I0,1X),A,2(1PE11.3,1X),A,1PE11.3)') '      ',trim(comp_names(n)), &
                ' idx=',wi(n),wk(n), ' rz=',rw,zw, ' err=',werr(n)
        end do
        write(*,'(A)') '    worst by region (combined):'
        do n = 1, nregion
            write(*,'(A,A,A,A,A,2(I0,1X),A,1PE11.3)') '      ',trim(region_names(n)), ' comp=', &
                trim(comp_names(rcomp(n))), ' idx=',ri(n),rk(n), ' err=',region_linf_out(n)
        end do
        if (viz_open) close(viz_unit)
        deallocate(Er,Ez,Ha)
    end subroutine run_level


    subroutine component_rz(ic,i,k,dr,dz,r,z)
        implicit none
        integer, intent(in) :: ic, i, k
        real, intent(in) :: dr, dz
        real, intent(out) :: r, z

        select case (ic)
        case (1) ! Er(r+1/2, z)
            r = (real(i)+0.5)*dr
            z = real(k)*dz
        case (2) ! Ez(r, z+1/2)
            r = real(i)*dr
            z = (real(k)+0.5)*dz
        case (3) ! Hphi(r+1/2, z+1/2)
            r = (real(i)+0.5)*dr
            z = (real(k)+0.5)*dz
        end select
    end subroutine component_rz


    subroutine write_viz_frame(unit,nr,nz,dr,dz,step,t_e,omega0,Ez)
        implicit none
        integer, intent(in) :: unit, nr, nz, step
        real, intent(in) :: dr, dz, t_e, omega0
        real, intent(in) :: Ez(0:nr,0:nz)
        integer :: i, k
        real :: r, z
        real :: er0, ez0, h0, ser, sez, sh
        real :: Ez_exact(0:nr,0:nz)

        do k = 0, nz
        do i = 0, nr
            r = real(i)*dr
            z = (real(k)+0.5)*dz
            call rz_tmz_exact_and_sources(r,z,t_e,ep,mu,rmax,lz,omega0,er0,ez0,h0,ser,sez,sh)
            Ez_exact(i,k) = ez0
        end do
        end do

        write(unit) step
        write(unit) t_e
        write(unit) Ez
        write(unit) Ez_exact
    end subroutine write_viz_frame


    subroutine init_fields(nr,nz,dr,dz,dt,omega0,Er,Ez,Ha)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(in) :: dr, dz, dt, omega0
        real, intent(inout) :: Er(0:nr,0:nz), Ez(0:nr,0:nz), Ha(0:nr,0:nz)
        integer :: i, k
        real :: r, z
        real :: er0, ez0, h0, ser, sez, sh

        Er = 0.0; Ez = 0.0; Ha = 0.0

        do k = 0, nz
        do i = 0, nr
            r = (real(i)+0.5)*dr
            z = real(k)*dz
            call rz_tmz_exact_and_sources(r,z,0.0,ep,mu,rmax,lz,omega0,er0,ez0,h0,ser,sez,sh)
            Er(i,k) = er0

            r = real(i)*dr
            z = (real(k)+0.5)*dz
            call rz_tmz_exact_and_sources(r,z,0.0,ep,mu,rmax,lz,omega0,er0,ez0,h0,ser,sez,sh)
            Ez(i,k) = ez0

            r = (real(i)+0.5)*dr
            z = (real(k)+0.5)*dz
            call rz_tmz_exact_and_sources(r,z,-0.5*dt,ep,mu,rmax,lz,omega0,er0,ez0,h0,ser,sez,sh)
            Ha(i,k) = h0
        end do
        end do
    end subroutine init_fields


    subroutine add_h_source(nr,nz,dr,dz,dt,t_src,omega0,Ha)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(in) :: dr, dz, dt, t_src, omega0
        real, intent(inout) :: Ha(0:nr,0:nz)
        integer :: i, k
        real :: r, z, er0, ez0, h0, ser, sez, sh

        do k = 0, nz-1
        do i = 0, nr-1
            r = (real(i)+0.5)*dr
            z = (real(k)+0.5)*dz
            call rz_tmz_exact_and_sources(r,z,t_src,ep,mu,rmax,lz,omega0,er0,ez0,h0,ser,sez,sh)
            Ha(i,k) = Ha(i,k) + dt*sh
        end do
        end do
    end subroutine add_h_source


    subroutine add_e_source(nr,nz,dr,dz,dt,t_src,omega0,Er,Ez)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(in) :: dr, dz, dt, t_src, omega0
        real, intent(inout) :: Er(0:nr,0:nz), Ez(0:nr,0:nz)
        integer :: i, k
        real :: r, z, er0, ez0, h0, ser, sez, sh

        do k = 1, nz-1
        do i = 0, nr-1
            r = (real(i)+0.5)*dr
            z = real(k)*dz
            call rz_tmz_exact_and_sources(r,z,t_src,ep,mu,rmax,lz,omega0,er0,ez0,h0,ser,sez,sh)
            Er(i,k) = Er(i,k) + dt*ser

            r = real(i)*dr
            z = (real(k)+0.5)*dz
            call rz_tmz_exact_and_sources(r,z,t_src,ep,mu,rmax,lz,omega0,er0,ez0,h0,ser,sez,sh)
            Ez(i,k) = Ez(i,k) + dt*sez
        end do
        end do
    end subroutine add_e_source


    subroutine enforce_h_ghosts(nr,nz,dr,dz,t_h,omega0,Ha)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(in) :: dr, dz, t_h, omega0
        real, intent(inout) :: Ha(0:nr,0:nz)
        integer :: i, k
        real :: r, z, er0, ez0, h0, ser, sez, sh

        do k = 0, nz
            r = (real(nr)+0.5)*dr
            z = (real(k)+0.5)*dz
            call rz_tmz_exact_and_sources(r,z,t_h,ep,mu,rmax,lz,omega0,er0,ez0,h0,ser,sez,sh)
            Ha(nr,k) = h0
        end do

        do i = 0, nr
            r = (real(i)+0.5)*dr
            z = (real(nz)+0.5)*dz
            call rz_tmz_exact_and_sources(r,z,t_h,ep,mu,rmax,lz,omega0,er0,ez0,h0,ser,sez,sh)
            Ha(i,nz) = h0
        end do
    end subroutine enforce_h_ghosts


    subroutine enforce_e_ghosts(nr,nz,dr,dz,t_e,omega0,Er,Ez)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(in) :: dr, dz, t_e, omega0
        real, intent(inout) :: Er(0:nr,0:nz), Ez(0:nr,0:nz)
        integer :: i, k
        real :: r, z, er0, ez0, h0, ser, sez, sh

        do i = 0, nr
            r = (real(i)+0.5)*dr
            z = 0.0
            call rz_tmz_exact_and_sources(r,z,t_e,ep,mu,rmax,lz,omega0,er0,ez0,h0,ser,sez,sh)
            Er(i,0) = er0
            z = lz
            call rz_tmz_exact_and_sources(r,z,t_e,ep,mu,rmax,lz,omega0,er0,ez0,h0,ser,sez,sh)
            Er(i,nz) = er0
        end do

        do k = 0, nz
            r = (real(nr)+0.5)*dr
            z = real(k)*dz
            call rz_tmz_exact_and_sources(r,z,t_e,ep,mu,rmax,lz,omega0,er0,ez0,h0,ser,sez,sh)
            Er(nr,k) = er0
        end do

        do k = 0, nz
            r = real(nr)*dr
            z = (real(k)+0.5)*dz
            call rz_tmz_exact_and_sources(r,z,t_e,ep,mu,rmax,lz,omega0,er0,ez0,h0,ser,sez,sh)
            Ez(nr,k) = ez0
        end do

        do i = 0, nr
            r = real(i)*dr
            z = (real(nz)+0.5)*dz
            call rz_tmz_exact_and_sources(r,z,t_e,ep,mu,rmax,lz,omega0,er0,ez0,h0,ser,sez,sh)
            Ez(i,nz) = ez0
        end do
    end subroutine enforce_e_ghosts


    subroutine compute_errors(nr,nz,dr,dz,t_e,t_h,omega0,Er,Ez,Ha,l2c,linfc,axis_linfc,l2all,linfall,axis_linfall, &
        l2e,l2h,linfe,linfh,region_linf,wi,wk,werr,rcomp,ri,rk)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(in) :: dr, dz, t_e, t_h, omega0
        real, intent(in) :: Er(0:nr,0:nz), Ez(0:nr,0:nz), Ha(0:nr,0:nz)
        real, intent(out) :: l2c(ncomp), linfc(ncomp), axis_linfc(ncomp), l2all, linfall, axis_linfall
        real, intent(out) :: l2e, l2h, linfe, linfh
        real, intent(out) :: region_linf(nregion)
        integer, intent(out) :: wi(ncomp), wk(ncomp), rcomp(nregion), ri(nregion), rk(nregion)
        real, intent(out) :: werr(ncomp)

        integer :: i, k, reg
        real :: r, z, w, err, axis_r
        real :: er0, ez0, h0, ser, sez, sh
        real :: sumsq(ncomp), sumw(ncomp), sumsq_all, sumw_all

        axis_r = axis_band_factor*dr
        sumsq = 0.0
        sumw = 0.0
        linfc = 0.0
        axis_linfc = 0.0
        region_linf = 0.0
        rcomp = 1; ri = 0; rk = 0
        wi = 0; wk = 0; werr = -1.0

        do k = 1, nz-1
        do i = 0, nr-1
            r = (real(i)+0.5)*dr
            z = real(k)*dz
            call rz_tmz_exact_and_sources(r,z,t_e,ep,mu,rmax,lz,omega0,er0,ez0,h0,ser,sez,sh)
            err = abs(Er(i,k)-er0)
            w = r*dr*dz
            sumsq(1) = sumsq(1) + err*err*w
            sumw(1) = sumw(1) + w
            linfc(1) = max(linfc(1), err)
            if (r <= axis_r) axis_linfc(1) = max(axis_linfc(1), err)
            if (err > werr(1)) then
                werr(1) = err; wi(1) = i; wk(1) = k
            end if
            reg = region_of_point(r,dr,dz,i,k,nr,nz)
            if (err > region_linf(reg)) then
                region_linf(reg) = err; rcomp(reg) = 1; ri(reg) = i; rk(reg) = k
            end if
        end do
        end do

        do k = 1, nz-1
        do i = 0, nr-1
            r = real(i)*dr
            z = (real(k)+0.5)*dz
            call rz_tmz_exact_and_sources(r,z,t_e,ep,mu,rmax,lz,omega0,er0,ez0,h0,ser,sez,sh)
            err = abs(Ez(i,k)-ez0)
            w = r*dr*dz
            sumsq(2) = sumsq(2) + err*err*w
            sumw(2) = sumw(2) + w
            linfc(2) = max(linfc(2), err)
            if (r <= axis_r) axis_linfc(2) = max(axis_linfc(2), err)
            if (err > werr(2)) then
                werr(2) = err; wi(2) = i; wk(2) = k
            end if
            reg = region_of_point(r,dr,dz,i,k,nr,nz)
            if (err > region_linf(reg)) then
                region_linf(reg) = err; rcomp(reg) = 2; ri(reg) = i; rk(reg) = k
            end if
        end do
        end do

        do k = 0, nz-1
        do i = 0, nr-1
            r = (real(i)+0.5)*dr
            z = (real(k)+0.5)*dz
            call rz_tmz_exact_and_sources(r,z,t_h,ep,mu,rmax,lz,omega0,er0,ez0,h0,ser,sez,sh)
            err = abs(Ha(i,k)-h0)
            w = r*dr*dz
            sumsq(3) = sumsq(3) + err*err*w
            sumw(3) = sumw(3) + w
            linfc(3) = max(linfc(3), err)
            if (r <= axis_r) axis_linfc(3) = max(axis_linfc(3), err)
            if (err > werr(3)) then
                werr(3) = err; wi(3) = i; wk(3) = k
            end if
            reg = region_of_point(r,dr,dz,i,k,nr,nz)
            if (err > region_linf(reg)) then
                region_linf(reg) = err; rcomp(reg) = 3; ri(reg) = i; rk(reg) = k
            end if
        end do
        end do

        do i = 1, ncomp
            if (sumw(i) > 0.0) then
                l2c(i) = sqrt(sumsq(i)/sumw(i))
            else
                l2c(i) = 0.0
            end if
        end do

        sumsq_all = sum(sumsq)
        sumw_all = sum(sumw)
        if (sumw_all > 0.0) then
            l2all = sqrt(sumsq_all/sumw_all)
        else
            l2all = 0.0
        end if
        linfall = maxval(linfc)
        axis_linfall = maxval(axis_linfc)
        l2e = sqrt((sumsq(1)+sumsq(2))/max(sumw(1)+sumw(2),1.0e-30))
        l2h = sqrt(sumsq(3)/max(sumw(3),1.0e-30))
        linfe = max(linfc(1),linfc(2))
        linfh = linfc(3)
    end subroutine compute_errors


    integer function region_of_point(r,dr,dz,i,k,nr,nz)
        implicit none
        real, intent(in) :: r, dr, dz
        integer, intent(in) :: i, k, nr, nz

        if (r >= rmax-1.5*dr .or. k <= 1 .or. k >= nz-1) then
            region_of_point = 4
        else if (r <= axis_band_factor*dr) then
            region_of_point = 2
        else if (r <= (axis_band_factor+1.0)*dr) then
            region_of_point = 3
        else
            region_of_point = 1
        end if
    end function region_of_point

end program test_mms_2d_rz_tmz_convergence
