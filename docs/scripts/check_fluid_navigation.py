"""Check J_Fluid and 012_fluid test navigation in generated Sphinx pages.

Run after either make html or sphinx-build. This catches stale navigation in
pages that an incremental build did not rewrite, not just the J_Fluid index.
"""
import argparse
import re
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit


class Sidebar(HTMLParser):
    def __init__(self):
        super().__init__()
        self.depth = 0
        self.href = None
        self.label = []
        self.links = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "div":
            if self.depth:
                self.depth += 1
            elif "wy-menu-vertical" in attrs.get("class", "").split():
                self.depth = 1
        if self.depth and tag == "a":
            self.href = attrs.get("href", "")
            self.label = []

    def handle_data(self, data):
        if self.depth and self.href is not None:
            self.label.append(data)

    def handle_endtag(self, tag):
        if tag == "a" and self.href is not None:
            self.links.append((self.href, "".join(self.label).strip()))
            self.href = None
        if tag == "div" and self.depth:
            self.depth -= 1


# A valid link is insufficient if the theme hides the fourth navigation level.
TEST_GROUPS = {
    "J01_test_overview": ("J01_fm_tests", "J01_solver_tests", "J01_tests"),
    "J02_test_overview": ("J02_tests", "J02_solver_tests", "J02_parallel_tests"),
    "J03_test_overview": ("J03_tests", "J03_transient_tests", "integration_tests", "application_tests"),
}


def check(root):
    errors = []
    checked = {"J_Fluid": 0, "012_fluid": 0}
    for page in sorted(root.rglob("*.html")):
        parser = Sidebar()
        parser.feed(page.read_text(encoding="utf-8"))
        seen = set()
        for href, label in parser.links:
            url = urlsplit(href)
            if url.scheme or url.netloc:
                continue
            target = (page.parent / unquote(url.path)).resolve() if url.path else page.resolve()
            try:
                relative = target.relative_to(root.resolve()).as_posix()
            except ValueError:
                continue
            if relative == "rst_files/J_Fluid.html" or relative.startswith("rst_files/J_Fluid/"):
                group = "J_Fluid"
            elif relative.startswith("tests/012_fluid/"):
                group = "012_fluid"
            else:
                continue
            checked[group] += 1
            if relative in seen:
                errors.append(f"{page.relative_to(root)}: duplicate sidebar target: {href}")
            seen.add(relative)
            if url.fragment or re.search(r"[\u4e00-\u9fff]", label):
                errors.append(f"{page.relative_to(root)}: section in sidebar: {label} -> {href}")
            if not target.is_file():
                errors.append(f"{page.relative_to(root)}: missing page: {href}")
        relative_page = page.relative_to(root).as_posix()
        if relative_page.startswith("tests/012_fluid/"):
            for parent, children in TEST_GROUPS.items():
                if page.stem not in (parent, *children):
                    continue
                for name in (parent, *children):
                    expected = f"tests/012_fluid/{name}.html"
                    if expected not in seen:
                        errors.append(f"{relative_page}: module navigation missing: {expected}")
    for group, count in checked.items():
        if not count:
            errors.append(f"No {group} sidebar links found.")
    for message in errors[:20]:
        print(message)
    for group, count in checked.items():
        print(f"{group} navigation: {count} links checked")
    print(f"Fluid navigation: {len(errors)} errors")
    return bool(errors)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("html_root", type=Path)
    args = parser.parse_args()
    raise SystemExit(check(args.html_root))
