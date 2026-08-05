# Codex Development Guide

This guide is for students and maintainers who use Codex while developing AlgoPlasma.
It complements `docs/DOCUMENTATION_GUIDE.md`, which defines the documentation
style.

## Working Principles

- Keep module work local. Improve the current module's algorithm explanation,
  public subroutines, local assumptions, tests, and examples without forcing a
  whole-PIC tutorial into every page.
- Do not change solver behavior during a documentation task unless the user
  explicitly asks for a code fix.
- Prefer clear repetition over hidden assumptions. A reader should be able to
  open one subroutine page and understand how to call that subroutine.
- Preserve existing public Fortran/C interfaces unless an interface change has
  been explicitly requested and reviewed.
- Treat user edits as intentional. Do not revert unrelated changes in a dirty
  worktree.

## Standard Module Deliverables

For a module or submodule update, aim to provide:

- `README.zh-CN.md` and `README.md` for short repository browsing.
- A bilingual Sphinx group or submodule page with a language switch.
- Routine/API pages with Chinese usage notes and generated Doxygen API in the
  English language block.
- A parameter table for each public subroutine: direction, shape, meaning,
  units/normalization if relevant, index range, local-domain ownership, and
  ghost-cell expectations.
- Local numerical assumptions on the page where they matter.
- Links to related tests and examples, or an explicit statement that none
  currently exist.
- A short verification note after running Sphinx and any relevant local checks.

## Tests Versus Examples

Use tests to prove correctness:

- Keep them small, deterministic, and easy to automate.
- Give each test a clear pass/fail condition.
- Prefer checking one property per test: formula agreement, convergence order,
  conservation, boundary behavior, I/O round trip, or MPI exchange.
- Avoid relying on manual image inspection for a core regression result.

Use examples to teach usage:

- Keep the program short and readable.
- Explain compile options, required dependencies, input arrays, and output
  interpretation.
- Show a realistic calling sequence without turning the example into a full
  application.
- Store plots or figures only when they help users understand how to use the
  routine.

If a current test is also the best available user example, document that
explicitly and consider splitting it later into an automated test plus a cleaner
example.

## Recommended Codex Workflow

1. Inspect the current module, tests, README files, Sphinx pages, and relevant
   source comments before editing.
2. Decide whether the task is documentation-only, test-only, example-only, or a
   code behavior change.
3. Make scoped edits using existing naming and bilingual page patterns.
4. For documentation changes, rebuild Sphinx with the environment configured for
   the current machine. If the environment is unknown, ask before assuming a
   virtualenv path.
5. For code or test changes, run the smallest relevant correctness check first,
   then broader checks when the change touches shared behavior.
6. Report what changed, what was verified, and what remains intentionally out of
   scope.

## Review Checklist

- Language switch exists where expected.
- No Chinese prose leaks into the English view, and no English-only explanation
  leaks into the Chinese view.
- Generated Doxygen API is inside the English language block unless there is a
  deliberate exception.
- Every public routine has enough local calling information for a reader who
  lands directly on that page.
- Tests and examples are labeled by purpose.
- Sphinx builds without new warnings.
