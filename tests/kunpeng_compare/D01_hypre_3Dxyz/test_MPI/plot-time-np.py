#!/usr/bin/env python3
import csv
import glob
import os
import re
import statistics

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


# Expected log names:
#   run_gcc_np4_omp1_1.log
#   run_bisheng_np4_omp1_1.log
#   run_AMD_np4_omp1_1.log
filename_pattern = re.compile(
    r"run_(?P<compiler>gcc|bisheng|AMD)_np(?P<np>\d+)_omp(?P<omp>\d+)_(?P<rep>\d+)\.log"
)

hypre_pattern = re.compile(r"\[TIME\]\s+hypre_time_avg\s+=\s+([0-9.Ee+-]+)")
total_pattern = re.compile(r"\[TIME\]\s+total_time\s+=\s+([0-9.Ee+-]+)")

compiler_order = {"gcc": 0, "bisheng": 1, "AMD": 2}
compiler_label = {
    "gcc": "KP-GCC",
    "bisheng": "KP-BiSheng",
    "AMD": "AMD",
}
compiler_style = {
    "gcc": {"color": "#1f77b4", "marker": "o"},
    "bisheng": {"color": "#d62728", "marker": "s"},
    "AMD": {"color": "#2ca02c", "marker": "^"},
}


def avg(values):
    return statistics.mean(values)


def std(values):
    return statistics.stdev(values) if len(values) > 1 else 0.0


data = {}

for fname in sorted(glob.glob("run_*_np*_omp*_*.log")):
    m = filename_pattern.match(os.path.basename(fname))
    if not m:
        continue

    compiler = m.group("compiler")
    np_val = int(m.group("np"))
    omp_val = int(m.group("omp"))

    with open(fname, "r", errors="ignore") as f:
        text = f.read()

    mh = hypre_pattern.search(text)
    mt = total_pattern.search(text)

    if mh is None or mt is None:
        print(f"WARNING: time data not found in {fname}")
        continue

    key = (compiler, omp_val, np_val)
    data.setdefault(key, {"hypre": [], "total": []})
    data[key]["hypre"].append(float(mh.group(1)))
    data[key]["total"].append(float(mt.group(1)))

if not data:
    raise RuntimeError(
        "No valid log files found. Expected names like "
        "run_gcc_np4_omp1_1.log, run_bisheng_np4_omp1_1.log, "
        "or run_AMD_np4_omp1_1.log"
    )

rows = []
for (compiler, omp_val, np_val), vals in sorted(
    data.items(), key=lambda item: (item[0][1], item[0][2], compiler_order.get(item[0][0], 99))
):
    rows.append(
        {
            "compiler": compiler,
            "omp": omp_val,
            "np": np_val,
            "repeats": len(vals["hypre"]),
            "hypre_avg": avg(vals["hypre"]),
            "hypre_std": std(vals["hypre"]),
            "total_avg": avg(vals["total"]),
            "total_std": std(vals["total"]),
        }
    )

print("compiler omp np repeats hypre_avg hypre_std total_avg total_std")
for row in rows:
    print(
        f"{row['compiler']} {row['omp']} {row['np']} {row['repeats']} "
        f"{row['hypre_avg']:.8e} {row['hypre_std']:.8e} "
        f"{row['total_avg']:.8e} {row['total_std']:.8e}"
    )

with open("time_compare_gcc_bisheng_AMD_np.csv", "w", newline="") as f:
    writer = csv.DictWriter(
        f,
        fieldnames=[
            "compiler",
            "omp",
            "np",
            "repeats",
            "hypre_avg",
            "hypre_std",
            "total_avg",
            "total_std",
        ],
    )
    writer.writeheader()
    writer.writerows(rows)

omp_values = sorted({row["omp"] for row in rows})
expected_compilers = ["gcc", "bisheng", "AMD"]

for omp_val in omp_values:
    sub_omp = [row for row in rows if row["omp"] == omp_val]
    np_values = sorted({row["np"] for row in sub_omp})
    available_compilers = [
        compiler for compiler in expected_compilers
        if any(row["compiler"] == compiler for row in sub_omp)
    ]

    if not available_compilers:
        print(f"WARNING: no gcc/bisheng/AMD data for OMP={omp_val}, skip plot")
        continue

    plt.figure(figsize=(11, 6))

    for compiler in expected_compilers:
        sub = [row for row in sub_omp if row["compiler"] == compiler]
        if not sub:
            print(f"WARNING: no data for {compiler}, OMP={omp_val}, skip")
            continue

        sub.sort(key=lambda x: x["np"])
        x_np = [row["np"] for row in sub]
        hypre_avg = [row["hypre_avg"] for row in sub]
        total_avg = [row["total_avg"] for row in sub]
        style = compiler_style.get(compiler, {})

        plt.plot(
            x_np,
            hypre_avg,
            marker=style.get("marker", "o"),
            color=style.get("color"),
            linewidth=1.8,
            label=f"{compiler_label.get(compiler, compiler)} HYPRE avg",
        )
        plt.plot(
            x_np,
            total_avg,
            marker=style.get("marker", "o"),
            color=style.get("color"),
            linestyle="--",
            linewidth=1.8,
            label=f"{compiler_label.get(compiler, compiler)} total",
        )

    plt.xlabel("MPI ranks")
    plt.ylabel("Time [s]")
    title_prefix = " vs ".join(compiler_label.get(c, c) for c in available_compilers)
    plt.title(f"{title_prefix}: HYPRE and total time vs MPI ranks, OMP={omp_val}")
    plt.xticks(np_values)
    plt.grid(True, alpha=0.35)
    plt.legend()
    plt.tight_layout()

    out_prefix = "_".join(available_compilers)
    outname = f"time_compare_{out_prefix}_np_omp{omp_val}.png"
    plt.savefig(outname, dpi=300)
    plt.close()
    print(f"Generated plot: {outname}")

print("Generated table: time_compare_gcc_bisheng_AMD_np.csv")
