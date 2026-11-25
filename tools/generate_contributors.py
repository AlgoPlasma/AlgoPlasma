#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate the AlgoPlasma contributor wall from ``contributors.yml``.

``contributors.yml`` is the single source of truth.  This script renders:

* the Sphinx / Read the Docs page ``docs/source/community/contributors.md``;
* surname-first initial avatars for members using ``default_avatar: initials``.

Lead and maintainer avatars use surname and given-name initials until an
explicit ``avatar`` is supplied. Ordinary contributors use their GitHub or
Gitee avatar by default, or initials without an account. An explicit ``avatar``
takes precedence for every role; ``default_avatar`` can also be a shared image.

Usage::

    python3 tools/generate_contributors.py           # regenerate in place
    python3 tools/generate_contributors.py --check   # exit 1 if out of date

Only the text between ``<!-- CONTRIBUTORS:START -->`` and
``<!-- CONTRIBUTORS:END -->`` in the documentation page is touched, so
hand-written page content is preserved. READMEs are not updated.
The output is deterministic: running the script twice
produces no diff, and the order of ``contributors.yml`` is never changed.

The script uses the standard library only.  A small built-in parser handles
the subset of YAML used by ``contributors.yml``. Lifetime activity is an offline
snapshot in ``tools/contributor_activity.json``. Update its Git revision, date,
line totals and Gitee PR numbers together, then rerun this generator.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
from html import escape as html_escape
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
DATA_FILE = ROOT / "contributors.yml"
ACTIVITY_FILE = Path(__file__).with_name("contributor_activity.json")

START = "<!-- CONTRIBUTORS:START -->"
END = "<!-- CONTRIBUTORS:END -->"

# --- Read the Docs page ------------------------------------------------------
RTD_TARGET = "docs/source/community/contributors.md"
RTD_TARGET_DIR = "docs/source/community"

README_COLUMNS = 6
RTD_COLUMNS = 4
RTD_TABLE_CLASS = "ap-contributors"
README_AVATAR_PX = 80
RTD_AVATAR_PX = 96
WORK_AVATAR_PX = 80
MODULE_PAGE_RE = re.compile(r"^([A-K][0-9]{2})_.+\.rst$")
ARCHIVE_PAGE_RE = re.compile(
    r"https://gitee\.com/algoplasma/algoplasma/blob/[0-9a-f]{40}/"
    r"docs/source/rst_files/[\w-]+/(?P<module>[A-K][0-9]{2}_[\w-]+)\.rst"
)
WORK_TABLE_CLASS = "ap-work-list"
WORK_HEADERS = {
    "zh": ("成员", "参与过的具体工作"),
    "en": ("Member", "Documented work"),
}
BIOGRAPHY_LABELS = {"zh": "个人简介", "en": "Biography"}
HOMEPAGE_LABELS = {"zh": "个人主页", "en": "Homepage"}
QUOTATION_INTROS = {
    "zh": "与大家共勉：",
    "en": "A thought to share:",
}
RESEARCH_LABELS = {"zh": "研究方向", "en": "Research Interests"}
RESEARCH_WORK_HEADERS = {
    "zh": "研究方向与参与工作",
    "en": "Research Interests and Documented Work",
}
WORK_PENDING = {"zh": "待补充", "en": "To be added"}

DEFAULT_AVATAR = "initials"
AVATAR_URL_BASE = "docs/source/_static/contributors"
AVATAR_PALETTE = (
    "#2c7be5", "#00a887", "#7b61ff", "#d9822b",
    "#1f9bb4", "#5964d8", "#c94c4c", "#178f66",
)

# --- Contribution types ------------------------------------------------------
# canonical key -> (emoji, English label, Chinese label).  Keep this list short
# and tied to the kinds of work that actually happen in this repository.
CONTRIBUTION_TYPES = {
    "code": ("💻", "Code", "代码"),
    "tests": ("🧪", "Tests", "测试"),
    "benchmark": ("📊", "Benchmark", "性能基准"),
    "docs": ("📖", "Documentation", "文档"),
    "examples": ("🎓", "Examples", "示例"),
    "bug": ("🐛", "Bug Fixes", "缺陷修复"),
}
# index of the label for each language in CONTRIBUTION_TYPES
LABEL_INDEX = {"en": 1, "zh": 2}
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
ROLE_LABELS_ZH = {
    "lead": "项目负责人",
    "maintainer": "维护者",
    "contributor": "贡献者",
}
DEFAULT_ROLE = "contributor"
# Individual contributors remain recorded in the data, but are not listed here.
HIDDEN_ROLES = {"contributor"}
# Read the Docs sections: (English title, Chinese title, roles in this section).
# Detailed rows show roles; ordinary contributor cards use the section heading.
RTD_SECTIONS = (
    ("Project Lead", "项目负责人", ("lead",)),
    ("Current Maintainers", "现任维护者", ("maintainer",)),
)
# README groups: (English title, Chinese title, roles).
README_SECTIONS = (
    ("Project Lead", "项目负责人", ("lead",)),
    ("Current Maintainers", "现任维护者", ("maintainer",)),
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
# The docs page is bilingual: each language lives in its own .ap-lang block, so
# no page mixes the two languages.
RTD_LEGEND_LABEL = {"zh": "贡献类型：", "en": "Contribution types: "}
# Plain HTML: Markdown is not parsed inside the generated HTML blocks.
README_OUTRO = {
    "zh": (
        "项目负责人及现任维护者："
        '<a href="https://algoplasma.readthedocs.io/en/develop/community/'
        'contributors.html">Read the Docs</a>'
    ),
    "en": (
        "Project lead and current maintainers: "
        '<a href="https://algoplasma.readthedocs.io/en/develop/community/'
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
        if key in mapping:
            raise ValueError(f"duplicate YAML key {key!r}")
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
        data = _mini_yaml_load(text)
    except ValueError as error:
        sys.exit(f"error: {path.name}: {error}")
    if not isinstance(data, dict) or "contributors" not in data:
        sys.exit(f"error: {path.name} must contain a top-level 'contributors' list")
    entries = data["contributors"]
    if not isinstance(entries, list) or not entries:
        sys.exit(f"error: 'contributors' in {path.name} must be a non-empty list")
    catalog = _normalise_work_catalog(data.get("work_catalog"))
    default_avatar = data.get("default_avatar") or DEFAULT_AVATAR
    if default_avatar != "initials":
        default_avatar = _normalise_avatar(default_avatar, "default_avatar")
    return [
        _normalise(entry, index, catalog, default_avatar)
        for index, entry in enumerate(entries)
    ]


def _module_pages() -> dict:
    """Index module homepages that have a namesake directory in the source tree."""
    pages = {}
    for path in sorted((ROOT / "docs/source/rst_files").glob("*/*.rst")):
        match = MODULE_PAGE_RE.fullmatch(path.name)
        if not match or not (ROOT / path.parent.name / path.stem).is_dir():
            continue
        module_id = match.group(1)
        if module_id in pages:
            sys.exit(f"error: duplicate module ID {module_id} in module pages")
        pages[module_id] = path
    return pages


def _normalise_work_catalog(raw) -> dict:
    if not isinstance(raw, dict) or not raw:
        sys.exit("error: contributors.yml must contain a non-empty 'work_catalog'")
    pages = _module_pages()
    catalog = {}
    for module_id, labels in raw.items():
        if not isinstance(labels, dict):
            sys.exit(f"error: {module_id}: work description must be a mapping")
        if "archive_url" in labels:
            url = labels["archive_url"]
            match = ARCHIVE_PAGE_RE.fullmatch(url) if isinstance(url, str) else None
            if not match or match.group("module") != module_id:
                sys.exit(f"error: {module_id}: archive_url must link to its commit-pinned module page")
            target = {"archive_url": url}
        else:
            if not isinstance(module_id, str) or not re.fullmatch(r"[A-K][0-9]{2}", module_id):
                sys.exit(f"error: invalid work module ID {module_id!r}")
            if module_id not in pages:
                sys.exit(f"error: {module_id}: matching module document not found")
            target = {"path": pages[module_id]}
        descriptions = {}
        for lang in ("zh", "en"):
            value = labels.get(lang)
            if not isinstance(value, str) or not value.strip():
                sys.exit(f"error: {module_id}: missing {lang} work description")
            if re.search(r"\b[A-K][0-9]{2}\b", value):
                sys.exit(f"error: {module_id}: {lang} description contains a module ID")
            descriptions[lang] = value.strip()
        catalog[module_id] = {"module_id": module_id, **descriptions, **target}
    return catalog


def _normalise_profile_text(raw, field: str, name: str) -> dict:
    """Keep optional profile prose complete in both language views."""
    if raw is None:
        return {}
    if not isinstance(raw, dict):
        sys.exit(f"error: {name}: '{field}' must be a zh/en mapping")
    text = {}
    for lang in ("zh", "en"):
        value = raw.get(lang)
        if not isinstance(value, str) or not value.strip():
            sys.exit(f"error: {name}: missing {lang} {field}")
        text[lang] = value.strip()
    return text


def _normalise(
    entry, index: int, catalog: dict, default_avatar: str = DEFAULT_AVATAR
) -> dict:
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
    raw_work = entry.get("work_modules") or []
    if not isinstance(raw_work, list):
        sys.exit(f"error: {name}: 'work_modules' must be a list")
    work_modules = []
    for module_id in raw_work:
        if not isinstance(module_id, str) or module_id not in catalog:
            sys.exit(f"error: {name}: unknown work module {module_id!r}")
        if module_id in work_modules:
            sys.exit(f"error: {name}: duplicate work module {module_id}")
        work_modules.append(module_id)
    if role == "contributor" and work_modules:
        sys.exit(f"error: {name}: 'work_modules' is only displayed for lead/maintainer")
    biography = _normalise_profile_text(entry.get("biography"), "biography", name)
    personal_statement = _normalise_profile_text(
        entry.get("personal_statement"), "personal_statement", name
    )
    raw_quotation = entry.get("quotation")
    quotation = {}
    if raw_quotation is not None:
        if not isinstance(raw_quotation, dict):
            sys.exit(f"error: {name}: 'quotation' must be a zh/en mapping")
        for lang in ("zh", "en"):
            quote_lines = raw_quotation.get(lang)
            if not isinstance(quote_lines, list) or not quote_lines or any(
                not isinstance(line, str) or not line.strip() for line in quote_lines
            ):
                sys.exit(f"error: {name}: {lang} quotation must contain non-empty lines")
            quotation[lang] = [line.strip() for line in quote_lines]
    research_interests = _normalise_profile_text(
        entry.get("research_interests"), "research_interests", name
    )
    if role == "contributor" and (
        biography or personal_statement or quotation or research_interests
    ):
        sys.exit(f"error: {name}: profile text is only displayed for lead/maintainer")
    github = str(entry.get("github") or "").strip()
    gitee = str(entry.get("gitee") or "").strip()
    avatar = str(entry.get("avatar") or "").strip()
    if not avatar and role == "contributor":
        if github:
            avatar = f"https://github.com/{github}.png"
        elif gitee:
            avatar = f"https://gitee.com/{gitee}.png"
    generated_avatar = not avatar and default_avatar == "initials"
    if generated_avatar:
        avatar = f"{AVATAR_URL_BASE}/{_slug(name)}.svg"
    else:
        avatar = _normalise_avatar(avatar or default_avatar, name)
    return {
        "name": name,
        "name_zh": str(entry.get("name_zh") or "").strip(),
        "role": role,
        "academic_status": _normalise_profile_text(
            entry.get("academic_status"), "academic_status", name
        ),
        "contributions": contributions,
        "work": [catalog[module_id] for module_id in work_modules],
        "biography": biography,
        "personal_statement": personal_statement,
        "quotation": quotation,
        "homepage": str(entry.get("homepage") or "").strip(),
        "research_interests": research_interests,
        "github": github,
        "gitee": gitee,
        "orcid": str(entry.get("orcid") or "").strip(),
        "avatar": avatar,
        "generated_avatar": generated_avatar,
    }


def display_name(entry: dict, lang: str) -> str:
    """Name shown for ``lang``: the Chinese name when there is one."""
    if lang == "zh" and entry.get("name_zh"):
        return entry["name_zh"]
    return entry["name"]


# =============================================================================
# Avatar helpers
# =============================================================================
def _slug(name: str) -> str:
    slug = re.sub(r"[^0-9A-Za-z]+", "-", name).strip("-").lower()
    return slug or hashlib.md5(name.encode("utf-8")).hexdigest()[:8]


def _initials(name: str) -> str:
    """Names are given-name first; avatar initials put the surname first."""
    parts = name.split()
    if len(parts) >= 2:
        return (parts[-1][0] + parts[0][0]).upper()
    return parts[0][:2].upper() if parts else "?"


def _avatar_svg(name: str) -> str:
    digest = hashlib.md5(name.encode("utf-8")).hexdigest()
    color = AVATAR_PALETTE[int(digest, 16) % len(AVATAR_PALETTE)]
    initials = html_escape(_initials(name))
    font_size = 66 if len(initials) == 1 else 58
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 160" '
        'width="160" height="160" role="img" '
        f'aria-label="{html_escape(name, quote=True)}">\n'
        f'  <rect width="160" height="160" rx="80" fill="{color}"/>\n'
        f'  <text x="80" y="80" fill="#ffffff" font-size="{font_size}" '
        'font-weight="600" font-family="Helvetica, Arial, sans-serif" '
        'text-anchor="middle" dominant-baseline="central">'
        f'{initials}</text>\n'
        '</svg>\n'
    )


def _normalise_avatar(value, owner: str) -> str:
    """Catch missing local photos before generating broken image links."""
    avatar = str(value).strip()
    if not avatar:
        sys.exit(f"error: {owner}: avatar path is empty")
    if not re.match(r"^https?://", avatar) and not (ROOT / avatar).is_file():
        sys.exit(f"error: {owner}: avatar image not found: {avatar}")
    return avatar


def _avatar_url(entry: dict, target_dir: str) -> str:
    return _localise(entry["avatar"], target_dir)


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
def _label(key: str, lang: str) -> str:
    return CONTRIBUTION_TYPES[key][LABEL_INDEX[lang]]


def _emoji_title_html(entry: dict, lang: str) -> str:
    tokens = []
    for key in entry["contributions"]:
        emoji = CONTRIBUTION_TYPES[key][0]
        tokens.append(f'<abbr title="{_label(key, lang)}">{emoji}</abbr>')
    return " ".join(tokens)


def _used_contribution_keys(contributors) -> list:
    """Contribution types actually used, in the canonical order."""
    used = {key for entry in contributors for key in entry["contributions"]}
    return [key for key in CONTRIBUTION_TYPES if key in used]


def _legend_text(contributors, lang: str) -> str:
    """One-line legend so the per-card emoji need no repeated labels."""
    return " · ".join(
        f"{CONTRIBUTION_TYPES[key][0]} {_label(key, lang)}"
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


def _readme_cell(
    entry: dict, target_dir: str, lang: str, role_label: str = ""
) -> list:
    url, _ = _profile_url(entry)
    src = _avatar_url(entry, target_dir)
    name = display_name(entry, lang)
    image = f'<img src="{src}" width="{README_AVATAR_PX}" height="{README_AVATAR_PX}" alt="{name}">'
    if url:
        image = f'<a href="{url}">{image}</a>'
    cell = [
        '<td align="center" width="110" valign="top">',
        f"  {image}<br>",
        f"  <sub><b>{name}</b></sub>",
    ]
    if role_label:
        cell[-1] += "<br>"
        cell.append(f"  <sub>{role_label}</sub>")
    emoji = _emoji_title_html(entry, lang)
    if emoji:
        cell[-1] += "<br>"
        cell.append(f"  <sub>{emoji}</sub>")
    cell.append("</td>")
    return cell


def _rtd_cell(entry: dict, target_dir: str, lang: str) -> list:
    url, _ = _profile_url(entry)
    src = _avatar_url(entry, target_dir)
    name = display_name(entry, lang)
    image = f'<img src="{src}" width="{RTD_AVATAR_PX}" height="{RTD_AVATAR_PX}" alt="{name}">'
    if url:
        image = f'<a href="{url}">{image}</a>'
    name = f'<a href="{url}">{name}</a>' if url else name
    cell = [
        '<td align="center" width="200" valign="top">',
        f"  {image}<br>",
        f"  <strong>{name}</strong>",
    ]
    emoji = _emoji_title_html(entry, lang)
    if emoji:
        cell[-1] += "<br>"
        cell.append(f"  <small>{emoji}</small>")
    links = _profile_links(entry)
    if links:
        cell.append("  <br><small>" + links + "</small>")
    cell.append("</td>")
    return cell


def _profile_links(entry: dict, separator: str = " | ") -> str:
    links = []
    for field, base, label in (
        ("github", "https://github.com/", "GitHub"),
        ("gitee", "https://gitee.com/", "Gitee"),
        ("orcid", "https://orcid.org/", "ORCID"),
    ):
        value = entry[field]
        if value:
            links.append(f'<a href="{base}{html_escape(value, quote=True)}">{label}</a>')
    return separator.join(links)


def _work_href(work: dict, target_dir: str) -> str:
    """Link to the archived revision, or to the current source RST or built HTML."""
    if "archive_url" in work:
        return work["archive_url"]
    path = work["path"]
    if target_dir == RTD_TARGET_DIR:
        path = path.with_suffix(".html")
    return PurePosixPath(os.path.relpath(path, ROOT / target_dir)).as_posix()


# Lifetime activity on the Read the Docs page --------------------------------
ACTIVITY_LABELS = {
    "zh": ("代码行数", "提交 PR", "审阅／合并 PR"),
    "en": ("Code lines", "PRs opened", "PRs reviewed/merged"),
}
MEDALS = ("🥇", "🥈", "🥉")
MEDAL_LABELS = {"zh": ("金牌", "银牌", "铜牌"), "en": ("Gold", "Silver", "Bronze")}


def _activity_rows(contributors, members, lang):
    """Rank the three metrics independently among the people shown on the page."""
    scores = {}
    for entry in contributors:
        name = entry["name"]
        if entry["role"] in HIDDEN_ROLES or name not in members:
            continue
        record = members[name]
        scores[name] = (
            record["source"] + record["docs"] + record["tests"],
            len(set(record["opened_prs"])),
            len(set(record["reviewed_or_merged_prs"]) - set(record["opened_prs"])),
        )

    ranks = []
    for column in zip(*scores.values()):
        leaders = sorted({value for value in column if value > 0}, reverse=True)[:3]
        ranks.append({value: rank for rank, value in enumerate(leaders)})

    rows = {}
    for name, values in scores.items():
        record = members[name]
        breakdown = (
            "算法源码 {source:,} 行 · 文档 {docs:,} 行 · 测试 {tests:,} 行"
            if lang == "zh" else "Algorithm source: {source:,} · Docs: {docs:,} · Tests: {tests:,}"
        ).format(**record)
        metrics = []
        for index, (label, value) in enumerate(zip(ACTIVITY_LABELS[lang], values)):
            title = f' title="{breakdown}"' if index == 0 else ""
            medal = ""
            if value in ranks[index]:
                rank = ranks[index][value]
                award = f"{label} · {MEDAL_LABELS[lang][rank]}"
                medal = (
                    f'<i class="ap-medal" role="img" aria-label="{award}" '
                    f'title="{award}">{MEDALS[rank]}</i>'
                )
            metrics.append(f'<span{title}>{label} <b>{value:,}</b>{medal}</span>')
        rows[name] = '<div class="ap-cum">' + "".join(metrics) + "</div>"
    return rows


def _activity_note(snapshot, lang):
    date = html_escape(snapshot["as_of"])
    revision = html_escape(snapshot["revision"], quote=True)
    baseline = html_escape(snapshot["import_revision"][:7])
    if lang == "zh":
        summary = f"历史累计 · 截至 {date} · 统计说明"
        notes = (
            ("代码行数", f"从首次整库导入（{baseline}）之后起算，按 develop 非合并提交的作者累计新增行。"
             "计入算法源码、仓库内的 Markdown 和 reStructuredText 文档、docs/ 和 tests/ 下的文本文件，"
             "以及模块内的测试代码。SVG、生成文件和文本测试数据也计入。删除不抵扣，纯重命名计零行。"),
            ("提交 PR", "统计本人在 Gitee 发起、以 develop 为目标的全部 PR，含开放、关闭和已合并的 PR。"),
            ("审阅／合并 PR", "统计本人正式审阅通过或合并他人 PR 的数量。同一人对同一 PR 只计一次。"
             "自动合并按 Gitee 记录的操作者归属。"),
            ("奖牌", "每项的前三档正数依次获金、银、铜牌。并列同牌，零值不授牌。"),
        )
        pr_label = "Gitee PR 记录"
    else:
        summary = f"Lifetime totals · through {date} · How we count"
        notes = (
            ("Code lines", f"Additions by author in non-merge commits on develop after the initial import ({baseline}). "
             "Counts include algorithm source, Markdown and reStructuredText across the repository, text files in docs/ "
             "and tests/, and tests within modules. SVGs, generated files and text test data count. "
             "Deletions do not reduce the total and pure renames add no lines."),
            ("PRs opened", "All Gitee PRs the contributor opened against develop, including open, closed and merged PRs."),
            ("PRs reviewed/merged", "PRs by other authors that the contributor formally approved or merged. Each PR counts "
             "once per person. Automatic merges are credited to the account recorded by Gitee."),
            ("Medals", "Gold, silver and bronze mark the three highest distinct positive values in each metric. Ties share a medal."),
        )
        pr_label = "Gitee pull requests"
    base = "https://gitee.com/algoplasma/algoplasma"
    lines = [f'<details class="ap-stats-note"><summary>{summary}</summary>']
    lines.extend(f"<p><strong>{label}</strong> {note}</p>" for label, note in notes)
    lines.append(
        f'<p><a href="{base}/commit/{revision}">develop · {revision[:7]}</a> · '
        f'<a href="{base}/pulls">{pr_label}</a></p></details>'
    )
    return "\n".join(lines)


def _maintainer_table(entries, lang: str, target_dir: str, activity=None) -> str:
    """Compact three-column profiles, read left to right in the supplied order."""
    cells = []
    for entry in entries:
        name = html_escape(display_name(entry, lang))
        src = html_escape(_avatar_url(entry, target_dir), quote=True)
        url, _ = _profile_url(entry)
        safe_url = html_escape(url, quote=True)
        image = f'<img src="{src}" width="72" height="72" alt="{name}">'
        if url:
            image = f'<a href="{safe_url}">{image}</a>'
            name = f'<a href="{safe_url}">{name}</a>'
        cell = [
            '<td width="33.333%" valign="top">',
            '  <div class="ap-member-profile">',
            f'    <span class="ap-member-avatar">{image}</span>',
            '    <div class="ap-member-identity">',
            f'      <strong>{name}</strong><br>',
        ]
        status = entry.get("academic_status", {}).get(lang, "")
        if status:
            cell.append(
                f'      <span class="ap-member-status">{html_escape(status)}</span>'
            )
        links = _profile_links(entry, separator=" ")
        if links:
            cell.append(f'      <br><small class="ap-member-links">{links}</small>')
        cell.extend(['    </div>', '  </div>'])
        research = entry.get("research_interests", {}).get(lang, "")
        if research:
            cell.append('  <div class="ap-member-details">')
            cell.append(
                f'    <p class="ap-member-research"><strong>{RESEARCH_LABELS[lang]}</strong>'
                f'<br>{html_escape(research, quote=False)}</p>'
            )
            cell.append('  </div>')
        if activity and entry["name"] in activity:
            cell.append('  ' + activity[entry["name"]])
        cell.append('</td>')
        cells.append(cell)
    return _render_table(cells, 3, "ap-maintainers")


def _work_table(entries, lang: str, target_dir: str, activity=None) -> str:
    member_label, work_label = WORK_HEADERS[lang]
    if all(entry.get("biography") for entry in entries):
        work_label = BIOGRAPHY_LABELS[lang]
    elif any(entry.get("research_interests") for entry in entries):
        work_label = RESEARCH_WORK_HEADERS[lang]
    role_labels = ROLE_LABELS if lang == "en" else ROLE_LABELS_ZH
    table_class = WORK_TABLE_CLASS
    if all(entry["role"] == "lead" for entry in entries):
        table_class += " ap-work-list--lead"
    lines = [
        f'<table class="{table_class}">',
        "  <thead>",
        "    <tr>",
        f'      <th scope="col" align="left" width="160">{member_label}</th>',
        f'      <th scope="col" align="left">{work_label}</th>',
        "    </tr>",
        "  </thead>",
        "  <tbody>",
    ]
    for entry in entries:
        name = html_escape(display_name(entry, lang))
        src = html_escape(_avatar_url(entry, target_dir), quote=True)
        url, _ = _profile_url(entry)
        safe_url = html_escape(url, quote=True)
        avatar_px = 160 if entry["role"] == "lead" else WORK_AVATAR_PX
        image = (
            f'<img src="{src}" width="{avatar_px}" height="{avatar_px}" '
            f'alt="{name}">'
        )
        if url:
            image = f'<a href="{safe_url}">{image}</a>'
        linked_name = f'<a href="{safe_url}">{name}</a>' if url else name
        lines.extend(
            [
                "    <tr>",
                '      <td class="ap-member" align="center" width="160" valign="top">',
                '        <div class="ap-member-profile">',
                f'          <span class="ap-member-avatar">{image}</span>',
                '          <div class="ap-member-identity">',
                f"            <strong>{linked_name}</strong><br>",
                f'            <sub class="ap-member-role">{role_labels[entry["role"]]}</sub>',
            ]
        )
        if target_dir == RTD_TARGET_DIR or entry.get("homepage"):
            links = _profile_links(entry, separator=" ")
            if entry.get("homepage"):
                homepage = html_escape(entry["homepage"], quote=True)
                links = (
                    f'<a href="{homepage}">{HOMEPAGE_LABELS[lang]}</a> {links}'
                ).rstrip()
            if links:
                lines.append(f'            <br><small class="ap-member-links">{links}</small>')
        lines.extend([
            "          </div>",
            "        </div>",
            "      </td>",
            '      <td class="ap-work-cell" valign="top">',
        ])
        biography = entry.get("biography", {}).get(lang, "")
        research_interests = entry.get("research_interests", {}).get(lang, "")
        if biography:
            lines.append(
                f'        <p class="ap-member-biography">{html_escape(biography, quote=False)}</p>'
            )
        personal_statement = entry.get("personal_statement", {}).get(lang, "")
        if personal_statement:
            lines.append(
                '        <p class="ap-member-statement">'
                f'{html_escape(personal_statement, quote=False)}</p>'
            )
        if entry.get("quotation"):
            quote = "<br>".join(
                html_escape(line, quote=False) for line in entry["quotation"][lang]
            )
            lines.extend([
                f'        <p class="ap-member-quote-intro">{QUOTATION_INTROS[lang]}</p>',
                f'        <blockquote class="ap-member-quote"><p>{quote}</p></blockquote>',
            ])
        if research_interests:
            lines.append(
                f'        <p class="ap-member-research"><strong>{RESEARCH_LABELS[lang]}</strong>'
                f'<br>{html_escape(research_interests, quote=False)}</p>'
            )
        if entry["work"] and not biography:
            list_class = "ap-work-items"
            if len(entry["work"]) > 8:
                list_class += " ap-work-items--long"
            lines.append(f'        <ul class="{list_class}">')
            for work in entry["work"]:
                href = html_escape(_work_href(work, target_dir), quote=True)
                description = html_escape(work[lang])
                lines.append(f'          <li><a href="{href}">{description}</a></li>')
            lines.append("        </ul>")
        elif not biography and not research_interests:
            lines.append(
                f'        <span class="ap-work-pending">{WORK_PENDING[lang]}</span>'
            )
        if activity and entry["name"] in activity:
            lines.append("        " + activity[entry["name"]])
        lines.extend(["      </td>", "    </tr>"])
    lines.extend(["  </tbody>", "</table>"])
    return "\n".join(lines)


def render_readme_section(contributors, lang: str, target_dir: str = ".") -> str:
    parts = []
    parts.append(f'<p align="center"><sub>{README_INTRO[lang]}</sub></p>')
    assigned = set(HIDDEN_ROLES)
    role_labels = ROLE_LABELS if lang == "en" else ROLE_LABELS_ZH
    for title_en, title_zh, roles in README_SECTIONS:
        group = _readme_group(contributors, roles, lang)
        assigned.update(roles)
        if not group:
            continue
        title = title_en if lang == "en" else title_zh
        parts.append("")
        parts.append(f"### {title}")
        parts.append("")
        if roles == ("maintainer",):
            parts.append(_maintainer_table(group, lang, target_dir))
        elif "lead" in roles:
            parts.append(_work_table(group, lang, target_dir))
        else:
            legend = _legend_text(group, lang)
            if legend:
                parts.append(
                    f'<p align="center"><sub>{README_LEGEND_LABEL[lang]}{legend}</sub></p>'
                )
            cells = [_readme_cell(entry, target_dir, lang) for entry in group]
            parts.append(_render_table(cells, README_COLUMNS))
    extra_roles = [
        role
        for role in ROLE_LABELS
        if role not in assigned and any(e["role"] == role for e in contributors)
    ]
    for role in extra_roles:  # future roles fall back to their own group
        group = [entry for entry in contributors if entry["role"] == role]
        parts.append("")
        parts.append(f"### {role_labels[role]}")
        parts.append("")
        cells = [_readme_cell(entry, target_dir, lang) for entry in group]
        parts.append(_render_table(cells, README_COLUMNS))
    parts.append("")
    parts.append(f'<p align="center"><sub>{README_OUTRO[lang]}</sub></p>')
    return "\n".join(parts) + "\n"


def _name_sort_key(entry: dict, lang: str) -> tuple:
    """Chinese: surname pinyin; English: first word of the English name."""
    words = entry["name"].split()
    if lang == "zh":
        return (
            words[-1].casefold(),
            " ".join(words[:-1]).casefold(),
            entry["name"].casefold(),
        )
    return (words[0].casefold(), entry["name"].casefold())


def _sorted_group(contributors, roles, lang: str) -> list:
    """Keep leads first and maintainers in the same curated order in both views."""
    group = [entry for entry in contributors if entry["role"] in roles]
    leads = [entry for entry in group if entry["role"] == "lead"]
    maintainers = [entry for entry in group if entry["role"] == "maintainer"]
    others = sorted(
        (entry for entry in group if entry["role"] not in ("lead", "maintainer")),
        key=lambda entry: _name_sort_key(entry, lang),
    )
    return leads + maintainers + others


def _readme_group(contributors, roles, lang: str) -> list:
    """Use the same contributor ordering in the README and documentation."""
    return _sorted_group(contributors, roles, lang)


def _rtd_block(contributors, lang: str, target_dir: str) -> str:
    """One language block of the Read the Docs page.

    Everything is emitted without blank lines inside the ``<div>`` so that the
    whole block stays a single HTML block in Markdown.
    """
    parts = [f'<div class="ap-lang ap-lang-{lang} ap-contributor-page">']
    snapshot = json.loads(ACTIVITY_FILE.read_text(encoding="utf-8"))
    activity = _activity_rows(contributors, snapshot["members"], lang)
    parts.append(_activity_note(snapshot, lang))
    assigned = set(HIDDEN_ROLES)
    role_titles = ROLE_LABELS if lang == "en" else ROLE_LABELS_ZH
    for title_en, title_zh, roles in RTD_SECTIONS:
        group = _sorted_group(contributors, roles, lang)
        assigned.update(roles)
        if not group:
            continue
        parts.append(f'<h2 class="ap-contributor-heading">{title_en if lang == "en" else title_zh}</h2>')
        if roles == ("maintainer",):
            parts.append(_maintainer_table(group, lang, target_dir, activity))
        elif "lead" in roles:
            parts.append(_work_table(group, lang, target_dir, activity))
        else:
            legend = _legend_text(group, lang)
            if legend:
                parts.append(f"<p>{RTD_LEGEND_LABEL[lang]}{legend}</p>")
            cells = [_rtd_cell(entry, target_dir, lang) for entry in group]
            parts.append(_render_table(cells, RTD_COLUMNS, RTD_TABLE_CLASS))
    extra_roles = [
        role for role in ROLE_LABELS if role not in assigned and any(
            entry["role"] == role for entry in contributors
        )
    ]
    for role in extra_roles:  # future roles fall back to their own section
        group = _sorted_group(contributors, (role,), lang)
        parts.append(f"<h2>{role_titles[role]}</h2>")
        cells = [_rtd_cell(entry, target_dir, lang) for entry in group]
        parts.append(_render_table(cells, RTD_COLUMNS, RTD_TABLE_CLASS))
    parts.append("</div>")
    return "\n".join(parts)


def render_rtd_page(contributors, target_dir: str = RTD_TARGET_DIR) -> str:
    # Chinese first: the docs site shows Chinese by default.
    return "\n\n".join(
        _rtd_block(contributors, lang, target_dir) for lang in ("zh", "en")
    )


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
        ROOT / entry["avatar"]: _avatar_svg(entry["name"])
        for entry in contributors
        if entry["generated_avatar"]
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
    files.update(desired_avatars(contributors))

    stale = []
    for path, content in files.items():
        current = path.read_text(encoding="utf-8") if path.is_file() else None
        if current != content:
            stale.append(path)
    if args.check:
        for path in stale:
            print(f"out of date: {path.relative_to(ROOT)}")
        if stale:
            print("run: python3 tools/generate_contributors.py")
            return 1
        print(f"up to date: {len(contributors)} contributors")
        return 0

    for path, content in files.items():
        if path.is_file() and path.read_text(encoding="utf-8") == content:
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        print(f"wrote {path.relative_to(ROOT)}")
    print(f"{len(contributors)} contributors")
    if not stale:
        print("no changes")
    return 0


if __name__ == "__main__":
    sys.exit(main())

# Contribution history (edit times include timezone).
# 2026-11-20 10:25 +08:00 | Zhongping Zhao | edit (Codex-assisted)
# 2026-11-22 21:31 +08:00 | Zhongping Zhao | edit (Codex-assisted)
# 2026-11-25 10:07 +0800 | Yinjian Zhao (Codex-assisted)
