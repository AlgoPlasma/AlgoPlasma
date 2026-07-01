D03_hypre_3Draz_uniform Tests
=============================

.. raw:: html

   <div class="pmsl-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="pmsl-lang-button" data-pmsl-set-lang="zh">中文</button>
     <button type="button" class="pmsl-lang-button" data-pmsl-set-lang="en">English</button>
   </div>

.. container:: pmsl-lang pmsl-lang-zh

   本页对应 ``tests/001_poisson/test03`` 和 ``test04``。两者共同构成 D03 均匀柱坐标求解器的边界条件回归：
   ``test03`` 是单 rank 基线，``test04`` 是 MPI 对照。

   .. rubric:: 测试定位

   D03 当前测试结构很直接：

   - ``test03``: 单 rank 边界条件回归。
   - ``test04``: 在 MPI 分块下重复同类测试，检查结果是否与单 rank 一致。

   .. rubric:: 运行方式

   运行前建议确认：

   .. code-block:: bash

      which mpif90
      which mpirun
      python3 -c "import numpy, matplotlib"

   编译前先检查并修改两个目录中的 ``HYPRE_INC`` 和 ``HYPRE_LIB``，确保它们指向本机 HYPRE 安装路径。随后两个目录都通过 ``run.sh`` 直接完成编译、运行和绘图：

   .. code-block:: bash

      cd tests/001_poisson/test03
      bash run.sh

      cd ../test04
      bash run.sh

   ``test03`` 默认单 rank，``test04`` 默认 ``mpirun -n 8``。

   .. rubric:: 覆盖内容

   .. list-table::
      :header-rows: 1
      :widths: 18 32 50

      * - 测试
        - 被测接口
        - 检查内容
      * - ``test03``
        - ``sub_D03_hypre_3Draz_uniform_A``、``sub_D03_hypre_3Draz_uniform``、``sub_D03_hypre_3Draz_uniform_bc_A_dielectric``、``sub_D03_hypre_3Draz_uniform_bc_A_outflow``
        - case 1 用线性解析解验证 axis、Neumann、Dirichlet；case 2 和 case 3 分别检查 dielectric 与 outflow 路径。
      * - ``test04``
        - ``sub_D03_hypre_3Draz_uniform_A_mpi``、``sub_D03_hypre_3Draz_uniform``、``sub_D03_hypre_3Draz_uniform_bc_A_dielectric``、``sub_D03_hypre_3Draz_uniform_bc_A_outflow``
        - 在 MPI 分块下重复相同边界条件测试，检查局部组装、物理边界和汇总输出是否一致。

   .. rubric:: 输出文件

   .. list-table::
      :header-rows: 1
      :widths: 22 26 52

      * - 测试
        - 主要输出
        - 说明
      * - ``test03``
        - ``case1_phi_compare.dat``、``case2_phi_only.dat``、``case3_phi_only.dat``、``fig_case*/*.png``
        - 单 rank 解析对比和 smoke 图。当前绘图脚本采用固定 ``8 x 4.5 inch`` 画布和 ``300 dpi``，默认输出 ``2400 x 1350`` PNG，并使用统一标题格式。
      * - ``test04``
        - ``case1_phi_compare.dat``、``case2_phi_only.dat``、``case3_phi_only.dat``、``fig_case*/*.png``
        - MPI 版本的同类输出，尺寸和标题规则与 ``test03`` 保持一致。

   .. rubric:: 参考结果

   ``test03`` 的 case 1 当前给出：

   - ``L_inf = 9.1019079242471401E-06``
   - relative ``L2 = 1.9264843543832734E-09``

   ``test04`` 的 case 1 当前给出：

   - ``L_inf = 9.1019079171417195E-06``
   - relative ``L2 = 1.9264841758867920E-09``

   两者在误差量级上几乎一致，说明 MPI 分块没有引入明显额外误差。case 2 与 case 3 主要用于覆盖 dielectric/outflow 代码路径。

   .. rubric:: 代表图

   ``test03`` case 1 三联图：

   .. list-table::
      :class: pmsl-triptych
      :widths: 34 33 33

      * - .. image:: ../../images/tests/001_poisson/test03/fig_case1/grid_phi_exact_j1.png
             :width: 100%
             :alt: test03 case1 exact field
        - .. image:: ../../images/tests/001_poisson/test03/fig_case1/grid_phi_num_j1.png
             :width: 100%
             :alt: test03 case1 numerical field
        - .. image:: ../../images/tests/001_poisson/test03/fig_case1/grid_error_j1.png
             :width: 100%
             :alt: test03 case1 error field

   ``test03`` case 1 三联图，从左到右分别为解析解、数值解和误差图。数值场结构应与解析解一致，误差应接近零，这是单 rank D03 主组装和边界处理正确的直接证据。

   ``test04`` case 1 三联图：

   .. list-table::
      :class: pmsl-triptych
      :widths: 34 33 33

      * - .. image:: ../../images/tests/001_poisson/test04/fig_case1/grid_phi_exact_j1.png
             :width: 100%
             :alt: test04 case1 exact field
        - .. image:: ../../images/tests/001_poisson/test04/fig_case1/grid_phi_num_j1.png
             :width: 100%
             :alt: test04 case1 numerical field
        - .. image:: ../../images/tests/001_poisson/test04/fig_case1/grid_error_j1.png
             :width: 100%
             :alt: test04 case1 error field

   ``test04`` case 1 三联图，从左到右分别为解析解、数值解和误差图。MPI 版本仍使用同一解析参考场，数值场结构应与 ``test03`` case 1 保持一致，误差量级也应与单 rank 基线对齐。

.. container:: pmsl-lang pmsl-lang-en

   This page corresponds to ``tests/001_poisson/test03`` and ``test04``.
   Together they define the D03 uniform cylindrical boundary-condition
   regression: ``test03`` is the single-rank baseline and ``test04`` is the
   MPI comparison run.

   .. rubric:: Test Role

   The current D03 split is simple:

   - ``test03``: single-rank boundary-condition regression.
   - ``test04``: the same boundary suite under MPI decomposition.

   .. rubric:: How To Run

   Before running them, check:

   .. code-block:: bash

      which mpif90
      which mpirun
      python3 -c "import numpy, matplotlib"

   Before building, update ``HYPRE_INC`` and ``HYPRE_LIB`` in both test
   directories so they match the local HYPRE installation. Then both
   directories use ``run.sh`` to build, run, and plot:

   .. code-block:: bash

      cd tests/001_poisson/test03
      bash run.sh

      cd ../test04
      bash run.sh

   ``test03`` runs on one rank by default. ``test04`` runs with
   ``mpirun -n 8`` by default.

   .. rubric:: Coverage

   .. list-table::
      :header-rows: 1
      :widths: 18 32 50

      * - Test
        - Interfaces
        - What is checked
      * - ``test03``
        - ``sub_D03_hypre_3Draz_uniform_A``, ``sub_D03_hypre_3Draz_uniform``, ``sub_D03_hypre_3Draz_uniform_bc_A_dielectric``, ``sub_D03_hypre_3Draz_uniform_bc_A_outflow``
        - Case 1 verifies axis, Neumann, and Dirichlet handling with a linear analytic solution. Case 2 and case 3 exercise the dielectric and outflow paths.
      * - ``test04``
        - ``sub_D03_hypre_3Draz_uniform_A_mpi``, ``sub_D03_hypre_3Draz_uniform``, ``sub_D03_hypre_3Draz_uniform_bc_A_dielectric``, ``sub_D03_hypre_3Draz_uniform_bc_A_outflow``
        - Repeats the same suite under MPI decomposition and checks local assembly, physical boundaries, and gathered output consistency.

   .. rubric:: Output Files

   .. list-table::
      :header-rows: 1
      :widths: 22 26 52

      * - Test
        - Main outputs
        - Notes
      * - ``test03``
        - ``case1_phi_compare.dat``, ``case2_phi_only.dat``, ``case3_phi_only.dat``, ``fig_case*/*.png``
        - Single-rank analytic comparison and smoke figures. The plotting script uses a fixed ``8 x 4.5 inch`` canvas at ``300 dpi``, producing ``2400 x 1350`` PNGs with a unified title style.
      * - ``test04``
        - ``case1_phi_compare.dat``, ``case2_phi_only.dat``, ``case3_phi_only.dat``, ``fig_case*/*.png``
        - MPI version of the same outputs, with the same size and title rules as ``test03``.

   .. rubric:: Reference Result

   ``test03`` case 1 currently gives:

   - ``L_inf = 9.1019079242471401E-06``
   - relative ``L2 = 1.9264843543832734E-09``

   ``test04`` case 1 currently gives:

   - ``L_inf = 9.1019079171417195E-06``
   - relative ``L2 = 1.9264841758867920E-09``

   The two runs match closely in error scale, which shows that the MPI
   decomposition does not introduce a meaningful additional accuracy loss.
   Case 2 and case 3 mainly serve to cover the dielectric/outflow code paths.

   .. rubric:: Representative Figures

   ``test03`` case-1 three-panel view:

   .. list-table::
      :class: pmsl-triptych
      :widths: 34 33 33

      * - .. image:: ../../images/tests/001_poisson/test03/fig_case1/grid_phi_exact_j1.png
             :width: 100%
             :alt: test03 case1 exact field
        - .. image:: ../../images/tests/001_poisson/test03/fig_case1/grid_phi_num_j1.png
             :width: 100%
             :alt: test03 case1 numerical field
        - .. image:: ../../images/tests/001_poisson/test03/fig_case1/grid_error_j1.png
             :width: 100%
             :alt: test03 case1 error field

   ``test03`` case-1 triptych. From left to right: exact field, numerical field, and error map. The numerical field should follow the exact solution and the error should remain near zero, which is the intended single-rank D03 regression signal.

   ``test04`` case-1 three-panel view:

   .. list-table::
      :class: pmsl-triptych
      :widths: 34 33 33

      * - .. image:: ../../images/tests/001_poisson/test04/fig_case1/grid_phi_exact_j1.png
             :width: 100%
             :alt: test04 case1 exact field
        - .. image:: ../../images/tests/001_poisson/test04/fig_case1/grid_phi_num_j1.png
             :width: 100%
             :alt: test04 case1 numerical field
        - .. image:: ../../images/tests/001_poisson/test04/fig_case1/grid_error_j1.png
             :width: 100%
             :alt: test04 case1 error field

   ``test04`` case-1 triptych. From left to right: exact field, numerical field, and error map. The MPI run uses the same analytic reference field, and both the solution pattern and error scale should stay aligned with the single-rank baseline.
