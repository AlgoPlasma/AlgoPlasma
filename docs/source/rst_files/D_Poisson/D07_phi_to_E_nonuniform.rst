D07_phi_to_E_nonuniform
=======================

.. toctree::
    :maxdepth: 1
    :hidden:

    D07_phi_to_E_nonuniform/mod_D07_phi_to_E_nonuniform
    D07_phi_to_E_nonuniform/sub_D07_phi_to_E_nonuniform

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``D07_phi_to_E_nonuniform`` 在 D04 非均匀柱坐标 ``(r,alpha,z)`` Poisson 求解后，
   由单元中心电势计算同位置的 ``Er``、``Ea``、``Ez``，满足 :math:`\mathbf{E}=-\nabla\phi`。

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


   该公式对二次电势精确，左右中心距离同时缩小时具有二阶截断误差。
   等间距时退化为通常的中心差分。

   .. list-table:: 文件角色
      :header-rows: 1
      :widths: 38 62

      * - 文件
        - 角色
      * - :doc:`mod_D07_phi_to_E_nonuniform.f90 <D07_phi_to_E_nonuniform/mod_D07_phi_to_E_nonuniform>`
        - 模块包装文件，集中 include D07 子程序。
      * - :doc:`sub_D07_phi_to_E_nonuniform.f90 <D07_phi_to_E_nonuniform/sub_D07_phi_to_E_nonuniform>`
        - 非均匀三点差分，输出 Er/Ea/Ez。
   .. rubric:: 单位与归一化

   ``da`` 使用弧度，半径、``dr``、``dz`` 使用与 D04 一致的长度单位。
   角向分量 ``Ea`` 包含柱坐标因子 :math:`1/r_i`，表示物理角向电场。
   输出单位为电势/长度；间距已包含在差分公式中，无需再乘单位网格间距换算因子。

   .. rubric:: 调用注意

   调用前应展开 D04 的一维解并填充电势 ghost 层（例如通过 D05），随后完成物理边界修正。
   宽度 ghost 值在进程分界取邻域单元宽度，在周期接缝取另一端宽度。
   仅写拥有单元 ``il:iu``，电场 ghost 值保持不变，后续由调用方交换和修正。
   边界精度依赖电势 ghost 值的重构。轴线是单元面，不计算 ``r=0`` 点值；
   轴线延拓需满足对应电势的正则性。输出均为单元中心值，不能直接接入需要面中心电场的 C03。


.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``D07_phi_to_E_nonuniform`` computes cell-centered ``Er``, ``Ea`` and ``Ez``
   from D04 nonuniform cylindrical ``(r,alpha,z)`` potentials,
   using :math:`\mathbf{E}=-\nabla\phi`.

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


   The stencil is exact for quadratic potentials and second order as both neighbor
   distances shrink. Equal spacing recovers the usual central difference.

   .. list-table:: File Roles
      :header-rows: 1
      :widths: 38 62

      * - File
        - Role
      * - :doc:`mod_D07_phi_to_E_nonuniform.f90 <D07_phi_to_E_nonuniform/mod_D07_phi_to_E_nonuniform>`
        - Module wrapper collecting the public routine.
      * - :doc:`sub_D07_phi_to_E_nonuniform.f90 <D07_phi_to_E_nonuniform/sub_D07_phi_to_E_nonuniform>`
        - Nonuniform three-point derivative; outputs Er/Ea/Ez.
   .. rubric:: Units and Normalisation

   ``da`` is measured in radians; radius, ``dr`` and ``dz`` use D04 length units.
   ``Ea`` is the physical azimuthal field and includes the cylindrical factor
   :math:`1/r_i`. Output units are potential/length; spacing is already included
   in the stencil, so no additional unit-grid spacing factor is required.

   .. rubric:: Calling Notes

   Unpack the D04 solution and fill potential ghosts (e.g. with D05), then
   apply physical-boundary corrections before calling. Width ghosts use neighbor
   widths at process interfaces and wrapped widths at periodic seams. Only owned
   cells ``il:iu`` are written; output ghosts are preserved and must be exchanged
   and corrected afterwards. Boundary accuracy depends on potential ghost
   reconstruction. The axis is a face; no r=0 point values are computed, and axis
   extension must satisfy potential regularity. All outputs are cell-centered,
   so they cannot be passed directly to the face-centered C03 interface.
