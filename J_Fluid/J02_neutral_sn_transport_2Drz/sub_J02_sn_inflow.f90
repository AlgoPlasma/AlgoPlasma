!> Inlet models: reservoir phase density and crossing-event distributions.
!>
!> A reservoir shape is a velocity-space phase density sampled at each
!> quadrature node.  In contrast, an MC crossing sample is a probability mass
!> per discrete incoming bin.  The latter is divided by the discrete crossing
!> measure w_m v_m |Omega_m.n| before it can be used as a phase-density shape.

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

    subroutine sub_J02_build_mc_crossing_bins_inflow_shape(quadrature, normal_r, &
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
