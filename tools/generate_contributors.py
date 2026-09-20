#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate the AlgoPlasma contributor wall from ``contributors.yml``.

``contributors.yml`` is the single source of truth.  This script renders:

* the ``Contributors`` section between the markers in ``README.md``,
  ``README.zh-CN.md`` and ``README.en.md``;
* the Sphinx / Read the Docs page ``docs/source/community/contributors.md``;
* initial-based fallback avatars in ``docs/source/_static/contributors/``
  for contributors that have neither a GitHub account nor an ``avatar``.

Usage::

    python3 tools/generate_contributors.py           # regenerate in place
    python3 tools/generate_contributors.py --check   # exit 1 if out of date

Only the text between ``<!-- CONTRIBUTORS:START -->`` and
``<!-- CONTRIBUTORS:END -->`` is touched, so hand-written README and page
content is preserved.  The output is deterministic: running the script twice
produces no diff, and the order of ``contributors.yml`` is never changed.

The script uses the standard library only.  PyYAML is used when it is
installed; otherwise a small built-in parser for the subset of YAML used by
``contributors.yml`` is used, so no dependency is required for a rebuild.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import re
import sys
from pathlib import Path, PurePosixPath
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parents[1]
DATA_FILE = ROOT / "contributors.yml"

START = "<!-- CONTRIBUTORS:START -->"
END = "<!-- CONTRIBUTORS:END -->"

# --- README targets: (repo-relative path, language) --------------------------
README_TARGETS = (
    ("README.md", "zh"),
    ("README.zh-CN.md", "zh"),
    ("README.en.md", "en"),
)
# --- Read the Docs page ------------------------------------------------------
RTD_TARGET = "docs/source/community/contributors.md"
RTD_TARGET_DIR = "docs/source/community"

README_COLUMNS = 6
RTD_COLUMNS = 4
RTD_TABLE_CLASS = "ap-contributors"
README_AVATAR_PX = 80
RTD_AVATAR_PX = 96

AVATAR_DIR = ROOT / "docs/source/_static/contributors"
AVATAR_URL_BASE = "docs/source/_static/contributors"
# Accent colors shared with the home-page module cards.
AVATAR_PALETTE = (
    "#2c7be5",
    "#00a887",
    "#7b61ff",
    "#d9822b",
    "#1f9bb4",
    "#5964d8",
    "#c94c4c",
    "#178f66",
)

# --- Contribution types ------------------------------------------------------
# canonical key -> (emoji, English label).  Keep this list short and tied to the
# kinds of work that actually happen in this repository.
CONTRIBUTION_TYPES = {
    "code": ("💻", "Code"),
    "tests": ("🧪", "Tests"),
    "benchmark": ("📊", "Benchmark"),
    "docs": ("📖", "Documentation"),
    "examples": ("🎓", "Examples"),
    "bug": ("🐛", "Bug Fixes"),
}
# accepted spellings -> canonical key
CONTRIBUTION_ALIASES = {
    "code": "code",
    "coding": "code",
    "implementation": "code",
    "software": "code",
    "algorithm": "code",
    "algorithms": "code",
    "tests": "tests",
    "test": "tests",
    "testing": "tests",
    "validation": "tests",
    "verify": "tests",
    "verification": "tests",
    "benchmark": "benchmark",
    "benchmarks": "benchmark",
    "performance": "benchmark",
    "perf": "benchmark",
    "profiling": "benchmark",
    "docs": "docs",
    "doc": "docs",
    "documentation": "docs",
    "writing": "docs",
    "translation": "docs",
    "examples": "examples",
    "example": "examples",
    "tutorial": "examples",
    "tutorials": "examples",
    "teaching": "examples",
    "education": "examples",
    "demo": "examples",
    "bug": "bug",
    "bugs": "bug",
    "bugfix": "bug",
    "bugfixes": "bug",
    "fix": "bug",
    "fixes": "bug",
}

# --- Roles -------------------------------------------------------------------
ROLE_LABELS = {
    "lead": "Project Lead",
    "maintainer": "Maintainer",
    "contributor": "Contributor",
}
DEFAULT_ROLE = "contributor"
# Read the Docs sections: (title, roles in this section).  The role is shown by
# the section heading, so it is not repeated on every card.
RTD_SECTIONS = (
    ("Project Lead", ("lead",)),
    ("Maintainers", ("maintainer",)),
    ("Contributors", ("contributor",)),
)
# README groups: (English title, Chinese title, roles).  Inside a group the order
# of contributors.yml is kept, so the README stays in paper-author order.
README_SECTIONS = (
    ("Maintainers", "维护者", ("lead", "maintainer")),
    ("Contributors", "贡献者", ("contributor",)),
)

# --- Short blurbs ------------------------------------------------------------
README_INTRO = {
    "zh": "感谢每一位为 AlgoPlasma 贡献代码、测试、性能基准、文档、示例与缺陷修复的成员。",
    "en": (
        "Thanks to everyone contributing code, tests, benchmarks, "
        "documentation, examples, and bug fixes to the project."
    ),
}
README_LEGEND_LABEL = {"zh": "贡献类型：", "en": "Contribution types: "}
# The docs page is English-only; the Chinese introduction lives in the Chinese
# README, so the two languages are not mixed on one page.
RTD_INTRO = (
    "AlgoPlasma is built by the people below. The Read the Docs page groups "
    "contributors by role; the README list keeps the order given in "
    "<code>contributors.yml</code>."
)
# Plain HTML: Markdown is not parsed inside the generated HTML blocks.
README_OUTRO = {
    "zh": (
        "完整名单（含角色与链接）："
        '<a href="https://algoplasma.readthedocs.io/en/latest/community/'
        'contributors.html">Read the Docs</a>'
    ),
    "en": (
        "Full list with roles and links: "
        '<a href="https://algoplasma.readthedocs.io/en/latest/community/'
        'contributors.html">Read the Docs</a>'
    ),
}


# =============================================================================
# Data loading
# =============================================================================
def _strip_comment(line: str) -> str:
    """Drop a trailing ``#`` comment, respecting single/double quotes."""
    if line.lstrip().startswith("#"):
        return ""
    quote = None
    for index, char in enumerate(line):
        if quote:
            if char == quote:
                quote = None
        elif char in "\"'":
            quote = char
        elif char == "#" and index > 0 and line[index - 1] in " \t":
            return line[:index]
    return line


def _unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def _parse_scalar(value: str):
    value = value.strip()
    if value.startswith("[") and value.endswith("]"):
        inner = value[1:-1].strip()
        if not inner:
            return []
        return [_parse_scalar(part) for part in inner.split(",")]
    if value in ("null", "~", "None", ""):
        return None
    if value in ("true", "false"):
        return value == "true"
    return _unquote(value)


def _mini_yaml_load(text: str):
    """Parse the small YAML subset used by ``contributors.yml``.

    Supported: nested mappings, block sequences (including ``- key: value``
    items), inline ``[a, b]`` sequences, quoted scalars and ``#`` comments.
    """
    tokens = []
    for raw in text.splitlines():
        line = _strip_comment(raw)
        if not line.strip():
            continue
        tokens.append((len(line) - len(line.lstrip(" ")), line.strip()))
    if not tokens:
        return None
    value, position = _parse_node(tokens, 0, tokens[0][0])
    if position != len(tokens):
        raise ValueError(f"unexpected YAML content near line {tokens[position]!r}")
    return value


def _is_sequence_item(token) -> bool:
    return token[1] == "-" or token[1].startswith("- ")


def _parse_node(tokens, position: int, indent: int):
    if _is_sequence_item(tokens[position]):
        return _parse_sequence(tokens, position, indent)
    return _parse_mapping(tokens, position, indent)


def _parse_sequence(tokens, position: int, indent: int):
    items = []
    while (
        position < len(tokens)
        and tokens[position][0] == indent
        and _is_sequence_item(tokens[position])
    ):
        content = tokens[position][1][1:].strip()
        position += 1
        if not content:
            value, position = _parse_node(tokens, position, tokens[position][0])
        elif re.match(r"^[A-Za-z_][\w.-]*\s*:(?:\s|$)", content):
            # "- key: value" starts a mapping whose first key sits on the dash.
            tokens.insert(position, (indent + 2, content))
            value, position = _parse_mapping(tokens, position, indent + 2)
        else:
            value = _parse_scalar(content)
        items.append(value)
    return items, position


def _parse_mapping(tokens, position: int, indent: int):
    mapping = {}
    while (
        position < len(tokens)
        and tokens[position][0] == indent
        and not _is_sequence_item(tokens[position])
    ):
        content = tokens[position][1]
        match = re.match(r"^([^:]+):\s*(.*)$", content)
        if not match:
            raise ValueError(f"expected 'key: value', got {content!r}")
        key = _unquote(match.group(1))
        rest = match.group(2).strip()
        position += 1
        if rest:
            mapping[key] = _parse_scalar(rest)
        elif position < len(tokens) and tokens[position][0] > indent:
            mapping[key], position = _parse_node(tokens, position, tokens[position][0])
        else:
            mapping[key] = None
    return mapping, position


def _display(path: Path) -> str:
    """Repo-relative path for messages, falling back to the raw path."""
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def load_contributors(path: Path = DATA_FILE):
    """Return the contributor list, in the order given in the YAML file."""
    if not path.is_file():
        sys.exit(f"error: {_display(path)} not found")
    text = path.read_text(encoding="utf-8")
    try:
        import yaml  # type: ignore
    except ImportError:
        data = _mini_yaml_load(text)
    else:
        data = yaml.safe_load(text)
    if not isinstance(data, dict) or "contributors" not in data:
        sys.exit(f"error: {path.name} must contain a top-level 'contributors' list")
    entries = data["contributors"]
    if not isinstance(entries, list) or not entries:
        sys.exit(f"error: 'contributors' in {path.name} must be a non-empty list")
    return [_normalise(entry, index) for index, entry in enumerate(entries)]


def _normalise(entry, index: int) -> dict:
    where = f"contributors.yml entry #{index + 1}"
    if not isinstance(entry, dict):
        sys.exit(f"error: {where} is not a mapping")
    name = str(entry.get("name") or "").strip()
    if not name:
        sys.exit(f"error: {where} has no 'name'")
    role = str(entry.get("role") or DEFAULT_ROLE).strip().lower()
    if role not in ROLE_LABELS:
        allowed = ", ".join(sorted(ROLE_LABELS))
        sys.exit(f"error: {name}: unknown role {role!r} (allowed: {allowed})")
    raw = entry.get("contributions") or []
    if isinstance(raw, str) and raw.strip().lower() in ("all", "*"):
        raw = list(CONTRIBUTION_TYPES)
    if not isinstance(raw, list):
        sys.exit(f"error: {name}: 'contributions' must be a list or 'all'")
    contributions = []
    for item in raw:
        key = CONTRIBUTION_ALIASES.get(str(item).strip().lower())
        if key is None:
            allowed = ", ".join(CONTRIBUTION_TYPES)
            sys.exit(
                f"error: {name}: unknown contribution {item!r} (allowed: {allowed})"
            )
        if key not in contributions:
            contributions.append(key)
    contributions.sort(key=list(CONTRIBUTION_TYPES).index)
    return {
        "name": name,
        "role": role,
        "contributions": contributions,
        "github": str(entry.get("github") or "").strip(),
        "gitee": str(entry.get("gitee") or "").strip(),
        "orcid": str(entry.get("orcid") or "").strip(),
        "avatar": str(entry.get("avatar") or "").strip(),
    }


# =============================================================================
# Avatar helpers
# =============================================================================
def _slug(name: str) -> str:
    slug = re.sub(r"[^0-9A-Za-z]+", "-", name).strip("-").lower()
    return slug or hashlib.md5(name.encode("utf-8")).hexdigest()[:8]


def _initials(name: str) -> str:
    parts = [part for part in re.split(r"\s+", name.strip()) if part]
    if len(parts) >= 2:
        return (parts[0][0] + parts[1][0]).upper()
    word = parts[0] if parts else "?"
    if word.isascii():
        return word[:2].upper()
    return word[0]


def _avatar_svg(name: str) -> str:
    digest = hashlib.md5(name.encode("utf-8")).hexdigest()
    color = AVATAR_PALETTE[int(digest, 16) % len(AVATAR_PALETTE)]
    initials = escape(_initials(name))
    font_size = 66 if len(initials) == 1 else 58
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 160" '
        'width="160" height="160" role="img" '
        f'aria-label="{escape(name)}">\n'
        f'  <rect width="160" height="160" rx="80" fill="{color}"/>\n'
        '  <text x="80" y="80" fill="#ffffff" font-size="{}" font-weight="600" '
        'font-family="Helvetica, Arial, sans-serif" text-anchor="middle" '
        f'dominant-baseline="central">{initials}</text>\n'
        "</svg>\n"
    ).format(font_size)


def _uses_fallback_avatar(entry: dict) -> bool:
    return not entry["avatar"] and not entry["github"]


def _avatar_url(entry: dict, target_dir: str) -> str:
    url = entry["avatar"]
    if not url and entry["github"]:
        url = f"https://github.com/{entry['github']}.png"
    if not url:
        url = f"{AVATAR_URL_BASE}/{_slug(entry['name'])}.svg"
    return _localise(url, target_dir)


def _localise(url: str, target_dir: str) -> str:
    """Re-root a repo-relative path for ``target_dir``; leave URLs untouched."""
    if re.match(r"^[A-Za-z][A-Za-z0-9+.-]*:", url) or url.startswith("//"):
        return url
    if target_dir in ("", "."):
        return url
    return PurePosixPath(os.path.relpath(url, target_dir)).as_posix()


def _profile_url(entry: dict):
    if entry["github"]:
        return f"https://github.com/{entry['github']}", "GitHub"
    if entry["gitee"]:
        return f"https://gitee.com/{entry['gitee']}", "Gitee"
    if entry["orcid"]:
        return f"https://orcid.org/{entry['orcid']}", "ORCID"
    return "", ""


# =============================================================================
# Rendering
# =============================================================================
def _emoji_title_html(entry: dict) -> str:
    tokens = []
    for key in entry["contributions"]:
        emoji, label = CONTRIBUTION_TYPES[key]
        tokens.append(f'<abbr title="{label}">{emoji}</abbr>')
    return " ".join(tokens)


def _used_contribution_keys(contributors) -> list:
    """Contribution types actually used, in the canonical order."""
    used = {key for entry in contributors for key in entry["contributions"]}
    return [key for key in CONTRIBUTION_TYPES if key in used]


def _legend_text(contributors) -> str:
    """One-line legend so the per-card emoji need no repeated labels."""
    return " · ".join(
        f"{CONTRIBUTION_TYPES[key][0]} {CONTRIBUTION_TYPES[key][1]}"
        for key in _used_contribution_keys(contributors)
    )


def _cells_to_rows(cells, columns: int):
    return [cells[start : start + columns] for start in range(0, len(cells), columns)]


def _render_table(cells, columns: int, table_class: str = "") -> str:
    attributes = f' class="{table_class}"' if table_class else ""
    lines = [f"<table{attributes}>"]
    for row in _cells_to_rows(cells, columns):
        lines.append("  <tr>")
        for cell in row:
            lines.extend("    " + line for line in cell)
        lines.append("  </tr>")
    lines.append("</table>")
    return "\n".join(lines)


def _readme_cell(entry: dict, target_dir: str, role_label: str = "") -> list:
    url, _ = _profile_url(entry)
    src = _avatar_url(entry, target_dir)
    image = f'<img src="{src}" width="{README_AVATAR_PX}" height="{README_AVATAR_PX}" alt="{entry["name"]}">'
    if url:
        image = f'<a href="{url}">{image}</a>'
    cell = [
        '<td align="center" width="110" valign="top">',
        f"  {image}<br>",
        f'  <sub><b>{entry["name"]}</b></sub>',
    ]
    if role_label:
        cell[-1] += "<br>"
        cell.append(f"  <sub>{role_label}</sub>")
    emoji = _emoji_title_html(entry)
    if emoji:
        cell[-1] += "<br>"
        cell.append(f"  <sub>{emoji}</sub>")
    cell.append("</td>")
    return cell


def _rtd_cell(entry: dict, target_dir: str) -> list:
    url, _ = _profile_url(entry)
    src = _avatar_url(entry, target_dir)
    image = f'<img src="{src}" width="{RTD_AVATAR_PX}" height="{RTD_AVATAR_PX}" alt="{entry["name"]}">'
    if url:
        image = f'<a href="{url}">{image}</a>'
    name = f'<a href="{url}">{entry["name"]}</a>' if url else entry["name"]
    cell = [
        '<td align="center" width="200" valign="top">',
        f"  {image}<br>",
        f"  <strong>{name}</strong>",
    ]
    emoji = _emoji_title_html(entry)
    if emoji:
        cell[-1] += "<br>"
        cell.append(f"  <small>{emoji}</small>")
    links = []
    if entry["github"]:
        links.append(f'<a href="https://github.com/{entry["github"]}">GitHub</a>')
    if entry["gitee"]:
        links.append(f'<a href="https://gitee.com/{entry["gitee"]}">Gitee</a>')
    if entry["orcid"]:
        links.append(f'<a href="https://orcid.org/{entry["orcid"]}">ORCID</a>')
    if links:
        cell.append("  <br><small>" + " | ".join(links) + "</small>")
    cell.append("</td>")
    return cell


def render_readme_section(contributors, lang: str, target_dir: str = ".") -> str:
    parts = []
    parts.append(f'<p align="center"><sub>{README_INTRO[lang]}</sub></p>')
    parts.append("")
    legend = f"{README_LEGEND_LABEL[lang]}{_legend_text(contributors)}"
    parts.append(f'<p align="center"><sub>{legend}</sub></p>')
    assigned = set()
    for title_en, title_zh, roles in README_SECTIONS:
        group = _readme_group(contributors, roles)
        assigned.update(roles)
        if not group:
            continue
        title = title_en if lang == "en" else f"{title_en} / {title_zh}"
        parts.append("")
        parts.append(f"### {title}")
        parts.append("")
        cells = [
            _readme_cell(
                entry,
                target_dir,
                # the project lead keeps a label inside the maintainer group
                ROLE_LABELS[entry["role"]] if entry["role"] == "lead" else "",
            )
            for entry in group
        ]
        parts.append(_render_table(cells, README_COLUMNS))
    extra_roles = [
        role
        for role in ROLE_LABELS
        if role not in assigned and any(e["role"] == role for e in contributors)
    ]
    for role in extra_roles:  # future roles fall back to their own group
        group = [entry for entry in contributors if entry["role"] == role]
        parts.append("")
        parts.append(f"### {ROLE_LABELS[role]}")
        parts.append("")
        cells = [_readme_cell(entry, target_dir) for entry in group]
        parts.append(_render_table(cells, README_COLUMNS))
    parts.append("")
    parts.append(f'<p align="center"><sub>{README_OUTRO[lang]}</sub></p>')
    return "\n".join(parts) + "\n"


def _sorted_group(contributors, roles) -> list:
    """Contributors of the given roles, sorted by display name."""
    group = [entry for entry in contributors if entry["role"] in roles]
    return sorted(group, key=lambda entry: entry["name"].casefold())


def _readme_group(contributors, roles) -> list:
    """Group for the README: project lead first, the rest by display name."""
    group = [entry for entry in contributors if entry["role"] in roles]
    lead = [entry for entry in group if entry["role"] == "lead"]
    rest = sorted(
        (entry for entry in group if entry["role"] != "lead"),
        key=lambda entry: entry["name"].casefold(),
    )
    return lead + rest


def render_rtd_page(contributors, target_dir: str = RTD_TARGET_DIR) -> str:
    parts = [RTD_INTRO, "", f"<p>Contribution types: {_legend_text(contributors)}</p>", ""]
    assigned = set()
    for title, roles in RTD_SECTIONS:
        group = _sorted_group(contributors, roles)
        assigned.update(roles)
        if not group:
            continue
        parts.append(f"<h2>{title}</h2>")
        parts.append("")
        cells = [_rtd_cell(entry, target_dir) for entry in group]
        parts.append(_render_table(cells, RTD_COLUMNS, RTD_TABLE_CLASS))
        parts.append("")
    extra_roles = [
        role for role in ROLE_LABELS if role not in assigned and any(
            entry["role"] == role for entry in contributors
        )
    ]
    for role in extra_roles:  # future roles fall back to their own section
        group = _sorted_group(contributors, (role,))
        parts.append(f"<h2>{ROLE_LABELS[role]}</h2>")
        parts.append("")
        cells = [_rtd_cell(entry, target_dir) for entry in group]
        parts.append(_render_table(cells, RTD_COLUMNS, RTD_TABLE_CLASS))
        parts.append("")
    return "\n".join(parts)


# =============================================================================
# Marker replacement
# =============================================================================
def replace_section(text: str, body: str, path: Path) -> str:
    start = text.find(START)
    end = text.find(END, start + 1) if start != -1 else -1
    if start == -1 or end == -1:
        sys.exit(
            f"error: markers {START} / {END} not found in "
            f"{_display(path)}; add them manually first"
        )
    if not body.endswith("\n"):
        body += "\n"
    return text[: start + len(START)] + "\n" + body + text[end:]


def desired_files(contributors) -> dict:
    """Map every generated text file to its expected full content."""
    files = {}
    for name, lang in README_TARGETS:
        path = ROOT / name
        if not path.is_file():
            continue
        files[path] = replace_section(
            path.read_text(encoding="utf-8"),
            render_readme_section(contributors, lang, "."),
            path,
        )
    page = ROOT / RTD_TARGET
    if not page.is_file():
        sys.exit(f"error: {RTD_TARGET} not found")
    files[page] = replace_section(
        page.read_text(encoding="utf-8"),
        render_rtd_page(contributors, RTD_TARGET_DIR),
        page,
    )
    return files


def desired_avatars(contributors) -> dict:
    return {
        AVATAR_DIR / f"{_slug(entry['name'])}.svg": _avatar_svg(entry["name"])
        for entry in contributors
        if _uses_fallback_avatar(entry)
    }


# =============================================================================
# Entry point
# =============================================================================
def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--check",
        action="store_true",
        help="do not write anything; exit 1 when a generated file is out of date",
    )
    args = parser.parse_args(argv)

    contributors = load_contributors()
    files = desired_files(contributors)
    avatars = desired_avatars(contributors)

    stale = []
    for path, content in files.items():
        current = path.read_text(encoding="utf-8")
        if current != content:
            stale.append(path)
    for path, content in avatars.items():
        if not path.is_file() or path.read_text(encoding="utf-8") != content:
            stale.append(path)
    obsolete = [
        path
        for path in sorted(AVATAR_DIR.glob("*.svg"))
        if path not in avatars
    ]

    if args.check:
        for path in stale:
            print(f"out of date: {path.relative_to(ROOT)}")
        for path in obsolete:
            print(f"unexpected:  {path.relative_to(ROOT)}")
        if stale or obsolete:
            print("run: python3 tools/generate_contributors.py")
            return 1
        print(f"up to date: {len(contributors)} contributors")
        return 0

    AVATAR_DIR.mkdir(parents=True, exist_ok=True)
    for path, content in {**files, **avatars}.items():
        if path.is_file() and path.read_text(encoding="utf-8") == content:
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        print(f"wrote {path.relative_to(ROOT)}")
    for path in obsolete:
        path.unlink()
        print(f"removed {path.relative_to(ROOT)}")

    fallback = [entry["name"] for entry in contributors if _uses_fallback_avatar(entry)]
    print(f"{len(contributors)} contributors")
    if fallback:
        print(
            "initial-based fallback avatars (add 'github' or 'avatar' to use a "
            "photo): " + ", ".join(fallback)
        )
    if not stale and not obsolete:
        print("no changes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
