"""Explain saved checks with PNGs; do not rerun diagnostic algorithms.

Waveform guides illustrate the recorded input models.
FFT amplitudes, phase estimates, spectra and recovered peaks come from the report.
Figures target a documentation page (11--12 inches wide, 180 dpi), not print.
"""
import json
from pathlib import Path

import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

BLUE, ORANGE, GREY, TEAL = '#286B91', '#C77732', '#626C75', '#388578'


def plot_results(outdir):
    outdir = Path(outdir)
    target = outdir / 'figures'
    target.mkdir(exist_ok=True)
    records = {r['id']: r for r in json.loads((outdir / 'summary.json').read_text())['tests']}
    plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 11,
                         'axes.titlesize': 12, 'axes.titlepad': 14,
                         'axes.spines.top': False, 'axes.spines.right': False,
                         'legend.frameon': False, 'axes.linewidth': .8})

    def data(name):
        with np.load(outdir / 'details' / ('test_' + name + '.npz')) as stored:
            return dict(stored)

    def record(name):
        return records['test_' + name]

    def save(fig, name):
        fig.savefig(target / (name + '.png'), dpi=180, bbox_inches='tight')
        plt.close(fig)

    # The visual chain is record -> periodic repetition -> measured FFT bins.
    d = data('leakage_can_bias_real_signal_phase')
    fig, axes = plt.subplots(2, 3, figsize=(12, 6.8), layout='constrained')
    for row, cycles, colour in [(0, 2., BLUE), (1, 1.25, ORANGE)]:
        suffix = str(cycles)
        ts = d['time_fraction']
        sample = d['signal_' + suffix]
        u = np.linspace(0, 1, 401)
        guide = np.cos(2 * np.pi * cycles * u)
        ax = axes[row, 0]
        ax.axvspan(0, 1, color=colour, alpha=.07)
        ax.plot(u, guide, color=colour, linewidth=1.5)
        ax.plot(ts, sample, '.', color=colour, markersize=3)
        ax.text(.03, .94, f'{cycles:g} cycles in T', transform=ax.transAxes,
                va='top', color=colour)
        ax.set(xlim=(0, 1), ylim=(-1.45, 1.7), xlabel='Time / T', ylabel='Signal',
               xticks=[0, .25, .5, .75, 1],
               title=f'({"a" if row == 0 else "d"}) Keep one record')

        ax = axes[row, 1]
        # Smooth analytic guide to the recorded cosine, including its left limit at T.
        # The dashed curve is the original wave continuing, not a second observation.
        ax.plot(u, guide, color=colour, linewidth=1.5)
        ax.plot(1 + u, guide, color=colour, linewidth=1.5)
        ax.plot(1 + u, np.cos(2 * np.pi * cycles * (1 + u)), '--', color=GREY,
                linewidth=1.2, label='Original wave continues')
        ax.axvspan(1, 2, color=colour, alpha=.07)
        ax.axvline(1, color=GREY, linestyle=':', linewidth=1)
        if row:
            ax.plot([1, 1], [guide[-1], guide[0]], color=colour, linewidth=2.5)
            ax.annotate('Restart at +1', xy=(1, .6), xytext=(1.12, 1.35),
                        fontsize=10, arrowprops={'arrowstyle': '->', 'color': colour})
            ax.legend(fontsize=8, loc='lower right')
        else:
            ax.text(.5, .91, 'Smooth join', transform=ax.transAxes,
                    ha='center', color=colour)
        ax.set(xlim=(0, 2), ylim=(-1.45, 1.7), xlabel='Time / T', xticks=[0, 1, 2],
               title=f'({"b" if row == 0 else "e"}) Repeat the same record')

        ax = axes[row, 2]
        spectrum = d['amplitude_' + suffix]
        bins = np.arange(min(9, len(spectrum)))
        ax.vlines(bins, 0, spectrum[bins], color=colour, linewidth=1.5)
        ax.plot(bins, spectrum[bins], 'o', color=colour, markersize=4)
        ax.axvline(cycles, color=GREY, linestyle='--', linewidth=1)
        selected = round(cycles)
        ax.plot(selected, spectrum[selected], 'o', markersize=10,
                markerfacecolor='none', markeredgecolor='black')
        i = int(np.flatnonzero(d['cycles'] == cycles)[0])
        error = float(d['error_deg'][i])
        error_text = '< 1e-12 deg' if error < 1e-12 else f'{error:.2f} deg'
        ax.text(.98, .94, f'True cycles: {cycles:g}\nRead phase at bin {selected}\nPhase error: {error_text}',
                transform=ax.transAxes, ha='right', va='top', fontsize=10)
        ax.set(xlim=(-.4, 8.4), ylim=(0, 42), xlabel='FFT bin (cycles per record)',
               ylabel='FFT magnitude', xticks=[0, 1, 2, 4, 6, 8],
               title=f'({"c" if row == 0 else "f"}) Inspect the FFT bins')
    save(fig, 'spectral_leakage')

    # Each independent case compares methods using the same saved observations.
    ordinary = data('liu_returns_mode_not_arithmetic_or_circular_mean')
    cut = data('branch_cut')
    ordinary_checks = record('liu_returns_mode_not_arithmetic_or_circular_mean')['checks']
    cut_checks = record('branch_cut')['checks']
    samples = np.rad2deg(ordinary['phase_rad'])
    arithmetic_mean = float(samples.mean())
    mode = float(np.rad2deg(ordinary['mean_rad']))
    fig, axes = plt.subplots(1, 2, figsize=(11.5, 5.6))
    fig.subplots_adjust(left=.07, right=.97, top=.70, bottom=.29, wspace=.30)
    fig.suptitle('Case A | Same samples, different definitions', fontsize=16, fontweight='bold', y=.98)
    fig.text(.5, .89, 'Shared input: [' + ', '.join(f'{v:.2f}°' for v in samples) + '] (rounded)',
             ha='center', fontsize=13)
    ax = axes[0]
    ax.set_title('(a) Arithmetic mean', fontsize=14, loc='left', pad=18)
    ax.axhline(.4, color='#C7D1D7', lw=1)
    # Vertical separation only exposes the three tightly spaced input points.
    dot_y = np.array([.33, .40, .47, .40])
    ax.scatter(samples, dot_y, s=45, color=BLUE, zorder=3)
    ax.annotate('3 samples near 0.7°', xy=(samples[1], .47), xytext=(.2, .76),
                fontsize=12, color=BLUE, arrowprops={'arrowstyle': '-', 'color': BLUE})
    ax.text(samples[3], .54, f'{samples[3]:.2f}°', fontsize=12, ha='center', color=BLUE)
    ax.axvline(arithmetic_mean, color=ORANGE, linestyle='--', lw=2)
    ax.annotate(f'Mean = {arithmetic_mean:.2f}°', xy=(arithmetic_mean, .40), xytext=(7, .15),
                fontsize=13, color=ORANGE, arrowprops={'arrowstyle': '->', 'color': ORANGE})
    ax.set(xlim=(-.5, 18.5), ylim=(0, 1), xticks=[0, 6, 12, 18], yticks=[], xlabel='Phase (°)')
    ax.spines['left'].set_visible(False)
    ax.tick_params(labelsize=12)
    fig.text(ax.get_position().x0 + ax.get_position().width/2, .14,
             f'Sum all four angles, then divide by 4\nMean: {arithmetic_mean:.5f}°',
             ha='center', va='top', fontsize=12)

    ax = axes[1]
    edges = np.array([0., 6., 12., 18.])
    counts, _ = np.histogram(samples, bins=edges)
    centers = (edges[:-1] + edges[1:]) / 2
    ax.bar(centers, counts, width=5.5, color=[BLUE, '#DCE3E7', '#B7C3CA'])
    for center, count in zip(centers, counts):
        ax.text(center, count+.12, f'{count}', ha='center', fontsize=14)
    ax.axvline(mode, color=ORANGE, linestyle='--', lw=2)
    ax.annotate(f'Bin centre = {mode:g}°', xy=(mode, 2), xytext=(7, 2.6),
                fontsize=13, color=ORANGE, arrowprops={'arrowstyle': '->', 'color': ORANGE})
    ax.set_title('(b) Histogram-mode bin centre', fontsize=14, loc='left', pad=18)
    ax.set(xlim=(-.5, 18.5), ylim=(0, 4), xticks=centers,
           xticklabels=['0–6°', '6–12°', '12–18°'], yticks=[0, 1, 2, 3],
           xlabel='Phase bins (6° wide)', ylabel='Number of samples')
    ax.tick_params(labelsize=12)
    reference = np.rad2deg(ordinary_checks[0]['expected'])
    fig.text(ax.get_position().x0 + ax.get_position().width/2, .14,
             f'Select the most populated bin\nProgram: {mode:g}°  |  Reference: {reference:g}°',
             ha='center', va='top', fontsize=12)
    fig.text(.5, .035, 'This checks the implemented definition. No known true phase is supplied, so accuracy is not ranked.',
             fontsize=11, color=GREY, ha='center')
    save(fig, 'phase_statistics')

    # A separate controlled comparison: only the representation of -179° changes.
    phases = np.rad2deg(cut['phase_rad'])
    unwrapped = np.where(phases < 0, phases+360, phases)
    naive_variance = float(np.var(phases, ddof=1)) + 1e-12*(180 / np.pi)**2
    degree_scale = (180 / np.pi)**2
    measured_variance = cut_checks[1]['actual'] * degree_scale
    reference_variance = cut_checks[1]['expected'] * degree_scale
    fig, axes = plt.subplots(1, 2, figsize=(11.5, 6.1))
    fig.subplots_adjust(left=.10, right=.96, top=.68, bottom=.29, wspace=.31)
    fig.suptitle('Case B | Same observations, change only angle handling',
                 fontsize=16, fontweight='bold', y=.98)
    fig.text(.5, .895, 'Shared input: [' + ', '.join(f'{v:g}°' for v in phases) + ']',
             ha='center', fontsize=13)
    fig.text(.5, .835, '−179° and 181° are the same direction; no observation is added or replaced.',
             ha='center', fontsize=12, color=GREY)
    for i, (ax, displayed, title) in enumerate(zip(axes, [phases, unwrapped],
            ['(a) Treat as ordinary numbers', '(b) Respect the 360° period'])):
        rows = np.arange(4, 0, -1)
        ax.scatter(displayed, rows, color=[BLUE, ORANGE, BLUE, BLUE], s=55, zorder=3)
        for row in rows:
            ax.axhline(row, color='#E5EAEE', linewidth=.8, zorder=0)
        for j, (value, row) in enumerate(zip(displayed, rows)):
            label = f'{value:g}°' if not (i == 1 and j == 1) else '181° ≡ −179°'
            ax.annotate(label, xy=(value, row), xytext=(-8 if value > 0 else 8, 9),
                        textcoords='offset points', ha='right' if value > 0 else 'left',
                        fontsize=12, color=ORANGE if j == 1 else BLUE)
        ax.set_title(title, loc='left', fontsize=14, pad=18)
        ax.set(ylim=(.6, 4.7), yticks=rows, yticklabels=[f'Sample {j}' for j in range(1, 5)],
               xlim=(-210, 210), xticks=[-180, -90, 0, 90, 180],
               xlabel='Phase (°)' if i == 0 else 'Equivalent phase (°)')
        if i == 0:
            result = f'Direct sample variance: {naive_variance:.5f} °²'
        else:
            result = f'Program variance: {measured_variance:.5f} °²\nReference: {reference_variance:.5f} °²'
        ax.tick_params(labelsize=11)
        fig.text(ax.get_position().x0 + ax.get_position().width/2, .14, result,
                 ha='center', va='top', fontsize=12,
                 color=GREY if i == 0 else BLUE, fontweight='bold')
    fig.text(.5, .04, 'Same observations and axis scales in both panels; both variances use the n − 1 denominator.',
             ha='center', fontsize=11, color=GREY)
    save(fig, 'phase_branch_cut')

    # Make the two different peak positions dominant. Each axis states its own scale.
    d = data('beall_auto_power_changes_peak')
    checks = record('beall_auto_power_changes_peak')['checks']
    fig, axes = plt.subplots(1, 2, figsize=(11.5, 5.7))
    fig.subplots_adjust(left=.085, right=.97, top=.73, bottom=.26, wspace=.32)
    fig.suptitle('This Beall test detects use of the wrong weight',
                 fontsize=16, fontweight='bold', y=.98)
    fig.text(.5, .90, 'Same two segments · same phase bins · divide each weight sum by 2',
             ha='center', fontsize=12, color=GREY)
    for ax, key, colour, label, ref_index, peak_index, weights in [
            (axes[0], 'auto_power_spectrum', BLUE, '(a) Required: mean auto-power', 3, 1,
             checks[0]['actual']),
            (axes[1], 'cross_magnitude_spectrum', ORANGE, '(b) Misuse control: cross magnitude', 4, 2, [1, 4])]:
        values = np.asarray(d[key])
        x = np.arange(len(values))
        winner = int(np.argmax(values))
        ax.bar(x, values, width=.5, color=[colour if i == winner else '#C7D1D7' for i in x])
        reference = np.asarray(checks[ref_index]['expected'])
        for xx, measured, expected in zip(x, values, reference):
            ax.plot([xx-.27, xx+.27], [expected, expected], color='#26343D', lw=1.5)
            ax.text(xx, measured + values.max()*.05, f'{measured:g}', ha='center', fontsize=14)
        actual_peak = checks[peak_index]['actual']
        expected_peak = checks[peak_index]['expected']
        ax.set_xticks(x, [f'{v:+g}' for v in d['k_rad_m']])
        ax.set(xlim=(-.65, 1.65), ylim=(0, values.max()*1.4),
               xlabel='Wavenumber bin centre (rad/m)', ylabel='Spectrum (own vertical scale)')
        ax.tick_params(labelsize=12)
        ax.set_title(label, fontsize=13, loc='left', pad=30)
        ax.text(0, 1.035, f'Weights [{weights[0]:g}, {weights[1]:g}] ÷ 2 segments',
                transform=ax.transAxes, fontsize=12, color=GREY)
        ax.annotate('PEAK', xy=(winner, values[winner]*.98),
                    xytext=(winner + (.65 if winner == 0 else -.65), values.max()*1.19),
                    ha='center', fontsize=13, fontweight='bold', color=colour,
                    arrowprops={'arrowstyle': '->', 'color': colour, 'lw': 1.6})
        ax.text(.5, -.32, f'Returned peak: {actual_peak:+g} rad/m\nReference: {expected_peak:+g} rad/m',
                transform=ax.transAxes, ha='center', fontsize=13, color=colour, fontweight='bold')
    fig.text(.5, .035, 'Bars: saved spectrum   |   Black caps: hand-calculated reference   |   Vertical scales differ',
             ha='center', fontsize=11, color=GREY)
    save(fig, 'beall_weights')

    # Retain the implementation regression plot in the report artifacts only.
    d = data('alias_requires_grid_resolution_not_local_refinement')
    fig, axes = plt.subplots(1, 2, figsize=(9, 3.5), layout='constrained')
    for ax, n, estimate, colour in zip(axes, [401, 4001], d['estimates_rad_m'], [ORANGE, BLUE]):
        ax.plot(d['kx_' + str(n)], -d['loglike_' + str(n)], color=colour, linewidth=.8)
        ax.axvline(d['truth_rad_m'][0], color=GREY, linestyle='--', label='True kx = 123.4')
        ax.axvline(estimate[0], color=colour, linestyle=':', label=f'Grid estimate = {estimate[0]:g}')
        ax.set_yscale('log')
        ax.set_ylim(1, 2e7)
        ax.set_xticks([-2000, -1000, 0, 1000, 2000])
        ax.set(xlabel='kx (rad/m)', ylabel='Negative log likelihood', title=f'{n} x {n} search; ky = 0 slice')
        ax.legend(fontsize=8, loc='lower left')
    save(fig, 'grid_resolution')
