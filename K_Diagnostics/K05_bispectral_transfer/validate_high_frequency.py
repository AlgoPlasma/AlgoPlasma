"""Optional dense 5--20 MHz prediction check, holding out capture 2.

The current page 08 uses analyze_extended_comparison.py for four holdouts.

Uses the original training-only scaling/SVD, with a fixed quadratic input
limit of 20 MHz. Generates one two-panel spectrum/residual figure only.
"""
from pathlib import Path
import argparse
import hashlib
import json
import platform
import time

import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import scipy

import validate_experiment as v


def target_grid(fs, n, low_mhz=5, high_mhz=20):
    """All native positive-frequency bins in the requested inclusive band."""
    if not 0 < low_mhz < high_mhz < fs/2/1e6:
        raise ValueError('Target band must lie strictly between DC and Nyquist')
    bins = np.arange(int(np.ceil(low_mhz*1e6/(fs/n))),
                     int(np.floor(high_mhz*1e6/(fs/n)))+1)
    if not len(bins):
        raise ValueError('No native bins in this target band')
    return bins


def plot_spectra(result, fs, n, output):
    """Same PSD normalization as the original Figure 2; no interpolation."""
    matplotlib.rcParams.update({'svg.fonttype': 'none', 'svg.hashsalt': 'k05-hf'})
    f = result['frequency_hz']/1e6
    factor = 2*n/(fs*(3/8))
    fig, axes = plt.subplots(2, 1, figsize=(9, 6.3), sharex=True, layout='constrained')
    axes[0].semilogy(f, result['target_power'][0]*factor, color='#333333',
                     label=r'Measured C3: $S_{YY}^+(f)$', lw=1.4)
    labels = (r'Linear: $S_{\widehat Y_0\widehat Y_0}^+(f)$',
              r'Linear + quadratic: $S_{\widehat Y_1\widehat Y_1}^+(f)$')
    for m, (label, color) in enumerate(zip(labels, v.MODEL_COLORS)):
        style = '-' if m == 0 else '--'
        axes[0].semilogy(f, result['prediction_power'][0, :, m]*factor,
                         color=color, label=label, ls=style, lw=1.25)
        axes[1].semilogy(f, result['mse'][0, :, m]*factor, color=color,
                         label=rf'$S_{{\varepsilon_{m}\varepsilon_{m}}}^+(f)$', ls=style, lw=1.25)
    axes[0].set_ylabel(r'Signal / prediction PSD $S^+(f)$ (V²/Hz)')
    axes[1].set_ylabel(r'Residual PSD $S_{\varepsilon_m\varepsilon_m}^+(f)$ (V²/Hz)')
    axes[1].set_xlabel('Target frequency $f$ (MHz)')
    axes[0].set_title('Capture #2 held out; fit captures #3, #4, #5\n'
                      'Dense 5–20 MHz targets; quadratic inputs |f₁|, |f₂| ≤ 20 MHz')
    axes[0].legend(fontsize=9); axes[1].legend(fontsize=9)
    for ax in axes:
        ax.set_xlim(5, 20); ax.grid(True, which='major', alpha=.2)
    v.save_figure(fig, output, 'high-frequency-spectra')


def analyze(data, output, metadata):
    if output.resolve() == data.resolve() or data.resolve() in output.resolve().parents:
        raise ValueError('Use a derived-output folder outside raw inputs')
    if (metadata['capture_ids'] != list(v.CAPTURES) or metadata['channels'] != [1, 3]
            or not metadata['synchronized_pairs'] or not metadata['same_operating_condition']):
        raise ValueError('Confirmed synchronous captures 2, 3, 4, 5 of C1/C3 required')
    output.mkdir(parents=True, exist_ok=True)
    sources = {name: Path(path).read_bytes() for name, path in
               [('high_frequency_calculation_source.py', __file__),
                ('validation_solver_source.py', v.__file__)]}
    n = 2048; input_mhz = 20; groups = {}; audit = []; files = []; fs = None
    started = time.monotonic()
    for g in v.CAPTURES:
        pair = []; info = []
        for ch in (1, 3):
            matches = list(data.rglob(f'SDS814X_HD_Binary_C{ch}_{g}.bin'))
            if len(matches) != 1:
                raise ValueError('Expected one file per capture/channel')
            m, x = v.read_capture(matches[0]); info.append(m)
            if fs is None:
                fs = m['fs_hz']
            if m['fs_hz'] != fs or m['channel'] != ch:
                raise ValueError('Header mismatch')
            bins = target_grid(fs, n)
            maximum = int(input_mhz*1e6/(fs/n))
            c, _ = v.coefficients(x, n); pair.append(c[:, :maximum+1].copy())
            audit.append(m); files.append(matches[0])
        if any(info[0][k] != info[1][k] for k in ('samples', 'fs_hz', 't_start_s')):
            raise ValueError('Pair timing differs')
        groups[g] = tuple(pair)
        print(f'Loaded capture {g}', flush=True)
    result = v.run_configuration(groups, fs, n, input_mhz, target_bins=bins,
                                 heldout_captures=(2,))
    for path, m in zip(files, audit):
        if hashlib.sha256(path.read_bytes()).hexdigest() != m['sha256']:
            raise RuntimeError('Raw input changed during analysis')
    report = dict(schema_version=1, experiment=metadata, raw_files=audit, fs_hz=fs, nperseg=n,
                  segments_per_capture={str(g): len(groups[g][0]) for g in v.CAPTURES},
                  requested_target_limits_hz=[5e6, 20e6], target_spacing_hz=fs/n,
                  actual_target_limits_hz=[float(result['frequency_hz'][0]), float(result['frequency_hz'][-1])],
                  input_max_mhz=input_mhz, actual_input_max_hz=maximum*fs/n,
                  input_pair_rule='All unique signed nonzero pairs b<=c, b+c=target; no modulo-N matching',
                  dc_and_nyquist='Excluded', fourier='exp(+iwt)/N', window='periodic Hann',
                  detrend='segment mean', overlap=0, scaling='training-column RMS only',
                  rcond=v.RCOND, condition_limit=v.CONDITION_LIMIT,
                  summary=v.configuration_summary(result, n, input_mhz), elapsed_s=time.monotonic()-started,
                  source_hashes={name: hashlib.sha256(source).hexdigest() for name, source in sources.items()},
                  software=dict(python=platform.python_version(), numpy=np.__version__,
                                scipy=scipy.__version__, matplotlib=matplotlib.__version__),
                  limitations=['Fixed held-out capture 2 only; no four-fold high-frequency claim',
                               'Quadratic inputs above 20 MHz omitted, including difference-frequency pairs',
                               'No Kim correction or physical growth/transfer inference',
                               'Wider input basis differs from the 0.5–5 MHz main analysis',
                               'No test-based selection of targets or input limit'])
    np.savez_compressed(output/'high_frequency_arrays.npz', **result)
    (output/'high_frequency_summary.json').write_text(
        json.dumps(v.json_safe(report), indent=2, allow_nan=False)+'\n', encoding='utf-8')
    for name, source in sources.items():
        (output/name).write_bytes(source)
    plot_spectra(result, fs, n, output)
    return report


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--data', required=True, type=Path)
    p.add_argument('--output', required=True, type=Path)
    p.add_argument('--metadata', type=Path, default=Path(__file__).with_name('experiment_z5p5_a3p7.json'))
    a = p.parse_args()
    analyze(a.data, a.output, json.loads(a.metadata.read_text(encoding='utf-8')))
