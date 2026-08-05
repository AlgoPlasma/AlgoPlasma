#!/usr/bin/env python3
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


def run_fdtd_2d_tm():
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

    # Fields (TMz: non-zero Hx, Hy, Ez)
    ez = np.zeros((nx, ny), dtype=np.float64)
    hx = np.zeros((nx, ny - 1), dtype=np.float64)
    hy = np.zeros((nx - 1, ny), dtype=np.float64)

    # First-order Mur ABC coefficient
    mur_x = (c0 * dt - dx) / (c0 * dt + dx)
    mur_y = (c0 * dt - dy) / (c0 * dt + dy)

    for n in range(nsteps):
        ez_prev = ez.copy()

        # Update Hx, Hy from Ez
        hx -= (dt / (mu0 * dy)) * (ez[:, 1:] - ez[:, :-1])
        hy += (dt / (mu0 * dx)) * (ez[1:, :] - ez[:-1, :])

        # Update Ez interior from Hx, Hy
        curl_h = (hy[1:, 1:-1] - hy[:-1, 1:-1]) / dx - (hx[1:-1, 1:] - hx[1:-1, :-1]) / dy
        ez[1:-1, 1:-1] += (dt / eps0) * curl_h

        # Add center sinusoidal source to Ez
        t = (n + 1) * dt
        ez[src_i, src_j] += np.sin(w0 * t)

        # Mur ABC on four edges
        ez[0, 1:-1] = ez_prev[1, 1:-1] + mur_x * (ez[1, 1:-1] - ez_prev[0, 1:-1])
        ez[-1, 1:-1] = ez_prev[-2, 1:-1] + mur_x * (ez[-2, 1:-1] - ez_prev[-1, 1:-1])
        ez[1:-1, 0] = ez_prev[1:-1, 1] + mur_y * (ez[1:-1, 1] - ez_prev[1:-1, 0])
        ez[1:-1, -1] = ez_prev[1:-1, -2] + mur_y * (ez[1:-1, -2] - ez_prev[1:-1, -1])

        # Corner treatment
        ez[0, 0] = 0.5 * (ez[1, 0] + ez[0, 1])
        ez[0, -1] = 0.5 * (ez[1, -1] + ez[0, -2])
        ez[-1, 0] = 0.5 * (ez[-2, 0] + ez[-1, 1])
        ez[-1, -1] = 0.5 * (ez[-2, -1] + ez[-1, -2])

    # Coordinate arrays for plotting
    x = np.arange(nx) * dx
    y = np.arange(ny) * dy

    # Plot a single, recognizable 2D |Ez| field map
    plt.figure(figsize=(8.5, 7.2), dpi=160)
    img = plt.imshow(
        np.abs(ez).T,
        origin="lower",
        extent=[x[0], x[-1], y[0], y[-1]],
        cmap="turbo",
        interpolation="bicubic",
        aspect="equal",
    )
    plt.xlabel("x (m)")
    plt.ylabel("y (m)")
    plt.title(f"2D TM FDTD |Ez| (center sinusoidal source, f = 278 MHz, step = {nsteps})")
    cbar = plt.colorbar(img, pad=0.02)
    cbar.set_label("|Ez| (V/m)")
    plt.tight_layout()
    plt.savefig("fdtd_2d_tm_cylindrical_wave.png", dpi=220)
    plt.close()


if __name__ == "__main__":
    run_fdtd_2d_tm()
