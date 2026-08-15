!> @file sub_B01_scatter_3Dxyz.f90
!> @author Zilong PENG (2026/04/06)
!> @brief Scatter particle weights to the 3D density field.
!> @details This subroutine deposits particle contributions from
!> ``par`` onto the nodal density array ``den`` using trilinear
!> weighting in 3D Cartesian coordinates. The reference node is the
!> node closest to the origin among the eight nodes of the cell
!> containing the particle. After all particle contributions are
!> accumulated, the whole density array is multiplied by ``w``.

!> @param[in] il: integer (1:3), cell-center lower indices in x, y, z.
!> @param[in] iu: integer (1:3), cell-center upper indices in x, y, z.
!> @param[inout] den: real
!> (``il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1``), density
!> array receiving scattered particle contributions.
!> @param[in] np: integer, number of particles.
!> @param[in] par: real (1:6,1:np), particle array. ``par(1:3,p)``
!> stores the particle position in x,y,z.
!> @param[in] w: real, global scaling factor applied after scattering.

subroutine sub_B01_scatter_3Dxyz(il,iu,den,np,par,w)

    implicit none

    integer,dimension(1:3) :: il,iu
    real,dimension(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1, &
        il(3)-1:iu(3)+1) :: den
    integer :: np
    real,dimension(1:3,1:np) :: par
    real :: w

    integer :: p,i,j,k
    real :: fi,fj,fk

    !$omp parallel default(firstprivate) reduction(+:den)
    !$omp do
    do p = 1,np
        i = floor(par(1,p))
        j = floor(par(2,p))
        k = floor(par(3,p))
        fi = par(1,p)-real(i)
        fj = par(2,p)-real(j)
        fk = par(3,p)-real(k)
        den(i  ,j  ,k  ) = den(i  ,j  ,k  ) + (1.0-fi)*(1.0-fj)*(1.0-fk)
        den(i+1,j  ,k  ) = den(i+1,j  ,k  ) + (    fi)*(1.0-fj)*(1.0-fk)
        den(i  ,j+1,k  ) = den(i  ,j+1,k  ) + (1.0-fi)*(    fj)*(1.0-fk)
        den(i  ,j  ,k+1) = den(i  ,j  ,k+1) + (1.0-fi)*(1.0-fj)*(    fk)
        den(i+1,j+1,k  ) = den(i+1,j+1,k  ) + (    fi)*(    fj)*(1.0-fk)
        den(i  ,j+1,k+1) = den(i  ,j+1,k+1) + (1.0-fi)*(    fj)*(    fk)
        den(i+1,j  ,k+1) = den(i+1,j  ,k+1) + (    fi)*(1.0-fj)*(    fk)
        den(i+1,j+1,k+1) = den(i+1,j+1,k+1) + (    fi)*(    fj)*(    fk)
    end do
    !$omp end do
    !$omp end parallel

    den = den * w

end subroutine sub_B01_scatter_3Dxyz