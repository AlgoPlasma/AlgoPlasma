!> Spatial pipeline: each quadrant has an acyclic upstream/downstream rank graph.
!> MPI calls stay on the calling thread. OpenMP sees only ready, read-only receive buffers.
    subroutine sub_J02_mpi_sweep(mesh,geometry,quadrature,sigma_t,boundary,psi, &
        status,failed_i,failed_k,fraction,boundary_inflow,zlo_inflow,psi_old,wall,diffuse, &
        zlo_source_xi_lo,zlo_source_xi_hi,progress_every,partition)
        use mpi
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_geometry_2drz_type), intent(in) :: geometry
        type(sn_quadrature_type), intent(in) :: quadrature
        type(sn_boundary_2drz_type), intent(in) :: boundary
        type(sn_partition_type), intent(in) :: partition
        real, intent(in) :: sigma_t(:,:,:),fraction
        real, contiguous, intent(inout) :: psi(:,:,:,:)
        integer, intent(inout) :: status(:),failed_i(:),failed_k(:)
        integer, intent(in) :: progress_every
        real, optional, intent(in) :: boundary_inflow(:,:,:,:),zlo_inflow(:),psi_old(:,:,:,:)
        real, optional, intent(in) :: wall(:),diffuse(:,:,:),zlo_source_xi_lo(:),zlo_source_xi_hi(:)
        type(sn_sweep_halo_type) :: halo
        real, allocatable, asynchronous :: send_r(:,:,:),send_z(:,:,:)
        real, allocatable :: local_inlet(:)
        integer, allocatable :: nodes(:)
        integer :: quadrant,sr,sz,m,j,n,up_r,down_r,up_z,down_z,ir,kz,ec,requests(2)
        if (present(zlo_inflow)) then
            local_inlet=zlo_inflow
            if (partition%first(2)/=1) local_inlet=0.0
        end if
        do quadrant=0,3
            sr=1; sz=1
            if (btest(quadrant,0)) sr=-1
            if (btest(quadrant,1)) sz=-1
            nodes=pack([(m,m=1,quadrature%n_dir)], &
                ((quadrature%mu>=0.0).eqv.(sr>0)) .and. ((quadrature%eta>=0.0).eqv.(sz>0)))
            n=size(nodes)
            up_r=SN_R_LO; down_r=SN_R_HI; ir=mesh%nr
            up_z=SN_Z_LO; down_z=SN_Z_HI; kz=mesh%nz
            if (sr<0) then
                up_r=SN_R_HI; down_r=SN_R_LO; ir=1
            end if
            if (sz<0) then
                up_z=SN_Z_HI; down_z=SN_Z_LO; kz=1
            end if
            allocate(halo%r(3,mesh%nz,n),halo%z(3,mesh%nr,n),send_r(3,mesh%nz,n),send_z(3,mesh%nr,n))
            halo%r=0.0; halo%z=0.0
            call MPI_Recv(halo%r,size(halo%r),partition%real_type,partition%neighbor(up_r),21010+quadrant, &
                partition%comm,MPI_STATUS_IGNORE,ec)
            call sub_J02_check_mpi(ec,partition%comm)
            call MPI_Recv(halo%z,size(halo%z),partition%real_type,partition%neighbor(up_z),21014+quadrant, &
                partition%comm,MPI_STATUS_IGNORE,ec)
            call sub_J02_check_mpi(ec,partition%comm)
            call sub_J02_sweep_batch(mesh,geometry,quadrature,sigma_t,boundary,nodes,psi, &
                status,failed_i,failed_k,fraction,boundary_inflow,local_inlet,psi_old,wall,diffuse, &
                zlo_source_xi_lo,zlo_source_xi_hi,progress_every,halo,partition%rank)
            do j=1,n
                send_r(:,:,j)=psi(:,ir,:,nodes(j))
                send_z(:,:,j)=psi(:,:,kz,nodes(j))
            end do
            ! Even on local numerical failure, complete the communication graph.
            ! The public wrapper collectively selects the error after all quadrants.
            call MPI_Isend(send_r,size(send_r),partition%real_type,partition%neighbor(down_r),21010+quadrant, &
                partition%comm,requests(1),ec)
            call sub_J02_check_mpi(ec,partition%comm)
            call MPI_Isend(send_z,size(send_z),partition%real_type,partition%neighbor(down_z),21014+quadrant, &
                partition%comm,requests(2),ec)
            call sub_J02_check_mpi(ec,partition%comm)
            call MPI_Waitall(2,requests,MPI_STATUSES_IGNORE,ec)
            call sub_J02_check_mpi(ec,partition%comm)
            deallocate(halo%r,halo%z,send_r,send_z)
        end do
    end subroutine sub_J02_mpi_sweep

    ! Both owners reconstruct the same upwind flux, in the same m order.
    ! Keep partition flux separate from physical open-boundary inflow/outflow.
    subroutine sub_J02_reconstruct_partition_fluxes(mesh,geometry,quadrature,boundary,psi,partition,flux,ierr)
        use mpi
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_geometry_2drz_type), intent(in) :: geometry
        type(sn_quadrature_type), intent(in) :: quadrature
        type(sn_boundary_2drz_type), intent(in) :: boundary
        type(sn_partition_type), intent(in) :: partition
        real, intent(in) :: psi(:,:,:,:)
        real, allocatable, intent(out) :: flux(:,:,:)
        integer, intent(out) :: ierr
        real, allocatable :: low(:,:,:),high(:,:,:),from_low(:,:,:),from_high(:,:,:)
        real :: coefficient(3),trace,component
        integer :: axis,n,t,m,ec,i,k,face,j
        allocate(flux(4,mesh%nr,mesh%nz))
        flux=0.0
        do axis=1,2
            n=mesh%nz
            if (axis==2) n=mesh%nr
            allocate(low(3,n,quadrature%n_dir),high(3,n,quadrature%n_dir), &
                from_low(3,n,quadrature%n_dir),from_high(3,n,quadrature%n_dir))
            if (axis==1) then
                low=psi(:,1,:,:); high=psi(:,mesh%nr,:,:)
            else
                low=psi(:,:,1,:); high=psi(:,:,mesh%nz,:)
            end if
            from_low=0.0; from_high=0.0
            call MPI_Sendrecv(high,size(high),partition%real_type,partition%neighbor(2*axis),21020+axis, &
                from_low,size(low),partition%real_type,partition%neighbor(2*axis-1),21020+axis, &
                partition%comm,MPI_STATUS_IGNORE,ec)
            call sub_J02_check_mpi(ec,partition%comm)
            call MPI_Sendrecv(low,size(low),partition%real_type,partition%neighbor(2*axis-1),21024+axis, &
                from_high,size(high),partition%real_type,partition%neighbor(2*axis),21024+axis, &
                partition%comm,MPI_STATUS_IGNORE,ec)
            call sub_J02_check_mpi(ec,partition%comm)
            do j=1,2
                face=2*axis-2+j
                do t=1,n
                    i=t; k=1
                    if (axis==1) then
                        i=1; k=t
                        if (j==2) i=mesh%nr
                    else if (j==2) then
                        k=mesh%nz
                    end if
                    if (.not.mesh%active(i,k)) cycle
                    if (fun_J02_face_type(boundary,face,i,k)/=SN_FACE_REMOTE) cycle
                    do m=1,quadrature%n_dir
                        component=quadrature%mu(m)
                        if (axis==2) component=quadrature%eta(m)
                        if (j==1) then
                            coefficient=low(:,t,m)
                            if (component>0.0) coefficient=from_low(:,t,m)
                        else
                            coefficient=high(:,t,m)
                            if (component<0.0) coefficient=from_high(:,t,m)
                        end if
                        if (axis==1) then
                            trace=coefficient(1)+sign(1.0,component)*coefficient(2)
                        else
                            trace=coefficient(1)+geometry%xi_bar(i)*coefficient(2)+ &
                                sign(1.0,component)*coefficient(3)
                        end if
                        flux(face,i,k)=flux(face,i,k)+quadrature%weight(m)*quadrature%speed(m)*component*trace
                    end do
                end do
            end do
            deallocate(low,high,from_low,from_high)
        end do
        ierr=SN_SUCCESS
    end subroutine sub_J02_reconstruct_partition_fluxes
