A02_Boris_3Drtz Test
====================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   本页说明 ``tests/002_pusher/A02_Boris_3Drtz`` 中的参考测试。该测试调用
   ``sub_A02_Boris_3Drtz_push_v_x(x, v, E, B, k, dt)``，检查非相对论柱坐标
   ``(r,\theta,z)`` Boris 推进器（同时更新位置和速度）在与 A01 对应的
   四个均匀场算例下的轨道、速度和解析参考解的一致性。

   .. rubric:: 跟 A01 的关键差异

   - **接口**：A02 是 ``(x, v, E, B, k, dt)``——子程序内部完成位置更新，
     不需要调用方再做 ``r = r + v*dt``。
   - **坐标系**：位置 ``x = (r, \theta, z)``，速度 ``v = (v_r, v_\theta, v_z)``，
     电磁场 ``E``、``B`` 也按柱坐标分量传入。
   - **初值位移**：四个 case 都把粒子的初始 Cartesian 位置从原点平移到
     ``(x_0, 0, 0)``，其中 ``x_0 = 1.0``，以避开 ``r = 0`` 奇点。
   - **case 1 初始速度调整**：A02 case 1 用 ``v_init = (0, v_0, 0)`` Cartesian
     （A01 用 ``(v_0, 0, 0)``），让回旋圆心位于 +x 方向，整个轨道 ``r`` 始终大于 ``x_0``。
   - **每步重算 cylindrical 场**：均匀 Cartesian 场 ``E_x = E_0``
     在柱坐标里随 ``\theta`` 旋转，每步从 Cartesian 输入按
     ``E_r = E_0 \cos\theta``、``E_\phi = -E_0 \sin\theta`` 重算。

   .. rubric:: 程序结构

   - ``source_f90/main.f90`` 设置参数并依次运行四个 case。
   - ``source_f90/sub_case*.f90`` 给出每个物理算例、解析参考解和误差输出；
     模拟值从柱坐标 ``(r, \theta, z, v_r, v_\theta, v_z)`` 转换回 Cartesian
     ``(x, y, z, v_x, v_y, v_z)`` 后再跟 A01 同款的 Cartesian 解析解比较。
   - ``source_py/plot_savefig.py`` 读取 ``build/*.dat``，打印最大误差并保存图片
     （与 A01 同款，因为输出列格式一致）。
   - ``make.sh`` 使用 ``gfortran -cpp -O3 -fdefault-real-8`` 编译测试程序。

   .. rubric:: 运行方式

   .. code-block:: bash

      cd tests/002_pusher/A02_Boris_3Drtz
      bash clean.sh && bash make.sh && bash run.sh && bash plot.sh

   ``run.sh`` 会生成 ``build/case*.dat``；``plot.sh`` 会生成 ``figs_cases/*.png``。
   文档中的静态图是从一次参考运行复制到 ``docs/source/images/tests/002_pusher`` 的结果。

   .. rubric:: 输出字段

   每个 ``.dat`` 文件的列与 A01 完全一致：
   ``step, t, x, y, z, vx, vy, vz, v2``，随后是解析位置和解析速度，
   最后两列为 ``err_v = |v - v_ana|`` 和 ``err_r = |r - r_ana|``。
   注意这里的 ``(x, y, z, vx, vy, vz)`` 是 **柱坐标模拟值转回 Cartesian** 后的结果，
   方便直接跟 A01 的解析解逐分量比对。

   .. list-table:: 测试算例
      :header-rows: 1
      :widths: 18 42 40

      * - Case
        - 设置（Cartesian）
        - 主要检查
      * - ``case01_gyro``
        - ``E = 0``，``B`` 沿 ``z``，``v_{init} = (0, v_0, 0)``
        - 偏移圆心的回旋轨道和 ``v^2`` 守恒。
      * - ``case02_Eonly``
        - 只有均匀电场 ``E = (E_x, 0, 0)``，``v_{init} = 0``
        - 沿 ``+x`` 的匀加速解析解，``\theta`` 全程为 0。
      * - ``case03_ExB``
        - 均匀 ``E = (E_x, 0, 0)``、``B = (0, 0, B_0)``，带初速
        - 回旋运动叠加 :math:`E \times B` drift；``\theta`` 随轨迹变化。
      * - ``case04_ExB_drift``
        - 选择初速 ``(0, -E_x/B_0, 0)`` 消去回旋分量
        - 纯 :math:`E \times B` drift；``\theta`` 单调向 ``-\pi/2`` 趋近。

   .. rubric:: 参考结果

   与 A01 在同样的物理参数下对比，A02 给出几乎相同量级的逐 case 误差：

   .. list-table::
      :header-rows: 1
      :widths: 18 22 22 22 22

      * - Case
        - A01 max ``|v - v_{ana}|``
        - A02 max ``|v - v_{ana}|``
        - A01 max ``|r - r_{ana}|``
        - A02 max ``|r - r_{ana}|``
      * - gyro
        - 3.83e-7
        - 9.66e-7
        - 1.00e+5
        - 1.00e+5
      * - Eonly
        - 2.19e-13
        - 2.19e-13
        - 4.00e-3
        - 4.00e-3
      * - ExB
        - 6.00e-7
        - 6.00e-7
        - 8.60e-4
        - 8.60e-4
      * - drift
        - 6.00e-7
        - 6.00e-7
        - 1.25e-6
        - 1.25e-6

   位置误差 **逐 case 完全一致**，验证柱坐标 Boris 在物理上等价于 Cartesian Boris。
   case 1 的速度误差略大（cos/sin/sqrt/atan2 引入的额外舍入），其余三个 case 完全相同。

   .. rubric:: 参考图

   .. figure:: ../../images/tests/002_pusher/A02_Boris_3Drtz/case01_gyro_traj_xy.png
      :align: center
      :width: 78%

      ``case01_gyro`` 的 ``x-y`` 轨道（柱坐标模拟值转回 Cartesian 后），
      数值轨道应跟随解析回旋轨道。

   .. figure:: ../../images/tests/002_pusher/A02_Boris_3Drtz/case01_gyro_v2_t.png
      :align: center
      :width: 78%

      ``case01_gyro`` 的 ``v^2`` 随时间变化，用于观察磁场旋转步的速度模保持情况。

   .. figure:: ../../images/tests/002_pusher/A02_Boris_3Drtz/case02_Eonly_x_t.png
      :align: center
      :width: 78%

      ``case02_Eonly`` 的 ``x(t)``，``\theta`` 全程为 0，曲线退化成 1D 匀加速。

   .. figure:: ../../images/tests/002_pusher/A02_Boris_3Drtz/case03_ExB_traj_xy.png
      :align: center
      :width: 78%

      ``case03_ExB`` 的 ``x-y`` 轨道，柱坐标 Boris 仍能正确给出回旋 + drift 的摆线轨迹。

   .. figure:: ../../images/tests/002_pusher/A02_Boris_3Drtz/case04_drift_traj_xy.png
      :align: center
      :width: 78%

      ``case04_ExB_drift`` 的 ``x-y`` 轨道，沿 ``-y`` 方向匀速漂移，
      无回旋分量。

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
   ``tests/002_pusher/A02_Boris_3Drtz``. The test calls
   ``sub_A02_Boris_3Drtz_push_v_x(x, v, E, B, k, dt)`` and checks the
   non-relativistic cylindrical ``(r,\theta,z)`` Boris pusher (which advances
   both position and velocity in one call) against analytic reference motion
   in the same four uniform-field cases as A01.

   .. rubric:: Key Differences from A01

   - **Interface**: A02 takes ``(x, v, E, B, k, dt)``. The subroutine performs
     the position update internally; the caller does not append
     ``r = r + v*dt``.
   - **Coordinates**: position ``x = (r, \theta, z)`` and velocity
     ``v = (v_r, v_\theta, v_z)``; the ``E`` and ``B`` inputs are also in
     cylindrical components.
   - **Initial offset**: all four cases shift the Cartesian starting position
     from the origin to ``(x_0, 0, 0)`` with ``x_0 = 1.0`` to avoid the
     ``r = 0`` singularity.
   - **Case 1 initial velocity**: A02 case 1 uses Cartesian
     ``v_{init} = (0, v_0, 0)`` (A01 uses ``(v_0, 0, 0)``) so the gyro center
     sits on the +x side and the orbit always satisfies ``r \ge x_0``.
   - **Per-step field conversion**: a uniform Cartesian ``E_x = E_0`` field
     has ``\theta``-dependent cylindrical components, recomputed each step as
     ``E_r = E_0 \cos\theta``, ``E_\phi = -E_0 \sin\theta``.

   .. rubric:: Program Structure

   - ``source_f90/main.f90`` sets the parameters and runs the four cases.
   - ``source_f90/sub_case*.f90`` defines each case and the analytic reference
     solution; simulated cylindrical state is converted back to Cartesian
     ``(x, y, z, v_x, v_y, v_z)`` before being compared to the same Cartesian
     analytic solution used in A01.
   - ``source_py/plot_savefig.py`` reads ``build/*.dat``, prints maximum
     errors, and saves figures (identical to A01 because the column format
     matches).
   - ``make.sh`` compiles the test with ``gfortran -cpp -O3 -fdefault-real-8``.

   .. rubric:: Run Command

   .. code-block:: bash

      cd tests/002_pusher/A02_Boris_3Drtz
      bash clean.sh && bash make.sh && bash run.sh && bash plot.sh

   ``run.sh`` writes ``build/case*.dat``. ``plot.sh`` writes
   ``figs_cases/*.png``. The static figures below are copied from one
   reference run into ``docs/source/images/tests/002_pusher``.

   .. rubric:: Output Fields

   Each ``.dat`` file uses the same columns as A01:
   ``step, t, x, y, z, vx, vy, vz, v2``, followed by analytic position and
   velocity columns, with the final two columns being
   ``err_v = |v - v_{ana}|`` and ``err_r = |r - r_{ana}|``. Note that
   ``(x, y, z, vx, vy, vz)`` are the **simulated cylindrical state converted
   back to Cartesian** so they can be directly compared with the same
   Cartesian analytic solutions used in A01.

   .. list-table:: Test Cases
      :header-rows: 1
      :widths: 18 42 40

      * - Case
        - Setup (Cartesian)
        - Main check
      * - ``case01_gyro``
        - ``E = 0``, ``B`` along ``z``, ``v_{init} = (0, v_0, 0)``
        - Gyro orbit (with offset center) and ``v^2`` conservation.
      * - ``case02_Eonly``
        - Uniform ``E = (E_x, 0, 0)``, ``v_{init} = 0``
        - Constant-acceleration along ``+x``; ``\theta`` stays at 0.
      * - ``case03_ExB``
        - Uniform ``E = (E_x, 0, 0)``, ``B = (0, 0, B_0)``, with initial velocity
        - Gyro motion plus :math:`E \times B` drift; ``\theta`` varies along the trajectory.
      * - ``case04_ExB_drift``
        - Initial velocity ``(0, -E_x/B_0, 0)`` chosen to remove the gyro component
        - Pure :math:`E \times B` drift; ``\theta`` approaches ``-\pi/2``.

   .. rubric:: Reference Results

   Run under the same physical parameters as A01, A02 produces case-by-case
   errors of essentially the same magnitude:

   .. list-table::
      :header-rows: 1
      :widths: 18 22 22 22 22

      * - Case
        - A01 max ``|v - v_{ana}|``
        - A02 max ``|v - v_{ana}|``
        - A01 max ``|r - r_{ana}|``
        - A02 max ``|r - r_{ana}|``
      * - gyro
        - 3.83e-7
        - 9.66e-7
        - 1.00e+5
        - 1.00e+5
      * - Eonly
        - 2.19e-13
        - 2.19e-13
        - 4.00e-3
        - 4.00e-3
      * - ExB
        - 6.00e-7
        - 6.00e-7
        - 8.60e-4
        - 8.60e-4
      * - drift
        - 6.00e-7
        - 6.00e-7
        - 1.25e-6
        - 1.25e-6

   Position errors are **identical case-by-case**, confirming that the
   cylindrical Boris is physically equivalent to the Cartesian one. The
   slightly larger velocity error in case 1 reflects extra rounding from
   ``cos/sin/sqrt/atan2``; the other three cases match exactly.

   .. rubric:: Reference Figures

   .. figure:: ../../images/tests/002_pusher/A02_Boris_3Drtz/case01_gyro_traj_xy.png
      :align: center
      :width: 78%

      ``case01_gyro`` trajectory in the ``x-y`` plane (cylindrical simulation
      converted back to Cartesian) tracking the analytic gyro orbit.

   .. figure:: ../../images/tests/002_pusher/A02_Boris_3Drtz/case01_gyro_v2_t.png
      :align: center
      :width: 78%

      ``case01_gyro`` time history of ``v^2``.

   .. figure:: ../../images/tests/002_pusher/A02_Boris_3Drtz/case02_Eonly_x_t.png
      :align: center
      :width: 78%

      ``case02_Eonly`` comparison of ``x(t)`` with the electric-only analytic
      solution. ``\theta`` stays at 0, so the trajectory is effectively 1D.

   .. figure:: ../../images/tests/002_pusher/A02_Boris_3Drtz/case03_ExB_traj_xy.png
      :align: center
      :width: 78%

      ``case03_ExB`` trajectory showing the cylindrical Boris correctly
      reproducing the gyro + :math:`E \times B` cycloid.

   .. figure:: ../../images/tests/002_pusher/A02_Boris_3Drtz/case04_drift_traj_xy.png
      :align: center
      :width: 78%

      ``case04_ExB_drift`` trajectory drifting uniformly in ``-y`` with no
      gyro component.

   .. rubric:: References

   [1] J.P. Boris, Relativistic plasma simulation-optimization of a hybrid code,
   in: Proceedings of the Fourth Conference on Numerical Simulation of Plasmas,
   Naval Research Laboratory, Washington, D.C., 1970, pp.3-67.

   [2] G.L. Delzanno, E. Camporeale, On particle movers in cylindrical geometry
   for Particle-In-Cell simulations, Journal of Computational Physics,
   253 (2013) 259-277. DOI: `10.1016/j.jcp.2013.07.007 <https://doi.org/10.1016/j.jcp.2013.07.007>`_
