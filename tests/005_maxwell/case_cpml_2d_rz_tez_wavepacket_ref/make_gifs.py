#!/usr/bin/env python3
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation, PillowWriter
import numpy as np

from plot_results import CASES, probe_index, read_case_info, read_field


def make_case_gif(case, info, prefix="ephi", label="Ephi", fps=8):
    files = sorted(Path(".").glob(f"{prefix}_snapshot_{case}_*.dat"))
    if not files:
        return

    steps = [int(path.stem.rsplit("_", 1)[1]) for path in files]
    fields = [read_field(path) for path in files]
    vmax = max(np.percentile(np.abs(field), 99.5) for field in fields)
    vmax = max(vmax, 1.0e-300)

    npml = info.get("npml", 12)
    ip, kp = probe_index(case, info)

    fig, ax = plt.subplots(figsize=(6.2, 5.6), constrained_layout=True)
    im = ax.imshow(fields[0].T, origin="lower", cmap="RdBu_r", vmin=-vmax, vmax=vmax, aspect="equal")
    ax.axvline(npml, color="black", lw=0.8, alpha=0.45)
    ax.axvline(fields[0].shape[0]-npml, color="black", lw=0.8, alpha=0.45)
    ax.axhline(npml, color="black", lw=0.8, alpha=0.45)
    ax.axhline(fields[0].shape[1]-npml, color="black", lw=0.8, alpha=0.45)
    ax.scatter(ip, kp, s=42, marker="o", facecolor="yellow", edgecolor="black", linewidth=0.8, zorder=5)
    ax.text(ip+3, kp+3, "probe", color="black", fontsize=8, weight="bold", zorder=6)
    title = ax.set_title(f"{case}, {label}, n={steps[0]}")
    ax.set_xlabel("r index")
    ax.set_ylabel("z index")
    fig.colorbar(im, ax=ax, label=label)

    def update(frame):
        im.set_data(fields[frame].T)
        title.set_text(f"{case}, {label}, n={steps[frame]}")
        return im, title

    animation = FuncAnimation(fig, update, frames=len(fields), interval=1000/fps, blit=False)
    animation.save(f"{prefix}_animation_{case}.gif", writer=PillowWriter(fps=fps))
    plt.close(fig)


def main():
    info = read_case_info()
    for case in CASES:
        make_case_gif(case, info, "ephi", "Ephi")
    print("Wrote ephi_animation_*.gif")


if __name__ == "__main__":
    main()
