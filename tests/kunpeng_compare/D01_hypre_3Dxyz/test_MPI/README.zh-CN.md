# D01_hypre_3Dxyz MPI 进程数性能对比

[English](README.md)

本算例在固定的 `320 x 80 x 320` 网格上测试 D01 直角坐标 Poisson/HYPRE 求解器的性能。默认固定 `OMP_NUM_THREADS=1` 并扫描 MPI 进程数，主要衡量性能随 MPI 进程数的变化。

计算域沿 x 方向分成若干片，每个 MPI 进程负责其中一片。基准程序记录 HYPRE 求解耗时、端到端总耗时和范数诊断。

## 文件

- `main_time.f90`：MPI 进程数基准驱动程序。
- `make.sh`：鲲鹏构建入口，可使用 `TOOLCHAIN=gcc` 或 `TOOLCHAIN=bisheng`。
- `build_config.sh`：选择鲲鹏上的 HYPRE、MPI 和编译器环境。
- `run_mpi_gcc.sh`：鲲鹏 GCC 的 MPI 进程数扫描。加载 GCC HYPRE 环境，用 `./make.sh` 重新编译并运行 `main_gcc.out`。
- `run_mpi_bisheng.sh`：鲲鹏毕昇的 MPI 进程数扫描。加载毕昇 HYPRE 环境，用 `./make.sh` 重新编译并运行 `main_bisheng.out`。
- `run_mpi_AMD.sh`：在 AMD 上使用已构建的可执行文件扫描 MPI 进程数。它设置本地 HYPRE 路径，并运行 `${EXE:-./main.out}`。
- `plot-time-np.py`：解析 `run_*_np*_omp*_*.log`，写入 CSV 汇总并生成 MPI 进程数对比图。
- `plot.py`：可选的 `phi.dat` 可视化脚本，仅在 `WRITE_PHI=1` 时使用。
- `clean.sh`：删除构建产物、`phi.dat` 和生成的 PNG，保留旧日志和 CSV 汇总。

## 默认扫描设置

鲲鹏 MPI 脚本使用：

```bash
NP_LIST="1 2 4 8 16 24 32 48 64 128"
OMP_NUM_THREADS=1
NREPEAT=5
```

AMD 脚本使用相同的默认进程数列表，并支持在运行时覆盖以下设置：

```bash
NP_LIST="1 2 4 8 16 24 32 48 64 128"
OMP_LIST="1"
NREPEAT=5
WRITE_PHI=0
MPI_BIND_ARGS="--bind-to none"
```

`WRITE_PHI=0` 默认禁止写出 `phi.dat`，避免将大量数据的汇集和写出开销计入 MPI 进程数的性能对比。

## 运行

基本步骤：

1. 构建可执行文件。
2. 运行对应的 MPI 扫描脚本。
3. 将各平台的日志复制或保留在本目录。
4. 运行 `python3 plot-time-np.py`。

运行前，鲲鹏服务器需具备对应的 HYPRE/OpenMPI 环境：

- GCC 环境：`/opt/hypre/3.1.0-gcc/env.sh`
- 毕昇环境：`/opt/hypre/3.1.0-bisheng/env.sh`

`build_config.sh` 根据 `TOOLCHAIN` 选择工具链，默认值为 `gcc`。
设为 `TOOLCHAIN=gcc` 时，脚本加载 `/opt/hypre/3.1.0-gcc/env.sh`，使用 `/usr/bin/mpicc` 和 `/usr/bin/mpifort`，生成 `main_gcc.out`。
设为 `TOOLCHAIN=bisheng` 时，脚本加载 `/opt/hypre/3.1.0-bisheng/env.sh`，使用 `/opt/openmpi/4.1.4-bisheng/bin/mpicc` 和 `/opt/openmpi/4.1.4-bisheng/bin/mpifort`，生成 `main_bisheng.out`。

### 鲲鹏 GCC

先构建：

```bash
TOOLCHAIN=gcc bash make.sh
```

再扫描 MPI 进程数：

```bash
TOOLCHAIN=gcc bash run_mpi_gcc.sh
```

`run_mpi_gcc.sh` 启动扫描前也会加载 `/opt/hypre/3.1.0-gcc/env.sh` 并再次调用 `./make.sh`。即使 Shell 之前导出了不同的 `TOOLCHAIN`，在命令中传入 `TOOLCHAIN=gcc` 也能保证脚本用 GCC 工具链重新构建。生成的日志名形如 `run_gcc_np<N>_omp1_<R>.log`。

### 鲲鹏毕昇

先构建：

```bash
TOOLCHAIN=bisheng bash make.sh
```

再以相同的工具链设置扫描 MPI 进程数：

```bash
TOOLCHAIN=bisheng bash run_mpi_bisheng.sh
```

`run_mpi_bisheng.sh` 启动扫描前会加载 `/opt/hypre/3.1.0-bisheng/env.sh` 并再次调用 `./make.sh`。在运行命令中传入 `TOOLCHAIN=bisheng`，使脚本重新构建时继续使用毕昇工具链。生成的日志名形如 `run_bisheng_np<N>_omp1_<R>.log`。

### AMD

本目录提供 AMD 运行脚本。请先在 AMD 服务器上构建或提供与本机 HYPRE/OpenMPI 安装兼容的可执行文件，使用同一套源文件（`main_time.f90` 和 D01 的 C/Fortran 接口源码）。`run_mpi_AMD.sh` 默认使用 `./main.out`，可用 `EXE=/path/to/exe` 覆盖。

AMD 脚本设置：

```bash
HYPRE_DIR=${HOME}/nfs/hypre/src/hypre
HYPRE_LIB=${HYPRE_DIR}/lib
LD_LIBRARY_PATH=${HYPRE_LIB}:${LD_LIBRARY_PATH}
```

运行扫描：

```bash
EXE=./main.out bash run_mpi_AMD.sh
```

AMD 的常用覆盖设置：

```bash
NP_LIST="1 2 4 8 16 24 32 48 64 128" OMP_LIST="1" NREPEAT=3 \
MPI_BIND_ARGS="--bind-to none" EXE=./main.out bash run_mpi_AMD.sh
```

生成的日志名形如 `run_AMD_np<N>_omp<T>_<R>.log`。

## 日志和绘图

绘图脚本读取以下命名格式的日志：

```text
run_gcc_np<N>_omp<T>_<R>.log
run_bisheng_np<N>_omp<T>_<R>.log
run_AMD_np<N>_omp<T>_<R>.log
```

将目标机器的日志放入本目录后，运行：

```bash
python3 plot-time-np.py
```

输出：

- `time_compare_gcc_bisheng_AMD_np.csv`：均值和标准差表。
- `time_compare_<available_compilers>_np_omp<T>.png`：按各可用的 OpenMP 线程数分别绘制 HYPRE 耗时和总耗时随 MPI 进程数的变化。

`plot-time-np.py` 会跳过缺少日志的平台。例如，只有 AMD 日志时，脚本仍会生成仅含 AMD 数据的汇总和图。

## 注意事项

- `clean.sh` 保留旧的 `run_*_np*_omp*_*.log` 和 `time_compare_gcc_bisheng_AMD_np.csv`。绘制新扫描结果之前，先移走或删除旧日志，否则新旧结果会一起计算平均值。
- 运行脚本默认使用 `mpirun --bind-to none`，不将 MPI 进程或 OpenMP 线程绑定到核心或 NUMA 节点。AMD 可用 `MPI_BIND_ARGS` 覆盖该设置，当前鲲鹏脚本的绑定参数固定在脚本中。
- `plot.py` 需要 `phi.dat`，只有设置 `WRITE_PHI=1` 运行基准程序时才会写出该文件。
