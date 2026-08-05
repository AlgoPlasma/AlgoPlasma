!> @file sub_H01_mpi_exchange_field.f90
!> @author Yinjian ZHAO (2025/12/04)
!> @brief Exchange ghost-cell values of a scalar field among MPI neighbor ranks.
!> @details
!>   This subroutine performs MPI halo/ghost-cell exchange of a scalar
!>   field ``f`` between neighbor ranks in a 3D Cartesian domain
!>   decomposition. It also applies periodic boundary conditions in
!>   directions where ``domain_split(d)==1`` and the physical length
!>   ``l(d)`` is non-zero. The array ``f`` is defined on cell centers
!>   with 1-layer ghost cells in each direction, i.e. ``il(d)-1:iu(d)+1``.
!>   Mappings between MPI rank and 3D logical indices are given by
!>   ``rank_to_ijk`` and ``ijk_to_rank``, where the latter may store ``-1``
!>   for non-existing neighbors. The actual point-to-point exchanges in
!>   x, y, z directions are implemented in the included files
!>   ``inc_exchange_in_x.f90``, ``inc_exchange_in_y.f90`` and
!>   ``inc_exchange_in_z.f90``.

!> @param[in] il: integer(1:3), lower cell-center indices in x,y,z of the
!>   local subdomain (excluding ghost cells).
!> @param[in] iu: integer(1:3), upper cell-center indices in x,y,z of the
!>   local subdomain (excluding ghost cells).
!> @param[in,out] f: real,dimension(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1, 
!>   il(3)-1:iu(3)+1), scalar field values on cell centers including one
!>   layer of ghost cells in each direction.
!> @param[in] mpi_n: integer, total number of MPI ranks in the communicator
!>   ``mpi_comm_world``.
!> @param[in] rank_to_ijk: integer(1:3,0:mpi_n-1), mapping from MPI rank to
!>   3D logical index triplet ``(i,j,k)``.
!> @param[in] domain_split: integer(1:3), number of MPI subdomains in each
!>   of the three directions.
!> @param[in] ijk_to_rank: integer(0:domain_split(1)+1,0:domain_split(2)+1, 
!>   0:domain_split(3)+1), mapping from logical indices ``(i,j,k)`` to MPI
!>   rank, with ``-1`` for non-existing neighbors and halo layers.
!> @param[in] l: real(1:3), physical length of the domain in each direction;
!>   used to decide whether periodic boundary conditions should be enforced
!>   when ``domain_split(d)==1``.

subroutine sub_H01_mpi_exchange_field(il,iu,f,&
    mpi_n,rank_to_ijk,domain_split,ijk_to_rank,l)

    use mpi

    implicit none

    integer,dimension(1:3) :: il,iu
    real,dimension(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1) :: f
    integer :: mpi_n
    integer,dimension(1:3,0:mpi_n-1) :: rank_to_ijk
    integer,dimension(1:3) :: domain_split
    integer,dimension(0:domain_split(1)+1,0:domain_split(2)+1,0:domain_split(3)+1) :: ijk_to_rank
    real,dimension(1:3) :: l

    integer :: d,mpi_i,ierr,i,j,k,ii,jj,kk
    integer,dimension(mpi_status_size) :: stat
    real,dimension(:,:),allocatable :: buf_send,buf_recv

    ! Handle periodic BC if no MPI split.
    d = 1
    if (domain_split(d)==1.and.l(d)>tiny(1.0)) then
        f(il(d)-1,:,:) = f(iu(d)-1,:,:)
        f(iu(d)+1,:,:) = f(il(d)+1,:,:)
    end if
    d = 2
    if (domain_split(d)==1.and.l(d)>tiny(1.0)) then
        f(:,il(d)-1,:) = f(:,iu(d)-1,:)
        f(:,iu(d)+1,:) = f(:,il(d)+1,:)
    end if
    d = 3
    if (domain_split(d)==1.and.l(d)>tiny(1.0)) then
        f(:,:,il(d)-1) = f(:,:,iu(d)-1)
        f(:,:,iu(d)+1) = f(:,:,il(d)+1)
    end if

    ! Get MPI rank.
    call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)

    ! Obtain the global MPI indices.
    i = rank_to_ijk(1,mpi_i)
    j = rank_to_ijk(2,mpi_i)
    k = rank_to_ijk(3,mpi_i)

#   include "inc_exchange_in_x.f90"
#   include "inc_exchange_in_y.f90"
#   include "inc_exchange_in_z.f90"

    ! Notice that for other BCs, it needs to be addressed further.

end subroutine sub_H01_mpi_exchange_field
