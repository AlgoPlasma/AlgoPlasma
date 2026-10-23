# K05 equation numbering

K05 uses one stable sequence, `(K05.1)`, `(K05.2)`, …, across pages.
English and Chinese versions of the same equation share a number but have
separate link targets. Numbers in the cited article remain its own numbers.

The registry is `docs/source/_data/k05_equations.json`. Add a semantic ID with
the next unused integer when adding an equation, including on a new page.
Do not renumber existing IDs when moving equations or adding an earlier step;
do not reuse retired IDs. Thus references remain stable as K05 grows.

In an English container:

```rst
.. k05:equation:: real-wave
   :lang: en

   u(y,t)=h(y,t)\cos(ky-\omega t).

See :k05:eq:`real-wave`.
```

Use the same ID and identical LaTeX with `:lang: zh` in the Chinese container.
Define each ID only once per language; reuse it elsewhere through a reference.
The role selects the language from the containing `ap-lang-en` or `ap-lang-zh`
container. Outside a language container it defaults to English; an explicit
target such as ``:k05:eq:`real-wave@zh` `` selects Chinese. A custom link caption
uses the usual syntax: ``:k05:eq:`the real wave <real-wave>` ``.

The Sphinx domain in `docs/source/_ext/k05_equations.py` resolves links across
pages and catches unknown IDs, duplicate targets and inconsistent translations.
Its JavaScript opens a target's disclosure and language panel on navigation.
Use this directive for K05 display equations instead of manual `\tag` numbers.
The current renderer uses `math_numfig = False` (the Sphinx default); do not
enable global figure-based math numbering without adapting this domain.

Revision classes are temporary reading aids. Remove old `k05-added` and
`k05-revised` markers before marking the next round. The optional directive
class `k05-new-number` colors a newly assigned number without coloring the
unchanged formula. It is not required for numbering or references.

With documentation dependencies installed, run from the repository root:

```sh
python -m unittest discover -s docs/tests -v
python -m sphinx -b html -W --keep-going docs/source docs/build/html
```

Revision 4 retires IDs `example-inputs`, `example-forcing`, and `example-solution`
(numbers 11–13) after removing the maintained-input example. Keep their registry
entries reserved; do not reuse them. New derivation steps have numbers 18–21.
The envelope equation remains K05.7, the one-dimensional result is K05.20,
and the three-dimensional result remains K05.15.
