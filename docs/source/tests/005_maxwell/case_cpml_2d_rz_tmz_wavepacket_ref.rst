case_cpml_2d_rz_tmz_wavepacket_ref
==================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   本测试验证 2D RZ TMz 分量组 ``Er,Hphi,Ez`` 的 CPML 吸收效果。它使用 compact/reference
   双域 probe 对比来判断有限厚度 CPML 的晚期反射。总体方法见 :doc:`CPML wave-packet 测试总览 <cpml_wavepacket>`。

   .. rubric:: 覆盖子程序

   - :doc:`mod_E01_cpml_2d_rz_tmz </rst_files/E_Maxwell/E01_Maxwell_2Drz/mod_E01_cpml_2d_rz_tmz>`
   - ``sub_E01_cpml_2d_rz_tmz_E`` 和 ``sub_E01_cpml_2d_rz_tmz_H``
   - 对应的 E01 TMz FDTD 更新核

   .. rubric:: 文件说明

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 文件
        - 作用
      * - ``test_rz_tmz_wavepacket_cpml.f90``
        - 主程序：运行 TMz 波包 compact/reference 对照。
      * - ``plot_results.py``
        - 生成 ``Er/Ez/Hphi`` 快照和 probe error dB 曲线。
      * - ``run.sh``
        - 编译、运行、后处理并写入输出目录。
      * - ``output_*``
        - 保存 probe 数据、快照图和误差图。

   .. rubric:: 运行方式

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_cpml_2d_rz_tmz_wavepacket_ref
      ./run.sh 12 output_lambda12mm_npml14 14 3 0.02 3.5 0.012 all 136 36 450 260 200 0

   .. rubric:: 主流程

   1. 构造 TMz 有限宽度波包。
   2. 对 ``z_plus,z_minus,r_plus`` 三个方向分别运行 compact/reference。
   3. 轴线 ``r=0`` 是几何轴线，因此不单独测试 ``r_minus`` CPML。
   4. 记录 probe 处的 ``Ez`` 或相关 TMz 分量。
   5. 计算 late gate 后的最大归一化误差。

   .. rubric:: 典型例子：``r_plus`` 出射的 TMz 波包

   ``test_rz_tmz_wavepacket_cpml.f90`` 默认用 ``lambda0=12 mm`` 的有限宽度 TMz
   波包检查 ``z_plus``、``z_minus`` 和 ``r_plus``。其中 ``r_plus`` 是外半径吸收边界，
   也是这组测试里更敏感的方向；``r_minus`` 不设 CPML，因为 ``r=0`` 是轴线条件。
   为了和 TEz 波包算例保持可比性，这里采用同样的中心波长，并把 TMz 的 compact CPML
   厚度设为 ``npml=14`` 以补偿径向 ``Ez`` 对反射更敏感的特点。

   .. code-block:: fortran

      real(dp), parameter :: dr = 1.0d-3
      real(dp), parameter :: dz = 1.0d-3
      real(dp), parameter :: dt = 0.80d0/(c0*sqrt(1.0d0/dr**2 + 1.0d0/dz**2))
      real(dp) :: lambda0 = 12.0d-3
      integer :: nstep = 450
      integer :: late_gate = 260
      integer :: npml = 14

      character(len=16), dimension(3), parameter :: cases = (/ &
          'z_plus          ', 'z_minus         ', 'r_plus          ' /)

   每个 case 使用相同的初始波包，先在 compact CPML 域中推进，再在更长 reference 域中推进。
   probe 误差以 reference 峰值归一化，并在 ``late_gate:nstep`` 区间取最大 dB 值。

   .. code-block:: fortran

      call run_one_sim(cname, nr_cpml, nz_cpml, npml, zmin_cpml, &
          .true., probe_cpml, e0_cpml, e1_cpml)
      call run_one_sim(cname, nr_ref, nz_ref, npml_ref, zmin_ref, &
          .false., probe_ref, e0_ref, e1_ref)

      ref_norm = max(maxval(abs(probe_ref)), 1.0d-300)
      err_db = 20.0d0*log10(max(abs(probe_cpml-probe_ref), 1.0d-300)/ref_norm)
      late_error_db = maxval(err_db(late_gate:nstep))

   TMz 推进先更新 ``Hphi``，再更新 ``Er`` 和 ``Ez``。CPML 修正分别作用在 z 向带和
   外半径带，轴线附近的 ``Er/Ez`` 更新仍由普通 FDTD 和轴线处理负责。

   .. rubric:: 重点调用方式

   .. code-block:: fortran

      call sub_E01_fdtd_2d_rz_tmz_H(...)
      call sub_E01_cpml_2d_rz_tmz_H(...)
      call sub_E01_fdtd_2d_rz_tmz_E(...)
      call sub_E01_cpml_2d_rz_tmz_E(...)
      call compare_probe_with_reference(...)

   .. rubric:: 结果和图像

   参考 ``lambda0=12 mm, npml=14`` 的 late reflection error 约为 ``-47.78`` 到 ``-49.18 dB``。

   第一张快照图用于观察径向出射的 TMz 波包。``r_plus`` 表示波包朝外半径边界传播，外半径 CPML
   应逐步吸收 ``Ez``；若快照中出现从外边界返回的亮带，说明径向吸收效果较弱。这里没有 ``r_minus``
   吸收边界，因为 ``r=0`` 是轴线而不是开放边界。

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/2d_rz_tmz_ez_snapshots_r_plus.png
      :align: center
      :width: 72%

      ``r_plus`` 方向 ``Ez`` 快照，用于观察外半径 CPML 吸收。

   第二张图是 probe error 曲线。它比较 compact CPML 域和 reference 域在 probe 点的归一化差异，
   dB 值越负表示 late reflection 越小。当前 ``r_plus`` 是这组三个方向里更敏感的方向，因此读图时
   应特别留意它在 late gate 后的峰值。

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/2d_rz_tmz_probe_error_db.png
      :align: center
      :width: 70%

      三个出射方向的 probe error dB 曲线。

   .. rubric:: 常见误读

   当前 TMz 的 ``r_plus`` 方向比 z 向更弱，是这组测试中更敏感的 CPML 指标。不要把没有 ``r_minus``
   当作漏测；``r=0`` 不是吸收边界，而是轴线。

   .. include:: _contributors_zh.inc

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   This test checks CPML absorption for the 2D RZ TMz field group
   ``Er,Hphi,Ez``. It uses compact/reference probe comparisons to estimate late
   reflection from finite-thickness CPML. See the
   :doc:`CPML wave-packet overview <cpml_wavepacket>` for the shared method.

   .. rubric:: Covered Routines

   - :doc:`mod_E01_cpml_2d_rz_tmz </rst_files/E_Maxwell/E01_Maxwell_2Drz/mod_E01_cpml_2d_rz_tmz>`
   - ``sub_E01_cpml_2d_rz_tmz_E`` and ``sub_E01_cpml_2d_rz_tmz_H``
   - The matching E01 TMz FDTD kernels

   .. rubric:: Files

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - File
        - Role
      * - ``test_rz_tmz_wavepacket_cpml.f90``
        - Main compact/reference TMz packet driver.
      * - ``plot_results.py``
        - Creates ``Er/Ez/Hphi`` snapshots and probe-error dB plots.
      * - ``run.sh``
        - Builds, runs, postprocesses, and writes the output directory.
      * - ``output_*``
        - Probe data, snapshots, and error plots.

   .. rubric:: Run Command

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_cpml_2d_rz_tmz_wavepacket_ref
      ./run.sh 12 output_lambda12mm_npml14 14 3 0.02 3.5 0.012 all 136 36 450 260 200 0

   .. rubric:: Main Flow

   1. Build a finite-width TMz packet.
   2. Run compact/reference comparisons for ``z_plus,z_minus,r_plus``.
   3. Skip ``r_minus`` because ``r=0`` is the cylindrical axis.
   4. Record probe ``Ez`` or the relevant TMz component.
   5. Compute the late-gate maximum normalized error.

   .. rubric:: Example: ``r_plus`` TMz Packet

   ``test_rz_tmz_wavepacket_cpml.f90`` uses a finite-width TMz packet with
   ``lambda0=12 mm`` and checks ``z_plus``, ``z_minus``, and ``r_plus``.
   The ``r_plus`` case exercises the outer radial absorbing boundary and is the
   more sensitive direction in this set. ``r_minus`` is omitted because ``r=0``
   is the cylindrical axis. To keep this case comparable with the TEz packet
   case, it uses the same center wavelength and a slightly thicker compact CPML,
   ``npml=14``, to compensate for the higher sensitivity of radial ``Ez``.

   .. code-block:: fortran

      real(dp), parameter :: dr = 1.0d-3
      real(dp), parameter :: dz = 1.0d-3
      real(dp), parameter :: dt = 0.80d0/(c0*sqrt(1.0d0/dr**2 + 1.0d0/dz**2))
      real(dp) :: lambda0 = 12.0d-3
      integer :: nstep = 450
      integer :: late_gate = 260
      integer :: npml = 14

      character(len=16), dimension(3), parameter :: cases = (/ &
          'z_plus          ', 'z_minus         ', 'r_plus          ' /)

   Each case starts from the same packet, advances a compact CPML domain, then
   advances a longer reference domain. The probe error is normalized by the
   reference peak and reduced to the maximum dB value over ``late_gate:nstep``.

   .. code-block:: fortran

      call run_one_sim(cname, nr_cpml, nz_cpml, npml, zmin_cpml, &
          .true., probe_cpml, e0_cpml, e1_cpml)
      call run_one_sim(cname, nr_ref, nz_ref, npml_ref, zmin_ref, &
          .false., probe_ref, e0_ref, e1_ref)

      ref_norm = max(maxval(abs(probe_ref)), 1.0d-300)
      err_db = 20.0d0*log10(max(abs(probe_cpml-probe_ref), 1.0d-300)/ref_norm)
      late_error_db = maxval(err_db(late_gate:nstep))

   The TMz step advances ``Hphi`` first, then ``Er`` and ``Ez``. CPML corrections
   are applied in the z-directed strips and the outer radial strip, while the
   near-axis update remains part of the standard FDTD and axis handling.

   .. rubric:: Core Call Pattern

   .. code-block:: fortran

      call sub_E01_fdtd_2d_rz_tmz_H(...)
      call sub_E01_cpml_2d_rz_tmz_H(...)
      call sub_E01_fdtd_2d_rz_tmz_E(...)
      call sub_E01_cpml_2d_rz_tmz_E(...)
      call compare_probe_with_reference(...)

   .. rubric:: Results and Figures

   For ``lambda0=12 mm, npml=14``, reference late reflection error is about
   ``-47.78`` to ``-49.18 dB``.

   The snapshot figure shows a radially outgoing TMz packet. ``r_plus`` means the
   packet travels toward the outer-radius boundary, where the CPML should absorb
   ``Ez``. A bright band returning from the outer edge would indicate weaker
   radial absorption. There is no ``r_minus`` absorbing boundary because ``r=0``
   is the axis, not an open boundary.

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/2d_rz_tmz_ez_snapshots_r_plus.png
      :align: center
      :width: 72%

      ``Ez`` snapshots for the ``r_plus`` direction.

   The probe-error figure compares compact and reference probe waveforms. More
   negative dB values mean lower late reflection. In this set, ``r_plus`` is the
   more sensitive direction, so its late-gate peak is the most useful value to
   inspect.

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/2d_rz_tmz_probe_error_db.png
      :align: center
      :width: 70%

      Probe-error curves for the three outgoing directions.

   .. rubric:: Common Pitfall

   ``r_plus`` is currently the more sensitive direction in this TMz set. The
   missing ``r_minus`` case is intentional because ``r=0`` is the axis, not an
   absorbing boundary.

   .. include:: _contributors_en.inc
