sub_C03_gather_3Draz_nonuniform_point.f90
-----------------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 子程序说明

   ``sub_C03_gather_3Draz_nonuniform_point`` 是实际组织场插值的入口。
   输入 ``x(3)`` 给出一个位置，程序读取附近的网格场值，返回该位置的 ``E(3),B(3)``。
   它先统一计算粒子与网格的相对位置，再为六个分量选择各自需要的网格点。

   .. rubric:: 接口

   .. code-block:: fortran

      call sub_C03_gather_3Draz_nonuniform_point( &
          x,il,iu,r_face,a_face,z_face,dr,da,dz, &
          Er,Ea,Ez,Br,Ba,Bz,E,B,cell,a_period,a_origin)

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1

      * - 参数
        - 方向
        - 类型 / 范围
        - 含义
      * - ``x``
        - in
        - real(3)
        - ``(r,alpha,z)``，单位 m/rad/m，``r>=0``。
      * - ``il,iu``
        - in
        - integer(3)
        - 各轴 owned 单元闭区间。
      * - ``r_face,a_face,z_face``
        - in
        - real(il(d)-1:iu(d))
        - 径向、角向、轴向单元面坐标；单位 m/rad/m。
      * - ``dr,da,dz``
        - in
        - real(il(d)-1:iu(d)+1)
        - 单元宽度，含两端各一层 ghost，单位 m/rad/m。
      * - ``Er,Ea,Ez,Br,Ba,Bz``
        - in
        - real(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1)
        - 统一存储范围，物理采样位置依各分量交错布局而定。
      * - ``E,B``
        - out
        - real(3)
        - 粒子处柱坐标场分量；单位与输入场相同。
      * - ``cell``
        - in, optional
        - integer(3)
        - 当前 owned 单元缓存；只读，失效时 error stop，不自动更新。
      * - ``a_period``
        - in, optional
        - real scalar
        - 正角向周期，单位 rad；省略则不归约角度。
      * - ``a_origin``
        - in, optional
        - real scalar
        - 周期起点，单位 rad，默认 0；仅与 a_period 同时使用。

   .. rubric:: 先计算位置关系，再读取场值

   .. code-block:: fortran

      call c03_build_stencil( &
          x,il,iu,r_face,a_face,z_face,dr,da,dz, &
          ic,ic0,wf,wc,cell,a_period,a_origin)

   这一步只处理几何，不读取 ``Er`` 等场数组。返回的四个数组都只有三个元素，
   第 1、2、3 个元素分别描述 r、alpha、z 方向：

   .. list-table::
      :header-rows: 1
      :widths: 30 30 30

      * - 变量
        - 保存什么
        - 后面怎样使用
      * - ``ic(3)``
        - 粒子所在的单元编号。
        - 面场取 ``ic(d)-1`` 与 ``ic(d)`` 两个面。
      * - ``ic0(3)``
        - 包围粒子的两个中心中，下端中心的编号。
        - 中心场取 ``ic0(d)`` 与 ``ic0(d)+1``。
      * - ``wf(3)``
        - 面插值中，上端面应占的比例。
        - 下端权重为 ``1-wf(d)``，上端为 ``wf(d)``。
      * - ``wc(3)``
        - 中心插值中，上端中心应占的比例。
        - 下端权重为 ``1-wc(d)``，上端为 ``wc(d)``。

   .. rubric:: 以径向电场 E(1) 为例

   .. code-block:: fortran

      E(1)=c03_trilinear(il-1,iu+1,Er, &
          [ic(1)-1,ic0(2),ic0(3)], [wf(1),wc(2),wc(3)])

   ``E(1)`` 是粒子处的径向电场，数据来自网格数组 ``Er``。
   ``Er`` 沿 r 方向存放在面上，沿 alpha 和 z 方向存放在中心上，所以：

   - 径向从 ``ic(1)-1`` 这个面开始，使用面权重 ``wf(1)``。
   - 角向从 ``ic0(2)`` 这个中心开始，使用中心权重 ``wc(2)``。
   - 轴向从 ``ic0(3)`` 这个中心开始，使用中心权重 ``wc(3)``。

   方括号 ``[...]`` 在 Fortran 中构造一个小数组。这里第一个小数组给出三个方向的起始下标，
   第二个给出三个方向的权重。``c03_trilinear`` 在每个起始下标上取当前位置及其后一个位置，
   共读取 ``2×2×2=8`` 个场值，返回一个加权结果。``il-1,iu+1`` 告诉函数场数组可访问的范围。

   .. rubric:: 其余五个分量

   ``Ea`` 的角向位置在面上，``Ez`` 的轴向位置在面上，所以代码相应交换面模板与中心模板。
   三个磁场分量都存放在三个方向的面坐标交点上，因而共用 ``ic-1,wf``：

   .. code-block:: fortran

      E(2)=c03_trilinear(il-1,iu+1,Ea, &
          [ic0(1),ic(2)-1,ic0(3)], [wc(1),wf(2),wc(3)])
      E(3)=c03_trilinear(il-1,iu+1,Ez, &
          [ic0(1),ic0(2),ic(3)-1], [wc(1),wc(2),wf(3)])
      B(1)=c03_trilinear(il-1,iu+1,Br,ic-1,wf)
      B(2)=c03_trilinear(il-1,iu+1,Ba,ic-1,wf)
      B(3)=c03_trilinear(il-1,iu+1,Bz,ic-1,wf)

   ``ic-1`` 表示把 ``ic`` 的三个元素各减 1。六次调用完成后，
   ``E=(Er_p,Ea_p,Ez_p)``，``B=(Br_p,Ba_p,Bz_p)``；下标 p 表示粒子所在位置。
   各方向的几何关系只计算一次，随后由六个分量复用。

   .. rubric:: 调用注意

   靠近本地边界时，中心插值可能用到 ``il-1`` 或 ``iu+1`` 的场值。
   场数组在三个方向都多分配一层，调用者还需要填好其中会被访问的数据，包括边和角。
   ``dr,da,dz`` 的两端额外宽度用于确定这些 ghost 中心的位置。

   ``cell`` 用于传入已知的所属单元；它不会被更新，若与粒子位置不符则终止。
   ``a_period`` 启用周期角度处理，``a_origin`` 指定周期起点且必须与 ``a_period`` 一起使用。
   粒子仍必须属于本地网格；这些选项不负责传输粒子或填充边界场。

   半径允许为 0，但轴上的场值及边界对称性由调用方准备。
   网格、位置或可选参数不符合要求时，代码使用 ``error stop`` 停止执行。
   各辅助函数的具体用途见 :doc:`sub_C03_gather_helpers`。

.. container:: ap-lang ap-lang-en

   .. rubric:: Subroutine Description

   ``sub_C03_gather_3Draz_nonuniform_point`` organizes the actual field gather.
   Given one position x(3), it reads nearby grid-field samples and returns E(3),B(3).
   It first determines how the particle lies relative to the mesh, then selects the
   appropriate grid samples for each of the six components.

   .. rubric:: Interface

   .. code-block:: fortran

      call sub_C03_gather_3Draz_nonuniform_point( &
          x,il,iu,r_face,a_face,z_face,dr,da,dz, &
          Er,Ea,Ez,Br,Ba,Bz,E,B,cell,a_period,a_origin)

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1

      * - Parameter
        - Direction
        - Type / Range
        - Meaning
      * - ``x``
        - in
        - real(3)
        - (r,alpha,z) in m/rad/m, with r>=0.
      * - ``il,iu``
        - in
        - integer(3)
        - Inclusive owned-cell bounds in each axis.
      * - ``r_face,a_face,z_face``
        - in
        - real(il(d)-1:iu(d))
        - Radial/angular/axial face coordinates in m/rad/m.
      * - ``dr,da,dz``
        - in
        - real(il(d)-1:iu(d)+1)
        - Cell widths including one ghost at each end, in m/rad/m.
      * - ``Er,Ea,Ez,Br,Ba,Bz``
        - in
        - real(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1)
        - Common storage envelope; physical sample locations depend on staggering.
      * - ``E,B``
        - out
        - real(3)
        - Cylindrical field components at the particle, in input field units.
      * - ``cell``
        - in, optional
        - integer(3)
        - Read-only cached owned cell; stale values cause error stop, not a cache update.
      * - ``a_period``
        - in, optional
        - real scalar
        - Positive angular period in rad; no wrapping if omitted.
      * - ``a_origin``
        - in, optional
        - real scalar
        - Period origin in rad, default 0; requires a_period.

   .. rubric:: Locate Samples Before Reading Fields

   .. code-block:: fortran

      call c03_build_stencil( &
          x,il,iu,r_face,a_face,z_face,dr,da,dz, &
          ic,ic0,wf,wc,cell,a_period,a_origin)

   This call handles geometry only; it does not read Er or other field arrays.
   Each output array has three elements, corresponding to r, alpha, and z:

   .. list-table::
      :header-rows: 1
      :widths: 30 30 30

      * - Variable
        - Contents
        - Later use
      * - ``ic(3)``
        - Containing cell indices.
        - Face samples use ic(d)-1 and ic(d).
      * - ``ic0(3)``
        - Lower of the two surrounding center indices.
        - Center samples use ic0(d) and ic0(d)+1.
      * - ``wf(3)``
        - Upper-face interpolation weights.
        - Lower weight is 1-wf(d); upper weight is wf(d).
      * - ``wc(3)``
        - Upper-center interpolation weights.
        - Lower weight is 1-wc(d); upper weight is wc(d).

   .. rubric:: Reading the E(1) Assignment

   .. code-block:: fortran

      E(1)=c03_trilinear(il-1,iu+1,Er, &
          [ic(1)-1,ic0(2),ic0(3)], [wf(1),wc(2),wc(3)])

   E(1) is the radial electric field at the particle, read from grid array Er.
   Er is sampled on faces in r and centers in alpha and z. Thus:

   - The radial stencil starts at face ic(1)-1 and uses wf(1).
   - The angular stencil starts at center ic0(2) and uses wc(2).
   - The axial stencil starts at center ic0(3) and uses wc(3).

   Square brackets construct small Fortran arrays: the first supplies three lower
   indices and the second three weights. c03_trilinear reads the lower index and
   its successor in each direction, giving 2×2×2=8 values and one weighted result.
   il-1 and iu+1 specify accessible field-array bounds.

   .. rubric:: The Other Five Components

   Ea uses faces in the angular direction and Ez in the axial direction, so their
   face and center choices change accordingly. All three B components are sampled
   at intersections of face coordinates and share ic-1,wf:

   .. code-block:: fortran

      E(2)=c03_trilinear(il-1,iu+1,Ea, &
          [ic0(1),ic(2)-1,ic0(3)], [wc(1),wf(2),wc(3)])
      E(3)=c03_trilinear(il-1,iu+1,Ez, &
          [ic0(1),ic0(2),ic(3)-1], [wc(1),wc(2),wf(3)])
      B(1)=c03_trilinear(il-1,iu+1,Br,ic-1,wf)
      B(2)=c03_trilinear(il-1,iu+1,Ba,ic-1,wf)
      B(3)=c03_trilinear(il-1,iu+1,Bz,ic-1,wf)

   ``ic-1`` subtracts one from every element of ic. After these six calls,
   E=(Er_p,Ea_p,Ez_p) and B=(Br_p,Ba_p,Bz_p), where p denotes the particle position.
   Geometry is computed once and reused by all six components.

   .. rubric:: Calling Notes

   Near local boundaries, center interpolation may read fields at il-1 or iu+1.
   Arrays provide one extra layer in all directions; the caller must populate
   accessed values, including edges and corners. End entries of dr,da,dz locate
   these ghost centers.

   Optional cell supplies known containing indices. It is never updated and stale
   values cause termination. a_period enables angular periodicity; a_origin sets
   the period origin and requires a_period. The particle must still belong to the
   local grid. These options neither transfer particles nor fill boundary fields.

   Radius zero is allowed, but axis field values and symmetry belong to the caller.
   Invalid geometry, positions, or options trigger error stop. See
   :doc:`sub_C03_gather_helpers` for the individual helper functions.

   .. rubric:: Generated API

   .. doxygenfile:: sub_C03_gather_3Draz_nonuniform_point.f90
