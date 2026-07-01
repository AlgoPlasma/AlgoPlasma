003_F_IO Tests
==============

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   本节整理 ``tests/003_F_IO`` 中的 F_IO 回归测试。这个测试不生成图片，而是用
   “写入 -> MPI 同步 -> 读取 -> 逐元素比较”的方式验证粒子数据和场数据的 I/O
   路径。任意比较失败都会触发 ``MPI_ABORT``，因此它是一个自检查测试。

   相关接口文档见 :doc:`F_IO API 说明 </rst_files/F_IO>`。

   .. rubric:: 运行环境

   测试依赖 MPI、HDF5 Fortran 绑定以及 ``h5pfc`` 编译包装器。运行前可先确认：

   .. code-block:: bash

      which mpirun
      which h5pfc
      h5pfc -show

   当前测试脚本会用 ``h5pfc`` 编译，并显式定义 ``USE_HDF5=1``，因为
   ``F01`` 和 ``F02`` 的 HDF5 子程序在 module wrapper 中受这个预处理宏控制。

   .. code-block:: bash

      cd tests/003_F_IO
      bash clean.sh
      bash makerun.sh

   ``makerun.sh`` 默认用 ``mpirun -n 4 ./test_F_IO`` 运行。不同机器上的 MPI
   启动参数可能不同；如果不确定本机 MPI/HDF5 环境，应先询问维护者或用户再调整脚本。

   .. rubric:: 测试覆盖范围

   .. list-table::
      :header-rows: 1
      :widths: 24 32 44

      * - 场景
        - 被测接口
        - 验证内容
      * - 粒子低层 I/O
        - ``sub_F02_par_output_*``、``sub_F01_par_load_*``
        - 直接测试 ``dat``、``bin``、``h5`` 三种格式的逐 rank 粒子文件写入和读回。
      * - 粒子 dispatcher
        - ``sub_F02_par_output``、``sub_F01_par_load``
        - 用 ``dat``、``bin``、``h5`` 标签测试统一入口能否分发到正确格式。
      * - 未知标签 fallback
        - 粒子 dispatcher
        - 故意传入 ``badtag``，确认 dispatcher 输出提示并回退到 ``dat`` 路径。
      * - 3D cell-centered 场
        - ``sub_F04_field_output_3d_*``、``sub_F03_field_load_3d_*``
        - 对 ``il=(1,1,1)``、``iu=(4,3,2)`` 的 3D 局部场测试 ``dat`` 和 ``bin`` round-trip。
      * - 1D packed 场
        - ``sub_F04_field_output_1d_*``、``sub_F03_field_load_1d_*``
        - 验证一维打包场的 ``dat`` 和 ``bin`` I/O；测试程序按 ``k, j, i`` 循环且 ``i`` 最快变化。
      * - grid-defined 场输出
        - ``sub_F04_field_output_3d_grid_*``、``sub_F03_field_load_3d_*``
        - 将节点场 ``[il-1:iu]`` 通过 8 点平均写成 cell-centered 场，再读回并与期望值比较。

   .. rubric:: 输出文件

   每个 MPI rank 写自己的文件，文件名遵循：

   .. code-block:: text

      label/label_IIIIIIIIII_RRRRR.ext

   其中 ``IIIIIIIIII`` 是 10 位 iteration 编号，``RRRRR`` 是 5 位 MPI rank 编号。
   一次 4-rank 参考运行会产生 52 个测试文件：

   .. list-table::
      :header-rows: 1
      :widths: 30 20 50

      * - 类别
        - 文件数
        - 目录示例
      * - 粒子低层 I/O
        - 12
        - ``T_par_dat_low``、``T_par_bin_low``、``T_par_h5_low``
      * - 粒子 dispatcher
        - 12
        - ``T_par_dat_dis``、``T_par_bin_dis``、``T_par_h5_dis``
      * - 未知标签 fallback
        - 4
        - ``T_par_badtag``
      * - 3D 场
        - 8
        - ``T_F3_dat``、``T_F3_bin``
      * - 1D packed 场
        - 8
        - ``T_F1_dat``、``T_F1_bin``
      * - grid-defined 场
        - 8
        - ``T_Fgrid_dat``、``T_Fgrid_bin``

   这些输出是临时验证产物，不需要纳入文档图片目录；测试完成后可用
   ``bash clean.sh`` 删除。

   .. rubric:: 参考运行结果

   本次参考运行在 4 个 MPI rank 上通过，核心输出如下：

   .. code-block:: text

      Running F_IO tests with MPI ranks = 4
      PASS: par dat low-level
      PASS: par bin low-level
      PASS: par h5 low-level
      PASS: par dat dispatcher
      PASS: par bin dispatcher
      PASS: par h5 dispatcher
      PASS: par unknown-tag fallback
      PASS: field 3d dat
      PASS: field 3d bin
      PASS: field 1d dat
      PASS: field 1d bin
      PASS: field 3d_grid dat
      PASS: field 3d_grid bin
      ALL TESTS PASSED.

   运行中会看到多行 ``ERROR: unknown particle ... tag = "badtag", switch to "dat".``。
   这是测试故意触发的 fallback 路径；只要后面出现 ``PASS: par unknown-tag fallback``，
   就表示该路径按预期工作。

.. container:: ap-lang ap-lang-en

   This section documents the F_IO regression test under ``tests/003_F_IO``.
   The test does not generate figures. Instead, it uses a
   "write -> MPI barrier -> read -> element-wise compare" round trip to verify
   particle and field I/O paths. Any mismatch calls ``MPI_ABORT``, so the test
   is self-checking.

   See :doc:`the F_IO API documentation </rst_files/F_IO>` for the related
   routines.

   .. rubric:: Runtime Environment

   The test requires MPI, the HDF5 Fortran bindings, and the ``h5pfc`` compiler
   wrapper. Before running it, check:

   .. code-block:: bash

      which mpirun
      which h5pfc
      h5pfc -show

   The script compiles with ``h5pfc`` and defines ``USE_HDF5=1`` explicitly,
   because the HDF5 implementations in the ``F01`` and ``F02`` module wrappers
   are guarded by that preprocessor macro.

   .. code-block:: bash

      cd tests/003_F_IO
      bash clean.sh
      bash makerun.sh

   ``makerun.sh`` runs ``mpirun -n 4 ./test_F_IO`` by default. MPI launch
   options may differ across machines; if the local MPI/HDF5 setup is unknown,
   ask the maintainer or user before editing the script.

   .. rubric:: Test Coverage

   .. list-table::
      :header-rows: 1
      :widths: 24 32 44

      * - Scenario
        - Interfaces
        - What is checked
      * - Particle low-level I/O
        - ``sub_F02_par_output_*``, ``sub_F01_par_load_*``
        - Direct per-rank particle write/read checks for ``dat``, ``bin``, and ``h5``.
      * - Particle dispatcher
        - ``sub_F02_par_output``, ``sub_F01_par_load``
        - Tag-based dispatch through the common ``dat``, ``bin``, and ``h5`` entry points.
      * - Unknown-tag fallback
        - Particle dispatchers
        - Intentional ``badtag`` input confirms that dispatchers warn and fall back to ``dat``.
      * - 3D cell-centered field
        - ``sub_F04_field_output_3d_*``, ``sub_F03_field_load_3d_*``
        - ``dat`` and ``bin`` round trips on a local 3D block with ``il=(1,1,1)`` and ``iu=(4,3,2)``.
      * - 1D packed field
        - ``sub_F04_field_output_1d_*``, ``sub_F03_field_load_1d_*``
        - ``dat`` and ``bin`` I/O for packed fields; the test packs in ``k, j, i`` order with ``i`` varying fastest.
      * - Grid-defined field output
        - ``sub_F04_field_output_3d_grid_*``, ``sub_F03_field_load_3d_*``
        - Node-defined values on ``[il-1:iu]`` are written as cell-centered fields via an 8-point average, then read back and compared.

   .. rubric:: Output Files

   Each MPI rank writes its own file using this naming convention:

   .. code-block:: text

      label/label_IIIIIIIIII_RRRRR.ext

   Here ``IIIIIIIIII`` is the 10-digit iteration number and ``RRRRR`` is the
   5-digit MPI rank. A 4-rank reference run produces 52 test files:

   .. list-table::
      :header-rows: 1
      :widths: 30 20 50

      * - Category
        - Files
        - Example directories
      * - Particle low-level I/O
        - 12
        - ``T_par_dat_low``, ``T_par_bin_low``, ``T_par_h5_low``
      * - Particle dispatcher
        - 12
        - ``T_par_dat_dis``, ``T_par_bin_dis``, ``T_par_h5_dis``
      * - Unknown-tag fallback
        - 4
        - ``T_par_badtag``
      * - 3D field
        - 8
        - ``T_F3_dat``, ``T_F3_bin``
      * - 1D packed field
        - 8
        - ``T_F1_dat``, ``T_F1_bin``
      * - Grid-defined field
        - 8
        - ``T_Fgrid_dat``, ``T_Fgrid_bin``

   These outputs are temporary validation artifacts rather than documentation
   images. Remove them with ``bash clean.sh`` after the run if they are no
   longer needed.

   .. rubric:: Reference Result

   The reference run passed on 4 MPI ranks:

   .. code-block:: text

      Running F_IO tests with MPI ranks = 4
      PASS: par dat low-level
      PASS: par bin low-level
      PASS: par h5 low-level
      PASS: par dat dispatcher
      PASS: par bin dispatcher
      PASS: par h5 dispatcher
      PASS: par unknown-tag fallback
      PASS: field 3d dat
      PASS: field 3d bin
      PASS: field 1d dat
      PASS: field 1d bin
      PASS: field 3d_grid dat
      PASS: field 3d_grid bin
      ALL TESTS PASSED.

   Several lines of
   ``ERROR: unknown particle ... tag = "badtag", switch to "dat".`` are expected
   during the run. They are emitted by the intentional fallback case; the path
   is considered valid when ``PASS: par unknown-tag fallback`` appears.
