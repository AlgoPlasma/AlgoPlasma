# K05 contribution history (Git author dates; edit times include timezone).
# 2026-11-03 13:13 +08:00 | Yinjian Zhao | git c78fafbf8e0b
# 2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)

"""Check or regenerate K05's bilingual equation numbers in reading order.

Run from any directory. Only --write changes the registry; semantic IDs and
equation content are never rewritten. Include equations inside disclosures.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re


def reading_order(repo: Path) -> dict[str, int]:
    pages = repo / "docs/source/rst_files/K_Diagnostics"
    overview = (pages / "K05_bispectral_transfer.rst").read_text(encoding="utf-8")
    names = re.findall(r"^   (K05_[A-Za-z0-9_]+)\s*$", overview, re.MULTILINE)
    if not names or len(names) != len(set(names)):
        raise ValueError("K05's overview must list each article exactly once.")
    result: dict[str, int] = {}
    for name in names:
        text = (pages / f"{name}.rst").read_text(encoding="utf-8")
        matches = re.findall(
            r"^ *\.\. k05:equation:: ([\w-]+)\s*\n +:lang: (en|zh)\s*$",
            text, re.MULTILINE,
        )
        if len(matches) != len(re.findall(r"\.\. k05:equation::", text)):
            raise ValueError(f"Unrecognized equation declaration in {name}.")
        en = [key for key, lang in matches if lang == "en"]
        zh = [key for key, lang in matches if lang == "zh"]
        if en != zh:
            raise ValueError(f"English and Chinese equation order differs in {name}.")
        for key in en:
            if key in result:
                raise ValueError(f"Duplicate equation ID: {key}.")
            result[key] = len(result) + 1
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="Update the registry.")
    parser.add_argument("--check", action="store_true", help="Check only (default).")
    args = parser.parse_args()
    if args.write and args.check:
        parser.error("Choose --write or --check, not both.")
    repo = Path(__file__).resolve().parents[2]
    registry = repo / "docs/source/_data/k05_equations.json"
    expected = reading_order(repo)
    if args.write:
        registry.write_bytes((json.dumps(expected, indent=2) + "\n").encode("utf-8"))
    elif json.loads(registry.read_text(encoding="utf-8")) != expected:
        raise SystemExit("Registry differs from reading order. Run with --write and rebuild.")
    print(f"K05: {len(expected)} equations, consecutive bilingual reading order.")


if __name__ == "__main__":
    main()
