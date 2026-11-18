<!-- K05 contribution history (Git author dates; edit times include timezone).
2026-10-23 16:13 +08:00 | Yinjian Zhao | git 482110a190d6
2026-10-27 16:16 +08:00 | Yinjian Zhao | git 1782aebfbe9c
2026-10-28 16:37 +08:00 | Yinjian Zhao | git 288e21275be3
2026-10-29 13:23 +08:00 | Yinjian Zhao | git 5604a5bb51cc
2026-10-30 11:25 +08:00 | Yinjian Zhao | git 303832d65c08
2026-11-02 13:56 +08:00 | Yinjian Zhao | git 1a1e390d6d38
2026-11-03 09:08 +08:00 | Yinjian Zhao | git 52f1bfb880ab
2026-11-03 13:13 +08:00 | Yinjian Zhao | git c78fafbf8e0b
2026-11-03 18:50 +08:00 | Yinjian Zhao | git 950991764e7f
2026-11-04 08:15 +08:00 | Yinjian Zhao | git 6e01f53a6565
2026-11-04 15:31 +08:00 | Yinjian Zhao | git 2d7ac25f8e67
2026-11-06 08:58 +08:00 | Yinjian Zhao | git 8ea987892b7b
2026-11-10 11:18 +08:00 | Yinjian Zhao | git 2960c1dc97d1
2026-11-12 10:09 +08:00 | Yinjian Zhao | git ca62b318155e
2026-11-13 13:10 +08:00 | Yinjian Zhao | git dfd0f9af0503
2026-11-16 12:10 +08:00 | Yinjian Zhao | git 14e5fad1530d
2026-11-16 15:37 +08:00 | Yinjian Zhao | git 5efc16596ad6
2026-11-17 11:41 +08:00 | Yinjian Zhao | git f851bf1cd4a0
2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)
-->

# K05 equation numbering

K05 uses a consecutive reading-order sequence `(K05.1)`, `(K05.2)`, ... across
peer pages in the module overview, including equations inside disclosures.
English and Chinese share display numbers and have distinct language targets.
The reference paper's equation numbers are separate. The current registry has
121 semantic IDs; do not hard-code display numbers in cross-references.

## Source and maintenance

- `docs/source/_data/k05_equations.json`: semantic ID to display-number registry.
- `renumber_equations.py`: reads the overview order and verifies bilingual IDs.
- `docs/source/_ext/k05_equations.py`: Sphinx domain, cross-page targets and checks.
- `docs/source/_static/K_Diagnostics/k05-equations.js`: navigation into language
  containers and closed disclosures.

After adding, removing or moving an equation, run from the repository root:

```bash
python K_Diagnostics/K05_bispectral_transfer/renumber_equations.py --write
python K_Diagnostics/K05_bispectral_transfer/renumber_equations.py --check
python -m unittest discover -s docs/tests -v
python -m sphinx -E -a -b html -W --keep-going docs/source docs/build/html
```

Use the same semantic ID and LaTeX once in each language. An example inside the
English container is:

```rst
.. k05:equation:: real-wave
   :lang: en

   u(y,t)=h(y,t)\cos(ky-\omega t).

See :k05:eq:`real-wave`.
```

For Chinese use `:lang: zh`. The reference role selects the enclosing language;
`:k05:eq:` followed by the target `real-wave@zh` explicitly chooses Chinese.
A caption can use ``:k05:eq:`the real wave <real-wave>` ``.

Semantic IDs are stable even when displayed numbers change. Do not reuse a
removed ID for a different equation. Consult Git history for previously removed
IDs and explanations. The domain rejects unknown IDs, duplicate definitions and
inconsistent bilingual ordering. Keep `math_numfig = False`; changing global
Sphinx math numbering requires adapting this domain.

This file describes the maintained interface. Personal revision notes and old
number-migration snapshots are not required to build or use the module.
