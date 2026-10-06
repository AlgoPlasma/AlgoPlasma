--------------------
fun_K01_coherence.py
--------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   给出一对探针的幅度平方相干度。

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
        - 探针 2 的分段谱，shape 必须相同。
        - 调用者归一化下的信号单位
        - 与 ``ffts_1`` 逐元素对应。

   .. rubric:: 返回值

   ``numpy.ndarray``，shape ``(nfreq,)``，取值 :math:`[0, 1]`。

   .. rubric:: 局部假设 / 前置条件

   - :math:`n` 个独立分段下，不相关信号的相干度平均到 :math:`1/n` 而不是 0。判断空频带时应以 :math:`1/n` 为参照。
   - 分段之间必须互相独立，否则该底会被低估。

   .. rubric:: 实现逻辑

   - 分段平均的互谱模平方除以两路自谱之积，并钳到 :math:`[0, 1]`。
   - 分母加 :math:`10^{-300}` 以避免全零频点除零。

   .. rubric:: 调用注意

   - 谱沉入噪声底的频段上相干度不携带信息，判据应只在高出底的频点上评估。

   .. rubric:: 算法说明

   .. math::

      \gamma^2(f) = \frac{\left|\langle X_1 X_2^{*}\rangle\right|^2}
      {\langle |X_1|^2\rangle\,\langle |X_2|^2\rangle}

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Return the magnitude-squared coherence of a probe pair.

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
        - Segment spectra of probe 2; the shape must match.
        - Signal units under the caller's normalisation
        - Element-wise counterpart of ``ffts_1``.

   .. rubric:: Return Value

   ``numpy.ndarray``, shape ``(nfreq,)``, in :math:`[0, 1]`.

   .. rubric:: Local Assumptions and Preconditions

   - With :math:`n` independent segments, uncorrelated signals average to :math:`1/n` rather than to zero. That floor is the reference for judging an empty band.
   - The segments must be mutually independent, or the floor is underestimated.

   .. rubric:: Implementation Notes

   - The squared modulus of the segment-averaged cross spectrum divided by the product of the auto spectra, clipped to :math:`[0, 1]`.
   - A :math:`10^{-300}` term guards the denominator against an all-zero bin.

   .. rubric:: Calling Notes

   - Where the spectrum has sunk into the noise floor the coherence carries no information, so criteria should be evaluated only on bins that stand clear of it.

   .. rubric:: Algorithm Notes

   .. math::

      \gamma^2(f) = \frac{\left|\langle X_1 X_2^{*}\rangle\right|^2}
      {\langle |X_1|^2\rangle\,\langle |X_2|^2\rangle}

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
