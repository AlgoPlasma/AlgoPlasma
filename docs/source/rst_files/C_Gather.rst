C_Gather
========

.. toctree::
   :maxdepth: 1

   C_Gather/C01_gather_3Dxyz
   C_Gather/C02_gather_3Dxyz_bspline

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 概览

   ``C_Gather`` 收集 PIC 方法中“网格到粒子”的插值例程。它位于场求解器和粒子推进器之间：
   先从网格场量或形函数模板中得到粒子位置处的局部信息，再把这些信息交给 pusher 或其他粒子算子。

   .. list-table:: C_Gather 模块
      :header-rows: 1
      :widths: 12 30 30 38

      * - ID
        - 功能
        - 核心接口
        - 典型用途
      * - C01
        - :doc:`输入 cell-centered 三维电磁场，输出粒子位置处的 E/B <C_Gather/C01_gather_3Dxyz>`
        - ``sub_C01_gather_3Dxyz`` / ``sub_C01_gather_3Dxyz_push``
        - 将 cell-centered 三维直角坐标电磁场插值到粒子位置，或在同一循环中完成 gather 和 Boris push。
      * - C02
        - :doc:`输入 cell-centered 三维电磁场和粒子位置，输出 B-spline gather 得到的 E/B <C_Gather/C02_gather_3Dxyz_bspline>`
        - ``sub_C02_gather_3Dxyz_bspline``
        - 按运行时 ``order`` 生成 centered B-spline 张量积权重，并直接插值 ``Ex/Ey/Ez/Bx/By/Bz``。

   .. rubric:: 数值约定

   粒子坐标默认使用网格指标单位。C01 假定电磁场存储在 cell-centered 网格上，并使用
   ``par(1:3,p)+0.5`` 映射到插值坐标。``C02_gather_3Dxyz_bspline`` 直接对六个
   电磁场分量执行 B-spline gather，阶数由运行时参数 ``order`` 指定。

   .. rubric:: 测试状态

   ``tests/007_gather`` 提供独立测试，覆盖 C01 的三线性 gather / fused gather-push，
   以及 C02 的直接 B-spline gather。见
   :doc:`007_gather 测试总览 </tests/007_gather/index>`。

.. container:: ap-lang ap-lang-en

   .. rubric:: Overview

   ``C_Gather`` contains grid-to-particle interpolation routines used by PIC
   workflows. These routines sit between field solvers and particle pushers:
   they obtain local particle-position data from grid fields or shape-function
   stencils before that information is consumed by a pusher or another particle
   operator.

   .. list-table:: C_Gather Modules
      :header-rows: 1
      :widths: 12 30 30 38

      * - ID
        - Function
        - Core interface
        - Typical use
      * - C01
        - :doc:`Input cell-centered 3D fields and output particle-position E/B <C_Gather/C01_gather_3Dxyz>`
        - ``sub_C01_gather_3Dxyz`` / ``sub_C01_gather_3Dxyz_push``
        - Interpolate cell-centered 3D Cartesian fields to particle positions, or fuse gather with Boris push in one loop.
      * - C02
        - :doc:`Input cell-centered 3D fields and a particle position, output B-spline-gathered E/B <C_Gather/C02_gather_3Dxyz_bspline>`
        - ``sub_C02_gather_3Dxyz_bspline``
        - Build centered B-spline tensor-product weights from runtime ``order`` and directly interpolate ``Ex/Ey/Ez/Bx/By/Bz``.

   .. rubric:: Numerical Conventions

   The routines use particle coordinates in grid-index units. C01 assumes
   electromagnetic fields on a cell-centered grid and maps positions with
   ``par(1:3,p)+0.5`` before interpolation. ``C02_gather_3Dxyz_bspline``
   directly gathers six electromagnetic-field components with a runtime
   ``order`` argument.

   .. rubric:: Test Status

   ``tests/007_gather`` provides standalone tests for C01 trilinear gather /
   fused gather-push and C02 direct B-spline gather. See the
   :doc:`007_gather test overview </tests/007_gather/index>`.
