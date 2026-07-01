import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


VT = (1.0, 2.0, 3.0)
VD = (0.5, -1.0, 2.0)


def ensure_dir(d):
    os.makedirs(d, exist_ok=True)


def load_dat(fname):
    return np.loadtxt(fname, comments="#")


def plot_velocity_histograms(fname, out_dir):
    if not os.path.isfile(fname):
        print(f"[missing] {fname}")
        return

    data = load_dat(fname)
    vx = data[:, 1]
    vy = data[:, 2]
    vz = data[:, 3]

    labels = ["vx", "vy", "vz"]
    vd_vals = VD
    vt_vals = VT
    v_arrays = [vx, vy, vz]

    fig, axes = plt.subplots(1, 3, figsize=(12, 4))
    for ax, v, label, vd, vt in zip(axes, v_arrays, labels, vd_vals, vt_vals):
        counts, bins, _ = ax.hist(v, bins=80, density=True, alpha=0.7, label="sampled")
        v_range = np.linspace(vd - 4*vt, vd + 4*vt, 300)
        gauss = np.exp(-0.5*((v_range - vd)/vt)**2) / (vt * np.sqrt(2*np.pi))
        ax.plot(v_range, gauss, "r-", lw=1.5, label=f"N({vd},{vt}²)")
        ax.set_xlabel(label)
        ax.set_ylabel("pdf")
        ax.set_title(f"{label}: mean={v.mean():.3f}, std={v.std():.3f}")
        ax.legend(fontsize=8)
        ax.grid(True)

    fig.suptitle("Case 04: Maxwellian velocity distribution (N=125000)")
    fig.tight_layout()
    fig.savefig(os.path.join(out_dir, "case04_maxwellian_hist.png"), dpi=200)
    plt.close(fig)
    print("Saved case04_maxwellian_hist.png")


def main():
    out_dir = "figs"
    ensure_dir(out_dir)
    plot_velocity_histograms("./build/case04_maxwellian.dat", out_dir)
    print(f"Done. Figures saved to ./{out_dir}/")


if __name__ == "__main__":
    main()
