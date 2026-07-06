D03_hypre_3Draz_uniform Tests
=============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   本页对应 ``tests/001_poisson/test03`` 和 ``test04``。两者共同构成 D03 均匀柱坐标求解器的边界条件回归：
   ``test03`` 是单 rank 基线，``test04`` 是 MPI 对照。

   .. rubric:: 测试定位

   D03 当前测试结构很直接：

   - ``test03``: 单 rank 边界条件回归。
   - ``test04``: 在 MPI 分块下重复同类测试，检查结果是否与单 rank 一致。

   .. rubric:: 这个测试在做什么

   D03 求解的是均匀柱坐标 ``(r, alpha, z)`` 网格上的 Poisson 方程。本页测试采用
   quasi-2D ``r-z`` 设置：``alpha`` 方向保留 8 个周期网格点，用来确认周期方向和
   3D 数据布局仍然走通；待验证的物理变化主要放在 ``r`` 和 ``z`` 方向。

   ``test03`` 是单 rank 基线。它先用有解析解的线性势
   :math:`\phi(z)=20z/L_z` 检查 axis、Neumann 和 Dirichlet 边界，再用两个
   smoke case 分别走 dielectric 和 outflow 修正路径。``test04`` 使用同一组物理算例，
   但把全局网格分给多个 MPI rank，重点检查局部矩阵组装、内部 MPI 面、物理外边界和
   结果汇总是否与单 rank 保持一致。

   .. rubric:: 参数设置

   .. list-table::
      :header-rows: 1
      :widths: 20 28 52

      * - 算例
        - 网格与运行方式
        - 主要设置
      * - ``test03`` case 1
        - 单 rank，``nr=320``、``na=8``、``nz=320``。
        - ``rmin=0``、``rmax=2``、``Lz=1``、``eps0=1``、``tolerance=1e-10``。``r_lo`` 为 axis，``r_hi`` 为 zero-Neumann，``z_lo=0 V``，``z_hi=20 V``，解析解为 ``phi(z)=20*z/Lz``。
      * - ``test03`` case 2
        - 单 rank，``nr=240``、``na=8``、``nz=240``。
        - 保持 ``z_lo=0 V``、``z_hi=20 V`` 和 ``alpha`` 周期；``r_hi`` 改为 dielectric，表面修正 ``sr_hi=1e-3``。该算例用于覆盖 dielectric 路径，不做解析误差判据。
      * - ``test03`` case 3
        - 单 rank，``nr=240``、``na=8``、``nz=240``。
        - ``r_hi`` 改为 outflow，``phi_infty=20``，``r0_cyl=(0,0,-10)``。该算例用于覆盖 outflow 路径，不做解析误差判据。
      * - ``test04`` 三个 case
        - 默认 ``mpirun -n 8``；``MPI_Dims_create`` 自动给出 ``(r,alpha,z)`` 三维分块。
        - 使用与 ``test03`` 相同的全局网格、边界和物理参数；内部 MPI 面由 neighbor 标记处理，只有全局外边界使用 axis、Neumann、Dirichlet、dielectric 或 outflow。

   边界数组顺序为 ``r_lo, r_hi, alpha_lo, alpha_hi, z_lo, z_hi``。
   ``alpha`` 方向通过 ``period=(0,na,0)`` 保持周期，因此本组图主要展示固定
   ``alpha`` 截面上的 ``r-z`` 结果。

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

   .. rubric:: 图片如何阅读

   case 1 的三联图从左到右分别是解析解、数值解和绝对误差。横轴为 ``z`` 索引，
   纵轴为 ``r`` 索引，画的是固定 ``alpha`` 截面。由于解析解只依赖 ``z``，
   左图和中图应呈现沿 ``z`` 单调变化、沿 ``r`` 基本不变的条带结构；右图应整体接近零。
   ``test04`` 的三联图应与 ``test03`` 保持同样的结构和误差量级，这说明 MPI 局部组装没有破坏解。

   case 2 和 case 3 输出的是 smoke 图，主要用于人工检查 dielectric/outflow 路径是否跑通、
   结果是否有限平滑；它们不是解析误差图。

   .. rubric:: 代表图

   ``test03`` case 1 三联图：

   .. list-table::
      :class: ap-triptych
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
      :class: ap-triptych
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

.. container:: ap-lang ap-lang-en

   This page corresponds to ``tests/001_poisson/test03`` and ``test04``.
   Together they define the D03 uniform cylindrical boundary-condition
   regression: ``test03`` is the single-rank baseline and ``test04`` is the
   MPI comparison run.

   .. rubric:: Test Role

   The current D03 split is simple:

   - ``test03``: single-rank boundary-condition regression.
   - ``test04``: the same boundary suite under MPI decomposition.

   .. rubric:: What This Test Is Doing

   D03 solves the Poisson equation on a uniform cylindrical ``(r, alpha, z)``
   grid. These tests use a quasi-2D ``r-z`` setup: the ``alpha`` direction
   still contains 8 periodic cells, so the periodic direction and 3D layout
   remain active, while the meaningful field variation is placed in ``r`` and
   ``z``.

   ``test03`` is the single-rank baseline. It first uses the exact linear
   potential :math:`\phi(z)=20z/L_z` to verify axis, Neumann, and Dirichlet
   boundaries, then runs two smoke cases that exercise the dielectric and
   outflow edit paths. ``test04`` repeats the same physical cases under MPI
   decomposition. Its focus is local matrix assembly, internal MPI faces,
   physical outer boundaries, and gathered output consistency with the
   single-rank baseline.

   .. rubric:: Parameters

   .. list-table::
      :header-rows: 1
      :widths: 20 28 52

      * - Case
        - Grid and run mode
        - Main settings
      * - ``test03`` case 1
        - Single rank, ``nr=320``, ``na=8``, ``nz=320``.
        - ``rmin=0``, ``rmax=2``, ``Lz=1``, ``eps0=1``, ``tolerance=1e-10``. ``r_lo`` is axis, ``r_hi`` is zero-Neumann, ``z_lo=0 V``, ``z_hi=20 V``, with exact solution ``phi(z)=20*z/Lz``.
      * - ``test03`` case 2
        - Single rank, ``nr=240``, ``na=8``, ``nz=240``.
        - Keeps ``z_lo=0 V``, ``z_hi=20 V``, and periodic ``alpha``; changes ``r_hi`` to dielectric with ``sr_hi=1e-3``. This is a dielectric-path smoke case, not an analytic-error check.
      * - ``test03`` case 3
        - Single rank, ``nr=240``, ``na=8``, ``nz=240``.
        - Changes ``r_hi`` to outflow with ``phi_infty=20`` and ``r0_cyl=(0,0,-10)``. This is an outflow-path smoke case, not an analytic-error check.
      * - ``test04`` three cases
        - Default ``mpirun -n 8``; ``MPI_Dims_create`` chooses the 3D ``(r,alpha,z)`` decomposition.
        - Uses the same global grids, boundaries, and physical parameters as ``test03``. Internal MPI faces are handled through neighbor flags; only global outer faces receive axis, Neumann, Dirichlet, dielectric, or outflow boundary codes.

   The boundary array order is ``r_lo, r_hi, alpha_lo, alpha_hi, z_lo, z_hi``.
   ``alpha`` is periodic through ``period=(0,na,0)``, so the figures mainly
   show ``r-z`` slices at a fixed ``alpha`` index.

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

   .. rubric:: How To Read The Figures

   The case-1 triptychs show exact field, numerical field, and absolute error
   from left to right. The horizontal axis is ``z`` index and the vertical axis
   is ``r`` index at one fixed ``alpha`` slice. Because the exact solution only
   depends on ``z``, the first two panels should show a monotone ``z`` pattern
   with little ``r`` variation, and the error panel should remain near zero.
   The ``test04`` triptych should match the ``test03`` structure and error
   scale, showing that MPI-local assembly does not disturb the solution.

   Case 2 and case 3 figures are smoke outputs for the dielectric and outflow
   paths. They should be finite and smooth, but they are not analytic-error
   plots.

   .. rubric:: Representative Figures

   ``test03`` case-1 three-panel view:

   .. list-table::
      :class: ap-triptych
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
      :class: ap-triptych
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
