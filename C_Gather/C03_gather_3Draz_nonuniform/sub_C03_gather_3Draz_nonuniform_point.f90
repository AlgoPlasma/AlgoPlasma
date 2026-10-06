!> @file sub_C03_gather_3Draz_nonuniform_point.f90
!> @brief Gather nonuniform 3D RAZ fields at one particle position.
!> @details AlgoPlasma geometry/index convention:
!>   owned cell indices: il(d):iu(d)
!>   cell i is bounded by face(i-1) and face(i)
!>   center(i)=0.5*(face(i-1)+face(i))
!> Fixed electrostatic RAZ field staggering:
!>   Er(q,j,k) at (r_face(q),   a_center(j), z_center(k))  : (f,c,c)
!>   Ea(i,q,k) at (r_center(i), a_face(q),   z_center(k))  : (c,f,c)
!>   Ez(i,j,q) at (r_center(i), a_center(j), z_face(q))    : (c,c,f)
!> Prescribed/nodal magnetic field:
!>   Br/Ba/Bz(qr,qa,qz) at (r_face(qr),a_face(qa),z_face(qz)) : (f,f,f)
!> All field arrays use the common one-guard storage envelope il-1:iu+1.
!> @param[in] x Physical (r,alpha,z), length 3, in m/rad/m; r must be nonnegative.
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
subroutine sub_C03_gather_3Draz_nonuniform_point( &
    x,il,iu,r_face,a_face,z_face,dr,da,dz,Er,Ea,Ez,Br,Ba,Bz,E,B,cell,a_period,a_origin)
    implicit none
    real, intent(in) :: x(3)
    integer, intent(in) :: il(3),iu(3)
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
    integer :: ic(3),ic0(3)
    real :: wf(3),wc(3)

    call c03_build_stencil( &
        x,il,iu,r_face,a_face,z_face,dr,da,dz,ic,ic0,wf,wc,cell,a_period,a_origin)

    ! Face direction  -> low index ic-1, weight wf.
    ! Center direction -> low index ic0,  weight wc.
    E(1)=c03_trilinear(il-1,iu+1,Er, &
        [ic(1)-1,ic0(2),  ic0(3)], [wf(1),wc(2),wc(3)])
    E(2)=c03_trilinear(il-1,iu+1,Ea, &
        [ic0(1),  ic(2)-1,ic0(3)], [wc(1),wf(2),wc(3)])
    E(3)=c03_trilinear(il-1,iu+1,Ez, &
        [ic0(1),  ic0(2),  ic(3)-1], [wc(1),wc(2),wf(3)])

    ! Prescribed/nodal B uses the same face stencil in all three directions.
    B(1)=c03_trilinear(il-1,iu+1,Br,ic-1,wf)
    B(2)=c03_trilinear(il-1,iu+1,Ba,ic-1,wf)
    B(3)=c03_trilinear(il-1,iu+1,Bz,ic-1,wf)
end subroutine sub_C03_gather_3Draz_nonuniform_point
