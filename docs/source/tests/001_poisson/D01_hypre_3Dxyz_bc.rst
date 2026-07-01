D01_hypre_3Dxyz_bc Tests
========================

.. raw:: html

   <div class="pmsl-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="pmsl-lang-button" data-pmsl-set-lang="zh">中文</button>
     <button type="button" class="pmsl-lang-button" data-pmsl-set-lang="en">English</button>
   </div>

.. container:: pmsl-lang pmsl-lang-zh

   本页对应 ``tests/001_poisson/test00``。它不是解析精度回归，而是 D01 旧版
   Fortran-C-HYPRE 路径的保留性 smoke test，用来确认最早一套 Cartesian 接口仍能完整跑通。

   .. rubric:: 测试定位

   ``test00`` 主要检查三件事：

   - 旧版 D01 接口是否还能成功编译和链接。
   - 4-rank 下非规则 box 分块是否还能正确组装并求解。
   - 输出的势函数场是否有限、连续、无明显 rank 拼接缝。

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
        - 中间 ``y`` 截面的 ``x-z`` 势函数图。

   .. rubric:: 参考结果

   当前参考运行在 4 个 MPI rank 上完成，输出 ``8192`` 个有限势函数值，
   ``min(phi)=0``、``max(phi)=4.885e-1``，未出现 ``NaN``。该测试没有解析真解，因此判断标准是：

   - 程序是否完整结束。
   - 输出是否全部有限。
   - 图像是否平滑连续。

   .. rubric:: 代表图

   .. figure:: ../../images/tests/001_poisson/test00/phi_zx.png
      :align: center
      :figclass: pmsl-figure-equal-height

      ``test00`` 的 ``x-z`` 截面势函数。场分布连续、无明显 rank 接缝，是 D01 旧接口仍可工作的直接证据。

.. container:: pmsl-lang pmsl-lang-en

   This page corresponds to ``tests/001_poisson/test00``. It is not an
   analytic-accuracy regression. Instead, it is a preservation smoke test for
   the legacy D01 Fortran-C-HYPRE path.

   .. rubric:: Test Role

   ``test00`` checks three practical points:

   - the legacy D01 interface still builds and links,
   - the irregular 4-rank box decomposition still solves,
   - the output field remains finite and visually continuous.

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
        - ``x-z`` potential slice at the mid-``y`` plane.

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
      :figclass: pmsl-figure-equal-height

      ``test00`` ``x-z`` potential slice. The continuous field without visible
      rank seams is the intended regression signal for the legacy D01 path.
