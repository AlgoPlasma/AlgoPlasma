# E_Maxwell 鲲鹏与 AMD 性能对比

[English](README.md)

本目录存放 `E_Maxwell` 子程序的跨平台性能对比测试。每个子目录对应一个基准算例，可通过对应平台的入口在 AMD 和鲲鹏机器上运行：

```bash
./run_amd.sh
./run_amd_ompdo.sh
./run_kunpeng.sh
./run_kunpeng_ompdo.sh
./run_kunpeng_optimized.sh
./clean.sh
```

第一个算例是 `E03_fdtd_3d_cartesian`，用于测试三维直角坐标 FDTD 电场和磁场更新内核的单节点性能。

## 输出约定

每个算例生成一个精简的对比文件：

```text
output/key_metrics.csv
```

同一份文件还会复制到：

```text
data_raw/<platform>/key_metrics.csv
```

在各服务器上分别运行对应脚本，将复制后的结果按平台并列存放：

```bash
./run_amd.sh
./run_amd_ompdo.sh
./run_kunpeng.sh
./run_kunpeng_ompdo.sh
./run_kunpeng_optimized.sh
```

各算例的原始日志和每次重复运行的计时文件保存在 `data_raw/<platform>/` 下。

脚本会将命令行参数传给对应算例：

```bash
THREAD_LIST="1 2 4 8 16 32 64" ./run_amd.sh 160 160 160 100 5
THREAD_LIST="1 2 4 8 16 32 64" ./run_amd_ompdo.sh 160 160 160 100 5
THREAD_LIST="1 2 4 8 16 32 64" ./run_kunpeng.sh 160 160 160 100 5
THREAD_LIST="1 2 4 8 16 32 64" ./run_kunpeng_ompdo.sh 160 160 160 100 5
THREAD_LIST="1 2 4 8 16 32 64" ./run_kunpeng_optimized.sh 160 160 160 100 5
```
