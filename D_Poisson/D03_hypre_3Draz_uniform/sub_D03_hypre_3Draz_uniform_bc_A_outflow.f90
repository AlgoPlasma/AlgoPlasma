!> @file sub_D03_hypre_3Draz_uniform_bc_A_outflow.f90
!> @brief Apply outflow/Robin-type boundary corrections to the already
!> assembled 7-point matrix and RHS for the single-domain
!> 3D cylindrical uniform-grid Poisson equation on a cell-centered grid.
!> @details
!> This routine is intended to be called after
!> `sub_D03_hypre_3Draz_uniform_A`.
!>
!> It modifies the already assembled `A_values` and `RHS` in place.
!>
!> The stencil order is
!> 0(i,j,k), 1(i-1,j,k), 2(i+1,j,k), 3(i,j-1,k), 4(i,j+1,k),
!> 5(i,j,k-1), 6(i,j,k+1).
!>
!> The face order in `bc` is
!> `(r_lo,r_hi,a_lo,a_hi,z_lo,z_hi)`.
!>
!> By convention, only faces with `bc(face) == 5` are processed here,
!> corresponding to
!> `5 = BC_OUTFLOW`.
!>
!> The reference point `r0_cyl` is given directly in cylindrical
!> coordinates `(r0,alpha0,z0)`. All geometric quantities are evaluated in
!> cylindrical form, and no Cartesian conversion is used.
!>
!> For a boundary-face center `(rb,alphab,zb)`, define
!>
!> `ds2 = rb^2 + r0^2 - 2*rb*r0*cos(alphab-alpha0) + (zb-z0)^2`.
!>
!> Let `dalpha = alphab - alpha0`. The projection of
!> `(x_face - x0)` onto the outward unit normal is:
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
!> `eta = kb * dn`, `gamma = 2*eta / (eta + 2)`.
!>
!> The local normal spacing `dn` is taken as:
!> - `dr` on radial faces,
!> - `rcell*da` on azimuthal faces,
!> - `dz` on axial faces.
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
!> coefficient directly from the local uniform-grid geometry and applies
!> the outflow correction from that coefficient.
!>
!> To avoid singular geometric configurations, the routine stops if the
!> reference point lies on a processed boundary-face center
!> (`ds2 <= tiny_ds2`) or if `eta + 2` is too small in magnitude.
!> @author Baisheng WANG(2026/04/27)
!
!> @param[in] il: integer (1:3), lower cell-center indices in
!> `r,alpha,z`.
!> @param[in] iu: integer (1:3), upper cell-center indices in
!> `r,alpha,z`.
!> @param[in] rface_lo: real scalar, radial face coordinate at
!> `r_{il(1)-1/2}`.
!> @param[in] amin: real scalar, azimuthal face coordinate at
!> `alpha_{il(2)-1/2}`.
!> @param[in] zmin: real scalar, axial face coordinate at
!> `z_{il(3)-1/2}`.
!> @param[in] dr: real scalar, uniform radial cell width.
!> @param[in] da: real scalar, uniform azimuthal cell width.
!> @param[in] dz: real scalar, uniform axial cell width.
!> @param[in,out] A_values: real (:), flattened 7-point stencil
!> coefficients.
!> @param[in,out] RHS: real (:), flattened right-hand-side array.
!> @param[in] bc: integer (1:6), boundary-type codes on
!> `(r_lo,r_hi,a_lo,a_hi,z_lo,z_hi)`.
!> @param[in] phi_infty: real scalar, far-field/reference potential used
!> in the outflow boundary condition.
!> @param[in] r0_cyl: real (1:3), cylindrical reference point
!> `(r0,alpha0,z0)`.
subroutine sub_D03_hypre_3Draz_uniform_bc_A_outflow( &
    il,iu,rface_lo,amin,zmin,dr,da,dz,A_values,RHS,bc,phi_infty,r0_cyl)

    implicit none

    integer,dimension(1:3) :: il,iu
    real :: rface_lo,amin,zmin,dr,da,dz,phi_infty
    real,dimension(:) :: A_values,RHS
    integer,dimension(1:6) :: bc
    real,dimension(1:3) :: r0_cyl

    integer,parameter :: BC_OUTFLOW = 5
    real,parameter :: tiny_ds2 = 1.0e-30
    real,parameter :: tiny_den = 1.0e-30
    real,parameter :: tiny_slot = 1.0e-30

    integer :: i,j,k,mA,mR
    real :: rface_m,rface_p,rcell
    real :: alpha_m,alpha_p,alpha_c
    real :: z_m,z_p,z_c
    real :: cface,slot_val,dn,eta,gamma,diag_add,rhs_add
    real :: rb,alphab,zb
    real :: dalpha,cos_da,sin_da,ds2,normal_proj,kb
    real :: r0,alpha0,z0

    r0 = r0_cyl(1)
    alpha0 = r0_cyl(2)
    z0 = r0_cyl(3)

    mA = 1
    mR = 1
    do k = il(3),iu(3)
    do j = il(2),iu(2)
    do i = il(1),iu(1)

        ! Construct the local cell and face geometry.
        rface_m = rface_lo + real(i-il(1))*dr
        rface_p = rface_m + dr
        rcell = 0.5*(rface_m + rface_p)

        alpha_m = amin + real(j-il(2))*da
        alpha_p = alpha_m + da
        alpha_c = alpha_m + 0.5*da

        z_m = zmin + real(k-il(3))*dz
        z_p = z_m + dz
        z_c = z_m + 0.5*dz

        ! r_lo face, stencil slot 1.
        ! Remove the existing minus-r coupling if present, then apply the
        ! equivalent outflow correction to the diagonal and RHS.
        if (bc(1) == BC_OUTFLOW .and. i == il(1)) then
            rb = rface_m
            alphab = alpha_c
            zb = z_c
            cface = rface_m*da*dz/dr
            dn = dr

            dalpha = alphab - alpha0
            cos_da = cos(dalpha)
            ds2 = rb*rb + r0*r0 - 2.0*rb*r0*cos_da + (zb-z0)*(zb-z0)
            if (ds2 <= tiny_ds2) then
                write(*,*) 'ERROR: outflow reference point lies on r_lo face center.'
                stop
            end if

            normal_proj = -(rb - r0*cos_da)
            kb = normal_proj/ds2
            eta = kb*dn
            if (abs(eta + 2.0) <= tiny_den) then
                write(*,*) 'ERROR: eta + 2 is too small on r_lo outflow face.'
                stop
            end if

            gamma = 2.0*eta/(eta + 2.0)
            rhs_add = cface*gamma*phi_infty

            slot_val = A_values(mA+1)
            if (abs(slot_val) > tiny_slot) then
                diag_add = cface*gamma - (-slot_val)
            else
                diag_add = cface*gamma
            end if

            A_values(mA  ) = A_values(mA  ) + diag_add
            A_values(mA+1) = 0.0
            RHS(mR) = RHS(mR) + rhs_add
        end if

        ! r_hi face, stencil slot 2.
        ! Remove the existing plus-r coupling if present, then apply the
        ! equivalent outflow correction to the diagonal and RHS.
        if (bc(2) == BC_OUTFLOW .and. i == iu(1)) then
            rb = rface_p
            alphab = alpha_c
            zb = z_c
            cface = rface_p*da*dz/dr
            dn = dr

            dalpha = alphab - alpha0
            cos_da = cos(dalpha)
            ds2 = rb*rb + r0*r0 - 2.0*rb*r0*cos_da + (zb-z0)*(zb-z0)
            if (ds2 <= tiny_ds2) then
                write(*,*) 'ERROR: outflow reference point lies on r_hi face center.'
                stop
            end if

            normal_proj = rb - r0*cos_da
            kb = normal_proj/ds2
            eta = kb*dn
            if (abs(eta + 2.0) <= tiny_den) then
                write(*,*) 'ERROR: eta + 2 is too small on r_hi outflow face.'
                stop
            end if

            gamma = 2.0*eta/(eta + 2.0)
            rhs_add = cface*gamma*phi_infty

            slot_val = A_values(mA+2)
            if (abs(slot_val) > tiny_slot) then
                diag_add = cface*gamma - (-slot_val)
            else
                diag_add = cface*gamma
            end if

            A_values(mA  ) = A_values(mA  ) + diag_add
            A_values(mA+2) = 0.0
            RHS(mR) = RHS(mR) + rhs_add
        end if

        ! a_lo face, stencil slot 3.
        ! Remove the existing minus-alpha coupling if present, then apply the
        ! equivalent outflow correction to the diagonal and RHS.
        if (bc(3) == BC_OUTFLOW .and. j == il(2)) then
            rb = rcell
            alphab = alpha_m
            zb = z_c
            cface = dr*dz/(rcell*da)
            dn = rcell*da

            dalpha = alphab - alpha0
            cos_da = cos(dalpha)
            sin_da = sin(dalpha)
            ds2 = rb*rb + r0*r0 - 2.0*rb*r0*cos_da + (zb-z0)*(zb-z0)
            if (ds2 <= tiny_ds2) then
                write(*,*) 'ERROR: outflow reference point lies on a_lo face center.'
                stop
            end if

            normal_proj = -r0*sin_da
            kb = normal_proj/ds2
            eta = kb*dn
            if (abs(eta + 2.0) <= tiny_den) then
                write(*,*) 'ERROR: eta + 2 is too small on a_lo outflow face.'
                stop
            end if

            gamma = 2.0*eta/(eta + 2.0)
            rhs_add = cface*gamma*phi_infty

            slot_val = A_values(mA+3)
            if (abs(slot_val) > tiny_slot) then
                diag_add = cface*gamma - (-slot_val)
            else
                diag_add = cface*gamma
            end if

            A_values(mA  ) = A_values(mA  ) + diag_add
            A_values(mA+3) = 0.0
            RHS(mR) = RHS(mR) + rhs_add
        end if

        ! a_hi face, stencil slot 4.
        ! Remove the existing plus-alpha coupling if present, then apply the
        ! equivalent outflow correction to the diagonal and RHS.
        if (bc(4) == BC_OUTFLOW .and. j == iu(2)) then
            rb = rcell
            alphab = alpha_p
            zb = z_c
            cface = dr*dz/(rcell*da)
            dn = rcell*da

            dalpha = alphab - alpha0
            cos_da = cos(dalpha)
            sin_da = sin(dalpha)
            ds2 = rb*rb + r0*r0 - 2.0*rb*r0*cos_da + (zb-z0)*(zb-z0)
            if (ds2 <= tiny_ds2) then
                write(*,*) 'ERROR: outflow reference point lies on a_hi face center.'
                stop
            end if

            normal_proj = r0*sin_da
            kb = normal_proj/ds2
            eta = kb*dn
            if (abs(eta + 2.0) <= tiny_den) then
                write(*,*) 'ERROR: eta + 2 is too small on a_hi outflow face.'
                stop
            end if

            gamma = 2.0*eta/(eta + 2.0)
            rhs_add = cface*gamma*phi_infty

            slot_val = A_values(mA+4)
            if (abs(slot_val) > tiny_slot) then
                diag_add = cface*gamma - (-slot_val)
            else
                diag_add = cface*gamma
            end if

            A_values(mA  ) = A_values(mA  ) + diag_add
            A_values(mA+4) = 0.0
            RHS(mR) = RHS(mR) + rhs_add
        end if

        ! z_lo face, stencil slot 5.
        ! Remove the existing minus-z coupling if present, then apply the
        ! equivalent outflow correction to the diagonal and RHS.
        if (bc(5) == BC_OUTFLOW .and. k == il(3)) then
            rb = rcell
            alphab = alpha_c
            zb = z_m
            cface = rcell*dr*da/dz
            dn = dz

            dalpha = alphab - alpha0
            cos_da = cos(dalpha)
            ds2 = rb*rb + r0*r0 - 2.0*rb*r0*cos_da + (zb-z0)*(zb-z0)
            if (ds2 <= tiny_ds2) then
                write(*,*) 'ERROR: outflow reference point lies on z_lo face center.'
                stop
            end if

            normal_proj = -(zb-z0)
            kb = normal_proj/ds2
            eta = kb*dn
            if (abs(eta + 2.0) <= tiny_den) then
                write(*,*) 'ERROR: eta + 2 is too small on z_lo outflow face.'
                stop
            end if

            gamma = 2.0*eta/(eta + 2.0)
            rhs_add = cface*gamma*phi_infty

            slot_val = A_values(mA+5)
            if (abs(slot_val) > tiny_slot) then
                diag_add = cface*gamma - (-slot_val)
            else
                diag_add = cface*gamma
            end if

            A_values(mA  ) = A_values(mA  ) + diag_add
            A_values(mA+5) = 0.0
            RHS(mR) = RHS(mR) + rhs_add
        end if

        ! z_hi face, stencil slot 6.
        ! Remove the existing plus-z coupling if present, then apply the
        ! equivalent outflow correction to the diagonal and RHS.
        if (bc(6) == BC_OUTFLOW .and. k == iu(3)) then
            rb = rcell
            alphab = alpha_c
            zb = z_p
            cface = rcell*dr*da/dz
            dn = dz

            dalpha = alphab - alpha0
            cos_da = cos(dalpha)
            ds2 = rb*rb + r0*r0 - 2.0*rb*r0*cos_da + (zb-z0)*(zb-z0)
            if (ds2 <= tiny_ds2) then
                write(*,*) 'ERROR: outflow reference point lies on z_hi face center.'
                stop
            end if

            normal_proj = zb-z0
            kb = normal_proj/ds2
            eta = kb*dn
            if (abs(eta + 2.0) <= tiny_den) then
                write(*,*) 'ERROR: eta + 2 is too small on z_hi outflow face.'
                stop
            end if

            gamma = 2.0*eta/(eta + 2.0)
            rhs_add = cface*gamma*phi_infty

            slot_val = A_values(mA+6)
            if (abs(slot_val) > tiny_slot) then
                diag_add = cface*gamma - (-slot_val)
            else
                diag_add = cface*gamma
            end if

            A_values(mA  ) = A_values(mA  ) + diag_add
            A_values(mA+6) = 0.0
            RHS(mR) = RHS(mR) + rhs_add
        end if

        mA = mA + 7
        mR = mR + 1

    end do
    end do
    end do

end subroutine sub_D03_hypre_3Draz_uniform_bc_A_outflow