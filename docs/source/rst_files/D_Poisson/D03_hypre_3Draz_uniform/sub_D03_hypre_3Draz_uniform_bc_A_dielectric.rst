sub_D03_hypre_3Draz_uniform_bc_A_dielectric.f90
-----------------------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_D03_hypre_3Draz_uniform_bc_A_dielectric`` 在已组装矩阵/RHS 上加入 dielectric 或 surface-charge 边界修正。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``il``
        - in
        - ``(1:3)``
        - 本地 active cell 下界索引。
      * - ``iu``
        - in
        - ``(1:3)``
        - 本地 active cell 上界索引。
      * - ``A_values``
        - in/out
        - ``(:)``
        - flattened 7 点 stencil 矩阵系数；每个 cell 按 center、负/正方向邻点顺序存放。
      * - ``RHS``
        - in/out
        - ``(:)``
        - flattened 右端项数组，顺序必须和矩阵组装顺序一致。
      * - ``bc``
        - in
        - ``(1:6)``
        - 六个边界面的类型码，顺序按 x/r 下/上、y/a 下/上、z 下/上。
      * - ``sr_lo``
        - in
        - optional scalar
        - 对应边界面的 surface-charge / dielectric 修正系数；仅在该边界类型需要时使用。
      * - ``sr_hi``
        - in
        - optional scalar
        - 对应边界面的 surface-charge / dielectric 修正系数；仅在该边界类型需要时使用。
      * - ``sa_lo``
        - in
        - optional scalar
        - 对应边界面的 surface-charge / dielectric 修正系数；仅在该边界类型需要时使用。
      * - ``sa_hi``
        - in
        - optional scalar
        - 对应边界面的 surface-charge / dielectric 修正系数；仅在该边界类型需要时使用。
      * - ``sz_lo``
        - in
        - optional scalar
        - 对应边界面的 surface-charge / dielectric 修正系数；仅在该边界类型需要时使用。
      * - ``sz_hi``
        - in
        - optional scalar
        - 对应边界面的 surface-charge / dielectric 修正系数；仅在该边界类型需要时使用。

   .. rubric:: 局部假设

   本页例程使用 cell-centered 柱坐标 ``(r,alpha,z)`` 和 7 点 stencil。``dr``、``da``、``dz`` 为均匀网格间距；flattened 数组顺序必须在矩阵、RHS 和解向量之间一致。HYPRE 句柄生命周期由调用方通过逻辑开关管理。

   .. rubric:: 实现逻辑

   实现只扫描边界 cell，并在匹配的边界类型上修正已经存在的 ``A_values`` 和 ``RHS``/``rho1d``；它应在基础矩阵组装之后、HYPRE solve 之前调用。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_D03_hypre_3Draz_uniform_bc_A_dielectric`` apply dielectric/surface-charge boundary corrections to the already assembled 7-point matrix and RHS for the single-domain 3D cylindrical uniform-grid Poisson equation on a cell-centered grid.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``il``
        - in
        - ``(1:3)``
        - integer (1:3), lower cell-center indices in ``r,alpha,z``.
      * - ``iu``
        - in
        - ``(1:3)``
        - integer (1:3), upper cell-center indices in ``r,alpha,z``.
      * - ``A_values``
        - in/out
        - ``(:)``
        - real (:), flattened 7-point stencil coefficients.
      * - ``RHS``
        - in/out
        - ``(:)``
        - real (:), flattened right-hand-side array.
      * - ``bc``
        - in
        - ``(1:6)``
        - integer (1:6), boundary-type codes on ``(r_lo,r_hi,a_lo,a_hi,z_lo,z_hi)``.
      * - ``sr_lo``
        - in
        - optional scalar
        - optional real ``(il(2)-1:iu(2),il(3)-1:iu(3))``, nodal surface-charge array on the
          ``r_lo`` face in ``(alpha,z)``.
      * - ``sr_hi``
        - in
        - optional scalar
        - optional real ``(il(2)-1:iu(2),il(3)-1:iu(3))``, nodal surface-charge array on the
          ``r_hi`` face in ``(alpha,z)``.
      * - ``sa_lo``
        - in
        - optional scalar
        - optional real ``(il(1)-1:iu(1),il(3)-1:iu(3))``, nodal surface-charge array on the
          ``a_lo`` face in ``(r,z)``.
      * - ``sa_hi``
        - in
        - optional scalar
        - optional real ``(il(1)-1:iu(1),il(3)-1:iu(3))``, nodal surface-charge array on the
          ``a_hi`` face in ``(r,z)``.
      * - ``sz_lo``
        - in
        - optional scalar
        - optional real ``(il(1)-1:iu(1),il(2)-1:iu(2))``, nodal surface-charge array on the
          ``z_lo`` face in ``(r,alpha)``.
      * - ``sz_hi``
        - in
        - optional scalar
        - optional real ``(il(1)-1:iu(1),il(2)-1:iu(2))``, nodal surface-charge array on the
          ``z_hi`` face in ``(r,alpha)``.

   .. rubric:: Local Assumptions

   These routines use a cell-centered cylindrical ``(r,alpha,z)`` layout and a 7-point stencil. ``dr``, ``da``, and ``dz`` are uniform spacings; flattened matrix, RHS, and solution arrays must use the same order. HYPRE object lifetime is managed by the caller through logical switches.

   .. rubric:: Implementation Notes

   The implementation scans boundary cells and modifies existing ``A_values`` plus ``RHS``/``rho1d`` only for matching boundary types. Call it after base assembly and before the HYPRE solve.

   .. rubric:: Generated API

   .. doxygenfile:: sub_D03_hypre_3Draz_uniform_bc_A_dielectric.f90
