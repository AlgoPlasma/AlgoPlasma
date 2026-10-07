!> Normalize any nonnegative inlet shape to a prescribed incoming number flux.
!> Model-specific shapes live in sub_J02_sn_inflow.f90; removal lives in sub_J02_sn_loss.f90.
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
        use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
        type(sn_quadrature_type), intent(in) :: quadrature

        fun_J02_quadrature_is_valid = quadrature%n_dir > 0 .and. &
            allocated(quadrature%mu) .and. allocated(quadrature%eta) .and. &
            allocated(quadrature%speed) .and. allocated(quadrature%weight)
        if (.not. fun_J02_quadrature_is_valid) return
        fun_J02_quadrature_is_valid = size(quadrature%mu) == quadrature%n_dir .and. &
            size(quadrature%eta) == quadrature%n_dir .and. &
            size(quadrature%speed) == quadrature%n_dir .and. &
            size(quadrature%weight) == quadrature%n_dir
        if (.not.fun_J02_quadrature_is_valid) return
        ! A nonfinite direction cannot be assigned to a spatial sweep quadrant.
        fun_J02_quadrature_is_valid = all(ieee_is_finite(quadrature%mu)) .and. &
            all(ieee_is_finite(quadrature%eta)) .and. all(ieee_is_finite(quadrature%speed)) .and. &
            all(ieee_is_finite(quadrature%weight))
        if (.not.fun_J02_quadrature_is_valid) return
        fun_J02_quadrature_is_valid = all(quadrature%speed > 0.0) .and. all(quadrature%weight > 0.0)
    end function fun_J02_quadrature_is_valid

    logical function fun_J02_normal_is_unit(normal_r, normal_z)
        real, intent(in) :: normal_r, normal_z
        real :: norm_squared

        norm_squared = normal_r*normal_r+normal_z*normal_z
        fun_J02_normal_is_unit = abs(norm_squared-1.0) <= 100.0*epsilon(1.0)
    end function fun_J02_normal_is_unit
