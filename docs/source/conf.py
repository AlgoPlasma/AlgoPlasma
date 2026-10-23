# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

import os
import re
import subprocess
from pathlib import Path
from docutils import nodes

project = 'AlgoPlasma'
copyright = '2026, Harbin Institute of Technology and AlgoPlasma contributors'
author = 'AlgoPlasma'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

HERE = os.path.dirname(__file__)


DOXYGEN_FILE_REF_RE = re.compile(
    r'<ref\b(?=[^>]*\brefid="[^"]*(?:_8f90|_8F90|_8c)(?:_[^"]*)?")[^>]*>'
    r"(.*?)</ref>",
    re.DOTALL,
)
DOXYGEN_FORTRAN_FUNCTION_SIGNATURE_FIXES = (
    ("<type>recursive real function</type>", "<type>real</type>"),
    ("<definition>recursive real function ", "<definition>real "),
    ("<type>real function</type>", "<type>real</type>"),
    ("<definition>real function ", "<definition>real "),
)


def _clean_doxygen_xml_for_sphinx(xml_dir):
    """Make Doxygen's Fortran XML friendlier to Breathe/Sphinx nitpicky builds."""
    xml_dir = Path(xml_dir)
    if not xml_dir.is_dir():
        return

    for xml_file in xml_dir.glob("*.xml"):
        text = xml_file.read_text(encoding="utf-8", errors="ignore")
        updated = DOXYGEN_FILE_REF_RE.sub(lambda match: match.group(1), text)
        for old, new in DOXYGEN_FORTRAN_FUNCTION_SIGNATURE_FIXES:
            updated = updated.replace(old, new)
        if updated != text:
            xml_file.write_text(updated, encoding="utf-8")


subprocess.run(["doxygen", "Doxyfile"], cwd=HERE, check=True)
_clean_doxygen_xml_for_sphinx(Path(HERE) / "_doxygen" / "xml")

breathe_projects = {"AlgoPlasma": os.path.join("_doxygen", "xml")}
breathe_default_project = "AlgoPlasma"
nitpick_ignore_regex = [
    ("cpp:identifier", r".*"),
]

extensions = [
    "sphinx_rtd_theme",
    "breathe",
    "myst_parser",
    "sphinxcontrib.katex",
    "matplotlib.sphinxext.plot_directive",
    "sphinx.ext.graphviz",
    "myst_parser",
    "sphinx_copybutton",
]

templates_path = ['_templates']
exclude_patterns = ["sphinx_rtd_theme"]

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'sphinx_rtd_theme'
html_static_path = ['_static']
html_js_files = globals().get('html_js_files', []) + ['J_Fluid/sn_walkthrough_embed.js']
html_extra_path = ['../../LICENSE', '../../NOTICE']
html_show_copyright = False

breathe_default_members = ()

html_theme_options = {
    'collapse_navigation': False,
    # Tests -> numbered group -> module group -> individual test page.
    'navigation_depth': 4,
}

# ===== matplotlib plot directive settings =====
plot_include_source = False
plot_html_show_source_link = False
plot_formats = [("png", 300)]


REFERENCE_LINK_HEADINGS = ("Reference", "References", "\u53c2\u8003\u6587\u732e")
REFERENCE_HEADING_PATTERN = (
    r"(?:\d+\.\s*)?(?:"
    + "|".join(re.escape(heading) for heading in REFERENCE_LINK_HEADINGS)
    + r")"
)
REFERENCE_SECTION_RE = re.compile(
    r'(<p class="rubric">'
    + REFERENCE_HEADING_PATTERN
    + r"</p>)(.*?)(?=<p class=\"rubric\">|</div>|</section>|$)",
    re.DOTALL,
)
EXTERNAL_REFERENCE_LINK_RE = re.compile(
    r'<a\b(?=[^>]*\bclass="[^"]*\breference\b[^"]*\bexternal\b)'
    r'(?=[^>]*\bhref="https?://)[^>]*>',
    re.DOTALL,
)
LITERATURE_LINK_RE = re.compile(
    r'<a\b(?=[^>]*\bhref="https?://(?:doi\.org|dx\.doi\.org|arxiv\.org|books\.google\.com)/)[^>]*>',
    re.DOTALL,
)


def _add_rel_token(tag, token):
    rel_match = re.search(r'\brel="([^"]*)"', tag)
    if not rel_match:
        return tag[:-1] + f' rel="{token}">'

    tokens = rel_match.group(1).split()
    if token in tokens:
        return tag

    tokens.append(token)
    return tag[: rel_match.start(1)] + " ".join(tokens) + tag[rel_match.end(1) :]


def _mark_reference_link(tag):
    if not re.search(r'\btarget=', tag):
        tag = tag[:-1] + ' target="_blank">'
    tag = _add_rel_token(tag, "noopener")
    tag = _add_rel_token(tag, "noreferrer")
    return tag


def _mark_reference_section_links(match):
    heading, body = match.groups()
    body = EXTERNAL_REFERENCE_LINK_RE.sub(
        lambda link_match: _mark_reference_link(link_match.group(0)),
        body,
    )
    return heading + body


def mark_reference_links_in_html(app, exception):
    if exception is not None or app.builder.name != "html":
        return

    for html_file in Path(app.outdir).rglob("*.html"):
        html = html_file.read_text(encoding="utf-8")
        updated = REFERENCE_SECTION_RE.sub(_mark_reference_section_links, html)
        updated = LITERATURE_LINK_RE.sub(
            lambda link_match: _mark_reference_link(link_match.group(0)),
            updated,
        )
        if updated != html:
            html_file.write_text(updated, encoding="utf-8")


def keep_g03_navigation_shallow(app, pagename, templatename, context, doctree):
    """Keep G03 chapters and selected theory sections at their actual depth."""
    from sphinx import addnodes
    from sphinx.environment.adapters.toctree import global_toctree_for_doc

    root = "rst_files/G_Collision/G03_DSMC"
    chapters = (
        (f"{root}/fundamentals", "Theory & Algorithm"),
        (f"{root}/implementation", "Source Guide"),
    )
    theory_sections = (
        ("g03-physical-foundations", "Physical Foundations"),
        ("g03-rate", "Collision Kernels"),
        ("g03-scattering", "Elastic Scattering"),
        ("g03-calibration", "Transport Calibration"),
        ("g03-collision-schedules", "NTC & Continuous Clock"),
        ("g03-cells", "Cylindrical Cells"),
        ("g03-random", "Random Sampling"),
    )

    def add_theory_sections(item, chapter, chapter_uri, depth):
        if chapter != f"{root}/fundamentals":
            return
        sections = nodes.bullet_list()
        for anchor, title in theory_sections:
            paragraph = addnodes.compact_paragraph()
            paragraph += nodes.reference(
                "", title, internal=True, refuri=f"{chapter_uri}#{anchor}"
            )
            sections += nodes.list_item("", paragraph,
                                        classes=[f"toctree-l{depth + 1}"])
        item += sections

    def list_item_for(reference):
        item = reference.parent
        while item is not None and not isinstance(item, nodes.list_item):
            item = item.parent
        return item

    def render_navigation(**kwargs):
        if kwargs.get("maxdepth") == "":
            kwargs.pop("maxdepth")
        kwargs.setdefault("collapse", True)
        kwargs.setdefault("includehidden", False)
        tree = global_toctree_for_doc(
            app.env, pagename, app.builder, tags=app.builder.tags, **kwargs
        )
        if tree is None:
            return ""

        root_uri = app.builder.get_relative_uri(pagename, root)
        for reference in list(tree.findall(nodes.reference)):
            if reference.get("refuri") != root_uri or reference.get("anchorname"):
                continue
            root_item = list_item_for(reference)
            if root_item is None:
                continue

            # Sphinx has already marked the active page's ancestors. Keeping
            # those items preserves the hub highlight even on a detail page.
            depth = next((int(value[len("toctree-l"):]) + 1
                          for value in root_item.get("classes", [])
                          if re.fullmatch(r"toctree-l\d+", value)), 3)
            entries = []
            for chapter, title in chapters:
                chapter_uri = app.builder.get_relative_uri(pagename, chapter)
                for child_ref in list(root_item.findall(nodes.reference)):
                    if (child_ref.get("refuri") == chapter_uri
                            and not child_ref.get("anchorname")):
                        item = list_item_for(child_ref)
                        if item is not None:
                            child_ref[:] = [nodes.Text(title)]
                            item[:] = [child_ref.parent]
                            # Flattened entries must carry their displayed depth.
                            # RTD uses these classes for both active and sibling
                            # indentation; retaining the old depth shifts a link
                            # sideways as soon as it becomes the current page.
                            item["classes"] = [
                                value for value in item.get("classes", [])
                                if not re.fullmatch(r"toctree-l\d+", value)
                            ] + [f"toctree-l{depth}"]
                            add_theory_sections(item, chapter, chapter_uri, depth)
                            entries.append(item)
                        break
                else:
                    # Restore a chapter entry omitted by the current toctree
                    # depth while browsing that chapter's G03 section.
                    if not pagename.startswith(root + "/"):
                        continue
                    paragraph = addnodes.compact_paragraph()
                    paragraph += nodes.reference("", title, internal=True, refuri=chapter_uri)
                    item = nodes.list_item("", paragraph,
                                           classes=[f"toctree-l{depth}"])
                    add_theory_sections(item, chapter, chapter_uri, depth)
                    entries.append(item)
            root_item[:] = [reference.parent]
            if entries:
                root_item += nodes.bullet_list("", *entries)

        return app.builder.render_partial(tree)["fragment"]

    # Keep one selected section tier in the global navigation. Each chapter
    # retains its full local contents in the page body.
    context["toctree"] = render_navigation


def track_g03_test_plot_inputs(app, docname, source):
    """Rebuild measured plots when the test data or renderer changes."""
    if docname != "tests/009_collision/G03_DSMC":
        return
    test_dir = Path(HERE).parent.parent / "tests/009_collision/G03_DSMC"
    app.env.note_dependency(str(test_dir / "plot_results.py"))
    for model in ("HS", "VHS", "VSS"):
        for schedule in ("ntc", "clock"):
            app.env.note_dependency(str(test_dir / "results" /
                                        f"relaxation-{model}-{schedule}.csv"))


def setup(app):
    app.add_css_file("custom.css")  # Sphinx >= 1.8
    app.add_css_file("ap-home-hero.css")
    app.add_css_file("contributors.css")
    app.add_css_file("g02-docs.css")
    app.add_css_file("g03-docs.css")
    app.add_js_file("ap-language-switch.js")
    app.add_js_file("g02-display-titles.js")
    app.add_js_file("G_Collision/G03_DSMC/collision-embed.js")
    app.connect("html-page-context", keep_g03_navigation_shallow)
    app.connect("source-read", track_g03_test_plot_inputs)
    app.connect("build-finished", mark_reference_links_in_html)
