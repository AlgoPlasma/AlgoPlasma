!> @file mod_J02_neutral_sn_transport_2Drz.f90
!> @brief Collects the first-stage neutral SN P1-DG transport routines.
!> @details The module owns the shared mesh, geometry, and quadrature types and
!> includes separately testable implementation files for geometry, quadrature,
!> sources, local DG operators, sweeps, and reconstruction.
module mod_J02_neutral_sn_transport_2Drz
    implicit none

    integer, parameter :: SN_R_LO = 1
    integer, parameter :: SN_R_HI = 2
    integer, parameter :: SN_Z_LO = 3
    integer, parameter :: SN_Z_HI = 4
    integer, parameter :: SN_N_FACES = 4
    integer, parameter :: SN_FACE_INTERIOR = 0
    integer, parameter :: SN_FACE_OPEN = 1
    integer, parameter :: SN_FACE_WALL = 2

! Globally unique status codes returned by the J02 public interfaces.
    integer, parameter :: SN_SUCCESS = 0
    integer, parameter :: SN_ERR_MESH_EDGE_COUNT = 101
    integer, parameter :: SN_ERR_MESH_ACTIVE_SHAPE = 102
    integer, parameter :: SN_ERR_MESH_NEGATIVE_RADIUS = 103
    integer, parameter :: SN_ERR_MESH_RADIAL_ORDER = 104
    integer, parameter :: SN_ERR_MESH_AXIAL_ORDER = 105
    integer, parameter :: SN_ERR_GEOMETRY_MESH = 201
    integer, parameter :: SN_ERR_GEOMETRY_THETA_SPAN = 202
    integer, parameter :: SN_ERR_BOUNDARY_SHAPE = 203
    integer, parameter :: SN_ERR_ANGLE_COUNT = 301
    integer, parameter :: SN_ERR_ANGLE_SCHEME = 302
    integer, parameter :: SN_ERR_SPEED_COUNT = 311
    integer, parameter :: SN_ERR_SPEED_MAX = 312
    integer, parameter :: SN_ERR_QUADRATURE_LAYOUT = 321
    integer, parameter :: SN_ERR_SIGMA_FREQUENCY_SHAPE = 322
    integer, parameter :: SN_ERR_SIGMA_NEGATIVE_FREQUENCY = 323
    integer, parameter :: SN_ERR_SOURCE_TEMPERATURE = 401
    integer, parameter :: SN_ERR_SOURCE_MASS = 402
    integer, parameter :: SN_ERR_SOURCE_INPUT_SHAPE = 403
    integer, parameter :: SN_ERR_SOURCE_NORMAL = 404
    integer, parameter :: SN_ERR_SOURCE_NEGATIVE_DATA = 405
    integer, parameter :: SN_ERR_SOURCE_ZERO_DATA = 406
    integer, parameter :: SN_ERR_SOURCE_TARGET_FLUX = 407
    integer, parameter :: SN_ERR_SOURCE_ZERO_NORMALIZATION = 408
    integer, parameter :: SN_ERR_SOURCE_OUTGOING_DATA = 409
    integer, parameter :: SN_ERR_LOCAL_SINGULAR = 501
    integer, parameter :: SN_ERR_LOCAL_POSITIVITY = 502
    integer, parameter :: SN_ERR_SWEEP_SIGMA_SHAPE = 601
    integer, parameter :: SN_ERR_SWEEP_BOUNDARY_SHAPE = 602
    integer, parameter :: SN_ERR_SWEEP_GEOMETRY_SHAPE = 603
    integer, parameter :: SN_ERR_SWEEP_DIRECTION = 604
    integer, parameter :: SN_ERR_SWEEP_DIRECTION_SIGMA_SHAPE = 605
    integer, parameter :: SN_ERR_SWEEP_DIRECTION_BOUNDARY_SHAPE = 606
    integer, parameter :: SN_ERR_SWEEP_DIRECTION_PSI_SHAPE = 607
    integer, parameter :: SN_ERR_SWEEP_AXIS_DIRECTION = 608
    integer, parameter :: SN_ERR_SWEEP_LOCAL_SOLVE = 609
    integer, parameter :: SN_ERR_SWEEP_NEGATIVE_SIGMA = 610
    integer, parameter :: SN_ERR_SWEEP_WALL_UNSUPPORTED = 611
    integer, parameter :: SN_ERR_SWEEP_FACE_TOPOLOGY = 612
    integer, parameter :: SN_ERR_REFLECTION_INPUT = 613
    integer, parameter :: SN_ERR_SOURCE_ITERATION_OPTIONS = 614
    integer, parameter :: SN_ERR_SOURCE_ITERATION_NOT_CONVERGED = 615
    integer, parameter :: SN_ERR_PARTIAL_INLET = 616
    integer, parameter :: SN_ERR_RECONSTRUCTION_PSI_SHAPE = 701
    integer, parameter :: SN_ERR_RECONSTRUCTION_BOUNDARY_SHAPE = 702

    type :: sn_mesh_2drz_type
        integer :: nr = 0
        integer :: nz = 0
        real, allocatable :: r_edge(:)
        real, allocatable :: z_edge(:)
        logical, allocatable :: active(:, :)
    end type sn_mesh_2drz_type

    type :: sn_geometry_2drz_type
        real :: theta_span = 0.0
        real, allocatable :: rc(:)
        real, allocatable :: hr(:)
        real, allocatable :: hz(:)
        real, allocatable :: xi_bar(:)
        real, allocatable :: volume(:, :)
        real, allocatable :: area_r_lo(:, :)
        real, allocatable :: area_r_hi(:, :)
        real, allocatable :: area_z_lo(:, :)
        real, allocatable :: area_z_hi(:, :)
    end type sn_geometry_2drz_type

    type :: sn_quadrature_type
        integer :: n_angles = 0
        integer :: n_speeds = 0
        integer :: n_dir = 0
        real :: speed_max = 0.0
        real, allocatable :: mu(:)
        real, allocatable :: eta(:)
        real, allocatable :: speed(:)
        real, allocatable :: weight(:)
    end type sn_quadrature_type

    type :: sn_boundary_2drz_type
        integer, allocatable :: face_r_lo(:, :)
        integer, allocatable :: face_r_hi(:, :)
        integer, allocatable :: face_z_lo(:, :)
        integer, allocatable :: face_z_hi(:, :)
    end type sn_boundary_2drz_type

contains

#   include "sub_J02_sn_error.f90"
#   include "sub_J02_sn_geometry.f90"
#   include "sub_J02_sn_quadrature.f90"
#   include "sub_J02_sn_source.f90"
#   include "sub_J02_sn_dg_operator.f90"
#   include "sub_J02_sn_sweep.f90"
#   include "sub_J02_sn_reflection.f90"
#   include "sub_J02_sn_reconstruction.f90"

end module mod_J02_neutral_sn_transport_2Drz
