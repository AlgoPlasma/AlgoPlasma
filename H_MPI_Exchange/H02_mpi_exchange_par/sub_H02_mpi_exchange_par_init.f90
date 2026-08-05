!> @file sub_H02_mpi_exchange_par_init.f90
!> @author Yinjian ZHAO (2025/12/18)
!> @brief Initialize cached neighbor lists and MPI tags for particle exchange.
!> @details
!> This subroutine precomputes the neighbor list for the current MPI rank,
!> builds a mapping from direction ``(ii,jj,kk)`` to neighbor index ``n``,
!> precomputes MPI tags for count and payload exchanges, and checks that the
!> required tag range is within ``MPI_TAG_UB``. It also allocates fixed-size
!> send and receive buffers of size ``npm`` per neighbor direction.
!>
!> In addition, it allocates cached integer work buffers (counts, offsets,
!> totals, per-species receive sums, and MPI requests) so that the hot exchange
!> routine avoids large stack arrays and repeated allocation overhead.
!>
!> The neighbor set includes faces, edges, and corners, so up to 26 neighbors
!> can be used. Directions without a valid neighbor rank are mapped to 0.
!>
!> @note
!> - The tag values are ``TAG_BASE_COUNT + DIR_ID(...)`` and
!>   ``TAG_BASE_DATA + DIR_ID(...)``. Make sure no other communication in
!>   ``MPI_COMM_WORLD`` uses the same tag range.
!> - ``npm`` must be the same for all ranks.

!> @param[in] ns: integer, number of species.
!> @param[in] npm: integer, maximum number of particles per neighbor buffer.
!> @param[in] mpi_n: integer, MPI size.
!> @param[in] rank_to_ijk: integer (1:3,0:mpi_n-1), map rank -> MPI indices.
!> @param[in] domain_split: integer (1:3), MPI splits in x,y,z.
!> @param[in] ijk_to_rank: integer (0:ds(1)+1,0:ds(2)+1,0:ds(3)+1),
!>   map MPI indices -> rank; -1 means no rank.

subroutine sub_H02_mpi_exchange_par_init( &
    ns,npm,mpi_n,rank_to_ijk,domain_split,ijk_to_rank)

    use mpi

    implicit none
    integer :: ns,npm,mpi_n
    integer :: rank_to_ijk(1:3,0:mpi_n-1)
    integer :: domain_split(1:3)
    integer :: ijk_to_rank(0:domain_split(1)+1,0:domain_split(2)+1, &
        0:domain_split(3)+1)

    integer :: ierr,mpi_i
    integer :: i0,j0,k0,ii,jj,kk,rank
    integer(kind=MPI_ADDRESS_KIND) :: tag_ub_a
    integer :: tag_ub,max_tag
    integer :: ndir_alloc
    logical :: flag

    call MPI_Comm_rank(MPI_COMM_WORLD,mpi_i,ierr)

    H02_dir_to_n = 0
    H02_ndir = 0

    i0 = rank_to_ijk(1,mpi_i)
    j0 = rank_to_ijk(2,mpi_i)
    k0 = rank_to_ijk(3,mpi_i)

    if (i0<1.or.i0>domain_split(1).or. &
        j0<1.or.j0>domain_split(2).or. &
        k0<1.or.k0>domain_split(3)) then
        if (mpi_i==0) then
            write(*,*) "ERROR: rank_to_ijk is out of expected bounds."
            write(*,*) "i0,j0,k0:",i0,j0,k0
            write(*,*) "domain_split:",domain_split(1),domain_split(2), &
                domain_split(3)
        end if
        call MPI_Abort(MPI_COMM_WORLD,1,ierr)
    end if

    do ii = -1,1
        do jj = -1,1
            do kk = -1,1
                if (ii==0.and.jj==0.and.kk==0) cycle

                rank = ijk_to_rank(i0+ii,j0+jj,k0+kk)
                if (rank==-1) cycle

                H02_ndir = H02_ndir + 1
                H02_dir_to_n(ii,jj,kk) = H02_ndir

                H02_di(H02_ndir) = ii
                H02_dj(H02_ndir) = jj
                H02_dk(H02_ndir) = kk
                H02_nbr_rank(H02_ndir) = rank

                H02_tag_count_send(H02_ndir) = TAG_BASE_COUNT + DIR_ID(ii,jj,kk)
                H02_tag_count_recv(H02_ndir) = TAG_BASE_COUNT + &
                    DIR_ID(-ii,-jj,-kk)

                H02_tag_data_send(H02_ndir) = TAG_BASE_DATA + DIR_ID(ii,jj,kk)
                H02_tag_data_recv(H02_ndir) = TAG_BASE_DATA + &
                    DIR_ID(-ii,-jj,-kk)
            end do
        end do
    end do

    call MPI_Comm_get_attr(MPI_COMM_WORLD,MPI_TAG_UB,tag_ub_a,flag,ierr)
    if (.not.flag) then
        if (mpi_i==0) then
            write(*,*) "ERROR: MPI_TAG_UB is not available via MPI_Comm_get_attr."
        end if
        call MPI_Abort(MPI_COMM_WORLD,1,ierr)
    end if

    tag_ub = int(tag_ub_a)
    max_tag = max(TAG_BASE_COUNT,TAG_BASE_DATA) + DIR_ID(1,1,1)
    if (tag_ub<max_tag) then
        if (mpi_i==0) then
            write(*,*) "ERROR: MPI_TAG_UB is too small for particle exchange."
            write(*,*) "MPI_TAG_UB,max_tag:",tag_ub,max_tag
        end if
        call MPI_Abort(MPI_COMM_WORLD,1,ierr)
    end if

    H02_ns = ns
    H02_npm = npm

    if (allocated(H02_send_buf)) deallocate(H02_send_buf)
    if (allocated(H02_recv_buf)) deallocate(H02_recv_buf)

    if (allocated(H02_send_cnt)) deallocate(H02_send_cnt)
    if (allocated(H02_recv_cnt)) deallocate(H02_recv_cnt)
    if (allocated(H02_send_base)) deallocate(H02_send_base)
    if (allocated(H02_send_cur)) deallocate(H02_send_cur)
    if (allocated(H02_recv_base)) deallocate(H02_recv_base)
    if (allocated(H02_send_tot)) deallocate(H02_send_tot)
    if (allocated(H02_recv_tot)) deallocate(H02_recv_tot)
    if (allocated(H02_req)) deallocate(H02_req)
    if (allocated(H02_recv_sum)) deallocate(H02_recv_sum)

    ndir_alloc = max(1,H02_ndir)

    allocate(H02_send_buf(1:6,1:H02_npm,1:ndir_alloc))
    allocate(H02_recv_buf(1:6,1:H02_npm,1:ndir_alloc))

    allocate(H02_send_cnt(1:H02_ns,1:ndir_alloc))
    allocate(H02_recv_cnt(1:H02_ns,1:ndir_alloc))
    allocate(H02_send_base(1:H02_ns,1:ndir_alloc))
    allocate(H02_send_cur(1:H02_ns,1:ndir_alloc))
    allocate(H02_recv_base(1:H02_ns,1:ndir_alloc))

    allocate(H02_send_tot(1:ndir_alloc))
    allocate(H02_recv_tot(1:ndir_alloc))

    allocate(H02_req(1:4*ndir_alloc))

    allocate(H02_recv_sum(1:H02_ns))

    H02_is_inited = .true.

end subroutine sub_H02_mpi_exchange_par_init
