# G01 MCC 截面表加载器测试

[中文](README.zh-CN.md) | [English](README.en.md)

本目录为 `G_Collision/G01_MCC/sub_G01_load_cross_section.f90` 提供一个聚焦的
回归测试，用于检查两列截面表加载器的数组边界行为。它不验证 MCC 碰撞物理，
所用截面表也不代表真实物理数据。

## 测试内容

- `cross_section_exact_nmax.dat` 恰好包含 `Nmax` 行，用于验证加载结果，并确认
  读取文件结尾时不会访问 `cross_section(:, Nmax + 1)`。
- `cross_section_too_many_rows.dat` 包含 `Nmax + 1` 行，用于验证加载器会输出
  尺寸错误信息、以非零状态退出，并且不会触发 AddressSanitizer 越界报告。

## 环境要求

- Bash
- 支持 AddressSanitizer 的 GNU Fortran

Ubuntu/Debian 可使用：

```bash
sudo apt update
sudo apt install -y gfortran
```

## 运行

从仓库根目录执行：

```bash
bash tests/009_collision/G01_MCC/clean.sh
bash tests/009_collision/G01_MCC/run.sh
```

测试成功时会输出：

```text
PASS: exact-length cross-section table loaded.
PASS: oversized cross-section table rejected without an out-of-bounds access.
```

测试可执行文件生成在 `build/` 下。

## 清理

```bash
bash tests/009_collision/G01_MCC/clean.sh
```

该命令删除本测试目录下的 `build/`。
