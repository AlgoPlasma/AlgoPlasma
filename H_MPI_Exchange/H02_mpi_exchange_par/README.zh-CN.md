# H02_mpi_exchange_par

[中文](README.zh-CN.md) | [English](README.md)

`H02_mpi_exchange_par` 在 3D Cartesian MPI 区域分解中迁移多物种粒子。

## 文件

- `mod_H02_mpi_exchange_par.f90`: 保存邻居元数据、tag、缓存缓冲区和 `DIR_ID`。
- `sub_H02_mpi_exchange_par_init.f90`: 初始化邻居列表、tag 和缓存缓冲区。
- `sub_H02_mpi_exchange_par.f90`: 执行粒子计数交换、payload 交换和接收粒子追加。

## 主接口

- `sub_H02_mpi_exchange_par_init(ns,npm,mpi_n,rank_to_ijk,domain_split,ijk_to_rank)`
- `sub_H02_mpi_exchange_par(ns,np,npmax,par,il,iu,il0,iu0,domain_split,l,nsmax,istat)`

## 注意

必须先初始化再交换。`npm` 应在所有 rank 上一致；当交换例程返回 `istat=1` 时，需要增大 `npm`、重新初始化并重试。
