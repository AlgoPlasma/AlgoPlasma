J02 Tests
==========================================================================================

.. toctree::
   :maxdepth: 1
   :hidden:

   01 Local Processes <J02_tests>
   02 Assembled Transport <J02_solver_tests>
   03 Parallel Consistency <J02_parallel_tests>

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 从积分到输运解

   J02 将速度分布离散为一组沿不同方向运动的分布函数，并在空间网格上求解。
   测试沿着这条计算顺序展开：

   .. list-table::
      :header-rows: 1
      :widths: 22 40 38

      * - 阅读顺序
        - 计算内容
        - 参考与判据
      * - 01 Local Processes
        - 坐标生成几何量；求积生成速度权重；构造入口和壁面；积分得到单元矩阵；由指定分布重构场
        - 环形体积、速度圆盘面积、独立面求积、已知矩阵解及通量符号
      * - 02 Assembled Transport
        - 单次扫描求全域分布；反射迭代连接入射与出射；保正；完整入口输出密度和面通量
        - 非负角点、入口/出口/体损失收支、迭代收敛、输入幅值缩放
      * - 03 Parallel Consistency
        - 相同算例改变线程数或空间分区方式，重新调用扫描和完整入口
        - 同精度串行参考、交界面通量、全域收支、集体错误返回

   局部矩阵测试将输入系数固定，逐项核对积分值。
   扫描测试随后让单元通过迎风面相连，检查内部面抵消和全域收支。
   反射测试再把上一轮出射分布用于下一轮入射，检查该迭代能否收敛。

   .. rubric:: 哪些程序承担哪一层

   源码位于 ``tests/012_fluid/J02_neutral_sn_transport_2Drz/source_f90``。

   .. list-table::
      :header-rows: 1

      * - 程序
        - 说明位置
      * - ``test_J02_neutral_sn_transport_2Drz``、``test_J02_transport_units``、``test_J02_dg_faces``
        - 第一页：几何、入口、算子和重构
      * - ``test_J02_reflection_partial_inlet``
        - 第一页说明边界积分与归一化；第二页说明扫描与反射迭代
      * - ``test_J02_positivity``
        - 第一页说明局部常数回退；第二页说明尖锐入口的全域扫描
      * - ``test_J02_unified_sweep``、``test_J02_transport_entry``、``test_J02_review_regressions``
        - 第二页：完整调用、收支、收敛和错误处理
      * - ``test_J02_parallel``、``test_J02_mpi``
        - 第三页：线程、空间 MPI 和混合并行

   .. rubric:: 执行顺序

   先运行普通测试，随后运行两个并行脚本：

   .. code-block:: bash

      bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run.sh
      bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run_parallel.sh
      MPIEXEC_FLAGS=--oversubscribe bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run_mpi.sh

   普通脚本按可执行文件名顺序运行 9 个非 MPI 程序；
   其中 ``test_J02_parallel`` 使用串行构建。
   第二个脚本重新构建串行与 OpenMP 版本，第三个脚本构建 MPI 与混合版本。
   普通构建会重建 ``build``，所以并行检查放在后面，以保留其日志。

   2026-10-06，9 个普通程序、线程一致性和 76 次 MPI/混合启动全部通过。
   并行测试的网格、布局、精度和容差在第三页逐项列出。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Progression

   1. Verify geometry, velocity weights, inlet/wall data, local DG integrals and
      reconstruction using prescribed arrays and exact references.
   2. Connect cells through upwind sweeps, then add reflection iteration and positivity;
      check convergence and particle balance.
   3. Repeat the same small problems with OpenMP, spatial MPI and hybrid execution.

   The first page covers ``test_J02_neutral_sn_transport_2Drz``,
   ``test_J02_transport_units`` and ``test_J02_dg_faces``.
   The reflection/partial-inlet and positivity programs contain both local and assembled
   checks. Unified sweep, complete transport and scaling tests are described on the
   second page; parallel drivers on the third.

   .. code-block:: bash

      bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run.sh
      bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run_parallel.sh
      MPIEXEC_FLAGS=--oversubscribe bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run_mpi.sh

   The ordinary runner executes nine non-MPI programs in filename order.
   Run parallel scripts afterwards because the ordinary build recreates ``build``.
   All ordinary, OpenMP and 76 MPI/hybrid checks passed on 2026-10-06.
