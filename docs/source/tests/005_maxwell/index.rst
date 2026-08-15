005_maxwell Tests
=================

.. toctree::
   :maxdepth: 1
   :caption: 1. FDTD Formula and Regression

   case_fdtd_single_step_formula
   case_fdtd_cyl_m0_equivalence
   case_fdtd_mms_convergence
   case_fdtd_stability
   case_fdtd_pulse_longrun

.. toctree::
   :maxdepth: 1
   :caption: 2. FDTD Visualization Cases

   case_fdtd_2d_tm_cylindrical_wave
   case_fdtd_2d_te_cylindrical_wave
   case_fdtd_3d_cartesian_wave
   case_fdtd_3d_cylindrical_m0_wave

.. toctree::
   :maxdepth: 1
   :caption: 3. CPML Absorbing Boundary

   cpml_wavepacket
   case_cpml_2d_rz_tez_wavepacket_ref
   case_cpml_2d_rz_tmz_wavepacket_ref
   case_cpml_3d_cartesian_wavepacket_ref
   case_cpml_3d_cylindrical_wavepacket_ref

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 范围

   本页是 ``tests/005_maxwell`` 的测试目录入口，面向 E_Maxwell 的 FDTD 更新内核。
   它补充 :doc:`E_Maxwell </rst_files/E_Maxwell>` 模块页和
   :doc:`FDTD Testing Guide </rst_files/E_Maxwell/fdtd_testing_guide>`：
   本页强调测试目录、运行顺序和结果判断；Testing Guide 保留更完整的公式、可视化说明和案例细节。

   其中 ``case_fdtd_2d_tm_cylindrical_wave``、``case_fdtd_2d_te_cylindrical_wave``、
   ``case_fdtd_3d_cartesian_wave`` 和 ``case_fdtd_3d_cylindrical_m0_wave`` 是
   Python-only 可视化算例；``run.sh`` 运行对应 ``*.py`` 脚本生成图片，不编译、也不调用
   ``E_Maxwell`` 目录中的 Fortran 子程序。它们用于展示场形和几何直觉，不作为 Fortran
   子程序的 pass/fail 回归证据。

   .. rubric:: 公共运行环境

   首次使用时，如果还没有 ``~/.venv``，可在 Ubuntu/WSL 中先安装系统工具并创建虚拟环境：

   .. code-block:: bash

      sudo apt update
      sudo apt install -y python3-venv python3-pip gfortran make
      python3 -m venv ~/.venv
      source ~/.venv/bin/activate
      python -m pip install --upgrade pip
      python -m pip install -r docs/requirements.txt numpy matplotlib imageio pillow

   之后进入任意 ``tests/005_maxwell`` 子目录前，只需在仓库根目录激活 Python 环境：

   .. code-block:: bash

      source ~/.venv/bin/activate

   Fortran 回归测试依赖 Bash、``gfortran`` 和 ``tests/005_maxwell/common.sh`` 中的通用编译参数。
   Python 可视化和 CPML 后处理依赖该虚拟环境中的 ``python``、``numpy``、``matplotlib``、``imageio``
   和 ``pillow``；``docs/requirements.txt`` 提供 Sphinx 文档构建所需包。case 目录都会提供
   ``run.sh``；部分目录还提供 ``clean.sh``，含 Fortran 可执行程序的目录还会提供 ``make.sh``。

   .. rubric:: 页面分组和建议阅读顺序

   这些页面按“先理解 FDTD 内核，再看场形直觉，最后进入 CPML 吸收边界”的顺序组织：

   1. **FDTD 公式与回归**：从单步 stencil 到几何一致性、MMS 收敛和长时间稳定性，是判断 Fortran 更新核是否可靠的主线。
   2. **FDTD 可视化算例**：用 Python-only 图像帮助理解 TMz/TEz、3D Cartesian 和 cylindrical 几何中的场形，不作为 Fortran pass/fail 判据。
   3. **CPML 吸收边界**：在已经理解基础 FDTD 更新后，再看 compact/reference 域比较、late reflection error 和吸收效果。

   .. list-table:: 测试矩阵
      :header-rows: 1
      :widths: 20 32 30 18

      * - 分类
        - 测试目录
        - 覆盖内容
        - 相关文档
      * - FDTD 公式与回归
        - ``case_fdtd_single_step_formula``
        - 单步 stencil/公式验证，和显式参考更新比较。
        - :doc:`case page <case_fdtd_single_step_formula>`
      * - FDTD 公式与回归
        - ``case_fdtd_cyl_m0_equivalence``
        - 检查 3D cylindrical ``m=0`` 更新与 2D RZ TEz/TMz 更新的一致性。
        - :doc:`case page <case_fdtd_cyl_m0_equivalence>`
      * - FDTD 公式与回归
        - ``case_fdtd_mms_convergence``
        - 2D RZ、3D cylindrical 和 3D Cartesian 的 MMS 收敛测试。
        - :doc:`case page <case_fdtd_mms_convergence>`
      * - FDTD 公式与回归
        - ``case_fdtd_stability``
        - 无源长时间稳定性测试。
        - :doc:`case page <case_fdtd_stability>`
      * - FDTD 公式与回归
        - ``case_fdtd_pulse_longrun``
        - 短脉冲激励后的长时间演化稳定性测试。
        - :doc:`case page <case_fdtd_pulse_longrun>`
      * - FDTD 可视化
        - ``case_fdtd_2d_tm_cylindrical_wave``
        - Python-only 2D TMz 圆形波前图；内部 Yee 更新等价于
          ``sub_E03_fdtd_3d_cartesian_H/E`` 在 ``∂/∂z=0``、仅 ``Hx,Hy,Ez`` 非零时的 2D 化。
        - :doc:`case page <case_fdtd_2d_tm_cylindrical_wave>`
      * - FDTD 可视化
        - ``case_fdtd_2d_te_cylindrical_wave``
        - Python-only 2D TEz 圆形波前图；内部 Yee 更新等价于
          ``sub_E03_fdtd_3d_cartesian_H/E`` 在 ``∂/∂z=0``、仅 ``Ex,Ey,Hz`` 非零时的 2D 化。
        - :doc:`case page <case_fdtd_2d_te_cylindrical_wave>`
      * - FDTD 可视化
        - ``case_fdtd_3d_cartesian_wave``
        - Python-only 3D Cartesian 可视化；内部六分量 curl 更新与
          ``sub_E03_fdtd_3d_cartesian_H/E`` 的内部更新式一致，源项和 sponge 边界在 Python 侧实现。
        - :doc:`case page <case_fdtd_3d_cartesian_wave>`
      * - FDTD 可视化
        - ``case_fdtd_3d_cylindrical_m0_wave``
        - Python-only cylindrical 几何可视化；脚本更新标量 ``Ez`` 波动方程，
          不是 ``sub_E02_fdtd_3d_cylindrical_H/E`` 的逐点等价实现。
        - :doc:`case page <case_fdtd_3d_cylindrical_m0_wave>`
      * - CPML 吸收边界
        - ``cpml_wavepacket``
        - 四个 CPML wave-packet case 的总览页，解释 compact/reference 域、probe 和 late gate。
        - :doc:`overview <cpml_wavepacket>`
      * - CPML 吸收边界
        - ``case_cpml_2d_rz_tez_wavepacket_ref``
        - 2D RZ TEz ``Ephi,Hr,Hz`` 的 CPML 波包吸收测试。
        - :doc:`case page <case_cpml_2d_rz_tez_wavepacket_ref>`
      * - CPML 吸收边界
        - ``case_cpml_2d_rz_tmz_wavepacket_ref``
        - 2D RZ TMz ``Er,Hphi,Ez`` 的 CPML 波包吸收测试。
        - :doc:`case page <case_cpml_2d_rz_tmz_wavepacket_ref>`
      * - CPML 吸收边界
        - ``case_cpml_3d_cartesian_wavepacket_ref``
        - 3D Cartesian CPML 波包吸收测试，比较 compact 域和 large reference 域。
        - :doc:`case page <case_cpml_3d_cartesian_wavepacket_ref>`
      * - CPML 吸收边界
        - ``case_cpml_3d_cylindrical_wavepacket_ref``
        - 3D cylindrical CPML 波包吸收测试，检查轴对称/柱坐标几何中的 late reflection error。
        - :doc:`case page <case_cpml_3d_cylindrical_wavepacket_ref>`

   .. rubric:: 建议运行顺序

   这些 case 用于确认当前已有 E_Maxwell FDTD/CPML 子程序仍然通过回归测试。
   常规检查可按以下顺序执行：

   1. ``case_fdtd_single_step_formula``
   2. ``case_fdtd_cyl_m0_equivalence``
   3. ``case_fdtd_mms_convergence``
   4. ``case_fdtd_stability``
   5. ``case_fdtd_pulse_longrun``
   6. 需要刷新展示图时，运行四个 visualization cases。
   7. 涉及 CPML 子程序或吸收层参数方案时，先查看 ``cpml_wavepacket`` 总览，再运行四个 ``case_cpml_*_wavepacket_ref``。

   若需要新的 Maxwell 功能、边界条件或参数方案，优先新增子程序或新版本，
   并为新增实现添加相应测试；已有稳定子程序应以保持回归通过为目标。

   .. rubric:: 快速命令

   每个 case 目录都包含 ``run.sh``；含 Fortran 可执行程序的目录通常还包含 ``make.sh`` 和 ``clean.sh``：

   .. code-block:: bash

      cd tests/005_maxwell/case_fdtd_single_step_formula
      bash run.sh

      cd ../case_fdtd_cyl_m0_equivalence
      bash run.sh

      cd ../case_fdtd_mms_convergence
      bash run.sh

      cd ../case_fdtd_2d_tm_cylindrical_wave
      bash run.sh

      cd ../case_cpml_2d_rz_tez_wavepacket_ref
      bash run.sh

   .. rubric:: 结果判断

   - 单步公式测试应报告接近机器精度的误差，并且失败计数为零。
   - MMS 测试应满足各 case README 中的 observed order 阈值。
   - 稳定性测试应检查 summary CSV 的 ``result`` 列，并结合 log 定位异常场量。
   - CPML wave-packet 测试应先查看 :doc:`CPML wave-packet 总览 <cpml_wavepacket>` 中的
     ``late reflection error`` 定义，再到各 case 页面查看 probe 误差图。
   - 可视化案例的图片用于文档展示；需要刷新展示图时，运行对应 Python 脚本并更新图片。

.. container:: ap-lang ap-lang-en

   .. rubric:: Scope

   This page is the test-directory entry point for ``tests/005_maxwell``,
   covering the FDTD update kernels in E_Maxwell. It complements the
   :doc:`E_Maxwell </rst_files/E_Maxwell>` module page and the
   :doc:`FDTD Testing Guide </rst_files/E_Maxwell/fdtd_testing_guide>`:
   this page emphasizes test locations, run order, and result interpretation,
   while the guide keeps the fuller formulas, visualization notes, and case
   details.

   The four directories ``case_fdtd_2d_tm_cylindrical_wave``,
   ``case_fdtd_2d_te_cylindrical_wave``, ``case_fdtd_3d_cartesian_wave``, and
   ``case_fdtd_3d_cylindrical_m0_wave`` are Python-only visualization cases.
   Their ``run.sh`` scripts execute the matching ``*.py`` file to generate
   figures; they do not compile or call the Fortran subroutines under
   ``E_Maxwell``. Use them for field-shape and geometry intuition, not as
   pass/fail regression evidence for the Fortran library.

   .. rubric:: Common Run Environment

   On first use, if ``~/.venv`` does not exist yet, install the system tools and
   create the virtual environment on Ubuntu/WSL:

   .. code-block:: bash

      sudo apt update
      sudo apt install -y python3-venv python3-pip gfortran make
      python3 -m venv ~/.venv
      source ~/.venv/bin/activate
      python -m pip install --upgrade pip
      python -m pip install -r docs/requirements.txt numpy matplotlib imageio pillow

   After that, before entering any ``tests/005_maxwell`` case directory, activate
   the Python environment from the repository root:

   .. code-block:: bash

      source ~/.venv/bin/activate

   Fortran regression tests require Bash, ``gfortran``, and the shared compile
   settings in ``tests/005_maxwell/common.sh``. Python visualization and CPML
   postprocessing use the virtual environment's ``python``, ``numpy``,
   ``matplotlib``, ``imageio``, and ``pillow``; ``docs/requirements.txt`` covers
   the Sphinx documentation build packages. Case directories provide ``run.sh``;
   some also provide ``clean.sh``, and directories with Fortran executables also
   provide ``make.sh``.

   .. rubric:: Page Groups and Suggested Reading Order

   The pages are organized as "understand the FDTD kernels first, then inspect
   field-shape intuition, and finally move to CPML absorbing boundaries":

   1. **FDTD formula and regression**: from one-step stencils to geometry consistency, MMS convergence, and long-run stability.
   2. **FDTD visualization cases**: Python-only images for TMz/TEz, 3D Cartesian, and cylindrical geometry intuition; these are not Fortran pass/fail evidence.
   3. **CPML absorbing boundary**: compact/reference-domain comparisons, late reflection error, and absorption diagnostics after the base FDTD updates are understood.

   .. list-table:: Test Matrix
      :header-rows: 1
      :widths: 20 32 30 18

      * - Category
        - Test directory
        - Coverage
        - Related docs
      * - FDTD formula and regression
        - ``case_fdtd_single_step_formula``
        - One-step stencil/formula verification against explicit reference updates.
        - :doc:`case page <case_fdtd_single_step_formula>`
      * - FDTD formula and regression
        - ``case_fdtd_cyl_m0_equivalence``
        - Consistency between 3D cylindrical ``m=0`` updates and 2D RZ TEz/TMz updates.
        - :doc:`case page <case_fdtd_cyl_m0_equivalence>`
      * - FDTD formula and regression
        - ``case_fdtd_mms_convergence``
        - MMS convergence tests for 2D RZ, 3D cylindrical, and 3D Cartesian kernels.
        - :doc:`case page <case_fdtd_mms_convergence>`
      * - FDTD formula and regression
        - ``case_fdtd_stability``
        - Long-run no-source boundedness tests.
        - :doc:`case page <case_fdtd_stability>`
      * - FDTD formula and regression
        - ``case_fdtd_pulse_longrun``
        - Long-run stability after a short pulse excitation.
        - :doc:`case page <case_fdtd_pulse_longrun>`
      * - FDTD visualization
        - ``case_fdtd_2d_tm_cylindrical_wave``
        - Python-only 2D TMz circular-wavefront figure; its interior Yee update
          is the ``∂/∂z=0`` reduction of ``sub_E03_fdtd_3d_cartesian_H/E`` with
          only ``Hx,Hy,Ez`` nonzero.
        - :doc:`case page <case_fdtd_2d_tm_cylindrical_wave>`
      * - FDTD visualization
        - ``case_fdtd_2d_te_cylindrical_wave``
        - Python-only 2D TEz circular-wavefront figure; its interior Yee update
          is the ``∂/∂z=0`` reduction of ``sub_E03_fdtd_3d_cartesian_H/E`` with
          only ``Ex,Ey,Hz`` nonzero.
        - :doc:`case page <case_fdtd_2d_te_cylindrical_wave>`
      * - FDTD visualization
        - ``case_fdtd_3d_cartesian_wave``
        - Python-only 3D Cartesian visualization; the six-component curl update
          matches ``sub_E03_fdtd_3d_cartesian_H/E`` inside the domain, while the
          source and sponge boundary are Python-side additions.
        - :doc:`case page <case_fdtd_3d_cartesian_wave>`
      * - FDTD visualization
        - ``case_fdtd_3d_cylindrical_m0_wave``
        - Python-only cylindrical-geometry visualization; it advances a scalar
          ``Ez`` wave equation and is not a pointwise equivalent of
          ``sub_E02_fdtd_3d_cylindrical_H/E``.
        - :doc:`case page <case_fdtd_3d_cylindrical_m0_wave>`
      * - CPML absorbing boundary
        - ``cpml_wavepacket``
        - Overview of the four CPML wave-packet cases: compact/reference domains, probes, and late gate.
        - :doc:`overview <cpml_wavepacket>`
      * - CPML absorbing boundary
        - ``case_cpml_2d_rz_tez_wavepacket_ref``
        - CPML wave-packet absorption test for 2D RZ TEz ``Ephi,Hr,Hz``.
        - :doc:`case page <case_cpml_2d_rz_tez_wavepacket_ref>`
      * - CPML absorbing boundary
        - ``case_cpml_2d_rz_tmz_wavepacket_ref``
        - CPML wave-packet absorption test for 2D RZ TMz ``Er,Hphi,Ez``.
        - :doc:`case page <case_cpml_2d_rz_tmz_wavepacket_ref>`
      * - CPML absorbing boundary
        - ``case_cpml_3d_cartesian_wavepacket_ref``
        - 3D Cartesian CPML wave-packet test comparing compact and large-reference domains.
        - :doc:`case page <case_cpml_3d_cartesian_wavepacket_ref>`
      * - CPML absorbing boundary
        - ``case_cpml_3d_cylindrical_wavepacket_ref``
        - 3D cylindrical CPML wave-packet test for late reflection error in cylindrical geometry.
        - :doc:`case page <case_cpml_3d_cylindrical_wavepacket_ref>`

   .. rubric:: Suggested Run Order

   These cases confirm that the existing E_Maxwell FDTD/CPML subroutines still
   pass regression checks. Routine checks can use the following order:

   1. ``case_fdtd_single_step_formula``
   2. ``case_fdtd_cyl_m0_equivalence``
   3. ``case_fdtd_mms_convergence``
   4. ``case_fdtd_stability``
   5. ``case_fdtd_pulse_longrun``
   6. Run the four visualization cases when documentation figures need refresh.
   7. Review the ``cpml_wavepacket`` overview, then run the four ``case_cpml_*_wavepacket_ref`` cases for CPML subroutines or absorbing-layer parameter schemes.

   For new Maxwell capabilities, boundary conditions, or parameter schemes,
   prefer adding a new subroutine or version and matching tests. Existing stable
   subroutines should be maintained as regression-tested behavior.

   .. rubric:: Quick Commands

   Each case directory provides ``run.sh``; directories with Fortran executables
   usually also provide ``make.sh`` and ``clean.sh``:

   .. code-block:: bash

      cd tests/005_maxwell/case_fdtd_single_step_formula
      bash run.sh

      cd ../case_fdtd_cyl_m0_equivalence
      bash run.sh

      cd ../case_fdtd_mms_convergence
      bash run.sh

      cd ../case_fdtd_2d_tm_cylindrical_wave
      bash run.sh

      cd ../case_cpml_2d_rz_tez_wavepacket_ref
      bash run.sh

   .. rubric:: Result Interpretation

   - Single-step formula tests should report near-machine-precision errors and zero failures.
   - MMS tests should satisfy the observed-order thresholds in the case README files.
   - Stability tests should be judged from the summary CSV ``result`` column and the matching logs.
   - CPML wave-packet tests should use the ``late reflection error`` definition from
     :doc:`CPML wave-packet overview <cpml_wavepacket>`, then judge the probe-error
     figures on each case page.
   - Visualization images are documentation assets; regenerate and update them when those figures need refresh.
