!> @file mod_F01_par_load.f90
!> @brief Module wrapper for F01 particle load routines.
!>
!> Included files:
!> - ``sub_F01_par_load.f90``
!> - ``sub_F01_par_load_dat.f90``
!> - ``sub_F01_par_load_bin.f90``
!> - ``sub_F01_par_load_count.f90``
!> - ``sub_F01_par_load_h5.f90``
!>
!> @author Yinjian ZHAO (2025/04/16), Zhe LIU (2025/11/04).

module mod_F01_par_load

    implicit none

    contains

#    include "sub_F01_par_load.f90"
#    include "sub_F01_par_load_dat.f90"
#    include "sub_F01_par_load_bin.f90"
#    include "sub_F01_par_load_count.f90"

#if (USE_HDF5==1)
#    include "sub_F01_par_load_h5.f90"
#endif

end module mod_F01_par_load
