sub_B04_project_density
=======================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-b04-doc

   .. admonition:: 输入 → 单元积分 → 直接输出

      **输入：** 完成所需共享节点求和及轴点平均的节点密度、径向坐标、角向周期设置。

      **处理：** 在每个物理单元内积分三线性节点场，除以该单元体积。

      **输出：** 覆写 ``cell_density`` ，供需要单元体积平均源项的组装过程使用。节点密度保持原值。

   .. code-block:: fortran

      call sub_B04_project_density(r, periodic_phi, density, cell_density, ierr)

   .. rubric:: 输出的物理含义

   设 :math:`D_h` 是用 ``density`` 中的八个节点值重构的三线性场，
   单元平均值 :math:`\overline D_{ijk}` 写入 ``cell_density(i,j,k)``：

   .. math::

      \overline D_{ijk}=\frac{1}{\Omega_{ijk}}\int_{\Omega_{ijk}}D_h\,r\,dr\,d\phi\,dz,\qquad
      \Omega_{ijk}=\frac{r_{i+1}^2-r_i^2}{2}\Delta\phi_j\Delta z_k.

   这里 :math:`\Omega_{ijk}` 表示物理单元及其体积；沉积归一化中的 :math:`V_{ijk}` 则是与节点形函数配套的有效节点体积。

   **这是一个单元内的体积平均值。** 它适用于下游方程需要单元平均源项的情形。
   例如 :math:`D=r`，平均值是 :math:`\frac{2}{3}(r_R^3-r_L^3)/(r_R^2-r_L^2)`，通常不同于几何中点的场值。
   使用前应核对下游离散方程对源项定义位置和平均方式的要求。

   .. rubric:: 从积分得到八节点系数

   角向、轴向的一维线性权重积分除以各自单元宽度，均为 :math:`1/2`；径向由于体积元中的 :math:`r` 而得到

   .. math::

      \beta_L=\frac{2r_i+r_{i+1}}{3(r_i+r_{i+1})},\qquad
      \beta_R=1-\beta_L,

      \overline D_{ijk}=\frac14\sum_{b,c=0}^1
      [\beta_L D_{i,j+b,k+c}+\beta_R D_{i+1,j+b,k+c}].

   因此本接口只需要径向坐标；角向和轴向宽度在平均公式中约去。
   ``wl`` 和 ``wr`` 分别对应 :math:`\beta_L` 和 :math:`\beta_R`；用 ``ratio=r(i)/r(i+1)`` 计算，避免先对较大半径求和。
   ``na`` 是角向单元数 ``nphi``，``jp`` 是应用周期连接后的角向节点索引：末角单元的上端节点在周期情形下映射到零号节点。
   ``nodes(a,b,c)`` 暂存八个顶点值；接近浮点上限时，先按其最大绝对值 ``density_scale`` 缩放，求平均后再还原量级。

   .. literalinclude:: ../../../../../B_Scatter/B04_scatter_3d_cyl_nonuniform/sub_B04_project_density.f90
      :language: fortran
      :start-at:         ratio = r(i)/r(i+1)
      :end-before:     ierr = B04_OK

   按一致的独立节点计数，:math:`\sum\Omega\overline D=\sum VD`。
   含轴首个径向单元有 :math:`\beta_L=1/3,\ \beta_R=2/3`。

   .. rubric:: 参数与布局

   .. list-table::
      :header-rows: 1
      :widths: 23 13 64

      * - 参数
        - 方向
        - 形状、含义与单位
      * - ``r``
        - in
        - ``(0:nr)`` ；有限、严格递增，``r(0)>=0`` ，至少一个径向单元；保留物理半径
      * - ``periodic_phi``
        - in
        - logical；决定角向末端连接及角单元数推断
      * - ``density``
        - in
        - 周期 ``(0:nr,0:nphi-1,0:nz)`` ，非周期 ``(0:nr,0:nphi,0:nz)`` ；有限节点密度
      * - ``cell_density``
        - inout
        - 已分配 ``(0:nr-1,0:nphi-1,0:nz-1)`` ；成功时全部覆写，与输入密度同单位
      * - ``ierr``
        - out
        - 整数；见 :ref:`公共状态码 <b04-status-zh>`

   ``nr`` 从 ``r`` 推得，``nphi/nz`` 从输入密度及周期设置推得，每向至少一个单元。
   首元素映射为零；传入完整物理节点范围，每个目标单元的八节点均可访问，无额外外侧节点要求。
   检查径向坐标、数组形状及密度有限性；非零返回保持输出原值。编译精度与调用方一致。


   返回 :doc:`B04 总览 </rst_files/B_Scatter/B04_scatter_3d_cyl_nonuniform>` · :doc:`调用示例 <usage>` · :doc:`测试与结果 </tests/004_scatter/B04_scatter_3d_cyl_nonuniform>`

.. container:: ap-lang ap-lang-en ap-b04-doc

   .. admonition:: Inputs → cell integration → output

      **Inputs:** complete nodal density after required summation/axis averaging, radial coordinates and angular topology.

      **Operation:** integrate the trilinear nodal field over each physical cell and divide by its volume.

      **Output:** replaces ``cell_density`` for cell-average source assembly; nodal input is retained.

   .. code-block:: fortran

      call sub_B04_project_density(r, periodic_phi, density, cell_density, ierr)

   .. rubric:: Meaning of the output

   Let :math:`D_h` be the trilinear field reconstructed from eight values in ``density``.
   The cell average :math:`\overline D_{ijk}` is written to ``cell_density(i,j,k)``:

   .. math::

      \overline D_{ijk}=\frac{1}{\Omega_{ijk}}\int_{\Omega_{ijk}}D_h\,r\,dr\,d\phi\,dz,\qquad
      \Omega_{ijk}=\frac{r_{i+1}^2-r_i^2}{2}\Delta\phi_j\Delta z_k.

   Here :math:`\Omega_{ijk}` denotes the physical cell and its volume; :math:`V_{ijk}` in deposition is the effective nodal volume associated with a nodal basis.

   **Each result is a physical cell-volume average.** For :math:`D=r`, it is
   :math:`\frac{2}{3}(r_R^3-r_L^3)/(r_R^2-r_L^2)`, generally different from the midpoint value.
   Use it when the downstream discretization requires this source definition.

   .. rubric:: Integration coefficients and code

   Normalized angular and axial endpoint integrals each give :math:`1/2`. Radial weights retain the volume factor :math:`r`:

   .. math::

      \beta_L=\frac{2r_i+r_{i+1}}{3(r_i+r_{i+1})},\qquad
      \beta_R=1-\beta_L,

      \overline D_{ijk}=\frac14\sum_{b,c=0}^1
      [\beta_L D_{i,j+b,k+c}+\beta_R D_{i+1,j+b,k+c}].

   Angular/axial widths cancel, so only radial coordinates are needed.
   ``wl`` and ``wr`` are :math:`\beta_L` and :math:`\beta_R`, computed with ``ratio=r(i)/r(i+1)`` to avoid summing large radii first.
   ``na`` is the angular cell count ``nphi``; ``jp`` is the angular node index after periodic mapping, which sends the last cell's upper node to zero.
   ``nodes(a,b,c)`` holds the eight vertex values. Near the floating-point limit, values are divided by their maximum absolute value ``density_scale`` before averaging, then the scale is restored.

   .. literalinclude:: ../../../../../B_Scatter/B04_scatter_3d_cyl_nonuniform/sub_B04_project_density.f90
      :language: fortran
      :start-at:         ratio = r(i)/r(i+1)
      :end-before:     ierr = B04_OK

   With consistent independent-node counting, :math:`\sum\Omega\overline D=\sum VD`.
   The first radial cell at the axis has :math:`\beta_L=1/3,\ \beta_R=2/3`.

   .. rubric:: Parameters and layout

   .. list-table::
      :header-rows: 1
      :widths: 23 13 64

      * - Parameter
        - Direction
        - Shape, meaning and units
      * - ``r``
        - in
        - ``(0:nr)``; finite, strictly increasing, ``r(0)>=0``, at least one cell; retain physical radius
      * - ``periodic_phi``
        - in
        - logical; selects endpoint identification and angular cell-count inference
      * - ``density``
        - in
        - Periodic ``(0:nr,0:nphi-1,0:nz)``, otherwise ``(0:nr,0:nphi,0:nz)``; finite nodal densities
      * - ``cell_density``
        - inout
        - Preallocated ``(0:nr-1,0:nphi-1,0:nz-1)``; fully overwritten on success, same units as density
      * - ``ierr``
        - out
        - Integer :ref:`shared status <b04-status-en>`

   ``nr`` comes from ``r`` and ``nphi/nz`` from density and topology. Each direction has at least one cell.
   The first actual element maps to zero. Pass complete physical-node extents with all eight nodes available per output cell; no extra exterior nodes are required.
   Checks cover radial coordinates, shapes and finite density; a nonzero returned status preserves the output. Use the caller's real precision.


   :doc:`B04 overview </rst_files/B_Scatter/B04_scatter_3d_cyl_nonuniform>` · :doc:`Usage example <usage>` · :doc:`Tests and results </tests/004_scatter/B04_scatter_3d_cyl_nonuniform>`

   .. raw:: html

      <details class="ap-b04-api">
      <summary>Generated API — source reference</summary>

   .. doxygenfile:: sub_B04_project_density.f90

   .. raw:: html

      </details>
