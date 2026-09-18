# J_Fluid

[中文](README.zh-CN.md) | [English](README.en.md)

`J_Fluid` 放置 AlgoPlasma 的流体方程更新例程。

## 子目录

- `J01_free_molecular`: 自由分子粒子前处理，以及三维连续性更新和二维给定速度通量工具。所有 J01 源码放在同一目录，按两个模块分别调用。
  面通量的二维柱坐标稳态自由分子历史求解器。
- `J02_neutral_sn_transport_2Drz`: 二维轴对称 r-z 网格上的中性粒子 SN P1-DG 前处理组件。
- `J03_neutral_continuity_faceflux_2Drz`: 接收 J01/J02 参考面通量并持续求解二维柱坐标连续性方程。

## 约定

- J01 保留原三维归一化接口，并增加使用真实体积/面积的二维 r-z FM 接口。
- J02 使用实际 r-z 单元边界坐标和显式柱坐标几何量；核心算法不读取 PIC 输入文件。
- J03 只冻结 J01/J02 产生的输运闭合，不在连续性迭代中重新运行输运求解器。

## 文档

详细的数值格式、索引约定和 API 说明见 Sphinx 的 `J_Fluid` 页面。
