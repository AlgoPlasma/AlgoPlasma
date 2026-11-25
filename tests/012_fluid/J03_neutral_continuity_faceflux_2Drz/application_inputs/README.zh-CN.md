# Application Inputs

[English](README.md)

本目录提供 FM/SN → J03 应用共用的非均匀网格。B0 为无体损失算例，
ION 使用给定的损失频率；FM 应用目前只实现 B0。
网格是几何输入，参考密度和通量由每次前处理计算生成。

## 文件与格式

| 文件 | 内容 |
| --- | --- |
| `grid_r.dat` | 256 个径向单元的边界与宽度，长度单位 m |
| `grid_z.dat` | 256 个轴向单元的边界与宽度，长度单位 m |
| [../application_case.f90](../application_case.f90) | 共用的有效区域和 ION 损失频率定义 |

每个网格文件有 256 个数据行，四列依次为：

```text
cell_index  lower_edge_m  upper_edge_m  width_m
```

编号从 1 开始，相邻单元边界须连续，宽度须为正且等于上下边界之差；
径向坐标须非负。空行和以 `#` 开头的注释行可省略。

有效区域按 Fortran 从 1 开始的下标定义为 `(65:192,1:72)` 与 `(:,73:256)`，
共 56320 个单元。两种前处理和两个 J03 驱动共用这一索引布局。
自定义输入目录须包含相同的文件名并保持 256×256 网格及有效区域索引。

## 给定损失频率

B0 的体损失频率为零。ION 在有效单元中心计算以下余弦窗口：

```text
nu(r,z) = 1e5*cos(pi*(r-rmid)/(rmax-rmin))*cos(pi*(z-zmid)/(zmax-zmin)) [s^-1]
rmin = 0.013683098220475191 m
rmax = 0.024672244366128356 m
zmin = 0.0024709824265487373 m
zmax = 0.010022411397665104 m
rmid = (rmin+rmax)/2
zmid = (zmin+zmax)/2
```

窗口外及非有效单元的损失频率为零。该定义用于检验给定损失下的输运，
无需历史掩膜、密度或电离场文件；损失场由上述函数直接生成。

## 输入检查与应用入口

需要 Python 3 标准库。从仓库根目录运行：

```bash
python3 tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/validate_application_inputs.py tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/application_inputs
```

通过时输出 `Application input grid: PASS`；文件缺失或网格格式错误时返回非零状态。
应用脚本在编译前执行同一检查。

运行与输出说明见 [FM 应用](../application_reference_J01/README.zh-CN.md) 和
[SN 应用](../application_reference/README.zh-CN.md)。
