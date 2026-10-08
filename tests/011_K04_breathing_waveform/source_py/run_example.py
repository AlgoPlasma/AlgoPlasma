"""Generate the K04 worked example and save numeric results, without plotting.

Run from repository root: python -B tests/011_K04_breathing_waveform/source_py/run_example.py
"""
import argparse
import json
from pathlib import Path
from _paths import CASE_DIR
import numpy as np
from K_Diagnostics.K04_breathing_waveform.mod_K04_breathing_waveform import fun_K04_extract_waveform, fun_K04_put_into_bins
from generate import synthetic_data

DEFAULT_OUTPUT = CASE_DIR/'output'


def run_example(seed=20261004):
    """Return the complete numerical example as arrays plus a compact metric dict."""
    t, fs, xs, truths = synthetic_data(seed)
    result = fun_K04_extract_waveform(xs, fs)
    B, r = 256, 0
    error = result['C'] - truths[r]
    S, K = fun_K04_put_into_bins(result['R'], result['positions'][r], B)
    square_sum, _ = fun_K04_put_into_bins(result['R']**2, result['positions'][r], B)
    res_mean = np.divide(S, K, out=np.full(B, np.nan), where=K>0)
    res_rms = np.sqrt(np.divide(square_sum, K, out=np.full(B, np.nan), where=K>0))
    result.update(t=t, fs=fs, xs=np.asarray(xs), truths=np.asarray(truths), B=B, r=r,
                  positions=np.asarray(result['positions']), C_known=truths[r],
                  error=error, res_mean=res_mean, res_rms=res_rms)
    metrics = dict(seed=seed, records=len(xs), samples=len(t), fs_hz=fs,
                   held_out=r, bins=B, grid_size=len(result['w']), cutoff_hz=3e6,
                   f0_hz=result['f0'], H=result['H'], min_training_count=int(result['K_train'].min()),
                   rmse_v=float(np.sqrt(np.mean(error**2))),
                   residual_bin_mean_v=res_mean[[32,160]].tolist(),
                   residual_bin_rms_v=res_rms[[32,160]].tolist())
    return result, metrics


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument('--seed', type=int, default=20261004)
    args = parser.parse_args()
    data, metrics = run_example(args.seed)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    np.savez_compressed(args.output_dir/'synthetic_result.npz', **data)
    (args.output_dir/'metrics.json').write_text(json.dumps(metrics, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(metrics, indent=2))
    print(f"Saved numerical results to {args.output_dir.resolve()}")


if __name__ == '__main__':
    main()
