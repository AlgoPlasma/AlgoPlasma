program b04_minimal
    use mod_B04_scatter_3d_cyl_nonuniform
    implicit none
    real :: r(0:2), phi(0:2), z(0:2)
    real :: inv_volume(0:2,0:2,0:2), phi_measure(0:2)
    real :: density(0:2,0:2,0:2), cell_density(0:1,0:1,0:1)
    integer :: ierr

    ! Annular sector with physical angular endpoints; all directions are nonuniform.
    r = [1.0, 2.0, 4.0]
    phi = [0.0, 1.0, 3.0]
    z = [0.0, 2.0, 3.0]
    call sub_B04_build_geometry(r, phi, z, .false., inv_volume, phi_measure, ierr)
    if (ierr /= B04_OK) error stop 'B04 geometry failed'

    density = 0.0
    ! One particle, already located in cell [0,0,0], represents eight real particles.
    call sub_B04_scatter_3d_cyl_nonuniform(r, phi, z, .false., &
        [0,0,0], [1.25,0.5,0.5], 8.0, inv_volume, density, ierr)
    if (ierr /= B04_OK) error stop 'B04 scatter failed'
    write(*,'(a,f12.6)') 'Represented number = ', sum(density/inv_volume)

    ! Optional: provide cell-volume averages to a cell-based source assembly.
    call sub_B04_project_density(r, .false., density, cell_density, ierr)
    if (ierr /= B04_OK) error stop 'B04 cell averaging failed'
    write(*,'(a,3(i0,1x))') 'Cell array shape = ', shape(cell_density)
end program b04_minimal
