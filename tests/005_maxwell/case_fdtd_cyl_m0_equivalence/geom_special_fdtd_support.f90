module geom_special_fdtd_support
    implicit none

    integer, parameter :: CLOSURE_COPY = 1
    integer, parameter :: CLOSURE_RWEIGHT = 2
    integer, parameter :: CLOSURE_EXACT = 3

contains

    real function pi_val()
        implicit none
        pi_val = acos(-1.0)
    end function pi_val


    subroutine init_2d_tmz(nr,nz,dr,dz,amp,rmax,lz,Er,Ez,Ha)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(in) :: dr, dz, amp, rmax, lz
        real, intent(inout) :: Er(0:nr,0:nz), Ez(0:nr,0:nz), Ha(0:nr,0:nz)
        integer :: i, k
        real :: r1, r0, z0, zh, f1, f0, kz

        kz = 2.0*pi_val()/lz
        Er = 0.0
        Ez = 0.0
        Ha = 0.0

        do k = 0, nz
        do i = 0, nr
            r1 = (real(i)+0.5)*dr
            r0 = real(i)*dr
            z0 = real(k)*dz
            zh = (real(k)+0.5)*dz
            f1 = max(0.0, 1.0-(r1/rmax)**2)
            f0 = max(0.0, 1.0-(r0/rmax)**2)

            Er(i,k) = amp*r1*f1*sin(kz*z0)
            Ez(i,k) = amp*(f0**2)*cos(kz*zh)
            Ha(i,k) = amp*r1*f1*cos(kz*zh)
        end do
        end do
    end subroutine init_2d_tmz


    subroutine fill_periodic_z_2d(nr,nz,A)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(inout) :: A(0:nr,0:nz)
        integer :: i

        do i = 0, nr
            A(i,0) = A(i,nz-1)
            A(i,nz) = A(i,1)
        end do
    end subroutine fill_periodic_z_2d


    subroutine fill_outer_copy_2d(nr,nz,A)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(inout) :: A(0:nr,0:nz)
        integer :: k

        do k = 0, nz
            A(nr,k) = A(nr-1,k)
        end do
    end subroutine fill_outer_copy_2d


    subroutine fill_2d_tmz_h(nr,nz,Ha)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(inout) :: Ha(0:nr,0:nz)
        call fill_periodic_z_2d(nr,nz,Ha)
        call fill_outer_copy_2d(nr,nz,Ha)
    end subroutine fill_2d_tmz_h


    subroutine fill_2d_tmz_e(nr,nz,Er,Ez)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(inout) :: Er(0:nr,0:nz), Ez(0:nr,0:nz)
        call fill_periodic_z_2d(nr,nz,Er)
        call fill_periodic_z_2d(nr,nz,Ez)
        call fill_outer_copy_2d(nr,nz,Er)
        call fill_outer_copy_2d(nr,nz,Ez)
    end subroutine fill_2d_tmz_e


    subroutine fill_2d_tmz_all(nr,nz,Er,Ez,Ha)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(inout) :: Er(0:nr,0:nz), Ez(0:nr,0:nz), Ha(0:nr,0:nz)
        call fill_2d_tmz_h(nr,nz,Ha)
        call fill_2d_tmz_e(nr,nz,Er,Ez)
    end subroutine fill_2d_tmz_all


    subroutine init_2d_tez(nr,nz,dr,dz,amp,rmax,lz,Ephi,Hr,Hz)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(in) :: dr, dz, amp, rmax, lz
        real, intent(inout) :: Ephi(0:nr,0:nz), Hr(0:nr,0:nz), Hz(0:nr,0:nz)
        integer :: i, k
        real :: r0, r1, z0, zh, f0, f1, kz

        kz = 2.0*pi_val()/lz
        Ephi = 0.0
        Hr = 0.0
        Hz = 0.0

        do k = 0, nz
        do i = 0, nr
            r0 = real(i)*dr
            r1 = (real(i)+0.5)*dr
            z0 = real(k)*dz
            zh = (real(k)+0.5)*dz
            f0 = max(0.0, 1.0-(r0/rmax)**2)
            f1 = max(0.0, 1.0-(r1/rmax)**2)

            Ephi(i,k) = amp*r0*f0*sin(kz*z0)
            Hr(i,k) = amp*r0*f0*cos(kz*zh)
            Hz(i,k) = amp*(f1**2)*sin(kz*z0)
        end do
        end do

        Ephi(0,:) = 0.0
        Hr(0,:) = 0.0
    end subroutine init_2d_tez


    subroutine fill_2d_tez_h(nr,nz,Hr,Hz)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(inout) :: Hr(0:nr,0:nz), Hz(0:nr,0:nz)
        call fill_periodic_z_2d(nr,nz,Hr)
        call fill_periodic_z_2d(nr,nz,Hz)
        call fill_outer_copy_2d(nr,nz,Hr)
        call fill_outer_copy_2d(nr,nz,Hz)
        Hr(0,:) = 0.0
    end subroutine fill_2d_tez_h


    subroutine fill_2d_tez_e(nr,nz,Ephi)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(inout) :: Ephi(0:nr,0:nz)
        call fill_periodic_z_2d(nr,nz,Ephi)
        call fill_outer_copy_2d(nr,nz,Ephi)
        Ephi(0,:) = 0.0
    end subroutine fill_2d_tez_e


    subroutine fill_2d_tez_all(nr,nz,Ephi,Hr,Hz)
        implicit none
        integer, intent(in) :: nr, nz
        real, intent(inout) :: Ephi(0:nr,0:nz), Hr(0:nr,0:nz), Hz(0:nr,0:nz)
        call fill_2d_tez_h(nr,nz,Hr,Hz)
        call fill_2d_tez_e(nr,nz,Ephi)
    end subroutine fill_2d_tez_all


    subroutine init_3d_m0(nr,nphi,nz,dr,dz,amp,rmax,lz,Er,Ephi,Ez,Hr,Hphi,Hz)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(in) :: dr, dz, amp, rmax, lz
        real, intent(inout) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)
        real, intent(inout) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)
        integer :: i, j, k
        real :: r1, r0, z0, zh, f1, f0, kz

        kz = 2.0*pi_val()/lz
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
            f1 = max(0.0, 1.0-(r1/rmax)**2)
            f0 = max(0.0, 1.0-(r0/rmax)**2)

            Er(i,j,k) = amp*r1*f1*sin(kz*z0)
            Ephi(i,j,k) = amp*r0*f0*cos(kz*z0)
            Ez(i,j,k) = amp*(f0**2)*sin(kz*zh)
            Hr(i,j,k) = amp*r0*f0*cos(kz*zh)
            Hphi(i,j,k) = amp*r1*f1*sin(kz*zh)
            Hz(i,j,k) = amp*(f1**2)*cos(kz*z0)
        end do
        end do
        end do

        call enforce_hr_axis_3d(nr,nphi,nz,Hr,Hphi)
        call enforce_e_axis_3d(nr,nphi,nz,Er,Ephi)
    end subroutine init_3d_m0


    subroutine init_3d_m1(nr,nphi,nz,dr,dphi,dz,amp,rmax,lz,Er,Ephi,Ez,Hr,Hphi,Hz)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(in) :: dr, dphi, dz, amp, rmax, lz
        real, intent(inout) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)
        real, intent(inout) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)
        integer :: i, j, k
        real :: r1, r0, z0, zh, phi0, phih, g1, g0, kz

        kz = 2.0*pi_val()/lz
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
            g1 = r1*max(0.0, 1.0-(r1/rmax)**2)
            g0 = r0*max(0.0, 1.0-(r0/rmax)**2)

            Er(i,j,k) = amp*g1*sin(kz*z0)*cos(phi0)
            Ephi(i,j,k) = amp*g0*sin(kz*z0)*sin(phih)
            Ez(i,j,k) = amp*g0*cos(kz*zh)*cos(phi0)
            Hr(i,j,k) = amp*g0*cos(kz*zh)*cos(phih)
            Hphi(i,j,k) = -amp*g1*cos(kz*zh)*sin(phi0)
            Hz(i,j,k) = amp*g1*sin(kz*z0)*cos(phih)
        end do
        end do
        end do

        call enforce_hr_axis_3d(nr,nphi,nz,Hr,Hphi)
        call enforce_e_axis_3d(nr,nphi,nz,Er,Ephi)
    end subroutine init_3d_m1


    subroutine fill_periodic_phi_3d(nr,nphi,nz,A)
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
    end subroutine fill_periodic_phi_3d


    subroutine fill_periodic_z_3d(nr,nphi,nz,A)
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
    end subroutine fill_periodic_z_3d


    subroutine fill_outer_3d_scalar(nr,nphi,nz,A,is_half,closure_mode,time,is_m1,comp_id, &
        dr,dphi,dz,rmax,lz,amp)
        implicit none
        integer, intent(in) :: nr, nphi, nz, closure_mode, comp_id
        logical, intent(in) :: is_half, is_m1
        real, intent(in) :: time, dr, dphi, dz, rmax, lz, amp
        real, intent(inout) :: A(0:nr,0:nphi+1,0:nz)

        integer :: j, k
        real :: ratio

        select case (closure_mode)
        case (CLOSURE_COPY)
            do k = 0, nz
            do j = 0, nphi+1
                A(nr,j,k) = A(nr-1,j,k)
            end do
            end do

        case (CLOSURE_RWEIGHT)
            if (is_half) then
                ratio = (real(nr)-0.5)/(real(nr)+0.5)
            else
                ratio = (real(nr)-1.0)/real(nr)
            end if
            do k = 0, nz
            do j = 0, nphi+1
                A(nr,j,k) = ratio*A(nr-1,j,k)
            end do
            end do

        case (CLOSURE_EXACT)
            if (.not. is_m1) then
                do k = 0, nz
                do j = 0, nphi+1
                    A(nr,j,k) = A(nr-1,j,k)
                end do
                end do
            else
                do k = 0, nz
                do j = 0, nphi+1
                    A(nr,j,k) = exact_m1_component(comp_id,nr,j,k,time,dr,dphi,dz,rmax,lz,amp)
                end do
                end do
            end if
        end select
    end subroutine fill_outer_3d_scalar


    real function exact_m1_component(comp_id,i,j,k,time,dr,dphi,dz,rmax,lz,amp)
        implicit none
        integer, intent(in) :: comp_id, i, j, k
        real, intent(in) :: time, dr, dphi, dz, rmax, lz, amp
        real :: r0, r1, z0, zh, phi0, phih, g0, g1, kz, omega

        r0 = real(i)*dr
        r1 = (real(i)+0.5)*dr
        z0 = real(k)*dz
        zh = (real(k)+0.5)*dz
        phi0 = (real(j)-1.0)*dphi
        phih = (real(j)-0.5)*dphi
        g0 = r0*max(0.0, 1.0-(r0/rmax)**2)
        g1 = r1*max(0.0, 1.0-(r1/rmax)**2)
        kz = 2.0*pi_val()/lz
        omega = 2.0*pi_val()

        select case (comp_id)
        case (1)
            exact_m1_component = amp*g1*sin(kz*z0)*cos(phi0)*cos(omega*time)
        case (2)
            exact_m1_component = amp*g0*sin(kz*z0)*sin(phih)*cos(omega*time)
        case (3)
            exact_m1_component = amp*g0*cos(kz*zh)*cos(phi0)*cos(omega*time)
        case (4)
            exact_m1_component = amp*g0*cos(kz*zh)*cos(phih)*sin(omega*time)
        case (5)
            exact_m1_component = -amp*g1*cos(kz*zh)*sin(phi0)*sin(omega*time)
        case (6)
            exact_m1_component = amp*g1*sin(kz*z0)*cos(phih)*sin(omega*time)
        case default
            exact_m1_component = 0.0
        end select
    end function exact_m1_component


    subroutine enforce_hr_axis_3d(nr,nphi,nz,Hr,Hphi)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(inout) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz)
        integer :: j, k

        do k = 0, nz
        do j = 1, nphi
            Hr(0,j,k) = Hphi(0,j,k)
        end do
        end do
    end subroutine enforce_hr_axis_3d


    subroutine enforce_e_axis_3d(nr,nphi,nz,Er,Ephi)
        implicit none
        integer, intent(in) :: nr, nphi, nz
        real, intent(inout) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz)
        integer :: j, k

        do k = 0, nz
        do j = 1, nphi
            Ephi(0,j,k) = Er(0,j,k)
        end do
        end do
    end subroutine enforce_e_axis_3d


    subroutine fill_3d_h(nr,nphi,nz,Hr,Hphi,Hz,closure_mode,time,is_m1,dr,dphi,dz,rmax,lz,amp)
        implicit none
        integer, intent(in) :: nr, nphi, nz, closure_mode
        logical, intent(in) :: is_m1
        real, intent(in) :: time, dr, dphi, dz, rmax, lz, amp
        real, intent(inout) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)

        call fill_periodic_phi_3d(nr,nphi,nz,Hr)
        call fill_periodic_phi_3d(nr,nphi,nz,Hphi)
        call fill_periodic_phi_3d(nr,nphi,nz,Hz)
        call fill_periodic_z_3d(nr,nphi,nz,Hr)
        call fill_periodic_z_3d(nr,nphi,nz,Hphi)
        call fill_periodic_z_3d(nr,nphi,nz,Hz)

        call fill_outer_3d_scalar(nr,nphi,nz,Hr,.false.,closure_mode,time,is_m1,4,dr,dphi,dz,rmax,lz,amp)
        call fill_outer_3d_scalar(nr,nphi,nz,Hphi,.true.,closure_mode,time,is_m1,5,dr,dphi,dz,rmax,lz,amp)
        call fill_outer_3d_scalar(nr,nphi,nz,Hz,.true.,closure_mode,time,is_m1,6,dr,dphi,dz,rmax,lz,amp)

        call enforce_hr_axis_3d(nr,nphi,nz,Hr,Hphi)
    end subroutine fill_3d_h


    subroutine fill_3d_e(nr,nphi,nz,Er,Ephi,Ez,closure_mode,time,is_m1,dr,dphi,dz,rmax,lz,amp)
        implicit none
        integer, intent(in) :: nr, nphi, nz, closure_mode
        logical, intent(in) :: is_m1
        real, intent(in) :: time, dr, dphi, dz, rmax, lz, amp
        real, intent(inout) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)

        call fill_periodic_phi_3d(nr,nphi,nz,Er)
        call fill_periodic_phi_3d(nr,nphi,nz,Ephi)
        call fill_periodic_phi_3d(nr,nphi,nz,Ez)
        call fill_periodic_z_3d(nr,nphi,nz,Er)
        call fill_periodic_z_3d(nr,nphi,nz,Ephi)
        call fill_periodic_z_3d(nr,nphi,nz,Ez)

        call fill_outer_3d_scalar(nr,nphi,nz,Er,.true.,closure_mode,time,is_m1,1,dr,dphi,dz,rmax,lz,amp)
        call fill_outer_3d_scalar(nr,nphi,nz,Ephi,.false.,closure_mode,time,is_m1,2,dr,dphi,dz,rmax,lz,amp)
        call fill_outer_3d_scalar(nr,nphi,nz,Ez,.false.,closure_mode,time,is_m1,3,dr,dphi,dz,rmax,lz,amp)

        call enforce_e_axis_3d(nr,nphi,nz,Er,Ephi)
    end subroutine fill_3d_e


    subroutine fill_3d_all(nr,nphi,nz,Er,Ephi,Ez,Hr,Hphi,Hz,closure_mode,time,is_m1,dr,dphi,dz,rmax,lz,amp)
        implicit none
        integer, intent(in) :: nr, nphi, nz, closure_mode
        logical, intent(in) :: is_m1
        real, intent(in) :: time, dr, dphi, dz, rmax, lz, amp
        real, intent(inout) :: Er(0:nr,0:nphi+1,0:nz), Ephi(0:nr,0:nphi+1,0:nz), Ez(0:nr,0:nphi+1,0:nz)
        real, intent(inout) :: Hr(0:nr,0:nphi+1,0:nz), Hphi(0:nr,0:nphi+1,0:nz), Hz(0:nr,0:nphi+1,0:nz)

        call fill_3d_h(nr,nphi,nz,Hr,Hphi,Hz,closure_mode,time,is_m1,dr,dphi,dz,rmax,lz,amp)
        call fill_3d_e(nr,nphi,nz,Er,Ephi,Ez,closure_mode,time,is_m1,dr,dphi,dz,rmax,lz,amp)
    end subroutine fill_3d_all

end module geom_special_fdtd_support

