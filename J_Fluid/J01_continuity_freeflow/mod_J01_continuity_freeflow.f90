!> @file   mod_J01_continuity_freeflow.f90
!> @author Yinjian ZHAO (2025/12/02)
!> @brief  Module wrapper for the free-flow continuity update routine.
!>
!> @details
!> Includes ``sub_J01_continuity_freeflow.f90`` so callers can advance the
!> density field through ``mod_J01_continuity_freeflow``. The current
!> implementation uses the explicit array bounds and update region declared in
!> ``sub_J01_continuity_freeflow.f90`` rather than the simpler
!> ``n(il:iu)`` active-cell convention.

module mod_J01_continuity_freeflow

    contains

#   include "sub_J01_continuity_freeflow.f90"

end module mod_J01_continuity_freeflow
