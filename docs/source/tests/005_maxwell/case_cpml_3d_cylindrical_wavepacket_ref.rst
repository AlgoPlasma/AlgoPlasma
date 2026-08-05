case_cpml_3d_cylindrical_wavepacket_ref
=======================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   本测试验证 3D cylindrical ``m=0`` TM01-like 波包在 z 向 CPML 中的吸收效果。它先在较长
   reference 域中准备离开源区的波包，再截取 compact/reference 的共同初值。总体方法见
   :doc:`CPML wave-packet 测试总览 <cpml_wavepacket>`。

   .. rubric:: 覆盖子程序

   - :doc:`mod_E02_cpml_3d_cylindrical </rst_files/E_Maxwell/E02_Maxwell_3Drtz/mod_E02_cpml_3d_cylindrical>`
   - ``sub_E02_cpml_3d_cylindrical_E`` 和 ``sub_E02_cpml_3d_cylindrical_H``
   - E02 3D cylindrical FDTD 更新核

   .. rubric:: 文件说明

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 文件
        - 作用
      * - ``test_3d_cylindrical_wavepacket_cpml.f90``
        - 主程序：准备 TM01-like 初始波包并运行 z 向 compact/reference 对照。
      * - ``plot_results.py``
        - 生成 ``sqrt(r) Ez`` 场切片和 probe error dB 曲线。
      * - ``make_gifs.py``
        - 可选生成 z 向传播动画。
      * - ``run.sh``
        - 接收波长、``npml``、网格和输出参数。

   .. rubric:: 运行方式

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_cpml_3d_cylindrical_wavepacket_ref
      ./run.sh 18 output_lambda18mm_npml12_gif 12 3 0.02 3.5 0.012 all 18 136 36 450 260 200 10

   .. rubric:: 主流程

   1. 在长 reference 域中用软源准备 TM01-like 波包。
   2. 等波包离开源区后截取 compact 和 reference 的共同初始场。
   3. 分别测试 ``z_plus`` 和 ``z_minus`` CPML。
   4. 记录 probe 处的轴对称场响应。
   5. 输出 ``sqrt(r) Ez`` 切片和 late reflection error。

   .. rubric:: 典型例子：``z_plus`` 方向的 TM01-like 波包

   ``test_3d_cylindrical_wavepacket_cpml.f90`` 先在长 reference 域中用软源生成
   ``m=0`` TM01-like 波包，再把已经离开源区的场截取到 compact 和 reference 域。
   以 ``z_plus`` 为例，compact 域在正 z 端放置 CPML，reference 域继续加长 z 向距离。

   .. code-block:: fortran

      real(dp), parameter :: dr = 1.0d-3
      real(dp), parameter :: dz = 1.0d-3
      integer :: nstep = 450
      integer :: late_gate = 260
      integer :: npml = 12
      real(dp) :: lambda0 = 18.0d-3
      real(dp) :: sigma_long = 18.0d-3

      character(len=16), dimension(2), parameter :: cases = (/ &
          'z_plus          ', 'z_minus         ' /)

   这个 case 和 2D/3D Cartesian CPML 页略有不同：它不直接把解析波包塞进 compact 域，
   而是先通过 ``prepare_source_packet`` 在长域中产生更接近圆柱波导传播模式的初值。
   后续仍然使用 compact/reference probe 差值定义 late reflection error。

   .. code-block:: fortran

      call prepare_source_packet(cname, Er_src, Ephi_src, Ez_src, Hr_src, Hphi_src, Hz_src)

      call run_one_sim(cname, nz_cpml, npml, zmin_cpml, &
          .true., probe_cpml, e0_cpml, e1_cpml)
      call run_one_sim(cname, nz_ref, npml_ref, zmin_ref, &
          .false., probe_ref, e0_ref, e1_ref)

      err_db = 20.0d0*log10(max(abs(probe_cpml-probe_ref), 1.0d-300)/ref_norm)
      late_error_db = maxval(err_db(late_gate:nstep))

   单步推进覆盖 E02 cylindrical FDTD 更新和 z 向两端 CPML 修正。当前测试只证明 z 向 CPML；
   径向吸收边界不在这个 case 的覆盖范围内。

   .. rubric:: 重点调用方式

   .. code-block:: fortran

      call prepare_source_packet(...)
      call sub_E02_fdtd_3d_cylindrical_H(...)
      call sub_E02_cpml_3d_cylindrical_H(...)
      call sub_E02_fdtd_3d_cylindrical_E(...)
      call sub_E02_cpml_3d_cylindrical_E(...)

   .. rubric:: 结果和图像

   参考 ``lambda0=18 mm, npml=12`` 的 late reflection error 约为 ``-35`` 到 ``-36 dB``。

   第一张切片图显示 ``z_plus`` 方向的 ``sqrt(r) Ez``。乘 ``sqrt(r)`` 只是为了让不同半径处的显示
   更容易比较，不是内核实际推进变量。读图时应看波包是否沿 z 向离开、轴线附近是否平滑、
   z 向 CPML 处是否没有明显返回波前；径向 CPML 不由这张图证明。

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/3d_cylindrical_field_slices_z_plus.png
      :align: center
      :width: 72%

      ``z_plus`` 的 ``sqrt(r) Ez`` 切片。乘 ``sqrt(r)`` 是为了更容易观察径向能量分布。

   动图每 10 步取一帧，直接显示 ``sqrt(r) Ez`` 波包分别向 ``z_plus`` 和 ``z_minus`` 端传播并进入
   CPML 的过程。图中的两条黑线标出 z 向 CPML 的内边界；波包穿过内边界后应快速衰减，且不应看到明显
   回传波前。动画适合做直观检查，定量反射水平仍以后面的 probe error 曲线为准。

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/3d_cylindrical_ez_animation_z_plus.gif
      :align: center
      :width: 64%

      ``z_plus`` 方向的 ``sqrt(r) Ez`` 传播动画。

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/3d_cylindrical_ez_animation_z_minus.gif
      :align: center
      :width: 64%

      ``z_minus`` 方向的 ``sqrt(r) Ez`` 传播动画。

   第二张图是 ``z_plus`` 和 ``z_minus`` 的 probe error 曲线。曲线比较 compact 域和 reference 域的
   probe 差异，dB 值越负说明 late reflection 越小。该图只评价 z 向两端 CPML 的反射水平。

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/3d_cylindrical_probe_error_db.png
      :align: center
      :width: 70%

      ``z_plus`` 和 ``z_minus`` 的 probe error dB 曲线。

   .. rubric:: 常见误读

   当前 3D cylindrical CPML wave-packet 测试只覆盖 z 向 CPML；径向 CPML 行为不由这一页证明。
   图中的 ``sqrt(r) Ez`` 是显示量，不是内核实际推进的场变量。

   .. include:: _contributors_zh.inc

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   This test checks z-directed CPML absorption for a 3D cylindrical ``m=0``
   TM01-like packet. It first prepares a packet in a longer reference domain,
   then clips a common compact/reference initial field after the packet leaves
   the source region. See the :doc:`CPML wave-packet overview <cpml_wavepacket>`.

   .. rubric:: Covered Routines

   - :doc:`mod_E02_cpml_3d_cylindrical </rst_files/E_Maxwell/E02_Maxwell_3Drtz/mod_E02_cpml_3d_cylindrical>`
   - ``sub_E02_cpml_3d_cylindrical_E`` and ``sub_E02_cpml_3d_cylindrical_H``
   - E02 3D cylindrical FDTD kernels

   .. rubric:: Files

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - File
        - Role
      * - ``test_3d_cylindrical_wavepacket_cpml.f90``
        - Main driver for preparing the TM01-like packet and running z-directed compact/reference comparisons.
      * - ``plot_results.py``
        - Creates ``sqrt(r) Ez`` slices and probe-error dB curves.
      * - ``make_gifs.py``
        - Optionally creates z-propagation animations.
      * - ``run.sh``
        - Accepts wavelength, ``npml``, grid, and output parameters.

   .. rubric:: Run Command

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_cpml_3d_cylindrical_wavepacket_ref
      ./run.sh 18 output_lambda18mm_npml12_gif 12 3 0.02 3.5 0.012 all 18 136 36 450 260 200 10

   .. rubric:: Main Flow

   1. Prepare a TM01-like packet with a soft source in the long reference domain.
   2. Clip common compact/reference initial fields after the packet leaves the source region.
   3. Test ``z_plus`` and ``z_minus`` CPML.
   4. Record axisymmetric probe responses.
   5. Output ``sqrt(r) Ez`` slices and late reflection error.

   .. rubric:: Example: ``z_plus`` TM01-Like Packet

   ``test_3d_cylindrical_wavepacket_cpml.f90`` first prepares an ``m=0``
   TM01-like packet with a soft source in the long reference domain, then clips
   the field after it has left the source region into compact and reference
   domains. For ``z_plus``, the compact domain places CPML at the positive-z
   end, while the reference domain keeps a longer z extent.

   .. code-block:: fortran

      real(dp), parameter :: dr = 1.0d-3
      real(dp), parameter :: dz = 1.0d-3
      integer :: nstep = 450
      integer :: late_gate = 260
      integer :: npml = 12
      real(dp) :: lambda0 = 18.0d-3
      real(dp) :: sigma_long = 18.0d-3

      character(len=16), dimension(2), parameter :: cases = (/ &
          'z_plus          ', 'z_minus         ' /)

   This case differs slightly from the 2D and Cartesian CPML pages: it does not
   insert an analytic packet directly into the compact domain. Instead,
   ``prepare_source_packet`` creates an initial field closer to the propagating
   cylindrical waveguide mode. The late reflection error is still the
   compact/reference probe difference.

   .. code-block:: fortran

      call prepare_source_packet(cname, Er_src, Ephi_src, Ez_src, Hr_src, Hphi_src, Hz_src)

      call run_one_sim(cname, nz_cpml, npml, zmin_cpml, &
          .true., probe_cpml, e0_cpml, e1_cpml)
      call run_one_sim(cname, nz_ref, npml_ref, zmin_ref, &
          .false., probe_ref, e0_ref, e1_ref)

      err_db = 20.0d0*log10(max(abs(probe_cpml-probe_ref), 1.0d-300)/ref_norm)
      late_error_db = maxval(err_db(late_gate:nstep))

   A time step combines the E02 cylindrical FDTD update with CPML corrections on
   the two z-directed ends. This case currently proves only z-directed CPML
   behavior; radial absorbing boundaries are outside its coverage.

   .. rubric:: Core Call Pattern

   .. code-block:: fortran

      call prepare_source_packet(...)
      call sub_E02_fdtd_3d_cylindrical_H(...)
      call sub_E02_cpml_3d_cylindrical_H(...)
      call sub_E02_fdtd_3d_cylindrical_E(...)
      call sub_E02_cpml_3d_cylindrical_E(...)

   .. rubric:: Results and Figures

   For ``lambda0=18 mm, npml=12``, reference late reflection error is about
   ``-35`` to ``-36 dB``.

   The first slice figure shows ``sqrt(r) Ez`` for the ``z_plus`` direction.
   The ``sqrt(r)`` factor is only a display scaling that makes different radii
   easier to compare; it is not the field advanced by the kernel. Check whether
   the packet exits along z, whether the axis remains smooth, and whether the
   z-directed CPML creates no obvious returning wavefront. Radial CPML is not
   validated by this figure.

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/3d_cylindrical_field_slices_z_plus.png
      :align: center
      :width: 72%

      ``sqrt(r) Ez`` slices for ``z_plus``.

   The animations sample every 10 steps and show the ``sqrt(r) Ez`` packet
   propagating toward the ``z_plus`` and ``z_minus`` ends. The two black guide
   lines mark the interior interfaces of the z-directed CPML. The packet should
   fade after crossing those interfaces without an obvious returning wavefront.
   Use the animations as a visual sanity check; the probe-error curves below
   remain the quantitative reflection metric.

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/3d_cylindrical_ez_animation_z_plus.gif
      :align: center
      :width: 64%

      ``sqrt(r) Ez`` propagation animation for ``z_plus``.

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/3d_cylindrical_ez_animation_z_minus.gif
      :align: center
      :width: 64%

      ``sqrt(r) Ez`` propagation animation for ``z_minus``.

   The second figure gives probe-error curves for ``z_plus`` and ``z_minus``.
   It compares compact and reference probe signals; more negative dB values mean
   lower late reflection. This figure evaluates only the two z-directed CPML
   ends.

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/3d_cylindrical_probe_error_db.png
      :align: center
      :width: 70%

      Probe-error curves for ``z_plus`` and ``z_minus``.

   .. rubric:: Common Pitfall

   This test currently covers z-directed CPML only; it does not prove radial
   CPML behavior. ``sqrt(r) Ez`` is a display quantity, not the field advanced
   by the kernel.

   .. include:: _contributors_en.inc
