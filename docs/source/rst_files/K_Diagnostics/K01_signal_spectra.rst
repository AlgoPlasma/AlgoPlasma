==================
K01_signal_spectra
==================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 适用范围

   K01 提供等间隔采样实数时序的分段 FFT、功率谱、相干度和互相位计算，可用于实验记录或模拟输出。
   两路分析需要采样对齐，并使用相同的分段、窗函数和归一化约定。
   将互相位进一步解释为空间波数时，才需要 :doc:`探针波动诊断专题 <probe_wave_diagnostics>` 中的测量几何与波动模型。

   本单元也包含该探针分析流程采用的具体方法：``pair_power`` 构造 Beall 权重，
   ``phase_mode_statistics`` 用众数格中心估计相位均值，并在移动分支切割线后计算方差。
   复用这些函数时，应按下列说明检查它们的统计定义。

   * :doc:`mod_K01_signal_spectra.py <K01_signal_spectra/mod_K01_signal_spectra>`:

       ``mod_K01_signal_spectra`` 是 K01 的模块入口。它本身不含计算，只汇总并再导出本单元的 routine，方便调用端从一处导入。

       汇总的 routine：

       - ``fun_K01_wrap_to_pi.py``：把角度折算到 :math:`[-\pi,\pi]`。
       - ``fun_K01_segment_ffts.py``：分段、去均值、实数 FFT。
       - ``fun_K01_power_spectrum.py``：单边功率谱密度。
       - ``fun_K01_coherence.py``：幅度平方相干度。
       - ``fun_K01_cross_phase.py``：互相位与互谱幅度。
       - ``fun_K01_pair_power.py``：Beall 谱使用的两路平均自功率权重。
       - ``fun_K01_phase_mode_statistics.py``：相位均值与方差。

   * :doc:`fun_K01_cross_phase.py <K01_signal_spectra/fun_K01_cross_phase>`:

       ``fun_K01_cross_phase`` 定义 K01–K03 探针分析链的相位符号约定。互谱取 :math:`X_1X_2^{*}`，间距取 :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`，平面波给出 :math:`\theta=\mathbf{K}\cdot\boldsymbol{\chi}`（模 :math:`2\pi`）；K02 与 K03 直接沿用，没有额外的符号翻转。

   * :doc:`fun_K01_pair_power.py <K01_signal_spectra/fun_K01_pair_power>`:

       ``fun_K01_pair_power`` 计算每分段的 :math:`(|X_1|^2+|X_2|^2)/2`，作为 K02 Beall 谱的累积权重。
       这是原始 FFT 自功率的平均，不是功率谱密度；两路频谱必须使用相同窗函数与归一化。

   * :doc:`fun_K01_phase_mode_statistics.py <K01_signal_spectra/fun_K01_phase_mode_statistics>`:

       ``fun_K01_phase_mode_statistics`` 把每分段的折叠相位约化为 K03 的似然所需的均值与方差。相位分布可能横跨 :math:`\pm\pi` 的分支切割线，此时算术平均会塌向零，因此先在直方图上定位众数、直接用众数估计均值，并将切割线移到众数对面计算方差。

   * :doc:`fun_K01_segment_ffts.py <K01_signal_spectra/fun_K01_segment_ffts>`:

       ``fun_K01_segment_ffts`` 把原始记录切成不重叠的分段并逐段变换。这是当前接口的分段约定，可避免重复使用同一批采样点；分段是否近似独立仍取决于信号的相关时间，不能仅由“不重叠”保证。

   * :doc:`fun_K01_power_spectrum.py <K01_signal_spectra/fun_K01_power_spectrum>`:

       ``fun_K01_power_spectrum`` 与 ``fun_K01_coherence`` 分别给出分段平均的单边功率谱密度和幅度平方相干度。对两路不相关信号，使用 :math:`n` 个独立分段时，相干度的有限样本平均值约为 :math:`1/n`；单个频点可以低于此值，它不是相干度的下界。

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

   .. rubric:: Scope

   K01 provides segmented FFTs, power spectra, coherence and cross phase for uniformly sampled
   real time series from measurements or simulations. Paired analysis requires aligned samples
   and the same segmentation, window and normalization conventions. Interpreting cross phase
   as a spatial wavenumber additionally requires the measurement geometry and wave model in
   :doc:`Probe Wave Diagnostics <probe_wave_diagnostics>`.

   This unit also includes methods specific to that probe analysis workflow: ``pair_power``
   constructs Beall weights, while ``phase_mode_statistics`` uses a modal-bin centre to estimate
   the phase mean and computes variance after shifting the branch cut. Check the statistical
   definitions below when reusing these functions.

   * :doc:`mod_K01_signal_spectra.py <K01_signal_spectra/mod_K01_signal_spectra>`:

       ``mod_K01_signal_spectra`` is the module entry of K01. It contains no computation; it collects and re-exports the routines of the unit so callers can import them from one place.

       Collected routines:

       - ``fun_K01_wrap_to_pi.py``: wrap angles into :math:`[-\pi,\pi]`.
       - ``fun_K01_segment_ffts.py``: segment, detrend, real FFT.
       - ``fun_K01_power_spectrum.py``: one-sided power spectral density.
       - ``fun_K01_coherence.py``: magnitude-squared coherence.
       - ``fun_K01_cross_phase.py``: cross phase and cross-spectral magnitude.
       - ``fun_K01_pair_power.py``: mean pair auto-power weights for the Beall spectrum.
       - ``fun_K01_phase_mode_statistics.py``: phase mean and variance.

   * :doc:`fun_K01_cross_phase.py <K01_signal_spectra/fun_K01_cross_phase>`:

       ``fun_K01_cross_phase`` defines the phase sign convention of the K01–K03 probe analysis chain. The cross spectrum is :math:`X_1X_2^{*}` with the separation :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`, so a plane wave gives :math:`\theta=\mathbf{K}\cdot\boldsymbol{\chi}` (modulo :math:`2\pi`); K02 and K03 use it directly, with no additional sign flip.

   * :doc:`fun_K01_pair_power.py <K01_signal_spectra/fun_K01_pair_power>`:

       ``fun_K01_pair_power`` computes :math:`(|X_1|^2+|X_2|^2)/2` per segment as the accumulation
       weight for the K02 Beall spectrum. This is mean raw FFT auto-power, not a power spectral
       density; both spectra must use the same window and normalization.

   * :doc:`fun_K01_phase_mode_statistics.py <K01_signal_spectra/fun_K01_phase_mode_statistics>`:

       ``fun_K01_phase_mode_statistics`` reduces the per-segment wrapped phases to the mean and variance the K03 likelihood needs. The distribution can straddle the :math:`\pm\pi` branch cut, where an arithmetic mean collapses towards zero, so the histogram mode estimates the mean directly; shifted samples give the variance.

   * :doc:`fun_K01_segment_ffts.py <K01_signal_spectra/fun_K01_segment_ffts>`:

       ``fun_K01_segment_ffts`` splits a raw record into non-overlapping segments and transforms each. This is the current interface convention and avoids reusing the same samples. Whether segments are approximately independent still depends on the signal's correlation time; non-overlap alone does not guarantee independence.

   * :doc:`fun_K01_power_spectrum.py <K01_signal_spectra/fun_K01_power_spectrum>`:

       ``fun_K01_power_spectrum`` and ``fun_K01_coherence`` return the segment-averaged one-sided power spectral density and magnitude-squared coherence, respectively. For two uncorrelated signals and :math:`n` independent segments, the finite-sample mean coherence is approximately :math:`1/n`; individual frequency bins can fall below this reference, which is not a lower bound.

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
