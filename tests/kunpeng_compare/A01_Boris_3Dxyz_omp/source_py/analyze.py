#!/usr/bin/env python3
from __future__ import annotations

import csv
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATASETS = {
    "AMD": ROOT / "data_raw" / "from_AMD",
    "Kunpeng": ROOT / "data_raw" / "from_kunpeng",
}
OUT = ROOT / "output"
FIG = OUT / "figures"


def extract_float(pattern: str, text: str, name: str) -> float:
    match = re.search(pattern, text, re.MULTILINE)
    if not match:
        raise ValueError(f"Cannot find {name}")
    return float(match.group(1))


def extract_int(pattern: str, text: str, name: str) -> int:
    match = re.search(pattern, text, re.MULTILINE)
    if not match:
        raise ValueError(f"Cannot find {name}")
    return int(match.group(1))


def read_log(platform: str, path: Path) -> dict[str, float | int | str]:
    text = path.read_text(encoding="utf-8", errors="replace")
    threads_from_name = int(re.search(r"log(\d+)\.run$", path.name).group(1))
    threads = extract_int(r"OpenMP max threads\s*=\s*(\d+)", text, "OpenMP max threads")
    if threads != threads_from_name:
        raise ValueError(f"{path}: filename threads and log threads differ")

    np = extract_int(r"np\s*=\s*(\d+)", text, "np")
    nt = extract_int(r"nt\s*=\s*(\d+)", text, "nt")
    total_wall = extract_float(r"Total wall time\s*=\s*([0-9.Ee+\-]+)", text, "total wall time")
    compute_wall = extract_float(r"Compute wall time\s*=\s*([0-9.Ee+\-]+)", text, "compute wall time")
    pushes = float(np) * float(nt)
    throughput = pushes / compute_wall

    return {
        "platform": platform,
        "threads": threads,
        "np": np,
        "nt": nt,
        "total_wall_time_s": total_wall,
        "compute_wall_time_s": compute_wall,
        "particle_pushes": pushes,
        "throughput_pushes_s": throughput,
        "throughput_gpushes_s": throughput / 1.0e9,
    }


def collect_rows() -> list[dict[str, float | int | str]]:
    rows: list[dict[str, float | int | str]] = []
    for platform, directory in DATASETS.items():
        logs = sorted(directory.glob("log*.run"), key=lambda p: int(re.search(r"log(\d+)\.run$", p.name).group(1)))
        if not logs:
            raise FileNotFoundError(f"No log*.run files found in {directory}")
        rows.extend(read_log(platform, path) for path in logs)
    return rows


def add_speedups(rows: list[dict[str, float | int | str]]) -> None:
    baseline: dict[str, float] = {}
    for row in rows:
        if int(row["threads"]) == 8:
            baseline[str(row["platform"])] = float(row["compute_wall_time_s"])

    for row in rows:
        platform = str(row["platform"])
        base = baseline.get(platform)
        if base is None:
            row["speedup_vs_8"] = ""
            row["parallel_efficiency_vs_8"] = ""
            continue
        speedup = base / float(row["compute_wall_time_s"])
        row["speedup_vs_8"] = speedup
        row["parallel_efficiency_vs_8"] = speedup / (float(row["threads"]) / 8.0)

    by_threads: dict[int, dict[str, float]] = {}
    for row in rows:
        by_threads.setdefault(int(row["threads"]), {})[str(row["platform"])] = float(row["compute_wall_time_s"])
    for row in rows:
        pair = by_threads[int(row["threads"])]
        row["kunpeng_speed_vs_AMD"] = pair["AMD"] / pair["Kunpeng"] if "AMD" in pair and "Kunpeng" in pair else ""


def write_summary(rows: list[dict[str, float | int | str]]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    fields = [
        "platform",
        "threads",
        "np",
        "nt",
        "total_wall_time_s",
        "compute_wall_time_s",
        "particle_pushes",
        "throughput_pushes_s",
        "throughput_gpushes_s",
        "speedup_vs_8",
        "parallel_efficiency_vs_8",
        "kunpeng_speed_vs_AMD",
    ]
    with (OUT / "summary.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for row in sorted(rows, key=lambda x: (str(x["platform"]), int(x["threads"]))):
            writer.writerow(row)


def maybe_make_figures(rows: list[dict[str, float | int | str]]) -> None:
    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except Exception as exc:
        print(f"WARNING: matplotlib unavailable, skipping figures: {exc}")
        return

    plt.rcParams.update(
        {
            "font.size": 11,
            "axes.titlesize": 12,
            "axes.labelsize": 11,
            "xtick.labelsize": 10,
            "ytick.labelsize": 10,
            "legend.fontsize": 10,
        }
    )

    FIG.mkdir(parents=True, exist_ok=True)
    styles = {"AMD": "o-", "Kunpeng": "s-"}

    def series(platform: str, key: str) -> tuple[list[int], list[float]]:
        subset = [r for r in rows if r["platform"] == platform]
        subset = sorted(subset, key=lambda x: int(x["threads"]))
        return [int(r["threads"]) for r in subset], [float(r[key]) for r in subset]

    plt.figure(figsize=(7.0, 4.8))
    for platform in DATASETS:
        x, y = series(platform, "compute_wall_time_s")
        plt.plot(x, y, styles[platform], label=platform)
    plt.xscale("log", base=2)
    plt.xlabel("OpenMP threads")
    plt.ylabel("Compute wall time (s)")
    plt.title("A01 Boris OpenMP: Compute Time")
    plt.grid(True, which="both", alpha=0.25)
    plt.legend()
    plt.tight_layout()
    plt.savefig(FIG / "wall_time_vs_threads.png", dpi=180)
    plt.close()

    plt.figure(figsize=(7.0, 4.8))
    for platform in DATASETS:
        x, y = series(platform, "throughput_gpushes_s")
        plt.plot(x, y, styles[platform], label=platform)
    plt.xscale("log", base=2)
    plt.xlabel("OpenMP threads")
    plt.ylabel("Throughput (G particle-pushes/s)")
    plt.title("A01 Boris OpenMP: Throughput")
    plt.grid(True, which="both", alpha=0.25)
    plt.legend()
    plt.tight_layout()
    plt.savefig(FIG / "throughput_vs_threads.png", dpi=180)
    plt.close()

    plt.figure(figsize=(7.0, 4.8))
    for platform in DATASETS:
        x, y = series(platform, "speedup_vs_8")
        plt.plot(x, y, styles[platform], label=platform)
    plt.xscale("log", base=2)
    plt.xlabel("OpenMP threads")
    plt.ylabel("Speedup relative to 8 threads")
    plt.title("A01 Boris OpenMP: Scaling")
    plt.grid(True, which="both", alpha=0.25)
    plt.legend()
    plt.tight_layout()
    plt.savefig(FIG / "speedup_vs_threads.png", dpi=180)
    plt.close()


def main() -> int:
    rows = collect_rows()
    add_speedups(rows)
    write_summary(rows)
    maybe_make_figures(rows)

    print("A01_Boris_3Dxyz_omp comparison")
    for row in sorted(rows, key=lambda x: (int(x["threads"]), str(x["platform"]))):
        print(
            f"  {row['platform']:7s} threads={int(row['threads']):3d} "
            f"compute={float(row['compute_wall_time_s']):9.3f}s "
            f"throughput={float(row['throughput_gpushes_s']):7.3f} Gpush/s"
        )
    print(f"  wrote {OUT / 'summary.csv'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
