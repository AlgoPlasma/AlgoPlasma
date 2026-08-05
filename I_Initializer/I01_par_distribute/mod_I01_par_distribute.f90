!> @file   mod_I01_par_distribute.f90
!> @author Yinjian ZHAO (2025/11/03)
!> @brief  Module wrapper for particle distribution initialization.
!>
!> @details
!> Includes ``sub_I01_par_distribute_equilibrium.f90`` so callers can initialize
!> uniform in-cell particle positions and Maxwellian velocities through
!> ``mod_I01_par_distribute``.

module mod_I01_par_distribute

    contains

#   include "sub_I01_par_distribute_equilibrium.f90"

end module mod_I01_par_distribute
