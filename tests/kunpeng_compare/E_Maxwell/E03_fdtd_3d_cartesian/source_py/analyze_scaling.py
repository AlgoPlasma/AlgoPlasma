#!/usr/bin/env python3
from __future__ import annotations

import csv
import sys
from pathlib import Path


NUMERIC_FIELDS = {
    "nx",
    "ny",
    "nz",
    "nsteps",
    "repeats",
    "threads",
    "cells_per_step",
    "total_component_updates",
    "avg_s",
    "best_s",
    "worst_s",
    "component_updates_per_s",
    "checksum_e",
    "checksum_h",
    "total_energy",
}


def as_float(row: dict[str, str], key: str) -> float:
    return float(row[key].strip())


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: analyze_scaling.py <raw_csv> <output_csv>", file=sys.stderr)
        return 2

    raw_path = Path(sys.argv[1])
    out_path = Path(sys.argv[2])

    with raw_path.open(newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))

    if not rows:
        raise SystemExit(f"{raw_path}: no rows found")

    baseline_by_platform: dict[str, float] = {}
    for row in rows:
        if int(as_float(row, "threads")) == 1:
            baseline_by_platform[row["platform"]] = as_float(row, "avg_s") / as_float(row, "nsteps")

    output_fields = [
        "platform",
        "hostname",
        "cpu_model",
        "compiler",
        "fc",
        "fcflags",
        "omp_proc_bind",
        "omp_places",
        "nx",
        "ny",
        "nz",
        "nsteps",
        "repeats",
        "threads",
        "cells_per_step",
        "single_step_avg_s",
        "single_step_best_s",
        "single_step_worst_s",
        "avg_s",
        "best_s",
        "worst_s",
        "component_updates_per_s",
        "speedup_vs_1",
        "efficiency_vs_1",
        "checksum_e",
        "checksum_h",
        "total_energy",
        "parallel_note",
    ]

    out_rows: list[dict[str, str]] = []
    for row in rows:
        nsteps = as_float(row, "nsteps")
        threads = as_float(row, "threads")
        single_step_avg = as_float(row, "avg_s") / nsteps
        single_step_best = as_float(row, "best_s") / nsteps
        single_step_worst = as_float(row, "worst_s") / nsteps
        baseline = baseline_by_platform.get(row["platform"])
        if baseline and single_step_avg > 0.0:
            speedup = baseline / single_step_avg
            efficiency = speedup / threads
            speedup_text = f"{speedup:.16e}"
            efficiency_text = f"{efficiency:.16e}"
        else:
            speedup_text = ""
            efficiency_text = ""

        if "ALGOPLASMA_E03_USE_OMPDO" in row.get("fcflags", ""):
            parallel_note = "E03 FDTD benchmark uses one outer OpenMP parallel region with H/E ompdo kernels."
        else:
            parallel_note = "E03 FDTD H/E update kernels use OpenMP parallel do collapse(3) over the Cartesian grid."

        out_row = {field: row.get(field, "") for field in output_fields}
        out_row.update(
            {
                "single_step_avg_s": f"{single_step_avg:.16e}",
                "single_step_best_s": f"{single_step_best:.16e}",
                "single_step_worst_s": f"{single_step_worst:.16e}",
                "speedup_vs_1": speedup_text,
                "efficiency_vs_1": efficiency_text,
                "parallel_note": parallel_note,
            }
        )
        out_rows.append(out_row)

    out_rows.sort(key=lambda row: (row["platform"], int(float(row["threads"]))))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=output_fields)
        writer.writeheader()
        writer.writerows(out_rows)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
