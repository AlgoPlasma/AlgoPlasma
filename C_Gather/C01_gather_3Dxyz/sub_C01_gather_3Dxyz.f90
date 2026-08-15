!> @file sub_C01_gather_3Dxyz.f90
!> @author Yinjian ZHAO, Zhongping ZHAO (2025/11/04).
!> @brief Trilinearly interpolates 3D grid fields to a single particle position.
!> @details
!>   This subroutine computes the electric field ``E`` and magnetic field ``B`` at the
!>   position of particle ``p`` by trilinearly interpolating the cell-centered grid
!>   fields ``Ex,Ey,Ez,Bx,By,Bz``. The particle position is taken from ``par(1:3,p)``,
!>   shifted by ``+0.5`` to map to cell-center indexing, and the eight surrounding
!>   grid nodes are blended using weights ``fi,fj,fk``.

!> @param[in] p
!>        integer, index of the particle whose position is used for interpolation.
!>
!> @param[in] np
!>        integer, total number of particles; used to define the size of @c par.
!>
!> @param[in] par
!>        real (1:6, 1:np), each column stores the 6-dimensional phase-space
!>        coordinates @f$(x, y, z, v_x, v_y, v_z)@f$ of a single particle.
!>        In this routine, only the position components @f$(x, y, z)@f$ of
!>        particle @c p are used to locate the particle in the grid.
!>
!> @param[in] il
!>        integer (1:3), global starting cell indices in the x, y, and z
!>        directions for the local subdomain, including guard-cell layout.
!>
!> @param[in] iu
!>        integer (1:3), global ending cell indices in the x, y, and z
!>        directions for the local subdomain, including guard-cell layout.
!>
!> @param[in] Ex
!>        real (il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1),
!>        x-component of the electric field on the 3D grid covering the
!>        local subdomain (extended by one guard cell in each direction).
!>
!> @param[in] Ey
!>        real (il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1),
!>        y-component of the electric field on the same 3D grid.
!>
!> @param[in] Ez
!>        real (il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1),
!>        z-component of the electric field on the same 3D grid.
!>
!> @param[in] Bx
!>        real (il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1),
!>        x-component of the magnetic field on the 3D grid.
!>
!> @param[in] By
!>        real (il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1),
!>        y-component of the magnetic field on the same 3D grid.
!>
!> @param[in] Bz
!>        real (il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1),
!>        z-component of the magnetic field on the same 3D grid.
!>
!> @param[in,out] E
!>        real (1:3), electric field at the particle position.
!>        On exit, contains the trilinearly interpolated electric field
!>        @f$\mathbf{E} = (E_x, E_y, E_z)@f$ at the position of particle @c p.
!>
!> @param[in,out] B
!>        real (1:3), magnetic field at the particle position.
!>        On exit, contains the trilinearly interpolated magnetic field
!>        @f$\mathbf{B} = (B_x, B_y, B_z)@f$ at the position of particle @c p.

subroutine sub_C01_gather_3Dxyz(p,np,par,il,iu,Ex,Ey,Ez,Bx,By,Bz,E,B)

    implicit none

    integer :: p,np
    real,dimension(1:6,1:np) :: par
    integer,dimension(1:3) :: il,iu
    real,dimension(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1) :: Ex,Ey,Ez,Bx,By,Bz
    real,dimension(1:3) :: E,B
    
    integer :: i,j,k
    real :: x,y,z,fi,fj,fk
    
    x = par(1,p)+0.5
    y = par(2,p)+0.5
    z = par(3,p)+0.5

    i = floor(x)
    j = floor(y)
    k = floor(z)

    fi = x-real(i)
    fj = y-real(j)
    fk = z-real(k)

    E(1) = trilinear_interp(il,iu,Ex,i,j,k,fi,fj,fk)
    E(2) = trilinear_interp(il,iu,Ey,i,j,k,fi,fj,fk)
    E(3) = trilinear_interp(il,iu,Ez,i,j,k,fi,fj,fk)

    B(1) = trilinear_interp(il,iu,Bx,i,j,k,fi,fj,fk)
    B(2) = trilinear_interp(il,iu,By,i,j,k,fi,fj,fk)
    B(3) = trilinear_interp(il,iu,Bz,i,j,k,fi,fj,fk)

!> \cond DOXYGEN_SHOULD_SKIP_THIS
    contains
    real function trilinear_interp(il,iu,field,i,j,k,fi,fj,fk)
        integer,dimension(1:3) :: il,iu
        real,dimension(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1) :: field 
        integer :: i,j,k
        real :: fi,fj,fk
        trilinear_interp = field(i  ,j  ,k  )*(1.0-fi)*(1.0-fj)*(1.0-fk) + &
                           field(i+1,j  ,k  )*(    fi)*(1.0-fj)*(1.0-fk) + &
                           field(i  ,j+1,k  )*(1.0-fi)*(    fj)*(1.0-fk) + &
                           field(i  ,j  ,k+1)*(1.0-fi)*(1.0-fj)*(    fk) + &
                           field(i+1,j+1,k  )*(    fi)*(    fj)*(1.0-fk) + &
                           field(i+1,j  ,k+1)*(    fi)*(1.0-fj)*(    fk) + &
                           field(i  ,j+1,k+1)*(1.0-fi)*(    fj)*(    fk) + &
                           field(i+1,j+1,k+1)*(    fi)*(    fj)*(    fk)
    end function trilinear_interp
!> \endcond

end subroutine sub_C01_gather_3Dxyz
