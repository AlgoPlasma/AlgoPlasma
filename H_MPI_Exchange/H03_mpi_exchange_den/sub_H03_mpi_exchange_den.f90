!> @file sub_H03_mpi_exchange_den.f90
!> @author Zilong PENG (2026/04/24)
!> @brief Exchange ghost-cell density data between MPI ranks and
!>        apply periodic boundary conditions where needed.
!>
!> @details This subroutine handles two tasks.  First, for any
!>     spatial dimension in which the domain is not split across MPI
!>     ranks (``domain_split(d) == 1``) and periodic boundary
!>     conditions are active (``l(d) > tiny(1.0)``), the ghost-layer
!>     contributions at the upper boundary are folded into the lower
!>     boundary and copied back symmetrically.  Second, the subroutine
!>     includes three direction-specific MPI exchange files via
!>     preprocessor ``#include`` directives, which handle the
!>     halo-exchange of ``den`` between neighboring MPI ranks in
!>     x, y, and z.  The MPI rank topology is described by
!>     ``rank_to_ijk`` and ``ijk_to_rank``.

!> @param[in] il: integer (1:3), cell-center lower indices in x, y, z
!> @param[in] iu: integer (1:3), cell-center upper indices in x, y, z
!> @param[inout] den: real (il(1)-1:iu(1)+1, il(2)-1:iu(2)+1,
!>     il(3)-1:iu(3)+1), density array to be exchanged and updated
!> @param[in] mpi_n: integer, total number of MPI ranks
!> @param[in] rank_to_ijk: integer (1:3, 0:mpi_n-1), mapping from
!>     MPI rank to 3D domain index ``(i, j, k)``
!> @param[in] domain_split: integer (1:3), number of MPI partitions
!>     in each spatial dimension
!> @param[in] ijk_to_rank: integer (0:domain_split(1)+1,
!>     0:domain_split(2)+1, 0:domain_split(3)+1), mapping from
!>     3D domain index to MPI rank, including halo entries
!> @param[in] l: real (1:3), domain lengths in x, y, z;
!>     ``l(d) > tiny(1.0)`` indicates periodic BC in dimension ``d``

subroutine sub_H03_mpi_exchange_den(il,iu,den,mpi_n,rank_to_ijk, &
    domain_split,ijk_to_rank,l)

    use mpi

    implicit none

    integer :: il(1:3),iu(1:3)
    real    :: den(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)
    integer :: mpi_n
    integer :: rank_to_ijk(1:3,0:mpi_n-1)
    integer :: domain_split(1:3)
    integer :: ijk_to_rank(0:domain_split(1)+1, &
                           0:domain_split(2)+1, &
                           0:domain_split(3)+1)
    real    :: l(1:3)

    integer :: ierr,mpi_i,stat(mpi_status_size)
    integer :: i,j,k,ii,jj,kk,d
    real,allocatable :: buf_send(:,:),buf_recv(:,:)

    d = 1
    if (domain_split(d) == 1 .and. l(d) > tiny(1.0)) then
        den(il(d),:,:) = den(il(d),:,:) + den(iu(d),:,:)
        den(iu(d),:,:) = den(il(d),:,:)
    end if
    d = 2
    if (domain_split(d) == 1 .and. l(d) > tiny(1.0)) then
        den(:,il(d),:) = den(:,il(d),:) + den(:,iu(d),:)
        den(:,iu(d),:) = den(:,il(d),:)
    end if
    d = 3
    if (domain_split(d) == 1 .and. l(d) > tiny(1.0)) then
        den(:,:,il(d)) = den(:,:,il(d)) + den(:,:,iu(d))
        den(:,:,iu(d)) = den(:,:,il(d))  !有个小bug
    end if

    call mpi_comm_rank(mpi_comm_world,mpi_i,ierr)

    i = rank_to_ijk(1,mpi_i)
    j = rank_to_ijk(2,mpi_i)
    k = rank_to_ijk(3,mpi_i)

#   include "inc_exchange_in_x.f90"
#   include "inc_exchange_in_y.f90"
#   include "inc_exchange_in_z.f90"

end subroutine sub_H03_mpi_exchange_den