# D01_hypre_3Dxyz OpenMP 线程数性能对比

[English](README.md)

本算例在固定的 `320 x 80 x 320` 网格上测试 D01 直角坐标 Poisson/HYPRE 求解器的性能。基准程序固定使用 4 个 MPI 进程，并扫描每个进程的 OpenMP 线程数，对比鲲鹏 GCC、鲲鹏毕昇和 AMD 服务器。

如果 MPI 进程数不是 4，`main_time.f90` 就会退出。除非修改驱动程序中写死的 4 进程划分，否则应保持 `NP=4`。

## 文件

- `main_time.f90`：固定使用 4 个 MPI 进程的 OpenMP 线程数基准驱动程序。
- `make.sh`：鲲鹏构建入口，可使用 `TOOLCHAIN=gcc` 或 `TOOLCHAIN=bisheng`。
- `build_config.sh`：选择鲲鹏上的 HYPRE、MPI 和编译器环境。
- `make_AMD.sh`：使用本地 HYPRE 源码或安装目录的 AMD 构建入口。
- `run_threads_gcc.sh`：鲲鹏 GCC 的 OpenMP 线程数扫描。
- `run_threads_bisheng.sh`：鲲鹏毕昇的 OpenMP 线程数扫描。
- `run_AMD.sh`：AMD 的 OpenMP 线程数扫描。
- `plot-time.py`：解析 `run_*_np*_omp*_*.log`，打印平均耗时并写入综合对比图。
- `clean.sh`：删除构建产物、`phi.dat`、生成的日志和本地 PNG 对比图。

## 默认扫描设置

三个运行脚本默认均使用 `NP=4`、`NREPEAT=5` 及以下 OpenMP 线程数：

```bash
THREAD_LIST="1 2 4 6 8 10 12 14 16 20 22 24 26 28 30 32 48 64"
```

每次运行的启动命令为：

```bash
mpirun -np ${NP} --bind-to none \
  --mca pml ob1 \
  --mca btl self,vader,tcp \
  -x OMP_NUM_THREADS \
  -x LD_LIBRARY_PATH \
  ${EXE}
```

脚本只设置 `OMP_NUM_THREADS`，不设置 `OMP_PROC_BIND`、`OMP_PLACES` 或 NUMA 放置策略。

## 运行

基本步骤：

1. 构建可执行文件。
2. 运行对应的 OpenMP 线程数扫描脚本。
3. 将各平台的日志复制或保留在本目录。
4. 运行 `python3 plot-time.py`。

运行前，鲲鹏服务器需具备对应的 HYPRE/OpenMPI 环境：

- GCC 环境：`/opt/hypre/3.1.0-gcc/env.sh`
- 毕昇环境：`/opt/hypre/3.1.0-bisheng/env.sh`

`build_config.sh` 根据 `TOOLCHAIN` 选择工具链，默认值为 `gcc`。
设为 `TOOLCHAIN=gcc` 时，脚本使用 `ENV_SH=/opt/hypre/3.1.0-gcc/env.sh` 并生成 `main_gcc.out`。设为 `TOOLCHAIN=bisheng` 时，脚本使用 `ENV_SH=/opt/hypre/3.1.0-bisheng/env.sh` 并生成 `main_bisheng.out`。

如果默认环境文件不存在，设置 `ENV_SH`，或在运行 `make.sh` 前导出 `HYPRE_INC` 和 `HYPRE_LIB`。

### 鲲鹏 GCC

先构建：

```bash
TOOLCHAIN=gcc bash make.sh
```

再扫描 OpenMP 线程数：

```bash
ENV_SH=/opt/hypre/3.1.0-gcc/env.sh EXE=./main_gcc.out bash run_threads_gcc.sh
```

生成的日志名形如 `run_gcc_np4_omp<T>_<R>.log`。

### 鲲鹏毕昇

先构建：

```bash
TOOLCHAIN=bisheng bash make.sh
```

再扫描 OpenMP 线程数：

```bash
ENV_SH=/opt/hypre/3.1.0-bisheng/env.sh EXE=./main_bisheng.out bash run_threads_bisheng.sh
```

生成的日志名形如 `run_bisheng_np4_omp<T>_<R>.log`。

### AMD

先构建：

```bash
bash make_AMD.sh
```

`make_AMD.sh` 的默认设置为：

```bash
HYPRE_INC=${HOME}/nfs/hypre/src/hypre/include
HYPRE_LIB=${HOME}/nfs/hypre/src/hypre/lib
HYPRE_SRC=${HOME}/nfs/hypre/src
FC=mpif90
CC=mpicc
```

再扫描 OpenMP 线程数：

```bash
bash run_AMD.sh
```

生成的日志名形如 `run_AMD_np4_omp<T>_<R>.log`。

AMD 的常用覆盖设置：

```bash
HYPRE_DIR=${HOME}/nfs/hypre/src/hypre EXE=./main.out \
NP=4 NREPEAT=3 THREAD_LIST="1 2 4 8 16 32" bash run_AMD.sh
```

除非修改 `main_time.f90` 使其支持其他 MPI 划分，否则请保持 `NP=4`。

## 日志和绘图

绘图脚本读取以下命名格式的日志：

```text
run_gcc_np4_omp<T>_<R>.log
run_bisheng_np4_omp<T>_<R>.log
run_AMD_np4_omp<T>_<R>.log
```

将目标机器的日志放入本目录后，运行：

```bash
python3 plot-time.py
```

输出：

- `time_3compares_np4.png`：鲲鹏 GCC、鲲鹏毕昇和 AMD 的综合对比图。
- `/mnt/e/kunpeng/time_kp_amd_np4_ylim0_14.png`：如果存在 `/mnt/e/kunpeng`，还会在 Windows 侧写出这张图。

图的纵轴范围固定为 `0-14 s`。AMD 在高线程数下的异常值仍保留在数据中，超出纵轴范围的点可能不会显示在图中。

`plot-time.py` 会跳过缺少日志的平台。例如，仅有 GCC 和毕昇的日志时，图中不画 AMD 曲线。

## 注意事项

- `run_threads_gcc.sh`、`run_threads_bisheng.sh` 和 `run_AMD.sh` 不构建可执行文件。先运行对应的构建命令。
- `clean.sh` 会删除本地的 `run_gcc_*`、`run_bisheng_*` 和 `run_AMD_*` 日志。如果仍需要这些日志，先将它们移到其他位置再清理。
- 运行脚本使用 `mpirun --bind-to none`，因此 MPI 进程和 OpenMP 线程不会绑定到核心或 NUMA 节点。
