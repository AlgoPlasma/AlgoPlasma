#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults for the local Gitee and GitHub working trees. Override them with:
#   GITEE_REPO=/path/to/algoplasma GITHUB_REPO=/path/to/AlgoPlasma ./scripts/sync_github_from_gitee.sh
src_root="$(cd "${GITEE_REPO:-${script_dir}/..}" && pwd)"
dst_root="${GITHUB_REPO:-/home/yin/algoplasma-github/AlgoPlasma}"

if [[ ! -d "${src_root}/.git" ]]; then
    echo "ERROR: source is not a git working tree: ${src_root}" >&2
    exit 1
fi

if [[ ! -d "${dst_root}/.git" ]]; then
    echo "ERROR: target is not a git working tree: ${dst_root}" >&2
    echo "Set GITHUB_REPO=/path/to/github/AlgoPlasma if needed." >&2
    exit 1
fi

dst_root="$(cd "${dst_root}" && pwd)"

if [[ "${src_root}" == "${dst_root}" ]]; then
    echo "ERROR: source and target are the same directory: ${src_root}" >&2
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

echo "[github defaults] using English README and documentation language"

readme_count=0
while IFS= read -r readme_en; do
    cp "${readme_en}" "$(dirname "${readme_en}")/README.md"
    readme_count=$((readme_count + 1))
done < <(find "${dst_root}" \
    -path "${dst_root}/.git" -prune -o \
    -name 'README.en.md' -type f -print)

if [[ "${readme_count}" -eq 0 ]]; then
    echo "WARNING: no README.en.md files found; README.md files were not updated." >&2
else
    echo "[github defaults] refreshed ${readme_count} English README.md files"
fi

language_js="${dst_root}/docs/source/_static/ap-language-switch.js"
if [[ -f "${language_js}" ]]; then
    perl -0pi -e 's/var storageKey = "ap-doc-language(?:-github)?";/var storageKey = "ap-doc-language-github";/g; s/readStoredLanguage\(\) \|\| "(?:zh|en)"/readStoredLanguage() || "en"/g' "${language_js}"
else
    echo "WARNING: language switch script not found: ${language_js}" >&2
fi

custom_css="${dst_root}/docs/source/_static/custom.css"
if [[ -f "${custom_css}" ]]; then
    perl -0pi -e 's/\.ap-lang-zh\s*\{\s*display:\s*none;\s*\}\s*\.ap-lang-en\s*\{\s*display:\s*block;\s*\}/.ap-lang-zh {\n    display: none;\n}\n\n.ap-lang-en {\n    display: block;\n}/s; s/\.ap-lang-en\s*\{\s*display:\s*none;\s*\}/.ap-lang-zh {\n    display: none;\n}\n\n.ap-lang-en {\n    display: block;\n}/s' "${custom_css}"
else
    echo "WARNING: custom CSS not found: ${custom_css}" >&2
fi

echo "[done] GitHub working tree status:"
git -C "${dst_root}" status --short
