# Plasma waves: interference, beats and standing waves (lesson 03)

- Audience: lesson 02's reader, familiar with density perturbation, phase, k and
  omega. Prerequisites are addition of signed perturbations and cosine behavior.
- Capability: use linear superposition to explain reinforcement/cancellation,
  predict beat frequency, identify stationary density nodes and distinguish them
  from stationary particles.
- Sequence: one density wave -> add an equal co-propagating wave and adjust phase
  -> use nearby frequencies -> reverse one of two equal-frequency waves ->
  expand and add the two cosines -> a short prediction about what vanishes at
  a density node. Six stages; the algebra replaces the animation in stage 4,
  and the optional prediction is stage 5 (zero-based).
- Independence: lesson 02 is linked as a prerequisite; each case visibly states its
  conditions and uses a self-contained analytic model. No Hall-thruster context.
- Feedback: the phase slider continuously updates resultant amplitude. The final
  two-choice prediction explains both answers and never blocks navigation. The
  tracked gold electron supplies visual evidence for the node interpretation.

## Physical scope and analytic fields

Within the linear approximation, add density perturbations, not total densities:

    n_e/n0 = 1 + sum_j a_j cos(k_j X - omega_j tau + phi_j).

The implicit ion background is fixed. X and tau use arbitrary reference length
and time units, k1=omega1=2*pi. Each a_j=0.14; amplitude is enlarged for clarity.
This prescribed visualization illustrates linear superposition, not nonlinear
wave interactions, a self-consistent plasma solution or a dispersion relation.
Thermal motion is omitted. Positive total density is guaranteed (n_e/n0>=0.72).

Each case uses the common exact monotone mass-coordinate map

    q = X + sum_j (a_j/k_j) sin(k_j X - omega_j tau + phi_j).

The map makes dot spacing agree with the Eulerian density. This consistency is
kinematic; particle displacements are NOT simply added as nonlinear solutions.

1. Interference: k2=k1, omega2=omega1; relative phase ranges 0..2*pi. The resultant
   density amplitude is 2A*abs(cos(DeltaPhi/2)). Three vertically aligned curves
   have identical scales and show delta_n1, delta_n2, and their sum. At pi the
   perturbations cancel; the background density remains n0, not zero.
2. Beats: k2=1.2*k1 and omega2=1.2*omega1, propagating in the same direction. At
   fixed X=0 the sum is 2A*cos(0.2*pi*tau)*cos(2.2*pi*tau). The amplitude envelope
   is 2A*abs(cos(0.2*pi*tau)); its consecutive maxima are 5 T1 apart. Thus
   f_beat=abs(f2-f1)=0.2*f1, NOT half that difference. The signed cosine factor
   changes sign after 5 T1; physical amplitude is its absolute value. The graph
   spans 10 T1, and both component signals repeat across the cursor wrap. Dashed
   envelopes are amplitude guides, not a third wave. This example assumes equal
   phase velocities; do not infer universal nondispersive plasma propagation.
3. Standing wave: k2=k1, omega2=-omega1 (equivalently cos(kX+omega*tau)). Then
   delta_n=2A*cos(kX)*cos(omega*tau). Density nodes lie at X=0.25+0.5m; density
   antinodes lie at X=0.5m. At a density node delta_n=0, not n_e=0. The continuity
   construction gives nonzero oscillatory particle flux through density nodes;
   they need not be velocity nodes. The gold electron has fixed label q=0.75
   and oscillates across the spatial density node at X=0.75.

The derivation states positive k and omega, equal amplitudes and wavenumber
magnitudes, and zero initial phases. Expand cos(kx-omega*t) and
cos(kx+omega*t) separately: the sine products cancel while the cosine products
add. A is each traveling wave's density amplitude in m^-3; the local resultant
amplitude is 2A*abs(cos(kx)), reaching 2A at antinodes. The fixed-node statement
requires cos(kx)=0 for every time, not a momentary zero of cos(omega*t).

The normal clock advances 0.15 T1 per display second, and the beat case uses 0.6
to show an envelope cycle without a long wait. Every stage starts at tau=0;
language changes and slider inputs preserve time and pause state. The visible
caption says playback speed differs across cases. No SI plasma parameters are
inferred from wall-clock playback.

## Checks

Verify exact reinforcement/cancellation, the beat envelope period (absolute
amplitude), stationary density nodes and gold-electron motion through a node.
Check translated quiz feedback, slider state across language changes, replay,
keyboard interaction, reduced motion, adjacent-page navigation and the Sphinx
build. Inspect desktop and mobile renderings. Educational effectiveness is a
future learner evaluation, not a conclusion of these functional checks.
Check the inserted algebra stage in both languages, returning to the standing
animation, optional quiz feedback and replay, and the static text alternative.
