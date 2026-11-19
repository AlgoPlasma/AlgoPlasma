# Lesson 06: wave packets, phase and group velocities

## Teaching chain

- Reader: understands density waves, k/omega and units, linear superposition,
  complex amplitudes, and the lesson 05 origin-to-point phase-speed construction.
- Destination: distinguish inner phase from the packet envelope; match their
  motions to origin-ray and tangent slopes; recognize the narrow-band condition.
- Fourteen independent slides, each with two to four builds. Forward navigation
  reveals one block within a slide, then clears the explanation for the next slide.
  Course navigation and slide navigation are labeled separately.
- Reasoning task: compare whether the two markers stay together when the branch
  is changed to omega=V*k, then explain the slopes using one checkbox.
  The time scrubber pauses the animation. Playback starts paused; users can
  also inspect every state without playing or dragging.
- The two-wave derivation occupies its own slides after the group-speed view. It gives
  the sum-to-product identity, modulation-phase condition, difference quotient
  and derivative limit, with symbol definitions and units. It explicitly
  distinguishes a periodic two-wave beat envelope from a localized packet.
- Keep all explanation/units large and semibold; preserve language, time,
  pause and comparison state on language changes. No quiz gate or new framework.

## Specified physical model

The base branch is the lesson 05 unmagnetized warm-electron fluid approximation,
with fixed ions and no collisional/kinetic damping:

    omega(k) = sqrt(W0^2 + U^2 k^2)
    W0 = 1e8 rad/s, U = 1e6 m/s
    kc = 60 rad/m, sigma_k = 6 rad/m
    k_j = 42 + 1.2*j rad/m, j = 0 ... 30
    a_j = 0.18 * exp[-(k_j-kc)^2/(2 sigma_k^2)] / sum(weights)
    z(x,t) = sum a_j exp[i(k_j*x - omega_j*t)]
    delta_n/n0 = Re(z), envelope = |z|

All initial phases are zero; a_j=A_j/n0 is dimensionless. The sum of amplitudes
is 0.18, so density is at least 0.82 n0. This is a prescribed linear density
field, not a nonlinear fluid calculation or a particle-force solver. Electron
thermal motion is not drawn; pressure enters the dispersion law.

The physical viewing window is -0.5 ... 0.9 m. The discrete k spacing gives a
spatial repetition period 2*pi/1.2 = 5.236 m, well outside the one-packet view.
The spectrum and animation slides disclose all weights and this repetition. Each component
uses the full dispersion frequency, not a manually translated Gaussian.

The central phase marker follows x=(omega_c/kc)*t exactly. It approximately
follows an inner density crest in this narrow-band packet; it is not an electron.
The blue ring locates the maximum of |z| by a bounded search near vg*t. It is
not forced to move at vg. The agreement between its measured motion and
vg=domega/dk at kc is approximate. Full-frequency superposition retains the
small higher-order deformation, rather than claiming an exactly rigid envelope.

The comparison replaces omega_j by V*k_j, V=omega_c/kc, preserving the central
frequency, phase speed, spectrum, amplitudes, initial phases and time scale.
Both envelope and phase then translate exactly at V. This is explicitly a
mathematical comparison, not an additional plasma branch. The tangent and ray
coincide; solid gold and dashed blue distinguish the coincident constructions.

Internal animation time tau=W0*t advances by 3 per playback second, so one
playback second represents 3e-8 s. It loops over 0 ... 2e-7 s, with this reset
disclosed in the caption/details. The scrubber displays SI seconds.

Dots solve q=x+sum(a_j/k_j sin(k_j*x-omega_j*t)) for x. Its derivative is
n/n0>0, so the map is monotone and conserves the prescribed density. Rows are
schematic repetitions of the same one-dimensional solution. Each particle is
solved once per frame, then reused in the rows; their displacements are not
added as separate electron populations. This mapping does not prove a
self-consistent nonlinear particle/fluid solution.

## References and scope

[David Morin, Dispersion, section 6.3](https://bpb-us-e1.wpmucdn.com/sites.harvard.edu/dist/0/550/files/2023/11/waves_dispersion.pdf)
supports phase/group geometry and the two-component derivation.
[MIT Introduction to Plasma Physics](https://silas.psfc.mit.edu/introplasma/master.pdf)
provides the warm-electron fluid background used on lesson 05. The finite spectrum,
playback parameters and slide sequence are local teaching choices.

Group speed is not equated universally with electron, energy or information
speed. The base example has vg<vph; other dispersion laws need not. Broader
bands, strong deformation, negative velocities and full packet spreading can
be developed in later independent lessons.

## Verification

Run `node docs/tests/test_wave_packet.cjs` for dispersion-derivative, spectral
normalization, density positivity, conservative dot mapping, envelope peak and
nondispersive shape-translation checks. The envelope-speed comparison allows
1% for the actual finite spectrum, rather than asserting exact equality.
Also check bilingual reveals, scrubbing, play/pause/loop, comparison and state
preservation, disclosure layout, navigation and no-canvas/no-script alternatives.
Build/interaction checks do not establish measured teaching effectiveness.

Verified on 2026-11-18: the dependency-free model test passed. The finite-spectrum
envelope moved at 513101.7 m/s over the displayed interval, versus the central
derivative 514495.8 m/s (about 0.27% difference); the nondispersive packet
passed exact-translation checks. All six stages in both languages passed at
320, 768, 1280, 1440 and 1920 px widths, including both details expanded.
Screen marker coordinates and SVG slopes were checked at three times on both
branches. Playback wrap, time scrubbing, keyboard controls, language-state
preservation, replay, all eight-page navigation links, bilingual directory and
no-canvas/no-JavaScript fallbacks passed. Sphinx completed without warnings.

Readability revision on 2026-11-19: reorganized both bilingual disclosures into
short explanatory sections. Main equations now occupy centered blocks; ratios
use stacked fractions with an accessible slash. Added the complex-sum
factorization to explain the existing narrow-band approximation. The
nondispersive comparison opens with the concise phase-speed definition of
dispersion requested by the user. Animation/model code is unchanged.
Checked both expanded panels at 320, 768, 1440 and 1920 px in both languages:
no horizontal overflow, centered equations, readable wrapping, and preserved
time, pause/comparison and disclosure state on language switching. Sphinx
completed without warnings.

## Slide-deck revision, 2026-11-19

The previous cumulative scene and repeated long disclosures made new content
hard to distinguish. Lesson 08 now has a dedicated deck controller; shared
lesson controls and the physics model are unchanged. Its 14 slides cover:

1. Packet and envelope.
2. Central phase and phase speed.
3. Envelope motion and group speed.
4. Two-wave sum-to-product identity.
5. Fixed modulation phase and the derivative limit.
6. Origin ray and tangent, drawn separately.
7. Warm-fluid model and the evaluated derivative.
8. The 31-component spectrum and amplitude weights.
9. Real and complex sums; envelope modulus.
10. First-order frequency expansion and phase splitting.
11. Factoring the carrier and reading envelope translation; approximation limits.
12. Nondispersive comparison, preserving the requested one-sentence definition.
13. Density mapping, positivity, physical time and viewing window.
14. A changed-slope prediction with answer/reason and references.

Each new slide starts paused with only its first block. Previous-slide content
is removed from the DOM. Within-slide builds fade in with a mint edge; reduced
motion disables the effect. Separate slide/build counters and action labels
make the transition explicit. The footer remains reachable on narrow screens,
and a newly revealed block scrolls into view when needed. Direct links preserve
slide/build in the hash; language switches preserve slide, build, time, pause
and comparison state. Backtracking reverses builds and returns to the previous
slide at its completed state. No repeated disclosure remains.

Verified: all 34 presentation states in Chinese and English at 320, 768,
1440 and 1920 px widths (272 views); no horizontal or equation overflow,
no Chinese text leakage into English, and no stale disclosure/content.
Checked next/back/replay, separate slope reveals, 31 spectral lines, paused
entry, scrubbing, playback wrap, language-state preservation, deep links,
reduced-motion and animated builds, and no-canvas/no-JavaScript fallbacks.
The original dependency-free packet physics test passed. Sphinx completed
without warnings. Browser checks verify implementation, not learning outcomes.

Navigation refinement, 2026-11-19: advancing and backing up now use explicit
buttons only. Canvas clicks and global arrow/PageUp/PageDown/Space shortcuts
do not change the slide or build; native keyboard activation of focused buttons
is retained. The bilingual Restart slide button restores the current slide
to build 0 and its entry time/comparison defaults, pauses playback, and scrolls
to its opening. Canvas uses the default cursor. Checked image/plot clicks,
non-button keys, button activation, running-state reset, all 14 slide restarts
in both languages, and 72 footer layouts at 320–1920 px without overlap or
horizontal overflow. Sphinx built without warnings.

Lesson restart, 2026-11-19: added a bilingual Restart lesson button beside
the slide counter. It restores slide 1/build 1, time zero, the original
dispersion branch and paused playback while preserving language. Restart slide
remains separate. Checked restart from the opening, comparison and final slides
in both languages, including active playback, and 48 footer layouts across
320–1920 px. Image clicks still do not advance. Sphinx built without warnings.

## Derivation and wide-window revision, 2026-11-19

Keep all 14 slide numbers. Slides 4, 10 and 13 now use four working panels
on the same slide; each panel replaces the previous one to retain large type
and a clean reading path. Other slides retain cumulative builds.

- Slide 4: define the two phases, express them as mean plus/minus half-difference,
  expand the cosine sum/difference identities, cancel sine terms, and substitute
  the wave variables to obtain the beat-envelope product.
- Slide 10: motivate the approximation from the exact complex sum and the goal
  of identifying an envelope depending on x-vg*t. Show Taylor terms explicitly,
  retain first order, substitute the approximation for omega_j into theta_j,
  then add/subtract kc*x and factor. Full omega_j still drives the animation.
- Slide 13: retain the dot-density/time explanation, then widen the observation
  window to [-6.5,6.5] m with the original [-0.5,0.9] m window highlighted and
  magnified below. Both plots directly sample the same 31 modes at the same
  time; no copied picture or extra wave populations are introduced.

The spacing is L=2*pi/1.2=5.235987756 m. For this spectrum, k_j=(35+j)*1.2,
so every complex component gains an integer multiple of 2*pi over L. Both
the real density and envelope repeat exactly at every time. This is a property
of this uniformly sampled spectrum, not a requirement for all physical packets.
The wide plot uses 2401 samples to resolve the model before screen compression;
the local view resolves the inner crests. Playback retains the original rate
and time interval, with pause/scrub, language preservation, and both resets.

Validation: physics tests and new spatial-period checks passed for real part,
imaginary part and envelope at multiple positions/times and shifts +/-L. All
40 states in both languages at 320, 768, 1440 and 1920 px were checked (320
views), with no horizontal/equation overflow or language leakage. Verified
replacement panels, next/back, unchanged slide numbering, image-click inactivity,
time continuity between local/wide views, animated redraw, language state and
slide/lesson reset. Sphinx built without warnings.
