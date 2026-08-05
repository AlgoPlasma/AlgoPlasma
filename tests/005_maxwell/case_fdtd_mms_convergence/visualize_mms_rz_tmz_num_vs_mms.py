#!/usr/bin/env python3
"""Generate a two-column GIF for MMS 2D RZ TMz.

Left: numerical Ez from FDTD run.
Right: MMS exact Ez at the same time.
"""

from __future__ import annotations

import io
from pathlib import Path

import imageio.v2 as imageio
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


def load_frames(bin_path: Path):
    with bin_path.open("rb") as f:
        nr = int(np.fromfile(f, dtype=np.int32, count=1)[0])
        nz = int(np.fromfile(f, dtype=np.int32, count=1)[0])
        viz_stride = int(np.fromfile(f, dtype=np.int32, count=1)[0])
        ncell = (nr + 1) * (nz + 1)

        frames = []
        while True:
            step_raw = np.fromfile(f, dtype=np.int32, count=1)
            if step_raw.size == 0:
                break
            t_raw = np.fromfile(f, dtype=np.float64, count=1)
            ez_num = np.fromfile(f, dtype=np.float64, count=ncell)
            ez_mms = np.fromfile(f, dtype=np.float64, count=ncell)
            if t_raw.size == 0 or ez_num.size < ncell or ez_mms.size < ncell:
                break

            ez_num = ez_num.reshape((nr + 1, nz + 1), order="F")
            ez_mms = ez_mms.reshape((nr + 1, nz + 1), order="F")
            frames.append((int(step_raw[0]), float(t_raw[0]), ez_num, ez_mms))

    return nr, nz, viz_stride, frames


def main() -> None:
    here = Path(__file__).resolve().parent
    out_dir = here / "figures"
    out_dir.mkdir(exist_ok=True)

    bin_path = here / "mms_rz_tmz_viz_fine.bin"
    if not bin_path.exists():
        raise SystemExit(
            "Missing mms_rz_tmz_viz_fine.bin. "
            "Please run ./test_mms_2d_rz_tmz_convergence.out first."
        )

    nr, nz, viz_stride, frames = load_frames(bin_path)
    if not frames:
        raise SystemExit("No frames found in mms_rz_tmz_viz_fine.bin.")

    vmax_num = max(float(np.max(np.abs(ez_num))) for _, _, ez_num, _ in frames)
    vmax_mms = max(float(np.max(np.abs(ez_mms))) for _, _, _, ez_mms in frames)
    vmax = max(vmax_num, vmax_mms)

    gif_frames = []
    for step, t, ez_num, ez_mms in frames:
        fig, axes = plt.subplots(1, 2, figsize=(10.5, 4.4), constrained_layout=True)
        extent = (0.0, 1.0, 0.0, 1.0)

        im0 = axes[0].imshow(
            ez_num.T,
            origin="lower",
            extent=extent,
            cmap="RdBu_r",
            vmin=-vmax,
            vmax=vmax,
            aspect="auto",
        )
        axes[0].set_title("Numerical Ez (FDTD)")
        axes[0].set_xlabel("r")
        axes[0].set_ylabel("z")
        fig.colorbar(im0, ax=axes[0], fraction=0.046, pad=0.02)

        im1 = axes[1].imshow(
            ez_mms.T,
            origin="lower",
            extent=extent,
            cmap="RdBu_r",
            vmin=-vmax,
            vmax=vmax,
            aspect="auto",
        )
        axes[1].set_title("MMS Ez (Exact)")
        axes[1].set_xlabel("r")
        axes[1].set_ylabel("z")
        fig.colorbar(im1, ax=axes[1], fraction=0.046, pad=0.02)

        fig.suptitle(
            f"2D RZ TMz MMS (fine level nr={nr}, nz={nz}) | step={step}, t={t:.4e}, stride={viz_stride}",
            fontsize=12,
        )

        buf = io.BytesIO()
        fig.savefig(buf, format="png", dpi=140)
        plt.close(fig)
        buf.seek(0)
        gif_frames.append(imageio.imread(buf))

    out_gif = out_dir / "mms_rz_tmz_num_vs_mms.gif"
    imageio.mimsave(out_gif, gif_frames, duration=0.09, loop=0)
    print(f"Saved: {out_gif}")


if __name__ == "__main__":
    main()
