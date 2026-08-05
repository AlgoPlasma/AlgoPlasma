# A03_Higuera_Cary_relativistic_3Dxyz 测试

[中文](README.zh-CN.md) | [English](README.en.md)

本目录提供 `A_Pusher/A03_Higuera_Cary_relativistic_3Dxyz` 的独立测试，用于验证三维直角坐标中的相对论 Higuera-Cary 粒子速度推进器。测试程序会编译一个小型 Fortran 驱动，运行相对论回旋和高 Lorentz 因子 `E x B` 漂移算例，并与解析解或参考容差对比。

## 测试内容

测试入口为 `source_f90/main.f90`，会依次运行 3 个算例：

| 输出文件 | 算例 | 验证内容 |
| --- | --- | --- |
| `build/case01_gyro.dat` | 相对论纯磁场回旋运动 | 初速度为 `0.9c`，使用相对论修正后的回旋频率对比解析轨道和速度。 |
| `build/case02_exb_drift.dat` | `gamma = 20` 的力自由 `E x B` 漂移 | 设置 `E = -v_y B_z` 使 Lorentz 力抵消，检查粒子是否保持 `x = 0` 并沿漂移方向匀速运动。 |
| `build/case03_warpx_exb_drift.dat` | WarpX 参考 `E x B` 漂移测试 | 使用正电子荷质比和 WarpX 参考设置，检查最终 `|x| < 0.001` 的容差。 |

运行程序时，每个算例会在终端输出最大速度误差和最大位置误差。第三个算例还会输出 WarpX 参考容差的 `PASS` 或 `FAIL`。

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
cd tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz
bash clean.sh
bash make.sh
bash run.sh
```

`make.sh` 会创建 `build/` 并生成 `build/a.out`。`run.sh` 会进入 `build/` 运行该程序，并生成：

- `build/case01_gyro.dat`
- `build/case02_exb_drift.dat`
- `build/case03_warpx_exb_drift.dat`

如果 `make.sh` 提示 `build` 已存在，请先运行 `bash clean.sh`。

## 绘图

运行：

```bash
bash plot.sh
```

绘图脚本会读取前两个算例的数据文件，并将图片保存到 `figs_cases/`。当前会生成：

- `figs_cases/case01_gyro_traj_xy.png`
- `figs_cases/case01_gyro_v2_t.png`
- `figs_cases/case02_exb_drift_x_t.png`
- `figs_cases/case02_exb_drift_traj_xy.png`

`case03_warpx_exb_drift.dat` 当前用于终端数值检查，不会被 `plot.sh` 绘图。

## 清理

运行：

```bash
bash clean.sh
```

该命令会删除：

- `build/`
- `figs_cases/`
