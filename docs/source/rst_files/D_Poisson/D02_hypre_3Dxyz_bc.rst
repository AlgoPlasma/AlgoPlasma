D02_hypre_3Dxyz_bc
==================

.. toctree::
    :maxdepth: 1
    :hidden:

    D02_hypre_3Dxyz_bc/mod_D02_hypre_3Dxyz_bc
    D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc
    D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A
    D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A_dielectric
    D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A_outflow
    D02_hypre_3Dxyz_bc/fun_D02_hypre_3Dxyz_bc
    D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_fortran

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``D02_hypre_3Dxyz_bc`` 是 Cartesian 3D Poisson 求解器的主要边界条件版本。它把矩阵/RHS
   组装和 HYPRE 求解分开：``*_A`` 例程构造 7 点 stencil 系数和右端项，求解例程只负责把这些数组交给
   HYPRE Struct PFMG。

   .. list-table:: 文件角色
      :header-rows: 1
      :widths: 34 66

      * - 文件
        - 角色
      * - :doc:`mod_D02_hypre_3Dxyz_bc.f90 <D02_hypre_3Dxyz_bc/mod_D02_hypre_3Dxyz_bc>`
        - 模块包装文件，集中 include Cartesian 组装和求解例程。
      * - :doc:`sub_D02_hypre_3Dxyz_bc.f90 <D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc>`
        - Fortran 到 C/HYPRE 的薄包装，适用于一次性求解流程。
      * - :doc:`sub_D02_hypre_3Dxyz_bc_fortran.f90 <D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_fortran>`
        - 纯 Fortran HYPRE Struct 接口，支持 init/update/solve/finalize 阶段化调用。
      * - :doc:`sub_D02_hypre_3Dxyz_bc_A.f90 <D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A>`
        - 组装 Cartesian 7 点矩阵和 RHS，并处理 Dirichlet/Neumann 等基本边界。
      * - :doc:`sub_D02_hypre_3Dxyz_bc_A_dielectric.f90 <D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A_dielectric>`
        - 在已组装矩阵/RHS 上加入介质面电荷修正。
      * - :doc:`sub_D02_hypre_3Dxyz_bc_A_outflow.f90 <D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A_outflow>`
        - 在已组装矩阵/RHS 上加入 outflow/Robin 类型边界修正。
      * - :doc:`fun_D02_hypre_3Dxyz_bc.c <D02_hypre_3Dxyz_bc/fun_D02_hypre_3Dxyz_bc>`
        - C/HYPRE Struct 包装函数。

   .. rubric:: 数据流

   调用方先确定本 rank 的 ``il:iu`` 盒子和 ``period``，再由组装例程填充 ``A_values`` 与
   ``rho1d``。每个 cell 的 stencil 系数按 ``center, xmin, xmax, ymin, ymax, zmin, zmax`` 存放。
   边界修正应在 HYPRE solve 之前完成，否则 PFMG 只会求解未修正的线性系统。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">赵隐剑 (2025/11/06; 2025/11/07; 2025/12/02; 2025/12/20) · 哈尔滨工业大学</p>
        <p class="ap-home-contact">王佰胜 (2025/12/15) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``D02_hypre_3Dxyz_bc`` is the main boundary-condition-aware Cartesian 3D
   Poisson solver. It separates matrix/RHS assembly from the HYPRE solve: the
   ``*_A`` routines build 7-point stencil coefficients and the right-hand side,
   while the solver routines hand those arrays to HYPRE Struct PFMG.

   .. list-table:: File Roles
      :header-rows: 1
      :widths: 34 66

      * - File
        - Role
      * - :doc:`mod_D02_hypre_3Dxyz_bc.f90 <D02_hypre_3Dxyz_bc/mod_D02_hypre_3Dxyz_bc>`
        - Module wrapper collecting the Cartesian assembly and solve routines.
      * - :doc:`sub_D02_hypre_3Dxyz_bc.f90 <D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc>`
        - Thin Fortran-to-C/HYPRE wrapper for one-shot solves.
      * - :doc:`sub_D02_hypre_3Dxyz_bc_fortran.f90 <D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_fortran>`
        - Pure Fortran HYPRE Struct interface with staged init/update/solve/finalize calls.
      * - :doc:`sub_D02_hypre_3Dxyz_bc_A.f90 <D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A>`
        - Assembles the Cartesian 7-point matrix and RHS with basic boundary conditions.
      * - :doc:`sub_D02_hypre_3Dxyz_bc_A_dielectric.f90 <D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A_dielectric>`
        - Adds dielectric surface-charge corrections to an assembled matrix/RHS.
      * - :doc:`sub_D02_hypre_3Dxyz_bc_A_outflow.f90 <D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A_outflow>`
        - Adds outflow/Robin-type boundary corrections to an assembled matrix/RHS.
      * - :doc:`fun_D02_hypre_3Dxyz_bc.c <D02_hypre_3Dxyz_bc/fun_D02_hypre_3Dxyz_bc>`
        - C/HYPRE Struct wrapper function.

   .. rubric:: Data Flow

   The caller first defines the local ``il:iu`` box and ``period`` vector, then the
   assembly routines fill ``A_values`` and ``rho1d``. Stencil entries are ordered
   as ``center, xmin, xmax, ymin, ymax, zmin, zmax`` for each cell. Boundary
   corrections must be applied before the HYPRE solve; otherwise PFMG solves the
   unmodified linear system.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Yinjian ZHAO (2025/11/06; 2025/11/07; 2025/12/02; 2025/12/20) · Harbin Institute of Technology</p>
        <p class="ap-home-contact">Baisheng WANG (2025/12/15) · Harbin Institute of Technology</p>
      </div>
