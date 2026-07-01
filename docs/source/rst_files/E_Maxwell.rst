E_Maxwell
=========

.. toctree::
    :maxdepth: 1

    E_Maxwell/fdtd_learning_path
    E_Maxwell/fdtd_usage_cookbook
    E_Maxwell/cpml_cookbook
    E_Maxwell/fdtd_testing_guide
    E_Maxwell/E01_Maxwell_2Drz
    E_Maxwell/E02_Maxwell_3Drtz
    E_Maxwell/E03_Maxwell_3Dxyz

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 概览

   ``E_Maxwell`` 记录 AlgoPlasma 中用于数值求解 Maxwell 方程组的场推进子程序和边界处理扩展。
   当前主要实现基于有限差分时域法（Finite-Difference Time-Domain, FDTD）：电场
   :math:`\mathbf{E}` 和磁场 :math:`\mathbf{H}` 在空间上交错，在时间上采用 leapfrog
   半步交错。模块还提供卷积完美匹配层（Convolutional Perfectly Matched Layer, CPML）
   扩展，用作有限计算区域边界处的电磁波吸收边界，以减小出射波反射。模块覆盖 2D
   轴对称柱坐标、完整 3D 柱坐标和 3D Cartesian 网格。

   .. rubric:: 从哪里开始

   .. list-table:: 阅读和使用路线
      :header-rows: 1
      :widths: 26 36 38

      * - 读者目标
        - 先看
        - 然后看
      * - 第一次学习 FDTD / Maxwell 更新
        - :doc:`FDTD Learning Path <E_Maxwell/fdtd_learning_path>`
        - 从 :doc:`E03 Cartesian notes <E_Maxwell/E03_Maxwell_3Dxyz/fdtd_3d_cartesian_notes>` 开始，再看 E01/E02。
      * - 想把 routine 接进自己的代码
        - :doc:`FDTD Usage Cookbook <E_Maxwell/fdtd_usage_cookbook>`
        - 进入对应 E01/E02/E03 页面，再看具体 subroutine 参数表。
      * - 需要吸收边界
        - :doc:`CPML Cookbook <E_Maxwell/cpml_cookbook>`
        - 看对应 CPML module/subroutine 页面，并运行 wave-packet reference 测试。
      * - 修改了算法，想确认没破坏实现
        - :doc:`FDTD Testing Guide <E_Maxwell/fdtd_testing_guide>`
        - 再看 :doc:`005_maxwell 测试总览 </tests/005_maxwell/index>`。

   .. list-table:: 模块关系
      :header-rows: 1
      :widths: 18 24 34 24

      * - 模块
        - 坐标/模式
        - 主要职责
        - 测试/说明
      * - :doc:`E01_Maxwell_2Drz <E_Maxwell/E01_Maxwell_2Drz>`
        - 2D ``(r,z)`` TE/TM
        - 轴对称 FDTD 更新，包含 TE/TM 拆分和 2D RZ CPML。
        - :doc:`2D RZ notes <E_Maxwell/E01_Maxwell_2Drz/fdtd_2d_rz_axisymmetric_notes>`
      * - :doc:`E02_Maxwell_3Drtz <E_Maxwell/E02_Maxwell_3Drtz>`
        - 3D ``(r,phi,z)``
        - 完整柱坐标六分量 Yee-FDTD 和 CPML 吸收边界扩展，显式处理轴线和柱坐标 metric 项。
        - :doc:`3D cylindrical notes <E_Maxwell/E02_Maxwell_3Drtz/fdtd_3d_cylindrical_notes>`
      * - :doc:`E03_Maxwell_3Dxyz <E_Maxwell/E03_Maxwell_3Dxyz>`
        - 3D ``(x,y,z)``
        - Cartesian 六分量 Yee-FDTD 和 3D CPML 扩展。
        - :doc:`3D Cartesian notes <E_Maxwell/E03_Maxwell_3Dxyz/fdtd_3d_cartesian_notes>`

   .. rubric:: 数值结构

   所有 FDTD 内核都遵循 Maxwell curl 方程的离散形式。非 CPML 内核只负责 interior-style
   curl update；周期边界、外部边界填充、源项注入和诊断输出由调用方或测试程序组织。
   CPML 模块额外维护 split-field memory variables，用于吸收层中的修正 curl 项。
   因此，``E_Maxwell`` 更像一组可组合的低层场推进积木，而不是包含网格管理、边界管理和
   I/O 的完整求解器框架。

   .. rubric:: 测试入口

   Maxwell/FDTD 测试目录入口见 :doc:`005_maxwell 测试总览 </tests/005_maxwell/index>`；
   更完整的公式、可视化说明和案例细节整理在 :doc:`FDTD Testing Guide <E_Maxwell/fdtd_testing_guide>`。
   覆盖内容对应 ``tests/005_maxwell`` 下的 single-step、m=0 equivalence、MMS、稳定性、
   长时间传播、CPML wave-packet reference 和可视化案例。

.. container:: ap-lang ap-lang-en

   .. rubric:: Overview

   ``E_Maxwell`` documents AlgoPlasma field-advance subroutines and boundary
   extensions for numerically solving Maxwell's equations. The current main
   implementation uses the finite-difference time-domain method (FDTD):
   electric and magnetic fields are staggered in space and advanced with
   leapfrog half-step staggering in time. The module also provides
   convolutional perfectly matched layer (CPML) extensions, which act as
   electromagnetic-wave absorbing boundaries at the edges of a finite
   computational domain to reduce outgoing-wave reflections. The module covers
   2D axisymmetric cylindrical, full 3D cylindrical, and 3D Cartesian grids.

   .. rubric:: Where to Start

   .. list-table:: Reading and Usage Paths
      :header-rows: 1
      :widths: 26 36 38

      * - Reader goal
        - Start with
        - Then read
      * - Learn FDTD / Maxwell updates for the first time
        - :doc:`FDTD Learning Path <E_Maxwell/fdtd_learning_path>`
        - Start from :doc:`E03 Cartesian notes <E_Maxwell/E03_Maxwell_3Dxyz/fdtd_3d_cartesian_notes>`, then move to E01/E02.
      * - Integrate routines into your own code
        - :doc:`FDTD Usage Cookbook <E_Maxwell/fdtd_usage_cookbook>`
        - Open the matching E01/E02/E03 page and then the subroutine parameter table.
      * - Add absorbing boundaries
        - :doc:`CPML Cookbook <E_Maxwell/cpml_cookbook>`
        - Read the matching CPML module/subroutine pages and run wave-packet reference tests.
      * - Validate changes after editing kernels
        - :doc:`FDTD Testing Guide <E_Maxwell/fdtd_testing_guide>`
        - Then use :doc:`005_maxwell Tests </tests/005_maxwell/index>`.

   .. list-table:: Module Map
      :header-rows: 1
      :widths: 18 24 34 24

      * - Module
        - Coordinates / mode
        - Main responsibility
        - Tests / notes
      * - :doc:`E01_Maxwell_2Drz <E_Maxwell/E01_Maxwell_2Drz>`
        - 2D ``(r,z)`` TE/TM
        - Axisymmetric FDTD updates with TE/TM splitting and 2D RZ CPML.
        - :doc:`2D RZ notes <E_Maxwell/E01_Maxwell_2Drz/fdtd_2d_rz_axisymmetric_notes>`
      * - :doc:`E02_Maxwell_3Drtz <E_Maxwell/E02_Maxwell_3Drtz>`
        - 3D ``(r,phi,z)``
        - Full cylindrical six-component Yee-FDTD and CPML absorbing-boundary extension with explicit axis and metric handling.
        - :doc:`3D cylindrical notes <E_Maxwell/E02_Maxwell_3Drtz/fdtd_3d_cylindrical_notes>`
      * - :doc:`E03_Maxwell_3Dxyz <E_Maxwell/E03_Maxwell_3Dxyz>`
        - 3D ``(x,y,z)``
        - Cartesian six-component Yee-FDTD and 3D CPML extension.
        - :doc:`3D Cartesian notes <E_Maxwell/E03_Maxwell_3Dxyz/fdtd_3d_cartesian_notes>`

   .. rubric:: Numerical Structure

   All FDTD kernels discretize Maxwell curl equations. Non-CPML kernels handle
   interior-style curl updates; periodic wrapping, external boundary fill, source
   injection, and diagnostics are organized by the caller or test programs. CPML
   modules additionally maintain split-field memory variables for corrected curl
   terms inside absorbing layers. In other words, ``E_Maxwell`` is a set of
   composable low-level field-advance building blocks, not a full solver
   framework with mesh management, boundary orchestration, and I/O.

   .. rubric:: Test Entry

   The Maxwell/FDTD test-directory entry point is
   :doc:`005_maxwell Tests </tests/005_maxwell/index>`. Fuller formulas,
   visualization notes, and case details are collected in the :doc:`FDTD
   Testing Guide <E_Maxwell/fdtd_testing_guide>`. Coverage corresponds to
   ``tests/005_maxwell`` cases for single-step formulas, m=0 equivalence, MMS,
   stability, long-run pulse propagation, CPML wave-packet reference tests, and
   visualization.
