#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Plot the six measured relaxation runs; also used by the Sphinx test page."""

import argparse
import csv
import math
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


MODELS = ("HS", "VHS", "VSS")
SCHEDULES = ("ntc", "clock")
COLORS = {"x": "#2864a0", "y": "#cc7924", "z": "#71842d"}
DEFAULT_RESULTS = Path(__file__).resolve().parent / "results"

plt.rcParams.update({
    "font.family": "DejaVu Sans", "font.size": 10,
    "axes.spines.top": False, "axes.spines.right": False,
    "axes.grid": True, "grid.alpha": 0.22, "grid.linewidth": 0.6,
    "lines.linewidth": 1.5, "savefig.facecolor": "white",
})


def load_results(directory, missing_ok=False):
    """Read complete trajectories, keeping integer counters exact."""
    paths = {(m, s): Path(directory) / f"relaxation-{m}-{s}.csv"
             for m in MODELS for s in SCHEDULES}
    missing = [str(path) for path in paths.values() if not path.is_file()]
    if missing:
        if missing_ok:
            return None  # A clean documentation build can show the run instruction.
        raise ValueError("missing relaxation data: " + ", ".join(missing))
    data = {}
    integers = {"step", "candidates", "accepted", "particle_count", "seed"}
    required = integers | {"time_s", "temperature_k", "energy_x_fraction",
        "energy_y_fraction", "energy_z_fraction", "kurtosis_x",
        "temperature_relative_change", "mean_velocity_change_over_v0"}
    for key, path in paths.items():
        with path.open(newline="", encoding="utf-8") as stream:
            reader = csv.DictReader(stream)
            if not required.issubset(reader.fieldnames or ()):
                raise ValueError(f"{path}: regenerate the CSV with the current run.sh")
            rows = [{name: int(row[name]) if name in integers else float(row[name])
                     for name in required} for row in reader]
        if len(rows) < 2 or rows[0]["step"] != 0 or rows[0]["time_s"] != 0:
            raise ValueError(f"{path}: expected an initial state and a time series")
        for i, row in enumerate(rows):
            if (not all(math.isfinite(value) for value in row.values())
                    or row["particle_count"] < 2
                    or row["particle_count"] != rows[0]["particle_count"]
                    or row["seed"] != rows[0]["seed"]
                    or not 0 <= row["accepted"] <= row["candidates"]):
                raise ValueError(f"{path}: invalid row {i + 2}")
            if i and (row["time_s"] <= rows[i-1]["time_s"]
                      or row["step"] <= rows[i-1]["step"]
                      or row["candidates"] < rows[i-1]["candidates"]
                      or row["accepted"] < rows[i-1]["accepted"]):
                raise ValueError(f"{path}: unordered time series or counters")
        data[key] = rows
    return data


def missing_figure(title):
    fig, ax = plt.subplots(figsize=(10, 2.2), layout="constrained")
    ax.set_axis_off()
    ax.set_title(title)
    ax.text(0.5, 0.5, "Generate the measured curves from the repository root:\n"
            "bash tests/009_collision/G03_DSMC/run.sh relaxation\n"
            "Then rebuild this documentation page.", ha="center", va="center",
            transform=ax.transAxes)
    return fig


def time_us(rows):
    return [row["time_s"] * 1e6 for row in rows]


def late_statistics(rows):
    """Use the same equal-time samples as the C++ regression check."""
    boundary = rows[-1]["step"] // 2
    late = [row for row in rows if row["step"] > boundary]
    means = {f"mean_energy_{d}_fraction":
             math.fsum(row[f"energy_{d}_fraction"] for row in late)/len(late)
             for d in "xyz"}
    means["mean_kurtosis_x"] = math.fsum(row["kurtosis_x"] for row in late)/len(late)
    return {
        "averaging_start_time_s": next(row["time_s"] for row in rows if row["step"] == boundary),
        "averaging_end_time_s": rows[-1]["time_s"],
        **means,
        "energy_fraction_relative_error": max(abs(3*means[f"mean_energy_{d}_fraction"]-1) for d in "xyz"),
        "kurtosis_relative_error": abs(means["mean_kurtosis_x"]/3-1),
    }


def plot_relaxation(data):
    """Show second- and fourth-moment relaxation for one representative run."""
    if data is None:
        return missing_figure("Collision relaxation: VSS / NTC")
    rows = data["VSS", "ntc"]
    times = time_us(rows)
    end = rows[-1]
    late = late_statistics(rows)
    fig, axes = plt.subplots(2, 1, figsize=(8, 6.6), sharex=True, layout="constrained")
    for ax in axes:
        ax.axvspan(late["averaging_start_time_s"]*1e6, times[-1], color="#555555", alpha=0.07)
    for direction, color, style in zip("xyz", COLORS.values(), ("-", "--", ":")):
        axes[0].plot(times, [v[f"energy_{direction}_fraction"] for v in rows],
                     color=color, linestyle=style, label=direction)
    axes[0].axhline(1/3, color="#555555", linestyle="-.", linewidth=1, label="1/3")
    axes[0].set(ylabel="Thermal energy fraction", ylim=(-0.025, 1.025))
    axes[0].legend(loc="upper right", ncol=4, frameon=False)
    mean_shares = ", ".join(f"{d}={late[f'mean_energy_{d}_fraction']:.4f}" for d in "xyz")
    axes[0].text(0.98, 0.72, "Late mean: " + mean_shares, ha="right", transform=axes[0].transAxes)
    axes[1].plot(times, [v["kurtosis_x"] for v in rows], color=COLORS["x"], label="x kurtosis")
    axes[1].axhline(3, color="#555555", linestyle="-.", linewidth=1, label="Maxwell target: 3")
    axes[1].set(xlabel=r"Time ($\mu$s)", ylabel=r"$\langle c_x^4\rangle/\langle c_x^2\rangle^2$",
                ylim=(0.8, max(3.3, max(v["kurtosis_x"] for v in rows)*1.05)))
    axes[1].legend(loc="lower right", frameon=False)
    axes[1].text(0.98, 0.27, f"Late mean: {late['mean_kurtosis_x']:.4f}", ha="right",
                 transform=axes[1].transAxes)
    axes[1].set_xlim(times[0], times[-1])
    fig.suptitle(f"VSS / NTC | N={end['particle_count']}, seed={end['seed']}\n"
                 f"Averaging interval: {late['averaging_start_time_s']*1e6:g}"
                 f"–{times[-1]:g} " r"$\mu$s (shaded)")
    return fig


def save_results(directory):
    directory = Path(directory).resolve()
    data = load_results(directory)
    fig = plot_relaxation(data)
    fig.savefig(directory / "relaxation.png", dpi=180)
    plt.close(fig)
    print(f"Figure: {directory / 'relaxation.png'}")
    with (directory / "summary.csv").open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream)
        late_fields = tuple(late_statistics(next(iter(data.values()))))
        writer.writerow(("model", "schedule", "particle_count", "seed", "steps", "time_s",
            "max_temperature_relative_change", "max_mean_velocity_change_over_v0",
            "energy_x_fraction", "energy_y_fraction", "energy_z_fraction", "kurtosis_x",
            "candidates", "accepted", "acceptance_fraction", *late_fields))
        for (model, schedule), rows in data.items():
            end = rows[-1]
            late = late_statistics(rows)
            writer.writerow((model, schedule, end["particle_count"], end["seed"], end["step"],
                end["time_s"], max(abs(v["temperature_relative_change"]) for v in rows),
                max(v["mean_velocity_change_over_v0"] for v in rows),
                *(end[f"energy_{d}_fraction"] for d in "xyz"), end["kurtosis_x"],
                end["candidates"], end["accepted"],
                end["accepted"]/end["candidates"] if end["candidates"] else "",
                *(late[name] for name in late_fields)))
    print(f"Summary: {directory / 'summary.csv'}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("results", nargs="?", type=Path, default=DEFAULT_RESULTS)
    args = parser.parse_args()
    try:
        save_results(args.results)
    except (OSError, ValueError) as error:
        parser.exit(1, f"ERROR: {error}\n")
