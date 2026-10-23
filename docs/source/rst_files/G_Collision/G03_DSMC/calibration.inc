.. _g03-calibration:

Parameter Calibration: Viscosity, Diffusion and Collision Moments
------------------------------------------------------------------------

.. container:: ap-lang ap-lang-zh

   前述碰撞核与散射模型已经给出速率依赖和角分布。
   本节将两者接到宏观输运量，回答三个问题：

   * 为什么 VHS 的指数由黏度温度指数决定？
   * 为什么只有黏度不足以确定 VSS 的角参数？
   * 给定参考黏度和自扩散信息后，怎样得到自洽的参考直径？

   推导对象为稀薄、单组分、中性、单原子、弹性气体。
   自扩散指给少量同种分子加上不影响动力学的标签后，标签浓度的扩散。
   混合气体的互扩散需要另行建立物种碰撞算子。

.. container:: ap-lang ap-lang-en

   The rate kernel and angular model specify the speed and direction dependence of collisions.
   This section connects them to macroscopic transport and derives why the viscosity exponent fixes the VHS exponent, why viscosity alone cannot fix the VSS angular parameter, and how viscosity plus self-diffusion determine a consistent reference diameter.

   The derivation covers dilute, single-species, neutral monatomic elastic gases.
   Self-diffusion means diffusion of a dilute population of dynamically identical tagged molecules.
   Interdiffusion in mixtures requires the corresponding species collision operators.

Theory: Collision Models, Chapman–Enskog and Sonine Approximations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   从分子模型到输运公式，中间有不同性质的近似：

   .. list-table::
      :header-rows: 1
      :widths: 24 44 32

      * - 层次
        - 所做的假设或计算
        - 能够保证什么
      * - 分子碰撞模型
        - 采用幂律有效截面和 VSS 角分布
        - 明确给定一个可抽样的 Boltzmann 碰撞核
      * - 一级 Chapman--Enskog 展开
        - 分布接近局部平衡，保留宏观梯度的一阶响应
        - 得到 Newton 黏性与 Fick 扩散等线性输运关系
      * - 第一 Sonine 近似
        - 在速度多项式展开中，保留每个输运模态的首项
        - 把线性积分方程近似为有限个投影方程

   给定模型和投影空间后，下面的角积分与 Gaussian 速度积分均可精确计算。
   近似来自梯度展开与速度展开的截断：Chapman--Enskog 的阶数对应宏观梯度的阶数，
   Sonine 项数对应速度多项式的保留项数。

   记第一 Sonine 的结果为 :math:`\mu_1,D_1`。
   本库的 ``reference_viscosity`` 与 ``reference_diameter`` 按
   :math:`\mu_1` 标定，这是输入参数的明确约定。
   DSMC 的数值收敛目标是所选碰撞核的动力学方程；其近连续输运系数一般还包含更高 Sonine 项的贡献。
   因此，高精度物性匹配还需评估第一 Sonine 近似的截断误差。

   近平衡分析在此用于参数标定，DSMC 随后使用所选碰撞核演化给定的速度分布。

.. container:: ap-lang ap-lang-en

   Three distinct levels connect a molecular model to transport coefficients:

   .. list-table::
      :header-rows: 1
      :widths: 24 44 32

      * - Level
        - Assumption or calculation
        - Result
      * - Molecular collision model
        - Power-law effective cross section and VSS angular law
        - A specified, sampleable Boltzmann collision kernel
      * - First-order Chapman–Enskog expansion
        - Near local equilibrium; first response to macroscopic gradients
        - Linear transport laws, including Newton viscosity and Fick diffusion
      * - First Sonine approximation
        - Retain the leading velocity-polynomial term for each transport mode
        - Approximate the integral equation by projection equations

   For a chosen model and projection space, the angular and Gaussian integrals below are evaluated exactly.
   The approximations are the gradient expansion and the truncated velocity expansion.
   Chapman–Enskog order counts gradient order; Sonine terms count retained velocity polynomials.

   Write the first Sonine results as :math:`\mu_1,D_1`.
   ``reference_viscosity`` and ``reference_diameter`` use :math:`\mu_1` as their calibration convention.
   Converged DSMC solves the kinetics of the chosen collision kernel; its near-continuum transport generally includes higher Sonine contributions.
   Precision fitting therefore requires estimating the first Sonine truncation error.
   Near-equilibrium theory calibrates the model; DSMC subsequently evolves its sampled velocity distribution using that model.

From a Velocity Gradient to the Linearised Collision Operator
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. container:: ap-lang ap-lang-zh

   用 :math:`\mathbf c=\mathbf v-\mathbf u` 表示热运动速度，
   以 :math:`s^2` 表示平衡态下每个速度分量的方差，定义归一化 Maxwell 分布

.. container:: ap-lang ap-lang-en

   Use thermal velocity :math:`\mathbf c=\mathbf v-\mathbf u`.
   Let :math:`s^2` denote the variance of each equilibrium component and define the normalised Maxwell density:

.. math::

   s^2=\frac{k_BT}{m},\qquad
   \mathcal M(\mathbf c)=\frac{1}{(2\pi s^2)^{3/2}}
                \exp\left(-\frac{c^2}{2s^2}\right),\qquad
   \int \mathcal M\,d^3c=1.

.. container:: ap-lang ap-lang-zh

   记局部平衡分布 :math:`f^{(0)}=n\mathcal M`。在其附近写成 :math:`f=f^{(0)}(1+\phi)`，其中
   :math:`|\phi|\ll1`；扰动的质量、三分量动量和能量矩均为零，
   使 :math:`n,\mathbf u,T` 仍由局部平衡部分确定。
   对 Boltzmann 碰撞项保留 :math:`\phi` 的一次项，得到算子

.. container:: ap-lang ap-lang-en

   Write local equilibrium as :math:`f^{(0)}=n\mathcal M` and a small perturbation as :math:`f=f^{(0)}(1+\phi)`, with :math:`|\phi|\ll1`.
   The perturbation has zero mass, momentum and energy moments, leaving :math:`n,\mathbf u,T` determined by :math:`f^{(0)}`.
   Keeping terms linear in :math:`\phi` in the collision operator defines:

.. math::
   :label: g03-cal-linear-operator

   Lh(\mathbf c_1)
   =n\int \mathcal M(\mathbf c_2)\,g
      \int\left(h_1'+h_2'-h_1-h_2\right)d\sigma\,d^3c_2.

.. container:: ap-lang ap-lang-zh

   这里 :math:`h_i=h(\mathbf c_i)`、:math:`h_i'=h(\mathbf c_i')`；撇号表示碰后值，
   :math:`\mathbf g=\mathbf c_1-\mathbf c_2`、:math:`g=|\mathbf g|`。
   微分截面 :math:`d\sigma=(d\sigma/d\Omega)d\Omega`
   由前述碰撞核与角分布共同确定。在 Maxwell 加权内积下，:math:`L` 是非正算子，
   表示碰撞衰减非守恒扰动。

   考察温度、数密度局部均匀的弱平面剪切
   :math:`\mathbf u=(u_x(y),0,0)`，记 :math:`G=\partial u_x/\partial y`。
   此时 :math:`v_y=c_y`，局部 Maxwell 分布的流动梯度产生

.. container:: ap-lang ap-lang-en

   Here :math:`h_i=h(\mathbf c_i)`, :math:`h_i'=h(\mathbf c_i')`, and :math:`\mathbf g=\mathbf c_1-\mathbf c_2` with magnitude :math:`g`.
   The differential cross section :math:`d\sigma=(d\sigma/d\Omega)d\Omega` is fixed by the rate and angular models.
   In the Maxwell-weighted inner product, :math:`L` is nonpositive: collisions damp nonconserved perturbations.

   Consider weak plane shear :math:`\mathbf u=(u_x(y),0,0)` at locally uniform density and temperature, and let :math:`G=\partial u_x/\partial y`.
   Since :math:`v_y=c_y`, the flow gradient generates the following streaming term:

.. math::

   \frac{1}{f^{(0)}}\mathbf v\cdot\nabla f^{(0)}
   =\frac{G}{s^2}c_xc_y.

.. container:: ap-lang ap-lang-zh

   因此求黏度的线性方程是

.. container:: ap-lang ap-lang-en

   The linear equation determining viscosity is consequently:

.. math::

   L\phi=\frac{G}{s^2}S,\qquad S(\mathbf c)=c_xc_y.

.. container:: ap-lang ap-lang-zh

   其因果关系是：相邻流层具有不同平均速度，分子的热运动携带这些差异，
   产生 :math:`c_xc_y` 型的速度各向异性；碰撞再衰减该各向异性。
   黏度给出这一响应形成的动量通量与速度梯度之间的比例。

.. container:: ap-lang ap-lang-en

   Thermal motion carries different mean momenta between neighbouring flow layers, generating a :math:`c_xc_y` anisotropy.
   Collisions relax that anisotropy.
   Viscosity relates the resulting momentum flux to the velocity gradient.

Projecting the Shear Mode: The Fifth-Order Speed Moment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. container:: ap-lang ap-lang-zh

   定义 Maxwell 平均 :math:`\langle F\rangle=\int \mathcal M F\,d^3c`，
   以及内积 :math:`\langle a,b\rangle=\langle ab\rangle`。
   第一 Sonine 近似对剪切扰动采用

.. container:: ap-lang ap-lang-en

   Define Maxwell averaging by :math:`\langle F\rangle=\int\mathcal M F\,d^3c` and inner product by :math:`\langle a,b\rangle=\langle ab\rangle`.
   The leading Sonine approximation for shear takes:

.. math::

   \phi\simeq-a_\eta GS.

.. container:: ap-lang ap-lang-zh

   将线性方程乘以 :math:`S` 并积分，令
   :math:`B_2=-\langle S,LS\rangle`，利用
   :math:`\langle S^2\rangle=s^4`，得到

.. container:: ap-lang ap-lang-en

   Multiply the linear equation by :math:`S`, integrate, define :math:`B_2=-\langle S,LS\rangle`, and use the independent Gaussian moment :math:`\langle S^2\rangle=s^4`:

.. math::

   a_\eta B_2=s^2,\qquad
   \mathsf P_{xy}=mn\langle S\phi\rangle
         =-mn a_\eta s^4G=-\mu_1G,

.. math::
   :label: g03-cal-mu-bracket

   \boxed{\mu_1=\frac{mn s^6}{B_2}}.

.. container:: ap-lang ap-lang-zh

   这里 :math:`\mathsf P_{xy}` 是分子输运产生的非对角动量通量；连续介质中的黏性应力为
   :math:`\tau_{xy}=-\mathsf P_{xy}=\mu_1G`。

   记 :math:`\mathcal M_i=\mathcal M(\mathbf c_i)`，
   :math:`\Delta(S_1+S_2)=S_1'+S_2'-S_1-S_2`。
   利用弹性碰撞的微观可逆性与
   :math:`\mathcal M_1'\mathcal M_2'=\mathcal M_1\mathcal M_2`，碰撞括号可对称化为

.. container:: ap-lang ap-lang-en

   :math:`\mathsf P_{xy}` denotes the off-diagonal molecular momentum flux.
   The continuum viscous stress has the opposite sign: :math:`\tau_{xy}=-\mathsf P_{xy}=\mu_1G`.

   Set :math:`\mathcal M_i=\mathcal M(\mathbf c_i)` and :math:`\Delta(S_1+S_2)=S_1'+S_2'-S_1-S_2`.
   Microscopic reversibility and the elastic equilibrium identity :math:`\mathcal M_1'\mathcal M_2'=\mathcal M_1\mathcal M_2` symmetrise the collision bracket into:

.. math::

   B_2=\frac n4\int \mathcal M_1\mathcal M_2\,g
       \int\left[\Delta(S_1+S_2)\right]^2d\sigma\,
       d^3c_1d^3c_2.

.. container:: ap-lang ap-lang-zh

   把两分子的热速度改写为质心与相对速度，质心在碰撞中保持不变，于是

.. container:: ap-lang ap-lang-en

   Expressing the two thermal velocities through centre-of-mass and relative velocities eliminates the conserved centre-of-mass contribution:

.. math::

   \Delta(S_1+S_2)
   =\frac12(g_x'g_y'-g_xg_y).

.. container:: ap-lang ap-lang-zh

   对于固定相对速率 :math:`g` 和偏转角 :math:`\chi`，
   横线表示对均匀入射方向与散射方位的平均。各向同性四阶方向矩给出

.. container:: ap-lang ap-lang-en

   Fix :math:`g` and :math:`\chi`.
   An overbar denotes averaging over uniform incident directions and scattering azimuths.
   The isotropic fourth-order directional moments give:

.. math::

   \overline{g_x^2g_y^2}=\frac{g^4}{15},\qquad
   \overline{g_xg_y g_x'g_y'}=\frac{g^4}{30}(3\cos^2\chi-1).

.. container:: ap-lang ap-lang-zh

   碰前、碰后的平方项具有相同平均，展开差的平方便得到

.. container:: ap-lang ap-lang-en

   The incoming and outgoing squared terms have equal averages.
   Expanding their squared difference therefore gives:

.. math::

   \overline{\left[\Delta(S_1+S_2)\right]^2}
   =\frac14\left[\frac{2g^4}{15}
     -\frac{g^4}{15}(3\cos^2\chi-1)\right]
   =\frac{g^4}{20}(1-\cos^2\chi).

.. container:: ap-lang ap-lang-zh

   其中 :math:`g^4` 来自二阶速度模态的平方，
   :math:`1-\cos^2\chi` 来自二阶方向模态。
   再乘碰撞通量中的一个 :math:`g`，便得到

.. container:: ap-lang ap-lang-en

   The :math:`g^4` factor comes from squaring the second-order velocity mode; :math:`1-\cos^2\chi` comes from its directional change.
   Multiplication by the collision-flux factor :math:`g` yields:

.. math::
   :label: g03-cal-b2

   \boxed{B_2=\frac n{80}
     \left\langle g^5Q^{(2)}(g)\right\rangle_{\mathrm{rel}}},\qquad
   Q^{(2)}=\int(1-\cos^2\chi)\,d\sigma.

.. container:: ap-lang ap-lang-zh

   下标 :math:`\mathrm{rel}` 表示两独立 Maxwell 速度之差的平均；
   其相对速率密度将在后文给出。代回黏度表达式，得到

.. container:: ap-lang ap-lang-en

   The subscript :math:`\mathrm{rel}` denotes an average over the difference of two independent Maxwell velocities.
   Its speed density is derived below.
   Substitution into the viscosity bracket gives:

.. math::
   :label: g03-cal-mu-moment

   \boxed{\mu_1(T)=
   \frac{80(k_BT)^3}
        {m^2\left\langle g^5Q^{(2)}(g)\right\rangle_{\mathrm{rel}}}}.

.. container:: ap-lang ap-lang-zh

   黏度由这一角权重与速度权重共同决定；
   即使 :math:`\langle \sigma g\rangle` 相同，模型的黏度仍可能不同。

.. container:: ap-lang ap-lang-en

   Viscosity depends on both angular and speed weights.
   Equal mean total collision kernels :math:`\langle\sigma g\rangle` can therefore produce different viscosities.

The Operator for Tagged Self-Diffusion
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. container:: ap-lang ap-lang-zh

   设极少量标签分子的数密度为 :math:`n_A(\mathbf x)`，
   背景是相同质量、相同碰撞性质的未标记分子，数密度近似为 :math:`n`。
   在恒定温度、无整体流动下，浓度梯度产生标签粒子数通量

.. container:: ap-lang ap-lang-en

   Let a dilute tagged population have density :math:`n_A(\mathbf x)`.
   The untagged background has the same mass and collision law and density approximately :math:`n`.
   At constant temperature and zero bulk flow, the concentration gradient produces number flux:

.. math::

   \mathbf j_A=-D_1\nabla n_A.

.. container:: ap-lang ap-lang-zh

   标签不会改变碰撞轨道，但我们只追踪标签分子的速度。
   其线性算子为

.. container:: ap-lang ap-lang-en

   A tag leaves the physical trajectory unchanged, but only the tagged molecule's velocity is tracked.
   Its linear collision operator is:

.. math::

   L_Dh(\mathbf c_1)
   =n\int \mathcal M_2\,g\int(h_1'-h_1)\,d\sigma\,d^3c_2.

.. container:: ap-lang ap-lang-zh

   背景分布保持 Maxwell 形式，因此这里只保留标签分子的 :math:`h_1'-h_1`。
   标签分子的动量可转移给背景，使 :math:`L_D` 衰减 :math:`c_x` 模态；
   相应地，完整单组分算子 :math:`L` 的 :math:`c_x` 模态由总动量守恒而保持不变。

   写标签分布为 :math:`f_A=n_A\mathcal M(1+\phi_A)`，取 :math:`H=\partial_x\ln n_A`。
   第一 Sonine 近似为 :math:`\phi_A=-a_D Hc_x`。
   投影方程 :math:`L_D\phi_A=Hc_x` 给出

.. container:: ap-lang ap-lang-en

   The background remains Maxwellian, leaving only the tagged contribution :math:`h_1'-h_1`.
   Momentum transfer to the background relaxes the :math:`c_x` mode under :math:`L_D`.
   For the full single-species operator :math:`L`, the corresponding mode instead belongs to total-momentum conservation.

   Write :math:`f_A=n_A\mathcal M(1+\phi_A)` and :math:`H=\partial_x\ln n_A`.
   The leading Sonine form is :math:`\phi_A=-a_DHc_x`.
   Projecting :math:`L_D\phi_A=Hc_x` gives:

.. math::

   B_1=-\langle c_x,L_Dc_x\rangle,\qquad a_DB_1=s^2.

.. container:: ap-lang ap-lang-zh

   对应的粒子数通量为
   :math:`j_{Ax}=n_A\langle c_x\phi_A\rangle=-a_Ds^2\partial_x n_A`，
   与 Fick 定律比较即得 :math:`D_1=a_Ds^2=s^4/B_1`。
   标签碰撞括号是

.. container:: ap-lang ap-lang-en

   The number flux is :math:`j_{Ax}=n_A\langle c_x\phi_A\rangle=-a_Ds^2\partial_xn_A`.
   Comparing with Fick's law gives :math:`D_1=a_Ds^2=s^4/B_1`.
   The tagged collision bracket is:

.. math::

   B_1=\frac n2\int \mathcal M_1\mathcal M_2\,g
       \int(c_{1x}'-c_{1x})^2d\sigma\,d^3c_1d^3c_2.

.. container:: ap-lang ap-lang-zh

   因为 :math:`\mathbf c_1'-\mathbf c_1=(\mathbf g'-\mathbf g)/2`，
   而 :math:`|\mathbf g'-\mathbf g|^2=2g^2(1-\cos\chi)`，
   方向平均后有

.. container:: ap-lang ap-lang-en

   Since :math:`\mathbf c_1'-\mathbf c_1=(\mathbf g'-\mathbf g)/2` and :math:`|\mathbf g'-\mathbf g|^2=2g^2(1-\cos\chi)`, the directional average gives:

.. math::

   \overline{(c_{1x}'-c_{1x})^2}
   =\frac{g^2}{6}(1-\cos\chi).

.. container:: ap-lang ap-lang-zh

   因此

.. container:: ap-lang ap-lang-en

   Combining the angular weight with the collision-flux factor gives:

.. math::
   :label: g03-cal-b1

   \boxed{B_1=\frac n{12}
     \left\langle g^3Q^{(1)}(g)\right\rangle_{\mathrm{rel}}},\qquad
   Q^{(1)}=\int(1-\cos\chi)\,d\sigma,

.. math::
   :label: g03-cal-d-moment

   \boxed{D_1(T,n)=
   \frac{12(k_BT)^2}
        {n m^2\left\langle g^3Q^{(1)}(g)\right\rangle_{\mathrm{rel}}}}.

.. container:: ap-lang ap-lang-zh

   扩散使用三次速率矩和 :math:`1-\cos\chi`，
   黏度使用五次速率矩和 :math:`1-\cos^2\chi`；二者测量的是不同碰撞矩。

.. container:: ap-lang ap-lang-en

   Self-diffusion uses the third-order speed moment weighted by :math:`1-\cos\chi`.
   Viscosity uses the fifth-order speed moment weighted by :math:`1-\cos^2\chi`.
   They therefore constrain different collision moments.

Relative-Speed Distribution and Gamma Integrals
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. container:: ap-lang ap-lang-zh

   两独立 Maxwell 速度相减后，每个相对速度分量的方差是 :math:`2s^2`。
   相对速率的概率密度为

.. container:: ap-lang ap-lang-en

   Subtracting independent Maxwell velocities gives relative components of variance :math:`2s^2`.
   The corresponding speed probability density is:

.. math::

   p_{\mathrm{rel}}(g)=
   \frac{g^2}{2\sqrt{\pi}s^3}
   \exp\left(-\frac{g^2}{4s^2}\right),\qquad g\ge0.

.. container:: ap-lang ap-lang-zh

   对任意函数 :math:`F(g)`，记
   :math:`\langle F\rangle_{\mathrm{rel}}=\int_0^\infty F(g)p_{\mathrm{rel}}(g)\,dg`。
   取 :math:`F=g^r`，以 :math:`x=g^2/(4s^2)` 换元可得（:math:`r>-3`）

.. container:: ap-lang ap-lang-en

   For any speed function :math:`F`, define :math:`\langle F\rangle_{\mathrm{rel}}=\int_0^\infty F(g)p_{\mathrm{rel}}(g)\,dg`.
   For :math:`F=g^r`, use :math:`x=g^2/(4s^2)` to obtain, for :math:`r>-3`:

.. math::
   :label: g03-cal-speed-moment

   \langle g^r\rangle_{\mathrm{rel}}
   =\frac{1}{2\sqrt{\pi}s^3}
      \int_0^\infty g^{r+2}e^{-g^2/(4s^2)}\,dg
   =(2s)^r\frac{\Gamma((r+3)/2)}{\Gamma(3/2)}.

.. container:: ap-lang ap-lang-zh

   概率密度中的 :math:`g^2` 来自三维速度空间的体积测度。
   把期望展开为一维积分后，黏度分母的幂次为 :math:`g^7Q^{(2)}`，
   扩散分母的幂次为 :math:`g^5Q^{(1)}`；这已包含该体积因子。

.. container:: ap-lang ap-lang-en

   The density's :math:`g^2` factor is the spherical-shell volume measure in three-dimensional velocity space.
   After expanding the expectations as one-dimensional integrals, the viscosity denominator contains :math:`g^7Q^{(2)}` and the diffusion denominator contains :math:`g^5Q^{(1)}`.
   These powers already include that shell factor.

Evaluating the VHS and VSS Transport Coefficients
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. container:: ap-lang ap-lang-zh

   将前文碰撞核的 Bird 规范改写为

.. container:: ap-lang ap-lang-en

   Rewrite Bird's cross-section convention as:

.. math::

   \sigma(g)=C_\sigma g^{1-2\omega},\qquad
   C_\sigma=
   \frac{\pi d_{\mathrm{ref}}^2g_{\mathrm{ref}}^{2\omega-1}}
        {\Gamma(5/2-\omega)}.

.. container:: ap-lang ap-lang-zh

   由前文的散射角矩，

.. container:: ap-lang ap-lang-en

   The angular moments derived in Elastic Scattering give:

.. math::

   Q^{(1)}=A_1C_\sigma g^{1-2\omega},\qquad
   A_1=\frac2{\alpha+1},

.. math::

   Q^{(2)}=A_2C_\sigma g^{1-2\omega},\qquad
   A_2=\frac{4\alpha}{(\alpha+1)(\alpha+2)}.

.. container:: ap-lang ap-lang-zh

   于是两个碰撞矩分别是

.. container:: ap-lang ap-lang-en

   Substituting the relative-speed moment formula gives:

.. math::

   \left\langle g^3Q^{(1)}\right\rangle
   =A_1C_\sigma(2s)^{4-2\omega}
      \frac{\Gamma(7/2-\omega)}{\Gamma(3/2)},

.. math::

   \left\langle g^5Q^{(2)}\right\rangle
   =A_2C_\sigma(2s)^{6-2\omega}
      \frac{\Gamma(9/2-\omega)}{\Gamma(3/2)}.

.. container:: ap-lang ap-lang-zh

   在参考温度使用 :math:`g_{\mathrm{ref}}=2s_{\mathrm{ref}}`，
   再用 Gamma 递推
   :math:`\Gamma(x+2)=x(x+1)\Gamma(x)`，
   黏度分母中的 Gamma 比化成

.. container:: ap-lang ap-lang-en

   At the reference temperature, :math:`g_{\mathrm{ref}}=2s_{\mathrm{ref}}`.
   The recurrence :math:`\Gamma(x+2)=x(x+1)\Gamma(x)` reduces the Gamma ratio in the viscosity denominator to:

.. math::

   \frac{\Gamma(9/2-\omega)}{\Gamma(5/2-\omega)}
   =\frac{(5-2\omega)(7-2\omega)}4.

.. container:: ap-lang ap-lang-zh

   最终得到

.. container:: ap-lang ap-lang-en

   Collecting the factors gives the reference viscosity and its temperature dependence:

.. math::
   :label: g03-cal-mu-reference

   \boxed{\mu_{1,\mathrm{ref}}=
   \frac{5(\alpha+1)(\alpha+2)}
        {4\alpha(5-2\omega)(7-2\omega)d_{\mathrm{ref}}^2}
   \sqrt{\frac{mk_BT_{\mathrm{ref}}}{\pi}}},

.. math::
   :label: g03-cal-mu-temperature

   \boxed{\mu_1(T)=
     \mu_{1,\mathrm{ref}}
     \left(\frac{T}{T_{\mathrm{ref}}}\right)^\omega}.

.. container:: ap-lang ap-lang-zh

   扩散同理得到

.. container:: ap-lang ap-lang-en

   The same calculation gives tagged self-diffusion:

.. math::
   :label: g03-cal-d-reference

   \boxed{D_1(T,n)=
   \frac{3(\alpha+1)}
        {4(5-2\omega)n d_{\mathrm{ref}}^2}
   \sqrt{\frac{k_BT_{\mathrm{ref}}}{\pi m}}
   \left(\frac{T}{T_{\mathrm{ref}}}\right)^\omega}.

.. container:: ap-lang ap-lang-zh

   在 :math:`\omega=1/2,\alpha=1` 的 HS 极限，

.. container:: ap-lang ap-lang-en

   For the HS limit :math:`\omega=1/2,\alpha=1`, these reduce to:

.. math::

   \mu_{1,\mathrm{HS}}=\frac{5}{16d^2}
      \sqrt{\frac{mk_BT}{\pi}},\qquad
   D_{1,\mathrm{HS}}=\frac{3}{8nd^2}
      \sqrt{\frac{k_BT}{\pi m}}.

.. container:: ap-lang ap-lang-zh

   两式恢复标准的 HS 第一 Sonine 系数，同时核对了角分布归一化和同种分子的约化质量 :math:`m/2`。

.. container:: ap-lang ap-lang-en

   These are the standard first Sonine HS coefficients.
   This limit also checks the angular normalisation and the identical-particle reduced mass :math:`m/2`.

.. rubric:: Source: The Common Coefficient in reference_viscosity

.. container:: ap-lang ap-lang-zh

   定义 :math:`C_\mu=\mu_{1,\mathrm{ref}}d_{\mathrm{ref}}^2`。
   源码先用内部函数 ``viscosity_scale`` 计算这一公共系数，再除以直径平方：

.. container:: ap-lang ap-lang-en

   Define :math:`C_\mu=\mu_{1,\mathrm{ref}}d_{\mathrm{ref}}^2`.
   The internal ``viscosity_scale`` computes this common coefficient before division by diameter squared:

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_calibration.cpp
   :language: cpp
   :start-at: Real viscosity_scale
   :end-before: } // namespace
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/fun_G03_dsmc_calibration.cpp

.. container:: ap-lang ap-lang-zh

   ``mass``、``temperature``、``omega``、``alpha`` 分别对应
   :math:`m,T_{\mathrm{ref}},\omega,\alpha`。
   局部变量 ``calibration`` 就是上面黏度公式中除 :math:`d_{\mathrm{ref}}^{-2}` 之外的完整系数，
   单位为 :math:`\mathrm{Pa\,s\,m^2}`。
   函数同时检查 :math:`m,T_{\mathrm{ref}}>0`、:math:`1/2\le\omega\le1` 与 :math:`\alpha\ge1`。

.. container:: ap-lang ap-lang-en

   ``mass``, ``temperature``, ``omega`` and ``alpha`` correspond to :math:`m,T_{\mathrm{ref}},\omega,\alpha`.
   The variable ``calibration`` is the complete coefficient multiplying :math:`d_{\mathrm{ref}}^{-2}` in the viscosity formula, with units :math:`\mathrm{Pa\,s\,m^2}`.
   The function validates :math:`m,T_{\mathrm{ref}}>0`, :math:`1/2\le\omega\le1` and :math:`\alpha\ge1`.

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_calibration.cpp
   :language: cpp
   :start-at: Real reference_viscosity
   :end-before: Real reference_diameter
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/fun_G03_dsmc_calibration.cpp

.. container:: ap-lang ap-lang-zh

   ``diameter`` 对应 :math:`d_{\mathrm{ref}}`，返回的 ``viscosity`` 对应 :math:`\mu_{1,\mathrm{ref}}`。
   ``DsmcModel`` 的构造函数调用它计算模型属性中的参考黏度；
   每次碰撞直接使用已构造的速率核与角分布。

.. container:: ap-lang ap-lang-en

   ``diameter`` is :math:`d_{\mathrm{ref}}`; the returned ``viscosity`` is :math:`\mu_{1,\mathrm{ref}}`.
   ``DsmcModel`` calls this function when constructing the model's reference-viscosity property.
   Individual collisions subsequently use the already constructed rate kernel and angular distribution.

Why the Temperature Exponent Survives Sonine Truncation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. container:: ap-lang ap-lang-zh

   上面的第一 Sonine 计算给出了闭式系数，但幂律指数还有更一般的来源。
   对固定 :math:`\alpha,\omega` 的齐次核，令
   :math:`\mathbf c=s\boldsymbol\xi`，则完整的线性算子可写为

.. container:: ap-lang ap-lang-en

   The first Sonine projection gives closed coefficients, but the power-law exponent has a more general origin.
   For fixed :math:`\alpha,\omega`, put :math:`\mathbf c=s\boldsymbol\xi` in the full linear operator:

.. math::

   L=nC_\sigma s^{2-2\omega}\widehat L,

.. container:: ap-lang ap-lang-zh

   其中 :math:`\widehat L` 的速度变量无量纲，且不再依赖
   :math:`n,T`；它只依赖角模型与幂指数。
   剪切方程的右端为 :math:`G\xi_x\xi_y`，因此其解的尺度为

.. container:: ap-lang ap-lang-en

   The dimensionless operator :math:`\widehat L` depends on angular law and power exponent, with all density and temperature dependence in the prefactor.
   The shear forcing becomes :math:`G\xi_x\xi_y`, so the solution scales as:

.. math::

   \phi\sim
   \frac{G}{nC_\sigma s^{2-2\omega}}
   \widehat L^{-1}(\xi_x\xi_y).

.. container:: ap-lang ap-lang-zh

   将它代入动量通量
   :math:`\mathsf P_{xy}=mn s^2\langle\xi_x\xi_y\phi\rangle`，便得到

.. container:: ap-lang ap-lang-en

   Insert this response into :math:`\mathsf P_{xy}=mns^2\langle\xi_x\xi_y\phi\rangle` to obtain:

.. math::

   \mu\propto\frac{m}{C_\sigma}s^{2\omega}
   \propto T^\omega.

.. container:: ap-lang ap-lang-zh

   这里的逆算子在排除守恒零模的输运子空间上理解。
   增加 Sonine 项会改进这个无量纲逆算子的表示，从而改变系数；
   只要核保持相同齐次性，温度指数不变。
   标签扩散的同样缩放给出 :math:`D\propto T^\omega/n`。
   这一区分说明了哪些结果来自模型的尺度结构，哪些数值常数来自具体投影近似。

.. container:: ap-lang ap-lang-en

   The inverse operator is understood on the transport subspace with conserved zero modes removed.
   Adding Sonine terms improves this dimensionless inverse and changes the coefficient.
   Homogeneity preserves the temperature exponent.
   The corresponding tagged calculation gives :math:`D\propto T^\omega/n`.
   This separates scaling properties of the model from constants affected by the projection approximation.

Density Dependence of Dynamic and Kinematic Viscosity
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. container:: ap-lang ap-lang-zh

   在剪切投影中，压力矩的幅度正比于 :math:`n`，
   碰撞松弛频率也正比于 :math:`n`；二者抵消，使
   :math:`\mu_1` 在稀薄二体碰撞模型下不显含密度。
   它仍依赖分子质量与碰撞模型参数，因此不同气体不具有同一个 :math:`\mu(T)`。

   运动黏度与动力黏度必须区分：

.. container:: ap-lang ap-lang-en

   In the shear projection, the pressure-moment amplitude and the collision relaxation rate both scale with :math:`n`.
   Their ratio makes dilute-gas dynamic viscosity independent of density.
   Molecular mass and collision parameters remain, so different gases have different :math:`\mu(T)`.

   Kinematic viscosity is defined by:

.. math::

   \boxed{\nu_{\mathrm{kin}}=\frac{\mu}{\rho}},\qquad
   \rho=mn,\qquad
   [\mu]=\mathrm{Pa\,s},\quad
   [\nu_{\mathrm{kin}}]=[D]=\mathrm{m^2/s}.

.. container:: ap-lang ap-lang-zh

   为避免与碰撞频率混淆，本节把运动黏度写为
   :math:`\nu_{\mathrm{kin}}`，把碰撞频率写为 :math:`\nu_{\mathrm{coll}}`。
   在同一模型下，:math:`D_1` 和 :math:`\nu_{\mathrm{kin},1}`
   都按 :math:`T^\omega/n` 缩放。
   若保持数密度不变，它们按 :math:`T^\omega` 变化；
   若保持压力 :math:`p=nk_BT` 不变，它们按 :math:`T^{\omega+1}` 变化。

   共同的平均流速不影响这些物性，因为它不影响相对速度。
   在线性理论中，速度梯度驱动黏性应力，:math:`\mu` 给出二者之间的比例。
   强非平衡时，仅知道局部 :math:`n,T,\mathbf u` 一般不足以确定应力：
   需要完整分布，Newton 本构也可能失效。

   密度抵消依赖稀薄二体碰撞假设；较高密度下需计入分子相关性与有限体积效应。
   较低密度则使平均自由程增大：连续介质本构的适用性还取决于它与流场尺度之比。

.. container:: ap-lang ap-lang-en

   Here :math:`\nu_{\mathrm{kin}}` denotes kinematic viscosity and :math:`\nu_{\mathrm{coll}}` collision frequency.
   Both :math:`D_1` and :math:`\nu_{\mathrm{kin},1}` scale as :math:`T^\omega/n`.
   At fixed density they scale as :math:`T^\omega`; at fixed pressure :math:`p=nk_BT` they scale as :math:`T^{\omega+1}`.

   A common mean drift preserves relative speeds and these material coefficients.
   In linear theory a velocity gradient drives shear stress, with viscosity as the proportionality coefficient.
   For strong nonequilibrium, :math:`n,T,\mathbf u` generally do not determine stress; the full distribution is needed and the Newton constitutive relation may fail.

   The density cancellation assumes dilute binary collisions.
   Higher densities introduce correlations and finite-volume effects.
   Lower densities increase mean free path, so the applicability of continuum constitutive laws also depends on macroscopic length scales.

Determining the Angular Parameter from the Schmidt Number
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. container:: ap-lang ap-lang-zh

   将两个输运系数相除，截面幅度、数密度和温度全部抵消：

.. container:: ap-lang ap-lang-en

   Taking the ratio of the two transport coefficients cancels density, temperature and cross-section amplitude:

.. math::
   :label: g03-cal-schmidt

   \boxed{\mathrm{Sc}_1
   =\frac{\mu_1}{mnD_1}
   =\frac{5(\alpha+2)}{3\alpha(7-2\omega)}}.

.. container:: ap-lang ap-lang-zh

   因此，黏度温度变化首先确定 :math:`\omega`；
   独立的自扩散信息通过 :math:`\mathrm{Sc}` 约束 :math:`\alpha`；
   最后才由黏度幅度确定 :math:`d_{\mathrm{ref}}`。
   VHS 固定 :math:`\alpha=1`，只能预测
   :math:`\mathrm{Sc}_1=5/(7-2\omega)`，没有额外自由度调整这个比值。

   在本库 :math:`\alpha\ge1` 的范围内，可反解

.. container:: ap-lang ap-lang-en

   The temperature dependence of viscosity first determines :math:`\omega`.
   Independent self-diffusion data constrain :math:`\alpha` through :math:`\mathrm{Sc}`, after which the viscosity amplitude determines :math:`d_{\mathrm{ref}}`.
   VHS fixes :math:`\alpha=1` and predicts :math:`\mathrm{Sc}_1=5/(7-2\omega)` without an additional fitting parameter.

   For the supported range :math:`\alpha\ge1`, inversion gives:

.. math::
   :label: g03-cal-alpha

   \boxed{\alpha=
   \frac{10}{3\mathrm{Sc}_1(7-2\omega)-5}}.

.. container:: ap-lang ap-lang-zh

   有限的允许参数须满足

.. container:: ap-lang ap-lang-en

   A finite allowed angular parameter requires:

.. math::

   \frac{5}{3(7-2\omega)}
   \lt \mathrm{Sc}_1
   \le \frac{5}{7-2\omega}.

.. container:: ap-lang ap-lang-zh

   下界只能在 :math:`\alpha\to\infty` 时逼近。
   目标数据超出区间时，应核查数据类型、单位、温区与近似，必要时更换模型。
   固定 :math:`\omega,\alpha` 给出恒定的 :math:`\mathrm{Sc}_1`，
   其标定温区应选择在目标比值变化足够小的范围内。

   上述反解使用同种分子的标签自扩散；异种二元扩散与多组分输运需采用相应的质量与耦合关系。

.. container:: ap-lang ap-lang-en

   The lower limit is approached only as :math:`\alpha\to\infty`.
   For data outside this range, check the quantity measured, units, temperature range and approximation, and reconsider the model if needed.
   Constant :math:`\omega,\alpha` imply constant :math:`\mathrm{Sc}_1`, so calibration should cover a range where the target ratio changes sufficiently little.

   This inversion applies to tagged self-diffusion of identical molecules.
   Binary diffusion and multicomponent transport require their own mass factors and coupled equations.

Calibration Procedure and Parameter Order
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   对一个选定的温区，可以采用以下标定顺序：

   #. 指定气体种类与真实分子质量 :math:`m`，选择参考温度 :math:`T_{\mathrm{ref}}`。
   #. 从黏度数据拟合 :math:`\ln\mu=\ln\mu_{\mathrm{ref}}+
      \omega\ln(T/T_{\mathrm{ref}})`。两点斜率只是最小示例，
      多点拟合还应检查幂律残差与适用温区。
   #. 选择 HS、VHS 或 VSS。HS 固定 :math:`\omega=1/2,\alpha=1`；
      VHS 固定 :math:`\alpha=1`；VSS 根据自扩散信息选 :math:`\alpha`。
   #. 在确定 :math:`\omega,\alpha` 后，按同一 Bird 规范计算参考直径。
   #. 将直径、参考温度、指数与角参数组成模型；用独立数值实验检查目标输运量。

   直径反解为

.. container:: ap-lang ap-lang-en

   For a selected temperature range:

   #. Choose the gas and molecular mass :math:`m`, then reference temperature :math:`T_{\mathrm{ref}}`.
   #. Fit :math:`\ln\mu=\ln\mu_{\mathrm{ref}}+\omega\ln(T/T_{\mathrm{ref}})`. With multiple points, check power-law residuals and the valid temperature range.
   #. Choose HS, VHS or VSS. HS fixes :math:`\omega=1/2,\alpha=1`; VHS fixes :math:`\alpha=1`; VSS uses self-diffusion data to choose :math:`\alpha`.
   #. Once :math:`\omega,\alpha` are fixed, compute the reference diameter under the same Bird convention.
   #. Construct the model from these parameters and verify the target transport properties independently.

   The inverse diameter formula is:

.. math::
   :label: g03-cal-diameter

   \boxed{d_{\mathrm{ref}}=
   \left[
   \frac{5(\alpha+1)(\alpha+2)}
        {4\alpha(5-2\omega)(7-2\omega)\mu_{1,\mathrm{ref}}}
   \sqrt{\frac{mk_BT_{\mathrm{ref}}}{\pi}}
   \right]^{1/2}}.

.. rubric:: Source: Recovering the Diameter with reference_diameter

.. container:: ap-lang ap-lang-zh

   同一个 ``viscosity_scale`` 提供 :math:`C_\mu`，反解只需计算
   :math:`d_{\mathrm{ref}}=\sqrt{C_\mu/\mu_{1,\mathrm{ref}}}`：

.. container:: ap-lang ap-lang-en

   The same ``viscosity_scale`` supplies :math:`C_\mu`, so inversion needs only :math:`d_{\mathrm{ref}}=\sqrt{C_\mu/\mu_{1,\mathrm{ref}}}`:

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_calibration.cpp
   :language: cpp
   :start-at: Real reference_diameter
   :end-before: } // namespace algoplasma::dsmc
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/fun_G03_dsmc_calibration.cpp

.. container:: ap-lang ap-lang-zh

   输入 ``viscosity`` 对应目标 :math:`\mu_{1,\mathrm{ref}}`，返回 ``diameter`` 的单位是米。
   正算和反算共用同一系数，保证它们使用相同的 Bird 规范与第一 Sonine 约定。
   调用方得到直径后，将其放入 ``ElasticModelParameters::diameter_ref_m``，
   模型构造函数再把它传给 ``HardSphereRate`` 或 ``VhsRate``。

   改变 :math:`\alpha` 会改变 :math:`Q^{(2)}`，因此通常也会改变黏度。
   若想保持同一个 :math:`\mu_{\mathrm{ref}}`，应在更换角分布后重新计算参考直径。

   温度用于输运标定；运行时则由每对粒子的相对速率 :math:`g` 直接计算碰撞核。

.. container:: ap-lang ap-lang-en

   The input ``viscosity`` is the target :math:`\mu_{1,\mathrm{ref}}`; the returned ``diameter`` is in metres.
   Forward and inverse calculations share the same coefficient, Bird convention and first Sonine approximation.
   The caller assigns the result to ``ElasticModelParameters::diameter_ref_m``, which model construction passes to ``HardSphereRate`` or ``VhsRate``.

   Changing :math:`\alpha` changes :math:`Q^{(2)}` and hence viscosity.
   To keep the same reference viscosity, recalibrate the diameter after changing the angular law.
   Temperature enters transport calibration; runtime collisions evaluate the kernel directly from each pair's relative speed :math:`g`.

A Reproducible Numerical Example
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. container:: ap-lang ap-lang-zh

   取教学参数

.. container:: ap-lang ap-lang-en

   Use the following teaching parameters:

.. math::

   m=6.6335209\times10^{-26}\ \mathrm{kg},\quad
   T_{\mathrm{ref}}=300\ \mathrm K,\quad
   \mu_{1,\mathrm{ref}}=2.23\times10^{-5}\ \mathrm{Pa\,s},

.. math::

   \omega=0.81,\qquad \alpha=1.4,\qquad
   n_{\mathrm{ref}}=10^{23}\ \mathrm{m^{-3}}.

.. container:: ap-lang ap-lang-zh

   这组教学数据采用氩原子量级的质量。代入公式得到

.. container:: ap-lang ap-lang-en

   The mass has the scale of an argon atom.
   Substitution gives:

.. math::

   d_{\mathrm{ref}}=4.09905589\times10^{-10}\ \mathrm m,\qquad
   \mathrm{Sc}_1=0.75234555,

.. math::

   D_{1,\mathrm{ref}}=4.46831113\times10^{-3}\ \mathrm{m^2/s},\qquad
   \nu_{\mathrm{kin},1,\mathrm{ref}}
   =3.36171399\times10^{-3}\ \mathrm{m^2/s}.

.. container:: ap-lang ap-lang-zh

   将这个 :math:`\mathrm{Sc}_1` 代回式 :eq:`g03-cal-alpha`，
   应恢复 :math:`\alpha=1.4`。
   若同样的参考黏度改用 VHS，即 :math:`\alpha=1`，
   需要 :math:`d_{\mathrm{ref}}=4.15889929\times10^{-10}\ \mathrm m`。

   在保持数密度不变、温度升至 :math:`600\ \mathrm K` 时，

.. container:: ap-lang ap-lang-en

   Putting this :math:`\mathrm{Sc}_1` into :eq:`g03-cal-alpha` recovers :math:`\alpha=1.4`.
   Using VHS with :math:`\alpha=1` at the same reference viscosity instead requires :math:`d_{\mathrm{ref}}=4.15889929\times10^{-10}\ \mathrm m`.

   Raise temperature to :math:`600\ \mathrm K` at fixed number density:

.. math::

   \mu_1=3.90966152\times10^{-5}\ \mathrm{Pa\,s},\qquad
   D_1=7.83389421\times10^{-3}\ \mathrm{m^2/s}.

.. container:: ap-lang ap-lang-zh

   若改为保持压力不变，数密度还会减半；
   此时 :math:`D_1` 是上述数值的两倍，而 :math:`\mu_1` 不变。
   这说明讨论“输运系数随温度变化”时必须同时说明保持什么条件不变。

.. container:: ap-lang ap-lang-en

   At fixed pressure instead, number density halves.
   Self-diffusion then doubles relative to the value above, while dynamic viscosity is unchanged.
   Temperature dependence must therefore be stated together with the held-fixed physical conditions.

Source Responsibilities: Calibration and Runtime Collisions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   ``calibration.hpp`` 声明上述正反两个公共函数，
   ``fun_G03_dsmc_calibration.cpp`` 实现共同的物理系数和参数检查。
   黏度数据拟合、由自扩散确定角参数以及适用温区的选择，由调用方依据数据完成。

   运行时使用的 ``VhsRate`` 保存由这些参数确定的核，``VssScattering`` 保存角参数的倒数。
   碰撞内核给定相对速度后，即可得到 :math:`K(g)` 和 :math:`\mathbf g'`。
   输入文件、命令行参数和初始粒子生成属于算例的组织方式；Tests 集中说明这些调用层内容。

.. container:: ap-lang ap-lang-en

   ``calibration.hpp`` declares the forward and inverse functions; ``fun_G03_dsmc_calibration.cpp`` implements their shared coefficient and parameter validation.
   The caller fits viscosity data, determines angular parameters from diffusion data and selects the valid temperature range.

   At runtime ``VhsRate`` holds the resulting kernel, and ``VssScattering`` holds the reciprocal angular parameter.
   Given a relative velocity, the collision kernel obtains :math:`K(g)` and :math:`\mathbf g'` from these objects.
   Input files, command-line options and particle initialisation belong to individual simulation programs and are described in Tests.

.. rubric:: References and Verification

.. container:: ap-lang ap-lang-zh

   Chapman 与 Cowling, *The Mathematical Theory of Non-Uniform Gases*, 第三版 (1970)，
   提供 Chapman--Enskog、Sonine 展开与碰撞括号的系统推导；
   Bird, *Molecular Gas Dynamics and the Direct Simulation of Gas Flows* (1994)，
   给出 DSMC 分子模型与参考参数约定；
   Koura 与 Matsumoto (1991) 的 VSS 原始论文说明利用角分布匹配输运性质的模型构造。

   本模块的检查方法与判据见 :ref:`测试说明 <g03-validation-calibration>`。

.. container:: ap-lang ap-lang-en

   Chapman and Cowling, *The Mathematical Theory of Non-Uniform Gases*, third edition (1970), develops Chapman–Enskog theory, Sonine expansions and collision brackets.
   Bird, *Molecular Gas Dynamics and the Direct Simulation of Gas Flows* (1994), specifies DSMC molecular models and reference-parameter conventions.
   Koura and Matsumoto (1991) presents the VSS angular model for matching transport properties.

   Checks and acceptance criteria are given in :ref:`Verification <g03-validation-calibration>`.
