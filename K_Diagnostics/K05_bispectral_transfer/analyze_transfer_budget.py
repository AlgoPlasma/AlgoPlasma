"""Stationary Kim moments and exact held-out budgets; parent fits for page 07.

Measured-voltage coefficients only. No response correction or group velocity
is silently supplied. See --help and EXPERIMENT.md for the assumptions.
"""
from pathlib import Path
import argparse
import hashlib
import json
import platform
import numpy as np
from validate_experiment import (CAPTURES, RCOND, CONDITION_LIMIT,
    load_coefficients, signed_pairs, design_matrix, fit_scaled)


def fit_kim(design, y):
    """Column-vector version of Kim et al. (1996), equations (11)-(17).

    Solve the full fourth moment via the SVD of RMS-scaled product columns.
    No diagonal/random-phase closure; singular cases remain invalid.
    """
    x, z = design[:, 0], design[:, 1:]
    if len(x) == 0 or len(y) != len(x) or not np.isfinite(design).all() or not np.isfinite(y).all():
        raise ValueError("Finite, nonempty matching rows required")
    px, py = np.mean(abs(x)**2), np.mean(abs(y)**2)
    g = np.mean(y*x.conj())
    scales = np.sqrt(np.mean(abs(z)**2, axis=0))
    result = dict(px=float(px), py=float(py), g=g, scales=scales,
        coef=np.full(design.shape[1], np.nan+1j*np.nan), pstar=np.nan,
        alpha=np.nan, beta=np.nan, eta=np.nan+1j*np.nan,
        rank=0, condition=np.inf, identified=False, admissible=False,
        moment_error=np.nan)
    if not (px > 0 and py > 0) or np.any(scales == 0):
        return result
    if z.shape[1]:
        zs = z/scales
        u, s, vh = np.linalg.svd(zs, full_matrices=False)
        rank = int(np.sum(s > RCOND*s[0]))
        result.update(rank=rank, condition=float(s[0]/s[-1]) if rank == len(s) else np.inf)
        if rank != z.shape[1] or result['condition'] > CONDITION_LIMIT:
            return result
        # Project x and y onto the complete product space; no Gram inversion.
        cx = vh.conj().T @ ((u.conj().T @ x)/s)
        cy = vh.conj().T @ ((u.conj().T @ y)/s)
        b = zs.conj().T @ x/len(x)
        d = zs.conj().T @ y/len(x)
        alpha = float(np.vdot(b, cx).real)
        beta = float(np.vdot(d, cy).real)
        eta = g-np.vdot(b, cy)
    else:
        result['condition'] = 1.
        b = d = cx = cy = np.empty(0, complex)
        alpha = beta = 0.
        eta = g
    pstar = (alpha+beta+np.hypot(alpha-beta, 2*abs(eta)))/2
    denominator = pstar-alpha
    result.update(alpha=alpha, beta=beta, eta=eta, pstar=float(pstar))
    if denominator <= 1e-12*max(px, py):
        return result
    linear = eta/denominator
    qs = cy-linear*cx
    result['coef'] = np.r_[linear, qs/scales]
    result['identified'] = True
    # Only a floating-point tolerance, not a statistical confidence interval.
    result['admissible'] = bool(0 <= pstar <= min(px, py)*(1+1e-6))
    errors = [g-linear*pstar-np.vdot(b, qs),
              pstar-linear*g.conjugate()-np.vdot(d, qs)]
    result['moment_error'] = float(np.max(abs(np.asarray(errors)))/max(px, py))
    return result


def power_budget(design, y, coef, phase):
    """Exact measured-signal identity, with explicit held-out residual cross term."""
    x = design[:, 0]
    a = x*coef[0]
    b = design[:, 1:]@coef[1:]
    residual = y-a-b
    py = np.mean(abs(y)**2)
    parts = np.array([np.mean(abs(a)**2), 2*np.mean((a.conj()*b).real),
                      np.mean(abs(b)**2), np.mean(abs(residual)**2),
                      2*np.mean(((a+b).conj()*residual).real)])
    rot = np.exp(-1j*phase)
    px = np.mean(abs(x)**2)
    ell = rot*coef[0]-1
    nonlinear = rot*b
    r = rot*residual
    step = ell*x+nonlinear
    # (PY-PX)/PX = first-order linear + first-order quadratic
    #             + finite-step square + residual power + residual cross.
    increments = np.array([2*ell.real,
        2*np.mean((x.conj()*nonlinear).real)/px,
        np.mean(abs(step)**2)/px,
        np.mean(abs(r)**2)/px,
        2*np.mean(((x+step).conj()*r).real)/px])
    return parts/py, increments


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--data', type=Path, required=True)
    p.add_argument('--output', type=Path, required=True)
    p.add_argument('--metadata', type=Path, default=Path(__file__).with_name('experiment_z5p5_a3p7.json'))
    args = p.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    if (args.output/'transfer_arrays.npz').exists():
        raise FileExistsError("Choose a new output directory to preserve prior numerical results")
    metadata = json.loads(args.metadata.read_text(encoding="utf-8"))
    fs, all_groups, audit, files = load_coefficients(args.data, metadata)
    groups = all_groups[2048]
    del all_groups
    n = 2048
    bins = np.arange(int(np.ceil(.5e6*n/fs)), int(5e6*n/fs)+1)
    pairs = [signed_pairs(int(k), int(5e6*n/fs)) for k in bins]
    nf = len(bins); pc = 1+max(map(len, pairs))
    a = dict(frequency_hz=bins*fs/n, captures=np.array(CAPTURES),
        pairs=np.zeros((nf,pc-1,2),int), pair_count=np.array(list(map(len,pairs))),
        kim_coef=np.full((4,nf,pc),np.nan+1j*np.nan),
        ls_coef=np.full((4,nf,pc),np.nan+1j*np.nan),
        scales=np.full((4,nf,pc-1),np.nan),
        powers=np.zeros((4,nf,3)), moments=np.zeros((4,nf,4),complex),
        phase=np.zeros((4,nf)), coherence=np.zeros((4,nf)),
        condition=np.zeros((4,nf)), rank=np.zeros((4,nf),int),
        identified=np.zeros((4,nf),bool), admissible=np.zeros((4,nf),bool),
        moment_error=np.zeros((4,nf)), test_ratio=np.zeros((4,nf)),
        budgets=np.zeros((4,nf,2,5)), increments=np.zeros((4,nf,2,5)))
    for ti,(k,pp) in enumerate(zip(bins,pairs)):
        ds = {g:design_matrix(groups[g][0],k,pp) for g in CAPTURES}
        ys = {g:groups[g][1][:,k] for g in CAPTURES}
        a['pairs'][ti,:len(pp)] = pp
        for gi,heldout in enumerate(CAPTURES):
            train = [g for g in CAPTURES if g != heldout]
            d,y = np.concatenate([ds[g] for g in train]),np.concatenate([ys[g] for g in train])
            km = fit_kim(d,y)
            ls = fit_scaled(d,y)
            cols = len(pp)+1
            a['kim_coef'][gi,ti,:cols] = km['coef']
            a['ls_coef'][gi,ti,:cols] = ls['coef']
            a['scales'][gi,ti,:len(pp)] = km['scales']
            a['powers'][gi,ti] = [km['px'],km['py'],km['pstar']]
            a['moments'][gi,ti] = [km['g'],km['alpha'],km['beta'],km['eta']]
            a['phase'][gi,ti] = phase = np.angle(km['g'])
            a['coherence'][gi,ti] = abs(km['g'])**2/(km['px']*km['py'])
            for key in ('condition','rank','identified','admissible','moment_error'):
                a[key][gi,ti] = km[key]
            a['test_ratio'][gi,ti] = np.mean(abs(ys[heldout])**2)/np.mean(abs(ds[heldout][:,0])**2)
            for mi,coef in enumerate([ls['coef'],km['coef']]):
                a['budgets'][gi,ti,mi],a['increments'][gi,ti,mi] = power_budget(ds[heldout],ys[heldout],coef,phase)
        if ti%15 == 0 or ti==nf-1:
            print(f"Kim/LS: {ti+1}/{nf} frequencies, four held-out captures",flush=True)
    np.savez_compressed(args.output/'transfer_arrays.npz',**a)
    finite = a['identified']
    budget_error = np.nanmax(abs(a['budgets'].sum(axis=-1)-1))
    inc_error = np.nanmax(abs(a['increments'].sum(axis=-1)-(a['test_ratio']-1)[:,:,None]))
    sha = lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
    summary = dict(config=dict(nperseg=n, target_mhz=[.5,5],input_max_mhz=5,
        fourier='exp(+i 2 pi f t)/N', window='periodic Hann',demean='each segment',
        overlap=0,rcond=RCOND,condition_limit=CONDITION_LIMIT,admissibility_relative_tolerance=1e-6,
        separation_m=.0037, direction='positive coordinate C1 to C3; not measured propagation',
        response_correction='none', group_velocity_m_per_s=None),
        metadata=metadata, metadata_sha256=sha(args.metadata),
        inputs=[dict(name=f.name,sha256=sha(f),bytes=f.stat().st_size) for f in files],
        source_sha256={f.name:sha(f) for f in [Path(__file__),Path(__file__).with_name('validate_experiment.py'),
             Path(__file__).with_name('analyze_experiment.py'),Path(__file__).with_name('siglent_v4.py')]},
        versions=dict(python=platform.python_version(),numpy=np.__version__),
        frequencies=nf, example_frequency_hz=float(a['frequency_hz'][np.argmin(abs(a['frequency_hz']-2e6))]),
        audit=dict(identified=int(finite.sum()),admissible=int(a['admissible'].sum()),
            total=int(finite.size),max_condition=float(a['condition'].max()),
            max_moment_error=float(np.nanmax(a['moment_error'])),
            max_budget_identity_error=float(budget_error),max_increment_identity_error=float(inc_error)),
        folds=[dict(heldout=g,train=[t for t in CAPTURES if t!=g],
            admissible=int(a['admissible'][j].sum()),
            common_fraction_min=float(np.nanmin(a['powers'][j,:,2]/np.minimum(a['powers'][j,:,0],a['powers'][j,:,1]))),
            common_fraction_max=float(np.nanmax(a['powers'][j,:,2]/np.minimum(a['powers'][j,:,0],a['powers'][j,:,1]))))
            for j,g in enumerate(CAPTURES)])
    (args.output/'transfer_summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False)+'\n', encoding="utf-8")
    print(json.dumps(summary['audit']),flush=True)


if __name__ == '__main__':
    main()
