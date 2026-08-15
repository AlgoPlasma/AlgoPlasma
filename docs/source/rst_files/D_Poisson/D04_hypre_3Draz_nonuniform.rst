D04_hypre_3Draz_nonuniform
==========================

.. toctree::
    :maxdepth: 1
    :hidden:

    D04_hypre_3Draz_nonuniform/mod_D04_hypre_3Draz_nonuniform
    D04_hypre_3Draz_nonuniform/sub_D04_hypre_3Draz_nonuniform
    D04_hypre_3Draz_nonuniform/sub_D04_hypre_3Draz_nonuniform_A
    D04_hypre_3Draz_nonuniform/sub_D04_hypre_3Draz_nonuniform_A_mpi
    D04_hypre_3Draz_nonuniform/sub_D04_hypre_3Draz_nonuniform_bc_A_dielectric
    D04_hypre_3Draz_nonuniform/sub_D04_hypre_3Draz_nonuniform_bc_A_outflow

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``D04_hypre_3Draz_nonuniform`` 求解非均匀柱坐标 ``(r,alpha,z)`` 网格上的 3D Poisson 方程。
   它与 D03 共享 HYPRE Struct 求解思路，但矩阵系数来自局部 cell/face 尺度，而不是全局常数网格间距。

   .. list-table:: 文件角色
      :header-rows: 1
      :widths: 38 62

      * - 文件
        - 角色
      * - :doc:`mod_D04_hypre_3Draz_nonuniform.f90 <D04_hypre_3Draz_nonuniform/mod_D04_hypre_3Draz_nonuniform>`
        - 模块包装文件，集中 include D04 求解和组装例程。
      * - :doc:`sub_D04_hypre_3Draz_nonuniform.f90 <D04_hypre_3Draz_nonuniform/sub_D04_hypre_3Draz_nonuniform>`
        - HYPRE Struct PFMG 求解驱动，支持阶段化初始化、矩阵更新、求解和释放。
      * - :doc:`sub_D04_hypre_3Draz_nonuniform_A.f90 <D04_hypre_3Draz_nonuniform/sub_D04_hypre_3Draz_nonuniform_A>`
        - 单进程/单域非均匀柱坐标矩阵和 RHS 组装。
      * - :doc:`sub_D04_hypre_3Draz_nonuniform_A_mpi.f90 <D04_hypre_3Draz_nonuniform/sub_D04_hypre_3Draz_nonuniform_A_mpi>`
        - MPI-local 组装，使用一层 ghost 数据和 ``has_neighbor`` 描述局部拓扑。
      * - :doc:`sub_D04_hypre_3Draz_nonuniform_bc_A_dielectric.f90 <D04_hypre_3Draz_nonuniform/sub_D04_hypre_3Draz_nonuniform_bc_A_dielectric>`
        - 对已组装矩阵/RHS 应用介质面电荷边界修正。
      * - :doc:`sub_D04_hypre_3Draz_nonuniform_bc_A_outflow.f90 <D04_hypre_3Draz_nonuniform/sub_D04_hypre_3Draz_nonuniform_bc_A_outflow>`
        - 对已组装矩阵/RHS 应用 outflow/Robin 边界修正。

   .. rubric:: 数值注意

   D04 的组装不能假设 ``dr``、``da``、``dz`` 为常数。单域版本使用局部网格数组，MPI 版本还需要
   ghost 层，以便在 owned cell 附近正确计算非均匀几何系数。它和 D03 的差异主要在系数计算，
   而不是 HYPRE 求解阶段。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">赵隐剑 (2026/03/30; 2026/04/01) · 哈尔滨工业大学</p>
        <p class="ap-home-contact">王佰胜 (2026/04/25; 2026/04/27) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``D04_hypre_3Draz_nonuniform`` solves the 3D Poisson equation on a nonuniform
   cylindrical ``(r,alpha,z)`` grid. It shares the HYPRE Struct solve pattern used
   by D03, but its matrix coefficients come from local cell/face spacing instead
   of global constant mesh sizes.

   .. list-table:: File Roles
      :header-rows: 1
      :widths: 38 62

      * - File
        - Role
      * - :doc:`mod_D04_hypre_3Draz_nonuniform.f90 <D04_hypre_3Draz_nonuniform/mod_D04_hypre_3Draz_nonuniform>`
        - Module wrapper collecting D04 solve and assembly routines.
      * - :doc:`sub_D04_hypre_3Draz_nonuniform.f90 <D04_hypre_3Draz_nonuniform/sub_D04_hypre_3Draz_nonuniform>`
        - HYPRE Struct PFMG solve driver with staged initialization, matrix update, solve, and finalization.
      * - :doc:`sub_D04_hypre_3Draz_nonuniform_A.f90 <D04_hypre_3Draz_nonuniform/sub_D04_hypre_3Draz_nonuniform_A>`
        - Single-domain matrix/RHS assembly for the nonuniform cylindrical grid.
      * - :doc:`sub_D04_hypre_3Draz_nonuniform_A_mpi.f90 <D04_hypre_3Draz_nonuniform/sub_D04_hypre_3Draz_nonuniform_A_mpi>`
        - MPI-local assembly using one ghost layer and ``has_neighbor`` for local topology.
      * - :doc:`sub_D04_hypre_3Draz_nonuniform_bc_A_dielectric.f90 <D04_hypre_3Draz_nonuniform/sub_D04_hypre_3Draz_nonuniform_bc_A_dielectric>`
        - Applies dielectric surface-charge corrections to an assembled matrix/RHS.
      * - :doc:`sub_D04_hypre_3Draz_nonuniform_bc_A_outflow.f90 <D04_hypre_3Draz_nonuniform/sub_D04_hypre_3Draz_nonuniform_bc_A_outflow>`
        - Applies outflow/Robin boundary corrections to an assembled matrix/RHS.

   .. rubric:: Numerical Notes

   D04 must not assume constant ``dr``, ``da``, or ``dz``. The single-domain
   version uses local grid arrays, while the MPI version also needs ghost-layer
   data to compute nonuniform geometry near owned cells. Its main difference from
   D03 is coefficient calculation, not the HYPRE solve stage.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Yinjian ZHAO (2026/03/30; 2026/04/01) · Harbin Institute of Technology</p>
        <p class="ap-home-contact">Baisheng WANG (2026/04/25; 2026/04/27) · Harbin Institute of Technology</p>
      </div>
