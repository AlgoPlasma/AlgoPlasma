!> @file sub_I02_load_init_particles_bin.f90
!> @author Zhongping ZHAO (2026/4/22)
!> @brief Read initial particle binary files and distribute particles to the
!> local MPI subdomain.
!>
!> @details
!> Species 1 is read from ``./output_init_particles_bin/par_ele_init.bin`` and
!> species 2 is read from ``./output_init_particles_bin/par_ion_init.bin``.
!> Each binary file is expected to contain raw stream records in the order
!> ``x,y,z,vx,vy,vz``. The routine keeps only particles whose positions fall
!> inside the local ``il``/``iu`` subdomain bounds, then uses ``MPI_Allreduce``
!> to choose the allocation size for the local particle array.

!> @param[out] npmax: integer, maximum allocated local particle number after
!> applying the expansion factor ``f_npmax``
!> @param[out] np: integer (:), local particle number of each species in the
!> current MPI rank
!> @param[in] ns: integer, total number of particle species
!> @param[in] np_load: integer, number of particles read from each binary
!> file before local filtering
!> @param[in] mpi_i_para: integer, MPI rank index
!> @param[in] il: integer (1:3), cell-center lower indices in x,y,z
!> @param[in] iu: integer (1:3), cell-center upper indices in x,y,z
!> @param[in,out] ierr_para: integer, MPI error flag
!> @param[in] mpi_int_para: integer, MPI integer datatype handle
!> @param[in] mpi_max_para: integer, MPI max reduction operator handle
!> @param[in] mpi_comm_world_para: integer, MPI communicator handle
!> @param[out] par: real (:,:,:), local particle array storing
!> ``x,y,z,vx,vy,vz``
!> @param[in] f_npmax: real, expansion factor used to enlarge ``npmax`` for
!> array allocation
!> @param[out] wei: real (:), particle weight of each species
!> @param[in] np_real: real, physical particle number represented by the
!> loaded particles

subroutine sub_I02_load_init_particles_bin(npmax,np,ns,np_load,mpi_i_para,il,iu, &
    ierr_para,mpi_int_para,mpi_max_para,mpi_comm_world_para,par,f_npmax, &
    wei,np_real)

    use mpi

    implicit none

    integer :: npmax
    integer,allocatable :: np(:)
    integer :: ns,np_load,mpi_i_para
    integer :: il(1:3),iu(1:3)
    integer :: ierr_para
    integer :: mpi_int_para,mpi_max_para,mpi_comm_world_para
    real,allocatable :: par(:,:,:)
    real :: f_npmax
    real,allocatable :: wei(:)
    real :: np_real

    integer :: ios,i,j,n,npmax0
    real,allocatable :: buf(:,:),par_buf(:,:,:)
    real :: r(1:6)

    npmax = 0

    allocate(np(1:ns))
    np = 0

    allocate(par_buf(1:6,1:np_load,1:ns))
    par_buf = 0.0

    allocate(buf(1:6,1:np_load))
    buf = 0.0

    do j = 1,ns

        buf = 0.0

        if (j == 1) then
            open(1000, &
                file = './output_init_particles_bin/par_ele_init.bin', &
                status = 'old', &
                access = 'stream', &
                form = 'unformatted', &
                action = 'read', &
                iostat = ios)
            if (mpi_i_para == 0) write(*,*) "- Load 'par_ele_init.bin'..."
        elseif (j == 2) then
            open(1000, &
                file = './output_init_particles_bin/par_ion_init.bin', &
                status = 'old', &
                access = 'stream', &
                form = 'unformatted', &
                action = 'read', &
                iostat = ios)
            if (mpi_i_para == 0) write(*,*) "- Load 'par_ion_init.bin'..."
        end if

        if (ios /= 0) then
            write(*,*) "Error opening particle file."
            stop
        end if

        n = 0
        do i = 1,np_load
            read(1000) r(1:6)

            if (r(1) < real(il(1) - 1) .or. r(1) >= real(iu(1))) cycle
            if (r(2) < real(il(2) - 1) .or. r(2) >= real(iu(2))) cycle
            if (r(3) < real(il(3) - 1) .or. r(3) >= real(iu(3))) cycle

            n = n + 1
            buf(1:6,n) = r(1:6)
        end do

        close(1000)

        np(j) = n
        par_buf(1:6,1:n,j) = buf(1:6,1:n)

        call mpi_allreduce(n,npmax0,1,mpi_int_para,mpi_max_para, &
            mpi_comm_world_para,ierr_para)

        if (j == 1) then
            npmax = npmax0
        else
            npmax = max(npmax,npmax0)
        end if

    end do

    deallocate(buf)

    npmax = int(npmax * f_npmax)

    allocate(par(1:6,1:npmax,1:ns))
    par = 0.0

    do j = 1,ns
        par(1:6,1:np(j),j) = par_buf(1:6,1:np(j),j)
    end do

    deallocate(par_buf)

    allocate(wei(1:ns))
    wei = 0.0
    wei(1:ns) = np_real / real(np_load)

    if (mpi_i_para == 0) then
        write(*,*) "- Particle weight:",wei
    end if

end subroutine sub_I02_load_init_particles_bin
