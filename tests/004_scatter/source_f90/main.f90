#include "mod_manageProcedures.f90"

program main 

    use mod_manageProcedures

    implicit none

    integer, dimension(1:3) :: il, iu
    real :: xp, yp, zp,w
    integer :: np
    character(len=128) :: outfile
    real, allocatable, dimension(:,:) :: par
    character(len=128) :: outfile_den, outfile_par

    !---------------------------------
    ! case 01: single particle center
    !---------------------------------
    il = (/1, 1, 1/)
    iu = (/12, 12, 12/)

    xp = 2.5
    yp = 3.5
    zp = 4.5
    w = 1.0

    print *, '=========================================='
    print *, 'Case 01: single particle center test'
    print *, 'Particle position = ', xp, yp, zp
    print *, 'Particle weight   = ', w
    print *, '=========================================='
    outfile = 'output_case01.dat'

    call sub_single(il, iu, xp, yp, zp, w, outfile)
    !---------------------------------
    ! case 02: single particle no-center
    !---------------------------------
    il = (/1, 1, 1/)
    iu = (/12, 12, 12/)

    xp = 2.2
    yp = 3.3
    zp = 4.4
    w = 1.0

    print *, '=========================================='
    print *, 'Case 02: single particle no-center test'
    print *, 'Particle position = ', xp, yp, zp
    print *, 'Particle weight   = ', w
    print *, '=========================================='

    outfile = 'output_case02.dat'

    call sub_single(il, iu, xp, yp, zp, w, outfile)
    !---------------------------------
    ! case 03: multi particle 
    !---------------------------------
    np = 3
    allocate(par(1:6,1:np))
    par = 0.0

    par(1,1) = 2.5
    par(2,1) = 3.5
    par(3,1) = 4.5

    par(1,2) = 2.2
    par(2,2) = 3.3
    par(3,2) = 4.4

    par(1,3) = 3.1
    par(2,3) = 2.7
    par(3,3) = 1.8

    outfile = 'output_case03.dat'
    call sub_multi(il, iu, np, par, w, outfile)

    deallocate(par)

    !---------------------------------
    ! Case 04: hollow H shape structure
    !---------------------------------
    outfile_den = 'output_case04_hollowH_den.dat'
    outfile_par = 'output_case04_hollowH_par.dat'
    call sub_many(il, iu, w, outfile_den, outfile_par)


    end program main
