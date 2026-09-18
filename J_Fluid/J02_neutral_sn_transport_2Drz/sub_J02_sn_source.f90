!> Open-boundary source shapes and flux normalization.
!>
!> A reservoir shape is a velocity-space phase density sampled at each
!> quadrature node.  In contrast, an MC crossing sample is a probability mass
!> per discrete incoming bin.  The latter is divided by the discrete crossing
!> measure w_m v_m |Omega_m.n| before it can be used as a phase-density shape.

    subroutine sub_J02_build_maxwellian_inflow_shape(quadrature, temperature, &
        particle_mass, inflow_shape, ierr)
        type(sn_quadrature_type), intent(in) :: quadrature
        real, intent(in) :: temperature, particle_mass
        real, allocatable, intent(out) :: inflow_shape(:)
        integer, intent(out) :: ierr

        call sub_J02_build_drifted_maxwellian_inflow_shape(quadrature, temperature, &
            particle_mass, 0.0, 0.0, inflow_shape, ierr)
    end subroutine sub_J02_build_maxwellian_inflow_shape

    subroutine sub_J02_build_drifted_maxwellian_inflow_shape(quadrature, &
        temperature, particle_mass, drift_velocity_r, drift_velocity_z, &
        inflow_shape, ierr)
        type(sn_quadrature_type), intent(in) :: quadrature
        real, intent(in) :: temperature, particle_mass
        real, intent(in) :: drift_velocity_r, drift_velocity_z
        real, allocatable, intent(out) :: inflow_shape(:)
        integer, intent(out) :: ierr
        real, parameter :: boltzmann_constant = 1.380649e-23
        real :: thermal_factor, velocity_r, velocity_z
        integer :: m

        ierr = SN_SUCCESS
        if (.not. fun_J02_quadrature_is_valid(quadrature)) then
            ierr = SN_ERR_QUADRATURE_LAYOUT
            return
        end if
        if (temperature <= 0.0) then
            ierr = SN_ERR_SOURCE_TEMPERATURE
            return
        end if
        if (particle_mass <= 0.0) then
            ierr = SN_ERR_SOURCE_MASS
            return
        end if

! Unit-density Maxwellian in two velocity dimensions:
! f(v_r,v_z)=alpha/pi*exp[-alpha*((v_r-u_r)^2+(v_z-u_z)^2)].
        thermal_factor = particle_mass/(2.0*boltzmann_constant*temperature)
        allocate(inflow_shape(quadrature%n_dir))
        do m = 1, quadrature%n_dir
            velocity_r = quadrature%speed(m)*quadrature%mu(m)
            velocity_z = quadrature%speed(m)*quadrature%eta(m)
            inflow_shape(m) = thermal_factor/acos(-1.0)*exp(-thermal_factor*( &
                (velocity_r-drift_velocity_r)**2+ &
                (velocity_z-drift_velocity_z)**2))
        end do
    end subroutine sub_J02_build_drifted_maxwellian_inflow_shape

    subroutine sub_J02_build_mc_crossing_inflow_shape(quadrature, normal_r, &
        normal_z, crossing_bin_probability, inflow_shape, ierr)
        type(sn_quadrature_type), intent(in) :: quadrature
        real, intent(in) :: normal_r, normal_z
        real, intent(in) :: crossing_bin_probability(:)
        real, allocatable, intent(out) :: inflow_shape(:)
        integer, intent(out) :: ierr
        real :: ndot, incoming_probability
        integer :: m

        ierr = SN_SUCCESS
        if (.not. fun_J02_quadrature_is_valid(quadrature)) then
            ierr = SN_ERR_QUADRATURE_LAYOUT
            return
        end if
        if (size(crossing_bin_probability) /= quadrature%n_dir) then
            ierr = SN_ERR_SOURCE_INPUT_SHAPE
            return
        end if
        if (.not. fun_J02_normal_is_unit(normal_r, normal_z)) then
            ierr = SN_ERR_SOURCE_NORMAL
            return
        end if
        if (any(crossing_bin_probability < 0.0)) then
            ierr = SN_ERR_SOURCE_NEGATIVE_DATA
            return
        end if

        allocate(inflow_shape(quadrature%n_dir))
        inflow_shape = 0.0
        incoming_probability = 0.0
        do m = 1, quadrature%n_dir
            ndot = quadrature%mu(m)*normal_r+quadrature%eta(m)*normal_z
            if (ndot < 0.0) then
                incoming_probability = incoming_probability+crossing_bin_probability(m)
                if (crossing_bin_probability(m) > 0.0) then
                    inflow_shape(m) = crossing_bin_probability(m)/(quadrature%weight(m)* &
                        quadrature%speed(m)*(-ndot))
                end if
            else if (crossing_bin_probability(m) > 0.0) then
                ierr = SN_ERR_SOURCE_OUTGOING_DATA
                deallocate(inflow_shape)
                return
            end if
        end do
        if (incoming_probability <= tiny(incoming_probability)) then
            ierr = SN_ERR_SOURCE_ZERO_DATA
            deallocate(inflow_shape)
        end if
    end subroutine sub_J02_build_mc_crossing_inflow_shape

    subroutine sub_J02_build_mc_crossing_bins_inflow_shape(quadrature, normal_r, &
        normal_z, crossing_bin_probability, inflow_shape, ierr)
        type(sn_quadrature_type), intent(in) :: quadrature
        real, intent(in) :: normal_r, normal_z, crossing_bin_probability(:)
        real, allocatable, intent(out) :: inflow_shape(:)
        integer, intent(out) :: ierr

        call sub_J02_build_mc_crossing_inflow_shape(quadrature, normal_r, normal_z, &
            crossing_bin_probability, inflow_shape, ierr)
    end subroutine sub_J02_build_mc_crossing_bins_inflow_shape

    subroutine sub_J02_build_mc_crossing_pdf_inflow_shape(quadrature, normal_r, &
        normal_z, crossing_pdf, inflow_shape, ierr)
        type(sn_quadrature_type), intent(in) :: quadrature
        real, intent(in) :: normal_r, normal_z, crossing_pdf(:)
        real, allocatable, intent(out) :: inflow_shape(:)
        integer, intent(out) :: ierr
        real :: ndot
        integer :: m

        ierr = SN_SUCCESS
        if (.not. fun_J02_quadrature_is_valid(quadrature)) then
            ierr = SN_ERR_QUADRATURE_LAYOUT
            return
        end if
        if (size(crossing_pdf) /= quadrature%n_dir) then
            ierr = SN_ERR_SOURCE_INPUT_SHAPE
            return
        end if
        if (.not. fun_J02_normal_is_unit(normal_r, normal_z)) then
            ierr = SN_ERR_SOURCE_NORMAL
            return
        end if
        if (any(crossing_pdf < 0.0)) then
            ierr = SN_ERR_SOURCE_NEGATIVE_DATA
            return
        end if
        allocate(inflow_shape(quadrature%n_dir))
        inflow_shape = 0.0
        do m = 1, quadrature%n_dir
            ndot = quadrature%mu(m)*normal_r+quadrature%eta(m)*normal_z
            if (ndot < 0.0) then
                inflow_shape(m) = crossing_pdf(m)/(quadrature%speed(m)*(-ndot))
            else if (crossing_pdf(m) > 0.0) then
                ierr = SN_ERR_SOURCE_OUTGOING_DATA
                deallocate(inflow_shape)
                return
            end if
        end do
        if (maxval(inflow_shape) <= tiny(1.0)) then
            ierr = SN_ERR_SOURCE_ZERO_DATA
            deallocate(inflow_shape)
        end if
    end subroutine sub_J02_build_mc_crossing_pdf_inflow_shape

    subroutine sub_J02_build_sigma_from_frequency(quadrature, ionization_frequency, &
        sigma_t, ierr)
        type(sn_quadrature_type), intent(in) :: quadrature
        real, intent(in) :: ionization_frequency(:, :)
        real, allocatable, intent(out) :: sigma_t(:, :, :)
        integer, intent(out) :: ierr
        integer :: m

        ierr = SN_SUCCESS
        if (.not. fun_J02_quadrature_is_valid(quadrature)) then
            ierr = SN_ERR_QUADRATURE_LAYOUT
            return
        end if
        if (size(ionization_frequency, 1) < 1 .or. size(ionization_frequency, 2) < 1) then
            ierr = SN_ERR_SIGMA_FREQUENCY_SHAPE
            return
        end if
        if (any(ionization_frequency < 0.0)) then
            ierr = SN_ERR_SIGMA_NEGATIVE_FREQUENCY
            return
        end if
        allocate(sigma_t(size(ionization_frequency, 1), &
            size(ionization_frequency, 2), quadrature%n_dir))
        do m = 1, quadrature%n_dir
            sigma_t(:, :, m) = ionization_frequency/quadrature%speed(m)
        end do
    end subroutine sub_J02_build_sigma_from_frequency

    subroutine sub_J02_normalize_inflow_flux(quadrature, normal_r, normal_z, &
        target_flux, inflow_shape, psi_in, ierr)
        type(sn_quadrature_type), intent(in) :: quadrature
        real, intent(in) :: normal_r, normal_z, target_flux
        real, intent(in) :: inflow_shape(:)
        real, allocatable, intent(out) :: psi_in(:)
        integer, intent(out) :: ierr
        integer :: m
        real :: ndot, denominator

        ierr = SN_SUCCESS
        if (.not. fun_J02_quadrature_is_valid(quadrature)) then
            ierr = SN_ERR_QUADRATURE_LAYOUT
            return
        end if
        if (size(inflow_shape) /= quadrature%n_dir) then
            ierr = SN_ERR_SOURCE_INPUT_SHAPE
            return
        end if
        if (.not. fun_J02_normal_is_unit(normal_r, normal_z)) then
            ierr = SN_ERR_SOURCE_NORMAL
            return
        end if
        if (target_flux < 0.0) then
            ierr = SN_ERR_SOURCE_TARGET_FLUX
            return
        end if
        if (any(inflow_shape < 0.0)) then
            ierr = SN_ERR_SOURCE_NEGATIVE_DATA
            return
        end if

        allocate(psi_in(quadrature%n_dir))
        psi_in = 0.0
        denominator = 0.0
        do m = 1, quadrature%n_dir
            ndot = quadrature%mu(m)*normal_r+quadrature%eta(m)*normal_z
            if (ndot < 0.0) then
                denominator = denominator+quadrature%weight(m)*quadrature%speed(m)* &
                    (-ndot)*inflow_shape(m)
            end if
        end do
        if (denominator <= tiny(denominator)) then
            ierr = SN_ERR_SOURCE_ZERO_NORMALIZATION
            deallocate(psi_in)
            return
        end if
        do m = 1, quadrature%n_dir
            ndot = quadrature%mu(m)*normal_r+quadrature%eta(m)*normal_z
            if (ndot < 0.0) then
                psi_in(m) = target_flux*inflow_shape(m)/denominator
            end if
        end do
    end subroutine sub_J02_normalize_inflow_flux

    logical function fun_J02_quadrature_is_valid(quadrature)
        type(sn_quadrature_type), intent(in) :: quadrature

        fun_J02_quadrature_is_valid = quadrature%n_dir > 0 .and. &
            allocated(quadrature%mu) .and. allocated(quadrature%eta) .and. &
            allocated(quadrature%speed) .and. allocated(quadrature%weight)
        if (.not. fun_J02_quadrature_is_valid) return
        fun_J02_quadrature_is_valid = size(quadrature%mu) == quadrature%n_dir .and. &
            size(quadrature%eta) == quadrature%n_dir .and. &
            size(quadrature%speed) == quadrature%n_dir .and. &
            size(quadrature%weight) == quadrature%n_dir .and. &
            all(quadrature%speed > 0.0) .and. all(quadrature%weight > 0.0)
    end function fun_J02_quadrature_is_valid

    logical function fun_J02_normal_is_unit(normal_r, normal_z)
        real, intent(in) :: normal_r, normal_z
        real :: norm_squared

        norm_squared = normal_r*normal_r+normal_z*normal_z
        fun_J02_normal_is_unit = abs(norm_squared-1.0) <= 100.0*epsilon(1.0)
    end function fun_J02_normal_is_unit
