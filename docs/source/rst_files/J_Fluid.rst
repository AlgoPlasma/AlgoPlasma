J_Fluid
=================================================================

.. toctree::
   :maxdepth: 1
   :hidden:

   J_Fluid/J01_free_molecular
   J_Fluid/J02_neutral_sn_transport_2Drz
   J_Fluid/J03_neutral_continuity_faceflux_2Drz

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 模块职责

   J_Fluid 包含连续性方程更新和中性粒子输运前处理。三维接口和二维柱坐标接口采用不同的数据布局与源项约定。

   .. rubric:: 子模块

   .. list-table::
      :header-rows: 1

      * - 模块
        - 输入
        - 输出与用途
      * - :doc:`J01 <J_Fluid/J01_free_molecular>`
        - 粒子方法输入网格、入口和壁面条件；连续性工具输入密度与给定速度
        - 粒子方法输出参考密度与面通量；连续性工具输出通量或更新后的密度。
      * - :doc:`J02 <J_Fluid/J02_neutral_sn_transport_2Drz>`
        - 网格、速度求积、入口、反射条件、吸收系数
        - 离散纵标分布、密度、速度及面通量。
      * - :doc:`J03 <J_Fluid/J03_neutral_continuity_faceflux_2Drz>`
        - 参考密度、面通量、几何、体源与损失频率
        - 单步更新或稳态密度、残差与收敛信息。


   .. rubric:: 调用关系

   二维应用先调用 J01 自由分子例程或 J02 输运例程，再把参考密度、内部面通量和开放边界通量传入 J03。J03 固定由参考场构造的面速度，后续通量随当前迎风密度变化。改变输运边界或速度分布后，应重新评估该闭合是否仍适用。

   .. rubric:: 数据约定

   三维 J01 使用带保护层的节点数组，``dx=dy=dz=dt=1``；更新式减去 ``s``，正值表示密度扣减。二维接口采用单元中心密度和实际几何量，正体源 ``source_rate`` 增加密度，损失为 ``loss_frequency*density``。

   面通量单位为粒子数每平方米每秒，符号相对于坐标正方向；计算净流出时，低端面取负号。四面顺序为径向低端、径向高端、轴向低端、轴向高端。

   .. rubric:: 测试入口

   :doc:`011_fluid </tests/011_fluid/index>` 列出各子测试的实现与通过条件。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Overview

   J01_neutral_free_molecular_2Drz provides particle preprocessing. Legacy Cartesian updates and prescribed-velocity utilities remain in J01_continuity_freeflow. J02 provides discrete-ordinates transport. J03 imports reference densities and fluxes to advance continuity.

   .. rubric:: Conventions

   The 3D J01 interface uses nodal arrays with guards and unit spacings; positive ``s`` is subtracted. Cylindrical interfaces use cell-centred density, physical geometry, positive production and loss frequency. Flux signs follow coordinate directions; low faces enter divergence with a minus sign.

   .. rubric:: Tests

   :doc:`011_fluid </tests/011_fluid/index>` describes unit and application tests.
