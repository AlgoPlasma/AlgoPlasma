case_fdtd_stability
===================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   ``case_fdtd_stability`` 在无源条件下长时间推进核心 FDTD 内核，检查总能量和场幅值是否保持有界。
   它用于发现轴线、周期缝、外半径 ghost 或 metric 项带来的慢增长。

   .. rubric:: 覆盖子程序

   覆盖 E01 2D RZ TEz/TMz 和 E02 3D cylindrical ``m=0``/``m=1`` 的 FDTD 更新核。

   .. rubric:: 文件说明

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 文件
        - 作用
      * - ``test_stability_*.f90``
        - 四个无源长跑主程序。
      * - ``stability_common.f90``
        - 能量、最大场幅值、轴线带和第一环监控。
      * - ``stability_summary.csv``
        - ``case_name,CFL,nsteps,final_energy_ratio,max_abs_E,max_abs_H,result``。
      * - ``logs/*.log``
        - 每个 case 的逐步监控输出。

   .. rubric:: 运行方式

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_fdtd_stability
      bash run.sh

   可选：``bash run.sh 50000 200``，参数为 ``nsteps monitor_every``。

   .. rubric:: 主流程

   1. 构造小幅光滑初始扰动，不添加任何源项。
   2. 每步先填充电场 ghost/周期边界，再调用 ``H`` 更新。
   3. 填充磁场 ghost/周期边界，再调用 ``E`` 更新。
   4. 对 cylindrical case 强制轴线特殊关系。
   5. 周期性输出最大场幅值、总能量、轴线带和第一环幅值。
   6. 根据能量增长和 NaN/Inf 情况给出 ``stable/marginal/unstable``。

   .. rubric:: 典型例子：3D cylindrical ``m=0`` 无源稳定性

   ``test_stability_3d_cyl_m0.f90`` 是检查轴线和 cylindrical metric 的代表例子。它设置
   ``nr=40,nphi=32,nz=64``、``ep=mu=1``、``cfl_scale=0.8``，初始场幅值只有 ``1e-4``。
   这个小扰动不是物理源，而是为了让所有更新分支都有非零输入。

   .. code-block:: fortran

      integer, parameter :: nr = 40, nphi = 32, nz = 64
      real, parameter :: ep = 1.0, mu = 1.0
      real, parameter :: cfl_scale = 0.8
      real, parameter :: amp0 = 1.0e-4
      integer, parameter :: nsteps_default = 20000

      dt_crit = 1.0/(c0*sqrt((1.0/dr)**2 + (1.0/dz)**2 + &
                 (1.0/(0.5*dr*dphi))**2))
      dt = cfl_scale*dt_crit

   每步推进后，测试显式执行 ``enforce_hr_axis``、``enforce_e_axis`` 和边界填充，然后用
   ``compute_metrics`` 记录总能量、最大场幅值、轴线带和第一环幅值。判据关注长期是否出现持续增长、
   NaN 或 Inf，而不是要求能量逐步严格不变。

   .. code-block:: fortran

      call sub_E02_fdtd_3d_cylindrical_H(..., Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,mu)
      call enforce_hr_axis(nr,nphi,nz,Hr,Hphi)
      call fill_h_boundaries(nr,nphi,nz,Hr,Hphi,Hz)

      call sub_E02_fdtd_3d_cylindrical_E(..., Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,ep)
      call enforce_e_axis(nr,nphi,nz,Er,Ephi)
      call fill_e_boundaries(nr,nphi,nz,Er,Ephi,Ez)

   .. rubric:: 重点调用方式

   .. code-block:: text

      call fill_e_boundaries(...)
      call sub_*_H(...)
      call fill_h_boundaries(...)
      call sub_*_E(...)
      call monitor_energy_and_axis_bands(...)

   .. rubric:: 结果判断

   默认 ``CFL=0.8, nsteps=20000`` 的最新基线：

   .. code-block:: text

      2D_RZ_TMz   final_energy_ratio=9.5997E-01  stable
      2D_RZ_TEz   final_energy_ratio=1.0114E+00  stable
      3D_CYL_M0   final_energy_ratio=9.8467E-01  stable
      3D_CYL_M1   final_energy_ratio=9.4779E-01  stable

   .. rubric:: 常见误读

   ``stable`` 不表示能量严格守恒；这些测试没有 PML/ABC，边界是测试用周期或 ghost 闭合。
   3D cylindrical ``m=1`` 的 ``Hz`` 径向项含 ``r*Ephi``，外半径 ``Ephi`` ghost 也必须按
   ``r*Ephi`` 一致填充，否则会出现外边界慢增长。

   .. include:: _contributors_zh.inc

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   ``case_fdtd_stability`` advances core FDTD kernels for a long no-source run
   and checks whether total energy and field amplitudes remain bounded. It is
   intended to catch slow growth from axis handling, periodic seams,
   outer-radius ghosts, or metric terms.

   .. rubric:: Covered Routines

   The tests cover E01 2D RZ TEz/TMz and E02 3D cylindrical ``m=0``/``m=1``
   FDTD kernels.

   .. rubric:: Files

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - File
        - Role
      * - ``test_stability_*.f90``
        - Four no-source long-run drivers.
      * - ``stability_common.f90``
        - Energy, maximum field, axis-band, and first-ring monitors.
      * - ``stability_summary.csv``
        - Summary columns for case, CFL, steps, energy ratio, final amplitudes, and result.
      * - ``logs/*.log``
        - Per-case monitor history.

   .. rubric:: Run Command

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_fdtd_stability
      bash run.sh

   Optional: ``bash run.sh 50000 200`` sets ``nsteps monitor_every``.

   .. rubric:: Main Flow

   1. Build a small smooth initial perturbation with no source.
   2. Fill electric ghosts/periodic boundaries, then call the ``H`` update.
   3. Fill magnetic ghosts/periodic boundaries, then call the ``E`` update.
   4. Apply cylindrical axis special handling where needed.
   5. Periodically print maximum amplitudes, total energy, axis-band, and first-ring values.
   6. Classify the run as ``stable``, ``marginal``, or ``unstable``.

   .. rubric:: Example: 3D Cylindrical ``m=0`` No-Source Stability

   ``test_stability_3d_cyl_m0.f90`` is a representative check for axis handling
   and cylindrical metric terms. It uses ``nr=40,nphi=32,nz=64``, ``ep=mu=1``,
   ``cfl_scale=0.8``, and an initial amplitude of only ``1e-4``. This small
   perturbation is not a physical source; it simply gives the update branches
   nonzero inputs.

   .. code-block:: fortran

      integer, parameter :: nr = 40, nphi = 32, nz = 64
      real, parameter :: ep = 1.0, mu = 1.0
      real, parameter :: cfl_scale = 0.8
      real, parameter :: amp0 = 1.0e-4
      integer, parameter :: nsteps_default = 20000

      dt_crit = 1.0/(c0*sqrt((1.0/dr)**2 + (1.0/dz)**2 + &
                 (1.0/(0.5*dr*dphi))**2))
      dt = cfl_scale*dt_crit

   After each advance, the test explicitly applies axis enforcement and boundary
   fills, then records total energy, maximum field amplitude, axis-band values,
   and first-ring values. The criterion looks for persistent growth, NaN, or
   Inf rather than exact step-by-step energy constancy.

   .. code-block:: fortran

      call sub_E02_fdtd_3d_cylindrical_H(..., Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,mu)
      call enforce_hr_axis(nr,nphi,nz,Hr,Hphi)
      call fill_h_boundaries(nr,nphi,nz,Hr,Hphi,Hz)

      call sub_E02_fdtd_3d_cylindrical_E(..., Er,Ephi,Ez,Hr,Hphi,Hz,dt,dr,dphi,dz,ep)
      call enforce_e_axis(nr,nphi,nz,Er,Ephi)
      call fill_e_boundaries(nr,nphi,nz,Er,Ephi,Ez)

   .. rubric:: Core Call Pattern

   .. code-block:: text

      call fill_e_boundaries(...)
      call sub_*_H(...)
      call fill_h_boundaries(...)
      call sub_*_E(...)
      call monitor_energy_and_axis_bands(...)

   .. rubric:: Result Interpretation

   Current baseline for ``CFL=0.8, nsteps=20000``:

   .. code-block:: text

      2D_RZ_TMz   final_energy_ratio=9.5997E-01  stable
      2D_RZ_TEz   final_energy_ratio=1.0114E+00  stable
      3D_CYL_M0   final_energy_ratio=9.8467E-01  stable
      3D_CYL_M1   final_energy_ratio=9.4779E-01  stable

   .. rubric:: Common Pitfall

   ``stable`` does not mean exact energy conservation. These tests use test
   periodic/ghost closures, not PML or ABC. For cylindrical ``m=1``, the
   ``Hz`` radial term differentiates ``r*Ephi``; the outer ``Ephi`` ghost must
   be consistent with that metric weighting.

   .. include:: _contributors_en.inc
