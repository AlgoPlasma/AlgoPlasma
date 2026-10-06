J01 Free Molecular
==========================================================================================

.. toctree::
   :maxdepth: 1
   :titlesonly:

   01 Module and Data <J01_free_molecular/mod_J01_neutral_free_molecular_2Drz>
   02 Inlet Sampling <J01_free_molecular/sub_J01_fm_sampling>
   03 Wall Reflection <J01_free_molecular/sub_J01_fm_reflection>
   04 Particle Tracking <J01_free_molecular/sub_J01_fm_trajectory>
   05 Field Estimators <J01_free_molecular/sub_J01_fm_statistics>
   06 Complete Calculation <J01_free_molecular/sub_J01_free_molecular_mc_2Drz>

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   J01 的粒子前处理用许多独立轨迹统计稳态中性气体场。
   这里的自由分子输运（Free Molecular，FM）指不计算分子间碰撞的运动；
   蒙特卡洛方法（Monte Carlo，MC）用于抽取入口位置、速度以及碰壁后的反射速度。

   它解决的问题是：入口以给定速率持续供气时，粒子在各单元停留多久，
   以什么平均速度运动，又有多少粒子穿过每个面。
   输出是单元密度、单元平均速度和面通量，不是粒子随某个共同物理时钟演化的快照。

   .. rubric:: 贯穿本章的物理问题

   考虑一个 :math:`r_a<r<r_b`、:math:`0<z<L` 的环形通道截面，
   其中 :math:`r_a>0`。下端面注入粒子，上端开放，两个径向侧面反射。
   下端也是开放面，已经进入通道的粒子可以从那里反向逃逸。
   本章先采用整个下端面均匀供气；入口半径只覆盖部分开放面时的含义在采样页说明。

   .. figure:: /_static/J_Fluid/fm_history.svg
      :alt: 粒子从下端注入，沿网格内直线飞行，碰壁改变速度，最终从开放边界逃逸
      :width: 900px

      一个历史包含从注入到逃逸的全部飞行段，遇到壁面不会新建历史。

   输入包括入口温度 :math:`T_{\mathrm{in}}`、轴向漂移 :math:`U_z`、
   供应强度参数 :math:`n_{\mathrm{in}}`、粒子质量 :math:`M`、
   壁温 :math:`T_{\mathrm w}` 和漫反射概率 :math:`d`。
   入口直接抽取 :math:`v_z>0` 的截断漂移正态速度；壁面以概率 :math:`d` 热漫反射，
   其余镜面反射。当前没有体产生、体损失、吸附和分子间碰撞。
   有限稳态需要粒子最终能够逃逸；完全封闭且持续供气的问题不属于这一稳态计算的适用范围。

   .. rubric:: 从一条轨迹到稳态密度

   一条历史不是固定数量的宏粒子，而是代表持续注入粒子率 :math:`\dot w` 的统计样本。
   若它在单元 :math:`K` 停留 :math:`\tau` 秒，就贡献 :math:`\dot w\tau` 个稳态粒子。
   把全部历史的贡献相加，再除以单元体积，得到密度。
   面通量则由有符号穿面次数计算，不能从单元平均速度直接替代。

   程序每次只追踪一条历史，完成后再抽取下一条。增加历史数是增加统计样本，
   不是延长某个连续性计算的物理时间。

   .. rubric:: 按以下顺序阅读实现

   .. list-table::
      :header-rows: 1
      :widths: 24 38 38

      * - 页面
        - 解释的计算
        - 对应文件
      * - 01 Module and Data
        - 网格、面类型、粒子状态、入口结构和累计数组
        - ``mod_J01_neutral_free_molecular_2Drz.f90``
      * - 02 Inlet Sampling
        - 注入区域、粒子率、位置与速度的概率分布
        - ``sub_J01_fm_sampling.f90``
      * - 03 Wall Reflection
        - 镜面变换和热漫反射的抽样公式
        - ``sub_J01_fm_reflection.f90``
      * - 04 Particle Tracking
        - 最近碰面时间、内部穿越、碰壁、逃逸和角点
        - ``sub_J01_fm_trajectory.f90``
      * - 05 Field Estimators
        - 驻留时间与穿面次数怎样转换为物理场
        - ``sub_J01_fm_statistics.f90``
      * - 06 Complete Calculation
        - 组装所有过程，检查结果，交付参考场
        - ``sub_J01_free_molecular_mc_2Drz.f90``

   .. rubric:: 当前运动模型的限制

   单元内按 :math:`\mathrm dr/\mathrm dt=v_r`、
   :math:`\mathrm dz/\mathrm dt=v_z` 直线飞行，两速度分量只在碰壁时改变。
   入口面积与最终体积采用柱坐标几何，但没有周向速度及相关惯性运动；
   这不是完整的三速度轴对称分子动力学模型。

   当前历史循环是串行的，使用 Fortran 运行时的随机数状态。
   源码没有独立线程随机流或空间分区通信接口，不能仅通过增加线程数就获得并行。
   改变采样或壁面模型时，应在对应功能文件中修改，同时保持统计权重与新模型一致。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   J01 estimates steady neutral fields from independent collisionless particle histories.
   It uses Monte Carlo sampling for inlet positions, inlet velocities and diffuse wall reflection.
   The outputs are cell density, residence-weighted mean velocities, internal face fluxes,
   and outgoing physical-boundary fluxes.

   The running problem is an annular r-z channel with an open lower inlet, an open upper outlet
   and reflecting radial walls. The lower inlet also allows reverse escape.
   The current inlet is a truncated drifted normal distribution of incoming particles.
   Walls mix specular and flux-weighted thermal reflection. There are no volume sources,
   volume losses, adsorption, or intermolecular collisions.

   A history carries a steady injection rate, not a PIC macro-particle population.
   Its residence time times that rate contributes to the steady particle inventory.
   Signed crossings provide face fluxes independently of cell velocity moments.

   Read Module and Data, Inlet Sampling, Wall Reflection, Particle Tracking, Field Estimators,
   then Complete Calculation. The six pages map to the module and its five included files.
   The current model uses straight r-z paths with two velocity components and cylindrical measures,
   not full axisymmetric three-velocity dynamics. Histories are currently serial and share
   the Fortran runtime random state.
