004_scatter Tests
=================

.. toctree::
   :maxdepth: 1
   :hidden:

   B01_scatter_3Dxyz
   B03_scatter_3Dxyz_bspline

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   本节整理 ``tests/004_scatter`` 中的 B_Scatter 测试，当前包含三组内容：
   ``B01_scatter_3Dxyz`` 下的 Cartesian scatter 综合测试、
   ``B02_deposit_3d_cyl`` 下的三维柱坐标电荷/电流沉积测试，以及
   ``B03_scatter_3Dxyz_bspline`` 下的任意阶 B-spline scatter 测试。

   .. list-table:: 当前测试页面
      :header-rows: 1
      :widths: 10 38 52

      * - ID
        - 测试页面
        - 说明
      * - B01
        - :doc:`B01_scatter_3Dxyz 测试 <B01_scatter_3Dxyz>`
        - 覆盖 ``sub_B01_scatter_3Dxyz`` （密度）、``_v`` （速度矩）、``_T`` （温度/方差）
          三个子程序，共 11 个算例，含 OMP 并行正确性与性能基准。
      * - B02
        - 暂无独立页面
        - ``B02_deposit_3d_cyl`` 的三维柱坐标电荷/电流沉积测试，详见下方说明。
      * - B03
        - :doc:`B03_scatter_3Dxyz_bspline 测试 <B03_scatter_3Dxyz_bspline>`
        - 覆盖任意阶 B-spline 粒子数沉积和 ``par(d,p)`` 分量沉积，包括 ``order=1`` 对 B01、
          总量守恒、一阶矩守恒和分批累加一致性。

   静态图片来自一次参考运行，并保存到 ``docs/source/images/tests/004_scatter``。
   如果修改了测试程序或绘图脚本，应重新运行并更新这些图片。

   .. rubric:: B02 cylindrical deposition 测试

   B02 测试位于 ``tests/004_scatter/B02_deposit_3d_cyl``。它们与 B01 顶层测试不重复：B01 验证
   Cartesian 三线性 scatter，B02 验证柱坐标 charge/current deposition。

   .. list-table::
      :header-rows: 1
      :widths: 18 34 30 18

      * - 子目录
        - 粒子采样/权重
        - 验证重点
        - 输出
      * - ``B02_deposit_3d_cyl/test1``
        - 柱坐标体积均匀采样，``r = Rmax * sqrt(U)``，粒子权重均匀。
        - 均匀物理密度下的 ``rho``、``Jr``、``Jphi``、``Jz`` 和连续性残差。
        - ``*.dat``、``*.png``
      * - ``B02_deposit_3d_cyl/test2``
        - ``r`` 均匀采样，粒子权重 ``wp = 2*r/Rmax*w0``。
        - 非均匀宏粒子权重仍表示均匀柱坐标体密度时的沉积一致性。
        - ``*.dat``、``*.png``

   B02 子测试可单独运行，例如：

   .. code-block:: bash

      cd tests/004_scatter/B02_deposit_3d_cyl/test1
      bash clean.sh
      bash make.sh
      bash run.sh 1000

      cd ../test2
      bash clean.sh
      bash make.sh
      bash run.sh 1000

   ``run.sh`` 的参数是粒子数；README 中的默认粒子数很大，做快速 smoke test 时建议显式给一个较小数值。

.. container:: ap-lang ap-lang-en

   This section documents the B_Scatter tests under ``tests/004_scatter``.
   It contains three groups: the ``B01_scatter_3Dxyz`` Cartesian scatter test
   suite, the ``B02_deposit_3d_cyl`` cylindrical charge/current deposition
   tests, and the ``B03_scatter_3Dxyz_bspline`` arbitrary-order B-spline
   scatter tests.

   .. list-table:: Available test pages
      :header-rows: 1
      :widths: 10 38 52

      * - ID
        - Test page
        - Notes
      * - B01
        - :doc:`B01_scatter_3Dxyz tests <B01_scatter_3Dxyz>`
        - Covers ``sub_B01_scatter_3Dxyz`` (density), ``_v`` (velocity moment),
          and ``_T`` (temperature/variance) — 11 cases including OMP correctness
          and performance benchmarks.
      * - B02
        - No dedicated page yet
        - 3D cylindrical charge/current deposition tests in ``B02_deposit_3d_cyl``;
          see the section below for run instructions.
      * - B03
        - :doc:`B03_scatter_3Dxyz_bspline tests <B03_scatter_3Dxyz_bspline>`
        - Covers arbitrary-order B-spline particle-number and ``par(d,p)`` component deposition, including ``order=1`` against B01, conservation, first moments, and split-call accumulation.

   The static figures are copied from one reference run and stored under
   ``docs/source/images/tests/004_scatter``. Regenerate and update them if the
   test program or plotting script changes.

   .. rubric:: B02 Cylindrical Deposition Tests

   The B02 tests live in ``tests/004_scatter/B02_deposit_3d_cyl``. They are not
   duplicates of the B01 top-level test: B01 checks Cartesian trilinear scatter,
   while B02 checks cylindrical charge/current deposition.

   .. list-table::
      :header-rows: 1
      :widths: 18 34 30 18

      * - Subdirectory
        - Particle sampling/weights
        - Check
        - Outputs
      * - ``B02_deposit_3d_cyl/test1``
        - Uniform cylindrical-volume sampling, ``r = Rmax * sqrt(U)``, with uniform particle weights.
        - ``rho``, ``Jr``, ``Jphi``, ``Jz``, and continuity residuals for uniform physical density.
        - ``*.dat``, ``*.png``
      * - ``B02_deposit_3d_cyl/test2``
        - Uniform ``r`` sampling with particle weight ``wp = 2*r/Rmax*w0``.
        - Deposition consistency when nonuniform macro-particle weights still represent uniform cylindrical volume density.
        - ``*.dat``, ``*.png``

   Run the B02 subtests separately, for example:

   .. code-block:: bash

      cd tests/004_scatter/B02_deposit_3d_cyl/test1
      bash clean.sh
      bash make.sh
      bash run.sh 1000

      cd ../test2
      bash clean.sh
      bash make.sh
      bash run.sh 1000

   The ``run.sh`` argument is the particle count. The README defaults are very
   large, so pass a smaller number explicitly for quick smoke tests.
