009_collision
=============

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
