J01_continuity_freeflow
=======================

.. toctree::
    :maxdepth: 1
    :hidden:

    J01_continuity_freeflow/mod_J01_continuity_freeflow
    J01_continuity_freeflow/sub_J01_continuity_freeflow

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块职责

   ``J01_continuity_freeflow`` 使用三维 Lax-Friedrichs 有限体积格式推进自由流连续性方程。
   例程在一次调用中原地更新节点存储的数密度 ``n``，并使用 ``n0`` 作为更新前密度的工作缓冲区。
   由于 ``n`` 不是 cell-centered ``n(il:iu)`` 布局，而是节点布局，
   具体更新区间应以 ``sub_J01_continuity_freeflow.f90`` 中的数组范围和循环边界为准。

   .. list-table:: 文件
      :header-rows: 1
      :widths: 40 60

      * - 文件
        - 说明
      * - :doc:`mod_J01_continuity_freeflow.f90 <J01_continuity_freeflow/mod_J01_continuity_freeflow>`
        - 模块包装器，通过 ``include`` 暴露连续性方程更新例程。
      * - :doc:`sub_J01_continuity_freeflow.f90 <J01_continuity_freeflow/sub_J01_continuity_freeflow>`
        - 计算三方向通量，并按当前实现约定更新
          ``i=il(1)-1:iu(1)``, ``j=il(2)-1:iu(2)``, ``k=il(3)-1:iu(3)`` 内的密度。

   .. rubric:: 数值格式

   在每个方向上，界面通量采用

   .. math::

      F_{L/R}
      =
      \frac{1}{2}(u_L n_L + u_R n_R)
      - \frac{1}{2}\alpha(n_R-n_L),
      \qquad
      \alpha=\max(|u_L|,|u_R|).

   对 active cell 的更新为

   .. math::

      n^{new}_{i,j,k}
      =
      n^0_{i,j,k}
      - (F^x_{i+1/2,j,k}-F^x_{i-1/2,j,k})
      - (F^y_{i,j+1/2,k}-F^y_{i,j-1/2,k})
      - (F^z_{i,j,k+1/2}-F^z_{i,j,k-1/2})
      - s_{i,j,k}.

   由于约定 ``dt=dx=dy=dz=1``，代码中没有额外比例系数。

   .. rubric:: 边界和稳定性

   调用前需要设置 guard cells 和边界条件。Lax-Friedrichs 格式是一阶格式，数值扩散与局部最大速度有关；
   在当前归一化步长下，通常需要满足有效 CFL 条件 ``max(|ux|,|uy|,|uz|) <= 1``。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">Yinjian ZHAO (2025/12/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``J01_continuity_freeflow`` advances the free-flow continuity equation with a
   three-dimensional Lax-Friedrichs finite-volume scheme. A call updates the
   node-stored number density ``n`` in place and uses ``n0`` as a work buffer
   holding the pre-update density.

   .. list-table:: Files
      :header-rows: 1
      :widths: 40 60

      * - File
        - Description
      * - :doc:`mod_J01_continuity_freeflow.f90 <J01_continuity_freeflow/mod_J01_continuity_freeflow>`
        - Module wrapper that exposes the continuity update routine through ``include``.
      * - :doc:`sub_J01_continuity_freeflow.f90 <J01_continuity_freeflow/sub_J01_continuity_freeflow>`
        - Computes directional fluxes and updates the density over
          ``i=il(1)-1:iu(1)``, ``j=il(2)-1:iu(2)``, ``k=il(3)-1:iu(3)``.

   .. rubric:: Numerical Scheme

   In each coordinate direction, the face flux is

   .. math::

      F_{L/R}
      =
      \frac{1}{2}(u_L n_L + u_R n_R)
      - \frac{1}{2}\alpha(n_R-n_L),
      \qquad
      \alpha=\max(|u_L|,|u_R|).

   The active-cell update is

   .. math::

      n^{new}_{i,j,k}
      =
      n^0_{i,j,k}
      - (F^x_{i+1/2,j,k}-F^x_{i-1/2,j,k})
      - (F^y_{i,j+1/2,k}-F^y_{i,j-1/2,k})
      - (F^z_{i,j,k+1/2}-F^z_{i,j,k-1/2})
      - s_{i,j,k}.

   Because ``dt=dx=dy=dz=1``, no extra scaling factors appear in the code.

   .. rubric:: Boundaries and Stability

   Guard cells and boundary conditions must be set before calling the routine.
   The Lax-Friedrichs scheme is first order and introduces numerical diffusion
   proportional to the maximum local velocity. Under the normalized step sizes,
   the effective CFL condition is typically ``max(|ux|,|uy|,|uz|) <= 1``.

   .. rubric:: Indexing Convention

   The routine should be read with its concrete array bounds, because the
   density is node-stored rather than a simple cell-centered ``n(il:iu)`` field.
   In the current implementation:

   - ``n``, ``s``, ``ux``, ``uy``, ``uz``, and ``n0`` are declared on
     ``il(*)-2:iu(*)+1``.
   - The density update loop runs over
     ``i=il(1)-1:iu(1)``, ``j=il(2)-1:iu(2)``, ``k=il(3)-1:iu(3)``.
   - The work arrays ``Fx/Fy/Fz`` are face-staggered relative to that update
     region.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Yinjian ZHAO (2025/12/02) · Harbin Institute of Technology</p>
      </div>
