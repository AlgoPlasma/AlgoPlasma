"""Optional mean swept-probe I–V analysis; raw inputs are read-only.

The original median workflow remains in analyze_probe_response.py for comparison.
This estimates slopes of averaged characteristics, not an independently calibrated
electron distribution. All preset sensitivity cases are retained.
"""
from pathlib import Path
import argparse
import hashlib
import json
import numpy as np
from scipy.signal import savgol_filter
from yokogawa_wdf import read_wdf
from analyze_probe_response import analyze_record as legacy_record, operating_scenarios


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def reduce_bins(supply, shunt, width=1., resistance=1000., bias=100.,
                statistic='mean', minimum=8, supply_limits=None):
    """Group by imposed supply voltage, then reduce both measured channels.

    Columns: probe voltage V, net current A, supply voltage V, shunt voltage V,
    sample count. In the mean case KVL holds exactly for the averaged channels.
    """
    supply, shunt = np.asarray(supply), np.asarray(shunt)
    if supply.shape != shunt.shape or not np.isfinite(supply).all() or not np.isfinite(shunt).all():
        raise ValueError('Finite, matching measured-channel arrays required')
    if not len(supply) or width <= 0 or resistance <= 0 or minimum < 1:
        raise ValueError('Nonempty input and positive bin width/resistance/count required')
    if statistic not in ('mean', 'median'):
        raise ValueError('Statistic must be mean or median')
    reducer = np.mean if statistic == 'mean' else np.median
    ids = np.floor(supply/width).astype(int)
    rows = []
    first, last = (int(ids.min()), int(ids.max())+1) if supply_limits is None else tuple(int(x/width) for x in supply_limits)
    for k in range(first, last):
        mask = ids == k
        if mask.sum() < minimum:
            continue
        s, r = float(reducer(supply[mask])), float(reducer(shunt[mask]))
        rows.append([s-bias+r, -r/resistance, s, r, int(mask.sum())])
    result = np.asarray(rows, dtype=float).reshape(-1, 5)
    if len(result) < 2:
        raise ValueError('Too few populated bins')
    return result


def floating_potential(voltage, current):
    candidates = np.flatnonzero((current[:-1] <= 0) & (current[1:] > 0) & (voltage[:-1] > -40))
    if len(candidates) != 1:
        raise ValueError('Expected one floating crossing above -40 V')
    j = candidates[0]
    return float(np.interp(0, current[j:j+2], voltage[j:j+2]))


def fit_slope(voltage, current, ion_window, electron_window, ion_model='linear', min_bins=8):
    """Fit ln(Ie / 1 mA), with a signed ion background; current input is A."""
    selected = (voltage >= ion_window[0]) & (voltage <= ion_window[1])
    if selected.sum() < 5:
        raise ValueError('Insufficient ion-background bins')
    if ion_model == 'linear':
        co = np.polyfit(voltage[selected], current[selected], 1)
    elif ion_model == 'constant':
        co = np.array([0., current[selected].mean()])
    else:
        raise ValueError('Unknown ion-background model')
    electron = current-np.polyval(co, voltage)
    mask = (voltage >= electron_window[0]) & (voltage <= electron_window[1])
    if mask.sum() < min_bins or np.any(electron[mask] <= 0):
        raise ValueError('Fit requires enough strictly positive electron-current bins')
    x, y = voltage[mask], np.log(electron[mask]/1e-3)
    m, c = np.polyfit(x, y, 1)
    if m <= 0:
        raise ValueError('Positive retarding-region slope required')
    residual = y-(m*x+c)
    return dict(te_ev=float(1/m), slope_per_v=float(m), intercept=float(c),
                r_squared=float(1-np.sum(residual**2)/np.sum((y-y.mean())**2)),
                ion_coeff_a=co.tolist(), ion_model=ion_model,
                ion_window_v=list(ion_window), electron_window_v=list(electron_window),
                actual_window_v=[float(x.min()), float(x.max())], bins=int(mask.sum()))


def potential_candidate(v, current, vf, spans):
    """Smoothed derivative feature, NOT an independently measured plasma potential."""
    grid = np.arange(-80., 60., .5)
    if v.min() > -80 or v.max() < 60:
        raise ValueError('Sweep does not cover the candidate-search grid')
    y = np.interp(grid, v, current)
    peaks, derivatives = [], []
    for span in spans:
        w = round(span/.5); w += 1-w % 2
        derivative = savgol_filter(y, w, 3, deriv=1, delta=.5)
        search = (grid > vf+5) & (grid < 45)
        peak = float(grid[np.flatnonzero(search)[np.argmax(derivative[search])]])
        peaks.append(dict(span_v=span, potential_v=peak)); derivatives.append(derivative)
    values = [r['potential_v'] for r in peaks if r['span_v'] >= 7]
    return float(np.median(values)), peaks, grid, np.asarray(derivatives)


def analyze_one(path, config):
    data = read_wdf(path)
    supply = data['traces'][config['supply_channel']]
    shunt = data['traces'][config['shunt_channel']]
    if any(x['unit'] != 'V' for x in (supply, shunt)):
        raise ValueError('Both channels must be measured in volts')
    if (supply['dt_s'], supply['t0_s'], len(supply['values'])) != (shunt['dt_s'], shunt['t0_s'], len(shunt['values'])):
        raise ValueError('Channels do not share a time grid')
    s, u = supply['values'], shunt['values']
    low, high = config['supply_limits_v']
    starts, stops = np.flatnonzero(s > low), np.flatnonzero(s > high)
    if not len(starts) or not len(stops) or starts[0] >= stops[0]:
        raise ValueError('The complete first upward sweep is missing')
    start, stop = int(starts[0]), int(stops[0])
    dt = supply['dt_s']; resistance = config['resistance_ohm']
    bins = reduce_bins(s[start:stop], u[start:stop], config['bin_width_v'], resistance,
                       config['bias_supply_v'], minimum=config['minimum_samples'], supply_limits=[low,high])
    v, current = bins[:, 0], bins[:, 1]
    if np.any(np.diff(v) <= 0):
        raise ValueError('Main averaged probe-voltage curve is non-monotonic; inspect the sweep')
    vf = floating_potential(v, current)
    vp, peaks, grid, derivatives = potential_candidate(v, current, vf, config['smoothing_spans_v'])
    window = [vf+config['lower_margin_v'], vp-config['upper_margin_v']]
    main = fit_slope(v, current, config['ion_window_v'], window)
    tests = []
    for lower in config['lower_margin_tests_v']:
        for upper in config['upper_margin_tests_v']:
            for ion in config['ion_window_tests_v']:
                for model in ('linear', 'constant'):
                    settings = dict(lower_margin_v=lower, upper_margin_v=upper,
                                    ion_window_v=ion, ion_model=model)
                    try:
                        tests.append(dict(**fit_slope(v, current, ion, [vf+lower, vp-upper], model),
                                          lower_margin_v=lower, upper_margin_v=upper, valid=True))
                    except ValueError as exc:
                        tests.append(dict(**settings, valid=False, reason=str(exc)))
    # Repeat widths at the SAME physical fit bounds, without choosing the best one.
    width_tests = []
    for width in (.5, 1., 2.):
        b = reduce_bins(s[start:stop], u[start:stop], width, resistance, config['bias_supply_v'], supply_limits=[low,high])
        f = fit_slope(b[:, 0], b[:, 1], config['ion_window_v'], window)
        width_tests.append(dict(width_v=width, te_ev=f['te_ev']))
    median = reduce_bins(s[start:stop], u[start:stop], config['bin_width_v'], resistance,
                         config['bias_supply_v'], statistic='median', supply_limits=[low,high])
    # All 2 ms blocks are display summaries; no exclusion of rare samples.
    nblock = round(.002/dt); usable = len(s)//nblock*nblock
    overview = np.column_stack(((np.arange(usable//nblock)*nblock+(nblock-1)/2)*dt,
        s[:usable].reshape(-1,nblock).mean(axis=1), u[:usable].reshape(-1,nblock).mean(axis=1),
        np.percentile(u[:usable].reshape(-1,nblock),[16,84],axis=1).T))
    selected = (s[start:stop] >= 75) & (s[start:stop] < 76)
    sample_s, sample_u = s[start:stop][selected], u[start:stop][selected]
    hist_example = dict(count=len(sample_s), supply_mean_v=float(sample_s.mean()),
        shunt_mean_v=float(sample_u.mean()), mean_current_a=float(-sample_u.mean()/resistance),
        median_current_a=float(-np.median(sample_u)/resistance),
        probe_mean_v=float(sample_s.mean()-config['bias_supply_v']+sample_u.mean()))
    time = np.arange(len(s))*dt
    hold_end = np.flatnonzero(s > high)[-1]*dt
    early = (time > stop*dt+.1) & (time < stop*dt+.3)
    late = (time > hold_end-.2) & (time < hold_end-.05)
    early_i, late_i = [-float(u[m].mean())/resistance for m in (early, late)]
    report = dict(file=path.name, sha256=data['sha256'], samples=len(s), dt_s=dt,
        ramp_indices=[start,stop], ramp_time_s=[start*dt,stop*dt], floating_v=vf,
        plasma_candidate_v=vp, candidate_tests=peaks, main_fit=main,
        sensitivity=tests, width_tests=width_tests, bin_example=hist_example,
        hold_relative_change=(late_i-early_i)/abs(early_i),
        sensitivity_range_ev=[min(f['te_ev'] for f in tests if f['valid']),max(f['te_ev'] for f in tests if f['valid'])])
    arrays = dict(bins=bins, median_bins=median, overview=overview,
                  derivative_grid=grid, derivatives=derivatives, example_supply=sample_s,
                  example_current=-sample_u/resistance)
    return report, arrays


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--config', type=Path, default=Path(__file__).with_name('probe_sweep_config.json'))
    args = parser.parse_args(); args.output.mkdir(parents=True, exist_ok=True)
    config = json.loads(args.config.read_text(encoding="utf-8"))
    if config['example_record'] != 15:
        raise ValueError('This page uses the preselected record 0015 as its worked example')
    reports, arrays = [], {}
    for ident in config['records']:
        path = args.data/f'1014{ident:04d}.WDF'
        report, a = analyze_one(path, config)
        assert digest(path) == report['sha256']
        reports.append(report); arrays[ident] = a
    primary = next(r for r in reports if r['file'] == '10140015.WDF')
    a = arrays[15]; v, i = a['bins'][:,:2].T
    legacy_config = json.loads(Path(__file__).with_name('probe_response_config.json').read_text(encoding="utf-8"))
    old, old_a = legacy_record(args.data/'10140015.WDF', legacy_config)
    old_v, old_i = old_a['curve'][:,:2].T
    old_window = [old['floating_v']-5,old['floating_v']+10]
    current_window = primary['main_fit']['electron_window_v']
    comparison = [dict(name='original_median_workflow',te_ev=old['fits'][1]['te_ev']),
        dict(name='mean_curve_old_rules', **fit_slope(v,i,[-90,-70],[primary['floating_v']-5,primary['floating_v']+10])),
        dict(name='mean_curve_current_rules',**primary['main_fit']),
        dict(name='old_curve_current_intervals',**fit_slope(old_v,old_i,[-80,-50],current_window)),
        dict(name='supply_medians_current_intervals',**fit_slope(a['median_bins'][:,0],a['median_bins'][:,1],[-80,-50],current_window))]
    a['legacy_curve'] = old_a['curve']; a['legacy_ion_coeff'] = np.asarray(old['ion_coeff_a'])
    a['legacy_window'] = np.asarray(old_window)
    load_config = dict(fast_battery_v=40.5,resistance_ohm=config['resistance_ohm'],
                       cathode_to_chamber_scenarios_v=config['cathode_scenarios_v'])
    scenarios = operating_scenarios(a['bins'][:,:2],primary['main_fit']['ion_coeff_a'],load_config)
    summary = dict(config=config, config_sha256=digest(args.config), records=reports,
        comparison=comparison, operating_scenarios=scenarios,
        interpretation='Effective slope temperatures of mean swept characteristics; no claim of a uniquely calibrated bulk temperature.',
        source_sha256={name:digest(Path(__file__).with_name(name)) for name in
            ('analyze_probe_sweep.py','plot_probe_sweep.py','yokogawa_wdf.py','analyze_probe_response.py','probe_response_config.json')})
    np.savez_compressed(args.output/'probe_sweep_arrays.npz',**{
        f'r{key}_{name}':val for key,a in arrays.items() for name,val in a.items()})
    (args.output/'probe_sweep_summary.json').write_text(json.dumps(summary,indent=2,allow_nan=False)+'\n', encoding="utf-8")
    from plot_probe_sweep import make_plots
    make_plots(summary,arrays,args.output)
    for r in reports:
        print(r['file'], 'Te',round(r['main_fit']['te_ev'],6),'Vf',round(r['floating_v'],4),
              'range',r['sensitivity_range_ev'])


if __name__ == '__main__':
    main()
