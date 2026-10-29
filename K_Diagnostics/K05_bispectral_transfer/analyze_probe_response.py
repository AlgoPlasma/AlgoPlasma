"""Rebuild swept-probe characteristics and labelled response scenarios for K05.

Examples are conditional diagnostic estimates, not an EDI growth inversion.
Run with --data, --output and optionally --config; raw files are opened read-only.
"""
from pathlib import Path
import argparse
import hashlib
import json

import numpy as np
from scipy.optimize import brentq
from yokogawa_wdf import read_wdf


def reconstruct(supply, shunt, resistance, battery, polarity=1.0):
    """Return probe/chamber voltage and electron-positive net current in A."""
    if resistance <= 0 or polarity not in (-1.0, 1.0):
        raise ValueError("Positive resistance and signed polarity required")
    drop = polarity*np.asarray(shunt)
    return np.asarray(supply)-battery+drop, -drop/resistance


def bin_curve(voltage, current, width=2.0, min_count=20):
    """Median and 16/84 percentiles in voltage bins; spreads are not fit errors."""
    valid = np.isfinite(voltage) & np.isfinite(current)
    voltage, current = voltage[valid], current[valid]
    if not len(voltage) or width <= 0:
        raise ValueError("No valid points or invalid bin width")
    edges = np.arange(np.floor(voltage.min()/width)*width,
                      np.ceil(voltage.max()/width)*width+1.1*width, width)
    ids = np.searchsorted(edges, voltage, side="right")-1
    result = []
    for k in range(len(edges)-1):
        take = ids == k
        if take.sum() >= min_count:
            q = np.percentile(current[take], [16, 50, 84])
            result.append([np.median(voltage[take]), q[1], q[0], q[2], int(take.sum())])
    return np.asarray(result)


def fit_temperature(curve, ion_range, windows):
    """Equal-weight fits to bin medians; Te is a local exponential-slope estimate."""
    voltage, current = curve[:, :2].T
    ion = (voltage >= ion_range[0]) & (voltage <= ion_range[1])
    if ion.sum() < 5:
        raise ValueError("Insufficient bins for ion-background fit")
    ion_coeff = np.polyfit(voltage[ion], current[ion], 1)
    crossings = np.flatnonzero((current[:-1] <= 0) & (current[1:] > 0))
    crossings = [k for k in crossings if voltage[k] > ion_range[1]]
    if len(crossings) != 1:
        raise ValueError("Expected one floating-potential crossing above ion fit")
    k = crossings[0]
    floating = float(np.interp(0, current[k:k+2], voltage[k:k+2]))
    electron = current-np.polyval(ion_coeff, voltage)
    fits = []
    for low, high in windows:
        selected = (voltage >= floating+low) & (voltage <= floating+high) & (electron > 0)
        if selected.sum() < 5:
            raise ValueError("Insufficient positive-electron-current fit bins")
        x = voltage[selected]
        y = np.log(electron[selected]/1e-3)  # dimensionless logarithm, reference 1 mA
        slope, intercept = np.polyfit(x, y, 1)
        if slope <= 0:
            raise ValueError("Electron branch is not increasing")
        residual = y-(slope*x+intercept)
        fits.append(dict(te_ev=float(1/slope), slope_per_v=float(slope),
                         intercept=float(intercept), bins=int(selected.sum()),
                         voltage_limits_v=[floating+low, floating+high],
                         r_squared=float(1-np.sum(residual**2)/np.sum((y-y.mean())**2))))
    return dict(floating_v=floating, ion_coeff_a=ion_coeff.tolist(), fits=fits), electron


def rc_response(frequency_hz, resistance, capacitance_f):
    """Z/R for exp(+i omega t) forward Fourier convention (inverse exp(-iwt))."""
    return 1/(1-2j*np.pi*np.asarray(frequency_hz)*resistance*capacitance_f)


def analyze_record(path, config):
    data = read_wdf(path)
    a, b = (data["traces"][config[k]] for k in ("supply_channel", "shunt_channel"))
    if a["unit"] != "V" or b["unit"] != "V":
        raise ValueError("Sweep channels must be volts")
    if a["dt_s"] != b["dt_s"] or a["t0_s"] != b["t0_s"] or len(a["values"]) != len(b["values"]):
        raise ValueError("Sweep channels do not share the same time grid")
    supply, shunt = a["values"], b["values"]
    if not np.isfinite(supply).all() or not np.isfinite(shunt).all():
        raise ValueError("Selected sweep traces contain illegal values")
    low, high = config["ramp_supply_limits_v"]
    starts, stops = np.flatnonzero(supply > low), np.flatnonzero(supply > high)
    if not len(starts) or not len(stops) or starts[0] >= stops[0]:
        raise ValueError("A complete first upward sweep was not found")
    start, stop = int(starts[0]), int(stops[0])
    # Require a net increasing supply in 20 ms blocks; retain plasma fluctuations.
    stride = max(1, round(.02/a["dt_s"]))
    means = [np.median(supply[j:min(j+stride, stop)]) for j in range(start, stop, stride)]
    if np.any(np.diff(means) < -1):
        raise ValueError("Selected interval is not a single upward sweep")
    v, current = reconstruct(supply[start:stop], shunt[start:stop], config["resistance_ohm"],
                             config["sweep_battery_v"], config["shunt_polarity"])
    curve = bin_curve(v, current, config["bin_width_v"], config["minimum_bin_samples"])
    fit, electron = fit_temperature(curve, config["ion_fit_range_v"],
                                    config["temperature_windows_relative_to_floating_v"])
    ion_sensitivity = []
    for limits in config["ion_fit_sensitivity_v"]:
        other, _ = fit_temperature(curve, limits, config["temperature_windows_relative_to_floating_v"])
        ion_sensitivity.append(dict(ion_range_v=limits, fits=other["fits"]))
    report = dict(file=data["file"], sha256=data["sha256"], trigger_time=data["trigger_time"],
                  samples=len(supply), dt_s=a["dt_s"], invalid_count=a["invalid_count"]+b["invalid_count"],
                  ramp_indices=[start, stop], ramp_time_from_record_start_s=[start*a["dt_s"], stop*a["dt_s"]],
                  supply_extrema_v=[float(supply.min()), float(supply.max())],
                  shunt_extrema_v=[float(shunt.min()), float(shunt.max())],
                  curve_bins=len(curve), **fit, ion_sensitivity=ion_sensitivity)
    # The overview shows 2 ms block medians and a 16–84% spread, not selected raw peaks.
    nblock = max(1, round(.002/a["dt_s"]))
    usable = len(supply)//nblock*nblock
    t = (np.arange(usable//nblock)*nblock+(nblock-1)/2)*a["dt_s"]
    raw_overview = np.column_stack([t, np.median(supply[:usable].reshape(-1,nblock),axis=1),
        np.percentile(shunt[:usable].reshape(-1,nblock),[16,50,84],axis=1).T])
    return report, dict(curve=curve, electron=electron, raw_overview=raw_overview,
                        header_text=data["header_text"])


def operating_scenarios(curve, ion_coeff, config):
    """Conditional load-line intersections, using one sweep as a proxy for fast data."""
    v, current = curve[:, :2].T
    result = []
    for cathode in config["cathode_to_chamber_scenarios_v"]:
        def balance(x):
            return x+config["resistance_ohm"]*np.interp(x,v,current)-cathode+config["fast_battery_v"]
        root = float(brentq(balance,float(v.min()),float(v.max())))
        net = float(np.interp(root,v,current)); ion = -float(np.polyval(ion_coeff,root))
        electron = net+ion
        result.append(dict(cathode_to_chamber_v=cathode, probe_to_chamber_v=root,
                           net_current_a=net, ion_background_a=ion,
                           electron_current_a=electron,
                           electron_to_ion_ratio=electron/ion if ion>0 else None))
    return result


def make_plots(reports, arrays, scenarios, config, output):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    plt.rcParams.update({"font.size":11,"axes.titlesize":12,"svg.fonttype":"none",
                         "axes.spines.top":False,"axes.spines.right":False})
    def save(fig,name):
        fig.savefig(output/f"k05-response-{name}.svg",bbox_inches="tight")
        fig.savefig(output/f"k05-response-{name}.png",dpi=160,bbox_inches="tight")
        plt.close(fig)
    first=reports[0]; sample=arrays[first["file"]]; overview=sample["raw_overview"]
    fig,ax=plt.subplots(2,1,figsize=(8.5,5.5),sharex=True,layout="constrained")
    ax[0].plot(overview[:,0],overview[:,1],color="#255b99",label=r"$V_s$: CH3_2")
    ax[1].fill_between(overview[:,0],overview[:,2],overview[:,4],alpha=.25,color="#b74c25",label="16–84% within each 2 ms block")
    ax[1].plot(overview[:,0],overview[:,3],color="#b74c25",lw=1,label=r"$u_R$: CH4_2 median")
    for a in ax:
        a.axvspan(*first["ramp_time_from_record_start_s"],color="#4d9867",alpha=.12)
        a.grid(alpha=.2);a.legend(loc="lower left",fontsize=9)
    ax[0].set_ylabel(r"Supply voltage $V_s$ [V]")
    ax[0].set_title("008: recorded sweep; shaded interval enters the I–V analysis")
    ax[1].set_ylabel(r"Shunt voltage $u_R$ [V]");ax[1].set_xlabel(r"Time from record start $t$ [s]")
    save(fig,"raw")
    fig,ax=plt.subplots(1,2,figsize=(10,4),sharey=True,layout="constrained")
    for r in reports:
        ident=int(Path(r["file"]).stem[-2:]);a=ax[int(ident in config["additional_ids"])];c=arrays[r["file"]]["curve"]
        a.plot(c[:,0],1e3*c[:,1],label=f"{ident:03d}")
    for a,title in zip(ax,["Primary sweeps: 008–011","Additional sweeps: 015–018"]):
        a.set_title(title);a.set_xlabel(r"Probe potential $V_p$ [V, chamber reference]");a.grid(alpha=.2);a.legend(fontsize=9)
        a.axhline(0,color="black",lw=.6)
    ax[0].set_ylabel(r"Net current $I=I_e-I_i$ [mA]")
    save(fig,"iv")
    fig,ax=plt.subplots(1,2,figsize=(10,4.4),layout="constrained")
    c=sample["curve"];electron=sample["electron"];m=electron>0
    ax[0].plot(c[m,0],np.log(electron[m]/1e-3),".",ms=3,color="#777777",label="008: positive electron-current bins")
    colors=["#39805c","#2456a5","#ae6824"]
    for i,(f,color) in enumerate(zip(first["fits"],colors)):
        x=np.array(f["voltage_limits_v"])
        ax[0].plot(x,f["slope_per_v"]*x+f["intercept"],color=color,lw=2,label=f"Window {i+1}: {f['te_ev']:.2f} eV")
    ax[0].set_xlim(first["floating_v"]-25,first["floating_v"]+25)
    ax[0].set_xlabel(r"Probe potential $V_p$ [V]");ax[0].set_ylabel(r"$\ln[I_e/(1\,\mathrm{mA})]$")
    ax[0].set_title("Temperature comes from the logarithmic slope");ax[0].legend(fontsize=8)
    for wi,color in enumerate(colors):
        vals=[r["fits"][wi]["te_ev"] for r in reports]
        ax[1].plot(np.arange(len(reports))+(wi-1)*.13,vals,"o",color=color,label=f"Window {wi+1}")
    ax[1].axhline(config["reported_temperature_ev"],color="#666666",ls="--",label="Reported 9.17 eV")
    ax[1].axvline(3.5,color="#bbbbbb",lw=.8)
    ax[1].set_xticks(np.arange(len(reports)),[Path(r["file"]).stem[-3:] for r in reports])
    ax[1].set_xlabel("Sweep file suffix");ax[1].set_ylabel(r"Slope temperature $T_{e,\mathrm{fit}}$ [eV]")
    ax[1].set_title("Fixed window rules applied to all eight records");ax[1].legend(fontsize=8)
    for a in ax:a.grid(alpha=.2)
    save(fig,"temperature")
    fig,ax=plt.subplots(figsize=(8.5,4.4),layout="constrained")
    ax.plot(c[:,0],c[:,1]*1e3,color="#333333",label="008: measured bin medians")
    v=np.linspace(-90,0,300);ax.plot(v,np.polyval(first["ion_coeff_a"],v)*1e3,"--",color="#777777",label="Extrapolated ion background")
    for scenario,color in zip(scenarios,colors):
        x=scenario["probe_to_chamber_v"];y=scenario["net_current_a"]*1e3
        ax.plot(x,y,"o",color=color,ms=7,label=fr"Assumed $V_c={scenario['cathode_to_chamber_v']:+.0f}$ V: $V_p={x:.1f}$ V")
        ax.axvline(x,color=color,lw=.8,alpha=.4)
    ax.axhline(0,color="black",lw=.6);ax.set_xlim(-90,0);ax.set_ylim(-.7,2.5)
    ax.set_xlabel(r"Probe potential $V_p$ [V, chamber reference]");ax.set_ylabel(r"Net current $I=I_e-I_i$ [mA]")
    ax.set_title("Estimated fast-probe operating points, conditional on the 008 I–V curve")
    ax.grid(alpha=.2);ax.legend(fontsize=9,loc="upper left")
    save(fig,"bias")
    fig,ax=plt.subplots(2,1,figsize=(8.5,5.8),sharex=True,layout="constrained")
    f=np.geomspace(.05e6,50e6,600)
    for cap,color in zip(config["effective_capacitance_scenarios_pf"],colors):
        h=rc_response(f,config["resistance_ohm"],cap*1e-12)
        ax[0].semilogx(f/1e6,abs(h),color=color,label=f"Assumed C = {cap:g} pF")
        ax[1].semilogx(f/1e6,np.angle(h,deg=True),color=color)
    ax[0].set_ylabel(r"Voltage gain $|Z_+(f)|/R$");ax[0].legend(fontsize=9)
    ax[0].set_title("Illustrative R || C response; these are not measured calibrations")
    ax[1].set_ylabel(r"Phase $\arg Z_+(f)$ [degrees]");ax[1].set_xlabel(r"Frequency $f$ [MHz]")
    for a in ax:a.grid(alpha=.2);a.axvspan(5,20,color="#777777",alpha=.07)
    save(fig,"rc")


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data",type=Path,required=True)
    parser.add_argument("--output",type=Path,required=True)
    parser.add_argument("--config",type=Path,default=Path(__file__).with_name("probe_response_config.json"))
    args=parser.parse_args()
    if args.data.resolve()==args.output.resolve() or args.data.resolve() in args.output.resolve().parents:
        raise ValueError("Output must be outside the raw-data directory")
    config=json.loads(args.config.read_text(encoding="utf-8"))
    args.output.mkdir(parents=True,exist_ok=True)
    reports=[];arrays={}
    for ident in config["primary_ids"]+config["additional_ids"]:
        path=args.data/f"1014{ident:04d}.WDF"
        report,array=analyze_record(path,config)
        reports.append(report);arrays[path.name]=array
        (args.output/f"{path.stem}_header.txt").write_text(array.pop("header_text"),encoding="ascii")
    scenarios=operating_scenarios(arrays[reports[0]["file"]]["curve"],reports[0]["ion_coeff_a"],config)
    make_plots(reports,arrays,scenarios,config,args.output)
    np.savez_compressed(args.output/"probe_response_arrays.npz",**{
        f"{Path(file).stem}__{name}":value for file,items in arrays.items() for name,value in items.items()})
    hashfile=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
    summary=dict(config=config,config_sha256=hashfile(args.config),records=reports,
                 operating_scenarios=scenarios,
                 rc_gain_at_5_and_20_mhz={str(cap):abs(rc_response(np.array([5e6,20e6]),config["resistance_ohm"],cap*1e-12)).tolist() for cap in config["effective_capacitance_scenarios_pf"]},
                 source_sha256={p.name:hashfile(p) for p in [Path(__file__),Path(__file__).with_name("yokogawa_wdf.py")]},
                 interpretation="Conditional slope temperatures and assumed circuit-response scenarios; no high-frequency correction or physical growth/transfer inference.")
    (args.output/"probe_response_summary.json").write_text(json.dumps(summary,indent=2,ensure_ascii=False,allow_nan=False)+"\n",encoding="utf-8")
    for r in reports:
        print(r["file"],"Vf",round(r["floating_v"],3),"Te(eV)",[round(x["te_ev"],3) for x in r["fits"]])
    print("Operating scenarios",scenarios)


if __name__ == "__main__":
    main()
