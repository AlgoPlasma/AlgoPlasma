#!/usr/bin/env bash
# Read-only guard: inspect the index; never stage files or remove run outputs.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
failed=0
while IFS= read -r -d '' path; do
  case "$path" in
    tests/011_fluid/*/build/*|tests/011_fluid/*/__pycache__/*|docs/build/*|docs/source/_doxygen/*)
      echo "Generated file must not be committed: $path" >&2
      failed=1
      ;;
  esac
done < <(git -C "$ROOT" diff --cached --name-only --diff-filter=ACMR -z)
git -C "$ROOT" diff --cached --check || failed=1
if [[ "$failed" -ne 0 ]]; then exit 1; fi
echo "Staged file check: PASS (no files were staged or modified)"
