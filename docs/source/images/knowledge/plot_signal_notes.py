"""Reproduce the FFT, temporal aliasing, and spectral-leakage teaching figures.

Run with the documentation Python environment; all data are generated here.
"""

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

OUT = Path(__file__).resolve().parent
BLUE, ORANGE, GREEN, ANNOTATION_COLOR = "#1768a6", "#dc6b27", "#21815b", "#59636e"


def save(fig, name):
    fig.savefig(OUT / name, dpi=180, facecolor="white")
    plt.close(fig)


def main():
    plt.rcParams.update({"font.size": 11, "axes.spines.top": False,
                         "axes.spines.right": False})
    # fft-example-start
    fs, N = 32000.0, 256
    t = np.arange(N) / fs
    x = np.cos(2*np.pi*1000*t) + 0.5*np.cos(2*np.pi*3000*t + np.pi/3)
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(N, d=1/fs)
    amplitude = 2*np.abs(X)/N
    amplitude[0] /= 2
    amplitude[-1] /= 2  # N is even: do not double the Nyquist bin
    phase = np.angle(X)
    # fft-example-end
    np.testing.assert_allclose(amplitude[[8, 24]], [1, .5], atol=1e-12)
    np.testing.assert_allclose(phase[[8, 24]], [0, np.pi/3], atol=1e-12)

    fig, axes = plt.subplots(2, 2, figsize=(10, 7), layout="constrained")
    dense = np.linspace(0, .002, 600)
    a = np.cos(2*np.pi*1000*dense)
    b = .5*np.cos(2*np.pi*3000*dense + np.pi/3)
    axes[0, 0].plot(dense*1e3, a, color=BLUE, label=r"$1\,\mathrm{kHz},\ A=1$")
    axes[0, 0].plot(dense*1e3, b, color=ORANGE, label=r"$3\,\mathrm{kHz},\ A=0.5$")
    axes[0, 0].set(xlabel=r"$t$ (ms)", ylabel=r"$x_1,\ x_2$ (a.u.)")
    axes[0, 0].legend(fontsize=9, loc="lower left", ncol=2)
    axes[0, 1].plot(dense*1e3, a+b, color=GREEN)
    axes[0, 1].scatter(t[:65]*1e3, x[:65], color=GREEN, s=9)
    axes[0, 1].set(xlabel=r"$t$ (ms)", ylabel=r"$x=x_1+x_2$ (a.u.)")
    axes[1, 0].vlines(f[:41]/1e3, 0, amplitude[:41], color=BLUE)
    axes[1, 0].scatter(f[:41]/1e3, amplitude[:41], color=BLUE, s=12)
    axes[1, 0].set(xlabel=r"$f_m$ (kHz)", ylabel=r"$\hat A_m$ (a.u.)",
                    ylim=(-.06, 1.2), xlim=(-.1, 5.1))
    axes[1, 0].annotate("1.0", (1, 1), xytext=(1.2,1.06))
    axes[1, 0].annotate("0.5", (3, .5), xytext=(3.2,.57))
    axes[1, 1].axhline(0, color="#999999", lw=.8)
    axes[1, 1].axvline(0, color="#999999", lw=.8)
    for idx, color in [(8, BLUE), (24, ORANGE)]:
        z = 2*X[idx]/N
        axes[1, 1].annotate("", (z.real,z.imag), (0,0),
                            arrowprops={"arrowstyle":"->", "color":color, "lw":2.5})
    ang = np.linspace(0, np.pi/3, 100)
    axes[1, 1].plot(.2*np.cos(ang), .2*np.sin(ang), color=ORANGE)
    axes[1, 1].text(.33,.16,r"$\phi=\pi/3$", color=ORANGE)
    axes[1, 1].text(.29,.49,r"$f=3\,\mathrm{kHz}$", color=ORANGE)
    axes[1, 1].text(.64,-.12,r"$f=1\,\mathrm{kHz}$", color=BLUE)
    axes[1, 1].set(xlabel=r"$\mathrm{Re}(2X/N)$", ylabel=r"$\mathrm{Im}(2X/N)$",
                    xlim=(-.15,1.2), ylim=(-.3,.85), aspect="equal")
    save(fig, "fft_amplitude_phase.png")

    fig, ax = plt.subplots(figsize=(9, 3.4), layout="constrained")
    tt = np.linspace(0,1,1200)
    sampled = np.arange(9)/8
    ax.plot(tt, np.cos(2*np.pi*3*tt), color=BLUE, label=r"$3\,\mathrm{Hz}$")
    ax.plot(tt, np.cos(2*np.pi*5*tt), color=ORANGE, ls="--", label=r"$5\,\mathrm{Hz}$")
    np.testing.assert_allclose(np.cos(2*np.pi*3*sampled),
                               np.cos(2*np.pi*5*sampled), atol=1e-13)
    ax.scatter(sampled, np.cos(2*np.pi*3*sampled), color="#222222", zorder=3, s=35,
               label=r"$f_s=8\,\mathrm{Hz},\ f_{\mathrm{Nyq}}=4\,\mathrm{Hz}$")
    ax.set(xlabel=r"$t$ (s)", ylabel=r"$x$ (a.u.)", ylim=(-1.4,1.5))
    ax.legend(ncol=3, fontsize=10, loc="upper right")
    save(fig, "nyquist_samples.png")

    duration = N/fs
    fig, axes = plt.subplots(2, 1, figsize=(9, 5.5), layout="constrained")
    local = np.linspace(0, duration, 700)
    for ax, tone in zip(axes, [1000, 1062.5]):
        for rep in [0,1]:
            ax.plot((local+rep*duration)*1e3,np.cos(2*np.pi*tone*local),color=BLUE)
        ax.axvline(duration*1e3, color=ANNOTATION_COLOR, ls="--")
        ax.set(ylabel=r"$x$ (a.u.)", ylim=(-1.3,1.45), xlabel=r"$t$ (ms)")
        ax.text(.4,1.12,rf"$f_0={tone:g}\,\mathrm{{Hz}},\ f_0T_{{\mathrm{{seg}}}}={tone*duration:g}$")
    axes[1].annotate("", (8,1), (8,-1), arrowprops={"arrowstyle":"<->","color":ANNOTATION_COLOR,"lw":2})
    axes[1].text(8.3,.05,r"$\Delta x=2$",color=ANNOTATION_COLOR)
    save(fig, "leakage_repeated_record.png")

    # leakage-example-start
    f0 = 1062.5  # 8.5 cycles in 8 ms: halfway between DFT bins
    x_off = np.cos(2*np.pi*f0*t)
    window = 0.5 - 0.5*np.cos(2*np.pi*np.arange(N)/N)  # periodic Hann
    rectangular = 2*np.abs(np.fft.rfft(x_off))/N
    hann = 2*np.abs(np.fft.rfft(window*x_off))/window.sum()
    # These are amplitude displays, not PSDs; endpoints need separate factors.
    # leakage-example-end
    aligned = 2*np.abs(np.fft.rfft(np.cos(2*np.pi*1000*t)))/N
    assert aligned[8] > .999999
    assert np.max(np.delete(aligned,8)) < 1e-12
    far = (f>2000)&(f<5000)
    assert np.sum(hann[far]**2) < np.sum(rectangular[far]**2)
    fig, ax = plt.subplots(figsize=(9,4.5), layout="constrained")
    for values, color, label in [(aligned,BLUE,r"$1000\,\mathrm{Hz},\ w=1$"),
                                 (rectangular,ORANGE,r"$1062.5\,\mathrm{Hz},\ w=1$"),
                                 (hann,GREEN,r"$1062.5\,\mathrm{Hz},\ w=\mathrm{Hann}$")]:
        ax.semilogy(f[1:33],np.maximum(values[1:33],1e-7),".-",color=color,label=label)
    ax.axvline(f0,color=ANNOTATION_COLOR,ls=":",lw=1.2)
    ax.set(xlabel=r"$f_m$ (Hz)", ylabel=r"$2|X_w[m]|/\sum_n w[n]$ (a.u.)",
           xlim=(125,4000),ylim=(1e-5,2))
    ax.legend(fontsize=10)
    save(fig, "leakage_spectra.png")
    print("Four knowledge figures generated; amplitude/phase, temporal aliasing, and leakage checks passed.")


if __name__ == "__main__":
    main()
