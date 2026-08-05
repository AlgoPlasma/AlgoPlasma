# Documentation Guide

This guide defines how AlgoPlasma documentation should be split between README files,
Sphinx pages, and Fortran Doxygen comments. The current `A_Pusher`
documentation is the reference implementation for structure, bilingual
switching, and build verification.

The goal is to keep repository browsing friendly while avoiding duplicated
long-form content and preventing Chinese/English content from leaking into the
wrong language view.

## Current Documentation Philosophy

AlgoPlasma documentation is module-first. Each subroutine group should remain useful
as an independent algorithm component rather than assuming one fixed PIC driver
or one global application workflow.

For each module, document enough local context that a reader can understand:

- what algorithm the module implements;
- what public subroutines are intended to be called;
- what inputs, outputs, array shapes, index ranges, and boundary/ghost-cell
  expectations apply;
- what numerical assumptions are local to that routine or module;
- how the implementation maps the algorithm into loops, stencils, MPI calls,
  file formats, or external-library calls;
- what tests or examples demonstrate the module.

Do not force every module page to explain the whole PIC cycle. A complete
end-to-end PIC case can be documented later as a separate tutorial or example.
Module pages should still link to related local tests or examples, but the
physical coupling between all modules should not be treated as required context
for understanding a single subroutine.

Numerical assumptions should be stated where they apply, not only in a global
conventions page. AlgoPlasma modules may be reused in different programs with
different normalizations, grid locations, precision choices, MPI layouts, and
external dependencies. Repeating local assumptions in each relevant routine page
is preferred over making the reader infer them from another module.

## Documentation Layers

Use three layers, each with a clear job:

- README files: short directory-facing documentation for browsing on Gitee or
  GitHub.
- Sphinx pages: full user documentation, formulas, detailed notes, examples,
  and bilingual pages.
- Fortran Doxygen comments: API facts close to the source code, consumed by
  Sphinx through Breathe.

Do not edit `docs/build/html` directly. Edit files under `docs/source`, rebuild
HTML, and verify the generated page.

## README Files

README files should stay short and practical.

Use README files for:

- A concise purpose statement for the directory or routine group.
- A file list with each file's role.
- The public interface or main subroutine signature.
- A minimal usage example.
- Required compile options such as `-cpp`, `-fdefault-real-8`, or
  `-real-size 64`.
- Key references, but not full derivations.

Avoid putting long equation derivations, implementation notes, boundary-case
analysis, or extensive algorithm discussion in README files. Put that material
in Sphinx instead.

Directory README pairs should use:

- `README.zh-CN.md`
- `README.md`

## Sphinx Pages

Sphinx is the complete documentation layer.

Use Sphinx pages for:

- Algorithm derivations and mathematical formulas.
- Detailed parameter tables.
- Boundary cases and numerical notes.
- Full references.
- Doxygen-generated API sections.
- Bilingual page-level documentation.

Sphinx pages may repeat short interface summaries from README files, but the
long explanation should live only in Sphinx.

## Tests And Examples

Tests and examples have different audiences and should not be merged into one
concept.

Tests are maintainer-facing correctness checks. They should be small,
deterministic, automatable, and suitable for future continuous or scripted
regression runs. A good test proves one property of the implementation: a known
formula, a conservation property, a convergence rate, a boundary condition, a
restart/load round trip, or an MPI exchange rule. Test output should have a clear
pass/fail criterion and should avoid unnecessary large images or long-running
demonstrations unless the test is explicitly marked as heavyweight.

Examples are user-facing usage demonstrations. They should show how a researcher
or student calls AlgoPlasma routines in a small but readable program. An example may
reuse a test-sized problem, but its explanation should prioritize the calling
sequence, required compile options, data preparation, output interpretation, and
common modifications. Examples can include plots or saved outputs when those
outputs help users understand how to use the module.

When both exist for the same algorithm, keep the distinction visible:

- `tests/`: prove correctness and support automated regression.
- `examples/` or example-style Sphinx pages: teach usage and adaptation.
- Module pages: link to both, and state whether the current repository has only
  tests, only examples, both, or neither.

## Page Types

### Group Overview Pages

Use this pattern for a group page such as `A_Pusher.rst`:

- Page title.
- `toctree` listing child algorithm pages.
- Language switch.
- Chinese overview sections.
- English overview sections.

For top-level group pages, use two large language containers, the same pattern
used by routine and module pages. This avoids accidentally leaving a later
section outside the intended language scope.

```rst
.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 概览

   中文内容。

.. container:: ap-lang ap-lang-en

   .. rubric:: Overview

   English content.
```

Do not leave ordinary prose, tables, formulas, or generated API sections outside
one of the two language containers after the language switch.

### Algorithm, Module, and Subroutine Pages

For routine pages and module pages, prefer two large language containers. This
keeps all headings, code blocks, tables, formulas, and Doxygen output inside one
language scope.

```rst
.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块说明

   中文内容。

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Description

   English content.

   .. rubric:: Generated API

   .. doxygenfile:: example.f90
```

If a page has a language switch, every visible content block after the switch
must be inside either `ap-lang-zh` or `ap-lang-en`.

## Generated API Sections

Doxygen output is usually English and should not appear at the end of the
Chinese view unless there is a deliberate bilingual API section.

Default rule:

- Put `.. doxygenfile::`, `.. doxygenfunction::`, and similar generated API
  directives inside the English container.
- Put the `Generated API` rubric inside the same English container.
- If Chinese API notes are needed, write a short Chinese summary in the Chinese
  container and keep generated Doxygen output in English.

This matches the current A module and subroutine pages.

## Fortran Doxygen Comments

Fortran Doxygen comments should describe API facts close to the source code.

Use Doxygen comments for:

- `@brief` one-line purpose.
- `@details` only when a short implementation summary helps.
- Parameter direction, shape, units, and meaning.
- Important precision or unit assumptions that affect correct calls.

Avoid long derivations in source comments. Put those in Sphinx instead.

## Bilingual Content Rules

- Keep Chinese and English documentation as parallel content, not line-by-line
  machine translations.
- Keep terminology consistent across languages. Scientific terms may keep the
  English name when it improves clarity, for example `particle pusher`,
  `Boris`, `leapfrog`, `proper velocity`, `field solver`, and
  `density deposition scheme`.
- Use `docs/source/glossary.rst` as the shared terminology reference for common
  grid, particle, and MPI terms such as `active cell`, `guard/ghost cell`,
  `cell-centered`, `node-centered`, `CIC`, `NGP`, `Yee grid`, and `MPI rank`.
- Code identifiers, file names, module names, subroutine names, compiler flags,
  and formulas should stay identical in both languages.
- Do not leave ordinary prose outside language blocks after a language switch.
- Do not put only the first section in a language block if later sections belong
  to the same language.

## Recommended Sphinx Content

For each algorithm or subroutine page, include the relevant parts from this
checklist:

- Purpose and scope.
- Public interface.
- Parameter table with direction, shape, meaning, units/normalization when
  relevant, index range, ownership/local-domain convention, and whether ghost
  cells are required.
- Coordinate system and updated quantities.
- Mathematical formulation.
- Algorithm steps.
- Boundary cases and numerical notes.
- Precision, units, and compile assumptions.
- Minimal usage example when useful.
- References.
- Generated API section.

Keep the depth proportional to the routine. A small wrapper module may only need
a module description, usage, precision note, and generated API section.

Redundancy is acceptable when it improves local readability. Each public
subroutine page should be understandable when opened directly from search or the
API index, even if that means repeating assumptions that also appear on a group
overview page.

## Maintenance Rule

When changing an algorithm or public interface:

1. Update the Fortran Doxygen comment for API facts.
2. Update the corresponding Sphinx page for formulas and detailed explanation.
3. Update README files only if the high-level purpose, file list, interface,
   usage example, compile option, or key reference changed.
4. Rebuild the Sphinx HTML and check the rendered page.

## Build And Verification

Use the documentation environment configured for the current machine. If the
environment is unknown, ask the maintainer or user before assuming a virtualenv
path, because different contributors may use different local setups.

For example, on a machine where the documentation virtualenv is `~/.venv`:

```bash
cd docs
source ~/.venv/bin/activate
make html O="-j 16 -Q"
```

For pages with language switching, verify the generated HTML, not only the RST
source. At minimum, check that:

- The Chinese view does not end with English-only sections.
- The English view does not start with Chinese sections.
- Navigation entries hide the inactive language sections.
- `Generated API` sections are inside the intended language container.

When updating a whole module group, scan all generated HTML pages in that group
for visible text outside `ap-lang-zh` or `ap-lang-en` after the language
switch.

For the practical maintenance checklist and command ideas, see
`docs/source/maintenance_checklist.rst`.

For the Codex-oriented development workflow used when students or maintainers
extend AlgoPlasma with AI assistance, see `docs/CODEX_DEVELOPMENT_GUIDE.md`.
