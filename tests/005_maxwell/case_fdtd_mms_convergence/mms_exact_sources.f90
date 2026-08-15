module mms_exact_sources

implicit none

contains

subroutine cartesian_exact_and_sources(x,y,z,t,ep,mu,lx,ly,lz,omega, &
    ex,ey,ez,hx,hy,hz,sex,sey,sez,shx,shy,shz)
    implicit none
    real, intent(in) :: x, y, z, t, ep, mu, lx, ly, lz, omega
    real, intent(out) :: ex, ey, ez, hx, hy, hz, sex, sey, sez, shx, shy, shz

    real :: kx, ky, kz
    real :: sx, sy, sz, cx, cy, cz, swt, cwt
    real :: dex_dt, dey_dt, dez_dt
    real :: dhx_dt, dhy_dt, dhz_dt
    real :: curlhx, curlhy, curlhz
    real :: curlex, curley, curlez

    kx = 2.0*acos(-1.0)/lx
    ky = 2.0*acos(-1.0)/ly
    kz = 2.0*acos(-1.0)/lz

    sx = sin(kx*x); cx = cos(kx*x)
    sy = sin(ky*y); cy = cos(ky*y)
    sz = sin(kz*z); cz = cos(kz*z)
    swt = sin(omega*t); cwt = cos(omega*t)

    ex = sx*cy*cz*cwt
    ey = -0.8*cx*sy*cz*cwt
    ez = 0.6*cx*cy*sz*cwt

    hx = 0.7*cx*sy*sz*swt
    hy = 0.5*sx*cy*sz*swt
    hz = -0.9*sx*sy*cz*swt

    dex_dt = -omega*sx*cy*cz*swt
    dey_dt = 0.8*omega*cx*sy*cz*swt
    dez_dt = -0.6*omega*cx*cy*sz*swt

    dhx_dt = 0.7*omega*cx*sy*sz*cwt
    dhy_dt = 0.5*omega*sx*cy*sz*cwt
    dhz_dt = -0.9*omega*sx*sy*cz*cwt

    curlhx = sx*cy*cz*swt*(-0.9*ky - 0.5*kz)
    curlhy = cx*sy*cz*swt*(0.7*kz + 0.9*kx)
    curlhz = cx*cy*sz*swt*(0.5*kx - 0.7*ky)

    curlex = cx*sy*sz*cwt*(-0.6*ky - 0.8*kz)
    curley = sx*cy*sz*cwt*(-kz + 0.6*kx)
    curlez = sx*sy*cz*cwt*(0.8*kx + ky)

    sex = dex_dt - curlhx/ep
    sey = dey_dt - curlhy/ep
    sez = dez_dt - curlhz/ep

    shx = dhx_dt + curlex/mu
    shy = dhy_dt + curley/mu
    shz = dhz_dt + curlez/mu
end subroutine cartesian_exact_and_sources


subroutine rz_tmz_exact_and_sources(r,z,t,ep,mu,rmax,lz,omega, &
    er,ez,hphi,ser,sez,shphi)
    implicit none
    real, intent(in) :: r, z, t, ep, mu, rmax, lz, omega
    real, intent(out) :: er, ez, hphi, ser, sez, shphi

    real :: g, q, dg, dq, metric_hphi
    real :: s1, c1, s2, c2, swt, cwt
    real :: der_dt, dez_dt, dhphi_dt
    real :: dhphi_dz, dez_dr, der_dz

    g = r*(1.0-(r/rmax)**2)
    q = (1.0-(r/rmax)**2)**2
    dg = 1.0 - 3.0*(r/rmax)**2
    dq = -4.0*r/rmax**2*(1.0-(r/rmax)**2)

    s1 = sin(acos(-1.0)*z/lz)
    c1 = cos(acos(-1.0)*z/lz)
    s2 = sin(2.0*acos(-1.0)*z/lz)
    c2 = cos(2.0*acos(-1.0)*z/lz)
    swt = sin(omega*t)
    cwt = cos(omega*t)

    er = g*s1*cwt
    ez = q*s2*cwt
    hphi = g*s2*swt

    der_dt = -omega*g*s1*swt
    dez_dt = -omega*q*s2*swt
    dhphi_dt = omega*g*s2*cwt

    dhphi_dz = g*(2.0*acos(-1.0)/lz)*c2*swt
    dez_dr = dq*s2*cwt
    der_dz = g*(acos(-1.0)/lz)*c1*cwt

    if (r > 0.0) then
        metric_hphi = (2.0 - 4.0*(r/rmax)**2)*s2*swt
    else
        metric_hphi = 2.0*s2*swt
    end if

    ser = der_dt + dhphi_dz/ep
    sez = dez_dt - metric_hphi/ep
    shphi = dhphi_dt - (dez_dr-der_dz)/mu
end subroutine rz_tmz_exact_and_sources


subroutine cyl_m0_exact_and_sources(r,z,t,ep,mu,rmax,lz,omega, &
    er,ephi,ez,hr,hphi,hz,ser,sephi,sez,shr,shphi,shz)
    implicit none
    real, intent(in) :: r, z, t, ep, mu, rmax, lz, omega
    real, intent(out) :: er, ephi, ez, hr, hphi, hz
    real, intent(out) :: ser, sephi, sez, shr, shphi, shz

    real :: g, q, dg, dq, metric_hphi, metric_ephi
    real :: s1, c1, s2, c2, swt, cwt
    real :: der_dt, dephi_dt, dez_dt, dhr_dt, dhphi_dt, dhz_dt
    real :: dhphi_dz, dhr_dz, dhz_dr
    real :: dephi_dz, dez_dr, der_dz

    g = r*(1.0-(r/rmax)**2)
    q = (1.0-(r/rmax)**2)**2
    dg = 1.0 - 3.0*(r/rmax)**2
    dq = -4.0*r/rmax**2*(1.0-(r/rmax)**2)

    s1 = sin(acos(-1.0)*z/lz)
    c1 = cos(acos(-1.0)*z/lz)
    s2 = sin(2.0*acos(-1.0)*z/lz)
    c2 = cos(2.0*acos(-1.0)*z/lz)
    swt = sin(omega*t)
    cwt = cos(omega*t)

    er = g*s1*cwt
    ephi = g*s2*cwt
    ez = q*s1*cwt

    hr = g*s2*swt
    hphi = g*s1*swt
    hz = q*s2*swt

    der_dt = -omega*g*s1*swt
    dephi_dt = -omega*g*s2*swt
    dez_dt = -omega*q*s1*swt
    dhr_dt = omega*g*s2*cwt
    dhphi_dt = omega*g*s1*cwt
    dhz_dt = omega*q*s2*cwt

    dhphi_dz = g*(acos(-1.0)/lz)*c1*swt
    dhr_dz = g*(2.0*acos(-1.0)/lz)*c2*swt
    dhz_dr = dq*s2*swt

    dephi_dz = g*(2.0*acos(-1.0)/lz)*c2*cwt
    dez_dr = dq*s1*cwt
    der_dz = g*(acos(-1.0)/lz)*c1*cwt

    if (r > 0.0) then
        metric_hphi = (2.0 - 4.0*(r/rmax)**2)*s1*swt
        metric_ephi = (2.0 - 4.0*(r/rmax)**2)*s2*cwt
    else
        metric_hphi = 2.0*s1*swt
        metric_ephi = 2.0*s2*cwt
    end if

    ser = der_dt + dhphi_dz/ep
    sephi = dephi_dt - (dhr_dz-dhz_dr)/ep
    sez = dez_dt - metric_hphi/ep

    shr = dhr_dt - dephi_dz/mu
    shphi = dhphi_dt - (dez_dr-der_dz)/mu
    shz = dhz_dt + metric_ephi/mu
end subroutine cyl_m0_exact_and_sources


subroutine rz_tez_exact_and_sources(r,z,t,ep,mu,rmax,lz,omega, &
    ephi,hr,hz,sephi,shr,shz)
    implicit none
    real, intent(in) :: r, z, t, ep, mu, rmax, lz, omega
    real, intent(out) :: ephi, hr, hz, sephi, shr, shz

    real :: g, q, dq, metric_ephi
    real :: s1, c1, s2, c2, swt, cwt
    real :: dephi_dt, dhr_dt, dhz_dt
    real :: dhr_dz, dephi_dz, dhz_dr

    g = r*(1.0-(r/rmax)**2)
    q = (1.0-(r/rmax)**2)**2
    dq = -4.0*r/rmax**2*(1.0-(r/rmax)**2)

    s1 = sin(acos(-1.0)*z/lz)
    c1 = cos(acos(-1.0)*z/lz)
    s2 = sin(2.0*acos(-1.0)*z/lz)
    c2 = cos(2.0*acos(-1.0)*z/lz)
    swt = sin(omega*t)
    cwt = cos(omega*t)

    ephi = g*s1*cwt
    hr = g*s2*swt
    hz = q*c1*swt

    dephi_dt = -omega*g*s1*swt
    dhr_dt = omega*g*s2*cwt
    dhz_dt = omega*q*c1*cwt

    dhr_dz = g*(2.0*acos(-1.0)/lz)*c2*swt
    dephi_dz = g*(acos(-1.0)/lz)*c1*cwt
    dhz_dr = dq*c1*swt

    if (r > 0.0) then
        metric_ephi = (2.0 - 4.0*(r/rmax)**2)*s1*cwt
    else
        metric_ephi = 2.0*s1*cwt
    end if

    sephi = dephi_dt - (dhr_dz-dhz_dr)/ep
    shr = dhr_dt - dephi_dz/mu
    shz = dhz_dt + metric_ephi/mu
end subroutine rz_tez_exact_and_sources


subroutine cyl_m1_exact_and_sources(r,phi,z,t,ep,mu,rmax,lz,omega, &
    er,ephi,ez,hr,hphi,hz,ser,sephi,sez,shr,shphi,shz)
    implicit none
    real, intent(in) :: r, phi, z, t, ep, mu, rmax, lz, omega
    real, intent(out) :: er, ephi, ez, hr, hphi, hz
    real, intent(out) :: ser, sephi, sez, shr, shphi, shz

    real :: f, g, dg, metric_hphi, metric_ephi
    real :: invr_dhz_dphi, invr_dhr_dphi, invr_dez_dphi, invr_der_dphi
    real :: s1, c1, s2, c2, sp, cp, swt, cwt
    real :: der_dt, dephi_dt, dez_dt, dhr_dt, dhphi_dt, dhz_dt
    real :: dhphi_dz, dhr_dz, dhz_dr
    real :: dephi_dz, dez_dr, der_dz

    f = 1.0 - (r/rmax)**2
    g = r*f
    dg = 1.0 - 3.0*(r/rmax)**2

    s1 = sin(acos(-1.0)*z/lz)
    c1 = cos(acos(-1.0)*z/lz)
    s2 = sin(2.0*acos(-1.0)*z/lz)
    c2 = cos(2.0*acos(-1.0)*z/lz)
    sp = sin(phi)
    cp = cos(phi)
    swt = sin(omega*t)
    cwt = cos(omega*t)

    er = g*s1*cp*cwt
    ephi = g*s1*sp*cwt
    ez = g*s2*cp*cwt

    hr = g*s2*cp*swt
    hphi = g*s2*sp*swt
    hz = g*s1*cp*swt

    der_dt = -omega*g*s1*cp*swt
    dephi_dt = -omega*g*s1*sp*swt
    dez_dt = -omega*g*s2*cp*swt
    dhr_dt = omega*g*s2*cp*cwt
    dhphi_dt = omega*g*s2*sp*cwt
    dhz_dt = omega*g*s1*cp*cwt

    dhphi_dz = g*(2.0*acos(-1.0)/lz)*c2*sp*swt
    dhr_dz = g*(2.0*acos(-1.0)/lz)*c2*cp*swt
    dhz_dr = dg*s1*cp*swt

    dephi_dz = g*(acos(-1.0)/lz)*c1*sp*cwt
    dez_dr = dg*s2*cp*cwt
    der_dz = g*(acos(-1.0)/lz)*c1*cp*cwt

    if (r > 0.0) then
        invr_dhz_dphi = -(g/r)*s1*sp*swt
        invr_dhr_dphi = -(g/r)*s2*sp*swt
        invr_dez_dphi = -(g/r)*s2*sp*cwt
        invr_der_dphi = -(g/r)*s1*sp*cwt
        metric_hphi = (2.0 - 4.0*(r/rmax)**2)*s2*sp*swt
        metric_ephi = (2.0 - 4.0*(r/rmax)**2)*s1*sp*cwt
    else
        invr_dhz_dphi = -s1*sp*swt
        invr_dhr_dphi = -s2*sp*swt
        invr_dez_dphi = -s2*sp*cwt
        invr_der_dphi = -s1*sp*cwt
        metric_hphi = 2.0*s2*sp*swt
        metric_ephi = 2.0*s1*sp*cwt
    end if

    ser = der_dt - (invr_dhz_dphi-dhphi_dz)/ep
    sephi = dephi_dt - (dhr_dz-dhz_dr)/ep
    sez = dez_dt - (metric_hphi-invr_dhr_dphi)/ep

    shr = dhr_dt - (dephi_dz-invr_dez_dphi)/mu
    shphi = dhphi_dt - (dez_dr-der_dz)/mu
    shz = dhz_dt + (metric_ephi-invr_der_dphi)/mu
end subroutine cyl_m1_exact_and_sources

end module mms_exact_sources
