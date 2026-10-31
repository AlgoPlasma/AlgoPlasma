!> @file sub_D07_phi_to_E_nonuniform.f90
!> @brief Cell-centered cylindrical E = -grad(phi) on a nonuniform grid.
!> @details Three-point quadratic interpolation gives the derivative:
!> D(phi) = [hp*(phi0-phim)/hm + hm*(phip-phi0)/hp]/(hm+hp).
!> hm/hp are center distances, half the sum of adjacent cell widths.
!> This is exact for quadratic potentials and second order as both
!> neighbor distances tend to zero. Ealpha includes the cylindrical 1/r.
!> Only owned cells are written; output ghost values are preserved.
!> No MPI exchange or physical-boundary reconstruction is performed.
!> Fill phi and width halos before calling, including periodic seams.
!> At physical faces use boundary-consistent ghost potentials and widths;
!> boundary accuracy depends on that reconstruction. Axis ghosts require
!> the caller's cylindrical regularity treatment (not generic reflection).
!> No cell center may lie at r=0. With an axis face, the first center is dr/2.
!> @param[in] il Lower owned indices (3), ordered r,alpha,z.
!> @param[in] iu Upper owned indices (3), each at least il.
!> @param[in] rface_lo Global radius of the lower LOCAL radial face,
!> r(il(1)-1/2), same convention as D04 A_mpi; nonnegative.
!> All grid widths and the lower radial face must be finite.
!> @param[in] dr Radial widths (il(1)-1:iu(1)+1), positive, including halos.
!> @param[in] da Angular widths (il(2)-1:iu(2)+1), positive, in radians.
!> @param[in] dz Axial widths (il(3)-1:iu(3)+1), positive, including halos.
!> @param[in] phi Potential on (il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,
!> il(3)-1:iu(3)+1), including one filled halo per side.
!> D04 phi1d must first be unpacked, e.g. by D05, then boundary corrected.
!> @param[in,out] Er Radial field, same shape as phi; owned cells overwritten.
!> @param[in,out] Ea Physical azimuthal field (not Cartesian Ey), same shape.
!> @param[in,out] Ez Axial field, same shape as phi.
!> dr,dz,rface_lo must use the same length units as D04. Output units are
!> potential/length; no extra unit-grid scaling is applied.
subroutine sub_D07_phi_to_E_nonuniform(il,iu,rface_lo,dr,da,dz,phi,Er,Ea,Ez)
    use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
    implicit none
    integer,intent(in) :: il(3),iu(3)
    real,intent(in) :: rface_lo
    real,intent(in) :: dr(il(1)-1:iu(1)+1),da(il(2)-1:iu(2)+1),dz(il(3)-1:iu(3)+1)
    real,intent(in) :: phi(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)
    real,intent(inout) :: Er(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)
    real,intent(inout) :: Ea(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)
    real,intent(inout) :: Ez(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)
    real :: rm(il(1):iu(1)),rp(il(1):iu(1)),rc(il(1):iu(1))
    real :: am(il(2):iu(2)),ap(il(2):iu(2))
    real :: zm(il(3):iu(3)),zp(il(3):iu(3)),rf
    integer :: i,j,k

    if (any(iu < il)) error stop 'D07: empty owned domain'
    if (.not.(rface_lo >= 0.0)) error stop 'D07: invalid lower radial face'
    if (any(.not.(dr > 0.0)) .or. any(.not.(da > 0.0)) .or. &
        any(.not.(dz > 0.0))) error stop 'D07: widths must be positive'
    if (.not.ieee_is_finite(rface_lo)) error stop 'D07: radial face must be finite'
    if (.not.all(ieee_is_finite(dr)).or..not.all(ieee_is_finite(da)).or. &
        .not.all(ieee_is_finite(dz))) error stop 'D07: widths must be finite'
    rf = rface_lo
    do i = il(1),iu(1)
        rc(i) = rf + 0.5*dr(i)
        rf = rf + dr(i)
        rm(i) = 0.5*(dr(i-1)+dr(i))
        rp(i) = 0.5*(dr(i)+dr(i+1))
    end do
    do j = il(2),iu(2)
        am(j) = 0.5*(da(j-1)+da(j))
        ap(j) = 0.5*(da(j)+da(j+1))
    end do
    do k = il(3),iu(3)
        zm(k) = 0.5*(dz(k-1)+dz(k))
        zp(k) = 0.5*(dz(k)+dz(k+1))
    end do
    do k = il(3),iu(3)
    do j = il(2),iu(2)
    do i = il(1),iu(1)
        Er(i,j,k) = -(rp(i)*(phi(i,j,k)-phi(i-1,j,k))/rm(i) &
                    +rm(i)*(phi(i+1,j,k)-phi(i,j,k))/rp(i))/(rm(i)+rp(i))
        Ea(i,j,k) = -(ap(j)*(phi(i,j,k)-phi(i,j-1,k))/am(j) &
                    +am(j)*(phi(i,j+1,k)-phi(i,j,k))/ap(j))/(am(j)+ap(j))/rc(i)
        Ez(i,j,k) = -(zp(k)*(phi(i,j,k)-phi(i,j,k-1))/zm(k) &
                    +zm(k)*(phi(i,j,k+1)-phi(i,j,k))/zp(k))/(zm(k)+zp(k))
    end do
    end do
    end do
end subroutine sub_D07_phi_to_E_nonuniform
