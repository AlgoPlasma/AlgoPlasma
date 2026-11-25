# FDTD 脉冲长时稳定性测试

[English](README.md)

本目录检验短脉冲激励后，电磁场在长时间无源传播中的稳定性。
本测试与制造解法（MMS）精度测试独立。

## 测试算例

- `test_pulse_2d_rz_tez.f90`
- `test_pulse_2d_rz_tmz.f90`
- `test_pulse_3d_cartesian.f90`
- `test_pulse_3d_cyl_m0.f90`
- `test_pulse_3d_cyl_m1.f90`

## 测试设置

- 各算例按需在周期方向（`z` 和 `phi`）采用周期边界。
- 三维直角坐标在 `x/y/z` 三个方向上均采用周期边界。
- 不使用 PML/ABC。
- 源项仅在前 `Npulse` 步启用，之后完全关闭。
- 脉冲在时间上使用平滑的 `sin^2` 包络，在空间上使用局域高斯包络。
- 源放在 `i>=2` 的位置，避开需要特殊处理的轴线点。
- `m=1` 算例使用与该模态一致的 `cos(phi)` 脉冲。

## 构建、运行与清理

按默认参数运行（`Ntotal=20000`、`monitor_every=100`、`Npulse=60`、`pulse_amp=1e-4`）

```bash
bash make.sh
bash run.sh
```

按自定义参数运行

```bash
bash run.sh 50000 200 80 5e-5
```

参数顺序如下。

`Ntotal monitor_every Npulse pulse_amp`

清理命令为 `bash clean.sh`。

## 输出

- 各算例的日志为 `logs/*.log`。
- 汇总文件为 `pulse_longrun_summary.csv`。

汇总表的列如下。

`case_name, CFL, Npulse, Ntotal, final_energy_ratio, post_pulse_growth_rate, result`

指标定义如下。

- `final_energy_ratio = E_final / E_at_pulse_end`
- `post_pulse_growth_rate = log(E_final/E_at_pulse_end) / (t_final - t_pulse_end)`

## 日志格式

表头

```text
# step,time,pulse_on,max_abs_E,max_abs_H,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_first_ring_max,axis_near_Ez_max,axis_near_Hz_max
```

示例行

```text
1200,2.316783E+01,0,5.270281E-05,1.242792E-04,7.502942E-09,3.808065E-05,3.724863E-05,3.808065E-05,3.724863E-05,3.612198E-06,1.022900E-05
```

## 结果判定

- `stable` 表示脉冲结束后保持有界，且没有持续增长。
- `marginal` 表示数值没有发散，但存在缓慢漂移。
- `unstable` 表示出现 NaN/Inf 或明显的持续增长。

## 二维 RZ TMz 对采样间隔的敏感性

- 当 `CFL=0.8, Ntotal=20000, Npulse=40, pulse_amp=1e-4` 且 `monitor_every=200` 时，偶尔会判定为 `marginal`。
- 同一演化过程的 `final_energy_ratio` 和 `post_pulse_growth_rate` 仍然较小（分别约为 `1.0069` 和 `6.47e-05`），而 `monitor_every=100/400` 时结果为 `stable`。
- 此处的 `marginal` 主要是采样窗口造成的。轴线处 `i=0` 与第一环 `i=1` 的峰值几乎同步，且幅值接近，说明轴线没有明显偏差。

## 三维柱坐标注意事项

- 重点关注 `axis_band` 和 `first_ring`。
- 对于 `m=1`，不把轴线上的非活跃自由度作为发散来源。
- 对于 `m=1`，外边界的 `Ephi` 幽灵值按柱坐标 `Hz` 更新所用的径向 `r*Ephi` 导数填充。
- 本测试关注场多次穿过周期边界后出现的缓慢不稳定，范围不限于脉冲衰减。

## 文件清单

所在目录

- `tests/005_maxwell/case_fdtd_pulse_longrun`

新增或更新的文件

- `pulse_common.f90`
- `test_pulse_2d_rz_tez.f90`
- `test_pulse_2d_rz_tmz.f90`
- `test_pulse_3d_cartesian.f90`
- `test_pulse_3d_cyl_m0.f90`
- `test_pulse_3d_cyl_m1.f90`
- `make.sh`
- `run.sh`
- `clean.sh`
- `README.md`
