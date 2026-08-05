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
    # e.g. "./build/case01_gyro.dat" -> "case01"
    base = os.path.basename(fname)
    stem = os.path.splitext(base)[0]          # "case01_gyro"
    return stem.split("_", 1)[0]              # "case01"


def plot_case_gyro(fname: str, kind: str, out_dir: str):
    prefix = _case_prefix_from_path(fname)    # "case01"
    title  = "Case: gyro trajectory (x-y)"

    res = _load_and_report(fname, "gyro")
    if res is None:
        return
    t, x, y, z, v2, xa, ya, za, err_v, err_r = res

    if kind == "traj":
        save_traj_xy(
            x, y, xa, ya,
            title,
            os.path.join(out_dir, f"{prefix}_gyro_traj_xy.png")
        )

        plt.figure()
        plt.plot(t, v2)
        plt.xlabel("t")
        plt.ylabel("${v}^2$")
        plt.title("Case: gyro ${v}^2$ conservation")
        plt.grid(True)
        plt.tight_layout()
        plt.savefig(os.path.join(out_dir, f"{prefix}_gyro_v2_t.png"), dpi=200)
        plt.close()


def plot_case_Eonly(fname: str, kind: str, out_dir: str):
    prefix = _case_prefix_from_path(fname)    # "case02"
    title  = "Case: E only x(t)"

    res = _load_and_report(fname, "Eonly")
    if res is None:
        return
    t, x, y, z, v2, xa, ya, za, err_v, err_r = res

    if kind == "xt":
        plt.figure()
        plt.plot(t, x, label="x")
        plt.plot(t, xa, "--", label="x_ana")
        plt.xlabel("t")
        plt.ylabel("x")
        plt.title(title)
        plt.grid(True)
        plt.legend()
        plt.tight_layout()
        plt.savefig(os.path.join(out_dir, f"{prefix}_Eonly_x_t.png"), dpi=200)
        plt.close()


def plot_case_ExB(fname: str, kind: str, out_dir: str):
    prefix = _case_prefix_from_path(fname)    # "case03"
    title  = r"Case: ExB trajectory (E $\perp$ B) in x-y"

    res = _load_and_report(fname, "ExB")
    if res is None:
        return
    t, x, y, z, v2, xa, ya, za, err_v, err_r = res

    if kind == "traj":
        save_traj_xy(
            x, y, xa, ya,
            title,
            os.path.join(out_dir, f"{prefix}_ExB_traj_xy.png")
        )


def plot_case_drift(fname: str, kind: str, out_dir: str):
    prefix = _case_prefix_from_path(fname)    # "case04"
    title  = r"Case: pure ExB drift (no gyration) in x-y"

    res = _load_and_report(fname, "drift")
    if res is None:
        return
    t, x, y, z, v2, xa, ya, za, err_v, err_r = res

    if kind == "traj":
        save_traj_xy(
            x, y, xa, ya,
            title,
            os.path.join(out_dir, f"{prefix}_drift_traj_xy.png")
        )


def main():
    out_dir = "figs_cases"
    ensure_dir(out_dir)

    plot_case_gyro("./build/case01_gyro.dat",       kind="traj", out_dir=out_dir)
    plot_case_Eonly("./build/case02_Eonly.dat",     kind="xt",   out_dir=out_dir)
    plot_case_ExB("./build/case03_ExB.dat",         kind="traj", out_dir=out_dir)
    plot_case_drift("./build/case04_ExB_drift.dat", kind="traj", out_dir=out_dir)

    print(f"Done. Figures saved to ./{out_dir}/")


if __name__ == "__main__":
    main()

