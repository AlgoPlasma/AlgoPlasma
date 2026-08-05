!> @file sub_B02_deposit_charge_3d_cyl.f90
!> @brief Deposit one particle charge to the surrounding 8 nodes.
!> @details The implementation follows the 3D cylindrical paper for
!>          uniform cells. The phi direction is periodic. The caller may
!>          average axis values after the particle loop.
!> @author Zhijun ZHOU (2026/04/13)
!
!> @param[in] rp: real, particle radius.
!> @param[in] phip: real, particle azimuth.
!> @param[in] zp: real, particle axial position.
!> @param[in] qp: real, particle charge.
!> @param[in] wp: real, macro-particle weight.
!> @param[in] dr: real, radial cell size.
!> @param[in] dphi: real, azimuthal cell size.
!> @param[in] dz: real, axial cell size.
!> @param[in] nr: integer, number of radial cells.
!> @param[in] nphi: integer, maximum phi node index.
!> @param[in] nz: integer, number of axial cells.
!> @param[inout] rho: real (0:nr,0:nphi,0:nz), node charge density.
subroutine sub_B02_deposit_charge_3d_cyl(rp,phip,zp,qp,wp,dr,dphi,dz, &
    nr,nphi,nz,rho)

    implicit none
    real :: rp,phip,zp,qp,wp,dr,dphi,dz
    integer :: nr,nphi,nz
    real,dimension(0:nr,0:nphi,0:nz) :: rho

    integer :: i,j,k,jp1,ncphi
    real :: pi,two_pi
    real :: r_use,phi_use,z_use,rmax,zmax
    real :: ri,phij,zk
    real :: fr0,fr1,fphi0,fphi1,fz0,fz1
    real :: vr0,vr1,vz0,vz1

    pi = acos(-1.0)
    two_pi = 2.0*pi
    ncphi = nphi + 1
    rmax = real(nr)*dr
    zmax = real(nz)*dz

    r_use = rp
    if (r_use<0.0) r_use = 0.0
    if (r_use>=rmax) r_use = rmax - 10.0*epsilon(rmax)

    z_use = zp
    if (z_use<0.0) z_use = 0.0
    if (z_use>=zmax) z_use = zmax - 10.0*epsilon(zmax)

    phi_use = modulo(phip,two_pi)
    if (phi_use<0.0) phi_use = phi_use + two_pi

    i = int(floor(r_use/dr))
    if (i>nr-1) i = nr - 1
    j = int(floor(phi_use/dphi))
    if (j>nphi) j = nphi
    k = int(floor(z_use/dz))
    if (k>nz-1) k = nz - 1
    jp1 = modulo(j+1,ncphi)

    ri = real(i)*dr
    phij = real(j)*dphi
    zk = real(k)*dz

    fr0 = (ri+dr-r_use)/dr
    fr1 = (r_use-ri)/dr
    fphi0 = (phij+dphi-phi_use)/dphi
    fphi1 = (phi_use-phij)/dphi
    fz0 = (zk+dz-z_use)/dz
    fz1 = (z_use-zk)/dz

    if (i==0) then
        vr0 = dr*dr/6.0
    else
        vr0 = real(i)*dr*dr
    end if

    if (i+1==nr) then
        vr1 = real(3*nr-1)*dr*dr/6.0
    else
        vr1 = real(i+1)*dr*dr
    end if

    if (k==0) then
        vz0 = 0.5*dz
    else
        vz0 = dz
    end if

    if (k+1==nz) then
        vz1 = 0.5*dz
    else
        vz1 = dz
    end if

    rho(i  ,j  ,k  ) = rho(i  ,j  ,k  ) + qp*wp*fr0*fphi0*fz0/(vr0*dphi*vz0)
    rho(i+1,j  ,k  ) = rho(i+1,j  ,k  ) + qp*wp*fr1*fphi0*fz0/(vr1*dphi*vz0)
    rho(i  ,jp1,k  ) = rho(i  ,jp1,k  ) + qp*wp*fr0*fphi1*fz0/(vr0*dphi*vz0)
    rho(i+1,jp1,k  ) = rho(i+1,jp1,k  ) + qp*wp*fr1*fphi1*fz0/(vr1*dphi*vz0)
    rho(i  ,j  ,k+1) = rho(i  ,j  ,k+1) + qp*wp*fr0*fphi0*fz1/(vr0*dphi*vz1)
    rho(i+1,j  ,k+1) = rho(i+1,j  ,k+1) + qp*wp*fr1*fphi0*fz1/(vr1*dphi*vz1)
    rho(i  ,jp1,k+1) = rho(i  ,jp1,k+1) + qp*wp*fr0*fphi1*fz1/(vr0*dphi*vz1)
    rho(i+1,jp1,k+1) = rho(i+1,jp1,k+1) + qp*wp*fr1*fphi1*fz1/(vr1*dphi*vz1)

end subroutine sub_B02_deposit_charge_3d_cyl
