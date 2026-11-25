!> Prescribed-ion CEX background and velocity-weighted loss coefficients.
!> No CEX gain term, neutral update, or transport coupling is performed here.

    !> Single-cell Maxwellian on ion nodes, normalized by NUMBER DENSITY.
    !> density [m^-3], temperature [K], ion_mass [kg], drift velocities [m/s].
    !> sum(ion_quadrature%weight*ion_distribution)=density; other moments may be approximate.
    subroutine sub_J02_build_ion_maxwellian(ion_quadrature, density, temperature, ion_mass, &
        drift_velocity_r, drift_velocity_z, ion_distribution, ierr)
        use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
        type(sn_quadrature_type), intent(in) :: ion_quadrature
        real, intent(in) :: density, temperature, ion_mass, drift_velocity_r, drift_velocity_z
        real, allocatable, intent(out) :: ion_distribution(:)
        integer, intent(out) :: ierr
        real, parameter :: boltzmann_constant = 1.380649e-23
        real, allocatable :: ion_velocity(:,:), shape(:)
        real :: thermal_speed, relative_speed, tail_cutoff, normalization
        integer :: j

        ierr = SN_ERR_CEX_BACKGROUND
        if (.not.all(ieee_is_finite([density,temperature,ion_mass, &
            drift_velocity_r,drift_velocity_z]))) return
        if (density < 0.0 .or. temperature <= 0.0 .or. ion_mass <= 0.0) return
        call sub_J02_build_velocity_vectors(ion_quadrature, ion_velocity, ierr)
        allocate(shape(ion_quadrature%n_dir))
        shape = 0.0
        if (density > 0.0) then
            thermal_speed = sqrt(boltzmann_constant*temperature)/sqrt(ion_mass)
            tail_cutoff = sqrt(-2.0*log(tiny(1.0)))
            do j = 1, ion_quadrature%n_dir
                relative_speed = fun_J02_relative_speed(ion_velocity(:,j), &
                    [drift_velocity_r,0.0,drift_velocity_z])
                ! Negligible tails are zero; keep the exponent bounded.
                if (relative_speed/tail_cutoff > thermal_speed) cycle
                shape(j) = exp(-0.5*(relative_speed/thermal_speed)**2)
            end do
            normalization = sum(ion_quadrature%weight*shape)
            ierr = SN_ERR_CEX_NORMALIZATION
            if (normalization <= 0.0) return
            shape = density*(shape/normalization)
        end if
        call move_alloc(shape, ion_distribution)
        ierr = SN_SUCCESS
    end subroutine sub_J02_build_ion_maxwellian

    !> frequency(m) = sum_j ion_population(j)*kernel(m,j) [s^-1].
    !> sigma_t(m) = frequency(m)/neutral_quadrature%speed(m) [m^-1].
    !> kernel = cross_section_m2*relative_speed [m^3/s]; sigma_t is a path-loss coefficient.
    !> Grids may differ but use the SAME local (r,phi,z) basis; J02 has v_phi=0.
    !> ion_distribution already contains density. Zero-population nodes are skipped.
    !> CEX mass arguments are neutral then ion; projectile-lab tables use the ION mass.
    !> Outputs remain unallocated on failure; no dense pair matrix is stored.
    subroutine sub_J02_compute_cex_frequency(neutral_quadrature, ion_quadrature, ion_distribution, &
        neutral_mass, ion_mass, table, frequency, sigma_t, ierr)
        use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
        type(sn_quadrature_type), intent(in) :: neutral_quadrature, ion_quadrature
        real, intent(in) :: ion_distribution(:), neutral_mass, ion_mass
        type(sn_reaction_table_type), intent(in) :: table
        real, allocatable, intent(out) :: frequency(:), sigma_t(:)
        integer, intent(out) :: ierr
        real, allocatable :: neutral_velocity(:,:), ion_velocity(:,:), ion_population(:), frequency_work(:)
        real :: energy_factor, relative_speed, energy_ev, cross_section_m2, kernel
        integer :: m, j

        ierr = SN_ERR_CEX_BACKGROUND_SHAPE
        if (size(ion_distribution) /= ion_quadrature%n_dir) return
        ierr = SN_ERR_CEX_BACKGROUND
        if (.not.all(ieee_is_finite(ion_distribution))) return
        if (any(ion_distribution < 0.0)) return
        call sub_J02_reaction_energy_factor(table, projectile_mass=ion_mass, target_mass=neutral_mass, &
            energy_factor=energy_factor, ierr=ierr)
        if (ierr /= SN_SUCCESS) return
        call sub_J02_build_velocity_vectors(neutral_quadrature, neutral_velocity, ierr)
        call sub_J02_build_velocity_vectors(ion_quadrature, ion_velocity, ierr)

        ion_population = ion_quadrature%weight*ion_distribution
        allocate(frequency_work(neutral_quadrature%n_dir))
        frequency_work = 0.0
        do m = 1, neutral_quadrature%n_dir
            do j = 1, ion_quadrature%n_dir
                if (ion_population(j) <= 0.0) cycle
                relative_speed = fun_J02_relative_speed(neutral_velocity(:,m), ion_velocity(:,j))
                call sub_J02_reaction_kernel_at_speed(table, energy_factor, relative_speed, &
                    energy_ev, cross_section_m2, kernel, ierr)
                if (ierr /= SN_SUCCESS) return
                frequency_work(m) = frequency_work(m)+ion_population(j)*kernel
            end do
        end do
        sigma_t = frequency_work/neutral_quadrature%speed
        call move_alloc(frequency_work, frequency)
    end subroutine sub_J02_compute_cex_frequency
