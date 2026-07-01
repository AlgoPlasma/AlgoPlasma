!> @file sub_D02_hypre_3Dxyz_bc_A_dielectric.f90
!> @brief  Assemble dielectric (surface–charge) boundary contributions
!>         to the Poisson matrix and RHS.
!>
!> @author Yinjian ZHAO (2025/11/07)

!> @param[in] il: integer (1:3), cell-center lower indices in x,y,z.

!> @param[in] iu: integer (1:3), cell-center upper indices in x,y,z.

!> @param[inout] A_values: real (1:N), 1D coefficient matrix A,
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
!>   The dielectric modifications are applied additively to the
!>   existing entries.

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
!> Surface charge corrections for dielectric faces are added in place.

!> @param[in] bc: integer (1:6), boundary types for
!> `xmin, xmax, ymin, ymax, zmin, zmax`.  Here only
!> bc(*) = 3 (dielectric with surface charge) is handled.
!> Other values are ignored in this routine.

!> @param[in] sx1:
!> real (:,:), optional surface charge term at `xmin`. Declared as
!> `sx1(il(2)-1:iu(2),il(3)-1:iu(3))`, it stores
!> \f$ + h \sigma / \varepsilon_0 \f$ on the lower x-face for each
!> \f$(j,k)\f$ of the local block, with
!> \f$h=\Delta x=\Delta y=\Delta z\f$.
!> Notice that s are nodal arrays, such that -1 is needed.
!> @param[in] sx2:
!> real (:,:), at `xmax`, dimension `(il(2)-1:iu(2),il(3)-1:iu(3))`,
!> it stores
!> \f$ - h \sigma / \varepsilon_0 \f$ on the upper x-face.
!> @param[in] sy1:
!> real (:,:), at `ymin`, dimension `(il(1)-1:iu(1),il(3)-1:iu(3))`.
!> @param[in] sy2:
!> real (:,:), at `ymax`, dimension `(il(1)-1:iu(1),il(3)-1:iu(3))`.
!> @param[in] sz1:
!> real (:,:), at `zmin`, dimension `(il(1)-1:iu(1),il(2)-1:iu(2))`.
!> @param[in] sz2:
!> real (:,:), at `zmax`, dimension `(il(1)-1:iu(1),il(2)-1:iu(2))`.

!> @note
!> - The Poisson operator is discretized on a cell-centered grid with
!>   a 7-point stencil and uniform spacing
!>   \f$\Delta x=\Delta y=\Delta z=h\f$.
!> - The logical indices `il(:), iu(:)` describe the local 3D block of
!>   cells owned by this MPI rank. The surface charge arrays are
!>   declared with index ranges that match the corresponding boundary
!>   faces:
!>   - `sx1(j,k), sx2(j,k)` share the \f$(j,k)\f$ ranges of the block,
!>   - `sy1(i,k), sy2(i,k)` share the \f$(i,k)\f$ ranges,
!>   - `sz1(i,j), sz2(i,j)` share the \f$(i,j)\f$ ranges.
!>   Thus, no additional index shifts are needed inside the loops.
!> - For a direction where `bc(face) /= 3`, the corresponding surface
!>   charge array may be omitted — the dummy argument is `optional` and
!>   is never referenced.
!> - The sign changes, ``sx1,sy1,sz1`` \f$ = h \sigma / \varepsilon_0\f$,
!>   while ``sx2,sy2,sz2`` \f$ = - h \sigma / \varepsilon_0\f$.

subroutine sub_D02_hypre_3Dxyz_bc_A_dielectric(il,iu,A_values,rho1d,bc,&
    sx1,sx2,sy1,sy2,sz1,sz2)

    implicit none

    !------------------------------------------------------------------
    ! Arguments
    !------------------------------------------------------------------
    integer,dimension(1:3) :: il,iu
    real,dimension(:)      :: A_values,rho1d
    integer,dimension(1:6) :: bc
    ! For faces with bc /= 3 the corresponding s-array may be omitted
    ! (dummy argument is OPTIONAL) and is never referenced.
    real,dimension(il(2)-1:iu(2),il(3)-1:iu(3)),optional :: sx1,sx2
    real,dimension(il(1)-1:iu(1),il(3)-1:iu(3)),optional :: sy1,sy2
    real,dimension(il(1)-1:iu(1),il(2)-1:iu(2)),optional :: sz1,sz2

    !------------------------------------------------------------------
    ! Locals
    !------------------------------------------------------------------
    integer :: nentries
    integer :: i,j,k,l,m

    nentries = 7

    !------------------------------------------------------------------
    ! Set A_values: modify the matrix for dielectric faces (bc = 3)
    ! by adjusting the diagonal and zeroing the out-of-domain neighbor
    ! entries, in analogy with Neumann BCs.
    !------------------------------------------------------------------
    m = 1
    do k = il(3),iu(3)
    do j = il(2),iu(2)
    do i = il(1),iu(1)
        do l = 0,nentries-1

            ! xmin face: i = il(1)
            if (bc(1)==3 .and. i==il(1)) then
                if (l==0) A_values(m) = A_values(m) - 1.0  ! (i,j,k)
                if (l==1) A_values(m) = 0.0                ! (i-1,j,k)
            end if
            ! xmax face: i = iu(1)
            if (bc(2)==3 .and. i==iu(1)) then
                if (l==0) A_values(m) = A_values(m) - 1.0  ! (i,j,k)
                if (l==2) A_values(m) = 0.0                ! (i+1,j,k)
            end if
            ! ymin face: j = il(2)
            if (bc(3)==3 .and. j==il(2)) then
                if (l==0) A_values(m) = A_values(m) - 1.0  ! (i,j,k)
                if (l==3) A_values(m) = 0.0                ! (i,j-1,k)
            end if
            ! ymax face: j = iu(2)
            if (bc(4)==3 .and. j==iu(2)) then
                if (l==0) A_values(m) = A_values(m) - 1.0  ! (i,j,k)
                if (l==4) A_values(m) = 0.0                ! (i,j+1,k)
            end if
            ! zmin face: k = il(3)
            if (bc(5)==3 .and. k==il(3)) then
                if (l==0) A_values(m) = A_values(m) - 1.0  ! (i,j,k)
                if (l==5) A_values(m) = 0.0                ! (i,j,k-1)
            end if
            ! zmax face: k = iu(3)
            if (bc(6)==3 .and. k==iu(3)) then
                if (l==0) A_values(m) = A_values(m) - 1.0  ! (i,j,k)
                if (l==6) A_values(m) = 0.0                ! (i,j,k+1)
            end if

            m = m + 1

        end do
    end do
    end do
    end do

    !------------------------------------------------------------------
    ! Set rho1d: add surface charge contributions for dielectric faces.
    ! The surface charge arrays are OPTIONAL; if a face is marked as
    ! dielectric (bc = 3) but the corresponding array is not present,
    ! execution stops with an error message.
    !------------------------------------------------------------------
    m = 1
    do k = il(3),iu(3)
    do j = il(2),iu(2)
    do i = il(1),iu(1)

        ! xmin: add sx1(j,k)
        if (bc(1)==3 .and. i==il(1)) then
            if (.not. present(sx1)) then
                write(*,*) "Error: sx1 not present in sub_D02_hypre_3Dxyz_bc_A_dielectric"
                stop
            end if
            rho1d(m) = rho1d(m) + 0.25*(sx1(j-1,k-1)+sx1(j-1,k)+sx1(j,k-1)+sx1(j,k))
        end if

        ! xmax: subtract sx2(j,k)
        if (bc(2)==3 .and. i==iu(1)) then
            if (.not. present(sx2)) then
                write(*,*) "Error: sx2 not present in sub_D02_hypre_3Dxyz_bc_A_dielectric"
                stop
            end if
            rho1d(m) = rho1d(m) - 0.25*(sx2(j-1,k-1)+sx2(j-1,k)+sx2(j,k-1)+sx2(j,k))
        end if

        ! ymin: add sy1(i,k)
        if (bc(3)==3 .and. j==il(2)) then
            if (.not. present(sy1)) then
                write(*,*) "Error: sy1 not present in sub_D02_hypre_3Dxyz_bc_A_dielectric"
                stop
            end if
            rho1d(m) = rho1d(m) + 0.25*(sy1(i-1,k-1)+sy1(i-1,k)+sy1(i,k-1)+sy1(i,k))
        end if

        ! ymax: subtract sy2(i,k)
        if (bc(4)==3 .and. j==iu(2)) then
            if (.not. present(sy2)) then
                write(*,*) "Error: sy2 not present in sub_D02_hypre_3Dxyz_bc_A_dielectric"
                stop
            end if
            rho1d(m) = rho1d(m) - 0.25*(sy2(i-1,k-1)+sy2(i-1,k)+sy2(i,k-1)+sy2(i,k))
        end if

        ! zmin: add sz1(i,j)
        if (bc(5)==3 .and. k==il(3)) then
            if (.not. present(sz1)) then
                write(*,*) "Error: sz1 not present in sub_D02_hypre_3Dxyz_bc_A_dielectric"
                stop
            end if
            rho1d(m) = rho1d(m) + 0.25*(sz1(i-1,j-1)+sz1(i-1,j)+sz1(i,j-1)+sz1(i,j))
        end if

        ! zmax: subtract sz2(i,j)
        if (bc(6)==3 .and. k==iu(3)) then
            if (.not. present(sz2)) then
                write(*,*) "Error: sz2 not present in sub_D02_hypre_3Dxyz_bc_A_dielectric"
                stop
            end if
            rho1d(m) = rho1d(m) - 0.25*(sz2(i-1,j-1)+sz2(i-1,j)+sz2(i,j-1)+sz2(i,j))
        end if

        m = m + 1

    end do
    end do
    end do

end
