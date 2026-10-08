#!/usr/bin/env python3
"""Plot this run's preprocessing and continuity fields; no archived solutions."""
from __future__ import annotations

import argparse
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


def read_field(path: Path, shape: tuple[int, int]) -> np.ndarray:
    values = np.fromfile(path, dtype=np.float64)
    if values.size != int(np.prod(shape)):
        raise ValueError(f"{path}: expected {np.prod(shape)} values, got {values.size}")
    return values.reshape(shape, order="F")


def edges(path: Path) -> np.ndarray:
    rows = np.loadtxt(path, comments="#", ndmin=2)
    result = np.concatenate((rows[:1, 1], rows[:, 2]))
    if not np.all(np.diff(result) > 0):
        raise ValueError(f"{path}: grid edges must increase")
    return result


def summary(path: Path) -> dict[str, str]:
    return dict(line.split("=", 1) for line in path.read_text().splitlines() if "=" in line)


def assess_balance(record: dict[str, str]) -> tuple[bool, float, float]:
    """Check steady continuity using rates, not the solver's flag alone."""
    names = ("inflow_rate", "outflow_rate", "production_rate", "removal_rate", "scaled_residual")
    values = np.array([float(record[name]) for name in names])
    if not np.isfinite(values).all():
        raise ValueError("non-finite balance diagnostics")
    pin, pout, production, removal, residual = values
    if min(pin, pout, production, removal, residual) < 0:
        raise ValueError("negative number rate or residual in balance diagnostics")
    balance = abs(pout + removal - pin - production) / max(
        pin + production, pout + removal, np.finfo(float).tiny)
    return bool(balance <= 1e-6 and residual <= 1e-8), float(balance), float(residual)


def validate_density(field: np.ndarray, mask: np.ndarray, label: str) -> None:
    """Reject invalid active cells; report one-based Fortran cell indices."""
    if field.shape != mask.shape or not mask.any():
        raise ValueError(f"{label}: inconsistent shape or no active cells")
    invalid = mask & (~np.isfinite(field) | (field < 0))
    if invalid.any():
        i, k = np.argwhere(invalid)[0]
        raise ValueError(f"{label}: density must be finite and nonnegative; "
                         f"i={i+1}, k={k+1}, value={field[i, k]}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("method", choices=("FM", "SN"))
    parser.add_argument("case_root", type=Path, help="case input data root")
    parser.add_argument("output", type=Path, help="current run output directory")
    args = parser.parse_args()
    grid = args.case_root
    r, z = edges(grid / "grid_r.dat"), edges(grid / "grid_z.dat")
    shape = (r.size - 1, z.size - 1)
    module = "j01" if args.method == "FM" else "j02"
    field = "na_j01_rz_f64.bin" if args.method == "FM" else "na_sn_rz_f64.bin"
    before = read_field(args.output / module / field, shape)
    after = read_field(args.output / "j03" / "na_cont_rz_f64.bin", shape)
    mask = read_field(args.output / module / "active_mask_rz_f64.bin", shape) > 0.5
    validate_density(before, mask, f"{module.upper()} preprocessing")
    validate_density(after, mask, "J03 continuity")
    record = summary(args.output / "j03" / "j03_run_summary.txt")
    converged = record.get("converged", "").strip() == "1"
    balance_ok, balance_error, scaled_residual = assess_balance(record)
    nonnegative = bool((after[mask] >= 0).all())
    if args.method == "FM":
        pre_record = summary(args.output / module / "j01_fm_summary.txt")
        pre_ok = int(pre_record["truncated"]) == 0
    else:
        pre_record = summary(args.output / module / "j02_run_summary.txt")
        pre_ok = pre_record.get("source_converged", "").strip() == "1"
    change = float(np.linalg.norm((after - before)[mask]) /
                   max(float(np.linalg.norm(before[mask])), np.finfo(float).tiny))
    fields = [np.where(mask, value, np.nan) for value in (before, after)]
    vmin = min(0.0, *(float(np.nanmin(value)) for value in fields))
    vmax = max(float(np.nanmax(value)) for value in fields)
    if vmax <= vmin:
        vmax = vmin + 1.0
    fig, axes = plt.subplots(1, 2, figsize=(10, 4.2), constrained_layout=True)
    for ax, value, title in zip(axes, fields, (f"{module.upper()} {args.method} preprocessing",
                                               "J03 steady density")):
        image = ax.pcolormesh(z, r, value, shading="auto", cmap="viridis",
                              vmin=vmin, vmax=vmax)
        ax.set(title=title, xlabel="z (m)", ylabel="r (m)")
    fig.colorbar(image, ax=axes, label="neutral density (m$^{-3}$)")
    fig.savefig(args.output / f"{module}_chain_density.png", dpi=160)
    plt.close(fig)
    passed = pre_ok and converged and balance_ok and nonnegative
    lines = [f"method={args.method}", f"preprocessing_complete={int(pre_ok)}",
             f"continuity_converged={int(converged)}", f"density_relative_l2_change={change:.8e}",
             "density_change_is_diagnostic_only=1",
             f"relative_balance={balance_error:.8e}", f"scaled_residual={scaled_residual:.8e}",
             f"continuity_nonnegative={int(nonnegative)}",
             "preprocessing_nonnegative=1",
             "checks=finite_active_densities,preprocessing_status,continuity_convergence,number_balance,residual,preprocessing_nonnegative,continuity_nonnegative",
             f"RESULT: {'PASS' if passed else 'FAIL'}"]
    report = "\n".join(lines) + "\n"
    (args.output / "summary.txt").write_text(report)
    print(report, end="")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
