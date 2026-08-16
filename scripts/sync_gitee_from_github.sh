#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults for the local GitHub and Gitee working trees. Override them with:
#   GITHUB_REPO=/path/to/AlgoPlasma GITEE_REPO=/path/to/algoplasma ./scripts/sync_gitee_from_github.sh
src_root="$(cd "${GITHUB_REPO:-${script_dir}/..}" && pwd)"
dst_root="${GITEE_REPO:-/home/yin/algoplasma}"

if [[ ! -d "${src_root}/.git" ]]; then
    echo "ERROR: source is not a git working tree: ${src_root}" >&2
    exit 1
fi

if [[ ! -d "${dst_root}/.git" ]]; then
    echo "ERROR: target is not a git working tree: ${dst_root}" >&2
    echo "Set GITEE_REPO=/path/to/gitee/algoplasma if needed." >&2
    exit 1
fi

dst_root="$(cd "${dst_root}" && pwd)"

if [[ "${src_root}" == "${dst_root}" ]]; then
    echo "ERROR: source and target are the same directory: ${src_root}" >&2
    exit 1
fi

if [[ -n "$(git -C "${dst_root}" status --porcelain)" && "${ALLOW_DIRTY_TARGET:-0}" != "1" ]]; then
    echo "ERROR: target working tree has uncommitted changes: ${dst_root}" >&2
    echo "Commit or stash them first, or set ALLOW_DIRTY_TARGET=1 to overwrite them intentionally." >&2
    exit 1
fi

echo "[sync] source: ${src_root}"
echo "[sync] target: ${dst_root}"

rsync -av --delete \
    --exclude='.git/' \
    --exclude='.venv/' \
    --exclude='docs/build/' \
    --exclude='docs/source/_doxygen/' \
    --exclude='**/__pycache__/' \
    --exclude='*.pyc' \
    "${src_root}/" "${dst_root}/"

echo "[gitee defaults] using Chinese README and documentation language"

readme_count=0
while IFS= read -r readme_zh; do
    cp "${readme_zh}" "$(dirname "${readme_zh}")/README.md"
    readme_count=$((readme_count + 1))
done < <(find "${dst_root}" \
    -path "${dst_root}/.git" -prune -o \
    -name 'README.zh-CN.md' -type f -print)

if [[ "${readme_count}" -eq 0 ]]; then
    echo "WARNING: no README.zh-CN.md files found; README.md files were not updated." >&2
else
    echo "[gitee defaults] refreshed ${readme_count} Chinese README.md files"
fi

language_js="${dst_root}/docs/source/_static/ap-language-switch.js"
custom_css="${dst_root}/docs/source/_static/custom.css"

if [[ -f "${language_js}" && -f "${custom_css}" ]]; then
    python3 - "${language_js}" "${custom_css}" <<'PY'
import re
import sys
from pathlib import Path

language_js = Path(sys.argv[1])
custom_css = Path(sys.argv[2])

js_text = language_js.read_text(encoding="utf-8")
js_text, key_count = re.subn(
    r'var storageKey = "ap-doc-language(?:-github)?";',
    'var storageKey = "ap-doc-language";',
    js_text,
)
js_text, default_count = re.subn(
    r'readStoredLanguage\(\) \|\| "(?:zh|en)"',
    'readStoredLanguage() || "zh"',
    js_text,
)
if key_count != 1 or default_count != 1:
    raise SystemExit(
        "ERROR: could not identify the documentation language settings in "
        f"{language_js}"
    )
language_js.write_text(js_text, encoding="utf-8")

css_text = custom_css.read_text(encoding="utf-8")
default_rules = re.compile(
    r"^\.ap-lang-zh\s*\{\s*display:\s*(?:none|block);\s*\}\s*"
    r"^\.ap-lang-en\s*\{\s*display:\s*(?:none|block);\s*\}",
    re.MULTILINE,
)
css_text, css_count = default_rules.subn(
    ".ap-lang-zh {\n"
    "    display: block;\n"
    "}\n\n"
    ".ap-lang-en {\n"
    "    display: none;\n"
    "}",
    css_text,
)
if css_count != 1:
    raise SystemExit(
        "ERROR: could not identify the default documentation language rules in "
        f"{custom_css}"
    )
custom_css.write_text(css_text, encoding="utf-8")
PY
else
    [[ -f "${language_js}" ]] || echo "WARNING: language switch script not found: ${language_js}" >&2
    [[ -f "${custom_css}" ]] || echo "WARNING: custom CSS not found: ${custom_css}" >&2
fi

echo "[done] Gitee working tree status:"
git -C "${dst_root}" status --short
