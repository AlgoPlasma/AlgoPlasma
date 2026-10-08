!> Convert a prescribed removal frequency [1/s] to direction-wise opacity [1/m].
!> This conversion does not calculate reaction rates or introduce a volume source.
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
