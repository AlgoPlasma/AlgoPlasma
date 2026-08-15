module pulse_common
    use, intrinsic :: ieee_arithmetic
    implicit none
contains

    subroutine parse_int_arg(idx, default_value, out_value)
        implicit none
        integer, intent(in) :: idx, default_value
        integer, intent(out) :: out_value
        character(len=64) :: arg
        integer :: ios

        out_value = default_value
        call get_command_argument(idx, arg)
        if (len_trim(arg) == 0) return
        read(arg, *, iostat=ios) out_value
        if (ios /= 0) out_value = default_value
    end subroutine parse_int_arg


    subroutine parse_real_arg(idx, default_value, out_value)
        implicit none
        integer, intent(in) :: idx
        real, intent(in) :: default_value
        real, intent(out) :: out_value
        character(len=64) :: arg
        integer :: ios

        out_value = default_value
        call get_command_argument(idx, arg)
        if (len_trim(arg) == 0) return
        read(arg, *, iostat=ios) out_value
        if (ios /= 0) out_value = default_value
    end subroutine parse_real_arg


    real function safe_ratio(num, den)
        implicit none
        real, intent(in) :: num, den
        real, parameter :: tiny_den = 1.0e-30

        safe_ratio = num / max(abs(den), tiny_den)
    end function safe_ratio


    real function smooth_pulse_envelope(n, npulse, amp)
        implicit none
        integer, intent(in) :: n, npulse
        real, intent(in) :: amp
        real :: s

        if (npulse <= 0 .or. n <= 0 .or. n > npulse) then
            smooth_pulse_envelope = 0.0
            return
        end if

        s = real(n) / real(npulse + 1)
        smooth_pulse_envelope = amp * (sin(acos(-1.0) * s)**2)
    end function smooth_pulse_envelope


    subroutine update_growth_counter(prev_value, cur_value, rel_tol, counter)
        implicit none
        real, intent(in) :: prev_value, cur_value, rel_tol
        integer, intent(inout) :: counter

        if (cur_value > prev_value*(1.0 + rel_tol)) then
            counter = counter + 1
        else
            counter = 0
        end if
    end subroutine update_growth_counter


    real function compute_post_pulse_growth_rate(energy_ref, energy_final, t_ref, t_final)
        implicit none
        real, intent(in) :: energy_ref, energy_final, t_ref, t_final
        real, parameter :: tiny_val = 1.0e-30
        real :: dt_eff

        dt_eff = max(t_final - t_ref, tiny_val)
        compute_post_pulse_growth_rate = log(max(energy_final, tiny_val) / max(energy_ref, tiny_val)) / dt_eff
    end function compute_post_pulse_growth_rate


    subroutine classify_pulse_stability(has_naninf, final_energy_ratio, post_growth_rate, &
        post_energy_growth_counter, post_axis_growth_counter, result)
        implicit none
        logical, intent(in) :: has_naninf
        real, intent(in) :: final_energy_ratio, post_growth_rate
        integer, intent(in) :: post_energy_growth_counter, post_axis_growth_counter
        character(len=*), intent(out) :: result

        if (has_naninf .or. (.not. ieee_is_finite(final_energy_ratio)) .or. (.not. ieee_is_finite(post_growth_rate))) then
            result = 'unstable'
        else if (final_energy_ratio > 10.0 .or. post_growth_rate > 3.0e-2 .or. &
            post_energy_growth_counter >= 8 .or. post_axis_growth_counter >= 8) then
            result = 'unstable'
        else if (final_energy_ratio > 1.5 .or. final_energy_ratio < 0.5 .or. &
            abs(post_growth_rate) > 3.0e-3 .or. post_energy_growth_counter >= 3 .or. &
            post_axis_growth_counter >= 3) then
            result = 'marginal'
        else
            result = 'stable'
        end if
    end subroutine classify_pulse_stability

end module pulse_common
