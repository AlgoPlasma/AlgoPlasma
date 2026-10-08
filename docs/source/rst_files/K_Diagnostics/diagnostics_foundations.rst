=============================
Probe Diagnostics Foundations
=============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-diagnostics-foundations

   .. rubric:: 探针诊断基础：从两路波形到波的频率、波长与传播方向

   FFT 和谱泄漏的独立解释收录在全库的
   :doc:`知识点目录 </knowledge/index>`，可从本页的边框内进入，读完再返回当前章节。

   本页从正弦函数开始，不要求你已经学过 FFT、复数谱或最大似然。目标是让你能解释
   ``K_Diagnostics`` 为什么这样计算、每一步得到什么，再去读
   :doc:`Diagnostics Learning Path <diagnostics_learning_path>` 和函数页。
   可以按顺序阅读，也可以回到需要补充的部分：

   :ref:`1. 诊断目的 <foundations-zh-purpose>` ·
   :ref:`2. 波的基础 <foundations-zh-wave>` ·
   :ref:`3. 双探针相位 <foundations-zh-pair>` ·
   :ref:`4. 频谱与复数 <foundations-zh-spectrum>` ·
   :ref:`5. 分段与噪声 <foundations-zh-noise>` ·
   :ref:`6. 混叠与 Beall 谱 <foundations-zh-alias>` ·
   :ref:`7. 多构型反演 <foundations-zh-inversion>` ·
   :ref:`8. 对应代码与后续阅读 <foundations-zh-next>`

   .. _foundations-zh-purpose:

   .. rubric:: 1. 这个诊断要做什么？

   假设实验中有两根探针，或者模拟中有两个固定的采样点。它们同时记录同一种随时间波动的量，
   例如电势扰动。我们得到两列数 :math:`x_1[n]` 和 :math:`x_2[n]`，其中 :math:`n` 是采样序号。
   看曲线可以发现“它在振荡”，但研究问题通常更具体：主要有多快的振荡？波长多大？
   相位朝哪个方向传播？不同频率对应什么波数？

   **诊断就是用这些记录估计波动的性质。** 它需要两路同步记录、采样率和探针的位置；
   二维波矢反演还需要多个探针构型。这里的探针只代表一个采样位置，算法不模拟探针硬件。
   实验中两路通道的响应差异或时钟误差也可能造成相位差，需要调用者先处理。

   .. list-table:: 从观测到问题
      :header-rows: 1
      :widths: 31 39 30

      * - 想知道什么
        - 从信号提取什么
        - 本模块的对应输出
      * - 哪些振荡最明显？
        - 各频率的波动强度
        - K01 功率谱
      * - 两处的振荡是否有稳定联系？
        - 各频率的相位差及其稳定性
        - K01 互相位、相干度、相位统计
      * - 沿探针间距方向，波变化多快？
        - 相位差除以间距
        - K02 投影波数及统计谱
      * - 平面内的波矢是多少？
        - 能共同解释多个构型的波矢
        - K03 每频点的二维波矢估计

   先从一个理想、单频、无噪声的波开始。后面只在这个例子上增加成分和噪声，
   不要求你一开始就读懂宽带测试里的全部参数。

   .. _foundations-zh-wave:

   .. rubric:: 2. 从一个正弦波读懂频率、波长和波矢

   在一维空间中，用 :math:`q(x,t)` 表示位置 :math:`x`、时刻 :math:`t` 的扰动：

   .. math::

      q(x,t)=A\cos(kx-\omega t+\phi_0),\qquad
      f=\frac{1}{T},\quad \omega=2\pi f,\quad k=\frac{2\pi}{\lambda}.

   :math:`A` 是振幅，单位与测量量相同；:math:`\phi_0` 是初始相位。
   余弦括号里的角度叫作 **相位**，变化 :math:`2\pi` 就走完一圈。
   弧度 rad 是角度单位，:math:`\pi` rad 等于 :math:`180^\circ`。
   固定位置看时间曲线，一次重复所需的时间是周期 :math:`T` （s），每秒重复次数是频率
   :math:`f` （Hz），角频率 :math:`\omega` （rad/s）表示每秒走过多少相位。
   固定时刻看空间曲线，相邻同相位点的距离是波长 :math:`\lambda` （m），
   波数 :math:`k` （rad/m）表示每米走过多少相位。

   为什么这个式子描述传播？跟踪一个波峰，它的相位保持不变，因而
   :math:`kx-\omega t=\text{常数}`，得到 :math:`x=(\omega/k)t+\text{常数}`。
   对这里 :math:`k>0` 的波，波峰以相速度 :math:`v_{\rm ph}=\omega/k=f\lambda` 沿 :math:`+x` 移动。
   相速度描述相位的移动，不应直接当作粒子运动速度或能量传播速度。

   本页始终使用同一个起点：:math:`f_0=1000\ \mathrm{Hz}`、
   :math:`v_{\rm ph}=20\ \mathrm{m/s}`、:math:`A=1`、:math:`\phi_0=0`。因此
   :math:`T=1\ \mathrm{ms}`、:math:`\lambda=20\ \mathrm{mm}`、
   :math:`k_0=100\pi\approx314.16\ \mathrm{rad/m}`。

   .. figure:: ../../images/K_Diagnostics/foundations/wave_and_probes.png
      :width: 100%
      :alt: 左边为两探针的时间波形，右边为同一波在固定时刻的空间分布。

      左图固定位置看时间，右图固定时刻看空间。两探针位于 0 和 5 mm，
      第二路比第一路晚 0.25 ms 出现同一波峰。图中 a.u. 表示任意信号单位。

   到二维时，位置变成 :math:`\mathbf r=(x,y)`，波数变成 **波矢**
   :math:`\mathbf K=(K_x,K_y)`：

   .. math::

      q(\mathbf r,t)=A\cos(\mathbf K\cdot\mathbf r-\omega t+\phi_0),\qquad
      \mathbf K\cdot\mathbf r=K_xx+K_yy,\qquad
      |\mathbf K|=\sqrt{K_x^2+K_y^2}.

   点乘就是把对应分量相乘后相加。波矢方向表示相位增加的空间方向，
   在这个正频率平面波模型里也是相位传播方向；长度满足 :math:`\lambda=2\pi/|\mathbf K|`。
   “平面波”表示同相位的位置排成直线（在三维中为平面）。
   我们的例子沿 :math:`+x` 传播，所以 :math:`\mathbf K=(k_0,0)`。

   **色散关系** 描述频率与波矢之间的关系。这里为教学选择
   :math:`\omega=v_{\rm ph}|\mathbf K|`，即各频率相速度相同的一条直线；真实介质的关系可能弯曲、
   依赖方向或有多条分支。诊断的任务是估计这些量之间的关系，不能把这个例子的直线预先当作所有数据的规律。

   .. _foundations-zh-pair:

   .. rubric:: 3. 两路波形怎样携带空间信息？

   把探针放在 :math:`r_1=0` 和 :math:`r_2=d=5\ \mathrm{mm}`。代入上面的波：

   .. math::

      x_1(t)=\cos(\omega t),\qquad
      x_2(t)=\cos(\omega t-kd)=x_1(t-\tau),\qquad \tau=\frac{d}{v_{\rm ph}}.

   第二路是延迟后的第一路。这个例子中 :math:`\tau=0.25\ \mathrm{ms}`，
   占周期的四分之一，对应相位差 :math:`\omega\tau=kd=\pi/2`。
   这里把“第一路的时间相位减去第二路的时间相位”记为 :math:`\theta`；
   下一节会看到代码怎样按这个顺序计算。

   对任意两处，定义从探针 1 指向探针 2 的间距向量
   :math:`\boldsymbol\chi=\mathbf r_2-\mathbf r_1`，长度为 :math:`d=|\boldsymbol\chi|`。
   在同一个平面波的假设下，探针的时间相位分别为
   :math:`-\mathbf K\cdot\mathbf r_1-\phi_0` 和
   :math:`-\mathbf K\cdot\mathbf r_2-\phi_0`，两者相减得到

   .. math::

      \theta=\mathbf K\cdot\boldsymbol\chi
      =K_x\chi_x+K_y\chi_y=k_\parallel d,\qquad
      k_\parallel=\mathbf K\cdot\frac{\boldsymbol\chi}{d}.

   :math:`k_\parallel` 是沿间距方向的 **投影波数**，可以为正或负。
   一个相位差只提供一个方程，通常不能确定 :math:`K_x,K_y` 两个未知数。
   例如两探针都在 x 轴上，测量里没有 :math:`K_y`，因此看不到垂直方向的分量。
   另外，相位只知道绕一圈后的角度；第 6 节再处理这项歧义。

   K03 的前向模型把“给定波矢会预测什么相位”直接写成下面的代码：

   .. literalinclude:: ../../../../K_Diagnostics/K03_mle_k2d/fun_K03_predicted_phase.py
      :language: python
      :start-at: def fun_K03_predicted_phase
      :lineno-match:

   ``chi`` 就是 :math:`\boldsymbol\chi`，``kx_values`` 和 ``ky_values`` 是候选波矢分量。
   ``None`` 增加数组维度，让两条一维坐标轴组合成二维表；表中每个位置存放一个候选的
   :math:`K_x\chi_x+K_y\chi_y`。目前先理解这个点乘，搜索整个表留到第 7 节。

   .. _foundations-zh-spectrum:

   .. rubric:: 4. 多个频率混在一起，怎样分别取出相位？

   在原来的 1 kHz 波上增加振幅为 0.5 的 3 kHz 波，两者仍沿 :math:`+x`、以 20 m/s 传播：

   .. math::

      q(x,t)=\cos[2\pi f_0(t-x/v_{\rm ph})]
      +0.5\cos[2\pi(3f_0)(t-x/v_{\rm ph})].

   两个探针仍在原来的位置。时域曲线变复杂了，但我们想分别比较 1 kHz 和 3 kHz 的相位。
   傅里叶分析就是把信号分解成不同频率的正弦、余弦成分；**FFT 是计算离散傅里叶变换的快速算法**。
   它把“一串时刻上的数”变成“一组频点上的复数”。

   **为什么会有复数？** 一个频率需要振幅和相位两个数来描述。
   用 :math:`z=a+ib=R(\cos\phi+i\sin\phi)=Re^{i\phi}` 可以把它们装在一起，
   其中 :math:`i^2=-1`，:math:`R=|z|=\sqrt{a^2+b^2}` 是长度，
   :math:`\phi=\arg z` 是角度。把 :math:`i` 换成 :math:`-i` 得到共轭
   :math:`z^*=Re^{-i\phi}`，也就是把角度反号。因此两个复数相乘时角度相加，
   与另一个数的共轭相乘时角度相减。

   .. admonition:: 独立知识点：FFT、频点与 Nyquist
      :class: ap-knowledge-box

      :doc:`点击阅读图解：FFT 把波形变成了什么？ </knowledge/fft>`
      其中包括变换公式、振幅与相位的推导、复平面图，以及采样混叠图；读完有链接返回这里。

      继续本页只需先知道：采样率为 :math:`f_s` （Hz）、每段 N 个样本时，
      第 m 个频点是 :math:`f_m=mf_s/N`，两探针的复数谱分别记为 :math:`X_1[m]`、:math:`X_2[m]`。
      :math:`|X|` 携带振幅，:math:`\arg X` 携带时间相位；``rfft`` 只保留非负频率。

      **Nyquist（奈奎斯特）频率** 是 :math:`f_{\rm Nyq}=f_s/2`，即每周期两个样本的边界。
      一般带限信号要无混叠地恢复，频率应严格低于此边界，并排除采样前的带外成分；
      边界点本身不能恢复任意相位。本例 fs=32 kHz，边界就是 16 kHz。
      下文的直流指 0 Hz，Nyquist 频点指偶数 N 时的 :math:`f_s/2` 端点。

   .. _foundations-zh-after-fft:

   **功率谱回答“哪个频率的波动强”。** 先取加窗 FFT 的 :math:`|X|^2`，再按采样率、窗口功率归一化。
   设窗口系数为 :math:`h_n`，本实现的单边功率谱密度为

   .. math::

      P_j(f_m)=\frac{a_m}{f_s\sum_n h_n^2}\left\langle |X_j(f_m)|^2\right\rangle,

   其中 :math:`\langle\cdot\rangle` 表示对多段求平均（下一节解释分段），
   :math:`a_m` 在普通正频率处为 2，在直流及偶数 :math:`N` 的 Nyquist 频点为 1。
   若信号单位为 V，谱密度单位就是 V²/Hz。它表示信号的均方强度分布，不自动等于物理能量密度。

   .. literalinclude:: ../../../../K_Diagnostics/K01_signal_spectra/fun_K01_power_spectrum.py
      :language: python
      :start-at:     density =
      :end-at:     return density * scale
      :dedent: 4

   ``np.abs(ffts) ** 2`` 对应 :math:`|X|^2`，``mean(axis=0)`` 沿分段方向平均，
   ``scale`` 处理单边谱倍数。本例用矩形窗 :math:`h_n=1`，分母退化为 :math:`f_sN`；
   选择 Hann 窗时，FFT 与功率谱必须传入相同的 ``window``。

   **互谱回答“两路同一频率差了多少相位”。** 设
   :math:`X_1=R_1e^{i\phi_1}`、:math:`X_2=R_2e^{i\phi_2}`，则

   .. math::

      C=X_1X_2^*=R_1R_2e^{i(\phi_1-\phi_2)},\qquad
      \theta=\arg C,\qquad w=(|X_1|^2+|X_2|^2)/2.

   :math:`C` 是互谱，:math:`\theta` 是互相位，:math:`w` 是后面 Beall 谱的累积权重。
   对本页的真实余弦信号，正频率的时间相位为 :math:`-\mathbf K\cdot\mathbf r_j-\phi_0`，
   因而这个乘法顺序给出 :math:`\theta=\mathbf K\cdot\boldsymbol\chi`，按整圈折算。

   .. literalinclude:: ../../../../K_Diagnostics/K01_signal_spectra/fun_K01_cross_phase.py
      :language: python
      :start-at:     with np.errstate
      :end-at:     return phase, magnitude
      :dedent: 4

   ``np.conj`` 是共轭，``np.angle`` 取角度，``np.abs`` 取长度。
   交换探针顺序会使相位反号；位置向量和信号顺序必须一起对应。
   1 kHz 的结果是 :math:`\pi/2`；3 kHz 得到 :math:`-\pi/2` 而非 :math:`3\pi/2`，
   原因正是第 6 节要讲的相位折叠。

   .. figure:: ../../images/K_Diagnostics/foundations/spectra_and_phase.png
      :width: 100%
      :alt: 双频波形、1 和 3 kHz 的功率谱峰，以及含噪信号分段相位的散布。

      上：同一对探针的双频波形，浅色线为第一路加噪后的记录。中：加噪后仍能分辨两个谱峰。
      下：每段的互相位围绕各自的理论值变化；s 是分段序号。噪声标准差为 0.3，信号采用任意单位。

   .. _foundations-zh-noise:

   .. rubric:: 5. 为什么分段、平均，还要计算相干度？

   真实记录可写为 :math:`x_j(t)=q(\mathbf r_j,t)+\epsilon_j(t)`，
   :math:`\epsilon_j` 是噪声。本例给每路加独立、零均值、标准差为 0.3 的高斯噪声。
   噪声会让一次 FFT 得到的相位偏离理想值。把记录分成多段，就能看到估计的散布，
   而不仅仅得到一个数。这样做假设这些分段描述的是相近的波动状态；若波的性质一直变化，
   平均可能把变化抹掉。

   本例取 :math:`f_s=32000\ \mathrm{Hz}`、每段 :math:`N=256` 个点，共 :math:`M=32` 段：

   .. list-table:: 四个容易混淆的量
      :header-rows: 1
      :widths: 24 25 51

      * - 量
        - 本例
        - 作用
      * - 采样间隔 :math:`1/f_s`
        - 31.25 μs
        - 决定时间采样有多密；可区分的频率范围受 :math:`f_s/2=16` kHz 限制。
      * - 每段时长 :math:`N/f_s`
        - 8 ms
        - 变长有助于区分更接近的频率，但要求波动状态在更长时间里相对稳定。
      * - 频点间隔 :math:`\Delta f=f_s/N`
        - 125 Hz
        - 1 和 3 kHz 恰好落在第 8、24 个频点；间隔不等于所有情况下的分辨能力。
      * - 分段数 :math:`M`
        - 32，总时长 256 ms
        - 提供多次估计以做统计；固定总时长时，增大每段长度会减少段数。

   当前 K01 取不重叠的完整分段，丢弃末尾不足一段的数据，默认逐段去均值：

   .. literalinclude:: ../../../../K_Diagnostics/K01_signal_spectra/fun_K01_segment_ffts.py
      :language: python
      :start-at:     block =
      :end-at:     return np.fft.rfft(block * weights, axis=1)
      :dedent: 4

   ``reshape(count, nperseg)`` 把一维记录排成“分段 × 时间样本”；FFT 后则是
   ``(M, N//2+1)``，即“分段 × 频点”。``axis=1`` 表示每一行分别变换。
   两路必须使用相同的分段起止时间。**不重叠不自动意味着统计独立**：信号若有长时间相关性，
   有效独立样本数仍可能少于段数。

   .. admonition:: 独立知识点：谱泄漏与窗函数
      :class: ap-knowledge-box

      本例每段恰好含整数个周期。频率不在频点上时，即使只有一个无噪声的波，
      有限记录的谱值也会分散到多个频点，这叫 **谱泄漏**。
      :doc:`点击看周期拼接图和频谱对比图 </knowledge/spectral_leakage>`，
      了解整数周期、非整数周期和加 Hann 窗的区别，再返回这里继续读。

      非整周期截断会使频谱分布到邻近频点，并可能影响互相位估计。
      Hann 窗通过平滑记录两端降低旁瓣，同时使主峰变宽。
      当前分段函数默认 ``window='boxcar'``，可选 ``window='hann'``；两路需使用相同窗口。
      功率谱函数必须传入相同的 ``window``，以 :math:`f_s\sum_n h_n^2` 为分母做窗口功率归一化。

   数值示例：:ref:`基础数值测试：有限记录与频谱 <basic-checks-zh-spectrum>`，核对相位偏差与窗口功率。

   .. _foundations-zh-after-leakage:

   **相干度** 衡量两路在一个频率上的线性相位关系是否稳定。本实现计算幅度平方相干度：

   .. math::

      \gamma^2(f)=\frac{|\langle X_1X_2^*\rangle|^2}
      {\langle|X_1|^2\rangle\langle|X_2|^2\rangle}.

   各段互谱的角度接近时，复数平均不容易抵消；角度散乱时容易抵消。因此相干度可帮助判断
   哪些频点值得继续分析，但高相干度不能单独证明只有一种波，也不能保证波数没有混叠。

   .. literalinclude:: ../../../../K_Diagnostics/K01_signal_spectra/fun_K01_coherence.py
      :language: python
      :start-at:     cross = np.mean
      :end-at:     return np.clip
      :dedent: 4

   ``cross`` 是先对互谱做复数平均，``auto_1``、``auto_2`` 是各路的平均平方模。
   只有一段且两个谱值非零时，这个比值恒为 1，不能用来判断可靠性。
   在独立分段、无真实相干等理想条件下，有限样本估计的噪声底约为 :math:`1/M`，不是严格的零；
   它也不是所有数据通用的显著性阈值。
   公式可参照 `SciPy 相干度文档 <https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.coherence.html>`_，
   但 SciPy 默认使用的窗和重叠设置与这里不同。

   **相位平均需要绕圆考虑。** :math:`179^\circ` 和 :math:`-179^\circ` 只差
   :math:`2^\circ`，普通平均却得到 :math:`0^\circ`。定义
   :math:`\operatorname{wrap}(\alpha)` 为加减整圈，把角度移到正负 :math:`\pi` 附近的主值范围。
   当前 K01 先用直方图找出相位最密集的位置 :math:`\theta_{\rm mode}` （众数参考），
   再在它附近计算偏差：

   .. math::

      \delta_s=\operatorname{wrap}(\theta_s-\theta_{\rm mode}),\quad
      \bar\theta=\theta_{\rm mode},\quad
      s_\theta^2=\frac{\sum_s(\delta_s-\bar\delta)^2}{M-1}.

   :math:`s` 是分段序号，:math:`\bar\delta` 是偏差平均值，:math:`s_\theta^2` 是样本方差（rad²）。
   小方差表示相位样本集中；对上面的两个角度，合理的均值在 :math:`180^\circ` 附近。

   .. literalinclude:: ../../../../K_Diagnostics/K01_signal_spectra/fun_K01_phase_mode_statistics.py
      :language: python
      :start-at:     shifted =
      :end-at:     variance =
      :dedent: 4

   ``shifted`` 对应 :math:`\delta_s`，``ddof=1`` 对应分母 :math:`M-1`，
   :math:`10^{-12}` 用于避免无噪数据导致后续除零。均值为最高直方图格中心，分箱与样本量会影响估计；不足两个有效样本返回 NaN。
   该方法适合围绕一个主要相位簇的样本；若同一频率混有多个传播方向、相位分布有多个峰，
   一个均值和方差就可能不足以描述数据。

   数值示例：:ref:`基础数值测试：相位的圆周性质 <basic-checks-zh-phase>`，查看跨越 ±π 的样本与众数格中心。

   .. _foundations-zh-alias:

   .. rubric:: 6. 相位为什么会给出折叠波数？Beall 图怎样读？

   下标 **meas** 是英文 **measured（测得的）** 的缩写：
   :math:`\theta_{\rm meas}` 是测得的主值相位，:math:`k_{\rm meas}` 是由它算出的波数。
   它们都可能已经折叠，所以“测得的”不等于“真实的”。meas 是文字标签，不是相乘的变量。

   如果只看钟表指针，转四分之一圈和转一又四分之一圈指向同一个位置。
   相位测量同样无法记录转过的整圈数。即使没有噪声、时间采样再密，也有

   .. math::

      \theta_{\rm meas}=\operatorname{wrap}(k_\parallel d),\qquad
      k_{\rm meas}=\frac{\theta_{\rm meas}}d,\qquad
      k_\parallel=k_{\rm meas}+\frac{2\pi\ell}{d},\quad \ell\in\mathbb Z.

   :math:`\ell` 是不知道的整圈数，也叫折叠阶数。单对探针无法仅从这个角度决定它。
   对 :math:`d=0.005\ \mathrm m`，主值波数范围的边界为
   :math:`k_{\rm Nyq}=\pi/d=200\pi\approx628.32\ \mathrm{rad/m}`。
   端点 :math:`-\pi` 和 :math:`+\pi` 表示同一个方向；本仓库的 wrap 使用取整，可能保留任一端点。
   要得到唯一的真实投影，必须另有 :math:`|k_\parallel|<\pi/d` 等范围信息。

   .. list-table:: 同一组探针上的手算例子
      :header-rows: 1
      :widths: 12 22 22 22 22

      * - 频率
        - 真波数 :math:`k_\parallel`
        - 真相位 :math:`k_\parallel d`
        - 观测相位
        - 报出的 :math:`k_{\rm meas}`
      * - 1 kHz
        - :math:`100\pi` rad/m
        - :math:`\pi/2`
        - :math:`\pi/2`
        - :math:`100\pi` rad/m
      * - 3 kHz
        - :math:`300\pi` rad/m
        - :math:`3\pi/2`
        - :math:`-\pi/2`
        - :math:`-100\pi` rad/m

   两个波实际都沿 :math:`+x` 传播，但第二个被折到了负波数。
   这说明仅凭折叠波数的正负判断真实方向可能出错。相位到波数的源码正是上述除法：

   .. literalinclude:: ../../../../K_Diagnostics/K02_beall/fun_K02_beall_wavenumber.py
      :language: python
      :start-at: def fun_K02_beall_wavenumber

   **不要混淆两种混叠。** 时间采样混叠与 :math:`f_s` 有关，空间相位歧义与
   :math:`\boldsymbol\chi` 有关。本例 1 和 3 kHz 都远低于时间 Nyquist 频率 16 kHz，
   3 kHz 却仍有空间混叠。对于沿间距方向传播的波，无空间混叠的条件可写成
   :math:`\lambda>2d`；一般方向应使用投影条件 :math:`|\mathbf K\cdot\boldsymbol\chi|<\pi`。

   **上面说的混叠，在下面第一张图里怎样看？** 这张图画的是一个转换关系，
   不是随时间变化的波形，也不是每一条线各代表一个固定频率。

   - 横轴 :math:`k_\parallel` 是真实波矢沿探针间距方向的投影，即
     :math:`\mathbf K\cdot\boldsymbol\chi/d`，单位 rad/m。横轴越往右表示真实投影越大，
     不是表示时间更晚。
   - 纵轴 :math:`k_{\rm meas}` 是这对探针按主值相位报出的波数，单位同样是 rad/m。
     沿蓝线读取一个横坐标，就得到对应的纵坐标。
   - 中间蓝线满足 :math:`k_{\rm meas}=k_\parallel`，位于无折叠的主值区间。
     灰色斜虚线把这个“测量等于真值”的关系延伸出去，作为比较。
   - **最左边的蓝线不是 3 kHz 的折叠。** 它对应负的真实投影
     :math:`k_\parallel<-628.32\ \mathrm{rad/m}`；在图示的这一分支，
     :math:`k_{\rm meas}=k_\parallel+1256.64\ \mathrm{rad/m}`。
     它展示负方向真值也会被折回，并不是本例另外生成了一个负方向波。
   - 3 kHz 对应 **右侧橙点**：横坐标
     :math:`300\pi\approx942.48\ \mathrm{rad/m}`，减去一个周期
     :math:`2\pi/d=400\pi\approx1256.64\ \mathrm{rad/m}`，
     得到纵坐标 :math:`-100\pi\approx-314.16\ \mathrm{rad/m}`。

   深灰色竖虚线标出真实投影的主值区间边界，深灰色横虚线标出测得波数的上下界；
   数值均为 :math:`\pm k_{\rm Nyq}=\pm\pi/d=\pm628.32\ \mathrm{rad/m}`。
   若事先知道真值严格落在两根竖线之间，就可以直接读出无折叠投影；
   超出竖线后，蓝线仍被限制在两根横线之间，说明整圈信息已经丢失。
   两端点在相位上等价，因此唯一性判断采用严格不等式。

   .. figure:: ../../images/K_Diagnostics/foundations/aliasing_and_beall.png
      :width: 100%
      :alt: 上图是真波数与折叠波数的锯齿关系，下图是双频信号的 Beall 统计谱。

      上图橙点对应手算的两个频率，浅灰色斜虚线表示不折叠时的关系，深灰色虚线标出 Nyquist 边界。
      下图来自无噪双频记录，
      横轴是报出的投影波数，纵轴是频率，颜色表示归一到最大值后的累积权重。
      3 kHz 的亮格落在负波数一侧；只有两个离散频率，所以这里是两个亮格而不是连续色散曲线。

   **Beall 谱是把多段估计放进二维直方图。** 每个“分段、频点”产生
   :math:`(k_{\rm meas},f)` 和权重 :math:`w=(|X_1|^2+|X_2|^2)/2`。
   把波数轴、频率轴切成小格，把落入每格的权重相加，最后除以分段数：

   .. math::

      S_{ab}=\frac1M\sum_{s,m}|C_{s,m}|\,
      \mathbf1\{f_m\in F_a,\ k_{s,m}\in B_b\}.

   :math:`F_a`、:math:`B_b` 分别是频率格和波数格，:math:`\mathbf1` 在条件满足时取 1，
   否则取 0。稳定的估计反复落到相近位置，形成亮格或亮脊；噪声使它们散开。
   代码中的 ``histogram2d`` 就在做这件事：

   .. literalinclude:: ../../../../K_Diagnostics/K02_beall/fun_K02_beall_spectrum.py
      :language: python
      :start-at:     histogram, _, _ =
      :dedent: 4

   返回字典的 ``spectrum`` 项就是累积结果。布尔掩码只选取相位、权重有效的样本；
   ``bins`` 给定格边界，``weights`` 给定各样本权重。此实现没有除以格宽或采用 K01 的 PSD
   归一化，因此这个 :math:`S(k,f)` 不应直接当成“每 Hz、每 rad/m 的能量密度”。
   格子越细，固定样本数下每格越稀；细网格本身不保证峰位更准确。

   数值示例：:ref:`基础数值测试：Beall 谱的累积 <basic-checks-zh-beall>`，逐步核对两段样本的分箱与功率累积。

   .. _foundations-zh-inversion:

   .. rubric:: 7. 多个构型怎样帮助寻找二维波矢？

   **一个构型就是一对具有已知间距向量的探针。** 多个构型可以来自阵列中的不同探针对，
   也可以来自重复实验；后一种情况要求各次实验描述相同的波动状态。
   联合反演对每一个频率分别进行，假设这些构型观测到同一个主要平面波的波矢。

   给一个候选 :math:`\mathbf K`，第 :math:`j` 个构型预测
   :math:`\mathbf K\cdot\boldsymbol\chi_j`。它应与实测均值 :math:`\bar\theta_j` 比较，
   但相差整圈不应被当成大误差，所以定义角度残差

   .. math::

      r_j(\mathbf K)=\operatorname{wrap}
      (\mathbf K\cdot\boldsymbol\chi_j-\bar\theta_j).

   单构型的所有零残差候选满足
   :math:`\mathbf K\cdot\boldsymbol\chi_j=\bar\theta_j+2\pi\ell`。
   一个 :math:`\ell` 对应波矢平面上的一条直线，所有整数就对应一族平行条纹。
   加入另一个方向的构型后，两族条纹相交，候选缩小到交点，但交点仍可能很多。

   .. figure:: ../../images/K_Diagnostics/foundations/wavevector_constraints.png
      :width: 100%
      :alt: 一个构型给出条纹，两个构型给出多个交点，三个构型在显示范围中突出一个峰。

      沿用 1 kHz 波，白色十字是真值 (100π, 0) rad/m。
      从左到右累积 J=1、2、3 个构型，间距向量依次为 (5, 0)、(0, 5)、(3.5, 2) mm。
      颜色越亮表示相位越符合观测。为显示条纹宽度，示意评分采用 0.15 rad 的相位标准差；
      相位均值直接取本例真值。评分已减去各图最大值，低于 −30 的部分使用同一种颜色。
      第三幅仍有较低的局部峰；最亮的峰靠近真值，并不意味着任意范围内都没有其他候选。

   **最大似然的直觉是：选择最能解释观测的候选。** 把集中在预测值附近的相位误差近似为高斯误差，
   方差 :math:`v_j` 描述测量的不确定程度，则一个候选的评分可写成

   .. math::

      \ln L(\mathbf K)=-\frac12\sum_j\frac{r_j(\mathbf K)^2}{v_j}
      +\text{与候选无关的常数}.

   高斯误差意味着小误差比大误差更常见；指数中的平方误差给出惩罚。
   对数把各构型似然的乘积变成相加，分数越大越好。
   同样的残差，在小方差的测量中更难解释，所以惩罚更大。
   这是用主值残差构造的局部高斯近似，不是针对任意宽分布的完整圆周概率模型。

   .. literalinclude:: ../../../../K_Diagnostics/K03_mle_k2d/fun_K03_config_log_likelihood.py
      :language: python
      :start-at:     residual =
      :end-at:     return -0.5 * residual * residual / variance
      :dedent: 4

   ``prediction`` 是点乘预测表，``delta_theta`` 是实测均值，``residual`` 是折回后的角度误差。
   联合计算再把各构型的这张评分表逐格相加：

   .. literalinclude:: ../../../../K_Diagnostics/K03_mle_k2d/fun_K03_joint_log_likelihood.py
      :language: python
      :start-at:     for chi, delta_theta, variance in _valid_configurations(configurations):
      :end-at:     return total
      :dedent: 4

   在给定的二维波数范围内建立均匀网格，计算各网格点的联合对数似然，取最大值对应的波矢作为估计结果。n_grid 指定每个坐标轴的点数，block_rows 指定每批计算的网格行数。

   .. rubric:: 几何与统计条件

   - **几何。** 一条基线产生一族相位条纹，多条基线的条纹交汇形成候选波矢。
     等长的多方向基线也能提供互补约束。若两个候选波矢之差 :math:`\Delta\mathbf K`
     对所有基线都满足 :math:`\Delta\mathbf K\cdot\boldsymbol\chi_j\in2\pi\mathbb Z`，
     两者会产生相同的包裹相位。这是精确混叠；可在给定搜索范围内检查这些候选点。
   - **统计权重。** K01 方差描述分段相位的散布，用于设置相位残差的尺度。
     众数位置的估计误差还取决于样本量、分箱和相位分布。
   - **构型间的统计关系。** 上面的简单评分把构型误差视为独立。
     共用探针可能带来相关误差；同频多个波、低相干度、变化中的波场也会使单个波矢解释不足。
     这些情况下，应先检查模型是否适用，而非只增加搜索网格。

   .. _foundations-zh-next:

   .. rubric:: 8. 把这条思路对应到代码，再继续阅读

   现在可以把计算过程读成两条分支。它们共享 K01 的输出，K03 不需要先从 K02 的图中读峰。

   .. code-block:: text

      同步时间序列 + 采样率
                  |
             K01: 分段 FFT
                  |
          功率谱 / 相干度 / 分段互相位
                  |
          +-------+---------------------+
          |                             |
      单对探针                       多个构型
      相位和两路自功率平均           各自的相位均值与方差
          |                             |
      K02: 投影波数、S(k,f)          K03: 联合评分、搜索 (Kx, Ky)

   .. list-table:: 下一步读什么
      :header-rows: 1
      :widths: 34 66

      * - 页面
        - 现在应当能够理解的内容
      * - :doc:`K01_signal_spectra <K01_signal_spectra>`
        - 为什么输出数组是“分段 × 频点”，互谱如何得到相位，为什么相位平均需要绕圆处理。
      * - :doc:`K02_beall <K02_beall>`
        - 为什么得到的是投影波数，折叠丢失什么信息，Beall 谱怎样累积。
      * - :doc:`K03_mle_k2d <K03_mle_k2d>`
        - 点乘预测、角度残差、方差权重和二维网格搜索怎样连接起来。
      * - :doc:`Learning Path <diagnostics_learning_path>`
        - 按推荐顺序进入具体函数，遇到术语时回到本页相应部分。
      * - :doc:`Usage Cookbook <diagnostics_usage_cookbook>`
        - 怎样导入和组合现有函数，准备符合形状和单位约定的输入。
      * - :doc:`基础数值测试 </tests/010_diagnostics/case_basic_checks>`
        - 核对三组测试的参考值、实测值、误差与验收判据；每节可返回对应原理。
      * - :doc:`宽带测试 </tests/010_diagnostics/case_broadband_dispersion>`
        - 已知生成真值时，怎样把估计结果与真值比较；它是验证案例，不是学习本页的前提。

   阅读自查：能否解释 3 kHz 的波为何报出负波数？一对探针为何不能确定二维波矢？
   功率谱高、相干度高、相位方差小分别说明什么？如果这些问题还说不清楚，
   可以先停在对应章节，不必急着进入全部函数接口。

.. container:: ap-lang ap-lang-en ap-diagnostics-foundations

   .. rubric:: Probe diagnostics: from two records to frequency, wavelength, and propagation direction

   FFT and leakage have reusable pages in the :doc:`knowledge index </knowledge/index>`.
   Follow the boxed links and return to the same section afterwards.

   This page starts with a cosine wave. No prior knowledge of FFTs, complex spectra, or maximum
   likelihood is assumed. The aim is to explain why ``K_Diagnostics`` performs each calculation
   and what it produces before you enter the :doc:`Diagnostics Learning Path <diagnostics_learning_path>`
   and individual routine pages. Read in order or return to a particular topic:

   :ref:`1. Purpose <foundations-en-purpose>` ·
   :ref:`2. Wave basics <foundations-en-wave>` ·
   :ref:`3. Two-probe phase <foundations-en-pair>` ·
   :ref:`4. Spectra and complex numbers <foundations-en-spectrum>` ·
   :ref:`5. Segments and noise <foundations-en-noise>` ·
   :ref:`6. Aliasing and Beall spectra <foundations-en-alias>` ·
   :ref:`7. Multiple configurations <foundations-en-inversion>` ·
   :ref:`8. Code and further reading <foundations-en-next>`

   .. _foundations-en-purpose:

   .. rubric:: 1. What is the diagnostic meant to do?

   Imagine two experimental probes, or two fixed sampling points in a simulation. Both record
   the same fluctuating quantity, such as a potential perturbation, at the same times.
   We obtain two sequences :math:`x_1[n]` and :math:`x_2[n]`, with sample index :math:`n`.
   A plot may show oscillations, but the research questions are more specific: which frequencies
   are present, what are their wavelengths, in which direction does phase propagate, and how
   does frequency depend on wavenumber?

   **A diagnostic estimates these properties from the records.** It needs synchronized signals,
   their sampling rate, and probe positions. A two-dimensional wavevector estimate also needs
   multiple probe configurations. A probe here is a sampling location; the algorithm does not
   model probe hardware. Differences in channel response or timing can also cause phase offsets
   in experiments and must be addressed by the caller.

   .. list-table:: From observations to questions
      :header-rows: 1
      :widths: 31 39 30

      * - Question
        - Information extracted
        - Module output
      * - Which oscillations are strongest?
        - Fluctuation strength at each frequency
        - K01 power spectrum
      * - Are the two records consistently related?
        - Phase difference and its stability at each frequency
        - K01 cross phase, coherence, phase statistics
      * - How rapidly does phase vary along the separation?
        - Phase difference divided by spacing
        - K02 projected wavenumber and statistical spectrum
      * - What is the wavevector in the plane?
        - A wavevector explaining several configurations together
        - K03 two-dimensional estimate at each frequency

   Start with one ideal, noiseless tone. We will add components and noise to that same example,
   without requiring you to understand all the broadband test parameters first.

   .. _foundations-en-wave:

   .. rubric:: 2. Frequency, wavelength, and wavevector from one cosine

   Let :math:`q(x,t)` be the perturbation at position :math:`x` and time :math:`t`:

   .. math::

      q(x,t)=A\cos(kx-\omega t+\phi_0),\qquad
      f=\frac{1}{T},\quad \omega=2\pi f,\quad k=\frac{2\pi}{\lambda}.

   :math:`A` is the amplitude, in the measured quantity's units, and :math:`\phi_0` is the
   initial phase. The angle inside the cosine is the **phase**; a change of :math:`2\pi`
   completes one cycle. Radians measure angles, with :math:`\pi` rad equal to :math:`180^\circ`.
   At a fixed location, the repeat time is the period :math:`T` (s), the cycles per second
   give frequency :math:`f` (Hz), and angular frequency :math:`\omega` (rad/s) measures phase
   change per second. At a fixed time, the repeat distance is the wavelength :math:`\lambda`
   (m), and wavenumber :math:`k` (rad/m) measures phase change per metre.

   Why does this expression propagate? Follow a crest of constant phase:
   :math:`kx-\omega t=\text{constant}`, so :math:`x=(\omega/k)t+\text{constant}`.
   With positive :math:`k` here, the crest moves in :math:`+x` at the phase velocity
   :math:`v_{\rm ph}=\omega/k=f\lambda`. This is the speed of phase, not automatically the
   particle velocity or the speed of energy transport.

   Our starting example uses :math:`f_0=1000\ \mathrm{Hz}`,
   :math:`v_{\rm ph}=20\ \mathrm{m/s}`, :math:`A=1`, and :math:`\phi_0=0`.
   Thus :math:`T=1\ \mathrm{ms}`, :math:`\lambda=20\ \mathrm{mm}`, and
   :math:`k_0=100\pi\approx314.16\ \mathrm{rad/m}`.

   .. figure:: ../../images/K_Diagnostics/foundations/wave_and_probes.png
      :width: 100%
      :alt: Temporal records at two probes and a spatial snapshot of the same wave.

      Left: time varies at fixed positions. Right: position varies at a fixed time.
      The probes are at 0 and 5 mm; the second sees the same crest 0.25 ms later.
      The label a.u. denotes arbitrary signal units.

   In two dimensions, position becomes :math:`\mathbf r=(x,y)` and wavenumber becomes the
   **wavevector** :math:`\mathbf K=(K_x,K_y)`:

   .. math::

      q(\mathbf r,t)=A\cos(\mathbf K\cdot\mathbf r-\omega t+\phi_0),\qquad
      \mathbf K\cdot\mathbf r=K_xx+K_yy,\qquad
      |\mathbf K|=\sqrt{K_x^2+K_y^2}.

   The dot product multiplies matching components and adds them. The wavevector points toward
   increasing spatial phase, also the phase propagation direction for this positive-frequency
   plane wave; its magnitude satisfies :math:`\lambda=2\pi/|\mathbf K|`. A plane wave has
   straight lines of equal phase in two dimensions, or planes in three dimensions.
   Our example propagates along :math:`+x`, so :math:`\mathbf K=(k_0,0)`.

   A **dispersion relation** connects frequency and wavevector. For teaching we choose
   :math:`\omega=v_{\rm ph}|\mathbf K|`, a straight line with the same phase speed at all
   frequencies. Real media can have curved, direction-dependent, or multiple branches.
   The diagnostic estimates the relation; this example's straight line must not be assumed
   for every dataset.

   .. _foundations-en-pair:

   .. rubric:: 3. How do two records carry spatial information?

   Place the probes at :math:`r_1=0` and :math:`r_2=d=5\ \mathrm{mm}`. Substitution gives

   .. math::

      x_1(t)=\cos(\omega t),\qquad
      x_2(t)=\cos(\omega t-kd)=x_1(t-\tau),\qquad \tau=\frac{d}{v_{\rm ph}}.

   The second record is a delayed version of the first. Here :math:`\tau=0.25\ \mathrm{ms}`
   is a quarter period, corresponding to :math:`\omega\tau=kd=\pi/2` of phase.
   We define :math:`\theta` as the first record's temporal phase minus the second's.
   The next section shows how the code preserves this order.

   For arbitrary positions define the separation from probe 1 to probe 2 as
   :math:`\boldsymbol\chi=\mathbf r_2-\mathbf r_1`, with length :math:`d=|\boldsymbol\chi|`.
   For the same plane wave, the temporal phases are
   :math:`-\mathbf K\cdot\mathbf r_1-\phi_0` and
   :math:`-\mathbf K\cdot\mathbf r_2-\phi_0`. Subtracting yields

   .. math::

      \theta=\mathbf K\cdot\boldsymbol\chi
      =K_x\chi_x+K_y\chi_y=k_\parallel d,\qquad
      k_\parallel=\mathbf K\cdot\frac{\boldsymbol\chi}{d}.

   :math:`k_\parallel` is the signed **projected wavenumber** along the separation.
   One phase difference supplies one equation and generally cannot determine two unknowns
   :math:`K_x,K_y`. If both probes lie on the x axis, for example, the measurement contains no
   :math:`K_y` and cannot see that perpendicular component. Phase is also only known after
   reducing full turns; section 6 addresses that ambiguity.

   The K03 forward model answers “what phase would this wavevector predict?” with this code:

   .. literalinclude:: ../../../../K_Diagnostics/K03_mle_k2d/fun_K03_predicted_phase.py
      :language: python
      :start-at: def fun_K03_predicted_phase
      :lineno-match:

   ``chi`` represents :math:`\boldsymbol\chi`; ``kx_values`` and ``ky_values`` hold candidate
   components. ``None`` adds array dimensions so the two coordinate lists form a table, each
   entry containing one :math:`K_x\chi_x+K_y\chi_y`. For now focus on that dot product;
   section 7 explains searching the table.

   .. _foundations-en-spectrum:

   .. rubric:: 4. How can we compare phases when frequencies are mixed?

   Add a 3 kHz wave of amplitude 0.5 to the original 1 kHz wave. Both still propagate along
   :math:`+x` at 20 m/s:

   .. math::

      q(x,t)=\cos[2\pi f_0(t-x/v_{\rm ph})]
      +0.5\cos[2\pi(3f_0)(t-x/v_{\rm ph})].

   The probes stay in place. Although the time trace is more complicated, we want separate
   phase comparisons at 1 and 3 kHz. Fourier analysis decomposes a signal into sinusoidal
   components; the **FFT is a fast algorithm for the discrete Fourier transform**.
   It converts samples at times into complex coefficients at frequency bins.

   **Why complex numbers?** Each frequency needs both an amplitude and a phase.
   A complex number :math:`z=a+ib=R(\cos\phi+i\sin\phi)=Re^{i\phi}` stores both, where
   :math:`i^2=-1`, :math:`R=|z|=\sqrt{a^2+b^2}` is its magnitude, and
   :math:`\phi=\arg z` is its angle. Replacing :math:`i` by :math:`-i` gives the conjugate
   :math:`z^*=Re^{-i\phi}`, reversing the angle. Multiplication adds angles; multiplication
   by another number's conjugate subtracts its angle.

   .. admonition:: Independent knowledge note: FFT, bins, and Nyquist
      :class: ap-knowledge-box

      :doc:`Open the illustrated explanation: what does an FFT produce? </knowledge/fft>`
      It covers the transform, amplitude and phase derivation, a complex-plane diagram,
      and a sampling-aliasing plot, with a link back here.

      To continue, retain this: for sampling rate :math:`f_s` (Hz) and N samples per segment,
      bin m has frequency :math:`f_m=mf_s/N`. The probes' complex spectra are
      :math:`X_1[m]` and :math:`X_2[m]`. Magnitude carries amplitude, angle carries temporal
      phase, and ``rfft`` retains nonnegative frequencies.

      The **Nyquist frequency** is :math:`f_{\rm Nyq}=f_s/2`, the boundary at two samples per
      cycle. Unaliased recovery of a general band-limited signal requires frequencies
      strictly below it and exclusion of out-of-band content before sampling. The endpoint
      cannot recover arbitrary phase. Here fs=32 kHz gives 16 kHz. DC below means 0 Hz;
      the Nyquist bin means the even-N endpoint at :math:`f_s/2`.

   .. _foundations-en-after-fft:

   **A power spectrum identifies strong frequency components.** We square the windowed FFT magnitude and
   normalize by sampling rate and window power. This implementation's one-sided power spectral
   density is

   .. math::

      P_j(f_m)=\frac{a_m}{f_s\sum_n h_n^2}\left\langle |X_j(f_m)|^2\right\rangle.

   Here :math:`h_n` is the analysis window and :math:`X_j` is the windowed FFT.
   Angle brackets denote an average over segments, explained next. The factor :math:`a_m`
   is 2 at ordinary positive frequencies and 1 at DC and the Nyquist bin for even :math:`N`.
   A signal in volts gives a density in V²/Hz. This describes mean-square signal strength,
   not automatically a physical energy density.

   .. literalinclude:: ../../../../K_Diagnostics/K01_signal_spectra/fun_K01_power_spectrum.py
      :language: python
      :start-at:     density =
      :end-at:     return density * scale
      :dedent: 4

   ``np.abs(ffts) ** 2`` is :math:`|X|^2`, ``mean(axis=0)`` averages over segments, and
   ``scale`` handles the one-sided factors. This example uses a boxcar window :math:`h_n=1`,
   giving denominator :math:`f_sN`. With Hann, pass the same ``window`` to both FFT and PSD routines.

   **The cross spectrum compares the phases at the same frequency.** Write
   :math:`X_1=R_1e^{i\phi_1}` and :math:`X_2=R_2e^{i\phi_2}`. Then

   .. math::

      C=X_1X_2^*=R_1R_2e^{i(\phi_1-\phi_2)},\qquad
      \theta=\arg C,\qquad w=(|X_1|^2+|X_2|^2)/2.

   :math:`C` is the cross spectrum, :math:`\theta` the cross phase, and :math:`w` the weight
   later used in the Beall spectrum. Our real cosine has positive-frequency temporal phase
   :math:`-\mathbf K\cdot\mathbf r_j-\phi_0`, so this multiplication order gives
   :math:`\theta=\mathbf K\cdot\boldsymbol\chi`, reduced modulo a full turn.

   .. literalinclude:: ../../../../K_Diagnostics/K01_signal_spectra/fun_K01_cross_phase.py
      :language: python
      :start-at:     with np.errstate
      :end-at:     return phase, magnitude
      :dedent: 4

   ``np.conj`` conjugates, ``np.angle`` extracts the angle, and ``np.abs`` extracts magnitude.
   Swapping probes reverses the phase sign; positions and record order must match.
   At 1 kHz we get :math:`\pi/2`; at 3 kHz we get :math:`-\pi/2` rather than
   :math:`3\pi/2`. This is the phase wrapping explained in section 6.

   .. figure:: ../../images/K_Diagnostics/foundations/spectra_and_phase.png
      :width: 100%
      :alt: Two-tone signals, power peaks at 1 and 3 kHz, and noisy segment phases.

      Top: the same probe pair now records two tones; the pale trace adds noise to probe 1.
      Middle: both spectral peaks remain visible with noise. Bottom: each segment's cross
      phase fluctuates around its theoretical value; s indexes segments. Noise has standard
      deviation 0.3 in the arbitrary signal units.

   .. _foundations-en-noise:

   .. rubric:: 5. Why segment, average, and calculate coherence?

   A real record can be written as :math:`x_j(t)=q(\mathbf r_j,t)+\epsilon_j(t)`, with noise
   :math:`\epsilon_j`. This example adds independent zero-mean Gaussian noise of standard
   deviation 0.3 to each probe. Noise changes the phase estimated from one FFT. Segments give
   repeated estimates whose spread we can inspect, instead of just one number. This assumes
   reasonably similar wave statistics across segments; averaging a changing wave field can
   conceal the change.

   Use :math:`f_s=32000\ \mathrm{Hz}`, :math:`N=256` samples per segment, and :math:`M=32` segments:

   .. list-table:: Four quantities with different roles
      :header-rows: 1
      :widths: 24 25 51

      * - Quantity
        - Example value
        - Role
      * - Sample interval :math:`1/f_s`
        - 31.25 μs
        - Sets temporal sampling density; the frequency range is limited by :math:`f_s/2=16` kHz.
      * - Segment duration :math:`N/f_s`
        - 8 ms
        - Longer segments help separate close frequencies but require a longer nearly stationary interval.
      * - Bin spacing :math:`\Delta f=f_s/N`
        - 125 Hz
        - 1 and 3 kHz fall exactly on bins 8 and 24; bin spacing is not a universal resolving power.
      * - Segment count :math:`M`
        - 32; total duration 256 ms
        - Supplies repeated estimates; at fixed total duration, longer segments mean fewer segments.

   K01 uses complete non-overlapping segments, discards a trailing partial segment, and by
   default removes each segment's mean:

   .. literalinclude:: ../../../../K_Diagnostics/K01_signal_spectra/fun_K01_segment_ffts.py
      :language: python
      :start-at:     block =
      :end-at:     return np.fft.rfft(block * weights, axis=1)
      :dedent: 4

   ``reshape(count, nperseg)`` arranges the record as “segments × time samples.” The FFT
   output is ``(M, N//2+1)``, or “segments × frequency bins”; ``axis=1`` transforms each row.
   Both probes must use the same segment boundaries. **Non-overlap does not guarantee
   statistical independence**: long correlations can reduce the effective independent count.

   .. admonition:: Independent knowledge note: spectral leakage and windows
      :class: ap-knowledge-box

      These example segments contain integer cycles. An off-bin tone can spread across
      several spectral bins even with no noise or other waves: **spectral leakage**.
      :doc:`Open the repeated-record and spectrum comparison diagrams </knowledge/spectral_leakage>`
      to compare integer cycles, non-integer cycles, and a Hann window, then return here.

      Off-bin truncation spreads a tone across neighboring bins and can affect cross-phase estimates.
      A Hann window smooths the record ends to reduce sidelobes while broadening the main lobe.
      Segmentation defaults to ``window='boxcar'`` and also supports ``window='hann'``.
      Both records must use the same window. Pass the matching ``window`` to the power-spectrum
      routine, whose window-power normalization uses the denominator :math:`f_s\sum_n h_n^2`.

   Numerical example: :ref:`basic_numerical tests: finite records and spectra <basic-checks-en-spectrum>`
   compares phase errors and window-normalized power.

   .. _foundations-en-after-leakage:

   **Coherence** measures the stability of the linear phase relationship at a frequency.
   This implementation uses magnitude-squared coherence:

   .. math::

      \gamma^2(f)=\frac{|\langle X_1X_2^*\rangle|^2}
      {\langle|X_1|^2\rangle\langle|X_2|^2\rangle}.

   Similar cross-spectrum angles reinforce one another during complex averaging; scattered
   angles tend to cancel. Coherence can help select frequencies for further analysis, but
   high coherence alone proves neither a single wave nor an unaliased wavenumber.

   .. literalinclude:: ../../../../K_Diagnostics/K01_signal_spectra/fun_K01_coherence.py
      :language: python
      :start-at:     cross = np.mean
      :end-at:     return np.clip
      :dedent: 4

   ``cross`` averages complex cross spectra; ``auto_1`` and ``auto_2`` average squared
   magnitudes. With just one segment and nonzero coefficients the ratio is always 1 and
   cannot establish reliability. Under ideal independent-segment, zero-coherence conditions,
   the finite-sample floor is approximately :math:`1/M`, not exactly zero; this is not a
   universal significance threshold. Compare the formula with the
   `SciPy coherence documentation <https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.coherence.html>`_,
   remembering that its default window and overlap settings differ from this implementation.

   **Phase averages live on a circle.** :math:`179^\circ` and :math:`-179^\circ` differ by
   only :math:`2^\circ`, but their arithmetic average is :math:`0^\circ`.
   Define :math:`\operatorname{wrap}(\alpha)` to add or subtract full turns and return an
   angle in the principal range near :math:`\pm\pi`. K01 first locates the most populated
   histogram region, the mode reference :math:`\theta_{\rm mode}`, and calculates offsets:

   .. math::

      \delta_s=\operatorname{wrap}(\theta_s-\theta_{\rm mode}),\quad
      \bar\theta=\theta_{\rm mode},\quad
      s_\theta^2=\frac{\sum_s(\delta_s-\bar\delta)^2}{M-1}.

   Here :math:`s` indexes segments, :math:`\bar\delta` is the mean offset, and
   :math:`s_\theta^2` is the sample variance in rad². Small variance means concentrated
   samples. The two example angles should average near :math:`180^\circ`.

   .. literalinclude:: ../../../../K_Diagnostics/K01_signal_spectra/fun_K01_phase_mode_statistics.py
      :language: python
      :start-at:     shifted =
      :end-at:     variance =
      :dedent: 4

   ``shifted`` is :math:`\delta_s`, ``ddof=1`` supplies the denominator :math:`M-1`, and
   :math:`10^{-12}` prevents later division by zero for noiseless input. The mean is the modal bin centre; binning and sample count matter. Fewer than two valid samples gives NaN. This approach suits
   samples clustered around one main phase; multiple directions at one frequency or multiple
   phase peaks may not be adequately described by one mean and variance.

   Numerical example: :ref:`basic_numerical tests: circular phase statistics <basic-checks-en-phase>`
   shows samples across ±π and their modal bin centers.

   .. _foundations-en-alias:

   .. rubric:: 6. Why does phase give a folded wavenumber? How is a Beall plot read?

   The subscript **meas** abbreviates **measured**: :math:`\theta_{\rm meas}` is the
   measured principal phase and :math:`k_{\rm meas}` the wavenumber calculated from it.
   Both can already be folded; measured does not necessarily mean true.
   The subscript is a text label, not variables being multiplied.

   A clock hand points the same way after a quarter turn and after one and a quarter turns.
   Phase measurements similarly cannot count completed turns. Even without noise and with
   arbitrarily dense time sampling,

   .. math::

      \theta_{\rm meas}=\operatorname{wrap}(k_\parallel d),\qquad
      k_{\rm meas}=\frac{\theta_{\rm meas}}d,\qquad
      k_\parallel=k_{\rm meas}+\frac{2\pi\ell}{d},\quad \ell\in\mathbb Z.

   The unknown integer :math:`\ell` is the fold order. One probe pair cannot determine it
   from this angle alone. For :math:`d=0.005\ \mathrm m`, the principal wavenumber boundary is
   :math:`k_{\rm Nyq}=\pi/d=200\pi\approx628.32\ \mathrm{rad/m}`.
   The endpoints :math:`-\pi` and :math:`+\pi` represent the same angle; this repository's
   rounding-based wrap can retain either endpoint. An additional range constraint such as
   :math:`|k_\parallel|<\pi/d` is needed to identify a unique true projection.

   .. list-table:: Hand calculation for the same probes
      :header-rows: 1
      :widths: 12 22 22 22 22

      * - Frequency
        - True :math:`k_\parallel`
        - True :math:`k_\parallel d`
        - Observed phase
        - Reported :math:`k_{\rm meas}`
      * - 1 kHz
        - :math:`100\pi` rad/m
        - :math:`\pi/2`
        - :math:`\pi/2`
        - :math:`100\pi` rad/m
      * - 3 kHz
        - :math:`300\pi` rad/m
        - :math:`3\pi/2`
        - :math:`-\pi/2`
        - :math:`-100\pi` rad/m

   Both waves actually propagate in :math:`+x`, but the second folds to a negative
   wavenumber. A folded sign alone can therefore misidentify the true direction.
   The conversion code is precisely the division above:

   .. literalinclude:: ../../../../K_Diagnostics/K02_beall/fun_K02_beall_wavenumber.py
      :language: python
      :start-at: def fun_K02_beall_wavenumber

   **Separate temporal and spatial aliasing.** Temporal aliasing depends on :math:`f_s`;
   spatial phase ambiguity depends on :math:`\boldsymbol\chi`. Both example frequencies
   are far below the 16 kHz temporal Nyquist frequency, yet 3 kHz aliases spatially.
   For propagation along the separation, the unaliased condition is :math:`\lambda>2d`.
   For a general direction use the projection condition
   :math:`|\mathbf K\cdot\boldsymbol\chi|<\pi`.

   **How does the first plot below show folding?** It plots a conversion relation,
   not a time trace; each line segment does not represent one fixed frequency.

   - Horizontal :math:`k_\parallel` is the true wavevector projected along the separation,
     :math:`\mathbf K\cdot\boldsymbol\chi/d`, in rad/m. Moving right increases the true
     projection, not time.
   - Vertical :math:`k_{\rm meas}` is the pair's principal-phase wavenumber estimate,
     also in rad/m. Follow the blue curve from an input on the horizontal axis to its output.
   - The middle branch has :math:`k_{\rm meas}=k_\parallel`, the unfurled principal
     interval. The grey diagonal extends this identity for comparison.
   - **The leftmost blue branch is not the 3 kHz fold.** It covers negative true
     projections :math:`k_\parallel<-628.32\ \mathrm{rad/m}`. On this displayed branch,
     :math:`k_{\rm meas}=k_\parallel+1256.64\ \mathrm{rad/m}`. It illustrates folding of
     negative truth; no extra negative-going wave was generated for our example.
   - The 3 kHz example is the **right-hand orange point**. Its input is
     :math:`300\pi\approx942.48\ \mathrm{rad/m}`. Subtracting one period,
     :math:`2\pi/d=400\pi\approx1256.64\ \mathrm{rad/m}`, gives the output
     :math:`-100\pi\approx-314.16\ \mathrm{rad/m}`.

   Dark grey vertical dashed lines bound the principal interval for the true projection;
   dark grey horizontal dashed lines bound the reported value. Both are at
   :math:`\pm k_{\rm Nyq}=\pm\pi/d=\pm628.32\ \mathrm{rad/m}`.
   If truth is known to lie strictly between the vertical lines, it can be read without
   folding. Beyond them the blue curve still stays between the horizontal lines:
   whole-turn information is lost. The endpoints are phase-equivalent, so uniqueness
   uses a strict inequality.

   .. figure:: ../../images/K_Diagnostics/foundations/aliasing_and_beall.png
      :width: 100%
      :alt: Sawtooth folding of true wavenumber and a two-tone Beall statistical spectrum.

      Top: orange points mark the two hand calculations; the light grey diagonal dashed line
      is the unfurled relation, and dark grey dashed lines mark the Nyquist boundaries.
      Bottom: the noiseless two-tone records produce a map of reported projected
      wavenumber against frequency, coloured by accumulated weight divided by its maximum.
      The 3 kHz cell is on the negative-wavenumber side. With only two discrete tones there
      are two bright cells, not a continuous dispersion curve.

   **The Beall spectrum is a weighted two-dimensional histogram of segment estimates.**
   Each segment-frequency sample supplies :math:`(k_{\rm meas},f)` and weight
   :math:`w=(|X_1|^2+|X_2|^2)/2`. Divide the frequency and wavenumber axes into bins, add the weights
   falling in each cell, and divide by segment count:

   .. math::

      S_{ab}=\frac1M\sum_{s,m}|C_{s,m}|\,
      \mathbf1\{f_m\in F_a,\ k_{s,m}\in B_b\}.

   :math:`F_a` and :math:`B_b` are frequency and wavenumber bins. The indicator
   :math:`\mathbf1` is 1 if the condition holds and 0 otherwise. Stable estimates accumulate
   near one location, making bright cells or ridges; noise spreads them out.
   The ``histogram2d`` call implements this accumulation:

   .. literalinclude:: ../../../../K_Diagnostics/K02_beall/fun_K02_beall_spectrum.py
      :language: python
      :start-at:     histogram, _, _ =
      :dedent: 4

   The returned dictionary's ``spectrum`` entry holds the accumulation. a Boolean mask selects valid phase/power samples, ``bins`` supplies boundaries, and ``weights``
   supplies contributions. This implementation divides neither by bin widths nor by the
   K01 PSD normalization, so its :math:`S(k,f)` is not directly an energy density per Hz per
   rad/m. Finer bins contain fewer samples at fixed record length; a finer grid alone does
   not guarantee a more accurate peak.

   Numerical example: :ref:`basic_numerical tests: Beall accumulation <basic-checks-en-beall>`
   follows two samples through binning and power accumulation.

   .. _foundations-en-inversion:

   .. rubric:: 7. How do multiple configurations help recover a two-dimensional wavevector?

   A **configuration is a probe pair with a known separation vector**. Configurations may
   come from pairs in an array or from repeated experiments; repeated experiments must
   describe the same wave statistics. The inversion operates separately at each frequency,
   assuming all configurations observe the same dominant plane-wave wavevector there.

   For candidate :math:`\mathbf K`, configuration :math:`j` predicts
   :math:`\mathbf K\cdot\boldsymbol\chi_j`. Compare it with measured mean phase
   :math:`\bar\theta_j`, without treating a full-turn difference as a large error:

   .. math::

      r_j(\mathbf K)=\operatorname{wrap}
      (\mathbf K\cdot\boldsymbol\chi_j-\bar\theta_j).

   Zero-residual candidates for one configuration obey
   :math:`\mathbf K\cdot\boldsymbol\chi_j=\bar\theta_j+2\pi\ell`.
   Each integer :math:`\ell` gives a line in wavevector space; together they form parallel
   fringes. A second orientation intersects them and reduces candidates to crossings, but
   many crossings may remain.

   .. figure:: ../../images/K_Diagnostics/foundations/wavevector_constraints.png
      :width: 100%
      :alt: One configuration gives fringes, two give crossings, and three highlight one peak in the shown domain.

      The white cross marks the same 1 kHz truth, (100π, 0) rad/m. From left to right,
      J=1, 2, and 3 configurations accumulate, with separations (5, 0), (0, 5), and
      (3.5, 2) mm. Brighter colours indicate better agreement. To show fringe widths,
      these illustrative scores use phase standard deviation 0.15 rad and exact example
      mean phases. Each map has its maximum subtracted; scores below −30 share one colour.
      Lower local peaks remain in the third map. Its brightest peak lies near the truth;
      this does not establish uniqueness over an arbitrary search domain.

   **Maximum likelihood chooses the candidate that best explains the observations.**
   Approximate concentrated phase errors by Gaussian errors, with variance :math:`v_j`
   describing measurement uncertainty. A candidate's score becomes

   .. math::

      \ln L(\mathbf K)=-\frac12\sum_j\frac{r_j(\mathbf K)^2}{v_j}
      +\text{constant independent of the candidate}.

   Gaussian errors make small discrepancies more likely than large ones; the squared error
   supplies the penalty. Taking a logarithm turns a product of likelihoods into a sum, with
   higher scores preferred. A given residual is harder to explain for a low-variance
   measurement and receives a greater penalty. Using the principal residual is a local
   Gaussian approximation, not a full circular probability model for arbitrary broad errors.

   .. literalinclude:: ../../../../K_Diagnostics/K03_mle_k2d/fun_K03_config_log_likelihood.py
      :language: python
      :start-at:     residual =
      :end-at:     return -0.5 * residual * residual / variance
      :dedent: 4

   ``prediction`` is the dot-product table, ``delta_theta`` is the measured mean, and
   ``residual`` is the wrapped angular error. The joint routine adds configuration scores
   at matching grid points:

   .. literalinclude:: ../../../../K_Diagnostics/K03_mle_k2d/fun_K03_joint_log_likelihood.py
      :language: python
      :start-at:     for chi, delta_theta, variance in _valid_configurations(configurations):
      :end-at:     return total
      :dedent: 4

   Build a uniform grid over the chosen two-dimensional wavenumber range, evaluate the joint log likelihood at every point, and report the wavevector at its maximum. n_grid sets the number of points per axis; block_rows sets the number of rows evaluated in each batch.

   .. rubric:: Geometry and statistical conditions

   - **Geometry.** Each baseline produces a family of phase fringes; their intersections locate candidate
     wavevectors. Equal-length baselines with different directions can supply complementary constraints.
     Two candidates separated by :math:`\Delta\mathbf K` produce identical wrapped phases when
     :math:`\Delta\mathbf K\cdot\boldsymbol\chi_j\in2\pi\mathbb Z` for every baseline.
     These exact aliases can be checked within the chosen search domain.
   - **Statistical weights.** The K01 variance describes segment-phase scatter and scales the phase residual.
     Mode-location uncertainty also depends on sample count, histogram binning and the distribution.
   - **Relations between configurations.** This simple score treats configuration
     errors as independent. Shared probes can correlate errors. Multiple waves at one
     frequency, low coherence, or a changing wave field can also defeat a single-wavevector
     description. Reassess the model rather than only enlarging the grid.

   .. _foundations-en-next:

   .. rubric:: 8. Connect the reasoning to the code and continue reading

   The calculation has two branches sharing K01 outputs. K03 does not require reading peaks
   from K02 first.

   .. code-block:: text

      Synchronized records + sampling rate
                       |
                 K01: segment FFTs
                       |
            Power / coherence / segment cross phase
                       |
              +--------+-----------------------+
              |                                |
          One probe pair                 Multiple configurations
          Phase and mean auto-power      Phase means and variances
              |                                |
          K02: projected k, S(k,f)       K03: joint score, search (Kx, Ky)

   .. list-table:: Further reading
      :header-rows: 1
      :widths: 34 66

      * - Page
        - What should now be understandable
      * - :doc:`K01_signal_spectra <K01_signal_spectra>`
        - Segment-frequency array axes, extracting phase from a cross spectrum, and circular phase statistics.
      * - :doc:`K02_beall <K02_beall>`
        - Projected wavenumber, information lost in folding, and Beall accumulation.
      * - :doc:`K03_mle_k2d <K03_mle_k2d>`
        - Connecting dot-product predictions, angular residuals, variance weights, and grid search.
      * - :doc:`Learning Path <diagnostics_learning_path>`
        - Follow the routine reading order and return here when a concept needs refreshing.
      * - :doc:`Usage Cookbook <diagnostics_usage_cookbook>`
        - Import and combine routines, preparing arrays with the correct shapes and units.
      * - :doc:`basic_numerical tests </tests/010_diagnostics/case_basic_checks>`
        - Compare references, measurements, errors and acceptance rules in three test groups; each links back to the theory.
      * - :doc:`Broadband test </tests/010_diagnostics/case_broadband_dispersion>`
        - Compare estimates with known generated truth; this verification case is not a prerequisite for this page.

   Check your understanding: why does 3 kHz report a negative wavenumber? Why can one pair
   not determine a two-dimensional wavevector? What do high power, high coherence, and small
   phase variance each tell you? Revisit the corresponding section if needed before moving
   on to the full routine interfaces.
