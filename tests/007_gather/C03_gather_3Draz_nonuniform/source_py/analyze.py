#!/usr/bin/env python3
"""Independent analytic references, completeness checks, and expected failures."""
from __future__ import annotations

import csv
import json
import math
import subprocess
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output'
SAMPLES = 96
EXACT = {
    'constant': 4, 'uniform': 4, 'nonuniform': 4, 'wrapper': 4,
    'cached': 4, 'periodic': 4, 'periodic_cached': 4, 'local_box': 4,
    'single_cell_axis': 1,
}
LEVELS = (8, 16, 32)
NEGATIVE = {
    'bad_particle': 'C03: invalid particle index',
    'negative_radius': 'C03: radius must be nonnegative',
    'outside': 'C03: particle outside owned grid; route particle first',
    'stale_cell': 'C03: stale cached cell',
    'outside_cell': 'C03: cached cell outside owned grid',
    'bad_period': 'C03: angular period must be positive',
    'origin_only': 'C03: a_origin requires a_period',
    'bad_width': 'C03: nonpositive or NaN width',
    'nan_width': 'C03: nonpositive or NaN width',
    'inconsistent_width': 'C03: inconsistent face/width',
    'nonmonotone': 'C03: faces must increase',
}


def reference(case: str, m: int, r: float, a: float, z: float) -> float:
    if case == 'constant':
        return m / 4 - 1
    if case == 'smooth':
        return m + math.sin(.7*r + .2*m)*math.cos(.6*a - .1*m) + .2*math.sin(.8*z + .3*m)
    # Multilinear polynomial: exact under trilinear interpolation at correctly
    # staggered sample locations, independently of cell size.
    return (m + .1*m*r - .07*(m+1)*a + .03*(m+2)*z + .02*r*a
            - .01*m*a*z + .005*(m+1)*r*z + .004*m*r*a*z)


def main() -> int:
    groups = defaultdict(list)
    seen = set()
    failures = []
    expected = {(case, n, p, m) for case, n in EXACT.items()
                for p in range(1, SAMPLES+1) for m in range(1, 7)}
    expected.update(('smooth', n, p, m) for n in LEVELS
                    for p in range(1, SAMPLES+1) for m in range(1, 7))
    with (OUT / 'c03_gather.csv').open(newline='') as stream:
        for row in csv.DictReader(stream):
            case = row['case']
            n, p, m = (int(row[k]) for k in ('level', 'sample', 'component'))
            key = (case, n, p, m)
            if key not in expected or key in seen:
                failures.append(f'unexpected or duplicate sample: {key}')
            seen.add(key)
            r, a, z, value = (float(row[k]) for k in ('r', 'alpha', 'z', 'value'))
            if not all(map(math.isfinite, (r, a, z, value))):
                failures.append(f'nonfinite sample: {key}')
                continue
            error = abs(value-reference(case, m, r, a, z))
            groups[case, n].append(error)
    missing = expected-seen
    if missing:
        failures.append(f'missing {len(missing)} samples')
    cases = {}
    for case, n in sorted(set((k[0], k[1]) for k in expected)):
        errors = groups[case, n]
        maximum = max(errors, default=math.inf)
        rms = math.sqrt(sum(e*e for e in errors)/len(errors)) if errors else math.inf
        tol = 1e-12 if case == 'constant' else 2e-11
        passed = len(errors) == SAMPLES*6 and (case == 'smooth' or maximum <= tol)
        if not passed:
            failures.append(f'{case}, n={n}: missing/nonfinite values or error exceeds {tol:g}')
        cases[f'{case}:{n}'] = {'rows': len(errors), 'max_abs_error': maximum,
                               'rms_error': rms, 'tolerance': None if case == 'smooth' else tol,
                               'pass': passed}
        print(f'{case:20s} n={n:2d} rows={len(errors):3d} max={maximum:.3e} rms={rms:.3e}')
    rates = []
    for coarse, fine in zip(LEVELS, LEVELS[1:]):
        a = cases[f'smooth:{coarse}']['rms_error']
        b = cases[f'smooth:{fine}']['rms_error']
        rate = math.log2(a/b) if 0 < b < a < math.inf else -math.inf
        passed = 1.7 <= rate <= 2.3
        rates.append({'coarse': coarse, 'fine': fine, 'order': rate, 'pass': passed})
        print(f'smooth {coarse:2d}->{fine:2d}: order={rate:.4f} {"PASS" if passed else "FAIL"}')
        if not passed:
            failures.append(f'smooth convergence order outside [1.7,2.3]: {coarse}->{fine}')
    negative = {}
    for case, diagnostic in NEGATIVE.items():
        result = subprocess.run([str(ROOT/'build/main'), case], cwd=ROOT,
                                capture_output=True, text=True, timeout=15)
        log = result.stdout + result.stderr
        (OUT/f'{case}.log').write_text(log)
        # A crash or a test-driver failure alone must not count as a correct rejection.
        passed = result.returncode != 0 and f'ERROR STOP {diagnostic}' in log
        negative[case] = {'returncode': result.returncode, 'diagnostic': diagnostic, 'pass': passed}
        if not passed:
            failures.append(f'incorrect rejection: {case}')
        print(f'{case:20s} {"PASS" if passed else "FAIL"}')
    summary = {'expected_rows': len(expected), 'observed_rows': len(seen), 'cases': cases,
               'convergence': rates, 'negative': negative, 'failures': failures, 'pass': not failures}
    (OUT/'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    for failure in failures:
        print('FAIL:', failure)
    print('C03 result:', 'PASS' if summary['pass'] else 'FAIL')
    return 0 if summary['pass'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
