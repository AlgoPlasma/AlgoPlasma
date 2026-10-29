"""Compare linear and quadratic probe models by leaving out whole captures.

All coefficients describe measured volts, not calibrated plasma growth or energy.
Run with --help. Numerical results and figures are written outside the raw inputs.
"""
from pathlib import Path
import argparse
import hashlib
import json
import platform

import numpy as np
import scipy
import matplotlib
import matplotlib.pyplot as plt

from analyze_experiment import coefficients
from siglent_v4 import read_capture

RCOND = 1e-10
CONDITION_LIMIT = 1e8
CAPTURES = (2, 3, 4, 5)
CONFIGS = ((2048, 5), (1024, 5), (4096, 5), (2048, 3), (2048, 8))
MODEL_COLORS = ("#007c91", "#d85c32")


def signed_pairs(target, maximum):
    """Unique nonzero signed pairs b <= c, b+c=target, |b|,|c|<=maximum."""
    if target <= 0 or maximum < 1:
        raise ValueError("Positive target and input limit required")
    return np.array([(b, target-b) for b in range(-maximum, maximum+1)
                     if b != 0 and b <= target-b and 0 < abs(target-b) <= maximum],
                    dtype=int).reshape(-1, 2)


def design_matrix(c, target, pairs):
    """c holds positive-exponent Fourier coefficients; negative bins are conjugates."""
    def signed(k):
        v = c[:, abs(k)]
        return v if k > 0 else v.conj()
    return np.column_stack([c[:, target]] + [signed(b)*signed(d) for b, d in pairs])


def fit_scaled(design, target):
    """No intercept; RMS scaling and SVD use only the supplied training rows."""
    if len(design) != len(target) or len(target) == 0:
        raise ValueError("Training rows are empty or mismatched")
    if not np.all(np.isfinite(design)) or not np.all(np.isfinite(target)):
        raise ValueError("Nonfinite training values")
    scales = np.sqrt(np.mean(abs(design)**2, axis=0))
    active = scales > 0
    coef = np.zeros(design.shape[1], dtype=complex)
    singular = np.zeros(design.shape[1])
    rank = 0
    if np.any(active):
        theta, _, rank, values = np.linalg.lstsq(design[:, active]/scales[active],
                                                target, rcond=RCOND)
        coef[active] = theta/scales[active]
        singular[:len(values)] = values
    condition = float(singular[0]/singular[-1]) if rank == len(coef) else float("inf")
    return dict(coef=coef, scales=scales, singular=singular, rank=int(rank),
                condition=condition, reliable=bool(rank == len(coef) and condition <= CONDITION_LIMIT))


def fit_fold(designs, targets, heldout):
    """All preprocessing for fitting excludes the entire held-out capture."""
    train = sorted(set(designs)-{heldout})
    d = np.concatenate([designs[g] for g in train])
    y = np.concatenate([targets[g] for g in train])
    linear = fit_scaled(d[:, :1], y)
    quadratic = fit_scaled(d, y)
    power = np.mean(abs(y)**2)
    train_nmse = np.array([mean_square(y-d[:, :1]@linear['coef']),
                           mean_square(y-d@quadratic['coef'])])
    train_nmse = train_nmse/power if power > 0 else np.full(2, np.nan)
    return linear, quadratic, train_nmse


def mean_square(x):
    return float(np.mean(abs(x)**2))


def normalized_correlation(residual, design):
    """Squared, uncentred residual/predictor cross moment on held-out rows."""
    den = mean_square(residual)*np.mean(abs(design)**2, axis=0)
    cross = np.mean(residual[:, None]*design.conj(), axis=0)
    return np.divide(abs(cross)**2, den, out=np.full(len(den), np.nan), where=den > 0)


def evaluate(y, design, linear, quadratic):
    p0 = design[:, 0]*linear['coef'][0]
    a = design[:, 0]*quadratic['coef'][0]
    terms = design[:, 1:]*quadratic['coef'][None, 1:]
    b = terms.sum(axis=1)
    p1 = a+b
    power = mean_square(y)
    mse = np.array([mean_square(y-p0), mean_square(y-p1)])
    nmse = mse/power if power > 0 else np.full(2, np.nan)
    improvement = 1-mse[1]/mse[0] if power > 0 and mse[0] > 0 else float('nan')
    contributions = np.array([mean_square(a), 2*np.mean((a.conj()*b).real), mean_square(b)])
    pair_cross = 2*np.mean((a.conj()[:, None]*terms).real, axis=0)
    residual_corr = np.array([normalized_correlation(y-p, design) for p in (p0, p1)])
    return dict(power=power, mse=mse, nmse=nmse, improvement=improvement,
                prediction_power=np.array([mean_square(p0), mean_square(p1)]),
                budget=contributions, pair_cross=pair_cross, residual_corr=residual_corr,
                prediction_linear=p0, prediction_quadratic=p1)


def load_coefficients(data, metadata):
    if metadata['capture_ids'] != list(CAPTURES) or metadata['channels'] != [1, 3]:
        raise ValueError("Expected C1/C3 captures 2, 3, 4, 5")
    if not metadata['synchronized_pairs'] or not metadata['same_operating_condition']:
        raise ValueError("This comparison requires confirmed synchronized pairs at one condition")
    groups = {n: {} for n in (1024, 2048, 4096)}
    audit, files = [], []
    common_fs = None
    for group in CAPTURES:
        pair_meta, pair_coeff = [], []
        for ch in (1, 3):
            paths = list(data.rglob(f'SDS814X_HD_Binary_C{ch}_{group}.bin'))
            if len(paths) != 1:
                raise ValueError(f'Expected exactly one C{ch} capture {group}')
            m, voltage = read_capture(paths[0])
            if m['channel'] != ch:
                raise ValueError('Channel header mismatch')
            if common_fs is None:
                common_fs = m['fs_hz']
            if m['fs_hz'] != common_fs or common_fs/2 <= 8e6:
                raise ValueError('Sampling rates differ or bandwidth is insufficient')
            by_n = {}
            for n in groups:
                c, _ = coefficients(voltage, n)
                kmax = int(8e6/(common_fs/n))
                by_n[n] = c[:, :kmax+1].copy()
            pair_coeff.append(by_n); pair_meta.append(m)
            audit.append(m); files.append(paths[0])
        if any(pair_meta[0][k] != pair_meta[1][k] for k in ('samples', 'fs_hz', 't_start_s')):
            raise ValueError('Pair timing differs')
        for n in groups:
            groups[n][group] = (pair_coeff[0][n], pair_coeff[1][n])
        print(f'Loaded capture #{group}', flush=True)
    return common_fs, groups, audit, files


def run_configuration(groups, fs, n, input_mhz, target_bins=None, heldout_captures=CAPTURES):
    maximum = min(int(input_mhz*1e6/(fs/n)), n//2-1)
    bins = (np.arange(int(np.ceil(.5e6/(fs/n))), int(5e6/(fs/n))+1)
            if target_bins is None else np.asarray(target_bins, dtype=int))
    if len(bins)==0 or np.any(bins<=0) or np.any(bins>=n//2) or len(set(bins))!=len(bins):
        raise ValueError('Unique target bins strictly between DC and Nyquist required')
    if not heldout_captures or len(set(heldout_captures)) != len(heldout_captures) or any(g not in CAPTURES for g in heldout_captures):
        raise ValueError('Choose unique held-out captures from 2, 3, 4, 5')
    pairs = [signed_pairs(int(k), maximum) for k in bins]
    pmax = 1+max(len(p) for p in pairs)
    shape = (len(heldout_captures), len(bins))
    result = dict(frequency_hz=bins*fs/n, target_bins=bins,
                  heldout_captures=np.array(heldout_captures),
                  pair_bins=np.zeros((len(bins), pmax-1, 2), dtype=int),
                  pair_count=np.array([len(p) for p in pairs]),
                  coefficients=np.full((*shape, pmax), complex(np.nan, np.nan)),
                  scales=np.full((*shape, pmax), np.nan), singular=np.full((*shape, pmax), np.nan),
                  linear_coefficient=np.full(shape, complex(np.nan, np.nan)),
                  rank=np.zeros(shape, dtype=int), condition=np.full(shape, np.nan),
                  reliable=np.zeros(shape, dtype=bool),
                  target_power=np.full(shape, np.nan), mse=np.full((*shape, 2), np.nan),
                  nmse=np.full((*shape, 2), np.nan), train_nmse=np.full((*shape, 2), np.nan),
                  improvement=np.full(shape, np.nan), prediction_power=np.full((*shape, 2), np.nan),
                  budget=np.full((*shape, 3), np.nan),
                  pair_cross=np.full((*shape, pmax-1), np.nan),
                  residual_x=np.full((*shape, 2), np.nan), residual_z_max=np.full((*shape, 2), np.nan))
    example_index = int(np.argmin(abs(result['frequency_hz']-2e6)))
    for ti, (k, pp) in enumerate(zip(bins, pairs)):
        result['pair_bins'][ti, :len(pp)] = pp
        designs = {g: design_matrix(groups[g][0], k, pp) for g in CAPTURES}
        targets = {g: groups[g][1][:, k] for g in CAPTURES}
        for gi, g in enumerate(heldout_captures):
            linear, quadratic, training = fit_fold(designs, targets, g)
            ev = evaluate(targets[g], designs[g], linear, quadratic)
            pc = len(pp)+1
            for name in ('coefficients', 'scales', 'singular'):
                result[name][gi, ti, :pc] = quadratic['coef' if name == 'coefficients' else name]
            for name in ('rank', 'condition', 'reliable'):
                result[name][gi, ti] = quadratic[name]
            result['linear_coefficient'][gi, ti] = linear['coef'][0]
            result['train_nmse'][gi, ti] = training
            result['target_power'][gi, ti] = ev['power']
            for name in ('mse','nmse','improvement','prediction_power','budget'):
                result[name][gi, ti] = ev[name]
            result['pair_cross'][gi, ti, :len(pp)] = ev['pair_cross']
            result['residual_x'][gi, ti] = ev['residual_corr'][:, 0]
            if len(pp):
                result['residual_z_max'][gi, ti] = np.nanmax(ev['residual_corr'][:, 1:], axis=1)
            if gi == 0 and ti == example_index:
                result['example_target'] = targets[g]
                result['example_prediction_linear'] = ev['prediction_linear']
                result['example_prediction_quadratic'] = ev['prediction_quadratic']
                result['example_time_s'] = (np.arange(len(targets[g]))+.5)*n/fs
                result['example_frequency_hz'] = np.array([k*fs/n])
        if target_bins is not None or ti % 25 == 0 or ti == len(bins)-1:
            print(f'N={n}, input={input_mhz} MHz: {ti+1}/{len(bins)} targets', flush=True)
    return result


def configuration_summary(result, n, input_mhz):
    folds = []
    for gi, g in enumerate(result.get('heldout_captures', CAPTURES)):
        g = int(g)
        loss = result['mse'][gi].sum(axis=0)
        power = result['target_power'][gi].sum()
        folds.append(dict(heldout=g, train=[t for t in CAPTURES if t != g],
                          band_nmse=(loss/power).tolist() if power > 0 else [None, None],
                          band_improvement=float(1-loss[1]/loss[0]) if loss[0] > 0 else None,
                          bins_improved=int(np.sum(result['improvement'][gi] > 0)),
                          reliable_bins=int(result['reliable'][gi].sum()),
                          condition_max=float(result['condition'][gi].max())))
    return dict(nperseg=n, input_max_mhz=input_mhz, targets=len(result['frequency_hz']),
                quadratic_columns_range=[int(result['pair_count'].min()),int(result['pair_count'].max())],
                example_frequency_hz=float(result['example_frequency_hz'][0]), folds=folds)


def save_figure(fig, output, stem):
    fig.savefig(output/f'k05-validation-{stem}.svg', metadata={'Date': None}, bbox_inches='tight')
    fig.savefig(output/f'k05-validation-{stem}.png', dpi=140, bbox_inches='tight')
    plt.close(fig)


def spread(ax, f, values, label, color):
    """Four-fold range, never labelled a confidence interval."""
    ax.plot(f, np.mean(values, axis=0), label=label, color=color)
    ax.fill_between(f, np.min(values, axis=0), np.max(values, axis=0), color=color, alpha=.13)


def plot_results(results, fs, output):
    base = results['n2048_b5']
    f = base['frequency_hz']/1e6
    fig, ax = plt.subplots(figsize=(8, 3.6), layout='constrained')
    ax.imshow(np.eye(4), cmap=matplotlib.colors.ListedColormap(['#d6ecee','#efab87']), vmin=0, vmax=1)
    for row in range(4):
        for col in range(4):
            ax.text(col,row,'TEST' if row==col else 'FIT',ha='center',va='center',fontsize=11)
    ax.set_xticks(range(4),[f'Capture\n#{g}' for g in CAPTURES]);ax.set_yticks(range(4),[f'Hold out #{g}' for g in CAPTURES])
    ax.set_title('Whole captures stay together: three fit, one tests');ax.grid(False)
    save_figure(fig,output,'folds')

    psd_scale = 2*2048/(fs*(3/8))
    fig, axes = plt.subplots(2,1,figsize=(9,6),sharex=True,layout='constrained')
    axes[0].semilogy(f,base['target_power'][0]*psd_scale,color='#333333',label='Measured C3')
    for j,(label,col) in enumerate(zip(('Linear prediction','Linear + quadratic prediction'),MODEL_COLORS)):
        axes[0].semilogy(f,base['prediction_power'][0,:,j]*psd_scale,color=col,label=label)
        axes[1].semilogy(f,base['mse'][0,:,j]*psd_scale,color=col,label=label)
    axes[0].set_ylabel('Coefficient-derived PSD (V²/Hz)');axes[1].set_ylabel('Residual PSD (V²/Hz)')
    axes[0].set_title('Capture #2 held out; predictions use C1 from that capture')
    axes[0].legend(fontsize=9);axes[1].set_xlabel('Target frequency (MHz)')
    save_figure(fig,output,'spectra')

    fig, axes = plt.subplots(2,1,figsize=(9,5.6),sharex=True,layout='constrained')
    t=base['example_time_s'][:150]*1e3
    for ax,part,label in zip(axes,(np.real,np.imag),('Real part (V)','Imaginary part (V)')):
        ax.plot(t,part(base['example_target'][:150]),color='#333333',label='Measured C3',lw=1.1)
        ax.plot(t,part(base['example_prediction_linear'][:150]),color=MODEL_COLORS[0],label='Linear',lw=.9)
        ax.plot(t,part(base['example_prediction_quadratic'][:150]),color=MODEL_COLORS[1],label='Linear + quadratic',lw=.9,ls='--')
        ax.set_ylabel(label)
    axes[0].legend(ncol=3,fontsize=9)
    axes[0].set_title(f"Held-out #2: Fourier coefficient at {base['example_frequency_hz'][0]/1e6:.6f} MHz\nFirst 150 segments; these are not raw-voltage samples")
    axes[1].set_xlabel('Segment midpoint (ms)');save_figure(fig,output,'example')

    fig,axes=plt.subplots(2,1,figsize=(9,6.4),sharex=True,layout='constrained')
    for j,(label,col) in enumerate(zip(('Linear','Linear + quadratic'),MODEL_COLORS)):
        spread(axes[0],f,base['nmse'][:,:,j],label,col)
    for gi,g in enumerate(CAPTURES):
        axes[1].plot(f,100*base['improvement'][gi],label=f'Hold out #{g}',lw=1)
    axes[0].set_ylabel('Held-out NMSE');axes[0].legend();axes[0].set_yscale('log')
    axes[1].axhline(0,color='#333333',lw=.8);axes[1].set_ylabel('Error reduction (%)')
    axes[1].legend(ncol=4,fontsize=8);axes[1].set_xlabel('Target frequency (MHz)')
    axes[0].set_title('Mean and range of four held-out captures; shaded range is not a confidence interval')
    save_figure(fig,output,'errors')

    fig,axes=plt.subplots(2,1,figsize=(9,6),sharex=True,layout='constrained')
    for j,(label,col) in enumerate(zip(('Linear residual','Linear + quadratic residual'),MODEL_COLORS)):
        spread(axes[0],f,base['residual_x'][:,:,j],label,col)
        spread(axes[1],f,base['residual_z_max'][:,:,j],label,col)
    axes[0].set_ylabel('Residual–X squared correlation');axes[1].set_ylabel('Maximum residual–Z\nsquared correlation')
    axes[0].legend(fontsize=9);axes[1].set_xlabel('Target frequency (MHz)')
    axes[0].set_title('Held-out residuals: means and four-capture ranges\nMaximum over pairs is a diagnostic, not a significance test')
    save_figure(fig,output,'residuals')

    fig,axes=plt.subplots(2,2,figsize=(11,6),sharex=True,layout='constrained')
    for gi,g in enumerate(CAPTURES):
        for j,l in enumerate((base['linear_coefficient'][gi],base['coefficients'][gi,:,0])):
            axes[0,j].plot(f,abs(l),label=f'Hold out #{g}',lw=.9)
            axes[1,j].plot(f,np.angle(l),lw=.9)
    for j,title in enumerate(('Linear-only L','Joint-fit L')):
        axes[0,j].set_title(title);axes[0,j].legend(ncol=2,fontsize=8)
        axes[1,j].set_xlabel('Target frequency (MHz)')
        axes[1,j].set_ylim(-np.pi,np.pi)
    axes[0,0].set_ylabel('|L| (dimensionless)');axes[1,0].set_ylabel('Wrapped arg L (rad)')
    fig.suptitle('Raw voltage-model coefficients; these are not growth rates')
    save_figure(fig,output,'coefficients')

    fig,axes=plt.subplots(2,1,figsize=(9,5.5),sharex=True,layout='constrained')
    for gi,g in enumerate(CAPTURES):
        axes[0].semilogy(f,base['condition'][gi],label=f'Hold out #{g}')
        axes[1].plot(f,base['rank'][gi]/(base['pair_count']+1),lw=1)
    axes[0].legend(ncol=4,fontsize=8);axes[0].set_ylabel('Scaled condition number')
    axes[1].set_ylabel('Rank / columns');axes[1].set_ylim(0,1.05);axes[1].set_xlabel('Target frequency (MHz)')
    axes[0].set_title('Joint design matrix: numerical identifiability\nFlag if rank deficient or condition > 10⁸; rcond = 10⁻¹⁰')
    save_figure(fig,output,'conditioning')

    fig,axes=plt.subplots(2,2,figsize=(11,7),sharex=True,layout='constrained')
    common=results['n1024_b5']['frequency_hz']
    configs_by_col=(('n1024_b5','n2048_b5','n4096_b5'),('n2048_b3','n2048_b5','n2048_b8'))
    for col,keys in enumerate(configs_by_col):
        for key in keys:
            r=results[key];selected=np.flatnonzero(np.isin(r['frequency_hz'],common))
            x=r['frequency_hz'][selected]/1e6
            label=('N='+key.split('_')[0][1:]) if col==0 else ('Inputs ≤ '+key.split('_b')[1]+' MHz')
            axes[0,col].plot(x,100*np.mean(r['improvement'][:,selected],axis=0),label=label)
            q=r['budget'][:,:,2]/r['target_power']
            axes[1,col].plot(x,np.mean(q[:,selected],axis=0),label=label)
        axes[0,col].axhline(0,color='#333333',lw=.7);axes[0,col].legend(fontsize=9)
        axes[1,col].set_xlabel('Common target frequency (MHz)')
    axes[0,0].set_ylabel('Mean error reduction (%)');axes[1,0].set_ylabel('Mean ⟨|B|²⟩ / ⟨|Y|²⟩')
    axes[0,0].set_title('Segment length; input limit fixed at 5 MHz')
    axes[0,1].set_title('Input limit; N fixed at 2048')
    fig.suptitle('All prespecified settings; common frequency bins; four-fold means')
    save_figure(fig,output,'sensitivity')

    fig=plt.figure(figsize=(11,6.2),layout='constrained')
    grid=fig.add_gridspec(2,2)
    power_ax=fig.add_subplot(grid[0,0])
    small_ax=fig.add_subplot(grid[1,0],sharex=power_ax)
    pair_ax=fig.add_subplot(grid[:,1])
    normalized=base['budget']/base['target_power'][:,:,None]
    for j,(label,col) in enumerate(zip(('⟨|A|²⟩ / PY','2 Re⟨A*B⟩ / PY','⟨|B|²⟩ / PY'),('#007c91','#9b4ba6','#d85c32'))):
        spread(power_ax if j==0 else small_ax,f,normalized[:,:,j],label,col)
    small_ax.axhline(0,color='#333333',lw=.7);small_ax.set_xlabel('Target frequency (MHz)')
    power_ax.set_ylabel('Normalized linear-part power');power_ax.legend(fontsize=8)
    small_ax.set_ylabel('Normalized cross / quadratic terms');small_ax.legend(fontsize=8)
    power_ax.tick_params(labelbottom=False)
    ti=int(np.argmin(abs(base['frequency_hz']-2e6)));pc=base['pair_count'][ti]
    values=base['pair_cross'][:,ti,:pc]/base['target_power'][:,ti,None]
    vmax=float(np.max(abs(values))) or 1.
    im=pair_ax.imshow(values,aspect='auto',origin='lower',cmap='RdBu_r',vmin=-vmax,vmax=vmax,
                      extent=(-.5,pc-.5,1.5,5.5))
    tick=np.linspace(0,pc-1,5).astype(int)
    freq1=base['pair_bins'][ti,tick,0]*fs/2048/1e6
    pair_ax.set_xticks(tick,[f'{v:.2f}' for v in freq1])
    pair_ax.set_yticks(CAPTURES);pair_ax.set_ylabel('Held-out capture')
    pair_ax.set_xlabel('Pairs labelled by f1 (MHz)\nf2 = target frequency − f1')
    pair_ax.set_title(f"Cross contributions at {base['frequency_hz'][ti]/1e6:.6f} MHz")
    pair_ax.grid(False);fig.colorbar(im,ax=pair_ax,label='2 Re⟨A* Qj Zj⟩ / PY',pad=.02)
    fig.suptitle('A = LX, B = Σ Qj Zj: finite-step model power, not plasma energy transfer')
    save_figure(fig,output,'budget')


def json_safe(value):
    if isinstance(value, dict):
        return {k:json_safe(v) for k,v in value.items()}
    if isinstance(value, list):
        return [json_safe(v) for v in value]
    if isinstance(value, float) and not np.isfinite(value):
        return None
    return value


def analyze(data, output, metadata):
    if output.resolve() == data.resolve():
        raise ValueError('Choose a derived-output directory separate from raw data')
    output.mkdir(parents=True, exist_ok=True)
    fs, groups, audit, files = load_coefficients(data, metadata)
    results, summaries = {}, {}
    for n, band in CONFIGS:
        key=f'n{n}_b{band}'
        results[key]=run_configuration(groups[n],fs,n,band)
        summaries[key]=configuration_summary(results[key],n,band)
    for path,m in zip(files,audit):
        if hashlib.sha256(path.read_bytes()).hexdigest() != m['sha256']:
            raise RuntimeError('An input changed during analysis')
    report=dict(schema_version=1,experiment=metadata,raw_files=audit,fs_hz=fs,
                direction='C1 predictors to C3 target; no physical propagation direction assumed',
                models=['linear','linear_quadratic'],main_configuration='n2048_b5',
                target_band_hz=[.5e6,5e6],fourier='exp(+iwt)/N',window='periodic Hann',
                detrend='segment mean',overlap=0,intercept=False,rcond=RCOND,
                condition_limit=CONDITION_LIMIT,scaling='training-column RMS only; coefficients restored',
                pair_rule='signed nonzero b<=c, b+c=target, |b| and |c| within input band',
                configurations=summaries,
                segments={str(n):{str(g):len(groups[n][g][0]) for g in CAPTURES} for n in groups},
                display='four-capture range is not a confidence interval; all prespecified settings reported',
                software=dict(python=platform.python_version(),numpy=np.__version__,scipy=scipy.__version__,matplotlib=matplotlib.__version__),
                source_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                limitations=['Errors in predictors are not corrected','No Kim correction',
                             'Uncalibrated voltage model; no plasma growth or transfer rate',
                             'Predictive improvement is not causal identification',
                             'Four captures do not establish formal statistical significance'])
    (output/'validation_summary.json').write_text(json.dumps(json_safe(report),indent=2,allow_nan=False)+'\n',encoding='utf-8')
    np.savez_compressed(output/'validation_arrays.npz',**{key+'__'+name:v for key,r in results.items() for name,v in r.items()})
    plot_results(results,fs,output)
    return report


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--metadata',type=Path,default=Path(__file__).with_name('experiment_z5p5_a3p7.json'))
    args=parser.parse_args()
    analyze(args.data,args.output,json.loads(args.metadata.read_text(encoding='utf-8')))
