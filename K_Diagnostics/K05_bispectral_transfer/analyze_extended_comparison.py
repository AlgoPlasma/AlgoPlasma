# K05 contribution history (Git author dates; edit times include timezone).
# 2026-11-13 13:10 +08:00 | Yinjian Zhao | git dfd0f9af0503
# 2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)

"""Four whole-capture fits over 0.5--20 MHz for the page-08 comparison.

QR compresses training rows without changing their inner products; the existing
RMS-scaled SVD and Kim solvers then work on the small triangular matrix.
No response calibration or dispersion extrapolation is performed.
"""
from pathlib import Path
import argparse
import hashlib
import json
import time
import platform
import numpy as np
import scipy
from scipy.linalg import qr
import validate_experiment as v
from analyze_transfer_budget import fit_kim, power_budget


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def compressed_fit(design, y):
    """Preserve D*D, D*y and y*y, including the target's orthogonal residual.

    The augmented target column is essential: compressing D alone would lose
    the residual power needed by Kim. The final common normalization m/n is
    restored for moments, but cancels from all estimated coefficients.
    """
    n, p = design.shape
    if n < p + 1:
        raise ValueError('More training rows than augmented columns required')
    scales = np.r_[np.sqrt(np.mean(abs(design)**2, axis=0)),
                   np.sqrt(np.mean(abs(y)**2))]
    safe = np.where(scales > 0, scales, 1.)
    augmented = np.column_stack((design, y)) / safe
    r = qr(augmented, mode='r', check_finite=True, overwrite_a=True)[0][:p+1]
    r = r * safe
    dsmall, ysmall = r[:, :-1], r[:, -1]
    ls = v.fit_scaled(dsmall, ysmall)
    km = fit_kim(dsmall, ysmall)
    factor = len(r)/n
    ls['scales'] *= np.sqrt(factor)
    ls['singular'] /= np.sqrt(factor)
    km['scales'] *= np.sqrt(factor)
    for key in ('px', 'py', 'g', 'pstar', 'alpha', 'beta', 'eta'):
        km[key] *= factor
    return ls, km


def analyze(data, output, metadata):
    if data.resolve() == output.resolve() or data.resolve() in output.resolve().parents:
        raise ValueError('Derived output must be outside raw inputs')
    output.mkdir(parents=True, exist_ok=True)
    if any(output.iterdir()):
        raise FileExistsError('Choose a new empty output directory')
    cfg = json.loads(metadata.read_text(encoding='utf8'))
    if (cfg['capture_ids'] != list(v.CAPTURES) or cfg['channels'] != [1, 3]
            or not cfg['same_operating_condition'] or not cfg['synchronized_pairs']):
        raise ValueError('Four synchronized pairs at the same condition required')
    started = time.monotonic()
    groups, audit, files = {}, [], []
    fs = None
    n = 2048
    for g in v.CAPTURES:
        pair, infos = [], []
        for ch in (1, 3):
            paths = list(data.rglob(f'SDS814X_HD_Binary_C{ch}_{g}.bin'))
            if len(paths) != 1:
                raise ValueError('One raw file per capture/channel required')
            info, voltage = v.read_capture(paths[0])
            fs = info['fs_hz'] if fs is None else fs
            if info['fs_hz'] != fs or info['channel'] != ch or fs/2 <= 20e6:
                raise ValueError('Invalid channel or sample rate')
            c, _ = v.coefficients(voltage, n)
            maximum = int(20e6*n/fs)
            pair.append(c[:, :maximum+1].copy())
            infos.append(info); audit.append(info); files.append(paths[0])
        if any(infos[0][k] != infos[1][k] for k in ('samples','fs_hz','t_start_s')):
            raise ValueError('Pair timing differs')
        groups[g] = pair
        print(f'Loaded capture {g}', flush=True)
    bins = np.arange(int(np.ceil(.5e6*n/fs)), maximum+1)
    pairs = [v.signed_pairs(int(k), maximum) for k in bins]
    nf, pmax = len(bins), 1+max(map(len,pairs))
    a = dict(frequency_hz=bins*fs/n, captures=np.array(v.CAPTURES),
        pair_count=np.array(list(map(len,pairs))), pairs=np.zeros((nf,pmax-1,2),int),
        ls_coef=np.full((4,nf,pmax),np.nan+1j*np.nan),
        kim_coef=np.full((4,nf,pmax),np.nan+1j*np.nan),
        train_scales=np.full((4,nf,pmax),np.nan),
        phase=np.zeros((4,nf)), coherence=np.zeros((4,nf)),
        powers=np.zeros((4,nf,3)), test_powers=np.zeros((4,nf,2)),
        kim_condition=np.zeros((4,nf)), ls_condition=np.zeros((4,nf)),
        kim_rank=np.zeros((4,nf),int), ls_rank=np.zeros((4,nf),int),
        identified=np.zeros((4,nf),bool), admissible=np.zeros((4,nf),bool),
        moment_error=np.zeros((4,nf)),
        increments=np.zeros((4,nf,2,5)), budgets=np.zeros((4,nf,2,5)),
        nmse=np.zeros((4,nf,3)), linear_coefficient=np.zeros((4,nf),complex),
        pair_moment=np.full((4,nf,pmax-1),np.nan+1j*np.nan))
    for ti, (k, pp) in enumerate(zip(bins,pairs)):
        ds = {g:v.design_matrix(groups[g][0],k,pp) for g in v.CAPTURES}
        ys = {g:groups[g][1][:,k] for g in v.CAPTURES}
        a['pairs'][ti,:len(pp)] = pp
        for gi, heldout in enumerate(v.CAPTURES):
            train = [g for g in v.CAPTURES if g != heldout]
            d = np.concatenate([ds[g] for g in train])
            y = np.concatenate([ys[g] for g in train])
            ls, km = compressed_fit(d,y)
            cols = len(pp)+1
            for name, fit in [('ls',ls),('kim',km)]:
                a[name+'_coef'][gi,ti,:cols] = fit['coef']
                for key in ('condition','rank'):
                    a[name+'_'+key][gi,ti] = fit[key]
            a['train_scales'][gi,ti,:cols] = ls['scales']
            for key in ('identified','admissible','moment_error'):
                a[key][gi,ti] = km[key]
            a['powers'][gi,ti] = [km['px'],km['py'],km['pstar']]
            a['phase'][gi,ti] = phase = np.angle(km['g'])
            a['coherence'][gi,ti] = abs(km['g'])**2/(km['px']*km['py'])
            dt, yt = ds[heldout], ys[heldout]
            px, py = np.mean(abs(dt[:,0])**2), np.mean(abs(yt)**2)
            a['test_powers'][gi,ti] = [px,py]
            a['pair_moment'][gi,ti,:len(pp)] = np.mean(dt[:,0,None].conj()*dt[:,1:],axis=0)
            linear = km['g']/km['px']
            a['linear_coefficient'][gi,ti] = linear
            a['nmse'][gi,ti,0] = np.mean(abs(yt-linear*dt[:,0])**2)/py
            for mi, coef in enumerate([ls['coef'],km['coef']]):
                a['budgets'][gi,ti,mi],a['increments'][gi,ti,mi] = power_budget(dt,yt,coef,phase)
                a['nmse'][gi,ti,mi+1] = np.mean(abs(yt-dt@coef)**2)/py
        if ti % 10 == 0 or ti == nf-1:
            np.savez_compressed(output/'checkpoint.npz',completed=ti+1,**a)
            print(f'{ti+1}/{nf} targets, four holdouts; {time.monotonic()-started:.1f}s',flush=True)
    for path, info in zip(files,audit):
        if sha(path) != info['sha256']:
            raise RuntimeError('Raw data changed during calculation')
    np.savez_compressed(output/'extended_arrays.npz', **a)
    difference = a['test_powers'][:,:,1]/a['test_powers'][:,:,0]-1
    audit_values = dict(max_power_identity_error=float(np.nanmax(abs(a['budgets'].sum(-1)-1))),
        max_increment_identity_error=float(np.nanmax(abs(a['increments'].sum(-1)-difference[:,:,None]))),
        max_kim_moment_error=float(np.nanmax(a['moment_error'])),
        max_ls_condition=float(a['ls_condition'].max()),
        kim_admissible=int(a['admissible'].sum()),total=int(a['admissible'].size))
    bands = []
    for lo,hi in [(.5,5),(5,10),(10,15),(15,20),(5,20)]:
        selected = (a['frequency_hz']>=lo*1e6)&(a['frequency_hz']<hi*1e6)
        mse = (a['nmse'][:,selected]*a['test_powers'][:,selected,1,None]).sum(1)
        bands.append(dict(band_mhz=[lo,hi],targets=int(selected.sum()),
            improvement_by_holdout=(1-mse[:,1]/mse[:,0]).tolist(),
            kim_admissible_by_holdout=a['admissible'][:,selected].sum(1).tolist()))
    report = dict(config=dict(nperseg=n,fs_hz=fs,target_mhz=[.5,20],input_max_mhz=20,
        actual_frequency_hz=[float(a['frequency_hz'][0]),float(a['frequency_hz'][-1])],
        fourier='exp(+i 2 pi f t)/N',window='periodic Hann',demean='each segment',overlap=0,
        rcond=v.RCOND,condition_limit=v.CONDITION_LIMIT,
        pair_rule='Unique nonzero signed b<=c, b+c=target; no modulo wrapping',
        validation='Four whole-capture holdouts; training-only scaling/phase/coefficients',
        compressed_solver='QR of augmented [D,y], preserving yy residual; existing SVD and Kim',
        assumed_speed_m_per_s=2150.,separation_m=.0037,response_correction='none'),
        raw_files=audit,metadata_sha256=sha(metadata),bands=bands,audit=audit_values,
        elapsed_s=time.monotonic()-started,versions=dict(python=platform.python_version(),numpy=np.__version__,scipy=scipy.__version__),
        source_hashes={p.name:sha(p) for p in [Path(__file__),Path(v.__file__),Path(__file__).with_name('analyze_transfer_budget.py')]})
    (output/'extended_summary.json').write_text(json.dumps(v.json_safe(report),indent=2,allow_nan=False)+'\n',encoding='utf8')
    (output/Path(__file__).name).write_bytes(Path(__file__).read_bytes())
    print(json.dumps(audit_values),flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--metadata',type=Path,default=Path(__file__).with_name('experiment_z5p5_a3p7.json'))
    args=parser.parse_args()
    analyze(args.data,args.output,args.metadata)
