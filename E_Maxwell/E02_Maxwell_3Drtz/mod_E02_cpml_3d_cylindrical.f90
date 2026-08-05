!> @file mod_E02_cpml_3d_cylindrical.f90
!> @brief CPML updates for 3D cylindrical Maxwell fields.
!> @details This module provides electric and magnetic CPML updates on
!> Yee-staggered ``r-phi-z`` grids.
!> @author Zhe LIU (2026/04/26)

module mod_E02_cpml_3d_cylindrical

contains

#include "sub_E02_cpml_3d_cylindrical_E.f90"
#include "sub_E02_cpml_3d_cylindrical_H.f90"

end module mod_E02_cpml_3d_cylindrical
