# J02 CEX 系数测试

[English](README.md)

验证 [J02 中性输运模块](../../../../J_Fluid/J02_neutral_sn_transport_2Drz/README.zh-CN.md) 的单元 CEX 系数计算：
离子分布与相对速率 → 碰撞能量与截面 → 碰撞核 → 损失频率与单位路程损失系数。
测试使用固定离子背景和合成截面，覆盖当前约化 2D2V 模型的系数链；碰撞增益与空间输运耦合需单独实现。

## 环境与运行

需要 Bash 和 GNU Fortran。从仓库根目录运行：

```bash
bash tests/012_fluid/J02_neutral_sn_transport_2Drz/cex_coefficients/run.sh
```

脚本用默认实数提升至 8 字节的配置编译一个测试程序，开启数组检查、
浮点 invalid/zero/overflow 捕获和编译器警告。可用 `FC` 选择兼容编译器，
第一个参数可指定构建目录。

## 文件与接口

| 文件 | 用途 |
| --- | --- |
| [run.sh](run.sh) | 独立编译并运行系数测试 |
| [test_J02_cex_coefficients.f90](../source_f90/test_J02_cex_coefficients.f90) | 三组解析检查及异常断言 |
| [sub_J02_sn_relative_speed.f90](../../../../J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_relative_speed.f90) | 相对速率和速度转换 |
| [sub_J02_sn_reaction_kernel.f90](../../../../J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_reaction_kernel.f90) | 截面表、能量换算及节点对碰撞核 |
| [sub_J02_sn_cex.f90](../../../../J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_cex.f90) | 离子分布归一化及频率求和 |

调用片段如下；每次调用后须确认 `ierr == SN_SUCCESS` 再使用输出：

```fortran
type(sn_reaction_table_type) :: table

! energy_table: eV; sigma_table: m^2.
call sub_J02_initialize_reaction_table(energy_table, sigma_table, &
    SN_REACTION_ENERGY_CM, SN_REACTION_RANGE_ERROR, table, ierr)
call sub_J02_build_ion_maxwellian(ion_quadrature, ion_density, ion_temperature, ion_mass, &
    drift_velocity_r, drift_velocity_z, ion_distribution, ierr)
call sub_J02_compute_cex_frequency(neutral_quadrature, ion_quadrature, ion_distribution, &
    neutral_mass, ion_mass, table, frequency, sigma_t, ierr)
```

- 数密度为 m^-3，温度为 K 且大于零，质量为 kg，速度为 m/s。
  `ion_distribution` 已包含密度，满足 `sum(ion_quadrature%weight*ion_distribution)=ion_density`；
  也可直接提供非负离散分布。此归一化约束数密度，其他矩的精度取决于速度网格。
- 中性与离子的速度节点可不同，但须使用同一局部正交基底。加权离子分布为零的节点不参与求和。
- `frequency(m)=sum_j w_j*f_i,j*sigma(g_mj)*g_mj`，单位 s^-1；
  `sigma_t(m)=frequency(m)/v_m`，单位 m^-1。输出可按空间单元保存；计算逐节点累加。
- 截面表能量单位为 eV、截面单位为 m^2，采用线性插值。
  `SN_REACTION_ENERGY_CM` 使用约化质量；
  `SN_REACTION_ENERGY_PROJECTILE_LAB` 使用靶静止系中的入射粒子质量。
  通用核的质量顺序为 `projectile_mass,target_mass`；
  CEX 入口为 `neutral_mass,ion_mass`，内部显式指定离子为入射粒子。
- 超出表格能量范围时，`SN_REACTION_RANGE_ERROR` 返回错误；
  选择 `SN_REACTION_RANGE_CLAMP` 时取端点截面。实际应用需提供单位、能量基准和适用范围明确的截面数据。

通用二体反应核可单独调用：

```fortran
relative_speed = fun_J02_relative_speed(velocity_a, velocity_b)
call sub_J02_evaluate_reaction_kernel(table, projectile_mass, target_mass, relative_speed, &
    energy_ev, cross_section_m2, kernel, ierr)
```

其中 `kernel = cross_section_m2 * relative_speed`，单位 m^3/s。
该过程返回单个节点对的物性，分布平均由 CEX 求和过程完成。

## 检查内容与通过条件

| 检查 | 比较基准与判据 |
| --- | --- |
| 能量、截面与碰撞核 | 合成线性截面与手算结果比较；质心能量和入射粒子能量分别核对，相对误差不超过 `1e-12` |
| 离子背景归一化 | 非均匀速度网格上的离散积分恢复指定数密度，相对误差不超过 `1e-12`；分布非负，零密度产生零分布 |
| 频率与输运损失系数 | 单离子节点使用 `n_i*sigma0*g`，Maxwell 背景使用独立求和；同时检查 `sigma_t=frequency/v`，相对误差不超过 `1e-12` |

还检查表格超界、核计算溢出、负离子背景及失败后的输出状态。
这些检查验证系数实现；真实 Xe CEX 预测还需要经验证的截面和背景数据。

## 输出

默认构建目录为上一级测试目录的 `build/cex_coefficients/`，其中保存模块文件和 `test_cex.out`。
结果打印到终端；成功时输出三组 `PASS` 和最终的 `RESULT: PASS`，失败返回非零状态。
脚本不生成 CSV 或图片；重复运行会覆盖同名构建文件，保留目录中的其他文件。

完整测试入口见 [J02 测试说明](../README.zh-CN.md)。
