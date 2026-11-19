# 003_F_IO — F_IO 输入输出回归测试（MPI + HDF5）

[English](README.md)

本目录提供一项规模较小但覆盖全面的回归测试，用于检查 AlgoPlasma 的 `F_IO` 输入输出例程。

它验证以下内容。

- 粒子 I/O 使用 `F02` 输出、`F01` 读取。
- 场 I/O 使用 `F04` 输出、`F03` 读取。
- 支持 `dat`、`bin` 和 `h5` 格式。
- 同时覆盖各格式的底层例程和按标签选择格式的分派例程。
- 检查分派例程遇到未知标签时的回退路径。

测试采用**往返读写**策略。

> 各 MPI 进程写入 → `MPI_BARRIER` → 各进程读取 → 逐元素比较。
>
> 一旦发现不匹配，立即调用 `MPI_ABORT`。

---

## 文件

- `test_F_IO.f90` 是 MPI Fortran 测试程序。各进程读写自己的文件，通过往返比较验证结果。
- `makerun.sh` 编译所需的 `F_IO` 模块和 `test_F_IO.f90`，然后使用 MPI 运行测试。
- `clean.sh` 清理构建产物和所有测试输出目录。

---

## 依赖

- MPI，例如 OpenMPI 或 MPICH。
- 带 Fortran 绑定的 HDF5，推荐使用并行 HDF5。
- 可用的 `h5pfc`，即 MPI + HDF5 Fortran 编译器包装命令。

可先检查命令是否可用。

```bash
which mpirun
which h5pfc
h5pfc -show
```
