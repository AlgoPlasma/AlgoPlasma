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

project = 'PMSL'
copyright = '2025-2026, PMSL'
author = 'PMSL'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

HERE = os.path.dirname(__file__)
subprocess.run(["doxygen", "Doxyfile"], cwd=HERE, check=True)

breathe_projects = {"PMSL": os.path.join("_doxygen", "xml")}
breathe_default_project = "PMSL"

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

breathe_default_members = ()

html_theme_options = {
    'collapse_navigation': False,
    'navigation_depth': 3,
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


def setup(app):
    app.add_css_file("custom.css")  # Sphinx >= 1.8
    app.add_css_file("pmsl-home-hero.css")
    app.add_js_file("pmsl-language-switch.js")
    app.connect("build-finished", mark_reference_links_in_html)
