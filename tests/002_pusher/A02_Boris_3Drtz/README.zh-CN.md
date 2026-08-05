# A02_Boris_3Drtz 测试

[中文](README.zh-CN.md) | [English](README.md)

本目录提供 `A_Pusher/A02_Boris_3Drtz` 的独立测试，用于验证三维柱坐标中的非相对论 Boris 粒子推进器。测试程序会编译一个小型 Fortran 驱动，运行多个单粒子解析算例，并把柱坐标推进得到的位置和速度转换回直角坐标后与解析解对比。

## 测试内容

测试入口为 `source_f90/main.f90`，会依次运行 4 个算例：

| 输出文件 | 算例 | 验证内容 |
| --- | --- | --- |
| `build/case01_gyro.dat` | 纯磁场回旋运动 | 验证柱坐标推进得到的轨道和速度是否匹配直角坐标解析回旋解，并检查速度平方守恒。 |
| `build/case02_Eonly.dat` | 纯电场加速 | 验证随粒子位置转换的柱坐标电场分量是否给出正确的直角坐标位置和速度。 |
| `build/case03_ExB.dat` | 垂直电磁场 | 验证柱坐标推进下的回旋运动叠加 `E x B` 漂移。 |
| `build/case04_ExB_drift.dat` | 纯 `E x B` 漂移 | 验证无回旋情况下的漂移速度和轨道。 |

运行程序时，每个算例会在终端输出最大速度误差和最大位置误差。输出文件中的数值位置和速度已经转换为直角坐标，方便与解析解直接比较。

## 环境要求

编译和运行需要：

- POSIX shell 或 bash。
- GNU Fortran 编译器 `gfortran`。
- Python 3。
- Python 包 `numpy` 和 `matplotlib`。

在 Ubuntu/Debian 上可使用：

```bash
sudo apt update
sudo apt install -y gfortran python3 python3-pip
python3 -m pip install --user numpy matplotlib
```

如果希望使用虚拟环境：

```bash
python3 -m venv ~/.venv
source ~/.venv/bin/activate
pip install numpy matplotlib
```

## 编译与运行

从本目录运行：

```bash
cd tests/002_pusher/A02_Boris_3Drtz
bash clean.sh
bash make.sh
bash run.sh
```

`make.sh` 会创建 `build/` 并生成 `build/a.out`。`run.sh` 会进入 `build/` 运行该程序，并生成：

- `build/case01_gyro.dat`
- `build/case02_Eonly.dat`
- `build/case03_ExB.dat`
- `build/case04_ExB_drift.dat`

如果 `make.sh` 提示 `build` 已存在，请先运行 `bash clean.sh`。

## 绘图

运行：

```bash
bash plot.sh
```

绘图脚本会读取 `build/` 中的数据文件，并将图片保存到 `figs_cases/`。当前会生成：

- `figs_cases/case01_gyro_traj_xy.png`
- `figs_cases/case01_gyro_v2_t.png`
- `figs_cases/case02_Eonly_x_t.png`
- `figs_cases/case03_ExB_traj_xy.png`
- `figs_cases/case04_drift_traj_xy.png`

## 清理

运行：

```bash
bash clean.sh
```

该命令会删除：

- `build/`
- `figs_cases/`
