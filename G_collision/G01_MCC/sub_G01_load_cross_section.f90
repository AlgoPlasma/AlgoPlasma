!> @file sub_G01_load_cross_section.f90
!> @brief Load tabulated electron collision cross-section data.
!>
!> @details
!> Reads a two-column table from ``path`` into ``cross_section``. The first
!> column is electron energy in eV and the second column is the cross section,
!> normally in square meters. The table is expected to use uniform energy
!> spacing. If fewer than ``Nmax`` lines are present, the remaining energy
!> entries are extrapolated and the last cross-section value is held constant.
!>
!> @author Lihuan XIE (2025/12/18)
!>
!> @param[in] Nmax Maximum number of table rows to load.
!> @param[out] cross_section Table ``(1:2,1:Nmax)``. Row 1 stores energies and
!>   row 2 stores the corresponding cross sections.
!> @param[in] path Path to the cross-section data file.

subroutine sub_G01_load_cross_section(Nmax,cross_section,path)

    implicit none

    integer :: Nmax
    real,dimension(1:2,1:Nmax) :: cross_section
    character(len=*) :: path

    integer :: stat,i,j
    real :: de,row(1:2)

    open(1000,file=path)

    cross_section(:,:) = 0.0
    i = 1
    do

        read(1000,*,iostat=stat) row

        ! If end of file.
        if (stat < 0) exit

        if (i > Nmax) then
            write(*,*) "ERROR: i > Nmax in sub_G01_load_cross_section."
            write(*,*) "- Use a larger Nmax."
            stop
        end if

        cross_section(1:2,i) = row
        i = i + 1

    end do

    ! Fill those leftovers.
    de = cross_section(1,2) - cross_section(1,1)
    do j = i,Nmax
        cross_section(1,j) = cross_section(1,j - 1) + de
        cross_section(2,j) = cross_section(2,i - 1)
    end do

    close(1000)

end subroutine sub_G01_load_cross_section
