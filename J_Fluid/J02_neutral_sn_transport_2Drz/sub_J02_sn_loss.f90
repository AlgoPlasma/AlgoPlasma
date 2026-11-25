!> Convert a prescribed removal frequency [1/s] to direction-wise opacity [1/m].
!> This conversion does not calculate reaction rates or introduce a volume source.
    subroutine sub_J02_build_sigma_from_frequency(quadrature, frequency, &
        sigma_t, ierr)
        type(sn_quadrature_type), intent(in) :: quadrature
        real, intent(in) :: frequency(:, :)
        real, allocatable, intent(out) :: sigma_t(:, :, :)
        integer, intent(out) :: ierr
        integer :: m

        ierr = SN_SUCCESS
        if (size(frequency, 1) < 1 .or. size(frequency, 2) < 1) then
            ierr = SN_ERR_SIGMA_FREQUENCY_SHAPE
            return
        end if
        if (any(frequency < 0.0)) then
            ierr = SN_ERR_SIGMA_NEGATIVE_FREQUENCY
            return
        end if
        allocate(sigma_t(size(frequency, 1), &
            size(frequency, 2), quadrature%n_dir))
        do m = 1, quadrature%n_dir
            sigma_t(:, :, m) = frequency/quadrature%speed(m)
        end do
    end subroutine sub_J02_build_sigma_from_frequency
