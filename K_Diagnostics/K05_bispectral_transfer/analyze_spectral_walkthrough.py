# K05 contribution history (Git author dates; edit times include timezone).
# 2026-11-06 08:58 +08:00 | Yinjian Zhao | git 8ea987892b7b
# 2026-11-10 10:13 +08:00 | Yinjian Zhao | git b760bab91ff8
# 2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)

"""K05 page 06: one consistent Fourier grid from records to complex moments.

Read-only raw inputs; choose a new output directory. Reuses the documented
SIGLENT reader and Fourier/PSD/bispectral functions of analyze_experiment.
No coefficient fitting or physical-rate conversion is performed here.
"""
from pathlib import Path
import argparse
import hashlib
import json
import platform

import numpy as np
import scipy
from scipy import signal
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import SymLogNorm
from analyze_experiment import (coefficients, psd_from_coefficients, bicoherence,
                                bicoherence_mesh, bicoherence_colorbar, COLORS)
from siglent_v4 import read_capture

N = 2048
CAPTURES = (2, 3, 4, 5)
plt.rcParams.update({"font.size": 11, "svg.fonttype": "none",
                     "svg.hashsalt": "k05-walkthrough-r36"})


def save(fig, output, name):
    for ext in ("svg", "png"):
        fig.savefig(output/f"k05-walkthrough-{name}.{ext}", dpi=150,
                    bbox_inches="tight", metadata={"Date": None} if ext == "svg" else None)
        if ext == "svg":
            path = output/f"k05-walkthrough-{name}.{ext}"
            path.write_text("\n".join(line.rstrip() for line in path.read_text(encoding="utf-8").splitlines())+"\n", encoding="utf-8")
    plt.close(fig)


def plot_coefficients(a, summary, output):
    """Plot the full first-segment spectrum and the fixed-bin complex plane."""
    fs = summary["fs_hz"]
    f = a["frequency_hz"]/1e6
    k = summary["example_bin"]
    fm = f[k]
    x, y = a["g2_X_band"], a["g2_Y_band"]
    fig, ax = plt.subplots(1, 2, figsize=(10, 4.2), layout="constrained")
    for ch, c, name, col in ((1, x, "X", COLORS[0]), (3, y, "Y", COLORS[1])):
        # All 1025 bins from the saved first segment, not the 0-5 MHz slice.
        full = np.fft.rfft(a[f"segment_c{ch}"] * a["window"]).conj() / N
        np.testing.assert_allclose(full[:c.shape[1]], c[0], rtol=1e-10, atol=1e-15)
        ax[0].semilogy(f, abs(full)*1e3, color=col, label=f"${name}$")
        ax[0].plot(fm, abs(c[0,k])*1e3, "s", color=col)
        ax[1].scatter(c[:80,k].real*1e3, c[:80,k].imag*1e3,
                      s=12, alpha=.45, color=col, label=f"${name}$, first 80 segments")
        ax[1].plot(c[0,k].real*1e3, c[0,k].imag*1e3, "s", ms=8, color=col, mec="black")
    ax[0].axvline(fm, color="#777", ls=":", lw=1)
    ax[0].set(xlabel=r"Frequency $f$ (MHz)", ylabel=r"$|X_f^{(1)}|, |Y_f^{(1)}|$ (mV)", title="One segment: full 0–50 MHz band", xlim=(0,fs/2e6))
    ax[1].axhline(0, color="#aaa", lw=.6); ax[1].axvline(0, color="#aaa", lw=.6)
    ax[1].set(xlabel=r"$\mathrm{Re}(X_f^{(r)}),\mathrm{Re}(Y_f^{(r)})$ (mV)",
              ylabel=r"$\mathrm{Im}(X_f^{(r)}),\mathrm{Im}(Y_f^{(r)})$ (mV)",
              title=f"One frequency: {fm:.6f} MHz")
    ax[1].set_aspect("equal", adjustable="datalim")
    for p in ax: p.legend(fontsize=9)
    save(fig, output, "coefficients")


def plot_results(a, summary, output):
    fs = summary["fs_hz"]
    f = a["frequency_hz"]/1e6
    r = np.arange(1, summary["segments_per_capture"]+1)
    k = summary["example_bin"]
    fm = f[k]
    x, y = a["g2_X_band"], a["g2_Y_band"]

    fig, ax = plt.subplots(2, 1, figsize=(8.7, 4.8), sharex=True, layout="constrained")
    for j, (ch, col) in enumerate(zip((1, 3), COLORS)):
        ax[j].fill_between(a["raw_time_ms"], a[f"raw_c{ch}_min"],
                           a[f"raw_c{ch}_max"], color=col, alpha=.3)
        ax[j].plot(a["raw_time_ms"], a[f"raw_c{ch}_mean"], color=col, lw=.8)
        ax[j].set_ylabel(rf"$x_{ch}(t)$ (V)")
        ax[j].set_title(f"C{ch}: record-centred voltage, capture 2", loc="left")
    ax[-1].set_xlabel(r"Time $t$ (ms)")
    save(fig, output, "records")

    fig, ax = plt.subplots(2, 1, figsize=(8.7, 5.2), sharex=True, layout="constrained")
    t = np.arange(N)/fs*1e6
    for ch, col in zip((1, 3), COLORS):
        v = a[f"segment_c{ch}"]
        ax[0].plot(t, v, color=col, lw=.8, label=f"C{ch}")
        ax[1].plot(t, v*a["window"], color=col, lw=.8, label=f"C{ch}")
    ax[0].set_ylabel(r"$x_{j,1}-\bar{x}_{j,1}$ (V)")
    ax[1].set_ylabel(r"$w_n(x_{j,1}-\bar{x}_{j,1})$ (V)")
    ax[0].set_title("First paired segment: before and after the same Hann window", loc="left")
    right = ax[1].twinx()
    right.plot(t, a["window"], color="#555", ls="--", lw=1, label=r"$w_n$")
    right.set_ylabel(r"Window $w_n$ (1)"); right.set_ylim(0, 1.05)
    ax[0].legend(ncol=2); ax[-1].set_xlabel(r"Time within segment $t_n$ (µs)")
    save(fig, output, "window")

    plot_coefficients(a, summary, output)

    fig, ax = plt.subplots(1, 2, figsize=(10, 3.7), layout="constrained")
    for c, name, col in ((x, "X", COLORS[0]), (y, "Y", COLORS[1])):
        power=abs(c[:,k])**2
        ax[0].plot(r[:150], power[:150]*1e6, color=col, lw=.8, label=f"${name}$")
        ax[1].plot(r, np.cumsum(power)/r*1e6, color=col, lw=1, label=f"${name}$")
        ax[1].axhline(power.mean()*1e6, color=col, ls=":", lw=1)
    ax[0].set(xlabel=r"Segment $r$", ylabel=r"$|X_f^{(r)}|^2, |Y_f^{(r)}|^2$ (mV²)", title="Square each complex coefficient")
    ax[1].set(xlabel=r"Segments averaged $m$", ylabel=r"$P_X^{[m]}, P_Y^{[m]}$ (mV²)", title="Then average the squared moduli")
    for p in ax: p.legend()
    fig.suptitle(f"Capture 2, f = {fm:.6f} MHz; dotted lines: all-segment means")
    save(fig, output, "averaging")

    fig, ax = plt.subplots(1, 2, figsize=(10, 4), layout="constrained")
    for g in CAPTURES:
        for ch, col in zip((1,3),COLORS):
            for p in ax:
                p.semilogy(f[1:], a[f"g{g}_psd_c{ch}"][1:],
                           color=col, alpha=1 if g==2 else .3,
                           lw=1.2 if g==2 else .7,
                           label=f"C{ch}, capture 2" if g==2 else None)
    for p, limit in zip(ax,(5,50)):
        p.set(xlim=(0,limit), xlabel=r"Frequency $f$ (MHz)", ylabel=r"$S_{XX}^{+}, S_{YY}^{+}$ (V²/Hz)")
        p.legend(fontsize=9)
    ax[0].set_title("0–5 MHz detail"); ax[1].set_title("0–50 MHz full band")
    fig.suptitle("Same N = 2048 throughout; faint curves: captures 3, 4, 5")
    save(fig, output, "psd")

    fig, ax = plt.subplots(2,2,figsize=(10,6),sharex="col",sharey="row",layout="constrained")
    for g in CAPTURES:
        coh=a[f"g{g}_coherence"];phase=np.angle(a[f"g{g}_G"])
        for c in range(2):
            ax[0,c].plot(f,coh,lw=.9,label=f"Capture {g}")
            ax[1,c].plot(f,np.where(coh>=.5,phase,np.nan),".",ms=1.6)
    ax[0,0].set_ylabel(r"$C_{13}^2(f)$ (1)");ax[1,0].set_ylabel(r"$\delta(f)=\arg G(f)$ (rad)")
    ax[0,0].set_ylim(0,1.05);ax[1,0].set_ylim(-np.pi,np.pi)
    for c,lim in enumerate((5,50)):
        ax[1,c].set(xlim=(0,lim),xlabel=r"Frequency $f$ (MHz)")
        ax[0,c].set_title(f"0–{lim} MHz");ax[0,c].legend(fontsize=8,ncol=2)
    fig.suptitle("Same complex cross spectrum G; phase displayed only for coherence ≥ 0.5")
    save(fig, output, "cross")

    B=a["g2_B_c1"];bf=np.arange(len(B))*fs/N/1e6
    vmax=float(np.nanmax(np.maximum(abs(B.real),abs(B.imag))))
    fig,ax=plt.subplots(1,2,figsize=(10,3.8),layout="constrained",sharex=True,sharey=True)
    norm=SymLogNorm(linthresh=1e-9, vmin=-vmax, vmax=vmax, base=10)
    for p,val,label in zip(ax,(B.real,B.imag),(r"$\mathrm{Re}\,B_X$",r"$\mathrm{Im}\,B_X$")):
        im=p.pcolormesh(bf,bf,np.ma.masked_invalid(val),norm=norm,cmap=plt.get_cmap("RdBu_r").with_extremes(bad="#e6e6e6"),shading="nearest",rasterized=True)
        p.set(xlabel=r"Input frequency $f_2$ (MHz)",xlim=(0,5),ylim=(0,2.5),title=label)
        p.set_aspect("equal");p.grid(False)
    ax[0].set_ylabel(r"Input frequency $f_1$ (MHz)")
    bar=fig.colorbar(im,ax=list(ax),label=r"$\mathrm{Re}B_X,\mathrm{Im}B_X$ (V³)",shrink=.85, ticks=[-1e-3,-1e-6,-1e-9,0,1e-9,1e-6,1e-3])
    bar.minorticks_off()
    fig.suptitle("Capture 2, C1: retain both parts of the complex average")
    save(fig, output, "bispectrum")

    fig,ax=plt.subplots(2,2,figsize=(9,5.8),sharex=True,sharey=True,layout="constrained")
    for p,g in zip(ax.flat,CAPTURES):
        im=bicoherence_mesh(p,bf,a[f"g{g}_b2_c1"])
        p.set_title(f"C1, capture {g}");p.set_aspect("equal")
    for p in ax[-1]:p.set_xlabel(r"$f_2$ (MHz)")
    for p in ax[:,0]:p.set_ylabel(r"$f_1$ (MHz)")
    bicoherence_colorbar(fig,im,list(ax.flat))
    fig.suptitle("Same moments and frequency grid: positive sum-frequency pairs")
    save(fig, output, "bicoherence")


def analyze(data, output, metadata):
    if output.exists() and any(output.iterdir()):
        raise FileExistsError("Choose a new output directory; previous results are preserved")
    output.mkdir(parents=True,exist_ok=True)
    arrays={}; audit=[]; checks=[]; paths=[]
    for group in CAPTURES:
        coeff=[]; metas=[]
        for ch in (1,3):
            hits=list(data.rglob(f"SDS814X_HD_Binary_C{ch}_{group}.bin"))
            if len(hits)!=1:raise ValueError(f"Expected exactly one C{ch}, capture {group}")
            m,v=read_capture(hits[0]);paths.append(hits[0]);audit.append(m);metas.append(m)
            if m['channel']!=ch:raise ValueError("Channel mismatch")
            c,w=coefficients(v,N); coeff.append(c);fs=m['fs_hz']
            p=np.mean(abs(c)**2,axis=0)
            psd=psd_from_coefficients(c,w,fs).mean(axis=0)
            fw,sw=signal.welch(v,fs=fs,window=w,nperseg=N,noverlap=0,detrend='constant')
            np.testing.assert_allclose(psd,sw,rtol=1e-10,atol=1e-20)
            R=len(c);center=v[:R*N].reshape(R,N);center=center-center.mean(axis=1,keepdims=True)
            parseval=np.mean(np.mean((center*w)**2,axis=1))/np.mean(w*w)
            np.testing.assert_allclose(psd.sum()*fs/N,parseval,rtol=1e-12)
            checks.append(dict(capture=group,channel=ch,welch_relative_error=float(np.max(abs(psd-sw))/sw.max()),parseval_error=float(abs(psd.sum()*fs/N-parseval))))
            b2,B=bicoherence(c,fs,N)
            arrays.update({f'g{group}_P_c{ch}':p,f'g{group}_psd_c{ch}':psd,f'g{group}_B_c{ch}':B,f'g{group}_b2_c{ch}':b2})
            if group==2:
                raw=v.reshape(-1,10000)
                arrays.update({f'raw_c{ch}_min':raw.min(axis=1),f'raw_c{ch}_max':raw.max(axis=1),f'raw_c{ch}_mean':raw.mean(axis=1),f'segment_c{ch}':v[:N]-v[:N].mean()})
            del v,center
        if any(metas[0][key]!=metas[1][key] for key in ('fs_hz','samples','t_start_s')):raise ValueError('Inconsistent pair timing')
        if group!=2 and any(metas[0][key]!=audit[0][key] for key in ('fs_hz','samples')):raise ValueError('Inconsistent capture sampling')
        x,y=coeff; G=np.mean(y*x.conj(),axis=0)
        den=arrays[f'g{group}_P_c1']*arrays[f'g{group}_P_c3']
        arrays[f'g{group}_G']=G
        arrays[f'g{group}_coherence']=np.divide(abs(G)**2,den,out=np.full_like(den,np.nan),where=den>0)
        if group==2:
            bins=int(5e6*N/fs)+1
            arrays['g2_X_band']=x[:,:bins].copy();arrays['g2_Y_band']=y[:,:bins].copy()
            arrays['frequency_hz']=fw;arrays['window']=w
            arrays['raw_time_ms']=(np.arange(len(raw))+.5)*10000/fs*1e3
        print(f'Capture {group}: {R} segments, PSD/cross/complex bispectrum complete',flush=True)
        del coeff,x,y
    k=int(round(2e6*N/fs));x=arrays['g2_X_band'];y=arrays['g2_Y_band']
    complex_json=lambda z:dict(real=float(z.real),imag=float(z.imag))
    summary=dict(n=N,fs_hz=fs,segments_per_capture=R,discarded_samples=audit[0]['samples']%N,df_hz=fs/N,
        example_capture=2,example_segment=1,example_bin=k,example_frequency_hz=float(fw[k]),
        example_rule='Capture 2; first segment; nearest frequency bin to 2 MHz; fixed before inspecting results',
        first_X_v=complex_json(x[0,k]),first_Y_v=complex_json(y[0,k]),
        example_PX_v2=float(arrays['g2_P_c1'][k]),example_PY_v2=float(arrays['g2_P_c3'][k]),
        example_G_v2=complex_json(arrays['g2_G'][k]),example_coherence=float(arrays['g2_coherence'][k]),
        example_phase_rad=float(np.angle(arrays['g2_G'][k])),
        bispectrum_components_max_v3=float(np.nanmax(np.maximum(abs(arrays['g2_B_c1'].real),abs(arrays['g2_B_c1'].imag)))),
        metadata=metadata,inputs=audit,numerical_checks=checks,
        software=dict(python=platform.python_version(),numpy=np.__version__,scipy=scipy.__version__,matplotlib=matplotlib.__version__),
        configuration=dict(window='periodic Hann',demean='per segment',overlap=0,fourier='positive exponent / N',psd='one-sided; window mean-square normalization',bispectrum_domain='0<f1<=f2; f1+f2<=5 MHz',phase_display_coherence_min=.5,bispectrum_linear_threshold_v3=1e-9))
    summary['coherence_medians']={str(g):{name:float(np.nanmedian(arrays[f'g{g}_coherence'][(fw>=lo)&(fw<=hi)])) for name,lo,hi in [('0p5_5mhz',.5e6,5e6),('25_50mhz',25e6,50e6)]} for g in CAPTURES}
    summary['source_sha256']={name:hashlib.sha256(Path(__file__).with_name(name).read_bytes()).hexdigest() for name in ('analyze_spectral_walkthrough.py','analyze_experiment.py','siglent_v4.py')}
    np.savez_compressed(output/'walkthrough_arrays.npz',**arrays)
    plot_results(arrays,summary,output)
    for path,m in zip(paths,audit):
        assert hashlib.sha256(path.read_bytes()).hexdigest()==m['sha256'],path.name
    summary['raw_hashes_verified_after_run']=True
    (output/'walkthrough_summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:summary[k] for k in ('example_frequency_hz','first_X_v','first_Y_v','example_PX_v2','example_PY_v2','example_G_v2','example_coherence','example_phase_rad','coherence_medians','bispectrum_components_max_v3')},indent=2),flush=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--metadata',type=Path,default=Path(__file__).with_name('experiment_z5p5_a3p7.json'))
    args=parser.parse_args()
    analyze(args.data,args.output,json.loads(args.metadata.read_text(encoding='utf-8')))
