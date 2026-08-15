# 2D RZ TMz CPML Wave-Packet Reference Test

这个测试和 `case_cpml_2d_rz_tez_wavepacket_ref` 同一套思路，用有限宽度波包比较 compact CPML 区域和更长 reference 区域。

- 坐标：2D cylindrical `r-z`
- 模式：TM
- 场量：`Er, Ez, Ha`
- 默认有效区域：`136 x 136`
- 默认 CPML：`npml = 14`
- 默认中心波长：`lambda0 = 12 mm`
- CFL：`0.8`
- 默认时间步：`450`
- 方向：`z_plus`, `z_minus`, `r_plus`

`r=0` 是轴线，不布置内侧径向 CPML，所以这里不测 `r_minus`。`z_*` 记录 `Er` probe，`r_plus` 记录 `Ez` probe。

运行：

```bash
./run.sh
```

指定输出目录：

```bash
./run.sh 12 output_lambda12mm_npml14 14 3 0.02 3.5 0.012
```

当前默认结果保存在 `output_lambda12mm_npml14/`：

| case | late reflection error | final interior energy |
|---|---:|---:|
| `z_plus` | -47.78 dB | -23.17 dB |
| `z_minus` | -49.18 dB | -23.17 dB |
| `r_plus` | -48.61 dB | -24.03 dB |
