module two_stream_case
    use mpi
    use two_stream_parameters
    use mod_I01_par_distribute
    use mod_B01_scatter_3Dxyz
    use mod_D02_hypre_3Dxyz_bc
    use mod_D05_phi1d_to_phi3d
    use mod_D06_phi_to_E
    use mod_C01_gather_3Dxyz
    use mod_A01_Boris_3Dxyz
    use mod_F02_par_output
    use mod_F04_field_output
    implicit none

    integer :: il(3) = [1,1,1], iu(3) = [nx,ny,1]
    integer :: periodic(3) = [nx,ny,0], bc(6) = [0,0,0,0,2,2]
    integer :: rank_map(3,0:0), inverse_map(0:2,0:2,0:2)
    integer :: split(3) = [1,1,1]
    real :: domain_length(3) = [lx,ly,0.0]
    real, allocatable :: particles(:,:), density(:,:,:), potential(:,:,:)
    real, allocatable :: ex(:,:,:), ey(:,:,:), ez(:,:,:)
    real, allocatable :: bx(:,:,:), by(:,:,:), bz(:,:,:)
    real, allocatable :: phi_vector(:), rhs(:), matrix_values(:)
    integer(8) :: hypre_grid=0, hypre_stencil=0, hypre_matrix=0
    integer(8) :: hypre_rhs=0, hypre_solution=0
    logical :: solver_initialized = .false.

contains

    subroutine initialize_case
        integer :: p, nseed, s, nproc, ierr
        integer :: nppc(3)
        integer, allocatable :: seed_values(:)
        real :: vt(3), vd(3), kx, ky, k2, phase

        call mpi_comm_size(mpi_comm_world,nproc,ierr)
        if (nproc /= 1) error stop 'This compact example uses one MPI rank.'

        allocate(particles(6,np))
        allocate(density(0:nx+1,0:ny+1,0:2),potential(0:nx+1,0:ny+1,0:2))
        allocate(ex(0:nx+1,0:ny+1,0:2),ey(0:nx+1,0:ny+1,0:2),ez(0:nx+1,0:ny+1,0:2))
        allocate(bx(0:nx+1,0:ny+1,0:2),by(0:nx+1,0:ny+1,0:2),bz(0:nx+1,0:ny+1,0:2))
        allocate(phi_vector(nx*ny),rhs(nx*ny),matrix_values(7*nx*ny))
        density=0.0; potential=0.0; ex=0.0; ey=0.0; ez=0.0
        bx=0.0; by=0.0; bz=0.0; phi_vector=0.0; rhs=0.0; matrix_values=0.0

        rank_map(:,0) = [1,1,1]
        inverse_map = -1
        inverse_map(1,1,1) = 0
        nppc = [nppc_x,nppc_y,1]
        vt = [thermal_speed,thermal_speed,thermal_speed]

        call random_seed(size=nseed)
        allocate(seed_values(nseed))
        do s=1,nseed
            seed_values(s) = random_seed_base + 104729*s
        end do
        call random_seed(put=seed_values)
        deallocate(seed_values)

        vd = [drift_speed,0.0,0.0]
        call sub_I01_par_distribute_equilibrium(particles(:,1:np_beam),nppc,il,iu,vt,vd)

        particles(:,np_beam+1:np) = particles(:,1:np_beam)
        particles(4:6,np_beam+1:np) = -particles(4:6,1:np_beam)

        kx = pi2*mode_x/lx
        ky = pi2*mode_y/ly
        k2 = kx*kx + ky*ky
        do p=1,np
            phase = kx*particles(1,p)*dx + ky*particles(2,p)*dy
            particles(1,p) = particles(1,p) + perturbation*kx*sin(phase)/(k2*dx)
            particles(2,p) = particles(2,p) + perturbation*ky*sin(phase)/(k2*dy)
        end do
        call move_particles(0.0)
    end subroutine initialize_case

    subroutine update_electric_field
        integer :: i, j, m
        real :: mean_rhs

        particles(1:3,:) = particles(1:3,:) + 0.5
        density = 0.0
        call sub_B01_scatter_3Dxyz(il,iu,density,np,particles(1:3,:),particle_weight)
        particles(1:3,:) = particles(1:3,:) - 0.5

        density(nx,:,:) = density(nx,:,:) + density(0,:,:)
        density(1,:,:)  = density(1,:,:)  + density(nx+1,:,:)
        density(:,ny,:) = density(:,ny,:) + density(:,0,:)
        density(:,1,:)  = density(:,1,:)  + density(:,ny+1,:)
        density(0,1:ny,1)=density(nx,1:ny,1); density(nx+1,1:ny,1)=density(1,1:ny,1)
        density(:,0,1)=density(:,ny,1); density(:,ny+1,1)=density(:,1,1)
        density(:,:,0)=density(:,:,1); density(:,:,2)=density(:,:,1)

        m = 1
        do j=1,ny
            do i=1,nx
                rhs(m) = (1.0-density(i,j,1)/(dx*dy))*dx*dx/eps0
                m = m + 1
            end do
        end do
        mean_rhs = sum(rhs)/real(nx*ny)
        rhs = rhs - mean_rhs

        if (.not.solver_initialized) then
            call sub_D02_hypre_3Dxyz_bc_A(il,iu,matrix_values,rhs,bc,[0.0,0.0,0.0,0.0,0.0,0.0])
        end if
        call sub_D02_hypre_3Dxyz_bc_fortran(mpi_comm_world,il,iu,phi_vector,rhs, &
            solver_tolerance,matrix_values,periodic,.not.solver_initialized,.false.,.false., &
            hypre_grid,hypre_stencil,hypre_matrix,hypre_rhs,hypre_solution)
        solver_initialized = .true.
        phi_vector = phi_vector - sum(phi_vector)/real(nx*ny)

        call sub_D05_phi1d_to_phi3d(il,iu,phi_vector,potential,1,rank_map,split,inverse_map,domain_length)
        call sub_D06_phi_to_E(il,iu,potential,ex,ey,ez)
        ex(1:nx,1:ny,1)=ex(1:nx,1:ny,1)/dx
        ey(1:nx,1:ny,1)=ey(1:nx,1:ny,1)/dy
        ez(1:nx,1:ny,1)=0.0
        call fill_field_ghosts(ex); call fill_field_ghosts(ey); call fill_field_ghosts(ez)
    end subroutine update_electric_field

    subroutine push_velocities(push_factor)
        real, intent(in) :: push_factor
        integer :: p
        real :: e_particle(3), b_particle(3), velocity(3)
        do p=1,np
            call sub_C01_gather_3Dxyz(p,np,particles,il,iu,ex,ey,ez,bx,by,bz,e_particle,b_particle)
            velocity = particles(4:6,p)
            call sub_A01_Boris_3Dxyz(velocity,e_particle,b_particle,push_factor)
            particles(4:6,p) = velocity
        end do
    end subroutine push_velocities

    subroutine move_particles(step)
        real, intent(in) :: step
        particles(1,:) = modulo(particles(1,:)+particles(4,:)*step,real(nx))
        particles(2,:) = modulo(particles(2,:)+particles(5,:)*step,real(ny))
        particles(3,:) = 0.5
    end subroutine move_particles

    subroutine write_fields(step)
        integer, intent(in) :: step
        call sub_F04_field_output_3d_bin('Ex',step,il,iu,ex(1:nx,1:ny,1:1))
        call sub_F04_field_output_3d_bin('Ey',step,il,iu,ey(1:nx,1:ny,1:1))
    end subroutine write_fields

    subroutine write_particles(step)
        integer, intent(in) :: step
        call sub_F02_par_output('bin','par01',step,np,particles)
    end subroutine write_particles

    subroutine finalize_case
        if (solver_initialized) call sub_D02_hypre_3Dxyz_bc_fortran( &
            mpi_comm_world,il,iu,phi_vector,rhs,solver_tolerance,matrix_values,periodic, &
            .false.,.false.,.true.,hypre_grid,hypre_stencil,hypre_matrix,hypre_rhs,hypre_solution)
    end subroutine finalize_case

    subroutine fill_field_ghosts(field)
        real, intent(inout) :: field(0:nx+1,0:ny+1,0:2)
        field(0,1:ny,1)=field(nx,1:ny,1); field(nx+1,1:ny,1)=field(1,1:ny,1)
        field(:,0,1)=field(:,ny,1); field(:,ny+1,1)=field(:,1,1)
        field(:,:,0)=field(:,:,1); field(:,:,2)=field(:,:,1)
    end subroutine fill_field_ghosts
end module two_stream_case

