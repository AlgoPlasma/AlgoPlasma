!> @file   mod_I02_load_init_particles_bin.f90
!> @author Zhongping ZHAO (2026/4/22)
!> @brief  Module wrapper for loading initial particle binary files.
!>
!> @details
!> Includes ``sub_I02_load_init_particles_bin.f90`` so MPI initialization code
!> can read offline-generated particle files and assign particles to local
!> subdomains through ``mod_I02_load_init_particles_bin``.

module mod_I02_load_init_particles_bin

    contains

#   include "sub_I02_load_init_particles_bin.f90"

end module mod_I02_load_init_particles_bin
