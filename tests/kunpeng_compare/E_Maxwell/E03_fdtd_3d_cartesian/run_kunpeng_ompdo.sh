#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

select_bisheng_fc() {
  if [[ -n "${FC:-}" ]]; then
    return
  fi

  local candidate
  for candidate in flang bisheng-flang biflang flang-new; do
    if command -v "${candidate}" >/dev/null 2>&1; then
      FC="${candidate}"
      export FC
      return
    fi
  done

  echo "ERROR: Bisheng Fortran compiler was not found. Load Bisheng or set FC=/path/to/flang." >&2
  exit 1
}

if [[ -z "${FC:-}" && -f /home/hpcuser/build_config.sh ]]; then
  export TOOLCHAIN="${TOOLCHAIN:-bisheng}"
  source /home/hpcuser/build_config.sh
fi

select_bisheng_fc

KUNPENG_MCPU="${KUNPENG_MCPU:-native}"
FCFLAGS="${FCFLAGS:--cpp -O3 -fdefault-real-8 -fopenmp -ffree-line-length-none -mcpu=${KUNPENG_MCPU}}"
case " ${FCFLAGS} " in
  *" -DALGOPLASMA_E03_USE_OMPDO "*) ;;
  *) FCFLAGS="${FCFLAGS} -DALGOPLASMA_E03_USE_OMPDO" ;;
esac
export FC FCFLAGS

echo "Kunpeng ompdo compiler: ${FC}"
echo "Kunpeng ompdo FCFLAGS: ${FCFLAGS}"

bash "${SCRIPT_DIR}/run_common.sh" kunpeng_ompdo "$@"
