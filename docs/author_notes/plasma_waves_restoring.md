# Plasma waves: restoring force and inertia

- Reader: the opening slide's newcomer, now able to distinguish electron motion
  from density-pattern motion. Positive/negative electric charge is the only new
  prerequisite reactivated here.
- Destination: explain the direction of the electric field and electron force
  after charge separation, and explain why zero force at equilibrium does not
  imply zero velocity or immediate rest.
- Dependency chain: overlapping neutral layers -> imposed rightward electron
  displacement -> exposed charge -> rightward electric field -> leftward force
  on a negative electron -> release, overshoot, reversal and repeated motion.
- Prediction: the advance labels ask for field direction, then electron-force
  direction before revealing the corresponding arrows. No additional quiz controls.
- Connection: page 1's spatial wave pattern is replaced with a simpler coherent
  slab displacement to isolate the restoring mechanism. Do not portray this as a
  simulation of the formation or propagation of page 1's wave.
- Presentation: static incremental sketches until release; a pause/play control
  appears only for the final oscillation. Both language views, backward steps,
  replay, reduced motion and keyboard controls follow the opening slide.

## Physical model

Uniform unmagnetized cold electrons move relative to a fixed uniform ion slab.
In the small-displacement bulk-field approximation, take rightward displacement
xi as positive and e as the positive elementary charge:

    E = n0 e xi / epsilon0
    F_e = -e E = -n0 e^2 xi / epsilon0
    xi'' = -omega_pe^2 xi
    xi(t) = A cos(omega_pe t), initially xi=A and velocity=0

On return to xi=0, the electric force is zero but velocity is maximal in
magnitude. After crossing, field and force reverse; the force always opposes
displacement, not necessarily velocity. With no damping, the ideal motion persists.
The animation uses xi/A=cos(tau), tau increasing by 1.15 radians per display second,
and A=0.085 times the displayed slab width. No SI density or time is assigned.
Arrow lengths are proportional to xi; the field and force arrows point in opposite
directions. A small zero-label threshold suppresses subpixel arrowheads near xi=0.

The displayed exposed charge bands are the non-overlapping ends of the shifted
electron and fixed ion slabs. For xi>0, the left band is positive and the right
band negative; for xi<0 the labels and bands exchange sides. The rigid-layer
model uses the uniform bulk restoring field. It does not resolve the detailed
nonuniform fields and deformations in the exposed edge regions. Arrow and force
interpretations concern the central electron, away from those edges.

The first shift is externally imposed to prepare the initial condition; its
short visual transition is not part of the free-oscillation solution. The dots
represent collective displacement, not thermal trajectories or a crystal lattice.
Collisions, pressure, magnetic fields, spatial propagation and damping are omitted.
The student sees the slab approximation and its principal omissions next to the
picture; quantitative derivation is deliberately deferred to a later page.

## Integration

The Sphinx course entry links to both pages. The first slide's conclusion links
forward, and this slide's conclusion links back, preserving the chosen language.
Source assets live in `docs/source/_static/plasma_waves/`; build outputs are not edited.
