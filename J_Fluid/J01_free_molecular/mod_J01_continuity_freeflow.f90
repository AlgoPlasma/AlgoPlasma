!> @file   mod_J01_continuity_freeflow.f90
!> @author Yinjian ZHAO (2025/12/02)
!> @brief  Legacy continuity update and prescribed-velocity face-flux utilities.
!>
!> @details
!> Retains the original three-dimensional continuity API and cylindrical
!> prescribed-velocity utilities. Particle preprocessing is provided separately
!> by mod_J01_neutral_free_molecular_2Drz.

module mod_J01_continuity_freeflow
    implicit none

!> @cond J01_INTERNAL_CONSTANTS
    integer, parameter :: J01_R_LO = 1
    integer, parameter :: J01_R_HI = 2
    integer, parameter :: J01_Z_LO = 3
    integer, parameter :: J01_Z_HI = 4
    integer, parameter :: J01_N_FACES = 4
    integer, parameter :: J01_FACE_INTERIOR = 0
    integer, parameter :: J01_FACE_OPEN = 1
    integer, parameter :: J01_FACE_WALL = 2
    integer, parameter :: J01_SUCCESS = 0
    integer, parameter :: J01_ERR_SHAPE = 101
    integer, parameter :: J01_ERR_NEGATIVE_INPUT = 102
    integer, parameter :: J01_ERR_TIMESTEP = 103
    integer, parameter :: J01_ERR_ITERATION = 104
    integer, parameter :: J01_ERR_CONFIGURATION = 105
    integer, parameter :: J01_ERR_PARTICLE_TRACKING = 106
!> @endcond

contains

#   include "sub_J01_continuity_freeflow.f90"
#   include "sub_J01_continuity_freeflow_2Drz.f90"

end module mod_J01_continuity_freeflow
