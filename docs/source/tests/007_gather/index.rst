007_gather Tests
================

.. toctree::
   :maxdepth: 1
   :hidden:

   C01_gather_3Dxyz
   C02_gather_3Dxyz_bspline

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 范围

   ``tests/007_gather`` 覆盖 :doc:`C_Gather </rst_files/C_Gather>` 的 gather 例程。
   测试程序由 Fortran 写出确定性 CSV 数据，Python 脚本负责基准对比、误差统计和图片输出。

   .. list-table::
      :header-rows: 1
      :widths: 24 38 38

      * - 测试页
        - 覆盖接口
        - 判断方式
      * - :doc:`C01_gather_3Dxyz <C01_gather_3Dxyz>`
        - ``sub_C01_gather_3Dxyz``、``sub_C01_gather_3Dxyz_push``
        - 三线性精确解、光滑场收敛阶、``B=0`` 推进解析解。
      * - :doc:`C02_gather_3Dxyz_bspline <C02_gather_3Dxyz_bspline>`
        - ``sub_C02_gather_3Dxyz_bspline``
        - ``order=1`` 对 C01、常数场保持、线性场精确性。

   .. rubric:: 运行方式

   .. code-block:: bash

      cd tests/007_gather/C01_gather_3Dxyz
      bash run.sh

      cd ../C02_gather_3Dxyz_bspline
      bash run.sh

.. container:: ap-lang ap-lang-en

   .. rubric:: Scope

   ``tests/007_gather`` covers gather routines from
   :doc:`C_Gather </rst_files/C_Gather>`. The Fortran drivers write
   deterministic CSV data; Python scripts compare against references, compute
   errors, and save diagnostic figures.

   .. list-table::
      :header-rows: 1
      :widths: 24 38 38

      * - Test page
        - Interfaces
        - Check
      * - :doc:`C01_gather_3Dxyz <C01_gather_3Dxyz>`
        - ``sub_C01_gather_3Dxyz``, ``sub_C01_gather_3Dxyz_push``
        - Trilinear exact field, smooth-field convergence, and ``B=0`` push reference.
      * - :doc:`C02_gather_3Dxyz_bspline <C02_gather_3Dxyz_bspline>`
        - ``sub_C02_gather_3Dxyz_bspline``
        - ``order=1`` against C01, constant-field preservation, and linear-field exactness.

   .. rubric:: Run Commands

   .. code-block:: bash

      cd tests/007_gather/C01_gather_3Dxyz
      bash run.sh

      cd ../C02_gather_3Dxyz_bspline
      bash run.sh
