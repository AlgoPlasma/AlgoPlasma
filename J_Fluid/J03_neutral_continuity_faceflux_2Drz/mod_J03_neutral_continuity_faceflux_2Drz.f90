!> @file mod_J03_neutral_continuity_faceflux_2Drz.f90
!> @brief Transient cylindrical continuity with prescribed face velocities; optional steady iteration.
!> Evolves scalar density, not a velocity distribution; no 2D3V claim applies.
module mod_J03_neutral_continuity_faceflux_2Drz
    implicit none

    integer, parameter :: J03_R_LO = 1
    integer, parameter :: J03_R_HI = 2
    integer, parameter :: J03_Z_LO = 3
    integer, parameter :: J03_Z_HI = 4
    integer, parameter :: J03_N_FACES = 4
    integer, parameter :: J03_FACE_INTERIOR = 0
    integer, parameter :: J03_FACE_OPEN = 1
    integer, parameter :: J03_FACE_WALL = 2
    integer, parameter :: J03_SUCCESS = 0
    integer, parameter :: J03_ERR_SHAPE = 101
    integer, parameter :: J03_ERR_GEOMETRY = 102
    integer, parameter :: J03_ERR_NEGATIVE_INPUT = 103
    integer, parameter :: J03_ERR_FACE_TYPE = 104
    integer, parameter :: J03_ERR_OPTIONS = 105
    integer, parameter :: J03_ERR_NOT_CONVERGED = 106

    type :: neutral_transport_closure_2drz_type
        integer :: nr = 0
        integer :: nz = 0
        logical, allocatable :: active(:, :)
        integer, allocatable :: face_type(:, :, :)
        real, allocatable :: volume(:, :), face_area(:, :, :)
        real, allocatable :: density_ref(:, :)
        real, allocatable :: flux_r_ref(:, :), flux_z_ref(:, :)
        real, allocatable :: boundary_inflow_flux(:, :, :)
        real, allocatable :: boundary_outflow_flux_ref(:, :, :)
        real, allocatable :: velocity_r_face(:, :), velocity_z_face(:, :)
        real, allocatable :: boundary_outflow_velocity(:, :, :)
        real, allocatable :: loss_frequency(:, :)
    end type neutral_transport_closure_2drz_type

contains

#   include "sub_J03_error.f90"
#   include "sub_J03_transport_closure.f90"
#   include "sub_J03_continuity_solver.f90"

end module mod_J03_neutral_continuity_faceflux_2Drz
