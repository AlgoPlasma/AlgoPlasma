# 008_mpi_exchange

[English](README.md)

本目录是 `H_MPI_Exchange` 的少进程 MPI 回归测试入口。测试使用 4 个 MPI 进程和固定的 `2 x 2 x 1` 逻辑拓扑，检查以下例程。

- `H01_mpi_exchange_field` 的场量幽灵层覆盖。
- `H03_mpi_exchange_den` 在散射后的密度边界累加。
- `H02_mpi_exchange_par` 的 MPI 子域间粒子迁移。

这是一个用于在 H 模块修改后快速发现回归的小型用例，覆盖范围有限。

## 文件分工

- `test_H_MPI_Exchange.f90` 是 MPI 测试驱动程序，包含断言。
- `plot_mpi_exchange.py` 读取 `build/*.dat` 并生成诊断图。
- `make.sh` 构建测试可执行文件。
- `run.sh` 构建并运行 4 进程用例，默认也会绘图。
- `clean.sh` 清理 `build/` 和 `fig/` 下的生成文件。
- `run.ps1` 是同一用例的 PowerShell 辅助脚本。

算例构造细节、手工推导的预期值和粒子归属脚本见以下文档。

- `docs/source/rst_files/H_MPI_Exchange/mpi_exchange_testing_guide.rst`
- `docs/source/tests/008_mpi_exchange/index.rst`

## 构建和运行

```bash
cd tests/008_mpi_exchange
bash run.sh
```

只构建可执行文件。

```bash
bash make.sh
```

复用现有可执行文件或跳过绘图。

```bash
BUILD=0 bash run.sh
PLOT=0 bash run.sh
```

默认设置如下。

- `FC=mpif90`
- `MPIEXEC=mpiexec`
- `NP=4`
- `MPI_NP_FLAG=-n`

如果本机命令名不同，可覆盖这些设置。

```bash
FC=mpifort MPIEXEC=mpirun MPI_NP_FLAG=-np NP=4 bash run.sh
```

当前 H01 和 H03 的阻塞交换辅助例程用 `MPI_DOUBLE` 发送默认 `real` 数组，因此构建使用 `-fdefault-real-8`。

## 运行说明

可先检查以下依赖。

```bash
which mpif90
which mpiexec
python3 -c "import matplotlib"
```

测试要求恰好 4 个 MPI 进程。如果 `NP` 不等于 `4`，可执行文件会在检查断言之前报错退出。

## 输出

Fortran 测试写出以下文件。

- `build/h01_field_faces.dat`
- `build/h03_density_faces.dat`
- `build/h02_particle_exchange.dat`

绘图脚本写出以下文件。

- `fig/h01_field_exchange.png`
- `fig/h03_density_exchange.png`
- `fig/h02_particle_exchange.png`

`.dat` 文件和图像用于诊断。通过或失败以 `test_H_MPI_Exchange.f90` 中的 Fortran 断言为准。

运行成功时输出如下。

```text
PASS: H_MPI_Exchange small MPI regression suite.
```

当前实现成功时每个 MPI 进程还会打印一行 `STOP 0`，这是正常输出。

## 覆盖范围与限制

本用例覆盖以下情形。

- 固定 `2 x 2 x 1` 拓扑下，H01 沿 `x/y` 方向交换幽灵层。
- H01 在未分区的 `z` 方向本地填充周期幽灵层。
- H03 沿 `x/y` 方向的边界累加抽样和沿 `z` 方向的本地周期折叠抽样。
- H02 两个物种的跨面、跨棱和跨角迁移，吸收边界处的粒子移除，以及沿 `z` 方向的本地周期回绕。

以下情形不在覆盖范围内。

- `2 x 2 x 1` 以外的拓扑。
- 实际沿 z 方向进行 MPI 交换，即 `domain_split(3)>1`。
- 大量粒子造成的负载压力或达到缓冲区上限的情形。
- 对 H03 的所有路径做逐点的整面检查。

## 清理

```bash
cd tests/008_mpi_exchange
bash clean.sh
```

`clean.sh` 删除 `build/` 和 `fig/` 下生成的数据、编译缓存、可执行文件和图像。
