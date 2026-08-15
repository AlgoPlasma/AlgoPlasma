!> @file sub_D04_hypre_3Draz_nonuniform_bc_A_outflow.f90
!> @brief Apply outflow/Robin-type boundary corrections to the already
!> assembled 7-point matrix and RHS for the single-domain 3D cylindrical
!> nonuniform Poisson equation on a cell-centered grid.
!> @details
!> This routine is intended to be called after
!> `sub_D04_hypre_3Draz_nonuniform_A`.
!>
!> It modifies the already assembled `A_values` and `RHS` in place.
!>
!> The stencil order is
!> 0(i,j,k), 1(i-1,j,k), 2(i+1,j,k), 3(i,j-1,k), 4(i,j+1,k),
!> 5(i,j,k-1), 6(i,j,k+1).
!>
!> The face order in `bc_type` is
!> `(r_lo,r_hi,a_lo,a_hi,z_lo,z_hi)`.
!>
!> By convention, only faces with `bc_type(face) == 5` are processed here.
!> This extends the current D04 boundary-code table with
!> `5 = BC_OUTFLOW`.
!>
!> The reference point `r0_cyl` is given directly in cylindrical
!> coordinates `(r0,alpha0,z0)`. All geometric quantities are evaluated in
!> cylindrical form. No Cartesian conversion is used.
!>
!> For a face center `(rb,alphab,zb)`, define
!>
!> `ds2 = rb^2 + r0^2 - 2*rb*r0*cos(alphab-alpha0) + (zb-z0)^2`.
!>
!> Let `dalpha = alphab - alpha0`. The projection of
!> `(x_face - x0)` on the outward unit normal is:
!>
!> - `r_lo`: `-(rb - r0*cos(dalpha))`
!> - `r_hi`: ` +(rb - r0*cos(dalpha))`
!> - `a_lo`: `-r0*sin(dalpha)`
!> - `a_hi`: `+r0*sin(dalpha)`
!> - `z_lo`: `-(zb-z0)`
!> - `z_hi`: ` +(zb-z0)`
!>
!> Then
!>
!> `kb = normal_proj / ds2`
!>
!> and
!>
!> `eta = kb * dn`, `gamma = 2*eta/(eta+2)`.
!>
!> Here the local normal spacing `dn` is taken as:
!> - `dr(i)` on `r` faces,
!> - `rcell(i)*da(j)` on `alpha` faces,
!> - `dz(k)` on `z` faces.
!>
!> For each outflow face, this routine replaces the corresponding
!> neighbor-coupling contribution by an equivalent diagonal and RHS
!> correction based on `gamma` and the far-field/reference potential
!> `phi_infty`.
!>
!> If the corresponding stencil slot already contains a nonzero
!> off-diagonal coefficient, that value is removed and converted into
!> a diagonal/RHS correction.
!>
!> If the slot is zero, the routine reconstructs the local boundary-face
!> coefficient directly from the local grid geometry and applies the
!> outflow correction from that coefficient.
!>
!> To avoid singular geometric configurations, the routine stops if the
!> reference point lies on a processed boundary-face center
!> (`ds2 <= tiny_ds2`) or if `eta + 2` is too small in magnitude.
!>
!> @author Baisheng WANG (2026/04/27)
!
!> @param[in] il: integer (1:3), lower cell-center indices in
!> `r,alpha,z`.
!> @param[in] iu: integer (1:3), upper cell-center indices in
!> `r,alpha,z`.
!> @param[in] rmin: real scalar, radial face coordinate at
!> `r_{il(1)-1/2}`.
!> @param[in] amin: real scalar, azimuthal face coordinate at
!> `alpha_{il(2)-1/2}`.
!> @param[in] zmin: real scalar, axial face coordinate at
!> `z_{il(3)-1/2}`.
!> @param[in] dr: real (il(1):iu(1)), radial cell widths.
!> @param[in] da: real (il(2):iu(2)), azimuthal cell widths.
!> @param[in] dz: real (il(3):iu(3)), axial cell widths.
!> @param[in] bc_type: integer (1:6), boundary-type codes on
!> `(r_lo,r_hi,a_lo,a_hi,z_lo,z_hi)`.
!> @param[in,out] A_values: real (:), flattened 7-point stencil
!> coefficients.
!> @param[in,out] RHS: real (:), flattened right-hand-side array.
!> @param[in] phi_infty: real scalar, far-field/reference potential used
!> in the outflow boundary condition.
!> @param[in] r0_cyl: real (1:3), cylindrical reference point
!> `(r0,alpha0,z0)`.

subroutine sub_D04_hypre_3Draz_nonuniform_bc_A_outflow( &
    il,iu,rmin,amin,zmin,dr,da,dz,bc_type,A_values,RHS,phi_infty,r0_cyl)

    implicit none

    integer,parameter :: BC_OUTFLOW = 5
    integer,parameter :: nentries = 7

    real,parameter :: tiny_ds2  = 1.0e-30
    real,parameter :: tiny_den  = 1.0e-30
    real,parameter :: tiny_slot = 1.0e-30

    integer,dimension(1:3) :: il,iu
    real :: rmin,amin,zmin,phi_infty
    real,dimension(il(1):iu(1)) :: dr
    real,dimension(il(2):iu(2)) :: da
    real,dimension(il(3):iu(3)) :: dz
    integer,dimension(1:6) :: bc_type
    real,dimension(:) :: A_values,RHS
    real,dimension(1:3) :: r0_cyl

    integer :: i,j,k,mA,mR
    real,dimension(il(1)-1:iu(1)) :: rface
    real,dimension(il(1):iu(1)) :: rcell
    real,dimension(il(2)-1:iu(2)) :: aface
    real,dimension(il(2):iu(2)) :: acell
    real,dimension(il(3)-1:iu(3)) :: zface
    real,dimension(il(3):iu(3)) :: zcell

    real :: cr_m,cr_p,ca_m,ca_p,cz_m,cz_p,ap
    real :: slot_val
    real :: rb,alphab,zb
    real :: dalpha,cos_da,sin_da,ds2,normal_proj,kb,eta,gamma
    real :: r0,alpha0,z0

    r0     = r0_cyl(1)
    alpha0 = r0_cyl(2)
    z0     = r0_cyl(3)

    rface(il(1)-1) = rmin
    do i = il(1),iu(1)
        rface(i) = rface(i-1) + dr(i)
    end do

    do i = il(1),iu(1)
        rcell(i) = 0.5*(rface(i-1) + rface(i))
    end do

    aface(il(2)-1) = amin
    do j = il(2),iu(2)
        aface(j) = aface(j-1) + da(j)
    end do

    do j = il(2),iu(2)
        acell(j) = 0.5*(aface(j-1) + aface(j))
    end do

    zface(il(3)-1) = zmin
    do k = il(3),iu(3)
        zface(k) = zface(k-1) + dz(k)
    end do

    do k = il(3),iu(3)
        zcell(k) = 0.5*(zface(k-1) + zface(k))
    end do

    mA = 1
    mR = 1
    do k = il(3),iu(3)
    do j = il(2),iu(2)
    do i = il(1),iu(1)

        ap = 0.0

        ! Minus-r face, stencil slot 1.
        if (i == il(1) .and. bc_type(1) == BC_OUTFLOW) then
            rb     = rface(i-1)
            alphab = acell(j)
            zb     = zcell(k)

            dalpha = alphab - alpha0
            cos_da = cos(dalpha)

            ds2 = rb*rb + r0*r0 - 2.0*rb*r0*cos_da + (zb-z0)*(zb-z0)
            if (ds2 <= tiny_ds2) then
                write(*,*) 'ERROR: outflow reference point lies on r_lo face center.'
                stop
            end if

            normal_proj = -(rb - r0*cos_da)
            kb  = normal_proj/ds2
            eta = kb*dr(i)

            if (abs(eta + 2.0) <= tiny_den) then
                write(*,*) 'ERROR: eta + 2 is too small on r_lo outflow face.'
                stop
            end if

            gamma = 2.0*eta/(eta + 2.0)

            ! If the off-diagonal slot is already present, eliminate that
            ! neighbor coupling and convert it into a diagonal correction.
            ! Otherwise, reconstruct the local face coefficient directly.
            slot_val = A_values(mA+1)
            if (abs(slot_val) > tiny_slot) then
                cr_m = -slot_val
                ap = ap + cr_m*gamma - cr_m
            else
                cr_m = rface(i-1)*da(j)*dz(k)/dr(i)
                ap = ap + cr_m*gamma
            end if

            RHS(mR) = RHS(mR) + cr_m*gamma*phi_infty
            A_values(mA+1) = 0.0
        end if

        ! Plus-r face, stencil slot 2.
        if (i == iu(1) .and. bc_type(2) == BC_OUTFLOW) then
            rb     = rface(i)
            alphab = acell(j)
            zb     = zcell(k)

            dalpha = alphab - alpha0
            cos_da = cos(dalpha)

            ds2 = rb*rb + r0*r0 - 2.0*rb*r0*cos_da + (zb-z0)*(zb-z0)
            if (ds2 <= tiny_ds2) then
                write(*,*) 'ERROR: outflow reference point lies on r_hi face center.'
                stop
            end if

            normal_proj = rb - r0*cos_da
            kb  = normal_proj/ds2
            eta = kb*dr(i)

            if (abs(eta + 2.0) <= tiny_den) then
                write(*,*) 'ERROR: eta + 2 is too small on r_hi outflow face.'
                stop
            end if

            gamma = 2.0*eta/(eta + 2.0)

            ! If the off-diagonal slot is already present, eliminate that
            ! neighbor coupling and convert it into a diagonal correction.
            ! Otherwise, reconstruct the local face coefficient directly.
            slot_val = A_values(mA+2)
            if (abs(slot_val) > tiny_slot) then
                cr_p = -slot_val
                ap = ap + cr_p*gamma - cr_p
            else
                cr_p = rface(i)*da(j)*dz(k)/dr(i)
                ap = ap + cr_p*gamma
            end if

            RHS(mR) = RHS(mR) + cr_p*gamma*phi_infty
            A_values(mA+2) = 0.0
        end if

        ! Minus-alpha face, stencil slot 3.
        if (j == il(2) .and. bc_type(3) == BC_OUTFLOW) then
            rb     = rcell(i)
            alphab = aface(j-1)
            zb     = zcell(k)

            dalpha = alphab - alpha0
            cos_da = cos(dalpha)
            sin_da = sin(dalpha)

            ds2 = rb*rb + r0*r0 - 2.0*rb*r0*cos_da + (zb-z0)*(zb-z0)
            if (ds2 <= tiny_ds2) then
                write(*,*) 'ERROR: outflow reference point lies on a_lo face center.'
                stop
            end if

            normal_proj = -r0*sin_da
            kb  = normal_proj/ds2
            eta = kb*(rcell(i)*da(j))

            if (abs(eta + 2.0) <= tiny_den) then
                write(*,*) 'ERROR: eta + 2 is too small on a_lo outflow face.'
                stop
            end if

            gamma = 2.0*eta/(eta + 2.0)

            ! If the off-diagonal slot is already present, eliminate that
            ! neighbor coupling and convert it into a diagonal correction.
            ! Otherwise, reconstruct the local face coefficient directly.
            slot_val = A_values(mA+3)
            if (abs(slot_val) > tiny_slot) then
                ca_m = -slot_val
                ap = ap + ca_m*gamma - ca_m
            else
                ca_m = dr(i)*dz(k)/(rcell(i)*da(j))
                ap = ap + ca_m*gamma
            end if

            RHS(mR) = RHS(mR) + ca_m*gamma*phi_infty
            A_values(mA+3) = 0.0
        end if

        ! Plus-alpha face, stencil slot 4.
        if (j == iu(2) .and. bc_type(4) == BC_OUTFLOW) then
            rb     = rcell(i)
            alphab = aface(j)
            zb     = zcell(k)

            dalpha = alphab - alpha0
            cos_da = cos(dalpha)
            sin_da = sin(dalpha)

            ds2 = rb*rb + r0*r0 - 2.0*rb*r0*cos_da + (zb-z0)*(zb-z0)
            if (ds2 <= tiny_ds2) then
                write(*,*) 'ERROR: outflow reference point lies on a_hi face center.'
                stop
            end if

            normal_proj = r0*sin_da
            kb  = normal_proj/ds2
            eta = kb*(rcell(i)*da(j))

            if (abs(eta + 2.0) <= tiny_den) then
                write(*,*) 'ERROR: eta + 2 is too small on a_hi outflow face.'
                stop
            end if

            gamma = 2.0*eta/(eta + 2.0)

            ! If the off-diagonal slot is already present, eliminate that
            ! neighbor coupling and convert it into a diagonal correction.
            ! Otherwise, reconstruct the local face coefficient directly.
            slot_val = A_values(mA+4)
            if (abs(slot_val) > tiny_slot) then
                ca_p = -slot_val
                ap = ap + ca_p*gamma - ca_p
            else
                ca_p = dr(i)*dz(k)/(rcell(i)*da(j))
                ap = ap + ca_p*gamma
            end if

            RHS(mR) = RHS(mR) + ca_p*gamma*phi_infty
            A_values(mA+4) = 0.0
        end if

        ! Minus-z face, stencil slot 5.
        if (k == il(3) .and. bc_type(5) == BC_OUTFLOW) then
            rb     = rcell(i)
            alphab = acell(j)
            zb     = zface(k-1)

            dalpha = alphab - alpha0
            cos_da = cos(dalpha)

            ds2 = rb*rb + r0*r0 - 2.0*rb*r0*cos_da + (zb-z0)*(zb-z0)
            if (ds2 <= tiny_ds2) then
                write(*,*) 'ERROR: outflow reference point lies on z_lo face center.'
                stop
            end if

            normal_proj = -(zb-z0)
            kb  = normal_proj/ds2
            eta = kb*dz(k)

            if (abs(eta + 2.0) <= tiny_den) then
                write(*,*) 'ERROR: eta + 2 is too small on z_lo outflow face.'
                stop
            end if

            gamma = 2.0*eta/(eta + 2.0)

            ! If the off-diagonal slot is already present, eliminate that
            ! neighbor coupling and convert it into a diagonal correction.
            ! Otherwise, reconstruct the local face coefficient directly.
            slot_val = A_values(mA+5)
            if (abs(slot_val) > tiny_slot) then
                cz_m = -slot_val
                ap = ap + cz_m*gamma - cz_m
            else
                cz_m = rcell(i)*dr(i)*da(j)/dz(k)
                ap = ap + cz_m*gamma
            end if

            RHS(mR) = RHS(mR) + cz_m*gamma*phi_infty
            A_values(mA+5) = 0.0
        end if

        ! Plus-z face, stencil slot 6.
        if (k == iu(3) .and. bc_type(6) == BC_OUTFLOW) then
            rb     = rcell(i)
            alphab = acell(j)
            zb     = zface(k)

            dalpha = alphab - alpha0
            cos_da = cos(dalpha)

            ds2 = rb*rb + r0*r0 - 2.0*rb*r0*cos_da + (zb-z0)*(zb-z0)
            if (ds2 <= tiny_ds2) then
                write(*,*) 'ERROR: outflow reference point lies on z_hi face center.'
                stop
            end if

            normal_proj = zb-z0
            kb  = normal_proj/ds2
            eta = kb*dz(k)

            if (abs(eta + 2.0) <= tiny_den) then
                write(*,*) 'ERROR: eta + 2 is too small on z_hi outflow face.'
                stop
            end if

            gamma = 2.0*eta/(eta + 2.0)

            ! If the off-diagonal slot is already present, eliminate that
            ! neighbor coupling and convert it into a diagonal correction.
            ! Otherwise, reconstruct the local face coefficient directly.
            slot_val = A_values(mA+6)
            if (abs(slot_val) > tiny_slot) then
                cz_p = -slot_val
                ap = ap + cz_p*gamma - cz_p
            else
                cz_p = rcell(i)*dr(i)*da(j)/dz(k)
                ap = ap + cz_p*gamma
            end if

            RHS(mR) = RHS(mR) + cz_p*gamma*phi_infty
            A_values(mA+6) = 0.0
        end if

        ! Accumulate all outflow-face corrections into the diagonal entry.
        A_values(mA) = A_values(mA) + ap

        mA = mA + nentries
        mR = mR + 1

    end do
    end do
    end do

end subroutine sub_D04_hypre_3Draz_nonuniform_bc_A_outflow