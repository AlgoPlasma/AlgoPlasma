"""Run the compact-phase knowledge-note example and save its numerical results."""
import argparse
import json
from pathlib import Path
from _paths import CASE_DIR
import numpy as np
from K_Diagnostics.K04_breathing_waveform.mod_K04_breathing_waveform import (
    fun_K04_compact_phase, fun_K04_make_complex_signal, fun_K04_mark_position,
)
from generate import compact_phase_data
from run_example import DEFAULT_OUTPUT


def run_example():
    """Compare compact phase to direct phase; truth is used only for verification."""
    t, fs, x, phi_known = compact_phase_data()
    result = fun_K04_compact_phase(x, fs)
    _, z = fun_K04_make_complex_signal(result['F'], result['f'])
    phi_direct, _ = fun_K04_mark_position(z)
    error = result['phi_compact']-phi_direct
    error -= 2*np.pi*np.rint(error[0]/(2*np.pi))
    result.update(t=t, fs=fs, x=x, N=len(x), T=len(x)/fs, phi_known=phi_known,
                  phi_direct=phi_direct, error=error)
    metrics = dict(f0_hz=result['f0'], band_bins=result['L'],
                   original_samples=len(x), M_base=result['M_base'],
                   phase_rmse_rad=float(np.sqrt(np.mean(error**2))),
                   phase_max_error_rad=float(np.max(np.abs(error))))
    return result, metrics


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    data, metrics = run_example()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    np.savez_compressed(args.output_dir/'compact_phase_result.npz', **data)
    (args.output_dir/'compact_phase_metrics.json').write_text(json.dumps(metrics, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(metrics, indent=2))
    print(f"Saved numerical results to {args.output_dir.resolve()}")


if __name__ == '__main__':
    main()
