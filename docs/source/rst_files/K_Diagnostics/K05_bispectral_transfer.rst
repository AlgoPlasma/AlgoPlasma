K05 · Bispectral transfer
=========================

.. raw:: html

   <link rel="stylesheet" href="../../_static/K_Diagnostics/k05-wave-packet.css">
   <script defer src="../../_static/K_Diagnostics/k05-legacy-links.js"></script>
   <div class="ap-language-switch" role="group" aria-label="Language switch" data-ap-default-lang="en">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. |ref-en| raw:: html

   <a class="k05-cite" href="#k05-index-reference-1-en" aria-label="Reference 1">[1]</a>

.. |ref-zh| raw:: html

   <a class="k05-cite" href="#k05-index-reference-1-zh" aria-label="参考文献 1">[1]</a>

.. container:: ap-lang ap-lang-en k05-lesson

   .. container:: k05-text

      .. rubric:: What K05 is for

      Which waves grow, and how do waves exchange energy? K05 follows Brown and
      Jorns |ref-en| from the wave equation to probe signals and their analysis.
      The aim is to connect the theory to calculations of growth and transfer
      from measured records.

   .. container:: k05-text

      .. rubric:: Read in this order

      1. :ref:`Wave growth and coupling <k05-wave-overview-en>` — start with a
         moving wave and build the structure of the wave-evolution equation.
      2. :ref:`Where the envelope equation comes from <k05-coefficients-en>` —
         connect the plasma response to group velocity, growth and coupling.
      3. :ref:`From waves to probe records <k05-probe-signals-en>` — describe a
         fixed probe's signal with Fourier coefficients, then compare two probes.
      4. :ref:`From records to spectral statistics <k05-statistics-en>` — average
         repeated records to obtain power, cross power and three-frequency phase relations.

      5. :ref:`From statistics to growth and coupling <k05-inference-en>` — estimate
         linear and quadratic coefficients, then connect them to growth and transfer.

      6. :ref:`From probe records to spectral statistics <k05-experiment-en>` —
         inspect four synchronized captures, build spectra and compare phase relations.

      7. :ref:`From measured statistics to linear and quadratic coefficients <k05-experiment-coefficients-en>` —
         build the actual moment matrix, fit L/Q and check the Kim result.

      8. :ref:`From fitted coefficients to growth and transfer <k05-rates-en>` —
         calculate the measured power balance and signed pair contributions,
         then introduce a group-velocity scenario to obtain conditional rates.

      9. :ref:`Supplement: what the probe measures <k05-response-en>` — rebuild I–V curves,
         estimate temperature and inspect bias and electrical-response scenarios.

      10. :ref:`Experimental counterparts of Figures 2 and 3 <k05-comparison-en>` —
          see the measured spectra, coupling map and conditional growth/transfer plots,
          then follow their calculation.

      11. :ref:`Supplement: interpreting the plots <k05-budget-en>` — explain the
          common-power check, reference phase and complete measured-power balance.

      12. :ref:`Read the paper from equations to conclusions <k05-synthesis-en>` —
          use independent schematics to connect drive, redistribution and saturation,
          and distinguish source conclusions from the C1/C3 example.

      13. :ref:`Supplement: validating the two-probe model <k05-validation-en>` —
          inspect complete holdouts, residuals, sensitivity and the higher-frequency example.

      Follow the main text first; open the calculation notes when needed.

   .. raw:: html

      <details class="k05-note"><summary>Find a reference equation</summary>

   Each comparison box puts the K05 equation above the original equation,
   then explains the symbol and normalization differences.

   - :ref:`[1], Eq. (1): Full wave evolution <k05-source-1-en>`
   - :ref:`[1], Eq. (2): Time-Fourier equation <k05-source-2-en>`
   - :ref:`[1], Eq. (3): Two-probe model <k05-source-3-en>`
   - :ref:`[1], Eq. (4): Coefficients, phase and rates <k05-source-4-en>`
   - :ref:`[1], Eq. (5): Measured moment equations <k05-source-5-en>`
   - :ref:`[1], Eq. (6): Signed transfer <k05-source-6-en>`
   - :ref:`[1], Eq. (7): Kinetic dispersion <k05-source-7-en>`

   .. raw:: html

      </details>

   .. rubric:: Contributor

   Yinjian Zhao — Harbin Institute of Technology.

   .. rubric:: Reference

   .. _k05-index-reference-1-en:

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
   115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

.. container:: ap-lang ap-lang-zh k05-lesson

   .. container:: k05-text

      .. rubric:: K05 要做什么

      哪些波正在增长？波与波之间怎样交换能量？K05 以 Brown 与 Jorns 的研究 |ref-zh|
      为线索，从波动方程走到探针信号及其分析，把理论与测量记录中的增长率（growth rate）
      和波间转移（wave-to-wave transfer）计算连接起来。

   .. container:: k05-text

      .. rubric:: 按这个顺序阅读

      1. :ref:`波增长与耦合 <k05-wave-overview-zh>` —— 从一列移动的波出发，建立描述波如何变化的方程。
      2. :ref:`包络方程和系数从哪里来 <k05-coefficients-zh>` —— 从等离子体响应得到群速度、增长率和耦合系数。
      3. :ref:`从移动的波到探针记录 <k05-probe-signals-zh>` —— 用傅里叶系数描述固定探针信号，再比较两支探针。
      4. :ref:`从重复记录到功率谱、互谱与双谱 <k05-statistics-zh>` —— 对多段记录取平均，提取强度及相位关联。

      5. :ref:`从统计量估计增长与耦合 <k05-inference-zh>` —— 联合估计线性与二次系数，再连接增长率和转移率。

      6. :ref:`从探针记录算出谱统计量 <k05-experiment-zh>` —— 用同一套分段，从波形得到复系数、功率、互谱与复双谱。

      7. :ref:`从实测统计量求线性与二次系数 <k05-experiment-coefficients-zh>` ——
         展开真实矩阵，求 L/Q，再计算和检查 Kim 结果。

      8. :ref:`从拟合系数走到增长与转移 <k05-rates-zh>` ——
         先算实测功率收支与有符号波对贡献，再用群速度情景换算条件变化率。

      9. :ref:`补充：探针实际测到了什么 <k05-response-zh>` —— 重建 I–V 曲线、估计温度，
         并检查工作偏置和电路响应情景。

      10. :ref:`把实验数据画成文献图 2、图 3 的形式 <k05-comparison-zh>` ——
          先看频谱、耦合系数和条件增长／转移曲线，再说明怎样计算。

      11. :ref:`补充：怎样解释增长与转移图 <k05-budget-zh>` ——
          展开共同功率检查、参考相位与完整实测功率收支。

      12. :ref:`从方程读到论文结论 <k05-synthesis-zh>` ——
          用独立示意图串起驱动、转移和饱和，区分原文结论与 C1/C3 示例。

      13. :ref:`补充：双探针模型验证 <k05-validation-zh>` ——
          检查完整留出结果、残差、设置敏感性与更高频率的预测。

      可以先顺着正文读，需要时再展开计算细节。

   .. raw:: html

      <details class="k05-note"><summary>按文献公式查找对应页面</summary>

   每个对照框先放 K05 方程，再列文献原式，随后说明符号、归一化或模型简化的差别。

   - :ref:`[1] 式 (1)：完整波动演化 <k05-source-1-zh>`
   - :ref:`[1] 式 (2)：时间 Fourier 方程 <k05-source-2-zh>`
   - :ref:`[1] 式 (3)：双探针模型 <k05-source-3-zh>`
   - :ref:`[1] 式 (4)：系数、相位与变化率 <k05-source-4-zh>`
   - :ref:`[1] 式 (5)：实测统计矩方程 <k05-source-5-zh>`
   - :ref:`[1] 式 (6)：有符号转移 <k05-source-6-zh>`
   - :ref:`[1] 式 (7)：动理学色散 <k05-source-7-zh>`

   .. raw:: html

      </details>

   .. rubric:: 贡献者

   赵隐剑（Yinjian Zhao）—— 哈尔滨工业大学。

   .. rubric:: 参考文献

   .. _k05-index-reference-1-zh:

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
   115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_。

.. toctree::
   :hidden:
   :maxdepth: 1

   K05_wave_growth
   K05_envelope_coefficients
   K05_probe_signals
   K05_spectral_statistics
   K05_coefficient_inference
   K05_experimental_signals
   K05_experimental_coefficients
   K05_growth_transfer
   K05_probe_response
   K05_paper_comparison
   K05_power_budget
   K05_paper_synthesis
   K05_model_validation
