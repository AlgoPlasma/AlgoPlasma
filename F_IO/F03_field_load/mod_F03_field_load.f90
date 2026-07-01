!> @file mod_F03_field_load.f90
!> @brief Module wrapper for F03 field load routines.
!>
!> Included files:
!> - ``sub_F03_field_load_1d_dat.f90``
!> - ``sub_F03_field_load_1d_bin.f90``
!> - ``sub_F03_field_load_3d_dat.f90``
!> - ``sub_F03_field_load_3d_bin.f90``
!>
!> The ``3d_grid`` load wrappers are intentionally not included, because
!> the corresponding ``sub_F04_field_output_3d_grid_*`` routines write
!> reconstructed cell-centered values only and do not preserve the
!> original grid-defined field. Therefore, a symmetric load routine that
!> recovers the original grid-defined array is not provided.
!>
!> @author Zhe LIU (2026/01/10), Yinjian ZHAO (2026/02/27).

module mod_F03_field_load

    implicit none

    contains

#    include "sub_F03_field_load_1d_dat.f90"
#    include "sub_F03_field_load_1d_bin.f90"
#    include "sub_F03_field_load_3d_dat.f90"
#    include "sub_F03_field_load_3d_bin.f90"

end module mod_F03_field_load
