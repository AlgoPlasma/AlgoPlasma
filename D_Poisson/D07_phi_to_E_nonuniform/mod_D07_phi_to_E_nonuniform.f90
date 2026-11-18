!> @file mod_D07_phi_to_E_nonuniform.f90
!> @brief Nonuniform cylindrical cell-centered electric-field reconstruction.
!> @details Compile this wrapper with preprocessing; do not compile the included subroutine separately.
module mod_D07_phi_to_E_nonuniform
    implicit none
    private
    public :: sub_D07_phi_to_E_nonuniform
    contains
#   include "sub_D07_phi_to_E_nonuniform.f90"
end module mod_D07_phi_to_E_nonuniform
