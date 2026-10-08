.. rst-class:: ap-g02 ap-g02-reference

MCC methods and verification references
=======================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. _g02-method-references-zh:

   .. rubric:: 方法出处与实现对应

   下列文献给出 G02 所用抽样方法的理论依据。引用说明的是方法对应关系，
   不表示 G02 逐行移植了论文程序，也不把通用反应接口当成某种实际气体的完整模型。

   .. list-table:: 从流程到文献
      :header-rows: 1
      :widths: 25 45 30

      * - G02 环节
        - 对应代码与含义
        - 文献依据
      * - 空碰撞与频率上界
        - ``fun_G02_mcc_engine.cpp`` 用总上界产生候选，以通道真实频率与上界之比接受；拒绝也消耗时间。
        - Skullerud [S68]；PIC-MCC 背景见 Vahedi 与 Surendra [VS95]。
      * - 指数时钟与通道选择
        - C01 用 ``-log1p(-u)/Lambda`` 抽等待时间，按通道上界份额选择候选通道，并继续剩余时间。
        - Gillespie [G77] 第 III.B 节、式 (21a–b) 的指数等待与竞争通道抽样；G02 另有空碰撞筛选。
      * - 热背景与两体运动学
        - 候选先从 Maxwell 分布抽背景速度，再以 ``n*sigma(g)*g`` 接受；``fun_G02_mcc_kinematics.cpp`` 在质心系生成两体末态。
        - Ristivojevic 与 Petrović [RP12] 第 III、V.A 节。

   对固定背景、当前粒子状态及有效上界，令 :math:`\Lambda=\sum_j\Lambda_j`。
   G02 将文献中的抽样原则组合为下面的候选流程：

   .. math::

      \tau=-\frac{\ln(1-u)}{\Lambda},\qquad
      P(j\mid\mathrm{candidate})=\frac{\Lambda_j}{\Lambda},\qquad
      P(\mathrm{accept}\mid j,\mathbf w)=\frac{\nu_j(\mathbf v,\mathbf w)}{\Lambda_j}.

   因而通道 :math:`j` 的接受事件率是
   :math:`\Lambda(\Lambda_j/\Lambda)(\nu_j/\Lambda_j)=\nu_j`。
   对截面通道，背景速度提议密度 :math:`F_B(\mathbf w)` 经过接受步骤后，
   真实碰撞中的背景速度密度正比于
   :math:`F_B(\mathbf w)\sigma_j(g)g`，:math:`g=|\mathbf v-\mathbf w|`。
   这对应 [RP12] 式 (22) 的条件分布；不能先判真实碰撞，再无条件抽一次 Maxwell 速度。
   该解释要求上界覆盖允许的采样域；G02 遇到超界会报错。

   温度速率系数通道直接使用 :math:`nk(T)` 或 :math:`n_1n_2k(T)`，
   其速度抽样是模型给定的闭合，不能仅凭热平均速率还原任意微分截面。
   背景在每次调用内固定，新产物从下一步参与；批量提交、ID 分配、CSV 模式以及
   C02–C08 的通用多产物闭合是本库的实现选择，不由上述文献自动保证物理有效性。

   .. _g02-test-references-zh:

   .. rubric:: 测试依据与验证范围

   Parodi 与 Petronio [PP25] 讨论将 PIC-MCC 分模块并与解析结果比较的验证方法。
   本库下列用例按自身模型核对，不声称复现该论文的七个算例，也没有使用其数值数据。

   .. list-table:: 测试与判据
      :header-rows: 1
      :widths: 28 45 27

      * - 测试
        - 判据来源
        - 范围
      * - ``cpp/test_c01.cpp``
        - [S68]、[G77] 的时钟与筛选原理：恒频率下计数为 Poisson，均值与方差均为 :math:`\nu t`，真实通道份额为 :math:`\nu_j/\sum_k\nu_k`。
        - 合成常数速率；也检查零事件及多事件概率。
      * - ``cpp/test_algorithms.cpp``
        - 动量、能量、电荷及反应账本；两体质心运动学参见 [RP12] 第 V.A 节。
        - 验证已配置末态的约束，不验证实际气体截面或多产物微分分布。
      * - ``examples/collision_box/main.cpp``
        - 下文由等质量、恒频率、各向同性模型推导的一、二阶矩和 Poisson 计数；另检查 Maxwell 平衡分布。
        - 本库构造的解析验证题，不是 [VS95] 的氩/氧放电或 [RP12] 的离子输运基准复现。
      * - schema、interpolation、batch、MPI/OpenMP
        - 输入约束、插值公式、事务一致性及串并行一致性。
        - 软件回归，不需要借用某个物理实验作为出处。

   .. _g02-box-derivation-zh:

   .. rubric:: 碰撞盒理论曲线的推导

   这里补出 ``reference()`` 的解析依据。A、B 质量同为 :math:`m`，背景零漂移、
   温度 :math:`T_B` 固定；每个 A 以与速度无关的频率 :math:`\nu=n_Bk` 碰撞。
   两体弹性碰撞后，在质心系均匀抽单位向量 :math:`\boldsymbol\omega`：

   .. math::

      \mathbf v'=\frac{\mathbf v+\mathbf w}{2}
                    +\frac{|\mathbf v-\mathbf w|}{2}\boldsymbol\omega.

   对背景速度和散射方向平均，利用 :math:`\mathbb E\mathbf w=0`、
   :math:`\mathbb E|\mathbf w|^2=3k_BT_B/m\equiv Q_B` 及
   :math:`\mathbb E\boldsymbol\omega=0`，得到

   .. math::

      \mathbb E[\mathbf v'\mid\mathbf v]=\tfrac12\mathbf v,\qquad
      \mathbb E[|\mathbf v'|^2\mid\mathbf v]=\tfrac12(|\mathbf v|^2+Q_B).

   若 :math:`N(t)\sim\mathrm{Poisson}(\nu t)`，则
   :math:`\mathbb E[2^{-N(t)}]=\exp(-\nu t/2)`。所以以实测初始矩 :math:`U_0,Q_0` 为起点，

   .. math::

      U(t)=U_0e^{-\nu t/2},\qquad
      Q(t)=Q_B+(Q_0-Q_B)e^{-\nu t/2},\qquad
      T(t)=\frac{m}{3k_B}\left(Q(t)-|U(t)|^2\right).

   这是当前测试模型的推导，引用用于说明抽样和两体力学基础，不表示论文给出了本库的参数与曲线。
   恒定截面通常仍有 :math:`\nu\propto g`，不能代替这里的恒定频率假设。
   六倍标准误差等通过阈值由测试代码选择，不是文献规定的通用精度标准。

   .. rubric:: 参考文献

   - **[S68]** H. R. Skullerud, “The stochastic computer simulation of ion motion in a gas subjected to a constant electric field,” *Journal of Physics D: Applied Physics* **1**, 1567–1568 (1968). `DOI: 10.1088/0022-3727/1/11/423 <https://doi.org/10.1088/0022-3727/1/11/423>`_.
   - **[VS95]** V. Vahedi and M. Surendra, “A Monte Carlo collision model for the particle-in-cell method: applications to argon and oxygen discharges,” *Computer Physics Communications* **87**, 179–198 (1995). `DOI: 10.1016/0010-4655(94)00171-W <https://doi.org/10.1016/0010-4655(94)00171-W>`_.
   - **[G77]** D. T. Gillespie, “Exact stochastic simulation of coupled chemical reactions,” *The Journal of Physical Chemistry* **81**, 2340–2361 (1977). `DOI: 10.1021/j100540a008 <https://doi.org/10.1021/j100540a008>`_.
   - **[RP12]** Z. Ristivojevic and Z. Lj. Petrović, “A Monte Carlo simulation of ion transport at finite temperatures,” *Plasma Sources Science and Technology* **21**, 035001 (2012). `DOI: 10.1088/0963-0252/21/3/035001 <https://doi.org/10.1088/0963-0252/21/3/035001>`_; `开放全文 <https://arxiv.org/abs/0806.0401>`_.
   - **[PP25]** P. Parodi and F. Petronio, “Step-by-step verification of particle-in-cell Monte Carlo collision codes,” *Physics of Plasmas* **32**, 013902 (2025). `DOI: 10.1063/5.0241527 <https://doi.org/10.1063/5.0241527>`_.

.. container:: ap-lang ap-lang-en

   .. _g02-method-references-en:

   .. rubric:: Methods and implementation mapping

   These references establish the sampling principles used by G02. The mapping
   does not claim a line-by-line port of a paper's code or a complete real-gas
   model merely from the availability of generic reaction interfaces.

   .. list-table:: From the workflow to the literature
      :header-rows: 1
      :widths: 25 45 30

      * - G02 step
        - Implementation and meaning
        - Basis
      * - Null collisions and majorants
        - ``fun_G02_mcc_engine.cpp`` generates candidates from a total bound and accepts with the channel rate/bound ratio. Rejections consume time.
        - Skullerud [S68]; PIC-MCC context in Vahedi and Surendra [VS95].
      * - Exponential clock and channel choice
        - C01 uses ``-log1p(-u)/Lambda``, chooses a candidate channel by its bound share, and continues the remaining time.
        - Gillespie [G77], Sec. III.B, Eqs. (21a–b), for exponential waiting and competing channels; G02 additionally thins candidates.
      * - Thermal partners and binary kinematics
        - Propose a Maxwell background velocity before acceptance with ``n*sigma(g)*g``; ``fun_G02_mcc_kinematics.cpp`` constructs binary outcomes in the centre-of-mass frame.
        - Ristivojevic and Petrović [RP12], Secs. III and V.A.

   For fixed backgrounds, the current particle state, and valid channel bounds,
   let :math:`\Lambda=\sum_j\Lambda_j`. G02 combines these principles as

   .. math::

      \tau=-\frac{\ln(1-u)}{\Lambda},\qquad
      P(j\mid\mathrm{candidate})=\frac{\Lambda_j}{\Lambda},\qquad
      P(\mathrm{accept}\mid j,\mathbf w)=\frac{\nu_j(\mathbf v,\mathbf w)}{\Lambda_j}.

   The accepted rate of channel :math:`j` is therefore
   :math:`\Lambda(\Lambda_j/\Lambda)(\nu_j/\Lambda_j)=\nu_j`.
   For cross-section channels, accepting Maxwell proposals :math:`F_B(\mathbf w)`
   gives a collision-partner density proportional to
   :math:`F_B(\mathbf w)\sigma_j(g)g`, where :math:`g=|\mathbf v-\mathbf w|`.
   This matches the conditional law in [RP12], Eq. (22); drawing an unweighted
   Maxwell partner only after declaring a real collision would not.
   The bound must cover the allowed sampling domain; G02 reports violations.

   Temperature-rate channels use :math:`nk(T)` or :math:`n_1n_2k(T)` directly.
   Their velocity sampling is a specified closure: a thermal rate coefficient
   does not determine an arbitrary differential cross section.
   Backgrounds stay fixed during a call and children start in the next step.
   Batch commits, IDs, CSV schemas and generic C02–C08 multiproduct closures are
   library choices whose physical validity is not established by these citations.

   .. _g02-test-references-en:

   .. rubric:: Verification basis and scope

   Parodi and Petronio [PP25] discuss separate PIC-MCC module checks against
   analytical results. The tests below check their own specified models; they
   neither reproduce that paper's seven cases nor use its numerical data.

   .. list-table:: Tests and their criteria
      :header-rows: 1
      :widths: 28 45 27

      * - Test
        - Basis of the criterion
        - Scope
      * - ``cpp/test_c01.cpp``
        - Clock/thinning principles [S68, G77]: constant-rate counts are Poisson with mean and variance :math:`\nu t`; real-channel shares are :math:`\nu_j/\sum_k\nu_k`.
        - Synthetic constant rates; also checks zero-event and multiple-event probabilities.
      * - ``cpp/test_algorithms.cpp``
        - Momentum, energy, charge and reaction ledgers; binary centre-of-mass kinematics in [RP12], Sec. V.A.
        - Configured outcome constraints, not real-gas cross sections or multiproduct differential distributions.
      * - ``examples/collision_box/main.cpp``
        - Moments derived below for equal masses, constant frequency and isotropic scattering; Poisson counts and a Maxwell equilibrium distribution.
        - A local analytic verification case, not the argon/oxygen discharges of [VS95] or ion-transport benchmark of [RP12].
      * - schema, interpolation, batch, MPI/OpenMP
        - Input constraints, interpolation formulas, transactional behavior and serial/parallel agreement.
        - Software regressions without a borrowed physical experiment.

   .. _g02-box-derivation-en:

   .. rubric:: Derivation of the collision-box reference curves

   This derives ``reference()`` for the implemented test. Both masses are
   :math:`m`; the background has zero drift and fixed temperature :math:`T_B`.
   Each A collides at a velocity-independent frequency :math:`\nu=n_Bk`.
   With a uniformly sampled unit direction :math:`\boldsymbol\omega`, an elastic
   equal-mass event gives

   .. math::

      \mathbf v'=\frac{\mathbf v+\mathbf w}{2}
                    +\frac{|\mathbf v-\mathbf w|}{2}\boldsymbol\omega.

   Average over background velocities and directions using
   :math:`\mathbb E\mathbf w=0`,
   :math:`\mathbb E|\mathbf w|^2=3k_BT_B/m\equiv Q_B` and
   :math:`\mathbb E\boldsymbol\omega=0`:

   .. math::

      \mathbb E[\mathbf v'\mid\mathbf v]=\tfrac12\mathbf v,\qquad
      \mathbb E[|\mathbf v'|^2\mid\mathbf v]=\tfrac12(|\mathbf v|^2+Q_B).

   For :math:`N(t)\sim\mathrm{Poisson}(\nu t)`,
   :math:`\mathbb E[2^{-N(t)}]=\exp(-\nu t/2)`. Starting with the measured initial
   moments :math:`U_0,Q_0` therefore gives

   .. math::

      U(t)=U_0e^{-\nu t/2},\qquad
      Q(t)=Q_B+(Q_0-Q_B)e^{-\nu t/2},\qquad
      T(t)=\frac{m}{3k_B}\left(Q(t)-|U(t)|^2\right).

   This is a derivation for this test model, not a claim that a cited paper
   supplies the library's parameters or curves. A constant cross section
   generally still gives :math:`\nu\propto g` and cannot replace the constant-rate
   assumption. Acceptance thresholds such as six standard errors are choices
   in the tests, not universal accuracy requirements prescribed by the papers.

   .. rubric:: References

   - **[S68]** H. R. Skullerud, “The stochastic computer simulation of ion motion in a gas subjected to a constant electric field,” *Journal of Physics D: Applied Physics* **1**, 1567–1568 (1968). `DOI: 10.1088/0022-3727/1/11/423 <https://doi.org/10.1088/0022-3727/1/11/423>`_.
   - **[VS95]** V. Vahedi and M. Surendra, “A Monte Carlo collision model for the particle-in-cell method: applications to argon and oxygen discharges,” *Computer Physics Communications* **87**, 179–198 (1995). `DOI: 10.1016/0010-4655(94)00171-W <https://doi.org/10.1016/0010-4655(94)00171-W>`_.
   - **[G77]** D. T. Gillespie, “Exact stochastic simulation of coupled chemical reactions,” *The Journal of Physical Chemistry* **81**, 2340–2361 (1977). `DOI: 10.1021/j100540a008 <https://doi.org/10.1021/j100540a008>`_.
   - **[RP12]** Z. Ristivojevic and Z. Lj. Petrović, “A Monte Carlo simulation of ion transport at finite temperatures,” *Plasma Sources Science and Technology* **21**, 035001 (2012). `DOI: 10.1088/0963-0252/21/3/035001 <https://doi.org/10.1088/0963-0252/21/3/035001>`_; `open manuscript <https://arxiv.org/abs/0806.0401>`_.
   - **[PP25]** P. Parodi and F. Petronio, “Step-by-step verification of particle-in-cell Monte Carlo collision codes,” *Physics of Plasmas* **32**, 013902 (2025). `DOI: 10.1063/5.0241527 <https://doi.org/10.1063/5.0241527>`_.
