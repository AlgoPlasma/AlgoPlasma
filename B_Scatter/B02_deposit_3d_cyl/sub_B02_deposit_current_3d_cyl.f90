!> @file sub_B02_deposit_current_3d_cyl.f90
!> @brief Deposit one particle current between two positions.
!> @details The trajectory is split only when it crosses a radial,
!>          azimuthal, or axial cell boundary. The single-cell formulas
!>          follow the 3D cylindrical paper. The denominator of ``Jr``
!>          uses ``dr`` rather than ``dr^2``.
!> @author Zhijun ZHOU (2026/04/13)
!
!> @param[in] r0: real, starting radius.
!> @param[in] phi0: real, starting azimuth.
!> @param[in] z0: real, starting axial position.
!> @param[in] r1: real, ending radius.
!> @param[in] phi1: real, ending azimuth.
!> @param[in] z1: real, ending axial position.
!> @param[in] qp: real, particle charge.
!> @param[in] wp: real, macro-particle weight.
!> @param[in] dr: real, radial cell size.
!> @param[in] dphi: real, azimuthal cell size.
!> @param[in] dz: real, axial cell size.
!> @param[in] nr: integer, number of radial cells.
!> @param[in] nphi: integer, maximum phi node index.
!> @param[in] nz: integer, number of axial cells.
!> @param[in] dt: real, time step.
!> @param[inout] jr: real (0:nr,0:nphi,0:nz), radial current density.
!> @param[inout] jphi: real (0:nr,0:nphi,0:nz), azimuthal current density.
!> @param[inout] jz: real (0:nr,0:nphi,0:nz), axial current density.
subroutine sub_B02_deposit_current_3d_cyl(r0,phi0,z0,r1,phi1,z1,qp,wp, &
    dr,dphi,dz,nr,nphi,nz,dt,jr,jphi,jz)

    implicit none
    real :: r0,phi0,z0,r1,phi1,z1,qp,wp,dr,dphi,dz,dt
    integer :: nr,nphi,nz
    real,dimension(0:nr,0:nphi,0:nz) :: jr,jphi,jz

    real :: r0_use,r1_use,z0_use,z1_use,phi0_use,phi1_use
    real :: pi,two_pi
    real :: rmax,zmax,dphi_use

    pi = acos(-1.0)
    two_pi = 2.0*pi

    rmax = real(nr)*dr
    zmax = real(nz)*dz

    r0_use = r0
    if (r0_use<0.0) r0_use = 0.0
    if (r0_use>=rmax) r0_use = rmax - 10.0*epsilon(rmax)
    r1_use = r1
    if (r1_use<0.0) r1_use = 0.0
    if (r1_use>=rmax) r1_use = rmax - 10.0*epsilon(rmax)

    z0_use = z0
    if (z0_use<0.0) z0_use = 0.0
    if (z0_use>=zmax) z0_use = zmax - 10.0*epsilon(zmax)
    z1_use = z1
    if (z1_use<0.0) z1_use = 0.0
    if (z1_use>=zmax) z1_use = zmax - 10.0*epsilon(zmax)

    phi0_use = modulo(phi0,two_pi)
    if (phi0_use<0.0) phi0_use = phi0_use + two_pi
    phi1_use = modulo(phi1,two_pi)
    if (phi1_use<0.0) phi1_use = phi1_use + two_pi

    dphi_use = phi1_use - phi0_use
    if (dphi_use> pi) dphi_use = dphi_use - two_pi
    if (dphi_use<-pi) dphi_use = dphi_use + two_pi
    phi1_use = phi0_use + dphi_use

    call B02_split_and_deposit(r0_use,phi0_use,z0_use,r1_use,phi1_use,z1_use, &
        qp,wp,dr,dphi,dz,nr,nphi,nz,dt,jr,jphi,jz,0)

end subroutine sub_B02_deposit_current_3d_cyl

!> @cond INTERNAL
recursive subroutine B02_split_and_deposit(r0,phi0,z0,r1,phi1,z1,qp,wp, &
    dr,dphi,dz,nr,nphi,nz,dt,jr,jphi,jz,depth)

    implicit none
    real :: r0,phi0,z0,r1,phi1,z1,qp,wp,dr,dphi,dz,dt
    integer :: nr,nphi,nz,depth
    real,dimension(0:nr,0:nphi,0:nz) :: jr,jphi,jz

    integer :: i0,i1,j0,j1,k0,k1
    real :: dr_seg,dphi_seg,dz_seg
    real :: tr,tphi,tz,tsplit
    real :: rb,phib,zb
    real :: pi,two_pi
    real :: rs,phis,zs,phi0w,phi1w,rmax,zmax

    pi = acos(-1.0)
    two_pi = 2.0*pi

    rmax = real(nr)*dr
    zmax = real(nz)*dz

    dr_seg = r1 - r0
    dphi_seg = phi1 - phi0
    dz_seg = z1 - z0
    if (abs(dr_seg)<1.0e-14 .and. abs(dphi_seg)<1.0e-14 .and. &
        abs(dz_seg)<1.0e-14) return

    if (depth>64) then
        call B02_deposit_one_cell(r0,phi0,z0,r1,phi1,z1,qp,wp,dr,dphi,dz, &
            nr,nphi,nz,dt,jr,jphi,jz)
        return
    end if

    if (r0<=0.0) then
        i0 = 0
    else if (r0>=rmax) then
        i0 = nr - 1
    else
        i0 = int(floor(r0/dr))
        if (abs(r0-real(i0)*dr)<=100.0*epsilon(dr)) then
            if (dr_seg<0.0 .and. i0>0) i0 = i0 - 1
        end if
    end if

    if (r1<=0.0) then
        i1 = 0
    else if (r1>=rmax) then
        i1 = nr - 1
    else
        i1 = int(floor(r1/dr))
        if (abs(r1-real(i1)*dr)<=100.0*epsilon(dr)) then
            if (dr_seg<0.0 .and. i1>0) i1 = i1 - 1
        end if
    end if

    phi0w = modulo(phi0,two_pi)
    if (phi0w<0.0) phi0w = phi0w + two_pi
    j0 = int(floor(phi0w/dphi))
    if (j0>nphi) j0 = nphi
    if (abs(phi0w-real(j0)*dphi)<=100.0*epsilon(dphi)) then
        if (dphi_seg<0.0) then
            if (j0>0) then
                j0 = j0 - 1
            else
                j0 = nphi
            end if
        end if
    end if

    phi1w = modulo(phi1,two_pi)
    if (phi1w<0.0) phi1w = phi1w + two_pi
    j1 = int(floor(phi1w/dphi))
    if (j1>nphi) j1 = nphi
    if (abs(phi1w-real(j1)*dphi)<=100.0*epsilon(dphi)) then
        if (dphi_seg<0.0) then
            if (j1>0) then
                j1 = j1 - 1
            else
                j1 = nphi
            end if
        end if
    end if

    if (z0<=0.0) then
        k0 = 0
    else if (z0>=zmax) then
        k0 = nz - 1
    else
        k0 = int(floor(z0/dz))
        if (abs(z0-real(k0)*dz)<=100.0*epsilon(dz)) then
            if (dz_seg<0.0 .and. k0>0) k0 = k0 - 1
        end if
    end if

    if (z1<=0.0) then
        k1 = 0
    else if (z1>=zmax) then
        k1 = nz - 1
    else
        k1 = int(floor(z1/dz))
        if (abs(z1-real(k1)*dz)<=100.0*epsilon(dz)) then
            if (dz_seg<0.0 .and. k1>0) k1 = k1 - 1
        end if
    end if

    if (i0==i1 .and. j0==j1 .and. k0==k1) then
        call B02_deposit_one_cell(r0,phi0,z0,r1,phi1,z1,qp,wp,dr,dphi,dz, &
            nr,nphi,nz,dt,jr,jphi,jz)
        return
    end if

    tr = 2.0
    tphi = 2.0
    tz = 2.0

    if (abs(dr_seg)>1.0e-14) then
        if (dr_seg>0.0) then
            rb = real(i0+1)*dr
        else
            rb = real(i0)*dr
        end if
        tr = (rb-r0)/dr_seg
        if (tr<=1.0e-14 .or. tr>=1.0-1.0e-14) tr = 2.0
    end if

    if (abs(dphi_seg)>1.0e-14) then
        if (dphi_seg>0.0) then
            phib = real(j0+1)*dphi
            if (j0==nphi) phib = two_pi
        else
            phib = real(j0)*dphi
        end if
        tphi = (phib-phi0w)/dphi_seg
        if (tphi<=1.0e-14 .or. tphi>=1.0-1.0e-14) tphi = 2.0
    end if

    if (abs(dz_seg)>1.0e-14) then
        if (dz_seg>0.0) then
            zb = real(k0+1)*dz
        else
            zb = real(k0)*dz
        end if
        tz = (zb-z0)/dz_seg
        if (tz<=1.0e-14 .or. tz>=1.0-1.0e-14) tz = 2.0
    end if

    tsplit = min(tr,min(tphi,tz))
    if (tsplit>1.0) then
        call B02_deposit_one_cell(r0,phi0,z0,r1,phi1,z1,qp,wp,dr,dphi,dz, &
            nr,nphi,nz,dt,jr,jphi,jz)
        return
    end if

    rs = r0 + tsplit*dr_seg
    phis = phi0 + tsplit*dphi_seg
    zs = z0 + tsplit*dz_seg

    call B02_split_and_deposit(r0,phi0,z0,rs,phis,zs,qp,wp,dr,dphi,dz, &
        nr,nphi,nz,dt,jr,jphi,jz,depth+1)
    call B02_split_and_deposit(rs,phis,zs,r1,phi1,z1,qp,wp,dr,dphi,dz, &
        nr,nphi,nz,dt,jr,jphi,jz,depth+1)

end subroutine B02_split_and_deposit

subroutine B02_deposit_one_cell(r0,phi0,z0,r1,phi1,z1,qp,wp,dr,dphi,dz, &
    nr,nphi,nz,dt,jr,jphi,jz)

    implicit none
    real :: r0,phi0,z0,r1,phi1,z1,qp,wp,dr,dphi,dz,dt
    integer :: nr,nphi,nz
    real,dimension(0:nr,0:nphi,0:nz) :: jr,jphi,jz

    integer :: i,j,k,jp1,ncphi
    real :: pi,two_pi
    real :: dr_seg,dphi_seg,dz_seg,phi0w,phi1w
    real :: ri,ri1,phij,zk,redge,rtilde
    real :: rplus,rminus,phiplus,phiminus,zplus,zminus
    real :: vr0,vr1,vz0,vz1,ri_node,ri1_node
    real :: v00,v10,v01,v11,vsum,buf

    pi = acos(-1.0)
    two_pi = 2.0*pi
    ncphi = nphi + 1
    dr_seg = r1 - r0
    dphi_seg = phi1 - phi0
    dz_seg = z1 - z0
    if (abs(dr_seg)<1.0e-14 .and. abs(dphi_seg)<1.0e-14 .and. &
        abs(dz_seg)<1.0e-14) return

    phi0w = modulo(phi0,two_pi)
    if (phi0w<0.0) phi0w = phi0w + two_pi
    phi1w = phi0w + dphi_seg

    i = int(floor(r0/dr))
    if (i<0) i = 0
    if (i>nr-1) i = nr - 1
    j = int(floor(phi0w/dphi))
    if (j<0) j = 0
    if (j>nphi) j = nphi
    k = int(floor(z0/dz))
    if (k<0) k = 0
    if (k>nz-1) k = nz - 1
    jp1 = modulo(j+1,ncphi)

    ri = real(i)*dr
    ri1 = real(i+1)*dr
    phij = real(j)*dphi
    zk = real(k)*dz
    redge = (real(i)+0.5)*dr
    rtilde = r0 + 0.5*dr_seg

    rplus = ri1 - r0
    rminus = r0 - ri
    phiplus = phij + dphi - phi0w
    phiminus = phi0w - phij
    zplus = zk + dz - z0
    zminus = z0 - zk

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

    ri_node = real(i)*dr
    ri1_node = real(i+1)*dr

    if (abs(dr_seg)>1.0e-14) then
        v00 = (phiplus*zplus - phiplus*dz_seg/2.0 - zplus*dphi_seg/2.0 + &
            dphi_seg*dz_seg/3.0)*abs(dr_seg)*redge
        v10 = (phiminus*zplus - phiminus*dz_seg/2.0 + zplus*dphi_seg/2.0 - &
            dphi_seg*dz_seg/3.0)*abs(dr_seg)*redge
        v01 = (phiplus*zminus + phiplus*dz_seg/2.0 - zminus*dphi_seg/2.0 - &
            dphi_seg*dz_seg/3.0)*abs(dr_seg)*redge
        v11 = (phiminus*zminus + phiminus*dz_seg/2.0 + zminus*dphi_seg/2.0 + &
            dphi_seg*dz_seg/3.0)*abs(dr_seg)*redge
        vsum = redge*dphi*dz*abs(dr_seg)
        buf = qp*wp*dr_seg/dt/(redge*dr*dphi)
        jr(i,j  ,k  ) = jr(i,j  ,k  ) + buf*(v00/vsum)/vz0
        jr(i,jp1,k  ) = jr(i,jp1,k  ) + buf*(v10/vsum)/vz0
        jr(i,j  ,k+1) = jr(i,j  ,k+1) + buf*(v01/vsum)/vz1
        jr(i,jp1,k+1) = jr(i,jp1,k+1) + buf*(v11/vsum)/vz1
    end if

    if (abs(dphi_seg)>1.0e-14 .and. abs(rtilde)>1.0e-14) then
        v00 = (rplus*zplus - rplus*dz_seg/2.0 - zplus*dr_seg/2.0 + &
            dr_seg*dz_seg/3.0)*abs(dphi_seg)*ri_node
        v10 = (rminus*zplus - rminus*dz_seg/2.0 + zplus*dr_seg/2.0 - &
            dr_seg*dz_seg/3.0)*abs(dphi_seg)*ri1_node
        v01 = (rplus*zminus + rplus*dz_seg/2.0 - zminus*dr_seg/2.0 - &
            dr_seg*dz_seg/3.0)*abs(dphi_seg)*ri_node
        v11 = (rminus*zminus + rminus*dz_seg/2.0 + zminus*dr_seg/2.0 + &
            dr_seg*dz_seg/3.0)*abs(dphi_seg)*ri1_node
        vsum = rtilde*dr*dz*abs(dphi_seg)
        buf = qp*wp*rtilde*dphi_seg/dt/dphi
        jphi(i  ,j,k  ) = jphi(i  ,j,k  ) + buf*(v00/vsum)/(vr0*vz0)
        jphi(i+1,j,k  ) = jphi(i+1,j,k  ) + buf*(v10/vsum)/(vr1*vz0)
        jphi(i  ,j,k+1) = jphi(i  ,j,k+1) + buf*(v01/vsum)/(vr0*vz1)
        jphi(i+1,j,k+1) = jphi(i+1,j,k+1) + buf*(v11/vsum)/(vr1*vz1)
    end if

    if (abs(dz_seg)>1.0e-14 .and. abs(rtilde)>1.0e-14) then
        v00 = (rplus*phiplus - rplus*dphi_seg/2.0 - phiplus*dr_seg/2.0 + &
            dr_seg*dphi_seg/3.0)*abs(dz_seg)*rtilde
        v10 = (rminus*phiplus - rminus*dphi_seg/2.0 + phiplus*dr_seg/2.0 - &
            dr_seg*dphi_seg/3.0)*abs(dz_seg)*rtilde
        v01 = (rplus*phiminus + rplus*dphi_seg/2.0 - phiminus*dr_seg/2.0 - &
            dr_seg*dphi_seg/3.0)*abs(dz_seg)*rtilde
        v11 = (rminus*phiminus + rminus*dphi_seg/2.0 + phiminus*dr_seg/2.0 + &
            dr_seg*dphi_seg/3.0)*abs(dz_seg)*rtilde
        vsum = rtilde*dr*dphi*abs(dz_seg)
        buf = qp*wp*dz_seg/dt/(dphi*dz)
        jz(i  ,j  ,k) = jz(i  ,j  ,k) + buf*(v00/vsum)/vr0
        jz(i+1,j  ,k) = jz(i+1,j  ,k) + buf*(v10/vsum)/vr1
        jz(i  ,jp1,k) = jz(i  ,jp1,k) + buf*(v01/vsum)/vr0
        jz(i+1,jp1,k) = jz(i+1,jp1,k) + buf*(v11/vsum)/vr1
    end if

end subroutine B02_deposit_one_cell
!> @endcond
