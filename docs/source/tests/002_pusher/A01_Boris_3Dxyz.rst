A01_Boris_3Dxyz Test
====================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   本页说明 ``tests/002_pusher/A01_Boris_3Dxyz`` 中的参考测试。该测试调用
   ``sub_A01_Boris_3Dxyz(v, E, B, k)``，检查非相对论 3D Cartesian Boris
   velocity pusher 在典型均匀场问题中的轨道、速度和解析参考解的一致性。

   .. rubric:: 程序结构

   - ``source_f90/main.f90`` 设置参数并依次运行四个 case。
   - ``source_f90/sub_case*.f90`` 给出每个物理算例、解析参考解和误差输出。
   - ``source_py/plot_savefig.py`` 读取 ``build/*.dat``，打印最大误差并保存图片。
   - ``make.sh`` 使用 ``gfortran -cpp -O3 -fdefault-real-8`` 编译测试程序。

   .. rubric:: 运行方式

   .. code-block:: bash

      cd tests/002_pusher/A01_Boris_3Dxyz
      bash clean.sh && bash make.sh && bash run.sh && bash plot.sh

   ``run.sh`` 会生成 ``build/case*.dat``；``plot.sh`` 会生成 ``figs_cases/*.png``。
   文档中的静态图是从一次参考运行复制到 ``docs/source/images/tests/002_pusher`` 的结果。

   .. rubric:: 输出字段

   每个 ``.dat`` 文件包含 ``step, t, x, y, z, vx, vy, vz, v2``，随后是解析位置和解析速度，最后两列为
   ``err_v = |v - v_ana|`` 和 ``err_r = |r - r_ana|``。

   .. list-table:: 测试算例
      :header-rows: 1
      :widths: 18 42 40

      * - Case
        - 设置
        - 主要检查
      * - ``case01_gyro``
        - ``E = 0``，``B`` 沿 ``z`` 方向
        - 回旋轨道和 ``v^2`` 守恒。
      * - ``case02_Eonly``
        - 只有均匀电场
        - 匀加速解析解。
      * - ``case03_ExB``
        - 均匀 ``E`` 和 ``B`` 垂直
        - 回旋运动叠加 :math:`E \times B` drift。
      * - ``case04_ExB_drift``
        - 选择初始速度消去回旋分量
        - 纯 :math:`E \times B` drift。

   .. rubric:: 参考图

   .. figure:: ../../images/tests/002_pusher/A01_Boris_3Dxyz/case01_gyro_traj_xy.png
      :align: center
      :width: 78%

      ``case01_gyro`` 的 ``x-y`` 轨道，数值轨道应跟随解析回旋轨道。

   .. figure:: ../../images/tests/002_pusher/A01_Boris_3Dxyz/case01_gyro_v2_t.png
      :align: center
      :width: 78%

      ``case01_gyro`` 的 ``v^2`` 随时间变化，用于观察磁场旋转步的速度模保持情况。

   .. figure:: ../../images/tests/002_pusher/A01_Boris_3Dxyz/case02_Eonly_x_t.png
      :align: center
      :width: 78%

      ``case02_Eonly`` 的 ``x(t)``，用于对照只有电场时的匀加速解析解。

   .. figure:: ../../images/tests/002_pusher/A01_Boris_3Dxyz/case03_ExB_traj_xy.png
      :align: center
      :width: 78%

      ``case03_ExB`` 的 ``x-y`` 轨道，展示回旋运动与 :math:`E \times B` drift。

   .. figure:: ../../images/tests/002_pusher/A01_Boris_3Dxyz/case04_drift_traj_xy.png
      :align: center
      :width: 78%

      ``case04_ExB_drift`` 的 ``x-y`` 轨道，展示无回旋分量的纯 drift 运动。

   .. rubric:: 参考文献

   [1] J.P. Boris, Relativistic plasma simulation-optimization of a hybrid code,
   in: Proceedings of the Fourth Conference on Numerical Simulation of Plasmas,
   Naval Research Laboratory, Washington, D.C., 1970, pp.3-67.

   [2] G.L. Delzanno, E. Camporeale, On particle movers in cylindrical geometry
   for Particle-In-Cell simulations, Journal of Computational Physics,
   253 (2013) 259-277. DOI: `10.1016/j.jcp.2013.07.007 <https://doi.org/10.1016/j.jcp.2013.07.007>`_

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   This page documents the reference test under
   ``tests/002_pusher/A01_Boris_3Dxyz``. The test calls
   ``sub_A01_Boris_3Dxyz(v, E, B, k)`` and checks the non-relativistic
   3D Cartesian Boris velocity pusher against analytic reference motion in
   simple uniform-field cases.

   .. rubric:: Program Structure

   - ``source_f90/main.f90`` sets the parameters and runs the four cases.
   - ``source_f90/sub_case*.f90`` defines each case, analytic reference solution, and error output.
   - ``source_py/plot_savefig.py`` reads ``build/*.dat``, prints maximum errors, and saves figures.
   - ``make.sh`` compiles the test with ``gfortran -cpp -O3 -fdefault-real-8``.

   .. rubric:: Run Command

   .. code-block:: bash

      cd tests/002_pusher/A01_Boris_3Dxyz
      bash clean.sh && bash make.sh && bash run.sh && bash plot.sh

   ``run.sh`` writes ``build/case*.dat``. ``plot.sh`` writes
   ``figs_cases/*.png``. The static figures below are copied from one
   reference run into ``docs/source/images/tests/002_pusher``.

   .. rubric:: Output Fields

   Each ``.dat`` file contains ``step, t, x, y, z, vx, vy, vz, v2``, followed
   by analytic position and velocity columns. The final two columns are
   ``err_v = |v - v_ana|`` and ``err_r = |r - r_ana|``.

   .. list-table:: Test Cases
      :header-rows: 1
      :widths: 18 42 40

      * - Case
        - Setup
        - Main check
      * - ``case01_gyro``
        - ``E = 0`` and ``B`` along ``z``
        - Gyro orbit and ``v^2`` conservation.
      * - ``case02_Eonly``
        - Uniform electric field only
        - Constant-acceleration analytic solution.
      * - ``case03_ExB``
        - Uniform perpendicular ``E`` and ``B``
        - Gyro motion plus :math:`E \times B` drift.
      * - ``case04_ExB_drift``
        - Initial velocity chosen to remove the gyro component
        - Pure :math:`E \times B` drift.

   .. rubric:: Reference Figures

   .. figure:: ../../images/tests/002_pusher/A01_Boris_3Dxyz/case01_gyro_traj_xy.png
      :align: center
      :width: 78%

      ``case01_gyro`` trajectory in the ``x-y`` plane.

   .. figure:: ../../images/tests/002_pusher/A01_Boris_3Dxyz/case01_gyro_v2_t.png
      :align: center
      :width: 78%

      ``case01_gyro`` time history of ``v^2``.

   .. figure:: ../../images/tests/002_pusher/A01_Boris_3Dxyz/case02_Eonly_x_t.png
      :align: center
      :width: 78%

      ``case02_Eonly`` comparison of ``x(t)`` with the electric-only analytic solution.

   .. figure:: ../../images/tests/002_pusher/A01_Boris_3Dxyz/case03_ExB_traj_xy.png
      :align: center
      :width: 78%

      ``case03_ExB`` trajectory showing gyro motion with :math:`E \times B` drift.

   .. figure:: ../../images/tests/002_pusher/A01_Boris_3Dxyz/case04_drift_traj_xy.png
      :align: center
      :width: 78%

      ``case04_ExB_drift`` trajectory for pure drift motion without a gyro component.

   .. rubric:: References

   [1] J.P. Boris, Relativistic plasma simulation-optimization of a hybrid code,
   in: Proceedings of the Fourth Conference on Numerical Simulation of Plasmas,
   Naval Research Laboratory, Washington, D.C., 1970, pp.3-67.

   [2] G.L. Delzanno, E. Camporeale, On particle movers in cylindrical geometry
   for Particle-In-Cell simulations, Journal of Computational Physics,
   253 (2013) 259-277. DOI: `10.1016/j.jcp.2013.07.007 <https://doi.org/10.1016/j.jcp.2013.07.007>`_
