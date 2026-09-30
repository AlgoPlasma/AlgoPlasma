009_collision
=============

.. toctree::
   :maxdepth: 1

   G02_collision_box
   G02_csv_templates

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: G01 MCC 截面表加载器回归测试

   ``tests/009_collision/G01_MCC`` 检查
   :doc:`sub_G01_load_cross_section </rst_files/G_Collision/G01_MCC/sub_G01_load_cross_section>`
   的数组边界行为。测试数据是合成的两列数值，不表示真实碰撞截面，也不验证完整
   MCC 碰撞物理。

   .. list-table:: 测试内容
      :header-rows: 1
      :widths: 30 70

      * - 输入
        - 验证内容
      * - ``cross_section_exact_nmax.dat``
        - 恰好包含 ``Nmax`` 行；检查数值完整载入且文件结尾探测不越界。
      * - ``cross_section_too_many_rows.dat``
        - 包含 ``Nmax + 1`` 行；检查加载器输出诊断、以非零状态退出，并且
          AddressSanitizer 不报告数组越界。

   从仓库根目录运行：

   .. code-block:: bash

      bash tests/009_collision/G01_MCC/clean.sh
      bash tests/009_collision/G01_MCC/run.sh

   成功时会打印两条 ``PASS`` 信息。完成后运行：

   .. code-block:: bash

      bash tests/009_collision/G01_MCC/clean.sh

   清理命令只删除该测试目录下的 ``build/``。

   .. rubric:: G02 零维碰撞盒与回归测试

   库的 C++ 源码和头文件直接位于 ``G_Collision/G02_MCC_network/``，
   Fortran 接口位于其 ``fortran_interface/``。本测试目录中的 ``fortran/`` 存放测试主程序。
   ``templates/`` 提供 CSV 模板，``tools/validate_model.cpp`` 是模型检查工具；
   详见 :doc:`CSV 模板与检查 <G02_csv_templates>`。

   初学者先看 :ref:`碰撞盒教程 <g02-collision-box-zh>`：
   它观察热粒子与冷气体的碰撞，并解释“零维”、温度与整体运动，以及怎样读结果。
   下面的回归测试用于检查修改代码后原有功能是否仍正常。

   ``tests/009_collision/G02_MCC_network`` 独立构建 G02，验证模型包、插值、
   碰撞算法、批量接口及 C/Fortran 适配层；启用 MPI/OpenMP 时还运行并行测试。
   :doc:`零维碰撞盒 <G02_collision_box>`
   使用合成等质量弹性模型，检查总动量与能量收支、随机碰撞次数、平均速度随时间的变化和末态分布，
   并包含零密度、零时间步等对照。检查失败时测试返回非零状态。

   从仓库根目录运行完整默认测试及手动算例：

   .. code-block:: bash

      bash tests/009_collision/G02_MCC_network/run.sh
      bash tests/009_collision/G02_MCC_network/examples/collision_box/run.sh

   默认测试需要 C/C++20、Fortran 编译器和 CMake 3.20 或以上。
   CTest 是自动逐项运行测试的工具；默认脚本还检查内存越界等程序错误。
   完成时应看到 ``100% tests passed``；手动算例应打印 ``collision_box: PASS``。
   算例的 ``checks.csv`` 中 ``true`` 表示该项通过，``false`` 表示失败。

   算例将 CSV 和图片写入其已忽略的 ``results/`` 目录。数据仅供软件验证，
   不得用于科研结论；参数与判据见 :ref:`零维碰撞盒教程 <g02-collision-box-zh>`。

.. container:: ap-lang ap-lang-en

   .. rubric:: G01 MCC Cross-Section Loader Regression Test

   ``tests/009_collision/G01_MCC`` checks the array-bound behavior of
   :doc:`sub_G01_load_cross_section </rst_files/G_Collision/G01_MCC/sub_G01_load_cross_section>`.
   The two-column inputs are synthetic: they are not physical cross sections,
   and this test does not validate the complete MCC collision model.

   .. list-table:: Test Cases
      :header-rows: 1
      :widths: 30 70

      * - Input
        - What it verifies
      * - ``cross_section_exact_nmax.dat``
        - Contains exactly ``Nmax`` rows; checks value preservation and a safe
          end-of-file probe.
      * - ``cross_section_too_many_rows.dat``
        - Contains ``Nmax + 1`` rows; checks for a diagnostic, a nonzero exit
          status, and no AddressSanitizer array-bound report.

   Run from the repository root:

   .. code-block:: bash

      bash tests/009_collision/G01_MCC/clean.sh
      bash tests/009_collision/G01_MCC/run.sh

   A successful run prints two ``PASS`` messages. Clean the generated executable
   files with:

   .. code-block:: bash

      bash tests/009_collision/G01_MCC/clean.sh

   The clean script removes only this test directory's ``build/`` directory.

   .. rubric:: G02 Collision-Box and Regression Tests

   Library C++ sources and headers are directly in ``G_Collision/G02_MCC_network/``;
   its ``fortran_interface/`` contains the Fortran interface. The test directory’s ``fortran/`` contains test programs.
   ``templates/`` holds CSV templates, and ``tools/validate_model.cpp`` is the model checker;
   see :doc:`CSV templates and checking <G02_csv_templates>`.

   Start with the :ref:`collision-box tutorial <g02-collision-box-en>` for hot particles in a cold gas,
   zero-dimensional modeling, temperature versus drift, and reading the output.
   Regression tests check that existing behavior still works after code changes.

   ``tests/009_collision/G02_MCC_network`` independently builds G02 and tests
   model packages, interpolation, collision algorithms, batching, C/Fortran
   adapters and optional MPI/OpenMP paths. The zero-dimensional collision box
   in :doc:`G02_collision_box <G02_collision_box>` uses a
   synthetic equal-mass elastic model. It checks conservation, Poisson collision
   counts, the time evolution of mean velocities, and the final distribution, with zero-density
   and zero-time-step controls. A failed check returns a nonzero status.

   From the repository root, run the default suite and the manual example:

   .. code-block:: bash

      bash tests/009_collision/G02_MCC_network/run.sh
      bash tests/009_collision/G02_MCC_network/examples/collision_box/run.sh

   The default tests need C/C++20 and Fortran compilers, plus CMake 3.20 or newer.
   CTest runs each test automatically; the default script also checks memory errors.
   Look for ``100% tests passed`` and, for the manual example, ``collision_box: PASS``.
   In its ``checks.csv``, ``true`` means a check passed and ``false`` means it failed.

   The example writes CSV files and plots to its ignored ``results/`` directory.
   Its data are for software validation only, not scientific conclusions; see
   the :ref:`collision-box tutorial <g02-collision-box-en>` for parameters and pass criteria.
