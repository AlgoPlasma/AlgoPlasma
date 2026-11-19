# Plasma waves: opening slide author brief

- Reader: a newcomer who knows that a plasma contains electrons and ions. No
  oscillator analogy, wave equation, Fourier analysis or dispersion relation is required.
- Destination: distinguish the local motion of an electron from the motion of a
  density pattern, using the same animated plasma picture.
- Dependency chain: uniform electron background -> ordered displacement -> track
  one electron -> track a dense region -> compare the two motions.
- Check: before highlighting the dense region, ask whether the tracked electron
  will travel through the plasma with the wave. The final comparison supplies
  feedback without adding quiz controls to the opening slide.
- Next connection: why does an electron displacement produce an oscillatory response?
- Presentation: one persistent canvas, progressively added cues, large type,
  one primary advance/replay button, a back button after the first step and a
  pause/play button only while motion is relevant. Keyboard F supplies fullscreen
  without another permanent control. Initial state is static. Reduced-motion
  preference keeps the animation paused unless the reader explicitly plays it.
- Language: the Sphinx entry follows the site's bilingual containers; its two
  launch links select `?lang=zh` or `?lang=en`. A compact Chinese/EN switch on the
  slide updates all text and canvas annotations without resetting the lesson
  step, phase or pause state. It shares the site's `ap-doc-language` preference;
  an explicit URL language takes precedence. Storage/history failures are nonfatal.
- Navigation: the Sphinx entry is a directory with one linked title and one short
  summary per lesson. Explanations, units and text alternatives remain inside
  the lessons. Header links connect adjacent lessons and the contents. The footer steps through
  the current deck and has separate slide-start and lesson-start buttons. First/last
  boundaries are disabled, and language is carried by the links. The shared
  `wave-navigation.js` catalog owns page order and adjacent-page labels; each
  HTML page also includes usable Chinese navigation without JavaScript.
- Presentation readability: `wave-presentation.css` loads last on all six pages.
  Desktop captions are at least 28 px, unit/explanatory text at least 26 px,
  with weight 600 and near-white text. Phone captions remain 24 px and notes
  22 px. Parentheses distinguish figure notes without reducing their prominence.
  `wave-text.js` applies semibold canvas labels (minimum 26 px desktop, 20 px
  phone), wraps long labels and keeps their bounds inside the canvas. Page height
  may grow on dense or narrow views so text and diagrams do not overlap; do not
  shrink the teaching text to force every layout into one viewport.

## Illustration model and limits

This page prescribes collective displacement; it does not solve a plasma's
response to a localized impulse. Green points represent electron fluid markers
in a periodic one-dimensional interval. Rows repeat the same longitudinal motion
to make density changes visible. Fixed plus signs indicate the ion background.
The array is a visualization device, not a claim that plasma particles form a lattice.

For equilibrium coordinate q in an interval of display length L:

    x(q, tau) = q + a sin(k q - tau), periodically wrapped into [0, L)
    k L = 4 pi; a / L = 0.028; k a = 0.352 < 1
    n(x(q), tau) / n0 = 1 / [1 + k a cos(k q - tau)]

The tracked dense region has `k q - tau = pi`, hence zero displacement at its
center and maximum density. Its center moves right as tau increases. The same
electron label always retains its q and oscillates within q +/- a. There is no
fluid-element crossing. Density varies because marker spacing varies; the
highlight follows a density maximum rather than an arbitrarily moving overlay.

`tau` increases by 1.12 radians per display second. Pixel lengths and animation
seconds have no SI calibration. The first click ramps the displayed amplitude
for readability; this visual transition is not an instability growth calculation.
Thermal motion, magnetic effects, damping and self-consistent fields are omitted.
The public slide states fixed ions, omitted thermal motion, the illustrative array
and slowed motion. The entry page also distinguishes this phase-motion picture
from a statement about wave-packet or energy transport.

## Integration and review

- Sphinx entry: `docs/source/learning/plasma_waves/index.rst`.
- Lesson source: `docs/source/_static/plasma_waves/01_what_moves.html` plus its CSS/JS.
- Sphinx copies these assets into the hosted `_static/plasma_waves/` directory.
- The return link is relative to the same built site, so RTD version prefixes survive.
- Do not edit generated files under `docs/build/`.
- Check all five reveals, backward navigation, replay, pause, keyboard controls,
  fullscreen, reduced motion, both languages and narrow screens in the built site.
- Browser and build checks establish implementation behavior, not learning effectiveness.
