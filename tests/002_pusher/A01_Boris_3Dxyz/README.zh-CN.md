# A01_Boris_3Dxyz 测试

[中文](README.zh-CN.md) | [English](README.md)

本目录提供 `A_Pusher/A01_Boris_3Dxyz` 的独立测试，用于验证三维直角坐标中的 Boris 粒子速度推进器。测试程序会编译一个小型 Fortran 驱动，运行多个单粒子解析算例，并把数值轨道、速度和解析解进行对比。

## 测试内容

测试入口为 `source_f90/main.f90`，会依次运行 4 个算例：

| 输出文件 | 算例 | 验证内容 |
| --- | --- | --- |
| `build/case01_gyro.dat` | 纯磁场回旋运动 | 对比解析回旋轨道，并检查速度平方守恒。 |
| `build/case02_Eonly.dat` | 纯电场加速 | 对比解析位置和速度。 |
| `build/case03_ExB.dat` | 垂直电磁场 | 验证回旋运动叠加 `E x B` 漂移。 |
| `build/case04_ExB_drift.dat` | 纯 `E x B` 漂移 | 验证无回旋情况下的漂移速度和轨道。 |

运行程序时，每个算例会在终端输出最大速度误差和最大位置误差。绘图脚本会读取这些 `.dat` 文件，并生成诊断图。

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
cd tests/002_pusher/A01_Boris_3Dxyz
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
