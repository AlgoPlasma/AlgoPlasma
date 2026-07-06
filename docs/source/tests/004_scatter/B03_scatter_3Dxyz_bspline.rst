B03_scatter_3Dxyz_bspline Test
==============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   ``tests/004_scatter/B03_scatter_3Dxyz_bspline`` 是
   :doc:`B03_scatter_3Dxyz_bspline </rst_files/B_Scatter/B03_scatter_3Dxyz_bspline>`
   的直接 scatter 回归测试。它测试的是完整粒子到网格沉积路径，而不只是
   B-spline 权重函数：

   - ``order=1`` 时，B03 是否退化为 B01 的 CIC/三线性 scatter。
   - 粒子数沉积是否保持总量 ``sum(den)=np*w``。
   - 粒子分量沉积是否保持总量 ``sum(den)=w*sum(par(d,:))``。
   - ``order>=1`` 时，沉积后的一阶矩是否等于粒子位置加权和。
   - ``den`` 是否保持累加语义，即分批沉积和一次性沉积结果一致。

   本测试不覆盖边界条件、周期折叠、MPI guard-cell 交换或多物种归一化系数。

   .. rubric:: 覆盖接口

   - ``sub_B03_scatter_3Dxyz_bspline``：被测顶层粒子数沉积接口。
   - ``sub_B03_scatter_3Dxyz_bspline_v``：被测顶层粒子分量沉积接口。
   - ``sub_B03_bspline_stencil_1d`` 和 ``fun_B03_bspline_shape``：通过顶层沉积间接覆盖。
   - ``sub_B01_scatter_3Dxyz`` 和 ``sub_B01_scatter_3Dxyz_v``：只在 ``order=1`` 子测试中作为参考。

   .. rubric:: 文件说明

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 文件
        - 作用
      * - ``source_f90/main.f90``
        - 构造确定性粒子，运行 B01 对比、总量守恒、一阶矩和累加语义测试。
      * - ``source_py/analyze.py``
        - 读取 Fortran 写出的比较行，统计误差、判断 PASS/FAIL，并生成参考图。
      * - ``make.sh``
        - 使用 ``gfortran -cpp -O2 -fdefault-real-8 -fopenmp`` 编译测试程序。
      * - ``run.sh``
        - 清理旧运行结果、编译、运行 Fortran 程序并执行 Python 后处理。
      * - ``clean.sh``
        - 删除测试目录中的编译产物、运行时结果和 Python 缓存。

   .. rubric:: 运行方式

   .. code-block:: bash

      cd tests/004_scatter/B03_scatter_3Dxyz_bspline
      bash run.sh

   .. rubric:: 测试设计

   Fortran 程序使用固定的 64 个粒子，粒子位置全部放在可访问网格范围内，避免边界处理影响
   B-spline 公式本身的判断。每个子测试写出一行或多行比较指标，包含参考值、实际值、绝对误差和阈值。
   Python 后处理逐行判断，只要任意一行超过阈值就返回失败。

   ``order=1`` 对 B01 的逐网格点比较用于检查低阶极限。总量守恒检查用于确认权重归一化。
   一阶矩检查用于确认 ``order>=1`` 的形函数在沉积意义下能保持粒子位置。分批累加检查用于确认
   ``den`` 是真正的累加目标，而不是在子程序内部被重新初始化。

   .. rubric:: 子测试说明

   .. list-table::
      :header-rows: 1
      :widths: 30 22 48

      * - 子测试
        - 阶数
        - 判断方式
      * - ``order1_b01_number``
        - ``order=1``
        - B03 粒子数沉积与 B01 CIC 沉积逐网格点比较。
      * - ``order1_b01_component``
        - ``order=1``
        - B03 ``_v`` 分量沉积与 B01 ``_v`` 逐网格点比较。
      * - ``number_conservation``
        - ``order=0..4``
        - 检查粒子数沉积满足 ``sum(den)=np*w``。
      * - ``component_conservation``
        - ``order=0..4``
        - 检查分量沉积满足 ``sum(den)=w*sum(par(d,:))``。
      * - ``number_first_moment``
        - ``order=1..4``
        - 检查 ``x,y,z`` 三个方向的一阶矩是否等于 ``w*sum(par(1:3,:))``。
      * - ``component_first_moment``
        - ``order=1..4``
        - 检查一阶矩是否等于 ``w*sum(par(d,:)*par(1:3,:))``。
      * - ``number_accumulation``
        - ``order=3``
        - 两批粒子沉积结果与一次性粒子数沉积逐网格点一致。
      * - ``component_accumulation``
        - ``order=3``
        - 两批粒子沉积结果与一次性分量沉积逐网格点一致。

   .. rubric:: 结果判断

   ``source_py/analyze.py`` 使用 Fortran 输出中的逐行阈值判断结果：

   .. list-table::
      :header-rows: 1
      :widths: 30 20 50

      * - 指标类型
        - 阈值
        - 说明
      * - B01 对比
        - ``1e-12``
        - ``order=1`` 应和 B01 数值一致，只允许浮点舍入差异。
      * - 总量守恒
        - ``1e-11``
        - 权重归一化后，总沉积量应保持。
      * - 一阶矩
        - ``1e-10``
        - ``order>=1`` 应保持一阶矩；阈值略宽以容纳三维乘加累积误差。
      * - 分批累加
        - ``1e-12``
        - 分批沉积和一次性沉积应逐点一致。

   参考运行结果：

   .. code-block:: text

      rows          : 38
      component_accumulation    : max_abs=3.469e-18, tol=1.0e-12, rows=1
      component_conservation    : max_abs=2.487e-14, tol=1.0e-11, rows=5
      component_first_moment    : max_abs=2.274e-13, tol=1.0e-10, rows=12
      number_accumulation       : max_abs=6.939e-18, tol=1.0e-12, rows=1
      number_conservation       : max_abs=1.776e-14, tol=1.0e-11, rows=5
      number_first_moment       : max_abs=3.126e-13, tol=1.0e-10, rows=12
      order1_b01_component      : max_abs=5.551e-17, tol=1.0e-12, rows=1
      order1_b01_number         : max_abs=0.000e+00, tol=1.0e-12, rows=1
      failures      : 0
      result        : PASS

   .. rubric:: 参考图

   .. figure:: ../../images/tests/004_scatter/B03_scatter_3Dxyz_bspline/b03_bspline_scatter_shape_curves.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``b03_bspline_scatter_shape_curves.png``：不同 ``order`` 的中心化
      B-spline 形函数曲线。横轴为粒子到网格点的距离 :math:`r`，纵轴为权重
      :math:`S_{order}(r)`。阶数越高，支撑范围越宽，曲线越平滑。

   .. figure:: ../../images/tests/004_scatter/B03_scatter_3Dxyz_bspline/b03_bspline_scatter_single_particle_footprint.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``b03_bspline_scatter_single_particle_footprint.png``：单个粒子的 xy
      沉积 footprint，图中已经对 z 方向权重求和。它展示了随着 ``order`` 增加，
      一个粒子的源项会分配到更多网格点上。

   .. figure:: ../../images/tests/004_scatter/B03_scatter_3Dxyz_bspline/b03_bspline_scatter_ref_vs_value.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``b03_bspline_scatter_ref_vs_value.png``：横轴为理论参考不变量，纵轴为
      从 ``den`` 计算得到的不变量。虚线为 ``value=reference``。总量守恒和一阶矩子测试
      都落在对角线附近，说明沉积结果满足对应不变量。

   .. figure:: ../../images/tests/004_scatter/B03_scatter_3Dxyz_bspline/b03_bspline_scatter_errors.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``b03_bspline_scatter_errors.png``：按子测试和阶数统计最大绝对误差。横轴为对数坐标。
      高阶误差略大来自递归求值、模板点增加和三维乘加次数增加后的双精度舍入累积；图中误差仍远低于阈值，
      不表示高阶 scatter 公式变差。

   .. rubric:: 常见误读

   - ``order=0`` 不检查一阶矩，因为零阶 top-hat 不具备线性一阶矩保持性质。
   - ``den`` 不在子程序内部清零是设计选择，方便多批粒子或多物种累加。
   - 本测试假定 stencil 位于可访问数组范围内，不检验 guard-cell 通信和边界处理。

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   ``tests/004_scatter/B03_scatter_3Dxyz_bspline`` is the direct scatter
   regression test for
   :doc:`B03_scatter_3Dxyz_bspline </rst_files/B_Scatter/B03_scatter_3Dxyz_bspline>`.
   It tests the full particle-to-grid deposition path, not only the B-spline
   weight function:

   - Whether ``order=1`` reduces to the B01 CIC/trilinear scatter.
   - Whether particle-number deposition preserves ``sum(den)=np*w``.
   - Whether component deposition preserves ``sum(den)=w*sum(par(d,:))``.
   - Whether ``order>=1`` preserves the first moment of the deposited source.
   - Whether ``den`` keeps accumulation semantics, so split deposition matches one full deposition.

   The test does not cover boundary conditions, periodic folding, MPI
   guard-cell exchange, or multi-species normalization factors.

   .. rubric:: Covered Interfaces

   - ``sub_B03_scatter_3Dxyz_bspline``: top-level particle-number deposition interface under test.
   - ``sub_B03_scatter_3Dxyz_bspline_v``: top-level particle-component deposition interface under test.
   - ``sub_B03_bspline_stencil_1d`` and ``fun_B03_bspline_shape``: covered indirectly through the top-level deposition routines.
   - ``sub_B01_scatter_3Dxyz`` and ``sub_B01_scatter_3Dxyz_v``: used only as references in the ``order=1`` subtests.

   .. rubric:: Files

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - File
        - Role
      * - ``source_f90/main.f90``
        - Builds deterministic particles and runs B01 comparison, total-conservation, first-moment, and accumulation tests.
      * - ``source_py/analyze.py``
        - Reads comparison rows written by Fortran, summarizes errors, determines PASS/FAIL, and generates reference figures.
      * - ``make.sh``
        - Compiles the test program with ``gfortran -cpp -O2 -fdefault-real-8 -fopenmp``.
      * - ``run.sh``
        - Cleans previous run products, builds, runs the Fortran program, and executes the Python postprocessor.
      * - ``clean.sh``
        - Removes build products, runtime results, and Python cache files from the test directory.

   .. rubric:: Run Command

   .. code-block:: bash

      cd tests/004_scatter/B03_scatter_3Dxyz_bspline
      bash run.sh

   .. rubric:: Test Design

   The Fortran program uses 64 deterministic particles whose positions all
   keep the stencil inside the accessible grid range. This isolates the
   B-spline formula from boundary handling. Each subtest writes one or more
   comparison rows containing a reference value, measured value, absolute
   error, and tolerance. The Python postprocessor checks every row and fails
   if any row exceeds its tolerance.

   The ``order=1`` B01 comparison checks the low-order limit. Total
   conservation checks weight normalization. The first-moment checks verify
   that ``order>=1`` preserves particle positions in the deposition sense. The
   split-accumulation checks confirm that ``den`` is a true accumulation
   target and is not reinitialized inside the subroutine.

   .. rubric:: Subtests

   .. list-table::
      :header-rows: 1
      :widths: 30 22 48

      * - Subtest
        - Orders
        - Check
      * - ``order1_b01_number``
        - ``order=1``
        - Compare B03 number deposition against B01 CIC deposition pointwise.
      * - ``order1_b01_component``
        - ``order=1``
        - Compare B03 ``_v`` component deposition against B01 ``_v`` pointwise.
      * - ``number_conservation``
        - ``order=0..4``
        - Check particle-number deposition with ``sum(den)=np*w``.
      * - ``component_conservation``
        - ``order=0..4``
        - Check component deposition with ``sum(den)=w*sum(par(d,:))``.
      * - ``number_first_moment``
        - ``order=1..4``
        - Check that the first moments in ``x,y,z`` equal ``w*sum(par(1:3,:))``.
      * - ``component_first_moment``
        - ``order=1..4``
        - Check that the first moments equal ``w*sum(par(d,:)*par(1:3,:))``.
      * - ``number_accumulation``
        - ``order=3``
        - Check that two split particle-number deposition calls match one full call pointwise.
      * - ``component_accumulation``
        - ``order=3``
        - Check that two split component-deposition calls match one full call pointwise.

   .. rubric:: Result Criteria

   ``source_py/analyze.py`` uses the per-row tolerances written by the Fortran
   program:

   .. list-table::
      :header-rows: 1
      :widths: 30 20 50

      * - Metric type
        - Tolerance
        - Meaning
      * - B01 comparison
        - ``1e-12``
        - ``order=1`` should match B01 numerically, allowing only round-off differences.
      * - Total conservation
        - ``1e-11``
        - After weight normalization, total deposited amount should be preserved.
      * - First moment
        - ``1e-10``
        - ``order>=1`` should preserve first moments; the tolerance allows accumulated 3D multiply-add round-off.
      * - Split accumulation
        - ``1e-12``
        - Split deposition and one full deposition should match pointwise.

   Reference run:

   .. code-block:: text

      rows          : 38
      component_accumulation    : max_abs=3.469e-18, tol=1.0e-12, rows=1
      component_conservation    : max_abs=2.487e-14, tol=1.0e-11, rows=5
      component_first_moment    : max_abs=2.274e-13, tol=1.0e-10, rows=12
      number_accumulation       : max_abs=6.939e-18, tol=1.0e-12, rows=1
      number_conservation       : max_abs=1.776e-14, tol=1.0e-11, rows=5
      number_first_moment       : max_abs=3.126e-13, tol=1.0e-10, rows=12
      order1_b01_component      : max_abs=5.551e-17, tol=1.0e-12, rows=1
      order1_b01_number         : max_abs=0.000e+00, tol=1.0e-12, rows=1
      failures      : 0
      result        : PASS

   .. rubric:: Reference Figures

   .. figure:: ../../images/tests/004_scatter/B03_scatter_3Dxyz_bspline/b03_bspline_scatter_shape_curves.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``b03_bspline_scatter_shape_curves.png``: centered B-spline shape
      functions for different ``order`` values. The x-axis is the
      particle-grid distance :math:`r`; the y-axis is the weight
      :math:`S_{order}(r)`. Higher order gives wider support and smoother
      curves.

   .. figure:: ../../images/tests/004_scatter/B03_scatter_3Dxyz_bspline/b03_bspline_scatter_single_particle_footprint.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``b03_bspline_scatter_single_particle_footprint.png``: xy deposition
      footprint of one particle after summing the z weights. It shows that a
      higher order distributes one particle source to more grid points.

   .. figure:: ../../images/tests/004_scatter/B03_scatter_3Dxyz_bspline/b03_bspline_scatter_ref_vs_value.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``b03_bspline_scatter_ref_vs_value.png``: theoretical invariant on the
      x-axis and the invariant computed from ``den`` on the y-axis. The dashed
      line is ``value=reference``. Conservation and first-moment subtests lie
      close to the diagonal, showing that the deposited grid field satisfies
      the corresponding invariants.

   .. figure:: ../../images/tests/004_scatter/B03_scatter_3Dxyz_bspline/b03_bspline_scatter_errors.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``b03_bspline_scatter_errors.png``: maximum absolute error grouped by
      subtest and order. The x-axis is logarithmic. Slightly larger
      high-order errors come from recursive evaluation, larger stencils, and
      more 3D multiply-add operations. The errors remain far below the
      tolerances, so this is not a degradation of the high-order scatter
      formula.

   .. rubric:: Common Misreadings

   - ``order=0`` does not run first-moment checks because the zero-order top-hat shape does not preserve linear moments.
   - ``den`` not being zeroed inside the subroutine is intentional; it supports multiple particle batches or species.
   - This test assumes the stencil lies inside the accessible array range; it does not test guard-cell communication or boundary handling.
