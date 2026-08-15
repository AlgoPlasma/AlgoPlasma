C02_gather_3Dxyz_bspline Test
==============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   ``tests/007_gather/C02_gather_3Dxyz_bspline`` 是
   :doc:`C02_gather_3Dxyz_bspline </rst_files/C_Gather/C02_gather_3Dxyz_bspline>`
   的直接 gather 回归测试。它测试的是完整电磁场插值路径，而不只是权重生成：

   - 顶层接口 ``sub_C02_gather_3Dxyz_bspline`` 是否能正确读取 ``par`` 和六个场数组。
   - ``order=1`` 时是否退化为 C01 的三线性 gather。
   - B-spline 权重对常数场是否保持常数。
   - ``order>=1`` 时，对线性场是否给出解析粒子位置处的值。

   本测试不覆盖 guard-cell 交换、边界条件、粒子推进或沉积。

   .. rubric:: 覆盖接口

   - ``sub_C02_gather_3Dxyz_bspline``：被测顶层子程序。
   - ``sub_C02_bspline_stencil_1d``、``fun_C02_bspline_shape``、
     ``fun_C02_gather_scalar_bspline``：通过顶层 gather 间接覆盖。
   - ``sub_C01_gather_3Dxyz``：只在 ``order1_c01`` 子测试中作为对照参考。

   .. rubric:: 文件说明

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 文件
        - 作用
      * - ``source_f90/main.f90``
        - 构造确定性粒子和场数组，运行三个逐分量比较子测试。
      * - ``source_py/analyze.py``
        - 读取运行时比较结果，按子测试阈值统计最大误差和 PASS/FAIL。
      * - ``make.sh``
        - 使用 ``gfortran -cpp -O2 -fdefault-real-8 -fopenmp`` 编译测试程序。
      * - ``run.sh``
        - 清理旧运行结果、编译、运行 Fortran 程序并执行 Python 分析。
      * - ``clean.sh``
        - 删除编译产物、运行时临时结果和 Python 缓存。

   .. rubric:: 运行方式

   .. code-block:: bash

      cd tests/007_gather/C02_gather_3Dxyz_bspline
      bash run.sh

   .. rubric:: 主流程

   1. Fortran 程序构造确定性粒子和场数组。
   2. ``order1_c01`` 子测试用非线性场填充六个分量，同时调用 C01 和 C02
      ``order=1``，逐分量比较。
   3. ``constant`` 子测试对 ``order=0..4`` 使用常数场，检查 gather 后仍为同一常数。
   4. ``linear`` 子测试对 ``order=1..4`` 使用线性场，检查 gather 值等于解析的
      ``F(x,y,z)``。
   5. Python 脚本读取运行时比较结果，按子测试阈值判定 PASS/FAIL。

   .. rubric:: 子测试说明

   .. list-table::
      :header-rows: 1
      :widths: 22 28 50

      * - 子测试
        - 阶数
        - 判断方式
      * - ``order1_c01``
        - ``order=1``
        - C02 的 ``E,B`` 与 C01 的三线性 gather 结果逐分量比较。
      * - ``constant``
        - ``order=0,1,2,3,4``
        - 六个场分量全部填为常数；gather 后应保持这些常数。
      * - ``linear``
        - ``order=1,2,3,4``
        - 六个场分量填为三维线性函数；gather 后应等于粒子坐标处的解析值。

   .. rubric:: 结果判断

   ``source_py/analyze.py`` 使用固定阈值判断结果：

   .. list-table::
      :header-rows: 1
      :widths: 24 24 52

      * - 子测试
        - 阈值
        - 说明
      * - ``order1_c01``
        - ``1e-11``
        - 允许不同计算顺序带来的双精度舍入误差。
      * - ``constant``
        - ``1e-12``
        - 常数保持应接近机器精度。
      * - ``linear``
        - ``1e-11``
        - ``order>=1`` 的 B-spline 应满足一阶矩，从而精确插值线性场。

   参考运行结果：

   .. code-block:: text

      rows          : 1842
      constant      : max_abs=5.551e-16, tol=1.0e-12, rows=810
      linear        : max_abs=2.220e-15, tol=1.0e-11, rows=648
      order1_c01    : max_abs=1.332e-15, tol=1.0e-11, rows=384
      failures      : 0
      result        : PASS

   .. rubric:: 参考图

   .. figure:: ../../images/tests/007_gather/C02_gather_3Dxyz_bspline/c02_bspline_gather_shape_curves.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``c02_bspline_gather_shape_curves.png``：不同 ``order`` 的中心化
      B-spline 形函数曲线。横轴为粒子到网格点的距离 :math:`r`，纵轴为权重
      :math:`S_{order}(r)`。这张图展示的是 gather 使用的局部权重形状，
      便于直接查看不同阶数的支撑范围和平滑程度。

   .. figure:: ../../images/tests/007_gather/C02_gather_3Dxyz_bspline/c02_bspline_gather_ref_vs_value.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``c02_bspline_gather_ref_vs_value.png``：横轴为参考值，纵轴为
      ``sub_C02_gather_3Dxyz_bspline`` 的 gather 输出。虚线为
      ``value=reference``。三类子测试都落在对角线附近，说明 direct gather
      路径在这些基准场上与参考值一致。

   .. figure:: ../../images/tests/007_gather/C02_gather_3Dxyz_bspline/c02_bspline_gather_errors.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``c02_bspline_gather_errors.png``：按子测试和 B-spline 阶数统计最大绝对误差。
      纵轴为对数坐标。``constant`` 覆盖 ``order=0..4``，``linear`` 覆盖
      ``order=1..4``，``order1_c01`` 检查 ``order=1`` 与 C01 的一致性。
      高阶误差略大来自浮点舍入累积：阶数越高，模板点、递归求值和乘加次数越多。
      图中误差仍在机器精度附近，远低于阈值，不表示高阶 gather 变差。

   .. rubric:: 常见误读

   - ``order1_c01`` 不要求逐 bit 完全相等；它比较的是数值误差。
   - ``constant`` 和 ``linear`` 是形函数一致性测试，不代表高阶非线性场的收敛阶测试。
   - 本测试假定粒子位置和模板位于可访问数组范围内；它不测试 guard-cell 通信。

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   ``tests/007_gather/C02_gather_3Dxyz_bspline`` is the direct-gather
   regression test for
   :doc:`C02_gather_3Dxyz_bspline </rst_files/C_Gather/C02_gather_3Dxyz_bspline>`.
   It tests the complete electromagnetic-field interpolation path, not only
   weight generation:

   - Whether the top-level ``sub_C02_gather_3Dxyz_bspline`` interface reads ``par`` and the six field arrays correctly.
   - Whether ``order=1`` reduces to the C01 trilinear gather.
   - Whether B-spline weights preserve constant fields.
   - Whether ``order>=1`` reproduces linear fields at the analytic particle position.

   The test does not cover guard-cell exchange, boundary conditions, particle
   pushing, or deposition.

   .. rubric:: Covered Interfaces

   - ``sub_C02_gather_3Dxyz_bspline``: the top-level routine under test.
   - ``sub_C02_bspline_stencil_1d``, ``fun_C02_bspline_shape``, and
     ``fun_C02_gather_scalar_bspline``: covered indirectly through the top-level gather.
   - ``sub_C01_gather_3Dxyz``: used only as a reference in the ``order1_c01`` subtest.

   .. rubric:: Files

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - File
        - Role
      * - ``source_f90/main.f90``
        - Builds deterministic particles and field arrays and runs three componentwise comparison subtests.
      * - ``source_py/analyze.py``
        - Reads runtime comparison results, computes maximum errors with case-specific tolerances, and reports PASS/FAIL.
      * - ``make.sh``
        - Compiles the test program with ``gfortran -cpp -O2 -fdefault-real-8 -fopenmp``.
      * - ``run.sh``
        - Cleans previous run products, builds, runs the Fortran program, and executes the Python analysis.
      * - ``clean.sh``
        - Removes build products, runtime temporary results, and Python cache files.

   .. rubric:: Run Command

   .. code-block:: bash

      cd tests/007_gather/C02_gather_3Dxyz_bspline
      bash run.sh

   .. rubric:: Main Flow

   1. The Fortran program builds deterministic particles and field arrays.
   2. The ``order1_c01`` subtest fills all six components with a nonlinear field, calls both C01 and C02 with ``order=1``, and compares every component.
   3. The ``constant`` subtest uses constant fields for ``order=0..4`` and checks that gathered values remain constant.
   4. The ``linear`` subtest uses 3D linear fields for ``order=1..4`` and checks gathered values against analytic ``F(x,y,z)``.
   5. The Python script reads runtime comparison results and applies case-specific tolerances.

   .. rubric:: Subtests

   .. list-table::
      :header-rows: 1
      :widths: 22 28 50

      * - Subtest
        - Orders
        - Check
      * - ``order1_c01``
        - ``order=1``
        - Compare C02 ``E,B`` componentwise against C01 trilinear gather.
      * - ``constant``
        - ``order=0,1,2,3,4``
        - Fill all six components with constants; gathered values should preserve those constants.
      * - ``linear``
        - ``order=1,2,3,4``
        - Fill all six components with 3D linear functions; gathered values should match analytic values at the particle coordinate.

   .. rubric:: Result Criteria

   ``source_py/analyze.py`` uses fixed tolerances:

   .. list-table::
      :header-rows: 1
      :widths: 24 24 52

      * - Subtest
        - Tolerance
        - Meaning
      * - ``order1_c01``
        - ``1e-11``
        - Allows double-precision round-off from different evaluation order.
      * - ``constant``
        - ``1e-12``
        - Constant preservation should be near machine precision.
      * - ``linear``
        - ``1e-11``
        - ``order>=1`` B-spline weights satisfy the first moment and should reproduce linear fields.

   Reference run:

   .. code-block:: text

      rows          : 1842
      constant      : max_abs=5.551e-16, tol=1.0e-12, rows=810
      linear        : max_abs=2.220e-15, tol=1.0e-11, rows=648
      order1_c01    : max_abs=1.332e-15, tol=1.0e-11, rows=384
      failures      : 0
      result        : PASS

   .. rubric:: Reference Figures

   .. figure:: ../../images/tests/007_gather/C02_gather_3Dxyz_bspline/c02_bspline_gather_shape_curves.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``c02_bspline_gather_shape_curves.png``: centered B-spline shape
      functions for different ``order`` values. The x-axis is the
      particle-grid distance :math:`r`; the y-axis is the weight
      :math:`S_{order}(r)`. This figure shows the local weight shapes used by
      gather, making the support width and smoothness of each order visible.

   .. figure:: ../../images/tests/007_gather/C02_gather_3Dxyz_bspline/c02_bspline_gather_ref_vs_value.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``c02_bspline_gather_ref_vs_value.png``: reference values on the x-axis
      and gathered values from ``sub_C02_gather_3Dxyz_bspline`` on the y-axis.
      The dashed line is ``value=reference``. All three subtests lie close to
      the diagonal, showing that the direct gather path agrees with the
      references for these benchmark fields.

   .. figure:: ../../images/tests/007_gather/C02_gather_3Dxyz_bspline/c02_bspline_gather_errors.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``c02_bspline_gather_errors.png``: maximum absolute error grouped by
      subtest and B-spline order. The y-axis is logarithmic. ``constant``
      covers ``order=0..4``, ``linear`` covers ``order=1..4``, and
      ``order1_c01`` checks agreement with C01 for ``order=1``. The slightly
      larger high-order errors come from accumulated floating-point round-off:
      higher orders use more stencil points, recursive evaluations, and
      multiply-add operations. The errors remain near machine precision and
      far below the tolerances, so this is not a loss of high-order accuracy.

   .. rubric:: Common Misreadings

   - ``order1_c01`` does not require bitwise equality; it checks numerical error.
   - ``constant`` and ``linear`` are shape-function consistency checks, not convergence-order tests for nonlinear fields.
   - This test assumes particle positions and stencils are inside the accessible array range; it does not test guard-cell communication.
