Knowledge Notes
===============

.. toctree::
   :maxdepth: 1
   :hidden:

   fft
   spectral_leakage
   compact_phase

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 知识点：跨模块的基础解释

   这里集中解释多个算法都可能用到的知识，不要求先读某个模块。
   从算法页遇到概念时可以跳来补充，再通过页内链接返回原来的章节继续读。

   - :doc:`FFT、频点与 Nyquist 频率 <fft>`：从时域波形、频谱和复平面图理解
     FFT 输出的振幅与相位，以及采样的频率限制。
   - :doc:`谱泄漏与窗函数 <spectral_leakage>`：用周期拼接图和频谱比较图理解
     “不在频点上”的单频信号为什么会出现在很多频点中。
   - :doc:`窄带相位的省点计算 <compact_phase>`：把频带搬到低频，用较少时刻计算慢相位，
     再还原到原采样点；配有移频图、误差图和 Python 示例。

   应用入口：:doc:`探针诊断基础 </rst_files/K_Diagnostics/diagnostics_foundations>`。

.. container:: ap-lang ap-lang-en

   .. rubric:: Knowledge notes: foundations shared by algorithm modules

   These notes explain concepts used across algorithms without requiring a particular module.
   Follow a concept link from an algorithm page, then use the return link to resume its section.

   - :doc:`FFT, frequency bins, and the Nyquist frequency <fft>`: connect time traces,
     spectra, and complex-plane diagrams to amplitude, phase, and sampling limits.
   - :doc:`Spectral leakage and windows <spectral_leakage>`: use repeated-record and
     spectrum plots to see why an off-bin tone contributes to multiple bins.
   - :doc:`Fewer-point evaluation of narrowband phase <compact_phase>`: shift a band
     to low frequencies, evaluate slow phase on fewer time points, and restore the original
     sampling grid, with frequency-shift plots, error plots, and Python examples.

   Application: :doc:`Probe Diagnostics Foundations </rst_files/K_Diagnostics/diagnostics_foundations>`.
