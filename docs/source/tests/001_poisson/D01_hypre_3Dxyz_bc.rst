D01_hypre_3Dxyz_bc Tests
========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   本页对应 ``tests/001_poisson/test00``。它不是解析精度回归，而是 D01 旧版
   Fortran-C-HYPRE 路径的保留性 smoke test，用来确认最早一套 Cartesian 接口仍能完整跑通。

   .. rubric:: 测试定位

   ``test00`` 主要检查三件事：

   - 旧版 D01 接口是否还能成功编译和链接。
   - 4-rank 下非规则 box 分块是否还能正确组装并求解。
   - 输出的势函数场是否有限、连续、无明显 rank 拼接缝。

   .. rubric:: 这个测试在做什么

   ``test00`` 在 ``32 x 8 x 32`` 的 Cartesian 网格上调用旧版
   ``sub_D01_hypre_3Dxyz_interface``。计算域被手动切成 4 个不等大小的
   MPI box，每个 rank 拥有一块局部区域；这种分块方式不是为了做规则负载均衡，
   而是为了保留早期 D01 接口对非规则子域、内部 MPI 面和物理外边界混合出现时的覆盖。

   该测试只在 rank 0 的局部 ``zmin`` 层放置一个简单源项 ``rho=1``，其余位置
   ``rho=0``。因此它没有解析真解，也不应按精度测试解读；它的作用是确认旧接口在
   混合边界和多 rank 回收输出下仍能得到有限、平滑的势函数场。

   .. rubric:: 参数设置

   .. list-table::
      :header-rows: 1
      :widths: 24 76

      * - 项目
        - 设置
      * - 全局网格
        - ``il0=(1,1,1)``、``iu0=(32,8,32)``，即 ``32 x 8 x 32``。
      * - MPI 数量
        - 固定 ``4`` 个 rank，``run.sh`` 使用 ``mpirun -np 4``。
      * - 周期方向
        - ``y`` 方向在旧接口中按周期方向处理；边界数组只显式描述 ``x`` 和 ``z`` 方向。
      * - 局部分块
        - rank 0: ``x=9..24,z=1..16``；rank 1: ``x=1..8,z=17..32``；rank 2: ``x=9..24,z=17..32``；rank 3: ``x=25..32,z=17..32``。
      * - 边界码
        - ``bc`` 数组按 ``xmin,xmax,zmin,zmax`` 给出；``0`` 表示内部面，``1`` 表示 Dirichlet，``2`` 表示 Neumann。
      * - 源项
        - 只有 rank 0 的局部 ``zmin`` 层设置 ``rho=1``，其他网格点为 ``0``。
      * - 求解容差
        - ``tolerance = 1.0e-6``。

   .. rubric:: 运行方式

   运行前建议确认：

   .. code-block:: bash

      which mpif90
      which mpicc
      which mpirun
      python3 -c "import numpy, matplotlib"

   编译前先检查并修改 ``make.sh`` 中的 ``HYPRE_INC`` 和 ``HYPRE_LIB``，确保它们指向本机 HYPRE 安装路径。随后目录脚本使用 ``make.sh`` 编译，再通过 ``run.sh`` 调用 4-rank MPI 运行：

   .. code-block:: bash

      cd tests/001_poisson/test00
      bash clean.sh
      bash make.sh
      bash run.sh
      python3 plot.py

   .. rubric:: 覆盖内容

   .. list-table::
      :header-rows: 1
      :widths: 24 30 46

      * - 测试
        - 被测接口
        - 检查内容
      * - ``test00``
        - ``sub_D01_hypre_3Dxyz_interface``
        - 检查 legacy D01 路径在 4 个 MPI rank 下是否还能处理 ``y`` 周期边界、混合 ``x/z`` Dirichlet-Neumann 条件，并返回有限势函数场。

   .. rubric:: 输出文件

   .. list-table::
      :header-rows: 1
      :widths: 28 20 52

      * - 文件
        - 类型
        - 说明
      * - ``phi.dat``
        - 数据
        - ``32 x 8 x 32`` 全局网格回收后的扁平势函数数组。
      * - ``phi_zx.png``
        - 图片
        - 中间 ``y`` 截面的 ``log10(phi)`` 显示图。

   .. rubric:: 图片如何阅读

   ``phi_zx.png`` 横轴为 ``z`` 方向索引，纵轴为 ``x`` 方向索引，取的是中间
   ``y`` 截面。绘图脚本显示 ``log10(phi)``，所以它更适合观察场的空间结构和
   rank 拼接是否连续，而不是读取绝对电势值。图中不应出现明显断裂条带、异常块状
   接缝或 ``NaN`` 区域；若出现这些现象，通常说明旧接口的边界处理、MPI 分块回收或
   HYPRE 调用链出现了问题。

   因为该测试只放了一个简单源项、没有解析解，图像的角色是 smoke-test 证据：
   它说明程序走完了、结果有限，并且不同 rank 的局部解能拼成一个连续全局场。

   .. rubric:: 参考结果

   当前参考运行在 4 个 MPI rank 上完成，输出 ``8192`` 个有限势函数值，
   ``min(phi)=0``、``max(phi)=4.885e-1``，未出现 ``NaN``。该测试没有解析真解，因此判断标准是：

   - 程序是否完整结束。
   - 输出是否全部有限。
   - 图像是否平滑连续。

   .. rubric:: 代表图

   .. figure:: ../../images/tests/001_poisson/test00/phi_zx.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-medium

      ``test00`` 的 ``x-z`` 截面势函数。场分布连续、无明显 rank 接缝，是 D01 旧接口仍可工作的直接证据。

.. container:: ap-lang ap-lang-en

   This page corresponds to ``tests/001_poisson/test00``. It is not an
   analytic-accuracy regression. Instead, it is a preservation smoke test for
   the legacy D01 Fortran-C-HYPRE path.

   .. rubric:: Test Role

   ``test00`` checks three practical points:

   - the legacy D01 interface still builds and links,
   - the irregular 4-rank box decomposition still solves,
   - the output field remains finite and visually continuous.

   .. rubric:: What This Test Is Doing

   ``test00`` calls the legacy ``sub_D01_hypre_3Dxyz_interface`` on a
   ``32 x 8 x 32`` Cartesian grid. The domain is split manually into four
   uneven MPI boxes. This decomposition is not meant to be a balanced
   production layout; it preserves coverage for an early D01 interface where
   irregular subdomains, internal MPI faces, and physical outer boundaries
   appear together.

   The source term is deliberately simple: only the local ``zmin`` layer on
   rank 0 is assigned ``rho=1`` and all other cells use ``rho=0``. The test
   therefore has no analytic reference solution and should not be read as an
   accuracy benchmark. Its purpose is to confirm that the legacy path still
   produces a finite, smooth potential field after mixed boundaries and
   multi-rank gather output.

   .. rubric:: Parameters

   .. list-table::
      :header-rows: 1
      :widths: 24 76

      * - Item
        - Setting
      * - Global grid
        - ``il0=(1,1,1)``, ``iu0=(32,8,32)``, i.e. ``32 x 8 x 32``.
      * - MPI size
        - Fixed at ``4`` ranks; ``run.sh`` uses ``mpirun -np 4``.
      * - Periodic direction
        - The legacy interface treats ``y`` as periodic; the explicit boundary array only describes ``x`` and ``z``.
      * - Local boxes
        - rank 0: ``x=9..24,z=1..16``; rank 1: ``x=1..8,z=17..32``; rank 2: ``x=9..24,z=17..32``; rank 3: ``x=25..32,z=17..32``.
      * - Boundary codes
        - ``bc`` is ordered as ``xmin,xmax,zmin,zmax``; ``0`` is internal, ``1`` is Dirichlet, and ``2`` is Neumann.
      * - Source term
        - Only the local ``zmin`` layer on rank 0 uses ``rho=1``; all other cells use ``0``.
      * - Solver tolerance
        - ``tolerance = 1.0e-6``.

   .. rubric:: How To Run

   Before running it, check:

   .. code-block:: bash

      which mpif90
      which mpicc
      which mpirun
      python3 -c "import numpy, matplotlib"

   Before building, update ``HYPRE_INC`` and ``HYPRE_LIB`` in ``make.sh`` so
   they match the local HYPRE installation. The directory then uses
   ``make.sh`` to build and ``run.sh`` to launch the 4-rank MPI run:

   .. code-block:: bash

      cd tests/001_poisson/test00
      bash clean.sh
      bash make.sh
      bash run.sh
      python3 plot.py

   .. rubric:: Coverage

   .. list-table::
      :header-rows: 1
      :widths: 24 30 46

      * - Test
        - Interface
        - What is checked
      * - ``test00``
        - ``sub_D01_hypre_3Dxyz_interface``
        - Verifies that the legacy D01 path still handles ``y`` periodicity, mixed ``x/z`` Dirichlet-Neumann conditions, and a 4-rank decomposition while returning a finite potential field.

   .. rubric:: Output Files

   .. list-table::
      :header-rows: 1
      :widths: 28 20 52

      * - File
        - Type
        - Notes
      * - ``phi.dat``
        - data
        - Flattened global potential on the ``32 x 8 x 32`` grid.
      * - ``phi_zx.png``
        - figure
        - Middle-``y`` ``log10(phi)`` view on the ``x-z`` slice.

   .. rubric:: How To Read The Figure

   ``phi_zx.png`` uses ``z`` index on the horizontal axis and ``x`` index on
   the vertical axis, with the middle ``y`` plane selected. The plotting script
   displays ``log10(phi)``, so the image is meant for checking field structure
   and rank stitching rather than reading absolute potential values. It should
   not contain obvious discontinuity bands, blocky rank seams, or ``NaN``
   regions; those would usually point to a boundary, gather, or HYPRE-call
   failure in the legacy path.

   Since this test has only a simple source term and no analytic solution, the
   figure is smoke-test evidence: the program completed, all values are finite,
   and the local rank fields combine into a continuous global field.

   .. rubric:: Reference Result

   The current reference run completes on 4 MPI ranks and writes ``8192``
   finite values with ``min(phi)=0`` and ``max(phi)=4.885e-1`` and no
   ``NaN`` entries. Since this test has no analytic solution, the acceptance
   criteria are:

   - successful completion,
   - finite output everywhere,
   - a smooth field image without obvious rank seams.

   .. rubric:: Representative Figure

   .. figure:: ../../images/tests/001_poisson/test00/phi_zx.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-medium

      ``test00`` ``x-z`` potential slice. The continuous field without visible
      rank seams is the intended regression signal for the legacy D01 path.
