# 3D Cylindrical CPML Wave-Packet Reference Test

这个测试按现有 wavepacket reference 的方式，检查 3D 柱坐标 CPML 的 `z` 向吸收。

- 坐标：3D cylindrical `r-phi-z`
- 模式：`m=0 TM01`
- 主要场量：`Er, Ez, Hphi`
- 默认传播方向有效长度：`136 cells`
- 默认径向网格：`48 cells`
- 默认方位网格：`4 cells`
- 默认 CPML：`npml = 12`
- 方向：`z_plus`, `z_minus`

这里先只测 `z` 两侧 CPML。初始场不是直接塞解析 Gaussian，而是在更长的 reference 域里用 `TM01` 软源激发波包，等它离开源区后截取 compact 窗口作为 compact/reference 的共同初始场。图片里显示的是 `sqrt(r) Ez`，这样不会把物理体积为零的轴线单元画得过重；probe 和误差仍然用原始 `Ez`。

运行：

```bash
./run.sh
```

指定输出目录：

```bash
./run.sh 18 output_lambda18mm_npml12 12 3 0.02 3.5 0.012
```

生成每 10 步一帧的 GIF：

```bash
./run.sh 18 output_lambda18mm_npml12_gif 12 3 0.02 3.5 0.012 all 18 136 36 450 260 200 10
```

当前默认结果保存在 `output_lambda18mm_npml12/`：

| case | late reflection error | final interior energy |
|---|---:|---:|
| `z_plus` | -35.24 dB | -39.62 dB |
| `z_minus` | -36.38 dB | -36.04 dB |
