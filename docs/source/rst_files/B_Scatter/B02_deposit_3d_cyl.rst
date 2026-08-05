===================
B02_deposit_3d_cyl
===================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块说明

   ``B02_deposit_3d_cyl`` 实现三维柱坐标 ``(r,\phi,z)`` 中的电荷密度和电流密度沉积。电荷密度定义在网格节点，电流分量定义在柱坐标 Yee 网格的对应面上。实现显式处理径向 Jacobian、轴线退化、外径节点体积以及跨单元轨迹切分。

   .. list-table:: 文件与职责
      :header-rows: 1

      * - 文件
        - 作用
      * - :doc:`mod_B02_deposit_charge_3d_cyl.f90 <B02_deposit_3d_cyl/mod_B02_deposit_charge_3d_cyl>`
        - 电荷沉积模块入口。
      * - :doc:`sub_B02_deposit_charge_3d_cyl.f90 <B02_deposit_3d_cyl/sub_B02_deposit_charge_3d_cyl>`
        - 将单个粒子电荷按一阶权重和柱坐标节点体积沉积到八个相邻节点。
      * - :doc:`sub_B02_average_axis_charge_3d_cyl.f90 <B02_deposit_3d_cyl/sub_B02_average_axis_charge_3d_cyl>`
        - 沿 ``phi`` 平均 ``r=0`` 轴线上的电荷密度。
      * - :doc:`mod_B02_deposit_current_3d_cyl.f90 <B02_deposit_3d_cyl/mod_B02_deposit_current_3d_cyl>`
        - 电流沉积模块入口。
      * - :doc:`sub_B02_deposit_current_3d_cyl.f90 <B02_deposit_3d_cyl/sub_B02_deposit_current_3d_cyl>`
        - 根据粒子从旧位置到新位置扫过的体积沉积 ``Jr``、``Jphi`` 和 ``Jz``。
      * - :doc:`sub_B02_average_axis_jz_3d_cyl.f90 <B02_deposit_3d_cyl/sub_B02_average_axis_jz_3d_cyl>`
        - 沿 ``phi`` 平均 ``r=0`` 轴线上的轴向电流密度 ``Jz``。
      * - :doc:`mod_B02_average_axis_3d_cyl.f90 <B02_deposit_3d_cyl/mod_B02_average_axis_3d_cyl>`
        - 轴线平均工具模块入口。

   .. rubric:: 网格与数组

   网格索引为 ``i=0...nr``、``j=0...nphi``、``k=0...nz``，均匀网格满足

   .. math::

      r_i=i\Delta r,\qquad
      \phi_j=j\Delta\phi,\qquad
      z_k=k\Delta z,\qquad
      \Delta\phi=\frac{2\pi}{n_\phi+1}.

   ``rho(0:nr,0:nphi,0:nz)`` 为节点电荷密度。``jr``、``jphi`` 和 ``jz``
   使用相同数组形状保存三个方向的电流密度；物理上分别对应径向、方位向和轴向
   Yee 面位置。``phi`` 方向按周期处理。

   .. rubric:: 电荷沉积

   粒子位于 :math:`(r_p,\phi_p,z_p)` 时，先定位包含它的单元
   :math:`[r_i,r_{i+1})\times[\phi_j,\phi_{j+1})\times[z_k,z_{k+1})`，
   然后使用一阶权重

   .. math::

      f_r^i=\frac{r_{i+1}-r_p}{\Delta r},\quad
      f_r^{i+1}=\frac{r_p-r_i}{\Delta r},

   ``phi`` 和 ``z`` 方向同理。单粒子对节点 ``(i,j,k)`` 的贡献为

   .. math::

      \rho_{i,j,k}^{(p)}
      =
      q_p w_p
      \frac{f_r^i f_\phi^j f_z^k}
           {V_r^i\,\Delta\phi\,V_z^k}.

   轴向边界使用半单元长度 ``V_z^0=V_z^{nz}=\Delta z/2``。径向体积因子由线性节点形函数乘以柱坐标 Jacobian ``r`` 积分得到：

   .. math::

      V_r^0=\frac{\Delta r^2}{6},\qquad
      V_r^i=i\Delta r^2\ (0\lt i\lt nr),\qquad
      V_r^{nr}=\frac{(3nr-1)\Delta r^2}{6}.

   这些特殊体积因子用于避免轴线和外径节点处的系统性密度误差。

   .. rubric:: 电流沉积

   ``sub_B02_deposit_current_3d_cyl`` 接收粒子旧位置
   :math:`(r_0,\phi_0,z_0)` 和新位置 :math:`(r_1,\phi_1,z_1)`。若轨迹跨过径向、方位向或轴向单元边界，内部递归例程会在最先跨越的边界处分裂轨迹，
   直到每段轨迹只位于一个单元内。

   单元内沉积按扫掠体积在相邻电流位置之间分配。径向电流使用固定面半径
   :math:`r_{i+1/2}`，方位向和轴向电流使用与对应面一致的径向因子。
   实现中 ``Jr`` 的归一化分母使用 ``dr`` 而不是 ``dr^2``，与柱坐标电流沉积修正公式一致。

   .. rubric:: 轴线处理与边界

   在 ``r=0`` 处，不同 ``j`` 索引表示同一个物理点。因此粒子循环结束后应调用
   ``sub_B02_average_axis_charge_3d_cyl`` 平均 ``rho(0,:,k)``，并调用
   ``sub_B02_average_axis_jz_3d_cyl`` 平均 ``jz(0,:,k)``。输入粒子的 ``r`` 和
   ``z`` 会被限制在有效计算域内；``phi`` 使用 ``modulo`` 映射到周期区间。

   .. rubric:: 守恒检查

   B02 测试用离散连续性方程检查电荷与电流的一致性：

   .. math::

      \frac{\rho_1^{i,j,k}-\rho_0^{i,j,k}}{\Delta t}
      +
      \frac{r_{i+1/2}J_r^{i+1/2,j,k}-r_{i-1/2}J_r^{i-1/2,j,k}}
           {r_i\Delta r}
      +
      \frac{J_\phi^{i,j+1/2,k}-J_\phi^{i,j-1/2,k}}
           {r_i\Delta\phi}
      +
      \frac{J_z^{i,j,k+1/2}-J_z^{i,j,k-1/2}}{\Delta z}
      =
      0 .

   相关测试位于 ``tests/004_scatter/B02_deposit_3d_cyl``。``test1`` 和 ``test2``
   包含电荷密度、电流密度和连续性残差的数值验证与绘图脚本。

   .. rubric:: 参考文献

   Yinjian Zhao, Chen Cui, Yuan Hu, *Rigorously conservative charge and current
   deposition in 3D cylindrical PIC*, Computational Particle Mechanics, 2022.
   DOI: `10.1007/s40571-022-00513-6 <https://doi.org/10.1007/s40571-022-00513-6>`_.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">周志君 (2026/04/13; 2026/04/23) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Description

   ``B02_deposit_3d_cyl`` implements charge-density and current-density
   deposition in three-dimensional cylindrical coordinates ``(r,\phi,z)``.
   Charge density is defined on grid nodes, while current components are placed
   on the corresponding cylindrical Yee-grid faces. The implementation handles
   radial Jacobian factors, axis degeneracy, outer-edge node volume, and
   trajectory splitting across cell boundaries.

   .. list-table:: Files And Roles
      :header-rows: 1

      * - File
        - Role
      * - :doc:`mod_B02_deposit_charge_3d_cyl.f90 <B02_deposit_3d_cyl/mod_B02_deposit_charge_3d_cyl>`
        - Module entry point for charge deposition.
      * - :doc:`sub_B02_deposit_charge_3d_cyl.f90 <B02_deposit_3d_cyl/sub_B02_deposit_charge_3d_cyl>`
        - Deposits one particle charge to the eight surrounding nodes with
          first-order weights and cylindrical node volumes.
      * - :doc:`sub_B02_average_axis_charge_3d_cyl.f90 <B02_deposit_3d_cyl/sub_B02_average_axis_charge_3d_cyl>`
        - Averages charge density on the ``r=0`` axis over ``phi``.
      * - :doc:`mod_B02_deposit_current_3d_cyl.f90 <B02_deposit_3d_cyl/mod_B02_deposit_current_3d_cyl>`
        - Module entry point for current deposition.
      * - :doc:`sub_B02_deposit_current_3d_cyl.f90 <B02_deposit_3d_cyl/sub_B02_deposit_current_3d_cyl>`
        - Deposits ``Jr``, ``Jphi``, and ``Jz`` from the swept volume between
          old and new particle positions.
      * - :doc:`sub_B02_average_axis_jz_3d_cyl.f90 <B02_deposit_3d_cyl/sub_B02_average_axis_jz_3d_cyl>`
        - Averages axial current density ``Jz`` on the ``r=0`` axis over
          ``phi``.
      * - :doc:`mod_B02_average_axis_3d_cyl.f90 <B02_deposit_3d_cyl/mod_B02_average_axis_3d_cyl>`
        - Module entry point for axis-averaging utilities.

   .. rubric:: Grid And Arrays

   Grid indices are ``i=0...nr``, ``j=0...nphi``, and ``k=0...nz``. For a
   uniform mesh,

   .. math::

      r_i=i\Delta r,\qquad
      \phi_j=j\Delta\phi,\qquad
      z_k=k\Delta z,\qquad
      \Delta\phi=\frac{2\pi}{n_\phi+1}.

   ``rho(0:nr,0:nphi,0:nz)`` stores nodal charge density. ``jr``, ``jphi``,
   and ``jz`` use the same declared array shape for the three current-density
   components; physically, they correspond to radial, azimuthal, and axial
   Yee-face locations. The ``phi`` direction is periodic.

   .. rubric:: Charge Deposition

   For a particle at :math:`(r_p,\phi_p,z_p)`, the containing cell is
   :math:`[r_i,r_{i+1})\times[\phi_j,\phi_{j+1})\times[z_k,z_{k+1})`.
   First-order weights are

   .. math::

      f_r^i=\frac{r_{i+1}-r_p}{\Delta r},\quad
      f_r^{i+1}=\frac{r_p-r_i}{\Delta r},

   with analogous factors in ``phi`` and ``z``. The contribution to node
   ``(i,j,k)`` is

   .. math::

      \rho_{i,j,k}^{(p)}
      =
      q_p w_p
      \frac{f_r^i f_\phi^j f_z^k}
           {V_r^i\,\Delta\phi\,V_z^k}.

   Axial boundary nodes use half-cell lengths
   ``V_z^0=V_z^nz=Delta z/2``. The radial volume factors come from integrating
   linear nodal shape functions against the cylindrical Jacobian ``r``:

   .. math::

      V_r^0=\frac{\Delta r^2}{6},\qquad
      V_r^i=i\Delta r^2\ (0\lt i\lt nr),\qquad
      V_r^{nr}=\frac{(3nr-1)\Delta r^2}{6}.

   These special volume factors remove systematic density errors at the axis
   and outer radial node.

   .. rubric:: Current Deposition

   ``sub_B02_deposit_current_3d_cyl`` receives an old particle position
   :math:`(r_0,\phi_0,z_0)` and a new position :math:`(r_1,\phi_1,z_1)`.
   If the trajectory crosses radial, azimuthal, or axial cell boundaries, an
   internal recursive helper splits the path at the earliest crossed boundary
   until every segment lies inside one cell.

   Within one cell, deposition is distributed among neighboring current
   locations according to swept volumes. Radial current uses the fixed face
   radius :math:`r_{i+1/2}`; azimuthal and axial currents use the radial
   factors associated with their own faces. In the implementation, the ``Jr``
   normalization denominator uses ``dr`` rather than ``dr^2``, matching the
   corrected cylindrical current-deposition formula.

   .. rubric:: Axis Handling And Boundaries

   At ``r=0``, different ``j`` indices denote the same physical point. After
   the particle loop, call ``sub_B02_average_axis_charge_3d_cyl`` to average
   ``rho(0,:,k)`` and ``sub_B02_average_axis_jz_3d_cyl`` to average
   ``jz(0,:,k)``. Input particle ``r`` and ``z`` coordinates are clamped to the
   valid domain; ``phi`` is mapped into the periodic interval with ``modulo``.

   .. rubric:: Conservation Check

   The B02 tests check consistency between charge and current using the
   discrete continuity equation:

   .. math::

      \frac{\rho_1^{i,j,k}-\rho_0^{i,j,k}}{\Delta t}
      +
      \frac{r_{i+1/2}J_r^{i+1/2,j,k}-r_{i-1/2}J_r^{i-1/2,j,k}}
           {r_i\Delta r}
      +
      \frac{J_\phi^{i,j+1/2,k}-J_\phi^{i,j-1/2,k}}
           {r_i\Delta\phi}
      +
      \frac{J_z^{i,j,k+1/2}-J_z^{i,j,k-1/2}}{\Delta z}
      =
      0 .

   Related tests live in ``tests/004_scatter/B02_deposit_3d_cyl``. ``test1``
   and ``test2`` contain charge-density, current-density,
   continuity-residual checks, and plotting scripts.

   .. rubric:: Reference

   Yinjian Zhao, Chen Cui, Yuan Hu, *Rigorously conservative charge and current
   deposition in 3D cylindrical PIC*, Computational Particle Mechanics, 2022.
   DOI: `10.1007/s40571-022-00513-6 <https://doi.org/10.1007/s40571-022-00513-6>`_.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zhijun ZHOU (2026/04/13; 2026/04/23) · Harbin Institute of Technology</p>
      </div>

.. toctree::
    :maxdepth: 1
    :hidden:

    B02_deposit_3d_cyl/mod_B02_deposit_charge_3d_cyl
    B02_deposit_3d_cyl/sub_B02_deposit_charge_3d_cyl
    B02_deposit_3d_cyl/sub_B02_average_axis_charge_3d_cyl
    B02_deposit_3d_cyl/mod_B02_deposit_current_3d_cyl
    B02_deposit_3d_cyl/sub_B02_deposit_current_3d_cyl
    B02_deposit_3d_cyl/sub_B02_average_axis_jz_3d_cyl
    B02_deposit_3d_cyl/mod_B02_average_axis_3d_cyl
