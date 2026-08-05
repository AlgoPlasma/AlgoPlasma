!> @file mod_F02_par_output.f90
!> @brief Module wrapper for F02 particle output routines.
!>
!> Included files:
!> - ``sub_F02_par_output.f90``
!> - ``sub_F02_par_output_dat.f90``
!> - ``sub_F02_par_output_bin.f90``
!> - ``sub_F02_par_output_h5.f90``
!>
!> @author Yinjian ZHAO (2025/04/16), Zhe LIU (2025/11/04).

module mod_F02_par_output

    implicit none

    contains

#    include "sub_F02_par_output.f90"
#    include "sub_F02_par_output_dat.f90"
#    include "sub_F02_par_output_bin.f90"

#if (USE_HDF5==1)
#    include "sub_F02_par_output_h5.f90"
#endif

end module mod_F02_par_output
