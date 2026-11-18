!> Shared validation of caller-supplied inlet distributions.
!> Mesh, geometry and quadrature structure are initialization contracts.

    logical function fun_J02_normal_is_unit(normal_r, normal_z)
        real, intent(in) :: normal_r, normal_z
        real :: norm_squared

        norm_squared = normal_r*normal_r+normal_z*normal_z
        fun_J02_normal_is_unit = abs(norm_squared-1.0) <= 100.0*epsilon(1.0)
    end function fun_J02_normal_is_unit

    ! Private shared contract for phase-density shapes and crossing distributions.
    integer function fun_J02_validate_inflow_input(quadrature, normal_r, normal_z, inflow_shape, &
        target_flux) result(ierr)
        type(sn_quadrature_type), intent(in) :: quadrature
        real, intent(in) :: normal_r, normal_z, inflow_shape(:)
        real, intent(in), optional :: target_flux

        ierr = SN_ERR_SOURCE_INPUT_SHAPE
        if (size(inflow_shape) /= quadrature%n_dir) return
        ierr = SN_ERR_SOURCE_NORMAL
        if (.not.fun_J02_normal_is_unit(normal_r, normal_z)) return
        if (present(target_flux)) then
            ierr = SN_ERR_SOURCE_TARGET_FLUX
            if (target_flux < 0.0) return
        end if
        ierr = SN_ERR_SOURCE_NEGATIVE_DATA
        if (any(inflow_shape < 0.0)) return
        ierr = SN_SUCCESS
    end function fun_J02_validate_inflow_input
