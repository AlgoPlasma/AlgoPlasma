#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


CASE_DIR = Path(__file__).resolve().parent
BUILD_DIR = CASE_DIR / "build"
FIG_DIR = CASE_DIR / "fig"


def read_table(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8") as f:
        header = f.readline().split()
        rows = []
        for line in f:
            fields = line.split()
            if not fields:
                continue
            rows.append(dict(zip(header, fields)))
        return rows


def plot_check_rows(path: Path, out_png: Path, title: str) -> None:
    rows = read_table(path)
    labels = [f"r{r['rank']}:{r['case']}" for r in rows]
    actual = [float(r["actual"]) for r in rows]
    expected = [float(r["expected"]) for r in rows]
    err = [max(float(r["abs_error"]), 1.0e-18) for r in rows]
    x = list(range(len(rows)))

    fig, axes = plt.subplots(2, 1, figsize=(10.5, 6.6), constrained_layout=True)

    axes[0].plot(x, actual, "o", label="actual")
    axes[0].plot(x, expected, "x", label="expected")
    axes[0].set_title(title)
    axes[0].set_ylabel("value")
    axes[0].grid(True, alpha=0.3)
    axes[0].legend()

    axes[1].bar(x, err, color="#3b7ea1")
    axes[1].set_yscale("log")
    axes[1].set_ylabel("absolute error")
    axes[1].set_xticks(x)
    axes[1].set_xticklabels(labels, rotation=35, ha="right")
    axes[1].grid(True, axis="y", alpha=0.3)

    fig.savefig(out_png, dpi=180)
    plt.close(fig)


def plot_particles(path: Path, out_png: Path) -> None:
    rows = read_table(path)
    colors = {0: "#276fbf", 1: "#c44536", 2: "#2a9d8f", 3: "#7b2cbf"}
    markers = {1: "o", 2: "s"}

    fig, ax = plt.subplots(figsize=(7.5, 6.8), constrained_layout=True)
    for row in rows:
        rank = int(row["rank"])
        species = int(row["species"])
        pid = int(row["id"])
        x = float(row["x"])
        y = float(row["y"])
        ax.scatter(
            x,
            y,
            s=80,
            marker=markers.get(species, "o"),
            color=colors.get(rank, "black"),
            edgecolor="white",
            linewidth=0.8,
            label=f"rank {rank}, species {species}",
        )
        ax.text(x + 0.05, y + 0.05, str(pid), fontsize=7)

    handles, labels = ax.get_legend_handles_labels()
    unique = dict(zip(labels, handles))
    ax.legend(unique.values(), unique.keys(), fontsize=8, loc="upper left", ncol=2)
    ax.set_title("H02 particle ownership after MPI exchange")
    ax.set_xlabel("x")
    ax.set_ylabel("y")
    ax.set_xlim(-0.5, 8.6)
    ax.set_ylim(-0.5, 8.6)
    ax.set_aspect("equal", adjustable="box")
    ax.axvline(4.0, color="0.35", linestyle="--", linewidth=1.0)
    ax.axhline(4.0, color="0.35", linestyle="--", linewidth=1.0)
    ax.grid(True, alpha=0.25)

    fig.savefig(out_png, dpi=180)
    plt.close(fig)


def main() -> None:
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    tasks = [
        (
            BUILD_DIR / "h01_field_faces.dat",
            FIG_DIR / "h01_field_exchange.png",
            "H01 field halo exchange: actual vs expected",
        ),
        (
            BUILD_DIR / "h03_density_faces.dat",
            FIG_DIR / "h03_density_exchange.png",
            "H03 density accumulation: actual vs expected",
        ),
    ]

    for src, dst, title in tasks:
        if not src.exists():
            raise FileNotFoundError(f"missing test output: {src}")
        plot_check_rows(src, dst, title)

    particle_src = BUILD_DIR / "h02_particle_exchange.dat"
    if not particle_src.exists():
        raise FileNotFoundError(f"missing test output: {particle_src}")
    plot_particles(particle_src, FIG_DIR / "h02_particle_exchange.png")

    print(f"Wrote figures to {FIG_DIR}")


if __name__ == "__main__":
    main()
