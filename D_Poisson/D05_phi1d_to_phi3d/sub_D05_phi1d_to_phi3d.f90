!> @file sub_D05_phi1d_to_phi3d.f90
!> @author Zilong PENG (2026/06/05)
!> @brief Unpack the HYPRE 1D solution vector into a 3D ghost-cell array
!>        and perform MPI halo exchange for the phi field.
!> @details
!>   After the HYPRE Poisson solver returns the solution as a 1D array
!>   ``phi1d`` (loop order i, j, k with the first index varying fastest),
!>   this subroutine fills the physical domain of ``phi3d(il:iu,:,:)``
!>   element by element, then handles two kinds of boundary cases:
!>
!>   - **Periodic BC (single-rank direction)**: if ``domain_split(d)==1``
!>     and ``l(d)>0``, the two ghost layers in direction ``d`` are filled
!>     by wrapping around the opposite physical boundary.
!>   - **Multi-rank MPI exchange**: for directions with more than one MPI
!>     rank, ghost cells are filled via point-to-point MPI communication
!>     with the left/right (or bottom/top, front/back) neighbours.
!>     The exchange sends the boundary cell of the local domain (``iu(d)``
!>     or ``il(d)``) to the neighbour's ghost cell, matching the HYPRE
!>     non-overlapping grid convention.
!>
!>   Non-periodic, non-MPI ghost cells (physical boundaries of the global
!>   domain) are left at zero after the call; the caller must set them
!>   explicitly (e.g. Dirichlet or Neumann conditions) before computing
!>   the electric field.
!>
!>   The MPI exchange pattern alternates send-then-receive (odd logical
!>   index) and receive-then-send (even logical index) to avoid deadlock
!>   on a Cartesian process grid.

!> @param[in] il: integer(1:3), cell-center lower indices in x,y,z of the
!>   local subdomain.
!> @param[in] iu: integer(1:3), cell-center upper indices in x,y,z of the
!>   local subdomain.
!> @param[in] phi1d: real(1:nx*ny*nz), 1D solution vector from HYPRE,
!>   with loop order i (fastest), j, k (slowest); ``nx=iu(1)-il(1)+1``,
!>   ``ny=iu(2)-il(2)+1``, ``nz=iu(3)-il(3)+1``.
!> @param[in,out] phi3d: real(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1,
!>   il(3)-1:iu(3)+1), 3D potential array including one ghost layer per
!>   side; physical cells are written from ``phi1d`` and ghost cells are
!>   filled by periodic wrap-around or MPI exchange.
!> @param[in] mpi_n: integer, total number of MPI ranks.
!> @param[in] rank_to_ijk: integer(1:3,0:mpi_n-1), mapping from MPI rank
!>   to 3D logical index triplet ``(i,j,k)``.
!> @param[in] domain_split: integer(1:3), number of MPI subdomains in each
!>   direction.
!> @param[in] ijk_to_rank: integer(0:domain_split(1)+1,
!>   0:domain_split(2)+1, 0:domain_split(3)+1), mapping from logical
!>   indices to MPI rank; ``-1`` denotes a non-existing neighbour.
!> @param[in] l: real(1:3), physical domain length in each direction;
!>   ``l(d)>0`` with ``domain_split(d)==1`` triggers periodic ghost fill.

subroutine sub_D05_phi1d_to_phi3d(il,iu,phi1d,phi3d,&
    mpi_n,rank_to_ijk,domain_split,ijk_to_rank,l)

    use mpi

    implicit none

    integer,dimension(1:3) :: il,iu
    real,dimension(1:(iu(1)-il(1)+1)*(iu(2)-il(2)+1)*(iu(3)-il(3)+1)) :: phi1d
    real,dimension(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1) :: phi3d
    integer :: mpi_n
    integer :: rank_to_ijk(1:3,0:mpi_n-1)
    integer :: domain_split(1:3)
    integer :: ijk_to_rank(0:domain_split(1)+1,0:domain_split(2)+1,0:domain_split(3)+1)
    real :: l(1:3)

    integer :: i,j,k,m,d,ii,jj,kk
    integer :: ierr,mpi_i,stat(mpi_status_size)
    real,dimension(:,:),allocatable :: buf_send,buf_recv

    phi3d = 0.0

    m = 1
    do k = il(3),iu(3)
    do j = il(2),iu(2)
    do i = il(1),iu(1)
        phi3d(i,j,k) = phi1d(m)
        m = m + 1
    end do
    end do
    end do

    ! Handle periodic BC if no MPI split.
    d = 1
    if (domain_split(d)==1.and.l(d)>tiny(1.0)) then
        phi3d(il(d)-1,:,:) = phi3d(iu(d),:,:)
        phi3d(iu(d)+1,:,:) = phi3d(il(d),:,:)
    end if
    d = 2
    if (domain_split(d)==1.and.l(d)>tiny(1.0)) then
        phi3d(:,il(d)-1,:) = phi3d(:,iu(d),:)
        phi3d(:,iu(d)+1,:) = phi3d(:,il(d),:)
    end if
    d = 3
    if (domain_split(d)==1.and.l(d)>tiny(1.0)) then
        phi3d(:,:,il(d)-1) = phi3d(:,:,iu(d))
        phi3d(:,:,iu(d)+1) = phi3d(:,:,il(d))
    end if

    ! Get MPI rank.
    call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)

    ! Obtain the global MPI indicies.
    i = rank_to_ijk(1,mpi_i)
    j = rank_to_ijk(2,mpi_i)
    k = rank_to_ijk(3,mpi_i)

#   include "inc_exchange_in_x.f90"
#   include "inc_exchange_in_y.f90"
#   include "inc_exchange_in_z.f90"

    ! Note that for other BCs, it needs to be addressed after
    ! calling this subroutine, and maybe before computing E from phi.

end subroutine sub_D05_phi1d_to_phi3d
