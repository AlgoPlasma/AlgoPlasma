case_cpml_3d_cartesian_wavepacket_ref
=====================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   本测试验证 3D Cartesian CPML 对平面波包的吸收效果。它覆盖 ``x/y/z`` 六个出射方向，并比较
   ``npml=12`` 与 ``npml=24`` 的反射水平。总体误差定义见 :doc:`CPML wave-packet 测试总览 <cpml_wavepacket>`。

   .. rubric:: 覆盖子程序

   - :doc:`mod_E03_cpml_3d_cartesian </rst_files/E_Maxwell/E03_Maxwell_3Dxyz/mod_E03_cpml_3d_cartesian>`
   - ``sub_E03_cpml_3d_cartesian_E`` 和 ``sub_E03_cpml_3d_cartesian_H``
   - E03 3D Cartesian FDTD 更新核

   .. rubric:: 文件说明

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 文件
        - 作用
      * - ``test_3d_cartesian_wavepacket_cpml.f90``
        - 主程序：构造 plane-wave-like 波包并运行 compact/reference 对照。
      * - ``plot_results.py``
        - 生成场切片和 probe error dB 曲线。
      * - ``run.sh``
        - 接收波长、输出目录、``npml`` 等参数并执行完整流程。

   .. rubric:: 运行方式

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_cpml_3d_cartesian_wavepacket_ref
      ./run.sh 12 output_lambda12mm_npml12 12 3 0.02 3.5 0.012
      ./run.sh 12 output_lambda12mm_npml24 24 3 0.02 3.5 0.012

   .. rubric:: 主流程

   1. 在 Cartesian 网格中构造有限宽度波包。
   2. 对六个方向分别设置传播方向和 probe。
   3. 使用 compact CPML 域和长 reference 域推进相同初值。
   4. 记录 probe 误差并输出场切片。
   5. 比较 ``npml=12`` 和 ``npml=24`` 的 late reflection error。

   .. rubric:: 典型例子：``z_plus`` 面的 3D Cartesian CPML

   ``test_3d_cartesian_wavepacket_cpml.f90`` 使用 ``dx=dy=dz=1 mm`` 的 Cartesian
   Yee 网格，分别把同一个 plane-wave-like 波包推向六个边界面。以 ``z_plus`` 为例，
   compact 域只保留测试所需的尺寸和 CPML 厚度，reference 域沿 z 向加长，用来近似无反射结果。

   .. code-block:: fortran

      integer :: nstep = 450
      integer :: late_gate = 260
      integer :: npml = 12
      real(dp) :: lambda0 = 12.0d-3

      character(len=16), dimension(6), parameter :: cases = (/ &
          'x_plus          ', 'x_minus         ', 'y_plus          ', &
          'y_minus         ', 'z_plus          ', 'z_minus         ' /)

   主程序先根据 ``cname`` 生成 compact/reference 几何，再用同一个 ``run_one_sim`` 推进两遍。
   通过 ``err_db`` 曲线可以直接比较 ``npml=12`` 和 ``npml=24`` 的吸收改善。

   .. code-block:: fortran

      call compact_geometry(cname, nx, ny, nz, xmin, ymin, zmin)
      call reference_geometry(cname, nrx, nry, nrz, rxmin, rymin, rzmin)

      call run_one_sim(cname, nx, ny, nz, npml, xmin, ymin, zmin, &
          .true., probe_cpml, e0, e1)
      call run_one_sim(cname, nrx, nry, nrz, npml_ref, rxmin, rymin, rzmin, &
          .false., probe_ref, e0, e1)

      err_db = 20.0d0*log10(max(abs(probe_cpml-probe_ref), 1.0d-300)/ref_norm)

   ``z_plus``/``z_minus`` 推进时，内部区域用 E03 Cartesian FDTD 更新，z 向 CPML 面带再调用
   E03 CPML 子程序修正 ``E`` 和 ``H`` 的记忆项。x/y 方向 case 使用同一模式，只是换成对应面带。

   .. rubric:: 重点调用方式

   .. code-block:: fortran

      call sub_E03_fdtd_3d_cartesian_H(...)
      call sub_E03_cpml_3d_cartesian_H(...)
      call sub_E03_fdtd_3d_cartesian_E(...)
      call sub_E03_cpml_3d_cartesian_E(...)
      call write_probe_and_slices(...)

   .. rubric:: 结果和图像

   本算例的主要判断依据是 compact CPML 与 large reference 在 probe 上的差值，而不是单个时刻的场图。
   ``late_gate=260`` 之后，``npml=12`` 的 late reflection error 约 ``-43`` 到 ``-45 dB``；
   ``npml=24`` 可降到约 ``-71`` 到 ``-77 dB``。因此页面首先展示 probe error 曲线：
   六个方向的曲线应成对接近，且 ``npml=24`` 的整体误差明显低于 ``npml=12``。

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/3d_cartesian_npml12_probe_error_db.png
      :align: center
      :width: 70%

      ``npml=12`` 的 probe error 曲线，``late_gate=260``。六个出射方向的 late reflection error
      约为 ``-43`` 到 ``-45 dB``。

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/3d_cartesian_npml24_probe_error_db.png
      :align: center
      :width: 70%

      ``npml=24`` 的 probe error 曲线，``late_gate=260``。相对于 ``npml=12``，更厚 CPML
      使曲线整体降低，late reflection error 降至约 ``-71`` 到 ``-77 dB``。

   下面的 probe 对比图用于说明 compact CPML 与 large reference 在主波包阶段几乎重合。
   注意它是线性尺度，晚期小反射不明显；吸收强弱仍应看上面的 dB 误差曲线。

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/3d_cartesian_npml12_probe_compare.png
      :align: center
      :width: 66%

      ``npml=12`` 的 compact CPML 与 large reference probe 对比。蓝色虚线为 compact CPML，
      橙色半透明粗实线为 large reference；主波包阶段两条曲线基本重合。

   最后一张切片图只作为空间形态检查。图中显示 ``npml=24``、``z_plus`` 传播方向的中心切片；
   正常情况下主波包应向正 z 边界离开计算域，CPML 区域附近不应产生明显返回结构。切片图只能帮助
   发现粗大的传播或边界错误，不应用来判断 CPML 吸收强弱。

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/3d_cartesian_npml24_field_slices_z_plus.png
      :align: center
      :width: 72%

      ``npml=24``、``z_plus`` 的中心切片。它展示波包离开方向和边界附近形态；通过与否看
      probe error 和 late reflection error。

   .. rubric:: 常见误读

   CPML 变厚后 probe error 通常降低，但 final interior energy 和单帧场图还受波包离开计算域、
   数值色散、色标和采样窗口影响。这个 case 的通过与优劣判断应以 probe error 和 late reflection
   error 为准。

   .. include:: _contributors_zh.inc

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   This test checks 3D Cartesian CPML absorption for plane-wave-like packets. It
   covers all six ``x/y/z`` outgoing directions and compares ``npml=12`` with
   ``npml=24``. See the :doc:`CPML wave-packet overview <cpml_wavepacket>` for
   the shared error definition.

   .. rubric:: Covered Routines

   - :doc:`mod_E03_cpml_3d_cartesian </rst_files/E_Maxwell/E03_Maxwell_3Dxyz/mod_E03_cpml_3d_cartesian>`
   - ``sub_E03_cpml_3d_cartesian_E`` and ``sub_E03_cpml_3d_cartesian_H``
   - E03 3D Cartesian FDTD kernels

   .. rubric:: Files

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - File
        - Role
      * - ``test_3d_cartesian_wavepacket_cpml.f90``
        - Main compact/reference plane-wave-like packet driver.
      * - ``plot_results.py``
        - Creates field slices and probe-error dB curves.
      * - ``run.sh``
        - Runs the full workflow from wavelength, output directory, and ``npml`` parameters.

   .. rubric:: Run Command

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_cpml_3d_cartesian_wavepacket_ref
      ./run.sh 12 output_lambda12mm_npml12 12 3 0.02 3.5 0.012
      ./run.sh 12 output_lambda12mm_npml24 24 3 0.02 3.5 0.012

   .. rubric:: Main Flow

   1. Build a finite-width packet on a Cartesian grid.
   2. Configure propagation direction and probe for each of the six faces.
   3. Advance compact CPML and long reference domains from the same initial state.
   4. Record probe errors and field slices.
   5. Compare late reflection error for ``npml=12`` and ``npml=24``.

   .. rubric:: Example: 3D Cartesian CPML on the ``z_plus`` Face

   ``test_3d_cartesian_wavepacket_cpml.f90`` uses a Cartesian Yee grid with
   ``dx=dy=dz=1 mm`` and launches the same plane-wave-like packet toward the six
   boundary faces. For ``z_plus``, the compact domain keeps only the tested
   length and CPML thickness, while the reference domain extends the z direction
   to approximate a reflection-free result.

   .. code-block:: fortran

      integer :: nstep = 450
      integer :: late_gate = 260
      integer :: npml = 12
      real(dp) :: lambda0 = 12.0d-3

      character(len=16), dimension(6), parameter :: cases = (/ &
          'x_plus          ', 'x_minus         ', 'y_plus          ', &
          'y_minus         ', 'z_plus          ', 'z_minus         ' /)

   The driver builds compact/reference geometries from ``cname``, then calls the
   same ``run_one_sim`` routine twice. The resulting ``err_db`` curve shows the
   absorption improvement when comparing ``npml=12`` with ``npml=24``.

   .. code-block:: fortran

      call compact_geometry(cname, nx, ny, nz, xmin, ymin, zmin)
      call reference_geometry(cname, nrx, nry, nrz, rxmin, rymin, rzmin)

      call run_one_sim(cname, nx, ny, nz, npml, xmin, ymin, zmin, &
          .true., probe_cpml, e0, e1)
      call run_one_sim(cname, nrx, nry, nrz, npml_ref, rxmin, rymin, rzmin, &
          .false., probe_ref, e0, e1)

      err_db = 20.0d0*log10(max(abs(probe_cpml-probe_ref), 1.0d-300)/ref_norm)

   For ``z_plus`` and ``z_minus``, the interior is advanced by the E03 Cartesian
   FDTD kernels, then the z-directed CPML face strips update the ``E`` and ``H``
   memory-variable corrections. The x/y cases use the same pattern on their
   selected face strips.

   .. rubric:: Core Call Pattern

   .. code-block:: fortran

      call sub_E03_fdtd_3d_cartesian_H(...)
      call sub_E03_cpml_3d_cartesian_H(...)
      call sub_E03_fdtd_3d_cartesian_E(...)
      call sub_E03_cpml_3d_cartesian_E(...)
      call write_probe_and_slices(...)

   .. rubric:: Results and Figures

   The main diagnostic is the probe difference between the compact CPML domain
   and the large reference domain, not a single-time field image. After
   ``late_gate=260``, ``npml=12`` gives late reflection error around ``-43`` to
   ``-45 dB``; ``npml=24`` lowers it to about ``-71`` to ``-77 dB``. The probe
   error curves should be nearly paired across the six directions, and the
   ``npml=24`` curves should sit well below the ``npml=12`` curves overall.

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/3d_cartesian_npml12_probe_error_db.png
      :align: center
      :width: 70%

      Probe error for ``npml=12`` with ``late_gate=260``. The six outgoing
      directions give late reflection error around ``-43`` to ``-45 dB``.

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/3d_cartesian_npml24_probe_error_db.png
      :align: center
      :width: 70%

      Probe error for ``npml=24`` with ``late_gate=260``. The thicker CPML lowers
      the curves overall, with late reflection error around ``-71`` to ``-77 dB``.

   The next probe-comparison figure shows that compact CPML and the large
   reference nearly overlap during the main packet. Because this is a linear
   scale, late small reflections are hard to see; use the dB error curves above
   for the absorption number.

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/3d_cartesian_npml12_probe_compare.png
      :align: center
      :width: 66%

      Compact CPML versus large reference probes for ``npml=12``. The blue
      dashed line is compact CPML, and the thicker translucent orange line is
      the large reference; the main packet portions nearly overlap.

   The final slice figure is only a spatial-shape check. It shows center slices
   for ``npml=24`` in the ``z_plus`` propagation direction. The main packet
   should leave through the positive-z boundary, and the CPML region should not
   generate a clear returning structure. Use this image to catch large
   propagation or boundary mistakes, not to judge absorption strength.

   .. figure:: ../../images/tests/005_maxwell/cpml_wavepacket/3d_cartesian_npml24_field_slices_z_plus.png
      :align: center
      :width: 72%

      Center slices for ``npml=24``, ``z_plus``. This shows the packet exit
      direction and boundary-region shape; pass/fail should come from probe
      error and late reflection error.

   .. rubric:: Common Pitfall

   Thicker CPML should reduce probe error, but final interior energy and
   single-frame field images also depend on packet exit, numerical dispersion,
   color scale, and the sampling window. Judge this case by probe error and late
   reflection error.

   .. include:: _contributors_en.inc
