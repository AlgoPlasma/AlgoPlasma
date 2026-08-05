#!/usr/bin/env python3
from pathlib import Path
import re

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


CASES = ["z_plus", "z_minus", "r_plus", "r_minus"]


def numbers_from_line(line):
    return [float(v.replace("D", "E").replace("d", "E")) for v in line.split("=")[1].split()]


def read_case_info():
    info = {}
    for line in Path("case_info.dat").read_text().splitlines():
        if "npml npml_ref" in line:
            vals = numbers_from_line(line)
            info["npml"] = int(vals[0])
            info["npml_ref"] = int(vals[1])
        elif "nr_interior nz_interior" in line:
            vals = numbers_from_line(line)
            info["nr_interior"] = int(vals[0])
            info["nz_interior"] = int(vals[1])
        elif "dr dz" in line:
            vals = numbers_from_line(line)
            info["dr"] = vals[0]
            info["dz"] = vals[1]
        elif "rmin_interior zmin_interior" in line:
            vals = numbers_from_line(line)
            info["rmin_interior"] = vals[0]
            info["zmin_interior"] = vals[1]
        elif "rmin_cpml zmin_cpml" in line:
            vals = numbers_from_line(line)
            info["rmin_cpml"] = vals[0]
            info["zmin_cpml"] = vals[1]
        elif "packet_margin probe_margin" in line:
            vals = numbers_from_line(line)
            info["packet_margin"] = vals[0]
            info["probe_margin"] = vals[1]
    return info


def probe_index(case, info):
    dr = info["dr"]
    dz = info["dz"]
    r_probe = info["rmin_interior"] + 68.0*dr
    z_probe = info["zmin_interior"] + 68.0*dz

    if case == "z_plus":
        z_probe = info["zmin_interior"] + info["probe_margin"]
    elif case == "z_minus":
        z_probe = info["zmin_interior"] + info["nz_interior"]*dz - info["probe_margin"]
    elif case == "r_plus":
        r_probe = info["rmin_interior"] + info["probe_margin"]
    elif case == "r_minus":
        r_probe = info["rmin_interior"] + info["nr_interior"]*dr - info["probe_margin"]

    ir = int(np.rint((r_probe-info["rmin_cpml"])/dr))
    iz = int(np.rint((z_probe-info["zmin_cpml"])/dz))
    return ir, iz


def read_probe(path):
    return np.loadtxt(path, skiprows=1)


def parse_fortran_float(text):
    value = text.replace("D", "E").replace("d", "E")
    if "E" not in value.upper():
        value = re.sub(r"([0-9.])([+-][0-9]{2,3})$", r"\1E\2", value)
    return float(value)


def read_field(path):
    lines = Path(path).read_text().splitlines()
    nr, nz = [int(v) for v in lines[0].split()]
    arr = np.empty((nr, nz), dtype=float)
    for i in range(nr):
        vals = [parse_fortran_float(token) for token in lines[1 + i].split()]
        arr[i, :] = vals
    return arr


def plot_probes():
    fig, axes = plt.subplots(2, 2, figsize=(10.0, 7.2), constrained_layout=True)
    for ax, case in zip(axes.ravel(), CASES):
        data = read_probe(f"{case}_probe.dat")
        n = data[:, 0]
        ax.plot(n, data[:, 1], lw=1.0, label="compact CPML")
        ax.plot(n, data[:, 2], lw=0.9, label="large reference", alpha=0.8)
        ax.set_title(case)
        ax.set_xlabel("step")
        ax.set_ylabel("Ephi probe")
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


def plot_field_snapshots(prefix, label):
    info = read_case_info()
    npml = info.get("npml", 12)
    for case in CASES:
        files = sorted(Path(".").glob(f"{prefix}_snapshot_{case}_*.dat"))
        if not files:
            continue
        steps = [int(path.stem.rsplit("_", 1)[1]) for path in files]
        fields = [read_field(path) for path in files]
        ip, kp = probe_index(case, info)
        vmax = max(np.percentile(np.abs(f), 99.5) for f in fields)
        vmax = max(vmax, 1.0e-300)
        fig, axes = plt.subplots(2, 2, figsize=(8.0, 7.0), constrained_layout=True)
        for ax, step, field in zip(axes.ravel(), steps, fields):
            im = ax.imshow(field.T, origin="lower", cmap="RdBu_r", vmin=-vmax, vmax=vmax, aspect="equal")
            ax.axvline(npml, color="black", lw=0.8, alpha=0.45)
            ax.axvline(field.shape[0] - npml, color="black", lw=0.8, alpha=0.45)
            ax.axhline(npml, color="black", lw=0.8, alpha=0.45)
            ax.axhline(field.shape[1] - npml, color="black", lw=0.8, alpha=0.45)
            ax.scatter(ip, kp, s=42, marker="o", facecolor="yellow", edgecolor="black", linewidth=0.8, zorder=5)
            ax.text(ip + 3, kp + 3, "probe", color="black", fontsize=8, weight="bold", zorder=6)
            ax.set_title(f"{case}, {label}, n={step}")
            ax.set_xlabel("r index")
            ax.set_ylabel("z index")
        for ax in axes.ravel()[len(fields):]:
            ax.set_visible(False)
        fig.colorbar(im, ax=axes.ravel().tolist(), label=label)
        fig.savefig(f"{prefix}_snapshots_{case}.png", dpi=160)
        plt.close(fig)


def plot_snapshots():
    plot_field_snapshots("ephi", "Ephi")
    plot_field_snapshots("hz", "Hz")


def main():
    plot_probes()
    plot_snapshots()
    print("Wrote probe_compare.png, probe_error_db.png, ephi_snapshots_*.png, and hz_snapshots_*.png")


if __name__ == "__main__":
    main()
