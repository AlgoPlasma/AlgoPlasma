# J02_neutral_sn_transport_2Drz

[中文](README.zh-CN.md) | [English](README.en.md)

本模块用离散纵标法（Discrete Ordinates Method，SN）求解二维 r-z 网格上的稳态中性粒子输运。
空间离散采用一阶不连续 Galerkin 方法（P1-DG），体积与面积按柱坐标几何计算。

空间算子沿用约化模型的柱坐标守恒形式：

```text
(1/r) d(r mu psi)/dr + d(eta psi)/dz + sigma_t psi = 0。
```

因此当 `mu` 非零时，逐方向常数 `psi` 不是径向自由流不变量。
测试应遵循这一约化方程，不能直接套用笛卡尔自由流不变性的假设。

当前阶段包括柱坐标几何、角度节点、等宽速率区间、入口外侧气体模型与入射粒子模型、入口
通量归一化、局部 P1-DG 算子、开放边界方向扫描、镜面/漫反射迭代、z-low
部分面入口积分，以及单元矩和内部面通量重构。
`gauss-chebyshev` 被明确保留为全圆 `midpoint` 节点集合及排列的别名，并不是另一套
数值求积规则。

相空间数组采用适合 Fortran 的 `psi(3,nr,nz,n_dir)` 布局，第一维对应局部基函数
`(1, xi, zeta)` 的三个系数。速度权重已经包含二维极坐标面积元
`v dv dtheta`。

核心算法不读取 PIC 网格或 NML 文件，也不负责写应用结果。局部 P1 多项式在角点
出现负值时，扫描器退回满足常数检验函数收支方程的 P0 解；这不是直接截断负值，
也不保证保留原 P1 解的单元平均值。

## 模型范围与维度

本模块保留两个空间坐标（r、z）和两个速度分量（v_r、v_z）。
速度用速率和一个平面角度离散，不包含周向速度及其动力学。
柱坐标的体积、面积和 r 权重不意味着完整的轴对称 2D3V 模型。

## 功能文件

各文件分别负责入口分布、通量归一化、边界、壁面反射、体损失和输运求解：

- `sub_J02_sn_inflow.f90`：入口外侧气体的 Maxwell 速度分布与入射粒子的速度分布转换。
- `sub_J02_sn_source.f90`：入口目标通量归一化与公共输入检查。
- `sub_J02_sn_boundary.f90`：部分入口的面积比例与局部区间。
- `sub_J02_sn_wall.f90`：由壁温确定的速度分布、镜面方向映射与漫反射通量归一化。
- `sub_J02_sn_loss.f90`：由损失频率计算单位路程损失系数。
- `sub_J02_sn_sweep.f90`：单次迎风扫描、边界组装及保正。
- `sub_J02_sn_reflection.f90`：反复调用同一扫描过程，控制反射迭代。

所有文件由同一个 mod 文件包含，串行与并行扫描共用单元求解过程。
零漂移直接调用 `sub_J02_build_drifted_maxwellian_inflow_shape`，两个漂移速度均设为零。

## 主要接口

- `sub_J02_solve_transport`：完整求解接口，选择一次扫描或反射迭代，并将单元场、
  内部面通量和边界通量集中返回到 `sn_transport_result_type`。
  四面入流数组 `boundary_inflow` 与下端入流数组 `zlo_inflow` 必须且只能提供一种；
  部分入口的区间端点必须成对提供。使用结果前先检查 `ierr == SN_SUCCESS`。
  扫描、反射迭代和重构仍可独立调用。

- `sub_J02_initialize_mesh`：检查径向、轴向单元边界和 有效单元标记。
- `sub_J02_build_geometry`：计算柱坐标体积、面面积和 P1 径向平均修正。
- `sub_J02_build_phase_quadrature`：将角度与速率组合为一组离散速度，并计算对应权重；角度数至少为
  8 且须被 4 整除，避免方向恰好落在坐标轴上。
- `sub_J02_build_drifted_maxwellian_inflow_shape`：按输入的温度 `K`、粒子质量
  `kg` 和漂移速度 `(u_r,u_z) [m/s]` 生成漂移 Maxwell 速度分布。
- `sub_J02_normalize_inflow_flux`：把非负 `inflow_shape` 归一化到指定粒子数通量。
- `sub_J02_sweep`：执行全方向 P1-DG 扫描；有反射时传入上一轮壁面场。可选输出
  `failed_direction/failed_i/failed_k` 分别指出失败方向和单元坐标。
- `sub_J02_build_partial_zlo_inlet`：把物理径向入口范围转换成各 z-low 面的柱坐标
  面积占比和局部 `xi` 区间。
- `sub_J02_build_wall_maxwell_shape`：构造保证漫反射离散通量归一化所需的壁温
  Maxwell 速度分布。
- `sub_J02_solve_source_iteration`：迭代反射边界直到达到给定相对误差，并返回迭代
  次数、最终变化量和失败位置。
- `sub_J02_reconstruct_cell_moments`：重构密度和平均速度。
- `sub_J02_reconstruct_internal_face_fluxes`：重构带符号的内部面粒子数通量密度。
- `sub_J02_reconstruct_open_boundary_fluxes`：把给定入射分布函数与单元内分布在面上的值
  分别积分成带符号的边界入流和出流，供 J03 构造冻结闭合；可选的 z-low `xi`
  区间会把两种通量都限制在部分面的开放区域。
- `sub_J02_build_sigma_from_frequency`：按 `sigma_t=nu/speed` 把电离频率转换为
  每个离散速度的单位路程损失系数。
- `sub_J02_build_mc_crossing_pdf_inflow_shape` 与
  `sub_J02_build_mc_crossing_bins_inflow_shape`：分别处理入射粒子的连续速度概率密度和各
  速度网格单元内的概率，避免混淆是否需要除以求积权重。

`sigma_t(nr,nz,n_dir)` 是单位为 `m^-1` 的单位路程损失系数；
`boundary_inflow(4,nr,nz,n_dir)` 是给定的入射速度分布函数。四个面的顺序是
`r-lo、r-hi、z-lo、z-hi`，出射方向上提供的边界值不会被上风扫描使用。

## 两种入口定义

入口外侧气体模型首先生成二维速度概率密度：

```text
f(v_r,v_z) = alpha/pi * exp(-alpha*((v_r-u_r)^2+(v_z-u_z)^2)),
alpha = particle_mass/(2*k_B*temperature)。
```

它在连续二维速度空间中的积分为 1；后续根据目标入口通量计算归一化系数，
得到实际入射分布函数。

入射粒子模型可以使用 Monte Carlo（蒙特卡洛）采样得到的速度统计。
`crossing_bin_probability(m)` 表示入射粒子的速度落在第 `m` 个速度网格单元内的概率。
程序先除以速度面积权重，将单元内的概率转换为概率密度，再除以法向速率，
即除以 `weight(m)*speed(m)*abs(Omega(m).normal)`，得到待归一化的边界分布。
按目标通量归一化后，各速度网格单元对应的入射粒子比例保持不变。
若输入已是速度概率密度，则使用 `crossing_pdf` 接口，只需除以法向速率。
入口外侧气体模型无需上述转换，直接按入口通量归一化。

所有可失败接口使用J02 内唯一的 `SN_ERR_*` 错误码。调用
`fun_J02_error_message(ierr)` 可得到具体原因。错误通过返回值报告；
只有显式给定正的 `progress_interval` 时才打印进度。

## 并行与串行构建

扫描支持 OpenMP（Open Multi-Processing）共享内存线程并行。
GNU Fortran 编译 J02 模块和最终链接时都需加 `-fopenmp`；
运行时可用 `OMP_NUM_THREADS=4 OMP_DYNAMIC=FALSE` 指定四个线程。
不加编译选项时，同一份源码按串行执行，调用参数不变。

并行计算按离散速度分配任务。每个任务只写自己的
`psi(:,:,:,m)`，其内部仍按迎风顺序逐单元求解。
入口、损失、上一轮分布和壁面归一化系数在扫描期间均只读。
每个进程内部的壁面归一化与最终重构仍由调用线程执行。
MPI 构建还会交换上游系数，并对收敛量作全局归约。
多个离散速度的任务同时失败时，待所有任务结束后报告编号最小的失败任务；
失败返回的场不能继续当作有效解使用。

SN 应用测试脚本默认启用 OpenMP，`OPENMP=0` 可关闭。
普通模块测试默认串行，`OPENMP=1` 可启用；独立的
`run_parallel.sh` 同时检查两种构建。
线程数不等于加速比；小网格、内存带宽和串行步骤都可能限制实际性能。

## 空间 MPI 与混合构建

MPI 把 r-z 网格分成相邻面匹配的矩形块，每个进程只存储本块单元，
但保留全部离散速度。同一进程内的离散速度可进一步使用 OpenMP 并行计算。

使用 MPI Fortran 编译器，增加 `-cpp -DJ02_USE_MPI`；
混合构建还需在编译和链接时加 `-fopenmp`。
不定义 MPI 宏的普通构建不依赖 MPI 库。

- `sub_J02_sn_partition.f90`：`sub_J02_initialize_partition` 接收应用建立的
  非周期二维 Cartesian 通信器；可选 `first/count` 指定自定义空间块。
  J02 不负责 MPI 启停，不复制全局场。
- `sub_J02_initialize_boundary_types(..., partition=part)`：连接进程交界面，
  使用 `SN_FACE_REMOTE`，不把它当作物理 OPEN/WALL。
- `sub_J02_sweep(..., partition=part)` 和
  `sub_J02_solve_transport(..., partition=part)`：
  每个进程传入本地网格与场，返回本地结果；所有进程集体调用，失败索引使用全局位置。
- `sub_J02_sn_mpi_sweep.f90`：内部完成上游 DG 系数通信与交界面通量重构，
  复用原有单元算子和扫描内核。
- `result%partition_flux(4,nr,nz)`：仅 REMOTE 面非零，按坐标正向计正；
  入口和开放出口的入射/出射数组不包含这些面。

混合运行至少需要 `MPI_THREAD_FUNNELED`，求解由 MPI 主线程发起。
各进程的求积、实数精度与停止条件必须一致。通信器由应用保持有效并最终释放，
同一通信器上不能交叠启动多次求解。
当前不支持周期分区、非匹配网格或零单元块；支持包含单元但全部标记为无效的分区。

应用先建立 Cartesian 通信器和空间分区，用全局入口面积归一化入流，
再由各进程共同调用输运接口。使用 Open MPI 时，`mpiexec -np N`
指定进程数，混合构建中的 `OMP_NUM_THREADS` 指定每个进程的线程数。
纯 MPI 构建不添加 `-fopenmp` 编译和链接选项。

一致性检查使用 `tests/012_fluid/J02_neutral_sn_transport_2Drz/run_mpi.sh`。
B0/ION 应用程序与 J03 当前仍是单域接口；分区结果交给现有 J03 前，
需要应用自行组装全局单元场与内部面，当前尚未实现分布式 J03 或自动汇集过程。

## 源码组织

源码遵循 AlgoPlasma 现有包装约定：唯一的
`mod_J02_neutral_sn_transport_2Drz.f90` 模块保存共享类型，并通过预处理
`include` 纳入按职责拆分、可独立阅读的 `sub_J02_sn_*.f90` 实现文件。

与仓库现有 Fortran 算法保持一致，源码使用默认 `real`；配套测试通过
`-fdefault-real-8` 按双精度进行数值验证；并行一致性测试还覆盖编译器默认实数精度。
