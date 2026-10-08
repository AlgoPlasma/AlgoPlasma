-------------------------
fun_K02_beall_spectrum.py
-------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   无效相位、非有限或非正权重不累积；仍除以输入总段数。不自动作 PSD 归一化。

   .. rubric:: 直接用途

   累积 Beall 统计色散谱 :math:`S(k,f)`。

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
      * - ``phase``
        - ``in``
        - ``(nseg, nfreq)``
        - 互相位。
        - 弧度
        - 轴 0 为分段，轴 1 为频点。
      * - ``magnitude``
        - ``in``
        - ``(nseg, nfreq)``
        - 两路自功率平均 ``(|X1|²+|X2|²)/2``，用作累积权重，由 fun_K01_pair_power 计算。
        - 调用者归一化下的信号单位平方
        - 与 ``phase`` 逐元素对应。
      * - ``frequencies_hz``
        - ``in``
        - ``(nfreq,)``
        - 各频点的中心频率。
        - Hz
        - 与 ``phase`` 的轴 1 一一对应。
      * - ``chi``
        - ``in``
        - ``(2,)``
        - 间距向量 :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`。
        - 米
        - 分量顺序为 :math:`(\chi_x,\chi_y)`，与波矢同一直角坐标系。
      * - ``k_edges``
        - ``in``
        - ``(nk+1,)``
        - 波数直方图边界。
        - rad/m
        - 单调递增。
      * - ``f_edges``
        - ``in``
        - ``(nf+1,)``
        - 频率直方图边界。
        - Hz
        - 单调递增。

   .. rubric:: 返回值

   ``dict``，含 ``spectrum`` ``(nf, nk)``、``k_centers``、``f_centers``、``k_nyquist`` 和 ``segments``。

   .. rubric:: 局部假设 / 前置条件

   - 这是一个**统计**估计器，需要的分段数远多于求一个均值相位所需。
   - 分段数远少于波数格数时，谱峰只是最强的单个样本而不是有意义的峰。

   .. rubric:: 实现逻辑

   - 每个 (分段, 频点) 样本按 :math:`(|X_1|^2+|X_2|^2)/2` 加权投进 :math:`\mathrm{wrap}(\theta)/|\boldsymbol{\chi}|` 所在的唯一一个波数格，最后除以分段数。
   - 不相干的分段沿波数轴散开，相干的堆叠——这就是该估计器"统计"二字的含义。

   .. rubric:: 调用注意

   - 参考：J. M. Beall, Y. C. Kim, E. J. Powers, J. Appl. Phys. **53**\ (6), 3933–3940 (1982)。

   .. rubric:: 算法说明

   .. math::

      S(k, f) = \frac{1}{N_{\rm seg}}\sum_{s}
      \frac{|X_{1,s}|^2+|X_{2,s}|^2}{2}\,
      \delta\!\left[k - \frac{\mathrm{wrap}(\theta_s)}{|\boldsymbol{\chi}|}\right]

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   Invalid phases and nonfinite/nonpositive weights are omitted; division remains by total input segments, not valid count. No PSD normalization is applied.

   .. rubric:: Direct Purpose

   Accumulate the Beall statistical dispersion spectrum :math:`S(k,f)`.

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
      * - ``phase``
        - ``in``
        - ``(nseg, nfreq)``
        - Cross phase.
        - radians
        - Axis 0 is the segment, axis 1 the frequency bin.
      * - ``magnitude``
        - ``in``
        - ``(nseg, nfreq)``
        - Mean pair auto-power ``(|X1|²+|X2|²)/2``, computed by fun_K01_pair_power and used as the accumulation weight.
        - Squared signal units under the caller's normalisation
        - Element-wise counterpart of ``phase``.
      * - ``frequencies_hz``
        - ``in``
        - ``(nfreq,)``
        - Centre frequency of each spectral bin.
        - Hz
        - One-to-one with axis 1 of ``phase``.
      * - ``chi``
        - ``in``
        - ``(2,)``
        - Separation vector :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`.
        - metres
        - Components ordered :math:`(\chi_x,\chi_y)`, in the same Cartesian frame as the wavevector.
      * - ``k_edges``
        - ``in``
        - ``(nk+1,)``
        - Wavenumber histogram edges.
        - rad/m
        - Monotonically increasing.
      * - ``f_edges``
        - ``in``
        - ``(nf+1,)``
        - Frequency histogram edges.
        - Hz
        - Monotonically increasing.

   .. rubric:: Return Value

   ``dict`` with ``spectrum`` ``(nf, nk)``, ``k_centers``, ``f_centers``, ``k_nyquist`` and ``segments``.

   .. rubric:: Local Assumptions and Preconditions

   - This is a **statistical** estimator and needs many more segments than a mean phase does.
   - When the segment count is far below the number of wavenumber bins, the peak is only the strongest single sample rather than a meaningful maximum.

   .. rubric:: Implementation Notes

   - Each (segment, frequency) sample contributes :math:`(|X_1|^2+|X_2|^2)/2` to the single wavenumber bin holding :math:`\mathrm{wrap}(\theta)/|\boldsymbol{\chi}|`, and the histogram is divided by the segment count.
   - Incoherent segments spread their power along the wavenumber axis while coherent ones concentrate it, which is what makes the estimator statistical.

   .. rubric:: Calling Notes

   - Reference: J. M. Beall, Y. C. Kim, E. J. Powers, J. Appl. Phys. **53**\ (6), 3933-3940 (1982).

   .. rubric:: Algorithm Notes

   .. math::

      S(k, f) = \frac{1}{N_{\rm seg}}\sum_{s}
      \frac{|X_{1,s}|^2+|X_{2,s}|^2}{2}\,
      \delta\!\left[k - \frac{\mathrm{wrap}(\theta_s)}{|\boldsymbol{\chi}|}\right]

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
