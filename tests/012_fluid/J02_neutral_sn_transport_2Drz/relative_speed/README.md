# J02 相对速率与坐标转换测试

本测试只验证速度运动学，尚未计算 CEX 截面、平均碰撞率或增益/损失项。
固定一个速率组与角度节点后，以其代表速度计算；每个给定节点对的相对速率固定。
同一局部正交基底内直接计算即可，不同方位角的局部分量需先统一基底。

## 源码及接口

- 实现：`../../../../J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_relative_speed.f90`
- 测试：`../source_f90/test_J02_relative_speed.f90`
- 独立运行：`run_test.py`；只依赖 Python 标准库及支持 OpenMP 的 GNU Fortran。

```fortran
! neutral_velocity(:,m) uses physical components (v_r,v_phi,v_z); J02 sets v_phi=0.
call sub_J02_build_velocity_vectors(neutral_quadrature,neutral_velocity,ierr)
! Check ierr == SN_SUCCESS before using neutral_velocity.
g = fun_J02_relative_speed(neutral_velocity(:,m),ion_velocity)
! Both inputs above must use the SAME local orthonormal basis.
v_xyz = fun_J02_velocity_cyl_to_cart(neutral_velocity(:,m),space_azimuth)
```

两个纯函数的输入必须有限，输出可表示；相对速率函数还要求分量差可表示。
低层纯函数不返回错误码。速度节点构造要求已成功初始化的求积对象，保留 `ierr` 参数以兼容现有调用。
三分量容器是坐标转换接口，不会使当前输运模型变为 2D3V。

## 测试与比较基准

| 检查 | 输入或比较基准 |
|---|---|
| 相同速度、双方静止 | 相对速率 0 |
| 一方静止 | (300,0,400) 对零向量，参考值 500 m/s |
| 等速反向、等速正交 | 参考值分别为 2v、sqrt(2)v |
| 周向速度 | (0,300,0) 对 (0,-100,0)，参考值 400 m/s |
| 已知坐标旋转 | (3,4,5) 在空间方位角 pi/2 变为 (-4,3,5) |
| 共同旋转 | 17 个正/负空间方位角；直接相减与转为笛卡尔后相减比较 |
| 不同局部基底 | 局部分量均 (500,0,0)，空间方位角 0 与 pi/2，参考值 500 sqrt(2) |
| 非均匀节点重构 | 中性 16 角度 × 5 速率组；离子 8 角度 × 3 速率组 |
| 节点对检查 | 全部 80 × 24 = 1920 对与余弦定理比较，另检查对称性、重复性和旋转 |
| 零对角、反向节点 | 全部 80 个中性节点，反向配对保持在同一速率组 |
| 数值范围 | 直接平方会溢出/下溢而范数仍可表示的速度，以及相邻大浮点数 |

中性速率边界为 `[0,125,500,1000,2000,4000]` m/s；
离子速率边界为 `[0,250,1500,5000]` m/s。
这里“离子节点”仅指第二套用于配对的速度节点，并未设置离子分布或密度。

余弦定理参考值为：

```text
g_ref = sqrt(v_m^2 + u_j^2 - 2*v_m*u_j*cos(alpha_m-beta_j))
E_pair = abs(g-g_ref) / max(v_m,u_j)
```

该误差按节点速率尺度归一化，不是除以可能接近零的相对速率，也不是碰撞算子误差。
节点对旋转比较使用相同尺度；通用旋转例的尺度为其解析相对速率。
断言容差为 `200*epsilon(1.0)`；几何关系的零值也使用非零速度尺度检查。
本测试检查代表节点上的运动学，不能量化用代表节点近似整个速度区间的积分误差。

## 重现

从仓库根目录运行：

```bash
python3 tests/012_fluid/J02_neutral_sn_transport_2Drz/relative_speed/run_test.py --output /path/to/output
```

默认输出为测试目录下的 `build/relative_speed`，不会清理已有目录。
输出包括 real4/real8 × 串行/4 线程四种配置的编译日志、运行日志、1920 对 CSV，
以及 `summary.json`。脚本验证实际精度、线程数和同精度串行/线程 CSV 完全一致。
编译开启边界检查、浮点 invalid/zero/overflow 捕获及编译器警告。
普通 J02 `make.sh`/`run.sh` 也会自动发现新测试；这些旧脚本会重建其原有 `build/`。
