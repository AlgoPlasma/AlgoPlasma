#!/usr/bin/env python3
"""Validate the published 256x256 application grid before compiling or running."""
import math
import sys
from pathlib import Path


def validate(root):
    for name in ("grid_r.dat", "grid_z.dat"):
        path = root / name
        rows = [line.split() for line in path.read_text().splitlines()
                if line.strip() and not line.lstrip().startswith("#")]
        if len(rows) != 256:
            raise ValueError(f"{path}: expected 256 rows, got {len(rows)}")
        previous = None
        for index, row in enumerate(rows, 1):
            if len(row) != 4:
                raise ValueError(f"{path}: row {index} needs index, lower, upper, width")
            i = int(row[0])
            lo, hi, width = map(float, row[1:])
            if i != index or not all(map(math.isfinite, (lo, hi, width))):
                raise ValueError(f"{path}: invalid row {index}")
            if hi <= lo or width <= 0 or not math.isclose(width, hi-lo, rel_tol=1e-10, abs_tol=1e-15):
                raise ValueError(f"{path}: invalid width at row {index}")
            if previous is not None and not math.isclose(previous, lo, rel_tol=1e-12, abs_tol=1e-15):
                raise ValueError(f"{path}: discontinuous edge at row {index}")
            if name == "grid_r.dat" and lo < 0:
                raise ValueError(f"{path}: negative radius")
            previous = hi


if __name__ == "__main__":
    try:
        if len(sys.argv) != 2:
            raise ValueError("usage: validate_application_inputs.py INPUT_DIRECTORY")
        validate(Path(sys.argv[1]))
    except (OSError, ValueError) as exc:
        print(f"Input error: {exc}", file=sys.stderr)
        raise SystemExit(2)
    print("Application input grid: PASS")
