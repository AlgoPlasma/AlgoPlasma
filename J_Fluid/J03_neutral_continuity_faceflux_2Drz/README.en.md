# J03_neutral_continuity_faceflux_2Drz

J03 advances transient cylindrical continuity using fixed face velocities obtained from J01/J02 reference density and fluxes. Current flux uses current upwind density; fixed velocity does not imply steady density.

Initialize the closure, update source and `closure%loss_frequency` at each physical step, compute a stable timestep, then call `sub_J03_continuity_step`. Update prescribed inflow when needed. The caller owns physical time and must enforce CFL and temporal resolution. Clipping negative density can change particle number.

The update is `n_new=(n-dt*div(flux)+dt*S)/(1+dt*nu)` with SI units. `sub_J03_solve_steady` is optional: for fixed data it requires both relative iterate change and a scaled residual tolerance. Optional `residual_tolerance` defaults to `max(tolerance,100*epsilon(1.0))`; `final_scaled_residual` returns the final value. The reference rate scale does not depend on dt.

`sub_J03_compute_residual` returns local and integrated residuals. `sub_J03_compute_balance` returns inflow, outflow, production and removal rates plus relative imbalance. A transient balance includes accumulation; only a steady field requires zero net rate.

Internal-face type and area must agree on both sides. Area tolerance is `100*epsilon(1.0)*max(A_left,A_right)`. Zero-area axis boundaries are allowed, but internal areas must be positive.

```bash
bash tests/011_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh
```

Tests cover transient decay, source-loss evolution, time-dependent loss, two-cell transfer, first-order time convergence, conservation and diagnostics. Full applications use bundled inputs but must be run separately.
