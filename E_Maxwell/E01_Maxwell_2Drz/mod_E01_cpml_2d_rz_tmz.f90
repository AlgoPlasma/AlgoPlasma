!> @file mod_E01_cpml_2d_rz_tmz.f90
!> @brief Module wrapper for the E01 TMz CPML component group.
!> @details Includes the ``Er/Ez`` electric CPML update and ``Ha/Hphi``
!> magnetic CPML update kernels.
!> @author Zhe LIU (2026/05/22)
module mod_E01_cpml_2d_rz_tmz

contains

#include "sub_E01_cpml_2d_rz_tmz_H.f90"
#include "sub_E01_cpml_2d_rz_tmz_E.f90"

end module mod_E01_cpml_2d_rz_tmz
