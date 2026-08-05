#!/usr/bin/env python3
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation, PillowWriter
import numpy as np

from plot_results import CASES, read_slice, visual_field


def numbers_from_line(line):
    return [float(v.replace("D", "E").replace("d", "E")) for v in line.split("=")[1].split()]


def read_case_info():
    info = {}
    path = Path("case_info.dat")
    if not path.exists():
        return info
    for line in path.read_text().splitlines():
        if "npml npml_ref" in line:
            vals = numbers_from_line(line)
            info["npml"] = int(vals[0])
    return info


def make_case_gif(case, info, fps=8):
    files = sorted(Path(".").glob(f"field_slice_{case}_*.dat"))
    if not files:
        return False

    steps = [int(path.stem.rsplit("_", 1)[1]) for path in files]
    fields = [visual_field(read_slice(path)) for path in files]
    vmax = max(np.percentile(np.abs(field), 99.5) for field in fields)
    vmax = max(vmax, 1.0e-300)
    npml = info.get("npml", 12)

    fig, ax = plt.subplots(figsize=(6.4, 5.8), constrained_layout=True)
    im = ax.imshow(fields[0].T, origin="lower", cmap="RdBu_r", vmin=-vmax, vmax=vmax, aspect="auto")
    ax.axhline(npml, color="black", lw=0.8, alpha=0.45)
    ax.axhline(fields[0].shape[1]-npml, color="black", lw=0.8, alpha=0.45)
    title = ax.set_title(f"{case}, sqrt(r) Ez, n={steps[0]}")
    ax.set_xlabel("r index")
    ax.set_ylabel("z index")
    fig.colorbar(im, ax=ax, label="sqrt(r) Ez")

    def update(frame):
        im.set_data(fields[frame].T)
        title.set_text(f"{case}, sqrt(r) Ez, n={steps[frame]}")
        return im, title

    animation = FuncAnimation(fig, update, frames=len(fields), interval=1000/fps, blit=False)
    animation.save(f"ez_animation_{case}.gif", writer=PillowWriter(fps=fps))
    plt.close(fig)
    return True


def main():
    info = read_case_info()
    written = [case for case in CASES if make_case_gif(case, info)]
    if written:
        print("Wrote " + ", ".join(f"ez_animation_{case}.gif" for case in written))
    else:
        print("No field_slice_*.dat files found")


if __name__ == "__main__":
    main()
