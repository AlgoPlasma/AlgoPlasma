I01_par_distribute Test
=======================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   本页说明 ``tests/006_initializer/I01_par_distribute`` 中的参考测试。
   测试验证
   :doc:`I01_par_distribute </rst_files/I_Initializer/I01_par_distribute>`
   提供的 ``sub_I01_par_distribute_equilibrium(par, nppc, il, iu, vt, vd)``——
   这个函数负责在 3D 网格上均匀铺粒子并按 Maxwell 分布赋初速度。
   覆盖以下四个方面：

   - **粒子数**：实际填充数是否等于 :math:`\prod(\text{iu}-\text{il}+1)\times\prod\text{nppc}`。
   - **空间位置**：每个粒子坐标是否严格满足 :math:`x = (i-1) + (i_p + 0.5)/\text{nppc}_x`。
   - 零热速度退化：``vt=0`` 时所有粒子速度是否精确等于漂移速度 ``vd`` （浮点精确，误差为 0）。
   - **Maxwell 速度分布统计**：大样本（N=125000）下均值是否趋近 ``vd``、标准差是否趋近 ``vt``，容差 5%。

   .. rubric:: 程序结构

   - ``source_f90/main.f90`` 依次运行四个 case。
   - ``source_f90/sub_case01_count.f90``：哨兵法（sentinel）验证粒子数边界。
   - ``source_f90/sub_case02_positions.f90``：逐粒子比对坐标解析公式，容差 1e-6。
   - ``source_f90/sub_case03_vt0.f90``：``vt=0`` 时速度精确等于 ``vd``，误差严格为 0。
   - ``source_f90/sub_case04_maxwellian.f90``：统计均值/标准差并输出 ``case04_maxwellian.dat``。
   - ``source_py/plot_savefig.py`` 读取 ``build/case04_maxwellian.dat``，绘制速度分布直方图。
   - ``make.sh`` 使用 ``gfortran -cpp -O3 -fdefault-real-8`` 编译（无 OpenMP 依赖）。

   .. rubric:: 运行方式

   .. code-block:: bash

      cd tests/006_initializer/I01_par_distribute
      bash clean.sh && bash make.sh && bash run.sh && bash plot.sh

   ``run.sh`` 在 ``build/`` 中生成 ``case04_maxwellian.dat``；
   ``plot.sh`` 在 ``figs/`` 中生成 ``case04_maxwellian_hist.png``。

   .. rubric:: 测试算例

   .. list-table::
      :header-rows: 1
      :widths: 10 38 30 22

      * - Case
        - 配置
        - 验证重点
        - 输出
      * - ``01``
        - A: 3×3×3 格 × 2×3×4 ppc = 648；B: 1×1×1 格 × 1×1×1 ppc = 1；C: 5×4×3 格 × 3×2×4 ppc = 1440
        - 粒子数精确等于 ``np``：分配 np+1 个槽全部预填极小值，调用后第 np 槽已写入、第 np+1 槽未被碰过。
        - 终端输出
      * - ``02``
        - A: 单格 il=iu=[2,3,4]，nppc=[4,3,2]，24 粒子；B: 2×2×2 格，nppc=[2,2,2]，64 粒子
        - 每个粒子位置正确：按循环顺序（k,j,i 外层；kp,jp,ip 内层）逐粒子比对解析坐标，最大误差 < 1e-6。
        - 终端输出
      * - ``03``
        - A: 4×4×4 格，nppc=[3,3,3]，vt=0，vd=(1.5,−2.0,3.7)；B: 2×2×2 格，vt=vd=0
        - ``vt=0`` 时每个粒子速度精确等于 ``vd``，误差严格为 0（浮点数 ``0.0 × g = 0.0``，不是近似）。
        - 终端输出
      * - ``04``
        - 10×10×10 格，nppc=[5,5,5]，N=125000；vt=(1,2,3)，vd=(0.5,−1,2)
        - :math:`|\bar{v}_\alpha - v_{d,\alpha}| < 0.05\,v_{t,\alpha}` 且 :math:`|\sigma_\alpha - v_{t,\alpha}| < 0.05\,v_{t,\alpha}`；5% 容差约 17–25 个统计标准误，几乎不会随机失败。
        - ``case04_maxwellian.dat``

   .. rubric:: 参考图

   .. figure:: ../../images/tests/006_initializer/I01_par_distribute/case04_maxwellian_hist.png
      :align: center
      :width: 92%

      Case 04 速度分布直方图（N=125000）。三个分量分别以对应的高斯曲线
      :math:`\mathcal{N}(v_d, v_t^2)` 叠加验证 Box-Muller 采样的正确性。

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   This page documents the reference test under
   ``tests/006_initializer/I01_par_distribute``. The test verifies
   ``sub_I01_par_distribute_equilibrium(par, nppc, il, iu, vt, vd)`` from
   :doc:`I01_par_distribute </rst_files/I_Initializer/I01_par_distribute>` —
   this routine fills a 3D grid with uniformly spaced particles and samples
   velocities from a Maxwellian distribution.
   Four aspects are checked:

   - **Particle count**: the number of filled particles equals :math:`\prod(\text{iu}-\text{il}+1)\times\prod\text{nppc}`.
   - **Spatial positions**: every particle coordinate satisfies :math:`x = (i-1) + (i_p + 0.5)/\text{nppc}_x` exactly.
   - **Zero thermal speed**: when ``vt=0`` all particle velocities equal ``vd`` with floating-point exactness (error strictly zero, not just small).
   - **Maxwellian statistics**: for a large sample (N=125000) the mean converges to ``vd`` and the standard deviation to ``vt``, within 5% tolerance.

   .. rubric:: Program Structure

   - ``source_f90/main.f90`` runs the four cases in sequence.
   - ``source_f90/sub_case01_count.f90``: sentinel method — allocates np+1 slots, pre-fills with a sentinel value, calls the routine, then checks the boundary.
   - ``source_f90/sub_case02_positions.f90``: compares each particle coordinate against the analytic formula, tolerance 1e-6.
   - ``source_f90/sub_case03_vt0.f90``: verifies that ``vt=0`` gives velocities exactly equal to ``vd`` (error strictly zero).
   - ``source_f90/sub_case04_maxwellian.f90``: checks mean/std statistics and writes ``case04_maxwellian.dat``.
   - ``source_py/plot_savefig.py`` reads ``build/case04_maxwellian.dat`` and saves a velocity histogram.
   - ``make.sh`` compiles with ``gfortran -cpp -O3 -fdefault-real-8`` (no OpenMP required).

   .. rubric:: Run Command

   .. code-block:: bash

      cd tests/006_initializer/I01_par_distribute
      bash clean.sh && bash make.sh && bash run.sh && bash plot.sh

   ``run.sh`` writes ``case04_maxwellian.dat`` in ``build/``.
   ``plot.sh`` writes ``case04_maxwellian_hist.png`` in ``figs/``.

   .. rubric:: Test Cases

   .. list-table::
      :header-rows: 1
      :widths: 10 38 30 22

      * - Case
        - Setup
        - Check
        - Output
      * - ``01``
        - A: 3×3×3 cells × 2×3×4 ppc = 648; B: 1×1×1 × 1×1×1 = 1; C: 5×4×3 × 3×2×4 = 1440
        - Particle count is exactly ``np``: allocates np+1 slots pre-filled with a very small value; after the call slot np is written and slot np+1 is untouched.
        - Terminal output
      * - ``02``
        - A: single cell il=iu=[2,3,4], nppc=[4,3,2], 24 particles; B: 2×2×2 cells, nppc=[2,2,2], 64 particles
        - Every particle lands at the correct position: loop order (outer k,j,i; inner kp,jp,ip), compared particle-by-particle against the analytic formula, max error < 1e-6.
        - Terminal output
      * - ``03``
        - A: 4×4×4 cells, nppc=[3,3,3], vt=0, vd=(1.5,−2.0,3.7); B: 2×2×2 cells, vt=vd=0
        - Every particle velocity equals ``vd`` exactly, error strictly zero (``0.0 * g = 0.0`` in floating point, not just approximately zero).
        - Terminal output
      * - ``04``
        - 10×10×10 cells, nppc=[5,5,5], N=125000; vt=(1,2,3), vd=(0.5,−1,2)
        - :math:`|\bar{v}_\alpha - v_{d,\alpha}| < 0.05\,v_{t,\alpha}` and :math:`|\sigma_\alpha - v_{t,\alpha}| < 0.05\,v_{t,\alpha}`; 5% tolerance ≈ 17–25 statistical standard errors, essentially never fails randomly.
        - ``case04_maxwellian.dat``

   .. rubric:: Reference Figure

   .. figure:: ../../images/tests/006_initializer/I01_par_distribute/case04_maxwellian_hist.png
      :align: center
      :width: 92%

      Case 04 velocity histograms (N=125000). Each component is overlaid with the
      target Gaussian :math:`\mathcal{N}(v_d, v_t^2)` to verify the Box-Muller sampler.
