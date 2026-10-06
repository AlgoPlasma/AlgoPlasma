=========================
Diagnostics Learning Path
=========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. note::

      如果还不熟悉波数、FFT、互相位或最大似然，请先读
      :doc:`探针诊断基础 <diagnostics_foundations>`。它从同一个双探针例子逐步引入这些概念，
      并说明多构型反演的适用条件；读完后再用本页安排函数阅读顺序。

   .. rubric:: 这页解决什么问题

   本页面向第一次接触 ``K_Diagnostics`` 的读者。它不是谱分析教材，而是帮你把"两根探针能测到什么、
   测不到什么"这件事跟仓库里的 routine 对上号。读完后，应该知道该先看哪一页、混叠为什么是这个
   模块存在的理由、以及测试为什么能说明实现是可信的。

   .. rubric:: 推荐学习顺序

   .. list-table::
      :header-rows: 1
      :widths: 10 46 44

      * - 步骤
        - 先理解什么
        - 建议阅读
      * - 1
        - 两根探针测到的唯一物理量是互相位，而它只在 :math:`(-\pi,\pi]` 内可知。
        - 本页"核心图景"
      * - 2
        - 从原始波形到互相位的完整链条：分段、FFT、互谱、相位统计。
        - :doc:`K01_signal_spectra <K01_signal_spectra>`，重点看
          ``fun_K01_cross_phase`` 和 ``fun_K01_phase_mode_statistics``
      * - 3
        - 混叠的闭式几何：Nyquist 波数、投影、折叠阶数。
        - :doc:`K02_beall <K02_beall>` 的前六个 routine
      * - 4
        - 混叠在 :math:`S(k,f)` 图上长什么样，以及为什么单对探针无法自行解开。
        - ``fun_K02_beall_spectrum`` 与测试里的 ``beall_skf.png``
      * - 5
        - 多构型联合为什么能解开：条纹相交与几何可辨识性。
        - :doc:`K03_mle_k2d <K03_mle_k2d>` 的 ``fun_K03_joint_log_likelihood``
      * - 6
        - 怎么用、怎么接进自己的分析流程。
        - :doc:`Diagnostics Usage Cookbook <diagnostics_usage_cookbook>`
      * - 7
        - 怎样验证实现可信。
        - :doc:`基础数值测试 </tests/010_diagnostics/case_basic_checks>`，再读
          :doc:`Diagnostics Testing Guide <diagnostics_testing_guide>` 和
          :doc:`010_diagnostics </tests/010_diagnostics/index>`

   .. rubric:: 核心图景

   一对探针放在相距 :math:`\boldsymbol{\chi}` 的两处，同时记录同一场量。对频率 :math:`f` 上的
   一个平面波，两路信号的唯一差别是相位差

   .. math::

      \theta = \mathbf{K}\cdot\boldsymbol{\chi}.

   这一个式子决定了整个模块的能力边界，有三层含义：

   - **只能测投影**。:math:`\theta` 只依赖 :math:`\mathbf{K}` 沿 :math:`\boldsymbol{\chi}`
     的分量，垂直分量完全不进入测量。所以单对探针永远给不出二维波矢。
   - **只能测模 2π**。相位是角度，:math:`\theta` 和 :math:`\theta+2\pi` 无法区分。当
     :math:`|\mathbf{K}\cdot\boldsymbol{\chi}|>\pi` 时，报出的波数是折叠后的假值。
   - **折叠阶数是丢失的信息**。真值与测量值差整数个 :math:`2\pi/|\boldsymbol{\chi}|`，这个整数
     无法从单次测量恢复。

   每条基线通过相位差约束波矢沿该方向的投影。将多个构型的对数似然相加，可以在二维波数平面上寻找共同支持的波矢。基线的方向和长度共同决定相位条纹的交汇位置。

   .. rubric:: 初学者最容易混的点

   - **基线几何**。沿不同方向布置基线，可以共同约束两个波矢分量；第 7 节基础说明给出条纹交汇和精确混叠条件。
   - **相干度的底不是零**。:math:`n` 个分段下不相关信号的相干度平均到 :math:`1/n`。把空频带的
     相干度当成"应该接近 0"会得出错误结论。
   - 分段数决定相位直方图的样本量。可增加分段数并比较众数位置的变化，检查当前噪声水平与分箱下的统计稳定性。
   - **波数轴是周期的**。比较两个折叠波数必须用圆周距离；直接相减会在贴近 Nyquist 边时报出整整
     一个周期的假误差。
   - **符号约定由探针顺序决定**。交换两路探针会让所有相位反号、所有反演出的波矢镜像，而波数的
     大小和色散斜率的大小都不变——这种错误不会自己暴露。

   .. rubric:: 建议练习

   - 取一个已知 :math:`\mathbf{K}`，手算它在几个不同间距上的 :math:`k_{\rm proj}`、折叠阶数和
     :math:`k_{\rm meas}`，再用 ``fun_K02_fold_wavenumber`` 对答案。
   - 用单个构型画一张 :math:`\ln L(K_x,K_y)` 的图，确认它确实是一族平行条纹，且条纹间距为
     :math:`2\pi/|\boldsymbol{\chi}|`。
   - 逐个加入构型重画联合似然，观察候选集如何从一族条纹收缩到一个峰。

.. container:: ap-lang ap-lang-en

   .. note::

      If wavenumber, FFTs, cross phase, or maximum likelihood are new to you, start with
      :doc:`Probe Diagnostics Foundations <diagnostics_foundations>`. It develops these ideas
      through one two-probe example and explains the conditions for multi-configuration
      inversion. Then use this page to choose the routine reading order.

   .. rubric:: What This Page Is For

   This page is for a reader meeting ``K_Diagnostics`` for the first time. It is not a course on
   spectral analysis; it maps the question "what can two probes measure, and what can they not"
   onto the routines in this repository. After reading it you should know which page to open
   first, why aliasing is the reason this module exists, and why the tests are evidence that the
   implementation is trustworthy.

   .. rubric:: Suggested Learning Order

   .. list-table::
      :header-rows: 1
      :widths: 10 46 44

      * - Step
        - Understand first
        - Suggested reading
      * - 1
        - The only physical quantity two probes measure is the cross phase, and it is knowable
          only within :math:`(-\pi,\pi]`.
        - "Core Mental Model" on this page
      * - 2
        - The full chain from raw waveform to cross phase: segmentation, FFT, cross spectrum,
          phase statistics.
        - :doc:`K01_signal_spectra <K01_signal_spectra>`, especially
          ``fun_K01_cross_phase`` and ``fun_K01_phase_mode_statistics``
      * - 3
        - The closed-form geometry of aliasing: Nyquist wavenumber, projection, fold order.
        - The first six routines of :doc:`K02_beall <K02_beall>`
      * - 4
        - What aliasing looks like on an :math:`S(k,f)` map, and why one pair cannot undo it.
        - ``fun_K02_beall_spectrum`` and ``beall_skf.png`` in the test
      * - 5
        - Why combining configurations works: intersecting fringes and geometric identifiability.
        - ``fun_K03_joint_log_likelihood`` in :doc:`K03_mle_k2d <K03_mle_k2d>`
      * - 6
        - How to use it and wire it into your own analysis.
        - :doc:`Diagnostics Usage Cookbook <diagnostics_usage_cookbook>`
      * - 7
        - How the implementation is shown to be trustworthy.
        - :doc:`basic_numerical tests </tests/010_diagnostics/case_basic_checks>`, then
          :doc:`Diagnostics Testing Guide <diagnostics_testing_guide>` and
          :doc:`010_diagnostics </tests/010_diagnostics/index>`

   .. rubric:: Core Mental Model

   Two probes sit a distance :math:`\boldsymbol{\chi}` apart and record the same field
   quantity. For a plane wave at frequency :math:`f`, the only difference between the two
   records is the phase difference

   .. math::

      \theta = \mathbf{K}\cdot\boldsymbol{\chi}.

   That single expression sets the limits of the whole module, in three ways:

   - **Only a projection is measurable.** :math:`\theta` depends only on the component of
     :math:`\mathbf{K}` along :math:`\boldsymbol{\chi}`; the perpendicular component never
     enters. One pair can therefore never yield a two-dimensional wavevector.
   - **Only modulo 2 pi.** A phase is an angle, so :math:`\theta` and :math:`\theta+2\pi` are
     indistinguishable. Once :math:`|\mathbf{K}\cdot\boldsymbol{\chi}|>\pi`, the reported
     wavenumber is a folded, false value.
   - **The fold order is the lost information.** Truth and measurement differ by an integer
     number of :math:`2\pi/|\boldsymbol{\chi}|`, and that integer cannot be recovered from a
     single measurement.

   Each baseline constrains the wavevector projection along its direction through the measured phase difference. Summing the configurations' log likelihoods locates jointly supported wavevectors in the two-dimensional wavenumber plane. Baseline directions and lengths determine where the phase fringes intersect.

   .. rubric:: Common Beginner Traps

   - **Baseline geometry.** Different directions constrain the two wavevector components; Section 7 of the foundations explains fringe intersections and exact aliases.
   - **The coherence floor is not zero.** Over :math:`n` segments, uncorrelated signals average
     to :math:`1/n`. Expecting an empty band to sit near zero leads to wrong conclusions.
   - **The Beall spectrum is a statistical estimator.** With far fewer segments than wavenumber
     bins, its "peak" is only the strongest single sample. It needs many more segments than a
     mean phase does.
   - **The wavenumber axis is periodic.** Comparing two folded wavenumbers requires a circular
     distance; a plain difference reports a full period of spurious error near a Nyquist edge.
   - **The sign convention follows the probe order.** Swapping the two probes negates every
     phase and mirrors every recovered wavevector while leaving all magnitudes and dispersion
     slopes unchanged, so the mistake never announces itself.

   .. rubric:: Suggested Exercises

   - Take a known :math:`\mathbf{K}` and work out by hand its :math:`k_{\rm proj}`, fold order
     and :math:`k_{\rm meas}` for a few separations, then check against
     ``fun_K02_fold_wavenumber``.
   - Plot :math:`\ln L(K_x,K_y)` for a single configuration and confirm that it really is a
     family of parallel fringes with spacing :math:`2\pi/|\boldsymbol{\chi}|`.
   - Add configurations one at a time and watch the candidate set contract from a fringe family
     to a single peak.
