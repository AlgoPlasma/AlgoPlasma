#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from pathlib import Path
import sys


MAX_WIDTH = 80  # RST 单行最大字符数
VALID_PREFIXES = ("mod_", "sub_", "fun_")


def wrap_text(text, width):
    """
    简单按空格做换行，保证每行长度 <= width。
    如果某个“单词”（比如一个很长的路径）本身就超过 width，就不强行拆开。
    """
    text = text.strip()
    if not text:
        return []
    if len(text) <= width:
        return [text]

    words = text.split(" ")
    lines = []
    cur = ""

    for w in words:
        if not cur:
            cur = w
        elif len(cur) + 1 + len(w) <= width:
            cur += " " + w
        else:
            lines.append(cur)
            cur = w

    if cur:
        lines.append(cur)

    return lines


def _strip_fortran_comment_prefix(line: str) -> str:
    """
    去掉 Fortran 注释前缀，例如:
        "!> text" / "!! text" / "! text"
    返回去掉前缀后的文本（首尾空格会再在外层处理）。
    """
    s = line.lstrip()
    if not s.startswith("!"):
        return s

    i = 0
    while i < len(s) and s[i] == "!":
        i += 1

    if i < len(s) and s[i] in (">", "<"):
        i += 1

    return s[i:].lstrip()


def extract_brief_from_file(path: Path):
    r"""
    从 .f90 源文件中提取 Doxygen 的 \brief 或 @brief 内容。
    支持多行 brief：
      - 从 \brief/@brief 所在行的后半部分开始
      - 继续读取后续注释行，直到遇到:
          * 空行（去掉注释前缀和空格后）
          * 或以 \/@ 开头的新 doxygen 命令
    将所有行合并为一段文字（用空格连接），若未找到则返回 None。
    """
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return None

    lines = text.splitlines()
    n = len(lines)

    for i, line in enumerate(lines):
        lower = line.lower()
        idx = -1
        tag = None

        if "\\brief" in lower:
            idx = lower.find("\\brief")
            tag = "\\brief"
        elif "@brief" in lower:
            idx = lower.find("@brief")
            tag = "@brief"

        if idx == -1 or tag is None:
            continue

        after = line[idx + len(tag):]
        first = after.strip(" :*-!>/<\t")

        parts = []
        if first:
            parts.append(first)

        j = i + 1
        while j < n:
            raw = lines[j]
            stripped = _strip_fortran_comment_prefix(raw).rstrip()

            if not stripped:
                break

            if stripped.startswith("\\") or stripped.startswith("@"):
                break

            parts.append(stripped)
            j += 1

        if not parts:
            return None

        return " ".join(parts)

    return None


def build_bullet_block(subname: str, filename: str, basename: str, desc: str) -> str:
    """
    构造 group rst 里一个条目的完整块（含 bullet、空行、描述段）。
    """
    doc_text = f":doc:`{filename} <{subname}/{basename}>`:"
    bullet_prefix = "* "

    wrapped = wrap_text(doc_text, max(MAX_WIDTH - len(bullet_prefix), 10))
    out_lines = []
    for i, part in enumerate(wrapped):
        if i == 0:
            out_lines.append(bullet_prefix + part)
        else:
            out_lines.append("  " + part)

    out_lines.append("")  # bullet 标题行与描述间空一行

    desc_lines = wrap_text(desc, MAX_WIDTH - 4)
    if desc_lines:
        for line in desc_lines:
            out_lines.append("    " + line)
        out_lines.append("")  # 条目间空一行
    else:
        out_lines.append("")

    return "\n".join(out_lines) + "\n"


def ensure_toctree_block(subname: str) -> str:
    """
    group rst 的标准 toctree block。
    """
    return (
        ".. toctree::\n"
        "    :maxdepth: 1\n"
        "    :hidden:\n"
        "    :glob:\n\n"
        f"    {subname}/*\n"
    )


def compute_desc_for_basename(basename: str, briefs: dict) -> str:
    """
    生成描述：
    - mod_：优先自己的 brief；没有则回退 sub_/fun_ 同后缀
    - sub_/fun_：用自己的 brief
    """
    desc = "TODO: add description."
    brief_this = briefs.get(basename)

    if basename.startswith("mod_"):
        if brief_this:
            return brief_this

        suffix = basename[len("mod_"):]
        for fallback_prefix in ("sub_", "fun_"):
            b = briefs.get(fallback_prefix + suffix)
            if b:
                return b
        return desc

    if brief_this:
        return brief_this

    return desc


def update_or_create_group_rst(group_rst: Path, subname: str, f90_files: list[Path], briefs: dict):
    """
    - group rst 不存在：新建（按当前 f90_files）
    - group rst 已存在：不覆盖原内容，只把缺的 f90 条目追加进去（追加在 .. toctree:: 之前）
    """
    entries = []
    for f90 in f90_files:
        filename = f90.name
        basename = f90.stem
        desc = compute_desc_for_basename(basename, briefs)
        entries.append((filename, basename, desc))

    if not group_rst.exists():
        eq_line = "=" * len(subname)
        with group_rst.open("w", encoding="utf-8") as f:
            f.write(eq_line + "\n")
            f.write(subname + "\n")
            f.write(eq_line + "\n\n")

            for filename, basename, desc in entries:
                f.write(build_bullet_block(subname, filename, basename, desc))

            f.write(ensure_toctree_block(subname))
        return

    old_text = group_rst.read_text(encoding="utf-8", errors="ignore")

    def marker(sn: str, bn: str) -> str:
        return f"<{sn}/{bn}>"

    missing_blocks = []
    for filename, basename, desc in entries:
        if marker(subname, basename) in old_text:
            continue
        missing_blocks.append(build_bullet_block(subname, filename, basename, desc))

    if not missing_blocks:
        return

    lines = old_text.splitlines(keepends=True)

    insert_at = None
    for idx, line in enumerate(lines):
        if line.lstrip().startswith(".. toctree::"):
            insert_at = idx
            break

    if insert_at is None:
        # 没找到 toctree：末尾追加缺失条目并补一个标准 toctree
        new_text = old_text.rstrip() + "\n\n" + "".join(missing_blocks) + "\n" + ensure_toctree_block(subname)
        group_rst.write_text(new_text, encoding="utf-8")
        return

    before = "".join(lines[:insert_at]).rstrip() + "\n\n"
    after = "".join(lines[insert_at:]).lstrip()

    new_text = before + "".join(missing_blocks) + "\n" + after
    group_rst.write_text(new_text, encoding="utf-8")


def create_f90_rst_if_missing(dest_sub_dir: Path, f90: Path):
    """
    每个 f90 对应的 rst：仅在不存在时创建（避免覆盖）。
    """
    filename = f90.name
    basename = f90.stem
    dest_f90_rst = dest_sub_dir / f"{basename}.rst"
    if dest_f90_rst.exists():
        return

    hyphen_line = "-" * len(filename)
    with dest_f90_rst.open("w", encoding="utf-8") as f:
        f.write(hyphen_line + "\n")
        f.write(filename + "\n")
        f.write(hyphen_line + "\n\n")

        doxy_line = f".. doxygenfile:: {filename}"
        if len(doxy_line) <= MAX_WIDTH:
            f.write(doxy_line + "\n")
        else:
            for line in wrap_text(doxy_line, MAX_WIDTH):
                f.write(line + "\n")


def update_or_create_top_rst(top_rst: Path, lib_name: str, subnames: list[str]):
    """
    更新 rst_files/{lib_name}.rst：
      - 若存在且 toctree 使用 :glob: + '{lib_name}/*'，无需更新（会自动包含新增 group rst）
      - 若没有 :glob: 但有 '{lib_name}/*'，补上 :glob:
      - 否则在 toctree 中增量加入缺少的 '{lib_name}/{subname}'
      - 若没有 toctree，则在文件末尾追加一个
    """
    subnames = sorted(subnames)
    desired_entries = [f"{lib_name}/{s}" for s in subnames]
    desired_glob_line = f"{lib_name}/*"

    if not top_rst.exists():
        with top_rst.open("w", encoding="utf-8") as f:
            eq_line = "=" * len(lib_name)
            f.write(eq_line + "\n")
            f.write(lib_name + "\n")
            f.write(eq_line + "\n\n")
            f.write(".. toctree::\n")
            f.write("    :maxdepth: 1\n")
            f.write("    :glob:\n\n")
            f.write(f"    {desired_glob_line}\n")
        return

    old = top_rst.read_text(encoding="utf-8", errors="ignore")
    lines = old.splitlines(keepends=True)

    start = None
    for i, ln in enumerate(lines):
        if ln.lstrip().startswith(".. toctree::"):
            start = i
            break

    if start is None:
        add = []
        add.append("\n" if (lines and not lines[-1].endswith("\n")) else "")
        add.append("\n.. toctree::\n")
        add.append("    :maxdepth: 1\n\n")
        for ent in desired_entries:
            add.append(f"    {ent}\n")
        top_rst.write_text("".join(lines) + "".join(add), encoding="utf-8")
        return

    end = start + 1
    while end < len(lines):
        ln = lines[end]
        if ln.strip() == "":
            end += 1
            continue
        if ln.startswith((" ", "\t")):
            end += 1
            continue
        break

    block = lines[start:end]

    has_glob_opt = any(b.lstrip().startswith(":glob:") for b in block if b.startswith((" ", "\t")))

    existing_entries = []
    for b in block:
        s = b.strip()
        if not s:
            continue
        if s.startswith(".. toctree::"):
            continue
        if s.startswith(":"):
            continue
        if b.startswith((" ", "\t")):
            existing_entries.append(s)

    # 已是 glob + lib/*：不用更新
    if has_glob_opt and desired_glob_line in existing_entries:
        return

    # 有 lib/* 但没 :glob:：补 :glob:
    if (desired_glob_line in existing_entries) and (not has_glob_opt):
        insert_pos = start + 1
        while insert_pos < end:
            t = lines[insert_pos].strip()
            if t.startswith(":"):
                insert_pos += 1
                continue
            break
        new_lines = lines[:insert_pos] + ["    :glob:\n"] + lines[insert_pos:]
        top_rst.write_text("".join(new_lines), encoding="utf-8")
        return

    # 非 glob：增量补齐缺失 entries
    missing = [e for e in desired_entries if e not in existing_entries]
    if not missing:
        return

    insert_at = end
    insertion = []
    if block and block[-1].strip() != "":
        insertion.append("\n")
    for ent in missing:
        insertion.append(f"    {ent}\n")

    new_text = "".join(lines[:insert_at]) + "".join(insertion) + "".join(lines[insert_at:])
    top_rst.write_text(new_text, encoding="utf-8")


def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]

    if len(argv) != 1:
        print(f"Usage: {Path(__file__).name} <Subroutine_ID>", file=sys.stderr)
        return 1

    lib_name = argv[0].strip()  # 例如 "H_MPI_Exchange"

    script_dir = Path(__file__).resolve().parent

    # ./rst_files/
    rst_root = script_dir / "rst_files"
    rst_root.mkdir(exist_ok=True)

    # ./rst_files/H_MPI_Exchange/
    dest_dir = rst_root / lib_name
    dest_dir.mkdir(parents=True, exist_ok=True)  # 不退出：确保存在即可

    # ../../H_MPI_Exchange/
    src_base = script_dir.parent.parent
    src_dir = src_base / lib_name
    if not src_dir.is_dir():
        print(f"Error: source directory '{src_dir}' does not exist.", file=sys.stderr)
        return 1

    # 枚举 ../../H_MPI_Exchange/ 下的子目录
    subdirs = sorted([d for d in src_dir.iterdir() if d.is_dir()], key=lambda p: p.name)
    if not subdirs:
        print(f"Error: no subdirectories found in '{src_dir}'.", file=sys.stderr)
        return 1

    # 顶层 H_MPI_Exchange.rst：增量更新
    top_rst = rst_root / f"{lib_name}.rst"
    update_or_create_top_rst(top_rst, lib_name, [d.name for d in subdirs])

    for sub in subdirs:
        subname = sub.name  # 例如 H01_xxx

        # ./rst_files/H_MPI_Exchange/H01_xxx/
        dest_sub_dir = dest_dir / subname
        dest_sub_dir.mkdir(parents=True, exist_ok=True)

        # ./rst_files/H_MPI_Exchange/H01_xxx.rst
        group_rst = dest_dir / f"{subname}.rst"

        # 只保留 mod_/sub_/fun_ 开头的 .f90
        f90_files_all = sorted(sub.glob("*.f90"))
        f90_files = [p for p in f90_files_all if p.stem.startswith(VALID_PREFIXES)]

        # 如果该子目录没有符合命名规则的文件，就跳过（不生成/不更新该组 rst）
        if not f90_files:
            continue

        # brief 扫描
        briefs = {}
        for f90 in f90_files:
            basename = f90.stem
            briefs[basename] = extract_brief_from_file(f90)

        # group rst：新建或增量追加缺失条目
        update_or_create_group_rst(group_rst, subname, f90_files, briefs)

        # 每个 f90 的子页面：仅缺失时创建
        for f90 in f90_files:
            create_f90_rst_if_missing(dest_sub_dir, f90)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
