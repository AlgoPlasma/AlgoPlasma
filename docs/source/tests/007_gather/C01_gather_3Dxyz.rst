C01_gather_3Dxyz Test
=====================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   本页说明 ``tests/007_gather/C01_gather_3Dxyz`` 中的参考测试。该测试覆盖
   :doc:`C01_gather_3Dxyz </rst_files/C_Gather/C01_gather_3Dxyz>` 提供的两个接口：

   - ``sub_C01_gather_3Dxyz``：把 cell-centered 三维 Cartesian 电磁场
     ``Ex,Ey,Ez,Bx,By,Bz`` gather 到单个粒子位置。
   - ``sub_C01_gather_3Dxyz_push``：在同一个粒子循环中完成 gather、Boris 速度更新和位置推进。

   测试重点是局部验证 C01 的三线性插值和 fused gather-push。它回答三个问题：

   - 网格场为三线性解析函数时，C01 是否能精确还原粒子位置处的解析场值？
   - 网格场为光滑但非三线性函数时，网格加密后 gather 误差是否下降？
   - ``B=0`` 时，fused gather-push 是否等价于一次解析电场加速？

   该测试不是完整 PIC 回路测试；不覆盖 MPI 分解、边界交换、粒子沉积或场推进。

   .. rubric:: 程序结构

   - ``source_f90/main.f90`` 构造三组人造场和粒子，调用 C01，并写出 CSV。
   - ``source_py/analyze.py`` 读取 CSV，独立计算解析参考值，统计误差并生成图片。
   - ``make.sh`` 使用 ``gfortran -cpp -O2 -fdefault-real-8 -fopenmp`` 编译测试程序。
   - ``run.sh`` 依次执行清理、编译、Fortran 测试和 Python 后处理。
   - ``clean.sh`` 删除 ``build/``、``output/`` 和 Python 缓存。

   .. rubric:: 运行方式

   .. code-block:: bash

      cd tests/007_gather/C01_gather_3Dxyz
      bash run.sh

   ``run.sh`` 会生成 ``output/*.csv``、``output/summary.json`` 和
   ``output/figures/*.png``。文档中的静态图是从一次参考运行复制到
   ``docs/source/images/tests/007_gather/C01_gather_3Dxyz`` 的结果。

   .. rubric:: 输出字段

   - ``output/c01_exact.csv``：每个粒子的 ``px,py,pz`` 和 C01 gather 得到的
     ``Ex,Ey,Ez,Bx,By,Bz``。
   - ``output/c01_convergence.csv``：网格数 ``n``、网格间距 ``h``、物理坐标
     ``x,y,z`` 和六个 gather 场分量。
   - ``output/c01_push.csv``：推进前后的粒子位置和速度，即 ``x0,y0,z0,vx0,vy0,vz0``
     与 ``x1,y1,z1,vx1,vy1,vz1``。
   - ``output/summary.json``：三个 case 的最大误差、收敛阶和 PASS/FAIL。

   .. rubric:: 坐标约定

   C01 内部使用下面的 cell-centered 坐标偏移：

   .. code-block:: fortran

      x = par(1,p) + 0.5
      y = par(2,p) + 0.5
      z = par(3,p) + 0.5

   因此 Python 解析参考值也在
   :math:`(par_1+0.5, par_2+0.5, par_3+0.5)` 处计算。这个测试同时检查该
   ``+0.5`` 坐标约定是否被正确使用。

   .. rubric:: 测试算例

   .. list-table::
      :header-rows: 1
      :widths: 16 38 32 14

      * - Case
        - 设置
        - 主要检查
        - 判据
      * - ``exact``
        - 在网格点上填入六个不同的三线性解析场分量，并放置 60 个非整数位置粒子。
        - 三线性插值对三线性函数应精确，所以 C01 gather 值应等于粒子位置解析值。
        - 最大绝对误差 ``< 1e-11``。
      * - ``convergence``
        - 使用 ``N=12,24,48`` 三套网格，填入同一个光滑解析场，并在相同物理位置放置 125 个粒子。
        - 光滑场不是三线性函数，误差不为零；但网格加密后误差应下降。
        - 最小观测收敛阶 ``> 1.75``。
      * - ``push``
        - 设置 16 个粒子，电场为三线性解析场，磁场设为 ``B=0``，调用 fused gather-push。
        - ``B=0`` 时 Boris 推进退化为纯电场加速，可直接写出解析参考更新。
        - 更新后 ``x,v`` 最大绝对误差 ``< 1e-11``。

   ``source_py/analyze.py`` 不调用 C01；它只读取 Fortran 输出并独立计算参考答案。
   ``push`` case 使用的参考更新为

   .. math::

      \mathbf{v}^{n+1}=\mathbf{v}^{n}+\frac{q}{m}\mathbf{E}\Delta t,\qquad
      \mathbf{x}^{n+1}=\mathbf{x}^{n}+\mathbf{v}^{n+1}\Delta t.

   .. rubric:: 参考图

   .. figure:: ../../images/tests/007_gather/C01_gather_3Dxyz/c01_ref_vs_num.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``exact`` case 的场值对比。横轴为粒子位置处的解析场分量值，纵轴为
      C01 gather 得到的同一分量值。每个点代表一个粒子的一个
      ``Ex/Ey/Ez/Bx/By/Bz`` 分量；点越贴近虚线，说明 gather 越接近解析值。

   .. figure:: ../../images/tests/007_gather/C01_gather_3Dxyz/c01_convergence.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``convergence`` case 的误差随网格间距变化。横轴为 ``h=1/N``，纵轴为
      gather 场分量相对解析值的误差。``L2`` 汇总所有粒子和六个场分量，
      ``Linf`` 是最大单分量误差。

   .. figure:: ../../images/tests/007_gather/C01_gather_3Dxyz/c01_push_displacement.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``push`` case 的粒子单步位移。每条线段从推进前 ``(x0,y0)`` 指向推进后
      ``(x1,y1)``，用于观察 fused gather-push 的位移方向和量级。

   .. rubric:: 参考运行结果

   .. code-block:: text

      exact max_abs error      : 8.882e-16
      convergence min order   : 1.936
      fused push max_abs error: 2.776e-17
      result                  : PASS

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   This page documents the reference test under
   ``tests/007_gather/C01_gather_3Dxyz``. The test covers two interfaces from
   :doc:`C01_gather_3Dxyz </rst_files/C_Gather/C01_gather_3Dxyz>`:

   - ``sub_C01_gather_3Dxyz``: gathers cell-centered 3D Cartesian
     electromagnetic fields ``Ex,Ey,Ez,Bx,By,Bz`` to one particle.
   - ``sub_C01_gather_3Dxyz_push``: performs gather, Boris velocity update,
     and position advance in one particle loop.

   The test locally verifies C01 trilinear interpolation and fused gather-push.
   It checks whether trilinear grid fields are reproduced exactly at particle
   positions, whether smooth-field gather errors decrease under refinement,
   and whether ``B=0`` fused gather-push matches one analytic electric
   acceleration step. It does not test a full PIC loop, MPI decomposition,
   boundary exchange, deposition, or field solve.

   .. rubric:: Program Structure

   - ``source_f90/main.f90`` constructs three synthetic field/particle cases, calls C01, and writes CSV files.
   - ``source_py/analyze.py`` reads the CSV files, computes independent analytic references, computes errors, and saves figures.
   - ``make.sh`` compiles with ``gfortran -cpp -O2 -fdefault-real-8 -fopenmp``.
   - ``run.sh`` performs cleanup, build, Fortran execution, and Python postprocessing.
   - ``clean.sh`` removes ``build/``, ``output/``, and Python cache files.

   .. rubric:: Run Command

   .. code-block:: bash

      cd tests/007_gather/C01_gather_3Dxyz
      bash run.sh

   ``run.sh`` writes ``output/*.csv``, ``output/summary.json``, and
   ``output/figures/*.png``. The static figures below are copied from one
   reference run into ``docs/source/images/tests/007_gather/C01_gather_3Dxyz``.

   .. rubric:: Output Fields

   - ``output/c01_exact.csv``: particle ``px,py,pz`` and gathered
     ``Ex,Ey,Ez,Bx,By,Bz``.
   - ``output/c01_convergence.csv``: grid size ``n``, grid spacing ``h``,
     physical coordinates ``x,y,z``, and gathered field components.
   - ``output/c01_push.csv``: particle position/velocity before and after the
     step: ``x0,y0,z0,vx0,vy0,vz0`` and ``x1,y1,z1,vx1,vy1,vz1``.
   - ``output/summary.json``: errors, convergence order, and PASS/FAIL for the
     three cases.

   .. rubric:: Coordinate Convention

   C01 uses the following cell-centered shift:

   .. code-block:: fortran

      x = par(1,p) + 0.5
      y = par(2,p) + 0.5
      z = par(3,p) + 0.5

   Therefore Python evaluates references at
   :math:`(par_1+0.5, par_2+0.5, par_3+0.5)`. The test also checks that this
   ``+0.5`` convention is used consistently.

   .. rubric:: Test Cases

   .. list-table::
      :header-rows: 1
      :widths: 16 38 32 14

      * - Case
        - Setup
        - Main check
        - Criterion
      * - ``exact``
        - Six different trilinear analytic field components are sampled on grid nodes; 60 particles are placed at non-integer positions.
        - Trilinear interpolation should reproduce the analytic value at each particle.
        - Max absolute error ``< 1e-11``.
      * - ``convergence``
        - Grids ``N=12,24,48`` use the same smooth analytic field; 125 particles stay at fixed physical positions.
        - The field is not trilinear, so the error is nonzero but should decrease under mesh refinement.
        - Minimum observed order ``> 1.75``.
      * - ``push``
        - 16 particles, trilinear electric field, and ``B=0``; fused gather-push is called.
        - With ``B=0``, Boris reduces to a directly checkable electric acceleration step.
        - Max absolute error in updated ``x,v`` ``< 1e-11``.

   ``source_py/analyze.py`` does not call C01; it reads Fortran output and
   computes independent references. In the ``push`` case the reference is

   .. math::

      \mathbf{v}^{n+1}=\mathbf{v}^{n}+\frac{q}{m}\mathbf{E}\Delta t,\qquad
      \mathbf{x}^{n+1}=\mathbf{x}^{n}+\mathbf{v}^{n+1}\Delta t.

   .. rubric:: Reference Figures

   .. figure:: ../../images/tests/007_gather/C01_gather_3Dxyz/c01_ref_vs_num.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``exact`` field comparison. x-axis: analytic field component at the
      particle. y-axis: the same component gathered by C01. Each point is one
      particle-component pair from ``Ex/Ey/Ez/Bx/By/Bz``.

   .. figure:: ../../images/tests/007_gather/C01_gather_3Dxyz/c01_convergence.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``convergence`` error versus grid spacing. x-axis: ``h=1/N``. y-axis:
      error of gathered field components against the analytic field. ``L2``
      uses all particles/components; ``Linf`` is the largest single component error.

   .. figure:: ../../images/tests/007_gather/C01_gather_3Dxyz/c01_push_displacement.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      ``push`` one-step displacement. Each segment goes from ``(x0,y0)``
      before the step to ``(x1,y1)`` after the step.

   .. rubric:: Reference Result

   .. code-block:: text

      exact max_abs error      : 8.882e-16
      convergence min order   : 1.936
      fused push max_abs error: 2.776e-17
      result                  : PASS
