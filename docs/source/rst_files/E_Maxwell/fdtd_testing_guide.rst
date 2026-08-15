==================
FDTD Testing Guide
==================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 1. 范围

   本指南概述 AlgoPlasma 中 FDTD 内核的验证方式、测试算例所在位置，以及如何快速运行和检查结果。
   如果只需要按目录查看测试入口、运行顺序和反向链接，可先看 :doc:`/tests/005_maxwell/index`。

   当前重点覆盖以下 Maxwell 更新内核：

   - 2D 柱坐标 ``(r,z)`` TE/TM
   - 3D 柱坐标 ``(r,\phi,z)``，包括 ``m=0`` 和 ``m=1`` 覆盖
   - 3D Cartesian ``(x,y,z)``

   除非各 case 的 README 明确说明，下面这些测试套件不包含 CPML、粒子、电流源、碰撞或滤波。
   其中 ``case_fdtd_2d_tm_cylindrical_wave``、``case_fdtd_2d_te_cylindrical_wave``、
   ``case_fdtd_3d_cartesian_wave`` 和 ``case_fdtd_3d_cylindrical_m0_wave`` 是 Python-only
   可视化算例：``run.sh`` 运行对应的 ``*.py`` 脚本生成图片，不编译、也不调用 ``E_Maxwell`` 的
   Fortran 子程序。

   .. rubric:: 2. 测试矩阵

   - ``tests/005_maxwell/case_fdtd_single_step_formula``
     对单步 stencil/公式进行验证，并与显式参考更新结果比较。输出包括每个 case 的 ``*.log`` 和误差图 ``*.pgm``。

   - ``tests/005_maxwell/case_fdtd_cyl_m0_equivalence``
     检查 3D 柱坐标 ``m=0`` 更新与 2D RZ TEz/TMz 更新的一致性。输出为
     ``logs/m0_equivalence.log`` 和 ``m0_equivalence_summary.csv``。

   - ``tests/005_maxwell/case_fdtd_mms_convergence``
     对 2D RZ TEz/TMz、3D 柱坐标 ``m=0/m=1`` 以及 3D Cartesian 进行 MMS 收敛和精度测试。
     输出为每个 case 的 ``test_mms_*.log``。

   - ``tests/005_maxwell/case_fdtd_stability``
     长时间、无源项的有界性测试。输出为 ``logs/*.log`` 和 ``stability_summary.csv``。

   - ``tests/005_maxwell/case_fdtd_pulse_longrun``
     短脉冲激励后的长时间演化稳定性测试。输出为 ``logs/*.log`` 和 ``pulse_longrun_summary.csv``。

   - :doc:`CPML wave-packet 测试总览 </tests/005_maxwell/cpml_wavepacket>` 和四个 ``case_cpml_*_wavepacket_ref``
     CPML 有限宽度波包反射测试，比较 compact CPML 区域和 large reference 区域。
     总览页解释 ``late_gate`` 和 ``late reflection error``；具体 probe 误差图、传播快照图和 GIF
     放在 :doc:`2D RZ TEz </tests/005_maxwell/case_cpml_2d_rz_tez_wavepacket_ref>`、
     :doc:`2D RZ TMz </tests/005_maxwell/case_cpml_2d_rz_tmz_wavepacket_ref>`、
     :doc:`3D Cartesian </tests/005_maxwell/case_cpml_3d_cartesian_wavepacket_ref>` 和
     :doc:`3D cylindrical </tests/005_maxwell/case_cpml_3d_cylindrical_wavepacket_ref>` case 页。

   - :doc:`case_fdtd_2d_tm_cylindrical_wave </tests/005_maxwell/case_fdtd_2d_tm_cylindrical_wave>`
     Python-only 2D TM 圆形波前可视化算例。内部 Yee 更新等价于 E03 3D Cartesian 的二维 TMz
     截面（``∂/∂z = 0``，保留 ``Hx,Hy,Ez``），源项和一阶 Mur 边界为 Python 展示设置。
     图片和读图说明见对应 case 页。

   - :doc:`case_fdtd_2d_te_cylindrical_wave </tests/005_maxwell/case_fdtd_2d_te_cylindrical_wave>`
     Python-only 2D TE 圆形波前可视化算例。内部 Yee 更新等价于 E03 3D Cartesian 的二维 TEz
     截面（``∂/∂z = 0``，保留 ``Ex,Ey,Hz``），源项和一阶 Mur 边界为 Python 展示设置。
     图片和读图说明见对应 case 页。

   - :doc:`case_fdtd_3d_cartesian_wave </tests/005_maxwell/case_fdtd_3d_cartesian_wave>`
     Python-only 3D Cartesian 波传播可视化算例。内部六分量 curl 更新与 E03
     ``sub_E03_fdtd_3d_cartesian_H/E`` 一致；中心源、RMS 图和 sponge 边界为 Python 展示设置。
     图片和读图说明见对应 case 页。

   - :doc:`case_fdtd_3d_cylindrical_m0_wave </tests/005_maxwell/case_fdtd_3d_cylindrical_m0_wave>`
     Python-only 3D 柱坐标波导可视化算例。它推进标量 ``Ez`` 波动方程，不是 E02
     ``sub_E02_fdtd_3d_cylindrical_H/E`` 的六分量逐点等价；严格 ``m=0`` 一致性见
     ``case_fdtd_cyl_m0_equivalence``。图片和读图说明见对应 case 页。

   .. rubric:: 3. 快速运行命令

   从仓库根目录开始：

   .. code-block:: bash

      cd tests/005_maxwell/case_fdtd_single_step_formula
      bash run.sh

      cd ../case_fdtd_cyl_m0_equivalence
      bash run.sh

      cd ../case_fdtd_mms_convergence
      bash run.sh

      cd ../case_fdtd_stability
      bash run.sh

      cd ../case_fdtd_pulse_longrun
      bash run.sh

      cd ../case_cpml_2d_rz_tez_wavepacket_ref
      bash run.sh

   编译型回归 case 通常提供：

   - ``make.sh``：编译测试程序
   - ``run.sh``：执行完整 case 集合
   - ``clean.sh``：删除生成产物

   .. rubric:: 4. 建议验证顺序

   本测试集用于确认当前已有 E_Maxwell FDTD/CPML 子程序的回归行为。
   常规验证建议按以下顺序运行：

   1. 先运行 single-step formula 测试，因为最快且最局部。
   2. 运行 3D 柱坐标 ``m=0`` equivalence，检查 2D/3D 更新一致性。
   3. 运行 MMS convergence，确认全局误差阶数。
   4. 运行无源项 long-run stability。
   5. 运行 pulse long-run stability。
   6. 涉及 CPML 子程序或吸收层参数方案时，运行 CPML wave-packet reference 测试。

   如果需要新的 Maxwell 功能、边界条件或参数方案，应优先新增子程序或新版本，
   并添加对应测试；已有稳定子程序应以保持这些回归测试通过为维护目标。

   .. rubric:: 5. 结果解读

   - Single-step 测试：误差应接近机器精度，并且 ``n_failed=0``。
   - MMS 测试：报告的 observed order 应满足 case 阈值，并显示 ``RESULT: PASS``。
   - Stability/pulse 测试：检查 summary CSV 中的 ``result`` 列
     （``stable/marginal/unstable``），并结合对应 log 排查热点。
   - CPML wave-packet 测试：先用总览页理解 ``late reflection error`` 定义，再到各 case
     页查看 probe 误差图；注意该误差是 probe 点场幅值误差，不是全局反射能量系数。

   .. rubric:: 6. 说明

   - 回归测试 case 的 README 包含方程、阈值和最新 baseline 结果；可视化 case 的图片和读图说明
     放在 005_maxwell 的对应 case 页面。
   - 更细的实现约定见：

     - ``E_Maxwell/E01_Maxwell_2Drz/fdtd_2d_rz_axisymmetric_notes``
     - ``E_Maxwell/E02_Maxwell_3Drtz/fdtd_3d_cylindrical_notes``
     - ``E_Maxwell/E03_Maxwell_3Dxyz/fdtd_3d_cartesian_notes``

.. container:: ap-lang ap-lang-en

   .. rubric:: 1. Scope

   This guide summarizes how FDTD kernels in AlgoPlasma are validated, where the test
   cases live, and how to run and check results quickly.
   For the directory-oriented entry point, run order, and reverse links, start
   from :doc:`/tests/005_maxwell/index`.

   Current focus is on core Maxwell updates in:

   - 2D cylindrical ``(r,z)`` TE/TM
   - 3D cylindrical ``(r,\phi,z)`` (including ``m=0`` and ``m=1`` coverage)
   - 3D Cartesian ``(x,y,z)``

   The following test suites do **not** include CPML, particles, current sources,
   collisions, or filtering unless explicitly stated in each case README.
   ``case_fdtd_2d_tm_cylindrical_wave``, ``case_fdtd_2d_te_cylindrical_wave``,
   ``case_fdtd_3d_cartesian_wave``, and ``case_fdtd_3d_cylindrical_m0_wave`` are
   Python-only visualization cases: ``run.sh`` runs the corresponding ``*.py``
   script to generate figures, without compiling or calling ``E_Maxwell``
   Fortran routines.

   .. rubric:: 2. Test Matrix

   - ``tests/005_maxwell/case_fdtd_single_step_formula``
     One-step stencil/formula verification against explicit reference updates.
     Output: per-case ``*.log`` plus error maps (``*.pgm``).

   - ``tests/005_maxwell/case_fdtd_cyl_m0_equivalence``
     Equivalence check between 3D cylindrical ``m=0`` updates and 2D RZ TEz/TMz
     updates. Output: ``logs/m0_equivalence.log`` and
     ``m0_equivalence_summary.csv``.

   - ``tests/005_maxwell/case_fdtd_mms_convergence``
     MMS convergence/accuracy tests for 2D RZ TEz/TMz, 3D cylindrical ``m=0/m=1``,
     and 3D Cartesian. Output: per-case ``test_mms_*.log``.

   - ``tests/005_maxwell/case_fdtd_stability``
     Long-run no-source boundedness tests. Output: ``logs/*.log`` and
     ``stability_summary.csv``.

   - ``tests/005_maxwell/case_fdtd_pulse_longrun``
     Stability tests with a short pulse and long post-pulse evolution. Output:
     ``logs/*.log`` and ``pulse_longrun_summary.csv``.

   - :doc:`CPML wave-packet overview </tests/005_maxwell/cpml_wavepacket>` and the four ``case_cpml_*_wavepacket_ref`` cases
     CPML finite-width wave-packet reflection tests comparing compact CPML and
     large-reference domains. The overview defines ``late_gate`` and
     ``late reflection error``; probe-error plots, propagation snapshots, and
     GIFs live on the
     :doc:`2D RZ TEz </tests/005_maxwell/case_cpml_2d_rz_tez_wavepacket_ref>`,
     :doc:`2D RZ TMz </tests/005_maxwell/case_cpml_2d_rz_tmz_wavepacket_ref>`,
     :doc:`3D Cartesian </tests/005_maxwell/case_cpml_3d_cartesian_wavepacket_ref>`,
     and :doc:`3D cylindrical </tests/005_maxwell/case_cpml_3d_cylindrical_wavepacket_ref>` case pages.

   - :doc:`case_fdtd_2d_tm_cylindrical_wave </tests/005_maxwell/case_fdtd_2d_tm_cylindrical_wave>`
     Python-only 2D TM circular-wavefront visualization. Its interior Yee update
     is the 2D TMz reduction of E03 3D Cartesian (``∂/∂z = 0``, keeping
     ``Hx,Hy,Ez``); the source and first-order Mur boundary are Python display
     choices. The figure and reading notes are on the case page.

   - :doc:`case_fdtd_2d_te_cylindrical_wave </tests/005_maxwell/case_fdtd_2d_te_cylindrical_wave>`
     Python-only 2D TE circular-wavefront visualization. Its interior Yee update
     is the 2D TEz reduction of E03 3D Cartesian (``∂/∂z = 0``, keeping
     ``Ex,Ey,Hz``); the source and first-order Mur boundary are Python display
     choices. The figure and reading notes are on the case page.

   - :doc:`case_fdtd_3d_cartesian_wave </tests/005_maxwell/case_fdtd_3d_cartesian_wave>`
     Python-only 3D Cartesian wave visualization. Its interior six-component
     curl update matches E03 ``sub_E03_fdtd_3d_cartesian_H/E``; the centered
     source, RMS figure, and sponge boundary are Python display choices. The
     figures and reading notes are on the case page.

   - :doc:`case_fdtd_3d_cylindrical_m0_wave </tests/005_maxwell/case_fdtd_3d_cylindrical_m0_wave>`
     Python-only 3D cylindrical waveguide visualization. It advances a scalar
     ``Ez`` wave equation and is not a pointwise six-component equivalent of E02
     ``sub_E02_fdtd_3d_cylindrical_H/E``; use
     ``case_fdtd_cyl_m0_equivalence`` for strict ``m=0`` consistency. The
     figures and reading notes are on the case page.

   .. rubric:: 3. Quick Run Commands

   From repository root:

   .. code-block:: bash

      cd tests/005_maxwell/case_fdtd_single_step_formula
      bash run.sh

      cd ../case_fdtd_cyl_m0_equivalence
      bash run.sh

      cd ../case_fdtd_mms_convergence
      bash run.sh

      cd ../case_fdtd_stability
      bash run.sh

      cd ../case_fdtd_pulse_longrun
      bash run.sh

      cd ../case_cpml_2d_rz_tez_wavepacket_ref
      bash run.sh

   Compiled regression cases usually provide:

   - ``make.sh``: build test executables
   - ``run.sh``: execute the full case set
   - ``clean.sh``: remove generated artifacts

   .. rubric:: 4. Suggested Validation Order

   This test set confirms the regression behavior of the existing E_Maxwell
   FDTD/CPML subroutines. Routine validation can use the following order:

   1. Run single-step formula tests first (fastest and most localized).
   2. Run 3D cylindrical ``m=0`` equivalence to check 2D/3D consistency.
   3. Run MMS convergence to confirm global error order.
   4. Run no-source long-run stability.
   5. Run pulse long-run stability.
   6. For CPML subroutines or absorbing-layer parameter schemes, run the CPML
      wave-packet reference tests.

   For new Maxwell capabilities, boundary conditions, or parameter schemes,
   prefer adding a new subroutine or version and corresponding tests. Existing
   stable subroutines should be maintained as regression-tested behavior.

   .. rubric:: 5. Result Interpretation

   - Single-step tests: expect errors near machine precision and ``n_failed=0``.
   - MMS tests: expect reported observed order to satisfy case thresholds and show
     ``RESULT: PASS``.
   - Stability/pulse tests: check summary CSV ``result`` column
     (``stable/marginal/unstable``) and inspect matching logs for hotspots.
   - CPML wave-packet tests: use the overview page for the ``late reflection error``
     definition, then check probe-error figures on each case page. This error is
     a field-amplitude error at one probe, not a global reflected-energy coefficient.

   .. rubric:: 6. Notes

   - Regression test cases have dedicated READMEs with equations, thresholds,
     and latest baseline results; visualization figures and reading notes live
     on the matching 005_maxwell case pages.
   - For detailed implementation-level conventions, see:

     - ``E_Maxwell/E01_Maxwell_2Drz/fdtd_2d_rz_axisymmetric_notes``
     - ``E_Maxwell/E02_Maxwell_3Drtz/fdtd_3d_cylindrical_notes``
     - ``E_Maxwell/E03_Maxwell_3Dxyz/fdtd_3d_cartesian_notes``
