# K05 contribution history (Git author dates; edit times include timezone).
# 2026-10-23 16:13 +08:00 | Yinjian Zhao | git 482110a190d6
# 2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)

"""Stable, module-wide equation numbers shared by K05's language variants."""

import json
import re
from pathlib import Path

from docutils import nodes
from docutils.parsers.rst import directives
from sphinx.domains import Domain
from sphinx.errors import ExtensionError
from sphinx.roles import XRefRole
from sphinx.util import logging
from sphinx.util.docutils import SphinxDirective
from sphinx.util.nodes import make_refnode

logger = logging.getLogger(__name__)


def read_registry(env):
    path = Path(env.srcdir) / env.config.k05_equation_registry
    env.note_dependency(str(path))
    registry = json.loads(path.read_text(encoding="utf-8"))
    values = list(registry.values())
    if (any(type(n) is not int or n < 1 for n in values)
            or len(set(values)) != len(values)):
        raise ExtensionError("K05 equation numbers must be distinct positive integers")
    if any(not re.fullmatch(r"[a-z][a-z0-9-]*", key) for key in registry):
        raise ExtensionError("K05 equation IDs must use lowercase letters, digits and hyphens")
    return registry


class Equation(SphinxDirective):
    required_arguments = 1
    has_content = True
    option_spec = {"lang": lambda v: directives.choice(v, ("en", "zh")),
                   "class": directives.class_option}

    def run(self):
        self.assert_has_content()
        key = self.arguments[0]
        registry = read_registry(self.env)
        if key not in registry:
            raise self.error(f"Unregistered K05 equation: {key}")
        lang = self.options.get("lang", "en")
        anchor = f"equation-k05-{key}-{lang}"
        number = f"K05.{registry[key]}"
        latex = "\n".join(self.content)
        node = nodes.math_block(latex, latex, number=number, nowrap=False,
                                docname=self.env.docname, label=anchor,
                                ids=[anchor], classes=self.options.get("class", []))
        self.set_source_info(node)
        domain = self.env.get_domain("k05")
        domain.record(f"{key}@{lang}", (self.env.docname, anchor, number, latex), node)
        return [node]


class K05Domain(Domain):
    name = "k05"
    label = "K05 equations"
    directives = {"equation": Equation}
    roles = {"eq": XRefRole(warn_dangling=True)}
    initial_data = {"equations": {}}

    def record(self, key, entry, location=None):
        old = self.data["equations"].get(key)
        if old is not None:
            logger.warning("Duplicate K05 equation %s in %s and %s",
                           key, old[0], entry[0], location=location)
        other_lang = key.rsplit("@", 1)[0] + ("@zh" if key.endswith("@en") else "@en")
        other = self.data["equations"].get(other_lang)
        if other and other[3] != entry[3]:
            logger.warning("K05 language variants have different mathematics: %s",
                           key, location=location)
        self.data["equations"][key] = entry

    def clear_doc(self, docname):
        self.data["equations"] = {key: entry for key, entry in self.data["equations"].items()
                                  if entry[0] != docname}

    def merge_domaindata(self, docnames, otherdata):
        for key, entry in otherdata["equations"].items():
            if entry[0] in docnames:
                self.record(key, entry)

    def resolve_xref(self, env, fromdocname, builder, typ, target, node, contnode):
        if "@" not in target:
            lang = "en"
            parent = node.parent
            while parent is not None:
                classes = parent.get("classes", [])
                if "ap-lang-zh" in classes:
                    lang = "zh"
                    break
                if "ap-lang-en" in classes:
                    break
                parent = parent.parent
            target += f"@{lang}"
        entry = self.data["equations"].get(target)
        if not entry:
            return None
        docname, anchor, number, _ = entry
        label = contnode if node.get("refexplicit") else nodes.inline("", f"({number})")
        result = make_refnode(builder, fromdocname, docname, anchor, label, number)
        result["classes"].append("k05-eq-ref")
        return result

    def get_objects(self):
        for key, (docname, anchor, number, _) in self.data["equations"].items():
            yield key, number, "equation", docname, anchor, 1


def setup(app):
    app.add_config_value("k05_equation_registry", "_data/k05_equations.json", "env")
    app.add_domain(K05Domain)
    app.add_js_file("K_Diagnostics/k05-equations.js")
    return {"version": "1.0", "parallel_read_safe": True, "parallel_write_safe": True}
