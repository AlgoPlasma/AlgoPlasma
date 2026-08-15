CPML Wave-Packet Tests Overview
===============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 目的

   本页是 ``tests/005_maxwell`` 下 CPML wave-packet reference 测试的轻量总览。各 case 页面已经分别说明
   算例流程、图像和结果，本页只保留共享方法、误差定义、参考结果和入口链接，避免重复展示每个 case 的图。

   这些测试使用有限宽度电磁波包，而不是连续源，比较 compact CPML 区域和足够长的 reference 区域在 probe
   处的场量差异。它们主要验证 CPML 边界反射，而不是 FDTD stencil 本身；FDTD stencil 的局部公式验证见
   :doc:`005_maxwell 测试总览 <index>` 中的 single-step、MMS 和稳定性测试。

   .. rubric:: Case 入口

   .. list-table::
      :header-rows: 1
      :widths: 34 22 24 20

      * - Case 页面
        - 坐标/模式
        - 检查方向
        - 主要看点
      * - :doc:`case_cpml_2d_rz_tez_wavepacket_ref`
        - 2D ``r-z`` TEz
        - ``z_plus``, ``z_minus``, ``r_plus``, ``r_minus``
        - ``Ephi`` 波包和 probe error
      * - :doc:`case_cpml_2d_rz_tmz_wavepacket_ref`
        - 2D ``r-z`` TMz
        - ``z_plus``, ``z_minus``, ``r_plus``
        - ``Ez`` 波包和外半径 CPML
      * - :doc:`case_cpml_3d_cartesian_wavepacket_ref`
        - 3D Cartesian plane wave
        - ``x/y/z`` 两侧
        - 六方向 probe error；``npml=12``/``24`` 对比
      * - :doc:`case_cpml_3d_cylindrical_wavepacket_ref`
        - 3D cylindrical ``m=0 TM01``
        - ``z_plus``, ``z_minus``
        - ``sqrt(r) Ez`` 和 z 向 CPML

   ``r=0`` 是柱坐标轴线，所以 2D TMz 测试不单独测 ``r_minus``。3D cylindrical 测试当前只覆盖
   z 向 CPML；它的初始场先在更长的 reference 域里用 ``TM01`` 软源激发，等波包离开源区后再截取
   compact 窗口作为 compact/reference 的共同初始场。

   .. rubric:: 误差定义

   每个测试都记录一个位于波包后方的 probe，并计算

   .. math::

      \mathrm{Error\_dB}(n)
      = 20 \log_{10}
      \frac{|E_\mathrm{compact}(n)-E_\mathrm{ref}(n)|}
           {\max_n |E_\mathrm{ref}(n)|}.

   ``late_gate`` 是开始统计晚期反射误差的时间步；它跳过主波通过 probe 和靠近边界时的直接响应，
   只看此后可能由 CPML 反射回来的残余场。``late reflection error`` 是 late gate 之后
   ``Error_dB`` 的最大值。它是 probe 点场幅值误差，不是全局反射能量系数；``final interior energy``
   另按内部总能量相对初始能量计算。

   .. rubric:: 参考结果

   .. list-table::
      :header-rows: 1
      :widths: 32 22 24 22

      * - 测试
        - 参数
        - late reflection error
        - final interior energy
      * - 2D RZ TEz
        - ``lambda0=12 mm, npml=12``
        - ``-49.13`` 到 ``-50.39 dB``
        - 约 ``-24.1 dB``
      * - 2D RZ TMz
        - ``lambda0=18 mm, npml=12``
        - ``-28.55`` 到 ``-33.12 dB``
        - 约 ``-19.7 dB``
      * - 3D Cartesian
        - ``lambda0=12 mm, npml=12``
        - ``-43.45`` 到 ``-44.82 dB``
        - ``-47.4`` 到 ``-49.4 dB``
      * - 3D Cartesian
        - ``lambda0=12 mm, npml=24``
        - ``-71.38`` 到 ``-76.83 dB``
        - 约 ``-49 dB``
      * - 3D cylindrical ``m=0 TM01``
        - ``lambda0=18 mm, npml=12``
        - ``-35.24`` 到 ``-36.38 dB``
        - ``-36.0`` 到 ``-39.6 dB``

   .. rubric:: 运行命令

   从仓库根目录进入对应目录运行：

   .. code-block:: bash

      cd tests/005_maxwell/case_cpml_2d_rz_tez_wavepacket_ref
      ./run.sh 12 output_lambda12mm_npml12_weak_ephi_gif 12 3 0.02 3.5 0.012 all 136 36 450 260 200 10

      cd ../case_cpml_2d_rz_tmz_wavepacket_ref
      ./run.sh 18 output_lambda18mm_npml12 12 3 0.02 3.5 0.012 all 136 36 450 260 200 0

      cd ../case_cpml_3d_cartesian_wavepacket_ref
      ./run.sh 12 output_lambda12mm_npml12 12 3 0.02 3.5 0.012
      ./run.sh 12 output_lambda12mm_npml24 24 3 0.02 3.5 0.012

      cd ../case_cpml_3d_cylindrical_wavepacket_ref
      ./run.sh 18 output_lambda18mm_npml12_gif 12 3 0.02 3.5 0.012 all 18 136 36 450 260 200 10

   文档中保留 PNG/GIF 作为参考图；``*.dat``、``*.log``、``*.o``、``*.mod`` 和 ``*.out`` 是可再生
   产物，不需要随文档保存。

   .. include:: _contributors_zh.inc

.. container:: ap-lang ap-lang-en

   .. rubric:: Purpose

   This page is a lightweight overview of the CPML wave-packet reference tests
   under ``tests/005_maxwell``. The individual case pages now explain their own
   workflow, figures, and results, so this page keeps only the shared method,
   error definition, reference results, and entry links.

   These tests launch finite-width electromagnetic packets rather than
   continuous sources, then compare a compact CPML domain against a much longer
   reference domain at a probe behind the outgoing packet. They test CPML
   boundary reflection, not the FDTD stencil itself; for local stencil checks,
   see the single-step, MMS, and stability tests from the
   :doc:`005_maxwell overview <index>`.

   .. rubric:: Case Entry Points

   .. list-table::
      :header-rows: 1
      :widths: 34 22 24 20

      * - Case page
        - Geometry/mode
        - Directions
        - Main reading
      * - :doc:`case_cpml_2d_rz_tez_wavepacket_ref`
        - 2D ``r-z`` TEz
        - ``z_plus``, ``z_minus``, ``r_plus``, ``r_minus``
        - ``Ephi`` packet and probe error
      * - :doc:`case_cpml_2d_rz_tmz_wavepacket_ref`
        - 2D ``r-z`` TMz
        - ``z_plus``, ``z_minus``, ``r_plus``
        - ``Ez`` packet and outer-radius CPML
      * - :doc:`case_cpml_3d_cartesian_wavepacket_ref`
        - 3D Cartesian plane wave
        - both sides of ``x/y/z``
        - six-direction probe error; ``npml=12``/``24`` comparison
      * - :doc:`case_cpml_3d_cylindrical_wavepacket_ref`
        - 3D cylindrical ``m=0 TM01``
        - ``z_plus``, ``z_minus``
        - ``sqrt(r) Ez`` and z-side CPML

   The 2D TMz case does not test ``r_minus`` because ``r=0`` is the cylindrical
   axis. The 3D cylindrical case currently tests only z-side CPML. Its initial
   field is prepared by exciting a ``TM01`` source in a longer reference domain
   and then cutting out the compact window after the packet has left the source
   region.

   .. rubric:: Error Definition

   The tests record a probe behind the outgoing packet and compute

   .. math::

      \mathrm{Error\_dB}(n)
      = 20 \log_{10}
      \frac{|E_\mathrm{compact}(n)-E_\mathrm{ref}(n)|}
           {\max_n |E_\mathrm{ref}(n)|}.

   ``late_gate`` is the first time step used for the late-reflection metric. It
   skips the direct probe response from the outgoing packet and the early
   boundary transient, so the metric focuses on residual fields that can return
   from the CPML. ``late reflection error`` is the maximum ``Error_dB`` after
   the late gate. It is a field-amplitude error at one probe, not a global
   reflected-energy coefficient. ``final interior energy`` is reported
   separately from the interior total energy relative to its initial value.

   .. rubric:: Reference Results

   .. list-table::
      :header-rows: 1
      :widths: 32 22 24 22

      * - Test
        - Parameters
        - late reflection error
        - final interior energy
      * - 2D RZ TEz
        - ``lambda0=12 mm, npml=12``
        - ``-49.13`` to ``-50.39 dB``
        - about ``-24.1 dB``
      * - 2D RZ TMz
        - ``lambda0=18 mm, npml=12``
        - ``-28.55`` to ``-33.12 dB``
        - about ``-19.7 dB``
      * - 3D Cartesian
        - ``lambda0=12 mm, npml=12``
        - ``-43.45`` to ``-44.82 dB``
        - ``-47.4`` to ``-49.4 dB``
      * - 3D Cartesian
        - ``lambda0=12 mm, npml=24``
        - ``-71.38`` to ``-76.83 dB``
        - about ``-49 dB``
      * - 3D cylindrical ``m=0 TM01``
        - ``lambda0=18 mm, npml=12``
        - ``-35.24`` to ``-36.38 dB``
        - ``-36.0`` to ``-39.6 dB``

   .. rubric:: Run Commands

   From the repository root:

   .. code-block:: bash

      cd tests/005_maxwell/case_cpml_2d_rz_tez_wavepacket_ref
      ./run.sh 12 output_lambda12mm_npml12_weak_ephi_gif 12 3 0.02 3.5 0.012 all 136 36 450 260 200 10

      cd ../case_cpml_2d_rz_tmz_wavepacket_ref
      ./run.sh 18 output_lambda18mm_npml12 12 3 0.02 3.5 0.012 all 136 36 450 260 200 0

      cd ../case_cpml_3d_cartesian_wavepacket_ref
      ./run.sh 12 output_lambda12mm_npml12 12 3 0.02 3.5 0.012
      ./run.sh 12 output_lambda12mm_npml24 24 3 0.02 3.5 0.012

      cd ../case_cpml_3d_cylindrical_wavepacket_ref
      ./run.sh 18 output_lambda18mm_npml12_gif 12 3 0.02 3.5 0.012 all 18 136 36 450 260 200 10

   The documentation keeps PNG/GIF reference figures. ``*.dat``, ``*.log``,
   ``*.o``, ``*.mod``, and ``*.out`` files are reproducible run artifacts and
   are not meant to be kept with the documentation.

   .. include:: _contributors_en.inc
