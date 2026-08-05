#!/usr/bin/env python3
from pathlib import Path
import re

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


CASES = ["z_plus", "z_minus"]
SLICE_STEP_FRACTIONS = [0.0, 1.0/6.0, 1.0/3.0, 2.0/3.0]


def read_probe(path):
    return np.loadtxt(path, skiprows=1)


def parse_fortran_float(text):
    value = text.replace("D", "E").replace("d", "E")
    if "E" not in value.upper():
        value = re.sub(r"([0-9.])([+-][0-9]{2,3})$", r"\1E\2", value)
    return float(value)


def read_slice(path):
    lines = Path(path).read_text().splitlines()
    nr, nz = [int(v) for v in lines[0].split()]
    arr = np.empty((nr, nz), dtype=float)
    for i in range(nr):
        vals = [parse_fortran_float(token) for token in lines[1 + i].split()]
        arr[i, :] = vals
    return arr


def visual_field(field):
    weights = np.sqrt(np.arange(field.shape[0], dtype=float)/max(1, field.shape[0]-1))
    return field*weights[:, None]


def select_slice_files(files):
    by_step = {int(path.stem.rsplit("_", 1)[1]): path for path in files}
    steps = sorted(by_step)
    if len(steps) <= 4:
        return [by_step[step] for step in steps]

    max_step = steps[-1]
    selected = []
    for fraction in SLICE_STEP_FRACTIONS:
        target = fraction*max_step
        step = min(steps, key=lambda value: (abs(value-target), value))
        if step not in selected:
            selected.append(step)

    for step in steps:
        if len(selected) >= 4:
            break
        if step not in selected:
            selected.append(step)

    return [by_step[step] for step in selected[:4]]


def plot_probes():
    fig, axes = plt.subplots(1, 2, figsize=(8.4, 3.6), constrained_layout=True)
    for ax, case in zip(axes.ravel(), CASES):
        data = read_probe(f"{case}_probe.dat")
        ax.plot(data[:, 0], data[:, 1], lw=1.0, label="compact CPML")
        ax.plot(data[:, 0], data[:, 2], lw=0.9, alpha=0.8, label="large reference")
        ax.set_title(case)
        ax.set_xlabel("step")
        ax.set_ylabel("Ez probe")
        ax.grid(True, alpha=0.25)
        ax.legend(fontsize=8)
    fig.savefig("probe_compare.png", dpi=160)
    plt.close(fig)

    fig, ax = plt.subplots(figsize=(8.0, 4.5), constrained_layout=True)
    for case in CASES:
        data = read_probe(f"{case}_probe.dat")
        ax.plot(data[:, 0], data[:, 3], lw=1.0, label=case)
    ax.set_ylim(-180.0, 20.0)
    ax.set_xlabel("step")
    ax.set_ylabel("Error_dB")
    ax.grid(True, alpha=0.25)
    ax.legend()
    fig.savefig("probe_error_db.png", dpi=160)
    plt.close(fig)


def plot_slices():
    for case in CASES:
        files = select_slice_files(sorted(Path(".").glob(f"field_slice_{case}_*.dat")))
        if not files:
            continue
        steps = [int(path.stem.rsplit("_", 1)[1]) for path in files]
        fields = [visual_field(read_slice(path)) for path in files]
        vmax = max(np.percentile(np.abs(f), 99.5) for f in fields)
        vmax = max(vmax, 1.0e-300)
        fig, axes = plt.subplots(2, 2, figsize=(8.0, 7.0), constrained_layout=True)
        for ax, step, field in zip(axes.ravel(), steps, fields):
            im = ax.imshow(field.T, origin="lower", cmap="RdBu_r", vmin=-vmax, vmax=vmax, aspect="auto")
            ax.set_title(f"{case}, n={step}")
            ax.set_xlabel("r index")
            ax.set_ylabel("z index")
        for ax in axes.ravel()[len(fields):]:
            ax.set_visible(False)
        fig.colorbar(im, ax=axes.ravel().tolist(), label="sqrt(r) Ez")
        fig.savefig(f"field_slices_{case}.png", dpi=160)
        plt.close(fig)


def main():
    plot_probes()
    plot_slices()
    print("Wrote probe_compare.png, probe_error_db.png, and field_slices_*.png")


if __name__ == "__main__":
    main()
