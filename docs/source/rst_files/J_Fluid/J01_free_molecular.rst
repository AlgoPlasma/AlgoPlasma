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

   J01 estimates steady neutral gas fields from independent particle histories. Free molecular (FM)
   transport assumes particles fly without intermolecular collisions. Monte Carlo (MC) sampling determines
   the inlet position and velocity and the outgoing velocity after diffuse reflection.

   For a continuous supply at a prescribed injection rate, how long do particles stay in each cell, what is
   their mean velocity there, and how many cross each face? J01 returns cell densities, cell-averaged
   velocities and face fluxes. Each history has its own clock.

   .. rubric:: The channel used throughout this chapter

   Consider an annular channel with :math:`r_a<r<r_b`, :math:`0<z<L` and :math:`r_a>0`. Particles enter at
   the lower axial end. Both axial ends are open, so particles can escape through either, and both radial
   walls reflect. The example starts with uniform injection across the entire lower end. The sampling page
   also treats inlets that cover part of an open face.

   .. figure:: ../../images/J_Fluid/fm_history_en.svg
      :alt: A particle enters at the lower end, flies through cells in straight segments, changes velocity at a wall and exits through an open boundary.
      :width: 900px

      One history includes all segments from injection to escape, including segments after a wall collision.

   The inputs are inlet temperature :math:`T_{\mathrm{in}}`, axial drift :math:`U_z`, supply parameter
   :math:`n_{\mathrm{in}}`, particle mass :math:`M`, wall temperature :math:`T_{\mathrm w}` and diffuse
   fraction :math:`d`. The inlet samples a drifting normal velocity distribution truncated to
   :math:`v_z>0`. A wall collision gives thermal diffuse reflection with probability :math:`d` and specular
   reflection otherwise. The calculation omits volume sources and losses, adsorption and intermolecular
   collisions. A finite steady state requires escape; a sealed channel with continuous injection has no
   such steady state.

   .. rubric:: From a single history to steady density

   Each history represents a continuous injection rate :math:`\dot w`. If it spends :math:`\tau` seconds in
   cell :math:`K`, it contributes :math:`\dot w\tau` particles to the steady population. Divide the sum
   over histories by the cell volume to obtain density. Use signed face crossings for flux; the cell mean
   velocity alone cannot recover it.

   The driver finishes one history before sampling the next. Increasing the number of histories increases
   the sample size without advancing a shared physical clock.

   .. rubric:: Reading the implementation

   .. list-table::
      :header-rows: 1
      :widths: 24 38 38

      * - Page
        - Calculation
        - Source file
      * - 01 Module and Data
        - Grid, face types, particle state, inlet data and tally arrays
        - ``mod_J01_neutral_free_molecular_2Drz.f90``
      * - 02 Inlet Sampling
        - Injection area and rate, position distribution and velocity distribution
        - ``sub_J01_fm_sampling.f90``
      * - 03 Wall Reflection
        - Sampling rules for specular and thermal diffuse reflection
        - ``sub_J01_fm_reflection.f90``
      * - 04 Particle Tracking
        - Time to the next face, internal crossings, wall hits, escape and corners
        - ``sub_J01_fm_trajectory.f90``
      * - 05 Field Estimators
        - Conversion of residence times and crossings into physical fields
        - ``sub_J01_fm_statistics.f90``
      * - 06 Complete Calculation
        - Assemble the calculation, check the result and return reference fields
        - ``sub_J01_free_molecular_mc_2Drz.f90``

   .. rubric:: Limits of the motion model

   The particle moves along a straight line within each cell, with :math:`\mathrm dr/\mathrm dt=v_r` and
   :math:`\mathrm dz/\mathrm dt=v_z`. The two velocity components change only at walls. Inlet areas and
   cell volumes use cylindrical geometry; the motion omits azimuthal velocity and its inertial effects.

   The history loop is serial and uses the Fortran runtime's random state. The code provides neither
   independent per-thread streams nor spatial partition communication. To change inlet sampling or wall
   reflection, modify the corresponding implementation file and ensure the statistical weights match the
   new model.
