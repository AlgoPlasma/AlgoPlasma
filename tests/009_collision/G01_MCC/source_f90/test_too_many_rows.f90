program test_cross_section_loader_too_many

    implicit none

    integer,parameter :: Nmax = 3
    real :: cross_section(1:2,1:Nmax)

    call sub_G01_load_cross_section(Nmax,cross_section,"data/cross_section_too_many_rows.dat")

    write(*,*) "FAIL: oversized cross-section table was accepted."
    stop 1

contains

#include "G_Collision/G01_MCC/sub_G01_load_cross_section.f90"

end program test_cross_section_loader_too_many
