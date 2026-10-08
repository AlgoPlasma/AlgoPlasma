fun_K01_phase_mode_statistics.py
==================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 相位分布的均值与方差

   多段互相位形成相位分布。依据 Liu and Jorns, AIAA-2025-1293, II.E，
   函数以最高直方图格的中心估计相位均值。随后将各样本相对于该中心的偏差折算到主值区间，
   计算分段相位的散布。这样可以把跨越 ±π 的同一相位簇放在一起处理。

   .. code-block:: python

      theta_bar = theta_mode
      sigma2 = var(wrap(theta - theta_mode), ddof=1) + 1e-12

   这里采用样本方差分母 M-1（ddof=1）；Liu 原文未指定分母。
   小正数 1e-12 用于有效无噪声样本的数值正则化。

   .. rubric:: 参数与返回值

   调用：``fun_K01_phase_mode_statistics(phase, nbins=60)``。

   - phase 是 (nseg,) 或 (nseg, nfreq) 的弧度相位。
   - nbins 为相位直方图格数，至少 2，默认 60。
   - 返回均值估计和单样本方差；一维输入返回标量，二维输入返回 (nfreq,) 数组。
   - 非有限样本按频点剔除；有效样本少于两个时返回 NaN。输入总段数少于 2 时抛 ValueError。

   互谱为零时相位无定义，由 cross_phase 用 NaN 标记，随后作为缺失样本处理。
   直方图峰并列时选择第一个格。

   .. rubric:: 分箱与样本数

   格宽决定众数估计的角度分辨率，分段数影响各格的计数稳定性。
   可比较不同分箱和分段数下的结果，观察峰的位置及相位分布形状。
   返回方差描述各段相位的散布；众数位置的估计误差还取决于样本数与分布。
   多峰分布适合结合直方图进一步分析各相位簇。

   贡献者：彭子龙 (2026/09/02) · Harbin Institute of Technology

.. container:: ap-lang ap-lang-en

   .. rubric:: Mean and variance of a phase distribution

   Segment cross phases form a phase distribution. Following Liu and Jorns, AIAA-2025-1293,
   II.E, the centre of its most populated histogram bin estimates the mean. Samples are
   shifted relative to that centre and wrapped before their variance is calculated.
   This groups a phase cluster spanning the ±pi cut into one neighborhood.

   .. code-block:: python

      theta_bar = theta_mode
      sigma2 = var(wrap(theta - theta_mode), ddof=1) + 1e-12

   This implementation uses the sample-variance denominator M-1 (ddof=1); Liu does not specify
   the denominator. The 1e-12 floor regularizes valid noiseless samples.

   .. rubric:: Parameters and returns

   Call: ``fun_K01_phase_mode_statistics(phase, nbins=60)``.

   - phase has shape (nseg,) or (nseg, nfreq), in radians.
   - nbins sets the phase histogram bin count: at least 2, default 60.
   - Returns mean estimate and individual-sample variance: scalars for 1D input or (nfreq,) arrays.
   - Nonfinite samples are omitted per frequency. Fewer than two valid samples returns NaN;
     fewer than two input segments raises ValueError.

   A zero cross spectrum has undefined phase, marked NaN by cross_phase and treated as missing.
   Exact histogram ties select the first bin.

   .. rubric:: Binning and sample count

   Bin width sets the angular resolution of the mode estimate; segment count affects histogram
   stability. Compare binning and sample counts to inspect the peak location and distribution.
   The returned variance describes segment-phase scatter. Uncertainty of the mode location also
   depends on sample count and distribution. Inspect multiple phase clusters with the histogram.

   Contributor: Zilong PENG (2026/09/02) · Harbin Institute of Technology
