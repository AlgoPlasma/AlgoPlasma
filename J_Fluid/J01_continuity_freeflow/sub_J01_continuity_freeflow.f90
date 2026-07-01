!> @file sub_J01_continuity_freeflow.f90
!> @author Yinjian ZHAO (2025/12/02)
!> @brief Solve the free-flow continuity equation using a 3D
!>   Lax-Friedrichs scheme.
!> @details
!>   It is assumed that ``dx=dy=dz=dt=1`` and that the node-stored
!>   velocity fields ``ux``, ``uy``, ``uz`` are given on the same
!>   indexing layout as the node-stored density ``n`` and remain
!>   constant during this update.
!>   Boundary conditions and guard (ghost) cells are fully set before
!>   calling this subroutine. The arrays ``n``, ``s``, ``ux``, ``uy``,
!>   ``uz``, ``n0`` include extra guard cells with index ranges
!>   ``(il(*)-2:iu(*)+1)``. The method proceeds as:
!>     1. Copy current density ``n`` into ``n0`` (storage of the
!>        old state).
!>     2. Compute Lax-Friedrichs fluxes ``Fx``, ``Fy``, ``Fz`` at
!>        cell faces in the x, y, z directions respectively, using
!>        ``F = u * n`` and ``alpha = max(|u_L|,|u_R|)``.
!>     3. Perform a finite-volume update of ``n`` over
!>        ``i=il(1)-1:iu(1)``, ``j=il(2)-1:iu(2)``,
!>        ``k=il(3)-1:iu(3)`` using the divergence of the fluxes and
!>        the source term ``s``, with unit spacing and time step so that
!>        ``dt/dx = dt/dy = dt/dz = 1``.

!> @param[in] il: integer(1:3), caller-provided reference lower indices in x,y,z.
!> @param[in] iu: integer(1:3), caller-provided reference upper indices in x,y,z.
!> @param[in,out] n: real,dimension(il(1)-2:iu(1)+1,il(2)-2:iu(2)+1, &
!>   il(3)-2:iu(3)+1), node-stored density array (includes guard cells), updated
!>   in-place over ``il(1)-1:iu(1)``, ``il(2)-1:iu(2)``,
!>   ``il(3)-1:iu(3)``.
!> @param[in] s: real,dimension(il(1)-2:iu(1)+1,il(2)-2:iu(2)+1, &
!>   il(3)-2:iu(3)+1), source term on the same indexing layout.
!> @param[in] ux: real,dimension(il(1)-2:iu(1)+1,il(2)-2:iu(2)+1, &
!>   il(3)-2:iu(3)+1), x-velocity field on the same indexing layout.
!> @param[in] uy: real,dimension(il(1)-2:iu(1)+1,il(2)-2:iu(2)+1, &
!>   il(3)-2:iu(3)+1), y-velocity field on the same indexing layout.
!> @param[in] uz: real,dimension(il(1)-2:iu(1)+1,il(2)-2:iu(2)+1, &
!>   il(3)-2:iu(3)+1), z-velocity field on the same indexing layout.
!> @param[out] n0: real,dimension(il(1)-2:iu(1)+1,il(2)-2:iu(2)+1, &
!>   il(3)-2:iu(3)+1), work buffer storing the old values of ``n`` over
!>   all cells (including guard cells).

subroutine sub_J01_continuity_freeflow(il,iu,n,s,ux,uy,uz,n0)

    implicit none

    integer,dimension(1:3) :: il,iu
    real,dimension(il(1)-2:iu(1)+1,il(2)-2:iu(2)+1,il(3)-2:iu(3)+1) :: &
         n,s,ux,uy,uz,n0

    real,dimension(il(1)-2:iu(1),il(2)-1:iu(2),il(3)-1:iu(3)) :: Fx
    real,dimension(il(1)-1:iu(1),il(2)-2:iu(2),il(3)-1:iu(3)) :: Fy
    real,dimension(il(1)-1:iu(1),il(2)-1:iu(2),il(3)-2:iu(3)) :: Fz
    real :: nL,nR,uL,uR,alpha
    integer :: k,j,i

    !---------------------------------------------------------------
    ! 1) Save old n.
    !---------------------------------------------------------------
    n0 = n

    !---------------------------------------------------------------
    ! 2) x: Lax-Friedrichs flux Fx(i+1/2,j,k)
    !    Fx(i,j,k) approximates F_{i+1/2,j,k}.
    !    F_{i+1/2} = 1/2(F_L + F_R) - 1/2 alpha_x (n_R - n_L)
    !    where F = u_x * n and alpha_x = max(|u_L|,|u_R|).
    !---------------------------------------------------------------
    do k = il(3)-1,iu(3)
      do j = il(2)-1,iu(2)
        do i = il(1)-2,iu(1)

          nL = n0(i,j,k)
          nR = n0(i+1,j,k)
          uL = ux(i,j,k)
          uR = ux(i+1,j,k)

          alpha = max(abs(uL),abs(uR))

          Fx(i,j,k) = 0.5*(uL*nL + uR*nR) - 0.5*alpha*(nR - nL)

        end do
      end do
    end do

    !---------------------------------------------------------------
    ! 3) y: Lax-Friedrichs flux Fy(i,j+1/2,k)
    !    Fy(i,j,k) approximates F_{i,j+1/2,k}.
    !---------------------------------------------------------------
    do k = il(3)-1,iu(3)
      do j = il(2)-2,iu(2)
        do i = il(1)-1,iu(1)

          nL = n0(i,j,k)
          nR = n0(i,j+1,k)
          uL = uy(i,j,k)
          uR = uy(i,j+1,k)

          alpha = max(abs(uL),abs(uR))

          Fy(i,j,k) = 0.5*(uL*nL + uR*nR) - 0.5*alpha*(nR - nL)

        end do
      end do
    end do

    !---------------------------------------------------------------
    ! 4) z: Lax-Friedrichs flux Fz(i,j,k+1/2)
    !    Fz(i,j,k) approximates F_{i,j,k+1/2}.
    !---------------------------------------------------------------
    do k = il(3)-2,iu(3)
      do j = il(2)-1,iu(2)
        do i = il(1)-1,iu(1)

          nL = n0(i,j,k)
          nR = n0(i,j,k+1)
          uL = uz(i,j,k)
          uR = uz(i,j,k+1)

          alpha = max(abs(uL),abs(uR))

          Fz(i,j,k) = 0.5*(uL*nL + uR*nR) - 0.5*alpha*(nR - nL)

        end do
      end do
    end do

    !---------------------------------------------------------------
    ! 5) Finite volume update:
    !
    !    n^{new}_{i,j,k} = n^{old}_{i,j,k}
    !       - dt/dx ( Fx_{i+1/2,j,k} - Fx_{i-1/2,j,k} )
    !       - dt/dy ( Fy_{i,j+1/2,k} - Fy_{i,j-1/2,k} )
    !       - dt/dz ( Fz_{i,j,k+1/2} - Fz_{i,j,k-1/2} )
    !       - dt * s_{i,j,k}
    !
    !    where dx = dy = dz = dt = 1.
    !---------------------------------------------------------------
    do k = il(3)-1,iu(3)
      do j = il(2)-1,iu(2)
        do i = il(1)-1,iu(1)

          n(i,j,k) = n0(i,j,k)                          &
     &               - (Fx(i,j,k) - Fx(i-1,j,k))        &
     &               - (Fy(i,j,k) - Fy(i,j-1,k))        &
     &               - (Fz(i,j,k) - Fz(i,j,k-1))        &
     &               - s(i,j,k)

        end do
      end do
    end do

end subroutine sub_J01_continuity_freeflow
