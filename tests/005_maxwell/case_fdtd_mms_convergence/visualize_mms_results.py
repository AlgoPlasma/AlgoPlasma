#!/usr/bin/env python3
"""Visualize MMS convergence logs for tests/005_maxwell/case_fdtd_mms_convergence.

Outputs:
  - figures/mms_error_comparison.png
  - figures/mms_observed_orders.png
  - figures/m1_axis_ez_timeseries.gif
"""

from __future__ import annotations

import io
import math
import re
from pathlib import Path

import imageio.v2 as imageio
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


LOG_FILES = [
    "test_mms_3d_cartesian_convergence.log",
    "test_mms_2d_rz_tmz_convergence.log",
    "test_mms_2d_rz_tez_convergence.log",
    "test_mms_3d_cyl_m0_convergence.log",
    "test_mms_3d_cyl_m1_convergence.log",
]


def parse_floats(text: str) -> list[float]:
    return [float(x.replace("D", "E")) for x in re.findall(r"[-+]?\d+\.\d+(?:[EeDd][-+]?\d+)?", text)]


def parse_case_log(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="ignore")
    lines = text.splitlines()

    title = path.stem
    for line in lines:
        m = re.search(r"===\s*MMS Convergence:\s*(.*?)\s*===", line)
        if m:
            title = m.group(1).strip()
            break

    levels = []
    for line in lines:
        m = re.search(r"^\s*level\s+(?:nx|nr)\s*=\s*(\d+)", line)
        if m:
            levels.append(int(m.group(1)))
    levels = levels[:3]

    l2 = []
    linf = []
    for i, line in enumerate(lines):
        if line.strip().startswith("L2  :"):
            l2 = parse_floats(line)[:3]
            if i + 1 < len(lines):
                linf = parse_floats(lines[i + 1])[:3]
            break

    l2_order = []
    linf_order = []
    for line in lines:
        if "Observed order L2" in line:
            l2_order = parse_floats(line)[:2]
        if "Observed order Linf" in line:
            linf_order = parse_floats(line)[:2]

    if not levels or not l2 or not linf:
        raise ValueError(f"Failed to parse required data from {path}")

    return {
        "title": title,
        "levels": np.array(levels, dtype=float),
        "h": 1.0 / np.array(levels, dtype=float),
        "l2": np.array(l2, dtype=float),
        "linf": np.array(linf, dtype=float),
        "l2_order": np.array(l2_order, dtype=float),
        "linf_order": np.array(linf_order, dtype=float),
    }


def plot_error_comparison(cases: list[dict], out_png: Path) -> None:
    fig, axes = plt.subplots(1, 2, figsize=(13, 5), constrained_layout=True)
    ax_l2, ax_linf = axes

    for case in cases:
        label = case["title"]
        ax_l2.loglog(case["h"], case["l2"], marker="o", linewidth=2, label=label)
        ax_linf.loglog(case["h"], case["linf"], marker="s", linewidth=2, label=label)

    ax_l2.set_title("Combined L2 Error vs Grid Size")
    ax_l2.set_xlabel("h (1 / radial-or-x resolution)")
    ax_l2.set_ylabel("Combined L2 Error")
    ax_l2.grid(True, which="both", alpha=0.3)

    ax_linf.set_title("Combined Linf Error vs Grid Size")
    ax_linf.set_xlabel("h (1 / radial-or-x resolution)")
    ax_linf.set_ylabel("Combined Linf Error")
    ax_linf.grid(True, which="both", alpha=0.3)
    ax_linf.legend(loc="best", fontsize=8)

    fig.suptitle("005_maxwell MMS Convergence Error Comparison", fontsize=13)
    fig.savefig(out_png, dpi=180)
    plt.close(fig)


def plot_observed_orders(cases: list[dict], out_png: Path) -> None:
    labels = [c["title"] for c in cases]
    l2_mean = [float(np.mean(c["l2_order"])) if c["l2_order"].size else math.nan for c in cases]
    linf_mean = [float(np.mean(c["linf_order"])) if c["linf_order"].size else math.nan for c in cases]

    x = np.arange(len(labels))
    w = 0.35

    fig, ax = plt.subplots(figsize=(12, 5), constrained_layout=True)
    ax.bar(x - w / 2, l2_mean, width=w, label="L2 observed order")
    ax.bar(x + w / 2, linf_mean, width=w, label="Linf observed order")
    ax.axhline(2.0, color="k", linestyle="--", linewidth=1, alpha=0.5)
    ax.axhline(1.8, color="tab:green", linestyle=":", linewidth=1, alpha=0.7, label="L2 pass threshold")
    ax.axhline(1.5, color="tab:orange", linestyle=":", linewidth=1, alpha=0.7, label="Linf pass threshold")
    ax.set_ylabel("Order")
    ax.set_title("Observed Convergence Order (mean of h->h/2 and h/2->h/4)")
    ax.set_xticks(x)
    ax.set_xticklabels(labels, rotation=20, ha="right")
    ax.set_ylim(0.0, max(2.4, np.nanmax([*l2_mean, *linf_mean]) + 0.2))
    ax.grid(True, axis="y", alpha=0.3)
    ax.legend(loc="upper right", fontsize=8)

    fig.savefig(out_png, dpi=180)
    plt.close(fig)


def load_axis_series(dat_file: Path) -> tuple[np.ndarray, np.ndarray]:
    arr = np.loadtxt(dat_file, comments="#")
    t = arr[:, 1]
    y = arr[:, 2]
    # Semilogy-safe lower bound.
    y = np.maximum(np.abs(y), 1e-30)
    return t, y


def make_axis_gif(dat_files: list[Path], out_gif: Path) -> None:
    series = []
    labels = []
    for p in dat_files:
        t, y = load_axis_series(p)
        m = re.search(r"nr(\d+)_nphi(\d+)_nz(\d+)", p.stem)
        if m:
            labels.append(f"nr={m.group(1)}, nphi={m.group(2)}, nz={m.group(3)}")
        else:
            labels.append(p.stem)
        series.append((t, y))

    t_max = max(s[0][-1] for s in series)
    y_max = max(float(np.max(s[1])) for s in series) * 1.15

    n_frames = 90
    frames = []
    for f in range(1, n_frames + 1):
        progress = f / n_frames
        fig, ax = plt.subplots(figsize=(8.5, 4.5), constrained_layout=True)
        for (t, y), label in zip(series, labels, strict=True):
            n = max(1, int(progress * len(t)))
            ax.semilogy(t[:n], y[:n], linewidth=2, label=label)

        ax.set_xlim(0.0, t_max)
        ax.set_ylim(1e-30, y_max)
        ax.grid(True, which="both", alpha=0.3)
        ax.set_xlabel("t")
        ax.set_ylabel(r"$|E_z|_{\max}$ on axis")
        ax.set_title("MMS 3D Cylindrical m=1: Axis Ez Growth (all grid levels)")
        ax.legend(loc="upper left", fontsize=8)

        buf = io.BytesIO()
        fig.savefig(buf, format="png", dpi=140)
        plt.close(fig)
        buf.seek(0)
        frames.append(imageio.imread(buf))

    imageio.mimsave(out_gif, frames, duration=0.08, loop=0)


def main() -> None:
    here = Path(__file__).resolve().parent
    out_dir = here / "figures"
    out_dir.mkdir(exist_ok=True)

    cases = []
    for log_name in LOG_FILES:
        p = here / log_name
        if p.exists():
            cases.append(parse_case_log(p))

    if not cases:
        raise SystemExit("No MMS logs found. Please run: bash run.sh")

    plot_error_comparison(cases, out_dir / "mms_error_comparison.png")
    plot_observed_orders(cases, out_dir / "mms_observed_orders.png")

    axis_files = sorted(here.glob("axis_ez_timeseries_m1_nr*_nphi*_nz*.dat"))
    if axis_files:
        make_axis_gif(axis_files, out_dir / "m1_axis_ez_timeseries.gif")

    print(f"Saved figures to: {out_dir}")
    for p in sorted(out_dir.glob("*")):
        print(f"  - {p.name}")


if __name__ == "__main__":
    main()
