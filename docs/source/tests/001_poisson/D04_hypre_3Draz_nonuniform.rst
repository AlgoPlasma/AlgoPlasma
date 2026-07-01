D04_hypre_3Draz_nonuniform Tests
================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   本页对应 ``tests/001_poisson/test05`` 到 ``test07``。三者共同描述 D04 非均匀柱坐标求解器的当前测试边界：
   ``test05`` 是单 rank 边界条件基线，``test06`` 是多 rank 解析/MPI 回归，``test07`` 用来和 D03 做 MMS 对比。

   .. rubric:: 测试定位

   D04 当前测试分成三层：

   - ``test05``: 单 rank 非均匀网格边界条件回归。
   - ``test06``: 固定 ``2 x 2 x 2`` 分块的 8-rank 解析/MPI 回归。
   - ``test07``: 在同一制造解下比较 D03 均匀网格和 D04 非均匀网格误差。

   .. rubric:: 运行方式

   运行前建议确认：

   .. code-block:: bash

      which mpif90
      which mpirun
      python3 -c "import numpy, matplotlib"

   编译前先检查并修改三个目录中的 ``HYPRE_INC`` 和 ``HYPRE_LIB``，确保它们指向本机 HYPRE 安装路径。随后三个目录都通过脚本直接完成编译、运行和绘图：

   .. code-block:: bash

      cd tests/001_poisson/test05
      bash run.sh

      cd ../test06
      bash run_multi_raz.sh

      cd ../test07
      bash run.sh

   ``test05`` 和 ``test07`` 默认单 rank，``test06`` 默认 ``mpirun -n 8``。

   .. rubric:: 覆盖内容

   .. list-table::
      :header-rows: 1
      :widths: 18 32 50

      * - 测试
        - 被测接口
        - 检查内容
      * - ``test05``
        - ``sub_D04_hypre_3Draz_nonuniform_A``、``sub_D04_hypre_3Draz_nonuniform``、``sub_D04_hypre_3Draz_nonuniform_bc_A_dielectric``、``sub_D04_hypre_3Draz_nonuniform_bc_A_outflow``
        - case 1 用非均匀网格线性解析解验证 axis、Neumann、Dirichlet；case 2 和 case 3 分别覆盖 dielectric 与 outflow 修改路径。
      * - ``test06``
        - ``sub_D04_hypre_3Draz_nonuniform_A_mpi``、``sub_D04_hypre_3Draz_nonuniform``
        - 在固定 ``2 x 2 x 2`` MPI 分块下，用解析解 ``J1(kappa r) cos(alpha) sin(pi z/Lz)`` 检查非均匀 ``r``/``z`` 网格、ghost 宽度交换、局部组装和全局汇总。
      * - ``test07``
        - D03 与 D04 主组装和求解入口
        - 在同一制造解上，对比均匀网格 D03 和非均匀网格 D04 在 ``16``、``24``、``32``、``48`` 四组网格下的误差水平与收敛趋势。

   .. rubric:: 输出文件

   .. list-table::
      :header-rows: 1
      :widths: 22 28 50

      * - 测试
        - 主要输出
        - 说明
      * - ``test05``
        - ``case1_nonuniform_phi_compare.dat``、``case2_nonuniform_phi_only.dat``、``case3_nonuniform_phi_only.dat``、``fig_case*/*.png``
        - 单 rank 非均匀边界条件回归的逐点数据和网格索引图。当前绘图脚本采用固定 ``8 x 4.5 inch`` 画布和 ``300 dpi``，默认输出 ``2400 x 1350`` PNG，并采用统一标题格式。
      * - ``test06``
        - ``phi_compare.dat``、``fig_phi_compare/*.png``
        - 8-rank 解析回归的逐点比较数据，以及物理坐标下的场图、误差图和线剖面对比。所有视图共享同一画布尺寸和统一标题前缀。
      * - ``test07``
        - ``compare_uniform_nonuniform_rz_mms.dat``、``field_uniform_fine.dat``、``field_nonuniform_fine.dat``、``fig_compare_uniform_nonuniform_rz_mms/*.png``
        - D03/D04 MMS 误差汇总、最细网格场数据，以及两套网格的对比图。误差收敛图和场图使用同一固定输出尺寸，便于并排查看。

   .. rubric:: 参考结果

   ``test05`` 的 case 1 当前给出：

   - ``L_inf = 3.8822896009094165E-007``
   - relative ``L2 = 5.9671035373130525E-010``

   这说明 D04 在单 rank 非均匀网格上线性场恢复已达到当前预期精度。case 2 与 case 3 主要用于覆盖 dielectric/outflow 代码路径。

   ``test06`` 当前 8-rank 解析/MPI 回归给出：

   - ``L_inf = 2.3782137742550113E-003``
   - relative ``L2 = 4.0385259915813676E-003``

   该测试不以 machine precision 为目标，而是用来同时验证非均匀网格、解析右端、固定 ``2 x 2 x 2`` 分块以及 MPI 汇总流程是否稳定。

   ``test07`` 的误差趋势见下方收敛图。当前制造解和网格设置下，均匀网格 D03 的误差整体低于非均匀网格 D04，但两者都随网格加密而下降。

   .. figure:: ../../images/tests/001_poisson/test07/fig_compare_uniform_nonuniform_rz_mms/mms_error_convergence.png
      :align: center
      :figclass: ap-figure-equal-height

      ``test07`` 的 MMS 误差收敛图。横轴为 ``N``，纵轴为误差；D03 与 D04 的 ``L_inf`` 和 relative ``L2`` 一起显示，便于直接比较两种网格的误差水平和下降趋势。

   .. rubric:: 代表图

   .. figure:: ../../images/tests/001_poisson/test05/fig_case1/grid_error_j1.png
      :align: center
      :figclass: ap-figure-equal-height

      ``test05`` case 1 的误差图。误差分布平滑，峰值约为 ``3.88e-7``，对应单 rank 非均匀边界条件回归。

   .. figure:: ../../images/tests/001_poisson/test06/fig_phi_compare/rz_pcolormesh_abs_error_j1.png
      :align: center
      :figclass: ap-figure-equal-height

      ``test06`` 的 ``r-z`` 物理坐标误差图，对应 8-rank 解析/MPI 回归汇总后的全局误差场。

   .. figure:: ../../images/tests/001_poisson/test06/fig_phi_compare/line_r_j1_k17.png
      :align: center
      :figclass: ap-figure-equal-height

      ``test06`` 在固定 ``j=1``、``k=17`` 下的径向线剖面对比图，用于检查 MPI 汇总后的解析解与数值解一致性。

   .. figure:: ../../images/tests/001_poisson/test07/fig_compare_uniform_nonuniform_rz_mms/uniform_error_j1.png
      :align: center
      :figclass: ap-figure-equal-height

      ``test07`` 的均匀网格误差图，对应最细 ``48 x 48`` MMS 结果。

   .. figure:: ../../images/tests/001_poisson/test07/fig_compare_uniform_nonuniform_rz_mms/nonuniform_error_j1.png
      :align: center
      :figclass: ap-figure-equal-height

      ``test07`` 的非均匀网格误差图。与均匀网格相比误差较大，但空间分布平滑并随加密下降。

.. container:: ap-lang ap-lang-en

   This page corresponds to ``tests/001_poisson/test05`` through ``test07``.
   Together they define the current D04 nonuniform cylindrical test boundary:
   ``test05`` is the single-rank boundary-condition baseline, ``test06`` is the
   analytic/MPI regression, and ``test07`` compares D04 against D03 with the
   same manufactured solution.

   .. rubric:: Test Role

   The current D04 coverage is split into three layers:

   - ``test05``: single-rank nonuniform boundary-condition regression.
   - ``test06``: 8-rank analytic/MPI regression on a fixed ``2 x 2 x 2`` decomposition.
   - ``test07``: D03 versus D04 MMS comparison on the same manufactured solution.

   .. rubric:: How To Run

   Before running them, check:

   .. code-block:: bash

      which mpif90
      which mpirun
      python3 -c "import numpy, matplotlib"

   Before building, update ``HYPRE_INC`` and ``HYPRE_LIB`` in the three test
   directories so they match the local HYPRE installation. Then all three
   directories use scripts to build, run, and plot:

   .. code-block:: bash

      cd tests/001_poisson/test05
      bash run.sh

      cd ../test06
      bash run_multi_raz.sh

      cd ../test07
      bash run.sh

   ``test05`` and ``test07`` run on one rank by default. ``test06`` runs with
   ``mpirun -n 8`` by default.

   .. rubric:: Coverage

   .. list-table::
      :header-rows: 1
      :widths: 18 32 50

      * - Test
        - Interfaces
        - What is checked
      * - ``test05``
        - ``sub_D04_hypre_3Draz_nonuniform_A``, ``sub_D04_hypre_3Draz_nonuniform``, ``sub_D04_hypre_3Draz_nonuniform_bc_A_dielectric``, ``sub_D04_hypre_3Draz_nonuniform_bc_A_outflow``
        - Case 1 verifies axis, Neumann, and Dirichlet handling with a linear analytic field on a nonuniform mesh. Case 2 and case 3 exercise the dielectric and outflow edit paths.
      * - ``test06``
        - ``sub_D04_hypre_3Draz_nonuniform_A_mpi``, ``sub_D04_hypre_3Draz_nonuniform``
        - Uses the analytic solution ``J1(kappa r) cos(alpha) sin(pi z/Lz)`` on a fixed ``2 x 2 x 2`` MPI decomposition to check nonuniform ``r``/``z`` spacing, ghost exchange, local assembly, and gathered output.
      * - ``test07``
        - D03 and D04 main assembly and solve entries
        - Compares the uniform-grid D03 and nonuniform-grid D04 error levels and refinement trend over ``16``, ``24``, ``32``, and ``48`` grids.

   .. rubric:: Output Files

   .. list-table::
      :header-rows: 1
      :widths: 22 28 50

      * - Test
        - Main outputs
        - Notes
      * - ``test05``
        - ``case1_nonuniform_phi_compare.dat``, ``case2_nonuniform_phi_only.dat``, ``case3_nonuniform_phi_only.dat``, ``fig_case*/*.png``
        - Pointwise data and grid-index figures for the single-rank nonuniform BC regression. The plotting script uses a fixed ``8 x 4.5 inch`` canvas at ``300 dpi``, producing ``2400 x 1350`` PNGs with a shared title style.
      * - ``test06``
        - ``phi_compare.dat``, ``fig_phi_compare/*.png``
        - Pointwise comparison data plus physical-coordinate field, error, and line-comparison plots for the 8-rank analytic/MPI regression. All views use the same canvas size and title prefix.
      * - ``test07``
        - ``compare_uniform_nonuniform_rz_mms.dat``, ``field_uniform_fine.dat``, ``field_nonuniform_fine.dat``, ``fig_compare_uniform_nonuniform_rz_mms/*.png``
        - MMS summary, finest-grid field files, and comparison figures for the two grid types. The convergence plot and field figures share the same fixed output size for easier side-by-side reading.

   .. rubric:: Reference Result

   ``test05`` case 1 currently gives:

   - ``L_inf = 3.8822896009094165E-007``
   - relative ``L2 = 5.9671035373130525E-010``

   This is the current single-rank nonuniform linear-field regression level.
   Case 2 and case 3 mainly serve to cover the dielectric/outflow code paths.

   ``test06`` currently gives:

   - ``L_inf = 2.3782137742550113E-003``
   - relative ``L2 = 4.0385259915813676E-003``

   This test is not targeting machine-precision recovery. Its role is to
   validate the combined nonuniform-grid, analytic-source, fixed
   ``2 x 2 x 2`` decomposition, and MPI gather path.

   ``test07`` error trends are summarized in the convergence figure below. In
   the current manufactured-solution setup, the uniform-grid D03 result is more
   accurate than the nonuniform-grid D04 result, while both still improve with
   refinement.

   .. figure:: ../../images/tests/001_poisson/test07/fig_compare_uniform_nonuniform_rz_mms/mms_error_convergence.png
      :align: center
      :figclass: ap-figure-equal-height

      MMS convergence plot for ``test07``. The horizontal axis is ``N`` and
      the curves show both ``L_inf`` and relative ``L2`` for D03 and D04.

   .. rubric:: Representative Figures

   .. figure:: ../../images/tests/001_poisson/test05/fig_case1/grid_error_j1.png
      :align: center
      :figclass: ap-figure-equal-height

      ``test05`` case-1 error map. The field is smooth and peaks near
      ``3.88e-7``, which is the intended single-rank D04 regression signal.

   .. figure:: ../../images/tests/001_poisson/test06/fig_phi_compare/rz_pcolormesh_abs_error_j1.png
      :align: center
      :figclass: ap-figure-equal-height

      ``test06`` physical ``r-z`` error map from the gathered 8-rank analytic
      regression.

   .. figure:: ../../images/tests/001_poisson/test06/fig_phi_compare/line_r_j1_k17.png
      :align: center
      :figclass: ap-figure-equal-height

      Radial line comparison at fixed ``j=1`` and ``k=17`` in ``test06``.

   .. figure:: ../../images/tests/001_poisson/test07/fig_compare_uniform_nonuniform_rz_mms/uniform_error_j1.png
      :align: center
      :figclass: ap-figure-equal-height

      Uniform-grid error field for the finest ``48 x 48`` MMS case.

   .. figure:: ../../images/tests/001_poisson/test07/fig_compare_uniform_nonuniform_rz_mms/nonuniform_error_j1.png
      :align: center
      :figclass: ap-figure-equal-height

      Nonuniform-grid error field for the same finest-grid MMS case.
