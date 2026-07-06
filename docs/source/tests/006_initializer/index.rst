006_initializer Tests
=====================

.. toctree::
   :maxdepth: 1
   :hidden:

   I01_par_distribute

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   本节整理 ``tests/006_initializer`` 中的 I_Initializer 测试，当前包含两组内容：
   ``I01_par_distribute`` 的纯 Fortran 单元测试，以及
   ``I02_par_init_and_load`` 的 Python 功能验证脚本。

   .. list-table:: 当前测试页面
      :header-rows: 1
      :widths: 10 38 52

      * - ID
        - 测试页面
        - 说明
      * - I01
        - :doc:`I01_par_distribute 测试 <I01_par_distribute>`
        - 验证粒子数、空间位置公式、零热速度退化和 Maxwell 速度分布统计，共 4 个 case。
      * - I02
        - 暂无独立页面
        - 依赖 MPI，无法独立运行 Fortran 单元测试。
          ``source_py/test_filter.py`` 以纯 Python 验证二进制文件格式和域过滤逻辑，
          详见下方说明。

   静态图片来自一次参考运行，并保存到 ``docs/source/images/tests/006_initializer``。

   .. rubric:: I02 Python 验证脚本

   ``sub_I02_load_init_particles_bin`` 从文件读取粒子并过滤掉不属于本 rank 域的粒子，
   但它依赖 MPI，没法单独跑 Fortran 测试。
   ``tests/006_initializer/I02_par_init_and_load/source_py/test_filter.py``
   用纯 Python 验证其中两件核心的事：

   - **二进制格式兼容性**：用 ``numpy.float64`` 按 Fortran 的 stream 格式写一个粒子文件
     （``access='stream'``，每粒子 6 个 float64：``x,y,z,vx,vy,vz``），
     再读回来比对，确认 Python 和 Fortran 读写同一套格式。
   - 域过滤逻辑：Fortran 的过滤条件是 ``il(d)-1 ≤ x(d) < iu(d)`` （下界含、上界不含）。
     Python 里重现这个条件，覆盖四种情况：全部在域内、全部在域外、一部分在域内、
     以及粒子恰好落在边界上。

   .. code-block:: bash

      cd tests/006_initializer/I02_par_init_and_load
      python3 source_py/test_filter.py

.. container:: ap-lang ap-lang-en

   This section documents the I_Initializer tests under
   ``tests/006_initializer``. It contains a pure-Fortran unit test suite for
   ``I01_par_distribute`` and a Python validation script for
   ``I02_par_init_and_load``.

   .. list-table:: Available test pages
      :header-rows: 1
      :widths: 10 38 52

      * - ID
        - Test page
        - Notes
      * - I01
        - :doc:`I01_par_distribute tests <I01_par_distribute>`
        - Verifies particle count, spatial positions, zero thermal speed, and
          Maxwellian velocity statistics — 4 cases.
      * - I02
        - No dedicated page yet
        - Depends on MPI; a standalone Fortran unit test is not practical.
          ``source_py/test_filter.py`` validates the binary file format and
          domain-filter logic in pure Python; see the section below.

   The static figures are copied from one reference run and stored under
   ``docs/source/images/tests/006_initializer``.

   .. rubric:: I02 Python Validation Script

   ``sub_I02_load_init_particles_bin`` reads particles from a file and filters
   out those outside the local MPI rank's domain. Because it requires MPI it
   cannot be tested as a standalone Fortran unit. Instead,
   ``tests/006_initializer/I02_par_init_and_load/source_py/test_filter.py``
   verifies two core behaviours in pure Python:

   - **Binary format compatibility**: writes a particle file in Fortran stream
     format (``access='stream'``, 6 ``float64`` values ``x,y,z,vx,vy,vz`` per
     particle) using ``numpy``, then reads it back and compares, confirming
     Python and Fortran share the same binary layout.
   - **Domain-filter logic**: replicates the Fortran condition
     ``il(d)-1 ≤ x(d) < iu(d)`` (lower bound inclusive, upper bound exclusive)
     and tests four scenarios: all inside, all outside, a mix of both, and
     particles sitting exactly on the boundary.

   .. code-block:: bash

      cd tests/006_initializer/I02_par_init_and_load
      python3 source_py/test_filter.py
