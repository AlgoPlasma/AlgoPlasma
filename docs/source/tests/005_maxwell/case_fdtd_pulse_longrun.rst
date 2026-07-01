case_fdtd_pulse_longrun
=======================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   ``case_fdtd_pulse_longrun`` 先用一个短时、局域、光滑脉冲激励场量，再关闭源项长时间传播。
   它比纯无源稳定性测试更接近“有扰动进入系统后是否慢增长”的场景。

   .. rubric:: 覆盖子程序

   覆盖 E01 2D RZ TEz/TMz、E02 3D cylindrical ``m=0``/``m=1`` 和 E03 3D Cartesian
   的 FDTD 更新核。

   .. rubric:: 文件说明

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 文件
        - 作用
      * - ``test_pulse_*.f90``
        - 五个带短脉冲的长跑主程序。
      * - ``pulse_common.f90``
        - 能量、轴线带、第一环和增长率监控。
      * - ``pulse_longrun_summary.csv``
        - ``case_name,CFL,Npulse,Ntotal,final_energy_ratio,post_pulse_growth_rate,result``。
      * - ``logs/*.log``
        - 每个 case 的时间序列监控。

   .. rubric:: 运行方式

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_fdtd_pulse_longrun
      bash run.sh

   可选：``bash run.sh 50000 200 80 5e-5``，参数为 ``Ntotal monitor_every Npulse pulse_amp``。

   .. rubric:: 主流程

   1. 初始化零场或小幅背景场。
   2. 在前 ``Npulse`` 步加入 ``sin^2`` 时间包络和 Gaussian 空间包络源项。
   3. 每步执行 ``H`` 更新、边界填充、``E`` 更新。
   4. ``Npulse`` 后完全关闭源项。
   5. 记录脉冲结束时能量 ``E_at_pulse_end``。
   6. 长时间传播后计算 ``final_energy_ratio`` 和 ``post_pulse_growth_rate``。

   .. rubric:: 典型例子：3D cylindrical ``m=1`` 脉冲长跑

   ``test_pulse_3d_cyl_m1.f90`` 是最敏感的一个子例子，因为它同时包含 ``phi`` 周期缝、
   轴线附近处理和 cylindrical metric。默认设置为 ``nr=40,nphi=32,nz=64``，总步数
   ``20000``，前 ``60`` 步加入幅值 ``1e-4`` 的短脉冲，之后完全无源传播。

   .. code-block:: fortran

      integer, parameter :: nsteps_default = 20000
      integer, parameter :: npulse_default = 60
      real, parameter :: pulse_amp_default = 1.0e-4

      call parse_int_arg(1, nsteps_default, nsteps)
      call parse_int_arg(3, npulse_default, npulse)
      call parse_real_arg(4, pulse_amp_default, pulse_amp)

   主循环和稳定性测试类似，但在 ``E`` 更新之后、边界填充之前给 ``Ez`` 加入局域脉冲源。
   当 ``n == npulse`` 时，测试记录 ``energy_pulse_end``，后续所有增长率都相对于这个“源项关闭时刻”来解释。

   .. code-block:: fortran

      call sub_E02_fdtd_3d_cylindrical_H(..., Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,mu)
      call fill_h_boundaries(nr,nphi,nz,Hr,Hphi,Hz)

      call sub_E02_fdtd_3d_cylindrical_E(..., Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,ep)
      if (n <= npulse) call add_pulse_source(n,npulse,pulse_amp,nr,nphi,nz,dr,dphi,dz,Ez)
      call fill_e_boundaries(nr,nphi,nz,Er,Ephi,Ez)

      if (n == npulse) energy_pulse_end = total_energy

   .. rubric:: 重点调用方式

   .. code-block:: text

      call sub_*_H(...)
      call fill_h_boundaries(...)
      call sub_*_E(...)
      if (n <= Npulse) call add_pulse_source(...)
      call monitor_post_pulse_growth(...)

   .. rubric:: 结果判断

   ``final_energy_ratio = E_final / E_at_pulse_end``，``post_pulse_growth_rate`` 是脉冲结束后的对数增长率。
   3D cylindrical ``m=1`` 的当前参考结果：

   .. code-block:: text

      SUMMARY_CSV,3D_CYL_M1,0.800,60,20000,1.0088E+00,2.2835E-04,stable

   .. rubric:: 常见误读

   脉冲后能量不一定单调下降，因为这里没有吸收边界，周期方向会发生回绕。判据关注的是脉冲关闭后是否出现持续增长或发散。

   .. include:: _contributors_zh.inc

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   ``case_fdtd_pulse_longrun`` injects a short localized smooth pulse, then
   turns the source off and propagates for a long time. It is closer than a
   pure no-source test to the question: does the scheme slowly grow after a
   finite disturbance enters the system?

   .. rubric:: Covered Routines

   The tests cover E01 2D RZ TEz/TMz, E02 3D cylindrical ``m=0``/``m=1``, and
   E03 3D Cartesian FDTD kernels.

   .. rubric:: Files

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - File
        - Role
      * - ``test_pulse_*.f90``
        - Five long-run drivers with a short pulse.
      * - ``pulse_common.f90``
        - Energy, axis-band, first-ring, and growth-rate monitors.
      * - ``pulse_longrun_summary.csv``
        - Summary columns for case, CFL, pulse length, total steps, energy ratio, growth rate, and result.
      * - ``logs/*.log``
        - Per-case time-history monitors.

   .. rubric:: Run Command

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_fdtd_pulse_longrun
      bash run.sh

   Optional: ``bash run.sh 50000 200 80 5e-5`` sets
   ``Ntotal monitor_every Npulse pulse_amp``.

   .. rubric:: Main Flow

   1. Initialize zero or small background fields.
   2. For the first ``Npulse`` steps, add a ``sin^2`` temporal envelope and Gaussian spatial pulse.
   3. Advance ``H``, fill boundaries, and advance ``E`` each step.
   4. Disable the source completely after ``Npulse``.
   5. Record energy at pulse end.
   6. Compute ``final_energy_ratio`` and ``post_pulse_growth_rate`` after the long run.

   .. rubric:: Example: 3D Cylindrical ``m=1`` Pulse Long Run

   ``test_pulse_3d_cyl_m1.f90`` is the most sensitive subcase because it includes
   the ``phi`` periodic seam, near-axis handling, and cylindrical metric terms.
   The default grid is ``nr=40,nphi=32,nz=64``. It runs ``20000`` steps, injects a
   ``1e-4`` pulse for the first ``60`` steps, and then propagates with no source.

   .. code-block:: fortran

      integer, parameter :: nsteps_default = 20000
      integer, parameter :: npulse_default = 60
      real, parameter :: pulse_amp_default = 1.0e-4

      call parse_int_arg(1, nsteps_default, nsteps)
      call parse_int_arg(3, npulse_default, npulse)
      call parse_real_arg(4, pulse_amp_default, pulse_amp)

   The main loop resembles the stability test, but it adds a localized pulse to
   ``Ez`` after the electric update and before the electric boundary fill. When
   ``n == npulse``, the test records ``energy_pulse_end``; all post-pulse growth
   metrics are interpreted relative to the source-off moment.

   .. code-block:: fortran

      call sub_E02_fdtd_3d_cylindrical_H(..., Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,mu)
      call fill_h_boundaries(nr,nphi,nz,Hr,Hphi,Hz)

      call sub_E02_fdtd_3d_cylindrical_E(..., Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,ep)
      if (n <= npulse) call add_pulse_source(n,npulse,pulse_amp,nr,nphi,nz,dr,dphi,dz,Ez)
      call fill_e_boundaries(nr,nphi,nz,Er,Ephi,Ez)

      if (n == npulse) energy_pulse_end = total_energy

   .. rubric:: Core Call Pattern

   .. code-block:: text

      call sub_*_H(...)
      call fill_h_boundaries(...)
      call sub_*_E(...)
      if (n <= Npulse) call add_pulse_source(...)
      call monitor_post_pulse_growth(...)

   .. rubric:: Result Interpretation

   ``final_energy_ratio = E_final / E_at_pulse_end``. The growth rate is the
   post-pulse logarithmic energy growth rate. Current 3D cylindrical ``m=1``
   reference output:

   .. code-block:: text

      SUMMARY_CSV,3D_CYL_M1,0.800,60,20000,1.0088E+00,2.2835E-04,stable

   .. rubric:: Common Pitfall

   Post-pulse energy need not decrease monotonically because these runs do not
   use absorbing boundaries; periodic directions can wrap. The criterion is
   persistent post-source growth or divergence.

   .. include:: _contributors_en.inc
