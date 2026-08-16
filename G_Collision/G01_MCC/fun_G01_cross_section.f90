!> @file fun_G01_cross_section.f90
!> @brief Interpolate a tabulated collision cross section.
!>
!> @details
!> Evaluates the cross section at ``energy`` by linear interpolation on a
!> uniformly spaced energy grid. Energies outside the table are clamped to the
!> nearest boundary value.
!>
!> @author Lihuan XIE (2025/12/18)
!>
!> @param[in] energy Particle energy at which the cross section is evaluated.
!> @param[in] Nmax Number of tabulated energy points.
!> @param[in] cross_section Tabulated data ``(1:2,1:Nmax)``. Row 1 stores
!>   energy values and row 2 stores cross-section values.
!> @return Interpolated or boundary-clamped cross-section value.

function fun_G01_cross_section(energy,Nmax,cross_section)

    implicit none

    real :: fun_G01_cross_section
    real :: energy
    integer :: Nmax
    real,dimension(1:2,1:Nmax) :: cross_section

    real :: de,buf
    integer :: i

    de = cross_section(1,2) - cross_section(1,1)

    i = floor((energy - cross_section(1,1)) / de) + 1

    if (i >= Nmax) then
        ! If bigger, set to be the last value.
        fun_G01_cross_section = cross_section(2,Nmax)
        return
    else if (i < 1) then
        ! If smaller, set to be the first value.
        fun_G01_cross_section = cross_section(2,1)
        return
    end if

    buf = (energy - cross_section(1,i)) / de

    fun_G01_cross_section = &
        cross_section(2,i) * (1.0 - buf) + cross_section(2,i + 1) * buf

end function fun_G01_cross_section
