# Synthetic demonstration data

The packages in this directory are **synthetic**. The cross sections and
rate coefficients are invented numbers whose only purpose is to exercise the
G02_MCC_network engine and its tests.

> **Do not use these values for scientific conclusions.** They are not measured,
> evaluated or reviewed cross sections.

Each package declares `license,CC0-1.0` and the note
`SYNTHETIC demonstration values only` in its `datasets.csv`; the package
`manifest.csv` carries the same warning in its `description`.

## demo_binary

Seven two-body channels on Ar-like synthetic species (`e-`, `M`, `M2`, `M+`,
`M-`, `M2+`):

| Reaction | Algorithm | Rate law |
|---|---|---|
| `e- + M -> e- + M` | C02 elastic | cross section (m²) |
| `e- + M -> e- + M(excited)` | C03 discrete transition | cross section (m²) |
| `e- + M2 -> e- + M + M` | C04 dissociation | cross section (m²) |
| `e- + M -> e- + e- + M+` | C05 ionization | cross section (m²) |
| `e- + M2 -> M- + M` | C06 attachment | cross section (m²) |
| `M+ + M -> M + M+` | C07 charge exchange | cross section (m²), `identity_exchange` |
| `e- + M2+ -> M + M` | C08 recombination | rate coefficient (m³/s, temperature) |

## demo_three_body

Three three-body channels used to verify the density exponents:

| Reaction | Algorithm | Density factor |
|---|---|---|
| `e- + M + M -> e- + M + M` | C02 elastic | `n_M^2` |
| `e- + M + M2 -> e- + M + M2` | C02 elastic | `n_M * n_M2` |
| `e- + M+ + M -> M + M` | C08 recombination | `n_M+ * n_M` |

## collision_box_elastic

One equal-mass A + B -> A + B elastic channel with an invented constant
temperature-based rate coefficient. Used only by the standalone
`examples/collision_box/` thermalization and collision-statistics validation.

Replace these packages with real, licensed data before any physical use.

For blank headers and filling instructions, see the [CSV template guide](../templates/README.en.md).
