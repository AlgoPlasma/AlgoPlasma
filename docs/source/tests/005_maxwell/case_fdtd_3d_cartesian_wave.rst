case_fdtd_3d_cartesian_wave
===========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   ``case_fdtd_3d_cartesian_wave`` 是 3D Cartesian Yee-FDTD 的可视化案例。它用中心
   z 向电场源激发波，并输出三个正交中心平面裁切后的 ``Ez`` 幅值 cutaway 图，用于直观检查三维传播形态。
   ``run.sh`` 运行 ``fdtd_3d_cartesian_wave.py`` 生成图片，不编译、也不调用 ``E_Maxwell`` 目录中的
   Fortran 子程序。目录中还保留了一张 ``z=0`` 单平面参考图，用于和三维切片图互相对照。

   .. rubric:: 对应算法

   该脚本的内部六分量 curl 更新与 :doc:`E03 3D Cartesian </rst_files/E_Maxwell/E03_Maxwell_3Dxyz>`
   中 ``sub_E03_fdtd_3d_cartesian_H`` 和 ``sub_E03_fdtd_3d_cartesian_E`` 的差分形式一致。
   中心 ``Ez`` 软源、Gaussian 空间包络、RMS 累积图和 sponge layer 边界都是 Python 脚本里的展示设置，
   不属于 E03 Fortran 子程序本身。

   .. rubric:: 文件说明

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 文件
        - 作用
      * - ``fdtd_3d_cartesian_wave.py``
        - Python 3D FDTD 演示脚本。
      * - ``fdtd_3d_cartesian_ez_slices.png``
        - 当前 ``run.sh`` 生成的主图：三个正交中心平面 ``x=0,y=0,z=0`` 裁切后的 ``Ez`` RMS cutaway 图。
      * - ``fdtd_3d_cartesian_wave_slice.png``
        - 目录中保留的单平面参考图：``z=0`` 截面上的场幅值快照，便于初学者先从二维切片理解波前。
      * - ``run.sh``
        - 运行 Python 脚本并重新生成图片。

   .. rubric:: 运行方式

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_fdtd_3d_cartesian_wave
      bash run.sh

   .. rubric:: 主流程

   1. 建立 3D Cartesian Yee 网格。
   2. 交替更新 ``Hx/Hy/Hz`` 和 ``Ex/Ey/Ez``。
   3. 在电场更新后加入中心 z 向电场源，并施加 sponge layer。
   4. 取 ``x=0``、``y=0``、``z=0`` 三个中心平面。
   5. 绘制 ``Ez`` RMS 幅值 cutaway 图并保存 PNG；目录中另有 ``z=0`` 单平面参考图可对照阅读。

   .. rubric:: 典型例子：3D 中心源和三正交切片

   ``fdtd_3d_cartesian_wave.py`` 用 ``100 x 100 x 100`` 网格演示三维 Yee 更新。
   网格间距取为波长的十分之一，时间步长按三维 CFL 公式计算。源项不是单点脉冲，而是一个很窄的
   Gaussian 空间包络，加到 ``Ez`` 上，这样可以减少单格点源带来的尖峰。

   .. code-block:: python

      nx = ny = nz = 100
      dx = dy = dz = lam0 / 10.0
      dt = s / (c0 * np.sqrt((1.0/dx**2) + (1.0/dy**2) + (1.0/dz**2)))

      ic, jc, kc = nx // 2, ny // 2, nz // 2
      src_profile = np.exp(-(((ii-ic)**2 + (jj-jc)**2 + (kk-kc)**2) /
                             (2.0 * src_sigma * src_sigma)))
      src_profile /= np.max(src_profile)

   主循环中六个分量都按 curl 交替更新，源项在电场更新后加入。边界不是 CPML，而是轻量的
   sponge layer；脚本还在最后 ``80`` 步累积 ``Ez`` 的 RMS 幅值，避免单步快照刚好落在相位零点。

   .. code-block:: python

      ez[1:, 1:, :] += ce * (
          (hy[1:, 1:, :] - hy[:-1, 1:, :]) / dx
          - (hx[1:, 1:, :] - hx[1:, :-1, :]) / dy
      )

      src = 0.25 * ramp * np.sin(w0 * t)
      ez += src * src_profile

      ex *= damp; ey *= damp; ez *= damp
      hx *= damp; hy *= damp; hz *= damp

   .. rubric:: 重点调用方式

   .. code-block:: text

      update Hx, Hy, Hz from Ex, Ey, Ez
      update Ex, Ey, Ez from Hx, Hy, Hz
      add centered Ez source and sponge damping
      plot half-width vertical center planes and one horizontal quadrant

   .. rubric:: 结果和图像

   这页有两张图，建议先看下面的二维 ``z=0`` 单平面图理解中心源的环状波前，再看三维三切片图
   判断 ``x=0``、``y=0``、``z=0`` 三个中心平面上的整体传播形态。两张图的色标和统计量不同：
   主图是最后 ``80`` 步的 ``Ez`` RMS，单平面图是保留的参考快照，因此只能比较形态，不能逐点比较数值。

   .. figure:: ../../../../tests/005_maxwell/case_fdtd_3d_cartesian_wave/fdtd_3d_cartesian_ez_slices.png
      :align: center
      :width: 66%

      ``fdtd_3d_cartesian_ez_slices.png``：当前脚本输出的主图。它把 ``x=0``、``y=0``、``z=0``
      三个中心平面裁成一个开角 cutaway 视图：两个竖直中心面保留完整 ``z`` 范围，
      水平 ``z=0`` 面只显示一个象限，避免完整平面互相遮挡。
      颜色表示最后 ``80`` 步累积得到的 ``Ez`` RMS 幅值；这张图主要帮助观察中心源附近三维剖面的整体形态。

   .. figure:: ../../../../tests/005_maxwell/case_fdtd_3d_cartesian_wave/fdtd_3d_cartesian_wave_slice.png
      :align: center
      :width: 62%

      ``fdtd_3d_cartesian_wave_slice.png``：单平面参考图，显示 ``z=0`` 截面上的场幅值快照。
      它更接近普通二维热图，适合先看中心源附近的环状波前、径向对称性和边界吸收后的剩余场分布。
      注意这张图的色标和量纲来自该参考快照，不能直接与上方 RMS 三切片图逐数值比较。

   .. rubric:: 常见误读

   ``Ez`` 切片并不代表完整电磁能量；它只是一个便于观察的分量。这个 Python 图适合检查传播形态，
   数值通过与否仍应看 single-step、MMS、稳定性和 CPML 测试。

   .. include:: _contributors_zh.inc

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   ``case_fdtd_3d_cartesian_wave`` is a 3D Cartesian Yee-FDTD visualization
   case. It excites a centered z-directed electric source and outputs ``Ez``
   magnitude cutaway slices from three orthogonal center planes for
   qualitative inspection. ``run.sh`` runs ``fdtd_3d_cartesian_wave.py`` to
   generate the figures; it does not compile or call any Fortran routine under
   ``E_Maxwell``.
   The directory also keeps a single ``z=0`` plane reference image, which is
   useful for reading the 3D result from a simpler 2D view first.

   .. rubric:: Related Algorithm

   The script's interior six-component curl update matches the finite-difference
   form used by ``sub_E03_fdtd_3d_cartesian_H`` and
   ``sub_E03_fdtd_3d_cartesian_E`` in
   :doc:`E03 3D Cartesian </rst_files/E_Maxwell/E03_Maxwell_3Dxyz>`. The centered
   ``Ez`` soft source, Gaussian spatial profile, RMS accumulation figure, and
   sponge boundary are Python-side display choices, not parts of the E03 Fortran
   routines.

   .. rubric:: Files

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - File
        - Role
      * - ``fdtd_3d_cartesian_wave.py``
        - Python 3D FDTD demo.
      * - ``fdtd_3d_cartesian_ez_slices.png``
        - Main figure regenerated by ``run.sh``: a cutaway ``Ez`` RMS view from the three center planes ``x=0,y=0,z=0``.
      * - ``fdtd_3d_cartesian_wave_slice.png``
        - Retained single-plane reference: a field-amplitude snapshot on the ``z=0`` section.
      * - ``run.sh``
        - Run the Python script and regenerate the figures.

   .. rubric:: Run Command

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_fdtd_3d_cartesian_wave
      bash run.sh

   .. rubric:: Main Flow

   1. Build a 3D Cartesian Yee grid.
   2. Alternate ``Hx/Hy/Hz`` and ``Ex/Ey/Ez`` updates.
   3. Add the centered z-directed electric source after the electric update and apply the sponge layer.
   4. Extract center planes at ``x=0``, ``y=0``, and ``z=0``.
   5. Plot and save the ``Ez`` RMS cutaway image; compare it with the retained ``z=0`` reference slice when useful.

   .. rubric:: Example: 3D Center Source and Orthogonal Slices

   ``fdtd_3d_cartesian_wave.py`` demonstrates a 3D Yee update on a
   ``100 x 100 x 100`` grid. The spacing is one tenth of the wavelength and
   the time step is computed from the 3D CFL condition. The source is a narrow
   Gaussian spatial profile added to ``Ez`` rather than a single-cell spike,
   which keeps the visualization cleaner.

   .. code-block:: python

      nx = ny = nz = 100
      dx = dy = dz = lam0 / 10.0
      dt = s / (c0 * np.sqrt((1.0/dx**2) + (1.0/dy**2) + (1.0/dz**2)))

      ic, jc, kc = nx // 2, ny // 2, nz // 2
      src_profile = np.exp(-(((ii-ic)**2 + (jj-jc)**2 + (kk-kc)**2) /
                             (2.0 * src_sigma * src_sigma)))
      src_profile /= np.max(src_profile)

   The main loop alternates the six curl updates and adds the source after the
   electric update. The edges use a lightweight sponge layer rather than CPML.
   The plotted amplitude is accumulated as an ``Ez`` RMS value over the last
   ``80`` steps, avoiding a misleading single-phase snapshot.

   .. code-block:: python

      ez[1:, 1:, :] += ce * (
          (hy[1:, 1:, :] - hy[:-1, 1:, :]) / dx
          - (hx[1:, 1:, :] - hx[1:, :-1, :]) / dy
      )

      src = 0.25 * ramp * np.sin(w0 * t)
      ez += src * src_profile

      ex *= damp; ey *= damp; ez *= damp
      hx *= damp; hy *= damp; hz *= damp

   .. rubric:: Core Pattern

   .. code-block:: text

      update Hx, Hy, Hz from Ex, Ey, Ez
      update Ex, Ey, Ez from Hx, Hy, Hz
      add centered Ez source and sponge damping
      plot half-width vertical center planes and one horizontal quadrant

   .. rubric:: Results and Figures

   This page has two figures. It is often easiest to read the retained 2D
   ``z=0`` slice first to understand the ring-like wavefront from the centered
   source, then read the 3D triple-slice figure to inspect the overall shape on
   the ``x=0``, ``y=0``, and ``z=0`` center planes. The color scales and plotted
   quantities differ: the main figure is an ``Ez`` RMS over the final ``80``
   steps, while the single-plane image is a retained reference snapshot.

   .. figure:: ../../../../tests/005_maxwell/case_fdtd_3d_cartesian_wave/fdtd_3d_cartesian_ez_slices.png
      :align: center
      :width: 66%

      ``fdtd_3d_cartesian_ez_slices.png``: the main output of the current
      script. It crops the ``x=0``, ``y=0``, and ``z=0`` center planes into an
      open-corner cutaway view: the two vertical center planes keep the full
      ``z`` range, while the horizontal ``z=0`` plane keeps one quadrant. This
      keeps the slices readable without hiding one complete plane behind
      another. Color denotes the ``Ez`` RMS amplitude accumulated over the final
      ``80`` steps.

   .. figure:: ../../../../tests/005_maxwell/case_fdtd_3d_cartesian_wave/fdtd_3d_cartesian_wave_slice.png
      :align: center
      :width: 62%

      ``fdtd_3d_cartesian_wave_slice.png``: a single-plane reference image on
      the ``z=0`` section. It is easier to read as a 2D heat map and helps show
      the ring-like wavefront near the centered source. Its color scale and
      quantity come from that snapshot, so it should not be compared
      point-by-point with the RMS triple-slice figure above.

   .. rubric:: Common Pitfall

   ``Ez`` slices are not total electromagnetic energy; they are one component
   chosen for visualization. This Python figure is useful for checking the
   propagation shape; use single-step, MMS, stability, and CPML tests for
   numerical validation.

   .. include:: _contributors_en.inc
