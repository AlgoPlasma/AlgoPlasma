!> @file mod_E03_cpml_3d_cartesian.f90
!> @brief CPML updates for 3D Cartesian Maxwell fields.
!> @details This module provides electric and magnetic CPML updates on
!> Yee-staggered ``x-y-z`` grids.
!> @author Zhe LIU (2026/04/09)

module mod_E03_cpml_3d_cartesian

contains

#include "sub_E03_cpml_3d_cartesian_E.f90"
#include "sub_E03_cpml_3d_cartesian_H.f90"

end module mod_E03_cpml_3d_cartesian
