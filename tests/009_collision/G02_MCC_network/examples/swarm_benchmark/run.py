#!/usr/bin/env python3
"""Build two G02 revisions, run paired electron swarms, and compare their outputs."""
import argparse
import csv
import hashlib
import io
import json
import os
from pathlib import Path
import subprocess
import zipfile

HERE = Path(__file__).resolve().parent
MODULE = 'G_Collision/G02_MCC_network'
TEST = 'tests/009_collision/G02_MCC_network'
BASE = '7db6abe640932a48bed863ec41a1f2585951cc42'
INPUT_SHA = 'd036b7afe596eb6040be1102ec7932ef5fe4b07e369bddef11ae57e896d2250b'
CASES = [('he_noion', 50), ('he_full', 200), ('reid', 12)]
SEEDS = [104729, 130363, 155921]


def git(*args):
    root = subprocess.check_output(['git', '-C', HERE, 'rev-parse', '--show-toplevel'], text=True).strip()
    return subprocess.check_output(['git', '-C', root, *args])


def build(out, name, revision):
    dest = out / name
    dest.mkdir()
    with zipfile.ZipFile(io.BytesIO(git('archive', '--format=zip', revision, MODULE, TEST))) as z:
        z.extractall(dest)
    build_dir = dest / 'build'
    subprocess.run(['cmake', '-S', dest / TEST, '-B', build_dir, '-DCMAKE_BUILD_TYPE=Release',
                    '-DCMAKE_CXX_COMPILER=g++', '-DG02_MCC_ENABLE_MPI=ON',
                    '-DG02_MCC_ENABLE_OPENMP=ON', '-DG02_MCC_ENABLE_SANITIZERS=OFF'], check=True)
    subprocess.run(['cmake', '--build', build_dir, '--target', 'g02_mcc', '-j', '4'], check=True)
    exe = dest / 'swarm'
    subprocess.run(['g++', '-std=c++20', '-O3', '-DNDEBUG', '-fopenmp', HERE / 'swarm.cpp',
                    '-I', dest / MODULE, build_dir / 'libg02_mcc.a', '-o', exe], check=True)
    return exe


def run_pair(out, executables, cpu, model, td, seed, order, phase, warm, steps):
    pair_dir = out / 'runs' / f'{phase}_{model}_{td}_{seed}'
    pair_dir.mkdir(parents=True)
    meta = {}
    env = dict(os.environ, OMP_NUM_THREADS='1', OMP_DYNAMIC='FALSE', OPENBLAS_NUM_THREADS='1')
    for name in order:
        data = pair_dir / f'{name}.csv'
        subprocess.run(['taskset', '-c', str(cpu), executables[name], out / 'models' / model,
                        out / 'inputs/initial' / f'{seed}.txt', data, str(td), '5e-14',
                        str(warm), str(steps), str(seed), '100'], check=True, env=env)
        meta[name] = json.loads(Path(str(data) + '.json').read_text())
        with data.open() as f:
            samples = list(csv.DictReader(f))
        if (len(samples) != (warm + steps) // 100 or
                any(int(r['step']) != 100*i or int(r['n_after_control']) != 4000 or
                    r['phase'] != ('warmup' if 100*i <= warm else 'measured')
                    for i, r in enumerate(samples, start=1))):
            raise ValueError(f'{data}: unexpected diagnostic count, step, phase or population')
    for suffix in ('.csv', '.csv.state'):
        a, b = [(pair_dir / (n + suffix)).read_bytes() for n in ('baseline', 'candidate')]
        if not a or a != b:
            raise ValueError(f'{pair_dir}: output mismatch or empty output ({suffix})')
    a, b = meta['baseline'], meta['candidate']
    for key in ('real_events', 'candidates', 'births_total', 'births_measured', 'particles_visited'):
        if a[key] != b[key]:
            raise ValueError(f'{pair_dir}: {key} differs')
    return dict(phase=phase, model=model, Td=td, seed=seed, order='/'.join(order),
                baseline_s=a['wall_s'], candidate_s=b['wall_s'], speedup=a['wall_s']/b['wall_s'],
                baseline_VmHWM_MiB=a['vmhwm_kib']/1024,
                candidate_VmHWM_MiB=b['vmhwm_kib']/1024)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True, help='new directory for inputs and results')
    parser.add_argument('--cpu', type=int, help='one allowed logical CPU, default: first available')
    parser.add_argument('--baseline', default=BASE)
    parser.add_argument('--candidate', default='HEAD')
    parser.add_argument('--smoke', action='store_true', help='check the setup without measuring full cases')
    parser.add_argument('--reverse-all', action='store_true',
                        help='repeat all nine main pairs with the run order reversed')
    args = parser.parse_args()
    allowed = os.sched_getaffinity(0)
    cpu = min(allowed) if args.cpu is None else args.cpu
    if cpu not in allowed:
        parser.error(f'CPU {cpu} unavailable; choose from {sorted(allowed)}')
    versions = {name: git('rev-parse', '--verify', ref + '^{commit}').decode().strip()
                for name, ref in [('baseline', args.baseline), ('candidate', args.candidate)]}
    if versions['baseline'] == versions['candidate']:
        parser.error('baseline and candidate resolve to the same commit')
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    archive = HERE / 'swarm_inputs.zip'
    if hashlib.sha256(archive.read_bytes()).hexdigest() != INPUT_SHA:
        raise ValueError('input archive differs from the PR benchmark')
    with zipfile.ZipFile(archive) as z:
        z.extractall(out)
    protocol = dict(revisions=versions, cpu=cpu, smoke=args.smoke, reverse_all=args.reverse_all, dt_s=5e-14, electrons=4000,
                    memory_source='Linux /proc/self/status VmHWM after final state output',
                    input_sha256=INPUT_SHA, driver_sha256=hashlib.sha256((HERE/'swarm.cpp').read_bytes()).hexdigest(),
                    compiler=subprocess.check_output(['g++','--version'], text=True).splitlines()[0])
    (out/'environment.json').write_text(json.dumps(protocol, indent=2) + '\n')
    exes = {name: build(out, name, rev) for name, rev in versions.items()}
    forward = ('baseline', 'candidate')
    rows = []
    for i, seed in enumerate(SEEDS[:1] if args.smoke else SEEDS):
        for model, td in CASES[i:] + CASES[:i]:
            order = forward if len(rows) % 2 == 0 else forward[::-1]
            rows.append(run_pair(out, exes, cpu, model, td, seed, order,
                                 'smoke' if args.smoke else 'main',
                                 100 if args.smoke else 40000, 200 if args.smoke else 40000))
    if not args.smoke:
        main_pairs = rows.copy() if args.reverse_all else rows[:3]
        for first in main_pairs:
            order = first['order'].split('/')[::-1]
            rows.append(run_pair(out, exes, cpu, first['model'], first['Td'], first['seed'],
                                 order, 'reverse', 40000, 40000))
    with (out/'pairs.csv').open('w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=rows[0])
        writer.writeheader()
        writer.writerows(rows)
    print(f'{len(rows)} pairs matched (diagnostic CSVs, final states and collision counts).')
    if not args.smoke:
        for model, td in CASES:
            case_rows = [r for r in rows if r['model'] == model]
            groups = [('main order', [r for r in case_rows if r['phase'] == 'main'])]
            if args.reverse_all:
                reverse_rows = [r for r in case_rows if r['phase'] == 'reverse']
                groups.extend([('reversed order', reverse_rows), ('both orders', case_rows)])
            for label, group in groups:
                gain = sum(r['baseline_s'] for r in group) / sum(r['candidate_s'] for r in group)
                print(f'{model} {td} Td: {gain:.3f}x ({label})')


if __name__ == '__main__':
    main()
