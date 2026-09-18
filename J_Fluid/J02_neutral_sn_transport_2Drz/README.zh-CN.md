# J02_neutral_sn_transport_2Drz

[中文](README.zh-CN.md) | [English](README.en.md)

本算法单元提供二维轴对称 r-z 网格上稳态中性粒子离散纵标法（SN）的可复用
P1-DG 数值组件。

空间算子沿用当前原型的轴对称守恒形式：

```text
(1/r) d(r mu psi)/dr + d(eta psi)/dz + sigma_t psi = 0。
```

因此当 `mu` 非零时，逐方向常数 `psi` 不是径向自由流不变量；回归测试使用冻结的
Python 原型系数，而不作这一不适用的假设。

当前阶段包括柱坐标几何、角度节点、均匀速度分组、储库/MC 采样入口构造、入口
通量归一化、局部 P1-DG 算子、开放边界方向扫描、镜面/漫反射源迭代、z-low
部分面入口积分，以及单元矩和内部面通量重构。
`gauss-chebyshev` 被明确保留为全圆 `midpoint` 节点集合及排列的别名，并不是另一套
数值求积规则。

相空间数组采用适合 Fortran 的 `psi(3,nr,nz,n_dir)` 布局，第一维对应局部基函数
`(1, xi, zeta)` 的三个系数。速度空间权重已经包含二维极坐标测度
`v dv dtheta`。

核心算法不读取 PIC 网格或 NML 文件，也不负责写应用结果。正性限制尚未纳入当前
公共接口。

## 主要接口

- `sub_J02_initialize_mesh`：检查径向、轴向单元边界和 active mask。
- `sub_J02_build_geometry`：计算柱坐标体积、面面积和 P1 径向平均修正。
- `sub_J02_build_phase_quadrature`：建立展平后的角度—速度节点和权重；角度数至少为
  8 且须被 4 整除，避免方向恰好落在坐标轴上。
- `sub_J02_build_maxwellian_inflow_shape`：生成零漂移、单位数密度的二维储库
  Maxwell 相空间形状。
- `sub_J02_build_drifted_maxwellian_inflow_shape`：按输入的温度 `K`、粒子质量
  `kg` 和漂移速度 `(u_r,u_z) [m/s]` 生成漂移 Maxwell 形状。
- `sub_J02_build_mc_crossing_inflow_shape`：把 MC 穿越边界后统计得到的“每个入射
  离散速度箱的概率质量”转换成相空间密度形状。
- `sub_J02_normalize_inflow_flux`：把非负 `inflow_shape` 归一化到指定粒子数通量。
- `sub_J02_sweep_all_directions`：执行所有方向的开放边界 P1-DG 扫描；可选输出
  `failed_direction/failed_i/failed_k` 分别指出失败方向和单元坐标。
- `sub_J02_build_partial_zlo_inlet`：把物理径向入口范围转换成各 z-low 面的柱坐标
  面积占比和局部 `xi` 区间。
- `sub_J02_build_wall_maxwell_shape`：构造保证漫反射离散通量归一化所需的壁温
  Maxwell 速度形状。
- `sub_J02_sweep_reflecting`：根据上一轮壁面状态执行一次镜面/漫反射混合扫描。
- `sub_J02_solve_source_iteration`：迭代反射边界直到达到给定相对误差，并返回迭代
  次数、最终变化量和失败位置。
- `sub_J02_reconstruct_cell_moments`：重构密度和平均速度。
- `sub_J02_reconstruct_internal_face_fluxes`：重构带符号的内部面粒子数通量密度。
- `sub_J02_reconstruct_open_boundary_fluxes`：把给定入射相密度与内部 DG trace
  分别积分成带符号的边界入流和出流，供 J03 构造冻结闭合；可选的 z-low `xi`
  区间会把两种通量都限制在部分面的开放区域。
- `sub_J02_build_sigma_from_frequency`：按 `sigma_t=nu/speed` 把电离频率转换为
  每个离散速度方向的宏观移除系数。
- `sub_J02_build_mc_crossing_pdf_inflow_shape` 与
  `sub_J02_build_mc_crossing_bins_inflow_shape`：分别处理连续 crossing PDF 和离散
  速度箱概率，避免混淆是否需要除以求积权重。

`sigma_t(nr,nz,n_dir)` 是单位为 `m^-1` 的宏观移除系数；
`boundary_inflow(4,nr,nz,n_dir)` 是给定的入射相空间密度。四个面的顺序是
`r-lo、r-hi、z-lo、z-hi`，出射方向上提供的边界值不会被上风扫描使用。

## 两种入口定义

储库构造器返回二维速度空间相密度：

```text
f(v_r,v_z) = alpha/pi * exp(-alpha*((v_r-u_r)^2+(v_z-u_z)^2)),
alpha = particle_mass/(2*k_B*temperature)。
```

它在连续二维速度空间中的积分为 1；后续通量归一化会用目标入口通量替换其绝对
幅值。

MC 接口的输入不是相密度。`crossing_bin_probability(m)` 表示实际穿越边界的粒子
落入第 `m` 个入射离散箱的概率质量。程序将其除以
`weight(m)*speed(m)*abs(Omega(m).normal)`，恢复成供 SN 边界使用的相密度形状。
再次归一化后，各速度箱的相对穿越通量概率保持不变。因此不能把储库相密度送进
MC 转换器，也不能把 MC 穿越直方图不经转换直接当作相密度。

所有可失败接口使用全局唯一的 `SN_ERR_*` 错误码。调用
`fun_J02_error_message(ierr)` 可得到具体原因；底层库本身不直接打印。

## 源码组织

源码遵循 AlgoPlasma 现有包装约定：唯一的
`mod_J02_neutral_sn_transport_2Drz.f90` 模块保存共享类型，并通过预处理
`include` 纳入按职责拆分、可独立阅读的 `sub_J02_sn_*.f90` 实现文件。

与仓库现有 Fortran 算法保持一致，源码使用默认 `real`；配套测试通过
`-fdefault-real-8` 按双精度进行数值验证。
