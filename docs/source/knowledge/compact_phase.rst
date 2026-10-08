Compact Evaluation of Narrowband Phase
========================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. _compact-zh-intro:

   .. rubric:: 窄带相位的省点计算

   一条记录可能有几十万甚至更多采样点，但如果我们只想知道一个窄频带的相位，
   不一定要在每个采样点上都做一次复数取角度。
   可以先扣掉已知的快速旋转，在较稀的时间网格上算剩下的慢变化，再补回完整相位。
   下面用人工数据一步一步说明：省的是哪些计算、为什么这样做，以及误差怎样核对。

   本页各段 Python 代码可按顺序在同一个脚本中运行，只需要 NumPy。
   来自 K04？读完可 :ref:`返回附录 B <k04-zh-baseband>`。

   可直接运行的示例与画图脚本见 :doc:`K04 代码与运行说明 </tests/011_K04_breathing_waveform/index>`。

   .. _compact-zh-input:

   .. rubric:: 1. 输入是什么？我们只需要其中哪一部分？

   输入是已经可用的单点电压 :math:`x_i=x(t_i)`，采样率为 :math:`f_s`。
   本例 :math:`f_s=8\ \mathrm{MHz}`，共 :math:`N=160000` 点，
   :math:`t_i=i/f_s`，:math:`i=0,\ldots,N-1`；记录长度按 :math:`T=N/f_s=20\ \mathrm{ms}` 计算。
   原始采样间隔为 0.125 μs。人工信号包含约 39.75 kHz 的基波、其二阶谐波和一个 300 kHz 成分，
   其中基波相位还在缓慢摆动。

   .. code-block:: python

      import numpy as np

      fs = 8_000_000.0
      N = 160_000
      t = np.arange(N) / fs
      T = N / fs
      phi_known = 2*np.pi*39_750*t + 0.37 + 0.18*np.sin(2*np.pi*250*t)
      x = (0.6 + 1.8*np.cos(phi_known)
           + 0.4*np.cos(2*phi_known - 0.7)
           + 0.08*np.cos(2*np.pi*300_000*t))

   我们只用 25–55 kHz 估计基波相位。二阶谐波和 300 kHz 成分仍在原始 ``x`` 中；
   这里的省点计算不会改动它们，也不会代替之后对原始电压做的处理。
   ``phi_known`` 只是造数据时设定的答案，下面的提取不读取它。

   .. _compact-zh-band:

   .. rubric:: 2. 先把要用的频率系数找出来

   先对去均值后的电压做 :doc:`FFT <fft>`，得到系数 :math:`F_k`。
   :math:`k` 是频率数组的序号，正频率部分对应 :math:`f_k=k/T`；相邻频点间隔为 :math:`1/T=50\ \mathrm{Hz}`。
   在 35–45 kHz 内找最强的峰，得到 :math:`f_0=39.75\ \mathrm{kHz}`。
   再取 25–55 kHz 的连续频点：第一个序号记作 :math:`k_L`，对应频率记作 :math:`f_L`，
   频点总数记作 :math:`L`。这里 :math:`k_L=500`、:math:`f_L=25\ \mathrm{kHz}`、:math:`L=601`。

   .. code-block:: python

      F = np.fft.fft(x - x.mean())
      f = np.fft.fftfreq(N, d=1/fs)
      search = np.flatnonzero((f >= 35_000) & (f <= 45_000))
      k0 = search[np.argmax(np.abs(F[search])**2)]
      f0 = f[k0]
      band = np.flatnonzero((f >= 25_000) & (f <= 55_000))
      kL = band[0]
      fL = f[kL]
      L = len(band)
      print(f0, fL, L)  # 39750.0, 25000.0, 601

   .. _compact-zh-direct:

   .. rubric:: 3. 完整计算：先留一个可以核对的结果

   最直接的办法是建一个仍有 :math:`N` 项的数组 :math:`\widehat F`：保留选中频带的系数，其余置零。
   对它做逆 FFT，得到每个原采样时刻的复数 :math:`z(t_i)`。
   同一组系数也定义了任意时刻的曲线：

   .. _compact-zh-eq-1:

   .. math::

      z(t)=\frac1N\sum_{m=0}^{L-1}F_{k_L+m}\exp\!\left[2\pi\mathrm{i}\left(f_L+\frac mT\right)t\right].\tag{1}

   式（1）的 :math:`m=0,\ldots,L-1` 是频带内部从零开始的序号；:math:`\mathrm{i}` 是虚数单位。
   只有正频率时，结果一般是复数。它的角度表示基波走到了哪一个位置。
   ``angle`` 把角度放在 −π 到 π 之间；``unwrap`` 在必要时加减整圈 2π，使相邻角度连续。
   这样得到的完整相位记作 :math:`\phi_{\rm direct}`。

   .. code-block:: python

      F_hat = np.zeros_like(F)
      F_hat[band] = F[band]
      z = np.fft.ifft(F_hat)
      phi_direct = np.unwrap(np.angle(z))

   这一步只作为本页的对照。采用省点方法时，可以直接从上一步的频率系数继续，
   不必先算出这条长的 ``z``。

   .. _compact-zh-pack:

   .. rubric:: 4. 把频带搬到低频，才能用较少的时刻表示

   复数曲线 :math:`z(t)` 大约每秒转 39750 圈。先把每个频率都减去 :math:`f_L=25\ \mathrm{kHz}`，
   频带就从 25–55 kHz 搬到 0–30 kHz。频率相对位置和各系数都不变，只是整组旋转慢了一些。

   实现时，把这 :math:`L` 个系数按原顺序放到一个较短数组 :math:`A` 的开头，后面补零。
   数组长度记作 :math:`M_{\rm base}`，本例取不小于 :math:`4L` 的最小 2 的幂，即 4096。
   这 4096 个时间点仍覆盖同一段 20 ms；新的时刻是 :math:`\tau_\ell=\ell T/M_{\rm base}`，
   :math:`\ell=0,\ldots,M_{\rm base}-1`。相邻时刻间隔约 4.883 μs。

   .. _compact-zh-eq-2:

   .. math::

      A_m=\begin{cases}F_{k_L+m},&0\le m\lt L,\\0,&L\le m\lt M_{\rm base}.\end{cases}\tag{2}

   .. _compact-zh-eq-3:

   .. math::

      v_\ell=\frac{M_{\rm base}}{N}\,\operatorname{IFFT}_{M_{\rm base}}(A)_\ell=\frac1N\sum_{m=0}^{L-1}F_{k_L+m}e^{2\pi\mathrm{i}m\ell/M_{\rm base}}=z(\tau_\ell)e^{-2\pi\mathrm{i}f_L\tau_\ell}.\tag{3}

   式（3）最后一项说明：短逆 FFT 算到的是“原曲线乘上一个反向旋转”，所以恰好实现移频。
   前面的 :math:`M_{\rm base}/N` 用于保持幅值：NumPy 的短逆变换默认除以 :math:`M_{\rm base}`，
   而式（1）需要除以 :math:`N`。只改长度、不补这个系数，幅值就会变大。
   本页使用的约定见 `NumPy FFT 说明 <https://numpy.org/doc/stable/reference/routines.fft.html>`_。

   .. code-block:: python

      M_base = 1 << int(np.ceil(np.log2(4*L)))
      tau = np.arange(M_base) * T / M_base
      A = np.zeros(M_base, dtype=complex)
      A[:L] = F[band]
      v = np.fft.ifft(A) * M_base / N
      print(M_base, T/M_base)  # 4096, 4.8828125e-06 seconds

   这里用的是复数逆 FFT，不需要补出镜像的负频率系数；我们需要保留复数的角度。
   本例短数组对应的采样率为 204.8 kHz，足以表示搬移后的 0–30 kHz 频带。
   “乘 4”给后面的相位插值留一些余量，并不是保证任意数据都准确的固定规则。

   .. _compact-zh-slow:

   .. rubric:: 5. 再扣掉剩余的主旋转，留下慢相位

   现在主峰仍在 :math:`f_0-f_L=14.75\ \mathrm{kHz}`。
   再乘一个频率为 :math:`f_0-f_L` 的反向旋转，得到 :math:`q_\ell`：

   .. _compact-zh-eq-4:

   .. math::

      q_\ell=v_\ell e^{-2\pi\mathrm{i}(f_0-f_L)\tau_\ell}=z(\tau_\ell)e^{-2\pi\mathrm{i}f_0\tau_\ell}.\tag{4}

   .. code-block:: python

      q = v * np.exp(-2j*np.pi*(f0 - fL)*tau)

   两次搬移合起来，就是从原曲线中扣掉 :math:`f_0` 的旋转。
   这时主峰位于零频率，频带为 −14.75 到 15.25 kHz。
   围绕零频率的这种表示通常叫 **基带表示**。
   第一次移频方便把系数放进短数组，第二次让主峰附近的角度变化更慢，便于插值。

   .. figure:: ../images/knowledge/compact_phase_frequency_shift.png
      :width: 100%
      :alt: 图 1. 同一组频率系数在三种坐标中的位置。上：原来的 z；中：减去 fL 后的 v；下：总共减去 f0 后的 q。

      图 1. 同一组频率系数在三种坐标中的位置。上：原来的 z；中：减去 fL 后的 v；下：总共减去 f0 后的 q。
      浅色区是所选频带，峰的高度保持不变，旁边的小峰来自人工设定的缓慢相位变化。
      这里展示的是移频关系，并不是重新筛掉了某些成分。

   .. _compact-zh-restore:

   .. rubric:: 6. 插值慢相位，再加回原来的旋转

   把 :math:`q_\ell` 的角度展开，得到慢相位 :math:`\delta_\ell`。
   用相邻两个粗网格点之间的直线估计原采样时刻的慢相位，记作 :math:`\widetilde\delta(t_i)`。
   再加回刚才扣掉的 :math:`2\pi f_0t_i`，就是需要的完整相位：

   .. _compact-zh-eq-5:

   .. math::

      \delta_\ell=\operatorname{unwrap}(\arg q_\ell),\qquad\phi_{\rm compact}(t_i)=2\pi f_0t_i+\widetilde\delta(t_i).\tag{5}

   **先展开，再插值。** 例如角度从 179° 变到 −179°，实际可能只前进了 2°；
   若直接连这两个数，插值却会绕过 0°。先把 −179° 接成 181°，才是在跟随同一次连续运动。

   还要补好记录尾端。最后一个粗网格点早于最后一个原采样点，
   因此在 :math:`T` 处再补一个复数值，给最后一小段插值提供右端点。
   本例 :math:`f_L` 和 :math:`f_0` 都取自 FFT 频点，因而 :math:`q(T)=q(0)`。
   **先把复数** ``q[0]`` **接到尾部，再统一取角度、展开**；
   不要直接把展开后的首角度照抄到末尾，因为中间可能已经累计了若干整圈。

   .. code-block:: python

      tau_extended = np.r_[tau, T]
      delta_extended = np.unwrap(np.angle(np.r_[q, q[0]]))
      delta_native = np.interp(t, tau_extended, delta_extended)
      phi_compact = 2*np.pi*f0*t + delta_native

   现在 ``phi_compact`` 又有 160000 个值，与原始电压逐点对应。
   省下的是在长数组上做逆 FFT、取角度和展开相位的工作；原采样点仍会得到完整结果。
   如果自行把载频改成不落在 FFT 频点上的数，不能直接使用上述首尾相等的补点方式。

   .. _compact-zh-error:

   .. rubric:: 7. 图里的误差是谁和谁的差？

   图 2 上半部比较完整计算得到的慢相位 :math:`\phi_{\rm direct}(t_i)-2\pi f_0t_i`
   与省点计算插值出的 :math:`\widetilde\delta(t_i)`。
   下半部放大显示 **省点法的完整相位减去直接法的完整相位**，单位为 μrad，即百万分之一弧度。
   这衡量的是省点计算增加的数值误差，不是“测量值与真实物理相位”的误差。

   .. figure:: ../images/knowledge/compact_phase_interpolation.png
      :width: 100%
      :alt: 图 2. 上：两条慢相位曲线在这个尺度上重合；黑点只画每 16 个粗网格点中的一个，计算时使用全部 4096 点。

      图 2. 上：两条慢相位曲线在这个尺度上重合；黑点只画每 16 个粗网格点中的一个，计算时使用全部 4096 点。
      下：放大 950–1050 μs 这一小段相位差，能够看见直线插值带来的微小误差。

   两条展开后的相位可能相差一个固定的整圈，比较前只消除这个固定差；
   不把每个时刻的差都折回 −π 到 π，以免掩盖中途展开错圈的问题。
   下面给出整个 20 ms 记录的均方根误差和最大绝对误差。

   .. code-block:: python

      error = phi_compact - phi_direct
      # Align only a constant 2*pi branch offset; retain any cycle-slip error.
      error -= 2*np.pi*np.rint(error[0] / (2*np.pi))
      rmse = np.sqrt(np.mean(error**2))
      max_error = np.max(np.abs(error))
      print(f"phase RMSE = {rmse:.3e} rad")
      print(f"maximum absolute error = {max_error:.3e} rad")

   本例均方根误差约 6.84e-07 rad，最大绝对误差约 1.32e-06 rad。
   这些数值只说明这组平稳人工数据的效果，不能作为实际数据的误差保证。
   频率系数搬移本身没有丢掉选中频带的信息；此处可见的差主要来自慢相位的直线插值。

   .. _compact-zh-limits:

   .. rubric:: 8. 少算到什么程度合适？

   粗网格既要装得下所选系数，也要跟得上复数角度的变化。
   本例的 4096 点是一个演示选择；实际使用可先取少量有代表性的记录，
   与直接法核对，再增加粗网格点数，直到关心的结果不再明显变化。
   2 的幂是方便 FFT 的长度选择，并不是数学上必须如此。

   尤其要注意 :math:`|q|` 很小的时候：复数箭头几乎没有长度，角度可能突然转得很快，
   甚至失去可靠意义。**复数信号的频带窄，不等于它的角度一定平滑。**
   粗网格太稀会漏掉这种变化，``unwrap`` 也可能接错圈；增加点数能减少数值问题，
   但不能让本来就不可靠的相位变成可靠的物理量。

   记录首尾不接续时，直接法与省点法都可能受边缘影响；省点并不消除
   :doc:`谱泄漏与记录边界的问题 <spectral_leakage>`。
   ``unwrap`` 和 ``interp`` 的具体行为可查
   `NumPy 相位展开 <https://numpy.org/doc/stable/reference/generated/numpy.unwrap.html>`_ 与
   `线性插值 <https://numpy.org/doc/stable/reference/generated/numpy.interp.html>`_。

   这里把逆 FFT 和主要取角度操作的规模从 160000 点降到 4096 点，点数约少 39 倍。
   **这不等于整个程序快 39 倍。** 原始数据仍要读取，前面的 FFT 仍使用全部 :math:`N` 点，
   插值和最终相位输出也仍有 :math:`N` 点。它只是让窄带相位计算中的一部分工作变少。
   在 K04 中，后续仍把这些相位与原始电压配对来求共同形状。

   继续阅读：:ref:`返回 K04 附录 B <k04-zh-baseband>`。


.. container:: ap-lang ap-lang-en

   .. _compact-en-intro:

   .. rubric:: Evaluating narrowband phase at fewer time points

   A record may contain hundreds of thousands of samples, yet estimating the phase of one narrow band
   need not require taking a complex angle at every sample. Remove a known rapid rotation,
   evaluate the remaining slow variation on a coarser time grid, then restore the full phase.
   A synthetic example shows what computation is saved, why it works, and how to check the error.

   The Python blocks run in order in one script and require only NumPy.
   Coming from K04? You can :ref:`return to Appendix B <k04-en-baseband>` afterward.

   Runnable examples and plot scripts are described in the :doc:`K04 running guide </tests/011_K04_breathing_waveform/index>`.

   .. _compact-en-input:

   .. rubric:: 1. What is the input, and which part do we need?

   The input is usable single-point voltage :math:`x_i=x(t_i)`, sampled at :math:`f_s`.
   Here :math:`f_s=8\ \mathrm{MHz}`, :math:`N=160000`, :math:`t_i=i/f_s`,
   and :math:`i=0,\ldots,N-1`. The record duration is :math:`T=N/f_s=20\ \mathrm{ms}`;
   the original sample spacing is 0.125 μs. Our synthetic signal contains a fundamental near
   39.75 kHz, its second harmonic, and a 300 kHz component. The fundamental phase also varies slowly.

   .. code-block:: python

      import numpy as np

      fs = 8_000_000.0
      N = 160_000
      t = np.arange(N) / fs
      T = N / fs
      phi_known = 2*np.pi*39_750*t + 0.37 + 0.18*np.sin(2*np.pi*250*t)
      x = (0.6 + 1.8*np.cos(phi_known)
           + 0.4*np.cos(2*phi_known - 0.7)
           + 0.08*np.cos(2*np.pi*300_000*t))

   We use only 25–55 kHz to estimate the fundamental phase. The second harmonic and 300 kHz component
   remain in the original ``x``; the compact calculation does not modify them or replace subsequent
   processing of the original voltage. ``phi_known`` is generator truth, unused by the extraction below.

   .. _compact-en-band:

   .. rubric:: 2. Select the frequency coefficients

   Apply an :doc:`FFT <fft>` to the demeaned voltage to obtain :math:`F_k`.
   Here :math:`k` indexes the frequency array; positive-frequency entries correspond to :math:`f_k=k/T`.
   Their spacing is :math:`1/T=50\ \mathrm{Hz}`. Find the strongest peak in 35–45 kHz,
   giving :math:`f_0=39.75\ \mathrm{kHz}`, then select the consecutive bins from 25 to 55 kHz.
   Let :math:`k_L` be their first index, :math:`f_L` its frequency, and :math:`L` their count.
   Here :math:`k_L=500`, :math:`f_L=25\ \mathrm{kHz}`, and :math:`L=601`.

   .. code-block:: python

      F = np.fft.fft(x - x.mean())
      f = np.fft.fftfreq(N, d=1/fs)
      search = np.flatnonzero((f >= 35_000) & (f <= 45_000))
      k0 = search[np.argmax(np.abs(F[search])**2)]
      f0 = f[k0]
      band = np.flatnonzero((f >= 25_000) & (f <= 55_000))
      kL = band[0]
      fL = f[kL]
      L = len(band)
      print(f0, fL, L)  # 39750.0, 25000.0, 601

   .. _compact-en-direct:

   .. rubric:: 3. Direct calculation: keep a reference result

   The direct approach constructs an :math:`N`-element array :math:`\widehat F`, keeps the selected coefficients,
   and sets all others to zero. Its inverse FFT gives a complex value :math:`z(t_i)` at every original sample.
   The same coefficients define a curve at any time:

   .. _compact-en-eq-1:

   .. math::

      z(t)=\frac1N\sum_{m=0}^{L-1}F_{k_L+m}\exp\!\left[2\pi\mathrm{i}\left(f_L+\frac mT\right)t\right].\tag{1}

   In (1), :math:`m=0,\ldots,L-1` counts positions inside the band, and :math:`\mathrm{i}` is the imaginary unit.
   Keeping only positive frequencies generally produces a complex result. Its angle tracks the fundamental's
   position within a cycle. ``angle`` returns an angle between −π and π; ``unwrap`` adds or subtracts
   whole turns of 2π where needed to continue the angle. Call this full phase :math:`\phi_{\rm direct}`.

   .. code-block:: python

      F_hat = np.zeros_like(F)
      F_hat[band] = F[band]
      z = np.fft.ifft(F_hat)
      phi_direct = np.unwrap(np.angle(z))

   This step supplies a reference for the tutorial. The compact method can proceed directly from
   the selected coefficients without first calculating this long ``z`` array.

   .. _compact-en-pack:

   .. rubric:: 4. Move the band down in frequency and use fewer time points

   The complex curve :math:`z(t)` rotates roughly 39750 times per second. Subtract :math:`f_L=25\ \mathrm{kHz}`
   from every frequency to move the band from 25–55 kHz to 0–30 kHz. The coefficients and their relative
   frequency spacing stay unchanged; the collective rotation becomes slower.

   Place the :math:`L` coefficients, in order, at the start of a shorter array :math:`A` and fill the rest with zeros.
   Call its length :math:`M_{\rm base}`. Here we choose the smallest power of two at least :math:`4L`, which is 4096.
   These 4096 time points still cover the same 20 ms: :math:`\tau_\ell=\ell T/M_{\rm base}`,
   with :math:`\ell=0,\ldots,M_{\rm base}-1`. Their spacing is approximately 4.883 μs.

   .. _compact-en-eq-2:

   .. math::

      A_m=\begin{cases}F_{k_L+m},&0\le m\lt L,\\0,&L\le m\lt M_{\rm base}.\end{cases}\tag{2}

   .. _compact-en-eq-3:

   .. math::

      v_\ell=\frac{M_{\rm base}}{N}\,\operatorname{IFFT}_{M_{\rm base}}(A)_\ell=\frac1N\sum_{m=0}^{L-1}F_{k_L+m}e^{2\pi\mathrm{i}m\ell/M_{\rm base}}=z(\tau_\ell)e^{-2\pi\mathrm{i}f_L\tau_\ell}.\tag{3}

   The last expression in (3) is the original curve multiplied by a reverse rotation, which produces exactly
   the frequency shift. The factor :math:`M_{\rm base}/N` preserves amplitude: NumPy's short inverse transform
   divides by :math:`M_{\rm base}`, whereas (1) requires division by :math:`N`. Changing the array length
   without this factor would increase the amplitude. See the
   `NumPy FFT conventions <https://numpy.org/doc/stable/reference/routines.fft.html>`_.

   .. code-block:: python

      M_base = 1 << int(np.ceil(np.log2(4*L)))
      tau = np.arange(M_base) * T / M_base
      A = np.zeros(M_base, dtype=complex)
      A[:L] = F[band]
      v = np.fft.ifft(A) * M_base / N
      print(M_base, T/M_base)  # 4096, 4.8828125e-06 seconds

   Use a complex inverse FFT without adding mirrored negative-frequency coefficients: we need the complex angle.
   The shorter array corresponds to a 204.8 kHz sampling rate, sufficient for the shifted 0–30 kHz band.
   The factor of four provides margin for phase interpolation; it does not guarantee accuracy for every signal.

   .. _compact-en-slow:

   .. rubric:: 5. Remove the remaining carrier rotation to obtain slow phase

   The main peak is still at :math:`f_0-f_L=14.75\ \mathrm{kHz}`.
   Multiply by a reverse rotation at that remaining frequency to obtain :math:`q_\ell`:

   .. _compact-en-eq-4:

   .. math::

      q_\ell=v_\ell e^{-2\pi\mathrm{i}(f_0-f_L)\tau_\ell}=z(\tau_\ell)e^{-2\pi\mathrm{i}f_0\tau_\ell}.\tag{4}

   .. code-block:: python

      q = v * np.exp(-2j*np.pi*(f0 - fL)*tau)

   Together the two shifts remove a rotation at :math:`f_0` from the original curve.
   The main peak now lies at zero frequency, and the band spans −14.75 to 15.25 kHz.
   This representation around zero frequency is called a **baseband representation**.
   The first shift makes it convenient to pack coefficients into the short array;
   the second slows the angle variation near the main peak for interpolation.

   .. figure:: ../images/knowledge/compact_phase_frequency_shift.png
      :width: 100%
      :alt: Figure 1. The same coefficients in three frequency coordinates: original z (top), v after subtracting fL (middle),

      Figure 1. The same coefficients in three frequency coordinates: original z (top), v after subtracting fL (middle),
      and q after subtracting f0 in total (bottom). Shading marks the selected band. Peak heights stay unchanged;
      small neighboring peaks come from the synthetic slow phase modulation. Shifting does not discard further components.

   .. _compact-en-restore:

   .. rubric:: 6. Interpolate the slow phase, then restore the original rotation

   Unwrap the angle of :math:`q_\ell` to obtain slow phase :math:`\delta_\ell`.
   Estimate its value at each original sample by a straight line between neighboring coarse-grid points,
   denoting the result :math:`\widetilde\delta(t_i)`. Restore the removed rotation :math:`2\pi f_0t_i`
   to obtain the full phase:

   .. _compact-en-eq-5:

   .. math::

      \delta_\ell=\operatorname{unwrap}(\arg q_\ell),\qquad\phi_{\rm compact}(t_i)=2\pi f_0t_i+\widetilde\delta(t_i).\tag{5}

   **Unwrap before interpolating.** A change from 179° to −179° may represent a forward motion of only 2°.
   Interpolating those wrapped numbers would instead pass through 0°.
   Continue −179° as 181° first to follow the same continuous motion.

   The record endpoint needs one extra step. The final coarse-grid point precedes the last original sample,
   so append a complex value at :math:`T` to provide the right endpoint for interpolation.
   Here both :math:`f_L` and :math:`f_0` are FFT-bin frequencies, hence :math:`q(T)=q(0)`.
   **Append the complex value** ``q[0]`` **before taking angles and unwrapping**.
   Copying the first unwrapped angle directly to the end could erase whole turns accumulated along the way.

   .. code-block:: python

      tau_extended = np.r_[tau, T]
      delta_extended = np.unwrap(np.angle(np.r_[q, q[0]]))
      delta_native = np.interp(t, tau_extended, delta_extended)
      phi_compact = 2*np.pi*f0*t + delta_native

   ``phi_compact`` now has 160000 values aligned with the original voltage.
   The savings come from avoiding a long inverse FFT and long angle/unwrap operations;
   the output still covers every original sample. If you choose a carrier frequency that is not on an FFT bin,
   the equal-endpoint extension above no longer applies directly.

   .. _compact-en-error:

   .. rubric:: 7. Which two results does the error compare?

   The top of Figure 2 compares the direct slow phase :math:`\phi_{\rm direct}(t_i)-2\pi f_0t_i`
   with the interpolated slow phase :math:`\widetilde\delta(t_i)`.
   The bottom zooms in on **the compact full phase minus the direct full phase**, in microradians
   (one millionth of a radian). It measures numerical error introduced by the compact calculation,
   not error between a measurement and its true physical phase.

   .. figure:: ../images/knowledge/compact_phase_interpolation.png
      :width: 100%
      :alt: Figure 2. Top: the two slow-phase curves overlap at this scale. Black markers show every 16th coarse point;

      Figure 2. Top: the two slow-phase curves overlap at this scale. Black markers show every 16th coarse point;
      the calculation uses all 4096. Bottom: the phase difference over 950–1050 μs reveals the small linear-interpolation error.

   Two unwrapped phases may differ by a constant whole-turn offset. Remove only that constant before comparison.
   Do not wrap every error back into −π to π, which could hide a cycle slip during unwrapping.
   The following reports root-mean-square and maximum absolute errors across the full 20 ms record.

   .. code-block:: python

      error = phi_compact - phi_direct
      # Align only a constant 2*pi branch offset; retain any cycle-slip error.
      error -= 2*np.pi*np.rint(error[0] / (2*np.pi))
      rmse = np.sqrt(np.mean(error**2))
      max_error = np.max(np.abs(error))
      print(f"phase RMSE = {rmse:.3e} rad")
      print(f"maximum absolute error = {max_error:.3e} rad")

   The example gives an RMSE of about 6.84e-07 rad and a maximum absolute error of 1.32e-06 rad.
   These values describe this well-behaved synthetic record, not an error guarantee for measured data.
   Shifting the coefficients does not discard selected-band information; the visible difference here comes mainly from linear interpolation of slow phase.

   .. _compact-en-limits:

   .. rubric:: 8. How coarse can the calculation be?

   The coarse grid must hold the selected coefficients and resolve the changing complex angle.
   Our 4096-point choice is illustrative. For measured data, compare a few representative records with the direct method,
   then increase the coarse-grid size until the results of interest stop changing materially.
   A power of two is a convenient FFT length, not a mathematical requirement.

   Pay particular attention when :math:`|q|` is small: the complex arrow nearly vanishes,
   and its angle can turn rapidly or become unreliable. **A narrow complex-signal bandwidth does not guarantee a smooth angle.**
   A sparse grid can miss such changes and ``unwrap`` can choose the wrong turn.
   More points can reduce numerical error, but cannot turn an intrinsically unreliable angle into a reliable physical quantity.

   If the record endpoints do not join smoothly, both methods can suffer edge effects;
   compact evaluation does not eliminate :doc:`spectral leakage or record-boundary effects <spectral_leakage>`.
   For the exact function behavior, see NumPy's
   `phase unwrapping <https://numpy.org/doc/stable/reference/generated/numpy.unwrap.html>`_ and
   `linear interpolation <https://numpy.org/doc/stable/reference/generated/numpy.interp.html>`_ documentation.

   The inverse FFT and main angle operations shrink from 160000 to 4096 points, roughly 39 times fewer.
   **This does not imply a 39-fold speedup of the whole program.** Reading the data and the initial FFT still use all :math:`N`
   samples, and interpolation and final phase output still have :math:`N` entries. Only part of narrowband phase evaluation
   becomes smaller. In K04, the resulting phases are still paired with the original voltage to estimate the shared shape.

   Continue reading: :ref:`return to K04 Appendix B <k04-en-baseband>`.
