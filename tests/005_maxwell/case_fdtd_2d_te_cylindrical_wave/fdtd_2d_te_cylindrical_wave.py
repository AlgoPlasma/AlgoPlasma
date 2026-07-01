#!/usr/bin/env python3
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


def run_fdtd_2d_te():
    # Physical constants
    c0 = 299792458.0
    mu0 = 4.0e-7 * np.pi
    eps0 = 1.0 / (mu0 * c0 * c0)

    # Grid and time settings
    nx, ny = 201, 201
    dx = dy = 0.054
    dt = dx / (c0 * np.sqrt(2.0))
    nsteps = 190

    # Source
    f0 = 278.0e6
    w0 = 2.0 * np.pi * f0
    src_i = nx // 2
    src_j = ny // 2

    # Fields (TEz: non-zero Ex, Ey, Hz)
    hz = np.zeros((nx, ny), dtype=np.float64)
    ex = np.zeros((nx, ny - 1), dtype=np.float64)
    ey = np.zeros((nx - 1, ny), dtype=np.float64)

    # First-order Mur ABC coefficient
    mur_x = (c0 * dt - dx) / (c0 * dt + dx)
    mur_y = (c0 * dt - dy) / (c0 * dt + dy)

    for n in range(nsteps):
        hz_prev = hz.copy()

        # Update Ex, Ey from Hz using the same sign convention as E03 Cartesian FDTD.
        ex += (dt / (eps0 * dy)) * (hz[:, 1:] - hz[:, :-1])
        ey -= (dt / (eps0 * dx)) * (hz[1:, :] - hz[:-1, :])

        # Update Hz interior from Ex, Ey
        curl_e = (ey[1:, 1:-1] - ey[:-1, 1:-1]) / dx - (ex[1:-1, 1:] - ex[1:-1, :-1]) / dy
        hz[1:-1, 1:-1] -= (dt / mu0) * curl_e

        # Add center sinusoidal source to Hz
        t = (n + 1) * dt
        hz[src_i, src_j] += np.sin(w0 * t)

        # Mur ABC on four edges
        hz[0, 1:-1] = hz_prev[1, 1:-1] + mur_x * (hz[1, 1:-1] - hz_prev[0, 1:-1])
        hz[-1, 1:-1] = hz_prev[-2, 1:-1] + mur_x * (hz[-2, 1:-1] - hz_prev[-1, 1:-1])
        hz[1:-1, 0] = hz_prev[1:-1, 1] + mur_y * (hz[1:-1, 1] - hz_prev[1:-1, 0])
        hz[1:-1, -1] = hz_prev[1:-1, -2] + mur_y * (hz[1:-1, -2] - hz_prev[1:-1, -1])

        # Corner treatment
        hz[0, 0] = 0.5 * (hz[1, 0] + hz[0, 1])
        hz[0, -1] = 0.5 * (hz[1, -1] + hz[0, -2])
        hz[-1, 0] = 0.5 * (hz[-2, 0] + hz[-1, 1])
        hz[-1, -1] = 0.5 * (hz[-2, -1] + hz[-1, -2])

    # Coordinates for plotting
    x = np.arange(nx) * dx
    y = np.arange(ny) * dy

    # Plot a single, recognizable 2D |Hz| field map
    plt.figure(figsize=(8.5, 7.2), dpi=160)
    img = plt.imshow(
        np.abs(hz).T,
        origin="lower",
        extent=[x[0], x[-1], y[0], y[-1]],
        cmap="turbo",
        interpolation="bicubic",
        aspect="equal",
    )
    plt.xlabel("x (m)")
    plt.ylabel("y (m)")
    plt.title(f"2D TE FDTD |Hz| (center sinusoidal source, f = 278 MHz, step = {nsteps})")
    cbar = plt.colorbar(img, pad=0.02)
    cbar.set_label("|Hz| (A/m)")
    plt.tight_layout()
    plt.savefig("fdtd_2d_te_cylindrical_wave.png", dpi=220)
    plt.close()


if __name__ == "__main__":
    run_fdtd_2d_te()
