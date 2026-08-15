#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output"
CSV_PATH = OUT / "c02_bspline_gather.csv"
FIG = OUT / "figures"

THRESHOLDS = {
    "order1_c01": 1.0e-11,
    "constant": 1.0e-12,
    "linear": 1.0e-11,
}


def read_rows() -> list[dict[str, str]]:
    with CSV_PATH.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def analyze(rows: list[dict[str, str]]) -> dict[str, object]:
    by_case: dict[str, list[float]] = defaultdict(list)
    by_case_order: dict[tuple[str, int], list[float]] = defaultdict(list)
    failures: list[dict[str, object]] = []

    for row in rows:
        case = row["case"]
        order = int(row["order"])
        err = abs(float(row["abs_error"]))
        by_case[case].append(err)
        by_case_order[(case, order)].append(err)

        tol = THRESHOLDS[case]
        if err > tol:
            failures.append(
                {
                    "case": case,
                    "order": order,
                    "p": int(row["p"]),
                    "component": row["component"],
                    "reference": float(row["reference"]),
                    "value": float(row["value"]),
                    "abs_error": err,
                    "tolerance": tol,
                }
            )

    case_summary = {
        case: {
            "rows": len(errors),
            "max_abs_error": max(errors) if errors else 0.0,
            "tolerance": THRESHOLDS[case],
            "pass": (max(errors) if errors else 0.0) <= THRESHOLDS[case],
        }
        for case, errors in sorted(by_case.items())
    }

    order_summary = {
        f"{case}:order{order}": {
            "rows": len(errors),
            "max_abs_error": max(errors) if errors else 0.0,
        }
        for (case, order), errors in sorted(by_case_order.items())
    }

    return {
        "rows": len(rows),
        "cases": case_summary,
        "case_orders": order_summary,
        "failure_count": len(failures),
        "failures": failures[:20],
        "pass": len(failures) == 0,
    }


def centered_bspline_shape(order: int, r: float) -> float:
    if order < 0:
        raise ValueError("order must be non-negative")
    if order == 0:
        return 1.0 if -0.5 <= r < 0.5 else 0.0

    h = 0.5 * float(order + 1)
    if r <= -h or r >= h:
        return 0.0

    return (
        ((r + h) / float(order)) * centered_bspline_shape(order - 1, r + 0.5)
        + ((h - r) / float(order)) * centered_bspline_shape(order - 1, r - 0.5)
    )


def maybe_make_figures(rows: list[dict[str, str]], summary: dict[str, object]) -> None:
    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except Exception as exc:  # pragma: no cover - optional diagnostic output
        print(f"WARNING: matplotlib unavailable, skipping figures: {exc}")
        return

    FIG.mkdir(parents=True, exist_ok=True)

    scatter_colors = {
        "order1_c01": "#4C78A8",
        "constant": "#59A14F",
        "linear": "#F28E2B",
    }
    bar_colors = {
        "order1_c01": "#B9D7EA",
        "constant": "#B7E4C7",
        "linear": "#FFD6A5",
    }
    curve_colors = ["#7EA6C8", "#F2B880", "#8BCB88", "#E89AA0", "#C5A3D8"]

    fig, ax = plt.subplots(figsize=(7.4, 5.0))
    for order, color in zip(range(5), curve_colors):
        half_width = 0.5 * float(order + 1)
        x0 = -half_width - 0.35
        x1 = half_width + 0.35
        xs = [x0 + (x1 - x0) * i / 400.0 for i in range(401)]
        ys = [centered_bspline_shape(order, x) for x in xs]
        ax.plot(xs, ys, linewidth=2.0, color=color, label=f"order={order}")

    ax.set_xlabel("Particle-grid distance r")
    ax.set_ylabel("Shape weight S_order(r)")
    ax.set_title("Centered B-spline shape functions used by C02 gather")
    ax.grid(True, alpha=0.22)
    ax.legend(loc="upper right", ncol=1, frameon=False)
    fig.tight_layout()
    fig.savefig(
        FIG / "c02_bspline_gather_shape_curves.png", dpi=180, bbox_inches="tight"
    )
    plt.close(fig)

    plt.figure(figsize=(6.8, 5.4))
    for case in ("order1_c01", "constant", "linear"):
        xs = [float(row["reference"]) for row in rows if row["case"] == case]
        ys = [float(row["value"]) for row in rows if row["case"] == case]
        plt.scatter(xs, ys, s=16, alpha=0.68, label=case, color=scatter_colors[case])

    all_values = [float(row["reference"]) for row in rows] + [
        float(row["value"]) for row in rows
    ]
    lo = min(all_values)
    hi = max(all_values)
    pad = 0.04 * (hi - lo + 1.0e-30)
    plt.plot([lo - pad, hi + pad], [lo - pad, hi + pad], "k--", linewidth=1.0)
    plt.xlabel("Reference field value")
    plt.ylabel("C02 gathered field value")
    plt.title("C02 B-spline gather: reference vs gathered values")
    plt.grid(True, alpha=0.25)
    plt.legend(frameon=False)
    plt.tight_layout()
    plt.savefig(FIG / "c02_bspline_gather_ref_vs_value.png", dpi=180)
    plt.close()

    case_orders = summary["case_orders"]
    labels = []
    values = []
    bar_face_colors = []
    for key in sorted(case_orders):
        case, order_text = key.split(":")
        labels.append(f"{case}\n{order_text.replace('order', 'm=')}")
        values.append(max(float(case_orders[key]["max_abs_error"]), 1.0e-18))
        bar_face_colors.append(bar_colors[case])

    plt.figure(figsize=(8.6, 4.8))
    plt.bar(
        range(len(values)),
        values,
        color=bar_face_colors,
        edgecolor="#7f8a99",
        linewidth=0.55,
    )
    plt.yscale("log")
    plt.xticks(range(len(labels)), labels, rotation=35, ha="right")
    plt.ylabel("Maximum absolute error")
    plt.title("C02 B-spline gather: maximum error by subtest and order")
    plt.grid(True, axis="y", which="both", alpha=0.25)
    ax = plt.gca()
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    plt.tight_layout()
    plt.savefig(FIG / "c02_bspline_gather_errors.png", dpi=180)
    plt.close()


def main() -> int:
    rows = read_rows()
    summary = analyze(rows)
    maybe_make_figures(rows, summary)

    (OUT / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True), encoding="utf-8"
    )

    print("C02_gather_3Dxyz_bspline summary")
    print(f"  rows          : {summary['rows']}")
    for case, item in summary["cases"].items():
        print(
            f"  {case:<12}: max_abs={item['max_abs_error']:.3e}, "
            f"tol={item['tolerance']:.1e}, rows={item['rows']}"
        )
    print(f"  failures      : {summary['failure_count']}")
    print("  result        :", "PASS" if summary["pass"] else "FAIL")

    return 0 if summary["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
