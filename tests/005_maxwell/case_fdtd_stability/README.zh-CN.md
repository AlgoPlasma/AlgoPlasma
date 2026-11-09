# FDTD 长时无源稳定性测试

[English](README.md)

本目录对 Maxwell 核心内核进行长时间无源稳定性检查。
本测试与制造解法（MMS）精度测试独立。

## 目标

- 进行长时间无源积分并检查解是否有界。
- 主要监测以下现象。
  - `max_abs_E/H` 和 `total_energy` 的缓慢增长。
  - 轴线附近的场积累（`axis_band_max`、`i0_active_max`）。
  - 第一环的场放大（`first_ring_max`、`i1_first_ring_max`）。
- 禁用 MMS 源项注入，不调用 `add_e_source/add_h_source`。

## 测试算例

- `test_stability_2d_rz_tmz.f90`
- `test_stability_2d_rz_tez.f90`
- `test_stability_3d_cyl_m0.f90`
- `test_stability_3d_cyl_m1.f90`

## 最新基线（`CFL=0.8`，`nsteps=20000`）

| 算例 | final_energy_ratio | 结果 |
|---|---:|---|
| 2D_RZ_TMz | 9.5997E-01 | stable |
| 2D_RZ_TEz | 1.0114E+00 | stable |
| 3D_CYL_M0 | 9.8467E-01 | stable |
| 3D_CYL_M1 | 9.4779E-01 | stable |

早先的一次 `3D_CYL_M1` 运行使用通用的外边界幽灵值复制规则，能量增长集中在外径边界带（`i=nr-1`）。占主导的是该处的 `Hz`，其次是 `Hr`，增长并未集中在轴线附近的分量。

## 边界与轴线处理

- 所有测试均不使用 PML/ABC。
- 柱坐标内核在以下方向采用周期处理。
  - `z` 方向采用周期边界。
  - 三维柱坐标的 `phi` 方向采用周期边界。
- `r` 方向沿用现有轴线闭合，对普通分量采用外侧幽灵值复制，无需其他边界模型。
- 对于三维柱坐标 `m=1` 测试，填充外侧 `Ephi` 幽灵值时使 `r*Ephi` 跨外侧幽灵单元保持连续。
- 对于 `m=1` 和 TM，判断是否发散时排除轴线上的非活跃自由度（`i=0` 处的 `Ephi/Hr`）。

三维柱坐标下，`Hz` 的径向项使用 `r*Ephi` 的导数。外径处的幽灵值和边界闭合须与该离散格式一致。直接使用 `Ephi(nr)=Ephi(nr-1)` 可能导致 `m=1` 算例中的场缓慢增长。

A/B 对照仅调整了 `m=1` 稳定性测试中的外径 `Ephi` 幽灵值规则，使它与半径加权一致。`final_energy_ratio` 由 `3.9787` 降至 `9.4779E-01`，`result` 从 `marginal` 变为 `stable`。这表明主要问题出在外径处的径向幽灵值及边界闭合，而非轴线项。

## 构建、运行与清理

按默认参数运行（`nsteps=20000`，`monitor_every=100`）

```bash
bash make.sh
bash run.sh
```

自定义步数和监测间隔

```bash
bash run.sh 50000 200
```

清理命令为 `bash clean.sh`。

## 输出

- 各算例的日志为 `logs/*.log`。
- 汇总文件为 `stability_summary.csv`。

`stability_summary.csv` 的列如下。

`case_name, CFL, nsteps, final_energy_ratio, max_abs_E_final, max_abs_H_final, result`

`result` 允许以下值。

- `stable`
- `marginal`
- `unstable`

## 日志格式

监测日志表头

```text
# step,time,max_abs_E,max_abs_H,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_first_ring_max
```

`m=1` 时包含的额外列

```text
# step,time,max_abs_E,max_abs_H,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_first_ring_max,axis_near_Ez_max,axis_near_Hz_max
```

示例行

```text
200,2.430000E-01,9.812345E-05,8.456789E-05,1.603210E-08,1.204321E-05,9.876543E-06,7.654321E-06,8.765432E-06
```

汇总行（标准输出）

```text
SUMMARY_CSV,3D_CYL_M1,0.800,20000,9.4779E-01,5.44E-05,5.92E-05,stable
```

## 文件清单

所在目录

- `tests/005_maxwell/case_fdtd_stability`

Fortran 文件

- `stability_common.f90`
- `test_stability_2d_rz_tmz.f90`
- `test_stability_2d_rz_tez.f90`
- `test_stability_3d_cyl_m0.f90`
- `test_stability_3d_cyl_m1.f90`

脚本

- `make.sh`
- `run.sh`
- `clean.sh`

## 注意事项

- 本组测试只验证稳定性。收敛阶由独立的测试验证。
- `case_fdtd_mms_convergence` 的构建和运行流程独立。
