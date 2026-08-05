program test_geom_m0_equivalence

    use mod_E01_fdtd_2d_rz_tmz
    use mod_E01_fdtd_2d_rz_tez
    use mod_E02_fdtd_3d_cylindrical
    use geom_special_common
    use geom_special_fdtd_support
    implicit none

    integer, parameter :: nr = 40, nphi = 32, nz = 64
    integer, parameter :: nsteps_default = 600
    real, parameter :: ep = 1.0, mu = 1.0
    real, parameter :: rmax = 1.0, lz = 1.0
    real, parameter :: cfl = 0.8
    real, parameter :: amp0 = 1.0e-4
    real, parameter :: rel_l2_tol = 2.0e-2
    real, parameter :: rel_linf_tol = 1.0e-1

    integer :: nsteps

    call parse_int_arg(1, nsteps_default, nsteps)
    nsteps = max(1, nsteps)

    call print_header('3D cyl m=0 vs 2D RZ equivalence')
    call run_tmz_equiv(nsteps)
    call run_tez_equiv(nsteps)

contains

    subroutine run_tmz_equiv(nsteps)
        implicit none
        integer, intent(in) :: nsteps
        real, allocatable :: Er2(:,:), Ez2(:,:), Ha2(:,:)
        real, allocatable :: Er3(:,:,:), Ephi3(:,:,:), Ez3(:,:,:), Hr3(:,:,:), Hphi3(:,:,:), Hz3(:,:,:)
        real :: dr, dz, dphi, dt, dt_crit, c0, tnow
        real :: l2_rel(3), linf_rel(3), comb_l2, comb_linf
        real :: sum_err2, sum_ref2, max_ref, max_err
        integer :: n, i, j, k
        character(len=8) :: result
        character(len=8), parameter :: cname(3) = [character(len=8) :: 'Er','Ez','Hphi']

        c0 = 1.0/sqrt(ep*mu)
        dr = rmax/real(nr)
        dz = lz/real(nz)
        dphi = 2.0*acos(-1.0)/real(nphi)
        dt_crit = 1.0/(c0*sqrt((1.0/dr)**2 + (1.0/dz)**2 + (1.0/(0.5*dr*dphi))**2))
        dt = cfl*dt_crit

        allocate(Er2(0:nr,0:nz), Ez2(0:nr,0:nz), Ha2(0:nr,0:nz))
        allocate(Er3(0:nr,0:nphi+1,0:nz), Ephi3(0:nr,0:nphi+1,0:nz), Ez3(0:nr,0:nphi+1,0:nz))
        allocate(Hr3(0:nr,0:nphi+1,0:nz), Hphi3(0:nr,0:nphi+1,0:nz), Hz3(0:nr,0:nphi+1,0:nz))

        call init_2d_tmz(nr,nz,dr,dz,amp0,rmax,lz,Er2,Ez2,Ha2)
        call fill_2d_tmz_all(nr,nz,Er2,Ez2,Ha2)

        Er3 = 0.0
        Ephi3 = 0.0
        Ez3 = 0.0
        Hr3 = 0.0
        Hphi3 = 0.0
        Hz3 = 0.0

        do k = 0, nz
        do j = 0, nphi+1
        do i = 0, nr
            Er3(i,j,k) = Er2(i,k)
            Ez3(i,j,k) = Ez2(i,k)
            Hphi3(i,j,k) = Ha2(i,k)
        end do
        end do
        end do
        call fill_3d_all(nr,nphi,nz,Er3,Ephi3,Ez3,Hr3,Hphi3,Hz3,CLOSURE_COPY,0.0,.false.,dr,dphi,dz,rmax,lz,amp0)

        tnow = 0.0
        do n = 1, nsteps
            call sub_E01_fdtd_2d_rz_tmz_H(0,nr,0,nz,0,nr-1,0,nz-1,Ha2,Er2,Ez2,dt,dr,dz,mu)
            call fill_2d_tmz_h(nr,nz,Ha2)
            call sub_E01_fdtd_2d_rz_tmz_E(0,nr,0,nz,0,nr-1,1,nz-1,Ha2,Er2,Ez2,dt,dr,dz,ep)
            call fill_2d_tmz_e(nr,nz,Er2,Ez2)

            call sub_E02_fdtd_3d_cylindrical_H(0,nr,0,nphi+1,0,nz,0,nr-1,1,nphi,0,nz-1, &
                Er3,Ephi3,Ez3,Hr3,Hphi3,Hz3,dt,dr,dphi,dz,mu)
            call fill_3d_h(nr,nphi,nz,Hr3,Hphi3,Hz3,CLOSURE_COPY,tnow+0.5*dt,.false.,dr,dphi,dz,rmax,lz,amp0)

            call sub_E02_fdtd_3d_cylindrical_E(0,nr,0,nphi+1,0,nz,0,nr-1,1,nphi,1,nz-1, &
                Er3,Ephi3,Ez3,Hr3,Hphi3,Hz3,dt,dr,dphi,dz,ep)
            call fill_3d_e(nr,nphi,nz,Er3,Ephi3,Ez3,CLOSURE_COPY,tnow+dt,.false.,dr,dphi,dz,rmax,lz,amp0)

            tnow = tnow + dt
        end do

        call compare_er(Er2,Er3,dr,dz,dphi,l2_rel(1),linf_rel(1))
        call compare_ez(Ez2,Ez3,dr,dz,dphi,l2_rel(2),linf_rel(2))
        call compare_hphi(Ha2,Hphi3,dr,dz,dphi,l2_rel(3),linf_rel(3))

        call combine_metrics(l2_rel,linf_rel,comb_l2,comb_linf)

        if (comb_l2 <= rel_l2_tol .and. comb_linf <= rel_linf_tol) then
            result = 'pass'
        else
            result = 'fail'
        end if

        write(*,'(A)') 'subcase=TMz_equivalence'
        write(*,'(A,3(1PE11.3,1X))') '  rel_L2   : ', l2_rel(1), l2_rel(2), l2_rel(3)
        write(*,'(A,3(1PE11.3,1X))') '  rel_Linf : ', linf_rel(1), linf_rel(2), linf_rel(3)
        write(*,'(A,1PE11.3,A,1PE11.3,A,A)') '  combined_L2=', comb_l2, ' combined_Linf=', comb_linf, ' result=', trim(result)
        write(*,'("SUMMARY_CSV,m0_equivalence,TMz,",1PE11.3,",",1PE11.3,",",A,",",A,",",A,",",A)') &
            comb_l2, comb_linf, trim(result), trim(cname(1)), trim(cname(2)), trim(cname(3))

        deallocate(Er2,Ez2,Ha2,Er3,Ephi3,Ez3,Hr3,Hphi3,Hz3)
    end subroutine run_tmz_equiv


    subroutine run_tez_equiv(nsteps)
        implicit none
        integer, intent(in) :: nsteps
        real, allocatable :: Ephi2(:,:), Hr2(:,:), Hz2(:,:)
        real, allocatable :: Er3(:,:,:), Ephi3(:,:,:), Ez3(:,:,:), Hr3(:,:,:), Hphi3(:,:,:), Hz3(:,:,:)
        real :: dr, dz, dphi, dt, dt_crit, c0, tnow
        real :: l2_rel(3), linf_rel(3), comb_l2, comb_linf
        integer :: n, i, j, k
        character(len=8) :: result
        character(len=8), parameter :: cname(3) = [character(len=8) :: 'Ephi','Hr','Hz']

        c0 = 1.0/sqrt(ep*mu)
        dr = rmax/real(nr)
        dz = lz/real(nz)
        dphi = 2.0*acos(-1.0)/real(nphi)
        dt_crit = 1.0/(c0*sqrt((1.0/dr)**2 + (1.0/dz)**2 + (1.0/(0.5*dr*dphi))**2))
        dt = cfl*dt_crit

        allocate(Ephi2(0:nr,0:nz), Hr2(0:nr,0:nz), Hz2(0:nr,0:nz))
        allocate(Er3(0:nr,0:nphi+1,0:nz), Ephi3(0:nr,0:nphi+1,0:nz), Ez3(0:nr,0:nphi+1,0:nz))
        allocate(Hr3(0:nr,0:nphi+1,0:nz), Hphi3(0:nr,0:nphi+1,0:nz), Hz3(0:nr,0:nphi+1,0:nz))

        call init_2d_tez(nr,nz,dr,dz,amp0,rmax,lz,Ephi2,Hr2,Hz2)
        call fill_2d_tez_all(nr,nz,Ephi2,Hr2,Hz2)

        Er3 = 0.0
        Ephi3 = 0.0
        Ez3 = 0.0
        Hr3 = 0.0
        Hphi3 = 0.0
        Hz3 = 0.0

        do k = 0, nz
        do j = 0, nphi+1
        do i = 0, nr
            Ephi3(i,j,k) = Ephi2(i,k)
            Hr3(i,j,k) = Hr2(i,k)
            Hz3(i,j,k) = Hz2(i,k)
        end do
        end do
        end do
        call fill_3d_all(nr,nphi,nz,Er3,Ephi3,Ez3,Hr3,Hphi3,Hz3,CLOSURE_COPY,0.0,.false.,dr,dphi,dz,rmax,lz,amp0)

        tnow = 0.0
        do n = 1, nsteps
            call sub_E01_fdtd_2d_rz_tez_H(0,nr,0,nz,0,nr-1,0,nz-1,Ephi2,Hr2,Hz2,dt,dr,dz,mu)
            call fill_2d_tez_h(nr,nz,Hr2,Hz2)
            call sub_E01_fdtd_2d_rz_tez_E(0,nr,0,nz,0,nr-1,1,nz-1,Ephi2,Hr2,Hz2,dt,dr,dz,ep)
            call fill_2d_tez_e(nr,nz,Ephi2)

            call sub_E02_fdtd_3d_cylindrical_H(0,nr,0,nphi+1,0,nz,0,nr-1,1,nphi,0,nz-1, &
                Er3,Ephi3,Ez3,Hr3,Hphi3,Hz3,dt,dr,dphi,dz,mu)
            call fill_3d_h(nr,nphi,nz,Hr3,Hphi3,Hz3,CLOSURE_COPY,tnow+0.5*dt,.false.,dr,dphi,dz,rmax,lz,amp0)

            call sub_E02_fdtd_3d_cylindrical_E(0,nr,0,nphi+1,0,nz,0,nr-1,1,nphi,1,nz-1, &
                Er3,Ephi3,Ez3,Hr3,Hphi3,Hz3,dt,dr,dphi,dz,ep)
            call fill_3d_e(nr,nphi,nz,Er3,Ephi3,Ez3,CLOSURE_COPY,tnow+dt,.false.,dr,dphi,dz,rmax,lz,amp0)

            tnow = tnow + dt
        end do

        call compare_ephi(Ephi2,Ephi3,dr,dz,dphi,l2_rel(1),linf_rel(1))
        call compare_hr(Hr2,Hr3,dr,dz,dphi,l2_rel(2),linf_rel(2))
        call compare_hz(Hz2,Hz3,dr,dz,dphi,l2_rel(3),linf_rel(3))

        call combine_metrics(l2_rel,linf_rel,comb_l2,comb_linf)

        if (comb_l2 <= rel_l2_tol .and. comb_linf <= rel_linf_tol) then
            result = 'pass'
        else
            result = 'fail'
        end if

        write(*,'(A)') 'subcase=TEz_equivalence'
        write(*,'(A,3(1PE11.3,1X))') '  rel_L2   : ', l2_rel(1), l2_rel(2), l2_rel(3)
        write(*,'(A,3(1PE11.3,1X))') '  rel_Linf : ', linf_rel(1), linf_rel(2), linf_rel(3)
        write(*,'(A,1PE11.3,A,1PE11.3,A,A)') '  combined_L2=', comb_l2, ' combined_Linf=', comb_linf, ' result=', trim(result)
        write(*,'("SUMMARY_CSV,m0_equivalence,TEz,",1PE11.3,",",1PE11.3,",",A,",",A,",",A,",",A)') &
            comb_l2, comb_linf, trim(result), trim(cname(1)), trim(cname(2)), trim(cname(3))

        deallocate(Ephi2,Hr2,Hz2,Er3,Ephi3,Ez3,Hr3,Hphi3,Hz3)
    end subroutine run_tez_equiv


    subroutine combine_metrics(l2_rel, linf_rel, comb_l2, comb_linf)
        implicit none
        real, intent(in) :: l2_rel(3), linf_rel(3)
        real, intent(out) :: comb_l2, comb_linf

        comb_l2 = sqrt((l2_rel(1)**2 + l2_rel(2)**2 + l2_rel(3)**2)/3.0)
        comb_linf = max(linf_rel(1), max(linf_rel(2), linf_rel(3)))
    end subroutine combine_metrics


    subroutine compare_er(ref2, num3, dr, dz, dphi, rel_l2, rel_linf)
        implicit none
        real, intent(in) :: ref2(0:nr,0:nz), num3(0:nr,0:nphi+1,0:nz)
        real, intent(in) :: dr, dz, dphi
        real, intent(out) :: rel_l2, rel_linf
        integer :: i, j, k
        real :: avg, e, r, w, sume2, sumr2, maxe, maxr

        sume2 = 0.0; sumr2 = 0.0; maxe = 0.0; maxr = 0.0
        do k = 1, nz-1
        do i = 0, nr-1
            avg = 0.0
            do j = 1, nphi
                avg = avg + num3(i,j,k)
            end do
            avg = avg/real(nphi)
            e = avg - ref2(i,k)
            r = ref2(i,k)
            w = (real(i)+0.5)*dr*dr*dz
            sume2 = sume2 + e*e*w
            sumr2 = sumr2 + r*r*w
            maxe = max(maxe, abs(e))
            maxr = max(maxr, abs(r))
        end do
        end do
        rel_l2 = sqrt(sume2/max(sumr2,1.0e-30))
        rel_linf = safe_ratio(maxe, maxr)
    end subroutine compare_er


    subroutine compare_ez(ref2, num3, dr, dz, dphi, rel_l2, rel_linf)
        implicit none
        real, intent(in) :: ref2(0:nr,0:nz), num3(0:nr,0:nphi+1,0:nz)
        real, intent(in) :: dr, dz, dphi
        real, intent(out) :: rel_l2, rel_linf
        integer :: i, j, k
        real :: avg, e, r, w, sume2, sumr2, maxe, maxr

        sume2 = 0.0; sumr2 = 0.0; maxe = 0.0; maxr = 0.0
        do k = 1, nz-1
        do i = 0, nr-1
            avg = 0.0
            do j = 1, nphi
                avg = avg + num3(i,j,k)
            end do
            avg = avg/real(nphi)
            e = avg - ref2(i,k)
            r = ref2(i,k)
            w = real(i)*dr*dr*dz
            sume2 = sume2 + e*e*w
            sumr2 = sumr2 + r*r*w
            maxe = max(maxe, abs(e))
            maxr = max(maxr, abs(r))
        end do
        end do
        rel_l2 = sqrt(sume2/max(sumr2,1.0e-30))
        rel_linf = safe_ratio(maxe, maxr)
    end subroutine compare_ez


    subroutine compare_hphi(ref2, num3, dr, dz, dphi, rel_l2, rel_linf)
        implicit none
        real, intent(in) :: ref2(0:nr,0:nz), num3(0:nr,0:nphi+1,0:nz)
        real, intent(in) :: dr, dz, dphi
        real, intent(out) :: rel_l2, rel_linf
        integer :: i, j, k
        real :: avg, e, r, w, sume2, sumr2, maxe, maxr

        sume2 = 0.0; sumr2 = 0.0; maxe = 0.0; maxr = 0.0
        do k = 0, nz-1
        do i = 0, nr-1
            avg = 0.0
            do j = 1, nphi
                avg = avg + num3(i,j,k)
            end do
            avg = avg/real(nphi)
            e = avg - ref2(i,k)
            r = ref2(i,k)
            w = (real(i)+0.5)*dr*dr*dz
            sume2 = sume2 + e*e*w
            sumr2 = sumr2 + r*r*w
            maxe = max(maxe, abs(e))
            maxr = max(maxr, abs(r))
        end do
        end do
        rel_l2 = sqrt(sume2/max(sumr2,1.0e-30))
        rel_linf = safe_ratio(maxe, maxr)
    end subroutine compare_hphi


    subroutine compare_ephi(ref2, num3, dr, dz, dphi, rel_l2, rel_linf)
        implicit none
        real, intent(in) :: ref2(0:nr,0:nz), num3(0:nr,0:nphi+1,0:nz)
        real, intent(in) :: dr, dz, dphi
        real, intent(out) :: rel_l2, rel_linf
        integer :: i, j, k
        real :: avg, e, r, w, sume2, sumr2, maxe, maxr

        sume2 = 0.0; sumr2 = 0.0; maxe = 0.0; maxr = 0.0
        do k = 1, nz-1
        do i = 1, nr-1
            avg = 0.0
            do j = 1, nphi
                avg = avg + num3(i,j,k)
            end do
            avg = avg/real(nphi)
            e = avg - ref2(i,k)
            r = ref2(i,k)
            w = real(i)*dr*dr*dz
            sume2 = sume2 + e*e*w
            sumr2 = sumr2 + r*r*w
            maxe = max(maxe, abs(e))
            maxr = max(maxr, abs(r))
        end do
        end do
        rel_l2 = sqrt(sume2/max(sumr2,1.0e-30))
        rel_linf = safe_ratio(maxe, maxr)
    end subroutine compare_ephi


    subroutine compare_hr(ref2, num3, dr, dz, dphi, rel_l2, rel_linf)
        implicit none
        real, intent(in) :: ref2(0:nr,0:nz), num3(0:nr,0:nphi+1,0:nz)
        real, intent(in) :: dr, dz, dphi
        real, intent(out) :: rel_l2, rel_linf
        integer :: i, j, k
        real :: avg, e, r, w, sume2, sumr2, maxe, maxr

        sume2 = 0.0; sumr2 = 0.0; maxe = 0.0; maxr = 0.0
        do k = 0, nz-1
        do i = 1, nr-1
            avg = 0.0
            do j = 1, nphi
                avg = avg + num3(i,j,k)
            end do
            avg = avg/real(nphi)
            e = avg - ref2(i,k)
            r = ref2(i,k)
            w = real(i)*dr*dr*dz
            sume2 = sume2 + e*e*w
            sumr2 = sumr2 + r*r*w
            maxe = max(maxe, abs(e))
            maxr = max(maxr, abs(r))
        end do
        end do
        rel_l2 = sqrt(sume2/max(sumr2,1.0e-30))
        rel_linf = safe_ratio(maxe, maxr)
    end subroutine compare_hr


    subroutine compare_hz(ref2, num3, dr, dz, dphi, rel_l2, rel_linf)
        implicit none
        real, intent(in) :: ref2(0:nr,0:nz), num3(0:nr,0:nphi+1,0:nz)
        real, intent(in) :: dr, dz, dphi
        real, intent(out) :: rel_l2, rel_linf
        integer :: i, j, k
        real :: avg, e, r, w, sume2, sumr2, maxe, maxr

        sume2 = 0.0; sumr2 = 0.0; maxe = 0.0; maxr = 0.0
        do k = 0, nz-1
        do i = 0, nr-1
            avg = 0.0
            do j = 1, nphi
                avg = avg + num3(i,j,k)
            end do
            avg = avg/real(nphi)
            e = avg - ref2(i,k)
            r = ref2(i,k)
            w = (real(i)+0.5)*dr*dr*dz
            sume2 = sume2 + e*e*w
            sumr2 = sumr2 + r*r*w
            maxe = max(maxe, abs(e))
            maxr = max(maxr, abs(r))
        end do
        end do
        rel_l2 = sqrt(sume2/max(sumr2,1.0e-30))
        rel_linf = safe_ratio(maxe, maxr)
    end subroutine compare_hz

end program test_geom_m0_equivalence

