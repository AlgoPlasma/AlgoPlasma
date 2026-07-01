!> @file mod_F04_field_output.f90
!> @brief Module wrapper for F04 field output subroutines.
!>
!> Included files:
!> - ``sub_F04_field_output_1d_dat.f90``
!> - ``sub_F04_field_output_1d_bin.f90``
!> - ``sub_F04_field_output_3d_dat.f90``
!> - ``sub_F04_field_output_3d_bin.f90``
!> - ``sub_F04_field_output_3d_grid_dat.f90``
!> - ``sub_F04_field_output_3d_grid_bin.f90``
!>
!> @author Zhe LIU (2025/12/29), Yinjian ZHAO (2026/02/26).

module mod_F04_field_output

    implicit none

    contains

#    include "sub_F04_field_output_1d_dat.f90"
#    include "sub_F04_field_output_1d_bin.f90"
#    include "sub_F04_field_output_3d_dat.f90"
#    include "sub_F04_field_output_3d_bin.f90"
#    include "sub_F04_field_output_3d_grid_dat.f90"
#    include "sub_F04_field_output_3d_grid_bin.f90"

end module mod_F04_field_output
