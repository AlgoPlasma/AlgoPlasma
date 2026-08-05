#!/usr/bin/env python3
from __future__ import annotations

import csv
from pathlib import Path


DATASETS = [
    ("amd", "AMD original", "#1f77b4", "o"),
    ("amd_ompdo", "AMD ompdo", "#ff7f0e", "s"),
    ("kunpeng", "Kunpeng GCC/mpifort", "#2ca02c", "^"),
    ("kunpeng_optimized", "Kunpeng BiSheng", "#d62728", "D"),
    ("kunpeng_ompdo", "Kunpeng BiSheng ompdo", "#9467bd", "v"),
]

SELECTED_THREADS = [1, 2, 4, 8, 16, 32, 64, 128, 256]


def repo_root(start: Path) -> Path:
    for path in [start, *start.parents]:
        if (path / "docs" / "source").is_dir() and (path / "tests").is_dir():
            return path
    raise RuntimeError(f"cannot find repo root from {start}")


def load_rows(case_dir: Path) -> dict[str, list[dict[str, float]]]:
    data: dict[str, list[dict[str, float]]] = {}
    for key, _label, _color, _marker in DATASETS:
        csv_path = case_dir / "data_raw" / key / "key_metrics.csv"
        with csv_path.open(newline="", encoding="utf-8") as f:
            rows = []
            for row in csv.DictReader(f):
                rows.append(
                    {
                        "threads": int(float(row["threads"])),
                        "single_step_avg_s": float(row["single_step_avg_s"]),
                    }
                )
        data[key] = sorted(rows, key=lambda row: row["threads"])
    return data


def configure_thread_axis(ax, ticks: list[int]) -> None:
    ax.set_xscale("log", base=2)
    ax.set_xticks(ticks)
    ax.set_xticklabels([str(tick) for tick in ticks])
    ax.set_xlabel("OpenMP threads")
    ax.grid(True, which="both", alpha=0.25)


def plot_time_all(data: dict[str, list[dict[str, float]]], out_dir: Path) -> None:
    import matplotlib.pyplot as plt

    all_threads = sorted({row["threads"] for rows in data.values() for row in rows})
    fig, ax = plt.subplots(figsize=(10.5, 6.2))
    for key, label, color, marker in DATASETS:
        rows = data[key]
        ax.plot(
            [row["threads"] for row in rows],
            [row["single_step_avg_s"] for row in rows],
            marker=marker,
            color=color,
            linewidth=1.8,
            markersize=4.5,
            label=label,
        )

    configure_thread_axis(ax, all_threads)
    ax.tick_params(axis="x", labelrotation=45, labelsize=8)
    ax.set_yscale("log")
    ax.set_ylabel("Average single-step time (s)")
    ax.set_title("E03 FDTD Cartesian: time vs threads")
    ax.legend(fontsize=8.2, loc="best")
    fig.tight_layout()
    fig.savefig(out_dir / "time_vs_threads.png", dpi=180)
    plt.close(fig)


def plot_time_selected(data: dict[str, list[dict[str, float]]], out_dir: Path) -> None:
    import matplotlib.pyplot as plt
    from matplotlib.lines import Line2D

    fig, ax = plt.subplots(figsize=(9.5, 5.8))
    for key, label, color, marker in DATASETS:
        by_thread = {row["threads"]: row["single_step_avg_s"] for row in data[key]}
        xs = [thread for thread in SELECTED_THREADS if thread in by_thread]
        ys = [by_thread[thread] for thread in xs]
        ax.plot(
            xs,
            ys,
            marker=marker,
            color=color,
            linewidth=1.8,
            markersize=4.8,
            label=label,
        )
        if 1 in by_thread:
            ax.plot(
                xs,
                [by_thread[1] / thread for thread in xs],
                linestyle="--",
                color=color,
                linewidth=1.1,
                alpha=0.55,
            )

    configure_thread_axis(ax, SELECTED_THREADS)
    ax.set_yscale("log")
    ax.set_ylabel("Average single-step time (s)")
    ax.set_title("E03 FDTD Cartesian: selected thread-count time")
    handles, labels = ax.get_legend_handles_labels()
    handles.append(Line2D([0], [0], color="0.35", linestyle="--", linewidth=1.1))
    labels.append("Ideal time: own T1 / threads")
    ax.legend(handles, labels, fontsize=8.2, loc="best")
    fig.tight_layout()
    fig.savefig(out_dir / "time_vs_selected_threads.png", dpi=180)
    plt.close(fig)


def plot_relative_time(data: dict[str, list[dict[str, float]]], out_dir: Path) -> None:
    import matplotlib.pyplot as plt

    amd_by_thread = {
        row["threads"]: row["single_step_avg_s"]
        for row in data["amd"]
    }
    all_threads = sorted(amd_by_thread)
    fig, ax = plt.subplots(figsize=(10.5, 6.2))
    for key, label, color, marker in DATASETS:
        rows = [
            row for row in data[key]
            if row["threads"] in amd_by_thread and amd_by_thread[row["threads"]] > 0.0
        ]
        ax.plot(
            [row["threads"] for row in rows],
            [100.0 * row["single_step_avg_s"] / amd_by_thread[row["threads"]] for row in rows],
            marker=marker,
            color=color,
            linewidth=1.8,
            markersize=4.5,
            label=label,
        )

    configure_thread_axis(ax, all_threads)
    ax.tick_params(axis="x", labelrotation=45, labelsize=8)
    ax.axhline(100.0, color="0.35", linestyle="--", linewidth=1.0, alpha=0.6)
    ax.set_ylabel("Time vs AMD original at same thread (%)")
    ax.set_title("E03 FDTD Cartesian: relative time vs AMD original")
    ax.legend(fontsize=8.2, loc="best")
    fig.tight_layout()
    fig.savefig(out_dir / "relative_time_vs_amd.png", dpi=180)
    plt.close(fig)


def main() -> int:
    import matplotlib

    matplotlib.use("Agg")

    case_dir = Path(__file__).resolve().parents[1]
    root = repo_root(case_dir)
    out_dir = root / "docs" / "source" / "images" / "tests" / "kunpeng_compare" / "E_Maxwell_E03_fdtd_3d_cartesian"
    out_dir.mkdir(parents=True, exist_ok=True)

    data = load_rows(case_dir)
    plot_time_all(data, out_dir)
    plot_time_selected(data, out_dir)
    plot_relative_time(data, out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
