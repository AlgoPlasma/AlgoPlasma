!> @file sub_D02_hypre_3Dxyz_bc_A.f90
!> @brief Set the coefficient matrix A with boundary conditions for Hypre.
!> @author Yinjian ZHAO (2025/11/06)

!> @param[in] il: integer (1:3), cell-center lower indices in x,y,z.

!> @param[in] iu: integer (1:3), cell-center upper indices in x,y,z.

!> @param[out] A_values: real (1:N), 1D coefficient matrix A,
!> ``N = 7 * (iu(1)-il(1)+1)*(iu(2)-il(2)+1)*(iu(3)-il(3)+1)``.
!> - The value/loop order follows:
!> ```
!> m = 1
!> do k = il(3),iu(3)
!> do j = il(2),iu(2)
!> do i = il(1),iu(1)
!> do l = 0,6
!>     A_values(m)
!>     m = m + 1
!> ......
!> ```

!> @param[inout] rho1d: real (1:N), 1D right-hand side (charge density) term array,
!> ``N = (iu(1)-il(1)+1)*(iu(2)-il(2)+1)*(iu(3)-il(3)+1)``.
!> - rho1d should be assigned
!> \f$ h^2 \rho / \varepsilon_0 \f$ before
!> passing into this subroutine, such that it can then be modified based on
!> the boundary conditions with values ``phibc``,
!> \f$h = \Delta x = \Delta y = \Delta z\f$ is the cell size,
!> \f$\rho\f$ is the cell-centered charge density,
!> \f$\varepsilon_0\f$ is the vacuum permittivity.
!> - The value/loop order follows:
!> ```
!> m = 1
!> do k = il(3),iu(3)
!> do j = il(2),iu(2)
!> do i = il(1),iu(1)
!>     rho1d(m)
!>     m = m + 1
!> ......
!> ```

!> @param[in] bc: integer (1:6), boundary types considered here:
!> 1 (Dirichlet), 2 (Neumann),
!> for xmin, xmax, ymin, ymax, zmin, zmax.

!> @param[in] phibc: real (1:6), boundary values.
!>            - For Dirichlet, phibc = the fixed potentials
!>            right on the boundary surfaces (in between two cell-centered grids).
!>            - For Neumann, phibc = h*E, h is the cell size,
!>            E is the electric field at the boundary.
!>            The correct sign of E should be provided.

!> @note
!> - This Poisson solver is based on cell-centered grids.
!> - The offsets (l) are
!> 0(i,j,k),
!> 1(i-1,j,k), 2(i+1,j,k), 3(i,j-1,k),
!> 4(i,j+1,k), 5(i,j,k-1), 6(i,j,k+1).
!> - The `bc(1:6)` corresponds to the above offsets.
!> - We follow the convention that array starts from 1 in Fortran, but 0 in C.
!> - Normalization: \f$\Delta x=\Delta y=\Delta z=h\f$.
!> For boundary types other than Dirichlet (1) and Neumann (2),
!> other subroutines should be called AFTER this subroutine, because
!> the main coefficients inside the domain are set first in this subroutine.

subroutine sub_D02_hypre_3Dxyz_bc_A(il,iu,A_values,rho1d,bc,phibc)

    implicit none

    integer,dimension(1:3) :: il,iu
    real,dimension(:) :: A_values,rho1d
    integer :: bc(1:6)
    real :: phibc(1:6)

    integer :: nentries,nvalues
    integer :: i,j,k,l,m

    nentries = 7
    nvalues = (iu(1)-il(1)+1)*(iu(2)-il(2)+1)*(iu(3)-il(3)+1)*nentries

    ! Set interior coefficients.
    do i = 1,nvalues,nentries
        A_values(i) = 6.0
        do j = 1,nentries-1
            A_values(i+j) = -1.0
        end do
    end do

    ! Set A_values for boundaries.
    m = 1
    do k = il(3),iu(3)
    do j = il(2),iu(2)
    do i = il(1),iu(1)
        do l = 0,nentries-1

            ! Set Dirichlet boundaries.
            if (bc(1)==1.and.i==il(1)) then
                if (l==0) A_values(m) = A_values(m) + 1.0 !i,j,k
                if (l==1) A_values(m) = 0.0 ! i-1,j,k
            end if
            if (bc(2)==1.and.i==iu(1)) then
                if (l==0) A_values(m) = A_values(m) + 1.0 !i,j,k
                if (l==2) A_values(m) = 0.0 ! i+1,j,k
            end if
            if (bc(3)==1.and.j==il(2)) then
                if (l==0) A_values(m) = A_values(m) + 1.0 !i,j,k
                if (l==3) A_values(m) = 0.0 ! i,j-1,k
            end if
            if (bc(4)==1.and.j==iu(2)) then
                if (l==0) A_values(m) = A_values(m) + 1.0 !i,j,k
                if (l==4) A_values(m) = 0.0 ! i,j+1,k
            end if
            if (bc(5)==1.and.k==il(3)) then
                if (l==0) A_values(m) = A_values(m) + 1.0 !i,j,k
                if (l==5) A_values(m) = 0.0 ! i,j,k-1
            end if
            if (bc(6)==1.and.k==iu(3)) then
                if (l==0) A_values(m) = A_values(m) + 1.0 !i,j,k
                if (l==6) A_values(m) = 0.0 ! i,j,k+1
            end if

            ! Set Neumann boundaries.
            if (bc(1)==2.and.i==il(1)) then
                if (l==0) A_values(m) = A_values(m) - 1.0 !i,j,k
                if (l==1) A_values(m) = 0.0 ! i-1,j,k
            end if
            if (bc(2)==2.and.i==iu(1)) then
                if (l==0) A_values(m) = A_values(m) - 1.0 !i,j,k
                if (l==2) A_values(m) = 0.0 ! i-1,j,k
            end if
            if (bc(3)==2.and.j==il(2)) then
                if (l==0) A_values(m) = A_values(m) - 1.0 !i,j,k
                if (l==3) A_values(m) = 0.0 ! i-1,j,k
            end if
            if (bc(4)==2.and.j==iu(2)) then
                if (l==0) A_values(m) = A_values(m) - 1.0 !i,j,k
                if (l==4) A_values(m) = 0.0 ! i-1,j,k
            end if
            if (bc(5)==2.and.k==il(3)) then
                if (l==0) A_values(m) = A_values(m) - 1.0 !i,j,k
                if (l==5) A_values(m) = 0.0 ! i-1,j,k
            end if
            if (bc(6)==2.and.k==iu(3)) then
                if (l==0) A_values(m) = A_values(m) - 1.0 !i,j,k
                if (l==6) A_values(m) = 0.0 ! i-1,j,k
            end if

            m = m + 1

        end do
    end do
    end do
    end do

    ! Set rho1d.
    m = 1
    do k = il(3),iu(3)
    do j = il(2),iu(2)
    do i = il(1),iu(1)

        ! Set Dirichlet boundaries.
        if (bc(1)==1.and.i==il(1)) rho1d(m) = rho1d(m) + 2.0*phibc(1)
        if (bc(2)==1.and.i==iu(1)) rho1d(m) = rho1d(m) + 2.0*phibc(2)
        if (bc(3)==1.and.j==il(2)) rho1d(m) = rho1d(m) + 2.0*phibc(3)
        if (bc(4)==1.and.j==iu(2)) rho1d(m) = rho1d(m) + 2.0*phibc(4)
        if (bc(5)==1.and.k==il(3)) rho1d(m) = rho1d(m) + 2.0*phibc(5)
        if (bc(6)==1.and.k==iu(3)) rho1d(m) = rho1d(m) + 2.0*phibc(6)

        ! Set Neumann boundaries.
        if (bc(1)==2.and.i==il(1)) rho1d(m) = rho1d(m) + phibc(1)
        if (bc(2)==2.and.i==iu(1)) rho1d(m) = rho1d(m) - phibc(2)
        if (bc(3)==2.and.j==il(2)) rho1d(m) = rho1d(m) + phibc(3)
        if (bc(4)==2.and.j==iu(2)) rho1d(m) = rho1d(m) - phibc(4)
        if (bc(5)==2.and.k==il(3)) rho1d(m) = rho1d(m) + phibc(5)
        if (bc(6)==2.and.k==iu(3)) rho1d(m) = rho1d(m) - phibc(6)

        m = m + 1

    end do
    end do
    end do

end
