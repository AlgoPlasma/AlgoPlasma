!> @file sub_B01_scatter_3Dxyz_v.f90
!> @author Zilong PENG (2026/04/16)
!> @brief Accumulate weighted particle quantities onto a 3D grid
!>        using trilinear (CIC) interpolation.
!>
!> @details This subroutine performs charge/current deposition onto
!>     a 3D Cartesian grid via the Cloud-In-Cell (CIC) scheme.
!>     Each particle at position ``(par(1,p), par(2,p), par(3,p))``
!>     distributes ``par(d,p) * w`` to the 8 surrounding grid nodes
!>     with trilinear weights.  The loop is parallelized with OpenMP,
!>     using a ``reduction`` clause on ``den`` to avoid race conditions.
!>     The caller is responsible for zeroing ``den`` before the call.

!> @param[in] il: integer (1:3), cell-center lower indices in x, y, z
!> @param[in] iu: integer (1:3), cell-center upper indices in x, y, z
!> @param[inout] den: real (il(1)-1:iu(1)+1, il(2)-1:iu(2)+1,
!>     il(3)-1:iu(3)+1), density array accumulating
!>     the deposited quantity
!> @param[in] np: integer, maximum number of particles in the partition
!> @param[in] par: real (1:6, 1:np), particle phase-space array;
!>     ``par(1:3, p)`` are x, y, z positions and
!>     ``par(d, p)`` is the quantity to be deposited
!> @param[in] w: real, particle weight applied after accumulation
!> @param[in] d: integer, index (1--6) selecting the component of
!>     ``par`` to deposit onto ``den``

subroutine sub_B01_scatter_3Dxyz_v(il,iu,den,np,par,w,d)

    implicit none

    integer :: il(1:3),iu(1:3)
    real    :: den(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)
    integer :: np
    real    :: par(1:6,1:np)
    real    :: w
    integer :: d

    integer :: p,i,j,k
    real    :: fi,fj,fk


    !$omp parallel default(firstprivate) reduction(+:den)
    !$omp do
    do p = 1,np
        i = floor(par(1,p))
        j = floor(par(2,p))
        k = floor(par(3,p))
        fi = par(1,p)-real(i)
        fj = par(2,p)-real(j)
        fk = par(3,p)-real(k)
        den(i  ,j  ,k  ) = den(i  ,j  ,k  ) + (1.0-fi)*(1.0-fj)*(1.0-fk)*par(d,p)
        den(i+1,j  ,k  ) = den(i+1,j  ,k  ) + (    fi)*(1.0-fj)*(1.0-fk)*par(d,p)
        den(i  ,j+1,k  ) = den(i  ,j+1,k  ) + (1.0-fi)*(    fj)*(1.0-fk)*par(d,p)
        den(i  ,j  ,k+1) = den(i  ,j  ,k+1) + (1.0-fi)*(1.0-fj)*(    fk)*par(d,p)
        den(i+1,j+1,k  ) = den(i+1,j+1,k  ) + (    fi)*(    fj)*(1.0-fk)*par(d,p)
        den(i  ,j+1,k+1) = den(i  ,j+1,k+1) + (1.0-fi)*(    fj)*(    fk)*par(d,p)
        den(i+1,j  ,k+1) = den(i+1,j  ,k+1) + (    fi)*(1.0-fj)*(    fk)*par(d,p)
        den(i+1,j+1,k+1) = den(i+1,j+1,k+1) + (    fi)*(    fj)*(    fk)*par(d,p)
    end do
    !$omp end do
    !$omp end parallel
    den = den * w

end subroutine sub_B01_scatter_3Dxyz_v