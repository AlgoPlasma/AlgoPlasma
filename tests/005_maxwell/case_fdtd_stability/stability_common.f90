module stability_common
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


    real function safe_ratio(num, den)
        implicit none
        real, intent(in) :: num, den
        real, parameter :: tiny_den = 1.0e-30

        safe_ratio = num / max(abs(den), tiny_den)
    end function safe_ratio


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


    subroutine classify_stability(has_naninf, final_energy_ratio, max_e_ratio, max_h_ratio, &
        energy_growth_counter, axis_growth_counter, result)
        implicit none
        logical, intent(in) :: has_naninf
        real, intent(in) :: final_energy_ratio, max_e_ratio, max_h_ratio
        integer, intent(in) :: energy_growth_counter, axis_growth_counter
        character(len=*), intent(out) :: result

        if (has_naninf .or. (.not. ieee_is_finite(final_energy_ratio)) .or. final_energy_ratio > 20.0 .or. &
            max_e_ratio > 20.0 .or. max_h_ratio > 20.0) then
            result = 'unstable'
        else if (energy_growth_counter >= 5 .or. axis_growth_counter >= 5 .or. &
            final_energy_ratio > 1.2 .or. final_energy_ratio < 0.8 .or. &
            max_e_ratio > 2.0 .or. max_h_ratio > 2.0) then
            result = 'marginal'
        else
            result = 'stable'
        end if
    end subroutine classify_stability

end module stability_common

