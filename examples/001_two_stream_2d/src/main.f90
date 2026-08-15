program two_stream_2d
    use mpi
    use two_stream_parameters
    use two_stream_case
    implicit none
    integer :: step, ierr

    call mpi_init(ierr)
    call initialize_case                        ! sub_I01_par_distribute_equilibrium
    call update_electric_field                  ! sub_B01_scatter_3Dxyz, sub_D02_hypre_3Dxyz_bc_A, sub_D02_hypre_3Dxyz_bc_fortran, sub_D05_phi1d_to_phi3d, sub_D06_phi_to_E
    call push_velocities(initial_half_push)     ! sub_C01_gather_3Dxyz, sub_A01_Boris_3Dxyz
    call write_fields(0)                        ! sub_F04_field_output_3d_bin
    call write_particles(0)                     ! sub_F02_par_output

    do step=1,nt
        call push_velocities(full_push)         ! sub_C01_gather_3Dxyz, sub_A01_Boris_3Dxyz
        call move_particles(dt)                 ! Application-specific position update and periodic boundaries
        call update_electric_field              ! sub_B01_scatter_3Dxyz, sub_D02_hypre_3Dxyz_bc_A, sub_D02_hypre_3Dxyz_bc_fortran, sub_D05_phi1d_to_phi3d, sub_D06_phi_to_E

        if (step==1 .or. mod(step,field_stride)==0) call write_fields(step)             ! sub_F04_field_output_3d_bin
        if (step==1 .or. mod(step,particle_stride)==0) call write_particles(step)       ! sub_F02_par_output
    end do

    call finalize_case                          ! sub_D02_hypre_3Dxyz_bc_fortran
    call mpi_finalize(ierr)
end program two_stream_2d

