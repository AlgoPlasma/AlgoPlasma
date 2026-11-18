# K05 contribution history (Git author dates; edit times include timezone).
# 2026-11-16 12:10 +08:00 | Yinjian Zhao | git 14e5fad1530d
# 2026-11-17 13:54 +08:00 | Yinjian Zhao | git 9085032adbf6
# 2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)

"""Cold-ion, moving-beam scenario for page 08; reuse, never refit, saved moments.

Coordinates: axial x, azimuthal y, radial r. eb is along B; es is perpendicular
to B in the x-r plane. The path ks=tan(theta)*ky is a geometric assumption.
The azimuthal group velocity is a PARTIAL derivative at fixed ks and kparallel,
not the derivative along that oblique path. No frequency extrapolation is used.
"""
import argparse
from functools import lru_cache
import hashlib
import json
from pathlib import Path
import platform

import numpy as np
import scipy
from scipy.constants import e, epsilon_0, m_e, atomic_mass
from scipy.optimize import root
from scipy.special import ive, wofz


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


class MovingColdIonEDI:
    def __init__(self, config):
        self.config = dict(config)
        positive = ('temperature_ev', 'density_m3', 'ion_mass_u',
                    'acceleration_length_m', 'parallel_wavelength_m', 'discharge_voltage_v')
        if any(not np.isfinite(config[k]) or config[k] <= 0 for k in positive):
            raise ValueError('Positive finite physical scales required')
        if config['ion_temperature_ev'] != 0:
            raise ValueError('This model implements cold ions only')
        if not 0 < config['ion_energy_fraction'] <= 1:
            raise ValueError('Ion energy fraction must lie in (0,1]')
        self.mi = config['ion_mass_u'] * atomic_mass
        self.br = config['magnetic_radial_gauss'] * 1e-4
        self.bx = config['magnetic_axial_gauss'] * 1e-4
        self.b = np.hypot(self.br, self.bx)
        if self.b <= 0 or not np.isfinite(self.b):
            raise ValueError('Finite nonzero B required')
        self.bhat_x, self.bhat_r = self.bx / self.b, self.br / self.b
        self.ld = np.sqrt(epsilon_0 * config['temperature_ev'] / (config['density_m3'] * e))
        self.cs = np.sqrt(e * config['temperature_ev'] / self.mi)
        self.vte = np.sqrt(e * config['temperature_ev'] / m_e)
        self.wce = e * self.b / m_e
        self.wpi = np.sqrt(config['density_m3'] * e**2 / (epsilon_0 * self.mi))
        self.kpar = 2 * np.pi / config['parallel_wavelength_m']
        self.drop = config['discharge_voltage_v'] * config['ion_energy_fraction']
        self.ui = np.sqrt(2 * e * self.drop / self.mi)
        self.ex = self.drop / config['acceleration_length_m']
        self.vd = self.ex * abs(self.br) / self.b**2
        self.alpha = np.tan(np.deg2rad(config['perpendicular_obliquity_deg']))

    def components(self, ky, ks=None, kp=None):
        ks = self.alpha * ky if ks is None else ks
        kp = self.kpar if kp is None else kp
        kx = self.bhat_x * kp + self.bhat_r * ks
        kr = self.bhat_r * kp - self.bhat_x * ks
        return kx, kr, ks, kp

    @lru_cache(maxsize=4096)
    def weights(self, ky, ks, extra=0):
        bessel = (ky**2 + ks**2) * (self.vte / self.wce)**2
        nmax = int(np.ceil(12 * np.sqrt(bessel + 1) + 20)) + extra
        orders = np.arange(-nmax, nmax + 1)
        return orders, ive(abs(orders), bessel)

    def gordeev(self, omega, ky, ks, kp, extra=0):
        orders, weights = self.weights(float(ky), float(ks), extra)
        scale = np.sqrt(2) * abs(kp) * self.vte
        if scale == 0:
            raise ValueError('Zero parallel wave number needs a separate limiting response')
        doppler = omega - ky * self.vd
        with np.errstate(over='ignore', invalid='ignore'):
            z = 1j * np.sqrt(np.pi) * wofz((doppler - orders * self.wce) / scale)
            return doppler / scale * np.sum(weights * z)

    def dielectric(self, omega, ky, ks=None, kp=None, extra=0):
        kx, _, ks, kp = self.components(ky, ks, kp)
        k2ld2 = (ky**2 + ks**2 + kp**2) * self.ld**2
        with np.errstate(divide='ignore', invalid='ignore', over='ignore'):
            return (1 + k2ld2 + self.gordeev(omega, ky, ks, kp, extra)
                    - k2ld2 * self.wpi**2 / (omega - kx * self.ui)**2)

    def root_at(self, ky, ks=None, kp=None, guess=None, sign=1):
        kx, _, ks, kp = self.components(ky, ks, kp)
        shift = kx * self.ui
        k2ld2 = (ky**2 + ks**2 + kp**2) * self.ld**2
        acoustic = sign * np.sqrt(k2ld2 / (1 + k2ld2)) + .001j
        initial = acoustic if guess is None else (guess - shift) / self.wpi
        guesses = [initial, acoustic, acoustic.conjugate()]
        for start in guesses:
            def residual(z):
                val = self.dielectric(shift + complex(*z) * self.wpi, ky, ks, kp)
                return [val.real, val.imag]
            sol = root(residual, [start.real, start.imag], tol=1e-11)
            w = shift + complex(*sol.x) * self.wpi
            error = abs(self.dielectric(w, ky, ks, kp))
            if np.isfinite(error) and error < self.config['root_tolerance'] and sign * (w.real - shift) > 0:
                return w, error
        raise ValueError(f'No accepted ion-frame sign={sign} root at ky={ky:g}')

    def velocities(self, omega, ky, relative_step=1e-5):
        _, _, ks, kp = self.components(ky)
        dw = self.wpi * relative_step
        dk = max(.01, abs(ky) * relative_step)
        de_w = (self.dielectric(omega + dw, ky, ks, kp)
                - self.dielectric(omega - dw, ky, ks, kp)) / (2 * dw)
        de_y = (self.dielectric(omega, ky + dk, ks, kp)
                - self.dielectric(omega, ky - dk, ks, kp)) / (2 * dk)
        de_s = (self.dielectric(omega, ky, ks + dk, kp)
                - self.dielectric(omega, ky, ks - dk, kp)) / (2 * dk)
        vg_y = float((-de_y / de_w).real)
        vg_s = float((-de_s / de_w).real)
        return vg_y, vg_s, vg_y + self.alpha * vg_s

    def branch(self, ky, sign=1):
        result = {k: [] for k in ('omega', 'residual', 'vg', 'vg_s', 'path_slope',
                                  'doppler', 'harmonic_check', 'derivative_check')}
        last_intrinsic = None
        for k in ky:
            kx, _, ks, kp = self.components(k)
            shift = kx * self.ui
            guess = None if last_intrinsic is None else shift + last_intrinsic
            w, error = self.root_at(k, guess=guess, sign=sign)
            last_intrinsic = w - shift
            vg, vgs, slope = self.velocities(w, k)
            check = self.velocities(w, k, 2e-5)[0]
            for key, value in dict(omega=w, residual=error, vg=vg, vg_s=vgs,
                    path_slope=slope, doppler=shift,
                    harmonic_check=abs(self.dielectric(w, k, extra=16)-self.dielectric(w, k)),
                    derivative_check=abs(vg-check)).items():
                result[key].append(value)
        return dict(ky=np.asarray(ky), **{k: np.asarray(v) for k,v in result.items()})

    def scales(self):
        return dict(temperature_ev=self.config['temperature_ev'], density_m3=self.config['density_m3'],
                    magnetic_gauss=self.b*1e4, debye_m=self.ld, sound_speed_m_per_s=self.cs,
                    fpi_hz=self.wpi/(2*np.pi), fce_hz=self.wce/(2*np.pi),
                    parallel_wave_number_per_m=self.kpar, parallel_debye=self.kpar*self.ld,
                    ion_energy_ev=self.drop, ion_speed_m_per_s=self.ui,
                    axial_field_v_per_m=self.ex, electron_drift_m_per_s=self.vd)


def frequency_map(branch, targets):
    f = branch['omega'].real/(2*np.pi)
    if not np.all(np.isfinite(f)) or not np.all(np.diff(f) > 0):
        raise ValueError('Frequency mapping requires a single strictly monotone selected branch')
    return {key: np.interp(targets, f, value, left=np.nan, right=np.nan)
            for key, value in dict(vg=branch['vg'], ky=branch['ky'],
                                   gamma=branch['omega'].imag, path_slope=branch['path_slope']).items()}


def kim_display_mask(admissible, identified):
    """Keep a target only if ALL folds pass; never average a selected subset."""
    return np.asarray(admissible).all(axis=0) & np.asarray(identified).all(axis=0)


def convert_voltage_units(coefficients, power, transfer, current_per_volt):
    """Same real gain for both channels: L unchanged, Q/a, P*a^2, T*a^2."""
    out = np.array(coefficients, copy=True)
    out[..., 1:] /= current_per_volt
    return out, power * current_per_volt**2, transfer * current_per_volt**2


def analyze(extended, config, output):
    output.mkdir(parents=True, exist_ok=True)
    if any(output.iterdir()):
        raise FileExistsError('Choose an empty output directory; preserve previous analysis')
    cfg = json.loads(config.read_text(encoding="utf-8"))
    parent = extended/'extended_arrays.npz'
    parent_hash = sha(parent)
    a = np.load(parent, allow_pickle=False)
    ky = np.linspace(cfg['ky_min_per_m'], cfg['ky_max_per_m'], cfg['ky_count'])
    scenarios = [('main', cfg)]
    scenarios += [(f'length_{i}',dict(cfg,acceleration_length_m=L))
                  for i,L in enumerate(cfg['sensitivity_lengths_m'])]
    scenarios += [(f'angle_{i}',dict(cfg,perpendicular_obliquity_deg=angle))
                  for i,angle in enumerate(cfg['sensitivity_angles_deg'])]
    arr, summaries = {}, {}
    for name, scenario in scenarios:
        m = MovingColdIonEDI(scenario)
        b = m.branch(ky)
        arr.update({name+'_'+key:value for key,value in b.items()})
        f = b['omega'].real/(2*np.pi)
        summaries[name] = dict(config=scenario, scales=m.scales(),
            frequency_mhz=[float(f.min()/1e6),float(f.max()/1e6)],
            vg_m_per_s=[float(b['vg'].min()),float(b['vg'].max())],
            gamma_per_s=[float(b['omega'].imag.min()),float(b['omega'].imag.max())],
            monotone=bool(np.all(np.diff(f)>0)),
            max_residual=float(b['residual'].max()),
            max_harmonic_change=float(b['harmonic_check'].max()),
            max_derivative_change=float(b['derivative_check'].max()),
            max_intrinsic_step_over_wpi=float(abs(np.diff(b['omega']-b['doppler'])).max()/m.wpi))
        print(name, json.dumps({k:v for k,v in summaries[name].items() if k not in ('config','scales')}), flush=True)
        if name == 'main':
            mapped = frequency_map(b, a['frequency_hz'])
            arr.update({'target_'+key:value for key,value in mapped.items()})
            negative = m.branch(ky, sign=-1)
            arr.update({'opposite_'+key:value for key,value in negative.items()})
    arr['frequency_hz'] = a['frequency_hz']
    arr['kim_display'] = kim_display_mask(a['admissible'], a['identified'])
    inverse_time = arr['target_vg']/cfg['separation_m']
    arr['gamma'] = a['increments'][:,:,:,0]*inverse_time[None,:,None]/2
    arr['transfer_v2_per_s'] = (a['increments'][:,:,:,1]*a['test_powers'][:,:,0,None]
                               *inverse_time[None,:,None]/2)
    # Nominal resistor conversion is kept separate from unknown MHz calibration.
    gain = 1/cfg['resistance_ohm']
    arr['transfer_a2_per_s'] = arr['transfer_v2_per_s']*gain**2
    arr['target_supported'] = np.isfinite(arr['target_vg'])
    arr['target_current_power_a2'] = a['test_powers'][:,:,0]*gain**2
    arr['normalized_transfer_per_s'] = arr['transfer_v2_per_s']/a['test_powers'][:,:,0,None]
    assert sha(parent) == parent_hash
    np.savez_compressed(output/'physical_arrays.npz', **arr)
    report = dict(config=cfg,scenarios=summaries,
        inputs_sha256={str(parent.name):parent_hash, config.name:sha(config)},
        source_sha256={Path(__file__).name:sha(__file__)},
        versions=dict(python=platform.python_version(),numpy=np.__version__,scipy=scipy.__version__),
        targets=len(a['frequency_hz']),supported_targets=int(arr['target_supported'].sum()),
        kim_all_fold_pass=int(arr['kim_display'].sum()),
        normalization='Same nominal 1/R for both probes; no DC, RMS, or peak normalization',
        group_velocity='partial omega_r / partial ky at fixed ks,kparallel; not the oblique path slope',
        limitations='Local Maxwellian proxy, cold ions, prescribed obliquity/signs, acceleration length estimate; no experimental root identification, response calibration or exhaustive kinetic root enumeration.')
    (output/'physical_summary.json').write_text(json.dumps(report,indent=2)+'\n', encoding="utf-8")


if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--extended',type=Path,required=True)
    p.add_argument('--config',type=Path,default=Path(__file__).with_name('physical_scenario_config.json'))
    p.add_argument('--output',type=Path,required=True)
    args=p.parse_args();analyze(args.extended,args.config,args.output)
