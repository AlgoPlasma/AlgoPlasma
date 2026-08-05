#!/usr/bin/env python3
"""Analyze B01 scatter OMP sweep logs from two platforms.

The Fortran benchmark sweeps an outer particle-count axis (`np`) and an inner
thread-count axis, recording avg/best/worst wall time per (np, nthread) point.
Each platform produces exactly one ``log.run`` under ``data_raw/from_<name>/``.

This script parses both logs (if present), writes ``output/summary.csv``, and
plots three figures only when *both* platforms have data:

* ``time_vs_threads.png``   — avg compute time vs threads (two subplots, one
  per platform; one curve per ``np``)
* ``speedup_vs_threads.png`` — ``t(1) / t(N)`` for each ``np`` per platform
* ``efficiency_vs_threads.png`` — ``speedup / nthread`` per ``np`` per platform
"""
from __future__ import annotations

import csv
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATASETS = {
    "AMD server": ROOT / "data_raw" / "from_AMD" / "log.run",
    "Kunpeng": ROOT / "data_raw" / "from_kunpeng" / "log.run",
}
OUT = ROOT / "output"
FIG = OUT / "figures"


def parse_log(platform: str, path: Path) -> list[dict]:
    """Parse one platform's single log file into a flat list of rows."""
    text = path.read_text(encoding="utf-8", errors="replace")

    rows: list[dict] = []
    cur_np: int | None = None
    np_re = re.compile(r"^---\s*np\s*=\s*(\d+)\s*---")
    pt_re = re.compile(
        r"nthread\s*=\s*(\d+)\s+"
        r"avg_s\s*=\s*([0-9.Ee+\-]+)\s+"
        r"best_s\s*=\s*([0-9.Ee+\-]+)\s+"
        r"worst_s\s*=\s*([0-9.Ee+\-]+)"
    )

    for raw_line in text.splitlines():
        line = raw_line.strip()
        m_np = np_re.match(line)
        if m_np:
            cur_np = int(m_np.group(1))
            continue
        m_pt = pt_re.search(line)
        if m_pt and cur_np is not None:
            nthread = int(m_pt.group(1))
            t_avg = float(m_pt.group(2))
            t_best = float(m_pt.group(3))
            t_worst = float(m_pt.group(4))
            rows.append({
                "platform": platform,
                "np": cur_np,
                "threads": nthread,
                "avg_s": t_avg,
                "best_s": t_best,
                "worst_s": t_worst,
            })

    if not rows:
        raise ValueError(f"{path}: no data rows parsed")
    return rows


def add_derived(rows: list[dict]) -> None:
    """Fill speedup and efficiency columns relative to t(nthread=1) at same np."""
    baseline: dict[tuple[str, int], float] = {}
    for row in rows:
        if row["threads"] == 1:
            baseline[(row["platform"], row["np"])] = row["avg_s"]

    for row in rows:
        base = baseline.get((row["platform"], row["np"]))
        if base is None or row["avg_s"] <= 0.0:
            row["speedup_vs_1"] = ""
            row["efficiency_vs_1"] = ""
            continue
        speedup = base / row["avg_s"]
        row["speedup_vs_1"] = speedup
        row["efficiency_vs_1"] = speedup / float(row["threads"])


def collect() -> tuple[list[dict], dict[str, bool]]:
    rows: list[dict] = []
    available: dict[str, bool] = {}
    for platform, log_path in DATASETS.items():
        if log_path.is_file():
            rows.extend(parse_log(platform, log_path))
            available[platform] = True
        else:
            available[platform] = False
    return rows, available


def write_summary(rows: list[dict]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    fields = [
        "platform", "np", "threads",
        "avg_s", "best_s", "worst_s",
        "speedup_vs_1", "efficiency_vs_1",
    ]
    with (OUT / "summary.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for row in sorted(rows, key=lambda r: (r["platform"], r["np"], r["threads"])):
            writer.writerow(row)


def make_figures(rows: list[dict]) -> None:
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except Exception as exc:
        print(f"WARNING: matplotlib unavailable, skipping figures: {exc}")
        return

    FIG.mkdir(parents=True, exist_ok=True)
    platforms = list(DATASETS.keys())
    nps = sorted({r["np"] for r in rows})

    cmap = plt.get_cmap("viridis")
    np_colors = {n: cmap(i / max(len(nps) - 1, 1)) for i, n in enumerate(nps)}

    def series(platform: str, np_val: int, key: str):
        subset = sorted(
            (r for r in rows if r["platform"] == platform and r["np"] == np_val),
            key=lambda r: r["threads"],
        )
        x = [r["threads"] for r in subset]
        y = [r[key] for r in subset if r[key] != ""]
        x = x[: len(y)]
        return x, [float(v) for v in y]

    def make_panel(key: str, title: str, ylabel: str, fname: str, yscale: str = "linear", ideal: bool = False):
        fig, axes = plt.subplots(1, 2, figsize=(13.5, 5.0), sharey=True)
        # sharey hides the right subplot's tick labels by default; re-enable
        # them so each subplot carries its own y-axis read-off while still
        # being on the same scale.
        axes[1].tick_params(axis="y", labelleft=True)
        for ax, platform in zip(axes, platforms):
            for n in nps:
                x, y = series(platform, n, key)
                if not x:
                    continue
                label = f"np = {n:,}"
                ax.plot(x, y, "o-", color=np_colors[n], label=label, linewidth=1.4, markersize=4.5)
            if ideal:
                xs = sorted({r["threads"] for r in rows if r["platform"] == platform})
                if key == "speedup_vs_1":
                    ax.plot(xs, xs, "k--", linewidth=0.8, alpha=0.45, label="ideal (= N)")
                elif key == "efficiency_vs_1":
                    ax.plot(xs, [1.0] * len(xs), "k--", linewidth=0.8, alpha=0.45, label="ideal (= 1)")
            ax.set_xscale("log", base=2)
            if yscale == "log":
                ax.set_yscale("log")
            ax.set_xlabel("OpenMP threads")
            ax.set_ylabel(ylabel)
            ax.set_title(platform)
            ax.grid(True, which="both", alpha=0.25)
            ax.legend(fontsize=8, loc="best")
        fig.suptitle(title)
        fig.tight_layout()
        fig.savefig(FIG / fname, dpi=180)
        plt.close(fig)

    make_panel("avg_s", "B01 Scatter OMP: avg compute time per call",
               "Avg compute time (s)", "time_vs_threads.png", yscale="log")
    make_panel("speedup_vs_1", "B01 Scatter OMP: speedup vs 1 thread",
               "Speedup = t(1) / t(N)", "speedup_vs_threads.png",
               yscale="log", ideal=True)
    make_panel("efficiency_vs_1", "B01 Scatter OMP: parallel efficiency",
               "Efficiency = speedup / N", "efficiency_vs_threads.png", ideal=True)


def main() -> int:
    rows, available = collect()
    if not rows:
        print("ERROR: no log files found under any platform directory.", file=sys.stderr)
        for platform, log_path in DATASETS.items():
            print(f"  {platform}: missing {log_path}", file=sys.stderr)
        return 1

    add_derived(rows)
    write_summary(rows)

    print("B01_scatter_3Dxyz_omp comparison")
    for platform, present in available.items():
        marker = "OK" if present else "missing"
        print(f"  {platform:7s}: {marker} ({DATASETS[platform]})")
    print(f"  wrote {OUT / 'summary.csv'} ({len(rows)} rows)")

    if not all(available.values()):
        missing = [p for p, ok in available.items() if not ok]
        print(f"  Skipping figures: still waiting for logs from {', '.join(missing)}.")
        return 0

    make_figures(rows)
    print(f"  wrote figures into {FIG}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
