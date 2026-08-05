# D05_phi1d_to_phi3d

[中文](README.zh-CN.md) | [English](README.md)

将 HYPRE Poisson 求解器输出的一维解向量展开为含幽灵格点的三维数组，并对 phi 场进行 MPI halo 交换。

## 文件

- `mod_D05_phi1d_to_phi3d.f90`: 模块包装文件。
- `sub_D05_phi1d_to_phi3d.f90`: 主子程序。
- `inc_exchange_in_x/y/z.f90`: 各 Cartesian 方向的 MPI halo 交换。
- `inc_send_recv.f90`: 先发后收的点对点通信模式（奇数 rank）。
- `inc_recv_send.f90`: 先收后发的点对点通信模式（偶数 rank）。

## 主接口

```fortran
call sub_D05_phi1d_to_phi3d(il, iu, phi1d, phi3d, &
    mpi_n, rank_to_ijk, domain_split, ijk_to_rank, l)
```

- `phi1d(1:nx*ny*nz)`：HYPRE 输出的一维解，循环顺序为 `i, j, k`。
- `phi3d(il(1)-1:iu(1)+1, ...)`：含单层幽灵格点的三维输出数组。
- `l(1:3)`：各方向物理域长度，用于判断是否为周期边界。

调用后，`phi3d` 的幽灵格点已由相邻 MPI rank 的数据填充。非周期边界的幽灵格点需由调用方在此后自行设置。

## 幽灵格点约定

rank 的右幽灵格 `phi3d(iu(1)+1,:,:)` 来自右邻居的 `phi3d(il(1),:,:)`，左幽灵格 `phi3d(il(1)-1,:,:)` 来自左邻居的 `phi3d(iu(1),:,:)`。这与 E 场交换（H01）使用次边界格点的约定不同。

## 依赖

需要 MPI。
