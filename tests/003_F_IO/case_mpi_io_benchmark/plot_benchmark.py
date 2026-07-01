#!/usr/bin/env python3
import csv
import sys
from pathlib import Path

import matplotlib.pyplot as plt


def read_rows(path):
    with Path(path).open(newline="") as f:
        return list(csv.DictReader(f))


def main():
    csv_path = Path(sys.argv[1] if len(sys.argv) > 1 else "benchmark_results.csv")
    rows = read_rows(csv_path)
    if not rows:
        raise SystemExit(f"empty benchmark file: {csv_path}")

    formats = ["dat", "bin", "h5"]
    fig, axes = plt.subplots(1, 2, figsize=(10.5, 4.2), constrained_layout=True)

    for fmt in formats:
        data = [r for r in rows if r["format"] == fmt]
        data.sort(key=lambda r: int(r["ranks"]))
        ranks = [int(r["ranks"]) for r in data]
        write_time = [float(r["write_seconds"]) for r in data]
        read_time = [float(r["read_seconds"]) for r in data]
        base_write = write_time[0]
        base_read = read_time[0]
        write_speedup = [base_write / t for t in write_time]
        read_speedup = [base_read / t for t in read_time]
        axes[0].plot(ranks, write_speedup, marker="o", label=fmt)
        axes[1].plot(ranks, read_speedup, marker="o", label=fmt)

    baseline = min(int(r["ranks"]) for r in rows)
    rank_values = sorted({int(r["ranks"]) for r in rows})
    ideal = [r / baseline for r in rank_values]
    for ax in axes:
        ax.plot(rank_values, ideal, color="black", linestyle="--", linewidth=1.0, label="ideal")

    for ax, title in zip(axes, ["Write speedup", "Read speedup"]):
        ax.set_title(title)
        ax.set_xlabel("MPI ranks")
        ax.set_ylabel(f"speedup vs {baseline} ranks")
        ax.set_xticks(rank_values)
        ax.grid(True, alpha=0.25)
        ax.legend()

    fig.savefig("benchmark_io_speedup.png", dpi=160)

    fig, axes = plt.subplots(1, 2, figsize=(10.5, 4.2), constrained_layout=True)

    for fmt in formats:
        data = [r for r in rows if r["format"] == fmt]
        data.sort(key=lambda r: int(r["ranks"]))
        ranks = [int(r["ranks"]) for r in data]
        write = [float(r["write_MB_s"]) for r in data]
        read = [float(r["read_MB_s"]) for r in data]
        axes[0].plot(ranks, write, marker="o", label=fmt)
        axes[1].plot(ranks, read, marker="o", label=fmt)

    for ax, title in zip(axes, ["Write throughput", "Read throughput"]):
        ax.set_title(title)
        ax.set_xlabel("MPI ranks")
        ax.set_ylabel("payload MB/s")
        ax.set_xticks(sorted({int(r["ranks"]) for r in rows}))
        ax.grid(True, alpha=0.25)
        ax.legend()

    fig.savefig("benchmark_io_speed.png", dpi=160)


if __name__ == "__main__":
    main()
