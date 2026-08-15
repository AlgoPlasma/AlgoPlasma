008_mpi_exchange Tests
======================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. raw:: html

   <div class="ap-mpi-guide">

.. container:: ap-lang ap-lang-zh

   .. rubric:: 速览

   本页是 ``tests/008_mpi_exchange`` 的目录入口，用一个固定的 4-rank 小算例快速回归
   :doc:`H_MPI_Exchange </rst_files/H_MPI_Exchange>` 的三条核心通信语义：
   H01 的场量 halo 覆盖、H02 的粒子跨 rank 迁移，以及 H03 的 scatter 后边界密度累加。
   它偏向“先跑一遍确认没回归”，不是完整正确性证明，也不是 MPI 压力测试。

   .. list-table::
      :class: ap-table-compact
      :header-rows: 1
      :widths: 18 26 56

      * - 主题
        - 固定设置
        - 说明
      * - 目录角色
        - ``tests/008_mpi_exchange``
        - 目录级运行命令、输出文件和结果判读集中放在这里。
      * - 固定拓扑
        - ``4`` ranks, ``2 x 2 x 1``
        - x/y 有真实 MPI 邻居；z 不拆分，只测本地周期处理。
      * - 核心文件
        - ``test_H_MPI_Exchange.f90``、``run.sh``、``plot_mpi_exchange.py``
        - Fortran driver 负责断言，shell 负责运行，Python 负责诊断图。
      * - 通过判据
        - ``PASS: H_MPI_Exchange small MPI regression suite.``
        - ``.dat/.png`` 是诊断输出，不单独决定 pass/fail。
      * - 继续阅读
        - testing guide / ``README.md``
        - 手工期望值和编号粒子剧本看
          :doc:`MPI Exchange Testing Guide </rst_files/H_MPI_Exchange/mpi_exchange_testing_guide>`；
          本地脚本入口和清理方式看 ``tests/008_mpi_exchange/README.md``。

   .. rubric:: 覆盖与边界

   .. list-table::
      :class: ap-table-compact
      :header-rows: 1
      :widths: 20 30 26 24

      * - 模块
        - 当前 case
        - 当前断言
        - 仍未覆盖
      * - :doc:`H01_mpi_exchange_field </rst_files/H_MPI_Exchange/H01_mpi_exchange_field>`
        - 每个 rank 一个 ``4 x 4 x 3`` 有效场块，外包一层 ghost。
        - ``x/y`` halo 整张面逐点比较；``z`` 周期 ghost 抽查两个代表点。
        - ``domain_split(3)>1`` 的 z 向 MPI halo、更多拓扑、更厚 ghost。
      * - :doc:`H02_mpi_exchange_par </rst_files/H_MPI_Exchange/H02_mpi_exchange_par>`
        - 2 个 species、固定编号粒子集、全局盒子 ``8 x 8 x 4``。
        - 最终粒子数、ID 归属、吸收删除和 z 周期回绕。
        - 大粒子量压力、``nsmax>npm`` 重试路径、``npmax`` 溢出保护、更多拓扑。
      * - :doc:`H03_mpi_exchange_den </rst_files/H_MPI_Exchange/H03_mpi_exchange_den>`
        - 每个 rank 一个 ``3 x 3 x 2`` 有效密度块。
        - ``x/y`` 边界累加抽样中心线；``z`` 周期折叠抽查一个代表点。
        - 边界整面穷举、``domain_split(3)>1`` 的 z 向 MPI 累加。

   .. rubric:: 运行

   运行前建议先确认 ``which mpif90``、``which mpiexec`` 和
   ``python3 -c "import matplotlib"``。默认使用
   ``FC=mpif90``、``MPIEXEC=mpiexec``、``MPI_NP_FLAG=-n``、``NP=4``，
   构建带 ``-fdefault-real-8``；这是因为 H01/H03 当前以默认 ``real`` 数组配合
   ``MPI_DOUBLE`` 通信。若启动器还需要额外参数，可通过 ``MPIEXEC_ARGS`` 透传。
   Windows/PowerShell 环境可改用 ``run.ps1``。

   .. code-block:: bash

      cd tests/008_mpi_exchange
      bash run.sh
      bash make.sh
      BUILD=0 bash run.sh
      PLOT=0 bash run.sh
      FC=mpifort MPIEXEC=mpirun MPI_NP_FLAG=-np NP=4 bash run.sh

   .. rubric:: 输出与判读

   .. list-table::
      :class: ap-table-compact
      :header-rows: 1
      :widths: 34 32 34

      * - 文件
        - 字段 / 内容
        - 用途
      * - ``build/h01_field_faces.dat`` / ``build/h03_density_faces.dat``
        - ``rank case sample_i sample_j sample_k actual expected abs_error``
        - H01/H03 的代表样本点，不是全部断言的完整转储。
      * - ``build/h02_particle_exchange.dat``
        - ``rank species slot id x y z``
        - 交换后的本地粒子列表；``id`` 来自测试专用 ``par(4)``。
      * - ``fig/h01_field_exchange.png`` / ``fig/h03_density_exchange.png``
        - 样本 ``actual``、``expected`` 和 ``abs_error``
        - 快速看 H01/H03 样本是否贴合。
      * - ``fig/h02_particle_exchange.png``
        - 粒子最终归属散点图
        - 人工核对 face/edge/corner 迁移是否符合预期。

   - 先看标准输出里是否出现 ``PASS: H_MPI_Exchange small MPI regression suite.``。
   - 如果失败，Fortran 会打印 ``rank``、断言标签和 ``actual/expected`` 差异。
   - H03 需要特别注意：当前 ``h03_density_faces.dat`` 和配套图片来自第二轮
     “带 z 周期折叠”的样本状态，不是第一轮非周期 ``x/y`` 断言的完整导出。
   - 某些编译器或 MPI 启动器会额外打印 ``STOP 0``；若 PASS 已出现，不必把它当成失败信号。
   - 当前参考运行中，``h01_field_faces.dat`` 和 ``h03_density_faces.dat`` 的
     ``abs_error`` 应为 ``0``，H02 粒子归属应与 testing guide 给出的最终 ID 集合一致。

   .. rubric:: 拓扑与代表图

   .. raw:: html

      <div class="ap-home-panel ap-topology-panel">
        <div class="ap-topology-label">拓扑 / 逻辑坐标</div>
        <div class="ap-topology-grid">
          <span class="ap-topology-node"><strong>rank 2</strong><code>(1,2,1)</code></span>
          <span class="ap-topology-node"><strong>rank 3</strong><code>(2,2,1)</code></span>
          <span class="ap-topology-node"><strong>rank 0</strong><code>(1,1,1)</code></span>
          <span class="ap-topology-node"><strong>rank 1</strong><code>(2,1,1)</code></span>
        </div>
      </div>

   .. list-table::
      :class: ap-table-compact
      :widths: 14 86

      * - **H01**
        - .. image:: ../../images/tests/008_mpi_exchange/h01_field_exchange.png
             :width: 100%
             :alt: H01 field exchange diagnostic plot

          halo 样本与邻居面 ``expected`` 的对比。
      * - **H02**
        - .. image:: ../../images/tests/008_mpi_exchange/h02_particle_exchange.png
             :width: 100%
             :alt: H02 particle exchange diagnostic plot

          粒子最终归属和 face/edge/corner 迁移结果。
      * - **H03**
        - .. image:: ../../images/tests/008_mpi_exchange/h03_density_exchange.png
             :width: 100%
             :alt: H03 density exchange diagnostic plot

          边界累加与 z 周期折叠后的代表样本状态。

.. container:: ap-lang ap-lang-en

   .. rubric:: Overview

   This page is the directory entry for ``tests/008_mpi_exchange``. It uses one
   fixed 4-rank case to quickly regress three core
   :doc:`H_MPI_Exchange </rst_files/H_MPI_Exchange>` semantics: H01 field-halo
   overwrite, H02 particle migration across ranks, and H03 post-scatter density
   boundary accumulation. It is meant to answer "did the small MPI regression
   break?" rather than provide a full correctness proof or an MPI stress test.

   .. list-table::
      :class: ap-table-compact
      :header-rows: 1
      :widths: 18 26 56

      * - Topic
        - Fixed setup
        - Meaning
      * - Page role
        - ``tests/008_mpi_exchange``
        - Directory-level run commands, output files, and result interpretation
          are collected here.
      * - Fixed topology
        - ``4`` ranks, ``2 x 2 x 1``
        - x/y have real MPI neighbors; z stays unsplit and only exercises local
          periodic handling.
      * - Core files
        - ``test_H_MPI_Exchange.f90``, ``run.sh``, ``plot_mpi_exchange.py``
        - The Fortran driver asserts behavior, shell scripts run the case, and
          Python writes diagnostic figures.
      * - Pass criterion
        - ``PASS: H_MPI_Exchange small MPI regression suite.``
        - ``.dat/.png`` files are diagnostics, not standalone pass/fail proof.
      * - Read next
        - testing guide / ``README.md``
        - Use the
          :doc:`MPI Exchange Testing Guide </rst_files/H_MPI_Exchange/mpi_exchange_testing_guide>`
          for hand-derived expectations and the ID-labeled particle script, and
          ``tests/008_mpi_exchange/README.md`` for the repo-local quick-start
          note and cleanup entry points.

   .. rubric:: Coverage And Limits

   .. list-table::
      :class: ap-table-compact
      :header-rows: 1
      :widths: 20 30 26 24

      * - Module
        - Current case
        - Current assertions
        - Still not covered
      * - :doc:`H01_mpi_exchange_field </rst_files/H_MPI_Exchange/H01_mpi_exchange_field>`
        - One ``4 x 4 x 3`` effective field block per rank with one ghost layer.
        - ``x/y`` halos are checked pointwise over the full face; z-periodic
          ghosts are sampled at two representative points.
        - z-direction MPI halos with ``domain_split(3)>1``, more topologies, and
          thicker ghost layers.
      * - :doc:`H02_mpi_exchange_par </rst_files/H_MPI_Exchange/H02_mpi_exchange_par>`
        - Two species, a fixed ID-labeled particle set, and a global
          ``8 x 8 x 4`` box.
        - Final particle counts, ID ownership, absorbing removal, and local
          z-periodic wrap.
        - Large-particle pressure, the ``nsmax>npm`` retry path,
          ``npmax`` overflow protection, and more topologies.
      * - :doc:`H03_mpi_exchange_den </rst_files/H_MPI_Exchange/H03_mpi_exchange_den>`
        - One ``3 x 3 x 2`` effective density block per rank.
        - ``x/y`` accumulation is sampled on a center line; z-periodic folding
          is checked at one representative point.
        - Full-face proofs and z-direction MPI accumulation with
          ``domain_split(3)>1``.

   .. rubric:: Running

   Before running, it is useful to confirm ``which mpif90``,
   ``which mpiexec``, and ``python3 -c "import matplotlib"``. The defaults are
   ``FC=mpif90``, ``MPIEXEC=mpiexec``, ``MPI_NP_FLAG=-n``, and ``NP=4``. The
   build keeps ``-fdefault-real-8`` because H01/H03 currently exchange default
   ``real`` arrays with ``MPI_DOUBLE``. Extra launcher options can be passed via
   ``MPIEXEC_ARGS``. On Windows/PowerShell, use ``run.ps1`` instead.

   .. code-block:: bash

      cd tests/008_mpi_exchange
      bash run.sh
      bash make.sh
      BUILD=0 bash run.sh
      PLOT=0 bash run.sh
      FC=mpifort MPIEXEC=mpirun MPI_NP_FLAG=-np NP=4 bash run.sh

   .. rubric:: Outputs And Reading Them

   .. list-table::
      :class: ap-table-compact
      :header-rows: 1
      :widths: 34 32 34

      * - File
        - Fields / content
        - Use
      * - ``build/h01_field_faces.dat`` / ``build/h03_density_faces.dat``
        - ``rank case sample_i sample_j sample_k actual expected abs_error``
        - Representative H01/H03 sample points, not a dump of every assertion.
      * - ``build/h02_particle_exchange.dat``
        - ``rank species slot id x y z``
        - Post-exchange local particle list; ``id`` comes from test-only
          ``par(4)``.
      * - ``fig/h01_field_exchange.png`` / ``fig/h03_density_exchange.png``
        - Sample ``actual``, ``expected``, and ``abs_error``
        - Fast visual check for H01/H03 sample agreement.
      * - ``fig/h02_particle_exchange.png``
        - Final particle-ownership scatter plot
        - Manual check of face/edge/corner migration.

   - Start by checking whether stdout contains
     ``PASS: H_MPI_Exchange small MPI regression suite.``.
   - On failure, the Fortran test prints the failing ``rank``, assertion label,
     and ``actual/expected`` difference.
   - H03 needs one extra note: the current ``h03_density_faces.dat`` and its
     figure come from the second pass with z-periodic folding enabled, not from
     the full first-pass nonperiodic ``x/y`` assertion set.
   - Some compilers or MPI launchers may also print ``STOP 0``; if the PASS
     line is present, do not treat that as a failure marker.
   - In the current reference run, ``abs_error`` in both
     ``h01_field_faces.dat`` and ``h03_density_faces.dat`` should be ``0``, and
     H02 particle ownership should match the final ID sets listed in the
     testing guide.

   .. rubric:: Topology And Representative Figures

   .. raw:: html

      <div class="ap-home-panel ap-topology-panel">
        <div class="ap-topology-label">Topology / Logical Coordinates</div>
        <div class="ap-topology-grid">
          <span class="ap-topology-node"><strong>rank 2</strong><code>(1,2,1)</code></span>
          <span class="ap-topology-node"><strong>rank 3</strong><code>(2,2,1)</code></span>
          <span class="ap-topology-node"><strong>rank 0</strong><code>(1,1,1)</code></span>
          <span class="ap-topology-node"><strong>rank 1</strong><code>(2,1,1)</code></span>
        </div>
      </div>

   .. list-table::
      :class: ap-table-compact
      :widths: 14 86

      * - **H01**
        - .. image:: ../../images/tests/008_mpi_exchange/h01_field_exchange.png
             :width: 100%
             :alt: H01 field exchange diagnostic plot

          Halo samples against neighbor-face ``expected`` values.
      * - **H02**
        - .. image:: ../../images/tests/008_mpi_exchange/h02_particle_exchange.png
             :width: 100%
             :alt: H02 particle exchange diagnostic plot

          Final particle ownership and face/edge/corner migration.
      * - **H03**
        - .. image:: ../../images/tests/008_mpi_exchange/h03_density_exchange.png
             :width: 100%
             :alt: H03 density exchange diagnostic plot

          Boundary accumulation plus z-periodic folding samples.

.. raw:: html

   </div>
