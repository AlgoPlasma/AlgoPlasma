!> @file sub_D02_hypre_3Dxyz_bc_A_outflow.f90
!> @brief Apply 3D outflow boundary conditions to Hypre matrix and RHS.
!> @details
!> This subroutine modifies the 7-point-stencil coefficient array ``A_values`` and
!> the right-hand side vector ``rho1d`` for a 3D Cartesian grid to impose an
!> outflow-type boundary condition (``bc == 4``) on any of the six faces of the
!> domain. The outflow condition is formulated with respect to a reference
!> point ``r0``, using the local radial direction to compute a coefficient ``kb``.
!> For each boundary cell, the diagonal entry is adjusted and the
!> corresponding ghost-cell neighbor coefficient is set to zero. The RHS is
!> also updated to incorporate the far-field value ``phi_infty``.
!>
!> @author Yinjian ZHAO (2025/12/02)

!> @param[in]  il: integer (1:3), cell-center lower indices in x,y,z.
!> @param[in]  iu: integer (1:3), cell-center upper indices in x,y,z.
!> @param[in,out] A_values: real(:), flattened 7-point stencil coefficients
!>                          for all cells in the domain, modified in-place.
!> @param[in,out] rho1d: real(:), right-hand side vector for all cells,
!>                       modified in-place by boundary contributions.
!> @param[in]  bc: integer (1:6), boundary condition type per face:
!>                 (xmin,xmax,ymin,ymax,zmin,zmax); 4 indicates outflow.
!> @param[in]  phi_infty: real, far-field potential value used in outflow BC.
!> @param[in]  r0: real (1:3), reference point (e.g. sphere center) for
!>                 computing radial direction and kb.

subroutine sub_D02_hypre_3Dxyz_bc_A_outflow(il,iu,A_values,rho1d,bc,phi_infty,r0)

    implicit none

    !------------------------------------------------------------------
    ! Arguments
    !------------------------------------------------------------------
    integer,dimension(1:3) :: il,iu
    real,dimension(:) :: A_values,rho1d
    integer,dimension(1:6) :: bc
    real :: phi_infty
    real,dimension(1:3) :: r0

    !------------------------------------------------------------------
    ! Locals
    !------------------------------------------------------------------
    integer :: nentries,m,k,j,i,l
    real :: rk,rj,ri,kb
    real,dimension(1:3) :: rb

    nentries = 7

    m = 1
    do k = il(3),iu(3)
    rk = real(k) - 0.5
    do j = il(2),iu(2)
    rj = real(j) - 0.5
    do i = il(1),iu(1)
    ri = real(i) - 0.5

        do l = 0,nentries-1

            ! xmin face: i = il(1)
            if (bc(1) == 4 .and. i == il(1)) then
                rb(1:3) = (/real(il(1) - 1),rj,rk/) - r0(1:3)
                kb = -rb(1)/dot_product(rb,rb)
                ! (i,j,k)
                if (l == 0) A_values(m) = A_values(m) + (kb - 2.0)/(kb + 2.0)
                if (l == 1) A_values(m) = 0.0  ! (i-1,j,k)
            end if

            ! xmax face: i = iu(1)
            if (bc(2) == 4 .and. i == iu(1)) then
                rb(1:3) = (/real(iu(1)),rj,rk/) - r0(1:3)
                kb = rb(1)/dot_product(rb,rb)
                ! (i,j,k)
                if (l == 0) A_values(m) = A_values(m) + (kb - 2.0)/(kb + 2.0)
                if (l == 2) A_values(m) = 0.0  ! (i+1,j,k)
            end if

            ! ymin face: j = il(2)
            if (bc(3) == 4 .and. j == il(2)) then
                rb(1:3) = (/ri,real(il(2) - 1),rk/) - r0(1:3)
                kb = -rb(2)/dot_product(rb,rb)
                ! (i,j,k)
                if (l == 0) A_values(m) = A_values(m) + (kb - 2.0)/(kb + 2.0)
                if (l == 3) A_values(m) = 0.0  ! (i,j-1,k)
            end if

            ! ymax face: j = iu(2)
            if (bc(4) == 4 .and. j == iu(2)) then
                rb(1:3) = (/ri,real(iu(2)),rk/) - r0(1:3)
                kb = rb(2)/dot_product(rb,rb)
                ! (i,j,k)
                if (l == 0) A_values(m) = A_values(m) + (kb - 2.0)/(kb + 2.0)
                if (l == 4) A_values(m) = 0.0  ! (i,j+1,k)
            end if

            ! zmin face: k = il(3)
            if (bc(5) == 4 .and. k == il(3)) then
                rb(1:3) = (/ri,rj,real(il(3) - 1)/) - r0(1:3)
                kb = -rb(3)/dot_product(rb,rb)
                ! (i,j,k)
                if (l == 0) A_values(m) = A_values(m) + (kb - 2.0)/(kb + 2.0)
                if (l == 5) A_values(m) = 0.0  ! (i,j,k-1)
            end if

            ! zmax face: k = iu(3)
            if (bc(6) == 4 .and. k == iu(3)) then
                rb(1:3) = (/ri,rj,real(iu(3))/) - r0(1:3)
                kb = rb(3)/dot_product(rb,rb)
                ! (i,j,k)
                if (l == 0) A_values(m) = A_values(m) + (kb - 2.0)/(kb + 2.0)
                if (l == 6) A_values(m) = 0.0  ! (i,j,k+1)
            end if

            m = m + 1

        end do
    end do
    end do
    end do

    m = 1
    do k = il(3),iu(3)
    rk = real(k) - 0.5
    do j = il(2),iu(2)
    rj = real(j) - 0.5
    do i = il(1),iu(1)
    ri = real(i) - 0.5

        ! xmin:
        if (bc(1) == 4 .and. i == il(1)) then
            rb(1:3) = (/real(il(1) - 1),rj,rk/) - r0(1:3)
            kb = -rb(1)/dot_product(rb,rb)
            rho1d(m) = rho1d(m) + 2.0*kb/(kb + 2.0)*phi_infty
        end if

        ! xmax:
        if (bc(2) == 4 .and. i == iu(1)) then
            rb(1:3) = (/real(iu(1)),rj,rk/) - r0(1:3)
            kb = rb(1)/dot_product(rb,rb)
            rho1d(m) = rho1d(m) + 2.0*kb/(kb + 2.0)*phi_infty
        end if

        ! ymin:
        if (bc(3) == 4 .and. j == il(2)) then
            rb(1:3) = (/ri,real(il(2) - 1),rk/) - r0(1:3)
            kb = -rb(2)/dot_product(rb,rb)
            rho1d(m) = rho1d(m) + 2.0*kb/(kb + 2.0)*phi_infty
        end if

        ! ymax:
        if (bc(4) == 4 .and. j == iu(2)) then
            rb(1:3) = (/ri,real(iu(2)),rk/) - r0(1:3)
            kb = rb(2)/dot_product(rb,rb)
            rho1d(m) = rho1d(m) + 2.0*kb/(kb + 2.0)*phi_infty
        end if

        ! zmin:
        if (bc(5) == 4 .and. k == il(3)) then
            rb(1:3) = (/ri,rj,real(il(3) - 1)/) - r0(1:3)
            kb = -rb(3)/dot_product(rb,rb)
            rho1d(m) = rho1d(m) + 2.0*kb/(kb + 2.0)*phi_infty
        end if

        ! zmax:
        if (bc(6) == 4 .and. k == iu(3)) then
            rb(1:3) = (/ri,rj,real(iu(3))/) - r0(1:3)
            kb = rb(3)/dot_product(rb,rb)
            rho1d(m) = rho1d(m) + 2.0*kb/(kb + 2.0)*phi_infty
        end if

        m = m + 1

    end do
    end do
    end do

end subroutine sub_D02_hypre_3Dxyz_bc_A_outflow
