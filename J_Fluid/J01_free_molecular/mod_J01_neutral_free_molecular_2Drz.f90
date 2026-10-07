!> Free-molecular particle preprocessing; no continuity update is performed here.
!> Reduced r-z straight-path model with vr and vz only, not axisymmetric 2D3V.
!> Cylindrical area/volume normalization does not supply azimuthal dynamics.
module mod_J01_neutral_free_molecular_2Drz
    implicit none

    integer, parameter :: J01_R_LO=1, J01_R_HI=2, J01_Z_LO=3, J01_Z_HI=4, J01_N_FACES=4
    integer, parameter :: J01_FACE_INTERIOR=0, J01_FACE_OPEN=1, J01_FACE_WALL=2
    integer, parameter :: J01_SUCCESS=0, J01_ERR_SHAPE=101
    integer, parameter :: J01_ERR_CONFIGURATION=105, J01_ERR_PARTICLE_TRACKING=106

! Prepared inlet: area-weighted segments and thermal speed for repeated sampling.
    type :: fm_inlet_2drz_type
        real, allocatable :: segment_area(:), segment_lo(:), segment_hi(:)
        real :: inlet_area=0.0, sigma_inlet=0.0
    end type fm_inlet_2drz_type

! Raw, unnormalised estimators. A trajectory adds residence time and signed crossings.
    type :: fm_tally_2drz_type
        real, allocatable :: residence(:, :), moment_r(:, :), moment_z(:, :)
        real, allocatable :: count_r(:, :), count_z(:, :), boundary_count(:, :, :)
    end type fm_tally_2drz_type

contains
#   include "sub_J01_fm_sampling.f90"
#   include "sub_J01_fm_reflection.f90"
#   include "sub_J01_fm_trajectory.f90"
#   include "sub_J01_fm_statistics.f90"
#   include "sub_J01_free_molecular_mc_2Drz.f90"
end module mod_J01_neutral_free_molecular_2Drz
