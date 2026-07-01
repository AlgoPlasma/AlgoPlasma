#!/usr/bin/env python3
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.tri import Triangulation


def make_sponge_1d(n, nbuf=20, smax=2.2):
    sigma = np.zeros(n, dtype=np.float64)
    for i in range(nbuf):
        a = (nbuf - i) / nbuf
        v = smax * a * a
        sigma[i] = max(sigma[i], v)
        sigma[n - 1 - i] = max(sigma[n - 1 - i], v)
    return sigma


def run_fdtd_3d_cylindrical_waveguide():
    # Physical constants
    c0 = 299792458.0

    # Waveguide / source parameters
    a = 0.027  # waveguide radius (m)
    f0 = 10.0e9
    w0 = 2.0 * np.pi * f0
    lam0 = c0 / f0

    # Cylindrical grid (r, phi, z)
    nr = 30
    nphi = 16
    nz = 140
    dr = a / (nr - 1)
    dphi = 2.0 * np.pi / nphi
    dz = lam0 / 18.0

    # Conservative CFL estimate (uses smallest metric spacing near axis)
    r_min = dr
    s = 0.78
    dt = s / (
        c0
        * np.sqrt(
            1.0 / dr**2
            + 1.0 / (r_min * dphi) ** 2
            + 1.0 / dz**2
        )
    )
    nsteps = 720

    # Scalar Ez wave-equation FDTD in cylindrical coordinates (TM-like mode demo)
    ez_prev = np.zeros((nr, nphi, nz), dtype=np.float64)
    ez = np.zeros_like(ez_prev)
    ez_next = np.zeros_like(ez_prev)

    r = np.arange(nr) * dr
    phi = np.arange(nphi) * dphi

    # z absorbing sponge (avoid strong end reflection)
    sz = make_sponge_1d(nz, nbuf=20, smax=2.4)
    damp = np.exp(-sz[None, None, :] * dt)

    # Hard electric source at entrance section (z = z_src)
    z_src = 2
    r0 = 0.35 * a
    wr = 0.20 * a
    src_profile = np.exp(-((r[:, None] - r0) / wr) ** 2) * np.cos(phi[None, :])

    cfl2 = (c0 * dt) ** 2

    for n in range(nsteps):
        # phi periodic neighbors
        ez_jp = np.roll(ez, -1, axis=1)
        ez_jm = np.roll(ez, 1, axis=1)

        # radial + azimuthal + axial Laplacian for i>0, interior z
        ui = ez[1:-1, :, 1:-1]
        urr = (ez[2:, :, 1:-1] - 2.0 * ui + ez[:-2, :, 1:-1]) / (dr * dr)
        ur = (ez[2:, :, 1:-1] - ez[:-2, :, 1:-1]) / (2.0 * dr)
        uphi = (ez_jp[1:-1, :, 1:-1] - 2.0 * ui + ez_jm[1:-1, :, 1:-1]) / (
            (r[1:-1, None, None] ** 2) * (dphi * dphi)
        )
        uzz = (ez[1:-1, :, 2:] - 2.0 * ui + ez[1:-1, :, :-2]) / (dz * dz)
        lap = urr + ur / r[1:-1, None, None] + uphi + uzz
        ez_next[1:-1, :, 1:-1] = 2.0 * ui - ez_prev[1:-1, :, 1:-1] + cfl2 * lap

        # axis closure at r=0: finite-value cylindrical limit for Ez
        ua = ez[0, :, 1:-1]
        urr_a = 4.0 * (ez[1, :, 1:-1] - ua) / (dr * dr)
        uzz_a = (ez[0, :, 2:] - 2.0 * ua + ez[0, :, :-2]) / (dz * dz)
        ez_next[0, :, 1:-1] = 2.0 * ua - ez_prev[0, :, 1:-1] + cfl2 * (urr_a + uzz_a)

        # hard source
        t = (n + 1) * dt
        env = np.exp(-((t - 22.0 / f0) * 0.25 * f0) ** 2)
        ez_next[:, :, z_src] = np.sin(w0 * t) * env * src_profile

        # PEC waveguide wall at r=a
        ez_next[-1, :, :] = 0.0

        # simple z-end treatment + absorbing sponge
        ez_next[:, :, 0] = ez_next[:, :, 1]
        ez_next[:, :, -1] = ez_next[:, :, -2]
        ez_next *= damp

        ez_prev, ez, ez_next = ez, ez_next, ez_prev
        ez_next.fill(0.0)

    # Pick a middle section to show mode pattern on x-y plane
    kz = nz // 2
    amp = np.abs(ez[:, :, kz])
    vmax = np.percentile(amp, 99.0)

    # Map (r,phi) -> (x,y) and draw a single pseudocolor map
    rr, pp = np.meshgrid(r, phi, indexing="ij")
    xx = (rr * np.cos(pp)).ravel()
    yy = (rr * np.sin(pp)).ravel()
    vv = amp.ravel()
    tri = Triangulation(xx, yy)

    plt.figure(figsize=(8.6, 7.3), dpi=170)
    im = plt.tripcolor(tri, vv, shading="gouraud", cmap="turbo", vmin=0.0, vmax=vmax)
    plt.gca().set_aspect("equal", adjustable="box")
    plt.xlabel("x (m)")
    plt.ylabel("y (m)")
    plt.title("3D Cylindrical FDTD Circular Waveguide Mode at 10 GHz (|Ez| slice)")
    cbar = plt.colorbar(im, pad=0.02)
    cbar.set_label("|Ez| (a.u.)")
    plt.tight_layout()
    plt.savefig("fdtd_3d_cylindrical_waveguide_mode.png", dpi=230)
    plt.close()


if __name__ == "__main__":
    run_fdtd_3d_cylindrical_waveguide()
