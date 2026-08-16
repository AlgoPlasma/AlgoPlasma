!> @file sub_G01_electron.f90
!> @brief Electron collision and post-collision velocity update.

!> @details
!> This subroutine handles electron-neutral collisions, including elastic
!> scattering, excitation, and ionization processes. The post-collision
!> electron velocity is updated according to the selected collision type.
!> For ionization events, a secondary electron and an ion are generated,
!> with their velocities sampled from the corresponding distributions.

!> @author Lihuan XIE (2025/12/18)

!> @param[in,out] v: real (1:3), electron velocity.
!> @param[in] me: real, electron mass.
!> @param[in] mn: real, neutral particle mass.
!> @param[in] e: real, unit charge.
!> @param[in] energy_excitation: real, excitation energy, if > 0 then excitation is applied.
!> @param[in] energy_ionization: real, ionization energy, if > 0 then ionization is applied.
!> @param[in] x: real (1:3), electron position.
!> @param[out] par_e: real (1:6), new electron particle array.
!> @param[out] par_i: real (1:6), new ion particle array.
!> @param[in] vti: real, thermal velocity of ion.
!> @param[in] vd: real (1:3), drifting velocity of ion.
!> @param[in] eV: real, electron volt conversion factor.

subroutine sub_G01_electron(v,me,mn,e,&
    energy_excitation,energy_ionization,x,par_e,par_i,vti,vd,&
    eV)

    implicit none

    real :: v(1:3),me,mn,e,energy_excitation,energy_ionization
    real :: x(1:3),par_e(1:6),par_i(1:6),vti,vd(1:3)
    real :: eV

    real :: energy,R,cosX,sinX,cosT,sinT,cosP,sinP,energy_new
    real :: vs(1:3),v2,vh(1:3),vm,buf1,buf2,loss,rr(1:6)
    real,parameter :: pi = 3.141592653589793
    real,parameter :: pi2 = 6.283185307179586

    energy_new = 0.0

    ! Compute energy in eV.
    v2 = v(1)*v(1) + v(2)*v(2) + v(3)*v(3)
    energy = 0.5*me*v2 / e

    ! If energy is too close to zero, do not collide.
    if (energy < tiny(1.0_4)) return

    vm = sqrt(v2)
    vh(1:3) = v(1:3) / vm

    ! Compute the post-collision electron scattering angle using the formulas given in the Vahedi(1994).
    call random_number(R)
    cosX = (2.0 + energy*eV - 2.0*(1.0 + energy*eV)**R) / (energy*eV)
    sinX = sqrt(1.0 - cosX*cosX)

    call random_number(R)
    cosP = cos(2.0*pi*R)
    sinP = sin(2.0*pi*R)

    cosT = vh(1)
    sinT = sqrt(1.0 - cosT*cosT)

    if (sinT > tiny(1.0_4)) then

        buf1 = sinX*sinP / sinT
        buf2 = sinX*cosP / sinT

        vs(1) = vh(1)*cosX + (vh(2)*vh(2) + vh(3)*vh(3))*buf2
        vs(2) = vh(2)*cosX + vh(3)*buf1 - vh(1)*vh(2)*buf2
        vs(3) = vh(3)*cosX - vh(2)*buf1 - vh(1)*vh(3)*buf2

    else

        vs(1) = cosX
        vs(2) = sinX*cosP
        vs(3) = sinX*sinP

    end if

    if (energy_excitation > 0.0) then

        loss = energy_excitation

    else if (energy_ionization > 0.0) then

        energy_new = (energy - energy_ionization) * 0.5
        loss = energy_ionization + energy_new

    else

        loss = 2.0*me/mn * (1.0 - cosX) * energy

    end if

    if (energy - loss > 0.0) then
        vm = sqrt((energy - loss)*e/me*2.0)
    else
        vm = 0.0
    end if
    v(1:3) = vs(1:3) * vm

    ! Compute the scattering angle of the newly generated electron produced by ionization.
    if (energy_ionization > 0.0) then

        vm = sqrt(energy_new*e/me*2.0)

        call random_number(R)
        cosX = (2.0 + energy_new*eV - 2.0*(1.0 + energy_new*eV)**R) / (energy_new*eV)
        sinX = sqrt(1.0 - cosX*cosX)

        call random_number(R)
        cosP = cos(2.0*pi*R)
        sinP = sin(2.0*pi*R)

        cosT = vh(1)
        sinT = sqrt(1.0 - cosT*cosT)

        if (sinT > tiny(1.0_4)) then

            buf1 = sinX*sinP / sinT
            buf2 = sinX*cosP / sinT

            vs(1) = vh(1)*cosX + (vh(2)*vh(2) + vh(3)*vh(3))*buf2
            vs(2) = vh(2)*cosX + vh(3)*buf1 - vh(1)*vh(2)*buf2
            vs(3) = vh(3)*cosX - vh(2)*buf1 - vh(1)*vh(3)*buf2

        else

            vs(1) = cosX
            vs(2) = sinX*cosP
            vs(3) = sinX*sinP

        end if

        par_e(4:6) = vs(1:3) * vm

        call random_number(rr(1:6))
        par_i(4) = vti*sqrt(-2.0*log(rr(1))) * cos(pi2*rr(4)) + vd(1)
        par_i(5) = vti*sqrt(-2.0*log(rr(2))) * cos(pi2*rr(5)) + vd(2)
        par_i(6) = vti*sqrt(-2.0*log(rr(3))) * cos(pi2*rr(6)) + vd(3)

        par_e(1:3) = x(1:3)
        par_i(1:3) = x(1:3)

    end if

end subroutine sub_G01_electron
