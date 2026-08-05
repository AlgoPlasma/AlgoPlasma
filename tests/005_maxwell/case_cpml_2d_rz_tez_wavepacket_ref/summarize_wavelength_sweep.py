#!/usr/bin/env python3
from pathlib import Path
import re


def parse_metrics(path):
    rows = []
    for line in Path(path).read_text().strip().splitlines()[1:]:
        case, gate, late, energy, ref = [v.strip() for v in line.split(",")]
        rows.append((case, int(gate), float(late), float(energy), float(ref)))
    return rows


def main():
    out = ["lambda_mm,case,late_gate_step,late_reflection_error_db,final_interior_energy_db,max_abs_ref_probe"]
    dirs = []
    for d in Path(".").glob("output_lambda*mm*"):
        match = re.fullmatch(r"output_lambda([0-9.]+)mm(?:_saved)?", d.name)
        if match:
            dirs.append((float(match.group(1)), d))
    for lambda_mm, d in sorted(dirs):
        metrics = d / "metrics.dat"
        if not metrics.exists():
            continue
        for case, gate, late, energy, ref in parse_metrics(metrics):
            out.append(f"{lambda_mm:g},{case},{gate},{late:.8e},{energy:.8e},{ref:.8e}")
    Path("wavelength_sweep_summary.csv").write_text("\n".join(out) + "\n")
    print(Path("wavelength_sweep_summary.csv").read_text())


if __name__ == "__main__":
    main()
