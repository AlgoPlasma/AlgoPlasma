D02_hypre_3Dxyz_bc Tests
========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   本页对应 ``tests/001_poisson/test01`` 和 ``test02``。两者共同描述 D02 在 Cartesian
   ``(x,y,z)`` 网格上的当前测试边界：``test01`` 偏重多 rank 代码路径，``test02`` 偏重解析边界回归。

   .. rubric:: 测试定位

   D02 当前测试分成两层：

   - ``test01``: 检查多 rank、矩阵组装、dielectric 修改、outflow 修改和求解入口是否贯通。
   - ``test02``: 用四个可解析边界算例确认边界离散和求解结果是否符合预期。

   .. rubric:: 这个测试在做什么

   D02 求解的是 Cartesian cell-centered 网格上的 Poisson 方程。边界条件不是
   HYPRE 求解器在运行时自动理解的选项，而是在进入 HYPRE 前由
   ``sub_D02_hypre_3Dxyz_bc_A`` 及其边界修正例程折算进矩阵 ``A_values`` 和右端项
   ``rho1d``。因此，本页测试关心的核心问题是：给定 Dirichlet、Neumann、
   dielectric 和 outflow 等边界标记后，组装出来的线性系统是否仍能给出正确的
   电势解。

   ``test01`` 是连通性测试。它故意把 4 个 MPI rank 放在不同子域上，让不同外边界走
   不同分支：有的面走 dielectric，有的面走 Dirichlet 或 Neumann，有的面走 outflow，
   同时 ``y`` 方向设置为周期。这个测试没有解析解对照，主要用于确认多 rank 组装、
   边界修正和 HYPRE Fortran 求解入口能够一起工作，输出不发散、不出现 ``NaN``。

   ``test02`` 是可验证的回归测试。它构造解析解已经知道的简单场：
   三个线性势函数和一个常量势函数。因为线性函数满足二阶 Laplacian 为零，且常量场也是
   Poisson 方程的平凡解，所以只要边界离散是对的，数值解就应该和解析解重合。
   这也是本页误差表和三联图的主要依据。

   .. rubric:: 边界设置如何阅读

   代码中的边界数组顺序为 ``xmin, xmax, ymin, ymax, zmin, zmax``。边界码含义为：
   ``0`` 表示内部/MPI 邻接面，``1`` 表示 Dirichlet，``2`` 表示 Neumann，
   ``3`` 表示 dielectric，``4`` 表示 outflow。对 ``test02``，MPI 子域之间的面会被
   ``build_local_bc`` 自动保持为 ``0``；只有全局计算域外边界才使用对应的物理边界码。

   ``test02`` 的四个解析算例如下：

   - case 1 使用 :math:`\phi=\phi_0+g_x x`。``x`` 两端给 Dirichlet 值，
     ``y`` 两端给 Neumann 法向导数，``z`` 两端走 dielectric 路径但表面电荷设为 0。
   - case 2 使用 :math:`\phi=\phi_0+g_y y`。``y`` 两端是 Dirichlet，
     ``z`` 两端是 Neumann，``x`` 两端是零表面电荷 dielectric。
   - case 3 使用 :math:`\phi=\phi_0+g_z z`。``z`` 两端是 Dirichlet，
     ``x`` 两端是 Neumann，``y`` 两端是零表面电荷 dielectric。
   - case 4 使用常量势 :math:`\phi=\phi_\infty`，所有外边界都是 outflow。

   前三个 case 中的 dielectric 面并不是为了模拟非零表面电荷，而是为了确认
   dielectric 代码路径在零表面电荷时不会破坏解析线性解。case 4 则专门检查 outflow
   离散路径：常量场应该保持为 ``phi_infty``。

   .. rubric:: 参数设置

   .. list-table::
      :header-rows: 1
      :widths: 20 28 52

      * - 测试
        - 网格与 MPI
        - 主要物理/数值参数
      * - ``test01``
        - ``32 x 8 x 32``，固定 4 rank。
        - ``rho=0``，``period=(0,8,0)``，``tolerance=1e-6``。外边界混合使用 dielectric、Dirichlet、Neumann 和 outflow；rank 0 的 ``zmin`` 面设 ``phibc=0.5``，dielectric 表面修正使用 ``sx1=0.05``、``sx2=-0.05``。
      * - ``test02`` case 1
        - ``160 x 160 x 160``，当前参考运行 8 rank。
        - ``phi0=0.5``、``gx=0.2``，解析解 ``phi=phi0+gx*x``。``x`` 两端 Dirichlet，``y`` 两端 Neumann，``z`` 两端 zero-surface-charge dielectric。
      * - ``test02`` case 2
        - ``160 x 160 x 160``，当前参考运行 8 rank。
        - ``phi0=0.5``、``gy=-0.15``，解析解 ``phi=phi0+gy*y``。``x`` 两端 zero-surface-charge dielectric，``y`` 两端 Dirichlet，``z`` 两端 Neumann。
      * - ``test02`` case 3
        - ``160 x 160 x 160``，当前参考运行 8 rank。
        - ``phi0=0.5``、``gz=0.1``，解析解 ``phi=phi0+gz*z``。``x`` 两端 Neumann，``y`` 两端 zero-surface-charge dielectric，``z`` 两端 Dirichlet。
      * - ``test02`` case 4
        - ``160 x 160 x 160``，当前参考运行 8 rank。
        - ``phi_infty=0.75``，所有全局外边界为 outflow，解析解为常量场 ``phi=0.75``。

   ``test02`` 的求解容差为 ``1e-10``，右端源项均按解析解设置；前三个线性 case 的
   Laplacian 为零，因此主要考察边界离散是否把线性场保持住。

   .. rubric:: 运行方式

   运行前建议确认：

   .. code-block:: bash

      which mpif90
      which mpicc
      which mpirun
      python3 -c "import numpy, matplotlib"

   编译前先检查并修改两个目录中的 ``HYPRE_INC`` 和 ``HYPRE_LIB``，确保它们指向本机 HYPRE 安装路径。随后两个目录都通过 ``make.sh`` 编译，再分别由 ``run.sh`` 启动：

   .. code-block:: bash

      cd tests/001_poisson/test01
      bash clean.sh
      bash make.sh
      bash run.sh
      python3 plot.py

      cd ../test02
      bash clean.sh
      bash make.sh
      bash run.sh
      python3 plot.py

   .. rubric:: 覆盖内容

   .. list-table::
      :header-rows: 1
      :widths: 18 32 50

      * - 测试
        - 被测接口
        - 检查内容
      * - ``test01``
        - ``sub_D02_hypre_3Dxyz_bc_A``、``sub_D02_hypre_3Dxyz_bc_A_dielectric``、``sub_D02_hypre_3Dxyz_bc_A_outflow``、``sub_D02_hypre_3Dxyz_bc_fortran``
        - 检查 4-rank 下的 Cartesian 组装、dielectric 修改、outflow 修改和求解入口是否全部连通。
      * - ``test02`` case 1
        - 同上
        - ``linear-x`` 解，验证 Dirichlet-x、Neumann-y、dielectric-z 组合边界。
      * - ``test02`` case 2
        - 同上
        - ``linear-y`` 解，验证 dielectric-x、Dirichlet-y、Neumann-z 组合边界。
      * - ``test02`` case 3
        - 同上
        - ``linear-z`` 解，验证 Neumann-x、dielectric-y、Dirichlet-z 组合边界。
      * - ``test02`` case 4
        - 同上
        - 常量场配合 outflow 条件，直接检查离散 outflow 路径。

   .. rubric:: 输出文件

   .. list-table::
      :header-rows: 1
      :widths: 22 26 52

      * - 测试
        - 主要输出
        - 说明
      * - ``test01``
        - ``phi.dat``、``phi_zx.png``
        - 4-rank smoke test 的全局势函数和中间 ``y`` 截面的 ``log10(phi)`` 图。该图用于快速检查场是否稳定，不是误差验证图。
      * - ``test02``
        - ``case*_compare.dat``、``case*_limited_colorbar.png``
        - 四组解析边界算例的逐点比较数据和三联图。三联图与 ``test00/test01`` 共享相同的 ``8 x 6 inch`` 画布、``300 dpi`` 输出和统一标题风格，便于和单图结果一起人工比对。

   .. rubric:: 图片如何阅读

   ``test01`` 的 ``phi_zx.png`` 只画中间 ``y`` 截面上的 ``log10(phi)``。它的用途是
   smoke test：如果多 rank 拼接、边界修正或求解失败，图中通常会出现明显断裂、异常值或
   ``NaN``。由于绘图脚本取了对数，``phi=0`` 附近可能对应 ``-inf`` 或空白色块；这不应被
   解读为解析误差，而只是这个 smoke-test 图的显示方式。

   ``test02`` 的每张三联图才是严格回归图。左图是解析解 ``phi_exact``，中图是 HYPRE
   求出的 ``phi_num``，右图是逐点绝对误差 ``abs_error``。左图和中图使用完全相同的色标，
   因此可以直接视觉比较；右图单独显示误差大小。若边界离散正确，左图和中图应几乎一致，
   右图应接近零。

   .. rubric:: 参考结果

   ``test01`` 当前参考运行在 ``32 x 8 x 32`` 网格和 4 个 MPI rank 上输出 ``8192`` 个有限势函数值，
   ``min(phi)=0``、``max(phi)=9.090e-1``，未出现 ``NaN``。

   ``test02`` 当前参考运行使用 ``160 x 160 x 160`` 网格和 8 个 MPI rank，四个算例的误差为：

   .. list-table::
      :header-rows: 1
      :widths: 16 42 42

      * - 算例
        - ``L_inf``
        - relative ``L2``
      * - case 1
        - ``2.4759546235486596E-007``
        - ``1.0219664115341861E-008``
      * - case 2
        - ``2.1403233141370492E-007``
        - ``1.2380101545974710E-008``
      * - case 3
        - ``6.6417982225175365E-012``
        - ``4.5378321214316385E-013``
      * - case 4
        - ``8.4721119009145696E-012``
        - ``5.9755050191842755E-012``

   其中 case 3 和 case 4 已回到接近 machine precision 的量级，可作为当前 D02 回归基线。

   .. rubric:: 代表图

   .. figure:: ../../images/tests/001_poisson/test01/phi_zx.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-medium

      ``test01`` 的中间 ``y`` 截面 ``log10(phi)``，用于确认多 rank smoke test 输出稳定。

   .. figure:: ../../images/tests/001_poisson/test02/case1_linear_x_compare_limited_colorbar.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``test02`` 的 ``case1`` 三联图。数值解与解析解在 ``1e-7`` 量级内重合，误差图接近零。

.. container:: ap-lang ap-lang-en

   This page corresponds to ``tests/001_poisson/test01`` and ``test02``.
   Together they define the current D02 Cartesian test boundary: ``test01`` is
   the multi-rank path check, while ``test02`` is the exact-boundary regression
   set.

   .. rubric:: Test Role

   The current D02 coverage is split into two layers:

   - ``test01``: checks multi-rank assembly plus dielectric/outflow edits and the solve entry.
   - ``test02``: uses four exact boundary cases as the numerical regression baseline.

   .. rubric:: What This Test Is Doing

   D02 solves the Poisson equation on a Cartesian cell-centered grid. Boundary
   conditions are not runtime options interpreted by HYPRE itself. Before the
   HYPRE solve, ``sub_D02_hypre_3Dxyz_bc_A`` and its boundary-correction
   routines fold boundary effects into the matrix ``A_values`` and the right
   hand side ``rho1d``. The key question tested here is therefore: after
   Dirichlet, Neumann, dielectric, and outflow boundary flags are converted into
   the linear system, does the solver still recover the expected potential?

   ``test01`` is a connectivity smoke test. It places four MPI ranks on
   different subdomains so that different outer faces exercise different
   branches: dielectric, Dirichlet, Neumann, and outflow, while the ``y``
   direction is periodic. This test has no analytic reference field; it checks
   that multi-rank assembly, boundary edits, and the HYPRE Fortran solve entry
   work together without divergence or ``NaN`` values.

   ``test02`` is the quantitative regression test. It constructs simple fields
   with known exact solutions: three linear potentials and one constant
   potential. Linear functions have zero second Laplacian on the uniform grid,
   and the constant field is a trivial Poisson solution. If the boundary
   discretization is correct, the numerical solution should match the analytic
   field. The error table and three-panel figures on this page come from this
   exact-solution comparison.

   .. rubric:: How To Read The Boundary Setup

   The boundary array order is ``xmin, xmax, ymin, ymax, zmin, zmax``. Boundary
   code ``0`` means an internal/MPI-neighbor face, ``1`` is Dirichlet, ``2`` is
   Neumann, ``3`` is dielectric, and ``4`` is outflow. In ``test02``,
   ``build_local_bc`` keeps MPI subdomain interfaces as ``0``; only global
   outer faces receive the physical boundary code.

   The four analytic cases in ``test02`` are:

   - case 1 uses :math:`\phi=\phi_0+g_x x`: Dirichlet on ``x``, Neumann on
     ``y``, and dielectric on ``z`` with zero surface charge.
   - case 2 uses :math:`\phi=\phi_0+g_y y`: dielectric on ``x`` with zero
     surface charge, Dirichlet on ``y``, and Neumann on ``z``.
   - case 3 uses :math:`\phi=\phi_0+g_z z`: Neumann on ``x``, dielectric on
     ``y`` with zero surface charge, and Dirichlet on ``z``.
   - case 4 uses the constant field :math:`\phi=\phi_\infty` with outflow on
     all outer faces.

   The dielectric faces in the first three cases are not meant to model a
   nonzero surface charge. They deliberately use zero surface charge to verify
   that the dielectric code path does not disturb the analytic linear solution.
   Case 4 isolates the outflow path: the constant field should remain equal to
   ``phi_infty``.

   .. rubric:: Parameters

   .. list-table::
      :header-rows: 1
      :widths: 20 28 52

      * - Test
        - Grid and MPI
        - Main physical/numerical parameters
      * - ``test01``
        - ``32 x 8 x 32``, fixed at 4 ranks.
        - ``rho=0``, ``period=(0,8,0)``, ``tolerance=1e-6``. The outer faces mix dielectric, Dirichlet, Neumann, and outflow branches; the rank-0 ``zmin`` face uses ``phibc=0.5``, and the dielectric edit uses ``sx1=0.05`` and ``sx2=-0.05``.
      * - ``test02`` case 1
        - ``160 x 160 x 160``, 8 ranks in the current reference run.
        - ``phi0=0.5``, ``gx=0.2``, exact solution ``phi=phi0+gx*x``. Dirichlet on ``x``, Neumann on ``y``, and zero-surface-charge dielectric on ``z``.
      * - ``test02`` case 2
        - ``160 x 160 x 160``, 8 ranks in the current reference run.
        - ``phi0=0.5``, ``gy=-0.15``, exact solution ``phi=phi0+gy*y``. Zero-surface-charge dielectric on ``x``, Dirichlet on ``y``, and Neumann on ``z``.
      * - ``test02`` case 3
        - ``160 x 160 x 160``, 8 ranks in the current reference run.
        - ``phi0=0.5``, ``gz=0.1``, exact solution ``phi=phi0+gz*z``. Neumann on ``x``, zero-surface-charge dielectric on ``y``, and Dirichlet on ``z``.
      * - ``test02`` case 4
        - ``160 x 160 x 160``, 8 ranks in the current reference run.
        - ``phi_infty=0.75``; every global outer face is outflow and the exact solution is the constant field ``phi=0.75``.

   ``test02`` uses solver tolerance ``1e-10``. The first three linear cases
   have zero Laplacian, so they mainly check whether the boundary
   discretization preserves a linear field.

   .. rubric:: How To Run

   Before running them, check:

   .. code-block:: bash

      which mpif90
      which mpicc
      which mpirun
      python3 -c "import numpy, matplotlib"

   Before building, update ``HYPRE_INC`` and ``HYPRE_LIB`` in both test
   directories so they match the local HYPRE installation. Then use
   ``make.sh`` to build and ``run.sh`` to launch:

   .. code-block:: bash

      cd tests/001_poisson/test01
      bash clean.sh
      bash make.sh
      bash run.sh
      python3 plot.py

      cd ../test02
      bash clean.sh
      bash make.sh
      bash run.sh
      python3 plot.py

   .. rubric:: Coverage

   .. list-table::
      :header-rows: 1
      :widths: 18 32 50

      * - Test
        - Interfaces
        - What is checked
      * - ``test01``
        - ``sub_D02_hypre_3Dxyz_bc_A``, ``sub_D02_hypre_3Dxyz_bc_A_dielectric``, ``sub_D02_hypre_3Dxyz_bc_A_outflow``, ``sub_D02_hypre_3Dxyz_bc_fortran``
        - Checks that 4-rank Cartesian assembly, dielectric edits, outflow edits, and the solve entry all connect correctly.
      * - ``test02`` case 1
        - same D02 interfaces
        - ``linear-x`` case with Dirichlet-x, Neumann-y, and dielectric-z boundaries.
      * - ``test02`` case 2
        - same D02 interfaces
        - ``linear-y`` case with dielectric-x, Dirichlet-y, and Neumann-z boundaries.
      * - ``test02`` case 3
        - same D02 interfaces
        - ``linear-z`` case with Neumann-x, dielectric-y, and Dirichlet-z boundaries.
      * - ``test02`` case 4
        - same D02 interfaces
        - constant-field outflow case used to check the discrete outflow path directly.

   .. rubric:: Output Files

   .. list-table::
      :header-rows: 1
      :widths: 22 26 52

      * - Test
        - Main outputs
        - Notes
      * - ``test01``
        - ``phi.dat``, ``phi_zx.png``
        - Global field and a middle-``y`` ``log10(phi)`` slice from the 4-rank smoke test. This figure is a quick stability check, not an error plot.
      * - ``test02``
        - ``case*_compare.dat``, ``case*_limited_colorbar.png``
        - Pointwise comparison data and three-panel figures for the four exact-boundary cases. The three-panel figures use the same ``8 x 6 inch`` canvas, ``300 dpi`` output, and title style as ``test00`` and ``test01``.

   .. rubric:: How To Read The Figures

   ``test01`` ``phi_zx.png`` shows ``log10(phi)`` on a middle-``y`` slice. Its
   purpose is smoke testing: if multi-rank stitching, boundary correction, or
   the solve fails, the plot will usually show obvious discontinuities,
   abnormal values, or ``NaN`` regions. Because the script plots a logarithm,
   cells with ``phi=0`` may appear as ``-inf`` or blank regions; this is a
   display artifact of the smoke-test plot, not an analytic error measure.

   The ``test02`` three-panel figures are the strict regression figures. The
   left panel is ``phi_exact``, the middle panel is the HYPRE result
   ``phi_num``, and the right panel is the pointwise absolute error
   ``abs_error``. The exact and numerical panels use the same color scale, so
   they can be compared directly. With correct boundary discretization, the
   first two panels should be visually identical and the error panel should
   stay near zero.

   .. rubric:: Reference Result

   The current ``test01`` reference run on a ``32 x 8 x 32`` grid over 4 MPI
   ranks writes ``8192`` finite values with ``min(phi)=0`` and
   ``max(phi)=9.090e-1`` and no ``NaN`` entries.

   The current ``test02`` reference run uses a ``160 x 160 x 160`` grid on 8
   MPI ranks. The four cases give:

   .. list-table::
      :header-rows: 1
      :widths: 16 42 42

      * - Case
        - ``L_inf``
        - relative ``L2``
      * - case 1
        - ``2.4759546235486596E-007``
        - ``1.0219664115341861E-008``
      * - case 2
        - ``2.1403233141370492E-007``
        - ``1.2380101545974710E-008``
      * - case 3
        - ``6.6417982225175365E-012``
        - ``4.5378321214316385E-013``
      * - case 4
        - ``8.4721119009145696E-012``
        - ``5.9755050191842755E-012``

   Cases 3 and 4 are back at near-machine-precision scale and serve as the
   current D02 regression baseline.

   .. rubric:: Representative Figures

   .. figure:: ../../images/tests/001_poisson/test01/phi_zx.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-medium

      ``test01`` middle-``y`` ``log10(phi)`` slice from the multi-rank smoke test.

   .. figure:: ../../images/tests/001_poisson/test02/case1_linear_x_compare_limited_colorbar.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``test02`` ``case1`` three-panel comparison. The numerical and exact
      fields agree at about the ``1e-7`` level and the error map stays near zero.
