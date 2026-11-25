sub_D07_phi_to_E_nonuniform.f90
===============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``D07_phi_to_E_nonuniform`` 在 D04 非均匀柱坐标 ``(r,alpha,z)`` Poisson 求解后，
   由单元中心电势计算同位置的 ``Er``、``Ea``、``Ez``，满足 :math:`\mathbf{E}=-\nabla\phi`。

   .. code-block:: fortran

      call sub_D07_phi_to_E_nonuniform(il,iu,rface_lo,dr,da,dz,phi,Er,Ea,Ez)

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 30 42

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``il``
        - in
        - ``(1:3)``
        - 本地拥有单元下界，顺序 r、alpha、z。
      * - ``iu``
        - in
        - ``(1:3)``
        - 本地拥有单元上界。
      * - ``rface_lo``
        - in
        - ``scalar``
        - 本地最低径向面的全局半径，非负；与 D04 A_mpi 一致。
      * - ``dr``
        - in
        - ``il(1)-1:iu(1)+1``
        - 正径向单元宽度，含 ghost 值。
      * - ``da``
        - in
        - ``il(2)-1:iu(2)+1``
        - 正角向单元宽度，弧度，含 ghost 值。
      * - ``dz``
        - in
        - ``il(3)-1:iu(3)+1``
        - 正轴向单元宽度，含 ghost 值。
      * - ``phi``
        - in
        - ``3D``
        - 电势，各方向范围 il(d)-1:iu(d)+1；ghost 层已填充。
      * - ``Er``
        - inout
        - ``same as phi``
        - 径向电场，仅覆盖拥有单元，ghost 值不变。
      * - ``Ea``
        - inout
        - ``same as phi``
        - 物理角向电场，含 1/r 因子，仅覆盖拥有单元。
      * - ``Ez``
        - inout
        - ``same as phi``
        - 轴向电场，仅覆盖拥有单元。


   .. rubric:: 局部假设

   使用 D04 的单元中心柱坐标布局，单元中心位于两侧单元面的中点。
   ``phi`` 和电场数组各方向均含一层 ghost 格；``dr/da/dz`` 也含一层 ghost 值且必须为正。
   ``rface_lo`` 是本地最低径向面的全局半径，中心半径由它和 ``dr`` 累积得到。
   无 MPI 或外部库依赖。

   ``da`` 使用弧度，半径、``dr``、``dz`` 使用与 D04 一致的长度单位。
   角向分量 ``Ea`` 包含柱坐标因子 :math:`1/r_i`，表示物理角向电场。
   输出单位为电势/长度；间距已包含在差分公式中，无需再乘单位网格间距换算因子。

   .. rubric:: 实现逻辑

   先构造各方向左右中心距离和中心半径，再以 k-j-i 三重循环遍历拥有单元。
   ``dr/da/dz`` 是单元宽度；求导使用的左右中心距离分别由相邻单元宽度计算，
   不假定两侧距离相等。径向距离如下，角向和轴向分别将 ``dr`` 换为 ``da`` 和 ``dz``。
   其中 :math:`\phi_-`、:math:`\phi_0`、:math:`\phi_+` 为相应方向三个相邻中心的电势。

   .. math::

      h_{r,-}=\frac{dr(i-1)+dr(i)}{2},\qquad
      h_{r,+}=\frac{dr(i)+dr(i+1)}{2}.

   .. math::

      D_q\phi=\frac{h_{q,+}}{h_{q,-}+h_{q,+}}
                \frac{\phi_0-\phi_-}{h_{q,-}}
             +\frac{h_{q,-}}{h_{q,-}+h_{q,+}}
                \frac{\phi_+-\phi_0}{h_{q,+}},\qquad q\in\{r,\alpha,z\}.

   .. math::

      E_r=-D_r\phi,\qquad E_\alpha=-\frac{1}{r_i}D_\alpha\phi,\qquad E_z=-D_z\phi.


   .. rubric:: 调用注意

   调用前应展开 D04 的一维解并填充电势 ghost 层（例如通过 D05），随后完成物理边界修正。
   宽度 ghost 值在进程分界取邻域单元宽度，在周期接缝取另一端宽度。
   仅写拥有单元 ``il:iu``，电场 ghost 值保持不变，后续由调用方交换和修正。
   边界精度依赖电势 ghost 值的重构。轴线是单元面，不计算 ``r=0`` 点值；
   轴线延拓需满足对应电势的正则性。输出均为单元中心值，不能直接接入需要面中心电场的 C03。



.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``D07_phi_to_E_nonuniform`` computes cell-centered ``Er``, ``Ea`` and ``Ez``
   from D04 nonuniform cylindrical ``(r,alpha,z)`` potentials,
   using :math:`\mathbf{E}=-\nabla\phi`.

   .. code-block:: fortran

      call sub_D07_phi_to_E_nonuniform(il,iu,rface_lo,dr,da,dz,phi,Er,Ea,Ez)

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 30 42

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``il``
        - in
        - ``(1:3)``
        - Lower local owned indices in r,alpha,z.
      * - ``iu``
        - in
        - ``(1:3)``
        - Upper local owned indices.
      * - ``rface_lo``
        - in
        - ``scalar``
        - Nonnegative global radius of the lower local radial face, matching D04 A_mpi.
      * - ``dr``
        - in
        - ``il(1)-1:iu(1)+1``
        - Positive radial cell widths, including ghosts.
      * - ``da``
        - in
        - ``il(2)-1:iu(2)+1``
        - Positive angular cell widths in radians, including ghosts.
      * - ``dz``
        - in
        - ``il(3)-1:iu(3)+1``
        - Positive axial cell widths, including ghosts.
      * - ``phi``
        - in
        - ``3D``
        - Potential; il(d)-1:iu(d)+1 in each direction, with filled ghosts.
      * - ``Er``
        - inout
        - ``same as phi``
        - Radial field; owned cells overwritten, ghosts preserved.
      * - ``Ea``
        - inout
        - ``same as phi``
        - Physical azimuthal field, including 1/r; only owned cells written.
      * - ``Ez``
        - inout
        - ``same as phi``
        - Axial field; only owned cells written.


   .. rubric:: Local Assumptions

   Use D04 cell-centered cylindrical geometry, with each center at the midpoint
   of its two faces. Potential and field arrays carry one ghost layer per side;
   positive width arrays also carry one ghost value per side. ``rface_lo`` is
   the global radius of the lower local radial face; center radii are accumulated
   from this face using ``dr``. No MPI or external library dependencies.

   ``da`` is measured in radians; radius, ``dr`` and ``dz`` use D04 length units.
   ``Ea`` is the physical azimuthal field and includes the cylindrical factor
   :math:`1/r_i`. Output units are potential/length; spacing is already included
   in the stencil, so no additional unit-grid spacing factor is required.

   .. rubric:: Implementation Notes

   Build the left/right center distances and radial centers, then traverse owned
   cells in k-j-i order.
   ``dr/da/dz`` are cell widths, not center-to-center distances. Left and right
   distances are computed separately from adjacent widths. The radial distances
   are shown below; replace ``dr`` by ``da`` or ``dz`` for the other directions.
   The values :math:`\phi_-`, :math:`\phi_0` and :math:`\phi_+` are the three neighboring potentials.

   .. math::

      h_{r,-}=\frac{dr(i-1)+dr(i)}{2},\qquad
      h_{r,+}=\frac{dr(i)+dr(i+1)}{2}.

   .. math::

      D_q\phi=\frac{h_{q,+}}{h_{q,-}+h_{q,+}}
                \frac{\phi_0-\phi_-}{h_{q,-}}
             +\frac{h_{q,-}}{h_{q,-}+h_{q,+}}
                \frac{\phi_+-\phi_0}{h_{q,+}},\qquad q\in\{r,\alpha,z\}.

   .. math::

      E_r=-D_r\phi,\qquad E_\alpha=-\frac{1}{r_i}D_\alpha\phi,\qquad E_z=-D_z\phi.


   .. rubric:: Calling Notes

   Unpack the D04 solution and fill potential ghosts (e.g. with D05), then
   apply physical-boundary corrections before calling. Width ghosts use neighbor
   widths at process interfaces and wrapped widths at periodic seams. Only owned
   cells ``il:iu`` are written; output ghosts are preserved and must be exchanged
   and corrected afterwards. Boundary accuracy depends on potential ghost
   reconstruction. The axis is a face; no r=0 point values are computed, and axis
   extension must satisfy potential regularity. All outputs are cell-centered,
   so they cannot be passed directly to the face-centered C03 interface.


   .. rubric:: Generated API

   .. doxygenfile:: sub_D07_phi_to_E_nonuniform.f90
