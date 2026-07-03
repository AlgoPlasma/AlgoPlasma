D03_hypre_3Draz_uniform
=======================

.. toctree::
    :maxdepth: 1
    :hidden:

    D03_hypre_3Draz_uniform/mod_D03_hypre_3Draz_uniform
    D03_hypre_3Draz_uniform/sub_D03_hypre_3Draz_uniform
    D03_hypre_3Draz_uniform/sub_D03_hypre_3Draz_uniform_A
    D03_hypre_3Draz_uniform/sub_D03_hypre_3Draz_uniform_A_mpi
    D03_hypre_3Draz_uniform/sub_D03_hypre_3Draz_uniform_bc_A_dielectric
    D03_hypre_3Draz_uniform/sub_D03_hypre_3Draz_uniform_bc_A_outflow

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``D03_hypre_3Draz_uniform`` 求解均匀柱坐标 ``(r,alpha,z)`` 网格上的 3D Poisson 方程。
   它保留 HYPRE Struct 7 点邻接拓扑，但矩阵系数包含柱坐标几何因子、轴线处理和角向/轴向周期条件。

   .. list-table:: 文件角色
      :header-rows: 1
      :widths: 36 64

      * - 文件
        - 角色
      * - :doc:`mod_D03_hypre_3Draz_uniform.f90 <D03_hypre_3Draz_uniform/mod_D03_hypre_3Draz_uniform>`
        - 模块包装文件，集中 include D03 求解和组装例程。
      * - :doc:`sub_D03_hypre_3Draz_uniform.f90 <D03_hypre_3Draz_uniform/sub_D03_hypre_3Draz_uniform>`
        - HYPRE Struct PFMG 求解驱动，支持阶段化初始化、矩阵更新、求解和释放。
      * - :doc:`sub_D03_hypre_3Draz_uniform_A.f90 <D03_hypre_3Draz_uniform/sub_D03_hypre_3Draz_uniform_A>`
        - 单进程/单域均匀柱坐标矩阵和 RHS 组装。
      * - :doc:`sub_D03_hypre_3Draz_uniform_A_mpi.f90 <D03_hypre_3Draz_uniform/sub_D03_hypre_3Draz_uniform_A_mpi>`
        - MPI-local 组装，使用 ``has_neighbor`` 区分物理边界与邻 rank 接口。
      * - :doc:`sub_D03_hypre_3Draz_uniform_bc_A_dielectric.f90 <D03_hypre_3Draz_uniform/sub_D03_hypre_3Draz_uniform_bc_A_dielectric>`
        - 对已组装矩阵/RHS 应用介质面电荷边界修正。
      * - :doc:`sub_D03_hypre_3Draz_uniform_bc_A_outflow.f90 <D03_hypre_3Draz_uniform/sub_D03_hypre_3Draz_uniform_bc_A_outflow>`
        - 对已组装矩阵/RHS 应用 outflow/Robin 边界修正。

   .. rubric:: 数值注意

   D03 使用标量 ``dr``、``da``、``dz`` 描述均匀网格。轴线 ``r=0`` 处的 stencil 不能直接照搬
   Cartesian 形式，需要通过轴线几何和边界约束折算进系数。MPI 版本只组装本 rank owned cells，
   跨 rank 邻接由 HYPRE Struct grid 和 neighbor flags 共同描述。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">王佰胜 (2026/04/27) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``D03_hypre_3Draz_uniform`` solves the 3D Poisson equation on a uniform
   cylindrical ``(r,alpha,z)`` grid. It keeps the HYPRE Struct 7-neighbor topology,
   but the coefficients include cylindrical geometry, axis treatment, and
   azimuthal/axial periodicity.

   .. list-table:: File Roles
      :header-rows: 1
      :widths: 36 64

      * - File
        - Role
      * - :doc:`mod_D03_hypre_3Draz_uniform.f90 <D03_hypre_3Draz_uniform/mod_D03_hypre_3Draz_uniform>`
        - Module wrapper collecting D03 solve and assembly routines.
      * - :doc:`sub_D03_hypre_3Draz_uniform.f90 <D03_hypre_3Draz_uniform/sub_D03_hypre_3Draz_uniform>`
        - HYPRE Struct PFMG solve driver with staged initialization, matrix update, solve, and finalization.
      * - :doc:`sub_D03_hypre_3Draz_uniform_A.f90 <D03_hypre_3Draz_uniform/sub_D03_hypre_3Draz_uniform_A>`
        - Single-domain matrix/RHS assembly for the uniform cylindrical grid.
      * - :doc:`sub_D03_hypre_3Draz_uniform_A_mpi.f90 <D03_hypre_3Draz_uniform/sub_D03_hypre_3Draz_uniform_A_mpi>`
        - MPI-local assembly using ``has_neighbor`` to separate physical boundaries from neighbor-rank interfaces.
      * - :doc:`sub_D03_hypre_3Draz_uniform_bc_A_dielectric.f90 <D03_hypre_3Draz_uniform/sub_D03_hypre_3Draz_uniform_bc_A_dielectric>`
        - Applies dielectric surface-charge corrections to an assembled matrix/RHS.
      * - :doc:`sub_D03_hypre_3Draz_uniform_bc_A_outflow.f90 <D03_hypre_3Draz_uniform/sub_D03_hypre_3Draz_uniform_bc_A_outflow>`
        - Applies outflow/Robin boundary corrections to an assembled matrix/RHS.

   .. rubric:: Numerical Notes

   D03 uses scalar ``dr``, ``da``, and ``dz`` for a uniform mesh. The ``r=0`` axis
   cannot reuse the Cartesian stencil directly; axis geometry and constraints must
   be folded into the coefficients. The MPI version assembles only owned cells on
   each rank, while HYPRE Struct grid metadata and neighbor flags describe
   cross-rank adjacency.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Baisheng WANG (2026/04/27) · Harbin Institute of Technology</p>
      </div>
