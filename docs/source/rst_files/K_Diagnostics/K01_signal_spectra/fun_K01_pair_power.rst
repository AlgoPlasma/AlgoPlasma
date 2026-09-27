fun_K01_pair_power.py
=======================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 两路自功率平均

   对每段、每频点计算 ``(abs(X1)**2 + abs(X2)**2)/2``，作为 Beall 直方图的累积权重，
   对应 Liu 2025 式 (2)。该权重汇总两路探针在此频点的功率。

   调用 ``fun_K01_pair_power(ffts_1, ffts_2)``。两路数组 shape 相同，
   使用相同窗口和 FFT 归一化。返回原始 FFT 功率单位的同形数组。
   K02 将有效互相位换算为波数，并把对应权重累加到波数格中。
   PSD 每 Hz 归一化由 power_spectrum 单独提供。

.. container:: ap-lang ap-lang-en

   .. rubric:: Mean pair auto-power

   Compute ``(abs(X1)**2 + abs(X2)**2)/2`` per segment and frequency as the Beall histogram
   weight, following Liu 2025 Eq. (2). The weight combines the two probes' powers at that frequency.

   Call ``fun_K01_pair_power(ffts_1, ffts_2)`` with equal-shaped arrays using a common window
   and FFT normalization. Returns an array of the same shape in raw FFT power units.
   K02 converts valid cross phases to wavenumbers and accumulates these weights in their bins.
   power_spectrum separately supplies PSD normalization per Hz.
