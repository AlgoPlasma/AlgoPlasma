fun_K03_search_wavevector.py
==============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 网格搜索

   在给定的二维波数范围内建立均匀网格，计算各网格点的联合对数似然，
   取最大值对应的波矢作为估计结果。计算按行分批进行，各批次使用同一个网格步长。

   .. rubric:: 参数

   调用：``fun_K03_search_wavevector(configurations, k_range_rad_m, n_grid=1501, block_rows=32)``。

   - ``configurations``：每项为 (chi, delta_theta, variance)，分别为基线向量、相位均值和方差，单位 m、rad、rad²。
   - ``k_range_rad_m``：两个坐标轴的搜索半宽，取有限正数。
   - ``n_grid``：每轴点数，至少 2；步长为 2*k_range_rad_m/(n_grid-1)。
   - ``block_rows``：每批计算的网格行数，默认 32，控制临时数组的内存。

   .. rubric:: 返回值与输入条件

   返回字典含 ``kx, ky, k_magnitude, angle_deg, peak_log_likelihood``，
   以及 ``grid_step, n_grid, boundary, valid_configurations, tied_grid_points``。
   相等最大值按先 y 后 x 的扫描顺序取第一个；tied_grid_points 记录达到该最大值的网格点数。
   peak_log_likelihood 为直接累加的对数似然值。

   非有限相位、非有限或非正方差的构型被剔除。其余构型应至少含两条线性独立基线，
   以约束两个波矢分量；有效约束不足或似然完全平坦时抛 ValueError。

   .. rubric:: 网格设置

   搜索范围根据目标波长和传播方向选取。固定范围后，可逐步增加 n_grid，
   比较估计波矢的变化，确定所需的数值分辨率。边界峰可通过扩大范围进一步检查。
   多个相位条纹交点形成的候选波矢，见 :doc:`诊断基础 <../diagnostics_foundations>` 第 7 节。

   贡献者：彭子龙 (2026/09/02) · Harbin Institute of Technology

.. container:: ap-lang ap-lang-en

   .. rubric:: Grid search

   Build a uniform grid over the chosen two-dimensional wavenumber range, evaluate the joint
   log likelihood at every point, and report the wavevector at its maximum.
   Rows are evaluated in batches with a common grid spacing.

   .. rubric:: Parameters

   Call: ``fun_K03_search_wavevector(configurations, k_range_rad_m, n_grid=1501, block_rows=32)``.

   - ``configurations``: triples (chi, delta_theta, variance): baseline vector, phase mean and variance, in m, rad and rad².
   - ``k_range_rad_m``: finite positive half-width of both coordinate axes.
   - ``n_grid``: at least two points per axis; spacing = 2*k_range_rad_m/(n_grid-1).
   - ``block_rows``: rows per batch (default 32), controlling temporary-array memory.

   .. rubric:: Returns and input conditions

   The dictionary contains ``kx, ky, k_magnitude, angle_deg, peak_log_likelihood``,
   plus ``grid_step, n_grid, boundary, valid_configurations, tied_grid_points``.
   Exact ties select the first point in y-then-x order; tied_grid_points counts grid points
   at that maximum. peak_log_likelihood is the directly summed log likelihood.

   Configurations with nonfinite phases or nonfinite/nonpositive variances are omitted.
   At least two independent valid baselines are required to constrain both components.
   Insufficient constraints or a flat likelihood raises ValueError.

   .. rubric:: Choosing the grid

   Choose the range for the wavelengths and propagation directions of interest. At fixed range,
   increase n_grid and compare wavevector estimates to assess numerical resolution.
   Expand the range to inspect boundary peaks. Section 7 of
   :doc:`the foundations <../diagnostics_foundations>` explains candidates at phase-fringe intersections.

   Contributor: Zilong PENG (2026/09/02) · Harbin Institute of Technology
