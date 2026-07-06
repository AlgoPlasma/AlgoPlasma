# B01_scatter_3Dxyz_omp — Kunpeng comparison

Cross-platform OpenMP comparison of the upstream `sub_B01_scatter_3Dxyz` kernel.
The same benchmark runs on the AMD server and the Kunpeng server, and the
analyzer overlays both platforms once their logs are present.

The test is designed to expose how the kernel's
`!$omp parallel default(firstprivate) reduction(+:den)` design scales with
thread count and particle count. The single-call wall time, speedup, and
parallel efficiency are reported across the joint sweep.

## Sweep axes

| Axis        | Values                                                  |
|-------------|---------------------------------------------------------|
| `np`        | 10 000, 100 000, 1 000 000, 10 000 000                  |
| `nthread`   | 1, 2, 4, 6, 7, 8, 9, 10, 12, 14, 16, 32, 64             |
| `nrepeat`   | 10 (per (np, nthread) point)                            |
| grid        | `il = (1,1,1)`, `iu = (12,12,12)`, 1 guard cell each side |
| `w`         | 2.0                                                     |

Particles are randomly placed inside `[il, iu]` once per `np` value and reused
across all thread counts for that `np`. `den = 0` is done outside the timed
region so each timing measures one pure scatter call.

Each (np, nthread) cell is run `nrepeat` times; the log records the avg, best,
and worst single-call time. Per-platform derived columns:

- `speedup_vs_1 = t(np, 1) / t(np, N)`
- `efficiency_vs_1 = speedup / N`

## Layout

```
run_AMD.sh                        # platform entry: builds, runs, writes data_raw/from_AMD/log.run
run_kunpeng.sh                    # platform entry: builds, runs, writes data_raw/from_kunpeng/log.run
plot.sh                           # post-process: invokes source_py/analyze.py
source_f90/main.f90               # outer np-loop × inner thread-loop benchmark
         /make.sh clean.sh         # build helpers, invoked by the run_*.sh entries
source_py/analyze.py               # parses logs, soft-fails on missing data
data_raw/from_AMD/log.run          # produced by run_AMD.sh
        /from_kunpeng/log.run      # produced by run_kunpeng.sh
output/summary.csv                 # always written when at least one platform has data
       /figures/                   # only written when both platforms have data
```

The three top-level `.sh` files are the only entry points. The `run_*.sh`
scripts each set `ulimit -s unlimited` and `OMP_STACKSIZE=1G` before launching,
because the upstream kernel firstprivatizes the entire `(3, np)` array onto
each thread's stack; the default 8 MB OS stack overflows immediately at
`np = 1e7`.

## How to reproduce

On the AMD server:

```bash
cd tests/kunpeng_compare/B01_scatter_3Dxyz_omp
bash run_AMD.sh        # clean + build + run, writes data_raw/from_AMD/log.run
```

On the Kunpeng server (after copying or syncing this directory there):

```bash
cd tests/kunpeng_compare/B01_scatter_3Dxyz_omp
bash run_kunpeng.sh    # clean + build + run, writes data_raw/from_kunpeng/log.run
```

After both `log.run` files are in place on the analysis machine, post-process:

```bash
bash plot.sh
```

`plot.sh` writes `output/summary.csv` for whichever platforms have data. It
writes the three figures into `output/figures/` **only when both platforms
have logs**; otherwise it prints which platform is still missing and exits
cleanly.

## Figures

When both sides have data the analyzer emits:

- `time_vs_threads.png` — avg compute time vs threads (log-log), two subplots
  (AMD server / Kunpeng), one curve per `np`. The classic U shape — minimum at a few
  threads, then rising — comes from the kernel's per-thread `par` copy.
- `speedup_vs_threads.png` — `t(1)/t(N)` on log-log, with an `ideal = N`
  reference. Real curves stay well below the diagonal and bend back below 1 at
  high thread counts, especially for large `np`.
- `efficiency_vs_threads.png` — `speedup / N`. The drop from 1.0 toward 0
  visualizes how quickly `firstprivate + reduction` overhead overtakes the
  scatter work; smaller `np` cases lose efficiency fastest.

## Memory budget

The upstream kernel uses `default(firstprivate)`, so each thread gets its own
copy of the `(3, np)` particle array. Per-thread footprint is `24 × np` bytes
(with `-fdefault-real-8`). At `np = 1e7` and `nthread = 64` this is
`64 × 240 MB ≈ 15 GB`. Make sure the target machine has enough free RAM before
running the largest `np` rows.
