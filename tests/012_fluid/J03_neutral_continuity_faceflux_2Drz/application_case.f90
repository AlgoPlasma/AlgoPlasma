! Shared application inputs; this module belongs to the tests, not J_Fluid.
module mod_application_case
    implicit none
contains
! Shared application geometry and prescribed loss; not part of the library.
    subroutine build_case_mask(active)
        logical, allocatable, intent(out) :: active(:,:)
        allocate(active(256,256))
        active = .false.
        active(65:192,1:72) = .true.
        active(:,73:256) = .true.
    end subroutine build_case_mask

    subroutine build_case_loss(r_edge, z_edge, active, enabled, loss)
        real, intent(in) :: r_edge(:), z_edge(:)
        logical, intent(in) :: active(:,:), enabled
        real, intent(out) :: loss(:,:)
        real, parameter :: rmin=0.013683098220475191, rmax=0.024672244366128356
        real, parameter :: zmin=0.0024709824265487373, zmax=0.010022411397665104
        real :: r, z, shape_value
        integer :: i, k
        loss = 0.0
        if (.not. enabled) return
        do k = 1, size(active,2)
            z = 0.5*(z_edge(k)+z_edge(k+1))
            do i = 1, size(active,1)
                if (.not. active(i,k)) cycle
                r = 0.5*(r_edge(i)+r_edge(i+1))
                if (r < rmin .or. r > rmax .or. z < zmin .or. z > zmax) cycle
                shape_value = cos(acos(-1.0)*(r-0.5*(rmin+rmax))/(rmax-rmin))* &
                    cos(acos(-1.0)*(z-0.5*(zmin+zmax))/(zmax-zmin))
                loss(i,k) = 1.0e5*max(0.0,shape_value)
            end do
        end do
    end subroutine build_case_loss

end module mod_application_case
