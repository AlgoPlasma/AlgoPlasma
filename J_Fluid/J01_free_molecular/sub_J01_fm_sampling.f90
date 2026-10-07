!> Reusable area-weighted inlet and truncated-normal event sampling.
    subroutine sub_J01_prepare_fm_inlet(r_edge, active, face_type, theta_span, inlet_r_lo, &
        inlet_r_hi, neutral_mass, inlet_temperature, inlet_drift_z, inlet_density, &
        n_histories, inlet, history_rate, ierr)
        real, intent(in) :: r_edge(:), theta_span, inlet_r_lo, inlet_r_hi, neutral_mass
        real, intent(in) :: inlet_temperature, inlet_drift_z, inlet_density
        logical, intent(in) :: active(:, :)
        integer, intent(in) :: face_type(:, :, :), n_histories
        type(fm_inlet_2drz_type), intent(out) :: inlet
        real, intent(out) :: history_rate
        integer, intent(out) :: ierr
        integer :: nr, i
        real :: overlap_lo, overlap_hi, mean_positive_z
        real, parameter :: kb=1.380649e-23
        nr = size(active, 1)
        ierr = J01_SUCCESS
        history_rate = 0.0
        if (nr < 1 .or. size(active, 2) < 1 .or. size(r_edge) /= nr+1 .or. &
            size(face_type,1) /= 4 .or. size(face_type,2) /= nr .or. &
            size(face_type,3) /= size(active,2)) then
            ierr = J01_ERR_SHAPE
            return
        end if
        if (neutral_mass <= 0.0 .or. inlet_temperature <= 0.0 .or. n_histories <= 0 .or. &
            theta_span <= 0.0 .or. inlet_density < 0.0 .or. inlet_r_hi <= inlet_r_lo) then
            ierr = J01_ERR_CONFIGURATION
            return
        end if
        allocate(inlet%segment_area(nr), inlet%segment_lo(nr), inlet%segment_hi(nr))
        inlet%segment_area = 0.0
        inlet%segment_lo = 0.0
        inlet%segment_hi = 0.0
        ! Area-weighted inlet distribution over active open z-low segments.
        inlet%inlet_area = 0.0
        do i = 1, nr
            if (.not. active(i, 1)) cycle
            if (face_type(J01_Z_LO, i, 1) /= J01_FACE_OPEN) cycle
            overlap_lo = max(r_edge(i), inlet_r_lo)
            overlap_hi = min(r_edge(i+1), inlet_r_hi)
            if (overlap_hi <= overlap_lo) cycle
            inlet%segment_lo(i) = overlap_lo
            inlet%segment_hi(i) = overlap_hi
            inlet%segment_area(i) = 0.5*theta_span*(overlap_hi**2-overlap_lo**2)
            inlet%inlet_area = inlet%inlet_area+inlet%segment_area(i)
        end do
        if (inlet%inlet_area <= 0.0) then
            ierr = J01_ERR_CONFIGURATION
            return
        end if

        inlet%sigma_inlet = sqrt(kb*inlet_temperature/neutral_mass)
        mean_positive_z = inlet_drift_z+ &
            inlet%sigma_inlet*exp(-0.5*(inlet_drift_z/inlet%sigma_inlet)**2)/ &
            sqrt(2.0*acos(-1.0))/max(0.5*(1.0+erf(inlet_drift_z/ &
            (inlet%sigma_inlet*sqrt(2.0)))), tiny(1.0))
        ! mean_positive_z is E[vz | vz>0] for the truncated Gaussian below.
        ! This event-distribution convention differs from reservoir Maxwell
        ! flux sampling, which weights the incoming velocity PDF by vz.
        history_rate = inlet_density*inlet%inlet_area*mean_positive_z/real(n_histories)

    end subroutine sub_J01_prepare_fm_inlet

! Requires a successfully prepared inlet. Each draw represents an incoming event.
    subroutine sub_J01_sample_fm_inlet(inlet, z_start, inlet_drift_z, r, z, ur, uz)
        type(fm_inlet_2drz_type), intent(in) :: inlet
        real, intent(in) :: z_start, inlet_drift_z
        real, intent(out) :: r, z, ur, uz
        integer :: nr, i, k
        real :: u, target, cumulative
        nr = size(inlet%segment_area)
        call random_number(u)
        target = u*inlet%inlet_area
        cumulative = 0.0
        i = nr
        do k = 1, nr
            cumulative = cumulative+inlet%segment_area(k)
            if (target <= cumulative .and. inlet%segment_area(k) > 0.0) then
                i = k
                exit
            end if
        end do
        call random_number(u)
        ! Uniform annular area means uniform r^2, not uniform r.
        r = sqrt(inlet%segment_lo(i)**2+u*(inlet%segment_hi(i)**2-inlet%segment_lo(i)**2))
        z = z_start
        ur = inlet%sigma_inlet*fun_J01_standard_normal()
        do
            uz = inlet_drift_z+inlet%sigma_inlet*fun_J01_standard_normal()
            if (uz > 0.0) exit
        end do

    end subroutine sub_J01_sample_fm_inlet

    real function fun_J01_standard_normal()
        real :: u1, u2
        call random_number(u1)
        call random_number(u2)
        u1 = max(u1, tiny(1.0))
        fun_J01_standard_normal = sqrt(-2.0*log(u1))*cos(2.0*acos(-1.0)*u2)
    end function fun_J01_standard_normal

    subroutine sub_J01_set_random_seed(seed_value)
        integer, intent(in) :: seed_value
        integer :: n, j
        integer, allocatable :: seed(:)
        call random_seed(size = n)
        allocate(seed(n))
        do j = 1, n
            seed(j) = modulo(seed_value+104729*j, 2147483646)+1
        end do
        call random_seed(put = seed)
    end subroutine sub_J01_set_random_seed
