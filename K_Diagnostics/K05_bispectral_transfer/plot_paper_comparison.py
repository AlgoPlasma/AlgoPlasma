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
from matplotlib.ticker import ScalarFormatter, LogLocator, FixedLocator, AutoMinorLocator, NullFormatter


def plot(output, figure="all", destination=None):
    output = Path(output)
    a = np.load(output / "comparison_arrays.npz")
    destination = Path(destination) if destination else output
    destination.mkdir(parents=True, exist_ok=True)
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
                ax.grid(alpha=.13 if name.endswith("3") else 0)
        fig.savefig(destination / (name + ".png"), dpi=180)
        fig.savefig(destination / (name + ".svg"), metadata={"Date": None})
        p = destination / (name + ".svg")
        p.write_text("\n".join(line.rstrip() for line in p.read_text(encoding="utf-8").splitlines()) + "\n", encoding="utf-8")
        plt.close(fig)

    bad = ~a["admissible"].all(axis=0)
    if figure in ("all", "2"):
        # Brown & Jorns Fig. 2: fixed paper limits, no extrapolation or refit.
        # Panel (b)'s unlabelled frame endpoints are read as approx. 0.2--4000.
        fig = plt.figure(figsize=(10, 6.6), layout="constrained")
        gs = fig.add_gridspec(2, 2, height_ratios=[1, 1])
        ax0, ax1, ax2 = fig.add_subplot(gs[0, 0]), fig.add_subplot(gs[0, 1]), fig.add_subplot(gs[1, :])
        theory_ax = ax2.twinx()
        for ax in (ax0, ax1, ax2, theory_ax):
            ax.spines[["top", "right"]].set_visible(True)
            ax.tick_params(which="both", direction="in", top=True, right=True)
        def scientific(ax, axis, exponent):
            formatter = ScalarFormatter(useMathText=True)
            formatter.set_powerlimits((exponent, exponent))
            formatter.set_useOffset(False)
            getattr(ax, axis + "axis").set_major_formatter(formatter)

        ax0.plot(a["dispersion_ky"], a["dispersion_omega"].real / (2*np.pi), color=green)
        ax0.set(xlim=(0, 1e4), ylim=(0, 5e7), xticks=[0, 5000, 10000], yticks=[0, 5e7],
                xlabel=r"Wave number $k_y$, [1/m]", ylabel=r"$\omega_k/(2\pi)$ [Hz]")
        ax0.xaxis.set_minor_locator(AutoMinorLocator(2))
        scientific(ax0, "y", 7)
        ax0.text(.03, .9, "(a)", transform=ax0.transAxes)

        psd_f = a["psd_frequency_hz"]
        keep = psd_f >= 1e5
        for ch, color, label, style in [
                ("c1", blue, r"$X_f X_f^*$ (C1)", "-"),
                ("c3", orange, r"$Y_f Y_f^*$ (C3)", "--")]:
            # Unit conversion only: (microvolt)^2 = 1e-12 V^2. No normalization.
            band(ax1, psd_f[keep], a["psd_" + ch][:, keep] * 1e12, color, label, lw=1, ls=style)
        ax1.axvspan(f.min()*1e6, f.max()*1e6, color="gray", alpha=.12)
        ax1.set(xscale="log", yscale="log", xlim=(1e5, 1e8), ylim=(.2, 4e3),
                xlabel=r"Frequency $f$, [Hz]", ylabel=r"$P_f=S_V(f)$, [$\mu$V$^2$/Hz]")
        ax1.xaxis.set_major_locator(FixedLocator([1e6, 1e7, 1e8]))
        ax1.xaxis.set_minor_locator(LogLocator(base=10, subs=np.arange(1, 10)))
        ax1.yaxis.set_major_locator(FixedLocator([1, 100]))
        ax1.yaxis.set_minor_locator(LogLocator(base=10, subs=np.arange(1, 10), numticks=100))
        ax1.xaxis.set_minor_formatter(NullFormatter())
        ax1.yaxis.set_minor_formatter(NullFormatter())
        ax1.text(.03, .9, "(b)", transform=ax1.transAxes)
        ax1.legend(fontsize=8.5, loc="upper right", frameon=False)

        for method, color, name in [("ls", blue, "Least squares (left)"),
                                     ("kim", orange, "Kim (left)")]:
            band(ax2, a["frequency_hz"], a[method + "_gamma"], color, name)
        theory_ax.plot(a["frequency_hz"], a["theoretical_gamma"], color=green, ls="--",
                       label=r"$\gamma_f$ model (right)")
        ax2.scatter(a["frequency_hz"][bad], a["kim_gamma"].mean(axis=0)[bad], s=15,
                    facecolors="white", edgecolors=orange, linewidths=.8, zorder=5)
        ax2.set(xlabel=r"Frequency $f$, [Hz]", ylabel=r"$\gamma_{f(y)}$, [1/s]",
                xlim=(0, 3.5e7), ylim=(-.5e5, 3e5),
                xticks=np.arange(0, 3.5e7+1, .5e7), yticks=np.arange(4)*1e5)
        theory_ax.set(ylim=(-.5e6, 3e6), ylabel=r"$\gamma_f$, [1/s]", yticks=np.arange(4)*1e6)
        scientific(ax2, "x", 7)
        scientific(ax2, "y", 5)
        scientific(theory_ax, "y", 6)
        ax2.xaxis.set_minor_locator(AutoMinorLocator(2))
        ax2.text(.015, .9, "(c)", transform=ax2.transAxes)
        handles, labels = ax2.get_legend_handles_labels()
        h2, l2 = theory_ax.get_legend_handles_labels()
        ax2.legend(handles+h2, labels+l2, fontsize=8.5, loc="upper right", frameon=False)
        save(fig, "k05-comparison-figure2")

    if figure in ("all", "3"):
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
        figures={p.name: sha(p) for p in destination.glob("k05-comparison-figure*")},
        selected_figure=figure,
        figure2_axes={
            "a": {"x_m_inverse": [0, 10000], "y_hz": [0, 5e7], "ordinate": "Re(omega)/(2*pi)"},
            "b": {"x_hz": [1e5, 1e8], "y_microvolt_squared_per_hz": [.2, 4000],
                  "paper_unlabelled_y_endpoints_approximate": True,
                  "unit_conversion": "S_V in V^2/Hz times 1e12; no amplitude normalization"},
            "c": {"x_hz": [0, 3.5e7], "left_per_s": [-5e4, 3e5], "right_per_s": [-5e5, 3e6]},
            "out_of_range": "clipped by fixed axes only; all saved arrays unchanged",
            "uncovered_frequency": "blank; no extrapolation"})
    (destination / "plot_provenance.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print(f"Saved selection {figure} from unchanged comparison arrays to {destination}.")


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--output", type=Path, required=True)
    p.add_argument("--figure", choices=("all", "2", "3"), default="all")
    p.add_argument("--destination", type=Path, help="Separate plot directory; input arrays stay under --output")
    args = p.parse_args()
    plot(args.output, args.figure, args.destination)
