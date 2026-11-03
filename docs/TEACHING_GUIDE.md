# Teaching design for AlgoPlasma explanations

Adopted 2026-11-03. Use this guide when creating or substantially revising
explanations, derivations, examples, figures, or interactive demonstrations.
It complements [the documentation guide](DOCUMENTATION_GUIDE.md) and
[the Codex development guide](CODEX_DEVELOPMENT_GUIDE.md).

The purpose is to help a reader build, use, and check a scientific explanation.
Readable pages and functioning controls are necessary, but do not demonstrate
learning by themselves. These are evidence-informed project defaults, not an
international certification, a rigid lesson template, or proof that a particular
AlgoPlasma page improves learning. Adapt them to the reader and task. Do not
turn a reference/API page into a course or rewrite unrelated modules.

## 1. Evidence and its limits

The references below are research articles, research syntheses, or accounts by
the developers of the relevant framework. They do not all provide the same type
of evidence. The rightmost column is our application to this project.

| Research basis | What it supports; important limit | AlgoPlasma application |
| --- | --- | --- |
| Constructive alignment, Biggs [1] | Align intended capabilities, learning activities and assessment. This is a design framework, not a universal experiment proving one page sequence. | Decide what the reader should be able to explain, calculate or distinguish; make the example and a small check exercise that capability. |
| Rosenshine [2]; worked examples, Sweller and Cooper [3] | Small steps, modeling, guided practice and checks; the algebra experiments found benefits especially on structurally similar problems. This is not evidence of automatic far transfer to plasma physics. | Show a complete minimal example before a general derivation; later remove some support and change the context. |
| Multimedia learning, Mayer and Moreno [4] | Limited processing capacity motivates pretraining, segmentation, signaling and keeping related information together. A principle depends on material and learner. | Introduce required objects before combining them; place the relevant explanation beside the formula or plotted feature. |
| Noetel et al. [5] | An overview of 29 reviews covering 1,189 studies supports several multimedia design principles. Effects vary with complexity and pacing; self-paced websites differ from lectures. | Prioritize clear correspondence, useful cues and manageable steps. Do not infer that every animation or redundant text block will help. |
| ICAP, Chi and Wylie [6] | Distinguishes passive, active, constructive and interactive engagement by what learners actually do. Clicking or selecting is not automatically constructive; interactive means substantive reciprocal contributions. | Ask for a prediction or explanation, then supply feedback. A slider is an interface, not a learning outcome. |
| Guided discovery, Alfieri et al. [7] | Two meta-analyses distinguish unsupported discovery from discovery with guidance. Guidance, feedback and explanation prompts matter. | Give a focused investigation and interpretable defaults before offering open exploration. |
| Retrieval and distributed practice, Dunlosky et al. [8] | Practice testing and distributed practice were rated highly useful in the reviewed evidence. Recall of a definition does not alone establish reasoning or transfer. | Offer brief, optional recall/application checks with answers; revisit essential distinctions in later applications. |
| PhET, Wieman et al. [9] | Research-based simulations connect manipulable variables with visible representations and measurements. This project report does not validate arbitrary interactive widgets. | Make an otherwise hard-to-see relation inspectable; test whether readers interpret the picture as intended. |

## 2. Plan the dependency chain before writing

Keep a short author note, outside the public explanation, containing:

1. **Reader:** likely mathematical/physical background and unfamiliar concepts.
2. **Destination:** usually one to three observable capabilities, not “understand
   everything about turbulence.” For example: distinguish phase rotation from
   amplitude change and calculate each from a specified complex coefficient.
3. **Prerequisites:** only what this destination actually requires. Link prior
   explanations; briefly reactivate a prerequisite at the point of use.
4. **Dependency chain:** each new statement uses quantities already introduced.
   A glossary at the end does not repair an unexplained symbol at first use.
5. **Evidence of understanding:** a prediction, calculation, comparison or
   explanation the reader could perform on a changed example.

Use this flexible progression for conceptual and derivation pages:

**Concrete question or observable result → minimal picture/example → quantities
and relations → equation/algorithm → worked interpretation → changed case and
limits → next connection.**

This sequence is a project synthesis, not a separately validated teaching model.
It may repeat within a long page. Preserve connected prose; do not mechanically
turn every question into a separate card. A data-analysis page can show a result
early, provided it immediately explains the observable and does not presume
unknown notation. A reference page should instead lead with a usable contract.

Before each section, ask: “What can the reader know now, and why does the next
step follow?” Replace a jump with the missing bridge, not another definition list.

## 3. Explain equations as decisions and relationships

- State the physical or computational question before introducing its notation.
- Introduce each symbol, index, operator and unit where it first matters. Explain
  whether a label selects a wave, a probe, a frequency bin or a realization.
- Give an intuitive case, then formalize it. For a generalization, say what is
  being changed: one dimension to three, one pair to a sum, or one sample to an
  ensemble. Do not change all of these without a bridge.
- Identify the source equation and the operation: substitute, differentiate,
  integrate by parts, average, approximate, or normalize. Explain why it is valid.
- Keep assumptions that determine the main conclusion visible. Put routine
  intermediate algebra in an optional expansion only if the unexpanded argument
  still makes sense. When the objective is the derivation itself, its essential
  reasoning belongs in the main path.
- Follow a new formula with what it predicts in a simple case and a unit/sign or
  limiting-case check. Distinguish “theory says,” “we assume,” and “data show.”
- For source-paper comparisons, show the local equation, the original equation
  and the symbol/convention mapping together. Preserve stable links and existing
  equation identifiers; use the relevant module's numbering policy.
- Map mathematics to code with the same symbols and explicit normalization.
  Explain array axes and shapes when needed; avoid incidental implementation
  details until they help use or reproduce the calculation.

## 4. Decide what a figure is supposed to teach

Choose the simplest representation that answers the intended question.

| Question | Usually useful representation |
| --- | --- |
| What are the parts, positions and directions? | Labeled static schematic. |
| How do two cases differ? | Static side-by-side plots with comparable scales. |
| What changes as one parameter changes? | Linked plots with one focused control and a stated observation task. |
| How does a process evolve in time? | Controllable animation plus key frames or a trail when comparison over time matters. |
| Which derivation step produces which term? | Aligned equations or a step reveal; motion is usually unnecessary. |

Every scientific figure needs a local reading path:

**What is shown → axes/symbols/units → which feature to inspect → what that feature
means → what it does not establish.**

Use formula symbols on axes where they identify the plotted quantity. Make the
observable, normalization, bandwidth and statistical aggregation clear. Color
should identify a quantity or relation consistently, with a redundant label or
line style. A symbol used in an equation should not silently change meaning in
a figure. Keep essential legends and explanations near their target.

Label measured data, analytical calculations, numerical models and illustrative
simulations distinctly. If a display rescales time, exaggerates a displacement
or uses arbitrary units, say so. Attractive visuals do not justify an inference.

## 5. Design an interaction around a reasoning task

For each widget, record what uncertainty it resolves. A useful pattern is:

**Predict → change a parameter → observe a relevant feature → explain → compare
with feedback.**

This is our implementation pattern, informed by [6], [7] and [9], not a claim
that this exact interface sequence has been validated for AlgoPlasma.

Start with a meaningful state and a focused task. Reveal extra controls when
they become useful; do not expose every model parameter at once. Show the actual
equation, parameter values and units used by the display. Provide reset and
comparison states. Animation should normally start paused and support pause,
replay and a time/step control where appropriate. Avoid changing essential text
faster than it can be read.

Keyboard operation, readable labels, reduced-motion support and a static/text
alternative are project accessibility defaults. A scientific explanation must
remain usable without mouse dragging. No audio narration is required merely to
invoke a multimedia principle; if audio exists, provide accessible alternatives.

For optional questions, reveal both the answer and the reason, including a likely
misconception. Do not block the rest of the article behind a quiz. Use later pages
to revisit a core distinction in a new context. This is spaced reuse, not a
requirement to install a spaced-repetition system.

## 6. Use expandable details without breaking the argument

Expandable details are an interface choice. The cited research does not establish
that an HTML `details` element itself improves learning. Use them to support
different needs while preserving a complete default reading path.

| Keep visible | May be collapsed |
| --- | --- |
| Page purpose and the bridge from the previous result | A reminder of a prerequisite already linked and not needed by every reader |
| Required symbol meanings and the central equation | Routine algebra, an alternative derivation or implementation detail |
| Assumptions that determine a conclusion and significant uncertainty | A deeper extension whose omission does not invalidate that conclusion |
| The primary result, how to read its figure and the main interpretation | An optional self-check answer or additional parameter case |

Name each disclosure by the question it answers, such as “Why does the derivative
contain a spatial term?” Give prerequisite hints for advanced material. Avoid
deep nesting and arbitrary length thresholds. Test the page with every optional
disclosure closed: a newcomer in the stated audience should still follow the
argument. Equation links into collapsed content should open the necessary panel.
Also test expanded layout, keyboard focus and narrow screens.

## 7. Example authoring brief: phase rotation versus growth

This is a proposed teaching design, not a change to an existing K05 analysis.

- **Question:** Does a changed complex coefficient necessarily indicate growth?
- **Starting case:** A sinusoid with fixed height whose phase shifts. Identify
  height and phase before introducing the complex plane.
- **Equation:** Write `L = a exp(i theta)` with `a = |L|`, and explain that these
  are an illustrative amplitude multiplier and phase angle, not automatically an
  inferred physical growth rate in the two-probe experiment.
- **Picture:** Link a sinusoidal trace with a complex-plane arrow. Turning the
  phase control rotates the arrow while leaving its length and wave height fixed.
  Changing `a` changes both length and height. Label the same symbols in both.
- **Prompt:** Before changing phase, predict whether `|L|` and `Re(L)` stay fixed.
  Then explain why the real part alone can mislead.
- **Feedback:** `Re(L) = a cos(theta)`, so it can decrease without a change in
  amplitude. Phase removal and model assumptions are needed before connecting
  the illustration to diagnostic growth.
- **Details:** Place the Euler-identity reminder in an optional panel; keep the
  experimental interpretation limit visible.
- **Transfer check:** Give a different phase and ask which quantity diagnoses
  amplitude change. In the later data page, revisit why a fitted `|L|` alone is
  still insufficient when quadratic terms, response differences and residuals exist.

## 8. Review before delivery

Review the reasoning, not merely whether a feature exists:

- Can the reader state what question this page answers?
- Does every essential concept have an earlier introduction or a short bridge?
- Is there a complete example where a new method needs one?
- Can the reader match the figure's quantities to the equations and code?
- Does each interaction have a meaningful reasoning task and feedback?
- With optional details closed, is the main chain intact?
- Are conditions, units, sign conventions and evidence limits visible at use?
- Is there a way to check application to a changed case, beyond recognizing prose?
- Are both language views complete, with pure English in the English view and
  Chinese explanations optionally including English technical terms?
- Do equations, links, controls, static alternatives and expanded layouts work?

Run the appropriate build and scoped checks when public pages/assets change.
For maintainer-guide-only edits, check links, consistency and the diff; a solver
test does not validate teaching quality. Do not claim a formal learning evaluation
from an author review. When a willing reader is available, observe where they
hesitate and whether they can explain or apply the central idea without the text.
Use that evidence to revise the page. Do not use click counts or reported liking
as a substitute for demonstrated understanding.

## References and recommended reading order

For immediate authoring, start with [2] and [4]; use [5] to check the broader
multimedia evidence, [9] for simulation design, and [6] to examine what the reader
actually does. The following records were checked on 2026-11-03. They are a
selected reading set, not an exhaustive or newest-only literature review.

1. Biggs, J. (1996). *Enhancing teaching through constructive alignment*.
   Higher Education, 32, 347–364.
   [DOI](https://doi.org/10.1007/BF00138871),
   [article copy](https://teaching.helsinki.fi/system/files/inline-files/Biggs1996_Article_EnhancingTeachingThroughConstr.pdf).
2. Rosenshine, B. (2012). *Principles of Instruction: Research-Based Strategies
   That All Teachers Should Know*. American Educator, 36(1), 12–19, 39.
   [Publisher PDF](https://www.aft.org/sites/default/files/Rosenshine.pdf).
   Research synthesis for practitioners, not a single controlled trial.
3. Sweller, J., & Cooper, G. A. (1985). *The Use of Worked Examples as a Substitute
   for Problem Solving in Learning Algebra*. Cognition and Instruction, 2(1), 59–89.
   [DOI](https://doi.org/10.1207/s1532690xci0201_3),
   [article copy](https://onderwijs.felienne.nl/vakdidactiek/materiaal/sweller_worked_examples.pdf).
4. Mayer, R. E., & Moreno, R. (2003). *Nine Ways to Reduce Cognitive Load in
   Multimedia Learning*. Educational Psychologist, 38(1), 43–52.
   [DOI](https://doi.org/10.1207/S15326985EP3801_6),
   [article copy](https://carpentries.github.io/instructor-training/files/papers/mayer-reduce-cognitive-load-2003.pdf).
5. Noetel, M., et al. (2022). *Multimedia Design for Learning: An Overview of
   Reviews With Meta-Meta-Analysis*. Review of Educational Research, 92(3), 413–454.
   [Publisher article](https://journals.sagepub.com/doi/10.3102/00346543211052329).
   Published online in 2021; the journal issue is 2022. Scope/result statement
   above was checked against the publisher abstract, not a full risk-of-bias reanalysis.
6. Chi, M. T. H., & Wylie, R. (2014). *The ICAP Framework: Linking Cognitive
   Engagement to Active Learning Outcomes*. Educational Psychologist, 49(4), 219–243.
   [DOI](https://doi.org/10.1080/00461520.2014.965823),
   [authors' institutional copy](https://education.asu.edu/sites/default/files/lcl/chiwylie2014icap_2.pdf).
7. Alfieri, L., Brooks, P. J., Aldrich, N. J., & Tenenbaum, H. R. (2011).
   *Does Discovery-Based Instruction Enhance Learning?* Journal of Educational
   Psychology, 103(1), 1–18.
   [DOI](https://doi.org/10.1037/a0021017),
   [article copy](https://app.nova.edu/toolbox/instructionalproducts/edd8124/articles/2011-Alfieri_et_al.pdf).
8. Dunlosky, J., Rawson, K. A., Marsh, E. J., Nathan, M. J., & Willingham, D. T.
   (2013). *Improving Students' Learning With Effective Learning Techniques:
   Promising Directions From Cognitive and Educational Psychology*.
   Psychological Science in the Public Interest, 14(1), 4–58.
   [DOI](https://doi.org/10.1177/1529100612453266),
   [publisher summary/abstract](https://www.psychologicalscience.org/journals/pspi/1529100612453266/).
   Utility ratings above were checked in the publisher's detailed abstract.
9. Wieman, C. E., Adams, W. K., & Perkins, K. K. (2008). *PhET: Simulations That
   Enhance Learning*. Science, 322(5902), 682–683.
   [DOI](https://doi.org/10.1126/science.1161948),
   [authors' project PDF](https://phet.colorado.edu/phet-dist/publications/PhET_Simulations_That_Enhance_Learning.pdf).

For a new specialist teaching claim, consult its source and relevant newer
evidence rather than treating this list as blanket support. Avoid unsupported
retention percentages, fixed rules for the number of concepts per screen, or
claims that a medium guarantees learning. Accessibility choices, disclosure
policy and the proposed page sequence are explicit project design decisions.
