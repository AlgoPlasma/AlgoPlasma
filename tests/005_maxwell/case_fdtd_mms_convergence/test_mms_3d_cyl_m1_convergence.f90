program test_mms_3d_cyl_m1_convergence

    use, intrinsic :: iso_fortran_env, only: output_unit
    use mod_E02_fdtd_3d_cylindrical
    use mms_exact_sources
    use mms_convergence_utils
    implicit none

    integer, parameter :: nlev = 3, ncomp = 6, nregion = 4
    integer, parameter :: nr_list(nlev) = (/20, 40, 80/)
  integer, parameter :: nphi_list(nlev) = (/16, 32, 64/)
    integer, parameter :: nz_list(nlev) = (/32, 64, 128/)
    character(len=8), parameter :: comp_names(ncomp) = [character(len=8) :: 'Er', 'Ephi', 'Ez', 'Hr', 'Hphi', 'Hz']
    character(len=16), parameter :: region_names(nregion) = [character(len=16) :: &
        'interior', 'axis_band', 'first_ring', 'boundary_band']

    real, parameter :: ep = 1.0
    real, parameter :: mu = 1.0
    real, parameter :: rmax = 1.0, lz = 1.0
    real, parameter :: cfl = 0.15
    integer, parameter :: nstep_base = 60
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
        dt_levels(ilev) = compute_dt(nr_list(ilev),nphi_list(ilev),nz_list(ilev),c0)
    end do
    tfinal = real(nstep_base)*dt_levels(1)

    do ilev = 1, nlev
        nsteps(ilev) = nint(tfinal/dt_levels(ilev))
    end do

    write(*,'(A)') '=== MMS Convergence: 3D cylindrical m=1 ==='
    write(*,'(A,1PE12.4)') 'target T = ', tfinal

    do ilev = 1, nlev
        call run_level(nr_list(ilev),nphi_list(ilev),nz_list(ilev),dt_levels(ilev),nsteps(ilev),omega, &
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

    real function compute_dt(nr,nphi,nz,c0)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(in) :: c0
        real :: dr, dz, dphi, rmin
        dr = rmax/real(nr)
        dz = lz/real(nz)
        dphi = 2.0*acos(-1.0)/real(nphi)
        rmin = 0.5*dr
        compute_dt = cfl/(c0*sqrt((1.0/dr)**2 + (1.0/dz)**2 + (1.0/(rmin*dphi))**2))
    end function compute_dt


    subroutine run_level(nr,nphi,nz,dt,nsteps,omega0,l2_out,linf_out,axis_linf_out,l2_comb_out,linf_comb_out,axis_linf_comb_out, &
        l2_comb_e_out,l2_comb_h_out,linf_comb_e_out,linf_comb_h_out,region_linf_out)
        implicit none
        integer, intent(in) :: nr, nphi, nz, nsteps
        real, intent(in) :: dt, omega0
        real, intent(out) :: l2_out(ncomp), linf_out(ncomp), axis_linf_out(ncomp)
        real, intent(out) :: l2_comb_out, linf_comb_out, axis_linf_comb_out
        real, intent(out) :: l2_comb_e_out, l2_comb_h_out, linf_comb_e_out, linf_comb_h_out
        real, intent(out) :: region_linf_out(nregion)

        real, allocatable :: Er(:,:,:), Ephi(:,:,:), Ez(:,:,:), Hr(:,:,:), Hphi(:,:,:), Hz(:,:,:)
        integer :: n, progress_stride
        real :: t_n, dr, dz, dphi, rw, phiw, zw
        integer :: wi(ncomp), wj(ncomp), wk(ncomp), rcomp(nregion), ri(nregion), rj(nregion), rk(nregion)
        real :: werr(ncomp)
        real, allocatable :: axis_ez_series(:), axis_ez_value(:)
        integer, allocatable :: axis_ez_j(:), axis_ez_k(:)
        integer :: viz_unit, viz_stride
        logical :: viz_on, viz_open

        dr = rmax/real(nr)
        dz = lz/real(nz)
        dphi = 2.0*acos(-1.0)/real(nphi)
        viz_on = (nr == nr_list(nlev) .and. nphi == nphi_list(nlev) .and. nz == nz_list(nlev))

        allocate(Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz))
        allocate(Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz))
        allocate(axis_ez_series(0:nsteps), axis_ez_value(0:nsteps), axis_ez_j(0:nsteps), axis_ez_k(0:nsteps))
        Er = 0.0
        Ephi = 0.0
        Ez = 0.0
        Hr = 0.0
        Hphi = 0.0
        Hz = 0.0

        call init_fields(nr,nphi,nz,dr,dz,dt,omega0,Er,Ephi,Ez,Hr,Hphi,Hz)
        call fill_phi_all(nr,nphi,nz,Er,Ephi,Ez,Hr,Hphi,Hz)
        call axis_ez_max_abs(nr,nphi,nz,Ez,axis_ez_series(0),axis_ez_j(0),axis_ez_k(0),axis_ez_value(0))
        viz_open = .false.
        if (viz_on) then
            viz_stride = max(1,nsteps/90)
            open(newunit=viz_unit,file='mms_cyl_m1_viz_fine.bin',form='unformatted',access='stream',status='replace')
            write(viz_unit) nr
            write(viz_unit) nz
            write(viz_unit) viz_stride
            call write_viz_frame(viz_unit,nr,nphi,nz,dr,dphi,dz,0,0.0,omega0,Ez)
            viz_open = .true.
        end if

        progress_stride = max(1, min(100, nsteps))
        write(*,'(A,I0,A,I0,A,I0,A,I0)') &
            '  running level nr=',nr,', nphi=',nphi,', nz=',nz,', nsteps=',nsteps
        flush(output_unit)

        t_n = 0.0
        do n = 1, nsteps
            call sub_E02_fdtd_3d_cylindrical_H(0,nr,0,nphi+1,0,nz,0,nr-1,1,nphi,0,nz-1, &
                Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,mu)
            call add_h_source(nr,nphi,nz,dr,dz,dt,t_n,omega0,Hr,Hphi,Hz)
            call enforce_hr_axis(nr,nphi,nz,Hr,Hphi)
            call fill_phi_h(nr,nphi,nz,Hr,Hphi,Hz)

            call sub_E02_fdtd_3d_cylindrical_E(0,nr,0,nphi+1,0,nz,0,nr-1,1,nphi,1,nz-1, &
                Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,ep)
            call add_e_source(nr,nphi,nz,dr,dz,dt,t_n+0.5*dt,omega0,Er,Ephi,Ez)
            call enforce_e_axis(nr,nphi,nz,Er,Ephi)
            call enforce_e_boundaries(nr,nphi,nz,dr,dz,t_n+dt,omega0,Er,Ephi,Ez)
            call fill_phi_e(nr,nphi,nz,Er,Ephi,Ez)

            call axis_ez_max_abs(nr,nphi,nz,Ez,axis_ez_series(n),axis_ez_j(n),axis_ez_k(n),axis_ez_value(n))
            if (viz_on .and. (mod(n,viz_stride) == 0 .or. n == nsteps)) then
                call write_viz_frame(viz_unit,nr,nphi,nz,dr,dphi,dz,n,t_n+dt,omega0,Ez)
            end if

            t_n = t_n + dt
            if (mod(n, progress_stride) == 0 .or. n == nsteps) then
                write(*,'(A,I0,A,I0,A)') '    progress ',n,'/',nsteps,' steps'
                flush(output_unit)
            end if
        end do

        call write_axis_ez_series(nr,nphi,nz,dt,nsteps,axis_ez_series,axis_ez_j,axis_ez_k,axis_ez_value)

        call compute_errors(nr,nphi,nz,dr,dz,dphi,t_n,t_n-0.5*dt,omega0,Er,Ephi,Ez,Hr,Hphi,Hz, &
            l2_out,linf_out,axis_linf_out,l2_comb_out,linf_comb_out,axis_linf_comb_out, &
            l2_comb_e_out,l2_comb_h_out,linf_comb_e_out,linf_comb_h_out,region_linf_out, &
            wi,wj,wk,werr,rcomp,ri,rj,rk)

        write(*,'(A,I0,A,I0,A,I0,A,1PE11.3,A,I0)') &
            '  level nr=',nr,', nphi=',nphi,', nz=',nz,', dt=',dt,', nsteps=',nsteps
        write(*,'(A)') '    worst points by component:'
        do n = 1, ncomp
            call component_rphiz(n,wi(n),wj(n),wk(n),dr,dphi,dz,rw,phiw,zw)
            write(*,'(A,A,A,3(I0,1X),A,3(1PE11.3,1X),A,1PE11.3)') '      ',trim(comp_names(n)), &
                ' idx=',wi(n),wj(n),wk(n), ' rphiz=',rw,phiw,zw, ' err=',werr(n)
        end do
        write(*,'(A)') '    worst by region (combined):'
        do n = 1, nregion
            write(*,'(A,A,A,A,A,3(I0,1X),A,1PE11.3)') '      ',trim(region_names(n)), ' comp=', &
                trim(comp_names(rcomp(n))), ' idx=',ri(n),rj(n),rk(n), ' err=',region_linf_out(n)
        end do

        if (viz_open) close(viz_unit)
        deallocate(Er,Ephi,Ez,Hr,Hphi,Hz)
        deallocate(axis_ez_series,axis_ez_j,axis_ez_k,axis_ez_value)
    end subroutine run_level


    subroutine axis_ez_max_abs(nr,nphi,nz,Ez,maxabs,jw,kw,valw)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(in) :: Ez(0:nr,0:nphi+1,0:nz)
        real, intent(out) :: maxabs, valw
        integer, intent(out) :: jw, kw
        integer :: j, k
        real :: v

        maxabs = -1.0
        valw = 0.0
        jw = 1
        kw = 1
        do k = 1, nz-1
        do j = 1, nphi
            v = Ez(0,j,k)
            if (abs(v) > maxabs) then
                maxabs = abs(v)
                valw = v
                jw = j
                kw = k
            end if
        end do
        end do
    end subroutine axis_ez_max_abs


    subroutine dump_axis_ez_update_term(nphi,nz,dt,dr,Hphi)
        implicit none
        integer, intent(in) :: nphi, nz
        real, intent(in) :: dt, dr
        real, intent(in) :: Hphi(0:,0:,0:)
        integer :: j, k
        real :: avgk, termk, vmin, vmax

        write(*,'(A,I0,A)') '    debug Ez-axis update term: nphi=',nphi,', k=1..nz-1'
        vmin = huge(1.0)
        vmax = -huge(1.0)
        do k = 1, nz-1
            avgk = 0.0
            do j = 1, nphi
                avgk = avgk + Hphi(0,j,k)
            end do
            avgk = avgk/real(nphi)
            termk = 4.0*dt/(ep*dr)*avgk
            vmin = min(vmin, termk)
            vmax = max(vmax, termk)
            write(*,'(A,I0,A,1PE13.5)') '      k=',k,' 4dt/(ep*dr)*axis_hphi_avg=',termk
        end do
        write(*,'(A,2(1PE13.5,1X))') '      Ez-axis term min/max=',vmin,vmax
    end subroutine dump_axis_ez_update_term


    subroutine write_axis_ez_series(nr,nphi,nz,dt,nsteps,series,jidx,kidx,val)
        implicit none
        integer, intent(in) :: nr, nphi, nz, nsteps
        real, intent(in) :: dt, series(0:nsteps), val(0:nsteps)
        integer, intent(in) :: jidx(0:nsteps), kidx(0:nsteps)
        integer :: n, iu
        character(len=256) :: fname

        write(fname,'(A,I0,A,I0,A,I0,A)') 'axis_ez_timeseries_m1_nr',nr,'_nphi',nphi,'_nz',nz,'.dat'
        open(newunit=iu,file=trim(fname),status='replace',action='write')
        write(iu,'(A)') '# step t axis_ez_max_abs j_at_max k_at_max ez_value_at_max'
        do n = 0, nsteps
            write(iu,'(I0,1X,1PE16.8,1X,1PE16.8,1X,I0,1X,I0,1X,1PE16.8)') &
                n, real(n)*dt, series(n), jidx(n), kidx(n), val(n)
        end do
        close(iu)
        write(*,'(A,A)') '    wrote axis Ez series: ',trim(fname)
    end subroutine write_axis_ez_series


    subroutine write_viz_frame(unit,nr,nphi,nz,dr,dphi,dz,step,t_e,omega0,Ez)
        implicit none
        integer, intent(in) :: unit, nr, nphi, nz, step
        real, intent(in) :: dr, dphi, dz, t_e, omega0
        real, intent(in) :: Ez(0:nr,0:nphi+1,0:nz)
        integer :: i, k
        real :: r, z, phi_n
        real :: er0, ephi0, ez0, hr0, hphi0, hz0, ser, sephi, sez, shr, shphi, shz
        real :: Ez_num(0:nr,0:nz), Ez_exact(0:nr,0:nz)
        integer, parameter :: j_slice = 1

        phi_n = (real(j_slice)-1.0)*dphi
        do k = 0, nz
        do i = 0, nr
            Ez_num(i,k) = Ez(i,j_slice,k)
            r = real(i)*dr
            z = (real(k)+0.5)*dz
            call cyl_m1_exact_and_sources(r,phi_n,z,t_e,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            Ez_exact(i,k) = ez0
        end do
        end do

        write(unit) step
        write(unit) t_e
        write(unit) Ez_num
        write(unit) Ez_exact
    end subroutine write_viz_frame


    subroutine component_rphiz(ic,i,j,k,dr,dphi,dz,r,phi,z)
        implicit none
        integer, intent(in) :: ic, i, j, k
        real, intent(in) :: dr, dphi, dz
        real, intent(out) :: r, phi, z

        select case (ic)
        case (1) ! Er(r+1/2, phi, z)
            r = (real(i)+0.5)*dr
            phi = (real(j)-1.0)*dphi
            z = real(k)*dz
        case (2) ! Ephi(r, phi+1/2, z)
            r = real(i)*dr
            phi = (real(j)-0.5)*dphi
            z = real(k)*dz
        case (3) ! Ez(r, phi, z+1/2)
            r = real(i)*dr
            phi = (real(j)-1.0)*dphi
            z = (real(k)+0.5)*dz
        case (4) ! Hr(r, phi+1/2, z+1/2)
            r = real(i)*dr
            phi = (real(j)-0.5)*dphi
            z = (real(k)+0.5)*dz
        case (5) ! Hphi(r+1/2, phi, z+1/2)
            r = (real(i)+0.5)*dr
            phi = (real(j)-1.0)*dphi
            z = (real(k)+0.5)*dz
        case (6) ! Hz(r+1/2, phi+1/2, z)
            r = (real(i)+0.5)*dr
            phi = (real(j)-0.5)*dphi
            z = real(k)*dz
        end select
    end subroutine component_rphiz


    subroutine init_fields(nr,nphi,nz,dr,dz,dt,omega0,Er,Ephi,Ez,Hr,Hphi,Hz)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(in) :: dr, dz, dt, omega0
        real, intent(inout) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)
        real, intent(inout) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)
        integer :: i, j, k
        real :: r, z, phi_n, phi_h
        real :: er0, ephi0, ez0, hr0, hphi0, hz0, ser, sephi, sez, shr, shphi, shz

        Er = 0.0; Ephi = 0.0; Ez = 0.0
        Hr = 0.0; Hphi = 0.0; Hz = 0.0

        do k = 0, nz
        do j = 1, nphi
        do i = 0, nr
            phi_n = (real(j)-1.0)*(2.0*acos(-1.0)/real(nphi))
            phi_h = (real(j)-0.5)*(2.0*acos(-1.0)/real(nphi))

            r = (real(i)+0.5)*dr
            z = real(k)*dz
            call cyl_m1_exact_and_sources(r,phi_n,z,0.0,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            Er(i,j,k) = er0

            r = real(i)*dr
            call cyl_m1_exact_and_sources(r,phi_h,z,0.0,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            Ephi(i,j,k) = ephi0

            z = (real(k)+0.5)*dz
            call cyl_m1_exact_and_sources(r,phi_n,z,0.0,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            Ez(i,j,k) = ez0

            call cyl_m1_exact_and_sources(r,phi_h,z,-0.5*dt,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            Hr(i,j,k) = hr0

            r = (real(i)+0.5)*dr
            call cyl_m1_exact_and_sources(r,phi_n,z,-0.5*dt,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            Hphi(i,j,k) = hphi0

            z = real(k)*dz
            call cyl_m1_exact_and_sources(r,phi_h,z,-0.5*dt,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            Hz(i,j,k) = hz0
        end do
        end do
        end do
    end subroutine init_fields


    subroutine add_h_source(nr,nphi,nz,dr,dz,dt,t_src,omega0,Hr,Hphi,Hz)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(in) :: dr, dz, dt, t_src, omega0
        real, intent(inout) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)
        integer :: i, j, k
        real :: r, z, phi_n, phi_h
        real :: er0, ephi0, ez0, hr0, hphi0, hz0, ser, sephi, sez, shr, shphi, shz

        do k = 0, nz-1
        do j = 1, nphi
        do i = 0, nr-1
            phi_n = (real(j)-1.0)*(2.0*acos(-1.0)/real(nphi))
            phi_h = (real(j)-0.5)*(2.0*acos(-1.0)/real(nphi))

            r = real(i)*dr
            z = (real(k)+0.5)*dz
            call cyl_m1_exact_and_sources(r,phi_h,z,t_src,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            Hr(i,j,k) = Hr(i,j,k) + dt*shr

            r = (real(i)+0.5)*dr
            call cyl_m1_exact_and_sources(r,phi_n,z,t_src,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            Hphi(i,j,k) = Hphi(i,j,k) + dt*shphi

            z = real(k)*dz
            call cyl_m1_exact_and_sources(r,phi_h,z,t_src,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            Hz(i,j,k) = Hz(i,j,k) + dt*shz
        end do
        end do
        end do
    end subroutine add_h_source


    subroutine add_e_source(nr,nphi,nz,dr,dz,dt,t_src,omega0,Er,Ephi,Ez)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(in) :: dr, dz, dt, t_src, omega0
        real, intent(inout) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)
        integer :: i, j, k
        real :: r, z, phi_n, phi_h
        real :: er0, ephi0, ez0, hr0, hphi0, hz0, ser, sephi, sez, shr, shphi, shz

        do k = 1, nz-1
        do j = 1, nphi
        do i = 0, nr-1
            phi_n = (real(j)-1.0)*(2.0*acos(-1.0)/real(nphi))
            phi_h = (real(j)-0.5)*(2.0*acos(-1.0)/real(nphi))

            r = (real(i)+0.5)*dr
            z = real(k)*dz
            call cyl_m1_exact_and_sources(r,phi_n,z,t_src,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            Er(i,j,k) = Er(i,j,k) + dt*ser

            r = real(i)*dr
            call cyl_m1_exact_and_sources(r,phi_h,z,t_src,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            Ephi(i,j,k) = Ephi(i,j,k) + dt*sephi

            z = (real(k)+0.5)*dz
            call cyl_m1_exact_and_sources(r,phi_n,z,t_src,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            if (i /= 0) then
                Ez(i,j,k) = Ez(i,j,k) + dt*sez
            end if
        end do
        end do
        end do
    end subroutine add_e_source


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


    subroutine enforce_e_boundaries(nr,nphi,nz,dr,dz,t_e,omega0,Er,Ephi,Ez)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(in) :: dr, dz, t_e, omega0
        real, intent(inout) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)
        integer :: i, j, k
        real :: r, z, phi_n, phi_h
        real :: er0, ephi0, ez0, hr0, hphi0, hz0, ser, sephi, sez, shr, shphi, shz

        do j = 1, nphi
        do k = 0, nz
            phi_n = (real(j)-1.0)*(2.0*acos(-1.0)/real(nphi))
            phi_h = (real(j)-0.5)*(2.0*acos(-1.0)/real(nphi))

            r = real(nr)*dr
            z = real(k)*dz
            call cyl_m1_exact_and_sources(r,phi_h,z,t_e,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            Ephi(nr,j,k) = ephi0

            z = (real(k)+0.5)*dz
            call cyl_m1_exact_and_sources(r,phi_n,z,t_e,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            Ez(nr,j,k) = ez0
        end do
        end do

        do j = 1, nphi
        do i = 0, nr
            phi_n = (real(j)-1.0)*(2.0*acos(-1.0)/real(nphi))
            phi_h = (real(j)-0.5)*(2.0*acos(-1.0)/real(nphi))

            r = (real(i)+0.5)*dr
            call cyl_m1_exact_and_sources(r,phi_n,0.0,t_e,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            Er(i,j,0) = er0
            call cyl_m1_exact_and_sources(r,phi_n,lz,t_e,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            Er(i,j,nz) = er0

            r = real(i)*dr
            call cyl_m1_exact_and_sources(r,phi_h,0.0,t_e,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            Ephi(i,j,0) = ephi0
            call cyl_m1_exact_and_sources(r,phi_h,lz,t_e,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            Ephi(i,j,nz) = ephi0
        end do
        end do
    end subroutine enforce_e_boundaries


    subroutine compute_errors(nr,nphi,nz,dr,dz,dphi,t_e,t_h,omega0,Er,Ephi,Ez,Hr,Hphi,Hz, &
        l2c,linfc,axis_linfc,l2all,linfall,axis_linfall,l2e,l2h,linfe,linfh,region_linf, &
        wi,wj,wk,werr,rcomp,ri,rj,rk)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(in) :: dr, dz, dphi, t_e, t_h, omega0
        real, intent(in) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)
        real, intent(in) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)
        real, intent(out) :: l2c(ncomp), linfc(ncomp), axis_linfc(ncomp), l2all, linfall, axis_linfall
        real, intent(out) :: l2e, l2h, linfe, linfh
        real, intent(out) :: region_linf(nregion)
        integer, intent(out) :: wi(ncomp), wj(ncomp), wk(ncomp), rcomp(nregion), ri(nregion), rj(nregion), rk(nregion)
        real, intent(out) :: werr(ncomp)

        integer :: i, j, k, reg
        real :: r, z, phi_n, phi_h, w, err, axis_r
        real :: er0, ephi0, ez0, hr0, hphi0, hz0, ser, sephi, sez, shr, shphi, shz
        real :: sumsq(ncomp), sumw(ncomp), sumsq_all, sumw_all

        axis_r = axis_band_factor*dr
        sumsq = 0.0
        sumw = 0.0
        linfc = 0.0
        axis_linfc = 0.0
        region_linf = 0.0
        wi = 0; wj = 1; wk = 0; werr = -1.0
        rcomp = 1; ri = 0; rj = 1; rk = 0

        do k = 1, nz-1
        do j = 1, nphi
        do i = 0, nr-1
            phi_n = (real(j)-1.0)*dphi
            r = (real(i)+0.5)*dr
            z = real(k)*dz
            call cyl_m1_exact_and_sources(r,phi_n,z,t_e,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            err = abs(Er(i,j,k)-er0)
            w = r*dr*dphi*dz
            sumsq(1) = sumsq(1) + err*err*w
            sumw(1) = sumw(1) + w
            linfc(1) = max(linfc(1), err)
            if (r <= axis_r) axis_linfc(1) = max(axis_linfc(1), err)
            if (err > werr(1)) then
                werr(1) = err; wi(1) = i; wj(1) = j; wk(1) = k
            end if
            reg = region_of_point(r,dr,dz,i,k,nr,nz)
            if (err > region_linf(reg)) then
                region_linf(reg) = err; rcomp(reg) = 1; ri(reg) = i; rj(reg) = j; rk(reg) = k
            end if
        end do
        end do
        end do

        do k = 1, nz-1
        do j = 1, nphi
        ! Axis Ephi(i=0,*,*) is replaced by Er in production update coupling.
        ! Exclude it from error norms to match the active DOF set.
        do i = 1, nr-1
            phi_h = (real(j)-0.5)*dphi
            r = real(i)*dr
            z = real(k)*dz
            call cyl_m1_exact_and_sources(r,phi_h,z,t_e,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            err = abs(Ephi(i,j,k)-ephi0)
            w = r*dr*dphi*dz
            sumsq(2) = sumsq(2) + err*err*w
            sumw(2) = sumw(2) + w
            linfc(2) = max(linfc(2), err)
            if (r <= axis_r) axis_linfc(2) = max(axis_linfc(2), err)
            if (err > werr(2)) then
                werr(2) = err; wi(2) = i; wj(2) = j; wk(2) = k
            end if
            reg = region_of_point(r,dr,dz,i,k,nr,nz)
            if (err > region_linf(reg)) then
                region_linf(reg) = err; rcomp(reg) = 2; ri(reg) = i; rj(reg) = j; rk(reg) = k
            end if
        end do
        end do
        end do

        do k = 1, nz-1
        do j = 1, nphi
        do i = 0, nr-1
            phi_n = (real(j)-1.0)*dphi
            r = real(i)*dr
            z = (real(k)+0.5)*dz
            call cyl_m1_exact_and_sources(r,phi_n,z,t_e,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            err = abs(Ez(i,j,k)-ez0)
            w = r*dr*dphi*dz
            sumsq(3) = sumsq(3) + err*err*w
            sumw(3) = sumw(3) + w
            linfc(3) = max(linfc(3), err)
            if (r <= axis_r) axis_linfc(3) = max(axis_linfc(3), err)
            if (err > werr(3)) then
                werr(3) = err; wi(3) = i; wj(3) = j; wk(3) = k
            end if
            reg = region_of_point(r,dr,dz,i,k,nr,nz)
            if (err > region_linf(reg)) then
                region_linf(reg) = err; rcomp(reg) = 3; ri(reg) = i; rj(reg) = j; rk(reg) = k
            end if
        end do
        end do
        end do

        do k = 0, nz-1
        do j = 1, nphi
        ! Axis Hr(i=0,*,*) is replaced by Hphi in production update coupling.
        ! Exclude it from error norms to match the active DOF set.
        do i = 1, nr-1
            phi_h = (real(j)-0.5)*dphi
            r = real(i)*dr
            z = (real(k)+0.5)*dz
            call cyl_m1_exact_and_sources(r,phi_h,z,t_h,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            err = abs(Hr(i,j,k)-hr0)
            w = r*dr*dphi*dz
            sumsq(4) = sumsq(4) + err*err*w
            sumw(4) = sumw(4) + w
            linfc(4) = max(linfc(4), err)
            if (r <= axis_r) axis_linfc(4) = max(axis_linfc(4), err)
            if (err > werr(4)) then
                werr(4) = err; wi(4) = i; wj(4) = j; wk(4) = k
            end if
            reg = region_of_point(r,dr,dz,i,k,nr,nz)
            if (err > region_linf(reg)) then
                region_linf(reg) = err; rcomp(reg) = 4; ri(reg) = i; rj(reg) = j; rk(reg) = k
            end if
        end do
        end do
        end do

        do k = 0, nz-1
        do j = 1, nphi
        do i = 0, nr-1
            phi_n = (real(j)-1.0)*dphi
            r = (real(i)+0.5)*dr
            z = (real(k)+0.5)*dz
            call cyl_m1_exact_and_sources(r,phi_n,z,t_h,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            err = abs(Hphi(i,j,k)-hphi0)
            w = r*dr*dphi*dz
            sumsq(5) = sumsq(5) + err*err*w
            sumw(5) = sumw(5) + w
            linfc(5) = max(linfc(5), err)
            if (r <= axis_r) axis_linfc(5) = max(axis_linfc(5), err)
            if (err > werr(5)) then
                werr(5) = err; wi(5) = i; wj(5) = j; wk(5) = k
            end if
            reg = region_of_point(r,dr,dz,i,k,nr,nz)
            if (err > region_linf(reg)) then
                region_linf(reg) = err; rcomp(reg) = 5; ri(reg) = i; rj(reg) = j; rk(reg) = k
            end if
        end do
        end do
        end do

        do k = 0, nz-1
        do j = 1, nphi
        do i = 0, nr-1
            phi_h = (real(j)-0.5)*dphi
            r = (real(i)+0.5)*dr
            z = real(k)*dz
            call cyl_m1_exact_and_sources(r,phi_h,z,t_h,ep,mu,rmax,lz,omega0, &
                er0,ephi0,ez0,hr0,hphi0,hz0,ser,sephi,sez,shr,shphi,shz)
            err = abs(Hz(i,j,k)-hz0)
            w = r*dr*dphi*dz
            sumsq(6) = sumsq(6) + err*err*w
            sumw(6) = sumw(6) + w
            linfc(6) = max(linfc(6), err)
            if (r <= axis_r) axis_linfc(6) = max(axis_linfc(6), err)
            if (err > werr(6)) then
                werr(6) = err; wi(6) = i; wj(6) = j; wk(6) = k
            end if
            reg = region_of_point(r,dr,dz,i,k,nr,nz)
            if (err > region_linf(reg)) then
                region_linf(reg) = err; rcomp(reg) = 6; ri(reg) = i; rj(reg) = j; rk(reg) = k
            end if
        end do
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
        l2e = sqrt(sum(sumsq(1:3))/max(sum(sumw(1:3)),1.0e-30))
        l2h = sqrt(sum(sumsq(4:6))/max(sum(sumw(4:6)),1.0e-30))
        linfe = maxval(linfc(1:3))
        linfh = maxval(linfc(4:6))
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


    subroutine fill_phi_field(nr,nphi,nz,A)
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
    end subroutine fill_phi_field


    subroutine fill_phi_all(nr,nphi,nz,Er,Ephi,Ez,Hr,Hphi,Hz)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(inout) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)
        real, intent(inout) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)
        call fill_phi_field(nr,nphi,nz,Er)
        call fill_phi_field(nr,nphi,nz,Ephi)
        call fill_phi_field(nr,nphi,nz,Ez)
        call fill_phi_field(nr,nphi,nz,Hr)
        call fill_phi_field(nr,nphi,nz,Hphi)
        call fill_phi_field(nr,nphi,nz,Hz)
    end subroutine fill_phi_all


    subroutine fill_phi_h(nr,nphi,nz,Hr,Hphi,Hz)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(inout) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)
        call fill_phi_field(nr,nphi,nz,Hr)
        call fill_phi_field(nr,nphi,nz,Hphi)
        call fill_phi_field(nr,nphi,nz,Hz)
    end subroutine fill_phi_h


    subroutine fill_phi_e(nr,nphi,nz,Er,Ephi,Ez)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(inout) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)
        call fill_phi_field(nr,nphi,nz,Er)
        call fill_phi_field(nr,nphi,nz,Ephi)
        call fill_phi_field(nr,nphi,nz,Ez)
    end subroutine fill_phi_e

end program test_mms_3d_cyl_m1_convergence
