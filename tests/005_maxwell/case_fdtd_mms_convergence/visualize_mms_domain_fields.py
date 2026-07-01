#!/usr/bin/env python3
"""Create domain-level MMS field animations for 005_maxwell."""

from __future__ import annotations

import io
from pathlib import Path

import imageio.v2 as imageio
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


def cartesian_emag_xy(x: np.ndarray, y: np.ndarray, t: float) -> np.ndarray:
    lx = ly = lz = 1.0
    c0 = 1.0
    omega = 0.7 * c0 * (2.0 * np.pi / lx)
    kx = 2.0 * np.pi / lx
    ky = 2.0 * np.pi / ly
    kz = 2.0 * np.pi / lz
    z = 0.5
    swt = np.sin(omega * t)
    cwt = np.cos(omega * t)

    ex = np.sin(kx * x) * np.cos(ky * y) * np.cos(kz * z) * cwt
    ey = -0.8 * np.cos(kx * x) * np.sin(ky * y) * np.cos(kz * z) * cwt
    ez = 0.6 * np.cos(kx * x) * np.cos(ky * y) * np.sin(kz * z) * cwt
    hx = 0.7 * np.cos(kx * x) * np.sin(ky * y) * np.sin(kz * z) * swt
    hy = 0.5 * np.sin(kx * x) * np.cos(ky * y) * np.sin(kz * z) * swt
    hz = -0.9 * np.sin(kx * x) * np.sin(ky * y) * np.cos(kz * z) * swt
    _ = (hx, hy, hz)  # keep parity with MMS fields, though not plotted.
    return np.sqrt(ex * ex + ey * ey + ez * ez)


def rz_tmz_ez(r: np.ndarray, z: np.ndarray, t: float) -> np.ndarray:
    rmax = lz = 1.0
    c0 = 1.0
    omega = 0.6 * c0 * (np.pi / lz)
    q = (1.0 - (r / rmax) ** 2) ** 2
    s2 = np.sin(2.0 * np.pi * z / lz)
    cwt = np.cos(omega * t)
    return q * s2 * cwt


def rz_tez_hz(r: np.ndarray, z: np.ndarray, t: float) -> np.ndarray:
    rmax = lz = 1.0
    c0 = 1.0
    omega = 0.6 * c0 * (np.pi / lz)
    q = (1.0 - (r / rmax) ** 2) ** 2
    c1 = np.cos(np.pi * z / lz)
    swt = np.sin(omega * t)
    return q * c1 * swt


def cyl_m0_ez(r: np.ndarray, z: np.ndarray, t: float) -> np.ndarray:
    rmax = lz = 1.0
    c0 = 1.0
    omega = 0.6 * c0 * (np.pi / lz)
    q = (1.0 - (r / rmax) ** 2) ** 2
    s1 = np.sin(np.pi * z / lz)
    cwt = np.cos(omega * t)
    return q * s1 * cwt


def cyl_m1_ez_phi0(r: np.ndarray, z: np.ndarray, t: float) -> np.ndarray:
    rmax = lz = 1.0
    c0 = 1.0
    omega = 0.6 * c0 * (np.pi / lz)
    g = r * (1.0 - (r / rmax) ** 2)
    s2 = np.sin(2.0 * np.pi * z / lz)
    cwt = np.cos(omega * t)
    cp = 1.0  # phi = 0
    return g * s2 * cp * cwt


def max_abs(arrays: list[np.ndarray]) -> float:
    return max(float(np.max(np.abs(a))) for a in arrays)


def main() -> None:
    here = Path(__file__).resolve().parent
    out_dir = here / "figures"
    out_dir.mkdir(exist_ok=True)

    # Use the same coarse-level physical final time as MMS tests.
    c0 = 1.0
    # Cartesian coarse dt and tfinal.
    nx = ny = nz = 16
    dt_cart = 0.20 / (c0 * np.sqrt((nx / 1.0) ** 2 + (ny / 1.0) ** 2 + (nz / 1.0) ** 2))
    tfinal = 10 * dt_cart

    nframes = 80
    times = np.linspace(0.0, tfinal, nframes)

    # Visualization grids (continuous field sampling).
    x = np.linspace(0.0, 1.0, 180)
    y = np.linspace(0.0, 1.0, 180)
    X, Y = np.meshgrid(x, y, indexing="xy")

    r = np.linspace(0.0, 1.0, 160)
    z = np.linspace(0.0, 1.0, 220)
    R, Z = np.meshgrid(r, z, indexing="xy")

    # Static color ranges.
    emag0 = cartesian_emag_xy(X, Y, 0.0)
    te0 = rz_tmz_ez(R, Z, 0.0)
    tm0 = rz_tez_hz(R, Z, tfinal / 4.0)
    m00 = cyl_m0_ez(R, Z, 0.0)
    m10 = cyl_m1_ez_phi0(R, Z, 0.0)

    vmax_emag = float(np.max(emag0))
    vmax_te = max_abs([te0])
    vmax_tm = max_abs([tm0])
    vmax_m0 = max_abs([m00])
    vmax_m1 = max_abs([m10])

    frames = []
    for t in times:
        fig, axes = plt.subplots(3, 2, figsize=(12.5, 10), constrained_layout=True)
        ax = axes.ravel()

        im0 = ax[0].imshow(
            cartesian_emag_xy(X, Y, t),
            origin="lower",
            extent=(0, 1, 0, 1),
            cmap="viridis",
            vmin=0.0,
            vmax=vmax_emag,
            aspect="auto",
        )
        ax[0].set_title("3D Cartesian MMS: |E| on z=0.5 plane")
        ax[0].set_xlabel("x")
        ax[0].set_ylabel("y")
        fig.colorbar(im0, ax=ax[0], fraction=0.046, pad=0.02)

        im1 = ax[1].imshow(
            rz_tmz_ez(R, Z, t),
            origin="lower",
            extent=(0, 1, 0, 1),
            cmap="RdBu_r",
            vmin=-vmax_te,
            vmax=vmax_te,
            aspect="auto",
        )
        ax[1].set_title("2D RZ TMz MMS: Ez(r,z)")
        ax[1].set_xlabel("r")
        ax[1].set_ylabel("z")
        fig.colorbar(im1, ax=ax[1], fraction=0.046, pad=0.02)

        im2 = ax[2].imshow(
            rz_tez_hz(R, Z, t),
            origin="lower",
            extent=(0, 1, 0, 1),
            cmap="RdBu_r",
            vmin=-vmax_tm,
            vmax=vmax_tm,
            aspect="auto",
        )
        ax[2].set_title("2D RZ TEz MMS: Hz(r,z)")
        ax[2].set_xlabel("r")
        ax[2].set_ylabel("z")
        fig.colorbar(im2, ax=ax[2], fraction=0.046, pad=0.02)

        im3 = ax[3].imshow(
            cyl_m0_ez(R, Z, t),
            origin="lower",
            extent=(0, 1, 0, 1),
            cmap="RdBu_r",
            vmin=-vmax_m0,
            vmax=vmax_m0,
            aspect="auto",
        )
        ax[3].set_title("3D Cyl m=0 MMS: Ez(r,z)")
        ax[3].set_xlabel("r")
        ax[3].set_ylabel("z")
        fig.colorbar(im3, ax=ax[3], fraction=0.046, pad=0.02)

        im4 = ax[4].imshow(
            cyl_m1_ez_phi0(R, Z, t),
            origin="lower",
            extent=(0, 1, 0, 1),
            cmap="RdBu_r",
            vmin=-vmax_m1,
            vmax=vmax_m1,
            aspect="auto",
        )
        ax[4].set_title("3D Cyl m=1 MMS: Ez(r,z) at phi=0")
        ax[4].set_xlabel("r")
        ax[4].set_ylabel("z")
        fig.colorbar(im4, ax=ax[4], fraction=0.046, pad=0.02)

        ax[5].axis("off")
        ax[5].text(
            0.02,
            0.85,
            "MMS Domain-Scale Field Evolution\n"
            "Fields are sampled from manufactured exact solutions\n"
            "using the same physical settings as 005_maxwell MMS tests.\n\n"
            f"t = {t:.5e}\n"
            f"t_final = {tfinal:.5e}",
            fontsize=12,
            va="top",
        )

        fig.suptitle("005_maxwell MMS: Whole-Domain Electromagnetic Field Evolution", fontsize=14)

        buf = io.BytesIO()
        fig.savefig(buf, format="png", dpi=140)
        plt.close(fig)
        buf.seek(0)
        frames.append(imageio.imread(buf))

    out_gif = out_dir / "mms_domain_overview.gif"
    imageio.mimsave(out_gif, frames, duration=0.09, loop=0)
    print(f"Saved: {out_gif}")


if __name__ == "__main__":
    main()
