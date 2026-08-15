#!/usr/bin/env bash
set -euo pipefail

case_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "${case_dir}" || "${case_dir}" == "/" ]]; then
    echo "Refusing to clean an invalid directory: ${case_dir}" >&2
    exit 1
fi

rm -rf -- "${case_dir}/build" "${case_dir}/output" "${case_dir}/figures"
echo "Removed generated build, output, and figure files."

