#!/usr/bin/env python3
"""Reproduce the velocity-kinematics checks without removing existing outputs."""
import argparse
import json
import os
from pathlib import Path
import shlex
import subprocess


def main():
    test_root = Path(__file__).resolve().parents[1]
    repo = Path(__file__).resolve().parents[4]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=test_root / 'build' / 'relative_speed')
    parser.add_argument('--compiler', default=os.environ.get('FC', 'gfortran'))
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    module_dir = repo / 'J_Fluid' / 'J02_neutral_sn_transport_2Drz'
    source = test_root / 'source_f90' / 'test_J02_relative_speed.f90'
    common = ['-cpp', '-O0', '-g', '-std=f2008', '-fcheck=all', '-fbacktrace',
              '-finit-real=snan', '-ffpe-trap=invalid,zero,overflow', '-Wall', '-Wextra']
    records = []
    for precision in (4, 8):
        for threaded in (False, True):
            tag = f'r{precision}_' + ('omp4' if threaded else 'serial')
            build = output / tag
            build.mkdir(parents=True, exist_ok=True)
            flags = common.copy()
            if precision == 8:
                flags.append('-fdefault-real-8')
            if threaded:
                flags.append('-fopenmp')
            compiler = shlex.split(args.compiler)
            env = os.environ.copy()
            env.update(OMP_NUM_THREADS='4', OMP_DYNAMIC='FALSE', OMP_THREAD_LIMIT='4')
            commands = []

            def run(command, log_name):
                result = subprocess.run(command, cwd=build, env=env, text=True,
                                        capture_output=True, timeout=120)
                (build / log_name).write_text(result.stdout + result.stderr, encoding='utf-8')
                commands.append({'command': command, 'returncode': result.returncode,
                                 'log': log_name})
                (build / 'commands.json').write_text(json.dumps(commands, indent=2), encoding='utf-8')
                if result.returncode:
                    raise RuntimeError(f'{tag}: see {build / log_name}')
                return result.stdout

            obj = build / 'module.o'
            run(compiler + flags + ['-I' + str(module_dir), '-J' + str(build), '-c',
                str(module_dir / 'mod_J02_neutral_sn_transport_2Drz.f90'), '-o', str(obj)],
                'module_compile.log')
            executable = build / 'test_J02_relative_speed.out'
            run(compiler + flags + ['-I' + str(build), '-J' + str(build), str(source),
                                   str(obj), '-o', str(executable)], 'test_compile.log')
            stdout = run([str(executable), str(build / 'pairs.csv')], 'test.log')
            expected_workers = 4 if threaded else 1
            if f'INFO: OpenMP workers: {expected_workers}' not in stdout:
                raise RuntimeError(f'{tag}: actual worker count differs; see test.log')
            if f'INFO: real bytes: {precision}' not in stdout or 'RESULT: PASS' not in stdout:
                raise RuntimeError(f'{tag}: missing precision/pass confirmation')
            metrics = {}
            for line in stdout.splitlines():
                if line.startswith('VALUE: '):
                    key, value = line[len('VALUE: '):].rsplit(':', 1)
                    metrics[key] = float(value)
            records.append({'build': tag, 'precision_bytes': precision,
                            'workers': expected_workers, 'metrics': metrics, 'passed': True})
            print(f'{tag}: PASS', flush=True)
        serial = output / f'r{precision}_serial' / 'pairs.csv'
        parallel = output / f'r{precision}_omp4' / 'pairs.csv'
        if serial.read_bytes() != parallel.read_bytes():
            raise RuntimeError(f'real{precision}: serial/OpenMP pair records differ')
        print(f'real{precision}: serial/OpenMP CSV identical', flush=True)
    summary = {'scope': 'velocity kinematics only; no CEX cross section or operator',
               'error_definition': '|g - g_reference| / max(neutral_speed, ion_speed) for node pairs',
               'serial_openmp_csv_identical': True, 'runs': records}
    (output / 'summary.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
    print(f'Records: {output}')


if __name__ == '__main__':
    main()
