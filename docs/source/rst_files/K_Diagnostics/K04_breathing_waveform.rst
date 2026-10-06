K04: Breathing Waveform Extraction
==========================================

.. raw:: html

   <style>
   .ap-k04 figure {border:1px solid #d8e2ea;padding:10px;border-radius:5px;background:#fff;}
   .ap-k04 table td,.ap-k04 table th {white-space:normal;}
   .ap-k04 .math {overflow-x:auto;}
   .ap-k04 table.k04-parameters tbody tr:first-child td {color:#a31d26;background:#fff0f1;font-weight:600;}
   </style>
   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-diagnostics-foundations ap-k04

   .. rubric:: K04：从探针数据一步步得到呼吸波形 C

   在电推进实验中，例如霍尔推力器的探针测量里，常会看到一轮轮明显的起伏，称为 **呼吸振荡**。
   它与中性推进剂气体的补充和电离消耗密切相关：气体进入放电区，被电离后中性粒子减少，
   电离活动随之减弱；新的气体补充进来后，电离又增强。这是理解呼吸节奏的一幅简化图景。
   常见频率约为 **10–30 kHz**，也就是每秒重复一万到三万次；具体数值随推力器和工况变化。
   下面用约 **40 kHz** 的人工数据演示，频率范围按这个例子设置。

   本页介绍怎样从探针数据中提取随呼吸周期重复的平均波形，
   便于在频谱分析时分开观察它与其余起伏的贡献。
   探针曲线上，一轮轮的起伏还叠着许多细碎变化。我们想问：
   **每次呼吸走到同一个位置时，通常会出现怎样的电压？**
   把这种重复出现的形状沿当前记录的呼吸节奏放回时间轴，就得到本页要算的 :math:`C`。

   下面用同一组人工数据逐步画图，公式旁给出对应的 Python 写法。

   :ref:`1 数据 <k04-zh-data>` → :ref:`2 F 与主频 <k04-zh-frequency>` → :ref:`3 筛选频带与 z <k04-zh-phase>` → :ref:`4 留出一条 <k04-zh-split>` → :ref:`5 S、K 与 μ <k04-zh-bins>` → :ref:`6 a 与 W <k04-zh-template>` → :ref:`7 得到 C <k04-zh-replay>` → :ref:`8 核对误差 <k04-zh-result>` → :ref:`9 读懂 R <k04-zh-meaning>` → :ref:`10 人为参数 <k04-zh-parameters>`

   完整示例、自动测试与重画图 1–12 的命令见 :doc:`K04 代码与运行说明 </tests/011_K04_breathing_waveform/index>`。

   运行代码时，先执行 :ref:`附录 A <k04-zh-demo>` 生成数据，再按第 2–10 节的顺序执行；只需 NumPy。

   .. _k04-zh-data:

   .. rubric:: 1. 手里有哪些数？

   本页只用 **一个探针、一个空间位置** 的重复测量。每次采集得到一列电压，叫一条记录；
   第 j 次采集的第 i 个电压写成 :math:`x_{j,i}`，在 Python 中就是 ``xs[j][i]``。
   数据已经是单位为 V 的可用数组。重复采集时保持测量位置和工作条件相同，才能学习共同形状。

   人工例子有 **10 条记录，每条 N = 160,000 点**。采样率 :math:`f_s=8\,000\,000` 点/秒，即 8 MHz；
   每条长 :math:`T=N/f_s=20` ms。``xs[0]`` 到 ``xs[9]`` 是十次采集，j 和 i 都从 0 编号。
   每个点的时刻由式（1）给出。图 1 的纵轴明确写成 ``xs[0][i]``，画的是第 0 条电压。

   .. _k04-zh-eq-1:

   .. math::

      t_i=i/f_s,\qquad i=0,\ldots,N-1. \tag{1}

   .. figure:: ../../images/K_Diagnostics/k04/r3_01_x.png
      :name: k04-zh-fig-1
      :width: 100%
      :alt: 图 1　灰线是输入 xs[0]；橙线是造数据时设定的重复形状，只用于最后核对。图示 150 μs，计算使用整条 20 ms。

      图 1　灰线是输入 xs[0]；橙线是造数据时设定的重复形状，只用于最后核对。图示 150 μs，计算使用整条 20 ms。

   图 1 中每轮细节不同，但有一个共同形状。下面从记录 1–9 学到它，再为第 0 条生成 C。

   .. _k04-zh-frequency:

   .. rubric:: 2. 一秒大约重复多少次？先看 F，再找主频

   约 40 kHz 就是每秒重复约四万次，一轮约 25 微秒。
   先取 ``x = xs[0]``，减去平均值，再做 :doc:`FFT（这里有 FFT 讲解） </knowledge/fft>`。
   FFT 把整段波形拆成不同频率的成分：第 k 个系数叫 :math:`F_k`，对应频率写成 :math:`f[k]`。

   **k 是频率数组的编号**，从 0 到 N − 1，Python 中对应 ``F[k]`` 和 ``f[k]``；它本身不是频率，也不是波数。
   i 给时间采样点编号，k 给频率点编号。k = 0 是零频；正频率部分有 :math:`f[k]=kf_s/N`，本例 k = 1 对应 50 Hz。
   式（2）固定一个 k，把所有时间点 i 的贡献相加，得到这一个频率点的系数。
   频率数组第零项 ``f[0]`` 与后面找到的呼吸主频 ``f0`` 是不同的量；后者在公式中记为 :math:`f_0`。

   .. _k04-zh-eq-2:

   .. math::

      \bar x=\frac1N\sum_{i=0}^{N-1}x_{0,i},\qquad F_k=\sum_{i=0}^{N-1}(x_{0,i}-\bar x)e^{-2\pi\mathrm{i}ki/N}. \tag{2}

   指数里的 :math:`\mathrm{i}` 是虚数单位，Python 写作 ``1j``；下标 i 仍是采样序号。
   ``fftfreq`` 给出每个系数的频率，先排列零频和正频率，再排列负频率。
   :math:`F_k` 是复数，不能直接用一条实数曲线画全它；图 2 先画大小 :math:`|F_k|/N` 随频率的变化。
   除以 N 只是让纵轴数值便于阅读，找峰用 :math:`|F_k|^2`，得到的位置一样。

   .. code-block:: python

      def find_frequency(x, fs, search=(35e3, 45e3)):
          x = np.asarray(x, dtype=float)
          lo, hi = search
          if x.ndim != 1 or x.size < 2 or not np.isfinite(x).all():
              raise ValueError("Expected a finite 1D record")
          if not 0 < lo < hi < fs/2:
              raise ValueError("Search band must lie below fs/2")
          F = np.fft.fft(x - x.mean())
          f = np.fft.fftfreq(x.size, d=1/fs)
          candidates = np.flatnonzero((f >= lo) & (f <= hi))
          if candidates.size == 0:
              raise ValueError("No frequency points in search band")
          k0 = candidates[np.argmax(np.abs(F[candidates])**2)]
          return F, f, float(f[k0])

      F, f, f0 = find_frequency(xs[0], fs)

   本例呼吸节奏在约 40 kHz 附近，因此只在 **35–45 kHz** 找峰，避免误选其他频率的成分。
   如图 2 右侧，得到 :math:`f_0=39.75` kHz；相邻频率点相差 :math:`f_s/N=50` Hz。
   图 2 左侧还能看到其他峰，它们暂时都留在 F 中。

   .. figure:: ../../images/K_Diagnostics/k04/r3_02_F.png
      :name: k04-zh-fig-2
      :width: 100%
      :alt: 图 2　F 的大小—频率图，只展示正频率。左图数字标出基频及其 2、5、12 倍附近的峰；右图放大找峰范围。

      图 2　F 的大小—频率图，只展示正频率。左图数字标出基频及其 2、5、12 倍附近的峰；右图放大找峰范围。

   .. _k04-zh-phase:

   .. rubric:: 3. 每个点处在这一轮的哪里？先得到 z，再读相位

   主频只告诉我们一轮大约多长；记录开始在半轮还是一轮起点、内部节奏怎样变化，还不知道。
   围住主频取 **25–55 kHz**，只保留这段正频率，其余系数设成零。
   处理后的系数另记为 :math:`\widehat F_k`，对应 ``F_hat``；原始 F 保持不变。

   .. _k04-zh-eq-3:

   .. math::

      \widehat F_k=\begin{cases}F_k,&25\,000\le f[k]\le55\,000\ \mathrm{Hz},\\0,&\text{otherwise}.\end{cases} \tag{3}

   式（3）的筛选结果见图 3：紫色只在正的 25–55 kHz 内有值，负频率和其他峰已变为零。

   .. figure:: ../../images/K_Diagnostics/k04/r3_03_Fhat.png
      :name: k04-zh-fig-3
      :width: 100%
      :alt: 图 3　灰色为原始 F 的大小，紫色为筛选后 F̂ 的大小；着色区是保留频带。两者都除以 N 方便显示。

      图 3　灰色为原始 F 的大小，紫色为筛选后 F̂ 的大小；着色区是保留频带。两者都除以 N 方便显示。

   对这份新的频谱做逆 FFT，得到式（4）的复数曲线 z。逆 FFT 把频率系数变回时间上的数。

   .. _k04-zh-eq-4:

   .. math::

      z(t_i)=\frac1N\sum_{k=0}^{N-1}\widehat F_k e^{2\pi\mathrm{i}ki/N}. \tag{4}

   式（4）里的 k 还是同一个频率编号；这次固定时间点 i，对频率编号 k 求和。被置零的系数不再贡献。

   .. code-block:: python

      def make_complex_signal(F, f, band=(25e3, 55e3)):
          lo, hi = band
          if not 0 < lo < hi <= np.max(f):
              raise ValueError("Choose a positive band below fs/2")
          keep = (f >= lo) & (f <= hi)
          F_hat = np.where(keep, F, 0.0)
          if not np.any(np.abs(F_hat) > 0):
              raise ValueError("No signal from which to read phase")
          z = np.fft.ifft(F_hat)
          return F_hat, z

      F_hat, z = make_complex_signal(F, f)

   一个复数可以画成平面上的箭头：实部是横坐标，虚部是纵坐标，角度叫 **相位**。
   为什么图 4 中实部像余弦、虚部像正弦？因为刚才只留下了基频附近一小段。
   对最简单的 :math:`A\cos(\omega t+\alpha)`，A 是振幅，:math:`\omega=2\pi f_0`，α 是起始角度。
   先把完整余弦写成正、负频率两项，再只保留正频率项，见式（5）。两项各有 A/2 的系数：

   .. _k04-zh-eq-5:

   .. math::

      \begin{aligned}
            A\cos(\omega t+\alpha)&=\underbrace{\frac A2e^{\mathrm{i}(\omega t+\alpha)}}_{+f_0}
            +\underbrace{\frac A2e^{-\mathrm{i}(\omega t+\alpha)}}_{-f_0},\\
            z(t)&=\frac A2e^{\mathrm{i}(\omega t+\alpha)}\\
            &=\frac A2\cos(\omega t+\alpha)+\mathrm{i}\frac A2\sin(\omega t+\alpha).
            \end{aligned} \tag{5}

   第二行是在删去负频率项之后。本页只保留系数，没有把正频率系数加倍，所以 z 的振幅是 A/2。

   因此实部和虚部相差四分之一圈。实际 z 由窄带内多个系数组成，只是近似这个形状，振幅和转速都可以慢慢变化。
   **z 用来给每个点标上周期位置；它还不是我们要提取的 C。** 原电压中重复的尖峰和不对称细节，后面另从原电压平均得到。

   .. figure:: ../../images/K_Diagnostics/k04/r3_04_z.png
      :name: k04-zh-fig-4
      :width: 100%
      :alt: 图 4　左：z(tᵢ) 的实部和虚部；右：同一批 z 的实部—虚部轨迹，箭头从原点指向一个样本。

      图 4　左：z(tᵢ) 的实部和虚部；右：同一批 z 的实部—虚部轨迹，箭头从原点指向一个样本。

   ``np.angle`` 读出约在 −π 到 π 之间的角度。连续转动可能返回 ``2.80, 3.05, -3.00, -2.75``；
   ``unwrap`` 给后两项补上 2π，就变为 ``2.80, 3.05, 3.283, 3.533``。
   展开后的累计角度叫 φ，再对 2π 取余，得到只保留一圈位置的 θ。

   .. _k04-zh-eq-6:

   .. math::

      \phi_i=\operatorname{unwrap}(\arg z_i),\qquad\theta_i=\phi_i\bmod2\pi. \tag{6}

   .. code-block:: python

      def mark_position(z):
          angle = np.angle(z)
          phi = np.unwrap(angle)
          theta = np.remainder(phi, 2*np.pi)
          return phi, theta

      phi, theta = mark_position(z)

   .. figure:: ../../images/K_Diagnostics/k04/r3_05_phase.png
      :name: k04-zh-fig-5
      :width: 100%
      :alt: 图 5　左：φ 累计走过的圈数，为显示减去一个整数；右：θ 只保留当前圈内位置，走完一圈就回到 0。

      图 5　左：φ 累计走过的圈数，为显示减去一个整数；右：θ 只保留当前圈内位置，走完一圈就回到 0。

   一圈是 2π 弧度，θ/(2π) = 0.25 就是四分之一圈。
   不同记录都用同一套取角度约定，不能逐条减去自己的初相位，否则不同的采集起点会被误当成同一呼吸位置。

   .. _k04-zh-split:

   .. rubric:: 4. 给十条都标上位置，再把当前记录留出来

   对其余九条重复相同运算，每条有自己的主频和周期位置数组。
   选 r = 0 为当前要重建的记录。它提供自己的节奏，但自己的电压不参与共同形状的平均。
   图 6 展示记录 1–3：时间轴上峰没有对齐，改按周期位置画，就落在共同形状附近。

   .. code-block:: python

      frequencies, positions = [], []
      for xj in xs:
          Fj, fj, f0j = find_frequency(xj, fs)
          _, zj = make_complex_signal(Fj, fj)
          _, theta_j = mark_position(zj)
          frequencies.append(f0j)
          positions.append(theta_j)
      r = 0  # Learn the shape from records 1-9; reconstruct record 0.

   .. figure:: ../../images/K_Diagnostics/k04/r3_06_fold.png
      :name: k04-zh-fig-6
      :width: 100%
      :alt: 图 6　左：三条训练记录随时间变化；右：各点横坐标换成自己的 θ/(2π)。这里只抽画部分点，计算使用全部点。

      图 6　左：三条训练记录随时间变化；右：各点横坐标换成自己的 θ/(2π)。这里只抽画部分点，计算使用全部点。

   留出的是 **整条记录**。轮到第 1 条时，用 0、2、…、9 条求平均。
   这种轮换叫 **留一记录交叉拟合**，避免某条记录自己的偶然起伏直接进入自己的平均形状。

   .. _k04-zh-bins:

   .. rubric:: 5. 同一周期位置的电压放一起：先定义 S、K，再得到 μ

   很少有两个点的角度完全相等，所以把一圈分成 B = 256 个小区间，叫 **相位箱**，
   编号 b = 0,…,255。式（7）给出每个点的箱号，向下取整的符号表示只取整数部分。

   .. _k04-zh-eq-7:

   .. math::

      b_{j,i}=\left\lfloor\frac{B\theta_{j,i}}{2\pi}\right\rfloor. \tag{7}

   这里的 :math:`\theta_{j,i}` **就是式（6）的 θ**，只是补上 j，表示“第 j 条记录、第 i 个点的一圈内位置”。
   把这个位置乘 B/(2π)，再向下取整，就得到箱号。例如 B = 256、θ = π 时，箱号为 128。

   现在明确区分两个统计量。:math:`K_{j,b}` 是 **第 j 条记录落入第 b 箱的样本个数**，
   :math:`S_{j,b}` 是 **这些样本的电压总和**。式（8）只对满足箱号条件的 i 求和：

   .. _k04-zh-eq-8:

   .. math::

      K_{j,b}=\sum_{i:\,b_{j,i}=b}1,\qquad S_{j,b}=\sum_{i:\,b_{j,i}=b}x_{j,i}. \tag{8}

   **式（8）用的是最初输入的原始电压** :math:`x_{j,i}`，也就是 ``xs[j][i]``，包含原来的平均值和全部起伏；不是筛选频带后的 z，也不是 z 的实部。
   前面筛选频带只为了找到每个点的 θ。现在用 θ 决定它进哪个箱，再把原电压加进 S。

   例如某条记录在某箱有两个电压 1.5 V 和 2.5 V，则 K = 2、S = 4 V。S 是加和，不是平均值。

   .. code-block:: python

      def put_into_bins(x, theta, B=256):
          x, theta = np.asarray(x), np.asarray(theta)
          if x.ndim != 1 or x.shape != theta.shape:
              raise ValueError("Voltage and phase must be aligned 1D arrays")
          b = np.floor(np.remainder(theta, 2*np.pi)*B/(2*np.pi)).astype(int)
          b = np.minimum(b, B-1)
          S = np.bincount(b, weights=x, minlength=B)
          K = np.bincount(b, minlength=B)
          return S, K

      B = 256
      sums, counts = [], []
      for xj, theta_j in zip(xs, positions):
          Sj, Kj = put_into_bins(xj, theta_j, B)
          sums.append(Sj)
          counts.append(Kj)

   ``bincount`` 按箱号计数，带 ``weights=x`` 时累加电压。
   **入箱的是原电压；z 只负责提供周期位置。** 排除第 r 条后，把其他记录的电压和先相加，点数也先相加，再相除：

   .. _k04-zh-eq-9:

   .. math::

      \mu_{-r,b}=\frac{\sum_{j\ne r}S_{j,b}}{\sum_{j\ne r}K_{j,b}}. \tag{9}

   μ 是平均电压，下标 −r 表示排除记录 r。例如一条提供 S = 4 V、K = 2，另一条提供 S = 18 V、K = 6，
   合起来是 22/8 = 2.75 V，而不是把两个记录均值 2 和 3 等权平均。这样每个采样点贡献相同。

   .. code-block:: python

      def mean_other_records(sums, counts, r):
          if len(sums) < 3 or not 0 <= r < len(sums):
              raise ValueError("Use at least 3 complete records")
          S_train = np.sum([s for j, s in enumerate(sums) if j != r], axis=0)
          K_train = np.sum([k for j, k in enumerate(counts) if j != r], axis=0)
          if np.any(K_train == 0):
              raise ValueError("Empty phase bin: check data coverage")
          return S_train/K_train, K_train

      mu, K_train = mean_other_records(sums, counts, r)

   图 7 左侧就是此时的 μ：一圈上有 256 个平均电压，暂时还没有连续曲线。右侧显示每个均值用了多少点。

   .. figure:: ../../images/K_Diagnostics/k04/r3_07_mu.png
      :name: k04-zh-fig-7
      :width: 100%
      :alt: 图 7　左：μ₋₀,ᵦ 随相位箱中心变化；右：记录 1–9 合计的箱内点数。横轴的箱中心是 (b + 1/2)/B 圈。

      图 7　左：μ₋₀,ᵦ 随相位箱中心变化；右：记录 1–9 合计的箱内点数。横轴的箱中心是 (b + 1/2)/B 圈。

   同一位置反复出现的形状会保留，正负不固定的起伏会在平均中部分抵消。若某箱没有点，代码会报错，不能把空箱当作零电压。

   .. _k04-zh-template:

   .. rubric:: 6. 从 μ 到 aₙ，再到周期曲线 W

   μ 已经给出每箱的平均电压，但只有 256 个离散位置。接下来要解决两件事：**选择保留哪些谐波，以及在任意周期位置取值**。
   所以先把 μ 拆成各阶系数 aₙ，按上限选择阶数，再组合成周期曲线 W。这样可以控制保留的细节，并为下一节沿时间轴查值做好准备。

   一圈里的形状可以由正弦、余弦叠加：一圈内起伏一次叫第 1 阶，两次叫第 2 阶，这些成分叫 **谐波**。
   先把每箱均值放在箱中心 β，再计算第 n 阶系数 aₙ。β 是相位角，单位弧度。

   .. _k04-zh-eq-10:

   .. math::

      \beta_b=\frac{2\pi(b+1/2)}B,\qquad b=0,\ldots,B-1. \tag{10}

   .. _k04-zh-eq-11:

   .. math::

      a_n=\frac1B\sum_{b=0}^{B-1}\mu_{-r,b}e^{-\mathrm{i}n\beta_b}. \tag{11}

   .. code-block:: python

      def mean_to_coefficients(mu):
          B = len(mu)
          n = np.arange(B//2 + 1)
          return np.fft.rfft(mu)/B * np.exp(-1j*n*np.pi/B)

      a = mean_to_coefficients(mu)

   ``a[n]`` 是复数：它同时保存这一阶的大小和左右偏移。图 8 左侧分别画实部、虚部，右侧画正阶振幅 2|aₙ|。
   a₀ 是常数电压；对正阶 n，振幅为 2|aₙ|，角度为 arg aₙ。
   代码中的半箱修正 ``exp(-1j*n*pi/B)``，把 FFT 默认的箱左端坐标改到式（10）的箱中心。

   .. figure:: ../../images/K_Diagnostics/k04/r3_08_a.png
      :name: k04-zh-fig-8
      :width: 100%
      :alt: 图 8　aₙ 的实部、虚部和正阶振幅。右图用对数纵轴显示很小的高阶系数；这里先观察各阶，下一步再选保留范围。

      图 8　aₙ 的实部、虚部和正阶振幅。右图用对数纵轴显示很小的高阶系数；这里先观察各阶，下一步再选保留范围。

   保留到哪一阶由人为选择的频率上限 :math:`f_{\rm cut}` 决定。本例用 3 MHz；它允许模板包含呼吸的高次谐波，并不表示要减掉所有 3 MHz 以下的波动。
   用本条主频估算第 n 阶频率为 :math:`nf_{0,r}`，于是最高阶 H 为：

   .. _k04-zh-eq-12:

   .. math::

      H=\left\lfloor f_{\rm cut}/f_{0,r}\right\rfloor. \tag{12}

   39.75 kHz 给出 H = 75：第 75 阶约 2.98125 MHz，第 76 阶约 3.021 MHz。
   将保留的阶数相加就得到 W(θ)，也就是一圈的平均形状。Re 表示取实部，乘 2 合并正负阶的贡献。

   .. _k04-zh-eq-13:

   .. math::

      W(\theta)=a_0+2\operatorname{Re}\sum_{n=1}^H a_n e^{\mathrm{i}n\theta}. \tag{13}

   为了方便查值，再在一圈内均匀选 M = 4096 个位置。**γℓ 是第 ℓ 个查表位置的相位角**，ℓ 是格点编号；
   wℓ 是 W 在该位置的电压值。它们由式（14）定义，不是新测量的数据：

   .. _k04-zh-eq-14:

   .. math::

      \gamma_\ell=\frac{2\pi\ell}M,\quad w_\ell=W(\gamma_\ell),\qquad\ell=0,\ldots,M-1. \tag{14}

   例如 γ₀ = 0，γ₁ = 2π/4096，最后一个位置还差一格才到 2π。
   βᵦ 表示原来 256 个箱的中心，γℓ 表示后来选择的 4096 个查表位置，两套坐标不要混在一起。

   .. code-block:: python

      def coefficients_to_grid(a, f0, fs, cutoff=3e6, M=4096):
          if not 0 < cutoff < fs/2 or f0 <= 0:
              raise ValueError("Nominal cutoff must be positive and below fs/2")
          H = int(np.floor(cutoff/f0))
          if H >= len(a)-1 or 2*H >= M:
              raise ValueError("Increase phase bins/grid, or lower the cutoff")
          gamma = 2*np.pi*np.arange(M)/M
          n = np.arange(1, H+1)
          waves = np.exp(1j*np.outer(gamma, n))
          w = a[0].real + 2*np.real(waves @ a[n])
          return gamma, w, H

      gamma, w, H = coefficients_to_grid(a, frequencies[r], fs)

   图 9 左侧把原来的 μ 点和算出的 W 放在一起；右侧放大 4096 个查表点中的连续 5 个，点旁数字就是 ℓ。
   更多查表点能让插值更细，但不能补回分箱时已经平均掉的细节。

   .. figure:: ../../images/K_Diagnostics/k04/r3_09_W.png
      :name: k04-zh-fig-9
      :width: 100%
      :alt: 图 9　左：平均值 μ 和周期曲线 W；右：横坐标 γℓ/(2π) = ℓ/M，纵坐标 wℓ，展示查表数组的含义。

      图 9　左：平均值 μ 和周期曲线 W；右：横坐标 γℓ/(2π) = ℓ/M，纵坐标 wℓ，展示查表数组的含义。

   图 9 中 μ 与 W 看起来几乎重合，正是因为 W 要表达 μ 学到的形状。
   **式（11）是沿相位箱做离散傅里叶变换，代码用 FFT；式（13）是选定阶数后的傅里叶合成，相当于做截断后的逆变换。**
   若完整保留离散变换系数，并使用一致的坐标和归一化，在原箱中心会恢复 μ；本页只保留 1 到 H 阶和常数项，所以通常只是近似重合。
   本例主要形状集中在较低阶，舍去的高阶很小，因而肉眼不易看出差别。

   这一步的作用不是再发现一份独立数据，而是 **把“256 个均值”变成“阶数可控、任意相位可查的周期函数”**。
   直接对 μ 做周期插值也能查值，但没有这里明确的谐波截断；只增加查表点 M，也不会增加原始信息。
   注意这里的 n 数的是“一圈里的第几阶”，与式（2）中整条时间记录的频率编号 k 不同。

   .. _k04-zh-replay:

   .. rubric:: 7. 沿当前记录的周期位置查 W，得到 C

   拿回第 0 条的 ``positions[0]``。每个时刻先读 θ，再到 W 上查对应电压，最后放回这个时刻。
   图 10 的三个紫点说明同一次查值。位置在两格之间时，按距离比例混合相邻值，叫 **线性插值**。

   设 u = Mθ/(2π)，左格号 ℓ = floor(u)，向右的比例 λ = u − ℓ，则：

   .. _k04-zh-eq-15:

   .. math::

      C(t_i)=(1-\lambda_i)w_{\ell_i}+\lambda_i w_{(\ell_i+1)\bmod M}. \tag{15}

   左右值为 2.00 V、2.04 V，走到四分之一处，得到 0.75 × 2.00 + 0.25 × 2.04 = 2.01 V。最后一格的右边接回第一格。

   .. code-block:: python

      def grid_to_time(theta, gamma, w):
          return np.interp(np.remainder(theta, 2*np.pi),
                           np.r_[gamma, 2*np.pi], np.r_[w, w[0]])

      C = grid_to_time(positions[r], gamma, w)
      R = xs[r] - C

   .. figure:: ../../images/K_Diagnostics/k04/r3_10_replay.png
      :name: k04-zh-fig-10
      :width: 100%
      :alt: 图 10　左：在一个时刻读取 θ；中：在 W 上查电压；右：把该电压放到原时刻成为 C。三个紫点对应同一个样本。

      图 10　左：在一个时刻读取 θ；中：在 W 上查电压；右：把该电压放到原时刻成为 C。三个紫点对应同一个样本。

   C 与输入电压长度相同、单位相同。其他九条记录决定一圈的形状，第 0 条自己的节奏决定怎样展开到时间轴。
   从输入减去 C，剩余部分叫 R：

   .. _k04-zh-eq-16:

   .. math::

      R(t_i)=x_{r,i}-C(t_i). \tag{16}

   .. _k04-zh-result:

   .. rubric:: 8. 图中的“误差”到底是谁减谁？

   人工数据让我们知道造数据时放进去的重复形状，记为 :math:`C_{\rm known}`。
   **估计误差 e = 提取的 C − 已知的 C_known**；它与上一节的 **剩余 R = 原电压 − C** 是两回事。
   图 11 中间画 R，最下面画 e，纵轴直接写出相减对象。

   .. _k04-zh-eq-17:

   .. math::

      e_i=C(t_i)-C_{\rm known}(t_i),\qquad\mathrm{RMSE}=\sqrt{\frac1N\sum_{i=0}^{N-1}e_i^2}. \tag{17}

   .. code-block:: python

      C_known = truths[r]  # Used only to check the answer, never to estimate C.
      error = C - C_known
      rmse = np.sqrt(np.mean(error**2))
      print(frequencies[r], H, K_train.min())
      print(rmse)

   本次单通道例子的结果是 f₀ = 39750 Hz、H = 75，训练箱内最少 5566 点。
   对整条 20 ms 的记录，RMSE = **4.934 mV**。
   已知答案只在这一步用于核对，从未参与相位提取、分箱或训练。

   .. figure:: ../../images/K_Diagnostics/k04/r3_11_result.png
      :name: k04-zh-fig-11
      :width: 100%
      :alt: 图 11　上：输入、提取的 C、已知重复形状；中：R = 输入 − C，单位 V；下：e = C − C_known，单位 mV。

      图 11　上：输入、提取的 C、已知重复形状；中：R = 输入 − C，单位 V；下：e = C − C_known，单位 mV。

   实际数据没有 C_known，不能直接算这种误差。可以检查原曲线和提取结果、替换训练记录、改变参数后比较 C 是否稳定。
   X = C + R 总能因相减定义而成立，单靠这个等式不能证明提取得准确。

   .. _k04-zh-meaning:

   .. rubric:: 9. 为什么 R 里还能看出呼吸节奏？

   这张残差图要说明的只有一件事：**减去重复的平均形状，不等于让每个位置的随机起伏一样强。**
   例如某位置的残差交替为 +1、−1，平均为 0；另一位置为 +3、−3，平均也为 0，但起伏明显更大。
   为了量化这种大小，把残差先平方、再平均、最后开方，叫 RMS。这里 θ 仍沿用原数据算出的位置。

   .. _k04-zh-eq-18:

   .. math::

      \overline R_b=\frac1{K_{r,b}}\sum_{i:\,b_{r,i}=b}R(t_i),\qquad R_{{\rm rms},b}=\sqrt{\frac1{K_{r,b}}\sum_{i:\,b_{r,i}=b}R(t_i)^2}. \tag{18}

   .. code-block:: python

      res_sum, res_count = put_into_bins(R, positions[r], B)
      res_square_sum, _ = put_into_bins(R**2, positions[r], B)
      res_mean = res_sum/res_count
      res_rms = np.sqrt(res_square_sum/res_count)

   图 12 只挑第 32 和第 160 箱，它们在一圈中相差半圈。
   左图每个点来自不同周期经过该位置时的残差，紫线是箱内所有点的平均。
   两条平均线都接近 0，但点的散布宽度不同；右图 RMS 约为 0.475 V 和 0.181 V，把这个差别变成数。

   .. figure:: ../../images/K_Diagnostics/k04/r3_12_residual.png
      :name: k04-zh-fig-12
      :width: 100%
      :alt: 图 12　左：每箱只展示前 100 个残差，均值用箱内全部点；右：同样全部点算出的 RMS。宽散布对应更大的 RMS。

      图 12　左：每箱只展示前 100 个残差，均值用箱内全部点；右：同样全部点算出的 RMS。宽散布对应更大的 RMS。

   这个强弱变化是人工数据故意设定的，用来演示“平均形状”和“起伏大小”不同。
   C 提取的是平均形状，R 仍可能受呼吸节奏调制。图 12 不用来衡量 C 的估计误差；误差应看图 11 最下方。
   训练数据有限时，留出记录的箱内均值也不会恰好全为零。

   .. _k04-zh-parameters:

   .. rubric:: 10. 哪些人为选择会影响 C？

   先把本例的选择列全。下面的“更大/更小”均指其他条件尽量不变时；不存在对所有数据都最好的参数。

   .. list-table:: 提取过程中的设置与影响
      :header-rows: 1
      :class: k04-parameters
      :widths: 18 30 52

      * - 选择
        - 本例
        - 对 C 的影响
      * - 重点：谐波上限 f_cut
        - 3 MHz，本条 H = 75
        - 应足够大，以覆盖对目标频段仍有影响的可重复呼吸谐波；它不是高、低频的物理分界。再大的上限也受采样、箱数和平均误差约束，且无法区分其他已锁相的物理过程。
      * - 训练数据
        - 同一位置和工况；共 10 条，每次 9 条训练；整条留出 r
        - 更多相同条件的记录通常减小随机误差；混入漂移或不同形状会使平均失真。代码至少要求 3 条，r 是轮换编号。
      * - 采样与时长
        - fₛ = 8 MHz，N = 160000，T = 20 ms
        - 时长决定 50 Hz 的频点间隔和平均用的周期数。采样率限制可分辨频率；加密插值不能增加原始信息。
      * - 找主频范围
        - 35–45 kHz；整条去均值后找最大幅值平方
        - 过窄可能漏峰，过宽可能选错峰。本例不做频点间峰值插值，主频落在 50 Hz 网格上。
      * - 读相位的频带与形状
        - 正的 25–55 kHz，区间内保留、外面置零
        - 太窄会抹掉节奏变化，太宽会混入其他波动而扰乱相位；陡直边界也可能带来边缘振铃。
      * - 相位约定
        - 同一取角度规则；unwrap 默认以 π 判断跳变；不重设各记录零点
        - 错误跳变或很短的复数箭头使相位不可靠；各记录任意重设零点会把平均形状抹平。
      * - 箱数 B
        - 256，等宽箱；空箱报错
        - 太少会抹平细节，太多使每箱样本变少、均值更易受随机波动影响，甚至出现空箱。
      * - 平均和坐标约定
        - 每个样本等权；箱中心 β；用原电压，保留常数 a₀
        - 按记录等权会改变样本权重；漏掉半箱修正会整体错位。保留常数时 C 含基线，只在算相位时去均值。
      * - 查表网格与插值
        - M = 4096；周期线性插值
        - M 太小会有查值误差；足够大后继续增大收益很小，不能弥补 B 太小或相位算错。
      * - 可选的省点算法
        - 附录 B：频带点数乘 4 后上取 2 的幂；本例 M_base = 4096
        - 决定慢相位插值的密度，太稀会增加误差；主线直接逆 FFT 不用此参数。记录首尾不接续也会影响边缘。

   .. rubric:: 上限应足够大，覆盖仍有影响的呼吸谐波

   在霍尔推力器的探针信号中，我们通常希望 **减去呼吸的重复波形及其高次谐波，保留其他高频波动**，再研究这些高频波动的频谱或色散关系。
   呼吸波形只要不是纯正弦，就会有基频的整数倍成分，即高次谐波；它们可能伸进我们关心的高频段。
   因此，不能简单地把低频都叫呼吸、高频都叫其他波动。这里说的高次谐波，也不等同于另一个物理模态的共振。

   **建议先让上限足够大，覆盖在目标频段仍有意义的可重复谐波，而不要在目标高频段开始处人为截断。**
   例如想研究 0.5–1 MHz，却把上限设为 0.5 MHz，会让更高阶的呼吸谐波留在 R，不能据此把它们认作其他高频波动。
   本例允许到名义 3 MHz，目的就是让高频段中的重复形状也有机会进入 C；实际数据通常没有一条公认的频率线，能标出“从这里起不再考虑呼吸谐波”。

   提高上限，只是让式（13）保留更多阶，其系数仍来自 μ。**与呼吸没有固定相位关系、平均后相消的高频电压，并不会仅仅因为落在上限以内就被减掉。**
   但“足够大”也不是无限增大：采样率、B 和 M 要支持这些阶数，有限数据的平均误差也可能留下假的小系数。

   光滑波形的高阶往往衰减较快，尖峰和陡边却可能留下可见的高阶，因此不能仅凭阶数高就认定振幅一定小。

   .. rubric:: 还有旋转辐条、离子渡越时间振荡时，能再做一次吗？

   **有条件地可以，但必须换成那个振荡自己的相位。** 本页只按呼吸相位求平均，所以不保证自动去掉其他振荡及其谐波。
   若研究目标是更高频的过程，而某个旋转辐条或离子渡越时间相关振荡属于希望排除的部分，可以先从合适的测量信号中取得它自己的周期位置 ψ。
   将本页提取的呼吸波形记为 :math:`C_{\rm breath}`，对第一轮残差 :math:`R_1=X-C_{\rm breath}` 重复“整条记录留出、按 ψ 分箱、求共同形状、重建并相减”，得到 :math:`R_2=R_1-C_{\rm other}`。
   ψ、C_other 分别是该振荡的相位和第二轮学到的波形；原来的 35–45 kHz、25–55 kHz 不能原样照搬。

   这需要该振荡有可追踪的相位、跨记录可重复的形状，并且确实是本次分析希望排除的成分。
   **旋转辐条不一定比呼吸频率高**，两者可能处于相近频段；离子渡越时间相关振荡可以在百 kHz 量级，高于呼吸而低于某些 MHz 量级波动。
   具体频率随装置和工况变化，不能只凭频率给模态命名，更不能把减完后的 R₂ 直接认定为 ECDI（电子回旋漂移不稳定性）。

   如果两个振荡的相位强相关，先减谁可能改变后减谁的结果；第一轮还可能已拿走部分第二个过程。
   此时需要同时利用两个相位的平均模型或空间信息，不能把单相位方法机械串两遍。
   因而“对另一种稳定周期成分再分离一次”可以作为扩展思路，但不是本页已验证的多模态识别算法。

   .. _k04-zh-demo:

   .. rubric:: 附录 A. 人工数据及其全部生成参数

   这段只生成单通道输入和独立核对用的答案。参数是：随机种子 20261004；10 条、8 MHz、每条 160000 点；
   第 j 条主频 40000 + 50(j − 5) Hz，初相位在 −π 到 π 均匀抽取；相位另加幅值 0.18 rad、频率 250 Hz 的缓慢变化。
   重复形状有常数 0.6 V，以及第 1、2、5、12 阶，振幅为 1.8、0.5、0.23、0.07 V，第 2 阶角度为 −0.7 rad，第 5 阶用正弦。
   随机噪声只含 150 kHz–1 MHz，先归一到单位标准差，再乘 0.18 + 0.16[1 + cos(φ − 0.8)] V。
   这就故意让残差在不同呼吸位置有不同强弱。所有这些都是造数据的设定，不能当作实际测量的已知答案。

   .. code-block:: python

      import numpy as np

      def synthetic_data(seed=20261004):
          rng = np.random.default_rng(seed)
          fs, N, J = 8_000_000, 160_000, 10
          t = np.arange(N) / fs
          xs, truths = [], []
          for j in range(J):
              ph = 2*np.pi*(40_000 + 50*(j-5))*t + rng.uniform(-np.pi, np.pi)
              ph += 0.18*np.sin(2*np.pi*250*t)
              known = (0.6 + 1.8*np.cos(ph) + 0.5*np.cos(2*ph-0.7)
                       + 0.23*np.sin(5*ph) + 0.07*np.cos(12*ph))
              noise_F = np.fft.rfft(rng.normal(size=N))
              noise_f = np.fft.rfftfreq(N, 1/fs)
              noise_F[(noise_f < 150e3) | (noise_f > 1e6)] = 0
              noise = np.fft.irfft(noise_F, n=N)
              noise /= np.std(noise)
              strength = 0.18 + 0.16*(1 + np.cos(ph-0.8))
              xs.append(known + strength*noise)
              truths.append(known)
          return t, fs, xs, truths

      t, fs, xs, truths = synthetic_data()

   .. _k04-zh-baseband:

   .. rubric:: 附录 B. 数据很多时，怎样少算一些点？

   数据较多时，可先把窄频带搬到低频，在较少时刻计算相位再还原到原采样点，详见 :doc:`知识点：窄带相位的省点计算 </knowledge/compact_phase>`。


   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">赵隐剑 · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en ap-diagnostics-foundations ap-k04

   .. rubric:: K04: from probe samples to the breathing waveform C

   Electric-propulsion measurements, such as probe signals from a Hall thruster, often show a repeated rise and fall
   called **breathing oscillations**. They are closely tied to the replenishment and ionization of neutral propellant:
   incoming gas is ionized, the supply of neutral atoms falls, ionization weakens, and fresh gas allows it to strengthen again.
   This is a simplified picture of the breathing rhythm. A common frequency range is **10–30 kHz**, or ten to thirty
   thousand cycles per second; the value depends on the thruster and operating conditions.
   Our synthetic example uses about **40 kHz**, with frequency ranges chosen for that example.

   This page extracts the mean waveform that repeats with breathing, so its contribution and the remaining fluctuations
   can be examined separately in spectral analysis. A repeating rise and fall sits underneath irregular fluctuations.
   Our question is: **what voltage typically occurs at the same position in a breathing cycle?**
   Learn that shape from other records and replay it along the current record's timing to obtain C.

   We follow one synthetic dataset through the figures, with Python beside the corresponding equations.

   :ref:`1 Data <k04-en-data>` → :ref:`2 F and frequency <k04-en-frequency>` → :ref:`3 Selected band and z <k04-en-phase>` → :ref:`4 Hold out one record <k04-en-split>` → :ref:`5 S, K, and mu <k04-en-bins>` → :ref:`6 a and W <k04-en-template>` → :ref:`7 Obtain C <k04-en-replay>` → :ref:`8 Check error <k04-en-result>` → :ref:`9 Interpret R <k04-en-meaning>` → :ref:`10 Chosen parameters <k04-en-parameters>`

   Run :ref:`Appendix A <k04-en-demo>` to create the data, then run Sections 2–10 in order. Only NumPy is required.

   For runnable examples, automated tests, and Figure 1–12 regeneration, see
   :doc:`K04 code and running guide </tests/011_K04_breathing_waveform/index>`.

   .. _k04-en-data:

   .. rubric:: 1. What numbers do we start with?

   Use **one probe at one spatial point**, measured repeatedly. Each acquisition supplies one voltage record.
   Sample i of record j is :math:`x_{j,i}`, written ``xs[j][i]`` in Python.
   The arrays already contain usable voltages in V. Keep the measurement position and operating conditions unchanged across records.

   The synthetic data contain **10 records, each with N = 160,000 samples**, sampled at :math:`f_s=8\,000\,000` samples/s (8 MHz).
   Each lasts :math:`T=N/f_s=20` ms. ``xs[0]`` through ``xs[9]`` are separate acquisitions; j and i start at zero.
   Equation (1) supplies the times. Figure 1 labels the voltage axis as ``xs[0][i]`` for record 0.

   .. _k04-en-eq-1:

   .. math::

      t_i=i/f_s,\qquad i=0,\ldots,N-1. \tag{1}

   .. figure:: ../../images/K_Diagnostics/k04/r3_01_x.png
      :name: k04-en-fig-1
      :width: 100%
      :alt: Figure 1. Gray is the input xs[0]; orange is the repeating shape specified by the generator, used only for checking. The view spans 150 microseconds; calculations use 20 ms.

      Figure 1. Gray is the input xs[0]; orange is the repeating shape specified by the generator, used only for checking. The view spans 150 microseconds; calculations use 20 ms.

   Figure 1 shows varying details around a common shape. Learn the shape from records 1–9, then reconstruct C for record 0.

   .. _k04-en-frequency:

   .. rubric:: 2. Inspect F and find the repetition rate

   40 kHz means about 40,000 cycles per second, or 25 microseconds per cycle.
   Take ``x = xs[0]``, subtract its mean, and compute the :doc:`FFT (background explanation here) </knowledge/fft>`.
   FFT expresses the record through frequency components: coefficient :math:`F_k` corresponds to frequency :math:`f[k]`.

   **k indexes the frequency array**, from 0 to N − 1: ``F[k]`` and ``f[k]`` in Python. It is neither a frequency value nor a wavenumber.
   i indexes time samples; k indexes frequency bins. k = 0 is zero frequency. For positive-frequency bins, :math:`f[k]=kf_s/N`; here k = 1 means 50 Hz.
   Equation (2) fixes one k and sums contributions from every time sample i to obtain that frequency coefficient.
   Array entry ``f[0]`` differs from the breathing-frequency estimate ``f0`` (written :math:`f_0`) found below.

   .. _k04-en-eq-2:

   .. math::

      \bar x=\frac1N\sum_{i=0}^{N-1}x_{0,i},\qquad F_k=\sum_{i=0}^{N-1}(x_{0,i}-\bar x)e^{-2\pi\mathrm{i}ki/N}. \tag{2}

   The upright :math:`\mathrm{i}` is the imaginary unit, written ``1j`` in Python; subscript i remains the sample index.
   ``fftfreq`` supplies each coefficient's frequency, ordered as zero and positive frequencies followed by negative frequencies.
   F is complex, so one real-valued curve cannot show it completely. Figure 2 plots its magnitude :math:`|F_k|/N`.
   Division by N only sets a readable display scale; finding the peak of :math:`|F_k|^2` gives the same location.

   .. code-block:: python

      def find_frequency(x, fs, search=(35e3, 45e3)):
          x = np.asarray(x, dtype=float)
          lo, hi = search
          if x.ndim != 1 or x.size < 2 or not np.isfinite(x).all():
              raise ValueError("Expected a finite 1D record")
          if not 0 < lo < hi < fs/2:
              raise ValueError("Search band must lie below fs/2")
          F = np.fft.fft(x - x.mean())
          f = np.fft.fftfreq(x.size, d=1/fs)
          candidates = np.flatnonzero((f >= lo) & (f <= hi))
          if candidates.size == 0:
              raise ValueError("No frequency points in search band")
          k0 = candidates[np.argmax(np.abs(F[candidates])**2)]
          return F, f, float(f[k0])

      F, f, f0 = find_frequency(xs[0], fs)

   Search only **35–45 kHz** around the known approximate breathing rate in this example, avoiding other components.
   Figure 2 gives :math:`f_0=39.75` kHz, with :math:`f_s/N=50` Hz spacing.
   Other peaks in the left panel are still present in F at this stage.

   .. figure:: ../../images/K_Diagnostics/k04/r3_02_F.png
      :name: k04-en-fig-2
      :width: 100%
      :alt: Figure 2. Magnitude of F versus frequency, showing positive frequencies. Numbers mark the fundamental and peaks near 2, 5, and 12 times it; the right panel enlarges the search range.

      Figure 2. Magnitude of F versus frequency, showing positive frequencies. Numbers mark the fundamental and peaks near 2, 5, and 12 times it; the right panel enlarges the search range.

   .. _k04-en-phase:

   .. rubric:: 3. Build z, then read each sample’s cycle position

   The main frequency estimates cycle duration, but not the starting position or changes in rhythm.
   Keep only the positive **25–55 kHz** band around it and set every other coefficient to zero.
   Call the selected coefficients :math:`\widehat F_k`, or ``F_hat`` in code; leave the original F unchanged.

   .. _k04-en-eq-3:

   .. math::

      \widehat F_k=\begin{cases}F_k,&25\,000\le f[k]\le55\,000\ \mathrm{Hz},\\0,&\text{otherwise}.\end{cases} \tag{3}

   Figure 3 shows equation (3): purple coefficients remain only in positive 25–55 kHz; negative frequencies and other peaks are zero.

   .. figure:: ../../images/K_Diagnostics/k04/r3_03_Fhat.png
      :name: k04-en-fig-3
      :width: 100%
      :alt: Figure 3. Gray is the original F magnitude and purple the selected F-hat magnitude. Shading marks the retained band. Both are divided by N for display.

      Figure 3. Gray is the original F magnitude and purple the selected F-hat magnitude. Shading marks the retained band. Both are divided by N for display.

   Inverse FFT of this new spectrum gives the complex time series z in equation (4). The inverse transform turns frequency coefficients back into time samples.

   .. _k04-en-eq-4:

   .. math::

      z(t_i)=\frac1N\sum_{k=0}^{N-1}\widehat F_k e^{2\pi\mathrm{i}ki/N}. \tag{4}

   k in equation (4) is the same frequency index. Now fix time sample i and sum over k; coefficients set to zero contribute nothing.

   .. code-block:: python

      def make_complex_signal(F, f, band=(25e3, 55e3)):
          lo, hi = band
          if not 0 < lo < hi <= np.max(f):
              raise ValueError("Choose a positive band below fs/2")
          keep = (f >= lo) & (f <= hi)
          F_hat = np.where(keep, F, 0.0)
          if not np.any(np.abs(F_hat) > 0):
              raise ValueError("No signal from which to read phase")
          z = np.fft.ifft(F_hat)
          return F_hat, z

      F_hat, z = make_complex_signal(F, f)

   A complex number is an arrow: real part horizontally, imaginary part vertically. Its angle is **phase**.
   Why do the components in Figure 4 resemble cosine and sine? We retained only a narrow band around the fundamental.
   For :math:`A\cos(\omega t+\alpha)`, A is amplitude, :math:`\omega=2\pi f_0`, and alpha is the starting angle.
   First write the full cosine as positive- and negative-frequency terms, then keep the positive one in equation (5). Each term has coefficient A/2:

   .. _k04-en-eq-5:

   .. math::

      \begin{aligned}
            A\cos(\omega t+\alpha)&=\underbrace{\frac A2e^{\mathrm{i}(\omega t+\alpha)}}_{+f_0}
            +\underbrace{\frac A2e^{-\mathrm{i}(\omega t+\alpha)}}_{-f_0},\\
            z(t)&=\frac A2e^{\mathrm{i}(\omega t+\alpha)}\\
            &=\frac A2\cos(\omega t+\alpha)+\mathrm{i}\frac A2\sin(\omega t+\alpha).
            \end{aligned} \tag{5}

   The second line follows removal of the negative-frequency term. This page keeps coefficients without doubling the positive term, so z has amplitude A/2.

   The components differ by a quarter turn. Actual z contains multiple nearby frequencies, so its amplitude and rotation speed can vary.
   **z supplies cycle-position labels; it is not the desired C.** Repeating sharp or asymmetric details will be learned later from the original voltages.

   .. figure:: ../../images/K_Diagnostics/k04/r3_04_z.png
      :name: k04-en-fig-4
      :width: 100%
      :alt: Figure 4. Left: real and imaginary parts of z(t_i). Right: their trajectory in the complex plane; the arrow points from the origin to one sample.

      Figure 4. Left: real and imaginary parts of z(t_i). Right: their trajectory in the complex plane; the arrow points from the origin to one sample.

   ``np.angle`` returns angles near −pi to pi. Continuous rotation might produce ``2.80, 3.05, -3.00, -2.75``;
   ``unwrap`` adds 2pi to the last two values to give ``2.80, 3.05, 3.283, 3.533``.
   Call the accumulated angle phi, and its remainder after division by 2pi theta, the position within one turn.

   .. _k04-en-eq-6:

   .. math::

      \phi_i=\operatorname{unwrap}(\arg z_i),\qquad\theta_i=\phi_i\bmod2\pi. \tag{6}

   .. code-block:: python

      def mark_position(z):
          angle = np.angle(z)
          phi = np.unwrap(angle)
          theta = np.remainder(phi, 2*np.pi)
          return phi, theta

      phi, theta = mark_position(z)

   .. figure:: ../../images/K_Diagnostics/k04/r3_05_phase.png
      :name: k04-en-fig-5
      :width: 100%
      :alt: Figure 5. Left: accumulated turns from phi, shifted by an integer only for display. Right: theta keeps the position within one turn and wraps to zero after each cycle.

      Figure 5. Left: accumulated turns from phi, shifted by an integer only for display. Right: theta keeps the position within one turn and wraps to zero after each cycle.

   One turn is 2pi radians; theta/(2pi) = 0.25 is a quarter turn.
   Use the same angle convention for every record. Do not subtract each record's initial phase: that would mistake arbitrary acquisition starts for the same breathing position.

   .. _k04-en-split:

   .. rubric:: 4. Label all records, then hold out the current one

   Repeat the calculation for the other nine records, each with its own main frequency and position array.
   Set r = 0 for reconstruction. It supplies its timing, but none of its voltages enters the learned mean shape.
   Figure 6 shows records 1–3: their peaks differ in time but align when plotted against cycle position.

   .. code-block:: python

      frequencies, positions = [], []
      for xj in xs:
          Fj, fj, f0j = find_frequency(xj, fs)
          _, zj = make_complex_signal(Fj, fj)
          _, theta_j = mark_position(zj)
          frequencies.append(f0j)
          positions.append(theta_j)
      r = 0  # Learn the shape from records 1-9; reconstruct record 0.

   .. figure:: ../../images/K_Diagnostics/k04/r3_06_fold.png
      :name: k04-en-fig-6
      :width: 100%
      :alt: Figure 6. Left: three training records in time. Right: the samples plotted at their own theta/(2pi). Only a subset is drawn; all samples enter the calculation.

      Figure 6. Left: three training records in time. Right: the samples plotted at their own theta/(2pi). Only a subset is drawn; all samples enter the calculation.

   Exclude the **whole record**. For record 1, learn from records 0, 2, …, 9.
   This is **leave-one-record-out cross-fitting**: a record's own accidental fluctuations do not directly train its shape.

   .. _k04-en-bins:

   .. rubric:: 5. Group equal cycle positions: define S and K, then mu

   Two samples rarely have exactly the same angle. Divide a turn into B = 256 **phase bins**, numbered b = 0,…,255.
   Equation (7) assigns each sample to a bin; the floor symbol takes the integer part.

   .. _k04-en-eq-7:

   .. math::

      b_{j,i}=\left\lfloor\frac{B\theta_{j,i}}{2\pi}\right\rfloor. \tag{7}

   Here :math:`\theta_{j,i}` **is theta from equation (6)**, with j added to identify record j and sample i.
   Multiply this cycle position by B/(2pi), then take the floor to obtain a bin index. For B = 256 and theta = pi, the bin index is 128.

   Two different quantities are needed: :math:`K_{j,b}` is the **number of samples from record j in bin b**;
   :math:`S_{j,b}` is the **sum of their voltages**. The sums in equation (8) run only over indices i assigned to that bin:

   .. _k04-en-eq-8:

   .. math::

      K_{j,b}=\sum_{i:\,b_{j,i}=b}1,\qquad S_{j,b}=\sum_{i:\,b_{j,i}=b}x_{j,i}. \tag{8}

   **Equation (8) uses the original input voltage** :math:`x_{j,i}`, or ``xs[j][i]``, including its original mean and all fluctuations; it is neither band-selected z nor the real part of z.
   The earlier band selection only found each sample's theta. Use theta to choose the bin, then add the original voltage to S.

   For example, voltages 1.5 V and 2.5 V in one bin give K = 2 and S = 4 V. S is a sum, not an average.

   .. code-block:: python

      def put_into_bins(x, theta, B=256):
          x, theta = np.asarray(x), np.asarray(theta)
          if x.ndim != 1 or x.shape != theta.shape:
              raise ValueError("Voltage and phase must be aligned 1D arrays")
          b = np.floor(np.remainder(theta, 2*np.pi)*B/(2*np.pi)).astype(int)
          b = np.minimum(b, B-1)
          S = np.bincount(b, weights=x, minlength=B)
          K = np.bincount(b, minlength=B)
          return S, K

      B = 256
      sums, counts = [], []
      for xj, theta_j in zip(xs, positions):
          Sj, Kj = put_into_bins(xj, theta_j, B)
          sums.append(Sj)
          counts.append(Kj)

   ``bincount`` counts samples by bin; ``weights=x`` sums voltages instead.
   **Bin the original voltage; z only supplies position labels.** Exclude r, pool voltage sums and counts separately, then divide:

   .. _k04-en-eq-9:

   .. math::

      \mu_{-r,b}=\frac{\sum_{j\ne r}S_{j,b}}{\sum_{j\ne r}K_{j,b}}. \tag{9}

   Mu is a mean voltage; subscript −r means omit record r. If one record supplies S = 4 V, K = 2 and another S = 18 V, K = 6,
   the pooled mean is 22/8 = 2.75 V, not the equal-record average of 2 and 3. Each sample contributes equally.

   .. code-block:: python

      def mean_other_records(sums, counts, r):
          if len(sums) < 3 or not 0 <= r < len(sums):
              raise ValueError("Use at least 3 complete records")
          S_train = np.sum([s for j, s in enumerate(sums) if j != r], axis=0)
          K_train = np.sum([k for j, k in enumerate(counts) if j != r], axis=0)
          if np.any(K_train == 0):
              raise ValueError("Empty phase bin: check data coverage")
          return S_train/K_train, K_train

      mu, K_train = mean_other_records(sums, counts, r)

   Figure 7 now shows mu: 256 mean voltages around a cycle, not yet a continuous curve. The right panel counts the points used for each mean.

   .. figure:: ../../images/K_Diagnostics/k04/r3_07_mu.png
      :name: k04-en-fig-7
      :width: 100%
      :alt: Figure 7. Left: mu for held-out record 0 versus bin center. Right: pooled counts from records 1–9. A bin center lies at (b + 1/2)/B turns.

      Figure 7. Left: mu for held-out record 0 versus bin center. Right: pooled counts from records 1–9. A bin center lies at (b + 1/2)/B turns.

   The repeating shape survives averaging; fluctuations with changing signs partly cancel. An empty bin raises an error rather than being treated as zero volts.

   .. _k04-en-template:

   .. rubric:: 6. From mu to a_n, then to the cycle curve W

   Mu already gives mean voltages, but only at 256 discrete positions. Two tasks remain: **choose which harmonics to retain, and evaluate the shape at arbitrary cycle positions**.
   Decompose mu into coefficients a_n, select orders using the cutoff, then recombine them into the periodic curve W. This controls retained detail and prepares evaluation along the time record.

   A cycle shape can be expressed as a sum of sines and cosines: one oscillation within a turn is order 1, two is order 2.
   These are **harmonics**. Place each bin mean at its center beta, an angle in radians, then compute coefficient a_n for order n.

   .. _k04-en-eq-10:

   .. math::

      \beta_b=\frac{2\pi(b+1/2)}B,\qquad b=0,\ldots,B-1. \tag{10}

   .. _k04-en-eq-11:

   .. math::

      a_n=\frac1B\sum_{b=0}^{B-1}\mu_{-r,b}e^{-\mathrm{i}n\beta_b}. \tag{11}

   .. code-block:: python

      def mean_to_coefficients(mu):
          B = len(mu)
          n = np.arange(B//2 + 1)
          return np.fft.rfft(mu)/B * np.exp(-1j*n*np.pi/B)

      a = mean_to_coefficients(mu)

   Each ``a[n]`` is complex and stores both size and shift of that order. Figure 8 shows its real and imaginary parts, then positive-order amplitude 2|a_n|.
   a_0 is the constant voltage; positive order n has amplitude 2|a_n| and angle arg a_n.
   ``exp(-1j*n*pi/B)`` corrects the FFT's left-edge coordinates to the bin centers in equation (10).

   .. figure:: ../../images/K_Diagnostics/k04/r3_08_a.png
      :name: k04-en-fig-8
      :width: 100%
      :alt: Figure 8. Real and imaginary parts of a_n, and positive-order amplitudes. The logarithmic right axis reveals small higher-order coefficients; the next step chooses which orders to retain.

      Figure 8. Real and imaginary parts of a_n, and positive-order amplitudes. The logarithmic right axis reveals small higher-order coefficients; the next step chooses which orders to retain.

   Choose a nominal frequency limit :math:`f_{\rm cut}`, set to 3 MHz here. It allows higher breathing harmonics in the template; it does not remove every fluctuation below 3 MHz.
   Estimate the frequency of order n as :math:`nf_{0,r}`,
   giving maximum retained order H:

   .. _k04-en-eq-12:

   .. math::

      H=\left\lfloor f_{\rm cut}/f_{0,r}\right\rfloor. \tag{12}

   39.75 kHz gives H = 75: order 75 is about 2.98125 MHz and order 76 about 3.021 MHz.
   Sum the retained orders to obtain W(theta), the mean cycle shape. Re takes the real part; the factor 2 combines paired positive and negative orders.

   .. _k04-en-eq-13:

   .. math::

      W(\theta)=a_0+2\operatorname{Re}\sum_{n=1}^H a_n e^{\mathrm{i}n\theta}. \tag{13}

   For convenient lookup, sample one turn at M = 4096 equally spaced positions. **Gamma_l is the phase angle at lookup index l**;
   w_l is W evaluated there. Equation (14) defines computed lookup points, not new measurements:

   .. _k04-en-eq-14:

   .. math::

      \gamma_\ell=\frac{2\pi\ell}M,\quad w_\ell=W(\gamma_\ell),\qquad\ell=0,\ldots,M-1. \tag{14}

   For example, gamma_0 = 0 and gamma_1 = 2pi/4096; the last point is one step short of 2pi.
   Beta_b locates the original 256 bin centers, whereas gamma_l locates the later 4096 lookup points.

   .. code-block:: python

      def coefficients_to_grid(a, f0, fs, cutoff=3e6, M=4096):
          if not 0 < cutoff < fs/2 or f0 <= 0:
              raise ValueError("Nominal cutoff must be positive and below fs/2")
          H = int(np.floor(cutoff/f0))
          if H >= len(a)-1 or 2*H >= M:
              raise ValueError("Increase phase bins/grid, or lower the cutoff")
          gamma = 2*np.pi*np.arange(M)/M
          n = np.arange(1, H+1)
          waves = np.exp(1j*np.outer(gamma, n))
          w = a[0].real + 2*np.real(waves @ a[n])
          return gamma, w, H

      gamma, w, H = coefficients_to_grid(a, frequencies[r], fs)

   Figure 9 places mu and W together, then zooms into five consecutive lookup points, labeled with index l.
   More lookup points refine interpolation but cannot recover detail already lost in bin averaging.

   .. figure:: ../../images/K_Diagnostics/k04/r3_09_W.png
      :name: k04-en-fig-9
      :width: 100%
      :alt: Figure 9. Left: bin means mu and curve W. Right: gamma_l/(2pi) = l/M on the horizontal axis and w_l on the vertical axis explain the lookup arrays.

      Figure 9. Left: bin means mu and curve W. Right: gamma_l/(2pi) = l/M on the horizontal axis and w_l on the vertical axis explain the lookup arrays.

   Mu and W nearly overlap in Figure 9 because W represents the shape learned in mu.
   **Equation (11) is a discrete Fourier transform across phase bins, computed by FFT; equation (13) synthesizes the selected orders, equivalent to a truncated inverse transform.**
   Keeping the complete discrete-transform coefficients with consistent coordinates and normalization recovers mu at the original bin centers. Here only orders 1 through H and the constant are retained, so agreement is generally approximate.
   Most of this example's shape lies at low orders; the omitted higher orders are too small for an obvious visual difference.

   This step turns **256 means into a periodic function with controlled harmonic content that can be evaluated at any phase**; it does not discover an independent dataset.
   Direct periodic interpolation of mu would also allow lookup, but without this explicit harmonic truncation. Increasing M alone adds no measured information.
   Here n counts oscillations within one breathing cycle; it differs from k, the frequency-bin index for the full time record in equation (2).

   .. _k04-en-replay:

   .. rubric:: 7. Look up W along the current record to obtain C

   Take ``positions[0]``. At each time, read theta, look up its voltage on W, and assign that voltage to the same time.
   The three purple points in Figure 10 show one lookup. Between grid points, blend neighbors according to distance: **linear interpolation**.

   Let u = Mtheta/(2pi), left index l = floor(u), and fraction lambda = u − l. Then:

   .. _k04-en-eq-15:

   .. math::

      C(t_i)=(1-\lambda_i)w_{\ell_i}+\lambda_i w_{(\ell_i+1)\bmod M}. \tag{15}

   One quarter of the way between 2.00 and 2.04 V gives 0.75 × 2.00 + 0.25 × 2.04 = 2.01 V. The last grid point connects back to the first.

   .. code-block:: python

      def grid_to_time(theta, gamma, w):
          return np.interp(np.remainder(theta, 2*np.pi),
                           np.r_[gamma, 2*np.pi], np.r_[w, w[0]])

      C = grid_to_time(positions[r], gamma, w)
      R = xs[r] - C

   .. figure:: ../../images/K_Diagnostics/k04/r3_10_replay.png
      :name: k04-en-fig-10
      :width: 100%
      :alt: Figure 10. Read theta at a time, find its voltage on W, then assign the voltage to C at that time. All three purple points correspond to the same sample.

      Figure 10. Read theta at a time, find its voltage on W, then assign the voltage to C at that time. All three purple points correspond to the same sample.

   C has the same length and voltage units as the input. The other nine records determine the shape; record 0 determines its timing.
   Subtract C from the input to define the remainder R:

   .. _k04-en-eq-16:

   .. math::

      R(t_i)=x_{r,i}-C(t_i). \tag{16}

   .. _k04-en-result:

   .. rubric:: 8. What exactly does “error” subtract?

   Synthetic data provide the generator's repeating shape, :math:`C_{\rm known}`.
   **Estimation error e = extracted C − known C_known**, whereas **remainder R = input voltage − C**.
   Figure 11 plots R in the middle and e at the bottom, with the subtraction written on each axis.

   .. _k04-en-eq-17:

   .. math::

      e_i=C(t_i)-C_{\rm known}(t_i),\qquad\mathrm{RMSE}=\sqrt{\frac1N\sum_{i=0}^{N-1}e_i^2}. \tag{17}

   .. code-block:: python

      C_known = truths[r]  # Used only to check the answer, never to estimate C.
      error = C - C_known
      rmse = np.sqrt(np.mean(error**2))
      print(frequencies[r], H, K_train.min())
      print(rmse)

   This single-channel example gives f0 = 39750 Hz, H = 75, and at least 5566 training samples per bin.
   Whole-record RMSE over 20 ms is **4.934 mV**.
   The known answer is used only for this check, never for phase extraction, binning, or training.

   .. figure:: ../../images/K_Diagnostics/k04/r3_11_result.png
      :name: k04-en-fig-11
      :width: 100%
      :alt: Figure 11. Top: input, extracted C, and known repeating shape. Middle: R = input − C in V. Bottom: e = C − C_known in mV.

      Figure 11. Top: input, extracted C, and known repeating shape. Middle: R = input − C in V. Bottom: e = C − C_known in mV.

   Measured data lack C_known, so this error is unavailable. Inspect the curves and compare C across training subsets and parameter choices.
   X = C + R follows from subtraction alone and cannot prove accurate extraction.

   .. _k04-en-meaning:

   .. rubric:: 9. Why can R still follow the breathing rhythm?

   The residual figure has one purpose: **removing the repeating mean shape does not make random fluctuations equally strong at every position.**
   Alternating +1 and −1 have mean zero; +3 and −3 also have mean zero but fluctuate more strongly.
   To measure size, square the residuals, average, and take a square root: RMS. Keep the positions computed from the original data.

   .. _k04-en-eq-18:

   .. math::

      \overline R_b=\frac1{K_{r,b}}\sum_{i:\,b_{r,i}=b}R(t_i),\qquad R_{{\rm rms},b}=\sqrt{\frac1{K_{r,b}}\sum_{i:\,b_{r,i}=b}R(t_i)^2}. \tag{18}

   .. code-block:: python

      res_sum, res_count = put_into_bins(R, positions[r], B)
      res_square_sum, _ = put_into_bins(R**2, positions[r], B)
      res_mean = res_sum/res_count
      res_rms = np.sqrt(res_square_sum/res_count)

   Figure 12 picks bins 32 and 160, half a turn apart.
   Each left-panel point is a residual from a different cycle at that position; purple lines are means of all samples in each bin.
   Both means are near zero, but the scatter widths differ. RMS values of about 0.475 V and 0.181 V quantify that difference on the right.

   .. figure:: ../../images/K_Diagnostics/k04/r3_12_residual.png
      :name: k04-en-fig-12
      :width: 100%
      :alt: Figure 12. Left: first 100 residual samples per bin; means use all samples in each bin. Right: RMS also uses all samples. Wider scatter corresponds to larger RMS.

      Figure 12. Left: first 100 residual samples per bin; means use all samples in each bin. Right: RMS also uses all samples. Wider scatter corresponds to larger RMS.

   The generator deliberately varies fluctuation strength to distinguish it from mean shape.
   C extracts the mean shape, while R can still be modulated by the breathing rhythm. Figure 12 does not measure C's estimation error; that is the bottom of Figure 11.
   Finite training data also mean the held-out bin means need not be exactly zero.

   .. _k04-en-parameters:

   .. rubric:: 10. Which choices affect C?

   Here are the choices used in this example. Effects assume other conditions stay approximately fixed; no setting is best for every dataset.

   .. list-table:: Extraction settings and their effects
      :header-rows: 1
      :class: k04-parameters
      :widths: 18 30 52

      * - Choice
        - Here
        - Effect on C
      * - Key choice: harmonic limit f_cut
        - 3 MHz, H = 75 here
        - Use a limit high enough to cover repeatable breathing harmonics that still affect the band of interest. It is not a physical low/high-frequency boundary. Sampling, bins, averaging error, and other phase-locked processes still limit interpretation.
      * - Training data
        - Same location/conditions; 10 records, 9 for training; hold out whole r
        - More comparable records usually reduce sampling error; drift or different shapes bias the mean. Code requires at least 3 records; r rotates.
      * - Sampling and duration
        - fs = 8 MHz, N = 160000, T = 20 ms
        - Duration sets 50 Hz spacing and available cycles. Sampling limits resolvable frequencies; interpolation adds no measured information.
      * - Peak search
        - 35–45 kHz; demean full record, maximize squared magnitude
        - Too narrow can miss the peak; too broad can select another component. No between-bin peak interpolation: frequency lies on the 50 Hz grid.
      * - Phase band and filter shape
        - Positive 25–55 kHz, hard keep/zero mask
        - Too narrow loses timing variation; too broad admits other fluctuations and corrupts phase. Sharp band edges can cause ringing.
      * - Phase convention
        - Common angle rule; unwrap uses its default pi threshold; retain record origins
        - Incorrect unwrap or near-zero arrow length makes phase unreliable. Arbitrarily resetting each origin smears the learned shape.
      * - Bin count B
        - 256 equal bins; empty bins raise an error
        - Too few smooth detail; too many reduce samples per bin, increasing variability and potentially creating empty bins.
      * - Averaging and coordinates
        - Equal sample weights; centers beta; raw voltage retains constant a0
        - Equal-record weights change the estimator. Omitting the half-bin correction shifts the curve. C includes the baseline; only the phase FFT is demeaned.
      * - Lookup grid and interpolation
        - M = 4096; periodic linear interpolation
        - Small M causes lookup error. Once dense enough, larger M adds little and cannot repair coarse bins or wrong phase.
      * - Optional compact evaluation
        - Appendix B: next power of two of 4 times band count; M_base = 4096
        - Controls slow-phase interpolation density; too sparse adds error. The direct main path does not use it. Record-end mismatch can affect edges.

   .. rubric:: Use a cutoff high enough to cover breathing harmonics that still matter

   For Hall-thruster probe signals, the usual aim is to **subtract the repeatable breathing waveform and its higher harmonics while retaining other high-frequency fluctuations** for spectral or dispersion analysis.
   A breathing waveform that is not a pure sinusoid contains integer multiples of its fundamental: higher harmonics that can extend into the frequency bands of interest.
   Frequency alone therefore cannot identify breathing versus other fluctuations. A higher harmonic is also not, by itself, evidence of a separate physical resonance.

   **Start with a cutoff high enough to cover repeatable harmonics that matter in the target band; do not truncate merely where that high-frequency band begins.**
   For example, studying 0.5–1 MHz with a 0.5 MHz cutoff leaves higher breathing harmonics in R; their presence there does not identify them as other high-frequency fluctuations.
   The nominal 3 MHz limit here lets repeatable structure in higher bands enter C. Measured data generally provide no universal frequency boundary above which breathing harmonics can be ignored.

   Raising the cutoff retains more orders in equation (13), with coefficients still learned from mu. **High-frequency voltages that lack a fixed phase relation to breathing and cancel in the mean are not removed merely because they fall below the cutoff.**
   A sufficiently high limit is not an unlimited one: sampling, B, and M must support the orders, and finite averaging can leave spurious small coefficients.

   Higher harmonics of smooth waveforms often decay rapidly, but sharp peaks and edges can retain visible higher-order content; high order alone does not guarantee a small amplitude.

   .. rubric:: Can the procedure be repeated for rotating spokes or ion transit-time oscillations?

   **Conditionally yes, but use that oscillation's own phase.** This page averages only by breathing phase and does not automatically remove other oscillations and their harmonics.
   If the research target is a higher-frequency process and a spoke or ion transit-time-related oscillation is unwanted, first obtain its own cycle position psi from an appropriate measured signal.
   Write the breathing waveform extracted on this page as :math:`C_{\rm breath}`. On the first residual :math:`R_1=X-C_{\rm breath}`, repeat whole-record holdout, binning by psi, mean-shape estimation, reconstruction, and subtraction to get :math:`R_2=R_1-C_{\rm other}`.
   Psi and C_other denote the second oscillation's phase and learned waveform. Do not reuse the 35–45 kHz and 25–55 kHz bands unchanged.

   This requires a trackable phase, a shape repeatable across records, and a reason to exclude that component from the present analysis.
   **Rotating spokes are not necessarily faster than breathing**; their bands can overlap. Ion transit-time-related oscillations can occur at hundreds of kHz, above breathing but below some MHz-scale fluctuations.
   Frequencies depend on the device and operating state. Frequency alone does not identify a mode, and the final R_2 is not automatically ECDI (electron cyclotron drift instability).

   If the two phases are strongly related, subtraction order can change the result, and the first pass may already remove part of the second process.
   A model using both phases together or spatial information may then be needed, rather than mechanically chaining two single-phase fits.
   Repeating the procedure for another stable periodic component is therefore an extension to investigate, not a validated multimode identification algorithm in this page.

   .. _k04-en-demo:

   .. rubric:: Appendix A. Synthetic data and their generation settings

   This generates single-channel input and independent checking truth. Settings are: seed 20261004; 10 records, 8 MHz, 160000 samples each;
   record-j frequency 40000 + 50(j − 5) Hz; uniform initial angle from −pi to pi; additional phase modulation of 0.18 rad at 250 Hz.
   The repeating shape has a 0.6 V baseline and orders 1, 2, 5, 12 with amplitudes 1.8, 0.5, 0.23, 0.07 V; order 2 has angle −0.7 rad and order 5 uses sine.
   Random noise occupies 150 kHz–1 MHz, is normalized to unit standard deviation, then multiplied by 0.18 + 0.16[1 + cos(phi − 0.8)] V.
   This deliberately changes residual strength with breathing position. These are generator settings, not known answers for measured data.

   .. code-block:: python

      import numpy as np

      def synthetic_data(seed=20261004):
          rng = np.random.default_rng(seed)
          fs, N, J = 8_000_000, 160_000, 10
          t = np.arange(N) / fs
          xs, truths = [], []
          for j in range(J):
              ph = 2*np.pi*(40_000 + 50*(j-5))*t + rng.uniform(-np.pi, np.pi)
              ph += 0.18*np.sin(2*np.pi*250*t)
              known = (0.6 + 1.8*np.cos(ph) + 0.5*np.cos(2*ph-0.7)
                       + 0.23*np.sin(5*ph) + 0.07*np.cos(12*ph))
              noise_F = np.fft.rfft(rng.normal(size=N))
              noise_f = np.fft.rfftfreq(N, 1/fs)
              noise_F[(noise_f < 150e3) | (noise_f > 1e6)] = 0
              noise = np.fft.irfft(noise_F, n=N)
              noise /= np.std(noise)
              strength = 0.18 + 0.16*(1 + np.cos(ph-0.8))
              xs.append(known + strength*noise)
              truths.append(known)
          return t, fs, xs, truths

      t, fs, xs, truths = synthetic_data()

   .. _k04-en-baseband:

   .. rubric:: Appendix B. How can we evaluate fewer time points?

   For large records, shift the narrow band to low frequencies, evaluate phase at fewer times, and restore the original sampling grid; see :doc:`Knowledge note: fewer-point evaluation of narrowband phase </knowledge/compact_phase>`.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Yinjian ZHAO · Harbin Institute of Technology</p>
      </div>
