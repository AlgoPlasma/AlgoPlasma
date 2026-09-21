"""Reproduce the four teaching figures in diagnostics_foundations.rst.

Run from any directory with the documentation Python environment. Uses only
NumPy, Matplotlib, and the repository's diagnostic routines; no signal files.
"""

from pathlib import Path
import sys

sys.dont_write_bytecode = True

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT))
from K_Diagnostics.K01_signal_spectra.mod_K01_signal_spectra import (
    fun_K01_segment_ffts,
    fun_K01_cross_phase,
    fun_K01_power_spectrum,
    fun_K01_phase_mode_statistics,
    fun_K01_wrap_to_pi,
)
from K_Diagnostics.K02_beall.mod_K02_beall import fun_K02_beall_spectrum
from K_Diagnostics.K03_mle_k2d.mod_K03_mle_k2d import (
    fun_K03_joint_log_likelihood,
)

OUT = Path(__file__).resolve().parent
FS, N, M = 32000.0, 256, 32
V, D, F0 = 20.0, 0.005, 1000.0
K0 = 2 * np.pi * F0 / V
BLUE, ORANGE = "#1768a6", "#dc6b27"
ANNOTATION_COLOR = "#59636e"


def signal(t, x, broadband=False):
    result = np.cos(2 * np.pi * F0 * (t - x / V))
    if broadband:
        result += 0.5 * np.cos(2 * np.pi * 3 * F0 * (t - x / V))
    return result


def save(fig, name):
    fig.savefig(OUT / name, dpi=180, facecolor="white")
    plt.close(fig)


def main():
    plt.rcParams.update({"font.size": 11, "axes.spines.top": False,
                         "axes.spines.right": False})
    t = np.arange(N * M) / FS
    x1, x2 = signal(t, 0, True), signal(t, D, True)
    fft1, fft2 = (fun_K01_segment_ffts(x, N) for x in (x1, x2))
    phase, magnitude = fun_K01_cross_phase(fft1, fft2)
    frequencies = np.fft.rfftfreq(N, 1 / FS)
    bins = [8, 24]
    expected = np.array([np.pi / 2, -np.pi / 2])
    np.testing.assert_allclose(phase[:, bins], np.tile(expected, (M, 1)), atol=1e-12)
    wrapped_mean, _ = fun_K01_phase_mode_statistics(np.deg2rad([179., -179.]))
    assert abs(abs(wrapped_mean) - np.pi) < 1e-12

    fig, axes = plt.subplots(1, 2, figsize=(10, 3.7), layout="constrained")
    tt = np.linspace(0, .002, 600)
    axes[0].plot(tt * 1e3, signal(tt, 0), color=BLUE, label=r"$x_1(t)$")
    axes[0].plot(tt * 1e3, signal(tt, D), color=ORANGE, label=r"$x_2(t)$")
    axes[0].annotate("", xy=(1.25, 1.15), xytext=(1., 1.15),
                     arrowprops={"arrowstyle": "<->", "color": "#333333"})
    axes[0].text(1.125, 1.26, r"$\tau=0.25\,\mathrm{ms}$", ha="center")
    axes[0].set(xlabel=r"$t$ (ms)", ylabel=r"$q$ (a.u.)", ylim=(-1.35, 1.65))
    axes[0].legend(loc="lower left", ncol=2)
    xx = np.linspace(0, .04, 600)
    axes[1].plot(xx * 1e3, signal(0, xx), color=BLUE)
    axes[1].scatter([0, D * 1e3], [1, 0], color=[BLUE, ORANGE], s=50, zorder=3)
    axes[1].text(.8, .85, r"$r_1$", color=BLUE)
    axes[1].text(5.5, .1, r"$r_2$", color=ORANGE)
    axes[1].annotate("", xy=(20, 1.15), xytext=(0, 1.15),
                     arrowprops={"arrowstyle": "<->"})
    axes[1].text(10, 1.26, r"$\lambda=20\,\mathrm{mm}$", ha="center")
    axes[1].annotate(r"$v=20\,\mathrm{m/s}$", xy=(36, .8), xytext=(25, .8),
                     arrowprops={"arrowstyle": "->"})
    axes[1].set(xlabel=r"$x$ (mm), $t=0$", ylim=(-1.35, 1.65))
    save(fig, "wave_and_probes.png")

    rng = np.random.default_rng(9)
    noisy1, noisy2 = (x + .3 * rng.standard_normal(t.size) for x in (x1, x2))
    nf1, nf2 = (fun_K01_segment_ffts(x, N) for x in (noisy1, noisy2))
    noisy_phase, _ = fun_K01_cross_phase(nf1, nf2)
    psd = fun_K01_power_spectrum(nf1, FS, N)
    fig, axes = plt.subplots(3, 1, figsize=(9, 8), layout="constrained")
    axes[0].plot(t[:65] * 1e3, noisy1[:65], color=BLUE, alpha=.45, label=r"$x_1+\epsilon_1$")
    axes[0].plot(t[:65] * 1e3, x1[:65], color=BLUE, label=r"$x_1$")
    axes[0].plot(t[:65] * 1e3, x2[:65], color=ORANGE, label=r"$x_2$")
    axes[0].set(xlabel=r"$t$ (ms)", ylabel=r"$q$ (a.u.)")
    axes[0].legend(ncol=3, loc="upper right")
    axes[1].semilogy(frequencies[1:] / 1e3, psd[1:], color=BLUE)
    axes[1].scatter(frequencies[bins] / 1e3, psd[bins], color=ORANGE, zorder=3)
    axes[1].set(xlim=(0, 5), ylim=(1e-6, 1e-2), xlabel=r"$f$ (kHz)",
                ylabel=r"$P_1$ (a.u.$^2$/Hz)")
    for j, color in zip(bins, (BLUE, ORANGE)):
        axes[2].plot(np.arange(1, M + 1), noisy_phase[:, j], ".-", color=color,
                     label=rf"$f={frequencies[j]/1000:g}\,\mathrm{{kHz}}$")
        axes[2].axhline(expected[bins.index(j)], color=color, ls="--", alpha=.5)
    axes[2].set(xlabel=r"$s$", ylabel=r"$\theta_s$ (rad)", ylim=(-np.pi, np.pi))
    axes[2].set_yticks([-np.pi, -np.pi/2, 0, np.pi/2, np.pi],
                       [r"$-\pi$", r"$-\pi/2$", "0", r"$\pi/2$", r"$\pi$"])
    axes[2].legend(ncol=2, loc="center right")
    save(fig, "spectra_and_phase.png")

    fig, axes = plt.subplots(2, 1, figsize=(10, 8), layout="constrained")
    k = np.linspace(-1600, 1600, 1601)
    folded = fun_K01_wrap_to_pi(k * D) / D
    folded[np.abs(np.diff(folded, prepend=folded[0])) > np.pi / D] = np.nan
    axes[0].plot(k, folded, color=BLUE)
    axes[0].plot(k, k, "--", color="#777777", alpha=.6)
    axes[0].scatter([K0, 3*K0], [K0, -K0], color=ORANGE, zorder=3)
    axes[0].annotate(r"$1\,\mathrm{kHz}$", (K0, K0), xytext=(400, 440))
    axes[0].annotate(r"$3\,\mathrm{kHz}$", (3*K0, -K0), xytext=(1000, -470))
    k_nyq = np.pi / D
    for bound in [-k_nyq, k_nyq]:
        axes[0].axvline(bound, color=ANNOTATION_COLOR, ls="--", lw=1.2)
        axes[0].axhline(bound, color=ANNOTATION_COLOR, ls="--", lw=1.2)
        axes[0].text(bound, -825, f"{bound:+.2f}", color=ANNOTATION_COLOR, ha="center", fontsize=10)
        axes[0].text(-1560, bound + 35, rf"$k_{{\mathrm{{meas}}}}={bound:+.2f}$",
                     color=ANNOTATION_COLOR, fontsize=10)
    axes[0].annotate(r"$k_\parallel<-k_{\mathrm{Nyq}}$", (-1100, -1100+2*k_nyq),
                     xytext=(-1570,-450), color=ANNOTATION_COLOR, fontsize=10,
                     arrowprops={"arrowstyle":"->","color":ANNOTATION_COLOR})
    axes[0].text(850, -790, r"$(942.48,\,-314.16)$", color=ANNOTATION_COLOR, fontsize=10)
    axes[0].set(xlabel=r"$k_\parallel$ (rad/m)", ylabel=r"$k_{\mathrm{meas}}$ (rad/m)",
                ylim=(-880, 880), xlim=(-1650, 1650))
    k_edges = np.linspace(-np.pi/D, np.pi/D, 64)
    f_edges = np.arange(-62.5, 4062.5 + 125, 125)
    beall = fun_K02_beall_spectrum(
        phase[:, bins], magnitude[:, bins], frequencies[bins], (D, 0),
        k_edges, f_edges)
    power = beall["spectrum"]
    axes[1].pcolormesh(k_edges, f_edges / 1000,
                       power / power.max(), cmap="viridis", vmin=0, vmax=1,
                       shading="flat")
    cb = fig.colorbar(axes[1].collections[0], ax=axes[1], pad=.02)
    cb.set_label(r"$S/\max(S)$")
    axes[1].set(xlabel=r"$k_{\mathrm{meas}}$ (rad/m)", ylabel=r"$f$ (kHz)")
    save(fig, "aliasing_and_beall.png")

    grid = np.linspace(-1500, 1500, 601)
    chis = [(.005, 0), (0, .005), (.0035, .002)]
    configs = [(chi, float(fun_K01_wrap_to_pi(K0 * chi[0])), .15**2) for chi in chis]
    fig, axes = plt.subplots(1, 3, figsize=(12, 4.2), layout="constrained")
    for count, ax in enumerate(axes, 1):
        ll = fun_K03_joint_log_likelihood(configs[:count], grid, grid)
        im = ax.imshow(ll, origin="lower", extent=(-1500,1500,-1500,1500),
                       vmin=-30, vmax=0, cmap="viridis", aspect="equal")
        ax.scatter(K0, 0, marker="+", color="white", s=90, linewidth=1.5)
        ax.set(title=rf"$J={count}$", xlabel=r"$K_x$ (rad/m)")
        ax.set_xticks([-1000, 0, 1000])
        ax.set_yticks([-1000, 0, 1000])
    axes[0].set_ylabel(r"$K_y$ (rad/m)")
    fig.colorbar(im, ax=axes, shrink=.68, pad=.02,
                 label=r"$\ln L-\max(\ln L)$")
    save(fig, "wavevector_constraints.png")
    print("Four figures generated; cross-phase signs and circular-mean example verified.")


if __name__ == "__main__":
    main()
