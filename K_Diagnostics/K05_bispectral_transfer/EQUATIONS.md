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
