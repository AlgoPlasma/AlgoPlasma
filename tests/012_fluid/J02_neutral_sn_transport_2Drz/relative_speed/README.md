# J02 相对速率与坐标转换测试

[中文](README.zh-CN.md) | [English](README.en.md)

验证 [J02](../../../../J_Fluid/J02_neutral_sn_transport_2Drz/README.zh-CN.md) 的速度节点重构、相对速率及柱坐标速度转换，
并比较 real4/real8 下的串行与 OpenMP 结果。检查针对代表速度节点上的运动学；
截面、离子分布及 CEX 频率见[系数测试](../cex_coefficients/README.zh-CN.md)。

## 环境与运行

需要 Python 3 标准库和支持 OpenMP 的 GNU Fortran。从仓库根目录运行：

```bash
python3 tests/012_fluid/J02_neutral_sn_transport_2Drz/relative_speed/run_test.py
```

脚本依次编译 real4/real8 × 串行/4 线程共四种配置，
开启数组检查、浮点 invalid/zero/overflow 捕获及编译器警告。
`--compiler` 或环境变量 `FC` 可选择编译器，`--output` 可指定结果目录。

## 文件与接口

| 文件 | 用途 |
| --- | --- |
| [run_test.py](run_test.py) | 编译、运行四种配置并比较日志和 CSV |
| [test_J02_relative_speed.f90](../source_f90/test_J02_relative_speed.f90) | 解析运动学和全部节点对检查 |
| [sub_J02_sn_relative_speed.f90](../../../../J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_relative_speed.f90) | 速度向量构造、相对速率和基底转换 |

调用片段如下：

```fortran
! neutral_velocity(:,m): (v_r,v_phi,v_z) in m/s; J02 sets v_phi=0.
call sub_J02_build_velocity_vectors(neutral_quadrature, neutral_velocity, ierr)
! Check ierr == SN_SUCCESS before using the velocity array.
g = fun_J02_relative_speed(neutral_velocity(:,m), ion_velocity)
! Both velocities above use the same local orthonormal basis.
v_xyz = fun_J02_velocity_cyl_to_cart(neutral_velocity(:,m), space_azimuth)
```

速度节点构造使用已成功初始化的求积对象。两个纯函数要求输入有限且输出可表示；
相对速率还要求分量差可表示，纯函数直接返回数值。
不同空间方位角处的局部分量须先转换到共同基底。
三分量容器用于通用坐标转换；J02 输运仍使用 `v_phi=0` 的约化 2D2V 模型。

## 检查内容

| 检查 | 输入或比较基准 |
| --- | --- |
| 相同速度、双方静止 | 相对速率为 0 |
| 一方静止 | `(300,0,400)` 对零向量，参考值 500 m/s |
| 等速反向、等速正交 | 分别为 `2v`、`sqrt(2)*v` |
| 周向速度 | `(0,300,0)` 对 `(0,-100,0)`，参考值 400 m/s |
| 已知坐标旋转 | `(3,4,5)` 在空间方位角 `pi/2` 下变为 `(-4,3,5)` |
| 共同旋转 | 17 个正/负方位角下，比较局部计算与转换后的笛卡尔计算 |
| 不同局部基底 | 两个局部分量均为 `(500,0,0)`，方位角为 0 与 `pi/2`，参考值为 `500*sqrt(2)` |
| 非均匀速度节点 | 中性 16 角度 × 5 速率组，离子 8 角度 × 3 速率组；检查分量、排列、零对角和同组反向节点 |
| 全部节点对 | 80 × 24 = 1920 对与余弦定理比较，同时检查交换对称性、重复调用和基底转换 |
| 数值范围 | 直接平方会溢出/下溢、但范数仍可表示的速度，以及相邻大浮点数 |

中性速率边界为 `[0,125,500,1000,2000,4000]` m/s；
离子速率边界为 `[0,250,1500,5000]` m/s。
这里的离子节点提供第二套配对速度；该测试不设置离子分布或密度。

## 通过条件

对速率为 `v_m,u_j`、速度方向角为 `alpha_m,beta_j` 的节点对，使用独立余弦定理：

```text
g_ref = sqrt(v_m^2 + u_j^2 - 2*v_m*u_j*cos(alpha_m-beta_j))
E_pair = abs(g-g_ref) / max(v_m,u_j)
```

节点对误差和旋转比较使用上述节点速率尺度，容差为 `200*epsilon(1.0)`，
其中 `epsilon` 随所编译的 real 精度取值。其他解析检查采用对应的非零速度尺度，
例如共同旋转使用解析相对速率；参考值为零时仍使用指定的非零尺度。

脚本还确认实际实数字节数、OpenMP 工作线程数及 `RESULT: PASS`，
并要求相同精度的串行/线程 `pairs.csv` 逐字节一致。任一检查失败则返回非零状态。
这些判据衡量代表节点计算误差；速度区间的积分离散误差由[速率求积测试](../nonuniform_speed/README.zh-CN.md)检查。

## 输出

默认输出位于上一级测试目录的 `build/relative_speed/`：

```text
r4_serial/   r4_omp4/   r8_serial/   r8_omp4/
  module_compile.log   test_compile.log   test.log
  commands.json        pairs.csv
  module.o             test_J02_relative_speed.out
summary.json
```

各配置的 `pairs.csv` 保存全部 1920 对的计算值、余弦定理参考值和转换后的笛卡尔计算值。
`summary.json` 汇总精度、实际线程数和误差指标；本测试不生成图。
脚本保留已有目录，重复运行覆盖同名构建文件和结果。

常规 [J02 测试](../README.zh-CN.md) 也包含此 Fortran 程序；
其 `make.sh` 会重建上级测试目录的 `build/`，应先于独立比较运行。
