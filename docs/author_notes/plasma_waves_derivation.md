# Lesson 09: deriving the first dispersion relation

## Teaching chain

- Reader: knows the continuity equation, density perturbations, k and omega with
  units, complex amplitudes, derivative substitutions from lesson 06, and the
  dispersion plots in 07–08.
- Destination: derive the cold-electron relation from a specified physical model,
  explain why a nonzero mode imposes a compatibility condition, and recover the
  earlier warm-fluid example after explicitly adding a pressure closure.
- Fifteen independent slides, 32 builds. Short explanations accumulate in the
  same working panel; longer sequences are divided into explicit panel groups.
  Each new slide starts clean and paused. Equations occupy centered blocks with
  stacked fractions. Intermediate substitutions and cancellations are written out.
- Route: question → model → continuity → momentum → Poisson → linearization →
  plane waves → elimination → cold result → restoring-sign check → pressure
  closure → warm result → parameter prediction → candidate-mode check.
- The initial density animation connects the algebra to a familiar plasma wave.
  Two wavelengths are compared after the cold result. These are separate cases,
  not two populations or a superposition.
- The parameter interaction asks learners to predict the square-root density
  scaling before moving the slider, then add pressure. The final question asks
  whether a drawn sinusoid can satisfy all three equations with a nonzero amplitude.
  Answers are revealed with the same next-step button; there is no quiz gate.

## Physical model and derivation

One-dimensional, uniform, unmagnetized, collisionless electrons; fixed singly
charged ions of density n0; longitudinal electrostatic perturbations. The
initial equilibrium is n=n0, v=0, E=0. Electrons have charge -e with e>0.
Cold electrons initially have no pressure force. Small perturbations give:

    partial_t n1 + n0 partial_x v1 = 0
    me partial_t v1 = -e E1
    partial_x E1 = -e n1 / epsilon0

The density excess is negative charge, not a quasineutral perturbation. Terms
n1*v1 and v1*partial_x v1 are second order and are explicitly discarded.
Using constant complex amplitudes (N,V,calE) times exp[i(kx-omega*t)], with
k>0, gives V=omega*N/(k*n0) and calE=i*e*N/(k*epsilon0). Substitution into
momentum yields (omega^2-omega_pe^2)*N=0. A nonzero N requires:

    omega_pe^2 = n0*e^2/(me*epsilon0)
    omega = +/- omega_pe

The animation selects the positive-frequency branch. A separate elimination
in real space gives partial_tt n1 + omega_pe^2*n1=0 and checks the restoring
sign. The horizontal cold branch is not the nondispersive omega=V*k comparison:
its phase speed varies with k, although its group speed is zero.

For warm electrons, pressure adds -(1/n0)*partial_x p1 to the force per electron.
The background pressure is uniform. The density correction in 1/n multiplies
the pressure perturbation and is second order. Specify a local closure:

    p1 = me*u^2*n1
    u^2 = (1/me)*(dp/dn)_0
    omega^2 = omega_pe^2 + u^2*k^2

No universal temperature coefficient is asserted. Relating u to temperature
requires a particular pressure closure and its applicability assumptions.
The example omega_pe=1e8 rad/s and u=1e6 m/s reconnects to 07–08. This fluid
model excludes collisions and Landau damping. The plotted intercept denotes
the long-wavelength limit k→0, since amplitude elimination used k>0.

Units are given for density [m^-3], mean velocity and u [m/s], field [V/m],
pressure [Pa], charge [C], mass [kg], permittivity [F/m], k [rad/m], omega
[rad/s] and ordinary frequency [Hz]. Squared frequencies have units s^-2.

## Animation and numerical values

The dependency-free model is in wave-derivation-model.js. Constants are e,
me and epsilon0 in SI. W0=1e8 rad/s sets NREF≈3.142e12 m^-3. The relative
amplitude is a=0.08. The density view spans x=0…0.24 m, with k=60 rad/m;
the comparison adds a separate k=120 rad/m case at the same time.

    n1 = a*n0*cos(theta)
    v1 = omega*a/k*cos(theta)
    E1 = -e*a*n0/(epsilon0*k)*sin(theta)
    p1 = me*u^2*a*n0*cos(theta)
    theta = k*x - omega*t

These fields satisfy the linear equations, including the pressure term. Dots
solve q=x+a/k*sin(k*x-W0*t), a monotone density map since 1+a*cos(theta)>0.
They visualize the prescribed density; they are not force-integrated particles
or a nonlinear fluid solution. Rows repeat the same one-dimensional map.

Playback advances physical time by 3e-8 s per real second and loops over one
cold period 2*pi/W0≈6.28e-8 s. Both scale and loop are disclosed. Scrubbing
pauses playback. The two cases have different wavelengths and phase speeds,
but the same cold oscillation frequency.

The density control selects 1…4 times NREF. Each setting represents a different
neutral equilibrium; the ion and electron backgrounds change together. Pressure
is a separate checkbox with u=1e6 m/s. Its dashed reference is the cold branch
at the currently selected density, not at a different background density.

## Interaction and accessibility

Chinese and English are synchronized. Language switching preserves slide,
build, time, pause and parameter state. Links retain language and deep links
identify the slide/build. Lesson 08 links forward to 09; the course directory
has a short bilingual summary. Restart slide resets the current slide to its
first build and entry defaults. Restart lesson returns to slide 1 while
preserving language. Only explicit buttons advance/backtrack; images and global
arrow/PageUp/PageDown/Space keys do not advance. Native button activation remains.

Large, semibold text and high-contrast annotations follow the lesson 08 shell.
Reduced motion disables transition effects. A no-canvas message and a bilingual
no-JavaScript derivation provide alternatives. The SVG chart remains available
without canvas support. No external script, rendering service or math CDN is used.

## References and validation

Primary background references linked in the final slide:

- [MIT Introduction to Plasma Physics](https://silas.psfc.mit.edu/introplasma/master.pdf)
- [Princeton AST 553 lecture notes](https://www.princeton.edu/~idodin/ast553/main.pdf)

Run: node docs/tests/test_wave_derivation.cjs

The test uses independent centered finite differences of the analytic fields
at multiple k, densities, pressure parameters, positions and times. It checks
continuity, momentum (including pressure), and the Poisson sign, plus frequency
scaling, positive density and the conservative visualization map.

Verified on 2026-11-19: numerical checks passed. All 33 states in both languages
were inspected at 320, 768, 1440 and 1920 px (264 views), followed by targeted
checks after the pressure wording and SVG visibility/layout fixes. No horizontal
or equation overflow, Chinese text leakage into English, or runtime errors.
Checked image/global-key inactivity, native Enter, next/back, both resets,
deep links, playback/loop/scrub, parameter and language-state preservation,
pressure/cold chart comparison, reduced motion and both fallbacks. The lesson
08 header was rechecked at narrow width with its newly enabled next-lesson link.
These checks establish implementation and model consistency, not measured
teaching effectiveness.

Final integration: Sphinx built without warnings. Both language variants of
all nine lessons passed previous/next link checks; both directory entries open
09 in the selected language.

## Reader-facing pacing revision, 2026-11-19

Removed the aside about needing no Hall-thruster background. The model description
now addresses the wave itself in both languages. Continuity is an assumed
prerequisite: slide 3 states the equation, units and its place in the system,
without the control-volume/flux-difference derivation. Other slide numbers remain
stable; an old slide-3-step-2 link resolves to its single equation step.

Slides now retain short context and append the next block below it, including
model assumptions plus variable definitions, plane-wave substitution, and the
pressure closure. The linear-system summary uses a new panel; elimination, the
warm result and the final question keep their first two blocks together and
use a separate panel for the concluding block. This avoids both unnecessary
clearing and accumulating the entire lesson on one screen.

The renderer keeps unchanged block nodes, heading text and diagram nodes. Only
new or replaced content fades in over 850 ms with a 6 px rise; there is no
whole-main animation. Within-slide reveals keep the scroll position when the
new block is visible, scrolling to the new material only when necessary.
Reduced motion disables these effects. The live announcement reports the
current step rather than rereading all retained content.

The two-wavelength comparison uses separate canvases. The k=60 rad/m plot has
the same dimensions and coordinates in both builds; only the k=120 rad/m plot
is appended and animated. Both use the original physical model and shared time.
Parameter changes and step reveals preserve the existing dispersion chart when
its data have not changed. No model or numerical parameters were changed.

Verification: all 32 states in both languages at 320, 768, 1440 and 1920 px
(256 views) passed horizontal/equation overflow and language checks. Across
34 bilingual transitions, retained blocks and unchanged title/narration nodes
stayed identical, while animation targets were limited to new/replaced content.
The first comparison canvas remained pixel-identical and at the same position
after adding the second; the unchanged SVG branch retained its node. Checked
button-only navigation, native Enter, both canvases during playback and scrubbing,
period wrap, language/parameter state, both resets, and reduced motion.
All 30 bilingual slide-reset cases, panel backtracking and no-canvas/no-script
alternatives passed. Sphinx built without warnings; generated assets match
the source and the built bilingual model slide preserves both revealed blocks.

## Concept-order and audience revision, 2026-11-19

Reviewed all lesson text against the reader prerequisites. Removed mentions of
collisions, Landau damping, kinetic theory, resonance and future model extensions
from both language versions and the no-JavaScript alternative. The physical
model and its assumptions remain documented above for maintainers; the public
explanation stays with the equations and forces actually used in this lesson.

The opening defines cold electrons by neglecting pressure instead of listing
several new model labels. Replaced closure, eigenfrequency, trivial solution and
other unnecessary terminology with their concrete meanings in this derivation.
The pressure step introduces p and its units, then explains the proportional
pressure–density relation and the slope evaluated at n0. No temperature-closure
caveat or growth/damping detour interrupts the argument. Diagram captions say
what the dot spacing and dashed curve show.

The final build now reviews the two derived dispersion relations and their
shared compatibility requirement, followed by references. It contains no
author-facing development roadmap. Slide/build numbers, equations in the
derivation, numerical model and incremental-reveal behavior are unchanged.

Checked all 32 states in both languages at 320, 768, 1440 and 1920 px (256
views): no horizontal/equation overflow, Chinese prose in English, runtime
errors, or remaining occurrences of the removed advanced terminology in the
public lesson. Visually reviewed the pressure explanation and final recap.
Sphinx built without warnings. Generated assets match source; checked the
built bilingual recap/restart and the no-JavaScript text alternative.
