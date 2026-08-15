A_Pusher
========

.. toctree::
    :maxdepth: 1

    A_Pusher/pusher_learning_path
    A_Pusher/pusher_usage_cookbook
    A_Pusher/pusher_testing_guide
    A_Pusher/A01_Boris_3Dxyz
    A_Pusher/A02_Boris_3Drtz
    A_Pusher/A03_Higuera_Cary_relativistic_3Dxyz

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 概览

   ``A_Pusher`` 收纳 PIC 方法中的粒子推进器。给定粒子位置处的电磁场后，pusher
   在离散时间步内积分 Lorentz force equations，更新粒子的速度、动量或位置。
   pusher 的选择会直接影响 PIC 模拟的稳定性、精度、相空间体积保持和长期能量行为。

   .. list-table:: Pusher 选择
      :header-rows: 1
      :widths: 8 24 18 15 17 34

      * - ID
        - 算法
        - 坐标系
        - 相对论
        - 更新量
        - 核心接口
      * - A01
        - :doc:`Boris velocity pusher <A_Pusher/A01_Boris_3Dxyz>`
        - 3D Cartesian / ``xyz``
        - 否
        - ``v``
        - ``sub_A01_Boris_3Dxyz(v,E,B,k)``
      * - A02
        - :doc:`Cylindrical Boris pusher <A_Pusher/A02_Boris_3Drtz>`
        - 3D cylindrical / ``r,theta,z``
        - 否
        - ``x, v``
        - ``sub_A02_Boris_3Drtz_push_v_x(x,v,E,B,k,dt)``
      * - A03
        - :doc:`Higuera-Cary relativistic pusher <A_Pusher/A03_Higuera_Cary_relativistic_3Dxyz>`
        - 3D Cartesian / ``xyz``
        - 是
        - ``v``
        - ``sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v(v,E,B,k)``

   .. rubric:: 运动方程与时间离散

   带电粒子的运动由 Lorentz force equations 描述：

   .. math::

      \frac{d\mathbf{x}}{dt} = \mathbf{v},\qquad
      \frac{d\mathbf{p}}{dt}
      = q\left[\mathbf{E}(\mathbf{x},t)+\mathbf{v}\times\mathbf{B}(\mathbf{x},t)\right].

   多数 PIC 算法采用 leapfrog 时间离散：位置在整数时间层，速度或动量在半整数时间层。
   这种 staggered 布局带来二阶时间精度，并有利于长期数值稳定。

   .. rubric:: 在 PIC 循环中的位置

   一个典型显式 PIC 时间步为：gather 网格电磁场到粒子位置，调用 pusher 更新粒子速度或动量，
   更新粒子位置，将粒子电荷/电流 scatter 回网格，最后推进场。pusher、gather、scatter 和
   field solver 的坐标、权重和边界约定必须保持一致。

.. container:: ap-lang ap-lang-en

   .. rubric:: Overview

   ``A_Pusher`` contains particle pushers used by PIC workflows. Given the
   electromagnetic field at a particle position, a pusher integrates the
   Lorentz force equations over a discrete time step and updates particle
   velocity, momentum, or position. The pusher choice directly affects
   stability, accuracy, phase-space volume preservation, and long-term energy
   behavior.

   .. list-table:: Pusher Selection
      :header-rows: 1
      :widths: 8 24 18 15 17 34

      * - ID
        - Algorithm
        - Coordinates
        - Relativistic
        - Updated state
        - Core interface
      * - A01
        - :doc:`Boris velocity pusher <A_Pusher/A01_Boris_3Dxyz>`
        - 3D Cartesian / ``xyz``
        - No
        - ``v``
        - ``sub_A01_Boris_3Dxyz(v,E,B,k)``
      * - A02
        - :doc:`Cylindrical Boris pusher <A_Pusher/A02_Boris_3Drtz>`
        - 3D cylindrical / ``r,theta,z``
        - No
        - ``x, v``
        - ``sub_A02_Boris_3Drtz_push_v_x(x,v,E,B,k,dt)``
      * - A03
        - :doc:`Higuera-Cary relativistic pusher <A_Pusher/A03_Higuera_Cary_relativistic_3Dxyz>`
        - 3D Cartesian / ``xyz``
        - Yes
        - ``v``
        - ``sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v(v,E,B,k)``

   .. rubric:: Equations and Time Discretization

   Charged-particle motion is governed by the Lorentz force equations:

   .. math::

      \frac{d\mathbf{x}}{dt} = \mathbf{v},\qquad
      \frac{d\mathbf{p}}{dt}
      = q\left[\mathbf{E}(\mathbf{x},t)+\mathbf{v}\times\mathbf{B}(\mathbf{x},t)\right].

   Most PIC algorithms use leapfrog time discretization: positions live at
   integer time levels, while velocities or momenta live at half-integer time
   levels. This staggered layout provides second-order time accuracy and helps
   long-term numerical stability.

   .. rubric:: Role in the PIC Cycle

   A typical explicit PIC step gathers grid electromagnetic fields to particle
   positions, pushes particle velocity or momentum, advances particle position,
   scatters charge/current back to the grid, and then advances the fields. The
   coordinate, weighting, and boundary conventions of pusher, gather, scatter,
   and field solver must remain consistent.
