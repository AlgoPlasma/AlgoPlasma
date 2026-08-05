!> @file sub_D04_hypre_3Draz_nonuniform_A_mpi.f90
!> @brief Assemble the full 7-point matrix and RHS for the MPI-local
!> 3D cylindrical nonuniform Poisson equation on a cell-centered grid.
!> @details
!> This MPI-local version uses owned-cell index ranges together with one
!> ghost layer in each coordinate direction. The stencil order is
!> 0(i,j,k), 1(i-1,j,k), 2(i+1,j,k), 3(i,j-1,k), 4(i,j+1,k),
!> 5(i,j,k-1), 6(i,j,k+1).
!>
!> The row is built by adding the contribution of each of the six faces.
!> On a local boundary face, the routine first checks `has_neighbor`:
!> if a neighbor exists, the corresponding ghost width is used and an
!> off-process stencil coefficient is assembled; otherwise the face is
!> treated as a physical boundary and `bc_type` / `bc_value` are applied.
!>
!> Currently implemented boundary types are:
!> `0 = BC_NONE`, `1 = BC_AXIS`, `2 = BC_DIRICHLET`,
!> `3 = BC_NEUMANN`,`4 = BC_DIELECTRIC`, `5 = BC_OUTFLOW`.
!>
!> In the current version, `BC_AXIS`, `BC_DIRICHLET`, and `BC_NEUMANN`
!> are assembled directly in this routine.
!> For `BC_NEUMANN`, `bc_value(face)` is the prescribed outward normal
!> derivative `dphi/dn` on that face.
!> `BC_DIELECTRIC` and `BC_OUTFLOW` are deferred to post-processing
!> routines that modify `A_values` and `RHS` after the base assembly.
!>
!> The face order in `has_neighbor`, `bc_type`, and `bc_value` is
!> `(r_lo,r_hi,a_lo,a_hi,z_lo,z_hi)`.
!>
!> Periodic topology is still handled by `HYPRE_StructGridSetPeriodic` in
!> the solver layer. For periodic directions, the caller should either
!> provide wrapped ghost-cell widths and set `has_neighbor(face)=.true.`
!> on seam ranks, or in the single-rank case allow the fallback periodic
!> coefficient path used below.
!> @author Yinjian ZHAO (2026/04/01) Baisheng WANG(2026/04/27)
!
!> @param[in] il_loc: integer (1:3), lower owned cell-center indices in
!> `r,alpha,z` on this MPI rank.
!> @param[in] iu_loc: integer (1:3), upper owned cell-center indices in
!> `r,alpha,z` on this MPI rank.
!> @param[in] rface_lo: real scalar, global radial face coordinate at
!> `r_{il_loc(1)-1/2}` for this MPI rank.
!> @param[in] eps0: real scalar, vacuum permittivity.
!> @param[in] dr: real (il_loc(1)-1:iu_loc(1)+1), local radial cell widths
!> with one ghost layer.
!> @param[in] da: real (il_loc(2)-1:iu_loc(2)+1), local azimuthal cell
!> widths with one ghost layer.
!> @param[in] dz: real (il_loc(3)-1:iu_loc(3)+1), local axial cell widths
!> with one ghost layer.
!> @param[in] periodic: integer (1:3), periodic lengths in r,alpha,z.
!> @param[in] has_neighbor: logical (1:6), whether this MPI rank has a
!> neighboring subdomain on `(r_lo,r_hi,a_lo,a_hi,z_lo,z_hi)`.
!> @param[in] bc_type: integer (1:6), physical boundary-type codes on
!> `(r_lo,r_hi,a_lo,a_hi,z_lo,z_hi)`.
!> @param[in] bc_value: real (1:6), physical boundary values on
!> `(r_lo,r_hi,a_lo,a_hi,z_lo,z_hi)`.
!> @param[out] A_values: real (1:N), flattened 7-point stencil
!> coefficients, `N = 7*(iu_loc(1)-il_loc(1)+1)*(iu_loc(2)-il_loc(2)+1)`
!> `*(iu_loc(3)-il_loc(3)+1)`.
!> @param[in] rho1d: real (1:M), flattened local cell-centered charge
!> density array, `M = (iu_loc(1)-il_loc(1)+1)*(iu_loc(2)-il_loc(2)+1)`
!> `*(iu_loc(3)-il_loc(3)+1)`.
!> @param[out] RHS: real (1:M), flattened right-hand-side array.

subroutine sub_D04_hypre_3Draz_nonuniform_A_mpi( &
    il_loc,iu_loc,rface_lo,eps0,dr,da,dz,periodic,has_neighbor, &
    bc_type,bc_value,A_values,rho1d,RHS)

    implicit none

    integer,parameter :: BC_NONE = 0
    integer,parameter :: BC_AXIS = 1
    integer,parameter :: BC_DIRICHLET = 2
    integer,parameter :: BC_NEUMANN = 3
    integer,parameter :: BC_DIELECTRIC = 4
    integer,parameter :: BC_OUTFLOW  = 5

    integer,dimension(1:3) :: il_loc,iu_loc,periodic
    logical,dimension(1:6) :: has_neighbor
    real :: rface_lo,eps0
    real,dimension(il_loc(1)-1:iu_loc(1)+1) :: dr
    real,dimension(il_loc(2)-1:iu_loc(2)+1) :: da
    real,dimension(il_loc(3)-1:iu_loc(3)+1) :: dz
    integer,dimension(1:6) :: bc_type
    real,dimension(1:6) :: bc_value
    real,dimension(:) :: A_values,rho1d,RHS

    integer :: nentries,ncells,nvalues
    integer :: i,j,k,mA,mR
    logical :: a_periodic,z_periodic
    real,dimension(il_loc(1)-1:iu_loc(1)) :: rface
    real,dimension(il_loc(1):iu_loc(1)) :: rcell
    real :: cr_m,cr_p,ca_m,ca_p,cz_m,cz_p,ap,vol,cbc

    nentries = 7
    ncells = (iu_loc(1)-il_loc(1)+1)*(iu_loc(2)-il_loc(2)+1)* &
        (iu_loc(3)-il_loc(3)+1)
    nvalues = ncells*nentries

    if (periodic(1) /= 0) then
        write(*,*) 'ERROR: periodic(1) /= 0 is not supported in r.'
        stop
    end if

    a_periodic = (periodic(2) /= 0)
    z_periodic = (periodic(3) /= 0)

    if (a_periodic .and. (bc_type(3) /= BC_NONE .or. &
        bc_type(4) /= BC_NONE)) then
        write(*,*) 'ERROR: alpha is periodic, but alpha BC is also set.'
        stop
    end if

    if (z_periodic .and. (bc_type(5) /= BC_NONE .or. &
        bc_type(6) /= BC_NONE)) then
        write(*,*) 'ERROR: z is periodic, but z BC is also set.'
        stop
    end if

    if (bc_type(2) == BC_AXIS .or. bc_type(3) == BC_AXIS .or. &
        bc_type(4) == BC_AXIS .or. bc_type(5) == BC_AXIS .or. &
        bc_type(6) == BC_AXIS) then
        write(*,*) 'ERROR: BC_AXIS is only valid on r_lo.'
        stop
    end if

    if (size(rho1d) /= ncells) then
        write(*,*) 'ERROR: size(rho1d) is inconsistent with local extents.'
        stop
    end if

    if (size(RHS) /= ncells) then
        write(*,*) 'ERROR: size(RHS) is inconsistent with local extents.'
        stop
    end if

    if (size(A_values) /= nvalues) then
        write(*,*) 'ERROR: size(A_values) is inconsistent with local extents.'
        stop
    end if

    rface(il_loc(1)-1) = rface_lo
    do i = il_loc(1),iu_loc(1)
        rface(i) = rface(i-1) + dr(i)
    end do

    do i = il_loc(1),iu_loc(1)
        rcell(i) = 0.5*(rface(i-1) + rface(i))
    end do

    A_values(1:nvalues) = 0.0
    RHS(1:ncells) = 0.0

    mA = 1
    mR = 1
    do k = il_loc(3),iu_loc(3)
    do j = il_loc(2),iu_loc(2)
    do i = il_loc(1),iu_loc(1)

        A_values(mA  ) = 0.0
        A_values(mA+1) = 0.0
        A_values(mA+2) = 0.0
        A_values(mA+3) = 0.0
        A_values(mA+4) = 0.0
        A_values(mA+5) = 0.0
        A_values(mA+6) = 0.0

        vol = rcell(i)*dr(i)*da(j)*dz(k)
        RHS(mR) = rho1d(mR)*vol/eps0
        ap = 0.0

        ! Minus-r face, stencil slot 1.
        if (i > il_loc(1)) then
            cr_m = rface(i-1)*da(j)*dz(k) / (0.5*(dr(i-1)+dr(i)))
            ap = ap + cr_m
            A_values(mA+1) = -cr_m
        else if (has_neighbor(1)) then
            cr_m = rface(i-1)*da(j)*dz(k) / (0.5*(dr(i-1)+dr(i)))
            ap = ap + cr_m
            A_values(mA+1) = -cr_m
        else
            select case (bc_type(1))
            case (BC_AXIS)
                ! Axis face: no flux contribution is added here.
            case (BC_DIRICHLET)
                cbc = 2.0*rface(i-1)*da(j)*dz(k)/dr(i)
                ap = ap + cbc
                RHS(mR) = RHS(mR) + cbc*bc_value(1)
            case (BC_NEUMANN)
                cbc = rface(i-1)*da(j)*dz(k)
                RHS(mR) = RHS(mR) - cbc*bc_value(1)
            case (BC_DIELECTRIC, BC_OUTFLOW)
                ! Deferred to post-processing routines.
            case default
                write(*,*) 'ERROR: invalid or missing BC at r_lo.'
                stop
            end select
        end if

        ! Plus-r face, stencil slot 2.
        if (i < iu_loc(1)) then
            cr_p = rface(i)*da(j)*dz(k) / (0.5*(dr(i)+dr(i+1)))
            ap = ap + cr_p
            A_values(mA+2) = -cr_p
        else if (has_neighbor(2)) then
            cr_p = rface(i)*da(j)*dz(k) / (0.5*(dr(i)+dr(i+1)))
            ap = ap + cr_p
            A_values(mA+2) = -cr_p
        else
            select case (bc_type(2))
            case (BC_DIRICHLET)
                cbc = 2.0*rface(i)*da(j)*dz(k)/dr(i)
                ap = ap + cbc
                RHS(mR) = RHS(mR) + cbc*bc_value(2)
            case (BC_NEUMANN)
                cbc = rface(i)*da(j)*dz(k)
                RHS(mR) = RHS(mR) - cbc*bc_value(2)
            case (BC_DIELECTRIC, BC_OUTFLOW)
                ! Deferred to post-processing routines.
            case default
                write(*,*) 'ERROR: invalid or missing BC at r_hi.'
                stop
            end select
        end if

        ! Minus-alpha face, stencil slot 3.
        if (j > il_loc(2)) then
            ca_m = dr(i)*dz(k) / (rcell(i)*0.5*(da(j-1)+da(j)))
            ap = ap + ca_m
            A_values(mA+3) = -ca_m
        else if (has_neighbor(3)) then
            ca_m = dr(i)*dz(k) / (rcell(i)*0.5*(da(j-1)+da(j)))
            ap = ap + ca_m
            A_values(mA+3) = -ca_m
        else if (a_periodic) then
            ca_m = dr(i)*dz(k) / (rcell(i)*0.5*(da(iu_loc(2))+da(j)))
            ap = ap + ca_m
            A_values(mA+3) = -ca_m
        else
            select case (bc_type(3))
            case (BC_DIRICHLET)
                cbc = 2.0*dr(i)*dz(k)/(rcell(i)*da(j))
                ap = ap + cbc
                RHS(mR) = RHS(mR) + cbc*bc_value(3)
            case (BC_NEUMANN)
                cbc = dr(i)*dz(k)
                RHS(mR) = RHS(mR) - cbc*bc_value(3)
            case (BC_DIELECTRIC, BC_OUTFLOW)
                ! Deferred to post-processing routines.
            case default
                write(*,*) 'ERROR: invalid or missing BC at a_lo.'
                stop
            end select
        end if

        ! Plus-alpha face, stencil slot 4.
        if (j < iu_loc(2)) then
            ca_p = dr(i)*dz(k) / (rcell(i)*0.5*(da(j)+da(j+1)))
            ap = ap + ca_p
            A_values(mA+4) = -ca_p
        else if (has_neighbor(4)) then
            ca_p = dr(i)*dz(k) / (rcell(i)*0.5*(da(j)+da(j+1)))
            ap = ap + ca_p
            A_values(mA+4) = -ca_p
        else if (a_periodic) then
            ca_p = dr(i)*dz(k) / (rcell(i)*0.5*(da(j)+da(il_loc(2))))
            ap = ap + ca_p
            A_values(mA+4) = -ca_p
        else
            select case (bc_type(4))
            case (BC_DIRICHLET)
                cbc = 2.0*dr(i)*dz(k)/(rcell(i)*da(j))
                ap = ap + cbc
                RHS(mR) = RHS(mR) + cbc*bc_value(4)
            case (BC_NEUMANN)
                cbc = dr(i)*dz(k)
                RHS(mR) = RHS(mR) - cbc*bc_value(4)
            case (BC_DIELECTRIC, BC_OUTFLOW)
                ! Deferred to post-processing routines.
            case default
                write(*,*) 'ERROR: invalid or missing BC at a_hi.'
                stop
            end select
        end if

        ! Minus-z face, stencil slot 5.
        if (k > il_loc(3)) then
            cz_m = rcell(i)*dr(i)*da(j) / (0.5*(dz(k-1)+dz(k)))
            ap = ap + cz_m
            A_values(mA+5) = -cz_m
        else if (has_neighbor(5)) then
            cz_m = rcell(i)*dr(i)*da(j) / (0.5*(dz(k-1)+dz(k)))
            ap = ap + cz_m
            A_values(mA+5) = -cz_m
        else if (z_periodic) then
            cz_m = rcell(i)*dr(i)*da(j) / (0.5*(dz(iu_loc(3))+dz(k)))
            ap = ap + cz_m
            A_values(mA+5) = -cz_m
        else
            select case (bc_type(5))
            case (BC_DIRICHLET)
                cbc = 2.0*rcell(i)*dr(i)*da(j)/dz(k)
                ap = ap + cbc
                RHS(mR) = RHS(mR) + cbc*bc_value(5)
            case (BC_NEUMANN)
                cbc = rcell(i)*dr(i)*da(j)
                RHS(mR) = RHS(mR) - cbc*bc_value(5)
            case (BC_DIELECTRIC, BC_OUTFLOW)
                ! Deferred to post-processing routines.
            case default
                write(*,*) 'ERROR: invalid or missing BC at z_lo.'
                stop
            end select
        end if

        ! Plus-z face, stencil slot 6.
        if (k < iu_loc(3)) then
            cz_p = rcell(i)*dr(i)*da(j) / (0.5*(dz(k)+dz(k+1)))
            ap = ap + cz_p
            A_values(mA+6) = -cz_p
        else if (has_neighbor(6)) then
            cz_p = rcell(i)*dr(i)*da(j) / (0.5*(dz(k)+dz(k+1)))
            ap = ap + cz_p
            A_values(mA+6) = -cz_p
        else if (z_periodic) then
            cz_p = rcell(i)*dr(i)*da(j) / (0.5*(dz(k)+dz(il_loc(3))))
            ap = ap + cz_p
            A_values(mA+6) = -cz_p
        else
            select case (bc_type(6))
            case (BC_DIRICHLET)
                cbc = 2.0*rcell(i)*dr(i)*da(j)/dz(k)
                ap = ap + cbc
                RHS(mR) = RHS(mR) + cbc*bc_value(6)
            case (BC_NEUMANN)
                cbc = rcell(i)*dr(i)*da(j)
                RHS(mR) = RHS(mR) - cbc*bc_value(6)
            case (BC_DIELECTRIC, BC_OUTFLOW)
                ! Deferred to post-processing routines.
            case default
                write(*,*) 'ERROR: invalid or missing BC at z_hi.'
                stop
            end select
        end if

        A_values(mA) = ap

        mA = mA + nentries
        mR = mR + 1

    end do
    end do
    end do

end subroutine sub_D04_hypre_3Draz_nonuniform_A_mpi
