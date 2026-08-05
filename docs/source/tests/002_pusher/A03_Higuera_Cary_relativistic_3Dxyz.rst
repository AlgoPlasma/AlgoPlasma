A03_Higuera_Cary_relativistic_3Dxyz Test
========================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   本页说明 ``tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz`` 中的参考测试。
   该测试调用 ``sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v(v, E, B, k)``，
   检查 relativistic Higuera-Cary velocity pusher 在均匀场问题中的轨道、
   速度和解析参考解的一致性，重点验证高 :math:`\gamma` 力平衡 ExB drift 场景下
   HC pusher 相对于 Boris pusher 的显著优势。

   .. rubric:: 程序结构

   - ``source_f90/main.f90`` 设置参数并依次运行三个 case。
   - ``source_f90/sub_case*.f90`` 给出每个物理算例、解析参考解和误差输出。
   - ``source_py/plot_savefig.py`` 读取 ``build/*.dat``，打印最大误差并保存图片。
   - ``make.sh`` 使用 ``gfortran -cpp -O3 -fdefault-real-8`` 编译测试程序。

   .. rubric:: 运行方式

   .. code-block:: bash

      cd tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz
      bash clean.sh && bash make.sh && bash run.sh && bash plot.sh

   ``run.sh`` 会生成 ``build/case*.dat``；``plot.sh`` 会生成 ``figs_cases/*.png``。
   文档中的静态图是从一次参考运行复制到 ``docs/source/images/tests/002_pusher`` 的结果。

   .. rubric:: 输出字段

   每个 ``.dat`` 文件包含 ``step, t, x, y, z, vx, vy, vz, v2``，随后是解析位置和解析速度，最后两列为
   ``err_v = |v - v_ana|`` 和 ``err_r = |r - r_ana|``。回旋测试使用
   :math:`\gamma` 修正后的回旋频率作为相对论解析参考。

   .. list-table:: 测试算例
      :header-rows: 1
      :widths: 20 42 38

      * - Case
        - 设置
        - 主要检查
      * - ``case01_gyro``
        - ``E = 0``，``B`` 沿 ``z`` 方向，:math:`v_0 = 0.9c`，:math:`\gamma \approx 2.3`
        - 相对论回旋轨道和 ``v²`` 守恒。
      * - ``case02_exb_drift``
        - :math:`\gamma = 20` 力平衡 ExB 场（``qm = 1``），``nstep = 10000``
        - HC 保持 :math:`|x| \approx 1.7 \times 10^{-5}` m；Boris 在同等条件下漂移约 2321 m。
      * - ``case03_warpx_exb_drift``
        - 同上，但 ``qm = e/m_e``，``dt`` 超过回旋周期约 7 个量级，复现 WarpX 参考测试
        - :math:`|x| < 0.001` m（PASS/FAIL），与 WarpX 报告的 HC ≈ 1.1×10⁻⁴ m 一致。

   .. rubric:: 参考图

   .. figure:: ../../images/tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz/case01_gyro_traj_xy.png
      :align: center
      :width: 78%

      ``case01_gyro`` 的 ``x-y`` 轨道，使用相对论修正回旋频率作为解析参考。

   .. figure:: ../../images/tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz/case01_gyro_v2_t.png
      :align: center
      :width: 78%

      ``case01_gyro`` 的 ``v^2`` 随时间变化，用于观察磁场旋转步的速度模保持情况。

   .. figure:: ../../images/tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz/case02_exb_drift_x_t.png
      :align: center
      :width: 78%

      ``case02_exb_drift`` 的 :math:`x(t)`。HC 将 :math:`x` 控制在 :math:`\sim 10^{-5}` m
      量级，Boris 在相同条件下积累约 2321 m 的系统性漂移。

   .. figure:: ../../images/tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz/case02_exb_drift_traj_xy.png
      :align: center
      :width: 78%

      ``case02_exb_drift`` 的 ``x-y`` 轨道，数值解（实线）与解析漂移轨迹（虚线）几乎重合。

   .. rubric:: 参考文献

   [1] A.V. Higuera, J.R. Cary, Structure-preserving second-order integration
   of relativistic charged particle trajectories in electromagnetic fields,
   Phys. Plasmas 24 (2017) 052104.
   DOI: `10.1063/1.4979989 <https://doi.org/10.1063/1.4979989>`_.

   [2] WarpX, ``Examples/Tests/particle_pusher/inputs_test_3d_particle_pusher``，
   https://github.com/ECP-WarpX/WarpX

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   This page documents the reference test under
   ``tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz``. The test calls
   ``sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v(v, E, B, k)`` and checks
   the relativistic Higuera-Cary velocity pusher against analytic reference
   motion in uniform-field cases, with emphasis on the high-:math:`\gamma`
   force-free ExB drift scenario where HC significantly outperforms Boris.

   .. rubric:: Program Structure

   - ``source_f90/main.f90`` sets the parameters and runs the three cases.
   - ``source_f90/sub_case*.f90`` defines each case, analytic reference solution, and error output.
   - ``source_py/plot_savefig.py`` reads ``build/*.dat``, prints maximum errors, and saves figures.
   - ``make.sh`` compiles the test with ``gfortran -cpp -O3 -fdefault-real-8``.

   .. rubric:: Run Command

   .. code-block:: bash

      cd tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz
      bash clean.sh && bash make.sh && bash run.sh && bash plot.sh

   ``run.sh`` writes ``build/case*.dat``. ``plot.sh`` writes
   ``figs_cases/*.png``. The static figures below are copied from one
   reference run into ``docs/source/images/tests/002_pusher``.

   .. rubric:: Output Fields

   Each ``.dat`` file contains ``step, t, x, y, z, vx, vy, vz, v2``, followed
   by analytic position and velocity columns. The final two columns are
   ``err_v = |v - v_ana|`` and ``err_r = |r - r_ana|``. The gyro case uses the
   relativistic cyclotron frequency corrected by :math:`\gamma`.

   .. list-table:: Test Cases
      :header-rows: 1
      :widths: 20 42 38

      * - Case
        - Setup
        - Main check
      * - ``case01_gyro``
        - ``E = 0``, ``B`` along ``z``, :math:`v_0 = 0.9c`, :math:`\gamma \approx 2.3`
        - Relativistic gyro orbit and ``v²`` conservation.
      * - ``case02_exb_drift``
        - :math:`\gamma = 20` force-free ExB field (``qm = 1``), ``nstep = 10000``
        - HC holds :math:`|x| \approx 1.7 \times 10^{-5}` m; Boris drifts ~2321 m under the same setup.
      * - ``case03_warpx_exb_drift``
        - Same as case02 but ``qm = e/m_e``; ``dt`` exceeds the gyro period by ~7 orders of magnitude. Replicates the WarpX reference test.
        - :math:`|x| < 0.001` m (PASS/FAIL); consistent with WarpX-reported HC ≈ 1.1×10⁻⁴ m.

   .. rubric:: Reference Figures

   .. figure:: ../../images/tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz/case01_gyro_traj_xy.png
      :align: center
      :width: 78%

      ``case01_gyro`` trajectory in the ``x-y`` plane using the relativistic gyro reference.

   .. figure:: ../../images/tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz/case01_gyro_v2_t.png
      :align: center
      :width: 78%

      ``case01_gyro`` time history of ``v^2``.

   .. figure:: ../../images/tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz/case02_exb_drift_x_t.png
      :align: center
      :width: 78%

      ``case02_exb_drift`` time history of :math:`x(t)`. HC keeps :math:`x` at the
      :math:`\sim 10^{-5}` m level; Boris accumulates a systematic drift of ~2321 m.

   .. figure:: ../../images/tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz/case02_exb_drift_traj_xy.png
      :align: center
      :width: 78%

      ``case02_exb_drift`` trajectory in the ``x-y`` plane. The numeric solution (solid)
      closely follows the analytic drift path (dashed).

   .. rubric:: References

   [1] A.V. Higuera, J.R. Cary, Structure-preserving second-order integration
   of relativistic charged particle trajectories in electromagnetic fields,
   Phys. Plasmas 24 (2017) 052104.
   DOI: `10.1063/1.4979989 <https://doi.org/10.1063/1.4979989>`_.

   [2] WarpX, ``Examples/Tests/particle_pusher/inputs_test_3d_particle_pusher``,
   https://github.com/ECP-WarpX/WarpX
