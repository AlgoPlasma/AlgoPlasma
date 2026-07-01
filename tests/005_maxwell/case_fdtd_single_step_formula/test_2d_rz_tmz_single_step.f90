program test_2d_rz_tmz_single_step

    use mod_E01_fdtd_2d_rz_tmz
    use test_single_step_utils
    implicit none

    integer, parameter :: nr = 24, nz = 26
    real, parameter :: pi = 3.14159265358979323846
    real, parameter :: dr = 0.07, dz = 0.06
    real, parameter :: dt = 0.22e-10
    real, parameter :: ep = 8.854187817e-12
    real, parameter :: mu = 1.2566370614e-6
    real, parameter :: tol_interior = 1.0e-11
    real, parameter :: tol_axis = 1.0e-10
    real, parameter :: tol_boundary = 1.0e-10

    real :: Er0(0:nr,0:nz), Ez0(0:nr,0:nz), Ha0(0:nr,0:nz)
    real :: Er_num(0:nr,0:nz), Ez_num(0:nr,0:nz), Ha_num(0:nr,0:nz)
    real :: Er_ref(0:nr,0:nz), Ez_ref(0:nr,0:nz), Ha_ref(0:nr,0:nz)
    real :: err2d(0:nr,0:nz)
    type(report_t) :: rep
    logical :: all_ok

    all_ok = .true.
    call init_rz_tmz_fields(nr,nz,dr,dz,Er0,Ez0,Ha0)

    write(*,'(A)') '=== 2D Cylindrical (r-z) TMz FDTD Single-Step Formula Test ==='

    call report_init(rep)
    Er_num = Er0; Ez_num = Ez0; Ha_num = Ha0
    call sub_E01_fdtd_2d_rz_tmz_E(0,nr,0,nz,0,nr-1,1,nz-1,Ha_num,Er_num,Ez_num,dt,dr,dz,ep)

    Er_ref = Er0; Ez_ref = Ez0
    call ref_update_rz_tmz_E(nr,nz,0,nr-1,1,nz-1,Ha0,Er0,Ez0,dt,dr,dz,ep,Er_ref,Ez_ref)
    call check_rz_tmz_E_domain(nr,nz,Er_ref,Ez_ref,Er_num,Ez_num,rep)
    call build_rz_tmz_E_error(nr,nz,Er_ref,Ez_ref,Er_num,Ez_num,err2d)
    call write_pgm_2d('err_2d_rz_tmz_E_step_rz.pgm',nr,nz,err2d)
    call report_print('E-step', rep)
    all_ok = all_ok .and. (rep%n_failed == 0)

    call report_init(rep)
    Er_num = Er0; Ez_num = Ez0; Ha_num = Ha0
    call sub_E01_fdtd_2d_rz_tmz_H(0,nr,0,nz,0,nr-1,0,nz-1,Ha_num,Er_num,Ez_num,dt,dr,dz,mu)

    Ha_ref = Ha0
    call ref_update_rz_tmz_H(nr,nz,0,nr-1,0,nz-1,Ha0,Er0,Ez0,dt,dr,dz,mu,Ha_ref)
    call check_rz_tmz_H_domain(nr,nz,Ha_ref,Ha_num,rep)
    call build_rz_tmz_H_error(nr,nz,Ha_ref,Ha_num,err2d)
    call write_pgm_2d('err_2d_rz_tmz_H_step_rz.pgm',nr,nz,err2d)
    call report_print('H-step', rep)
    all_ok = all_ok .and. (rep%n_failed == 0)

    call report_init(rep)
    Er_num = Er0; Ez_num = Ez0; Ha_num = Ha0
    call sub_E01_fdtd_2d_rz_tmz_E(0,nr,0,nz,0,nr-1,1,nz-1,Ha_num,Er_num,Ez_num,dt,dr,dz,ep)
    call sub_E01_fdtd_2d_rz_tmz_H(0,nr,0,nz,0,nr-1,0,nz-1,Ha_num,Er_num,Ez_num,dt,dr,dz,mu)

    Er_ref = Er0; Ez_ref = Ez0; Ha_ref = Ha0
    call ref_update_rz_tmz_E(nr,nz,0,nr-1,1,nz-1,Ha0,Er0,Ez0,dt,dr,dz,ep,Er_ref,Ez_ref)
    call ref_update_rz_tmz_H(nr,nz,0,nr-1,0,nz-1,Ha0,Er_ref,Ez_ref,dt,dr,dz,mu,Ha_ref)

    call check_rz_tmz_E_domain(nr,nz,Er_ref,Ez_ref,Er_num,Ez_num,rep)
    call check_rz_tmz_H_domain(nr,nz,Ha_ref,Ha_num,rep)
    call build_rz_tmz_full_error(nr,nz,Er_ref,Ez_ref,Ha_ref,Er_num,Ez_num,Ha_num,err2d)
    call write_pgm_2d('err_2d_rz_tmz_full_step_rz.pgm',nr,nz,err2d)
    call report_print('Full-step (E then H)', rep)
    all_ok = all_ok .and. (rep%n_failed == 0)

    if (all_ok) then
        write(*,'(A)') 'RESULT: PASS'
    else
        write(*,'(A)') 'RESULT: FAIL'
        stop 1
    end if

contains

    subroutine init_rz_tmz_fields(nr0,nz0,dr0,dz0,Er,Ez,Ha)
        implicit none
        integer, intent(in) :: nr0, nz0
        real, intent(in) :: dr0, dz0
        real, intent(out) :: Er(0:nr0,0:nz0), Ez(0:nr0,0:nz0), Ha(0:nr0,0:nz0)
        integer :: i, k
        real :: lr, lz, r, z

        lr = real(nr0)*dr0
        lz = real(nz0)*dz0

        do k = 0, nz0
        do i = 0, nr0
            r = (real(i)+0.5)*dr0
            z = real(k)*dz0
            Er(i,k) = r*(0.34 + 0.12*r/lr) * sin(2.0*pi*z/lz + 0.2)

            r = real(i)*dr0
            z = (real(k)+0.5)*dz0
            Ez(i,k) = (1.0 + 0.08*(r/lr)**2) * cos(2.0*pi*z/lz + 0.1) + 0.03*cos(4.0*pi*z/lz)

            r = (real(i)+0.5)*dr0
            z = (real(k)+0.5)*dz0
            Ha(i,k) = r*(0.28 + 0.10*r/lr) * cos(2.0*pi*z/lz + 0.35)
        end do
        end do
    end subroutine init_rz_tmz_fields


    subroutine ref_update_rz_tmz_E(nr0,nz0,il,iu,kl,ku,Ha_old,Er_old,Ez_old,dt0,dr0,dz0,ep0,Er_new,Ez_new)
        implicit none
        integer, intent(in) :: nr0, nz0, il, iu, kl, ku
        real, intent(in) :: dt0, dr0, dz0, ep0
        real, intent(in) :: Ha_old(0:nr0,0:nz0), Er_old(0:nr0,0:nz0), Ez_old(0:nr0,0:nz0)
        real, intent(inout) :: Er_new(0:nr0,0:nz0), Ez_new(0:nr0,0:nz0)
        integer :: i, k
        real :: curl_z, curl_r

        Er_new = Er_old
        Ez_new = Ez_old

        do k = kl, ku
        do i = il, iu
            curl_z = (Ha_old(i,k)-Ha_old(i,k-1))/dz0
            Er_new(i,k) = Er_old(i,k) - dt0/ep0*curl_z
        end do
        end do

        do k = kl, ku
        do i = il, iu
            if (i == 0) then
                Ez_new(i,k) = Ez_old(i,k) + 4.0*dt0/(ep0*dr0)*Ha_old(i,k)
            else
                curl_r = ((real(i)+0.5)*Ha_old(i,k) - (real(i)-0.5)*Ha_old(i-1,k)) / (real(i)*dr0)
                Ez_new(i,k) = Ez_old(i,k) + dt0/ep0*curl_r
            end if
        end do
        end do
    end subroutine ref_update_rz_tmz_E


    subroutine ref_update_rz_tmz_H(nr0,nz0,il,iu,kl,ku,Ha_old,Er_old,Ez_old,dt0,dr0,dz0,mu0,Ha_new)
        implicit none
        integer, intent(in) :: nr0, nz0, il, iu, kl, ku
        real, intent(in) :: dt0, dr0, dz0, mu0
        real, intent(in) :: Ha_old(0:nr0,0:nz0), Er_old(0:nr0,0:nz0), Ez_old(0:nr0,0:nz0)
        real, intent(inout) :: Ha_new(0:nr0,0:nz0)
        integer :: i, k
        real :: dEz_dr, dEr_dz

        Ha_new = Ha_old

        do k = kl, ku
        do i = il, iu
            dEz_dr = (Ez_old(i+1,k)-Ez_old(i,k))/dr0
            dEr_dz = (Er_old(i,k+1)-Er_old(i,k))/dz0
            Ha_new(i,k) = Ha_old(i,k) + dt0/mu0*(dEz_dr-dEr_dz)
        end do
        end do
    end subroutine ref_update_rz_tmz_H


    subroutine check_rz_tmz_E_domain(nr0,nz0,Er_ref,Ez_ref,Er_num,Ez_num,rep)
        implicit none
        integer, intent(in) :: nr0, nz0
        real, intent(in) :: Er_ref(0:nr0,0:nz0), Ez_ref(0:nr0,0:nz0), Er_num(0:nr0,0:nz0), Ez_num(0:nr0,0:nz0)
        type(report_t), intent(inout) :: rep
        integer :: i, k
        real :: tol

        do k = 0, nz0
        do i = 0, nr0
            tol = tol_interior
            if (i <= 1) tol = tol_axis
            if (i == nr0 .or. k == 0 .or. k == nz0) tol = tol_boundary
            call report_check(rep,'domain','Er',i,0,k,Er_ref(i,k),Er_num(i,k),tol,tol)
            call report_check(rep,'domain','Ez',i,0,k,Ez_ref(i,k),Ez_num(i,k),tol,tol)
        end do
        end do
    end subroutine check_rz_tmz_E_domain


    subroutine check_rz_tmz_H_domain(nr0,nz0,Ha_ref,Ha_num,rep)
        implicit none
        integer, intent(in) :: nr0, nz0
        real, intent(in) :: Ha_ref(0:nr0,0:nz0), Ha_num(0:nr0,0:nz0)
        type(report_t), intent(inout) :: rep
        integer :: i, k
        real :: tol

        do k = 0, nz0
        do i = 0, nr0
            tol = tol_interior
            if (i <= 1) tol = tol_axis
            if (i == nr0 .or. k == 0 .or. k == nz0) tol = tol_boundary
            call report_check(rep,'domain','Hphi',i,0,k,Ha_ref(i,k),Ha_num(i,k),tol,tol)
        end do
        end do
    end subroutine check_rz_tmz_H_domain


    subroutine build_rz_tmz_E_error(nr0,nz0,Er_ref,Ez_ref,Er_num,Ez_num,err)
        implicit none
        integer, intent(in) :: nr0, nz0
        real, intent(in) :: Er_ref(0:nr0,0:nz0), Ez_ref(0:nr0,0:nz0), Er_num(0:nr0,0:nz0), Ez_num(0:nr0,0:nz0)
        real, intent(out) :: err(0:nr0,0:nz0)
        integer :: i, k

        do k = 0, nz0
        do i = 0, nr0
            err(i,k) = max(abs(Er_num(i,k)-Er_ref(i,k)), abs(Ez_num(i,k)-Ez_ref(i,k)))
        end do
        end do
    end subroutine build_rz_tmz_E_error


    subroutine build_rz_tmz_H_error(nr0,nz0,Ha_ref,Ha_num,err)
        implicit none
        integer, intent(in) :: nr0, nz0
        real, intent(in) :: Ha_ref(0:nr0,0:nz0), Ha_num(0:nr0,0:nz0)
        real, intent(out) :: err(0:nr0,0:nz0)
        integer :: i, k

        do k = 0, nz0
        do i = 0, nr0
            err(i,k) = abs(Ha_num(i,k)-Ha_ref(i,k))
        end do
        end do
    end subroutine build_rz_tmz_H_error


    subroutine build_rz_tmz_full_error(nr0,nz0,Er_ref,Ez_ref,Ha_ref,Er_num,Ez_num,Ha_num,err)
        implicit none
        integer, intent(in) :: nr0, nz0
        real, intent(in) :: Er_ref(0:nr0,0:nz0), Ez_ref(0:nr0,0:nz0), Ha_ref(0:nr0,0:nz0)
        real, intent(in) :: Er_num(0:nr0,0:nz0), Ez_num(0:nr0,0:nz0), Ha_num(0:nr0,0:nz0)
        real, intent(out) :: err(0:nr0,0:nz0)
        integer :: i, k

        do k = 0, nz0
        do i = 0, nr0
            err(i,k) = max(abs(Er_num(i,k)-Er_ref(i,k)), abs(Ez_num(i,k)-Ez_ref(i,k)))
            err(i,k) = max(err(i,k), abs(Ha_num(i,k)-Ha_ref(i,k)))
        end do
        end do
    end subroutine build_rz_tmz_full_error

end program test_2d_rz_tmz_single_step
