# J02 非均匀速率分组测试

[English](README.md)

比较 [J02](../../../../J_Fluid/J02_neutral_sn_transport_2Drz/README.zh-CN.md) 的等宽、二次幂边界与分段等宽速率求积，
检验分布矩和固定空间网格上的输运误差。速度积分采用约化二维测度 `v dv dtheta`；
算例包含给定损失频率，CEX 碰撞需另行验证。

## 环境与运行

需要 GNU Fortran、Python 3、NumPy 和 Matplotlib。从仓库根目录运行：

```bash
python3 tests/012_fluid/J02_neutral_sn_transport_2Drz/nonuniform_speed/run_comparison.py
```

脚本以串行、8 字节实数配置编译并运行 [compare_speed_grids.f90](compare_speed_grids.f90)，
开启数组检查和浮点异常捕获。参考输运解使用 16384 个速率组，峰值内存约 1.5 GB。
`FC` 可指定兼容的 Fortran 编译器，`--output` 可指定结果目录。

已有 CSV 时，只重画图和生成报告：

```bash
python3 tests/012_fluid/J02_neutral_sn_transport_2Drz/nonuniform_speed/run_comparison.py --analyze-only
```

两次运行须使用相同的输出目录；自选目录时，两条命令都添加 `--output /path/to/output`。

## 对比设计

速率上限固定为 16000 m/s，组数依次为 16、32、64、128、256、512：

| 分组 | 边界或组数分配 |
| --- | --- |
| `uniform` | 等宽区间 |
| `power2` | `v_i = 16000*(i/N)^2` |
| `piecewise` | 边界为 `[0,1600,9000,15000,16000]` m/s，四段组数按 `8:2:5:1` 分配 |

每个区间的节点为速率中点，径向速度积分权重为 `(v_hi-v_lo)*(v_hi+v_lo)/2`。
测试采用质量 `2.18017e-25 kg` 的二维漂移 Maxwell 分布：

- 冷分量：550 K，轴向漂移 300 m/s。
- 快分量：轴向漂移 12000 m/s，各速度分量的热标准差为 600 m/s。
- 混合分布：按粒子数取 90% 冷分量和 10% 快分量。

| 检查 | 比较基准 |
| --- | --- |
| 原始分布矩 | 使用 512 个角度，核对未经离散归一化的密度、轴向流密度、原始二阶矩和正轴向半空间通量；参考值为无限二维速度域解析积分 |
| 开放通道输运 | 固定 `2×6` 空间网格、128 个角度、单位入口粒子通量密度和 `2e4 s^-1` 损失频率；密度误差按柱坐标体积加权相对 L1 计算 |
| 参考解细化 | 在相同空间和角度网格上比较 8192 与 16384 个等宽速率组 |
| 角度与截断 | 独立检查角度数 128–1024、速率上限 14000–18000 m/s；另比较通道输运的 128/256 角度结果 |

分段位置利用了本例的分布信息，适用性须随输入分布重新评估。
参考解细化差衡量此次速率分辨率的变化；完整输运精度还需独立检查空间、角度和截断误差。
极粗速率网格的反射源迭代也需单独检查收敛性。

## 通过条件

[run_comparison.py](run_comparison.py) 检查三个 CSV 的行数及全部数值有限性，并要求：

- 通道输运的最大相对粒子收支误差小于 `1e-10`。
- 在 512 个速率组下，三种分组、三种分布的四项原始矩相对解析误差均小于 `1e-3`。
- 各次输运求解成功；失败时程序返回非零状态。

输运场相对参考解的误差及参考解细化差作为诊断结果保存。
守恒检查与精度检查使用各自的比较基准。

## 输出与读图

默认输出位于上一级测试目录的 `build/nonuniform_speed/`：

| 文件 | 内容 |
| --- | --- |
| `moments.csv` | 54 组原始矩及解析值 |
| `transport.csv` | 21 组输运误差、收支和运行时间 |
| `angle_cutoff.csv` | 21 组角度与截断检查 |
| `speed_grids.png/.svg` | 相同 32 组下的速率边界、中点及分布所在速度范围 |
| `convergence.png/.svg` | 随速率组数变化的原始矩和通道密度误差 |
| `report.md`、`summary.json` | 中文分析报告与机器可读汇总 |
| `compile/`、`compile.log`、`run.log` | 可执行文件、模块及编译/运行记录 |

读 `speed_grids` 时比较节点在冷、快分量附近的分布；
读 `convergence` 时在相同组数下比较误差，并结合参考解细化线判断低误差区间。
脚本保留已有目录，重复运行会覆盖同名结果；`--analyze-only` 读取现有 CSV 并更新图和报告。

## 模块与并行检查

常规 [J02 测试](../README.zh-CN.md) 和 `run_parallel.sh` 包含
[test_J02_nonuniform_quadrature.f90](../source_f90/test_J02_nonuniform_quadrature.f90)。
空间 MPI 程序支持第四个参数 `nonuniform`，使用四组边界 `[0,0.2,0.6,1.5,3]`。
先运行上级目录的 `run_mpi.sh` 完成并行构建，再从仓库根目录执行指定组合：

```bash
OMP_NUM_THREADS=2 OMP_DYNAMIC=FALSE mpiexec -np 4 \
  tests/012_fluid/J02_neutral_sn_transport_2Drz/build/mpi/r8/hybrid/test.out 2 2 custom nonuniform
```

此项需要 MPI 和支持 OpenMP 的 Fortran 编译器。
