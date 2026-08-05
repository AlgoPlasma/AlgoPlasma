B01_scatter_3Dxyz Test
======================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   本页说明 ``tests/004_scatter/B01_scatter_3Dxyz`` 中的参考测试。
   测试覆盖 :doc:`B01_scatter_3Dxyz </rst_files/B_Scatter/B01_scatter_3Dxyz>`
   提供的三个子程序：

   - ``sub_B01_scatter_3Dxyz``：基础 CIC / 三线性粒子到网格沉积（密度）。
   - ``sub_B01_scatter_3Dxyz_v``：速度矩沉积，将 ``par(d,:) * w`` 按 CIC 权重分配到网格。
   - ``sub_B01_scatter_3Dxyz_T``：温度（方差）沉积，用最近格子法计算每格 ``<(v-<v>)²>``。

   .. rubric:: 程序结构

   - ``source_f90/main.f90`` 设置参数并依次运行 11 个 case。
   - ``source_f90/sub_case*.f90`` 给出每个算例的粒子布局、守恒量验证和误差输出。
   - ``source_py/plot_savefig.py`` 读取 ``build/output_case04_hollowH_*.dat``，生成密度切片图。
   - ``make.sh`` 使用 ``gfortran -cpp -O3 -fdefault-real-8 -fopenmp`` 编译测试程序。

   .. rubric:: 运行方式

   .. code-block:: bash

      cd tests/004_scatter/B01_scatter_3Dxyz
      bash clean.sh && bash make.sh && bash run.sh && bash plot.sh

   ``run.sh`` 在 ``build/`` 中生成 ``output_case*.dat``；
   ``plot.sh`` 生成 ``build/result_many.png``。

   .. rubric:: 测试算例

   **sub_B01_scatter_3Dxyz — 基础密度沉积（Cases 01–06）**

   .. list-table::
      :header-rows: 1
      :widths: 10 38 30 22

      * - Case
        - 粒子配置
        - 验证重点
        - 输出
      * - ``01``
        - 单粒子 ``(2.5, 3.5, 4.5)``，``w=1``
        - 8 节点各 ``0.125``；``sum(den)=1.0``。
        - ``output_case01.dat``
      * - ``02``
        - 单粒子 ``(2.2, 3.3, 4.4)``，``w=1``
        - 非中心位置的三线性权重；``sum(den)=1.0``。
        - ``output_case02.dat``
      * - ``03``
        - 3 个粒子，权重各 ``w=1``
        - 多粒子贡献叠加；``sum(den)=3.0``。
        - ``output_case03.dat``
      * - ``04``
        - 41 个粒子，分层 hollow-square / H / cross 图案
        - 结构化粒子云沉积形状与 ``sum(den)=41.0``。
        - ``output_case04_hollowH_den.dat``、``output_case04_hollowH_par.dat``
      * - ``05``
        - 10 万粒子，串行 vs 并行逐一对比（13 种线程数）
        - OMP 并行结果与串行结果逐节点一致；每次均打印 PASS。
        - 终端输出
      * - ``06``
        - 同上，重复 10 次基准（13 种线程数）
        - 记录平均 / 最佳 / 最差 speedup，供性能参考。
        - 终端输出

   **sub_B01_scatter_3Dxyz_v — 速度矩沉积（Cases 07–09）**

   .. list-table::
      :header-rows: 1
      :widths: 10 38 30 22

      * - Case
        - 粒子配置
        - 验证重点
        - 输出
      * - ``07``
        - 单粒子 ``(2.5, 3.5, 4.5)``，``vp=2.0``，``d=4``，对应 ``vx``
        - 8 节点 ``den_v`` 之和等于 ``w*vp=2.0``；中心粒子各节点等分。
        - ``output_case07.dat``
      * - ``08``
        - 单粒子 ``(2.2, 3.3, 4.4)``，``vp=-1.5``，``d=5``，对应 ``vy``
        - 非中心位置；``sum(den_v)=-1.5``；三线性权重对负值分量同样适用。
        - ``output_case08.dat``
      * - ``09``
        - 几何图案粒子（box / H / cross），``d=4``
        - ``sum(den_v) = w * sum(par(4,:))``，全局守恒验证。
        - ``output_case09_v_den.dat``、``output_case09_v_par.dat``

   **sub_B01_scatter_3Dxyz_T — 温度沉积（Cases 10–11）**

   .. list-table::
      :header-rows: 1
      :widths: 10 42 48

      * - Case
        - 配置
        - 验证重点
      * - ``10``
        - 5 组解析单元测试（A–E）：单粒子 T=0、均匀速度 T=0、±v T=v²、
          [1,3,1,3] T=1、两格独立
        - 每组精确 PASS/FAIL（tol=1e-5），覆盖最近格子法方差公式的边界和典型情形。
      * - ``11``
        - 3 层 5×5 空间图案：[1,3,1,3]→T=1.0，[+2,−2]→T=4.0，[5,5,5,5]→T=0.0
        - 层求和：25×1.0=25、25×4.0=100、25×0.0=0；全局守恒验证。

   .. rubric:: 参考图

   .. figure:: ../../images/tests/004_scatter/B01_scatter_3Dxyz/result_many.png
      :align: center
      :width: 92%

      ``case04`` 粒子布局与沉积密度切片。左上为 3D 粒子位置；右上为 ``k=5`` 的
      ``x-y`` 切片；左下为 ``j=5`` 的 ``x-z`` 切片；右下为 ``i=5`` 的 ``y-z`` 切片。

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   This page documents the reference test under
   ``tests/004_scatter/B01_scatter_3Dxyz``. The test covers the three
   subroutines provided by
   :doc:`B01_scatter_3Dxyz </rst_files/B_Scatter/B01_scatter_3Dxyz>`:

   - ``sub_B01_scatter_3Dxyz``: basic CIC / trilinear particle-to-grid scatter (density).
   - ``sub_B01_scatter_3Dxyz_v``: velocity-moment scatter — deposits ``par(d,:) * w`` to the grid with CIC weights.
   - ``sub_B01_scatter_3Dxyz_T``: temperature (variance) scatter — computes ``<(v-<v>)²>`` per cell using the nearest-cell assignment.

   .. rubric:: Program Structure

   - ``source_f90/main.f90`` sets up and runs 11 cases in sequence.
   - ``source_f90/sub_case*.f90`` defines particle layouts, conservation checks, and error output.
   - ``source_py/plot_savefig.py`` reads ``build/output_case04_hollowH_*.dat`` and writes a density-slice figure.
   - ``make.sh`` compiles with ``gfortran -cpp -O3 -fdefault-real-8 -fopenmp``.

   .. rubric:: Run Command

   .. code-block:: bash

      cd tests/004_scatter/B01_scatter_3Dxyz
      bash clean.sh && bash make.sh && bash run.sh && bash plot.sh

   ``run.sh`` writes ``output_case*.dat`` files in ``build/``.
   ``plot.sh`` writes ``build/result_many.png``.

   .. rubric:: Test Cases

   **sub_B01_scatter_3Dxyz — basic density scatter (Cases 01–06)**

   .. list-table::
      :header-rows: 1
      :widths: 10 38 30 22

      * - Case
        - Particle setup
        - Check
        - Output
      * - ``01``
        - One particle at ``(2.5, 3.5, 4.5)``, ``w=1``
        - All 8 nodes receive ``0.125``; ``sum(den)=1.0``.
        - ``output_case01.dat``
      * - ``02``
        - One particle at ``(2.2, 3.3, 4.4)``, ``w=1``
        - Trilinear weights for an off-center particle; ``sum(den)=1.0``.
        - ``output_case02.dat``
      * - ``03``
        - 3 particles, each ``w=1``
        - Accumulated multi-particle contributions; ``sum(den)=3.0``.
        - ``output_case03.dat``
      * - ``04``
        - 41 particles forming layered hollow-square, H, and cross patterns
        - Deposited shape and ``sum(den)=41.0``.
        - ``output_case04_hollowH_den.dat``, ``output_case04_hollowH_par.dat``
      * - ``05``
        - 100k particles; serial vs. parallel compared for 13 thread counts
        - OMP result matches serial node-by-node; prints PASS each time.
        - Terminal output
      * - ``06``
        - Same; benchmark repeated 10 times for 13 thread counts
        - Records avg/best/worst speedup for performance reference.
        - Terminal output

   **sub_B01_scatter_3Dxyz_v — velocity-moment scatter (Cases 07–09)**

   .. list-table::
      :header-rows: 1
      :widths: 10 38 30 22

      * - Case
        - Particle setup
        - Check
        - Output
      * - ``07``
        - One particle at ``(2.5, 3.5, 4.5)``, ``vp=2.0``, ``d=4`` (``vx``)
        - ``sum(den_v)=w*vp=2.0``; equal split across 8 nodes for center particle.
        - ``output_case07.dat``
      * - ``08``
        - One particle at ``(2.2, 3.3, 4.4)``, ``vp=-1.5``, ``d=5`` (``vy``)
        - ``sum(den_v)=-1.5``; trilinear weights apply correctly to negative velocity.
        - ``output_case08.dat``
      * - ``09``
        - Geometric pattern (box/H/cross), ``d=4``
        - Global conservation: ``sum(den_v) = w * sum(par(4,:))``.
        - ``output_case09_v_den.dat``, ``output_case09_v_par.dat``

   **sub_B01_scatter_3Dxyz_T — temperature scatter (Cases 10–11)**

   .. list-table::
      :header-rows: 1
      :widths: 10 42 48

      * - Case
        - Setup
        - Check
      * - ``10``
        - 5 analytical unit tests (A–E): single particle T=0, uniform velocity T=0,
          ±v giving T=v², pattern [1,3,1,3] giving T=1, two independent cells
        - Each sub-test prints exact PASS/FAIL (tol=1e-5), covering boundary
          and typical cases of the nearest-cell variance formula.
      * - ``11``
        - 3-layer 5×5 spatial pattern: [1,3,1,3]→T=1.0, [+2,−2]→T=4.0, [5,5,5,5]→T=0.0
        - Layer sums: 25×1.0=25, 25×4.0=100, 25×0.0=0; global conservation verified.

   .. rubric:: Reference Figure

   .. figure:: ../../images/tests/004_scatter/B01_scatter_3Dxyz/result_many.png
      :align: center
      :width: 92%

      ``case04`` particle layout and deposited-density slices. Upper-left: 3D
      particle positions. Upper-right: ``x-y`` slice at ``k=5``. Lower-left:
      ``x-z`` slice at ``j=5``. Lower-right: ``y-z`` slice at ``i=5``.
