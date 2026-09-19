---------------------
fun_K01_wrap_to_pi.py
---------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   把角度折算到 :math:`[-\pi, \pi]`。

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
      * - ``values``
        - ``in``
        - 任意 shape
        - 以弧度表示的角度。
        - 无量纲（弧度）
        - 逐元素运算，不解释任何轴的含义。

   .. rubric:: 返回值

   ``numpy.ndarray``，与输入同 shape，取值落在 :math:`[-\pi, \pi]`。

   .. rubric:: 局部假设 / 前置条件

   - 区间两端闭合：输入恰为 :math:`\pm\pi` 时原样返回，而取模写法会把 :math:`+\pi` 折到 :math:`-\pi`。
   - 实测相位不会精确落在端点，因此这一差异在本模块内不产生实际影响。

   .. rubric:: 实现逻辑

   - 用 ``x - 2*pi*round(x/(2*pi))`` 而不是取模。
   - 两者相差数倍机器精度，但取模慢数倍，而本 routine 会在 K03 的似然里对整个波数网格反复调用。

   .. rubric:: 调用注意

   - 本 routine 不做输入校验以外的任何假设，可安全用于相位、残差或任何以 :math:`2\pi` 为周期的量。

   .. rubric:: 算法说明

   .. math::

      \mathrm{wrap}(x) = x - 2\pi\,\mathrm{round}\!\left(\frac{x}{2\pi}\right)

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Wrap angles into :math:`[-\pi, \pi]`.

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
      * - ``values``
        - ``in``
        - any shape
        - Angles in radians.
        - Dimensionless (radians)
        - Element-wise; no axis carries meaning.

   .. rubric:: Return Value

   ``numpy.ndarray`` of the input shape, with values in :math:`[-\pi, \pi]`.

   .. rubric:: Local Assumptions and Preconditions

   - The interval is closed at both ends: an input of exactly :math:`\pm\pi` is returned unchanged, whereas a modulo would fold :math:`+\pi` to :math:`-\pi`.
   - Measured phases never land there exactly, so the difference has no practical effect inside this module.

   .. rubric:: Implementation Notes

   - Uses ``x - 2*pi*round(x/(2*pi))`` rather than a modulo.
   - The two agree to a few times machine epsilon, but the modulo is several times slower and this routine runs over full wavenumber grids inside the K03 likelihood.

   .. rubric:: Calling Notes

   - The routine assumes nothing beyond its input check and is safe for phases, residuals, or any quantity periodic in :math:`2\pi`.

   .. rubric:: Algorithm Notes

   .. math::

      \mathrm{wrap}(x) = x - 2\pi\,\mathrm{round}\!\left(\frac{x}{2\pi}\right)

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
