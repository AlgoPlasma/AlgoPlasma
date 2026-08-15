#!/usr/bin/env python3
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import cm
from matplotlib.colors import Normalize


def make_sponge_1d(n, nbuf=14, smax=0.20):
    """Dimensionless per-step polynomial damping for absorbing edges."""
    sigma = np.zeros(n, dtype=np.float64)
    for i in range(nbuf):
        a = (nbuf - i) / nbuf
        v = smax * a * a
        sigma[i] = max(sigma[i], v)
        sigma[n - 1 - i] = max(sigma[n - 1 - i], v)
    return sigma


def draw_box_edges(ax, x, y, z):
    xmin, xmax = x[0], x[-1]
    ymin, ymax = y[0], y[-1]
    zmin, zmax = z[0], z[-1]

    edge_color = "0.35"
    edge_alpha = 0.42
    edge_width = 0.65

    for yy in (ymin, ymax):
        for zz in (zmin, zmax):
            ax.plot([xmin, xmax], [yy, yy], [zz, zz], color=edge_color, alpha=edge_alpha, lw=edge_width)
    for xx in (xmin, xmax):
        for zz in (zmin, zmax):
            ax.plot([xx, xx], [ymin, ymax], [zz, zz], color=edge_color, alpha=edge_alpha, lw=edge_width)
    for xx in (xmin, xmax):
        for yy in (ymin, ymax):
            ax.plot([xx, xx], [yy, yy], [zmin, zmax], color=edge_color, alpha=edge_alpha, lw=edge_width)


def run_fdtd_3d_cartesian():
    # Physical constants
    c0 = 299792458.0
    mu0 = 4.0e-7 * np.pi
    eps0 = 1.0 / (mu0 * c0 * c0)

    # Source parameters
    f0 = 278.0e6
    w0 = 2.0 * np.pi * f0
    lam0 = c0 / f0

    # Grid settings: 10 cells per wavelength
    nx = ny = nz = 100
    dx = dy = dz = lam0 / 10.0

    # 3D CFL time step
    s = 0.95
    dt = s / (c0 * np.sqrt((1.0 / dx**2) + (1.0 / dy**2) + (1.0 / dz**2)))

    # Steps: enough to form clear radiation while keeping reflections moderate
    nsteps = 300

    # Field arrays (Yee leapfrog updates, stored on common index lattice)
    ex = np.zeros((nx, ny, nz), dtype=np.float64)
    ey = np.zeros((nx, ny, nz), dtype=np.float64)
    ez = np.zeros((nx, ny, nz), dtype=np.float64)
    hx = np.zeros((nx, ny, nz), dtype=np.float64)
    hy = np.zeros((nx, ny, nz), dtype=np.float64)
    hz = np.zeros((nx, ny, nz), dtype=np.float64)

    # Center z-directed soft source added to Ez
    ic, jc, kc = nx // 2, ny // 2, nz // 2

    # Mildly spread source to reduce point singularity
    ii = np.arange(nx)[:, None, None]
    jj = np.arange(ny)[None, :, None]
    kk = np.arange(nz)[None, None, :]
    src_sigma = 1.2
    src_profile = np.exp(
        -(
            ((ii - ic) ** 2 + (jj - jc) ** 2 + (kk - kc) ** 2)
            / (2.0 * src_sigma * src_sigma)
        )
    )
    src_profile /= np.max(src_profile)

    # Simplified absorbing boundary: 3D sponge layer (no periodic BC).
    # The profile is a per-step damping exponent, not a physical 1/s rate.
    sx = make_sponge_1d(nx, nbuf=14, smax=0.20)
    sy = make_sponge_1d(ny, nbuf=14, smax=0.20)
    sz = make_sponge_1d(nz, nbuf=14, smax=0.20)
    damp = np.exp(-(sx[:, None, None] + sy[None, :, None] + sz[None, None, :]))

    ce = dt / eps0
    ch = dt / mu0

    # RMS amplitude accumulation over the final window (use amplitude, not one-step snapshot)
    nrms = 80
    sumsq = np.zeros_like(ez)

    for n in range(nsteps):
        # H update from curl(E)
        # Hx^{n+1/2} = Hx^{n-1/2} - dt/mu * (dEz/dy - dEy/dz)
        hx[:, :-1, :-1] -= ch * (
            (ez[:, 1:, :-1] - ez[:, :-1, :-1]) / dy
            - (ey[:, :-1, 1:] - ey[:, :-1, :-1]) / dz
        )
        # Hy^{n+1/2} = Hy^{n-1/2} - dt/mu * (dEx/dz - dEz/dx)
        hy[:-1, :, :-1] -= ch * (
            (ex[:-1, :, 1:] - ex[:-1, :, :-1]) / dz
            - (ez[1:, :, :-1] - ez[:-1, :, :-1]) / dx
        )
        # Hz^{n+1/2} = Hz^{n-1/2} - dt/mu * (dEy/dx - dEx/dy)
        hz[:-1, :-1, :] -= ch * (
            (ey[1:, :-1, :] - ey[:-1, :-1, :]) / dx
            - (ex[:-1, 1:, :] - ex[:-1, :-1, :]) / dy
        )

        # E update from curl(H)
        # Ex^{n+1} = Ex^n + dt/eps * (dHz/dy - dHy/dz)
        ex[:, 1:, 1:] += ce * (
            (hz[:, 1:, 1:] - hz[:, :-1, 1:]) / dy
            - (hy[:, 1:, 1:] - hy[:, 1:, :-1]) / dz
        )
        # Ey^{n+1} = Ey^n + dt/eps * (dHx/dz - dHz/dx)
        ey[1:, :, 1:] += ce * (
            (hx[1:, :, 1:] - hx[1:, :, :-1]) / dz
            - (hz[1:, :, 1:] - hz[:-1, :, 1:]) / dx
        )
        # Ez^{n+1} = Ez^n + dt/eps * (dHy/dx - dHx/dy)
        ez[1:, 1:, :] += ce * (
            (hy[1:, 1:, :] - hy[:-1, 1:, :]) / dx
            - (hx[1:, 1:, :] - hx[1:, :-1, :]) / dy
        )

        # Center z-directed sinusoidal source (soft source)
        t = (n + 1) * dt
        ramp = 1.0 - np.exp(-((n + 1) / 35.0) ** 2)
        src = 0.25 * ramp * np.sin(w0 * t)
        ez += src * src_profile

        # Apply sponge damping to all fields
        ex *= damp
        ey *= damp
        ez *= damp
        hx *= damp
        hy *= damp
        hz *= damp

        if n >= nsteps - nrms:
            sumsq += ez * ez

    amp = np.sqrt(sumsq / nrms)
    vmax = np.percentile(amp, 99.5)
    norm = Normalize(vmin=0.0, vmax=vmax)
    cmap = cm.turbo

    # Coordinates (centered around source)
    x = (np.arange(nx) - ic) * dx
    y = (np.arange(ny) - jc) * dy
    z = (np.arange(nz) - kc) * dz

    # Build one cutaway figure from three center slices.  Each center plane is
    # cropped to a visible half/quadrant so the orthogonal slices do not hide
    # each other like three complete opaque sheets.
    fig = plt.figure(figsize=(10.2, 8.0), dpi=170)
    ax = fig.add_subplot(111, projection="3d")

    x_neg = slice(0, ic + 1)
    y_neg = slice(0, jc + 1)
    z_all = slice(0, nz)

    # x = center plane, cropped to the front half for this view.
    y2, z2 = np.meshgrid(y[y_neg], z[z_all], indexing="ij")
    x2 = np.full_like(y2, x[ic])
    c_x = cmap(norm(amp[ic, y_neg, z_all]))
    ax.plot_surface(
        x2, y2, z2, facecolors=c_x, linewidth=0, antialiased=False, shade=False, alpha=0.97
    )

    # y = center plane, cropped to the left half for this view.
    x3, z3 = np.meshgrid(x[x_neg], z[z_all], indexing="ij")
    y3 = np.full_like(x3, y[jc])
    c_y = cmap(norm(amp[x_neg, jc, z_all]))
    ax.plot_surface(
        x3, y3, z3, facecolors=c_y, linewidth=0, antialiased=False, shade=False, alpha=0.97
    )

    # z = center plane, cropped to the visible quadrant between the two vertical cuts.
    x4, y4 = np.meshgrid(x[x_neg], y[y_neg], indexing="ij")
    z4 = np.full_like(x4, z[kc])
    c_z = cmap(norm(amp[x_neg, y_neg, kc]))
    ax.plot_surface(
        x4, y4, z4, facecolors=c_z, linewidth=0, antialiased=False, shade=False, alpha=0.98
    )

    ax.set_xlabel("x (m)")
    ax.set_ylabel("y (m)")
    ax.set_zlabel("z (m)")
    ax.set_title("3D Cartesian FDTD Ez RMS Cutaway Slices")
    ax.set_xlim(x[0], x[-1])
    ax.set_ylim(y[0], y[-1])
    ax.set_zlim(z[0], z[-1])
    ax.set_box_aspect((1.0, 1.0, 1.0))
    ax.view_init(elev=24, azim=-135)
    draw_box_edges(ax, x, y, z)

    sm = cm.ScalarMappable(norm=norm, cmap=cmap)
    sm.set_array([])
    cbar = fig.colorbar(sm, ax=ax, shrink=0.72, pad=0.07)
    cbar.set_label("Ez amplitude (RMS, V/m)")

    plt.tight_layout()
    plt.savefig("fdtd_3d_cartesian_ez_slices.png", dpi=230)
    plt.close(fig)


if __name__ == "__main__":
    run_fdtd_3d_cartesian()
