program test_cross_section_loader

    implicit none

    integer,parameter :: Nmax = 3
    real :: cross_section(1:2,1:Nmax)
    real :: expected(1:2,1:Nmax)

    expected = reshape((/ 0.0,10.0,1.0,20.0,2.0,40.0 /),shape(expected))

    call sub_G01_load_cross_section(Nmax,cross_section,"data/cross_section_exact_nmax.dat")

    if (maxval(abs(cross_section - expected)) > 1.0e-12) then
        write(*,*) "FAIL: loaded table differs from the input values."
        stop 1
    end if

    write(*,*) "PASS: exact-length cross-section table loaded."

contains

#include "G_Collision/G01_MCC/sub_G01_load_cross_section.f90"

end program test_cross_section_loader
