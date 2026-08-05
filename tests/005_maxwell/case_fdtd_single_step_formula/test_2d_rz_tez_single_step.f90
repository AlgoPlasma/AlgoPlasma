program test_2d_rz_tez_single_step

    use mod_E01_fdtd_2d_rz_tez
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

    real :: Ephi0(0:nr,0:nz), Hr0(0:nr,0:nz), Hz0(0:nr,0:nz)
    real :: Ephi_num(0:nr,0:nz), Hr_num(0:nr,0:nz), Hz_num(0:nr,0:nz)
    real :: Ephi_ref(0:nr,0:nz), Hr_ref(0:nr,0:nz), Hz_ref(0:nr,0:nz)
    real :: err2d(0:nr,0:nz)
    type(report_t) :: rep
    logical :: all_ok

    all_ok = .true.
    call init_rz_tez_fields(nr,nz,dr,dz,Ephi0,Hr0,Hz0)

    write(*,'(A)') '=== 2D Cylindrical (r-z) TEz FDTD Single-Step Formula Test ==='

    call report_init(rep)
    Ephi_num = Ephi0; Hr_num = Hr0; Hz_num = Hz0
    call sub_E01_fdtd_2d_rz_tez_E(0,nr,0,nz,0,nr-1,1,nz-1,Ephi_num,Hr_num,Hz_num,dt,dr,dz,ep)

    Ephi_ref = Ephi0
    call ref_update_rz_tez_E(nr,nz,0,nr-1,1,nz-1,Ephi0,Hr0,Hz0,dt,dr,dz,ep,Ephi_ref)
    call check_rz_tez_E_domain(nr,nz,Ephi_ref,Ephi_num,rep)
    call build_rz_tez_E_error(nr,nz,Ephi_ref,Ephi_num,err2d)
    call write_pgm_2d('err_2d_rz_tez_E_step_rz.pgm',nr,nz,err2d)
    call report_print('E-step', rep)
    all_ok = all_ok .and. (rep%n_failed == 0)

    call report_init(rep)
    Ephi_num = Ephi0; Hr_num = Hr0; Hz_num = Hz0
    call sub_E01_fdtd_2d_rz_tez_H(0,nr,0,nz,0,nr-1,0,nz-1,Ephi_num,Hr_num,Hz_num,dt,dr,dz,mu)

    Hr_ref = Hr0; Hz_ref = Hz0
    call ref_update_rz_tez_H(nr,nz,0,nr-1,0,nz-1,Ephi0,Hr0,Hz0,dt,dr,dz,mu,Hr_ref,Hz_ref)
    call check_rz_tez_H_domain(nr,nz,Hr_ref,Hz_ref,Hr_num,Hz_num,rep)
    call build_rz_tez_H_error(nr,nz,Hr_ref,Hz_ref,Hr_num,Hz_num,err2d)
    call write_pgm_2d('err_2d_rz_tez_H_step_rz.pgm',nr,nz,err2d)
    call report_print('H-step', rep)
    all_ok = all_ok .and. (rep%n_failed == 0)

    call report_init(rep)
    Ephi_num = Ephi0; Hr_num = Hr0; Hz_num = Hz0
    call sub_E01_fdtd_2d_rz_tez_E(0,nr,0,nz,0,nr-1,1,nz-1,Ephi_num,Hr_num,Hz_num,dt,dr,dz,ep)
    call sub_E01_fdtd_2d_rz_tez_H(0,nr,0,nz,0,nr-1,0,nz-1,Ephi_num,Hr_num,Hz_num,dt,dr,dz,mu)

    Ephi_ref = Ephi0; Hr_ref = Hr0; Hz_ref = Hz0
    call ref_update_rz_tez_E(nr,nz,0,nr-1,1,nz-1,Ephi0,Hr0,Hz0,dt,dr,dz,ep,Ephi_ref)
    call ref_update_rz_tez_H(nr,nz,0,nr-1,0,nz-1,Ephi_ref,Hr0,Hz0,dt,dr,dz,mu,Hr_ref,Hz_ref)
    call check_rz_tez_E_domain(nr,nz,Ephi_ref,Ephi_num,rep)
    call check_rz_tez_H_domain(nr,nz,Hr_ref,Hz_ref,Hr_num,Hz_num,rep)
    call build_rz_tez_full_error(nr,nz,Ephi_ref,Hr_ref,Hz_ref,Ephi_num,Hr_num,Hz_num,err2d)
    call write_pgm_2d('err_2d_rz_tez_full_step_rz.pgm',nr,nz,err2d)
    call report_print('Full-step (E then H)', rep)
    all_ok = all_ok .and. (rep%n_failed == 0)

    if (all_ok) then
        write(*,'(A)') 'RESULT: PASS'
    else
        write(*,'(A)') 'RESULT: FAIL'
        stop 1
    end if

contains

    subroutine init_rz_tez_fields(nr0,nz0,dr0,dz0,Ephi,Hr,Hz)
        implicit none
        integer, intent(in) :: nr0, nz0
        real, intent(in) :: dr0, dz0
        real, intent(out) :: Ephi(0:nr0,0:nz0), Hr(0:nr0,0:nz0), Hz(0:nr0,0:nz0)
        integer :: i, k
        real :: lr, lz, r, z

        lr = real(nr0)*dr0
        lz = real(nz0)*dz0

        do k = 0, nz0
        do i = 0, nr0
            r = real(i)*dr0
            z = (real(k)+0.5)*dz0
            Ephi(i,k) = r*(0.25 + 0.09*r/lr) * sin(2.0*pi*z/lz + 0.30)

            r = real(i)*dr0
            z = (real(k)+0.5)*dz0
            Hr(i,k) = r*(0.18 + 0.05*r/lr) * cos(2.0*pi*z/lz + 0.20)

            r = (real(i)+0.5)*dr0
            z = real(k)*dz0
            Hz(i,k) = (0.72 + 0.06*(r/lr)**2) * sin(2.0*pi*z/lz + 0.15)
        end do
        end do
    end subroutine init_rz_tez_fields


    subroutine ref_update_rz_tez_E(nr0,nz0,il,iu,kl,ku,Ephi_old,Hr_old,Hz_old,dt0,dr0,dz0,ep0,Ephi_new)
        implicit none
        integer, intent(in) :: nr0, nz0, il, iu, kl, ku
        real, intent(in) :: dt0, dr0, dz0, ep0
        real, intent(in) :: Ephi_old(0:nr0,0:nz0), Hr_old(0:nr0,0:nz0), Hz_old(0:nr0,0:nz0)
        real, intent(inout) :: Ephi_new(0:nr0,0:nz0)
        integer :: i, k
        real :: term_z, term_r

        Ephi_new = Ephi_old

        do k = kl, ku
        do i = il, iu
            if (i == 0) then
                Ephi_new(i,k) = 0.0
            else
                term_z = (Hr_old(i,k)-Hr_old(i,k-1))/dz0
                term_r = (Hz_old(i,k)-Hz_old(i-1,k))/dr0
                Ephi_new(i,k) = Ephi_old(i,k) + dt0/ep0*(term_z-term_r)
            end if
        end do
        end do
    end subroutine ref_update_rz_tez_E


    subroutine ref_update_rz_tez_H(nr0,nz0,il,iu,kl,ku,Ephi_old,Hr_old,Hz_old,dt0,dr0,dz0,mu0,Hr_new,Hz_new)
        implicit none
        integer, intent(in) :: nr0, nz0, il, iu, kl, ku
        real, intent(in) :: dt0, dr0, dz0, mu0
        real, intent(in) :: Ephi_old(0:nr0,0:nz0), Hr_old(0:nr0,0:nz0), Hz_old(0:nr0,0:nz0)
        real, intent(inout) :: Hr_new(0:nr0,0:nz0), Hz_new(0:nr0,0:nz0)
        integer :: i, k
        real :: ri, riph, rimh, term_r, term_z

        Hr_new = Hr_old
        Hz_new = Hz_old

        do k = kl, ku
        do i = il, iu
            if (i == 0) then
                Hr_new(i,k) = 0.0
            else
                term_z = (Ephi_old(i,k+1)-Ephi_old(i,k))/dz0
                Hr_new(i,k) = Hr_old(i,k) + dt0/mu0*term_z
            end if
        end do
        end do

        do k = kl, ku
        do i = il, iu
            ri = max((real(i)+0.5)*dr0, 0.5*dr0)
            riph = (real(i)+1.0)*dr0
            rimh = real(i)*dr0
            term_r = (riph*Ephi_old(i+1,k)-rimh*Ephi_old(i,k))/(ri*dr0)
            Hz_new(i,k) = Hz_old(i,k) - dt0/mu0*term_r
        end do
        end do
    end subroutine ref_update_rz_tez_H


    subroutine check_rz_tez_E_domain(nr0,nz0,Ephi_ref,Ephi_num,rep)
        implicit none
        integer, intent(in) :: nr0, nz0
        real, intent(in) :: Ephi_ref(0:nr0,0:nz0), Ephi_num(0:nr0,0:nz0)
        type(report_t), intent(inout) :: rep
        integer :: i, k
        real :: tol

        do k = 0, nz0
        do i = 0, nr0
            tol = tol_interior
            if (i <= 1) tol = tol_axis
            if (i == nr0 .or. k == 0 .or. k == nz0) tol = tol_boundary
            call report_check(rep,'domain','Ephi',i,0,k,Ephi_ref(i,k),Ephi_num(i,k),tol,tol)
        end do
        end do
    end subroutine check_rz_tez_E_domain


    subroutine check_rz_tez_H_domain(nr0,nz0,Hr_ref,Hz_ref,Hr_num,Hz_num,rep)
        implicit none
        integer, intent(in) :: nr0, nz0
        real, intent(in) :: Hr_ref(0:nr0,0:nz0), Hz_ref(0:nr0,0:nz0), Hr_num(0:nr0,0:nz0), Hz_num(0:nr0,0:nz0)
        type(report_t), intent(inout) :: rep
        integer :: i, k
        real :: tol

        do k = 0, nz0
        do i = 0, nr0
            tol = tol_interior
            if (i <= 1) tol = tol_axis
            if (i == nr0 .or. k == 0 .or. k == nz0) tol = tol_boundary
            call report_check(rep,'domain','Hr',i,0,k,Hr_ref(i,k),Hr_num(i,k),tol,tol)
            call report_check(rep,'domain','Hz',i,0,k,Hz_ref(i,k),Hz_num(i,k),tol,tol)
        end do
        end do
    end subroutine check_rz_tez_H_domain


    subroutine build_rz_tez_E_error(nr0,nz0,Ephi_ref,Ephi_num,err)
        implicit none
        integer, intent(in) :: nr0, nz0
        real, intent(in) :: Ephi_ref(0:nr0,0:nz0), Ephi_num(0:nr0,0:nz0)
        real, intent(out) :: err(0:nr0,0:nz0)
        integer :: i, k

        do k = 0, nz0
        do i = 0, nr0
            err(i,k) = abs(Ephi_num(i,k)-Ephi_ref(i,k))
        end do
        end do
    end subroutine build_rz_tez_E_error


    subroutine build_rz_tez_H_error(nr0,nz0,Hr_ref,Hz_ref,Hr_num,Hz_num,err)
        implicit none
        integer, intent(in) :: nr0, nz0
        real, intent(in) :: Hr_ref(0:nr0,0:nz0), Hz_ref(0:nr0,0:nz0), Hr_num(0:nr0,0:nz0), Hz_num(0:nr0,0:nz0)
        real, intent(out) :: err(0:nr0,0:nz0)
        integer :: i, k

        do k = 0, nz0
        do i = 0, nr0
            err(i,k) = max(abs(Hr_num(i,k)-Hr_ref(i,k)), abs(Hz_num(i,k)-Hz_ref(i,k)))
        end do
        end do
    end subroutine build_rz_tez_H_error


    subroutine build_rz_tez_full_error(nr0,nz0,Ephi_ref,Hr_ref,Hz_ref,Ephi_num,Hr_num,Hz_num,err)
        implicit none
        integer, intent(in) :: nr0, nz0
        real, intent(in) :: Ephi_ref(0:nr0,0:nz0), Hr_ref(0:nr0,0:nz0), Hz_ref(0:nr0,0:nz0)
        real, intent(in) :: Ephi_num(0:nr0,0:nz0), Hr_num(0:nr0,0:nz0), Hz_num(0:nr0,0:nz0)
        real, intent(out) :: err(0:nr0,0:nz0)
        integer :: i, k

        do k = 0, nz0
        do i = 0, nr0
            err(i,k) = abs(Ephi_num(i,k)-Ephi_ref(i,k))
            err(i,k) = max(err(i,k), abs(Hr_num(i,k)-Hr_ref(i,k)))
            err(i,k) = max(err(i,k), abs(Hz_num(i,k)-Hz_ref(i,k)))
        end do
        end do
    end subroutine build_rz_tez_full_error

end program test_2d_rz_tez_single_step
