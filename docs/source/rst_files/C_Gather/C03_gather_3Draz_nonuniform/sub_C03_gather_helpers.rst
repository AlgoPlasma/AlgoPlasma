sub_C03_gather_helpers.f90
--------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 文件作用

   ``sub_C03_gather_helpers.f90`` 把插值过程中的小步骤拆成独立例程。
   这些例程分别解决“网格是否合理”“粒子在哪个单元”“该取哪些位置”“如何合并场值”。
   其中 ``sub_C03_check_grid`` 可以由调用程序使用，其余函数只供 C03 内部调用。

   .. rubric:: sub_C03_check_grid：检查输入网格

   该例程适合在网格准备好后调用。它只检查一个方向，所以 r、alpha、z 要分别调用。
   检查的目的是避免后续插值使用零宽度、倒序坐标或互相矛盾的几何数据。

   .. code-block:: fortran

      call sub_C03_check_grid(lo,hi,face,width)

   .. list-table::
      :header-rows: 1
      :widths: 30 30 30

      * - 参数
        - 方向与范围
        - 用途
      * - ``lo,hi``
        - ``in; integer``
        - 该方向负责的单元上下界。
      * - ``face``
        - ``in; real(lo-1:hi)``
        - 单元面的实际坐标。
      * - ``width``
        - ``in; real(lo-1:hi+1)``
        - 单元宽度，包括两端额外一层宽度。

   源码依次检查 ``hi>=lo``、所有宽度为正、面坐标递增，以及
   ``face(i)-face(i-1)`` 与 ``width(i)`` 是否在浮点容差内一致。
   同一方向的坐标和宽度必须同单位：r/z 用 m，alpha 用 rad。
   失败时 ``error stop``；成功则直接返回，不修改网格。gather 不会自动调用这个完整检查。

   .. rubric:: c03_center：由单元编号求中心位置

   .. code-block:: fortran

      c = c03_center(idx,lo,hi,face,width)

   ``idx`` 是要查询的单元编号，返回值 ``c`` 是实际坐标。
   普通单元的中心取 ``0.5*(face(idx-1)+face(idx))``。
   查询左侧 ghost 单元时，从左边界面向外减去半个 ghost 宽度；右侧则加上半个宽度。
   这样无需额外提供 ghost face 数组，也能得到边界附近中心插值需要的位置。

   .. rubric:: c03_axis_stencil：计算一个方向的取点位置和权重

   .. code-block:: fortran

      call c03_axis_stencil(x,lo,hi,face,width,ic,ic0,wf,wc,cell)

   输入 ``x`` 是一个方向的粒子坐标。返回 ``ic``、``ic0`` 两个编号，以及 ``wf``、``wc`` 两个权重。
   这一步可按源码顺序分成三部分：

   1. 检查位置是否属于本地范围。仅在舍入误差范围内越界时，才将坐标钳制到边界。
   2. 寻找包含粒子的单元 ``ic``。没有 ``cell`` 时用二分搜索：每次检查中间面坐标，排除不含粒子的一半区间；有缓存时检查缓存单元是否仍包含粒子。
   3. 计算面权重，再判断粒子位于本单元中心的哪一侧，从而选出包围它的两个中心并计算中心权重。

   .. code-block:: fortran

      wf = min(1.0,max(0.0,(xx-face(ic-1))/span))
      cc = 0.5*(face(ic-1)+face(ic))
      if (xx < cc) then
          ic0=ic-1
      else
          ic0=ic
      end if

   ``xx`` 是检查后的坐标，``span`` 是本单元两面间距。``wf`` 表示粒子从左面到右面走过的比例；
   越靠近右面，右面场值应占的权重越大。
   ``ic0`` 确定后，调用 ``c03_center`` 得到两个中心的实际位置，再以相同的距离比例计算 ``wc``。
   非均匀网格上面间距和中心间距不同，因此两套权重分别计算。

   .. rubric:: c03_build_stencil：组合三个方向，并处理周期角度

   该例程接收 ``x(3)``，先检查半径非负，然后处理可选的角向周期。
   接着对 r、alpha、z 分别调用 ``c03_axis_stencil``，把单轴结果放入
   ``ic(3),ic0(3),wf(3),wc(3)``，交给 point 使用。

   同一个角度可以写成相差一个整周期的多个数值。提供 ``a_period`` 时，
   代码先用 ``modulo`` 把角度归入一个周期，再用 ``anint`` 选择靠近本地网格的那个周期副本。
   默认参考本地角向区间中点；若给出 ``cell``，则参考缓存单元的中心。
   这样周期边界附近的粒子可用本地坐标表达，随后仍要接受本地范围检查。
   ``a_origin`` 是周期起点，默认 0；``a_period`` 必须为正。

   .. rubric:: c03_trilinear：把八个网格值合成一个场值

   .. code-block:: fortran

      value = c03_trilinear(lo,hi,f,idx,w)

   ``f`` 是某一个场分量的三维数组，``lo,hi`` 是数组上下界，
   ``idx(3)`` 是三个方向的下端下标，``w(3)`` 是三个方向的上端权重。
   函数先检查 ``idx`` 和 ``idx+1`` 都在数组范围内，再读取八个值。

   一维情况下，加权就是 ``(1-w)*左端值+w*右端值``。
   三维情况下，代码先把 r 方向上的两两场值合并，再沿 alpha 合并，最后沿 z 合并。
   因此，源码较长的 ``value=...`` 表达式只是把同一项线性加权连续应用三次。
   返回值是一个标量；point 对六个场数组分别调用它，才得到完整的 ``E`` 和 ``B``。

.. container:: ap-lang ap-lang-en

   .. rubric:: File Purpose

   ``sub_C03_gather_helpers.f90`` separates interpolation into small operations:
   check the mesh, locate the particle cell, choose sample locations, and combine
   field values. Only sub_C03_check_grid is public; the remaining helpers are internal to C03.

   .. rubric:: sub_C03_check_grid: Check the Input Mesh

   Call this after preparing the grid. It checks one axis, so r, alpha, and z
   require separate calls. It prevents later interpolation from using zero widths,
   reversed coordinates, or inconsistent geometry.

   .. code-block:: fortran

      call sub_C03_check_grid(lo,hi,face,width)

   .. list-table::
      :header-rows: 1
      :widths: 30 30 30

      * - Argument
        - Direction and bounds
        - Purpose
      * - ``lo,hi``
        - ``in; integer``
        - Owned-cell bounds along this axis.
      * - ``face``
        - ``in; real(lo-1:hi)``
        - Physical face coordinates.
      * - ``width``
        - ``in; real(lo-1:hi+1)``
        - Cell widths including one extra cell at either end.

   It checks hi>=lo, positive widths, increasing faces, and agreement between
   face(i)-face(i-1) and width(i) within floating-point tolerance. Face coordinates
   and widths must share units: m for r/z and rad for alpha. Failure triggers
   error stop; success returns without changes. Gather does not automatically run this full check.

   .. rubric:: c03_center: Convert a Cell Index to Its Center

   .. code-block:: fortran

      c = c03_center(idx,lo,hi,face,width)

   idx is the requested cell index and c its physical center. Interior centers
   use 0.5*(face(idx-1)+face(idx)). The lower ghost center lies half a ghost width
   below the lower face; the upper ghost center lies half a width above the upper
   face. This supplies boundary center locations without an extra ghost-face array.

   .. rubric:: c03_axis_stencil: Select Samples and Weights on One Axis

   .. code-block:: fortran

      call c03_axis_stencil(x,lo,hi,face,width,ic,ic0,wf,wc,cell)

   Input x is one coordinate. Outputs ic and ic0 are indices; wf and wc are weights.
   The source performs three operations:

   1. Check local containment and clamp only roundoff-sized boundary excursions.
   2. Find the containing cell ic. Without cell, binary search compares a middle face and discards the half-interval without the particle. With a cache, verify that the cached cell still contains it.
   3. Compute face weights, determine which side of the cell center contains the particle, then select the two surrounding centers and calculate center weights.

   .. code-block:: fortran

      wf = min(1.0,max(0.0,(xx-face(ic-1))/span))
      cc = 0.5*(face(ic-1)+face(ic))
      if (xx < cc) then
          ic0=ic-1
      else
          ic0=ic
      end if

   xx is the checked coordinate and span the distance between bounding faces.
   wf is the fraction of that distance traveled toward the upper face: the closer
   the particle is to that face, the more its field contributes. After selecting
   ic0, c03_center returns the two actual center coordinates and wc is computed
   from the same distance-ratio idea. Face and center distances differ on a
   nonuniform mesh, so the two weights are calculated separately.

   .. rubric:: c03_build_stencil: Combine Three Axes and Handle Periodic Angles

   This routine accepts x(3), checks for nonnegative radius, and handles optional
   angular periodicity. It then calls c03_axis_stencil for r, alpha, and z, storing
   the results in ic(3),ic0(3),wf(3),wc(3) for the point routine.

   An angle can have several numerical representations separated by whole periods.
   With a_period, modulo first places it in one period, then anint selects a
   periodic copy near the local mesh. The reference is the local angular midpoint,
   or the cached cell center when cell is supplied. This expresses seam-adjacent
   particles in local coordinates; local containment is still checked. a_origin
   is the period origin, default zero, and a_period must be positive.

   .. rubric:: c03_trilinear: Combine Eight Samples into One Value

   .. code-block:: fortran

      value = c03_trilinear(lo,hi,f,idx,w)

   f is one three-dimensional field component, lo,hi are its bounds, idx(3)
   contains lower sample indices, and w(3) contains upper weights. The function
   checks that idx and idx+1 lie inside the array, then reads eight values.

   In one dimension, interpolation is (1-w)*lower_value+w*upper_value. In three
   dimensions, the code combines pairs along r, combines those results along alpha,
   then combines along z. The long value expression simply applies the same linear
   blend three times. It returns one scalar; point calls it for six arrays to obtain E and B... rubric:: Generated API

   .. doxygenfile:: sub_C03_gather_helpers.f90
