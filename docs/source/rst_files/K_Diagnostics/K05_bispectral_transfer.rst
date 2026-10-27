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

      Follow the main text first; open the calculation notes when needed.

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

      可以先顺着正文读，需要时再展开计算细节。

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
