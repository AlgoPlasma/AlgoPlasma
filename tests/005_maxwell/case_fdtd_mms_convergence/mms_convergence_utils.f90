module mms_convergence_utils

implicit none

contains

real function observed_order(eh,eh2)
    implicit none
    real, intent(in) :: eh, eh2
    if (eh > 0.0 .and. eh2 > 0.0) then
        observed_order = log(eh/eh2)/log(2.0)
    else
        observed_order = 0.0
    end if
end function observed_order

end module mms_convergence_utils
