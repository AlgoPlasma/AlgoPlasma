----------------------
fun_K01_cross_phase.py
----------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   给出一对探针每个分段的互相位与互谱幅度。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 14 10 28 34 26 40

      * - 参数
        - 方向
        - shape / 范围
        - 含义
        - 单位 / 归一化
        - 索引 / 轴约定
      * - ``ffts_1``
        - ``in``
        - ``(nseg, nfreq)`` 复数
        - 探针 1 的分段谱。
        - 调用者归一化下的信号单位
        - 轴 0 为分段，轴 1 为频点。
      * - ``ffts_2``
        - ``in``
        - ``(nseg, nfreq)`` 复数
        - 探针 2 的分段谱；探针 2 是沿 :math:`+\boldsymbol{\chi}` 位移的那一路。
        - 调用者归一化下的信号单位
        - 与 ``ffts_1`` 逐元素对应。

   .. rubric:: 返回值

   两个 ``numpy.ndarray``，均为 ``(nseg, nfreq)``：互相位 :math:`\arg(X_1X_2^{*})` 与互谱幅度 :math:`|X_1X_2^{*}|`。互谱为零时辐角无定义，函数以 NaN 表示该相位；非有限互谱采用相同标记。Beall 累积所需的两路自功率平均由 fun_K01_pair_power 提供。

   .. rubric:: 局部假设 / 前置条件

   - 互谱定义为 :math:`X_1 X_2^{*}`，间距为 :math:`\boldsymbol{\chi} = \mathbf{r}_2 - \mathbf{r}_1`。
   - 配合 ``numpy.fft.rfft`` 的 :math:`\exp(-i\omega t)` 正变换，平面波给出 :math:`\theta = \mathbf{K}\cdot\boldsymbol{\chi}`。K02 与 K03 直接沿用，全模块没有符号翻转。
   - 交换探针顺序会让 :math:`\theta` 反号并镜像所有反演结果。

   .. rubric:: 实现逻辑

   - 相位由 ``numpy.angle`` 给出，因此落在 :math:`(-\pi, \pi]`。

   .. rubric:: 调用注意

   - 两路探针必须来自同一批分段，否则相位差里会混入分段间的随机相位。

   .. rubric:: 算法说明

   .. math::

      \theta(f) = \arg\left[X_1(f)X_2^{*}(f)\right]
      = \mathbf{K}\cdot\boldsymbol{\chi} \pmod{2\pi}

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Return the per-segment cross phase and cross-spectral magnitude of a probe pair.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 14 10 28 34 26 40

      * - Parameter
        - Direction
        - Shape / range
        - Meaning
        - Units / normalisation
        - Indexing / axis convention
      * - ``ffts_1``
        - ``in``
        - ``(nseg, nfreq)`` complex
        - Segment spectra of probe 1.
        - Signal units under the caller's normalisation
        - Axis 0 is the segment, axis 1 the frequency bin.
      * - ``ffts_2``
        - ``in``
        - ``(nseg, nfreq)`` complex
        - Segment spectra of probe 2, the one displaced by :math:`+\boldsymbol{\chi}`.
        - Signal units under the caller's normalisation
        - Element-wise counterpart of ``ffts_1``.

   .. rubric:: Return Value

   Two ``numpy.ndarray`` of shape ``(nseg, nfreq)``: the cross phase :math:`\arg(X_1X_2^{*})` and the magnitude :math:`|X_1X_2^{*}|`. A zero cross spectrum has an undefined argument, represented by NaN; nonfinite cross spectra receive the same marker. fun_K01_pair_power supplies the mean pair auto-power for Beall accumulation.

   .. rubric:: Local Assumptions and Preconditions

   - The cross spectrum is :math:`X_1 X_2^{*}` with the separation :math:`\boldsymbol{\chi} = \mathbf{r}_2 - \mathbf{r}_1`.
   - With the :math:`\exp(-i\omega t)` forward transform of ``numpy.fft.rfft``, a plane wave gives :math:`\theta = \mathbf{K}\cdot\boldsymbol{\chi}`. K02 and K03 use it directly, with no sign flip anywhere in the module.
   - Reversing the probe order negates :math:`\theta` and mirrors every recovered result.

   .. rubric:: Implementation Notes

   - The phase comes from ``numpy.angle``, so it lies in :math:`(-\pi, \pi]`.

   .. rubric:: Calling Notes

   - Both probes must come from the same batch of segments, or the per-segment random phase leaks into the difference.

   .. rubric:: Algorithm Notes

   .. math::

      \theta(f) = \arg\left[X_1(f)X_2^{*}(f)\right]
      = \mathbf{K}\cdot\boldsymbol{\chi} \pmod{2\pi}

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
