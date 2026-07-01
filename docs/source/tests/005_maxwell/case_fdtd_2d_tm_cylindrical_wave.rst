case_fdtd_2d_tm_cylindrical_wave
================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   ``case_fdtd_2d_tm_cylindrical_wave`` 是 Python-only 的 2D TM 柱面波前可视化案例。
   ``run.sh`` 运行 ``fdtd_2d_tm_cylindrical_wave.py`` 生成图片，不编译、也不调用
   ``E_Maxwell`` 目录中的 Fortran 子程序。这里的“柱面波”指 ``x-y`` 平面内由中心源向外传播的
   圆形波前；它主要用于文档展示和直观检查，不是严格的 Fortran 子程序回归测试。

   .. rubric:: 对应算法

   该脚本的内部 Yee 更新与 :doc:`E03 3D Cartesian </rst_files/E_Maxwell/E03_Maxwell_3Dxyz>`
   中 ``sub_E03_fdtd_3d_cartesian_H`` 和 ``sub_E03_fdtd_3d_cartesian_E`` 的二维 TMz 截面一致：
   取 ``∂/∂z = 0``，只保留 ``Hx, Hy, Ez``。中心软源和一阶 Mur 边界是 Python 脚本里的展示设置，
   不属于 E03 Fortran 子程序本身。它不对应 E01 的 ``r-z`` 柱坐标 TMz 子程序。

   .. rubric:: 文件说明

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 文件
        - 作用
      * - ``fdtd_2d_tm_cylindrical_wave.py``
        - Python FDTD 演示脚本，使用中心正弦源生成 TM 柱面波图。
      * - ``fdtd_2d_tm_cylindrical_wave.png``
        - 生成的 ``|Ez|`` 参考图。
      * - ``run.sh``
        - 运行 Python 脚本并重新生成图片。

   .. rubric:: 运行方式

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_fdtd_2d_tm_cylindrical_wave
      bash run.sh

   .. rubric:: 主流程

   1. 建立 2D Cartesian ``x-y`` Yee 网格。
   2. 在中心位置加入 ``Ez`` 正弦源。
   3. 按二维 TMz 截面公式更新 ``Hx/Hy`` 和 ``Ez``。
   4. 施加一阶 Mur 边界，运行到指定步数后输出 ``|Ez|`` 图。
   5. 用图像检查圆形波前是否从源附近向外传播。

   .. rubric:: 典型例子：中心 ``Ez`` 源的 TMz 波前

   ``fdtd_2d_tm_cylindrical_wave.py`` 里最值得看的部分是场数组和更新顺序。脚本使用
   ``201 x 201`` 的二维网格，``dx=dy=0.054``，时间步长取二维 CFL 上限附近的
   ``dt = dx/(c0*sqrt(2))``，源项频率为 ``278 MHz``。这里直接使用 ``x/y`` 网格做二维
   Cartesian Yee 更新；文件名里的 ``cylindrical_wave`` 只描述圆形波前形态，不表示柱坐标
   ``r-z`` 离散。

   .. code-block:: python

      nx, ny = 201, 201
      dx = dy = 0.054
      dt = dx / (c0 * np.sqrt(2.0))
      nsteps = 190
      f0 = 278.0e6

      ez = np.zeros((nx, ny), dtype=np.float64)
      hx = np.zeros((nx, ny - 1), dtype=np.float64)
      hy = np.zeros((nx - 1, ny), dtype=np.float64)

   每个时间步先用 ``Ez`` 更新 ``Hx/Hy``，再用 ``Hx/Hy`` 的 curl 更新内部 ``Ez``。
   中心源在电场更新之后加入，这样图上可以看到从源附近向外传播的波前。四条边使用一阶
   Mur absorbing boundary condition。需要注意，一阶 Mur 对近似垂直入射的平面波吸收较好；
   对柱面波中的斜入射分量，边界反射会更明显。因此它适合这个轻量展示，但不是本仓库
   CPML 测试的替代品。

   .. code-block:: python

      hx -= (dt / (mu0 * dy)) * (ez[:, 1:] - ez[:, :-1])
      hy += (dt / (mu0 * dx)) * (ez[1:, :] - ez[:-1, :])

      curl_h = (hy[1:, 1:-1] - hy[:-1, 1:-1]) / dx - \
               (hx[1:-1, 1:] - hx[1:-1, :-1]) / dy
      ez[1:-1, 1:-1] += (dt / eps0) * curl_h

      ez[src_i, src_j] += np.sin(w0 * t)

   .. rubric:: 重点调用方式

   .. code-block:: text

      update Hx and Hy from Ez
      update Ez from Hx and Hy
      add center Ez source and Mur boundaries
      save |Ez| image

   .. rubric:: 结果和图像

   这张图显示单个输出时刻的 ``|Ez|`` 幅值。读图时先看源点附近是否形成平滑波前，再看波前是否
   大体向外传播，最后看外边界附近是否出现明显反射条纹。由于画的是幅值而不是 signed ``Ez``，
   相位正负被隐藏；它适合做形态检查，不适合当作误差收敛证据。

   .. figure:: ../../../../tests/005_maxwell/case_fdtd_2d_tm_cylindrical_wave/fdtd_2d_tm_cylindrical_wave.png
      :align: center
      :width: 62%

      2D TM ``|Ez|`` 圆形波前图。波前应围绕源位置形成清晰的外传结构。

   .. rubric:: 常见误读

   这张图适合发现明显的源项、边界或绘图错误；不要把它理解为 E01 柱坐标 RZ 算例。
   是否真正通过 Fortran 回归测试，应看 single-step、MMS 和稳定性测试。

   .. include:: _contributors_zh.inc

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   ``case_fdtd_2d_tm_cylindrical_wave`` is a Python-only 2D TM circular-wavefront
   visualization case. ``run.sh`` runs ``fdtd_2d_tm_cylindrical_wave.py`` to
   generate the figure; it does not compile or call any Fortran routine under
   ``E_Maxwell``. Here "cylindrical wave" means an outward circular wavefront on
   an ``x-y`` plane. The case is for documentation and qualitative inspection,
   not for strict Fortran routine regression.

   .. rubric:: Related Algorithm

   The interior Yee update is consistent with the 2D TMz reduction of
   :doc:`E03 3D Cartesian </rst_files/E_Maxwell/E03_Maxwell_3Dxyz>`:
   set ``∂/∂z = 0`` and keep only ``Hx, Hy, Ez`` from
   ``sub_E03_fdtd_3d_cartesian_H`` and ``sub_E03_fdtd_3d_cartesian_E``. The
   centered soft source and first-order Mur boundary are Python-side display
   choices, not parts of the E03 Fortran routines. This case is not the E01
   ``r-z`` cylindrical-coordinate TMz routine.

   .. rubric:: Files

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - File
        - Role
      * - ``fdtd_2d_tm_cylindrical_wave.py``
        - Python FDTD demo with a centered sinusoidal source.
      * - ``fdtd_2d_tm_cylindrical_wave.png``
        - Generated ``|Ez|`` reference image.
      * - ``run.sh``
        - Run the Python script and regenerate the image.

   .. rubric:: Run Command

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_fdtd_2d_tm_cylindrical_wave
      bash run.sh

   .. rubric:: Main Flow

   1. Build a 2D Cartesian ``x-y`` Yee grid.
   2. Add a centered sinusoidal ``Ez`` source.
   3. Update ``Hx/Hy`` and ``Ez`` using the 2D TMz reduction.
   4. Apply first-order Mur boundaries and save a ``|Ez|`` image.
   5. Visually inspect the outgoing circular wavefront.

   .. rubric:: Example: Centered ``Ez`` Source for a TMz Wavefront

   The most useful part of ``fdtd_2d_tm_cylindrical_wave.py`` is the field
   layout and update order. The script uses a ``201 x 201`` grid, ``dx=dy=0.054``,
   a two-dimensional CFL time step ``dt = dx/(c0*sqrt(2))``, and a ``278 MHz``
   sinusoidal source. The script directly uses an ``x/y`` Cartesian Yee grid;
   ``cylindrical_wave`` in the file name describes the circular wavefront shape,
   not a cylindrical-coordinate ``r-z`` discretization.

   .. code-block:: python

      nx, ny = 201, 201
      dx = dy = 0.054
      dt = dx / (c0 * np.sqrt(2.0))
      nsteps = 190
      f0 = 278.0e6

      ez = np.zeros((nx, ny), dtype=np.float64)
      hx = np.zeros((nx, ny - 1), dtype=np.float64)
      hy = np.zeros((nx - 1, ny), dtype=np.float64)

   Each step updates ``Hx/Hy`` from ``Ez``, updates interior ``Ez`` from the
   magnetic curl, and then adds the centered soft source. The four edges use a
   first-order Mur absorbing boundary condition. First-order Mur works best for
   nearly normal plane-wave incidence; oblique components in a cylindrical wave
   can reflect more strongly. It is sufficient for this compact visual demo, but
   it is not a substitute for the CPML regression cases.

   .. code-block:: python

      hx -= (dt / (mu0 * dy)) * (ez[:, 1:] - ez[:, :-1])
      hy += (dt / (mu0 * dx)) * (ez[1:, :] - ez[:-1, :])

      curl_h = (hy[1:, 1:-1] - hy[:-1, 1:-1]) / dx - \
               (hx[1:-1, 1:] - hx[1:-1, :-1]) / dy
      ez[1:-1, 1:-1] += (dt / eps0) * curl_h

      ez[src_i, src_j] += np.sin(w0 * t)

   .. rubric:: Core Pattern

   .. code-block:: text

      update Hx and Hy from Ez
      update Ez from Hx and Hy
      add center Ez source and Mur boundaries
      save |Ez| image

   .. rubric:: Result and Figure

   The figure shows ``|Ez|`` at one output time. Read it by checking whether a
   smooth wavefront forms near the source, whether it propagates outward, and
   whether obvious reflected stripes appear near the outer edges. Because the
   plotted quantity is a magnitude, signed phase information is hidden; use this
   figure for qualitative shape inspection, not convergence evidence.

   .. figure:: ../../../../tests/005_maxwell/case_fdtd_2d_tm_cylindrical_wave/fdtd_2d_tm_cylindrical_wave.png
      :align: center
      :width: 62%

      2D TM ``|Ez|`` circular-wavefront image.

   .. rubric:: Common Pitfall

   This image can reveal obvious source, boundary, or plotting mistakes. Do not
   read it as the E01 cylindrical-coordinate RZ case. Formal pass/fail evidence
   comes from the single-step, MMS, and stability tests.

   .. include:: _contributors_en.inc
