# SN 代码阅读顺序与命名约定

先读公开过程中的物理公式。初始化负责建立合法对象，后续计算直接使用这些对象。
不再逐层检查分配状态、字段尺寸和初始化已经确定的邻接关系。
CEX 的归一化和频率累加直接写在主体中；重构不再返回输入校验错误。

## 两条阅读路径

- 碰撞准备：`sn_quadrature` → `sn_relative_speed` → `sn_reaction_kernel` → `sn_cex`。
- 空间输运：`sn_transport` → `sn_reflection`（反射迭代）→ `sn_sweep` → `sn_reconstruction`。

以上均为 `sub_J02_*.f90` 文件，并由同一个 `mod_J02_neutral_sn_transport_2Drz` 包含。
CEX 目前只输出单元系数；增益项和空间输运耦合尚未实现。

## 同一个量使用同一个名称

| 名称 | 含义与单位 |
|---|---|
| `neutral_quadrature`, `ion_quadrature` | 中性与离子的速度求积对象 |
| `neutral_velocity`, `ion_velocity` | 局部 `(v_r,v_phi,v_z)` 分量，m/s；当前 `v_phi=0` |
| `ion_distribution` | 节点上的离子分布，已包含数密度 |
| `ion_population` | `ion_quadrature%weight*ion_distribution`，m^-3 |
| `relative_speed` | 一对速度节点的相对速率，m/s |
| `energy_ev` | 与截面表能量定义一致的碰撞能量，eV |
| `cross_section_m2` | 微观截面，m^2 |
| `kernel` | `cross_section_m2*relative_speed`，m^3/s；未做分布平均 |
| `frequency` | 对离子节点求和得到的损失频率，s^-1 |
| `sigma_t` | `frequency/neutral_speed`，m^-1；供输运使用 |
| `boundary_inflow` | 四面入流分布；从求解到重构均使用此名 |

`m` 表示中性速度节点，`j` 表示离子速度节点。`*_work` 是成功后才交给调用方的临时输出。
`sub_J02_` 表示子程序，`fun_J02_` 表示函数。

## 检查保留在哪里

- 网格、速度分组、截面表的构造入口：检查原始输入，成功后才可使用对象。
- `sn_validation`：只保留入口分布共用的法向、尺寸和非负性检查。
- `sn_sweep`：入口组合、反射比例、物理区间、面类型和损失符号；方向有限性保证速度分区可用。
- 数值失败点：归一化分母、截面能量范围、局部求解与保正、迭代收敛。
- MPI：分区与交界面一致性、共同迭代选项和必要的失败同步，防止进程互相等待。

`sn_numerics`、带状态码的相对速度包装、结构有效性谓词和重构校验包装已删除。
相对速率使用 `fun_J02_relative_speed`；CEX 使用直接乘除与逐节点求和，不保存节点对核矩阵。
普通算术要求输入与中间结果有限且可表示，不再为每一步构造浮点范围错误路径。

对象需先成功初始化，场数组须符合接口形状；修改网格后需重建相关几何与面类型。
内部面邻接关系由初始化建立，调用方可以设置物理边界类型，但不能破坏该邻接关系。
重构和速度分量构造保留原有 `ierr` 参数，正常返回 `SN_SUCCESS`；它们不再检查对象结构。
反射迭代的 `wall_shape` 改为可选，仅漫反射需要提供；其余主要计算过程的参数顺序不变。

## 接口调整

过程的物理计算和参数位置保持原有顺序；以下关键字调用需要采用新名称：

- CEX：`neutral_quad/ion_quad/ion_f/opacity` → `neutral_quadrature/ion_quadrature/ion_distribution/sigma_t`。
- 离子 Maxwell：`quadrature/drift_r/drift_z/ion_f` → `ion_quadrature/drift_velocity_r/drift_velocity_z/ion_distribution`。
- 反应核：`rate_coefficient` → `kernel`。
- 频率到输运损失系数：`ionization_frequency` → `frequency`。
- 开放边界重构：`prescribed_inflow` → `boundary_inflow`。
- 面辅助过程：`fun_face_normal` → `sub_J02_face_normal`；`fun_face_trace` → `fun_J02_face_trace`。

CEX 公开入口的质量顺序仍是 **中性、离子**。通用反应核则为 **入射粒子、靶粒子**；
CEX 内部通过关键字显式指定离子为入射粒子，避免靠参数排列猜测物理角色。
