# FDTD 3D Cylindrical m=0 Equivalence Test

This case keeps only one program: `test_geom_m0_equivalence.f90`.
It checks TMz/TEz equivalence between 3D cylindrical `m=0` and 2D RZ updates.

## Pass Criteria

- `combined_rel_L2 <= 2e-2` for both TMz and TEz
- `combined_rel_Linf <= 1e-1` for both TMz and TEz

## build / run / clean

Build:

```bash
bash make.sh
```

Run (default):

```bash
bash run.sh
```

Run (custom):

```bash
bash run.sh <Nequiv>
```

Parameter:
- `Nequiv`: number of update steps (default `600`)

Clean:

```bash
bash clean.sh
```

## Output

- Log: `logs/m0_equivalence.log`
- Summary: `m0_equivalence_summary.csv`

## Related Test Result

- Last update: `2026-04-09`
- Run command: `bash run.sh`
- Run status in this workspace: `PASS`

Result summary:

```csv
m0_equivalence,TMz,  2.776E-15,  1.059E-14,pass,Er,Ez,Hphi
m0_equivalence,TEz,  4.456E-16,  8.833E-16,pass,Ephi,Hr,Hz
```

Generated files:
- `logs/m0_equivalence.log`
- `m0_equivalence_summary.csv`
