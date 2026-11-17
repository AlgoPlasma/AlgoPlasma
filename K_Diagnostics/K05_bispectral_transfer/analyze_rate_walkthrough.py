"""Earlier 5 MHz rate walkthrough from saved coefficients and held-out moments.

For the current page 08, use analyze_extended_comparison.py,
analyze_physical_scenario.py and plot_physical_comparison.py.

The saved kinetic branch supplies an explicit scenario, not a measured velocity.
No raw inputs or parent results are modified. See EXPERIMENT.md.
"""
import argparse
import json
import platform
from pathlib import Path

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from analyze_coefficient_walkthrough import load_groups, sha, save, FS, N
from analyze_transfer_budget import power_budget
from analyze_paper_comparison import convert_rates
from validate_experiment import design_matrix


def derive(groups, budget, comparison):
    """Use test moments, with coefficients and reference phases fixed by training."""
    b, c = budget, comparison
    f = b["frequency_hz"]
    np.testing.assert_array_equal(f, c["frequency_hz"])
    np.testing.assert_array_equal(b["phase"], c["phase"])
    shape = b["ls_coef"].shape
    pair_moment = np.full((shape[0], shape[1], shape[2]-1), np.nan+1j*np.nan)
    pair_increment = np.full(pair_moment.shape, np.nan)
    px = np.zeros(shape[:2]); py = px.copy()
    inc = np.zeros((*shape[:2], 5))
    for gi, capture in enumerate(b["captures"]):
        xall, yall = groups[int(capture)]
        for fi, freq in enumerate(f):
            k = int(round(freq*N/FS)); count = int(b["pair_count"][fi])
            d = design_matrix(xall, k, b["pairs"][fi, :count])
            y, x = yall[:, k], d[:, 0]
            coef = b["ls_coef"][gi, fi, :count+1]
            px[gi, fi], py[gi, fi] = np.mean(abs(x)**2), np.mean(abs(y)**2)
            moment = np.mean(d[:, 1:]*x.conj()[:, None], axis=0)
            pair_moment[gi, fi, :count] = moment
            pair_increment[gi, fi, :count] = (
                2*np.real(np.exp(-1j*b["phase"][gi, fi])*coef[1:]*moment)/px[gi, fi])
            _, inc[gi, fi] = power_budget(d, y, coef, b["phase"][gi, fi])
    np.testing.assert_allclose(inc, b["increments"][:, :, 0], atol=2e-12, rtol=2e-10)
    np.testing.assert_allclose(np.nansum(pair_increment, axis=-1), inc[:, :, 1], atol=2e-12)
    np.testing.assert_allclose(inc.sum(axis=-1), py/px-1, atol=2e-12)
    np.testing.assert_allclose(px, c["input_power"], rtol=2e-10)
    ell = np.exp(-1j*b["phase"])*b["ls_coef"][:, :, 0]-1
    gamma, transfer = convert_rates(b["ls_coef"][:, :, 0], b["phase"],
                                   inc[:, :, 1], px, c["target_vg"], .0037)
    np.testing.assert_allclose(gamma, c["ls_gamma"], rtol=2e-10)
    np.testing.assert_allclose(transfer, c["ls_transfer_half"], rtol=2e-10, atol=1e-12)
    return dict(frequency_hz=f, captures=b["captures"], ell=ell, px=px, py=py,
                increments=inc, pair_moment=pair_moment, pair_increment=pair_increment,
                gamma_app=gamma, transfer_half=transfer,
                transfer_half_over_px=transfer/px, group_velocity=c["target_vg"])


def plot_phase(a, b, output):
    """Draw Figure 1 from saved coefficients; no refitting or new transforms."""
    plt.rcParams.update({"font.size": 11, "axes.grid": True, "grid.alpha": .2,
                         "svg.fonttype": "none"})
    f = a["frequency_hz"]/1e6; j = int(np.argmin(abs(f-2)))
    teal, orange, purple = "#007c91", "#d85c32", "#7654a3"
    fig, ax = plt.subplots(1, 2, figsize=(9.3, 3.6), layout="constrained")
    raw = b["ls_coef"][0, j, 0]; aligned = a["ell"][0, j]+1
    for z, col, name in [(raw, orange, r"$L_f$"), (aligned, teal, r"$\widetilde L_f$")]:
        ax[0].annotate("", (z.real,z.imag), (0,0), arrowprops=dict(arrowstyle="->", color=col,lw=2))
        ax[0].plot(z.real,z.imag,"o",color=col,label=name)
    ax[0].plot(1,0,"x",color="black", label="Unit multiplier")
    theta=np.linspace(-np.pi/2,np.pi/2,200)
    ax[0].plot(abs(raw)*np.cos(theta),abs(raw)*np.sin(theta),":",color=".65")
    ax[0].set(xlabel="Real part (dimensionless)",ylabel="Imaginary part (dimensionless)",
              xlim=(-.05,1.08),ylim=(-.42,.15),title="(a) Rotation at 2.00195 MHz")
    ax[0].set_aspect("equal",adjustable="box");ax[0].legend(fontsize=9)
    ax[1].plot(f,a["ell"][0].real,color=teal,label=r"$\operatorname{Re}(\ell_f)=\operatorname{Re}(\widetilde L_f)-1$")
    ax[1].plot(f,a["ell"][0].imag,color=orange,ls="--",label=r"$\operatorname{Im}(\ell_f)=\operatorname{Im}(\widetilde L_f)$")
    ax[1].axhline(0,color=".4",lw=.7)
    ax[1].axvline(f[j],color=".65",lw=.8,ls=":")
    ax[1].plot(f[j],a["ell"][0,j].real,"o",color=teal,ms=4)
    ax[1].plot(f[j],a["ell"][0,j].imag,"o",color=orange,ms=4)
    ax[1].set(xlabel=r"Target frequency $f$ (MHz)",ylabel=r"$\ell_f$ components (dimensionless)",
              title=r"(b) Same increment $\ell_f$, across frequencies")
    ax[1].legend(fontsize=9);save(fig,output,"k05-rate-phase")


def plots(a, b, output):
    plot_phase(a, b, output)
    f = a["frequency_hz"]/1e6; j = int(np.argmin(abs(f-2)))
    teal, orange, purple = "#007c91", "#d85c32", "#7654a3"
    fig, ax = plt.subplots(1,2,figsize=(10,3.7),layout="constrained")
    vals=a["increments"][0,j]*100
    labels=[r"$g_f$",r"$t_f$",r"$s_f$",r"$r_f$",r"$c_f$","Sum",r"$D_f$"]
    full=np.r_[vals,vals.sum(),100*(a["py"][0,j]/a["px"][0,j]-1)]
    ax[0].bar(range(7),full,color=[teal,orange,purple,"#8b969e","#b8a684","#202c39","#697985"])
    for k,v in enumerate(full):ax[0].annotate(f"{v:+.3f}",(k,v),xytext=(0,4 if v>=0 else -12),
                                            textcoords="offset points",ha="center",fontsize=8)
    ax[0].set(xticks=range(7),xticklabels=labels,ylabel=r"Contribution relative to $P_X$ (%)",
              title="(a) Held-out capture 2, 2.00195 MHz")
    ax[0].axhline(0,color=".3",lw=.7);ax[0].margins(y=.22)
    D=100*(a["py"][0]/a["px"][0]-1)
    ax[1].plot(f,D,color="black",lw=2,label=r"Measured $D_f$")
    ax[1].plot(f,100*a["increments"][0,:,:2].sum(axis=-1),color=orange,label=r"First order $g_f+t_f$")
    ax[1].plot(f,100*a["increments"][0].sum(axis=-1),"--",color=teal,label="All five terms")
    ax[1].set(xlabel=r"Target frequency $f$ (MHz)",ylabel=r"$(P_Y-P_X)/P_X$ (%)",
              title="(b) Exact balance versus first order")
    ax[1].legend(fontsize=9);save(fig,output,"k05-rate-balance")

    count=int(b["pair_count"][j]);p=b["pairs"][j,:count]
    first=p[:,0]*FS/N/1e6; q=abs(b["ls_coef"][0,j,1:count+1])
    fig, ax=plt.subplots(2,1,figsize=(8,5.4),sharex=True,layout="constrained")
    ax[0].plot(first,q,".-",ms=3,color=purple)
    ax[0].set(yscale="log",ylabel=r"$|Q_{fj}|$ (V$^{-1}$)",title=r"Same pairs: $f_2=f-f_1$, $f=2.00195$ MHz")
    val=100*a["pair_increment"][0,j,:count]
    ax[1].bar(first,val,width=.8*FS/N/1e6,color=np.where(val>=0,teal,orange))
    ax[1].axhline(0,color=".3",lw=.7)
    ax[1].set(xlabel=r"First input frequency $f_1$ (MHz), $f_1\leq f_2$",
              ylabel=r"Pair contribution $t_{fj}$ (% of $P_X$)")
    save(fig,output,"k05-rate-pairs")

    fig, ax=plt.subplots(1,2,figsize=(9.5,3.8),layout="constrained")
    ax[0].plot(f,a["group_velocity"]/1e3,color=purple)
    ax[0].set(xlabel=r"Target frequency $f$ (MHz)",ylabel=r"Assumed $v_{g,y}(f)$ (km/s)",
              title="(a) From an estimated kinetic scenario")
    for key,col,label in [("gamma_app",teal,r"$\gamma_{y,\mathrm{app}}$"),
                          ("transfer_half_over_px",orange,r"$T_f^{(1/2)}/P_X$")]:
        v=a[key]/1e4
        ax[1].plot(f,v.mean(axis=0),color=col,label=label)
        ax[1].fill_between(f,v.min(axis=0),v.max(axis=0),color=col,alpha=.18)
    ax[1].axhline(0,color=".3",lw=.7)
    ax[1].set(xlabel=r"Target frequency $f$ (MHz)",ylabel=r"Conditional rate ($10^4$ s$^{-1}$)",
              title="(b) Joint LS: four-holdout mean and range")
    ax[1].legend(fontsize=9);save(fig,output,"k05-rate-conversion")


def main():
    p=argparse.ArgumentParser(description=__doc__)
    for key in ("data","budget","comparison","validation","output"):
        p.add_argument("--"+key,type=Path,required=True)
    args=p.parse_args()
    args.output.mkdir(parents=True,exist_ok=True)
    if any(args.output.iterdir()):raise FileExistsError("Use an empty output directory")
    parents=[args.budget/"transfer_arrays.npz",args.budget/"transfer_summary.json",
             args.comparison/"comparison_arrays.npz",args.comparison/"comparison_summary.json",
             args.validation/"validation_summary.json"]
    hashes={x.name:sha(x) for x in parents}
    bs=json.loads(parents[1].read_text(encoding="utf8"))
    vs=json.loads(parents[4].read_text(encoding="utf8"))
    cs=json.loads(parents[3].read_text(encoding="utf8"))
    if cs["inputs_sha256"]["transfer_arrays.npz"]!=hashes["transfer_arrays.npz"]:
        raise ValueError("Kinetic comparison uses a different coefficient result")
    groups,raw=load_groups(args.data,[(bs,"inputs"),(vs,"raw_files")])
    with np.load(parents[0]) as b,np.load(parents[2]) as c:
        a=derive(groups,b,c);plots(a,b,args.output)
        j=int(np.argmin(abs(a["frequency_hz"]-2e6)))
        report=dict(config=dict(nperseg=N,fs_hz=FS,fourier="exp(+i 2 pi f t)/N",
             window="periodic Hann",demean="segment",overlap=0,method="joint LS",
             targets_mhz=[.5,5],inputs_max_mhz=5,separation_m=.0037,
             example_heldout=2,example_train=[3,4,5],moments="held-out capture",
             phase="training cross power",kinetic_scenario=cs["config"]),
             inputs_sha256=hashes,raw_inputs=raw,
             sources_sha256={Path(__file__).name:sha(Path(__file__))},
             versions=dict(python=platform.python_version(),numpy=np.__version__,matplotlib=matplotlib.__version__),
             example=dict(frequency_hz=float(a["frequency_hz"][j]),
                 phase_rad=float(b["phase"][0,j]),linear_real=float(b["ls_coef"][0,j,0].real),
                 linear_imag=float(b["ls_coef"][0,j,0].imag),
                 ell_real=float(a["ell"][0,j].real),ell_imag=float(a["ell"][0,j].imag),
                 px_v2=float(a["px"][0,j]),py_v2=float(a["py"][0,j]),
                 increments=a["increments"][0,j].tolist(),
                 measured_change=float(a["py"][0,j]/a["px"][0,j]-1),
                 vg_m_per_s=float(a["group_velocity"][j]),gamma_per_s=float(a["gamma_app"][0,j]),
                 transfer_half_v2_per_s=float(a["transfer_half"][0,j]),
                 transfer_half_over_px_per_s=float(a["transfer_half_over_px"][0,j])),
             audit=dict(max_balance_error=float(np.max(abs(a["increments"].sum(axis=-1)-(a["py"]/a["px"]-1)))),
                 max_pair_sum_error=float(np.max(abs(np.nansum(a["pair_increment"],axis=-1)-a["increments"][:,:,1]))),
                 kim_admissible=int(b["admissible"].sum()),kim_total=int(b["admissible"].size)),
             interpretation="Measured-voltage finite-step identity; conditional rates, not calibrated plasma energy transfer.")
    np.savez_compressed(args.output/"rate_walkthrough_arrays.npz",**a)
    for path in parents:assert sha(path)==hashes[path.name]
    (args.output/"rate_walkthrough_summary.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf8")
    print(json.dumps(dict(example=report["example"],audit=report["audit"]),indent=2))


if __name__=="__main__":main()
