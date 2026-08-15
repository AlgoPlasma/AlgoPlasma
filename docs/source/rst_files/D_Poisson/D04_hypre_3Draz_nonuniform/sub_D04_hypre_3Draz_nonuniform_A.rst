sub_D04_hypre_3Draz_nonuniform_A.f90
------------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_D04_hypre_3Draz_nonuniform_A`` 为单域 Poisson 问题组装 7 点矩阵系数和 RHS。

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
      * - ``rmin``
        - in
        - scalar or caller-provided array
        - 径向网格起始 face 坐标。
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

   本页例程使用 cell-centered 柱坐标 ``(r,alpha,z)``；flattened 数组只覆盖调用方给定的 owned/active cells。非均匀版本的 ``dr``、``da``、``dz`` 是方向相关间距数组，MPI 版本需要包含相邻 ghost/halo 间距。HYPRE 句柄的生命周期由 ``do_init``、``do_updateA``、``do_finalize`` 或 C 包装器控制。

   .. rubric:: 实现逻辑

   实现按 cell 循环写入每个 cell 的 7 个 stencil entry，并同步构造 RHS。MPI 版本只处理本 rank owned cells，并用 neighbor flags 区分内部邻居和物理边界。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_D04_hypre_3Draz_nonuniform_A`` assemble the full 7-point matrix and RHS for the single-domain 3D cylindrical nonuniform Poisson equation on a cell-centered grid.

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
        - integer (1:3), lower cell-center indices of the full assembled domain in
          ``r,alpha,z``.
      * - ``iu``
        - in
        - ``(1:3)``
        - integer (1:3), upper cell-center indices of the full assembled domain in
          ``r,alpha,z``.
      * - ``rmin``
        - in
        - scalar or caller-provided array
        - real scalar, radial face position at ``r_{il(1)-1/2}`` for the full domain.
      * - ``eps0``
        - in
        - scalar or caller-provided array
        - real scalar, vacuum permittivity.
      * - ``dr``
        - in
        - scalar or caller-provided array
        - real (il(1):iu(1)), full-domain cell widths in the radial direction, without ghost
          layers.
      * - ``da``
        - in
        - scalar or caller-provided array
        - real (il(2):iu(2)), full-domain cell widths in the azimuthal direction, without
          ghost layers.
      * - ``dz``
        - in
        - scalar or caller-provided array
        - real (il(3):iu(3)), full-domain cell widths in the axial direction, without ghost
          layers.
      * - ``periodic``
        - in
        - ``(1:3)``
        - integer (1:3), periodic lengths in r,alpha,z.
      * - ``bc_type``
        - in
        - ``(1:6)``
        - integer (1:6), boundary-type codes on ``(r_lo,r_hi,a_lo,a_hi,z_lo,z_hi)``.
      * - ``bc_value``
        - in
        - ``(1:6)``
        - real (1:6), boundary values on ``(r_lo,r_hi,a_lo,a_hi,z_lo,z_hi)``. Dirichlet uses
          these entries directly.
      * - ``A_values``
        - out
        - ``(1:N)``
        - real (1:N), flattened 7-point stencil coefficients, `N =
          7*(iu(1)-il(1)+1)*(iu(2)-il(2)+1)*(iu(3)-il(3)+1)`.
      * - ``rho1d``
        - in
        - ``(1:M)``
        - real (1:M), flattened full-domain cell-centered charge density array, `M =
          (iu(1)-il(1)+1)*(iu(2)-il(2)+1)*(iu(3)-il(3)+1)`.
      * - ``RHS``
        - out
        - ``(1:M)``
        - real (1:M), flattened right-hand-side array.

   .. rubric:: Local Assumptions

   These routines use a cell-centered cylindrical ``(r,alpha,z)`` layout. Flattened arrays cover only the caller-provided owned/active cells. In the nonuniform variant, ``dr``, ``da``, and ``dz`` are directional spacing arrays; MPI-local assembly needs neighboring halo spacings. HYPRE handle lifetime is controlled by ``do_init``, ``do_updateA``, ``do_finalize``, or by the C wrapper.

   .. rubric:: Implementation Notes

   The implementation loops over cells, writes seven stencil entries per cell, and builds the RHS in the same traversal. MPI variants handle only owned cells and use neighbor flags to distinguish internal neighbors from physical boundaries.

   .. rubric:: Generated API

   .. doxygenfile:: sub_D04_hypre_3Draz_nonuniform_A.f90
