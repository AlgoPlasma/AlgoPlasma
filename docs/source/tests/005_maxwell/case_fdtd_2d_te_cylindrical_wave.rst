case_fdtd_2d_te_cylindrical_wave
================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   ``case_fdtd_2d_te_cylindrical_wave`` 是 Python-only 的 2D TE 圆形波前可视化案例。
   ``run.sh`` 运行 ``fdtd_2d_te_cylindrical_wave.py`` 生成图片，不编译、也不调用
   ``E_Maxwell`` 目录中的 Fortran 子程序。这里的“柱面波”指 ``x-y`` 平面内由中心源向外传播的
   圆形波前，主要用于文档图和直观检查。

   .. rubric:: 对应算法

   该脚本的内部 Yee 更新与 :doc:`E03 3D Cartesian </rst_files/E_Maxwell/E03_Maxwell_3Dxyz>`
   中 ``sub_E03_fdtd_3d_cartesian_H`` 和 ``sub_E03_fdtd_3d_cartesian_E`` 的二维 TEz 截面一致：
   取 ``∂/∂z = 0``，只保留 ``Ex, Ey, Hz``。中心软源和一阶 Mur 边界是 Python 脚本里的展示设置，
   不属于 E03 Fortran 子程序本身。它不对应 E01 的 ``r-z`` 柱坐标 TEz 子程序。

   .. rubric:: 文件说明

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 文件
        - 作用
      * - ``fdtd_2d_te_cylindrical_wave.py``
        - Python FDTD 演示脚本，生成 TE 柱面波。
      * - ``fdtd_2d_te_cylindrical_wave.png``
        - 生成的参考图。
      * - ``run.sh``
        - 运行 Python 脚本并重新生成图片。

   .. rubric:: 运行方式

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_fdtd_2d_te_cylindrical_wave
      bash run.sh

   .. rubric:: 主流程

   1. 建立 2D Cartesian ``x-y`` Yee 网格。
   2. 在中心位置加入 ``Hz`` 正弦源。
   3. 按二维 TEz 截面公式更新 ``Ex/Ey`` 和 ``Hz``。
   4. 施加一阶 Mur 边界，保存最终 ``|Hz|`` 幅值图。
   5. 用图像检查圆形波前形状和边界附近是否有明显异常。

   .. rubric:: 典型例子：中心 ``Hz`` 源的 TEz 波前

   ``fdtd_2d_te_cylindrical_wave.py`` 与 TMz 可视化脚本成对出现，但场分量换成
   ``Ex/Ey/Hz``。它同样使用 ``201 x 201`` 的 ``x-y`` 网格和 ``278 MHz`` 正弦源，只是源项加在
   ``Hz`` 上。这个例子适合学生对比 TEz/TMz：TMz 用 ``Ez`` 看波前，TEz 用 ``Hz`` 看波前。

   .. code-block:: python

      nx, ny = 201, 201
      dx = dy = 0.054
      dt = dx / (c0 * np.sqrt(2.0))
      nsteps = 190

      hz = np.zeros((nx, ny), dtype=np.float64)
      ex = np.zeros((nx, ny - 1), dtype=np.float64)
      ey = np.zeros((nx - 1, ny), dtype=np.float64)

   时间推进时先用 ``Hz`` 更新 ``Ex/Ey``，再用 ``Ex/Ey`` 的 curl 更新内部 ``Hz``。
   源项和一阶 Mur 边界放在同一个主循环里。需要注意，一阶 Mur 对近似垂直入射的平面波
   吸收较好；对柱面波中的斜入射分量，边界反射会更明显。因此这页主要说明“波前是否合理”，
   不作为严格的 Fortran 内核误差判据。

   .. code-block:: python

      ex += (dt / (eps0 * dy)) * (hz[:, 1:] - hz[:, :-1])
      ey -= (dt / (eps0 * dx)) * (hz[1:, :] - hz[:-1, :])

      curl_e = (ey[1:, 1:-1] - ey[:-1, 1:-1]) / dx - \
               (ex[1:-1, 1:] - ex[1:-1, :-1]) / dy
      hz[1:-1, 1:-1] -= (dt / mu0) * curl_e

      hz[src_i, src_j] += np.sin(w0 * t)

   .. rubric:: 重点调用方式

   .. code-block:: text

      update Ex and Ey from Hz
      update Hz from Ex and Ey
      add center Hz source and Mur boundaries
      save |Hz| image

   .. rubric:: 结果和图像

   这张图显示 TEz 可视化脚本中的场幅值。读图时主要检查三点：中心源是否产生连续波前，
   波前在二维平面内是否平滑向外传播，边界附近是否出现比主体波前更强的反射结构。
   由于图中显示的是幅值，正负相位信息被隐藏；它是波形和边界行为的直观检查图。

   .. figure:: ../../../../tests/005_maxwell/case_fdtd_2d_te_cylindrical_wave/fdtd_2d_te_cylindrical_wave.png
      :align: center
      :width: 62%

      2D TE 圆形波前参考图。图像应显示从源区传播出去的平滑波前。

   .. rubric:: 常见误读

   这里的 TEz 是 Cartesian 二维截面的 ``Ex,Ey,Hz`` 分量组，不是 E01 的 ``Ephi,Hr,Hz``
   柱坐标 RZ 分量组。这个 Python 图不是 Fortran 内核的数值精度证明；精度仍看 single-step 和 MMS。

   .. include:: _contributors_zh.inc

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   ``case_fdtd_2d_te_cylindrical_wave`` is a Python-only 2D TE circular-wavefront
   visualization case. ``run.sh`` runs ``fdtd_2d_te_cylindrical_wave.py`` to
   generate the figure; it does not compile or call any Fortran routine under
   ``E_Maxwell``. Here "cylindrical wave" means an outward circular wavefront on
   an ``x-y`` plane, for documentation and qualitative inspection.

   .. rubric:: Related Algorithm

   The interior Yee update is consistent with the 2D TEz reduction of
   :doc:`E03 3D Cartesian </rst_files/E_Maxwell/E03_Maxwell_3Dxyz>`:
   set ``∂/∂z = 0`` and keep only ``Ex, Ey, Hz`` from
   ``sub_E03_fdtd_3d_cartesian_H`` and ``sub_E03_fdtd_3d_cartesian_E``. The
   centered soft source and first-order Mur boundary are Python-side display
   choices, not parts of the E03 Fortran routines. This case is not the E01
   ``r-z`` cylindrical-coordinate TEz routine.

   .. rubric:: Files

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - File
        - Role
      * - ``fdtd_2d_te_cylindrical_wave.py``
        - Python FDTD demo for a TE cylindrical wave.
      * - ``fdtd_2d_te_cylindrical_wave.png``
        - Generated reference image.
      * - ``run.sh``
        - Run the Python script and regenerate the image.

   .. rubric:: Run Command

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_fdtd_2d_te_cylindrical_wave
      bash run.sh

   .. rubric:: Main Flow

   1. Build a 2D Cartesian ``x-y`` Yee grid.
   2. Add a centered sinusoidal ``Hz`` source.
   3. Update ``Ex/Ey`` and ``Hz`` using the 2D TEz reduction.
   4. Apply first-order Mur boundaries and save the final ``|Hz|`` image.
   5. Inspect wavefront shape and boundary artifacts.

   .. rubric:: Example: Centered ``Hz`` Source for a TEz Wavefront

   ``fdtd_2d_te_cylindrical_wave.py`` is paired with the TMz visualization
   script, but the active field group is ``Ex/Ey/Hz``. It uses the same
   ``201 x 201`` ``x-y`` grid and ``278 MHz`` sinusoidal source, with the source
   added to ``Hz``. This makes it a useful side-by-side comparison for students:
   TMz visualizes ``Ez``, while TEz visualizes ``Hz``.

   .. code-block:: python

      nx, ny = 201, 201
      dx = dy = 0.054
      dt = dx / (c0 * np.sqrt(2.0))
      nsteps = 190

      hz = np.zeros((nx, ny), dtype=np.float64)
      ex = np.zeros((nx, ny - 1), dtype=np.float64)
      ey = np.zeros((nx - 1, ny), dtype=np.float64)

   Each time step updates ``Ex/Ey`` from ``Hz`` and then updates interior
   ``Hz`` from the electric curl. The source and first-order Mur boundary
   conditions live in the same loop. First-order Mur works best for nearly normal
   plane-wave incidence; oblique components in a cylindrical wave can reflect
   more strongly. This page is therefore for qualitative wavefront inspection
   rather than strict Fortran-kernel error measurement.

   .. code-block:: python

      ex += (dt / (eps0 * dy)) * (hz[:, 1:] - hz[:, :-1])
      ey -= (dt / (eps0 * dx)) * (hz[1:, :] - hz[:-1, :])

      curl_e = (ey[1:, 1:-1] - ey[:-1, 1:-1]) / dx - \
               (ex[1:-1, 1:] - ex[1:-1, :-1]) / dy
      hz[1:-1, 1:-1] -= (dt / mu0) * curl_e

      hz[src_i, src_j] += np.sin(w0 * t)

   .. rubric:: Core Pattern

   .. code-block:: text

      update Ex and Ey from Hz
      update Hz from Ex and Ey
      add center Hz source and Mur boundaries
      save |Hz| image

   .. rubric:: Result and Figure

   The figure shows the field magnitude from the TEz visualization script. Use
   it to check whether the centered source produces a coherent wavefront,
   whether the wavefront remains smooth as it expands, and whether the boundary
   region shows reflection structures stronger than the outgoing packet. Since
   the plotted value is a magnitude, signed phase information is hidden.

   .. figure:: ../../../../tests/005_maxwell/case_fdtd_2d_te_cylindrical_wave/fdtd_2d_te_cylindrical_wave.png
      :align: center
      :width: 62%

      2D TE circular-wavefront reference image.

   .. rubric:: Common Pitfall

   TEz here is the Cartesian 2D ``Ex,Ey,Hz`` field group, not the E01
   cylindrical-coordinate ``Ephi,Hr,Hz`` group. This Python figure is not a
   Fortran accuracy proof; use single-step and MMS tests for accuracy.

   .. include:: _contributors_en.inc
