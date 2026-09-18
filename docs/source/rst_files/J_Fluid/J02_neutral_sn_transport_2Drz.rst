J02_neutral_sn_transport_2Drz
=================================================================

.. toctree::
   :maxdepth: 1
   :hidden:

   J02_neutral_sn_transport_2Drz/sub_J02_sn_geometry
   J02_neutral_sn_transport_2Drz/sub_J02_sn_quadrature
   J02_neutral_sn_transport_2Drz/sub_J02_sn_source
   J02_neutral_sn_transport_2Drz/sub_J02_sn_dg_operator
   J02_neutral_sn_transport_2Drz/sub_J02_sn_sweep
   J02_neutral_sn_transport_2Drz/sub_J02_sn_reflection
   J02_neutral_sn_transport_2Drz/sub_J02_sn_reconstruction
   J02_neutral_sn_transport_2Drz/sub_J02_sn_error

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 按实现文件阅读

   * :doc:`网格、几何与面类型：sub_J02_sn_geometry.f90 <J02_neutral_sn_transport_2Drz/sub_J02_sn_geometry>`
   * :doc:`速度空间求积：sub_J02_sn_quadrature.f90 <J02_neutral_sn_transport_2Drz/sub_J02_sn_quadrature>`
   * :doc:`入口分布与损失系数：sub_J02_sn_source.f90 <J02_neutral_sn_transport_2Drz/sub_J02_sn_source>`
   * :doc:`局部不连续伽辽金算子：sub_J02_sn_dg_operator.f90 <J02_neutral_sn_transport_2Drz/sub_J02_sn_dg_operator>`
   * :doc:`开放边界迎风扫描：sub_J02_sn_sweep.f90 <J02_neutral_sn_transport_2Drz/sub_J02_sn_sweep>`
   * :doc:`反射边界与源迭代：sub_J02_sn_reflection.f90 <J02_neutral_sn_transport_2Drz/sub_J02_sn_reflection>`
   * :doc:`密度、速度与面通量重构：sub_J02_sn_reconstruction.f90 <J02_neutral_sn_transport_2Drz/sub_J02_sn_reconstruction>`
   * :doc:`错误码说明：sub_J02_sn_error.f90 <J02_neutral_sn_transport_2Drz/sub_J02_sn_error>`

   .. rubric:: 模块职责

   在二维 r-z 网格上求解稳态中性粒子输运。速度空间由速率和全圆角方向离散，空间使用一次不连续 Galerkin 方法（P1-DG）。输出供 J03 使用的密度与面通量。

   .. rubric:: 方程与离散

   当前实现的守恒输运算子为

   .. math::

      \frac1r\partial_r(r\mu\psi)+\partial_z(\eta\psi)+\sigma_t\psi=0,
      \qquad \sigma_t=\nu/v.

   其中 :math:`\mu,\eta` 是径向、轴向方向余弦，v 是速率，nu 是损失频率。局部展开为

   .. math::

      \psi=\psi_0+\psi_1\xi+\psi_2\zeta,\qquad
      \xi=(r-r_c)/h_r,\quad \zeta=(z-z_c)/h_z.

   将方程乘以三个基函数，按柱坐标权重 r 积分并对输运项分部积分，得到每方向、每单元的 3×3 线性系统。出流面加入本单元矩阵，入流面取迎风邻居或边界分布，吸收项加入加权质量矩阵。径向常分布在非零径向方向下不一定是该算子的平衡解。

   这里离散的是上述二维速度模型；不能仅凭柱坐标体积权重把它等同于包含周向速度运动的完整三维轴对称动力学。

   .. rubric:: 数据与单位

   .. list-table::
      :header-rows: 1

      * - 对象
        - 形状或单位
        - 含义
      * - mesh
        - nr、nz；r_edge(nr+1)、z_edge(nz+1)、active(nr,nz)
        - 网格边界及有效单元标记。
      * - geometry
        - 体积 m³、面积 m²、单元中心与半宽 m
        - theta_span 指定计算扇区角度；零轴面面积有效。
      * - quadrature
        - n_dir=n_angles×n_speeds
        - mu、eta、speed、weight；权重包含 v dv dtheta。
      * - psi
        - (3,nr,nz,n_dir)
        - 三个局部基函数系数，不是三个速度分量。
      * - sigma_t
        - (nr,nz,n_dir)，m⁻¹
        - 按速率转换的线性吸收系数。
      * - density、velocity_r/z
        - (nr,nz)；m⁻³、m/s
        - 柱坐标加权密度与平均速度。
      * - flux_r、flux_z
        - (nr-1,nz)、(nr,nz-1)；m⁻²s⁻¹
        - 内部面坐标方向通量。
      * - inflow_flux、outflow_flux
        - (4,nr,nz)；m⁻²s⁻¹
        - 开放面的入射与出射分别存储，符号仍按坐标方向。


   .. rubric:: 文件与函数职责

   .. list-table::
      :header-rows: 1

      * - 实现文件
        - 主要接口
        - 输入与输出
      * - sub_J02_sn_geometry.f90
        - initialize_mesh、build_geometry、initialize_boundary_types
        - 校验边界坐标；构造几何与面类型；部分入口配置更新轴向低端面。
      * - sub_J02_sn_quadrature.f90
        - build_angular_nodes、build_speed_groups、build_phase_quadrature
        - 节点数和最大速率 → 节点与积分权重。midpoint 和 gauss-chebyshev 为同节点别名。
      * - sub_J02_sn_source.f90
        - build_*_inflow_shape、normalize_inflow_flux、build_sigma_from_frequency
        - 温度/质量/漂移或穿面概率 → 入射分布；目标通量 → 归一化系数；nu → sigma_t。
      * - sub_J02_sn_dg_operator.f90
        - add_volume_matrix、add_absorption_matrix、add_*_rhs、solve_local_3x3
        - 局部几何、方向和入射数据 → 矩阵、右端项与三个系数。
      * - sub_J02_sn_sweep.f90
        - sweep_direction、sweep_all_directions
        - 按方向选迎风遍历顺序，求开放边界扫描解；不支持反射壁。
      * - sub_J02_sn_reflection.f90
        - build_partial_zlo_inlet、sweep_reflecting、solve_source_iteration
        - 入口区间 → 面份额与局部区间；旧出射场 → 新反射入射场；迭代直至阈值。
      * - sub_J02_sn_reconstruction.f90
        - reconstruct_cell_moments、reconstruct_internal_face_fluxes、reconstruct_open_boundary_fluxes
        - 角分布系数 → 单元矩、内部面通量及开放边界入出射通量。
      * - sub_J02_sn_error.f90
        - fun_J02_error_message
        - 错误码 → 可读说明。


   .. rubric:: 入口与壁面

   储气池接口使用二维 Maxwell 相密度，穿面采样接口使用入射事件的概率；后者需要除去相应速度权重和法向速率，才能转换为相密度。两种输入不能直接互换。

   镜面反射翻转法向速度分量。漫反射使用壁温 Maxwell 分布，并由出射粒子通量决定归一化系数。部分入口按环面面积积分，剩余面积参与壁面反射。

   .. rubric:: 调用顺序与诊断

   建立网格和几何 → 构造速度求积与入口分布 → 设置面类型及吸收 → 执行扫描或反射源迭代 → 重构密度与通量。接口名在上表中省略共同的 ``sub_J02_`` 前缀。

   每步检查 ``ierr``；扫描失败同时查看 ``failed_direction``、``failed_i``、``failed_k``。错误码在 J02 内有明确含义，跨模块记录时仍须带上模块名。当前未实现保正限制器，重构密度可能存在负值。


   .. rubric:: 模块文件：类型与包含关系

   ``mod_J02_neutral_sn_transport_2Drz.f90`` 定义四组共享数据：
   ``sn_mesh_2drz_type`` 保存坐标与有效单元，``sn_geometry_2drz_type`` 保存积分几何量，
   ``sn_quadrature_type`` 保存速度节点，``sn_boundary_2drz_type`` 保存面类型。
   调用方使用该模块；八个实现文件位于其 contains 下，通过 include 合并编译，不是八个独立模块。
   面序号 1、2、3、4 为径向下端、径向上端、轴向下端、轴向上端；
   面类型 0、1、2 为内部、开放、反射壁。序号与类型不可混用。

   .. rubric:: 测试

   :doc:`J02 子测试 </tests/011_fluid/J02_tests>` 给出每个几何、求积、边界、扫描和重构检查。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Role and model

   J02 solves the conservative reduced transport operator
   :math:`r^{-1}\partial_r(r\mu\psi)+\partial_z(\eta\psi)+(\nu/v)\psi=0`.
   Local coefficients multiply (1,xi,zeta); weighted integration produces a 3×3 system. This reduced two-velocity model is not a full three-velocity axisymmetric kinetic model.

   .. rubric:: Data and interfaces

   psi has shape (3,nr,nz,n_dir); weights include v dv dtheta. Geometry supplies physical volumes and areas. Geometry, quadrature, sources, DG operators, sweeps, reflection and reconstruction are split into separate included files. Build the inputs, solve the sweep/source iteration, then reconstruct moments and signed fluxes.

   .. rubric:: Boundary and diagnostics

   Reservoir phase density and crossing-event probability are different inputs. Mixed reflection conserves discrete wall flux through normalization. Partial inlets integrate their annular area. Check ierr and failed direction/cell indices. No positivity limiter is implemented.

   .. rubric:: Tests

   :doc:`J02 tests </tests/011_fluid/J02_tests>`.
