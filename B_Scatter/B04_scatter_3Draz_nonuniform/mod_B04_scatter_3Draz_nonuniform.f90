!> @file mod_B04_scatter_3Draz_nonuniform.f90
!> @brief Module entry for B04 density deposition on nonuniform r-a-z grids.
!> @see @ref mod_b04_scatter_3draz_nonuniform "mod_B04_scatter_3Draz_nonuniform"

!> @brief Linear CIC nodal number or charge density deposition and supporting
!> operations on a three-dimensional structured tensor-product cylindrical
!> grid allowing independently nonuniform coordinate spacing.
!> @author Xin Luo (2026/10/31)
!>
!> @details
!> Grid geometry is specified by radial, angular and axial node arrays.
!> In the module name, raz denotes these r-a-z directions; the angular
!> coordinate is named phi in the interfaces and written as phi in the formulas.
!> Radius and axial position use consistent length units; angles are in radians.
!>
!> @par Public routines
!> - @ref sub_b04_build_geometry "sub_B04_build_geometry": prepare inverse
!>   effective nodal volumes and angular weights when the grid or topology changes.
!> - @ref sub_b04_scatter_3draz_nonuniform "sub_B04_scatter_3Draz_nonuniform":
!>   add one particle's represented number or charge to nodal density.
!> - @ref sub_b04_average_axis "sub_B04_average_axis": make density single-valued
!>   at each axial position on a full-circle r=0 axis by weighted averaging.
!> - @ref sub_b04_project_density "sub_B04_project_density": optionally form
!>   cell-volume averages when required by downstream source assembly.
!>
!> @par Caller responsibilities
!> The caller manages arrays, supplies particle positions and containing cells,
!> and organizes particle boundary handling and shared-node summation.
!> Initialize density before a new deposition stage; successive particle calls
!> accumulate into the same array. Sum shared-node contributions, then apply
!> full-circle axis averaging when applicable. Use the resulting nodal density
!> directly or form cell-volume averages as needed.
!>
!> @anchor b04_return_status
!> @par Return status
!> Check ierr after every public call. Common definitions are attached to
!> @ref mod_b04_scatter_3draz_nonuniform::b04_ok "B04_OK",
!> @ref mod_b04_scatter_3draz_nonuniform::b04_bad_shape "B04_BAD_SHAPE",
!> @ref mod_b04_scatter_3draz_nonuniform::b04_bad_grid "B04_BAD_GRID",
!> @ref mod_b04_scatter_3draz_nonuniform::b04_bad_cell "B04_BAD_CELL",
!> @ref mod_b04_scatter_3draz_nonuniform::b04_bad_value "B04_BAD_VALUE" and
!> @ref mod_b04_scatter_3draz_nonuniform::b04_bad_volume "B04_BAD_VOLUME".
!> Each routine documents its input requirements and additional checks.
!>
!> @par Compilation and use
!> Compile this module with preprocessing enabled and the B04 directory on the
!> include path; it includes the four implementation files. Callers import the
!> interfaces with `use mod_B04_scatter_3Draz_nonuniform`. Compile the module
!> and callers with the same default real kind.
module mod_B04_scatter_3Draz_nonuniform
    use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
    implicit none
    private

    !> Successful completion of a B04 routine.
    integer, parameter, public :: B04_OK = 0
    !> Array dimensions do not satisfy the routine's interface requirements.
    integer, parameter, public :: B04_BAD_SHAPE = 1
    !> Coordinate arrays or local grid geometry do not satisfy the routine's requirements.
    integer, parameter, public :: B04_BAD_GRID = 2
    !> A supplied cell index is outside the valid range.
    integer, parameter, public :: B04_BAD_CELL = 3
    !> A numerical input or checked result is nonfinite, a density sum exceeds the
    !> representable range, or a particle lies outside its supplied cell.
    integer, parameter, public :: B04_BAD_VALUE = 4
    !> A nodal volume, inverse volume, angular weight or weight sum fails the routine's validity checks.
    integer, parameter, public :: B04_BAD_VOLUME = 5

    public :: sub_B04_build_geometry, sub_B04_scatter_3Draz_nonuniform
    public :: sub_B04_average_axis, sub_B04_project_density

contains

#include "sub_B04_build_geometry.f90"
#include "sub_B04_scatter_3Draz_nonuniform.f90"
#include "sub_B04_average_axis.f90"
#include "sub_B04_project_density.f90"

    ! Check for at least two finite, strictly increasing coordinate nodes.
    logical function valid_coordinates(x)
        real, intent(in) :: x(0:)
        valid_coordinates = .false.
        if (size(x) < 2) return
        if (.not. all(ieee_is_finite(x))) return
        if (any(x(1:) <= x(:size(x)-2))) return
        valid_coordinates = .true.
    end function valid_coordinates

end module mod_B04_scatter_3Draz_nonuniform
