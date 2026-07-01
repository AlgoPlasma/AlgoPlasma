sub_D03_hypre_3Draz_uniform_A_mpi.f90
-------------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_D03_hypre_3Draz_uniform_A_mpi`` 为 MPI rank 本地子域组装柱坐标 Poisson 的 7 点矩阵系数和 RHS。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``il_loc``
        - in
        - ``(1:3)``
        - MPI rank 拥有的本地 cell 下界。
      * - ``iu_loc``
        - in
        - ``(1:3)``
        - MPI rank 拥有的本地 cell 上界。
      * - ``rface_lo``
        - in
        - scalar or caller-provided array
        - 本地径向下界 face 坐标。
      * - ``eps0``
        - in
        - scalar or caller-provided array
        - 真空介电常数。
      * - ``dr``
        - in
        - scalar or caller-provided array
        - 径向网格间距或间距数组。
      * - ``da``
        - in
        - scalar or caller-provided array
        - 方位角网格间距或间距数组。
      * - ``dz``
        - in
        - scalar or caller-provided array
        - 轴向网格间距或间距数组。
      * - ``periodic``
        - in
        - ``(1:3)``
        - 周期长度向量；0 表示该方向非周期。
      * - ``has_neighbor``
        - in
        - ``(1:6)``
        - 六个面的邻居标志；无邻居时该面按物理边界处理。
      * - ``bc_type``
        - in
        - ``(1:6)``
        - 六个边界面的类型码，顺序按 r/x、alpha/y、z 的下/上界。
      * - ``bc_value``
        - in
        - ``(1:6)``
        - 六个边界面的物理边界值。
      * - ``A_values``
        - out
        - ``(1:N)``
        - flattened 7 点 stencil 矩阵系数；每个 cell 按 center、负/正方向邻点顺序存放。
      * - ``rho1d``
        - in
        - ``(1:M)``
        - flattened 电荷密度或 Poisson RHS 源项数组。
      * - ``RHS``
        - out
        - ``(1:M)``
        - flattened 右端项数组，顺序必须和矩阵组装顺序一致。

   .. rubric:: 局部假设

   本页例程使用 cell-centered 柱坐标 ``(r,alpha,z)`` 和 7 点 stencil。``dr``、``da``、``dz`` 为均匀网格间距；flattened 数组顺序必须在矩阵、RHS 和解向量之间一致。HYPRE 句柄生命周期由调用方通过逻辑开关管理。

   .. rubric:: 实现逻辑

   实现按 cell 循环写入每个 cell 的 7 个 stencil entry，并同步构造 RHS。MPI 版本只处理本 rank owned cells，并用 neighbor flags 区分内部邻居和物理边界。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_D03_hypre_3Draz_uniform_A_mpi`` assemble the full 7-point matrix and RHS for the MPI-local 3D cylindrical uniform-grid Poisson equation on a cell-centered grid.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``il_loc``
        - in
        - ``(1:3)``
        - integer (1:3), lower owned cell-center indices in ``r,alpha,z`` on this MPI rank.
      * - ``iu_loc``
        - in
        - ``(1:3)``
        - integer (1:3), upper owned cell-center indices in ``r,alpha,z`` on this MPI rank.
      * - ``rface_lo``
        - in
        - scalar or caller-provided array
        - real scalar, physical radial face coordinate at ``r_{il_loc(1)-1/2}`` for this MPI
          rank.
      * - ``eps0``
        - in
        - scalar or caller-provided array
        - real scalar, vacuum permittivity.
      * - ``dr``
        - in
        - scalar or caller-provided array
        - real scalar, uniform radial cell width.
      * - ``da``
        - in
        - scalar or caller-provided array
        - real scalar, uniform azimuthal cell width.
      * - ``dz``
        - in
        - scalar or caller-provided array
        - real scalar, uniform axial cell width.
      * - ``periodic``
        - in
        - ``(1:3)``
        - integer (1:3), periodic lengths in ``r,alpha,z``.
      * - ``has_neighbor``
        - in
        - ``(1:6)``
        - logical (1:6), whether this MPI rank has a neighboring subdomain on
          ``(r_lo,r_hi,a_lo,a_hi,z_lo,z_hi)``.
      * - ``bc_type``
        - in
        - ``(1:6)``
        - integer (1:6), physical boundary-type codes on ``(r_lo,r_hi,a_lo,a_hi,z_lo,z_hi)``.
      * - ``bc_value``
        - in
        - ``(1:6)``
        - real (1:6), physical boundary values on ``(r_lo,r_hi,a_lo,a_hi,z_lo,z_hi)``.
      * - ``A_values``
        - out
        - ``(1:N)``
        - real (1:N), flattened 7-point stencil coefficients; ``N`` is seven times the number of owned cells.
      * - ``rho1d``
        - in
        - ``(1:M)``
        - real (1:M), flattened cell-centered charge-density array; ``M`` is the number of owned cells.
      * - ``RHS``
        - out
        - ``(1:M)``
        - real (1:M), flattened right-hand-side array.

   .. rubric:: Local Assumptions

   These routines use a cell-centered cylindrical ``(r,alpha,z)`` layout and a 7-point stencil. ``dr``, ``da``, and ``dz`` are uniform spacings; flattened matrix, RHS, and solution arrays must use the same order. HYPRE object lifetime is managed by the caller through logical switches.

   .. rubric:: Implementation Notes

   The implementation loops over cells, writes seven stencil entries per cell, and builds the RHS in the same traversal. MPI variants handle only owned cells and use neighbor flags to distinguish internal neighbors from physical boundaries.

   .. rubric:: Generated API

   .. doxygenfile:: sub_D03_hypre_3Draz_uniform_A_mpi.f90
