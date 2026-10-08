#!/usr/bin/env python3
"""Plot collision_box CSV files; never participates in the MCC run."""

import argparse
import csv
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


def rows(path):
    with path.open(newline="", encoding="utf-8") as stream:
        return list(csv.DictReader(stream))


def column(data, key):
    return [float(row[key]) for row in data]


def make_thermalization(directory):
    data = rows(directory / "history.csv")
    tau = column(data, "nu_t")
    fig, axes = plt.subplots(3, 1, figsize=(8.5, 9.5), sharex=True)
    series = (
        ("mean_vx_m_s", "reference_vx_m_s", "Mean $v_x$ (m/s)"),
        ("temperature_k", "reference_temperature_k", "Central temperature (K)"),
        ("mean_v2_m2_s2", "reference_v2_m2_s2", "Raw $\\langle v^2 \\rangle$ (m$^2$/s$^2$)"),
    )
    for axis, (measured, reference, ylabel) in zip(axes, series):
        axis.plot(tau, column(data, reference), color="#cc683b", label="Analytic")
        axis.plot(tau, column(data, measured), color="#167b83", linewidth=1.2,
                  label="MCC")
        axis.set_ylabel(ylabel)
        axis.grid(alpha=0.22)
        axis.legend(frameon=False)
    axes[-1].set_xlabel(r"Collision time $\nu t$")
    fig.suptitle("Elastic thermalization in a fixed background")
    fig.tight_layout()
    fig.savefig(directory / "thermalization.png", dpi=170)
    plt.close(fig)


def make_distributions(directory):
    data = rows(directory / "distribution.csv")
    fig, axes = plt.subplots(1, 2, figsize=(12, 4.5))
    colors = {"initial": "#cc683b", "final": "#167b83"}
    for axis, variable, xlabel in zip(
        axes, ("vx", "speed"), (r"$v_x$ (m/s)", "Speed (m/s)"),
    ):
        for snapshot in ("initial", "final"):
            subset = [row for row in data if row["snapshot"] == snapshot
                      and row["variable"] == variable]
            x = column(subset, "bin_center")
            y = column(subset, "observed_density")
            axis.step(x, y, where="mid", color=colors[snapshot],
                      label=f"{snapshot.capitalize()} MCC")
            if subset[0]["expected_density"]:
                axis.plot(x, column(subset, "expected_density"),
                          color=colors[snapshot], linestyle="--",
                          label=f"{snapshot.capitalize()} Maxwell")
        axis.set_xlabel(xlabel)
        axis.set_ylabel("Probability density (s/m)")
        axis.grid(alpha=0.22)
        axis.legend(frameon=False)
    fig.suptitle("Particle velocity distributions")
    fig.tight_layout()
    fig.savefig(directory / "distributions.png", dpi=170)
    plt.close(fig)


def make_counts(directory):
    data = rows(directory / "collision_counts.csv")
    x = column(data, "collisions")
    observed = column(data, "observed_particles")
    expected = column(data, "poisson_expected_particles")
    fig, axis = plt.subplots(figsize=(8.5, 4.5))
    axis.bar(x, observed, color="#167b83", alpha=0.7, label="MCC particles")
    axis.plot(x, expected, color="#cc683b", marker="o", markersize=2.5,
              linewidth=1, label="Poisson expectation")
    axis.set_xlabel("Real collisions per particle")
    axis.set_ylabel("Particle count")
    axis.grid(axis="y", alpha=0.22)
    axis.legend(frameon=False)
    fig.tight_layout()
    fig.savefig(directory / "collision_counts.png", dpi=170)
    plt.close(fig)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path, help="collision_box output directory")
    directory = parser.parse_args().directory
    make_thermalization(directory)
    make_distributions(directory)
    make_counts(directory)
    print(f"Plots written to {directory}")


if __name__ == "__main__":
    main()
