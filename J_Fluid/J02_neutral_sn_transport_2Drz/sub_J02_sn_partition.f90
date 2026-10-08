!> @brief Describe owned cells on a borrowed nonperiodic 2D Cartesian communicator.
!> @param[in] communicator Integer MPI communicator; topology axes are r, then z.
!> @param[in] global_shape Global cell counts, equal on all ranks.
!> @param[out] partition Read-only ownership metadata; local fields contain no ghosts.
!> @param[out] ierr Collective status for input/layout errors.
!> @param[in] first Optional one-based global start; supply together with count.
!> @param[in] count Optional positive local cell counts for a conforming tiling.
!> @details Collective call. The application owns MPI and communicator lifetime.
!> Hybrid builds require MPI_THREAD_FUNNELED or higher and MPI-main-thread calls.
    subroutine sub_J02_initialize_partition(communicator,global_shape,partition,ierr,first,count)
        use mpi
        integer, intent(in) :: communicator,global_shape(2)
        type(sn_partition_type), intent(out) :: partition
        integer, intent(out) :: ierr
        integer, optional, intent(in) :: first(2),count(2)
        integer :: ec,topology,ndims,q,axis,peer,lo(2),hi(2),info(6)
        integer, allocatable :: all_info(:,:)
        logical :: initialized,finalized,periods(2),main_thread
        call MPI_Initialized(initialized,ec)
        call MPI_Finalized(finalized,ec)
        ierr=SN_ERR_MPI_LAYOUT
        if (.not.initialized .or. finalized .or. communicator==MPI_COMM_NULL) return
        partition%comm=communicator
        call MPI_Comm_rank(communicator,partition%rank,ec)
        call MPI_Comm_size(communicator,partition%n_ranks,ec)
        call MPI_Topo_test(communicator,topology,ec)
        if (topology/=MPI_CART) return
        call MPI_Cartdim_get(communicator,ndims,ec)
        if (ndims/=2) return
        call MPI_Cart_get(communicator,2,partition%dims,periods,partition%coords,ec)
        if (any(periods)) return
        call MPI_Query_thread(q,ec)
        call MPI_Is_thread_main(main_thread,ec)
        ierr=SN_SUCCESS
        if (.not.main_thread) ierr=SN_ERR_MPI_THREAD
#ifdef _OPENMP
        if (q<MPI_THREAD_FUNNELED) ierr=SN_ERR_MPI_THREAD
#endif
        if (any(global_shape<partition%dims)) ierr=SN_ERR_MPI_LAYOUT
        if (present(first).neqv.present(count)) ierr=SN_ERR_MPI_LAYOUT
        call MPI_Allreduce(global_shape,lo,2,MPI_INTEGER,MPI_MIN,communicator,ec)
        call MPI_Allreduce(global_shape,hi,2,MPI_INTEGER,MPI_MAX,communicator,ec)
        if (any(lo/=hi)) ierr=SN_ERR_MPI_LAYOUT
        call sub_J02_sync_status(partition,ierr)
        if (ierr/=SN_SUCCESS) return
        partition%global_shape=global_shape
        partition%first=global_shape*partition%coords/partition%dims+1
        partition%count=global_shape*(partition%coords+1)/partition%dims-partition%first+1
        if (present(first)) partition%first=first
        if (present(count)) partition%count=count
        info=[partition%coords,partition%first,partition%count]
        allocate(all_info(6,partition%n_ranks))
        call MPI_Allgather(info,6,MPI_INTEGER,all_info,6,MPI_INTEGER,communicator,ec)
        ! Each logical row/column must tile the domain without gaps or overlap.
        do q=1,partition%n_ranks
            do axis=1,2
                if (all_info(4+axis,q)<1) ierr=SN_ERR_MPI_LAYOUT
                if (all_info(axis,q)==0 .and. all_info(2+axis,q)/=1) ierr=SN_ERR_MPI_LAYOUT
                if (all_info(axis,q)==partition%dims(axis)-1) then
                    if (all_info(2+axis,q)+all_info(4+axis,q)-1/=global_shape(axis)) ierr=SN_ERR_MPI_LAYOUT
                end if
                do peer=1,partition%n_ranks
                    if (all_info(3-axis,peer)/=all_info(3-axis,q)) cycle
                    if (all_info(axis,peer)/=all_info(axis,q)+1) cycle
                    if (all_info(2+axis,q)+all_info(4+axis,q)/=all_info(2+axis,peer)) ierr=SN_ERR_MPI_LAYOUT
                    if (all_info(5-axis,q)/=all_info(5-axis,peer) .or. &
                        all_info(7-axis,q)/=all_info(7-axis,peer)) ierr=SN_ERR_MPI_LAYOUT
                end do
            end do
        end do
        call sub_J02_sync_status(partition,ierr)
        if (ierr/=SN_SUCCESS) return
        call MPI_Cart_shift(communicator,0,1,partition%neighbor(SN_R_LO),partition%neighbor(SN_R_HI),ec)
        call MPI_Cart_shift(communicator,1,1,partition%neighbor(SN_Z_LO),partition%neighbor(SN_Z_HI),ec)
        call MPI_Type_match_size(MPI_TYPECLASS_REAL,storage_size(1.0)/8,partition%real_type,ec)
        call sub_J02_check_mpi(ec,communicator)
    end subroutine sub_J02_initialize_partition

    ! Return the same numerical error everywhere, before any later point-to-point phase.
    ! The selected cell follows the unsplit sweep order: direction, signed i, signed k.
    subroutine sub_J02_sync_status(partition,ierr,fd,fi,fk,quadrature)
        use mpi
        type(sn_partition_type), optional, intent(in) :: partition
        integer, intent(inout) :: ierr
        integer, optional, intent(inout) :: fd,fi,fk
        type(sn_quadrature_type), optional, intent(in) :: quadrature
        integer :: ec,q,winner,local(4),key(3),best(3)
        integer, allocatable :: states(:,:)
        if (.not.present(partition)) return
        local=[ierr,0,0,0]
        if (present(fd)) local(2)=fd
        if (present(fi)) local(3)=fi
        if (present(fk)) local(4)=fk
        if (local(3)>0) local(3)=local(3)+partition%first(1)-1
        if (local(4)>0) local(4)=local(4)+partition%first(2)-1
        allocate(states(4,partition%n_ranks))
        call MPI_Allgather(local,4,MPI_INTEGER,states,4,MPI_INTEGER,partition%comm,ec)
        call sub_J02_check_mpi(ec,partition%comm)
        winner=0
        best=huge(1)
        do q=1,partition%n_ranks
            if (states(1,q)==SN_SUCCESS) cycle
            key=states(2:4,q)
            if (present(quadrature)) then
                if (key(1)>0 .and. key(1)<=quadrature%n_dir) then
                    if (quadrature%mu(key(1))<0.0 .and. key(2)>0) key(2)=partition%global_shape(1)+1-key(2)
                    if (quadrature%eta(key(1))<0.0 .and. key(3)>0) key(3)=partition%global_shape(2)+1-key(3)
                end if
            end if
            if (winner==0 .or. key(1)<best(1) .or. &
                (key(1)==best(1) .and. key(2)<best(2)) .or. &
                (all(key(1:2)==best(1:2)) .and. key(3)<best(3))) then
                best=key
                winner=q
            end if
        end do
        ierr=SN_SUCCESS
        if (winner>0) then
            ierr=states(1,winner)
            if (present(fd)) fd=states(2,winner)
            if (present(fi)) fi=states(3,winner)
            if (present(fk)) fk=states(4,winner)
        end if
    end subroutine sub_J02_sync_status

    ! A failed MPI transport/communicator is not a recoverable numerical input error.
    subroutine sub_J02_check_mpi(code,communicator)
        use mpi
        integer, intent(in) :: code,communicator
        integer :: ec,n
        character(len=MPI_MAX_ERROR_STRING) :: message
        if (code==MPI_SUCCESS) return
        call MPI_Error_string(code,message,n,ec)
        write(*,'(a)') 'J02 MPI communication failure: '//message(:n)
        call MPI_Abort(communicator,code,ec)
    end subroutine sub_J02_check_mpi

    subroutine sub_J02_partition_real_reduce(partition,value,maximum)
        use mpi
        type(sn_partition_type), optional, intent(in) :: partition
        real, intent(inout) :: value
        logical, intent(in) :: maximum
        integer :: op,ec
        real :: reduced
        if (.not.present(partition)) return
        op=MPI_SUM
        if (maximum) op=MPI_MAX
        call MPI_Allreduce(value,reduced,1,partition%real_type,op,partition%comm,ec)
        call sub_J02_check_mpi(ec,partition%comm)
        value=reduced
    end subroutine sub_J02_partition_real_reduce

    subroutine sub_J02_partition_any(partition,value)
        use mpi
        type(sn_partition_type), optional, intent(in) :: partition
        logical, intent(inout) :: value
        logical :: reduced
        integer :: ec
        if (.not.present(partition)) return
        call MPI_Allreduce(value,reduced,1,MPI_LOGICAL,MPI_LOR,partition%comm,ec)
        call sub_J02_check_mpi(ec,partition%comm)
        value=reduced
    end subroutine sub_J02_partition_any

    subroutine sub_J02_partition_check(mesh,partition,ierr)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_partition_type), intent(in) :: partition
        integer, intent(out) :: ierr
        ierr=SN_SUCCESS
        if (any(partition%count/=[mesh%nr,mesh%nz])) ierr=SN_ERR_MPI_LAYOUT
        if (.not.allocated(mesh%r_edge) .or. .not.allocated(mesh%z_edge) .or. &
            .not.allocated(mesh%active)) then
            ierr=SN_ERR_GEOMETRY_MESH
        else if (size(mesh%r_edge)/=mesh%nr+1 .or. size(mesh%z_edge)/=mesh%nz+1 .or. &
            any(shape(mesh%active)/=[mesh%nr,mesh%nz])) then
            ierr=SN_ERR_GEOMETRY_MESH
        end if
        call sub_J02_sync_status(partition,ierr)
    end subroutine sub_J02_partition_check

    ! Matching velocity nodes are required for matching messages, not just equal n_dir.
    subroutine sub_J02_partition_quadrature(partition,quadrature,ierr)
        use mpi
        type(sn_partition_type), intent(in) :: partition
        type(sn_quadrature_type), intent(in) :: quadrature
        integer, intent(out) :: ierr
        integer :: sizes(3),lo(3),hi(3),ec
        real, allocatable :: values(:),minimum(:),maximum(:)
        sizes=[quadrature%n_angles,quadrature%n_speeds,quadrature%n_dir]
        call MPI_Allreduce(sizes,lo,3,MPI_INTEGER,MPI_MIN,partition%comm,ec)
        call MPI_Allreduce(sizes,hi,3,MPI_INTEGER,MPI_MAX,partition%comm,ec)
        ierr=SN_ERR_MPI_INPUT
        if (any(lo/=hi)) return
        values=[quadrature%mu,quadrature%eta,quadrature%speed,quadrature%weight]
        allocate(minimum(size(values)),maximum(size(values)))
        call MPI_Allreduce(values,minimum,size(values),partition%real_type,MPI_MIN,partition%comm,ec)
        call MPI_Allreduce(values,maximum,size(values),partition%real_type,MPI_MAX,partition%comm,ec)
        call sub_J02_check_mpi(ec,partition%comm)
        if (any(maximum>minimum)) return
        ierr=SN_SUCCESS
    end subroutine sub_J02_partition_quadrature

    ! Exchange edge geometry and active flags, not the global mesh/field.
    subroutine sub_J02_connect_partition_faces(mesh,boundary,partition,ierr,validate_only)
        use mpi
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_boundary_2drz_type), intent(inout) :: boundary
        type(sn_partition_type), intent(in) :: partition
        integer, intent(out) :: ierr
        logical, optional, intent(in) :: validate_only
        real, allocatable :: low(:),high(:),from_low(:),from_high(:)
        integer :: axis,n,j,ec
        logical :: validate
        validate=.false.
        if (present(validate_only)) validate=validate_only
        call sub_J02_partition_check(mesh,partition,ierr)
        if (ierr/=SN_SUCCESS) return
        do axis=1,2
            n=mesh%nz
            if (axis==2) n=mesh%nr
            allocate(low(2*n+2),high(2*n+2),from_low(2*n+2),from_high(2*n+2))
            if (axis==1) then
                low=[mesh%r_edge(1),mesh%z_edge,merge(1.0,0.0,mesh%active(1,:))]
                high=[mesh%r_edge(mesh%nr+1),mesh%z_edge,merge(1.0,0.0,mesh%active(mesh%nr,:))]
            else
                low=[mesh%z_edge(1),mesh%r_edge,merge(1.0,0.0,mesh%active(:,1))]
                high=[mesh%z_edge(mesh%nz+1),mesh%r_edge,merge(1.0,0.0,mesh%active(:,mesh%nz))]
            end if
            from_low=0.0; from_high=0.0
            call MPI_Sendrecv(high,size(high),partition%real_type,partition%neighbor(2*axis),21000+axis, &
                from_low,size(low),partition%real_type,partition%neighbor(2*axis-1),21000+axis, &
                partition%comm,MPI_STATUS_IGNORE,ec)
            call sub_J02_check_mpi(ec,partition%comm)
            call MPI_Sendrecv(low,size(low),partition%real_type,partition%neighbor(2*axis-1),21004+axis, &
                from_high,size(high),partition%real_type,partition%neighbor(2*axis),21004+axis, &
                partition%comm,MPI_STATUS_IGNORE,ec)
            call sub_J02_check_mpi(ec,partition%comm)
            do j=1,2
                if (partition%neighbor(2*axis-2+j)==MPI_PROC_NULL) cycle
                if (j==1) then
                    call check_edge(low,from_low,2*axis-1)
                else
                    call check_edge(high,from_high,2*axis)
                end if
            end do
            deallocate(low,high,from_low,from_high)
        end do
        call sub_J02_sync_status(partition,ierr)
    contains
        subroutine check_edge(own,other,face)
            real, intent(in) :: own(:),other(:)
            integer, intent(in) :: face
            integer :: t,i,k,actual,expected
            real :: scale
            scale=max(maxval(abs(own(:n+2))),tiny(1.0))
            if (maxval(abs(own(:n+2)-other(:n+2)))>32.0*epsilon(1.0)*scale) ierr=SN_ERR_MPI_LAYOUT
            do t=1,n
                if (own(n+2+t)<0.5) cycle
                expected=SN_FACE_WALL
                if (other(n+2+t)>0.5) expected=SN_FACE_REMOTE
                i=t; k=1
                select case(face)
                case(SN_R_LO)
                    i=1; k=t
                    actual=boundary%face_r_lo(i,k)
                    if (.not.validate) boundary%face_r_lo(i,k)=expected
                case(SN_R_HI)
                    i=mesh%nr; k=t
                    actual=boundary%face_r_hi(i,k)
                    if (.not.validate) boundary%face_r_hi(i,k)=expected
                case(SN_Z_LO)
                    actual=boundary%face_z_lo(i,k)
                    if (.not.validate) boundary%face_z_lo(i,k)=expected
                case(SN_Z_HI)
                    k=mesh%nz
                    actual=boundary%face_z_hi(i,k)
                    if (.not.validate) boundary%face_z_hi(i,k)=expected
                case default
                    ierr=SN_ERR_MPI_LAYOUT
                    return
                end select
                if (validate) then
                    if (actual/=expected) ierr=SN_ERR_MPI_LAYOUT
                end if
            end do
        end subroutine check_edge
    end subroutine sub_J02_connect_partition_faces

    ! Mismatched stopping rules would leave other ranks blocked in later collectives.
    subroutine sub_J02_partition_iteration_options(partition,options,ierr)
        use mpi
        type(sn_partition_type), optional, intent(in) :: partition
        type(sn_transport_options_type), intent(in) :: options
        integer, intent(out) :: ierr
        integer :: lo,hi,ec
        real :: values(2),minimum(2),maximum(2)
        ierr=SN_SUCCESS
        if (.not.present(partition)) return
        call MPI_Allreduce(options%max_iterations,lo,1,MPI_INTEGER,MPI_MIN,partition%comm,ec)
        call MPI_Allreduce(options%max_iterations,hi,1,MPI_INTEGER,MPI_MAX,partition%comm,ec)
        if (lo/=hi) ierr=SN_ERR_MPI_INPUT
        values=[options%tolerance,options%diffuse_fraction]
        call MPI_Allreduce(values,minimum,2,partition%real_type,MPI_MIN,partition%comm,ec)
        call MPI_Allreduce(values,maximum,2,partition%real_type,MPI_MAX,partition%comm,ec)
        call sub_J02_check_mpi(ec,partition%comm)
        if (any(maximum>minimum)) ierr=SN_ERR_MPI_INPUT
    end subroutine sub_J02_partition_iteration_options
