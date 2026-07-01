!> @file mod_H02_mpi_exchange_par.f90
!> @author Yinjian ZHAO (2025/12/18)
!> @brief Module for fast MPI particle exchange with cached neighbor metadata.
!> @details
!> This module provides a high-performance particle exchange implementation
!> for 3D domain decomposition. It caches the neighbor list, direction maps,
!> and MPI tags after a one-time initialization. It owns fixed-size send and
!> receive buffers for packed payloads and also owns cached integer work
!> buffers (counts, offsets, totals, and requests) to avoid per-call stack
!> allocation.
!>
!> The runtime exchange routine performs a two-phase protocol: first it
!> exchanges per-species counts with neighbors, then it exchanges packed
!> particle payloads. The packing layout is neighbor-major and species-
!> concatenated, which reduces message count compared to per-species
!> point-to-point exchanges.
!>
!> The cached arrays are module globals. Therefore, this module is not
!> thread-safe. Call the exchange routines from a single OpenMP thread.
!>
!> The include files ``sub_H02_mpi_exchange_par_init.f90`` and
!> ``sub_H02_mpi_exchange_par.f90`` are intended to be included here and must
!> not be compiled as separate translation units.

module mod_H02_mpi_exchange_par

    use mpi

    implicit none

    integer,parameter :: MAXDIR=26,TAG_BASE_COUNT=10000,TAG_BASE_DATA=20000

    logical :: H02_is_inited=.false.
    integer :: H02_ns=0,H02_npm=0,H02_ndir=0
    integer :: H02_dir_to_n(-1:1,-1:1,-1:1)
    integer :: H02_di(MAXDIR),H02_dj(MAXDIR),H02_dk(MAXDIR),H02_nbr_rank(MAXDIR)
    integer :: H02_tag_count_send(MAXDIR),H02_tag_count_recv(MAXDIR)
    integer :: H02_tag_data_send(MAXDIR),H02_tag_data_recv(MAXDIR)

    real,allocatable :: H02_send_buf(:,:,:),H02_recv_buf(:,:,:)

    integer,allocatable :: H02_send_cnt(:,:),H02_recv_cnt(:,:), &
        H02_send_base(:,:),H02_send_cur(:,:),H02_recv_base(:,:)
    integer,allocatable :: H02_send_tot(:),H02_recv_tot(:),H02_req(:)
    integer,allocatable :: H02_recv_sum(:)

contains

#   include "sub_H02_mpi_exchange_par_init.f90"
#   include "sub_H02_mpi_exchange_par.f90"

    !> @brief Convert a direction triplet in ``{-1,0,1}^3`` into a flat id.
    !> @details
    !> The returned id corresponds to a 3x3x3 flattening with ``c`` varying
    !> fastest, then ``b``, then ``a``. The center direction ``(0,0,0)`` maps
    !> to 13. This routine performs no range checking for performance; callers
    !> must ensure ``a``, ``b``, and ``c`` are in ``[-1,1]``.
    !> @return Integer id in ``[0,26]``.
    !
    !> @param[in] a: integer, x-direction offset in ``{-1,0,1}``.
    !> @param[in] b: integer, y-direction offset in ``{-1,0,1}``.
    !> @param[in] c: integer, z-direction offset in ``{-1,0,1}``.

    integer function DIR_ID(a,b,c)

        implicit none
        integer :: a,b,c

        DIR_ID = (a+1)*9 + (b+1)*3 + (c+1)

    end function DIR_ID

end module mod_H02_mpi_exchange_par
