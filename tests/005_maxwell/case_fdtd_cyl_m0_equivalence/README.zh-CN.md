# FDTD 三维柱坐标 m=0 等价性测试

[English](README.md)

本算例仅保留一个程序 `test_geom_m0_equivalence.f90`。
它检验三维柱坐标 `m=0` 与二维 RZ 更新在 TMz 和 TEz 模式下的等价性。

## 通过标准

- TMz 和 TEz 均须满足 `combined_rel_L2 <= 2e-2`。
- TMz 和 TEz 均须满足 `combined_rel_Linf <= 1e-1`。

## 构建、运行与清理

构建命令

```bash
bash make.sh
```

按默认参数运行

```bash
bash run.sh
```

按自定义参数运行

```bash
bash run.sh <Nequiv>
```

参数说明
- `Nequiv` 为更新步数，默认值为 `600`。

清理命令

```bash
bash clean.sh
```

## 输出

- 日志文件 `logs/m0_equivalence.log`
- 汇总文件 `m0_equivalence_summary.csv`

## 相关测试结果

- 最后更新于 `2026-04-09`。
- 运行命令为 `bash run.sh`。
- 在当前工作区的运行结果为 `PASS`。

结果汇总

```csv
m0_equivalence,TMz,  2.776E-15,  1.059E-14,pass,Er,Ez,Hphi
m0_equivalence,TEz,  4.456E-16,  8.833E-16,pass,Ephi,Hr,Hz
```

生成文件
- `logs/m0_equivalence.log`
- `m0_equivalence_summary.csv`
