# 简化版三维柱坐标沉积程序

[English](README.md)

此版本移除了此前分散的辅助工具。源码结构如下。

- `src/mod_B00_cyl3d_base.f90`，仅定义常量。
- `src/mod_B01_deposit_charge_3d_cyl.f90`
- `src/sub_B01_deposit_charge_3d_cyl.f90`
- `src/mod_B02_deposit_current_3d_cyl.f90`
- `src/sub_B02_deposit_current_3d_cyl.f90`

电流沉积只保留两个必要的辅助例程，分别用于轨迹分段和单网格单元沉积。

## 构建

```bash
mkdir -p build

gfortran -cpp -O2 -Wall -Wextra -fimplicit-none -J build -I src \
    src/mod_B00_cyl3d_base.f90 \
    src/mod_B01_deposit_charge_3d_cyl.f90 \
    test/test_charge_paper.f90 \
    -o build/test_charge_paper

gfortran -cpp -O2 -Wall -Wextra -fimplicit-none -J build -I src \
    src/mod_B00_cyl3d_base.f90 \
    src/mod_B01_deposit_charge_3d_cyl.f90 \
    src/mod_B02_deposit_current_3d_cyl.f90 \
    test/test_current_paper.f90 \
    -o build/test_current_paper
```

## 运行

执行以下命令快速检查电荷沉积和电流沉积。

```bash
./build/test_charge_paper 200000
python plot/plot_charge_paper.py

./build/test_current_paper 200000
python plot/plot_current_paper.py
```
