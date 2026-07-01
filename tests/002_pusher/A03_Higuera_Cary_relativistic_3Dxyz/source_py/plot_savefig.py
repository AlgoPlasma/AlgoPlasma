import os
import numpy as np

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


def load_dat(fname: str) -> np.ndarray:
    return np.loadtxt(fname, comments="#")


def ensure_dir(d: str):
    os.makedirs(d, exist_ok=True)


def unpack(data: np.ndarray):
    # step t x y z vx vy vz v2 x_ana y_ana z_ana vx_ana vy_ana vz_ana err_v err_r
    t  = data[:, 1]
    x  = data[:, 2]; y  = data[:, 3]; z  = data[:, 4]
    v2 = data[:, 8]
    xa = data[:, 9]; ya = data[:,10]; za = data[:,11]
    err_v = data[:,15]; err_r = data[:,16]
    return t, x, y, z, v2, xa, ya, za, err_v, err_r


def save_traj_xy(x, y, xa, ya, title, outpath):
    plt.figure()
    plt.plot(x, y, label="numeric")
    plt.plot(xa, ya, "--", label="analytic")
    plt.xlabel("x")
    plt.ylabel("y")
    plt.title(title)
    plt.axis("equal")
    plt.grid(True)
    plt.legend()
    plt.tight_layout()
    plt.savefig(outpath, dpi=200)
    plt.close()


def _load_and_report(fname: str, tag: str):
    if not os.path.isfile(fname):
        print(f"{tag:<6} {'[missing file]':>12} {'':>12}")
        return None

    d = load_dat(fname)
    t, x, y, z, v2, xa, ya, za, err_v, err_r = unpack(d)

    label = f"{tag}:"
    print(f"{label:<7} max err_v={err_v.max():12.3e}, max err_r={err_r.max():12.3e}")
    return t, x, y, z, v2, xa, ya, za, err_v, err_r


def _case_prefix_from_path(fname: str) -> str:
    base = os.path.basename(fname)
    stem = os.path.splitext(base)[0]
    return stem.split("_", 1)[0]


def plot_case_gyro(fname: str, out_dir: str):
    prefix = _case_prefix_from_path(fname)
    res = _load_and_report(fname, "gyro")
    if res is None:
        return
    t, x, y, z, v2, xa, ya, za, err_v, err_r = res

    save_traj_xy(
        x, y, xa, ya,
        "Case 01: gyro trajectory (x-y)",
        os.path.join(out_dir, f"{prefix}_gyro_traj_xy.png")
    )

    plt.figure()
    plt.plot(t, v2)
    plt.xlabel("t")
    plt.ylabel("${v}^2$")
    plt.title("Case 01: gyro ${v}^2$ conservation")
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(os.path.join(out_dir, f"{prefix}_gyro_v2_t.png"), dpi=200)
    plt.close()


def plot_case_exb_drift(fname: str, out_dir: str):
    prefix = _case_prefix_from_path(fname)
    res = _load_and_report(fname, "HC_g20")
    if res is None:
        return
    t, x, y, z, v2, xa, ya, za, err_v, err_r = res

    # x should stay at 0; plot x(t) to show any drift
    plt.figure()
    plt.plot(t, x, label="|x| (numeric)")
    plt.axhline(0.0, linestyle="--", color="gray", label="x = 0 (analytic)")
    plt.xlabel("t")
    plt.ylabel("x")
    plt.title("Case 02: HC gamma=20 force-free ExB drift — x(t)")
    plt.grid(True)
    plt.legend()
    plt.tight_layout()
    plt.savefig(os.path.join(out_dir, f"{prefix}_exb_drift_x_t.png"), dpi=200)
    plt.close()

    save_traj_xy(
        x, y, xa, ya,
        r"Case 02: HC $\gamma$=20 force-free ExB drift (x-y)",
        os.path.join(out_dir, f"{prefix}_exb_drift_traj_xy.png")
    )


def main():
    out_dir = "figs_cases"
    ensure_dir(out_dir)

    plot_case_gyro("./build/case01_gyro.dat",               out_dir=out_dir)
    plot_case_exb_drift("./build/case02_exb_drift.dat",     out_dir=out_dir)
    print(f"Done. Figures saved to ./{out_dir}/")


if __name__ == "__main__":
    main()
