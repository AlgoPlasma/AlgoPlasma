#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output"
CSV_PATH = OUT / "b03_bspline_scatter.csv"
FIG = OUT / "figures"


def read_rows() -> list[dict[str, str]]:
    with CSV_PATH.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def analyze(rows: list[dict[str, str]]) -> dict[str, object]:
    by_case: dict[str, list[float]] = defaultdict(list)
    by_case_order: dict[tuple[str, int], list[float]] = defaultdict(list)
    failures: list[dict[str, object]] = []

    for row in rows:
        err = abs(float(row["abs_error"]))
        tol = float(row["tolerance"])
        case = row["case"]
        order = int(row["order"])
        by_case[case].append(err)
        by_case_order[(case, order)].append(err)

        if err > tol:
            failures.append(
                {
                    "case": case,
                    "order": order,
                    "d": int(row["d"]),
                    "metric": row["metric"],
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
            "tolerance": max(
                float(row["tolerance"]) for row in rows if row["case"] == case
            ),
            "pass": (max(errors) if errors else 0.0)
            <= max(float(row["tolerance"]) for row in rows if row["case"] == case),
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


def stencil_1d(order: int, xp: float) -> tuple[list[int], list[float]]:
    i0 = int((xp - 0.5 * float(order - 1)) // 1)
    idx = [i0 + a for a in range(order + 1)]
    weight = [centered_bspline_shape(order, xp - i) for i in idx]
    sw = sum(weight)
    if sw > 0.0:
        weight = [w / sw for w in weight]
    return idx, weight


def save_figure(fig, name: str) -> None:
    FIG.mkdir(parents=True, exist_ok=True)
    fig.savefig(FIG / name, dpi=180, bbox_inches="tight")


def maybe_make_figures(rows: list[dict[str, str]], summary: dict[str, object]) -> None:
    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except Exception as exc:  # pragma: no cover - optional diagnostic output
        print(f"WARNING: matplotlib unavailable, skipping figures: {exc}")
        return

    plt.rcParams.update(
        {
            "font.size": 9,
            "axes.titlesize": 11,
            "axes.labelsize": 9,
            "legend.fontsize": 8,
            "xtick.labelsize": 8,
            "ytick.labelsize": 8,
        }
    )

    curve_colors = ["#7EA6C8", "#F2B880", "#8BCB88", "#E89AA0", "#C5A3D8"]
    fig, ax = plt.subplots(figsize=(7.2, 4.8))
    for order, color in zip(range(5), curve_colors):
        half_width = 0.5 * float(order + 1)
        x0 = -half_width - 0.35
        x1 = half_width + 0.35
        xs = [x0 + (x1 - x0) * i / 500.0 for i in range(501)]
        ys = [centered_bspline_shape(order, x) for x in xs]
        ax.plot(xs, ys, linewidth=2.0, color=color, label=f"order={order}")

    ax.set_xlabel("Particle-grid distance r")
    ax.set_ylabel("Shape weight S_order(r)")
    ax.set_title("Centered B-spline shape functions used by B03 scatter")
    ax.grid(True, alpha=0.22)
    ax.legend(loc="upper right", ncol=1, frameon=False)
    fig.tight_layout()
    save_figure(fig, "b03_bspline_scatter_shape_curves.png")
    plt.close(fig)

    particle = (5.35, 5.65, 5.20)
    fig, axes = plt.subplots(2, 2, figsize=(7.4, 6.0), constrained_layout=True)
    for ax, order in zip(axes.flat, range(1, 5)):
        ix, wx = stencil_1d(order, particle[0])
        iy, wy = stencil_1d(order, particle[1])
        footprint = [[wy[j] * wx[i] for i in range(len(ix))] for j in range(len(iy))]
        im = ax.imshow(
            footprint,
            origin="lower",
            cmap="YlGnBu",
            extent=[min(ix) - 0.5, max(ix) + 0.5, min(iy) - 0.5, max(iy) + 0.5],
            aspect="equal",
        )
        ax.scatter([particle[0]], [particle[1]], s=28, c="#D1495B", marker="x")
        ax.set_title(f"order={order}")
        ax.set_xlabel("i")
        ax.set_ylabel("j")
        fig.colorbar(im, ax=ax, fraction=0.046, pad=0.03)

    fig.suptitle("Single-particle xy deposition footprint after summing z weights")
    save_figure(fig, "b03_bspline_scatter_single_particle_footprint.png")
    plt.close(fig)

    invariant_rows = [row for row in rows if row["metric"] != "max_abs_grid"]
    scatter_colors = {
        "number_conservation": "#79A7D3",
        "component_conservation": "#B99AD6",
        "number_first_moment": "#76B77D",
        "component_first_moment": "#E39A9F",
    }
    fig, ax = plt.subplots(figsize=(6.8, 5.0))
    for case, color in scatter_colors.items():
        xs = [float(row["reference"]) for row in invariant_rows if row["case"] == case]
        ys = [float(row["value"]) for row in invariant_rows if row["case"] == case]
        if xs:
            ax.scatter(xs, ys, s=28, alpha=0.78, label=case, color=color)

    all_values = [float(row["reference"]) for row in invariant_rows] + [
        float(row["value"]) for row in invariant_rows
    ]
    lo = min(all_values)
    hi = max(all_values)
    pad = 0.04 * (hi - lo + 1.0e-30)
    ax.plot([lo - pad, hi + pad], [lo - pad, hi + pad], "--", color="#555555")
    ax.set_xlabel("Reference invariant")
    ax.set_ylabel("Measured invariant from den")
    ax.set_title("B03 scatter: conservation and first-moment checks")
    ax.grid(True, alpha=0.25)
    ax.legend(frameon=False, loc="best")
    fig.tight_layout()
    save_figure(fig, "b03_bspline_scatter_ref_vs_value.png")
    plt.close(fig)

    case_orders = summary["case_orders"]
    palette = {
        "order1_b01_number": "#F8DDA4",
        "order1_b01_component": "#F8DDA4",
        "number_conservation": "#BFDDF2",
        "component_conservation": "#D8C5F2",
        "number_first_moment": "#C5E6C8",
        "component_first_moment": "#F4C8C8",
        "number_accumulation": "#C9D7E8",
        "component_accumulation": "#C9D7E8",
    }
    labels = []
    values = []
    colors = []
    for key in sorted(case_orders):
        case, order_text = key.split(":")
        order_label = order_text.replace("order", "m=")
        labels.append(f"{case}  {order_label}")
        values.append(max(float(case_orders[key]["max_abs_error"]), 1.0e-18))
        colors.append(palette.get(case, "#D5DADF"))

    fig, ax = plt.subplots(figsize=(8.2, 6.4))
    y = list(range(len(values)))
    ax.barh(y, values, color=colors, edgecolor="#7f8a99", linewidth=0.5)
    ax.set_xscale("log")
    ax.set_yticks(y)
    ax.set_yticklabels(labels)
    ax.invert_yaxis()
    ax.set_xlabel("Maximum absolute error")
    ax.set_title("B03 scatter: maximum error by subtest and order")
    ax.grid(True, axis="x", which="both", alpha=0.25)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    fig.tight_layout()
    save_figure(fig, "b03_bspline_scatter_errors.png")
    plt.close(fig)


def main() -> int:
    rows = read_rows()
    summary = analyze(rows)
    maybe_make_figures(rows, summary)

    (OUT / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True), encoding="utf-8"
    )

    print("B03_scatter_3Dxyz_bspline summary")
    print(f"  rows          : {summary['rows']}")
    for case, item in summary["cases"].items():
        print(
            f"  {case:<26}: max_abs={item['max_abs_error']:.3e}, "
            f"tol={item['tolerance']:.1e}, rows={item['rows']}"
        )
    print(f"  failures      : {summary['failure_count']}")
    print("  result        :", "PASS" if summary["pass"] else "FAIL")

    return 0 if summary["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
