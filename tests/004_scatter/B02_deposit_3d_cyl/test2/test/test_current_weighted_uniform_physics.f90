!> @file test_current_weighted_uniform_physics.f90
!> @brief Current deposition test with nonuniform particle weights.
!> @details Particles are sampled uniformly in ``r``, ``phi`` and ``z`` and
!>          assigned ``wp = 2*rp/Rmax*w0`` with ``w0 = 1``. This keeps the
!>          represented physical density uniform in cylindrical volume.
!>          The program deposits ``n0``, advances particles by one small step,
!>          deposits ``Jr``, ``Jphi`` and ``Jz``, deposits ``n1``, and writes
!>          paper-style map files. ``Jr`` is written on half radial indices
!>          ``±(i+1/2)`` without inserting an artificial ``r=0`` column.
!> @author OpenAI (2026/04/16)
program test_current_weighted_uniform_physics

    use, intrinsic :: ieee_arithmetic
    use mod_B02_deposit_charge_3d_cyl
    use mod_B02_deposit_current_3d_cyl
    use mod_B02_average_axis_3d_cyl

    implicit none

    integer,parameter :: Nr = 20,Nphi = 19,Nz = 20
    integer,parameter :: Np_default = 200000000
    real,parameter :: pi = acos(-1.0),two_pi = 2.0*pi
    real,parameter :: Rmax = 1.0,Zmax = 1.0
    real,parameter :: dr = Rmax/real(Nr)
    real,parameter :: dphi = two_pi/real(Nphi+1)
    real,parameter :: dz = Zmax/real(Nz)
    real,parameter :: dt = 0.01
    real,parameter :: vr = 0.001*dr/dt
    real,parameter :: vphi = 0.001*dphi/dt
    real,parameter :: vz = 0.001*dz/dt
    real,parameter :: w0 = 1.0

    real,allocatable :: n0_arr(:,:,:),n1_arr(:,:,:)
    real,allocatable :: jr(:,:,:),jphi(:,:,:),jz(:,:,:)
    integer :: ip,Np
    integer :: i,k,ios,j0,jpi
    real :: ur,uphi,uz,rp0,phip0,zp0,rp1,phip1,zp1,wp
    real :: nbar0,expected_jr,expected_jz,expected_jphi
    real :: div_r,div_phi,div_z,err_local,denom,xi,yi,nanv
    character(len=64) :: arg

    allocate(n0_arr(0:Nr,0:Nphi,0:Nz))
    allocate(n1_arr(0:Nr,0:Nphi,0:Nz))
    allocate(jr(0:Nr,0:Nphi,0:Nz))
    allocate(jphi(0:Nr,0:Nphi,0:Nz))
    allocate(jz(0:Nr,0:Nphi,0:Nz))

    Np = Np_default
    call get_command_argument(1,arg)
    if (len_trim(arg)>0) then
        read(arg,*,iostat=ios) Np
        if (ios/=0) Np = Np_default
    end if

    n0_arr = 0.0
    n1_arr = 0.0
    jr = 0.0
    jphi = 0.0
    jz = 0.0
    nanv = ieee_value(0.0,ieee_quiet_nan)

    call random_seed()

    do ip = 1,Np
        call random_number(ur)
        call random_number(uphi)
        call random_number(uz)

        rp0 = Rmax*ur
        phip0 = two_pi*uphi
        zp0 = Zmax*uz
        wp = 2.0*rp0/Rmax*w0

        call sub_B02_deposit_charge_3d_cyl(rp0,phip0,zp0,1.0,wp,dr,dphi,dz, &
            Nr,Nphi,Nz,n0_arr)

        rp1 = rp0 + vr*dt
        phip1 = modulo(phip0 + vphi*dt,two_pi)
        zp1 = zp0 + vz*dt

        call sub_B02_deposit_current_3d_cyl(rp0,phip0,zp0,rp1,phip1,zp1,1.0,wp, &
            dr,dphi,dz,Nr,Nphi,Nz,dt,jr,jphi,jz)

        call sub_B02_deposit_charge_3d_cyl(rp1,phip1,zp1,1.0,wp,dr,dphi,dz, &
            Nr,Nphi,Nz,n1_arr)
    end do

    call sub_B02_average_axis_charge_3d_cyl(Nr,Nphi,Nz,n0_arr)
    call sub_B02_average_axis_charge_3d_cyl(Nr,Nphi,Nz,n1_arr)
    call sub_B02_average_axis_jz_3d_cyl(Nr,Nphi,Nz,jz)

    nbar0 = real(Np)*w0/pi
    expected_jr = vr*nbar0
    expected_jz = vz*nbar0
    j0 = 0
    jpi = (Nphi+1)/2

    open(10,file='current_weighted_jr_map.dat',status='replace')
    do i = Nr - 1,0,-1
        yi = -(real(i) + 0.5)
        do k = 0,Nz
            xi = real(k)
            write(10,'(3(es24.16,1x))') xi,yi,jr(i,jpi,k)/expected_jr
        end do
        write(10,*)
    end do
    do i = 0,Nr - 1
        yi = real(i) + 0.5
        do k = 0,Nz
            xi = real(k)
            write(10,'(3(es24.16,1x))') xi,yi,jr(i,j0,k)/expected_jr
        end do
        write(10,*)
    end do
    close(10)

    open(11,file='current_weighted_jphi_map.dat',status='replace')
    do i = Nr,1,-1
        yi = -real(i)
        expected_jphi = real(i)*dr*vphi*nbar0
        do k = 0,Nz
            xi = real(k)
            write(11,'(3(es24.16,1x))') xi,yi,jphi(i,jpi,k)/expected_jphi
        end do
        write(11,*)
    end do
    do i = 1,Nr
        yi = real(i)
        expected_jphi = real(i)*dr*vphi*nbar0
        do k = 0,Nz
            xi = real(k)
            write(11,'(3(es24.16,1x))') xi,yi,jphi(i,j0,k)/expected_jphi
        end do
        write(11,*)
    end do
    close(11)

    open(12,file='current_weighted_jz_map.dat',status='replace')
    do i = Nr,1,-1
        yi = -real(i)
        do k = 0,Nz - 1
            xi = real(k)
            write(12,'(3(es24.16,1x))') xi,yi,jz(i,jpi,k)/expected_jz
        end do
        write(12,*)
    end do
    yi = 0.0
    do k = 0,Nz - 1
        xi = real(k)
        write(12,'(3(es24.16,1x))') xi,yi,jz(0,j0,k)/expected_jz
    end do
    write(12,*)
    do i = 1,Nr
        yi = real(i)
        do k = 0,Nz - 1
            xi = real(k)
            write(12,'(3(es24.16,1x))') xi,yi,jz(i,j0,k)/expected_jz
        end do
        write(12,*)
    end do
    close(12)

    open(13,file='current_weighted_error_map.dat',status='replace')
    do i = Nr - 1,1,-1
        yi = -real(i)
        do k = 1,Nz - 1
            xi = real(k)
            div_r = ((real(i)+0.5)*dr*jr(i,jpi,k) - &
                (real(i)-0.5)*dr*jr(i-1,jpi,k)) / (real(i)*dr*dr)
            div_phi = (jphi(i,jpi,k) - jphi(i,modulo(jpi-1,Nphi+1),k)) / (real(i)*dr*dphi)
            div_z = (jz(i,jpi,k) - jz(i,jpi,k-1))/dz
            denom = n1_arr(i,jpi,k) - n0_arr(i,jpi,k)
            if (abs(denom)>1.0e-30) then
                err_local = ((denom/dt) + div_r + div_phi + div_z) * dt/denom
                write(13,'(3(es24.16,1x))') xi,yi,log10(max(abs(err_local),1.0e-30))
            else
                write(13,'(3(es24.16,1x))') xi,yi,nanv
            end if
        end do
        write(13,*)
    end do
    do i = 1,Nr - 1
        yi = real(i)
        do k = 1,Nz - 1
            xi = real(k)
            div_r = ((real(i)+0.5)*dr*jr(i,j0,k) - &
                (real(i)-0.5)*dr*jr(i-1,j0,k)) / (real(i)*dr*dr)
            div_phi = (jphi(i,j0,k) - jphi(i,modulo(j0-1,Nphi+1),k)) / (real(i)*dr*dphi)
            div_z = (jz(i,j0,k) - jz(i,j0,k-1))/dz
            denom = n1_arr(i,j0,k) - n0_arr(i,j0,k)
            if (abs(denom)>1.0e-30) then
                err_local = ((denom/dt) + div_r + div_phi + div_z) * dt/denom
                write(13,'(3(es24.16,1x))') xi,yi,log10(max(abs(err_local),1.0e-30))
            else
                write(13,'(3(es24.16,1x))') xi,yi,nanv
            end if
        end do
        write(13,*)
    end do
    close(13)

    print *, 'Weighted current test finished.'
    print *, 'Sampling: rp = Rmax*U, wp = 2*rp/Rmax*w0, w0 = ',w0
    print *, 'Np used = ',Np
    print *, 'Output:'
    print *, '  current_weighted_jr_map.dat'
    print *, '  current_weighted_jphi_map.dat'
    print *, '  current_weighted_jz_map.dat'
    print *, '  current_weighted_error_map.dat'

    deallocate(n0_arr,n1_arr,jr,jphi,jz)

end program test_current_weighted_uniform_physics
