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
    out = [
        "lambda_mm,npml,case,late_gate_step,late_reflection_error_db,"
        "final_interior_energy_db,max_abs_ref_probe"
    ]
    dirs = []
    for path in Path(".").glob("output_lambda*mm_npml*_equal"):
        match = re.fullmatch(r"output_lambda([0-9.]+)mm_npml([0-9]+)_equal", path.name)
        if match and (path / "metrics.dat").exists():
            dirs.append((float(match.group(1)), int(match.group(2)), path))

    for lambda_mm, npml, path in sorted(dirs):
        for case, gate, late, energy, ref in parse_metrics(path / "metrics.dat"):
            out.append(f"{lambda_mm:g},{npml},{case},{gate},{late:.8e},{energy:.8e},{ref:.8e}")

    Path("equal_lambda_npml_sweep_summary.csv").write_text("\n".join(out) + "\n")
    print(Path("equal_lambda_npml_sweep_summary.csv").read_text())


if __name__ == "__main__":
    main()
