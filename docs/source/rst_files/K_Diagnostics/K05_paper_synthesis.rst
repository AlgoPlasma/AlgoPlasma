12 · Reading the paper from equations to conclusions
====================================================

.. raw:: html

   <link rel="stylesheet" href="../../_static/K_Diagnostics/k05-wave-packet.css?v=30">
   <div class="ap-language-switch" role="group" aria-label="Language switch" data-ap-default-lang="en">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-en k05-lesson

   .. _k05-synthesis-en:

   .. rubric:: Put the equations and the physical conclusions together

   We can now return to the question in the title of Brown and Jorns [1]:
   **what supplies fluctuations, what redistributes them, and how can a finite
   spectrum persist?** The preceding pages explain the inference method and apply
   it to C1/C3. This page reads the original article's evidence and distinguishes
   it from the new experiment. The diagrams below are independently constructed schematics inspired by the
   questions in [1]. They contain no digitized paper data and no C1/C3 data.
   Quantitative statements about the paper are attributed to [1] separately.

   .. rubric:: 1. Why use a frequency-based bispectral method?

   An electron drift instability (EDI) can draw energy from the relative drift
   of magnetized electrons and ions. In a Hall discharge the electron drift is
   mainly in the crossed-field direction. Electrons orbit the magnetic field;
   their response can be enhanced near Doppler-shifted cyclotron harmonics.
   This gives candidate resonances, not a rule that every spectral peak is an EDI.

   To diagnose growth and coupling, one would like to know how each wave component
   changes between positions. Small wavelengths and fast oscillations make a dense,
   well-resolved spatial probe array difficult. Two time records are more accessible,
   but their separation can span many wavelengths: the measured phase does not
   uniquely determine a wavenumber. The article replaces spatial Fourier labels
   by temporal frequency labels, using an assumed single-branch correspondence,
   and obtains group velocity from a theoretical dispersion relation.

   The advance is the connection from **measured higher-order moments to fitted
   linear and quadratic coefficients, then to rates**. A power spectrum alone
   only tells us where fluctuation power is present. A bispectrum measures a
   three-frequency statistical relationship; the fitted coefficient supplies the
   additional dynamical weighting. Frequency analysis does not itself remove
   spatial aliasing or prove that one branch is present.

   .. raw:: html

      <details class="k05-note"><summary>What was actually measured in the original experiment?</summary>

   Figure 1 of [1] locates the probes in the H9 Hall thruster. The experiment used
   xenon at a 300 V, 15 A discharge, or 4.5 kW. Two ion-saturation probes were
   separated azimuthally by 1 cm and placed 6 mm downstream of the exit.
   Each signal contained two million samples at 100 million samples per second;
   the authors divided the record into 2000 realizations for ensemble averages.
   These are the source experiment's settings, not the C1/C3 geometry or the
   2048-sample segmentation used in the present analysis.

   The probes directly recorded an ion-current-related signal. Interpreting that
   signal as density fluctuation requires a probe-response assumption; relating
   density to potential requires an additional plasma-wave response model.
   It is therefore not a direct measurement of fluctuating potential or electric
   field. The authors also discuss possible probe perturbation and spatial aliasing.
   Our :ref:`probe page <k05-response-en>` explains the corresponding measurement
   chain for C1/C3. This distinction matters when comparing absolute PSD levels,
   coefficient units and energy-transfer interpretations.

   .. raw:: html

      </details>

   .. rubric:: 2. Follow the logic of Figure 2: response, spectrum, then growth

   .. figure:: /_static/K_Diagnostics/k05-reading-dispersion-schematic.svg
      :width: 100%
      :alt: Independent dimensionless diagrams of dispersion, two spectra and drive or damping, calculated from stated illustrative functions.

      Schematic 1. Independently drawn to explain the questions behind Figure 2
      of [1]; not a reproduction, fit or numerical reconstruction of its data.
      All axes are dimensionless and the scale constants are arbitrary.

   Panel A illustrates a frequency–wavenumber relation whose slope supplies
   a group velocity. B illustrates two nearby spectra. C illustrates positive
   drive and negative damping. The curves are separate prescribed examples,
   not a self-consistent kinetic solution or inferred measurement. In the
   actual article, Figure 2(c) compares a coefficient-based diagnostic with
   a kinetic growth calculation; :ref:`the C1/C3 counterparts <k05-comparison-en>`
   explain that distinction for the present experiment.

   The article reports growth features near several common frequencies, an
   inferred azimuthal rate roughly an order of magnitude below its theoretical
   rate, and negative inferred growth near about 1.5 MHz. The last feature is
   associated there with the modified two-stream instability (MTSI), a low-frequency
   branch related to the EDI when finite parallel structure matters. That mode
   name depends on the dispersion and background conditions, not on frequency alone.

   When consulting original Figure 2(c) in [1], notice its left and right axes: their scales differ by ten.
   Similar line heights do not mean equal rates. The original (a) also labels
   its ordinate with :math:`\omega_k` and Hz, whereas its text defines
   :math:`f=\omega/(2\pi)`. K05 consistently uses angular frequency in the solver
   and ordinary frequency in the plotted Hz axis. The printed label alone leaves
   the original plotting convention unresolved; do not use a visual slope ratio
   as an experimental speed measurement.

   .. raw:: html

      <details class="k05-note"><summary>Why can the azimuthal diagnostic differ from the total theoretical growth?</summary>

   Equation (2) contains three spatial derivatives. Moving the axial and radial
   terms to the right and taking their amplitude part gives

   .. k05:equation:: paper-transverse-growth
      :lang: en

      \begin{aligned}
      \gamma_f^{(y)}&=\gamma_f-\operatorname{Re}\!\left[
       C_f^{-1}(v_{g,x}\partial_x C_f+v_{g,z}\partial_z C_f)\right],\\
      \gamma_f-\gamma_f^{(y)}&\simeq
       \frac{v_{g,x}}{2P_f}\partial_xP_f+
       \frac{v_{g,z}}{2P_f}\partial_zP_f.
      \end{aligned}

   :math:`x,y,z` here retain the article's axial, azimuthal and radial directions.
   :math:`C_f` is the local Fourier amplitude and must be nonzero in the first line.
   For a representative amplitude, :math:`P_f=|C_f|^2`, so
   :math:`\operatorname{Re}(C_f^{-1}\partial_x C_f)=\partial_xP_f/(2P_f)`.
   For ensemble powers, the second line additionally requires compatible local
   averaging and transport assumptions. It is not a new measured correction.

   A wave can leave the local region through another direction even while it
   extracts energy from particles. Hence :math:`\gamma_f^{(y)}` need not equal
   :math:`\gamma_f`. The article discusses two interpretations: a changed electron
   distribution reducing the kinetic drive (quasilinear feedback), or important
   axial convection, with :math:`v_{g,x}\approx v_p` in its chosen approximation.
   It does not uniquely select one cause. Nor does a C1/C3 difference alone
   measure the missing axial or radial gradients.

   .. raw:: html

      </details>

   .. rubric:: 3. Follow the logic of Figure 3: coefficients first, signed transfer second

   .. figure:: /_static/K_Diagnostics/k05-reading-transfer-schematic.svg
      :width: 100%
      :alt: Independent difference-frequency coefficient geometry and a separately prescribed signed contribution profile, with arbitrary normalized scales.

      Schematic 2. An independent illustration inspired by the interpretation
      of Figure 3 in [1]. A shows a possible coefficient pattern for positive
      sum frequencies; B prescribes a positive-low/negative-high contribution.
      B is not computed from A: magnitudes alone cannot provide its sign.
      These are illustrative functions, not either experiment's results.

   A negative frequency is the conjugate partner of a positive-frequency
   component of a real signal. For example, the marked pair at 3 and −2 in units of :math:`f_0` feeds
   the target :math:`f_0`; it is a difference interaction, not a negative-energy wave.
   In schematic A, large coefficients near the opposite-sign diagonal therefore connect
   relatively high input frequencies to a smaller sum frequency. Coefficient
   magnitudes alone still do not give the sign or amount of transferred power.

   To calculate a measured transfer curve, unlike prescribed schematic B,
   multiply each complex coefficient by its three-frequency moment,
   remove the reference propagation phase, take the real part and sum all retained
   pairs. In the article, the nonlinear contribution is negative in a higher
   frequency region around 5–10 MHz and positive below about 2 MHz.
   Together with the growth/damping pattern in Figure 2(c), the authors interpret
   this as an inverse transfer toward lower-frequency, longer-wavelength modes,
   followed by damping there. That frequency-to-length interpretation depends
   on the chosen dispersion branch.

   The article also flags a feature near a 45 MHz sum frequency as potentially
   nonphysical because the signals approach the noise floor. This is why a bright
   coefficient region, especially with weak inputs, is not sufficient evidence
   on its own. A summed transfer curve does not uniquely identify every donor–receiver
   pair, and voltage-square transfer is not automatically a calibrated plasma-energy flux.

   .. raw:: html

      <details class="k05-note"><summary>Functions used to draw these schematics</summary>

   All quantities below are dimensionless. Scale constants :math:`f_0,k_0,P_0,\gamma_0,Q_0,T_0` are arbitrary positive reference values. The script imports NumPy as ``np``; these functions teach shapes, not fitted physical parameters.

   .. code-block:: python

      # u=f/f0; a=f1/f0; b=f2/f0; x=ky/k0; arbitrary positive scales
      G = lambda u, m, w: np.exp(-((u-m)/w)**2)
      frequency = x + 0.06*np.sin(np.pi*x)
      P1 = 0.15 + G(u,1,.5) + .6*G(u,3,.3) + .35*G(u,5,.3)
      P2 = .95*P1
      gamma = .7*G(u,3,.5) + .5*G(u,5,.5) - .5*G(u,1,.4)
      Qabs = np.exp(-((a+b-1)/.32)**2)*np.exp(-((a-b)/6)**2)*(a*b<0)
      T = G(u,1,.45)-G(u,3,.45)  # prescribed independently of Qabs

   .. raw:: html

      </details>

   .. rubric:: 4. Saturation does not mean that growth and coupling disappear

   A statistically stationary spectrum can have continuing drive and continuing
   loss. For the local mean-square convention used in K05, the ideal one-dimensional
   balance is

   .. k05:equation:: paper-saturated-balance
      :lang: en

      v_{g,y}\partial_yP_f
      =2\gamma_f^{(y)}P_f+2T_f^{(1/2)},
      \qquad \partial_yP_f\simeq0\ \Longrightarrow\
      \gamma_f^{(y)}P_f+T_f^{(1/2)}\simeq0.

   :math:`P_f` is a frequency-bin mean square, not a PSD per Hz;
   :math:`T_f^{(1/2)}` uses the half-rate convention corresponding to reference
   Eq. (6). A full nonlinear mean-square rate is :math:`2T_f^{(1/2)}`.
   The right-hand statement additionally assumes local azimuthal uniformity and
   the adequacy of the retained model. With finite probe spacing or measured
   residuals, use :ref:`the complete budget <k05-budget-en>` instead.

   Thus a source band can have positive linear growth and negative nonlinear
   contribution, while a receiving band has positive nonlinear contribution and
   negative linear growth. The sustained spectrum reflects these competing
   processes; saturation does not require every :math:`\gamma_f` to vanish.

   The measurement in [1] concerns the **final statistically stationary state**.
   It does not observe the full startup sequence of linear growth, nonlinear
   development and saturation. Kim's equal-model-power condition is also an
   input to estimation, so an apparent balance obtained after imposing that
   condition is not, by itself, an independent proof of the saturation mechanism.

   .. rubric:: 5. Trace each published result through K05

   .. list-table::
      :class: k05-reading-table
      :header-rows: 1
      :widths: 24 43 33

      * - Result in [1]
        - Calculation path
        - Meaning of the C1/C3 counterpart
      * - Figure 2(a): dispersion
        - :ref:`Response and group velocity <k05-coefficients-en>` → :ref:`original Eq. (7) and its specialization <k05-source-7-en>`
        - Estimated kinetic scenario; not a measured dispersion.
      * - Figure 2(b): spectra
        - :ref:`Fourier coefficients <k05-probe-signals-en>` → :ref:`statistics <k05-statistics-en>` → :ref:`experimental spectra <k05-experiment-en>`
        - Measured voltage PSD to 50 MHz; amplitude conventions must match for absolute comparison.
      * - Figure 2(c): growth
        - :ref:`Eqs. (3)–(5), coefficient inference <k05-inference-en>` → :k05:eq:`comparison-rate`
        - Four-split conditional rates; least squares and Kim are two estimators of the same linear-plus-quadratic model.
      * - Figure 3(a): coupling map
        - Jointly estimate :math:`Q` → :k05:eq:`comparison-symmetric-q`
        - Magnitude of fitted coefficients, not squared bicoherence or signed transfer.
      * - Figure 3(b): transfer
        - :ref:`Original Eq. (6) <k05-source-6-en>` → :k05:eq:`comparison-transfer`
        - Signed voltage-domain proxy, not an established inverse cascade in these records.

   The extra :ref:`prediction checks <k05-validation-en>`,
   :ref:`probe-response discussion <k05-response-en>` and
   :ref:`power-budget checks <k05-budget-en>` connect the algebra to this actual
   measurement. The four-split coefficient band is 0.537–4.980 MHz; the separate
   5–20 MHz prediction example is not a four-split Kim transfer analysis.
   Only 35 of 368 current frequency–split cases pass the necessary common-power
   bound. Passing that bound would still not verify all physical assumptions.

   The method and the article's interpretation can now be followed end to end.
   For this experiment, mode identification, response calibration and a justified
   frequency–wavevector/group-velocity relation remain scientific questions.
   The article motivates a connection to anomalous cross-field electron transport,
   but neither a :math:`|Q|` map nor these voltage records alone directly measure
   the density–electric-field correlation needed for that transport.

   .. raw:: html

      <details class="k05-note"><summary>A compact symbol guide for rereading</summary>

   .. list-table::
      :class: k05-reading-table
      :header-rows: 1
      :widths: 27 73

      * - Symbol
        - Meaning and distinction
      * - :math:`A_a`, :math:`\phi_a`, :math:`C_f`
        - Slow envelope; full complex component; time-Fourier coefficient retaining spatial phase. The article uses a hat for more than one of these roles.
      * - :math:`f`, :math:`\omega`, :math:`k_y`
        - Hz; rad/s; rad/m. Group speed is :math:`\partial\omega_r/\partial k_y`, not simply :math:`\partial f/\partial k_y`.
      * - :math:`\gamma_f`, :math:`\gamma_f^{(y)}`
        - Total/model amplitude growth; effective azimuthal amplitude growth. Mean-square growth has an extra factor 2.
      * - :math:`L,Q`, :math:`\widetilde L,\widetilde Q`, :math:`V^Q`
        - Discrete coefficients; phase-rotated coefficients; continuous quadratic coefficient. Pair counting and observable units matter.
      * - :math:`P_f`, :math:`S_V(f)`
        - Bin mean square in V²; voltage PSD in V²/Hz. Their different normalizations cannot be silently interchanged.
      * - :math:`B`, :math:`b^2`, :math:`|Q|`, :math:`T_f`
        - Bispectrum; squared bicoherence; coefficient magnitude; signed transfer. They answer different questions.
      * - :math:`X,Y`
        - Probe Fourier coefficients in the inference pages; dimensionless Gordeev arguments only in the dielectric formula.
      * - :math:`T_e`, :math:`\rho`, :math:`\epsilon`
        - Temperature must be converted to an energy for the kinetic formulas; :math:`\rho` there is a Larmor radius, while :math:`\rho_1` is charge density; residual :math:`\varepsilon` is not dielectric :math:`\epsilon^{(1)}`.

   .. raw:: html

      </details>

   .. rubric:: Reference

   [1] Z. A. Brown and B. A. Jorns (2023), “Growth and Saturation of the Electron
   Drift Instability in a Crossed Field Plasma,” *Physical Review Letters*
   **130**, 115101, Eqs. (1)–(7), Figs. 1–3 and pp. 115101-4–5.
   `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.
   The original figures can be consulted at the DOI link. Only independently
   constructed teaching schematics are embedded on this page.

.. container:: ap-lang ap-lang-zh k05-lesson

   .. _k05-synthesis-zh:

   .. rubric:: 把方程、图形和物理结论接起来

   现在可以回到 Brown 与 Jorns [1] 标题中的问题： **什么过程给波动供能，
   什么过程重新分配波动，有限幅度的频谱为什么能维持？**
   前面的页面解释了反演方法，并应用到 C1/C3 数据。
   本页阅读原论文的证据，明确它与新实验的区别。
   下方为参考文献[1]的问题与图意、独立绘制的示意图，未提取或描摹原文数据，也不是C1/C3测量。
   关于论文的定量结论另行注明来自文献[1]，不要从示意曲线上读取论文数值。

   .. rubric:: 1．为什么要做基于频率的双谱分析？

   电子漂移不稳定性（electron drift instability, EDI）可以从磁化电子与离子的相对漂移中获得能量。
   在 Hall 放电中，电子主要沿交叉场方向漂移，同时绕磁场回旋。
   当多普勒频移后的扰动接近电子回旋谐波时，响应可能增强。
   这给出了候选共振机制，不表示每个频谱峰都是 EDI。

   诊断增长和耦合，需要知道各波分量在两个位置之间怎样变化。
   小波长和快速振荡使密集、高空间分辨率的探针阵列很难实现。
   两条时间记录更容易取得，但探针间距可能跨越多个波长，所测相位便不能唯一给出波数。
   论文用时间频率标签代替空间 Fourier 标签，同时假设合适的单分支对应关系，
   并从理论色散关系取得群速度。

   方法的关键是把 **实测高阶统计矩连接到线性／二次系数，再连接到变化率**。
   功率谱本身只说明波动功率在哪里；双谱说明三频率统计关系；
   拟合系数进一步提供动力学权重。频率分析本身不会消除空间混叠，
   也不会自动证明信号只含一条波模分支。

   .. raw:: html

      <details class="k05-note"><summary>原文实验实际测量了什么？</summary>

   文献 [1] 图 1 标出了 H9 霍尔推力器中的探针位置。实验使用氙气，放电为
   300 V、15 A，即 4.5 kW。两支离子饱和探针（ion-saturation probes）周向相距
   1 cm，位于出口下游 6 mm。每路以每秒一亿点采集两百万点，再分成
   2000 段作集合平均。这些是原文实验的设置，不是本例 C1/C3 的几何，
   也不是本例每段 2048 点的分析设置。

   探针直接记录的是与离子电流有关的信号。把它解释为密度波动需要探针响应假设；
   把密度连接到电势还需要等离子体波的响应模型。因此，这不是直接测得的电势或电场波动。
   原文也讨论了探针对等离子体的扰动及空间混叠问题。
   :ref:`探针页面 <k05-response-zh>` 解释本例 C1/C3 对应的测量链。
   比较功率谱绝对幅度、系数单位和能量转移含义时，需要保留这层区别。

   .. raw:: html

      </details>

   .. rubric:: 2．理解文献图2的逻辑：先响应，再频谱，再增长率

   .. figure:: /_static/K_Diagnostics/k05-reading-dispersion-schematic.svg
      :width: 100%
      :alt: 用给定示例函数独立绘制的无量纲色散、双位置频谱及驱动和阻尼示意。

      示意图1．参考文献[1]图2的问题与图意独立绘制，不是原图转载、数据拟合或数值复原。
      各轴均已无量纲化，尺度常数为任意正值。

   A示意频率—波数关系，其斜率提供群速度；B示意两处相近的频谱；C示意正驱动与负阻尼。
   三组曲线分别由示例函数给定，不是一套自洽动理学解，也不是反演的测量结果。
   实际文献图2(c)比较由拟合系数得到的诊断增长与动理学模型增长；
   :ref:`C1/C3对应图 <k05-comparison-zh>` 解释本实验里这两类曲线的区别。

   论文报告：几处增长特征出现在相近频率，反演的周向增长率比理论值约小一个数量级，
   而约 1.5 MHz 附近出现负增长。作者把这个低频特征联系到修正双流不稳定性
   （modified two-stream instability, MTSI）：在有限平行结构参与时，与 EDI 相关的一条低频分支。
   波模名称依赖色散和背景条件，不能仅凭频率给它命名。

   查阅文献[1]原图2(c)时，注意其左右轴相差十倍：曲线在同一高度，不表示增长率相等。
   原图 (a) 以 :math:`\omega_k` 标记纵轴却使用 Hz，正文则定义
   :math:`f=\omega/(2\pi)`。K05 在求解器中使用角频率、在 Hz 图轴上使用普通频率。
   仅凭原图标签，作者的绘图转换尚未完全核实；不要把视觉斜率之比直接当成实验波速之比。

   .. raw:: html

      <details class="k05-note"><summary>为什么周向诊断增长率可能不同于总的理论增长率？</summary>

   式 (2) 包含三个方向的空间导数。把轴向、径向项移到右边，取其中改变幅值的部分，可写成

   .. k05:equation:: paper-transverse-growth
      :lang: zh

      \begin{aligned}
      \gamma_f^{(y)}&=\gamma_f-\operatorname{Re}\!\left[
       C_f^{-1}(v_{g,x}\partial_x C_f+v_{g,z}\partial_z C_f)\right],\\
      \gamma_f-\gamma_f^{(y)}&\simeq
       \frac{v_{g,x}}{2P_f}\partial_xP_f+
       \frac{v_{g,z}}{2P_f}\partial_zP_f.
      \end{aligned}

   这里 :math:`x,y,z` 保留原文的轴向、周向、径向定义。
   :math:`C_f` 是局部 Fourier 幅值，第一行要求它非零。
   对代表性幅值，:math:`P_f=|C_f|^2`，所以
   :math:`\operatorname{Re}(C_f^{-1}\partial_x C_f)=\partial_xP_f/(2P_f)`。
   若使用集合平均功率，第二行还需要相容的局部平均和输运假设；它不是已经测得的额外修正。

   波一边从粒子取得能量，也可能一边沿其他方向离开局部区域，
   因此 :math:`\gamma_f^{(y)}` 不必等于 :math:`\gamma_f`。
   论文讨论两种解释：电子分布受波动改变、使驱动减弱，即准线性反馈（quasilinear feedback）；
   或者轴向对流（axial convection）很重要，在作者采用的近似下有 :math:`v_{g,x}\approx v_p`。
   论文没有唯一确定是哪一种原因；两支 C1/C3 探针也不能单独测出缺失的轴向、径向梯度。

   .. raw:: html

      </details>

   .. rubric:: 3．理解文献图3的逻辑：系数大小之后，还要看有符号转移

   .. figure:: /_static/K_Diagnostics/k05-reading-transfer-schematic.svg
      :width: 100%
      :alt: 独立构造的差频系数几何与另行给定的正负贡献曲线，使用任意归一化尺度。

      示意图2．参考文献[1]图3的解释独立绘制。A给出正和频目标的一种系数分布，
      B另行给定低频正、高频负的贡献。B不是由A计算得到的：单凭系数模不能确定符号。
      两图均为示例函数，不是原文或本实验结果。

   实信号的负频率是正频率的共轭伙伴。
   例如图中标出的 :math:`3f_0+(-2f_0)=f_0`，这是差频相互作用，不是负能量波。
   因此，示意A中异号对角线附近的大系数连接了较高输入频率与较低的和频目标。
   但系数模本身仍没有给出实际转移的符号或大小。

   若要算出真实数据的转移曲线，而不是像示意B那样预设曲线，还要将每个复系数乘以对应三频率统计矩，去参考传播相位，取实部，再对保留波对求和。
   论文中，约 5–10 MHz 的较高频段为负非线性贡献，约 2 MHz 以下为正贡献。
   结合图 2(c) 的增长／阻尼分布，作者将其解释为向较低频率、较长波长的逆向转移，
   随后在低频分支中通过阻尼损失能量。
   这里从“低频”说到“长波长”，仍依赖选定的色散分支。

   论文还指出，和频约 45 MHz 附近的特征可能不物理，因为相关信号已接近噪声底。
   这说明明亮的系数区域，尤其当输入很弱时，不能独立作为物理结论。
   求和后的转移曲线也不能唯一确定每一对供能者与接收者；电压平方转移不自动等于标定后的等离子体能量通量。

   .. raw:: html

      <details class="k05-note"><summary>示意图具体用什么函数绘制？</summary>

   以下各量均已无量纲化；:math:`f_0,k_0,P_0,\gamma_0,Q_0,T_0` 是任意正参考尺度。代码用 ``np`` 表示NumPy。这些函数用于讲图意，不是拟合出的物理参数。

   .. code-block:: python

      # u=f/f0; a=f1/f0; b=f2/f0; x=ky/k0; arbitrary positive scales
      G = lambda u, m, w: np.exp(-((u-m)/w)**2)
      frequency = x + 0.06*np.sin(np.pi*x)
      P1 = 0.15 + G(u,1,.5) + .6*G(u,3,.3) + .35*G(u,5,.3)
      P2 = .95*P1
      gamma = .7*G(u,3,.5) + .5*G(u,5,.5) - .5*G(u,1,.4)
      Qabs = np.exp(-((a+b-1)/.32)**2)*np.exp(-((a-b)/6)**2)*(a*b<0)
      T = G(u,1,.45)-G(u,3,.45)  # prescribed independently of Qabs

   .. raw:: html

      </details>

   .. rubric:: 4．饱和不表示增长和耦合全部消失

   统计平稳的频谱，可以同时存在持续驱动和持续损失。
   在 K05 的局部模平方约定下，理想一维收支为

   .. k05:equation:: paper-saturated-balance
      :lang: zh

      v_{g,y}\partial_yP_f
      =2\gamma_f^{(y)}P_f+2T_f^{(1/2)},
      \qquad \partial_yP_f\simeq0\ \Longrightarrow\
      \gamma_f^{(y)}P_f+T_f^{(1/2)}\simeq0.

   :math:`P_f` 是频点均方量，不是每 Hz 的 PSD；
   :math:`T_f^{(1/2)}` 采用对应文献式 (6) 的半变化率约定，
   完整非线性模平方变化率是 :math:`2T_f^{(1/2)}`。
   右侧关系还要求局部周向均匀，并且所保留的模型足够描述信号。
   对于有限探针间距和实测残差，应回到 :ref:`完整收支 <k05-budget-zh>`。

   于是，供能频带可以有正线性增长、负非线性贡献；
   接收频带可以有正非线性贡献、负线性增长。
   频谱维持在有限幅度，是这些过程竞争的结果，并不要求每个 :math:`\gamma_f` 都变为零。

   文献 [1] 测量的是 **最终统计平稳状态**，没有观测启动时的线性增长、
   非线性发展、饱和这一整段时间历程。
   而且 Kim 的两处模型功率相等是估计时输入的条件；
   施加该条件后出现的表观平衡，本身不是饱和机制的独立验证。

   .. rubric:: 5．把论文的每个结果接回 K05

   .. list-table::
      :class: k05-reading-table
      :header-rows: 1
      :widths: 24 43 33

      * - 文献结果
        - 计算路线
        - C1/C3 对应结果的含义
      * - 图 2(a)：色散
        - :ref:`响应与群速度 <k05-coefficients-zh>` → :ref:`原式 (7) 及简化 <k05-source-7-zh>`
        - 估计参数下的动理学情景，不是实测色散。
      * - 图 2(b)：频谱
        - :ref:`Fourier 系数 <k05-probe-signals-zh>` → :ref:`统计量 <k05-statistics-zh>` → :ref:`实测谱 <k05-experiment-zh>`
        - 到 50 MHz 的实测电压 PSD，绝对幅值对比仍须统一归一化。
      * - 图 2(c)：增长
        - :ref:`式 (3)–(5) 的系数反演 <k05-inference-zh>` → :k05:eq:`comparison-rate`
        - 四轮条件增长率，Least squares 与 Kim 是同一线性＋二次模型的两种估计器。
      * - 图 3(a)：耦合图
        - 联合估计 :math:`Q` → :k05:eq:`comparison-symmetric-q`
        - 拟合系数的模，不是平方双相干，也不是带符号的转移。
      * - 图 3(b)：转移
        - :ref:`原式 (6) <k05-source-6-zh>` → :k05:eq:`comparison-transfer`
        - 电压观测量下的有符号代理，并非本实验已确认的逆级联。

   额外的 :ref:`预测验证 <k05-validation-zh>`、
   :ref:`探针响应说明 <k05-response-zh>` 和 :ref:`功率收支检查 <k05-budget-zh>`，
   把代数方法连接到这组具体测量。
   四轮系数的目标频带为 0.537–4.980 MHz；另做的 5–20 MHz 预测示例，
   不是四轮 Kim 转移分析。目前 368 个频点×轮次案例中，只有 35 个通过共同功率必要上界，
   即使通过这一上界，也不表示全部物理条件都已验证。

   至此，方法和论文解释可以从头追踪到尾。
   对于本实验，波模识别、响应标定及可靠的频率—波矢／群速度关系仍是科学问题。
   论文进一步提出这类测量有助于理解反常跨场电子输运；
   但 :math:`|Q|` 图或目前的电压记录本身，没有直接测得该输运所需的密度—电场相关项。

   .. raw:: html

      <details class="k05-note"><summary>重读时可查的简短符号表</summary>

   .. list-table::
      :class: k05-reading-table
      :header-rows: 1
      :widths: 27 73

      * - 符号
        - 含义与区别
      * - :math:`A_a`、:math:`\phi_a`、:math:`C_f`
        - 慢包络、完整复波分量、保留空间相位的时间 Fourier 系数；文献的帽子承担不止一种含义。
      * - :math:`f`、:math:`\omega`、:math:`k_y`
        - 分别为 Hz、rad/s、rad/m；群速度是 :math:`\partial\omega_r/\partial k_y`，不是直接的 :math:`\partial f/\partial k_y`。
      * - :math:`\gamma_f`、:math:`\gamma_f^{(y)}`
        - 总的／模型幅值增长率、有效周向幅值增长率；均方量增长多一个因子 2。
      * - :math:`L,Q`、:math:`\widetilde L,\widetilde Q`、:math:`V^Q`
        - 离散系数、去相位后的系数、连续二次系数；波对计数与观测量单位都影响对应关系。
      * - :math:`P_f`、:math:`S_V(f)`
        - V² 的频点均方量、V²/Hz 的电压 PSD；不同归一化不能悄悄互换。
      * - :math:`B`、:math:`b^2`、:math:`|Q|`、:math:`T_f`
        - 双谱、平方双相干、系数模、有符号转移；它们回答不同问题。
      * - :math:`X,Y`
        - 反演页面中是双探针 Fourier 系数；只有介电公式中是 Gordeev 无量纲参数。
      * - :math:`T_e`、:math:`\rho`、:math:`\epsilon`
        - 动理学公式中的温度须换成能量；其中 :math:`\rho` 是 Larmor 半径，:math:`\rho_1` 才是电荷密度；残差 :math:`\varepsilon` 不是介电函数 :math:`\epsilon^{(1)}`。

   .. raw:: html

      </details>

   .. rubric:: 参考文献

   [1] Z. A. Brown and B. A. Jorns (2023), “Growth and Saturation of the Electron
   Drift Instability in a Crossed Field Plasma,” *Physical Review Letters*
   **130**, 115101，式 (1)–(7)、图 1–3 及第 115101-4–5 页。
   `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_。
   原图请通过DOI链接查阅；本页仅嵌入独立构造的教学示意图。

