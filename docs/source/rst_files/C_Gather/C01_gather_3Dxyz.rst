================
C01_gather_3Dxyz
================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   * :doc:`mod_C01_gather_3Dxyz.f90 <C01_gather_3Dxyz/mod_C01_gather_3Dxyz>`:

       ``mod_C01_gather_3Dxyz`` 是 C01 的源码级 Fortran module 入口，用 ``#include`` 收集并导出三线性 gather 例程和融合 gather-push 例程。

   * :doc:`sub_C01_gather_3Dxyz.f90 <C01_gather_3Dxyz/sub_C01_gather_3Dxyz>`:

       ``sub_C01_gather_3Dxyz`` 对单个粒子执行三维直角坐标 cell-centered 电磁场的三线性插值，返回粒子位置处的 :math:`\mathbf{E}` 与 :math:`\mathbf{B}`。

   * :doc:`sub_C01_gather_3Dxyz_push.f90 <C01_gather_3Dxyz/sub_C01_gather_3Dxyz_push>`:

       ``sub_C01_gather_3Dxyz_push`` 在一个 OpenMP 粒子循环中完成场插值、非相对论 Boris 速度更新和位置推进，适合性能敏感的 PIC 主循环。

   .. rubric:: 测试

   独立测试见 :doc:`/tests/007_gather/C01_gather_3Dxyz`，覆盖三线性精确性、光滑场收敛和
   ``B=0`` fused gather-push 基准。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">赵隐剑 (2025/11/04; 2026/03/23) · 哈尔滨工业大学</p>
        <p class="ap-home-contact">赵中平 (2025/11/04) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   * :doc:`mod_C01_gather_3Dxyz.f90 <C01_gather_3Dxyz/mod_C01_gather_3Dxyz>`:

       ``mod_C01_gather_3Dxyz`` is the C01 source-level Fortran module entry. It uses ``#include`` to collect and export the trilinear gather routine and the fused gather-push routine.

   * :doc:`sub_C01_gather_3Dxyz.f90 <C01_gather_3Dxyz/sub_C01_gather_3Dxyz>`:

       ``sub_C01_gather_3Dxyz`` trilinearly interpolates 3D Cartesian cell-centered electromagnetic fields for one particle and returns :math:`\mathbf{E}` and :math:`\mathbf{B}` at the particle position.

   * :doc:`sub_C01_gather_3Dxyz_push.f90 <C01_gather_3Dxyz/sub_C01_gather_3Dxyz_push>`:

       ``sub_C01_gather_3Dxyz_push`` fuses field interpolation, non-relativistic Boris velocity update, and position advance in one OpenMP particle loop for performance-oriented PIC workflows.

   .. rubric:: Tests

   See :doc:`/tests/007_gather/C01_gather_3Dxyz` for standalone checks of
   trilinear exactness, smooth-field convergence, and the ``B=0`` fused
   gather-push reference.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Yinjian ZHAO (2025/11/04; 2026/03/23) · Harbin Institute of Technology</p>
        <p class="ap-home-contact">Zhongping ZHAO (2025/11/04) · Harbin Institute of Technology</p>
      </div>

.. toctree::
   :maxdepth: 1
   :hidden:

   C01_gather_3Dxyz/mod_C01_gather_3Dxyz
   C01_gather_3Dxyz/sub_C01_gather_3Dxyz
   C01_gather_3Dxyz/sub_C01_gather_3Dxyz_push
