# 3D Cartesian CPML Plane-Wave Packet Reference Test

这个测试用来和 `case_cpml_2d_rz_tez_wavepacket_ref` 对照。这里改成三维笛卡尔坐标，初始场是横向均匀的平面波波包，主要看 CPML 对平面波的吸收效果。

FDTD 和 CPML 更新都调用项目里的 Fortran Maxwell 子程序：

- `../../../E_Maxwell/E03_Maxwell_3Dxyz/mod_E03_fdtd_3d_cartesian.f90`
- `../../../E_Maxwell/E03_Maxwell_3Dxyz/mod_E03_cpml_3d_cartesian.f90`

测试 setup：

- 坐标：3D Cartesian `x-y-z`
- 场量：`Ex, Ey, Ez, Hx, Hy, Hz`
- 默认中央有效区域：传播方向 `136 cells`，横向 `8 x 8 cells`
- 传播方向长度可以在运行时改，比如这次加大到 `300 cells`
- 默认 CPML：`npml = 12`
- 默认小区域总网格：传播方向 `160 cells`，横向 `8 x 8 cells`
- 默认大参考区域：只在传播方向加长，传播方向长度为 `136 + 2*200 + 2*20 = 576`，横向为 `8 x 8 cells`
- `dx = dy = dz = 1 mm`
- `dt = 0.99 / (c * sqrt(1/dx^2 + 1/dy^2 + 1/dz^2))`
- 默认时间步：`450`
- 默认中心波长：`lambda0 = 12 mm`
- 波包包络：`sigma_long = 18 mm`
- 初始场：横向均匀的高斯包络调制平面波波包，不使用持续点源
- 默认波包中心离后方 CPML 内边界 `36 mm`，离吸收端 CPML 内边界 `100 mm`
- 方向：`x_plus`, `x_minus`, `y_plus`, `y_minus`, `z_plus`, `z_minus`
- 横向边界：周期复制
- 传播方向边界：CPML

比较方式：

- compact 区域和 large reference 区域使用同一个初始平面波波包。
- probe 放在波包后方，记录对应的电场分量：
  - `x_*` 记录 `Ey`
  - `y_*` 记录 `Ez`
  - `z_*` 记录 `Ex`
- `Error_dB = 20 log10(abs(compact-reference)/max(abs(reference)))`
- 默认 `late reflection error` 使用 `n = 260..450` 的最大误差；长区域测试改成 `n = 800..1200`。
- 额外记录最终内部能量相对初始内部能量的 dB 值。

运行：

```bash
./run.sh
```

指定参数运行：

```bash
./run.sh 12 output_lambda12mm_npml12 12 3 0.02 3.5 0.012
```

加大传播方向区域的运行例子：

```bash
./run.sh 12 output_lambda12mm_npml12_long300 12 3 0.02 3.5 0.012 all 18 300 36 1200 800 500
```

这组参数表示：传播方向 interior 为 `300 cells`，波包中心仍离后方 CPML `36 mm`，所以它离吸收端 CPML 内边界约 `264 mm`；总步数 `1200`，从 `n = 800` 开始统计 late reflection，参考区域额外加长 `500 cells`。

输出：

- `metrics.dat`
- `*_probe.dat`
- `probe_compare.png`
- `probe_error_db.png`
- `field_slices_*.png`
- `field_slice_*.dat`

当前已跑结果：

默认 `lambda0 = 12 mm, npml = 12, kappa_max = 3, alpha_max = 0.02, m = 3.5, R0 = 0.012`，结果保存到 `output_lambda12mm_npml12/`：

| case | late reflection error | final interior energy |
|---|---:|---:|
| `x_plus` | -43.45 dB | -49.41 dB |
| `x_minus` | -44.82 dB | -47.41 dB |
| `y_plus` | -43.45 dB | -49.41 dB |
| `y_minus` | -44.82 dB | -47.41 dB |
| `z_plus` | -43.45 dB | -49.41 dB |
| `z_minus` | -44.82 dB | -47.41 dB |

加厚到 `npml = 24` 后，其他参数不变，结果保存到 `output_lambda12mm_npml24/`：

| case | late reflection error | final interior energy |
|---|---:|---:|
| `x_plus` | -71.38 dB | -48.51 dB |
| `x_minus` | -76.83 dB | -49.53 dB |
| `y_plus` | -71.38 dB | -48.51 dB |
| `y_minus` | -76.83 dB | -49.53 dB |
| `z_plus` | -71.38 dB | -48.51 dB |
| `z_minus` | -76.83 dB | -49.53 dB |

扩大传播方向区域后，`lambda0 = 12 mm, npml = 12`，结果保存到 `output_lambda12mm_npml12_long300/`：

| case | late reflection error | final interior energy |
|---|---:|---:|
| `x_plus` | -42.54 dB | -54.59 dB |
| `x_minus` | -46.19 dB | -62.26 dB |
| `y_plus` | -42.54 dB | -54.59 dB |
| `y_minus` | -46.19 dB | -62.26 dB |
| `z_plus` | -42.54 dB | -54.59 dB |
| `z_minus` | -46.19 dB | -62.26 dB |

和原来的 `136 cells` 对比，worst late reflection 从约 `-43.45 dB` 变成约 `-42.54 dB`，基本没有提升。这说明当前 `npml = 12` 的主要限制不是初始波包离吸收端太近，而更像是 12 层 CPML 的离散剖面本身；把 CPML 加厚到 `24` 层才会明显降到 `-71 dB` 左右。

排查记录：

- 最开始为了加速，把传播方向 interior 缩到 `72 cells`，波包中心离后方 CPML 只有 `24 mm`。在 `sigma_long = 18 mm` 时，波包尾巴在 CPML 内边界仍有约 `17%` 幅值，这会严重污染反射测试。
- 修正为 `136 cells` 后，`npml = 12` 从约 `-20 dB` 提升到约 `-31 dB`。
- 继续扫描参数后发现，`R0 = 1e-6/1e-8` 对 12 层离散 CPML 来说过强，`sigma` 太大导致界面离散失配。改成 `R0 = 0.012, kappa_max = 3, alpha_max = 0.02, m = 3.5` 后，`npml = 12` 达到约 `-43 dB`。

所以这个测试里之前吸收差的主要原因不是三维笛卡尔 CPML 本身不行，而是波包离 CPML 太近，以及 `sigma` 剖面过强。

注意：

- Python 只负责画图，不做 FDTD/CPML 更新。
- 这个测试刻意使用横向均匀平面波波包，所以横向网格不需要很宽；这样能把测试重点放在传播方向 CPML 的平面波吸收上，同时避免 3D 参考解太慢。
