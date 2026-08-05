#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
import math
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output"
FIG = OUT / "figures"

COMPONENTS = ["Ex", "Ey", "Ez", "Bx", "By", "Bz"]


def exact_poly_component(comp: int, x: float, y: float, z: float) -> float:
    c = float(comp)
    return (
        0.11 * c
        + 0.031 * c * x
        - 0.017 * (c + 1.0) * y
        + 0.013 * (c + 2.0) * z
        + 0.0011 * (c + 0.5) * x * y
        - 0.0007 * (c + 1.0) * x * z
        + 0.0009 * (c + 1.5) * y * z
        + 0.00012 * (c + 0.25) * x * y * z
    )


def smooth_component(comp: int, x: float, y: float, z: float) -> float:
    c = float(comp)
    twopi = 2.0 * math.pi
    return (
        math.sin(twopi * (x + 0.013 * c))
        + 0.27 * math.cos(twopi * (y - 0.011 * c))
        + 0.19 * math.sin(twopi * (z + 0.007 * c))
        + 0.08 * c * x * y
        - 0.05 * (c + 1.0) * y * z
        + 0.03 * (c + 2.0) * x * z
    )


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def analyze_exact() -> dict[str, object]:
    rows = read_csv(OUT / "c01_exact.csv")
    by_comp: dict[str, list[float]] = defaultdict(list)
    paired: list[tuple[str, float, float]] = []

    for row in rows:
        xg = float(row["px"]) + 0.5
        yg = float(row["py"]) + 0.5
        zg = float(row["pz"]) + 0.5
        for idx, name in enumerate(COMPONENTS, start=1):
            num = float(row[name])
            ref = exact_poly_component(idx, xg, yg, zg)
            err = abs(num - ref)
            by_comp[name].append(err)
            paired.append((name, ref, num))

    max_abs = max(max(vals) for vals in by_comp.values())
    return {
        "max_abs": max_abs,
        "by_component": {k: max(v) for k, v in by_comp.items()},
        "paired": paired,
        "pass": max_abs < 1.0e-11,
    }


def analyze_convergence() -> dict[str, object]:
    rows = read_csv(OUT / "c01_convergence.csv")
    errs: dict[int, list[float]] = defaultdict(list)
    linfs: dict[int, float] = defaultdict(float)

    for row in rows:
        n = int(row["n"])
        x = float(row["x"])
        y = float(row["y"])
        z = float(row["z"])
        for idx, name in enumerate(COMPONENTS, start=1):
            num = float(row[name])
            ref = smooth_component(idx, x, y, z)
            err = abs(num - ref)
            errs[n].append(err)
            linfs[n] = max(linfs[n], err)

    levels = sorted(errs)
    l2 = {n: math.sqrt(sum(e * e for e in vals) / len(vals)) for n, vals in errs.items()}
    orders = {}
    for n0, n1 in zip(levels, levels[1:]):
        orders[f"{n0}->{n1}"] = math.log(l2[n0] / l2[n1]) / math.log((1.0 / n0) / (1.0 / n1))

    min_order = min(orders.values()) if orders else float("nan")
    return {
        "levels": levels,
        "l2": l2,
        "linf": dict(linfs),
        "orders": orders,
        "min_order": min_order,
        "pass": min_order > 1.75,
    }


def analyze_push() -> dict[str, object]:
    rows = read_csv(OUT / "c01_push.csv")
    max_abs = 0.0
    traj = []

    for row in rows:
        q = float(row["q"])
        m = float(row["m"])
        dt = float(row["dt"])
        x0 = [float(row["x0"]), float(row["y0"]), float(row["z0"])]
        v0 = [float(row["vx0"]), float(row["vy0"]), float(row["vz0"])]
        x1 = [float(row["x1"]), float(row["y1"]), float(row["z1"])]
        v1 = [float(row["vx1"]), float(row["vy1"]), float(row["vz1"])]

        xg = [x0[0] + 0.5, x0[1] + 0.5, x0[2] + 0.5]
        e = [exact_poly_component(i, *xg) for i in range(1, 4)]
        vref = [v0[i] + q / m * dt * e[i] for i in range(3)]
        xref = [x0[i] + vref[i] * dt for i in range(3)]

        for got, ref in zip(v1 + x1, vref + xref):
            max_abs = max(max_abs, abs(got - ref))
        traj.append((x0[0], x0[1], x1[0], x1[1]))

    return {"max_abs": max_abs, "traj": traj, "pass": max_abs < 1.0e-11}


def maybe_make_figures(exact: dict[str, object], conv: dict[str, object], push: dict[str, object]) -> None:
    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except Exception as exc:  # pragma: no cover - optional diagnostic output
        print(f"WARNING: matplotlib unavailable, skipping figures: {exc}")
        return

    FIG.mkdir(parents=True, exist_ok=True)

    paired = exact["paired"]
    refs = [item[1] for item in paired]
    nums = [item[2] for item in paired]
    lo = min(refs + nums)
    hi = max(refs + nums)
    pad = 0.03 * (hi - lo + 1.0e-30)

    plt.figure(figsize=(6.6, 5.6))
    plt.scatter(refs, nums, s=12, alpha=0.75)
    plt.plot([lo - pad, hi + pad], [lo - pad, hi + pad], "k--", linewidth=1)
    plt.xlabel("Analytic Ex/Ey/Ez/Bx/By/Bz at particle")
    plt.ylabel("C01 gathered Ex/Ey/Ez/Bx/By/Bz")
    plt.title("C01: Analytic Field vs Gathered Field")
    plt.text(
        0.02,
        0.98,
        "Point = 1 particle x 1 field component\nComponents: Ex, Ey, Ez, Bx, By, Bz",
        transform=plt.gca().transAxes,
        va="top",
        ha="left",
        fontsize=9,
        bbox={"facecolor": "white", "alpha": 0.85, "edgecolor": "0.8"},
    )
    plt.tight_layout()
    plt.savefig(FIG / "c01_ref_vs_num.png", dpi=180)
    plt.close()

    levels = conv["levels"]
    hs = [1.0 / n for n in levels]
    l2 = [conv["l2"][n] for n in levels]
    linf = [conv["linf"][n] for n in levels]

    plt.figure(figsize=(6.8, 4.9))
    plt.loglog(hs, l2, "o-", label="L2: all particles/components")
    plt.loglog(hs, linf, "s-", label="Linf: max component error")
    plt.gca().invert_xaxis()
    plt.xlabel("Grid spacing h = 1/N")
    plt.ylabel("Error of gathered field components")
    plt.title("C01: Gather Error vs Grid Spacing")
    plt.grid(True, which="both", alpha=0.25)
    plt.legend()
    plt.tight_layout()
    plt.savefig(FIG / "c01_convergence.png", dpi=180)
    plt.close()

    traj = push["traj"]
    plt.figure(figsize=(6.2, 5.2))
    for x0, y0, x1, y1 in traj:
        plt.plot([x0, x1], [y0, y1], "-o", markersize=3, linewidth=1)
    plt.xlabel("Particle x position")
    plt.ylabel("Particle y position")
    plt.title("C01: Fused Gather-Push Displacement")
    plt.text(
        0.02,
        0.98,
        "Segment: (x0,y0) -> (x1,y1)\nB = 0, analytic electric acceleration",
        transform=plt.gca().transAxes,
        va="top",
        ha="left",
        fontsize=9,
        bbox={"facecolor": "white", "alpha": 0.85, "edgecolor": "0.8"},
    )
    plt.tight_layout()
    plt.savefig(FIG / "c01_push_displacement.png", dpi=180)
    plt.close()


def main() -> int:
    exact = analyze_exact()
    conv = analyze_convergence()
    push = analyze_push()

    summary = {
        "exact": {k: v for k, v in exact.items() if k != "paired"},
        "convergence": conv,
        "push": {k: v for k, v in push.items() if k != "traj"},
    }

    maybe_make_figures(exact, conv, push)

    summary["pass"] = bool(exact["pass"] and conv["pass"] and push["pass"])
    (OUT / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True), encoding="utf-8")

    print("C01_gather_3Dxyz summary")
    print(f"  exact max abs error      : {exact['max_abs']:.3e}")
    print(f"  convergence min order   : {conv['min_order']:.3f}")
    print(f"  fused push max abs error: {push['max_abs']:.3e}")
    print("  result                  :", "PASS" if summary["pass"] else "FAIL")

    return 0 if summary["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
