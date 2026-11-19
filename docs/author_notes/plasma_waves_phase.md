# Plasma waves: phase and the wave expression (lesson 02, slides 4–6)

- Audience/prerequisites: the period, wavelength and phase speed from the preceding measurement slides; a cosine
  curve and one turn of an angle (2*pi radians). No dispersion relation required.
- Capability: predict relative timing at separated probes, compute k and omega
  from lambda and T, and interpret each term of a right-moving sinusoidal wave.
- Sequence: moving density field -> two local time traces and an adjustable
  probe -> simultaneous spatial phase difference -> phase change at a fixed
  point over time -> combine x and t in one wave expression.
- Check: slide probe B through lambda/4, lambda/2 and lambda; compare phase and
  traces before reading the same/opposite-phase feedback. Slider arrow keys
  adjust its value rather than advancing the slide. No additional mode buttons.
- Final connection: constant kx-omega*t+phi0 implies dx/dt=omega/k, linking the
  expression directly to the phase speed measured in the first half of the lesson.

## Model and interpretation

The density and dot mapping are the same as in the measurement slides: a=0.28, k=omega=2*pi in
normalized internal reference units. The two probes are at X_A=0.5 and
X_B=X_A+DeltaX, where DeltaX ranges from 0 to one wavelength in 0.05 increments.
At each instant DeltaPhi=phi_B-phi_A=k*DeltaX. At a fixed position the adopted
right-moving-wave convention gives DeltaPhi=-omega*DeltaT. Angular frequency
omega is positive; the minus sign describes the temporal phase change, not a
negative frequency. Integer multiples of 2*pi are equivalent phases.

The full expression uses dimensional notation:

    n_e = n0 + delta_n
    delta_n(x,t) = A cos(kx - omega*t + phi0)
    k = 2*pi/lambda; omega = 2*pi/T = 2*pi*f

A is a density amplitude, not a displacement, electric-field amplitude or total
density. The final curve is delta_n with zero baseline; earlier curves are n_e
with n0 baseline. The animation uses phi0=0 and a positive k and omega; the peak
highlight follows phase 2*pi*m. It is a prescribed kinematic illustration, not
a calculation of self-consistent plasma dynamics. Ions are implicit and fixed;
thermal motion is omitted. Amplitude is set for visibility and no linear plasma
dispersion claim is made.

## Interaction/accessibility

All five stages retain pause/back/replay, the persistent language choice,
keyboard navigation, reduced-motion behavior and canvas text alternatives.
The slider appears only for the two-probe stages, with a visible label, numeric
output, an accessible value description, and translated phase feedback.
Language switching preserves time, pause, stage and probe separation. Choosing a
new separation changes the observation point rather than the underlying wave.

Verify the half-wavelength opposition and one-wavelength coincidence, formula
sign, phase-speed correspondence, language/state preservation and layout, then
build Sphinx. These checks do not establish student learning outcomes.
