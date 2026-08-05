!> @file mod_E01_cpml_2d_rz_tez.f90
!> @brief Module wrapper for the E01 TEz CPML component group.
!> @details Includes the ``Ephi`` electric CPML update and ``Hr/Hz`` magnetic
!> CPML update kernels.
!> @author Zhe LIU (2026/05/22)
module mod_E01_cpml_2d_rz_tez

contains

#include "sub_E01_cpml_2d_rz_tez_H.f90"
#include "sub_E01_cpml_2d_rz_tez_E.f90"

end module mod_E01_cpml_2d_rz_tez
