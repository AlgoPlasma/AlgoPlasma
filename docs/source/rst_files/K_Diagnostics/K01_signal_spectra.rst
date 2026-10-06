==================
K01_signal_spectra
==================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   * :doc:`mod_K01_signal_spectra.py <K01_signal_spectra/mod_K01_signal_spectra>`:

       ``mod_K01_signal_spectra`` 是 K01 的模块入口。它本身不含计算，只汇总并再导出本单元的 routine，方便调用端从一处导入。

       汇总的 routine：

       - ``fun_K01_wrap_to_pi.py``：把角度折算到 :math:`[-\pi,\pi]`。
       - ``fun_K01_segment_ffts.py``：分段、去均值、实数 FFT。
       - ``fun_K01_power_spectrum.py``：单边功率谱密度。
       - ``fun_K01_coherence.py``：幅度平方相干度。
       - ``fun_K01_cross_phase.py``：互相位与互谱幅度。
       - ``fun_K01_phase_mode_statistics.py``：相位均值与方差。

   * :doc:`fun_K01_cross_phase.py <K01_signal_spectra/fun_K01_cross_phase>`:

       ``fun_K01_cross_phase`` 是本单元的核心：它定义了整个模块族的相位符号约定。互谱取 :math:`X_1X_2^{*}`，间距取 :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`，平面波给出 :math:`\theta=\mathbf{K}\cdot\boldsymbol{\chi}`；K02 与 K03 直接沿用，全模块没有符号翻转。

   * :doc:`fun_K01_phase_mode_statistics.py <K01_signal_spectra/fun_K01_phase_mode_statistics>`:

       ``fun_K01_phase_mode_statistics`` 把每分段的折叠相位约化为 K03 的似然所需的均值与方差。相位分布可能横跨 :math:`\pm\pi` 的分支切割线，此时算术平均会塌向零，因此先在直方图上定位众数、直接用众数估计均值，并将切割线移到众数对面计算方差。

   * :doc:`fun_K01_segment_ffts.py <K01_signal_spectra/fun_K01_segment_ffts>`:

       ``fun_K01_segment_ffts`` 把原始记录切成不重叠的分段并逐段变换。分段不重叠是硬约定：重叠会使相位样本相关，而 K03 的似然权重假定样本独立。

   * :doc:`fun_K01_power_spectrum.py <K01_signal_spectra/fun_K01_power_spectrum>`:

       ``fun_K01_power_spectrum`` 与 ``fun_K01_coherence`` 给出信号的整体形态：前者是分段平均的单边功率谱密度，后者是幅度平方相干度，其底为 :math:`1/n` 而不是零。

   * :doc:`fun_K01_coherence.py <K01_signal_spectra/fun_K01_coherence>`:

       见上一条；两者共用同一批分段谱，通常一起用于判断哪些频点值得进入后续反演。

   * :doc:`fun_K01_wrap_to_pi.py <K01_signal_spectra/fun_K01_wrap_to_pi>`:

       ``fun_K01_wrap_to_pi`` 是本单元最基础的 routine，K02 与 K03 都直接调用它折算相位与残差。

   .. rubric:: 测试

   相关测试说明见 :doc:`010_diagnostics 测试 </tests/010_diagnostics/index>`。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>


.. container:: ap-lang ap-lang-en

   * :doc:`mod_K01_signal_spectra.py <K01_signal_spectra/mod_K01_signal_spectra>`:

       ``mod_K01_signal_spectra`` is the module entry of K01. It contains no computation; it collects and re-exports the routines of the unit so callers can import them from one place.

       Collected routines:

       - ``fun_K01_wrap_to_pi.py``: wrap angles into :math:`[-\pi,\pi]`.
       - ``fun_K01_segment_ffts.py``: segment, detrend, real FFT.
       - ``fun_K01_power_spectrum.py``: one-sided power spectral density.
       - ``fun_K01_coherence.py``: magnitude-squared coherence.
       - ``fun_K01_cross_phase.py``: cross phase and cross-spectral magnitude.
       - ``fun_K01_phase_mode_statistics.py``: phase mean and variance.

   * :doc:`fun_K01_cross_phase.py <K01_signal_spectra/fun_K01_cross_phase>`:

       ``fun_K01_cross_phase`` is the core of the unit: it defines the phase sign convention of the whole module family. The cross spectrum is :math:`X_1X_2^{*}` with the separation :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`, so a plane wave gives :math:`\theta=\mathbf{K}\cdot\boldsymbol{\chi}`; K02 and K03 use it directly, with no sign flip anywhere.

   * :doc:`fun_K01_phase_mode_statistics.py <K01_signal_spectra/fun_K01_phase_mode_statistics>`:

       ``fun_K01_phase_mode_statistics`` reduces the per-segment wrapped phases to the mean and variance the K03 likelihood needs. The distribution can straddle the :math:`\pm\pi` branch cut, where an arithmetic mean collapses towards zero, so the histogram mode estimates the mean directly; shifted samples give the variance.

   * :doc:`fun_K01_segment_ffts.py <K01_signal_spectra/fun_K01_segment_ffts>`:

       ``fun_K01_segment_ffts`` splits a raw record into non-overlapping segments and transforms each. The non-overlap is a hard convention: overlapping correlates the phase samples, whereas the K03 likelihood weights assume independence.

   * :doc:`fun_K01_power_spectrum.py <K01_signal_spectra/fun_K01_power_spectrum>`:

       ``fun_K01_power_spectrum`` and ``fun_K01_coherence`` describe the overall shape of the signal: the segment-averaged one-sided power spectral density, and the magnitude-squared coherence whose floor is :math:`1/n` rather than zero.

   * :doc:`fun_K01_coherence.py <K01_signal_spectra/fun_K01_coherence>`:

       See the entry above; both consume the same segment spectra and are normally used together to decide which bins are worth carrying into the inversion.

   * :doc:`fun_K01_wrap_to_pi.py <K01_signal_spectra/fun_K01_wrap_to_pi>`:

       ``fun_K01_wrap_to_pi`` is the most basic routine of the unit; K02 and K03 both call it directly to fold phases and residuals.

   .. rubric:: Tests

   See :doc:`010_diagnostics tests </tests/010_diagnostics/index>` for the reference case and figures.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>


.. toctree::
    :maxdepth: 1
    :hidden:

    K01_signal_spectra/mod_K01_signal_spectra
    K01_signal_spectra/fun_K01_cross_phase
    K01_signal_spectra/fun_K01_pair_power
    K01_signal_spectra/fun_K01_phase_mode_statistics
    K01_signal_spectra/fun_K01_segment_ffts
    K01_signal_spectra/fun_K01_power_spectrum
    K01_signal_spectra/fun_K01_coherence
    K01_signal_spectra/fun_K01_wrap_to_pi
