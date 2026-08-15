#!/usr/bin/env python3
"""Generate a 5x2 GIF for MMS cases: left numerical field, right error field."""

from __future__ import annotations

import io
from dataclasses import dataclass
from pathlib import Path

import imageio.v2 as imageio
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


@dataclass(frozen=True)
class CaseConfig:
    name: str
    path: str
    loader: str
    x_label: str
    y_label: str


def load_frames_rz_like(bin_path: Path):
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
            num_raw = np.fromfile(f, dtype=np.float64, count=ncell)
            exact_raw = np.fromfile(f, dtype=np.float64, count=ncell)
            if t_raw.size == 0 or num_raw.size < ncell or exact_raw.size < ncell:
                break
            num = num_raw.reshape((nr + 1, nz + 1), order="F")
            exact = exact_raw.reshape((nr + 1, nz + 1), order="F")
            frames.append((int(step_raw[0]), float(t_raw[0]), num, exact))

    return viz_stride, frames


def load_frames_cart(bin_path: Path):
    with bin_path.open("rb") as f:
        nx = int(np.fromfile(f, dtype=np.int32, count=1)[0])
        nz = int(np.fromfile(f, dtype=np.int32, count=1)[0])
        viz_stride = int(np.fromfile(f, dtype=np.int32, count=1)[0])
        ncell = nx * nz

        frames = []
        while True:
            step_raw = np.fromfile(f, dtype=np.int32, count=1)
            if step_raw.size == 0:
                break
            t_raw = np.fromfile(f, dtype=np.float64, count=1)
            num_raw = np.fromfile(f, dtype=np.float64, count=ncell)
            exact_raw = np.fromfile(f, dtype=np.float64, count=ncell)
            if t_raw.size == 0 or num_raw.size < ncell or exact_raw.size < ncell:
                break
            num = num_raw.reshape((nx, nz), order="F")
            exact = exact_raw.reshape((nx, nz), order="F")
            frames.append((int(step_raw[0]), float(t_raw[0]), num, exact))

    return viz_stride, frames


def max_abs(arrays):
    return max(float(np.max(np.abs(a))) for a in arrays)


def main() -> None:
    here = Path(__file__).resolve().parent
    out_dir = here / "figures"
    out_dir.mkdir(exist_ok=True)

    cases = [
        CaseConfig("3D Cartesian (Ez, y-mid)", "mms_cart3d_viz_fine.bin", "cart", "x", "z"),
        CaseConfig("2D RZ TMz (Ez)", "mms_rz_tmz_viz_fine.bin", "rz", "r", "z"),
        CaseConfig("2D RZ TEz (Ephi)", "mms_rz_tez_viz_fine.bin", "rz", "r", "z"),
        CaseConfig("3D Cyl m=0 (Ez, phi=0)", "mms_cyl_m0_viz_fine.bin", "rz", "r", "z"),
        CaseConfig("3D Cyl m=1 (Ez, phi=0)", "mms_cyl_m1_viz_fine.bin", "rz", "r", "z"),
    ]

    loaded = []
    for case in cases:
        p = here / case.path
        if not p.exists():
            raise SystemExit(f"Missing {case.path}. Please run the corresponding MMS test first.")
        if case.loader == "cart":
            stride, frames = load_frames_cart(p)
        else:
            stride, frames = load_frames_rz_like(p)
        if not frames:
            raise SystemExit(f"No frames found in {case.path}.")
        loaded.append((case, stride, frames))

    nframes_common = min(len(frames) for _, _, frames in loaded)
    if nframes_common < 2:
        raise SystemExit("Not enough frames to generate GIF.")

    sampled_idx = []
    for _, _, frames in loaded:
        idx = np.linspace(0, len(frames) - 1, nframes_common)
        sampled_idx.append(np.rint(idx).astype(int))

    vmax_num = []
    vmax_err = []
    for (_, _, frames), idx in zip(loaded, sampled_idx):
        num_series = [frames[i][2] for i in idx]
        err_series = [frames[i][2] - frames[i][3] for i in idx]
        vmax_num.append(max_abs(num_series))
        vmax_err.append(max_abs(err_series))

    gif_frames = []
    for iframe in range(nframes_common):
        fig, axes = plt.subplots(5, 2, figsize=(11.2, 16.8), constrained_layout=True)

        for row, ((case, stride, frames), idx) in enumerate(zip(loaded, sampled_idx)):
            step, t, num, exact = frames[idx[iframe]]
            err = num - exact

            ax_l = axes[row, 0]
            ax_r = axes[row, 1]

            ax_l.imshow(
                num.T,
                origin="lower",
                extent=(0.0, 1.0, 0.0, 1.0),
                cmap="RdBu_r",
                vmin=-vmax_num[row],
                vmax=vmax_num[row],
                aspect="auto",
            )
            ax_l.set_title(f"{case.name} | Numerical")
            ax_l.set_xlabel(case.x_label)
            ax_l.set_ylabel(case.y_label)

            ax_r.imshow(
                err.T,
                origin="lower",
                extent=(0.0, 1.0, 0.0, 1.0),
                cmap="RdBu_r",
                vmin=-vmax_err[row],
                vmax=vmax_err[row],
                aspect="auto",
            )
            ax_r.set_title(
                f"{case.name} | Error (Num-Exact), step={step}, t={t:.4e}, stride={stride}"
            )
            ax_r.set_xlabel(case.x_label)
            ax_r.set_ylabel(case.y_label)

        fig.suptitle("005_maxwell MMS: 5 Cases (Left: Numerical, Right: Error)", fontsize=13)

        buf = io.BytesIO()
        fig.savefig(buf, format="png", dpi=120)
        plt.close(fig)
        buf.seek(0)
        gif_frames.append(imageio.imread(buf))

    out_gif = out_dir / "mms_5cases_num_vs_error.gif"
    imageio.mimsave(out_gif, gif_frames, duration=0.09, loop=0)
    print(f"Saved: {out_gif}")


if __name__ == "__main__":
    main()
