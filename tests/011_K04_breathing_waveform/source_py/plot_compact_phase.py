"""Redraw the two compact-phase knowledge-note figures from saved results."""
import argparse
from pathlib import Path
from _paths import CASE_DIR
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from run_example import DEFAULT_OUTPUT


def make_figures(ns, output_dir):
    """Plot frequency shifts and direct-versus-compact phase error."""
    output_dir = Path(output_dir)
    plt.rcParams.update({'font.size': 11, 'axes.spines.top': False,
                         'axes.spines.right': False, 'savefig.dpi': 170})
    output_dir.mkdir(parents=True, exist_ok=True)
    f, F, band, N = [ns[key] for key in ('f', 'F', 'band', 'N')]
    fig, axs = plt.subplots(3, 1, figsize=(9.6, 8), constrained_layout=True)
    for ax, shift, title, color in zip(
        axs, [0, ns['fL'], ns['f0']],
        ['Original selected band: z', 'After shifting by fL: v', 'After total shift by f0: q'],
        ['#2364aa', '#ce6e25', '#268579']
    ):
        freq = (f[band] - shift)/1000
        ax.axvspan(freq[0], freq[-1], color=color, alpha=.08)
        ax.plot(freq, np.abs(F[band])/N, color=color, lw=1.8)
        peak = (ns['f0'] - shift)/1000
        ax.axvline(peak, ls=':', color=color, alpha=.6)
        ax.annotate(f'Main peak: {peak:g} kHz', (peak, .9),
                    xytext=(10, -6), textcoords='offset points', va='top')
        ax.set(xlim=(freq[0]-3, freq[-1]+3), ylim=(0, 1.07),
               xlabel='Frequency (kHz)', ylabel='|coefficient| / N (V)', title=title)
        ax.set_xticks(sorted(set([freq[0], peak, freq[-1]])))
        ax.grid(alpha=.15)
    fig.savefig(output_dir/'compact_phase_frequency_shift.png')
    plt.close(fig)

    t, tau, phi_direct, delta_native, delta_extended, error = [
        ns[key] for key in ('t', 'tau', 'phi_direct', 'delta_native', 'delta_extended', 'error')]
    delta_direct = phi_direct - 2*np.pi*ns['f0']*t
    fig, axs = plt.subplots(2, 1, figsize=(9.6, 7), constrained_layout=True)
    idx = t <= .004
    axs[0].plot(t[idx]*1000, delta_direct[idx], color='#2364aa', lw=2.5,
                label='Direct phase minus known carrier rotation')
    axs[0].plot(t[idx]*1000, delta_native[idx], color='#ce6e25', ls='--', lw=1.3,
                label='Interpolated slow phase')
    ci = np.flatnonzero(tau <= .004)[::16]
    axs[0].scatter(tau[ci]*1000, delta_extended[ci], s=15, color='#222',
                   label='Coarse-grid phase (every 16th marker shown)', zorder=4)
    axs[0].set(xlabel='Time (ms)', ylabel='Slow phase (rad)', title='Slow phase: two curves overlap at this scale')
    axs[0].legend(fontsize=9, loc='lower left')
    ei = (t >= .00095) & (t <= .00105)
    axs[1].plot(t[ei]*1e6, error[ei]*1e6, color='#7b51aa', lw=1.2)
    axs[1].axhline(0, color='gray', lw=.8)
    axs[1].set(xlabel='Time (microseconds)', ylabel='Phase difference (microrad)',
               title='Zoom: compact phase minus direct phase', xlim=(950,1050))
    for ax in axs: ax.grid(alpha=.18)
    fig.savefig(output_dir/'compact_phase_interpolation.png')
    plt.close(fig)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, default=DEFAULT_OUTPUT/'compact_phase_result.npz')
    parser.add_argument('--output-dir', type=Path, default=DEFAULT_OUTPUT/'compact_figures')
    args = parser.parse_args()
    with np.load(args.input, allow_pickle=False) as data:
        make_figures(data, args.output_dir)
    print(f"Saved 2 figures to {args.output_dir.resolve()}")


if __name__ == '__main__':
    main()
