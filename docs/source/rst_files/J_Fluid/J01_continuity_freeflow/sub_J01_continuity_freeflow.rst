sub_J01_continuity_freeflow.f90
-------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_J01_continuity_freeflow`` 在当前代码实现的密度更新区间
   ``i=il(1)-1:iu(1)``, ``j=il(2)-1:iu(2)``, ``k=il(3)-1:iu(3)``
   上推进三维自由流连续性方程。

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
        - 调用方传入的参考下界索引；对节点存储密度而言，最终更新从 ``il-1`` 开始。
      * - ``iu``
        - in
        - ``(1:3)``
        - 调用方传入的参考上界索引。
      * - ``n``
        - in/out
        - ``real(il(1)-2:iu(1)+1, il(2)-2:iu(2)+1, il(3)-2:iu(3)+1)``
        - 节点存储的密度数组，含 guard/ghost cells；例程最终回写的区间是
          ``il(1)-1:iu(1)``, ``il(2)-1:iu(2)``, ``il(3)-1:iu(3)``。
      * - ``s``
        - in
        - ``real(il(1)-2:iu(1)+1, il(2)-2:iu(2)+1, il(3)-2:iu(3)+1)``
        - 与 ``n`` 同索引布局的源项数组。
      * - ``ux``
        - in
        - ``real(il(1)-2:iu(1)+1, il(2)-2:iu(2)+1, il(3)-2:iu(3)+1)``
        - 与节点密度 ``n`` 同索引布局的 x 方向速度数组。
      * - ``uy``
        - in
        - ``real(il(1)-2:iu(1)+1, il(2)-2:iu(2)+1, il(3)-2:iu(3)+1)``
        - 与节点密度 ``n`` 同索引布局的 y 方向速度数组。
      * - ``uz``
        - in
        - ``real(il(1)-2:iu(1)+1, il(2)-2:iu(2)+1, il(3)-2:iu(3)+1)``
        - 与节点密度 ``n`` 同索引布局的 z 方向速度数组。
      * - ``n0``
        - inout/work
        - ``real(il(1)-2:iu(1)+1, il(2)-2:iu(2)+1, il(3)-2:iu(3)+1)``
        - 工作缓冲区；先复制旧 ``n``，随后作为更新公式右端中的 ``n^0`` 使用。

   .. rubric:: 局部假设

   当前实现采用归一化 ``dx=dy=dz=dt=1``；边界和 ghost cell 需要调用方在进入本例程前准备好。
   这里不应把 ``il``/``iu`` 机械理解成 cell-centered ``n(il:iu)`` 的下上界。
   对当前节点存储实现，最终更新循环实际写回的是 ``il-1:iu``。

   .. rubric:: 实现逻辑

   实现先把 ``n`` 复制到 ``n0``，再构造面通量工作数组 ``Fx/Fy/Fz``，
   最后用一阶 Lax-Friedrichs 型有限体积更新把结果写回密度数组。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_J01_continuity_freeflow`` solve the free-flow continuity equation using a 3D Lax-Friedrichs scheme.

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
        - integer(1:3), reference lower indices passed in by the caller. For
          the node-stored density used here, the updated region starts from
          ``il-1`` rather than exactly at ``il``.
      * - ``iu``
        - in
        - ``(1:3)``
        - integer(1:3), reference upper indices passed in by the caller.
      * - ``n``
        - in/out
        - scalar or caller-provided array
        - real,dimension(il(1)-2:iu(1)+1,il(2)-2:iu(2)+1, &
          il(3)-2:iu(3)+1), node-stored density array including guard cells, updated
          in-place. The active update region is
          ``il(1)-1:iu(1)``, ``il(2)-1:iu(2)``, ``il(3)-1:iu(3)``.
      * - ``s``
        - in
        - scalar or caller-provided array
        - real,dimension(il(1)-2:iu(1)+1,il(2)-2:iu(2)+1, &
          il(3)-2:iu(3)+1), source-term array on the same indexing layout
          expected by the update.
      * - ``ux``
        - in
        - scalar or caller-provided array
        - real,dimension(il(1)-2:iu(1)+1,il(2)-2:iu(2)+1, &
          il(3)-2:iu(3)+1), x-velocity array on the same indexing layout
          expected by the flux construction.
      * - ``uy``
        - in
        - scalar or caller-provided array
        - real,dimension(il(1)-2:iu(1)+1,il(2)-2:iu(2)+1, &
          il(3)-2:iu(3)+1), y-velocity array on the same indexing layout
          expected by the flux construction.
      * - ``uz``
        - in
        - scalar or caller-provided array
        - real,dimension(il(1)-2:iu(1)+1,il(2)-2:iu(2)+1, &
          il(3)-2:iu(3)+1), z-velocity array on the same indexing layout
          expected by the flux construction.
      * - ``n0``
        - out
        - scalar or caller-provided array
        - real,dimension(il(1)-2:iu(1)+1,il(2)-2:iu(2)+1, &
          il(3)-2:iu(3)+1), buffer storing the old values of ``n`` over all
          cells (including guard cells).

   .. rubric:: Local Assumptions

   The current implementation uses normalized ``dx=dy=dz=dt=1``; boundary and
   ghost-cell values must be prepared by the caller before entry. Because the
   density is node-stored, the update
   should be interpreted from the explicit loops in the source:
   ``n(i,j,k)`` is updated for
   ``i=il(1)-1:iu(1)``, ``j=il(2)-1:iu(2)``, ``k=il(3)-1:iu(3)``.

   .. rubric:: Implementation Notes

   The implementation first copies ``n`` into ``n0``, then forms the
   face-staggered work arrays ``Fx/Fy/Fz`` from first-order Lax-Friedrichs
   fluxes plus source terms, and finally writes the updated density back over
   the implemented ``il-1:iu`` update region.

   .. rubric:: Indexing Convention

   The routine does not use a simple cell-centered ``n(il:iu)`` interpretation.
   Instead, the density is node-stored and:

   - ``n``, ``s``, ``ux``, ``uy``, ``uz``, and ``n0`` are declared on
     ``il(*)-2:iu(*)+1``.
   - ``Fx`` is declared on
     ``il(1)-2:iu(1)``, ``il(2)-1:iu(2)``, ``il(3)-1:iu(3)``.
   - ``Fy`` is declared on
     ``il(1)-1:iu(1)``, ``il(2)-2:iu(2)``, ``il(3)-1:iu(3)``.
   - ``Fz`` is declared on
     ``il(1)-1:iu(1)``, ``il(2)-1:iu(2)``, ``il(3)-2:iu(3)``.
   - The final density update uses
     ``n(il(1)-1:iu(1), il(2)-1:iu(2), il(3)-1:iu(3))``.

   .. rubric:: Generated API

   .. doxygenfile:: sub_J01_continuity_freeflow.f90
