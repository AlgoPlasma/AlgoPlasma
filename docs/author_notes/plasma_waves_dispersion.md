# Plasma waves: reading a dispersion relation (page 7)

- Reader: knows k, omega, wavelength, period, phase speed, linear superposition
  and the complex plane-wave expression from pages 1–6.
- Capabilities: read a k–omega pair from a dispersion curve; compute wavelength
  and period; distinguish the origin-to-point slope from a tangent slope.
- Sequence: familiar density wave -> parameter axes and one point -> allowed
  branch with a k selector -> linked wavelength/period -> phase-speed secant.
  Five reveals; reuse the shared large typography and progressive controls.
- A point denotes a wave component, not particle position or a time-history
  sample. The chosen branch is a specified fluid example, not a universal plasma
  dispersion law. The next lesson can introduce wave packets and tangent slope.
- Interaction: one keyboard-accessible range input; clicking the plot projects
  the selected horizontal coordinate onto the branch. Changing k compares modes
  and resets phase to zero, preserving pause state. Language changes preserve
  k, time, stage, pause and the model disclosure state.
- Check: predict how lambda and T change when k increases. The fixed spatial
  and temporal plotting windows make the change observable, rather than hiding
  it through autoscaling. No forced quiz or additional navigation controls.

## Specified physical model and units

    omega(k)^2 = W0^2 + U^2 k^2
    W0 = 1e8 rad/s, U = 1e6 m/s
    k selection = 20 ... 80 rad/m; graph = 0 ... 100 rad/m
    omega plot = 0 ... 1.5e8 rad/s

This is the unmagnetized, immobile-ion warm-electron fluid branch with a 1D
pressure closure U^2=3*k_B*T_e/m_e. W0 is the electron plasma frequency; the
numerical parameters are illustrative. The model omits collisions and kinetic
Landau damping. Do not present the curve as a full kinetic result, especially at
shorter wavelengths. Visible captions state the fluid approximation and omitted
damping; a large-text disclosure specifies the equation and all model parameters.
Random thermal motion is not drawn: temperature enters via the pressure term.

References: [MIT Introduction to Plasma Physics](https://silas.psfc.mit.edu/introplasma/master.pdf),
electron plasma waves / Bohm–Gross relation;
[David Morin, Dispersion](https://bpb-us-e1.wpmucdn.com/sites.harvard.edu/dist/0/550/files/2023/11/waves_dispersion.pdf),
origin-to-point phase-speed geometry. The teaching sequence is a local design.

## One consistent dimensional conversion

The animation uses X=K0*x, tau=W0*t, K0=W0/U=100 rad/m (radians dimensionless).
The shared mass-coordinate inversion is supplied k_hat=k/K0 and
omega_hat=omega/W0; thus its density is 1+0.18*cos(k*x-omega*t).
The visible domain is always 0.4 m, so X spans 40. Dots use the same density
coefficients as the probe trace; the relative amplitude is exaggerated to 0.18.
The wave graph is normalized delta_n/n0, not calibrated absolute density.

tau advances by 3 per playback second: physical time is slowed uniformly to
3e-8 s per playback second, independent of k. The probe is x=0 and its fixed
time window spans 8e-8 s. Its cursor replays the first period and always matches
the instantaneous probe phase; the fixed trace is not a growing time history.
The bracket length is lambda=2*pi/k in the fixed
spatial window. A crest marker uses omega_hat*tau/k_hat modulo lambda_hat;
it relabels the next crest after each wavelength and is not an electron marker.

Readouts use omega=frequency(k), lambda=2*pi/k, T=2*pi/omega, vp=omega/k.
The SVG uses physical k/omega, with real origins and numeric ticks. The final
gold line connects (0,0) and (k,omega); it is not a tangent or group velocity.
Negative k, additional branches, propagation cutoffs and growth rates are deferred.

## Validation

Check coordinate projections, mode selection by plot and keyboard slider,
readouts, lambda and period against the drawn wave, the density-map inversion,
and vph=lambda/T. Check all five reveals, replay, language/state preservation,
reduced motion, text alternative, disclosure, page 6–7 links, directory and build.
Inspect large-screen and stacked mobile diagrams, units, and label clipping.
These checks establish functional consistency, not measured learning effectiveness.

Verified on 2026-11-18 in headless Edge against the Sphinx build: all five
reveals in Chinese and English at 320, 768, 1280, 1440 and 1920 px widths;
no horizontal overflow or clipped SVG text. Model/drawing checks at k=20, 40,
80 rad/m covered dimensional conversion, density-map inversion, wavelength
brackets, probe phase after multiple periods, and crest speed. Plot/keyboard
selection, replay, language-state preservation, reduced motion, no-JavaScript
and no-canvas fallbacks, and all seven page-navigation links passed.
Sphinx completed without warnings.
