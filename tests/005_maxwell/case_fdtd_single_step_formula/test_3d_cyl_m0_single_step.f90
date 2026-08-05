program test_3d_cyl_m0_single_step

    use mod_E02_fdtd_3d_cylindrical
    use test_single_step_utils
    implicit none

    integer, parameter :: nr = 12, nphi = 12, nz = 11
    real, parameter :: pi = 3.14159265358979323846
    real, parameter :: dr = 0.06, dz = 0.07, dphi = 2.0*pi/real(nphi)
    real, parameter :: dt = 0.18e-10
    real, parameter :: ep = 8.854187817e-12
    real, parameter :: mu = 1.2566370614e-6
    real, parameter :: tol_interior = 1.0e-11
    real, parameter :: tol_axis = 1.0e-10
    real, parameter :: tol_boundary = 1.0e-10

    real :: Er0(0:nr,0:nphi+1,0:nz), Ephi0(0:nr,0:nphi+1,0:nz), Ez0(0:nr,0:nphi+1,0:nz)
    real :: Hr0(0:nr,0:nphi+1,0:nz), Hphi0(0:nr,0:nphi+1,0:nz), Hz0(0:nr,0:nphi+1,0:nz)
    real :: Er_num(0:nr,0:nphi+1,0:nz), Ephi_num(0:nr,0:nphi+1,0:nz), Ez_num(0:nr,0:nphi+1,0:nz)
    real :: Hr_num(0:nr,0:nphi+1,0:nz), Hphi_num(0:nr,0:nphi+1,0:nz), Hz_num(0:nr,0:nphi+1,0:nz)
    real :: Er_ref(0:nr,0:nphi+1,0:nz), Ephi_ref(0:nr,0:nphi+1,0:nz), Ez_ref(0:nr,0:nphi+1,0:nz)
    real :: Hr_ref(0:nr,0:nphi+1,0:nz), Hphi_ref(0:nr,0:nphi+1,0:nz), Hz_ref(0:nr,0:nphi+1,0:nz)
    real :: err3d(0:nr,0:nphi+1,0:nz), err2d_rz(0:nr,0:nz)
    type(report_t) :: rep
    logical :: all_ok

    all_ok = .true.
    call init_cyl_m0_fields(nr,nphi,nz,dr,dz,dphi,Er0,Ephi0,Ez0,Hr0,Hphi0,Hz0)

    write(*,'(A)') '=== 3D Cylindrical FDTD Single-Step Formula Test (m=0, with axis) ==='

    call report_init(rep)
    Er_num = Er0; Ephi_num = Ephi0; Ez_num = Ez0
    Hr_num = Hr0; Hphi_num = Hphi0; Hz_num = Hz0
    call sub_E02_fdtd_3d_cylindrical_E(0,nr,0,nphi+1,0,nz,0,nr-1,1,nphi,1,nz-1, &
        Er_num,Ephi_num,Ez_num,Hr_num,Hphi_num,Hz_num,dt,dr,dphi,dz,ep)

    Er_ref = Er0; Ephi_ref = Ephi0; Ez_ref = Ez0
    call ref_update_cyl_E(nr,nphi,nz,0,nr-1,1,nphi,1,nz-1, &
        Er0,Ephi0,Ez0,Hr0,Hphi0,Hz0,dt,dr,dphi,dz,ep,Er_ref,Ephi_ref,Ez_ref)
    call check_cyl_E_domain(nr,nphi,nz,Er_ref,Ephi_ref,Ez_ref,Er_num,Ephi_num,Ez_num,rep)
    call build_cyl_E_error(nr,nphi,nz,Er_ref,Ephi_ref,Ez_ref,Er_num,Ephi_num,Ez_num,err3d)
    call project_max_over_j(nr,nphi+1,nz,err3d,err2d_rz)
    call write_pgm_2d('err_3d_cyl_m0_E_step_rz_maxphi.pgm',nr,nz,err2d_rz)
    call report_print('E-step (m=0)', rep)
    all_ok = all_ok .and. (rep%n_failed == 0)

    call report_init(rep)
    Er_num = Er0; Ephi_num = Ephi0; Ez_num = Ez0
    Hr_num = Hr0; Hphi_num = Hphi0; Hz_num = Hz0
    call sub_E02_fdtd_3d_cylindrical_H(0,nr,0,nphi+1,0,nz,0,nr-1,1,nphi,0,nz-1, &
        Er_num,Ephi_num,Ez_num,Hr_num,Hphi_num,Hz_num,dt,dr,dphi,dz,mu)

    Hr_ref = Hr0; Hphi_ref = Hphi0; Hz_ref = Hz0
    call ref_update_cyl_H(nr,nphi,nz,0,nr-1,1,nphi,0,nz-1, &
        Er0,Ephi0,Ez0,Hr0,Hphi0,Hz0,dt,dr,dphi,dz,mu,Hr_ref,Hphi_ref,Hz_ref)
    call check_cyl_H_domain(nr,nphi,nz,Hr_ref,Hphi_ref,Hz_ref,Hr_num,Hphi_num,Hz_num,rep)
    call build_cyl_H_error(nr,nphi,nz,Hr_ref,Hphi_ref,Hz_ref,Hr_num,Hphi_num,Hz_num,err3d)
    call project_max_over_j(nr,nphi+1,nz,err3d,err2d_rz)
    call write_pgm_2d('err_3d_cyl_m0_H_step_rz_maxphi.pgm',nr,nz,err2d_rz)
    call report_print('H-step (m=0)', rep)
    all_ok = all_ok .and. (rep%n_failed == 0)

    call report_init(rep)
    Er_num = Er0; Ephi_num = Ephi0; Ez_num = Ez0
    Hr_num = Hr0; Hphi_num = Hphi0; Hz_num = Hz0
    call sub_E02_fdtd_3d_cylindrical_E(0,nr,0,nphi+1,0,nz,0,nr-1,1,nphi,1,nz-1, &
        Er_num,Ephi_num,Ez_num,Hr_num,Hphi_num,Hz_num,dt,dr,dphi,dz,ep)
    call sub_E02_fdtd_3d_cylindrical_H(0,nr,0,nphi+1,0,nz,0,nr-1,1,nphi,0,nz-1, &
        Er_num,Ephi_num,Ez_num,Hr_num,Hphi_num,Hz_num,dt,dr,dphi,dz,mu)

    Er_ref = Er0; Ephi_ref = Ephi0; Ez_ref = Ez0
    Hr_ref = Hr0; Hphi_ref = Hphi0; Hz_ref = Hz0
    call ref_update_cyl_E(nr,nphi,nz,0,nr-1,1,nphi,1,nz-1, &
        Er0,Ephi0,Ez0,Hr0,Hphi0,Hz0,dt,dr,dphi,dz,ep,Er_ref,Ephi_ref,Ez_ref)
    call ref_update_cyl_H(nr,nphi,nz,0,nr-1,1,nphi,0,nz-1, &
        Er_ref,Ephi_ref,Ez_ref,Hr0,Hphi0,Hz0,dt,dr,dphi,dz,mu,Hr_ref,Hphi_ref,Hz_ref)
    call check_cyl_E_domain(nr,nphi,nz,Er_ref,Ephi_ref,Ez_ref,Er_num,Ephi_num,Ez_num,rep)
    call check_cyl_H_domain(nr,nphi,nz,Hr_ref,Hphi_ref,Hz_ref,Hr_num,Hphi_num,Hz_num,rep)
    call build_cyl_full_error(nr,nphi,nz,Er_ref,Ephi_ref,Ez_ref,Hr_ref,Hphi_ref,Hz_ref, &
        Er_num,Ephi_num,Ez_num,Hr_num,Hphi_num,Hz_num,err3d)
    call project_max_over_j(nr,nphi+1,nz,err3d,err2d_rz)
    call write_pgm_2d('err_3d_cyl_m0_full_step_rz_maxphi.pgm',nr,nz,err2d_rz)
    call report_print('Full-step (E then H, m=0)', rep)
    all_ok = all_ok .and. (rep%n_failed == 0)

    if (all_ok) then
        write(*,'(A)') 'RESULT: PASS'
    else
        write(*,'(A)') 'RESULT: FAIL'
        stop 1
    end if

contains

    subroutine init_cyl_m0_fields(nr0,nphi0,nz0,dr0,dz0,dphi0,Er,Ephi,Ez,Hr,Hphi,Hz)
        implicit none
        integer, intent(in) :: nr0, nphi0, nz0
        real, intent(in) :: dr0, dz0, dphi0
        real, intent(out) :: Er(0:nr0,0:nphi0+1,0:nz0), Ephi(0:nr0,0:nphi0+1,0:nz0), Ez(0:nr0,0:nphi0+1,0:nz0)
        real, intent(out) :: Hr(0:nr0,0:nphi0+1,0:nz0), Hphi(0:nr0,0:nphi0+1,0:nz0), Hz(0:nr0,0:nphi0+1,0:nz0)
        integer :: i, j, k
        real :: lr, lz, r, z

        lr = real(nr0)*dr0
        lz = real(nz0)*dz0

        do k = 0, nz0
        do j = 0, nphi0+1
        do i = 0, nr0
            r = (real(i)+0.5)*dr0
            z = real(k)*dz0
            Er(i,j,k) = r*(0.22 + 0.07*r/lr) * sin(2.0*pi*z/lz + 0.10)

            r = real(i)*dr0
            z = real(k)*dz0
            Ephi(i,j,k) = r*(0.20 + 0.05*r/lr) * cos(2.0*pi*z/lz + 0.25)

            r = real(i)*dr0
            z = (real(k)+0.5)*dz0
            Ez(i,j,k) = (0.90 + 0.06*(r/lr)**2) * cos(2.0*pi*z/lz + 0.40)

            r = real(i)*dr0
            z = (real(k)+0.5)*dz0
            Hr(i,j,k) = r*(0.17 + 0.04*r/lr) * sin(2.0*pi*z/lz + 0.35)

            r = (real(i)+0.5)*dr0
            z = (real(k)+0.5)*dz0
            Hphi(i,j,k) = r*(0.18 + 0.05*r/lr) * cos(2.0*pi*z/lz + 0.15)

            r = (real(i)+0.5)*dr0
            z = real(k)*dz0
            Hz(i,j,k) = (0.65 + 0.04*(r/lr)**2) * sin(2.0*pi*z/lz + 0.20)
        end do
        end do
        end do
    end subroutine init_cyl_m0_fields


    subroutine ref_update_cyl_E(nr0,nphi0,nz0,il,iu,jl,ju,kl,ku, &
        Er_old,Ephi_old,Ez_old,Hr_old,Hphi_old,Hz_old,dt0,dr0,dphi0,dz0,ep0,Er_new,Ephi_new,Ez_new)
        implicit none
        integer, intent(in) :: nr0, nphi0, nz0, il, iu, jl, ju, kl, ku
        real, intent(in) :: dt0, dr0, dphi0, dz0, ep0
        real, intent(in) :: Er_old(0:nr0,0:nphi0+1,0:nz0), Ephi_old(0:nr0,0:nphi0+1,0:nz0), Ez_old(0:nr0,0:nphi0+1,0:nz0)
        real, intent(in) :: Hr_old(0:nr0,0:nphi0+1,0:nz0), Hphi_old(0:nr0,0:nphi0+1,0:nz0), Hz_old(0:nr0,0:nphi0+1,0:nz0)
        real, intent(inout) :: Er_new(0:nr0,0:nphi0+1,0:nz0), Ephi_new(0:nr0,0:nphi0+1,0:nz0), Ez_new(0:nr0,0:nphi0+1,0:nz0)
        integer :: i, j, k, nphi_active
        real :: ri, riph, rimh, term_r, term_phi, term_z
        real :: axis_hphi_avg(0:nz0)

        Er_new = Er_old
        Ephi_new = Ephi_old
        Ez_new = Ez_old
        axis_hphi_avg = 0.0

        if (il == 0) then
            nphi_active = ju-jl+1
            do k = kl, ku
                do j = jl, ju
                    axis_hphi_avg(k) = axis_hphi_avg(k) + Hphi_old(0,j,k)
                end do
                axis_hphi_avg(k) = axis_hphi_avg(k)/real(nphi_active)
            end do
        end if

        do k = kl, ku
        do j = jl, ju
        do i = il, iu
            ri = max((real(i)+0.5)*dr0, 0.5*dr0)
            term_phi = (Hz_old(i,j,k)-Hz_old(i,j-1,k))/(ri*dphi0)
            term_z = (Hphi_old(i,j,k)-Hphi_old(i,j,k-1))/dz0
            Er_new(i,j,k) = Er_old(i,j,k) + dt0/ep0*(term_phi-term_z)
        end do
        end do
        end do

        do k = kl, ku
        do j = jl, ju
        do i = il, iu
            if (i == 0) then
                Ephi_new(i,j,k) = Er_new(i,j,k)
            else
                term_z = (Hr_old(i,j,k)-Hr_old(i,j,k-1))/dz0
                term_r = (Hz_old(i,j,k)-Hz_old(i-1,j,k))/dr0
                Ephi_new(i,j,k) = Ephi_old(i,j,k) + dt0/ep0*(term_z-term_r)
            end if
        end do
        end do
        end do

        do k = kl, ku
        do j = jl, ju
        do i = il, iu
            if (i == 0) then
                Ez_new(i,j,k) = Ez_old(i,j,k) + 4.0*dt0/(ep0*dr0)*axis_hphi_avg(k)
            else
                ri = real(i)*dr0
                riph = (real(i)+0.5)*dr0
                rimh = (real(i)-0.5)*dr0
                term_r = (riph*Hphi_old(i,j,k)-rimh*Hphi_old(i-1,j,k))/(ri*dr0)
                term_phi = (Hr_old(i,j,k)-Hr_old(i,j-1,k))/(ri*dphi0)
                Ez_new(i,j,k) = Ez_old(i,j,k) + dt0/ep0*(term_r-term_phi)
            end if
        end do
        end do
        end do
    end subroutine ref_update_cyl_E


    subroutine ref_update_cyl_H(nr0,nphi0,nz0,il,iu,jl,ju,kl,ku, &
        Er_old,Ephi_old,Ez_old,Hr_old,Hphi_old,Hz_old,dt0,dr0,dphi0,dz0,mu0,Hr_new,Hphi_new,Hz_new)
        implicit none
        integer, intent(in) :: nr0, nphi0, nz0, il, iu, jl, ju, kl, ku
        real, intent(in) :: dt0, dr0, dphi0, dz0, mu0
        real, intent(in) :: Er_old(0:nr0,0:nphi0+1,0:nz0), Ephi_old(0:nr0,0:nphi0+1,0:nz0), Ez_old(0:nr0,0:nphi0+1,0:nz0)
        real, intent(in) :: Hr_old(0:nr0,0:nphi0+1,0:nz0), Hphi_old(0:nr0,0:nphi0+1,0:nz0), Hz_old(0:nr0,0:nphi0+1,0:nz0)
        real, intent(inout) :: Hr_new(0:nr0,0:nphi0+1,0:nz0), Hphi_new(0:nr0,0:nphi0+1,0:nz0), Hz_new(0:nr0,0:nphi0+1,0:nz0)
        integer :: i, j, k
        real :: ri, riph, rimh, term_r, term_phi, term_z

        Hr_new = Hr_old
        Hphi_new = Hphi_old
        Hz_new = Hz_old

        do k = kl, ku
        do j = jl, ju
        do i = il, iu
            if (i == 0) then
                Hr_new(i,j,k) = Hphi_old(i,j,k)
            else
                ri = real(i)*dr0
                term_phi = (Ez_old(i,j+1,k)-Ez_old(i,j,k))/(ri*dphi0)
                term_z = (Ephi_old(i,j,k+1)-Ephi_old(i,j,k))/dz0
                Hr_new(i,j,k) = Hr_old(i,j,k) - dt0/mu0*(term_phi-term_z)
            end if
        end do
        end do
        end do

        do k = kl, ku
        do j = jl, ju
        do i = il, iu
            term_z = (Er_old(i,j,k+1)-Er_old(i,j,k))/dz0
            term_r = (Ez_old(i+1,j,k)-Ez_old(i,j,k))/dr0
            Hphi_new(i,j,k) = Hphi_old(i,j,k) - dt0/mu0*(term_z-term_r)
        end do
        end do
        end do

        do k = kl, ku
        do j = jl, ju
        do i = il, iu
            ri = max((real(i)+0.5)*dr0, 0.5*dr0)
            riph = (real(i)+1.0)*dr0
            rimh = real(i)*dr0
            term_r = (riph*Ephi_old(i+1,j,k)-rimh*Ephi_old(i,j,k))/(ri*dr0)
            term_phi = (Er_old(i,j+1,k)-Er_old(i,j,k))/(ri*dphi0)
            Hz_new(i,j,k) = Hz_old(i,j,k) - dt0/mu0*(term_r-term_phi)
        end do
        end do
        end do

        if (il == 0) then
            do k = kl, ku
            do j = jl, ju
                Hr_new(0,j,k) = Hphi_new(0,j,k)
            end do
            end do
        end if
    end subroutine ref_update_cyl_H


    subroutine check_cyl_E_domain(nr0,nphi0,nz0,Er_ref,Ephi_ref,Ez_ref,Er_num,Ephi_num,Ez_num,rep)
        implicit none
        integer, intent(in) :: nr0, nphi0, nz0
        real, intent(in) :: Er_ref(0:nr0,0:nphi0+1,0:nz0), Ephi_ref(0:nr0,0:nphi0+1,0:nz0), Ez_ref(0:nr0,0:nphi0+1,0:nz0)
        real, intent(in) :: Er_num(0:nr0,0:nphi0+1,0:nz0), Ephi_num(0:nr0,0:nphi0+1,0:nz0), Ez_num(0:nr0,0:nphi0+1,0:nz0)
        type(report_t), intent(inout) :: rep
        integer :: i, j, k
        real :: tol

        do k = 0, nz0
        do j = 0, nphi0+1
        do i = 0, nr0
            tol = tol_interior
            if (i <= 1) tol = tol_axis
            if (i == nr0 .or. j == 0 .or. j == nphi0+1 .or. k == 0 .or. k == nz0) tol = tol_boundary
            call report_check(rep,'domain','Er',i,j,k,Er_ref(i,j,k),Er_num(i,j,k),tol,tol)
            call report_check(rep,'domain','Ephi',i,j,k,Ephi_ref(i,j,k),Ephi_num(i,j,k),tol,tol)
            call report_check(rep,'domain','Ez',i,j,k,Ez_ref(i,j,k),Ez_num(i,j,k),tol,tol)
        end do
        end do
        end do
    end subroutine check_cyl_E_domain


    subroutine check_cyl_H_domain(nr0,nphi0,nz0,Hr_ref,Hphi_ref,Hz_ref,Hr_num,Hphi_num,Hz_num,rep)
        implicit none
        integer, intent(in) :: nr0, nphi0, nz0
        real, intent(in) :: Hr_ref(0:nr0,0:nphi0+1,0:nz0), Hphi_ref(0:nr0,0:nphi0+1,0:nz0), Hz_ref(0:nr0,0:nphi0+1,0:nz0)
        real, intent(in) :: Hr_num(0:nr0,0:nphi0+1,0:nz0), Hphi_num(0:nr0,0:nphi0+1,0:nz0), Hz_num(0:nr0,0:nphi0+1,0:nz0)
        type(report_t), intent(inout) :: rep
        integer :: i, j, k
        real :: tol

        do k = 0, nz0
        do j = 0, nphi0+1
        do i = 0, nr0
            tol = tol_interior
            if (i <= 1) tol = tol_axis
            if (i == nr0 .or. j == 0 .or. j == nphi0+1 .or. k == 0 .or. k == nz0) tol = tol_boundary
            call report_check(rep,'domain','Hr',i,j,k,Hr_ref(i,j,k),Hr_num(i,j,k),tol,tol)
            call report_check(rep,'domain','Hphi',i,j,k,Hphi_ref(i,j,k),Hphi_num(i,j,k),tol,tol)
            call report_check(rep,'domain','Hz',i,j,k,Hz_ref(i,j,k),Hz_num(i,j,k),tol,tol)
        end do
        end do
        end do
    end subroutine check_cyl_H_domain


    subroutine build_cyl_E_error(nr0,nphi0,nz0,Er_ref,Ephi_ref,Ez_ref,Er_num,Ephi_num,Ez_num,err)
        implicit none
        integer, intent(in) :: nr0, nphi0, nz0
        real, intent(in) :: Er_ref(0:nr0,0:nphi0+1,0:nz0), Ephi_ref(0:nr0,0:nphi0+1,0:nz0), Ez_ref(0:nr0,0:nphi0+1,0:nz0)
        real, intent(in) :: Er_num(0:nr0,0:nphi0+1,0:nz0), Ephi_num(0:nr0,0:nphi0+1,0:nz0), Ez_num(0:nr0,0:nphi0+1,0:nz0)
        real, intent(out) :: err(0:nr0,0:nphi0+1,0:nz0)
        integer :: i, j, k

        do k = 0, nz0
        do j = 0, nphi0+1
        do i = 0, nr0
            err(i,j,k) = max(abs(Er_num(i,j,k)-Er_ref(i,j,k)), abs(Ephi_num(i,j,k)-Ephi_ref(i,j,k)))
            err(i,j,k) = max(err(i,j,k), abs(Ez_num(i,j,k)-Ez_ref(i,j,k)))
        end do
        end do
        end do
    end subroutine build_cyl_E_error


    subroutine build_cyl_H_error(nr0,nphi0,nz0,Hr_ref,Hphi_ref,Hz_ref,Hr_num,Hphi_num,Hz_num,err)
        implicit none
        integer, intent(in) :: nr0, nphi0, nz0
        real, intent(in) :: Hr_ref(0:nr0,0:nphi0+1,0:nz0), Hphi_ref(0:nr0,0:nphi0+1,0:nz0), Hz_ref(0:nr0,0:nphi0+1,0:nz0)
        real, intent(in) :: Hr_num(0:nr0,0:nphi0+1,0:nz0), Hphi_num(0:nr0,0:nphi0+1,0:nz0), Hz_num(0:nr0,0:nphi0+1,0:nz0)
        real, intent(out) :: err(0:nr0,0:nphi0+1,0:nz0)
        integer :: i, j, k

        do k = 0, nz0
        do j = 0, nphi0+1
        do i = 0, nr0
            err(i,j,k) = max(abs(Hr_num(i,j,k)-Hr_ref(i,j,k)), abs(Hphi_num(i,j,k)-Hphi_ref(i,j,k)))
            err(i,j,k) = max(err(i,j,k), abs(Hz_num(i,j,k)-Hz_ref(i,j,k)))
        end do
        end do
        end do
    end subroutine build_cyl_H_error


    subroutine build_cyl_full_error(nr0,nphi0,nz0,Er_ref,Ephi_ref,Ez_ref,Hr_ref,Hphi_ref,Hz_ref, &
        Er_num,Ephi_num,Ez_num,Hr_num,Hphi_num,Hz_num,err)
        implicit none
        integer, intent(in) :: nr0, nphi0, nz0
        real, intent(in) :: Er_ref(0:nr0,0:nphi0+1,0:nz0), Ephi_ref(0:nr0,0:nphi0+1,0:nz0), Ez_ref(0:nr0,0:nphi0+1,0:nz0)
        real, intent(in) :: Hr_ref(0:nr0,0:nphi0+1,0:nz0), Hphi_ref(0:nr0,0:nphi0+1,0:nz0), Hz_ref(0:nr0,0:nphi0+1,0:nz0)
        real, intent(in) :: Er_num(0:nr0,0:nphi0+1,0:nz0), Ephi_num(0:nr0,0:nphi0+1,0:nz0), Ez_num(0:nr0,0:nphi0+1,0:nz0)
        real, intent(in) :: Hr_num(0:nr0,0:nphi0+1,0:nz0), Hphi_num(0:nr0,0:nphi0+1,0:nz0), Hz_num(0:nr0,0:nphi0+1,0:nz0)
        real, intent(out) :: err(0:nr0,0:nphi0+1,0:nz0)
        integer :: i, j, k

        do k = 0, nz0
        do j = 0, nphi0+1
        do i = 0, nr0
            err(i,j,k) = abs(Er_num(i,j,k)-Er_ref(i,j,k))
            err(i,j,k) = max(err(i,j,k), abs(Ephi_num(i,j,k)-Ephi_ref(i,j,k)))
            err(i,j,k) = max(err(i,j,k), abs(Ez_num(i,j,k)-Ez_ref(i,j,k)))
            err(i,j,k) = max(err(i,j,k), abs(Hr_num(i,j,k)-Hr_ref(i,j,k)))
            err(i,j,k) = max(err(i,j,k), abs(Hphi_num(i,j,k)-Hphi_ref(i,j,k)))
            err(i,j,k) = max(err(i,j,k), abs(Hz_num(i,j,k)-Hz_ref(i,j,k)))
        end do
        end do
        end do
    end subroutine build_cyl_full_error

end program test_3d_cyl_m0_single_step
