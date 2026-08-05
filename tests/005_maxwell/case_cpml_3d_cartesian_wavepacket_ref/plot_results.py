#!/usr/bin/env python3
from pathlib import Path
import re

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


CASES = ["x_plus", "x_minus", "y_plus", "y_minus", "z_plus", "z_minus"]


def read_probe(path):
    return np.loadtxt(path, skiprows=1)


def parse_fortran_float(text):
    value = text.replace("D", "E").replace("d", "E")
    if "E" not in value.upper():
        value = re.sub(r"([0-9.])([+-][0-9]{2,3})$", r"\1E\2", value)
    return float(value)


def read_slice(path):
    lines = Path(path).read_text().splitlines()
    nx, ny = [int(v) for v in lines[0].split()]
    arr = np.empty((nx, ny), dtype=float)
    for i in range(nx):
        tokens = lines[1 + i].split()
        vals = [parse_fortran_float(token) for token in tokens]
        arr[i, :] = vals
    return arr


def plot_probes():
    fig, axes = plt.subplots(3, 2, figsize=(10.0, 10.0), constrained_layout=True)
    for ax, case in zip(axes.ravel(), CASES):
        data = read_probe(f"{case}_probe.dat")
        ref_line, = ax.plot(
            data[:, 0],
            data[:, 2],
            color="tab:orange",
            lw=2.2,
            alpha=0.50,
            label="large reference",
            zorder=1,
        )
        cpml_line, = ax.plot(
            data[:, 0],
            data[:, 1],
            color="tab:blue",
            lw=1.35,
            ls="--",
            alpha=0.95,
            label="compact CPML",
            zorder=2,
        )
        ax.set_title(case)
        ax.set_xlabel("step")
        ax.set_ylabel("E probe")
        ax.grid(True, alpha=0.25)
        ax.legend(handles=[cpml_line, ref_line], fontsize=8)
    fig.savefig("probe_compare.png", dpi=160)
    plt.close(fig)

    fig, ax = plt.subplots(figsize=(8.0, 4.8), constrained_layout=True)
    for case in CASES:
        data = read_probe(f"{case}_probe.dat")
        ax.plot(data[:, 0], data[:, 3], lw=1.0, label=case)
    ax.set_ylim(-180.0, 20.0)
    ax.set_xlabel("step")
    ax.set_ylabel("Error_dB")
    ax.grid(True, alpha=0.25)
    ax.legend(ncol=2)
    fig.savefig("probe_error_db.png", dpi=160)
    plt.close(fig)


def plot_slices():
    for case in CASES:
        files = sorted(Path(".").glob(f"field_slice_{case}_*.dat"))
        if not files:
            continue
        steps = [int(path.stem.rsplit("_", 1)[1]) for path in files]
        fields = [read_slice(path) for path in files]
        vmax = max(np.percentile(np.abs(f), 99.5) for f in fields)
        vmax = max(vmax, 1.0e-300)
        fig, axes = plt.subplots(2, 2, figsize=(8.4, 7.2), constrained_layout=True)
        for ax, step, field in zip(axes.ravel(), steps, fields):
            im = ax.imshow(field.T, origin="lower", cmap="RdBu_r", vmin=-vmax, vmax=vmax, aspect="equal")
            ax.set_title(f"{case}, n={step}")
            ax.set_xlabel("index 1")
            ax.set_ylabel("index 2")
        for ax in axes.ravel()[len(fields):]:
            ax.set_visible(False)
        fig.colorbar(im, ax=axes.ravel().tolist(), label="E")
        fig.savefig(f"field_slices_{case}.png", dpi=160)
        plt.close(fig)


def main():
    plot_probes()
    plot_slices()
    print("Wrote probe_compare.png, probe_error_db.png, and field_slices_*.png")


if __name__ == "__main__":
    main()
