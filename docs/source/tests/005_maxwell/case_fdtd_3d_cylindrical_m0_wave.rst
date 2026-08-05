case_fdtd_3d_cylindrical_m0_wave
================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   ``case_fdtd_3d_cylindrical_m0_wave`` 是 Python-only 的 3D cylindrical 波导/柱坐标波传播可视化案例。
   ``run.sh`` 运行 ``fdtd_3d_cylindrical_m0_wave.py`` 生成图片，不编译、也不调用 ``E_Maxwell``
   目录中的 Fortran 子程序。它用于直观展示柱坐标几何、轴线处理和横截面模式形态；当前脚本不是
   E02 六分量 Fortran 内核的逐点回归测试。

   .. rubric:: 对应算法

   该脚本在几何上接近 :doc:`E02 3D cylindrical </rst_files/E_Maxwell/E02_Maxwell_3Drtz>`，但算法上
   不是 ``sub_E02_fdtd_3d_cylindrical_H`` 和 ``sub_E02_fdtd_3d_cylindrical_E`` 的六分量 Yee 更新。
   它推进的是标量 ``Ez`` 波动方程，显式写出柱坐标 Laplacian、轴线闭合和 PEC 外壁。严格检查
   E02 与 ``m=0`` 简化的一致性时，应看 :doc:`m=0 equivalence <case_fdtd_cyl_m0_equivalence>`。

   .. rubric:: 文件说明

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 文件
        - 作用
      * - ``fdtd_3d_cylindrical_m0_wave.py``
        - Python cylindrical FDTD 可视化脚本。
      * - ``fdtd_3d_cylindrical_m0_wave_rz.png``
        - 页面保留的 ``r-z`` 截面传播快照；当前 ``run.sh`` 不重新生成该图。
      * - ``fdtd_3d_cylindrical_waveguide_mode.png``
        - 当前脚本生成的固定 ``z`` 横截面 ``|Ez|`` 模式形态示意图，含 ``cos(phi)`` 角向结构。
      * - ``run.sh``
        - 运行 Python 脚本并重新生成图像。

   .. rubric:: 运行方式

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_fdtd_3d_cylindrical_m0_wave
      bash run.sh

   当前 ``run.sh`` 会重新生成 ``fdtd_3d_cylindrical_waveguide_mode.png``。页面中的
   ``fdtd_3d_cylindrical_m0_wave_rz.png`` 是保留的传播快照，用于辅助说明 ``r-z`` 截面如何读图。

   .. rubric:: 主流程

   1. 建立 ``r,phi,z`` 柱坐标网格。
   2. 设置可视化源；当前横截面模式图使用带 ``cos(phi)`` 的角向源。
   3. 按 cylindrical metric 更新标量 ``Ez`` 波动方程。
   4. 当前脚本重新生成横截面模式图；页面同时保留一张 ``r-z`` 截面传播快照。
   5. 用图像检查轴线附近、外半径、角向结构和传播形态。

   .. rubric:: 典型例子：圆柱波导中的 ``Ez`` 模式

   ``fdtd_3d_cylindrical_m0_wave.py`` 是一个偏展示型的标量 ``Ez`` 波动方程例子，用来帮助读者理解
   ``r,phi,z`` 几何和轴线处理。脚本设置半径 ``a=0.027 m`` 的圆柱波导，``nr=30``、``nphi=16``、
   ``nz=140``，源位于入口附近 ``z_src=2``，径向包络乘以 ``cos(phi)``，因此横截面图会出现清晰的模式结构。
   由于 ``cos(phi)`` 引入了角向变化，第二张横截面图应理解为带角向结构的模式示意图，而不是严格的
   ``m=0`` 本征模参考解。

   .. code-block:: python

      nr = 30
      nphi = 16
      nz = 140
      dr = a / (nr - 1)
      dphi = 2.0 * np.pi / nphi
      dz = lam0 / 18.0

      z_src = 2
      src_profile = np.exp(-((r[:, None] - r0) / wr) ** 2) * np.cos(phi[None, :])

   主循环里显式写出柱坐标 Laplacian：内部点包含 ``urr``、``ur/r``、``uphi`` 和 ``uzz``，
   轴线 ``r=0`` 单独用有限值极限闭合，外壁 ``r=a`` 设置为 PEC 的 ``Ez=0``。这类脚本不是
   E02 Fortran 六分量内核的逐点回归，也不能替代 ``sub_E02_fdtd_3d_cylindrical_H/E`` 的一致性测试，
   但能直观展示柱坐标网格、轴线和 ``phi`` 周期方向如何影响图像。

   .. code-block:: python

      lap = urr + ur / r[1:-1, None, None] + uphi + uzz
      ez_next[1:-1, :, 1:-1] = 2.0 * ui - ez_prev[1:-1, :, 1:-1] + cfl2 * lap

      urr_a = 4.0 * (ez[1, :, 1:-1] - ua) / (dr * dr)
      ez_next[0, :, 1:-1] = 2.0 * ua - ez_prev[0, :, 1:-1] + cfl2 * (urr_a + uzz_a)
      ez_next[-1, :, :] = 0.0

   .. rubric:: 重点调用方式

   .. code-block:: text

      initialize cylindrical scalar Ez field
      update Ez with cylindrical metric terms
      apply axis handling and PEC outer wall
      plot retained r-z snapshot and regenerated cross-section mode shape

   .. rubric:: 结果和图像

   .. rubric:: 如何看第一张 ``r-z`` 图

   第一张图是 ``r-z`` 截面上的传播快照，横轴为半径方向 ``r``，纵轴为轴向 ``z``，颜色为场幅值
   ``|u|``。读图时主要看三件事：轴线 ``r=0`` 附近是否平滑、波前是否从源附近向外传播、
   外侧暗区和边界附近是否出现明显非物理反射。因为图中画的是幅值，正负相位已经被取绝对值隐藏；
   因此它适合做几何和传播形态检查，不是严格误差图，也不是解析模态验证图。

   .. figure:: ../../../../tests/005_maxwell/case_fdtd_3d_cylindrical_m0_wave/fdtd_3d_cylindrical_m0_wave_rz.png
      :align: center
      :width: 64%

      3D cylindrical 的 ``r-z`` 截面传播快照。颜色表示幅值，主要用于检查轴线、波前和边界附近行为。

   .. rubric:: 如何看第二张横截面图

   第二张图把某个固定 ``z`` 截面上的 ``(r,\phi)`` 数据转换到 ``(x,y)`` 平面显示，颜色为
   ``|Ez|``。圆形外边界附近接近零，对应脚本中的 PEC 外壁 ``Ez=0``。图中左右两个亮瓣和中间暗线
   来自源项里的 ``cos(phi)``：若画 signed ``Ez``，左右两瓣应带相反符号；现在画 ``|Ez|``，
   所以只显示幅值大小。这个图可以帮助读者理解角向网格和模式形态，但不能作为严格的 ``m=0``
   波导本征模参考图；真正的 ``m=0`` 横截面应不随 ``phi`` 变化，形态应近似轴对称。

   .. figure:: ../../../../tests/005_maxwell/case_fdtd_3d_cylindrical_m0_wave/fdtd_3d_cylindrical_waveguide_mode.png
      :align: center
      :width: 62%

      固定 ``z`` 截面上的 ``|Ez|`` 模式形态示意图。该图含 ``cos(phi)`` 角向结构，不是严格
      ``m=0`` 本征模参考解。

   .. rubric:: 常见误读

   ``m=0`` 表示无 ``phi`` 变化；它不覆盖 ``m=1`` 的角向相位、周期缝和对应轴线自由度问题。
   当前横截面图由于使用 ``cos(phi)`` 源，更适合看作角向模式可视化示意，而不是 ``m=0`` 验证。
   严格几何一致性请看 :doc:`m=0 equivalence <case_fdtd_cyl_m0_equivalence>`。

   .. include:: _contributors_zh.inc

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   ``case_fdtd_3d_cylindrical_m0_wave`` is a Python-only 3D cylindrical
   waveguide/cylindrical-wave visualization case. ``run.sh`` runs
   ``fdtd_3d_cylindrical_m0_wave.py`` to generate figures; it does not compile
   or call any Fortran routine under ``E_Maxwell``. The case illustrates
   cylindrical geometry, axis handling, and cross-section mode shape; it is not
   a pointwise regression test for the E02 six-component Fortran kernels.

   .. rubric:: Related Algorithm

   The script is geometrically related to
   :doc:`E02 3D cylindrical </rst_files/E_Maxwell/E02_Maxwell_3Drtz>`, but it is
   not the six-component Yee update implemented by
   ``sub_E02_fdtd_3d_cylindrical_H`` and ``sub_E02_fdtd_3d_cylindrical_E``. It
   advances a scalar ``Ez`` wave equation with an explicit cylindrical
   Laplacian, axis closure, and PEC outer wall. For strict E02 versus ``m=0``
   consistency, use :doc:`m=0 equivalence <case_fdtd_cyl_m0_equivalence>`.

   .. rubric:: Files

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - File
        - Role
      * - ``fdtd_3d_cylindrical_m0_wave.py``
        - Python cylindrical FDTD visualization script.
      * - ``fdtd_3d_cylindrical_m0_wave_rz.png``
        - Retained ``r-z`` propagation snapshot; it is not regenerated by the
          current ``run.sh``.
      * - ``fdtd_3d_cylindrical_waveguide_mode.png``
        - Regenerated fixed-``z`` ``|Ez|`` cross-section mode-shape
          visualization with a ``cos(phi)`` angular structure.
      * - ``run.sh``
        - Run the Python script and regenerate figures.

   .. rubric:: Run Command

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_fdtd_3d_cylindrical_m0_wave
      bash run.sh

   The current ``run.sh`` regenerates
   ``fdtd_3d_cylindrical_waveguide_mode.png``. The page keeps
   ``fdtd_3d_cylindrical_m0_wave_rz.png`` as a retained propagation snapshot to
   explain how an ``r-z`` section should be read.

   .. rubric:: Main Flow

   1. Build an ``r,phi,z`` cylindrical grid.
   2. Configure a visualization source; the current cross-section mode figure
      uses an angular ``cos(phi)`` source.
   3. Update the scalar ``Ez`` wave equation with cylindrical metric terms.
   4. Regenerate the cross-section mode figure; the page also keeps one retained
      ``r-z`` propagation snapshot.
   5. Inspect axis, outer-radius, angular structure, and propagation behavior.

   .. rubric:: Example: ``Ez`` Mode in a Cylindrical Waveguide

   ``fdtd_3d_cylindrical_m0_wave.py`` is a visualization-oriented scalar
   ``Ez`` wave-equation example. It helps readers see how the ``r,phi,z``
   geometry and axis treatment appear in a plot. The script uses a circular
   waveguide of radius ``a=0.027 m`` with ``nr=30``, ``nphi=16``, and ``nz=140``.
   The source is placed near the entrance at ``z_src=2`` and uses a radial
   envelope multiplied by ``cos(phi)``. Since ``cos(phi)`` introduces angular
   variation, the cross-section figure should be read as an angular-mode
   visualization, not as a strict ``m=0`` eigenmode reference.

   .. code-block:: python

      nr = 30
      nphi = 16
      nz = 140
      dr = a / (nr - 1)
      dphi = 2.0 * np.pi / nphi
      dz = lam0 / 18.0

      z_src = 2
      src_profile = np.exp(-((r[:, None] - r0) / wr) ** 2) * np.cos(phi[None, :])

   The loop writes the cylindrical Laplacian explicitly. Interior points use
   ``urr``, ``ur/r``, ``uphi``, and ``uzz``; the axis uses a finite-value
   closure; and the outer wall uses a PEC-style ``Ez=0`` condition. This script
   is not a pointwise regression of the E02 six-component Fortran kernels and
   cannot replace consistency tests for ``sub_E02_fdtd_3d_cylindrical_H/E``. It
   is useful for understanding cylindrical indexing, the axis, and the periodic
   ``phi`` direction.

   .. code-block:: python

      lap = urr + ur / r[1:-1, None, None] + uphi + uzz
      ez_next[1:-1, :, 1:-1] = 2.0 * ui - ez_prev[1:-1, :, 1:-1] + cfl2 * lap

      urr_a = 4.0 * (ez[1, :, 1:-1] - ua) / (dr * dr)
      ez_next[0, :, 1:-1] = 2.0 * ua - ez_prev[0, :, 1:-1] + cfl2 * (urr_a + uzz_a)
      ez_next[-1, :, :] = 0.0

   .. rubric:: Core Pattern

   .. code-block:: text

      initialize cylindrical scalar Ez field
      update Ez with cylindrical metric terms
      apply axis handling and PEC outer wall
      plot retained r-z snapshot and regenerated cross-section mode shape

   .. rubric:: Results and Figures

   .. rubric:: How to Read the ``r-z`` Figure

   The first figure is a propagation snapshot on an ``r-z`` section. The
   horizontal axis is the radial coordinate ``r``, the vertical axis is the axial
   coordinate ``z``, and the color shows the field magnitude ``|u|``. Use it to
   check whether the axis near ``r=0`` remains smooth, whether the wavefront
   leaves the source region coherently, and whether the outer region or
   boundaries show obvious nonphysical reflections. Because the figure shows a
   magnitude, the signed phase information is hidden. It is therefore a
   qualitative geometry/propagation check, not an error map or analytic mode
   validation.

   .. figure:: ../../../../tests/005_maxwell/case_fdtd_3d_cylindrical_m0_wave/fdtd_3d_cylindrical_m0_wave_rz.png
      :align: center
      :width: 64%

      ``r-z`` propagation snapshot for a 3D cylindrical visualization case.

   .. rubric:: How to Read the Cross-Section Figure

   The second figure maps ``(r,\phi)`` data at one fixed ``z`` section onto the
   ``(x,y)`` plane and plots ``|Ez|``. The near-zero circular outer edge comes
   from the PEC-style wall condition ``Ez=0``. The two bright lobes and central
   dark line come from the ``cos(phi)`` source: a signed ``Ez`` plot would show
   opposite signs on the two sides, while the magnitude plot only shows their
   amplitude. This makes the figure useful for reading the angular grid and mode
   shape, but it should not be treated as a strict ``m=0`` waveguide eigenmode
   reference. A true ``m=0`` cross section would be independent of ``phi`` and
   approximately axisymmetric.

   .. figure:: ../../../../tests/005_maxwell/case_fdtd_3d_cylindrical_m0_wave/fdtd_3d_cylindrical_waveguide_mode.png
      :align: center
      :width: 62%

      ``|Ez|`` mode-shape visualization on a fixed ``z`` section. The angular
      ``cos(phi)`` structure means this is not a strict ``m=0`` eigenmode
      reference.

   .. rubric:: Common Pitfall

   ``m=0`` means no ``phi`` variation. It does not cover ``m=1`` angular phase,
   periodic seams, or its axis inactive DOFs. Because the current cross-section
   figure uses a ``cos(phi)`` source, read it as an angular-mode visualization
   rather than an ``m=0`` validation figure. For strict geometry consistency, see
   :doc:`m=0 equivalence <case_fdtd_cyl_m0_equivalence>`.

   .. include:: _contributors_en.inc
