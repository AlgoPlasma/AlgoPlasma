!> @file sub_D03_hypre_3Draz_uniform_bc_A_dielectric.f90
!> @brief Apply dielectric/surface-charge boundary corrections to the
!> already assembled 7-point matrix and RHS for the single-domain
!> 3D cylindrical uniform-grid Poisson equation on a cell-centered grid.
!> @details
!> This routine is intended to be called after
!> `sub_D03_hypre_3Draz_uniform_A`.
!>
!> It modifies the already assembled `A_values` and `RHS` in place on the
!> cylindrical `(r,alpha,z)` cell-centered uniform grid.
!>
!> The stencil order is
!> 0(i,j,k), 1(i-1,j,k), 2(i+1,j,k), 3(i,j-1,k), 4(i,j+1,k),
!> 5(i,j,k-1), 6(i,j,k+1).
!>
!> The face order in `bc` is
!> `(r_lo,r_hi,a_lo,a_hi,z_lo,z_hi)`.
!>
!> By convention, only faces with `bc(face) == 4` are processed here,
!> corresponding to
!> `4 = BC_DIELECTRIC`.
!>
!> The optional surface arrays are nodal arrays defined on the
!> corresponding boundary faces and are averaged with a four-node
!> arithmetic mean before being added to the cell-centered RHS.
!>
!> These arrays are assumed to already contain the properly scaled
!> surface-charge contribution for each face, so this routine only
!> performs:
!> - four-node averaging from nodal values to the adjacent cell center,
!> - sign handling according to the outward face orientation,
!> - removal of the corresponding matrix coupling across the dielectric face.
!>
!> The face-array locations are:
!> - `sr_lo` / `sr_hi` on `(alpha,z)` nodes,
!> - `sa_lo` / `sa_hi` on `(r,z)` nodes,
!> - `sz_lo` / `sz_hi` on `(r,alpha)` nodes.
!>
!> Matrix handling:
!> if the corresponding off-diagonal stencil slot already contains a
!> nonzero value, that neighbor coupling is removed by zeroing the slot
!> and subtracting its associated face contribution from the diagonal.
!> If the slot is already zero, the matrix is left unchanged and only the
!> RHS surface-charge term is applied.
!>
!> Sign convention for the RHS correction in the current implementation:
!> - `r_lo`, `a_lo`, `z_lo`: add the averaged surface term,
!> - `r_hi`, `a_hi`, `z_hi`: subtract the averaged surface term.
!>
!> The routine stops if a dielectric face is requested but the
!> corresponding optional surface array is not present.
!> @author Baisheng WANG(2026/04/27)
!
!> @param[in] il: integer (1:3), lower cell-center indices in
!> `r,alpha,z`.
!> @param[in] iu: integer (1:3), upper cell-center indices in
!> `r,alpha,z`.
!> @param[in,out] A_values: real (:), flattened 7-point stencil
!> coefficients.
!> @param[in,out] RHS: real (:), flattened right-hand-side array.
!> @param[in] bc: integer (1:6), boundary-type codes on
!> `(r_lo,r_hi,a_lo,a_hi,z_lo,z_hi)`.
!> @param[in] sr_lo: optional real
!> `(il(2)-1:iu(2),il(3)-1:iu(3))`, nodal surface-charge array on the
!> `r_lo` face in `(alpha,z)`.
!> @param[in] sr_hi: optional real
!> `(il(2)-1:iu(2),il(3)-1:iu(3))`, nodal surface-charge array on the
!> `r_hi` face in `(alpha,z)`.
!> @param[in] sa_lo: optional real
!> `(il(1)-1:iu(1),il(3)-1:iu(3))`, nodal surface-charge array on the
!> `a_lo` face in `(r,z)`.
!> @param[in] sa_hi: optional real
!> `(il(1)-1:iu(1),il(3)-1:iu(3))`, nodal surface-charge array on the
!> `a_hi` face in `(r,z)`.
!> @param[in] sz_lo: optional real
!> `(il(1)-1:iu(1),il(2)-1:iu(2))`, nodal surface-charge array on the
!> `z_lo` face in `(r,alpha)`.
!> @param[in] sz_hi: optional real
!> `(il(1)-1:iu(1),il(2)-1:iu(2))`, nodal surface-charge array on the
!> `z_hi` face in `(r,alpha)`.
subroutine sub_D03_hypre_3Draz_uniform_bc_A_dielectric( &
    il,iu,A_values,RHS,bc,sr_lo,sr_hi,sa_lo,sa_hi,sz_lo,sz_hi)

    implicit none

    integer,dimension(1:3) :: il,iu
    real,dimension(:) :: A_values,RHS
    integer,dimension(1:6) :: bc
    real,dimension(il(2)-1:iu(2),il(3)-1:iu(3)),optional :: sr_lo,sr_hi
    real,dimension(il(1)-1:iu(1),il(3)-1:iu(3)),optional :: sa_lo,sa_hi
    real,dimension(il(1)-1:iu(1),il(2)-1:iu(2)),optional :: sz_lo,sz_hi

    integer,parameter :: BC_DIELECTRIC = 4
    real,parameter :: tiny_slot = 1.0e-30

    integer :: i,j,k,mA,mR
    real :: slot_val

    mA = 1
    mR = 1
    do k = il(3),iu(3)
    do j = il(2),iu(2)
    do i = il(1),iu(1)

        ! r_lo face, stencil slot 1.
        ! Remove the existing minus-r coupling if present, then add the
        ! averaged dielectric/surface-charge contribution to the RHS.
        if (bc(1) == BC_DIELECTRIC .and. i == il(1)) then
            slot_val = A_values(mA+1)
            if (abs(slot_val) > tiny_slot) then
                A_values(mA) = A_values(mA) + slot_val
            end if
            A_values(mA+1) = 0.0

            if (.not. present(sr_lo)) then
                write(*,*) 'ERROR: sr_lo not present in dielectric BC routine.'
                stop
            end if

            RHS(mR) = RHS(mR) + 0.25*( &
                sr_lo(j-1,k-1) + sr_lo(j-1,k  ) + &
                sr_lo(j  ,k-1) + sr_lo(j  ,k  ) )
        end if

        ! r_hi face, stencil slot 2.
        ! Remove the existing plus-r coupling if present, then apply the
        ! signed dielectric/surface-charge contribution to the RHS.
        if (bc(2) == BC_DIELECTRIC .and. i == iu(1)) then
            slot_val = A_values(mA+2)
            if (abs(slot_val) > tiny_slot) then
                A_values(mA) = A_values(mA) + slot_val
            end if
            A_values(mA+2) = 0.0

            if (.not. present(sr_hi)) then
                write(*,*) 'ERROR: sr_hi not present in dielectric BC routine.'
                stop
            end if

            RHS(mR) = RHS(mR) - 0.25*( &
                sr_hi(j-1,k-1) + sr_hi(j-1,k  ) + &
                sr_hi(j  ,k-1) + sr_hi(j  ,k  ) )
        end if

        ! a_lo face, stencil slot 3.
        ! Remove the existing minus-alpha coupling if present, then add the
        ! averaged dielectric/surface-charge contribution to the RHS.
        if (bc(3) == BC_DIELECTRIC .and. j == il(2)) then
            slot_val = A_values(mA+3)
            if (abs(slot_val) > tiny_slot) then
                A_values(mA) = A_values(mA) + slot_val
            end if
            A_values(mA+3) = 0.0

            if (.not. present(sa_lo)) then
                write(*,*) 'ERROR: sa_lo not present in dielectric BC routine.'
                stop
            end if

            RHS(mR) = RHS(mR) + 0.25*( &
                sa_lo(i-1,k-1) + sa_lo(i-1,k  ) + &
                sa_lo(i  ,k-1) + sa_lo(i  ,k  ) )
        end if

        ! a_hi face, stencil slot 4.
        ! Remove the existing plus-alpha coupling if present, then apply the
        ! signed dielectric/surface-charge contribution to the RHS.
        if (bc(4) == BC_DIELECTRIC .and. j == iu(2)) then
            slot_val = A_values(mA+4)
            if (abs(slot_val) > tiny_slot) then
                A_values(mA) = A_values(mA) + slot_val
            end if
            A_values(mA+4) = 0.0

            if (.not. present(sa_hi)) then
                write(*,*) 'ERROR: sa_hi not present in dielectric BC routine.'
                stop
            end if

            RHS(mR) = RHS(mR) - 0.25*( &
                sa_hi(i-1,k-1) + sa_hi(i-1,k  ) + &
                sa_hi(i  ,k-1) + sa_hi(i  ,k  ) )
        end if

        ! z_lo face, stencil slot 5.
        ! Remove the existing minus-z coupling if present, then add the
        ! averaged dielectric/surface-charge contribution to the RHS.
        if (bc(5) == BC_DIELECTRIC .and. k == il(3)) then
            slot_val = A_values(mA+5)
            if (abs(slot_val) > tiny_slot) then
                A_values(mA) = A_values(mA) + slot_val
            end if
            A_values(mA+5) = 0.0

            if (.not. present(sz_lo)) then
                write(*,*) 'ERROR: sz_lo not present in dielectric BC routine.'
                stop
            end if

            RHS(mR) = RHS(mR) + 0.25*( &
                sz_lo(i-1,j-1) + sz_lo(i-1,j  ) + &
                sz_lo(i  ,j-1) + sz_lo(i  ,j  ) )
        end if

        ! z_hi face, stencil slot 6.
        ! Remove the existing plus-z coupling if present, then apply the
        ! signed dielectric/surface-charge contribution to the RHS.
        if (bc(6) == BC_DIELECTRIC .and. k == iu(3)) then
            slot_val = A_values(mA+6)
            if (abs(slot_val) > tiny_slot) then
                A_values(mA) = A_values(mA) + slot_val
            end if
            A_values(mA+6) = 0.0

            if (.not. present(sz_hi)) then
                write(*,*) 'ERROR: sz_hi not present in dielectric BC routine.'
                stop
            end if

            RHS(mR) = RHS(mR) - 0.25*( &
                sz_hi(i-1,j-1) + sz_hi(i-1,j  ) + &
                sz_hi(i  ,j-1) + sz_hi(i  ,j  ) )
        end if

        mA = mA + 7
        mR = mR + 1

    end do
    end do
    end do

end subroutine sub_D03_hypre_3Draz_uniform_bc_A_dielectric