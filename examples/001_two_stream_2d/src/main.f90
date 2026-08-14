program two_stream_2d
    use mpi
    use two_stream_parameters
    use two_stream_case
    implicit none
    integer :: step, ierr

    call mpi_init(ierr)
    call initialize_case
    call update_electric_field
    call push_velocities(initial_half_push)
    call write_fields(0)
    call write_particles(0)

    do step=1,nt
        call push_velocities(full_push)
        call move_particles(dt)
        call update_electric_field

        if (step==1 .or. mod(step,field_stride)==0) call write_fields(step)
        if (step==1 .or. mod(step,particle_stride)==0) call write_particles(step)
    end do

    call finalize_case
    call mpi_finalize(ierr)
end program two_stream_2d

