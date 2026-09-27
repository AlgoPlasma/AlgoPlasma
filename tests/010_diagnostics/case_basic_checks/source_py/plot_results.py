"""Render only saved measurements from the basic-check run (PNG, no recomputation)."""
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

BLUE, ORANGE, GREY = '#286B91', '#C77732', '#626C75'
def plot_results(outdir):
    outdir = Path(outdir)
    target = outdir/'figures'
    target.mkdir(exist_ok=True)
    plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 10,
                         'axes.spines.top': False, 'axes.spines.right': False,
                         'legend.frameon': False, 'axes.linewidth': .8})
    def data(name):
        with np.load(outdir/'details'/('test_'+name+'.npz')) as stored:
            return dict(stored)
    def save(fig, name):
        fig.savefig(target/(name+'.png'), dpi=180, bbox_inches='tight')
        plt.close(fig)

    fig, axes = plt.subplots(1, 2, figsize=(9, 3.4), layout='constrained')
    for ax, name, title in zip(axes, ['liu_returns_mode_not_arithmetic_or_circular_mean', 'branch_cut'],
                               ['(a) Histogram-mode estimate', '(b) Samples around the phase cut']):
        d = data(name)
        samples, mode = np.rad2deg(d['phase_rad']), float(np.rad2deg(d['mean_rad']))
        ax.hist(samples, bins=np.linspace(-180, 180, 61), color=BLUE, edgecolor='white')
        ax.axvline(mode, color=ORANGE, linestyle='--', label=f'Mode bin centre: {mode:.1f} deg')
        ax.set(xlabel='Wrapped phase (deg)', ylabel='Sample count', title=title)
        ax.set_yticks(range(4))
        ax.set_ylim(0, 3.7)
        ax.legend(fontsize=8, loc='upper center')
        if name.startswith('liu'):
            ax.set_xlim(-6, 24)
        else:
            ax.set_xticks([-180, -90, 0, 90, 180])
    save(fig, 'phase_statistics')

    d = data('beall_auto_power_changes_peak')
    fig, ax = plt.subplots(figsize=(6.5, 3.5), layout='constrained')
    x = np.arange(len(d['k_rad_m']))
    ax.bar(x-.18, d['auto_power_spectrum'], .36, label='Mean pair auto-power', color=BLUE)
    ax.bar(x+.18, d['cross_magnitude_spectrum'], .36, label='Cross-spectrum magnitude', color=ORANGE)
    ax.set_xticks(x, [f'{v:g}' for v in d['k_rad_m']])
    ax.set(xlabel='Wavenumber bin centre (rad/m)', ylabel='Accumulated weight / segment',
           title='Unequal probe amplitudes change the weighted peak')
    ax.legend()
    save(fig, 'beall_weights')

    d = data('alias_requires_grid_resolution_not_local_refinement')
    fig, axes = plt.subplots(1, 2, figsize=(9, 3.5), layout='constrained')
    for ax, n, estimate, colour in zip(axes, [401, 4001], d['estimates_rad_m'], [ORANGE, BLUE]):
        ax.plot(d['kx_'+str(n)], -d['loglike_'+str(n)], color=colour, linewidth=.8)
        ax.axvline(d['truth_rad_m'][0], color=GREY, linestyle='--', label='True kx = 123.4')
        ax.axvline(estimate[0], color=colour, linestyle=':', label=f'Grid estimate = {estimate[0]:g}')
        ax.set_yscale('log')
        ax.set_ylim(1, 2e7)
        ax.set_xticks([-2000, -1000, 0, 1000, 2000])
        ax.set(xlabel='kx (rad/m)', ylabel='Negative log likelihood',
               title=f'{n} x {n} search; ky = 0 slice')
        ax.legend(fontsize=8, loc='lower left')
    save(fig, 'grid_resolution')

    d = data('leakage_can_bias_real_signal_phase')
    fig, axes = plt.subplots(1, 2, figsize=(9, 3.5), layout='constrained')
    for cycles, colour in zip(d['cycles'], [ORANGE, BLUE]):
        spectrum = d['amplitude_'+str(float(cycles))]
        axes[0].plot(np.arange(len(spectrum)), spectrum, 'o-', markersize=3,
                     color=colour, label=f'{cycles:g} cycles / record')
    axes[0].set(xlim=(0, 12), xlabel='FFT bin', ylabel='FFT magnitude', title='(a) Rectangular-window spectra')
    axes[0].legend(fontsize=8)
    axes[1].bar(['1.25 cycles', '2 cycles'], d['error_deg'], color=[ORANGE, BLUE])
    for i, value in enumerate(d['error_deg']):
        axes[1].text(i, value+.15, f'{value:.3g}', ha='center')
    axes[1].set(ylabel='Absolute phase error (deg)', title='(b) Error at the nearest bin',
                ylim=(0, max(d['error_deg'])*1.25))
    save(fig, 'spectral_leakage')
