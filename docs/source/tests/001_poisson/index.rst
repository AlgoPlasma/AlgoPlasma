001_poisson Tests
=================

.. toctree::
   :maxdepth: 1
   :hidden:

   D01_hypre_3Dxyz_bc
   D02_hypre_3Dxyz_bc
   D03_hypre_3Draz_uniform
   D04_hypre_3Draz_nonuniform

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   本节整理 ``tests/001_poisson`` 下的 Poisson 回归测试。页面目标不是重复算法/API 文档，而是回答三件事：

   1. 当前每组测试实际在跑什么。
   2. 它覆盖了哪些代码路径。
   3. 应该看哪些输出和图片判断测试是否正常。

   .. rubric:: 阅读顺序

   建议按“从旧接口到新接口、从 Cartesian 到柱坐标、从单机到 MPI、从边界回归到解析/MMS 对比”的顺序阅读：

   .. list-table:: 页面分工
      :header-rows: 1
      :widths: 14 34 52

      * - 页面
        - 对应测试
        - 说明
      * - :doc:`D01_hypre_3Dxyz_bc <D01_hypre_3Dxyz_bc>`
        - ``test00``
        - 旧版 Cartesian D01 接口的 4-rank smoke test，用于保留最早一条完整的 Fortran-C-HYPRE 调用链。
      * - :doc:`D02_hypre_3Dxyz_bc <D02_hypre_3Dxyz_bc>`
        - ``test01``、``test02``
        - Cartesian D02 的多 rank 边界路径与解析边界回归测试。
      * - :doc:`D03_hypre_3Draz_uniform <D03_hypre_3Draz_uniform>`
        - ``test03``、``test04``
        - 均匀柱坐标 D03 的单 rank 与 MPI 边界条件测试。
      * - :doc:`D04_hypre_3Draz_nonuniform <D04_hypre_3Draz_nonuniform>`
        - ``test05``、``test06``、``test07``
        - 非均匀柱坐标 D04 的单 rank 边界条件回归、8-rank 解析/MPI 回归，以及 D03-D04 MMS 对比。

   .. rubric:: 使用约定

   四个子页面统一采用同一结构：

   - `测试定位`：先说明测试的角色和目录边界。
   - `这个测试在做什么`：用普通读者能跟上的语言解释测试问题和判据。
   - `参数设置`：列出网格、MPI、边界、解析解、容差等关键参数。
   - `运行方式`：给出脚本入口和默认 MPI 配置。
   - `覆盖内容`：按测试目录解释覆盖到的接口和行为。
   - `输出文件`：说明判断结果要看哪些数据和图片。
   - `图片如何阅读`：说明图中横纵轴、误差图含义，以及哪些现象代表测试异常。
   - `参考结果`：列出当前可对照的误差或输出范围。
   - `代表图`：保留一组风格一致的参考图，便于快速人工比对。

   所有测试在编译前都应先检查脚本中的 ``HYPRE_INC`` 与 ``HYPRE_LIB``。如果本机 HYPRE 安装路径不同，必须先修改这些变量，再执行 ``make.sh``、``run.sh`` 或其他编译/运行脚本。


.. container:: ap-lang ap-lang-en

   This section documents the Poisson regression tests under
   ``tests/001_poisson``. These pages do not repeat the algorithm/API notes.
   Instead, each page answers three practical questions:

   1. What the current test actually runs.
   2. Which code paths it covers.
   3. Which outputs and figures should be checked.

   .. rubric:: Reading Order

   A useful order is: legacy to current interface, Cartesian to cylindrical,
   single-rank to MPI, and boundary regression to analytic/MMS comparison.

   .. list-table:: Page roles
      :header-rows: 1
      :widths: 14 34 52

      * - Page
        - Tests
        - Notes
      * - :doc:`D01_hypre_3Dxyz_bc <D01_hypre_3Dxyz_bc>`
        - ``test00``
        - Legacy Cartesian D01 4-rank smoke test that preserves the earliest complete Fortran-C-HYPRE path.
      * - :doc:`D02_hypre_3Dxyz_bc <D02_hypre_3Dxyz_bc>`
        - ``test01`` and ``test02``
        - Multi-rank boundary-path and exact-boundary regression tests for Cartesian D02.
      * - :doc:`D03_hypre_3Draz_uniform <D03_hypre_3Draz_uniform>`
        - ``test03`` and ``test04``
        - Single-rank and MPI boundary-condition tests for uniform cylindrical D03.
      * - :doc:`D04_hypre_3Draz_nonuniform <D04_hypre_3Draz_nonuniform>`
        - ``test05``, ``test06``, and ``test07``
        - Single-rank BC regression, 8-rank analytic/MPI regression, and D03-D04 MMS comparison for nonuniform cylindrical D04.

   .. rubric:: Shared Structure

   All four subpages now follow the same structure:

   - `Test Role`: what this test is supposed to prove.
   - `What This Test Is Doing`: a reader-facing explanation of the problem being tested and the acceptance signal.
   - `Parameters`: key grid, MPI, boundary, exact-solution, and tolerance settings.
   - `How To Run`: entry script and default MPI layout.
   - `Coverage`: routines and behaviors exercised by the test.
   - `Outputs`: which data files and figures matter.
   - `How To Read The Figures`: axis meanings, error-map interpretation, and common failure signs.
   - `Reference Result`: the current numeric baseline.
   - `Representative Figures`: a small, style-consistent figure set for manual comparison.

   Before any build step, check ``HYPRE_INC`` and ``HYPRE_LIB`` in the test
   scripts. If the local HYPRE installation path differs, update those
   variables before running ``make.sh``, ``run.sh``, or other build/run
   scripts.
