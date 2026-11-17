"""Build K05's measured-statistics-to-coefficients worked example.

Reuses the complete four-fold LS/Kim results, checks their provenance against the
raw captures, and independently refits the fixed 2 MHz example. No physical
response correction, growth rate or energy transfer is inferred. See EXPERIMENT.md.
"""
from pathlib import Path
import argparse
import hashlib
import json
import platform

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm, Normalize

from analyze_experiment import coefficients
from siglent_v4 import read_capture
from validate_experiment import CAPTURES, design_matrix, signed_pairs, fit_scaled
from analyze_transfer_budget import fit_kim

N = 2048
FS = 100e6
TARGET = 41
MAXIMUM = 102
SMALL_PAIRS = np.array([(10, 31), (-10, 51)])
COLORS = ("#007c91", "#d85c32", "#7654a3")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def encode(value):
    if isinstance(value, complex):
        return {"real": value.real, "imag": value.imag}
    if isinstance(value, np.ndarray):
        return value.tolist() if not np.iscomplexobj(value) else {
            "real": value.real.tolist(), "imag": value.imag.tolist()}
    if isinstance(value, np.generic):
        return encode(value.item())
    raise TypeError(type(value).__name__)


def save(fig, output, name):
    fig.savefig(output / (name + ".svg"), bbox_inches="tight",
                metadata={"Date": None})
    fig.savefig(output / (name + ".png"), dpi=160, bbox_inches="tight")
    p = output / (name + ".svg")
    p.write_bytes(("\n".join(line.rstrip() for line in
                            p.read_text(encoding="utf-8").splitlines()) + "\n").encode())
    plt.close(fig)


def load_groups(data, summaries):
    expected = [{r.get("name", r.get("file")): r["sha256"]
                 for r in s[key]} for s, key in summaries]
    if expected[0] != expected[1]:
        raise ValueError("Parent results use different raw captures")
    groups, audit = {}, []
    for capture in CAPTURES:
        cs, ms = [], []
        for ch in (1, 3):
            name = f"SDS814X_HD_Binary_C{ch}_{capture}.bin"
            matches = list(data.rglob(name))
            if len(matches) != 1:
                raise ValueError(f"Expected one {name}")
            p = matches[0]
            digest = sha(p)
            if digest != expected[0][name]:
                raise ValueError(f"Raw capture hash mismatch: {name}")
            m, voltage = read_capture(p)
            if m["channel"] != ch or m["fs_hz"] != FS:
                raise ValueError("Unexpected channel or sampling rate")
            c, _ = coefficients(voltage, N)
            cs.append(c[:, :MAXIMUM + 1].copy())
            ms.append(m)
            audit.append(dict(name=name, sha256=digest, samples=m["samples"],
                              segments=len(c), omitted_samples=len(voltage) % N))
        if any(ms[0][key] != ms[1][key] for key in
               ("samples", "fs_hz", "t_start_s")):
            raise ValueError("Pair timing mismatch")
        groups[capture] = cs
        print(f"Verified and transformed capture {capture}", flush=True)
    return groups, audit


def plots(v, t, a, summary, output):
    plt.rcParams.update({"font.size": 11, "axes.grid": True,
                         "grid.alpha": .2, "svg.fonttype": "none"})
    f = t["frequency_hz"] / 1e6
    ti = int(np.argmin(abs(f - 2)))
    example = a["example_y"]
    prediction = a["example_predictions"][:, 0]
    fig, ax = plt.subplots(1, 2, figsize=(9.2, 3.5), layout="constrained")
    r = np.arange(1, 81)
    ax[0].plot(r, 1e3 * example[:80].real, color="#202c39", label=r"Measured $\Re Y$")
    ax[0].plot(r, 1e3 * prediction[:80].real, "--", color=COLORS[0],
               label=r"Linear $\Re(L_0X)$")
    ax[0].set(xlabel=r"Test segment $r$", ylabel="Real coefficient (mV)",
              title=r"(a) $f=2.00195$ MHz, held-out capture 2")
    ax[0].legend(fontsize=9)
    ax[1].scatter(example[:80].real * 1e3, example[:80].imag * 1e3,
                  s=16, color="#202c39", label=r"Measured $Y$")
    ax[1].scatter(prediction[:80].real * 1e3, prediction[:80].imag * 1e3,
                  s=22, facecolors="none", edgecolors=COLORS[0], label=r"$L_0X$")
    for y, p in zip(example[:80], prediction[:80]):
        ax[1].plot([y.real * 1e3, p.real * 1e3], [y.imag * 1e3, p.imag * 1e3],
                   color="#999999", lw=.5)
    ax[1].set(xlabel=r"$\Re Y,\ \Re\widehat Y$ (mV)",
              ylabel=r"$\Im Y,\ \Im\widehat Y$ (mV)", title="(b) Same 80 complex coefficients")
    ax[1].set_aspect("equal", adjustable="datalim")
    ax[1].legend(fontsize=9)
    save(fig, output, "k05-fit-linear-example")

    fig, ax = plt.subplots(1, 2, figsize=(9.2, 3.3), layout="constrained")
    z = a["small_design"][:80, 1:]
    for j, pair in enumerate(SMALL_PAIRS):
        ax[j].plot(r, 1e6*z[:, j].real, label=r"$\Re Z$", color=COLORS[j])
        ax[j].plot(r, 1e6*z[:, j].imag, "--", label=r"$\Im Z$", color="#525d66")
        ax[j].set(xlabel=r"Training segment $r$ (capture 3)", ylabel=r"$Z_j$ (mV$^2$)",
                  title=f"({chr(97+j)}) ({pair[0]*FS/N/1e6:.3f}, {pair[1]*FS/N/1e6:.3f}) MHz")
        ax[j].legend(fontsize=9)
    save(fig, output, "k05-fit-products")

    m = a["small_scaled_moment"]
    fig, ax = plt.subplots(1, 2, figsize=(8.2, 3.3), layout="constrained")
    for ai, mat, title, cmap, limits in [
            (ax[0], abs(m), r"(a) $|M_{ij}|$", "viridis", (0, 1)),
            (ax[1], np.angle(m), r"(b) $\arg M_{ij}$ (rad)", "twilight", (-np.pi, np.pi))]:
        im = ai.imshow(mat, cmap=cmap, vmin=limits[0], vmax=limits[1])
        ai.set(xticks=range(3), yticks=range(3),
               xticklabels=[r"$X/s_0$", r"$Z_1/s_1$", r"$Z_2/s_2$"],
               yticklabels=[r"$X/s_0$", r"$Z_1/s_1$", r"$Z_2/s_2$"], title=title)
        ai.grid(False)
        for i in range(3):
            for j in range(3):
                ai.text(j, i, f"{mat[i,j]:.3f}", ha="center", va="center",
                        color="black" if (title.startswith("(a)") and mat[i,j] > .65) else "white")
        fig.colorbar(im, ax=ai, shrink=.82)
    save(fig, output, "k05-fit-matrix")

    fig, ax = plt.subplots(2, 1, figsize=(8.8, 5), sharex=True, layout="constrained")
    for j, (values, label) in enumerate([(v["linear_coefficient"], r"Linear only $L_0$"),
                                        (v["coefficients"][:, :, 0], r"Joint LS $L$")]):
        for fold in range(4):
            ax[0].plot(f, abs(values[fold]), color=COLORS[j], alpha=.15, lw=.8)
            ax[1].plot(f, np.angle(values[fold]), color=COLORS[j], alpha=.15, lw=.8)
        ax[0].plot(f, abs(values[0]), color=COLORS[j], label=label)
        ax[1].plot(f, np.angle(values[0]), color=COLORS[j])
    ax[0].set(ylabel=r"$|L_0|,\ |L|$ (dimensionless)")
    ax[0].legend()
    ax[1].set(xlabel=r"Target frequency $f$ (MHz)", ylabel=r"$\arg L_0,\ \arg L$ (rad)")
    for ai in ax:
        ai.axvline(f[ti], ls=":", color="#777777")
        ai.set_xlim(.5, 5)
    save(fig, output, "k05-fit-linear-coefficients")

    shape = (MAXIMUM, MAXIMUM + MAXIMUM//2 + 1)
    amp, phase = np.full(shape, np.nan), np.full(shape, np.nan)
    for k, count in enumerate(t["pair_count"]):
        for j, (b, c) in enumerate(t["pairs"][k, :count]):
            q = t["ls_coef"][0, k, j+1]
            amp[c-1, b+MAXIMUM] = abs(q)
            phase[c-1, b+MAXIMUM] = np.angle(q)
    extent = ((-MAXIMUM-.5)*FS/N/1e6, (MAXIMUM//2+.5)*FS/N/1e6,
              .5*FS/N/1e6, (MAXIMUM+.5)*FS/N/1e6)
    fig, ax = plt.subplots(1, 2, figsize=(9.3, 4), layout="constrained")
    for ai, mat, cmap, norm, title in [
            (ax[0], amp, "viridis", LogNorm(.01, max(1, np.nanmax(amp))), r"(a) $|Q(f_1,f_2)|$ (V$^{-1}$)"),
            (ax[1], phase, "twilight", Normalize(-np.pi, np.pi), r"(b) $\arg Q(f_1,f_2)$ (rad)")]:
        ai.set_facecolor("#efefef")
        im = ai.imshow(mat, origin="lower", extent=extent, aspect="auto",
                       cmap=cmap, norm=norm, interpolation="nearest")
        ai.set(xlabel=r"First input $f_1$ (MHz)", ylabel=r"Second input $f_2$ (MHz)", title=title)
        line_x = np.linspace(f[ti]-MAXIMUM*FS/N/1e6, f[ti]/2, 100)
        ai.plot(line_x, f[ti]-line_x, "--", color="white", lw=1.1, label=r"$f_1+f_2=2.002$ MHz")
        ai.legend(fontsize=8, loc="upper left", facecolor="#333333", labelcolor="white")
        fig.colorbar(im, ax=ai, shrink=.82, extend="min" if ai is ax[0] else "neither")
    save(fig, output, "k05-fit-quadratic-map")

    fig, ax = plt.subplots(2, 1, figsize=(8.8, 5.3), sharex=True, layout="constrained")
    ratio = t["powers"][:, :, 2] / np.min(t["powers"][:, :, :2], axis=2)
    for row in ratio:
        ax[0].plot(f, row, color=COLORS[2], alpha=.2, lw=.8)
    ax[0].axhspan(0, 1, color="#cfe6d9", alpha=.45, label="Allowed common-power range")
    ax[0].plot(f, ratio[0], color=COLORS[2], label="Kim, train 3/4/5")
    fail = ~t["admissible"][0]
    ax[0].scatter(f[fail], ratio[0,fail], facecolors="none", edgecolors=COLORS[2], s=18)
    ax[0].axhline(1, color="black", ls=":", lw=1)
    ax[0].set(ylabel=r"$P_*/\min(P_X,P_Y)$", ylim=(.9, 1.33))
    ax[0].legend(fontsize=9, ncol=2)
    ax[1].plot(f, abs(t["ls_coef"][0,:,0]), color=COLORS[1], label=r"Joint LS $|L|$")
    ax[1].plot(f, abs(t["kim_coef"][0,:,0]), "--", color=COLORS[2], label=r"Kim algebraic $|L|$")
    ax[1].scatter(f[fail], abs(t["kim_coef"][0,fail,0]), facecolors="none", edgecolors=COLORS[2], s=18,
                  label="Common-power bound fails")
    ax[1].set(xlabel=r"Target frequency $f$ (MHz)", ylabel=r"$|L|$ (dimensionless)", xlim=(.5,5))
    ax[1].legend(fontsize=9)
    save(fig, output, "k05-fit-kim")

    errors = np.concatenate([v["nmse"], t["budgets"][:,:,1,3,None]], axis=2)
    fig, ax = plt.subplots(2, 1, figsize=(8.8,5.5), sharex=True, layout="constrained")
    for j, label in enumerate(["Linear only", "Joint LS", "Kim algebraic (bound not enforced)"]):
        for fold in range(4):
            ax[0].semilogy(f, errors[fold,:,j], color=COLORS[j], lw=.8, alpha=.2)
        ax[0].semilogy(f, errors[0,:,j], color=COLORS[j], label=label)
        ax[1].semilogy(f, errors[0,:,j]*v["target_power"][0],
                       color=COLORS[j], label=label)
    ax[0].set(ylabel=r"$\langle|Y-\widehat Y|^2\rangle_{\rm test}/P_{Y,\rm test}$")
    ax[0].legend(fontsize=9)
    ax[1].set(xlabel=r"Target frequency $f$ (MHz)",
              ylabel=r"Residual $\langle|Y-\widehat Y|^2\rangle_{\rm test}$ (V$^2$)", xlim=(.5,5))
    save(fig, output, "k05-fit-heldout")


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--data", type=Path, required=True)
    p.add_argument("--validation", type=Path, required=True, help="Existing validation output directory")
    p.add_argument("--budget", type=Path, required=True, help="Existing transfer-budget output directory")
    p.add_argument("--output", type=Path, required=True)
    p.add_argument("--metadata", type=Path, default=Path(__file__).with_name("experiment_z5p5_a3p7.json"))
    args = p.parse_args()
    if args.output.exists() and any(args.output.iterdir()):
        raise FileExistsError("Use a new empty output directory")
    metadata = json.loads(args.metadata.read_text(encoding="utf-8"))
    if (metadata["capture_ids"] != list(CAPTURES) or metadata["channels"] != [1,3]
            or not metadata["synchronized_pairs"] or not metadata["same_operating_condition"]):
        raise ValueError("Requires the four confirmed synchronized C1/C3 captures")
    vs = json.loads((args.validation/"validation_summary.json").read_text(encoding="utf-8"))
    ts = json.loads((args.budget/"transfer_summary.json").read_text(encoding="utf-8"))
    if (vs["main_configuration"] != "n2048_b5" or ts["config"]["nperseg"] != N
            or ts["config"]["input_max_mhz"] != 5):
        raise ValueError("Unexpected parent configurations")
    with np.load(args.validation/"validation_arrays.npz") as z:
        v = {k.removeprefix("n2048_b5__"): z[k] for k in z.files if k.startswith("n2048_b5__")}
    with np.load(args.budget/"transfer_arrays.npz") as z:
        t = {k:z[k] for k in z.files}
    np.testing.assert_array_equal(v["frequency_hz"], t["frequency_hz"])
    np.testing.assert_allclose(v["coefficients"], t["ls_coef"], rtol=1e-10, atol=1e-12)
    groups, inputs = load_groups(args.data, [(vs,"raw_files"), (ts,"inputs")])
    ti = int(np.argmin(abs(t["frequency_hz"]-2e6)))
    pairs = signed_pairs(TARGET, MAXIMUM)
    np.testing.assert_array_equal(pairs, t["pairs"][ti,:len(pairs)])
    designs = {g:design_matrix(groups[g][0], TARGET, pairs) for g in CAPTURES}
    y = {g:groups[g][1][:,TARGET] for g in CAPTURES}
    train = np.concatenate([designs[g] for g in (3,4,5)])
    target = np.concatenate([y[g] for g in (3,4,5)])
    small = np.concatenate([design_matrix(groups[g][0], TARGET, SMALL_PAIRS) for g in (3,4,5)])
    h = small.conj().T @ small/len(small)
    rhs = small.conj().T @ target/len(target)
    scale = np.sqrt(np.diag(h).real)
    small_fit = fit_scaled(small, target)
    linear, joint, kim = fit_scaled(train[:,:1], target), fit_scaled(train,target), fit_kim(train,target)
    np.testing.assert_allclose(joint["coef"], v["coefficients"][0,ti,:len(pairs)+1], rtol=1e-9, atol=1e-11)
    np.testing.assert_allclose(kim["coef"], t["kim_coef"][0,ti,:len(pairs)+1], rtol=1e-9, atol=1e-11)
    np.testing.assert_allclose(linear["coef"][0], rhs[0]/h[0,0], rtol=1e-12)
    np.testing.assert_allclose(linear["coef"][0], v["linear_coefficient"][0,ti], rtol=1e-10)
    np.testing.assert_allclose(h @ small_fit["coef"], rhs, rtol=1e-10, atol=1e-15)
    prediction = np.column_stack([designs[2][:,0]*linear["coef"][0],
                                  designs[2]@joint["coef"], designs[2]@kim["coef"]])
    np.testing.assert_allclose(prediction[:,0], v["example_prediction_linear"], rtol=1e-9, atol=1e-12)
    np.testing.assert_allclose(prediction[:,1], v["example_prediction_quadratic"], rtol=1e-9, atol=1e-12)
    errors = np.mean(abs(y[2][:,None]-prediction)**2,axis=0)/np.mean(abs(y[2])**2)
    np.testing.assert_allclose(errors[:2],v["nmse"][0,ti], rtol=1e-10)
    np.testing.assert_allclose(errors[2], t["budgets"][0,ti,1,3], rtol=1e-10)
    # Check stored training powers and cross moments over all target frequencies.
    bins = v["target_bins"]
    xx = np.concatenate([groups[g][0][:,bins] for g in (3,4,5)])
    yy = np.concatenate([groups[g][1][:,bins] for g in (3,4,5)])
    np.testing.assert_allclose(np.mean(abs(xx)**2,axis=0), t["powers"][0,:,0], rtol=1e-10)
    np.testing.assert_allclose(np.mean(abs(yy)**2,axis=0), t["powers"][0,:,1], rtol=1e-10)
    np.testing.assert_allclose(np.mean(yy*xx.conj(),axis=0), t["moments"][0,:,0], rtol=1e-10)
    # Raw-unit Kim moment checks, including the complete fourth-moment equation.
    b = train[:,1:].conj().T @ train[:,0]/len(train)
    d = train[:,1:].conj().T @ target/len(train)
    ff = train[:,1:].conj().T @ train[:,1:]/len(train)
    q, ll = kim["coef"][1:], kim["coef"][0]
    np.testing.assert_allclose(ff@q, d-ll*b, rtol=1e-9, atol=1e-15)
    a = dict(small_pairs=SMALL_PAIRS, small_design=small, small_moment=h, small_rhs=rhs,
             small_scales=scale, small_scaled_moment=h/scale[:,None]/scale[None,:],
             small_scaled_rhs=rhs/scale, small_coef=small_fit["coef"],
             example_y=y[2], example_predictions=prediction, example_pairs=pairs,
             example_b=b, example_d=d, example_F=ff,
             example_ls=joint["coef"], example_kim=kim["coef"])
    summary = dict(config=dict(nperseg=N, fs_hz=FS, example_bin=TARGET, example_frequency_hz=TARGET*FS/N,
                training_captures=[3,4,5], heldout_capture=2, training_segments=len(train),
                test_segments=len(y[2]), max_input_bin=MAXIMUM, small_pairs=SMALL_PAIRS,
                convention="positive exponent / N; segment demean; periodic Hann; no overlap",
                coefficients="raw voltage: L dimensionless, Q inverse V; unordered unique signed pairs"),
        metadata=metadata, metadata_sha256=sha(args.metadata), inputs=inputs,
        parents={path.name:sha(path) for path in [
            args.validation/"validation_arrays.npz",args.validation/"validation_summary.json",
            args.budget/"transfer_arrays.npz",args.budget/"transfer_summary.json"]},
        source_sha256={name:sha(Path(__file__).with_name(name)) for name in [
            Path(__file__).name,"validate_experiment.py","analyze_transfer_budget.py",
            "analyze_experiment.py","siglent_v4.py"]},
        versions=dict(python=platform.python_version(),numpy=np.__version__,matplotlib=matplotlib.__version__),
        example=dict(px=kim["px"],py=kim["py"],g=kim["g"],linear_only=linear["coef"][0],
            joint_l=joint["coef"][0],small_lq=small_fit["coef"],small_scales=scale,
            small_scaled_moment=a["small_scaled_moment"],small_scaled_rhs=a["small_scaled_rhs"],
            pair_count=len(pairs),ls_rank=joint["rank"],ls_condition=joint["condition"],
            kim_l=ll,kim_alpha=kim["alpha"],kim_beta=kim["beta"],kim_eta=kim["eta"],
            kim_pstar=kim["pstar"],kim_admissible=kim["admissible"],kim_rank=kim["rank"],
            kim_condition=kim["condition"],nmse=errors),
        audit=dict(all_saved_training_moments_match=True,example_refits_match=True,
            kim_all_admissible=int(t["admissible"].sum()),kim_total=int(t["admissible"].size),
            kim_main_admissible=int(t["admissible"][0].sum()),
            ls_all_identified=bool(v["reliable"].all()),
            ls_condition_range=[float(v["condition"].min()),float(v["condition"].max())],
            main_improvement_percent_range=[float(v["improvement"][0].min()*100),float(v["improvement"][0].max()*100)],
            main_improvement_percent_median=float(np.median(v["improvement"][0])*100),
            fold_median_improvement_percent=(np.median(v["improvement"],axis=1)*100)),
        limitations=["A valid numerical solve is not a validation of stationary independent noise.",
                     "Kim failed-bound coefficients remain algebraic comparisons, not corrected physical coefficients.",
                     "Four folds share training captures; their spread is not a confidence interval.",
                     "Q magnitude is not an energy-transfer rate; no physical response or group velocity supplied."])
    args.output.mkdir(parents=True,exist_ok=True)
    np.savez_compressed(args.output/"coefficient_walkthrough_arrays.npz", **a)
    plots(v,t,a,summary,args.output)
    (args.output/"coefficient_walkthrough_summary.json").write_bytes(
        (json.dumps(summary,default=encode,indent=2,ensure_ascii=False)+"\n").encode())
    print(json.dumps(dict(example=summary["example"],audit=summary["audit"]),default=encode,indent=2))


if __name__ == "__main__":
    main()
