"""Reproducible first analysis of four SIGLENT two-channel captures.

Run with --help. Raw data stay outside the repository. This program reports
voltage statistics, not calibrated plasma energy or temporal growth rates.
"""
from pathlib import Path
import argparse
import json
import platform

import numpy as np
import scipy
from scipy import signal
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm

from siglent_v4 import read_capture

COLORS = ("#007c91", "#d85c32")
BICOHERENCE_COLOR_MIN = 1e-4
BICOHERENCE_COLOR_MAX = 1.0
plt.rcParams.update({"font.size": 10, "axes.spines.top": False,
                     "axes.spines.right": False, "svg.fonttype": "none",
                     "axes.grid": True, "grid.alpha": .16,
                     "savefig.facecolor": "white", "svg.hashsalt": "k05-experiment"})


def coefficients(x, n):
    """Nonoverlapping, segment-demeaned periodic-Hann coefficients, exp(+iwt)/N."""
    count = len(x)//n
    segments = x[:count*n].reshape(count, n)
    centered = segments - segments.mean(axis=1, keepdims=True)
    w = signal.windows.hann(n, sym=False)
    return np.fft.rfft(centered*w, axis=1).conj()/n, w


def psd_from_coefficients(c, w, fs):
    n = len(w)
    scale = np.full(c.shape[1], 2*n/(fs*np.mean(w*w)))
    scale[0] *= .5
    if n % 2 == 0:
        scale[-1] *= .5
    return abs(c)**2 * scale


def bicoherence(c, fs, n, max_hz=5e6):
    """One unordered positive sum-frequency domain; no DC or negative pairs."""
    kmax = min(int(max_hz/(fs/n)), c.shape[1]-1)
    result = np.full((kmax+1, kmax+1), np.nan)
    bispectrum = np.full(result.shape, complex(np.nan, np.nan))
    for a in range(1, kmax//2+1):
        b = np.arange(a, kmax-a+1)
        z = c[:, a, None]*c[:, b]
        target = c[:, a+b]
        B = np.mean(z*target.conj(), axis=0)
        den = np.mean(abs(z)**2, axis=0)*np.mean(abs(target)**2, axis=0)
        result[a, b] = np.divide(abs(B)**2, den, out=np.zeros(len(b)), where=den>0)
        bispectrum[a, b] = B
    return result, bispectrum


def save(fig, out, stem):
    fig.savefig(out/("k05-experiment-"+stem+".svg"), bbox_inches="tight", metadata={"Date": None})
    fig.savefig(out/("k05-experiment-"+stem+".png"), dpi=140, bbox_inches="tight")
    plt.close(fig)


def plot_cross_spectra(arrays, output, synchronized=True):
    """Display the full nonnegative band alongside a 0–5 MHz detail view."""
    fig, axes = plt.subplots(2, 2, figsize=(12, 7), sharex="col", sharey="row")
    nyquist_mhz = arrays["g2_f_hz"][-1]/1e6
    for group in range(2, 6):
        f = arrays[f"g{group}_f_hz"]/1e6
        coherence = arrays[f"g{group}_coherence"]
        phase = arrays[f"g{group}_cross_phase_rad"]
        for col in range(2):
            axes[0, col].plot(f, coherence, lw=.8, label=f"#{group}")
            axes[1, col].plot(f, np.where(coherence >= .5, phase, np.nan), ".", ms=1.4)
    axes[0, 0].set_ylabel("Magnitude-squared coherence")
    axes[1, 0].set_ylabel(r"$\arg\langle YX^*\rangle$ (rad)")
    axes[0, 0].set_ylim(0, 1.05)
    axes[1, 0].set_ylim(-np.pi, np.pi)
    axes[0, 0].set_title(f"Full band: 0–{nyquist_mhz:g} MHz")
    axes[0, 1].set_title("Detail: 0–5 MHz")
    for col, upper in enumerate((nyquist_mhz, min(5, nyquist_mhz))):
        axes[0, col].legend(ncol=4, fontsize=8)
        axes[1, col].set_xlabel("Frequency (MHz)")
        axes[1, col].set_xlim(0, upper)
    label = "Synchronous C1–C3" if synchronized else "Synchronization unverified"
    fig.suptitle(label+"; phase shown only where coherence ≥ 0.5")
    fig.tight_layout()
    save(fig, output, "cross")


def bicoherence_mesh(ax, frequency_mhz, b2):
    """Shared log colors; floor only the display copy, keeping NaNs white."""
    display = np.ma.masked_invalid(np.maximum(b2, BICOHERENCE_COLOR_MIN))
    mesh = ax.pcolormesh(
        frequency_mhz, frequency_mhz, display,
        norm=LogNorm(vmin=BICOHERENCE_COLOR_MIN, vmax=BICOHERENCE_COLOR_MAX),
        shading="nearest", cmap=plt.get_cmap("viridis").with_extremes(bad="white"),
        rasterized=True,
    )
    ax.set_xlim(0, 5)
    ax.set_ylim(0, 2.5)
    ax.grid(False)
    return mesh


def bicoherence_colorbar(fig, mesh, axes):
    """Ticks show b², with equal spacing for factors of ten."""
    bar = fig.colorbar(mesh, ax=axes, label=r"Squared bicoherence $b^2$ (log scale)",
                       ticks=[1e-4, 1e-3, 1e-2, 1e-1, 1], extend="min", pad=.025)
    bar.ax.set_yticklabels(["0.0001", "0.001", "0.01", "0.1", "1"])
    bar.minorticks_off()


def plot_bicoherence_maps(arrays, output, fs, n=2048):
    """Compare both channels and all four captures on the same log scale."""
    for ch, stem in ((1, "bicoherence"), (3, "bicoherence-c3")):
        fig, axes = plt.subplots(2, 2, figsize=(11, 6), sharex=True, sharey=True,
                                 layout="constrained")
        for ax, group in zip(axes.flat, range(2, 6)):
            b2 = arrays[f"g{group}_bicoherence_c{ch}"]
            freq = np.arange(b2.shape[0])*fs/n/1e6
            mesh = bicoherence_mesh(ax, freq, b2)
            ax.set_title(f"C{ch}, capture #{group}")
            ax.set_aspect("equal")
        for ax in axes[-1]:
            ax.set_xlabel("f2 (MHz)")
        for ax in axes[:, 0]:
            ax.set_ylabel("f1 (MHz)")
        bicoherence_colorbar(fig, mesh, list(axes.flat))
        fig.suptitle("Positive sum pairs: 0 < f1 ≤ f2, f1 + f2 ≤ 5 MHz\n"
                     "Shared log scale; values below 0.0001 use the darkest color")
        save(fig, output, stem)


def plot_bicoherence_sensitivity(arrays, output, fs, sample_count):
    """Use the same log colors as the channel maps for all segment lengths."""
    fig, axes = plt.subplots(1, 3, figsize=(12, 3.6), sharex=True, sharey=True,
                             layout="constrained")
    for ax, n in zip(axes, (1024, 2048, 4096)):
        b2 = arrays[f"sensitivity_n{n}_bicoherence_c1"]
        freq = np.arange(b2.shape[0])*fs/n/1e6
        mesh = bicoherence_mesh(ax, freq, b2)
        ax.set_title(f"N={n}, R={sample_count//n}\nΔf={fs/n/1e3:.2f} kHz")
        ax.set_xlabel("f2 (MHz)")
    axes[0].set_ylabel("f1 (MHz)")
    bicoherence_colorbar(fig, mesh, list(axes))
    fig.suptitle("Capture #2, C1: segment-length sensitivity\n"
                 "Same log scale as both probe maps; darkest color includes values < 0.0001")
    save(fig, output, "sensitivity")


def analyze(data, output, metadata):
    output.mkdir(parents=True, exist_ok=True)
    n = 16384
    nb = 2048
    all_meta, summary, arrays = [], [], {}
    fig_raw, ax_raw = plt.subplots(4, 1, figsize=(10, 9), sharex=True)
    fig_zoom, ax_zoom = plt.subplots(2, 1, figsize=(10, 5.6), sharex=True)
    fig_qc, ax_qc = plt.subplots(2, 1, figsize=(10, 6), sharex=True)
    fig_psd, ax_psd = plt.subplots(2, 1, figsize=(10, 7), sharex=True)
    for gi, group in enumerate(range(2, 6)):
        meta, values = [], []
        for ch in (1, 3):
            matches = list(data.rglob(f"SDS814X_HD_Binary_C{ch}_{group}.bin"))
            if len(matches) != 1:
                raise ValueError(f"Expected exactly one C{ch}, capture {group}")
            m, v = read_capture(matches[0])
            if m["channel"] != ch:
                raise ValueError("Filename/channel mismatch")
            meta.append(m); values.append(v); all_meta.append(m)
        if any(meta[0][key] != meta[1][key] for key in ("samples", "fs_hz", "t_start_s")):
            raise ValueError("Nominal pair has different sample timing")
        fs = meta[0]["fs_hz"]
        x, y = values
        for j, v in enumerate(values):
            # Min/max aggregation, not striding: every original sample is represented.
            blocks = v.reshape(-1, 10000)
            t = (np.arange(len(blocks))+.5)*10000/fs*1e3
            ax_raw[gi].fill_between(t, blocks.min(axis=1), blocks.max(axis=1),
                                   color=COLORS[j], alpha=.22)
            ax_raw[gi].plot(t, blocks.mean(axis=1), color=COLORS[j], lw=.8, label=f"C{(1,3)[j]}")
            b = v.reshape(-1, 100000)
            tq = (np.arange(len(b))+.5)*100000/fs*1e3
            style = ("-", "--", ":", "-.")[gi]
            ax_qc[0].plot(tq, b.mean(axis=1), style, color=COLORS[j], alpha=.7,
                          label=f"C{(1,3)[j]}, #{group}")
            ax_qc[1].plot(tq, b.std(axis=1), style, color=COLORS[j], alpha=.7)
            if group == 2:
                k = np.arange(5000000, 5002000)
                ax_zoom[j].plot((k-k[0])/fs*1e6, v[k], color=COLORS[j], lw=.75)
                ax_zoom[j].set_ylabel(f"C{(1,3)[j]} fluctuation (V)")
                arrays[f"zoom_c{(1,3)[j]}"] = v[k]
        ax_raw[gi].set_ylabel(f"#{group}\nFluctuation (V)")
        ax_raw[gi].legend(loc="lower right", ncol=2)
        cx, w = coefficients(x, n); cy, _ = coefficients(y, n)
        f = np.fft.rfftfreq(n, 1/fs)
        sx = psd_from_coefficients(cx, w, fs); sy = psd_from_coefficients(cy, w, fs)
        px = np.mean(abs(cx)**2, axis=0); py = np.mean(abs(cy)**2, axis=0)
        g = np.mean(cy*cx.conj(), axis=0)
        coh = abs(g)**2/(px*py)
        phase = np.angle(g)
        # Compare against an independent established PSD implementation.
        fw, sw = signal.welch(x, fs, window=w, nperseg=n, noverlap=0, detrend="constant")
        psd_error = float(np.max(abs(sx.mean(axis=0)-sw))/sw.max())
        if not np.allclose(sx.mean(axis=0), sw, rtol=1e-10, atol=1e-20):
            raise AssertionError("PSD normalization differs from scipy.signal.welch")
        for j, s in enumerate((sx, sy)):
            ax_psd[j].loglog(f[1:]/1e6, s.mean(axis=0)[1:], lw=1, label=f"Capture #{group}")
            ax_psd[j].set_ylabel(f"C{(1,3)[j]} PSD (V²/Hz)")
        item = dict(capture=group, psd_segments=len(cx), psd_tail_samples=len(x)%n,
                    psd_vs_scipy_relative_error=psd_error,
                    high_frequency_peak_mhz=float(f[np.argmax(np.where(f>=1e5,sx.mean(axis=0),0))]/1e6),
                    coherence_median_0p5_5mhz=float(np.median(coh[(f>=.5e6)&(f<=5e6)])))
        for name, val in (("f_hz",f),("psd_c1",sx.mean(axis=0)),("psd_c3",sy.mean(axis=0)),
                          ("coherence",coh),("cross_phase_rad",phase)):
            arrays[f"g{group}_{name}"] = val
        if group == 2:
            fig_seg, axes = plt.subplots(2, 1, figsize=(10, 5.5), sharex=True)
            seg = x[:n]-x[:n].mean()
            # Only visual display is thinned; FFT uses every sample.
            axes[0].plot(np.arange(n)/fs*1e6, seg, lw=.45, color=COLORS[0])
            axes[1].plot(np.arange(n)/fs*1e6, seg*w, lw=.45, color=COLORS[0])
            axes[0].set_ylabel("Demeaned C1 (V)"); axes[1].set_ylabel("Hann × C1 (V)")
            axes[1].set_xlabel("Time within the first segment (µs)")
            axes[0].set_title(f"Capture #2: {n} samples per segment, {len(cx)} complete segments")
            save(fig_seg, output, "segments")
            fig_tf, axes = plt.subplots(2, 1, figsize=(10, 6), sharex=True)
            use = f<=5e6
            lo, hi = -12, -5
            for j, s in enumerate((sx,sy)):
                im = axes[j].pcolormesh((np.arange(len(cx))+.5)*n/fs*1e3,
                                      f[use]/1e6, np.log10(np.maximum(s[:,use].T,1e-30)),
                                      vmin=lo,vmax=hi,cmap="magma",shading="auto",rasterized=True)
                axes[j].set_ylabel(f"C{(1,3)[j]}: f (MHz)")
            axes[-1].set_xlabel("Time from record start (ms)")
            fig_tf.colorbar(im, ax=axes, label="log10[PSD / (V²/Hz)]",pad=.02)
            axes[0].set_title("Capture #2: frequency content versus time")
            save(fig_tf, output, "spectrogram")
        cb, wb = coefficients(x, nb)
        bi, bis = bicoherence(cb, fs, nb)
        arrays[f"g{group}_bicoherence_c1"] = bi
        arrays[f"g{group}_bispectrum_c1"] = bis
        cby, _ = coefficients(y, nb)
        biy, bisy = bicoherence(cby, fs, nb)
        arrays[f"g{group}_bicoherence_c3"] = biy
        arrays[f"g{group}_bispectrum_c3"] = bisy
        item["bispectral_segments"] = len(cb)
        item["bispectral_tail_samples"] = len(x)%nb
        # Illustrative triad is selected exploratorily, not a confirmatory discovery.
        inds = np.indices(bi.shape)
        eligible = np.isfinite(bi) & (inds[0]*fs/nb >= 1e5)
        a,b = np.unravel_index(np.nanargmax(np.where(eligible,bi,np.nan)),bi.shape)
        item["exploratory_triad_mhz"] = [float(k*fs/nb/1e6) for k in (a,b,a+b)]
        item["exploratory_b2"] = float(bi[a,b])
        if group == 2:
            z = cb[:,a]*cb[:,b]; target = cb[:,a+b]
            triple = z*target.conj()
            rng = np.random.default_rng(20261028)
            shifts = rng.integers(len(cb)//4,3*len(cb)//4,size=63)
            null = np.array([abs(np.mean(z*np.roll(target,int(shift)).conj()))**2/
                             (np.mean(abs(z)**2)*np.mean(abs(target)**2)) for shift in shifts])
            item["triad_shifted_median_b2"] = float(np.median(null))
            fig_tri, axes = plt.subplots(1,2,figsize=(10,3.6))
            axes[0].hist(np.angle(triple),bins=30,range=(-np.pi,np.pi),color=COLORS[0],alpha=.8)
            axes[0].set_xlabel("arg(Xa Xb X* a+b) (rad)");axes[0].set_ylabel("Segment count")
            axes[0].set_title("Unweighted phase histogram")
            axes[1].hist(null,bins=14,color="#888888",alpha=.7,label="Shifted target segments")
            axes[1].axvline(bi[a,b],color=COLORS[1],lw=2,label="Original ordering")
            axes[1].set_xlabel("Squared bicoherence");axes[1].set_ylabel("Shift count")
            axes[1].legend(fontsize=8)
            fig_tri.suptitle("Exploratory C1 triad: %.3f + %.3f = %.3f MHz" % tuple(item["exploratory_triad_mhz"]))
            fig_tri.tight_layout();save(fig_tri, output, "triad")
            # Repeat with different segment durations rather than trusting one bin grid.
            for ns in (1024,2048,4096):
                cs,_=coefficients(x,ns)
                bs,_=bicoherence(cs,fs,ns)
                arrays[f"sensitivity_n{ns}_bicoherence_c1"]=bs
            plot_bicoherence_sensitivity(arrays, output, fs, len(x))
        summary.append(item)
        print(json.dumps(item),flush=True)
    ax_raw[-1].set_xlabel("Time from record start (ms)")
    ax_raw[0].set_title("All 8 records, mean removed: min–max bands in 0.1 ms display bins")
    fig_raw.tight_layout();save(fig_raw,output,"raw")
    ax_zoom[-1].set_xlabel("Time from 50 ms within capture #2 (µs)")
    ax_zoom[0].set_title("20 µs zoom: record mean removed, every sample, no filtering")
    fig_zoom.tight_layout();save(fig_zoom,output,"zoom")
    ax_qc[0].set_ylabel("Local mean − record mean (V)");ax_qc[1].set_ylabel("Fluctuation RMS (V)")
    ax_qc[0].legend(ncol=4,fontsize=8);ax_qc[0].set_title("Local statistics in consecutive 1 ms blocks")
    ax_qc[1].set_xlabel("Time from record start (ms)")
    fig_qc.tight_layout();save(fig_qc,output,"stability")
    ax_psd[0].legend(ncol=4,fontsize=8)
    ax_psd[0].set_title("Each capture separately: one-sided Hann PSD")
    ax_psd[-1].set_xlabel("Frequency (MHz)")
    ax_psd[-1].set_xlim(.006,50)
    fig_psd.tight_layout();save(fig_psd,output,"psd")
    plot_cross_spectra(arrays, output, metadata["synchronized_pairs"])
    plot_bicoherence_maps(arrays, output, fs, nb)
    report=dict(schema_version=1,experiment=metadata,
                signal_quantity="Scope-scaled ion-saturation-current diagnostic voltage",
                psd=dict(nperseg=n,window="periodic Hann",overlap=0,detrend="segment mean",
                         df_hz=fs/n,enbw_hz=1.5*fs/n),
                bispectrum=dict(nperseg=nb,window="periodic Hann",overlap=0,
                                df_hz=fs/nb,max_sum_hz=5e6,domain="positive unordered sums only"),
                captures=all_meta,statistics=summary,
                software=dict(python=platform.python_version(),numpy=np.__version__,
                              scipy=scipy.__version__,matplotlib=matplotlib.__version__),
                limitations=["DC offset sign differs between vendor document and supplied lab reader; record-centred plots avoid choosing it",
                             "No channel delay/gain calibration applied",
                             "No calibrated plasma potential, density or energy",
                             "No frequency-to-wavenumber branch assumption made",
                             "No physical growth/transfer inferred from bicoherence",
                             "Shifted-triad comparison is exploratory; no multiple-testing claim"])
    (output/"analysis_summary.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    np.savez_compressed(output/"spectral_arrays.npz",**arrays)
    return report


if __name__ == "__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data",type=Path,required=True,help="Directory containing the original .bin files")
    parser.add_argument("--output",type=Path,required=True,help="Derived figures, arrays and provenance")
    parser.add_argument("--metadata",type=Path,default=Path(__file__).with_name("experiment_z5p5_a3p7.json"),
                        help="Acquisition facts and explicitly unknown calibration parameters")
    args=parser.parse_args()
    analyze(args.data,args.output,json.loads(args.metadata.read_text(encoding="utf-8")))
