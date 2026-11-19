# Plasma waves: measuring a wave (page 3)

- Audience: newcomers who can distinguish electron motion from density-pattern
  motion and recognize restoring force and inertia from pages 1–2.
- Capability: measure a period at a fixed spatial point, a wavelength at a fixed
  time, and derive phase speed by following the same crest through one period.
- Sequence: clean moving dot field -> fixed virtual density probe and time trace
  -> frozen density snapshot and wavelength -> a crest advances lambda in T.
  Three slides keep the time measurement, spatial measurement and crest tracking distinct.
- Prediction: ask the learner what must be held fixed for each measurement, and
  how far a crest will move in one period before revealing the final animation.
- Interpretation: the probe measures Eulerian local density, not displacement
  of a marked electron. The trace and dots use exactly the same density field.
- Independence: page 2 explains a restoring mechanism, but its rigid slab is not
  reused as a propagating-wave model. Page 3 prescribes a wave to teach kinematics.
- Interaction: explicit advance/back, slide and lesson restart, pause and language switching;
  reduced-motion starts paused and allows explicit play. A textual alternative
  and per-stage accessible descriptions carry the meaning without animation.

## Model and units

Normalized coordinates X=x/lambda_ref and tau=t/T_ref are internal animation
coordinates, not measured SI plasma parameters. For this page k=omega=2*pi and
a=0.28, so one reference length is lambda and one reference time is T:

    n_e(X,tau)/n0 = 1 + a cos(k X - omega tau).

Dots represent equal electron counts, with fixed labels q spaced uniformly:

    q = X + (a/k) sin(k X - omega tau).

The derivative dq/dX equals n_e/n0 exactly. Newton inversion of this monotone map
gives electron positions whose spacing matches the displayed Eulerian density.
This is a prescribed, mass-conserving kinematic construction, not a solution of
the plasma momentum/Poisson system. It imposes no dispersion relation. There is
no thermal motion; a fixed ion background is implicit; the dots are not a crystal.
For this single wave each labeled electron returns to its position after T.

The fixed probe is at X=0.5. Its time trace spans 2.2 T; the cursor wraps every
2 T, so density remains in phase across wraps. Adjacent maxima at tau=0.5 and
1.5 are separated by T. The frozen view samples the same density at the current
time and marks peaks one wavelength apart. In the final view the tracked crest
starts at X=0.25 and advances to X=1.25 over T, pauses briefly, then repeats.
The full density field uses that same time, including the hold and replay.
The normal playback rate is 0.15 reference periods per wall-clock second.
The elapsed fraction of T is illustrative, not a calibrated physical clock.

Phase speed is lambda/T=lambda*f. It need not equal particle velocity, group
velocity or energy-transport speed. The page deliberately does not identify
these velocities or derive plasma frequency yet.

## Implementation and validation

### Unit presentation across the opening lessons

Show SI units beside newly introduced quantities and dimensional axis labels:
T and t in s; f in Hz; x and lambda in m; phase speed in m/s; k in rad/m;
omega in rad/s; phase in rad; electron number density, its perturbation and its
amplitude in m^-3. Page 2's electric field is in V/m and electron force in N.
Keep the explicit radian symbol to distinguish phase from a cycle count. In SI
the radian has dimension one, so k and omega have dimensions m^-1 and s^-1.
See the [BIPM SI Brochure](https://www.bipm.org/en/publications/si-brochure).

The plotted physical quantities have symbolic reference scales lambda, T and n0
(lambda1 and T1 for the two-wave examples). No numerical SI calibration is
assigned. The caption makes this explicit: the animation's wall-clock duration
is not a physical period. Slider values DeltaX/lambda are dimensionless ratios;
displaying 0.25 lambda is a relative distance, not 0.25 m. Values in the phase
sliders are in pi radians, and their visible and accessible outputs include rad.

`wave-course.js` shares presentation controls and exact density-to-dot mapping
among pages 3–6; the first two lessons retain their existing independent models.
`wave-measures.js` supplies this page's bilingual content and diagram. The course
entry and page 2 link here. Verify both language views, forward/back, pause,
reduced motion, frozen snapshot, period/wavelength annotations and navigation.
Build the Sphinx documentation; inspect desktop and narrow-screen renderings.
These are functional checks, not evidence of measured learning effectiveness.
