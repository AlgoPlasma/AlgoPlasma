# H_MPI_Exchange

[中文](README.zh-CN.md) | [English](README.md)

`H_MPI_Exchange` 提供 AlgoPlasma 在 MPI 区域分解中使用的数据交换例程。

## 子目录

- `H01_mpi_exchange_field`: 标量场一层 ghost/halo cell 交换，接收后覆盖 ghost 层。
- `H02_mpi_exchange_par`: 多物种粒子跨 MPI 子域迁移交换，接收后转移粒子所有权。
- `H03_mpi_exchange_den`: scatter 后密度边界累加交换，接收后把邻居贡献加到本地边界节点。

## 依赖

- 所有例程依赖 MPI，并直接使用 `MPI_COMM_WORLD`。
- 源码通过 Fortran `include` 组织，构建时需要启用预处理并配置 include 路径。
- H01 和 H03 的 blocking send/recv 使用奇偶顺序避免死锁；H02 使用两阶段非阻塞通信。

## 文档

详细索引约定、通信流程、测试期望值和 API 说明见 Sphinx 的 `H_MPI_Exchange` 页面。
