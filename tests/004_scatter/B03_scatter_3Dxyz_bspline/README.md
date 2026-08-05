# B03_scatter_3Dxyz_bspline test

This test validates `B_Scatter/B03_scatter_3Dxyz_bspline`.

It checks the following properties:

- `order=1` number deposition matches `B01_Scatter_3Dxyz` pointwise.
- `order=1` component deposition matches `B01_Scatter_3Dxyz_v` pointwise.
- `order=0..4` conserves the deposited total amount.
- `order=1..4` preserves first moments.
- Split accumulation matches a single full call.

The Python postprocessor also generates reference figures for the RST test
documentation.

Run:

```bash
bash run.sh
```
