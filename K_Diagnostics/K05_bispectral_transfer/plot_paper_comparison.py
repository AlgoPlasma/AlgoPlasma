"""Plot saved K05 equivalents of Brown & Jorns (2023) Figures 2 and 3."""
import argparse
import json
from pathlib import Path
import hashlib

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm


def plot(output):
    output = Path(output)
    a = np.load(output / "comparison_arrays.npz")
    summary = json.loads((output / "comparison_summary.json").read_text())
    f = a["frequency_hz"] / 1e6
    blue, orange, green = "#2368a2", "#bd6225", "#218575"
    plt.rcParams.update({
        "font.family": "DejaVu Sans", "font.size": 11, "axes.titlesize": 11,
        "axes.spines.top": False, "axes.spines.right": False, "svg.hashsalt": "k05-paper-r28",
    })
    def band(ax, x, values, color, label, **kw):
        ax.plot(x, values.mean(axis=0), color=color, label=label, **kw)
        ax.fill_between(x, values.min(axis=0), values.max(axis=0), color=color, alpha=.15)
    def save(fig, name):
        for ax in fig.axes:
            if ax.get_label() != "<colorbar>":
                ax.grid(alpha=.13)
        fig.savefig(output / (name + ".png"), dpi=180)
        fig.savefig(output / (name + ".svg"), metadata={"Date": None})
        p = output / (name + ".svg")
        p.write_text("\n".join(line.rstrip() for line in p.read_text().splitlines()) + "\n")
        plt.close(fig)

    fig = plt.figure(figsize=(10, 7.2), layout="constrained")
    gs = fig.add_gridspec(2, 2, height_ratios=[1, 1.15])
    ax0, ax1, ax2 = fig.add_subplot(gs[0, 0]), fig.add_subplot(gs[0, 1]), fig.add_subplot(gs[1, :])
    ax0.plot(a["dispersion_ky"] / 1e3, a["dispersion_omega"].real / (2*np.pi*1e6),
             color=green, label="Illustrative kinetic branch")
    ax0.set(xlabel=r"Azimuthal wave number $k_y$ [$10^3$ m$^{-1}$]",
            ylabel=r"Frequency $f=\omega_r/(2\pi)$ [MHz]",
            title="(a) Model dispersion: estimated inputs")
    ax0.legend(fontsize=9, loc="lower right")
    psd_f = a["psd_frequency_hz"] / 1e6
    keep = psd_f >= .1
    for ch, color in [("c1", blue), ("c3", orange)]:
        band(ax1, psd_f[keep], a["psd_" + ch][:, keep], color, ch.upper(), lw=1)
    ax1.axvspan(f.min(), f.max(), color="gray", alpha=.12, label="Coefficient-fit band")
    ax1.set(xscale="log", yscale="log", xlim=(.1, 50),
            xlabel=r"Frequency $f$ [MHz]", ylabel=r"Voltage PSD $S_V(f)$ [V$^2$/Hz]",
            title="(b) Measured spectra: four captures")
    ax1.legend(fontsize=8, ncol=1, loc="lower left")
    for method, color, name in [("ls", blue, "Least squares, conditional"),
                                 ("kim", orange, "Kim, conditional")]:
        band(ax2, f, a[method + "_gamma"] / 1e3, color, name)
    ax2.plot(f, a["theoretical_gamma"] / 1e3, color=green, ls="--",
             label=r"Model $\gamma_{\rm th}$ (estimated inputs)")
    bad = ~a["admissible"].all(axis=0)
    ax2.scatter(f[bad], a["kim_gamma"].mean(axis=0)[bad] / 1e3, s=15,
                facecolors="white", edgecolors=orange, linewidths=.8, zorder=5,
                label="Kim bound failed in at least one split")
    ax2.axhline(0, color="gray", lw=.8)
    ax2.set(xlabel=r"Frequency $f$ [MHz]",
            ylabel=r"$\gamma_{y,\rm app}$ and $\gamma_{\rm th}$ [$10^3$ s$^{-1}$]",
            title="(c) Apparent amplitude growth: one shared vertical scale", xlim=(f.min(), f.max()))
    ax2.legend(fontsize=8.5, ncol=2)
    save(fig, "k05-comparison-figure2")

    fig, (ax0, ax1) = plt.subplots(1, 2, figsize=(10, 4.6), layout="constrained",
                                  gridspec_kw={"width_ratios": [1.05, 1]})
    pair_f = a["pair_frequency_hz"] / 1e6
    values = abs(a["kim_q_map"]).mean(axis=0)
    cmap = plt.get_cmap("magma").copy()
    cmap.set_bad("#e2e5e9")
    im = ax0.pcolormesh(pair_f, pair_f, values, shading="nearest", cmap=cmap,
                       norm=LogNorm(vmin=1e-3, vmax=10), rasterized=True)
    ax0.set(xlabel=r"Input frequency $f_2$ [MHz]", ylabel=r"Input frequency $f_1$ [MHz]",
            aspect="equal", title=r"(a) Kim coefficient magnitude $|Q^{\rm sym}|$")
    cb = fig.colorbar(im, ax=ax0, shrink=.8, pad=.03, extend="min")
    cb.set_label(r"Mean $|Q^{\rm sym}|$ [V$^{-1}$]", fontsize=10)
    ax0.text(.03, .03, "Gray: not fitted\n0.54–4.98 MHz targets", transform=ax0.transAxes,
             fontsize=8.5, va="bottom", bbox=dict(facecolor="white", alpha=.9, edgecolor="none"))
    for method, color, name in [("ls", blue, "Least squares"), ("kim", orange, "Kim")]:
        band(ax1, f, a[method + "_transfer_half"], color, name)
    ax1.scatter(f[bad], a["kim_transfer_half"].mean(axis=0)[bad], s=12,
                facecolors="white", edgecolors=orange, linewidths=.7, zorder=5)
    ax1.axhline(0, color="gray", lw=.8)
    ax1.set(xlabel=r"Target frequency $f$ [MHz]",
            ylabel=r"Half-power proxy $T^{(1/2)}_{V,f}$ [V$^2$/s]",
            title="(b) Signed quadratic contribution", xlim=(f.min(), f.max()))
    ax1.legend(fontsize=9)
    save(fig, "k05-comparison-figure3")
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    metadata = dict(
        array_sha256=sha(output / "comparison_arrays.npz"),
        plot_source_sha256=sha(Path(__file__)),
        q_color_limits_v_inverse=[.001, 10], q_display_floor_only=True,
        figures={p.name: sha(p) for p in output.glob("k05-comparison-figure*")})
    (output / "plot_provenance.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print("Saved two SVG/PNG figures from unchanged comparison arrays.")


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--output", type=Path, required=True)
    plot(p.parse_args().output)
