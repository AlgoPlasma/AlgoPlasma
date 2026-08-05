# G_collision

[中文](README.zh-CN.md) | [English](README.md)

`G_collision` 收集 AlgoPlasma 中的碰撞模型。当前实现为 `G01_MCC`，用于基于截面表的 Monte Carlo Collision (MCC) 采样。

## 子目录

- `G01_MCC`: null-collision MCC；包含截面表读取、截面插值、电子-中性粒子碰撞、离子-中性粒子碰撞和电离二次粒子处理。

## 依赖

- 碰撞例程使用 MPI；调用方需要在 MPI 程序中运行。
- 源码通过 Fortran `include` 组织，构建时需要启用预处理并配置 include 路径。
- 截面表、粒子质量、电荷常数和 `eV` 换算因子需要由调用方保持单位一致。

## 文档

完整公式、流程说明和 API 入口见 Sphinx 的 `G_collision` / `G01_MCC` 页面。
