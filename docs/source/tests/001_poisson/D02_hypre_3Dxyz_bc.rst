D02_hypre_3Dxyz_bc Tests
========================

.. raw:: html

   <div class="pmsl-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="pmsl-lang-button" data-pmsl-set-lang="zh">中文</button>
     <button type="button" class="pmsl-lang-button" data-pmsl-set-lang="en">English</button>
   </div>

.. container:: pmsl-lang pmsl-lang-zh

   本页对应 ``tests/001_poisson/test01`` 和 ``test02``。两者共同描述 D02 在 Cartesian
   ``(x,y,z)`` 网格上的当前测试边界：``test01`` 偏重多 rank 代码路径，``test02`` 偏重解析边界回归。

   .. rubric:: 测试定位

   D02 当前测试分成两层：

   - ``test01``: 检查多 rank、矩阵组装、dielectric 修改、outflow 修改和求解入口是否贯通。
   - ``test02``: 用四个可解析边界算例确认边界离散和求解结果是否符合预期。

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
        - 4-rank smoke test 的全局势函数和 ``x-z`` 截面图。当前绘图脚本采用与 ``test00`` 相同的 ``8 x 6 inch`` 画布和 ``300 dpi``，默认输出 ``2400 x 1800`` PNG，并采用统一标题前缀。
      * - ``test02``
        - ``case*_compare.dat``、``case*_limited_colorbar.png``
        - 四组解析边界算例的逐点比较数据和三联图。三联图与 ``test00/test01`` 共享相同的 ``8 x 6 inch`` 画布、``300 dpi`` 输出和统一标题风格，便于和单图结果一起人工比对。

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
      :figclass: pmsl-figure-equal-height

      ``test01`` 的 ``x-z`` 截面势函数，显示多 rank smoke test 输出稳定。

   .. figure:: ../../images/tests/001_poisson/test02/case1_linear_x_compare_limited_colorbar.png
      :align: center
      :figclass: pmsl-figure-equal-height

      ``test02`` 的 ``case1`` 三联图。数值解与解析解在 ``1e-7`` 量级内重合，误差图接近零。

.. container:: pmsl-lang pmsl-lang-en

   This page corresponds to ``tests/001_poisson/test01`` and ``test02``.
   Together they define the current D02 Cartesian test boundary: ``test01`` is
   the multi-rank path check, while ``test02`` is the exact-boundary regression
   set.

   .. rubric:: Test Role

   The current D02 coverage is split into two layers:

   - ``test01``: checks multi-rank assembly plus dielectric/outflow edits and the solve entry.
   - ``test02``: uses four exact boundary cases as the numerical regression baseline.

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
        - Global field and ``x-z`` slice from the 4-rank smoke test. The plotting script now uses the same ``8 x 6 inch`` canvas and ``300 dpi`` baseline as ``test00``, producing ``2400 x 1800`` PNGs with a shared title prefix.
      * - ``test02``
        - ``case*_compare.dat``, ``case*_limited_colorbar.png``
        - Pointwise comparison data and three-panel figures for the four exact-boundary cases. The three-panel figures use the same ``8 x 6 inch`` canvas, ``300 dpi`` output, and title style as ``test00`` and ``test01``.

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
      :figclass: pmsl-figure-equal-height

      ``test01`` ``x-z`` potential slice from the multi-rank smoke test.

   .. figure:: ../../images/tests/001_poisson/test02/case1_linear_x_compare_limited_colorbar.png
      :align: center
      :figclass: pmsl-figure-equal-height

      ``test02`` ``case1`` three-panel comparison. The numerical and exact
      fields agree at about the ``1e-7`` level and the error map stays near zero.
