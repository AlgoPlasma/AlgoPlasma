!> @file test_charge_weighted_uniform_physics.f90
!> @brief Charge deposition test with nonuniform particle weights.
!> @details Particles are sampled uniformly in ``r``, ``phi`` and ``z``,
!>          while each macro-particle weight is set to
!>          ``wp = 2*rp/Rmax*w0`` with ``w0 = 1``. This combination should
!>          still represent a physically uniform density in the cylindrical
!>          volume. Axis values are averaged using the B02 helper routine.
!> @author OpenAI (2026/04/16)
program test_charge_weighted_uniform_physics

    use mod_B02_deposit_charge_3d_cyl
    use mod_B02_average_axis_3d_cyl

    implicit none

    integer,parameter :: Nr = 20,Nphi = 19,Nz = 20
    integer,parameter :: Np_default = 200000000
    real,parameter :: Rmax = 1.0,Zmax = 1.0

    real,allocatable :: rho(:,:,:),plot_map(:,:)
    integer :: ip,Np
    integer :: i,k,ios,j0,jpi
    real :: pi,two_pi,dr,dphi,dz,w0
    real :: ur,uphi,uz,rp,phip,zp,wp,n0
    character(len=64) :: arg

    pi = acos(-1.0)
    two_pi = 2.0*pi
    dr = Rmax/real(Nr)
    dphi = two_pi/real(Nphi+1)
    dz = Zmax/real(Nz)
    w0 = 1.0

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

        rp = Rmax*ur
        phip = two_pi*uphi
        zp = Zmax*uz
        wp = 2.0*rp/Rmax*w0

        call sub_B02_deposit_charge_3d_cyl(rp,phip,zp,1.0,wp,dr,dphi,dz, &
            Nr,Nphi,Nz,rho)
    end do

    call sub_B02_average_axis_charge_3d_cyl(Nr,Nphi,Nz,rho)

    n0 = real(Np)*w0/pi
    j0 = 0
    jpi = (Nphi+1)/2

    do k = 0,Nz
        plot_map(0,k) = rho(0,j0,k)/n0
        do i = 1,Nr
            plot_map(i,k) = rho(i,j0,k)/n0
            plot_map(-i,k) = rho(i,jpi,k)/n0
        end do
    end do

    open(10,file='density_weighted_uniform_physics_map.dat',status='replace')
    do k = 0,Nz
        do i = -Nr,Nr
            write(10,'(3(es24.16,1x))') real(i)*dr,real(k)*dz,plot_map(i,k)
        end do
        write(10,*)
    end do
    close(10)

    open(11,file='density_weighted_uniform_physics_axis0.dat',status='replace')
    do k = 0,Nz
        write(11,'(2(es24.16,1x))') real(k)*dz,plot_map(0,k)
    end do
    close(11)

    print *, 'Weighted charge test finished.'
    print *, 'Sampling: rp = Rmax*U, wp = 2*rp/Rmax*w0, w0 = ',w0
    print *, 'Np used = ',Np
    print *, 'Output: density_weighted_uniform_physics_map.dat'

    deallocate(rho,plot_map)

end program test_charge_weighted_uniform_physics
