!> @file test_charge_like_test2.f90
!> @brief Uniform-grid charge deposition test matching the Python script.
!> @details This program uses ``sub_B02_deposit_charge_3d_cyl`` and
!>          ``sub_B02_average_axis_charge_3d_cyl`` from ``B02_deposit_3d_cyl``.
!>          Particles are sampled uniformly in cylindrical volume. After all
!>          particles are deposited, axis values are averaged over ``phi`` and
!>          the output map is written on the signed-``r``/``z`` plane using
!>          ``phi = 0`` and ``phi = pi``.
!> @author Zhijun ZHOU (2026/04/13)
program test_charge_like_test2

    use mod_B02_deposit_charge_3d_cyl
    use mod_B02_average_axis_3d_cyl

    implicit none

    integer,parameter :: Nr = 20
    integer,parameter :: Nphi = 19
    integer,parameter :: Nz = 20
    integer,parameter :: Np_default = 200000000
    real,parameter :: Rmax = 1.0
    real,parameter :: Zmax = 1.0

    real,allocatable :: rho(:,:,:),plot_map(:,:)
    integer :: ip,Np
    integer :: i,k,ios,j0,jpi
    real :: pi,two_pi,dr,dphi,dz
    real :: ur,uphi,uz,rp,phip,zp,n0
    character(len=64) :: arg

    pi = acos(-1.0)
    two_pi = 2.0*pi
    dr = Rmax/real(Nr)
    dphi = two_pi/real(Nphi+1)
    dz = Zmax/real(Nz)

    allocate(rho(0:Nr,0:Nphi,0:Nz))
    allocate(plot_map(-Nr:Nr,0:Nz))

    Np = Np_default
    call get_command_argument(1,arg)
    if (len_trim(arg)>0) then
        read(arg,*,iostat=ios) Np
        if (ios/=0) Np = Np_default
    end if

    rho = 0.0
    call random_seed()

    do ip = 1,Np
        call random_number(ur)
        call random_number(uphi)
        call random_number(uz)

        rp = Rmax*sqrt(ur)
        phip = two_pi*uphi
        zp = Zmax*uz

        call sub_B02_deposit_charge_3d_cyl(rp,phip,zp,1.0,1.0,dr,dphi,dz, &
            Nr,Nphi,Nz,rho)
    end do

    call sub_B02_average_axis_charge_3d_cyl(Nr,Nphi,Nz,rho)

    n0 = real(Np)/pi
    j0 = 0
    jpi = (Nphi+1)/2

    do k = 0,Nz
        plot_map(0,k) = rho(0,j0,k)/n0
        do i = 1,Nr
            plot_map(i,k) = rho(i,j0,k)/n0
            plot_map(-i,k) = rho(i,jpi,k)/n0
        end do
    end do

    open(10,file='density_uniform_map.dat',status='replace')
    do k = 0,Nz
        do i = -Nr,Nr
            write(10,'(3(es24.16,1x))') real(i)*dr,real(k)*dz,plot_map(i,k)
        end do
        write(10,*)
    end do
    close(10)

    open(11,file='density_uniform_axis0.dat',status='replace')
    do k = 0,Nz
        write(11,'(2(es24.16,1x))') real(k)*dz,plot_map(0,k)
    end do
    close(11)

    print *, 'Uniform charge test finished.'
    print *, 'Np used = ',Np
    print *, 'Output: density_uniform_map.dat'

    deallocate(rho,plot_map)

end program test_charge_like_test2
