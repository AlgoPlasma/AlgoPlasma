!> @file sub_C03_gather_helpers.f90
!> @brief Public grid validator and private stateless geometry/interpolation helpers for C03.

!> @brief Validate one D04-style mesh axis once during setup.
!> @details Owned cell i is [face(i-1),face(i)] and width(i)=face(i)-face(i-1).
!> @param[in] lo,hi Inclusive owned-cell bounds; hi must be at least lo.
!> @param[in] face Physical face coordinates (lo-1:hi), strictly increasing.
!> @param[in] width Cell widths (lo-1:hi+1), including positive ghost widths.
!> @note Use the same units for face and width: meters for r/z, radians for alpha.
!> Call once per axis during setup; gather does not call this validator.
!> Failure causes error stop. Ghost widths are not matched against neighbor geometry.
subroutine sub_C03_check_grid(lo,hi,face,width)
    implicit none
    integer, intent(in) :: lo,hi
    real, intent(in) :: face(lo-1:hi),width(lo-1:hi+1)
    integer :: i
    real :: span,tol

    if (hi < lo) error stop 'C03: empty grid axis'
    if (any(.not. (width > 0.0))) error stop 'C03: nonpositive or NaN width'

    do i=lo,hi
        span=face(i)-face(i-1)
        if (.not. (span > 0.0)) error stop 'C03: faces must increase'
        tol=64.0*epsilon(1.0)*max(abs(face(i-1)),abs(face(i)),abs(width(i)))
        if (abs(span-width(i)) > tol) error stop 'C03: inconsistent face/width'
    end do
end subroutine sub_C03_check_grid

!> @brief Return the physical coordinate of cell center idx, including one ghost cell.
real function c03_center(idx,lo,hi,face,width) result(c)
    implicit none
    integer, intent(in) :: idx,lo,hi
    real, intent(in) :: face(lo-1:hi),width(lo-1:hi+1)

    if (idx < lo-1 .or. idx > hi+1) error stop 'C03: center index outside one-cell halo'

    if (idx == lo-1) then
        c=face(lo-1)-0.5*width(lo-1)
    else if (idx == hi+1) then
        c=face(hi)+0.5*width(hi+1)
    else
        c=0.5*(face(idx-1)+face(idx))
    end if
end function c03_center

!> @brief Build face and center interpolation stencils for one nonuniform axis.
subroutine c03_axis_stencil(x,lo,hi,face,width,ic,ic0,wf,wc,cell)
    implicit none
    real, intent(in) :: x
    integer, intent(in) :: lo,hi
    real, intent(in) :: face(lo-1:hi),width(lo-1:hi+1)
    integer, intent(out) :: ic,ic0
    real, intent(out) :: wf,wc
    integer, intent(in), optional :: cell
    integer :: left,right,mid
    real :: xx,cc,c0,c1,span,tol

    if (hi < lo) error stop 'C03: empty local grid'

    tol=64.0*epsilon(1.0)*max(abs(face(lo-1)),abs(face(hi)),abs(face(hi)-face(lo-1)))
    if (.not. (x >= face(lo-1)-tol .and. x <= face(hi)+tol)) &
        error stop 'C03: particle outside owned grid; route particle first'
    xx=min(face(hi),max(face(lo-1),x))

    if (present(cell)) then
        ic=cell
        if (ic < lo .or. ic > hi) error stop 'C03: cached cell outside owned grid'
    else
        ! Find ic such that face(ic-1) <= xx <= face(ic).
        left=lo
        right=hi
        do while (left < right)
            mid=left+(right-left)/2
            if (xx <= face(mid)) then
                right=mid
            else
                left=mid+1
            end if
        end do
        ic=left
    end if

    if (xx < face(ic-1)-tol .or. xx > face(ic)+tol) error stop 'C03: stale cached cell'

    span=face(ic)-face(ic-1)
    if (.not. (span > 0.0)) error stop 'C03: invalid face spacing'
    wf=min(1.0,max(0.0,(xx-face(ic-1))/span))

    cc=0.5*(face(ic-1)+face(ic))
    if (xx < cc) then
        ic0=ic-1
    else
        ic0=ic
    end if

    c0=c03_center(ic0,  lo,hi,face,width)
    c1=c03_center(ic0+1,lo,hi,face,width)
    if (.not. (c1 > c0)) error stop 'C03: invalid cell-center spacing'
    wc=min(1.0,max(0.0,(xx-c0)/(c1-c0)))
end subroutine c03_axis_stencil

!> @brief Build the 3D RAZ interpolation stencil.
subroutine c03_build_stencil(x,il,iu,rf,af,zf,dr,da,dz,ic,ic0,wf,wc,cell,a_period,a_origin)
    implicit none
    real, intent(in) :: x(3)
    integer, intent(in) :: il(3),iu(3)
    real, intent(in) :: rf(il(1)-1:iu(1)),af(il(2)-1:iu(2)),zf(il(3)-1:iu(3))
    real, intent(in) :: dr(il(1)-1:iu(1)+1),da(il(2)-1:iu(2)+1),dz(il(3)-1:iu(3)+1)
    integer, intent(out) :: ic(3),ic0(3)
    real, intent(out) :: wf(3),wc(3)
    integer, intent(in), optional :: cell(3)
    real, intent(in), optional :: a_period,a_origin
    real :: a,origin,reference

    if (.not. (x(1) >= 0.0)) error stop 'C03: radius must be nonnegative'
    if (present(a_origin) .and. .not. present(a_period)) error stop 'C03: a_origin requires a_period'

    a=x(2)
    if (present(a_period)) then
        if (.not. (a_period > 0.0)) error stop 'C03: angular period must be positive'
        origin=0.0
        if (present(a_origin)) origin=a_origin

        reference=0.5*(af(il(2)-1)+af(iu(2)))
        if (present(cell)) then
            if (cell(2) < il(2) .or. cell(2) > iu(2)) error stop 'C03: invalid angular cell'
            reference=0.5*(af(cell(2)-1)+af(cell(2)))
        end if

        a=origin+modulo(a-origin,a_period)
        a=a+anint((reference-a)/a_period)*a_period
    end if

    if (present(cell)) then
        call c03_axis_stencil(x(1),il(1),iu(1),rf,dr,ic(1),ic0(1),wf(1),wc(1),cell(1))
        call c03_axis_stencil(a,   il(2),iu(2),af,da,ic(2),ic0(2),wf(2),wc(2),cell(2))
        call c03_axis_stencil(x(3),il(3),iu(3),zf,dz,ic(3),ic0(3),wf(3),wc(3),cell(3))
    else
        call c03_axis_stencil(x(1),il(1),iu(1),rf,dr,ic(1),ic0(1),wf(1),wc(1))
        call c03_axis_stencil(a,   il(2),iu(2),af,da,ic(2),ic0(2),wf(2),wc(2))
        call c03_axis_stencil(x(3),il(3),iu(3),zf,dz,ic(3),ic0(3),wf(3),wc(3))
    end if
end subroutine c03_build_stencil

!> @brief Standard 8-point trilinear interpolation on an explicit local stencil.
real function c03_trilinear(lo,hi,f,idx,w) result(value)
    implicit none
    integer, intent(in) :: lo(3),hi(3),idx(3)
    real, intent(in) :: f(lo(1):hi(1),lo(2):hi(2),lo(3):hi(3)),w(3)
    integer :: i,j,k
    real :: u,v,t

    i=idx(1); j=idx(2); k=idx(3)
    u=w(1); v=w(2); t=w(3)

    if (any(idx < lo) .or. any(idx+1 > hi)) error stop 'C03: trilinear stencil outside field array'

    value=(1.0-t)*((1.0-v)*((1.0-u)*f(i,j,k)   +u*f(i+1,j,k))   + &
                             v *((1.0-u)*f(i,j+1,k) +u*f(i+1,j+1,k))) + &
                 t *((1.0-v)*((1.0-u)*f(i,j,k+1) +u*f(i+1,j,k+1)) + &
                             v *((1.0-u)*f(i,j+1,k+1)+u*f(i+1,j+1,k+1)))
end function c03_trilinear
