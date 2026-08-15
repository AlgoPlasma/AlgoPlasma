#include "mod_manageProcedures.f90"

program main
    use mod_manageProcedures
    implicit none

    write(*,'("==========================================")')
    write(*,'("Case 01: particle count")')
    write(*,'("==========================================")')
    call sub_case01_count()

    write(*,*)
    write(*,'("==========================================")')
    write(*,'("Case 02: spatial positions")')
    write(*,'("==========================================")')
    call sub_case02_positions()

    write(*,*)
    write(*,'("==========================================")')
    write(*,'("Case 03: zero thermal speed (vt=0 -> v=vd)")')
    write(*,'("==========================================")')
    call sub_case03_vt0()

    write(*,*)
    write(*,'("==========================================")')
    write(*,'("Case 04: Maxwellian statistics")')
    write(*,'("==========================================")')
    call sub_case04_maxwellian()

end program main
