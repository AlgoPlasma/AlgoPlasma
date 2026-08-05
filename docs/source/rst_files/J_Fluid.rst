J_Fluid
=======

.. toctree::
    :maxdepth: 1

    J_Fluid/J01_continuity_freeflow

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 概览

   ``J_Fluid`` 放置 AlgoPlasma 的流体方程更新例程。当前只有一个子模块，负责在三维直角网格上推进自由流连续性方程。

   .. math::

      \frac{\partial n}{\partial t}
      + \nabla \cdot (\mathbf{u} n)
      = s.

   其中 ``n`` 是按网格节点存储的数密度场；``u=(ux,uy,uz)`` 是给定速度场，
   ``s`` 是源项。

   .. list-table:: 子模块
      :header-rows: 1
      :widths: 28 32 40

      * - 模块
        - 数值方法
        - 主要职责
      * - :doc:`J01_continuity_freeflow <J_Fluid/J01_continuity_freeflow>`
        - 一阶 Lax-Friedrichs 有限体积通量
        - 在 ``dx=dy=dz=dt=1`` 的约定下更新三维数密度场。

   .. rubric:: 共享约定

   - 网格和时间步采用归一化约定 ``dx=dy=dz=dt=1``。
   - 速度场 ``ux``、``uy``、``uz`` 与 ``n`` 使用相同的节点索引布局，并在一次更新中保持不变。
   - 边界条件和 guard/ghost cells 需要在调用流体更新例程前由调用者设置。
   - 由于 ``n`` 采用节点存储，按当前代码实现，密度最终更新区间是
     ``i=il(1)-1:iu(1)``, ``j=il(2)-1:iu(2)``, ``k=il(3)-1:iu(3)``；
     因而不能把 ``il``/``iu`` 直接理解成 cell-centered ``n(il:iu)`` 的下上界。

   .. rubric:: 测试状态

   当前仓库中未发现覆盖 ``J_Fluid`` 的独立顶层 ``tests/`` 回归目录。若后续添加连续性方程或有限体积通量测试，应同步在 :doc:`测试总览 </tests/index>` 和本页补充链接。

.. container:: ap-lang ap-lang-en

   .. rubric:: Overview

   ``J_Fluid`` contains fluid-equation update routines for AlgoPlasma. The current
   module advances the free-flow continuity equation on a three-dimensional
   Cartesian mesh:

   .. math::

      \frac{\partial n}{\partial t}
      + \nabla \cdot (\mathbf{u} n)
      = s.

   Here ``n`` is a node-stored number-density field. ``u=(ux,uy,uz)`` is a
   prescribed velocity field, and ``s`` is a source term.

   .. list-table:: Submodules
      :header-rows: 1
      :widths: 28 32 40

      * - Module
        - Numerical method
        - Main responsibility
      * - :doc:`J01_continuity_freeflow <J_Fluid/J01_continuity_freeflow>`
        - First-order Lax-Friedrichs finite-volume flux
        - Update a three-dimensional density field under the ``dx=dy=dz=dt=1`` convention.

   .. rubric:: Shared Conventions

   - Grid spacing and time step use the normalized convention ``dx=dy=dz=dt=1``.
   - ``ux``, ``uy``, and ``uz`` use the same nodal indexing layout as ``n`` and remain fixed during one update.
   - Boundary conditions and guard/ghost cells must be set by the caller before invoking the fluid update.
   - Because ``n`` is node-stored, the density update region in the current code is
     ``i=il(1)-1:iu(1)``, ``j=il(2)-1:iu(2)``, ``k=il(3)-1:iu(3)``, so ``il``/``iu``
     should not be read as cell-centered ``n(il:iu)`` bounds.

   .. rubric:: Test Status

   The current repository does not contain a standalone top-level ``tests/``
   regression directory for ``J_Fluid``. If continuity-equation or finite-volume
   flux tests are added later, link them from both the :doc:`test overview
   </tests/index>` and this page.
