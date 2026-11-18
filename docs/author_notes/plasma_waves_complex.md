# Plasma waves: complex representation (page 6)

- Reader: knows period, wavelength, phase, density perturbation and superposition
  from pages 3–5. Introduce only the needed complex-number facts: i^2=-1, real and
  imaginary components, and Euler's identity. No prior phasor course is assumed.
  The final two reveals assume basic differentiation and explain what each
  partial derivative holds fixed, followed by the chain rule.
- Destination: recover a real density signal from its complex representation;
  interpret complex amplitude as magnitude plus initial phase; add amplitudes
  for a common mode; explain the derivative multipliers and their signs/units.
- Sequence: real plasma signal -> rotating complex density and its real-axis
  projection -> constant amplitude times the traveling exponential -> head-to-tail
  amplitude addition -> derivatives as scaled, rotated complex quantities ->
  time partial derivative at fixed x -> space partial derivative at fixed t.
  Seven stages connect the pictures to the calculation. The last two replace
  the animation with readable algebra; the same advance/back controls reveal
  them, with no additional buttons. Real-part checks explain the opposite signs.
- Checks: change initial phase while watching the same probe; predict cancellation
  at relative phase pi; observe that zero total amplitude has undefined phase;
  compare the derivative's zero crossings with density extrema.
- Controls: one slider, revealed only when relevant; it edits initial phase in
  stage 2 and relative phase in stage 3. Stage, time, slider values and pause state
  survive language switching. Keyboard and reduced-motion behavior use the shared
  runtime. A full bilingual text alternative accompanies accessible stage summaries.

## Convention, quantities and units

Use the convention from page 4 throughout:

    n_tilde(x,t) = n_hat exp(i(k*x - omega*t))
    n_hat = A exp(i*phi0)
    delta_n = Re(n_tilde), n_e = n0 + delta_n

Both axes of the complex plane, A, n_hat, n_tilde and delta_n have units m^-3.
The complex plane is not the physical x-y plane. A complex representation records
two quadratures; the chosen real-part convention recovers the physical signal.
The imaginary component is useful information, not an additional electron motion.
The spatial coordinate x uses m, k rad/m, omega rad/s, phase rad; i and the
exponential are dimensionless. Rad has dimension one in SI. No numerical SI
calibration is assigned: plot scales use lambda, T and n0, with arbitrary slowed
playback. The density model is prescribed kinematics, not a plasma dispersion
calculation. Ions are fixed and thermal motion is omitted.

The fixed probe is x=0. For positive omega its complex value rotates clockwise,
because theta=-omega*t+phi0. The solid arrow shows n_tilde(0,t), its real-axis
projection gives the instantaneous probe delta_n, and the time-curve marker uses
the same value. Stages 1 and 2 begin at tau=1/8 to make both quadratures and the
projection visible even when reduced motion is enabled. Other stages begin at
tau=0. The initial-amplitude arrow in stage 2 is dashed and stationary;
it does not become a second rotating wave.

Internal X=x/lambda_ref and tau=t/T_ref use k=omega=2*pi. A/n0=0.28 for the single
wave; in the sum each component has A/n0=0.14. For the sum stage, equal k and omega
allow the common exponential to be factored out. The complex amplitudes on the
left are stationary; the real physical wave on the right still evolves in time.
The second arrow is translated head-to-tail without rotating it. At phase pi the
sum vanishes (within numerical tolerance); no resultant phase is assigned.

The density uses the shared mass-coordinate inversion from page 3, with exactly
the same wave coefficients as the complex arrows and probe curves. Thus the
density, the real part of the complex field and particle spacing agree.

## Differentiation and comparable vectors

For constant n_hat and a single plane-wave component:

    d_t [i(k*x - omega*t)] = -i*omega   (hold x fixed)
    d_x [i(k*x - omega*t)] =  i*k       (hold t fixed)
    d_v exp(g) = exp(g) d_v g          (chain rule, v = t or x)
    d_t n_tilde = -i*omega*n_tilde       [m^-3/s]
    d_x n_tilde =  i*k*n_tilde          [m^-4]

With theta=k*x-omega*t+phi0, the real-part check gives
d_t delta_n=A*omega*sin(theta) and d_x delta_n=-A*k*sin(theta).
The cosine derivative supplies one minus sign; d_t theta supplies a second,
whereas d_x theta=k does not. Both derivations display the constant-amplitude
condition, original wave, chain-rule intermediate expression and result units.
Both also repeat n_tilde=A*exp(i*theta)=A*cos(theta)+i*A*sin(theta) beside
the real-part calculation, so the projection can be checked without backtracking.

Take real parts to obtain the corresponding physical derivatives. These simple
substitutions are not the derivative of an arbitrary time/space-varying envelope;
product-rule terms would then also appear. This is a linear-operation tool, not
permission to multiply complex representatives and take a real part as though
that always reproduced products of real signals.

To compare arrows with the same units, plot n_tilde, d_t n_tilde/omega=-i*n_tilde,
and d_x n_tilde/k=i*n_tilde, all in m^-3. The corresponding right-hand curves are
their real parts at the same fixed probe. Dividing does not remove the physical
multipliers from the displayed derivative equations. Temporal differentiation
rotates the normalized arrow by -pi/2; spatial differentiation by +pi/2.

Reference for the complex/real-part convention:
[MIT 2.71 lecture 12](https://ocw.mit.edu/courses/2-71-optics-spring-2009/8570547486f689a28af12509e2cb6875_MIT2_71S09_lec12.pdf).

## Functional validation

Check the real-part identity against the actual density function; the signs of
both derivative multipliers using finite differences; same-mode amplitude
addition and cancellation; phase/projection correspondence; language/slider/pause
state; replay, reduced motion, keyboard controls, page 5–6 navigation and Sphinx.
Inspect desktop and stacked narrow-screen layouts. Functional checks do not
establish educational effectiveness; learner interpretation remains to evaluate.
For the two algebra stages, also check forward/backward/replay, language switching,
hidden animation controls, complete text alternatives and formula wrapping.
