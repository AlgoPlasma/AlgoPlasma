case_cpml_2d_rz_tez_wavepacket_ref
==================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   本测试验证 2D RZ TEz 分量组 ``Ephi,Hr,Hz`` 的 CPML 吸收效果。它把 compact CPML 域和更长的
   reference 域在 probe 点的波形相减，估计 late reflection error。CPML 总体说明见
   :doc:`CPML wave-packet 测试总览 <cpml_wavepacket>`。

   .. rubric:: 覆盖子程序

   - :doc:`mod_E01_cpml_2d_rz_tez </rst_files/E_Maxwell/E01_Maxwell_2Drz/mod_E01_cpml_2d_rz_tez>`
   - ``sub_E01_cpml_2d_rz_tez_E`` 和 ``sub_E01_cpml_2d_rz_tez_H``
   - 对应的 E01 TEz FDTD 更新核

   .. rubric:: 文件说明

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 文件
        - 作用
      * - ``test_rz_tez_wavepacket_cpml.f90``
        - 主程序：构造 TEz 波包、运行 compact/reference 对照并输出 probe 数据。
      * - ``plot_results.py``
        - 生成快照图和 probe error dB 曲线。
      * - ``make_gifs.py``
        - 可选生成 ``Ephi`` 动画。
      * - ``run_wavelength_sweep.sh`` / ``run_equal_lambda_npml_sweep.sh``
        - 扫描波长或 CPML 厚度的辅助脚本。

   .. rubric:: 运行方式

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_cpml_2d_rz_tez_wavepacket_ref
      ./run.sh 12 output_lambda12mm_npml12_weak_ephi_gif 12 3 0.02 3.5 0.012 all 136 36 450 260 200 10

   .. rubric:: 主流程

   1. 初始化有限宽度 TEz 波包。
   2. 用相同初值分别推进 compact CPML 域和更长 reference 域。
   3. 按 ``z_plus,z_minus,r_plus,r_minus`` 方向测试出射。
   4. 在主波后方 probe 记录 ``Ephi`` 波形。
   5. 用 reference 峰值归一化 compact-reference 差值。
   6. late gate 后取最大值作为 late reflection error。

   .. rubric:: 典型例子：``z_plus`` 入射的 TEz 波包

   ``test_rz_tez_wavepacket_cpml.f90`` 默认在 ``dr=dz=1 mm`` 网格上生成有限宽度
   TEz 波包，并依次检查 ``z_plus``、``z_minus``、``r_plus``、``r_minus`` 四个出射方向。
   以 ``z_plus`` 为例，compact 域在右侧放置 CPML，reference 域加长同一传播方向，
   然后比较同一 probe 上的 ``Ephi`` 波形。

   .. code-block:: fortran

      real(dp), parameter :: dr = 1.0d-3
      real(dp), parameter :: dz = 1.0d-3
      real(dp), parameter :: dt = 0.99d0/(c0*sqrt(1.0d0/dr**2 + 1.0d0/dz**2))
      real(dp) :: lambda0 = 12.0d-3
      integer :: nstep = 450
      integer :: late_gate = 260
      integer :: npml = 12

      character(len=16), dimension(4), parameter :: cases = (/ &
          'z_plus          ', 'z_minus         ', 'r_plus          ', 'r_minus         ' /)

   每个方向都运行两次：一次打开 CPML 并写快照，一次使用更长 reference 域作为近似无反射基准。
   late reflection error 由 compact/reference probe 差值归一化得到。

   .. code-block:: fortran

      call run_one_sim(cname, nr_cpml, nz_cpml, npml, rmin_cpml, zmin_cpml, &
          .true., probe_cpml, e0, e1)
      call run_one_sim(cname, nr_ref, nz_ref, npml_ref, rmin_ref, zmin_ref, &
          .false., probe_ref, e0, e1)

      ref_norm = max(maxval(abs(probe_ref)), 1.0d-300)
      err_db = 20.0d0*log10(max(abs(probe_cpml-probe_ref), 1.0d-300)/ref_norm)
      late_error_db = maxval(err_db(late_gate:nstep))

   单步推进中先做内部 FDTD 更新，再把四条 CPML 带补上记忆变量修正。TEz 例子主要观察
   ``Ephi``；``Hr`` 和 ``Hz`` 提供磁场半步更新。

   .. rubric:: 重点调用方式

   .. code-block:: fortran

      call sub_E01_fdtd_2d_rz_tez_H(...)
      call sub_E01_cpml_2d_rz_tez_H(...)
      call sub_E01_fdtd_2d_rz_tez_E(...)
      call sub_E01_cpml_2d_rz_tez_E(...)
      call record_probe_error(...)

   .. rubric:: 结果和图像

   当前参考 ``lambda0=12 mm, npml=12`` 的 late reflection error 约为 ``-49`` 到 ``-50 dB``。

   第一张快照图用来检查波包传播形态。应看到 ``Ephi`` 波包向 ``z_plus`` 边界移动，进入右侧 CPML
   后迅速衰减；如果 CPML 区域附近出现明显返回波前，说明吸收边界或参数可能有问题。

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/2d_rz_tez_ephi_snapshots_z_plus.png
      :align: center
      :width: 72%

      ``z_plus`` 方向 ``Ephi`` 波包快照。波包进入右侧 CPML 后应快速衰减。

   第二张误差图才是定量判据。曲线表示 compact CPML 域和 longer reference 域在 probe 点的归一化差异，
   单位为 dB；越负表示反射越小。应重点看 late gate 之后的峰值，而不是主波包经过 probe 时的早期瞬态。

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/2d_rz_tez_probe_error_db.png
      :align: center
      :width: 70%

      四个方向的 probe error dB 曲线；late gate 后的峰值用于判定反射水平。

   .. rubric:: 常见误读

   ``late reflection error`` 是一个 probe 点上的幅值误差，不是全局反射能量系数。TEz 的主观测量是
   ``Ephi``，不要把它和 TMz 的 ``Ez`` 图混用。

   .. include:: _contributors_zh.inc

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   This test checks CPML absorption for the 2D RZ TEz field group
   ``Ephi,Hr,Hz``. It subtracts probe waveforms from a compact CPML domain and a
   longer reference domain to estimate late reflection error. See also the
   :doc:`CPML wave-packet overview <cpml_wavepacket>`.

   .. rubric:: Covered Routines

   - :doc:`mod_E01_cpml_2d_rz_tez </rst_files/E_Maxwell/E01_Maxwell_2Drz/mod_E01_cpml_2d_rz_tez>`
   - ``sub_E01_cpml_2d_rz_tez_E`` and ``sub_E01_cpml_2d_rz_tez_H``
   - The matching E01 TEz FDTD kernels

   .. rubric:: Files

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - File
        - Role
      * - ``test_rz_tez_wavepacket_cpml.f90``
        - Main program for TEz packet generation, compact/reference runs, and probe output.
      * - ``plot_results.py``
        - Creates snapshots and probe-error dB plots.
      * - ``make_gifs.py``
        - Optionally creates ``Ephi`` animations.
      * - Sweep scripts
        - Optional wavelength or equal-wavelength/CPML-thickness sweeps.

   .. rubric:: Run Command

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_cpml_2d_rz_tez_wavepacket_ref
      ./run.sh 12 output_lambda12mm_npml12_weak_ephi_gif 12 3 0.02 3.5 0.012 all 136 36 450 260 200 10

   .. rubric:: Main Flow

   1. Initialize a finite-width TEz packet.
   2. Propagate the same initial state in compact and longer reference domains.
   3. Test ``z_plus,z_minus,r_plus,r_minus`` outgoing directions.
   4. Record ``Ephi`` at a probe behind the main packet.
   5. Normalize compact-reference error by the reference peak.
   6. Use the late-gate maximum as late reflection error.

   .. rubric:: Example: ``z_plus`` TEz Packet

   ``test_rz_tez_wavepacket_cpml.f90`` builds a finite-width TEz packet on a
   ``dr=dz=1 mm`` grid and checks ``z_plus``, ``z_minus``, ``r_plus``, and
   ``r_minus`` outgoing directions. For ``z_plus``, the compact domain places
   CPML on the right side, while the reference domain extends the same
   propagation direction. The two ``Ephi`` probe traces are then compared.

   .. code-block:: fortran

      real(dp), parameter :: dr = 1.0d-3
      real(dp), parameter :: dz = 1.0d-3
      real(dp), parameter :: dt = 0.99d0/(c0*sqrt(1.0d0/dr**2 + 1.0d0/dz**2))
      real(dp) :: lambda0 = 12.0d-3
      integer :: nstep = 450
      integer :: late_gate = 260
      integer :: npml = 12

      character(len=16), dimension(4), parameter :: cases = (/ &
          'z_plus          ', 'z_minus         ', 'r_plus          ', 'r_minus         ' /)

   Each direction is run twice: once in the compact CPML domain, with snapshots,
   and once in the longer reference domain. The late reflection error is the
   normalized compact/reference probe difference.

   .. code-block:: fortran

      call run_one_sim(cname, nr_cpml, nz_cpml, npml, rmin_cpml, zmin_cpml, &
          .true., probe_cpml, e0, e1)
      call run_one_sim(cname, nr_ref, nz_ref, npml_ref, rmin_ref, zmin_ref, &
          .false., probe_ref, e0, e1)

      ref_norm = max(maxval(abs(probe_ref)), 1.0d-300)
      err_db = 20.0d0*log10(max(abs(probe_cpml-probe_ref), 1.0d-300)/ref_norm)
      late_error_db = maxval(err_db(late_gate:nstep))

   A time step first advances the interior FDTD region, then applies memory
   variable corrections in the CPML strips. The TEz example mainly monitors
   ``Ephi``; ``Hr`` and ``Hz`` are the staggered magnetic components.

   .. rubric:: Core Call Pattern

   .. code-block:: fortran

      call sub_E01_fdtd_2d_rz_tez_H(...)
      call sub_E01_cpml_2d_rz_tez_H(...)
      call sub_E01_fdtd_2d_rz_tez_E(...)
      call sub_E01_cpml_2d_rz_tez_E(...)
      call record_probe_error(...)

   .. rubric:: Results and Figures

   For ``lambda0=12 mm, npml=12``, reference late reflection error is about
   ``-49`` to ``-50 dB``.

   The snapshot figure is for reading the packet shape. ``Ephi`` should move
   toward the ``z_plus`` boundary and decay rapidly once it enters the right-side
   CPML. A clear returning wavefront near the CPML side would indicate a boundary
   or parameter problem.

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/2d_rz_tez_ephi_snapshots_z_plus.png
      :align: center
      :width: 72%

      ``Ephi`` snapshots for the ``z_plus`` direction.

   The probe-error figure is the quantitative diagnostic. It plots the normalized
   compact-domain/reference-domain probe difference in dB; more negative values
   mean lower reflection. Focus on the peak after the late gate, not on the early
   transient while the main packet passes the probe.

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/2d_rz_tez_probe_error_db.png
      :align: center
      :width: 70%

      Probe-error curves for the four directions.

   .. rubric:: Common Pitfall

   Late reflection error is a probe amplitude error, not a global reflected
   energy coefficient. TEz is monitored mainly through ``Ephi``; do not mix it
   with TMz ``Ez`` plots.

   .. include:: _contributors_en.inc
