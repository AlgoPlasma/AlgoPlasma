! Three essential checks for CEX coefficients; all cross sections are synthetic.
program test_J02_cex_coefficients
    use mod_J02_neutral_sn_transport_2Drz
    implicit none
    type(sn_reaction_table_type) :: cm_table, lab_table, constant_table
    type(sn_quadrature_type) :: neutral_quadrature, ion_quadrature
    real, parameter :: qe=1.602176634e-19, mass=2.18017e-25, density=1.e15, sigma0=1.e-19
    real, allocatable :: ion_distribution(:), zero_distribution(:), beam(:)
    real, allocatable :: neutral_velocity(:,:), ion_velocity(:,:), frequency(:), sigma_t(:)
    real :: energy_ev, cross_section_m2, kernel, energy_ref, kernel_ref, density_error, frequency_error, expected
    integer :: ierr, m

    ! 1. Known linear cross section: cross_section_m2(E)=sigma0*(1+E/10), with E in eV.
    call sub_J02_initialize_reaction_table([0.0,1.0,10.0,100.0], &
        sigma0*[1.0,1.1,2.0,11.0],SN_REACTION_ENERGY_CM,SN_REACTION_RANGE_ERROR,cm_table,ierr)
    call check_status()
    call sub_J02_evaluate_reaction_kernel(cm_table,mass,mass,12000.0,energy_ev,cross_section_m2,kernel,ierr)
    call check_status()
    energy_ref=mass*12000.0**2/(4.0*qe)
    kernel_ref=sigma0*(1.0+energy_ref/10.0)*12000.0
    if (abs(energy_ev/energy_ref-1.0)>1.e-12.or.abs(kernel/kernel_ref-1.0)>1.e-12) &
        error stop 'energy or linear cross-section kernel differs from hand calculation'
    call sub_J02_initialize_reaction_table([0.0,100.0],[sigma0,sigma0], &
        SN_REACTION_ENERGY_PROJECTILE_LAB,SN_REACTION_RANGE_ERROR,lab_table,ierr)
    call check_status()
    ! Target mass changes; projectile-lab energy must still use the first mass.
    call sub_J02_evaluate_reaction_kernel(lab_table,mass,2.0*mass,12000.0,energy_ev,cross_section_m2,kernel,ierr)
    call check_status()
    if (abs(energy_ev/(2.0*energy_ref)-1.0)>1.e-12) error stop 'projectile-lab energy convention'
    call sub_J02_evaluate_reaction_cross_section(cm_table,101.0,cross_section_m2,ierr)
    if (ierr/=SN_ERR_REACTION_ENERGY_RANGE) error stop 'out-of-range table query must be explicit'
    ! Refactoring must retain numeric guards and cleared scalar outputs on failure.
    call sub_J02_evaluate_reaction_kernel(cm_table,mass,mass,huge(1.0),energy_ev,cross_section_m2,kernel,ierr)
    if (ierr/=SN_ERR_NUMERIC_RANGE) error stop 'kernel overflow must return a status'
    if (maxval(abs([energy_ev,cross_section_m2,kernel]))>0.0) error stop 'failed kernel exposed partial outputs'
    print *, 'PASS 1: energy conventions, cross section and kernel match hand calculation'

    ! 2. One frozen Maxwellian, normalized by number density on a nonuniform grid.
    call sub_J02_build_phase_quadrature_from_edges(16,[0.0,500.0,1500.0,4000.0],'midpoint',ion_quadrature,ierr)
    call check_status()
    call sub_J02_build_ion_maxwellian(ion_quadrature,density,1000.0,mass,200.0,400.0,ion_distribution,ierr)
    call check_status()
    density_error=abs(sum(ion_quadrature%weight*ion_distribution)/density-1.0)
    if (density_error>1.e-12.or.any(ion_distribution<0.0)) error stop 'ion density normalization'
    call sub_J02_build_ion_maxwellian(ion_quadrature,0.0,1000.0,mass,200.0,400.0,zero_distribution,ierr)
    call check_status()
    if (any(abs(zero_distribution)>0.0)) error stop 'zero density created particles'
    write(*,'(a,es12.4)') 'PASS 2: ion density relative error = ',density_error

    ! 3. A monoenergetic ion node gives frequency=n_i*sigma0*g and sigma_t=frequency/v exactly.
    call sub_J02_build_phase_quadrature_from_edges(8,[0.0,1000.0,3000.0],'midpoint',neutral_quadrature,ierr)
    call check_status()
    call sub_J02_build_velocity_vectors(neutral_quadrature,neutral_velocity,ierr)
    call check_status()
    call sub_J02_build_velocity_vectors(ion_quadrature,ion_velocity,ierr)
    call check_status()
    call sub_J02_initialize_reaction_table([0.0,1000.0],[sigma0,sigma0], &
        SN_REACTION_ENERGY_CM,SN_REACTION_RANGE_ERROR,constant_table,ierr)
    call check_status()
    allocate(beam(ion_quadrature%n_dir));beam=0.0;beam(1)=density/ion_quadrature%weight(1)
    call sub_J02_compute_cex_frequency(neutral_quadrature,ion_quadrature,beam,mass,mass,constant_table, &
        frequency,sigma_t,ierr)
    call check_status()
    frequency_error=0.0
    do m=1,neutral_quadrature%n_dir
        expected=density*sigma0*sqrt(sum((neutral_velocity(:,m)-ion_velocity(:,1))**2))
        frequency_error=max(frequency_error,abs(frequency(m)/expected-1.0))
        if (abs(sigma_t(m)*neutral_quadrature%speed(m)/frequency(m)-1.0)>1.e-12) error stop 'sigma_t conversion'
    end do
    if (frequency_error>1.e-12) error stop 'single-ion-node collision frequency'
    ! Also check the end-to-end Maxwellian sum using the same constant cross section.
    call sub_J02_compute_cex_frequency(neutral_quadrature,ion_quadrature,ion_distribution,mass,mass, &
        constant_table,frequency,sigma_t,ierr)
    call check_status()
    expected=sum(ion_quadrature%weight*ion_distribution*sqrt(sum((spread(neutral_velocity(:,1),2, &
        ion_quadrature%n_dir)-ion_velocity)**2,dim=1)))*sigma0
    if (abs(frequency(1)/expected-1.0)>1.e-12) error stop 'Maxwellian collision frequency sum'
    write(*,'(a,es12.4)') 'PASS 3: frequency maximum relative error = ',frequency_error
    beam(1)=-1.0
    call sub_J02_compute_cex_frequency(neutral_quadrature=neutral_quadrature, ion_quadrature=ion_quadrature, &
        ion_distribution=beam, neutral_mass=mass, ion_mass=mass, table=constant_table, &
        frequency=frequency, sigma_t=sigma_t, ierr=ierr)
    if (ierr/=SN_ERR_CEX_BACKGROUND) error stop 'negative background accepted'
    if (allocated(frequency).or.allocated(sigma_t)) error stop 'failed frequency exposed stale outputs'
    print *, 'RESULT: PASS (three checks, synthetic cross sections, double precision)'
contains
    subroutine check_status()
        if (ierr/=SN_SUCCESS) then
            print *,trim(fun_J02_error_message(ierr))
            error stop 1
        end if
    end subroutine check_status
end program test_J02_cex_coefficients
