# H01_mpi_exchange_field

[中文](README.zh-CN.md) | [English](README.en.md)

`H01_mpi_exchange_field` 交换标量场的一层 ghost/halo cell。

## 文件

- `mod_H01_mpi_exchange_field.f90`: 模块包装器。
- `sub_H01_mpi_exchange_field.f90`: 场量 ghost 层交换主例程。
- `inc_exchange_in_x.f90`: x 方向交换实现。
- `inc_exchange_in_y.f90`: y 方向交换实现。
- `inc_exchange_in_z.f90`: z 方向交换实现。
- `inc_send_recv.f90`: blocking send 后 recv。
- `inc_recv_send.f90`: blocking recv 后 send。

## 主接口

`sub_H01_mpi_exchange_field(il,iu,f,mpi_n,rank_to_ijk,domain_split,ijk_to_rank,l)`

## 注意

`f` 需要包含一层 ghost cell，范围为 `il(d)-1:iu(d)+1`。非周期物理边界条件不在该例程内完成。
