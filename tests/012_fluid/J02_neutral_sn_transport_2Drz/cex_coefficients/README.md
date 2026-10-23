# CEX 系数：最小验证

当前实现单个空间单元的固定离子背景系数链：
宏观参数 → 离子速度分布；相对速率 → 能量 → 截面 → 碰撞核 → 频率与输运损失系数。
实现按计算职责拆分，均由原 J02 模块导出：

- `sub_J02_sn_relative_speed.f90`：`fun_J02_relative_speed` 纯函数和相关速度工具。
- `sub_J02_sn_reaction_kernel.f90`：二体反应通用的截面表、能量换算和 `sigma*g`。
- `sub_J02_sn_cex.f90`：固定离子背景和 CEX 频率的加权求和。
当前仍为 2D2V；本轮没有加入碰撞增益项或把系数接入空间输运迭代。

## 调用

```fortran
type(sn_reaction_table_type) :: table
! energy_table [eV], sigma_table [m^2]; arbitrary increasing energy nodes.
! Check ierr == SN_SUCCESS after EACH call.
call sub_J02_initialize_reaction_table(energy_table, sigma_table, &
    SN_REACTION_ENERGY_CM, SN_REACTION_RANGE_ERROR, table, ierr)
call sub_J02_build_ion_maxwellian(ion_quadrature, ion_density, ion_temperature, ion_mass, &
    drift_velocity_r, drift_velocity_z, ion_distribution, ierr)
call sub_J02_compute_cex_frequency(neutral_quadrature, ion_quadrature, ion_distribution, &
    neutral_mass, ion_mass, table, frequency, sigma_t, ierr)
```

- `ion_density` 为 m^-3，`ion_temperature` 为 K 且大于零，质量为 kg，速度为 m/s。
- `ion_distribution` 按 `sum(ion_quadrature%weight*ion_distribution)=ion_density` 归一化，已包含密度。
  也可直接传入非负离散分布。归一化保证密度，不保证粗网格上的其他矩准确。
- 两套速度节点可以不同，但须处于同一局部正交基底。离子零权重分布节点不参与求和。
- `frequency(m)=sum_j w_j*f_i,j*sigma(g_mj)*g_mj`，单位 s^-1；`sigma_t(m)=frequency(m)/v_m`，单位 m^-1。
  返回数组可按空间单元保存并复用；计算不分配完整的节点对矩阵。
- 截面表线性插值。必须明确能量基准：`SN_REACTION_ENERGY_CM` 使用约化质量，
  `SN_REACTION_ENERGY_PROJECTILE_LAB` 使用调用方指定的入射粒子质量（靶粒子静止系）。
  通用核参数依次为 `projectile_mass,target_mass`；CEX 公开入口仍为 `neutral_mass,ion_mass`，
  其内部用关键字明确传入 `projectile_mass=ion_mass,target_mass=neutral_mass`。
  不可混用两种能量横轴，入射粒子不能根据速度循环的先后顺序判断。
- 必须明确超界策略：`SN_REACTION_RANGE_ERROR` 报错；显式选择 `SN_REACTION_RANGE_CLAMP` 才取端点值。
  表格不自动做单位换算。真实 CEX 数据、来源及适用范围需由调用方提供。
- `sub_J02_evaluate_reaction_kernel` 是纯子程序，返回能量、微观截面、节点对 `sigma*g` 和错误码。
  它不需要粒子分布，也不决定反应后产物；其他二体反应可传自己的截面表复用。
  共用的是计算过程，不同反应的 `sigma*g` 数值通常不同，不能直接共用同一份结果。

```fortran
relative_speed = fun_J02_relative_speed(velocity_a, velocity_b)
call sub_J02_evaluate_reaction_kernel(table, projectile_mass, target_mass, relative_speed, &
    energy_ev, cross_section_m2, kernel, ierr)
```

旧表类型/过程的 `cex` 命名已统一改为 `reaction`；相对速率函数名称保持不变。
命名与校验位置见 [代码阅读说明](../../../../J_Fluid/J02_neutral_sn_transport_2Drz/READING.zh-CN.md)。
各过程定义的完整路径位于 `J_Fluid/J02_neutral_sn_transport_2Drz/` 下。

## 只运行三个检查

```bash
bash tests/012_fluid/J02_neutral_sn_transport_2Drz/cex_coefficients/run.sh
```

一个程序、双精度，检查：① 线性合成截面及能量基准；② Maxwell 背景密度归一化；
③ 单离子节点的手算碰撞频率，并核对 Maxwell 分布求和和 `nu/v`。
2026-10-09 拆分前后三项均通过，输出一致；密度误差 1.11e-16，单离子节点频率最大相对误差 2.22e-16。
可读性重构在这三项中补充溢出、零密度和无效背景的断言，不增加测试程序。
这些是算法检查，合成截面不是实际 Xe CEX 数据。
独立脚本保留原有目录，只覆盖自身测试可执行文件与模块编译文件。
