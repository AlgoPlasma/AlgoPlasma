# 2D RZ TEz CPML Wave-Packet Reference Test

这个测试用来检查二维柱坐标 `r-z` 下 TEz 模式 CPML 对有限宽度电磁波包的吸收效果。

FDTD 和 CPML 更新都调用项目里的 Fortran Maxwell 子程序：

- `../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tez.f90`
- `../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_cpml_2d_rz_tez.f90`

Python 只负责画图和生成 GIF。

## 当前 Setup

- 坐标：2D cylindrical `r-z`
- 模式：TE
- 场量：`Ephi, Hr, Hz`
- 中央有效区域：`136 x 136`
- 小区域总网格：`160 x 160`
- 大参考区域：`568 x 576`
- `dr = dz = 1 mm`
- `dt = 2.335067793 ps`
- 小区域 CPML：`npml = 12`
- 参考区域 CPML：`npml_ref = 20`
- 中心波长：`lambda0 = 12 mm`
- 波包包络：`sigma_long = 18 mm, sigma_trans = 22 mm`
- 初始场：高斯包络调制的有限宽度电磁波包，不使用持续源
- 时间步：`450`
- late gate：`260`
- 静态 snapshot：`0, 150, 300, 450`
- GIF：`Ephi` 完整动画，每 `10` 步一帧

CPML 参数：

```text
kappa_max = 3
alpha_max = 0.02
m         = 3.5
R0        = 0.012
```

四个传播方向：

- `z_plus`：沿 `+z` 传播
- `z_minus`：沿 `-z` 传播
- `r_plus`：沿 `+r` 传播
- `r_minus`：沿 `-r` 传播

probe 记录量是 `Ephi`，位置在波包后方：

| case | probe index `(r,z)` |
|---|---:|
| `z_plus` | `(80, 36)` |
| `z_minus` | `(80, 124)` |
| `r_plus` | `(36, 80)` |
| `r_minus` | `(124, 80)` |

## 误差定义

小区域结果记为 `Ecompact`，大参考区域结果记为 `Eref`。误差定义为：

```text
Error_dB(n) = 20 log10( abs(Ecompact(n) - Eref(n)) / max(abs(Eref)) )
```

`late reflection error` 是从 `n = 260` 到 `n = 450` 之间的最大 `Error_dB`。这个时间段避开了 probe 处的主入射波，主要用来看 CPML 反射回来的残余波。

## 当前结果

当前保留的结果目录：

```text
output_lambda12mm_npml12_weak_ephi_gif/
```

结果：

| case | late reflection error | final interior energy |
|---|---:|---:|
| `z_plus` | -49.18886 dB | -24.06556 dB |
| `z_minus` | -49.30641 dB | -24.06455 dB |
| `r_plus` | -49.12683 dB | -24.09557 dB |
| `r_minus` | -50.39389 dB | -24.09364 dB |

最差 late reflection：

```text
worst late reflection = -49.12683 dB
```

## 参考解检查

为了确认 `Eref` 不会影响结果，只改变大参考区域大小做过检查：

```text
ref_extra = 200, 350, 500
```

三组得到的 `worst late reflection` 都是：

```text
-49.12683 dB
```

不同参考域之间的 `Eref` 差异在 late gate 后约为 `-300 dB` 量级，所以当前 `ref_extra = 200` 的大参考区域已经足够。

## 输出文件

当前目录中保留：

- `metrics.dat`
- `case_info.dat`
- `*_probe.dat`
- `probe_compare.png`
- `probe_error_db.png`
- `ephi_snapshots_*.png`
- `hz_snapshots_*.png`
- `ephi_animation_*.gif`
- `ephi_snapshot_*.dat`
- `hz_snapshot_*.dat`
- `ephi_final_*.dat`
- `hz_final_*.dat`

四个 `Ephi` GIF：

- `ephi_animation_z_plus.gif`
- `ephi_animation_z_minus.gif`
- `ephi_animation_r_plus.gif`
- `ephi_animation_r_minus.gif`

## 运行命令

生成当前保留结果：

```bash
./run.sh 12 output_lambda12mm_npml12_weak_ephi_gif 12 3 0.02 3.5 0.012 all 136 36 450 260 200 0
```

上面最后一个参数 `0` 表示静态 snapshot 只输出 `0,150,300,450`。

如果要重新生成每 10 步一帧的完整 GIF，可以临时跑：

```bash
./run.sh 12 output_lambda12mm_npml12_weak_ephi_gif_fullframes 12 3 0.02 3.5 0.012 all 136 36 450 260 200 10
```

然后只保留其中的 `ephi_animation_*.gif`。
