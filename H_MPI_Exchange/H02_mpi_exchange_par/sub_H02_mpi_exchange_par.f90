!> @file sub_H02_mpi_exchange_par.f90
!> @author Yinjian ZHAO (2025/12/17)
!> @brief Exchange particles across MPI subdomains for all species.
!> @details
!> This routine packs particles that move outside the local domain into fixed
!> per-neighbor buffers and exchanges them with all existing neighbors using
!> a two-phase nonblocking protocol. Phase A exchanges per-species counts as
!> a single ``ns``-integer message per neighbor. Phase B exchanges the packed
!> payload as one message per neighbor, with particles concatenated in species
!> order (1..``ns``). Received particles are unpacked and appended to each
!> species array.
!>
!> Packing never reallocates. If the global ``nsmax`` is larger than
!> ``H02_npm``, all ranks return with ``istat=1`` after Phase A, so that the
!> caller can increase ``npm``, re-run ``sub_H02_mpi_exchange_par_init``, and
!> retry. The global decision is enforced by an ``MPI_Allreduce`` on ``nsmax``
!> to prevent rank divergence.
!>
!> Hot-path optimizations:
!> - Cache ``l(i)>0`` as ``has_lx/has_ly/has_lz``.
!> - Cache ``l(1:3)`` as ``lx/ly/lz``.
!> - Cache global real bounds ``iu0`` and ``il0-1`` as real scalars.
!> - Cache local bounds ``xlo/xhi`` as scalars to reduce subscript traffic.
!> - Use module-level cached integer work buffers to avoid large stack arrays.
!> - Check ``npmax`` overflow once per species before unpacking, instead of
!>   per-particle checks inside the unpack loop.
!>
!> @note The dimensionless cell size is assumed to be 1.0. Positions in
!> ``par(1:3,:,:)`` and periodic lengths ``l(1:3)`` are expressed in cell
!> units.
!
!> @param[in] ns: integer, number of species.
!> @param[inout] np: integer (1:ns), current number of particles per species.
!> @param[in] npmax: integer, maximum number of particles per species array.
!> @param[inout] par: real (1:6,1:npmax,1:ns), particle array.
!> @param[in] il: integer (1:3), cell-center lower indices in x,y,z.
!> @param[in] iu: integer (1:3), cell-center upper indices in x,y,z.
!> @param[in] il0: integer (1:3), global cell-center lower indices in x,y,z.
!> @param[in] iu0: integer (1:3), global cell-center upper indices in x,y,z.
!> @param[in] domain_split: integer (1:3), MPI splits in x,y,z.
!> @param[in] l: real (1:3), periodic length in x,y,z (<=0 non-periodic).
!> @param[out] nsmax: integer, global maximum of per-neighbor send and recv
!>   totals.
!> @param[out] istat: integer, status flag. 0 means success; 1 means
!>   ``nsmax>H02_npm`` and the caller should increase ``npm``, re-run
!>   ``sub_H02_mpi_exchange_par_init``, and retry.

subroutine sub_H02_mpi_exchange_par( &
    ns,np,npmax,par,il,iu,il0,iu0,domain_split,l,nsmax,istat)

    use mpi

    implicit none
    integer :: ns
    integer :: np(1:ns)
    integer :: npmax
    real :: par(1:6,1:npmax,1:ns)
    integer :: il(1:3),iu(1:3),il0(1:3),iu0(1:3),domain_split(1:3)
    real :: l(1:3)
    integer :: nsmax,istat

    integer :: ierr,mpi_i,mpi_rtype
    logical :: has_lx,has_ly,has_lz
    logical :: per_x,per_y,per_z,abs_x,abs_y,abs_z
    real :: lx,ly,lz
    real :: xlo1,xhi1,xlo2,xhi2,xlo3,xhi3
    real :: iu0_r1,iu0_r2,iu0_r3,il0m1_r1,il0m1_r2,il0m1_r3
    integer :: send_max,recv_max
    integer :: nreq
    integer :: s,p,n,dir_i,dir_j,dir_k,nidx,slot,m
    integer :: nsmax_local,nsmax_global
    real :: xpos,ypos,zpos

    if (.not.H02_is_inited) then
        write(*,*) "ERROR: sub_H02_mpi_exchange_par is called before init."
        call MPI_Abort(MPI_COMM_WORLD,1,ierr)
    end if
    if (ns/=H02_ns) then
        write(*,*) "ERROR: ns does not match the initialized value in init."
        write(*,*) "ns,H02_ns:",ns,H02_ns
        call MPI_Abort(MPI_COMM_WORLD,1,ierr)
    end if

    call MPI_Comm_rank(MPI_COMM_WORLD,mpi_i,ierr)

    if (kind(par(1,1,1))==kind(1.0_8)) then
        mpi_rtype = MPI_DOUBLE_PRECISION
    else if (kind(par(1,1,1))==kind(1.0_4)) then
        mpi_rtype = MPI_REAL
    else
        if (mpi_i==0) write(*,*) "ERROR: Unknown MPI real type in H02."
        call MPI_Abort(MPI_COMM_WORLD,1,ierr)
    end if

    lx = l(1)
    ly = l(2)
    lz = l(3)

    has_lx = (lx>0.0)
    has_ly = (ly>0.0)
    has_lz = (lz>0.0)

    per_x = (domain_split(1)==1.and.has_lx)
    per_y = (domain_split(2)==1.and.has_ly)
    per_z = (domain_split(3)==1.and.has_lz)

    abs_x = (domain_split(1)==1)
    abs_y = (domain_split(2)==1)
    abs_z = (domain_split(3)==1)

    xlo1 = real(il(1)-1)
    xhi1 = real(iu(1))
    xlo2 = real(il(2)-1)
    xhi2 = real(iu(2))
    xlo3 = real(il(3)-1)
    xhi3 = real(iu(3))

    iu0_r1 = real(iu0(1))
    iu0_r2 = real(iu0(2))
    iu0_r3 = real(iu0(3))

    il0m1_r1 = real(il0(1)-1)
    il0m1_r2 = real(il0(2)-1)
    il0m1_r3 = real(il0(3)-1)

    H02_send_cnt = 0
    H02_recv_cnt = 0
    H02_send_tot = 0
    H02_recv_tot = 0

    !------------------------------------------------------------------
    ! Pass 1: Count outgoing particles per (neighbor, species).
    ! Periodic wrap is applied here and re-evaluated on the same particle.
    ! Absorbing removals are not performed in this pass.
    !------------------------------------------------------------------
    do s = 1,ns
        p = 1
        do while (p<=np(s))

            xpos = par(1,p,s)
            ypos = par(2,p,s)
            zpos = par(3,p,s)

            if (xpos>=xlo1.and.xpos<xhi1.and. &
                ypos>=xlo2.and.ypos<xhi2.and. &
                zpos>=xlo3.and.zpos<xhi3) then
                p = p + 1
                cycle
            end if

            if (xpos<xlo1) then
                dir_i = -1
            else if (xpos>=xhi1) then
                dir_i = 1
            else
                dir_i = 0
            end if
            if (ypos<xlo2) then
                dir_j = -1
            else if (ypos>=xhi2) then
                dir_j = 1
            else
                dir_j = 0
            end if
            if (zpos<xlo3) then
                dir_k = -1
            else if (zpos>=xhi3) then
                dir_k = 1
            else
                dir_k = 0
            end if

            if (per_x.and.dir_i/=0) then
                if (dir_i==1) par(1,p,s) = par(1,p,s) - lx
                if (dir_i==-1) par(1,p,s) = par(1,p,s) + lx
                cycle
            end if
            if (per_y.and.dir_j/=0) then
                if (dir_j==1) par(2,p,s) = par(2,p,s) - ly
                if (dir_j==-1) par(2,p,s) = par(2,p,s) + ly
                cycle
            end if
            if (per_z.and.dir_k/=0) then
                if (dir_k==1) par(3,p,s) = par(3,p,s) - lz
                if (dir_k==-1) par(3,p,s) = par(3,p,s) + lz
                cycle
            end if

            if (abs_x.and.dir_i/=0) then
                p = p + 1
                cycle
            end if
            if (abs_y.and.dir_j/=0) then
                p = p + 1
                cycle
            end if
            if (abs_z.and.dir_k/=0) then
                p = p + 1
                cycle
            end if

            nidx = H02_dir_to_n(dir_i,dir_j,dir_k)
            if (nidx==0) then
                p = p + 1
                cycle
            end if

            H02_send_cnt(s,nidx) = H02_send_cnt(s,nidx) + 1
            p = p + 1

        end do
    end do

    !------------------------------------------------------------------
    ! Phase A: Exchange per-species counts, one message per neighbor.
    !------------------------------------------------------------------
    nreq = 0
    do n = 1,H02_ndir
        nreq = nreq + 1
        call MPI_Irecv(H02_recv_cnt(1,n),ns,MPI_INTEGER,H02_nbr_rank(n), &
            H02_tag_count_recv(n),MPI_COMM_WORLD,H02_req(nreq),ierr)

        nreq = nreq + 1
        call MPI_Isend(H02_send_cnt(1,n),ns,MPI_INTEGER,H02_nbr_rank(n), &
            H02_tag_count_send(n),MPI_COMM_WORLD,H02_req(nreq),ierr)
    end do
    if (nreq>0) then
        call MPI_Waitall(nreq,H02_req,MPI_STATUSES_IGNORE,ierr)
    end if

    send_max = 0
    recv_max = 0
    do n = 1,H02_ndir
        do s = 1,ns
            H02_send_tot(n) = H02_send_tot(n) + H02_send_cnt(s,n)
            H02_recv_tot(n) = H02_recv_tot(n) + H02_recv_cnt(s,n)
        end do
        if (H02_send_tot(n)>send_max) send_max = H02_send_tot(n)
        if (H02_recv_tot(n)>recv_max) recv_max = H02_recv_tot(n)
    end do

    nsmax_local = max(send_max,recv_max)

    call MPI_Allreduce(nsmax_local,nsmax_global,1,MPI_INTEGER,MPI_MAX, &
        MPI_COMM_WORLD,ierr)

    nsmax = nsmax_global
    istat = 0
    if (nsmax>H02_npm) then
        istat = 1
        return
    end if

    !------------------------------------------------------------------
    ! Build per-neighbor, per-species base offsets for concatenation.
    ! Species order is 1..ns for both send and receive payload layout.
    !------------------------------------------------------------------
    do n = 1,H02_ndir
        H02_send_base(1,n) = 1
        H02_recv_base(1,n) = 1
        do s = 2,ns
            H02_send_base(s,n) = H02_send_base(s-1,n) + H02_send_cnt(s-1,n)
            H02_recv_base(s,n) = H02_recv_base(s-1,n) + H02_recv_cnt(s-1,n)
        end do
        do s = 1,ns
            H02_send_cur(s,n) = H02_send_base(s,n)
        end do
    end do

    !------------------------------------------------------------------
    ! Pass 2: Pack and remove outgoing particles.
    ! No reallocation is performed here. Pack order matches Phase B layout.
    !------------------------------------------------------------------
    do s = 1,ns
        p = 1
        do while (p<=np(s))

            xpos = par(1,p,s)
            ypos = par(2,p,s)
            zpos = par(3,p,s)

            if (xpos>=xlo1.and.xpos<xhi1.and. &
                ypos>=xlo2.and.ypos<xhi2.and. &
                zpos>=xlo3.and.zpos<xhi3) then
                p = p + 1
                cycle
            end if

            if (xpos<xlo1) then
                dir_i = -1
            else if (xpos>=xhi1) then
                dir_i = 1
            else
                dir_i = 0
            end if
            if (ypos<xlo2) then
                dir_j = -1
            else if (ypos>=xhi2) then
                dir_j = 1
            else
                dir_j = 0
            end if
            if (zpos<xlo3) then
                dir_k = -1
            else if (zpos>=xhi3) then
                dir_k = 1
            else
                dir_k = 0
            end if

            if (per_x.and.dir_i/=0) then
                if (dir_i==1) par(1,p,s) = par(1,p,s) - lx
                if (dir_i==-1) par(1,p,s) = par(1,p,s) + lx
                cycle
            end if
            if (per_y.and.dir_j/=0) then
                if (dir_j==1) par(2,p,s) = par(2,p,s) - ly
                if (dir_j==-1) par(2,p,s) = par(2,p,s) + ly
                cycle
            end if
            if (per_z.and.dir_k/=0) then
                if (dir_k==1) par(3,p,s) = par(3,p,s) - lz
                if (dir_k==-1) par(3,p,s) = par(3,p,s) + lz
                cycle
            end if

            if (abs_x.and.dir_i/=0) then
                par(:,p,s) = par(:,np(s),s)
                np(s) = np(s) - 1
                cycle
            end if
            if (abs_y.and.dir_j/=0) then
                par(:,p,s) = par(:,np(s),s)
                np(s) = np(s) - 1
                cycle
            end if
            if (abs_z.and.dir_k/=0) then
                par(:,p,s) = par(:,np(s),s)
                np(s) = np(s) - 1
                cycle
            end if

            nidx = H02_dir_to_n(dir_i,dir_j,dir_k)
            if (nidx==0) then
                par(:,p,s) = par(:,np(s),s)
                np(s) = np(s) - 1
                cycle
            end if

            slot = H02_send_cur(s,nidx)

            H02_send_buf(1,slot,nidx) = xpos
            H02_send_buf(2,slot,nidx) = ypos
            H02_send_buf(3,slot,nidx) = zpos
            H02_send_buf(4,slot,nidx) = par(4,p,s)
            H02_send_buf(5,slot,nidx) = par(5,p,s)
            H02_send_buf(6,slot,nidx) = par(6,p,s)

            if (has_lx) then
                if (xpos>=iu0_r1) H02_send_buf(1,slot,nidx) = &
                    H02_send_buf(1,slot,nidx) - lx
                if (xpos<il0m1_r1) H02_send_buf(1,slot,nidx) = &
                    H02_send_buf(1,slot,nidx) + lx
            end if
            if (has_ly) then
                if (ypos>=iu0_r2) H02_send_buf(2,slot,nidx) = &
                    H02_send_buf(2,slot,nidx) - ly
                if (ypos<il0m1_r2) H02_send_buf(2,slot,nidx) = &
                    H02_send_buf(2,slot,nidx) + ly
            end if
            if (has_lz) then
                if (zpos>=iu0_r3) H02_send_buf(3,slot,nidx) = &
                    H02_send_buf(3,slot,nidx) - lz
                if (zpos<il0m1_r3) H02_send_buf(3,slot,nidx) = &
                    H02_send_buf(3,slot,nidx) + lz
            end if

            H02_send_cur(s,nidx) = H02_send_cur(s,nidx) + 1

            par(:,p,s) = par(:,np(s),s)
            np(s) = np(s) - 1

        end do
    end do

    !------------------------------------------------------------------
    ! Phase B: Exchange payloads, one message per neighbor.
    ! Receives are posted first, then sends, then a single Waitall.
    !------------------------------------------------------------------
    nreq = 0
    do n = 1,H02_ndir
        if (H02_recv_tot(n)>0) then
            nreq = nreq + 1
            call MPI_Irecv(H02_recv_buf(1,1,n),6*H02_recv_tot(n),mpi_rtype, &
                H02_nbr_rank(n),H02_tag_data_recv(n),MPI_COMM_WORLD, &
                H02_req(nreq),ierr)
        end if
    end do

    do n = 1,H02_ndir
        if (H02_send_tot(n)>0) then
            nreq = nreq + 1
            call MPI_Isend(H02_send_buf(1,1,n),6*H02_send_tot(n),mpi_rtype, &
                H02_nbr_rank(n),H02_tag_data_send(n),MPI_COMM_WORLD, &
                H02_req(nreq),ierr)
        end if
    end do

    if (nreq>0) then
        call MPI_Waitall(nreq,H02_req,MPI_STATUSES_IGNORE,ierr)
    end if

    !------------------------------------------------------------------
    ! Check capacity once per species, then unpack.
    !------------------------------------------------------------------
    do s = 1,ns
        H02_recv_sum(s) = 0
        do n = 1,H02_ndir
            H02_recv_sum(s) = H02_recv_sum(s) + H02_recv_cnt(s,n)
        end do
        if (np(s)+H02_recv_sum(s)>npmax) then
            write(*,*) "ERROR: sub_H02_mpi_exchange_par, np>npmax."
            call MPI_Abort(MPI_COMM_WORLD,1,ierr)
        end if
    end do

    do s = 1,ns
        do n = 1,H02_ndir
            if (H02_recv_cnt(s,n)<=0) cycle
            p = H02_recv_base(s,n)
            do m = 1,H02_recv_cnt(s,n)
                np(s) = np(s) + 1
                par(:,np(s),s) = H02_recv_buf(:,p,n)
                p = p + 1
            end do
        end do
    end do

end subroutine sub_H02_mpi_exchange_par
