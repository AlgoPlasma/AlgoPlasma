D01_hypre_3Dxyz_bc
==================

.. toctree::
    :maxdepth: 1
    :hidden:

    D01_hypre_3Dxyz_bc/mod_D01_hypre_3Dxyz_bc
    D01_hypre_3Dxyz_bc/sub_D01_hypre_3Dxyz_interface
    D01_hypre_3Dxyz_bc/fun_D01_hypre_3Dxyz_bc

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``D01_hypre_3Dxyz_bc`` 是较早的 Cartesian Poisson/HYPRE 接口。它将 Fortran 侧的一维 ``phi1d``、``rho1d`` 和本地 box 索引传给 C 侧 HYPRE Struct 求解器，由 C 例程创建
   7 点 stencil、组装矩阵并调用 PFMG。这个模块仍用于理解 D02 之前的 Cartesian 接口结构。

   .. list-table:: 文件角色
      :header-rows: 1
      :widths: 32 68

      * - 文件
        - 角色
      * - :doc:`mod_D01_hypre_3Dxyz_bc.f90 <D01_hypre_3Dxyz_bc/mod_D01_hypre_3Dxyz_bc>`
        - 模块包装文件，通过 include 暴露 Fortran-C 桥接子程序。
      * - :doc:`sub_D01_hypre_3Dxyz_interface.f90 <D01_hypre_3Dxyz_bc/sub_D01_hypre_3Dxyz_interface>`
        - Fortran 入口，把 MPI communicator、数组和边界标志传给 C 求解器。
      * - :doc:`fun_D01_hypre_3Dxyz_bc.c <D01_hypre_3Dxyz_bc/fun_D01_hypre_3Dxyz_bc>`
        - C/HYPRE 实现，创建 Struct grid、stencil、matrix/vector 和 PFMG solver。

   .. rubric:: 使用注意

   D01 假设 Cartesian cell-centered 网格，``bc`` 只覆盖 ``x`` 和 ``z`` 两端，``y`` 方向通过
   HYPRE periodic 设置处理。新代码通常优先参考 D02 的更完整边界组装接口。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">赵隐剑 (2025/11/09; 2025/12/15) · 哈尔滨工业大学</p>
        <p class="ap-home-contact">王佰胜 (2025/11/09; 2025/12/15) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``D01_hypre_3Dxyz_bc`` is the earlier Cartesian Poisson/HYPRE interface. The
   Fortran side passes flattened ``phi1d`` and ``rho1d`` arrays plus local box
   indices into a C-side HYPRE Struct solver. The C routine creates the 7-point
   stencil, assembles the matrix, and runs PFMG. This module is still useful for
   understanding the Cartesian interface that preceded D02.

   .. list-table:: File Roles
      :header-rows: 1
      :widths: 32 68

      * - File
        - Role
      * - :doc:`mod_D01_hypre_3Dxyz_bc.f90 <D01_hypre_3Dxyz_bc/mod_D01_hypre_3Dxyz_bc>`
        - Module wrapper that exposes the Fortran-C bridge through an include.
      * - :doc:`sub_D01_hypre_3Dxyz_interface.f90 <D01_hypre_3Dxyz_bc/sub_D01_hypre_3Dxyz_interface>`
        - Fortran entry point forwarding the MPI communicator, arrays, and boundary flags to the C solver.
      * - :doc:`fun_D01_hypre_3Dxyz_bc.c <D01_hypre_3Dxyz_bc/fun_D01_hypre_3Dxyz_bc>`
        - C/HYPRE implementation that creates the Struct grid, stencil, matrix/vector objects, and PFMG solver.

   .. rubric:: Notes

   D01 assumes a Cartesian cell-centered grid. ``bc`` covers the lower and upper
   ``x``/``z`` faces, while ``y`` periodicity is handled through HYPRE periodic
   settings. Newer code should usually use D02 for the more complete boundary
   assembly interface.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Yinjian ZHAO (2025/11/09; 2025/12/15) · Harbin Institute of Technology</p>
        <p class="ap-home-contact">Baisheng WANG (2025/11/09; 2025/12/15) · Harbin Institute of Technology</p>
      </div>
