!> @file sub_C03_gather_3Draz_nonuniform.f90
!> @brief C01-style particle-array wrapper for the AlgoPlasma-compatible C03 gather.
!> @details par(1:3,p)=(r [m],alpha [rad],z [m]); par(4:6,p) are untouched.
!> @param[in] p Particle index, 1 <= p <= np.
!> @param[in] np Number of particles.
!> @param[in] par Particle array (1:6,1:np); only (r,alpha,z) in m/rad/m is read.
!> @param[in] il,iu Inclusive owned-cell index bounds, integer arrays of length 3.
!> @param[in] r_face Radial faces, il(1)-1:iu(1), in meters.
!> @param[in] a_face Angular faces, il(2)-1:iu(2), in radians.
!> @param[in] z_face Axial faces, il(3)-1:iu(3), in meters.
!> @param[in] dr Radial cell widths, il(1)-1:iu(1)+1, including ghosts, in meters.
!> @param[in] da Angular cell widths, il(2)-1:iu(2)+1, including ghosts, in radians.
!> @param[in] dz Axial cell widths, il(3)-1:iu(3)+1, including ghosts, in meters.
!> @param[in] Er,Ea,Ez Electric fields at (f,c,c), (c,f,c), (c,c,f), respectively.
!> @param[in] Br,Ba,Bz Prescribed magnetic fields at (f,f,f).
!> @param[out] E,B Length-3 cylindrical (r,alpha,z) components, in input field units.
!> @param[in] cell Optional length-3 cached owned cell; checked, never updated.
!> @param[in] a_period Optional positive angular period in radians.
!> @param[in] a_origin Optional period origin in radians (default zero); requires a_period.
!> @note All fields have bounds il(d)-1:iu(d)+1 in every dimension. The caller
!> supplies valid ghost fields and widths and routes particles to the local grid.
!> Angular wrapping does not fill ghosts. No Cartesian basis rotation is applied.
!> @note Uses default real; compile caller and module with consistent precision.
!> Invalid geometry, containment, or optional arguments cause error stop.
subroutine sub_C03_gather_3Draz_nonuniform( &
    p,np,par,il,iu,r_face,a_face,z_face,dr,da,dz,Er,Ea,Ez,Br,Ba,Bz,E,B,cell,a_period,a_origin)
    implicit none
    integer, intent(in) :: p,np,il(3),iu(3)
    real, intent(in) :: par(1:6,1:np)
    real, intent(in) :: r_face(il(1)-1:iu(1)),a_face(il(2)-1:iu(2)),z_face(il(3)-1:iu(3))
    real, intent(in) :: dr(il(1)-1:iu(1)+1),da(il(2)-1:iu(2)+1),dz(il(3)-1:iu(3)+1)
    real, intent(in) :: Er(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)
    real, intent(in) :: Ea(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)
    real, intent(in) :: Ez(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)
    real, intent(in) :: Br(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)
    real, intent(in) :: Ba(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)
    real, intent(in) :: Bz(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)
    real, intent(out) :: E(3),B(3)
    integer, intent(in), optional :: cell(3)
    real, intent(in), optional :: a_period,a_origin

    if (p < 1 .or. p > np) error stop 'C03: invalid particle index'

    call sub_C03_gather_3Draz_nonuniform_point( &
        par(1:3,p),il,iu,r_face,a_face,z_face,dr,da,dz,Er,Ea,Ez,Br,Ba,Bz,E,B,cell,a_period,a_origin)
end subroutine sub_C03_gather_3Draz_nonuniform
