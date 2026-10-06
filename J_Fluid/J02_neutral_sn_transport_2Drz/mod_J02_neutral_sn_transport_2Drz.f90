!> @file mod_J02_neutral_sn_transport_2Drz.f90
!> @brief Collects the first-stage neutral SN P1-DG transport routines.
!> @details The module owns the shared mesh, geometry, and quadrature types and
!> includes separately testable implementation files for geometry, quadrature,
!> sources, local DG operators, sweeps, and reconstruction.
!> Reduced two-velocity r-z transport, not full axisymmetric 2D3V kinetics.
!> Speed and one in-plane angle supply vr/vz; v_theta is not represented.
module mod_J02_neutral_sn_transport_2Drz
    implicit none
    private :: sub_J02_sweep_velocity, sub_J02_sweep_batch, sn_sweep_halo_type
#ifdef J02_USE_MPI
    private :: sub_J02_mpi_sweep, sub_J02_connect_partition_faces, sub_J02_sync_status
    private :: sub_J02_partition_check, sub_J02_partition_real_reduce, sub_J02_partition_any
    private :: sub_J02_check_mpi, sub_J02_partition_quadrature
    private :: sub_J02_partition_iteration_options, sub_J02_reconstruct_partition_fluxes
#endif

    integer, parameter :: SN_R_LO = 1
    integer, parameter :: SN_R_HI = 2
    integer, parameter :: SN_Z_LO = 3
    integer, parameter :: SN_Z_HI = 4
    integer, parameter :: SN_N_FACES = 4
    integer, parameter :: SN_FACE_INTERIOR = 0
    integer, parameter :: SN_FACE_OPEN = 1
    integer, parameter :: SN_FACE_WALL = 2
    integer, parameter :: SN_FACE_REMOTE = 3

! Status codes unique within the J02 public interfaces.
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
    integer, parameter :: SN_ERR_SWEEP_AXIS_DIRECTION = 608
    integer, parameter :: SN_ERR_SWEEP_LOCAL_SOLVE = 609
    integer, parameter :: SN_ERR_SWEEP_NEGATIVE_SIGMA = 610
    integer, parameter :: SN_ERR_SWEEP_FACE_TOPOLOGY = 612
    integer, parameter :: SN_ERR_REFLECTION_INPUT = 613
    integer, parameter :: SN_ERR_SOURCE_ITERATION_OPTIONS = 614
    integer, parameter :: SN_ERR_SOURCE_ITERATION_NOT_CONVERGED = 615
    integer, parameter :: SN_ERR_WALL_NORMALIZATION = 617
    integer, parameter :: SN_ERR_PARTIAL_INLET = 616
    integer, parameter :: SN_ERR_RECONSTRUCTION_PSI_SHAPE = 701
    integer, parameter :: SN_ERR_RECONSTRUCTION_BOUNDARY_SHAPE = 702

    integer, parameter :: SN_ERR_MPI_DISABLED = 801
    integer, parameter :: SN_ERR_MPI_LAYOUT = 802
    integer, parameter :: SN_ERR_MPI_INPUT = 803
    integer, parameter :: SN_ERR_MPI_THREAD = 804

    ! Borrowed nonperiodic 2D Cartesian communicator. MPI lifetime belongs to the caller.
    ! first/count describe owned cells (global one-based indices); public fields have no ghosts.
    type :: sn_partition_type
        integer :: comm = -1, rank = -1, n_ranks = 0, real_type = 0
        integer :: dims(2) = 0, coords(2) = 0, global_shape(2) = 0
        integer :: first(2) = 0, count(2) = 0, neighbor(4) = -1
    end type sn_partition_type

    ! The two upstream coefficient planes for a group of velocity nodes.
    type :: sn_sweep_halo_type
        real, allocatable :: r(:,:,:), z(:,:,:)
    end type sn_sweep_halo_type

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

    ! Reference fields and solver diagnostics belong to one completed solve.
    type :: sn_transport_options_type
        real :: diffuse_fraction = 0.0
        real :: tolerance = 1.0e-6
        integer :: max_iterations = 200
        integer :: progress_interval = 0
    end type sn_transport_options_type

    type :: sn_transport_result_type
        logical :: converged = .false.
        integer :: iterations = 0
        integer :: failed_direction = 0, failed_i = 0, failed_k = 0
        real :: relative_change = 0.0
        real, allocatable :: psi(:,:,:,:)
        real, allocatable :: density(:,:), velocity_r(:,:), velocity_z(:,:)
        real, allocatable :: flux_r(:,:), flux_z(:,:)
        real, allocatable :: inflow_flux(:,:,:), outflow_flux(:,:,:)
        ! Coordinate-signed flux density on REMOTE faces only; local ownership on each rank.
        real, allocatable :: partition_flux(:,:,:)
    end type sn_transport_result_type

contains

#   include "sub_J02_sn_error.f90"
#ifdef J02_USE_MPI
#   include "sub_J02_sn_partition.f90"
#endif
#   include "sub_J02_sn_geometry.f90"
#   include "sub_J02_sn_quadrature.f90"
#   include "sub_J02_sn_inflow.f90"
#   include "sub_J02_sn_source.f90"
#   include "sub_J02_sn_loss.f90"
#   include "sub_J02_sn_boundary.f90"
#   include "sub_J02_sn_wall.f90"
#   include "sub_J02_sn_dg_operator.f90"
#   include "sub_J02_sn_sweep.f90"
#ifdef J02_USE_MPI
#   include "sub_J02_sn_mpi_sweep.f90"
#endif
#   include "sub_J02_sn_reflection.f90"
#   include "sub_J02_sn_reconstruction.f90"
#   include "sub_J02_sn_transport.f90"

end module mod_J02_neutral_sn_transport_2Drz
