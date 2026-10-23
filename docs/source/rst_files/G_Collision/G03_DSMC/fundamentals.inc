.. _g03-physical-foundations:

Physical Foundations: Distributions, Conservation and Collision Scales
------------------------------------------------------------------------

.. container:: ap-lang ap-lang-zh

   DSMC 用位置与速度样本表示气体的分布，再通过粒子运动和随机二体碰撞推进这个分布。
   本节先明确分布函数、宏观量、二体守恒和碰撞尺度，再用 Boltzmann 方程概括气体的演化。
   随后三节分别给出碰撞率核、角分布和参数标定，并在公式旁展示实现这些物理关系的函数。
   在这些模型确定之后，“单元碰撞：NTC 与连续时钟”由碰撞算子推导有限样本的事件率与候选调度。

.. container:: ap-lang ap-lang-en

   DSMC represents a gas distribution with position and velocity samples, then advances it through particle motion and stochastic binary collisions.
   This section establishes the distribution function, its macroscopic moments, binary conservation laws and collision scales, before connecting them through the Boltzmann equation.
   The following sections derive the rate kernel, angular law and transport calibration alongside their implementations.
   Cell collision scheduling then turns the collision operator into finite-sample event rates and candidate loops.

.. _g03-notation:

.. rubric:: Notation and SI Units

.. container:: ap-lang ap-lang-zh

   粗体表示三维向量；压力张量记为 :math:`\mathsf P`。
   尖括号表示对指定分布取平均，撇号表示碰后量。
   除明确标出的 eV 外采用 SI；:math:`k_B=1.380649\times10^{-23}\,\mathrm{J/K}`。

   .. list-table::
      :header-rows: 1
      :widths: 30 46 24

      * - 符号
        - 定义
        - 单位
      * - :math:`\mathbf x,t;\ m,k_B,T`
        - 位置、时间；单分子质量、Boltzmann 常数、平动温度
        - m、s；kg、J/K、K
      * - :math:`\mathbf v,\mathbf u,\mathbf c=\mathbf v-\mathbf u`
        - 分子速度、局部平均流速、热运动速度
        - m/s
      * - :math:`\mathbf g=\mathbf v_1-\mathbf v_2,g;\ \mathbf V_{\mathrm{cm}}`
        - 两分子相对速度及模长；这对分子的质心速度
        - m/s
      * - :math:`\mu_r,E_{\mathrm{rel}},E_{\mathrm{kin}}`
        - 约化质量、相对平动能、两分子总动能
        - kg、J、J
      * - :math:`d,b,\sigma;\ K(g)=\sigma(g)g`
        - 硬球直径、碰撞参数、总截面；碰撞率核
        - m、m、m²；m³/s
      * - :math:`\chi,\varphi,\Omega;\ p_\Omega`
        - 相对速度的偏转角、方位角、相对入射方向的球面角坐标；单位立体角的条件散射概率密度
        - rad、rad、—（:math:`d\Omega` 的单位为 sr）；sr⁻¹
      * - :math:`f,\phi_v=f/n`
        - 数分布函数、速度概率密度
        - :math:`\mathrm{s^3/m^6,s^3/m^3}`
      * - :math:`n,p;\ \mathsf P,\mathbf q`
        - 数密度、标量压力；动理学压力张量、热流密度
        - m⁻³、Pa；Pa、W/m²
      * - :math:`\nu,\bar\nu,\mathcal R;\ \tau_{\mathrm{coll}},\lambda`
        - 单分子及平均碰撞频率、单位体积碰撞事件率；平均碰撞间隔、平均自由程
        - s⁻¹、s⁻¹、m⁻³s⁻¹；s、m
      * - :math:`L,\mathrm{Kn}=\lambda/L;\ \mathbf a,Q`
        - 宏观变化长度、Knudsen 数；加速度、碰撞算子
        - m、无量纲；m/s²、:math:`f/\mathrm s`
      * - :math:`N,W,V_{\mathrm{cell}},\Delta t`
        - 单元内模拟粒子数、每个样本代表的真实分子数、单元体积、时间步
        - 无量纲、无量纲、m³、s

   下标 1、2 指一对分子，:math:`\mathrm{eq}` 表示平衡态，:math:`\mathrm{tr}` 表示平动。
   质心速度 :math:`\mathbf V_{\mathrm{cm}}` 属于一对分子，平均流速 :math:`\mathbf u` 属于局部粒子群。

.. container:: ap-lang ap-lang-en

   Bold symbols denote three-dimensional vectors; :math:`\mathsf P` denotes the pressure tensor.
   Angle brackets denote an average over the specified distribution, and a prime denotes an outgoing quantity.
   SI units apply except where eV is explicitly stated; :math:`k_B=1.380649\times10^{-23}\,\mathrm{J/K}`.

   .. list-table::
      :header-rows: 1
      :widths: 30 46 24

      * - Symbol
        - Definition
        - Unit
      * - :math:`\mathbf x,t;\ m,k_B,T`
        - Position, time; molecular mass, Boltzmann constant, translational temperature
        - m, s; kg, J/K, K
      * - :math:`\mathbf v,\mathbf u,\mathbf c=\mathbf v-\mathbf u`
        - Molecular, mean-flow and thermal velocities
        - m/s
      * - :math:`\mathbf g=\mathbf v_1-\mathbf v_2,g;\ \mathbf V_{\mathrm{cm}}`
        - Relative velocity and its magnitude; pair centre-of-mass velocity
        - m/s
      * - :math:`\mu_r,E_{\mathrm{rel}},E_{\mathrm{kin}}`
        - Reduced mass, relative kinetic energy, total pair kinetic energy
        - kg, J, J
      * - :math:`d,b,\sigma;\ K(g)=\sigma(g)g`
        - Hard-sphere diameter, impact parameter, total cross section; rate kernel
        - m, m, m²; m³/s
      * - :math:`\chi,\varphi,\Omega;\ p_\Omega`
        - Deflection angle, azimuth, angular coordinates about the incident direction; conditional density per solid angle
        - rad, rad, dimensionless (:math:`d\Omega` in sr); sr⁻¹
      * - :math:`f,\phi_v=f/n`
        - Number distribution and velocity probability density
        - :math:`\mathrm{s^3/m^6,s^3/m^3}`
      * - :math:`n,p;\ \mathsf P,\mathbf q`
        - Number density, scalar pressure; kinetic pressure tensor, heat flux
        - m⁻³, Pa; Pa, W/m²
      * - :math:`\nu,\bar\nu,\mathcal R;\ \tau_{\mathrm{coll}},\lambda`
        - Molecular and mean collision frequencies, event rate per volume; mean collision interval, mean free path
        - s⁻¹, s⁻¹, m⁻³s⁻¹; s, m
      * - :math:`L,\mathrm{Kn}=\lambda/L;\ \mathbf a,Q`
        - Macroscopic variation length, Knudsen number; acceleration, collision operator
        - m, dimensionless; m/s², :math:`f/\mathrm s`
      * - :math:`N,W,V_{\mathrm{cell}},\Delta t`
        - Simulation particles per cell, molecules represented per sample, cell volume, time step
        - Dimensionless, dimensionless, m³, s

   Subscripts 1 and 2 identify a molecular pair; :math:`\mathrm{eq}` and :math:`\mathrm{tr}` denote equilibrium and translation.
   The pair velocity :math:`\mathbf V_{\mathrm{cm}}` concerns two molecules; :math:`\mathbf u` concerns the local population.

.. _g03-box-experiment:

Particle Samples and the Distribution Function
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   气体的单分子统计状态用数分布函数 :math:`f(\mathbf x,\mathbf v,t)` 描述：
   :math:`f\,d^3x\,d^3v` 是位置区间 :math:`d^3x`、速度区间 :math:`d^3v` 内的期望分子数。
   输运改变分子所处的位置，外力与碰撞改变速度；这些变化共同决定 :math:`f` 的演化。

   DSMC 以一组带统计权重的位置、速度样本近似这个连续分布。
   一个等权重模拟粒子代表 :math:`W` 个真实分子，因此包含 :math:`N` 个样本的单元代表 :math:`NW` 个分子。
   对体积为 :math:`V_{\mathrm{cell}}` 的单元，将分布在空间上平均后，其速度分布的样本表示为

.. container:: ap-lang ap-lang-en

   The number distribution :math:`f(\mathbf x,\mathbf v,t)` describes the one-molecule statistical state:
   :math:`f\,d^3x\,d^3v` is the expected number in the specified position and velocity elements.
   Transport changes position, while forces and collisions change velocity.

   DSMC approximates this continuous distribution with weighted samples.
   One equal-weight simulation particle represents :math:`W` molecules, so :math:`N` samples represent :math:`NW` molecules.
   Spatial averaging over a cell of volume :math:`V_{\mathrm{cell}}` gives the following empirical velocity distribution.

.. math::
   :label: g03-eq-empirical-distribution

   f_N(\mathbf v)=\frac{W}{V_{\mathrm{cell}}}
   \sum_{i=1}^{N}\delta^{(3)}(\mathbf v-\mathbf v_i).

.. container:: ap-lang ap-lang-zh

   :math:`\delta^{(3)}` 是三维 Dirac 分布：对任何速度函数 :math:`\psi`，
   :math:`\int\psi(\mathbf v)\delta^{(3)}(\mathbf v-\mathbf v_i)\,d^3v=\psi(\mathbf v_i)`。
   于是连续分布的积分可以由样本求和计算；这是宏观量采样和碰撞抽样共用的表示。
   实际程序保存 :math:`\mathbf x_i,\mathbf v_i,W`，空间分组给出局部的 :math:`f_N`。

.. container:: ap-lang ap-lang-en

   The three-dimensional Dirac distribution satisfies
   :math:`\int\psi(\mathbf v)\delta^{(3)}(\mathbf v-\mathbf v_i)\,d^3v=\psi(\mathbf v_i)` for any velocity function :math:`\psi`.
   Thus distribution integrals become sample sums, providing one representation for both macroscopic sampling and collision sampling.
   The program stores :math:`\mathbf x_i,\mathbf v_i,W`; spatial grouping defines the local :math:`f_N`.

.. rubric:: Source: Basic Types for Positions, Velocities and Particle IDs

.. container:: ap-lang ap-lang-zh

   粒子样本中的位置和速度是三维向量，代码用 ``Vec3`` 保存三个分量，
   用 ``Real`` 保存分量、质量和时间等数值，用粒子 ID 标识同一个样本。
   ``common.hpp`` 定义这些基础类型和 Boltzmann 常数，物理量统一采用 SI 单位。

.. container:: ap-lang ap-lang-en

   ``Vec3`` holds the three components of a sample position or velocity.
   ``Real`` holds component values, masses, times and other scalar quantities; particle IDs identify individual samples.
   ``common.hpp`` defines these types and the Boltzmann constant. Physical quantities use SI units.

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/common.hpp
   :language: cpp
   :start-at: using Real
   :end-before: inline Vec3 operator+
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/common.hpp

.. container:: ap-lang ap-lang-zh

   本章采用经典稀薄气体的二体弹性碰撞模型，其物理前提是：

   * 分子间距远大于相互作用尺度。硬球气体可用 :math:`nd^3\ll1` 衡量稀薄性。
   * 碰撞持续时间远小于相邻碰撞的平均间隔，因而可分别处理自由运动和局部瞬时碰撞。
   * 即将相遇的两分子，其碰前速度联合分布用两个单分子分布的乘积近似。这是 **分子混沌假设**，也是单元内随机配对的依据。

   这些假设把多体演化简化为单分子分布与二体碰撞；碰撞模型进一步提供发生速率和末态规律。
   当前主库处理单组分、等权重的弹性碰撞，下面先在这一范围内建立完整对应关系。

.. container:: ap-lang ap-lang-en

   The classical dilute-gas model assumes:

   * Molecular spacing greatly exceeds the interaction scale; :math:`nd^3\ll1` is the hard-sphere diluteness condition.
   * Collision duration is much shorter than the mean interval between collisions, permitting free motion and instantaneous local collisions to be treated separately.
   * The incoming pair distribution factorises into two one-molecule distributions. This **molecular-chaos assumption** underlies random pairing within a cell.

   These assumptions reduce the many-body dynamics to a one-molecule distribution and binary events.
   The present library covers single-species, equal-weight elastic collisions; a molecular model supplies each event's rate and outcome.

.. _g03-s02:

Macroscopic Moments from Distributions and Samples
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   有了 :math:`f`，数密度就是速度空间的总数，平均流速就是分子的速度平均。
   扣除平均流动以后，每个分子的平均平动能定义平动温度：

.. container:: ap-lang ap-lang-en

   Integrating :math:`f` over velocity gives number density; its first moment gives mean flow velocity.
   After subtracting that flow, the average translational kinetic energy per molecule defines translational temperature:

.. math::
   :label: g03-eq-moments

   n=\int f\,d^3v,\qquad
   \mathbf u=\frac1n\int\mathbf v f\,d^3v,\qquad
   \frac32k_BT_{\mathrm{tr}}=\frac{m}{2n}\int|\mathbf v-\mathbf u|^2f\,d^3v.

.. container:: ap-lang ap-lang-zh

   将上面的样本分布 :math:`f_N` 代入，对 :math:`N>0` 的单元立即得到采样公式：

.. container:: ap-lang ap-lang-en

   Substituting :math:`f_N` converts the integrals into the following sampling formulas for a cell with :math:`N>0`:

.. math::
   :label: g03-eq-sample-moments

   n_N=\frac{NW}{V_{\mathrm{cell}}},\qquad
   \mathbf u_N=\frac1N\sum_i\mathbf v_i,\qquad
   T_N=\frac{m}{3k_BN}\sum_i|\mathbf v_i-\mathbf u_N|^2.

.. container:: ap-lang ap-lang-zh

   这说明权重用于把样本数量换成物理数量，而流速与温度来自样本分布的形状。
   上述温度是样本中心二阶矩对应的平动温度；本章单原子气体简记 :math:`T=T_{\mathrm{tr}}`。
   即使局部速度分布远离平衡，这个定义仍然成立。

   方向动量通量和热流还需要更高的速度信息：

.. container:: ap-lang ap-lang-en

   Weight converts sample counts into physical counts; flow velocity and temperature follow from the distribution's shape.
   Here temperature is the central second moment of the samples, written :math:`T=T_{\mathrm{tr}}` for the monatomic gas.
   This definition remains meaningful away from equilibrium.

   Directional momentum flux and heat flux require further moments:

.. math::
   :label: g03-eq-moment-closure

   \mathbf c=\mathbf v-\mathbf u,\qquad
   \mathsf P=m\int\mathbf c\mathbf c\,f\,d^3v,\qquad
   \mathbf q=\frac m2\int c^2\mathbf c\,f\,d^3v.

.. container:: ap-lang ap-lang-zh

   :math:`\mathbf c\mathbf c` 是外积，例如其 :math:`xy` 分量为 :math:`c_xc_y`；
   :math:`\mathsf I` 表示三维单位张量，:math:`\mathrm{tr}` 表示张量的迹。
   :math:`\mathsf P` 的对角元记录各方向的动量通量，非对角元记录方向之间的动量输运；
   :math:`\mathbf q` 记录相对于平均流动的能量输运。
   标量动理学压力 :math:`p=\mathrm{tr}(\mathsf P)/3=nk_BT` 是三个法向动量通量的平均值。
   DSMC 推进完整的速度样本，因此这些量都能按同一个积分转求和的规则统计。

   局部平衡态的分布为

.. container:: ap-lang ap-lang-en

   The product :math:`\mathbf c\mathbf c` is an outer product, with :math:`xy` component :math:`c_xc_y`.
   :math:`\mathsf I` is the identity tensor and :math:`\mathrm{tr}` denotes its trace.
   Diagonal components of :math:`\mathsf P` measure normal momentum fluxes; off-diagonal components measure momentum transfer between directions.
   :math:`\mathbf q` measures energy transport relative to the mean flow.
   Their scalar pressure is :math:`p=\mathrm{tr}(\mathsf P)/3=nk_BT`.
   DSMC samples all these moments by the same integral-to-sum rule.

   At local equilibrium the distribution is Maxwellian:

.. math::
   :label: g03-eq-maxwell

   f_{\mathrm{eq}}(\mathbf v)=n\left(\frac{m}{2\pi k_BT}\right)^{3/2}
   \exp\!\left[-\frac{m|\mathbf v-\mathbf u|^2}{2k_BT}\right].

.. container:: ap-lang ap-lang-zh

   此时三个热速度分量各为均值 0、方差 :math:`k_BT/m` 的独立高斯量，
   :math:`\mathsf P=nk_BT\mathsf I`、:math:`\mathbf q=0`。
   Maxwell 分布可以提供平衡初值和速度尺度；进入时间推进以后，局部分布由当前样本及其碰撞历史决定。

.. container:: ap-lang ap-lang-en

   The three thermal-velocity components are independent Gaussians of mean zero and variance :math:`k_BT/m`.
   Consequently :math:`\mathsf P=nk_BT\mathsf I` and :math:`\mathbf q=0`.
   The Maxwellian supplies equilibrium initial conditions and useful speed scales.
   During time evolution, the actual samples and their collision history determine the local distribution.

.. _g03-binary-physics:

Conservation and the Outcome of a Binary Collision
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Relative and Centre-of-Mass Motion
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. container:: ap-lang ap-lang-zh

   二体末态由总动量、总能量和散射方向共同确定。先把运动分解为整对分子的平移与分子之间的相对运动：

.. container:: ap-lang ap-lang-en

   An elastic pair's outgoing state follows from total momentum, total energy and a scattering direction.
   First separate translation of the entire pair from relative motion:

.. math::
   :label: g03-eq-relative

   \mathbf V_{\mathrm{cm}}=\frac{m_1\mathbf v_1+m_2\mathbf v_2}{m_1+m_2},\qquad
   \mathbf g=\mathbf v_1-\mathbf v_2,\qquad
   \mu_r=\frac{m_1m_2}{m_1+m_2}.

.. math::
   :label: g03-eq-energy-split

   E_{\mathrm{kin}}=\frac12m_1v_1^2+\frac12m_2v_2^2
   =\frac12(m_1+m_2)|\mathbf V_{\mathrm{cm}}|^2+E_{\mathrm{rel}},\qquad
   E_{\mathrm{rel}}=\frac12\mu_r g^2.

.. container:: ap-lang ap-lang-zh

   相同的整体漂移只改变质心运动，分子之间的接近过程由 :math:`\mathbf g` 描述。
   孤立二体弹性碰撞保持总动量与总动能，等价于保持 :math:`\mathbf V_{\mathrm{cm}}` 和 :math:`g`，并改变相对速度的方向。
   因此弹性模型还需给定碰后方向 :math:`\widehat{\mathbf g}'`。
   令 :math:`\mathbf g'=g\widehat{\mathbf g}'`，还原两个分子的速度：

.. container:: ap-lang ap-lang-en

   A common velocity drift changes the centre-of-mass motion while preserving relative approach.
   For an isolated elastic pair, conservation of momentum and energy is equivalent to preserving :math:`\mathbf V_{\mathrm{cm}}` and :math:`g`.
   The model must also specify an outgoing unit direction :math:`\widehat{\mathbf g}'`.
   Set :math:`\mathbf g'=g\widehat{\mathbf g}'` and reconstruct both molecular velocities:

.. math::
   :label: g03-eq-fund-outgoing

   \mathbf v_1'=\mathbf V_{\mathrm{cm}}+\frac{m_2}{m_1+m_2}\mathbf g',\qquad
   \mathbf v_2'=\mathbf V_{\mathrm{cm}}-\frac{m_1}{m_1+m_2}\mathbf g'.

.. container:: ap-lang ap-lang-zh

   当前单组分库中 :math:`m_1=m_2=m`，两个系数都为 :math:`1/2`。
   同时更新这两个速度，就把单次碰撞的动量和能量守恒落实到了样本上。

.. container:: ap-lang ap-lang-en

   For the single-species library, :math:`m_1=m_2=m`, so both mass fractions equal :math:`1/2`.
   Updating the pair together enforces momentum and kinetic-energy conservation in each sampled event.

Total Cross Section and Angular Distribution
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. container:: ap-lang ap-lang-zh

   硬球模型假设分子在接触前自由运动，接触时发生瞬时弹性反射。
   碰撞参数 :math:`b` 是未偏转的相对入射轨迹到目标球心的最短距离。
   两个直径均为 :math:`d` 的球在 :math:`b\lt d` 时接触，允许轨迹的面积为

.. container:: ap-lang ap-lang-en

   Hard spheres move freely until contact and undergo an instantaneous elastic reflection.
   The impact parameter :math:`b` is the shortest distance from the undeflected relative trajectory to the target centre.
   Two spheres of diameter :math:`d` contact when :math:`b\lt d`; the permitted trajectories therefore occupy area:

.. math::
   :label: g03-eq-cross-section

   \sigma=\pi d^2,\qquad
   \sigma_{12}=\pi\left(\frac{d_1+d_2}{2}\right)^2.

.. container:: ap-lang ap-lang-zh

   这里 :math:`d` 是分子在硬球相互作用模型中的有效直径，用于定义截面。
   统计权重 :math:`W` 决定样本代表的分子数；两者分别进入分子碰撞核与模拟粒子配对率。

.. container:: ap-lang ap-lang-en

   The effective molecular diameter :math:`d` defines the interaction cross section.
   Statistical weight :math:`W` specifies how many molecules a sample represents.
   They enter, respectively, the molecular rate kernel and the simulation-pair event rate.

.. figure:: /_static/G_Collision/G03_DSMC/collision-geometry.svg
   :alt: Two hard spheres of diameter d and a collision disk of radius d
   :width: 700px

   The collision-disk radius is the sum of the molecular radii; the dashed circle has radius d.

.. container:: ap-lang ap-lang-zh

   总截面累加所有允许轨迹的面积，决定碰撞发生率。
   对于已经选中的碰撞，末态方向由微分截面给出：

.. container:: ap-lang ap-lang-en

   The total cross section adds all permitted trajectory areas and sets the collision rate.
   Conditional on a collision, the differential cross section determines the outgoing direction:

.. math::
   :label: g03-eq-fund-angular-law

   \sigma(g)=\int_{S^2}\frac{d\sigma}{d\Omega}(g,\Omega)\,d\Omega,
   \qquad
   p_\Omega(\Omega\mid g)=\frac1{\sigma(g)}\frac{d\sigma}{d\Omega}(g,\Omega).

.. container:: ap-lang ap-lang-zh

   :math:`S^2` 是单位球面；:math:`\Omega=(\chi,\varphi)` 是以入射方向 :math:`\mathbf g/g` 为极轴的角坐标，
   :math:`d\Omega=\sin\chi\,d\chi\,d\varphi` 是立体角元。
   偏转角 :math:`\chi` 从极轴量起，方位角 :math:`\varphi` 绕极轴测量。
   条件概率密度 :math:`p_\Omega` 对整个球面积分为 1，因而可以直接用于抽取碰后方向。

   HS 的接触几何给出各向同性角分布 :math:`p_\Omega=1/(4\pi)`。
   “弹性散射：守恒律、角测度与 VSS”将从碰撞参数推导这一结果，再引入 VSS 的角分布。
   总截面与角分布分别规定碰撞发生率与碰后方向。

.. container:: ap-lang ap-lang-en

   :math:`S^2` is the unit sphere and :math:`\Omega=(\chi,\varphi)` gives angular coordinates with polar axis :math:`\mathbf g/g`.
   The deflection :math:`\chi` is measured from this axis; the azimuth :math:`\varphi` is measured around it.
   The solid-angle element is :math:`d\Omega=\sin\chi\,d\chi\,d\varphi`.
   The conditional density :math:`p_\Omega` integrates to one over the sphere, making it a sampling law for the outgoing direction.

   Hard-sphere contact geometry yields isotropic scattering, :math:`p_\Omega=1/(4\pi)`.
   The Elastic Scattering section derives this result from the impact parameter and then introduces the VSS angular law.
   Total cross section and angular distribution thus specify event frequency and event outcome.

.. _g03-s03:

Collision Rates and Molecular Time and Length Scales
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   先看一组速度相同、数密度为 :math:`n` 的目标分子。
   测试分子相对它们以速率 :math:`g` 运动，在 :math:`dt` 内扫过体积 :math:`\sigma(g)gdt`，
   平均遇到 :math:`n\sigma(g)gdt` 个目标。
   由此定义碰撞率核 :math:`K(g)=\sigma(g)g`；它的单位是体积/时间，乘数密度得到碰撞频率。

   实际目标有不同速度。令 :math:`\mathbf w` 为目标速度，
   :math:`\phi_v(\mathbf w)=f(\mathbf w)/n` 为归一化速度概率密度，分别计算各速度群的贡献并积分：

.. container:: ap-lang ap-lang-en

   Consider targets with a common velocity and number density :math:`n`.
   A molecule travelling at relative speed :math:`g` sweeps volume :math:`\sigma(g)gdt` in time :math:`dt`, encountering :math:`n\sigma(g)gdt` targets on average.
   This defines :math:`K(g)=\sigma(g)g`, a volume per time; multiplication by number density gives a collision frequency.

   Actual targets have a velocity distribution.
   Writing target velocity as :math:`\mathbf w` and its normalised density as :math:`\phi_v(\mathbf w)=f(\mathbf w)/n`, sum the contributions of all target velocities:

.. math::
   :label: g03-eq-frequency

   \nu(\mathbf v)=n\int K(|\mathbf v-\mathbf w|)\phi_v(\mathbf w)\,d^3w,\qquad
   \bar\nu=\int\phi_v(\mathbf v)\nu(\mathbf v)\,d^3v.

.. container:: ap-lang ap-lang-zh

   碰撞更新速度，也就更新后续的相对速率与碰撞频率。
   在单组分气体中，单位体积内的碰撞事件率为

.. container:: ap-lang ap-lang-en

   A collision changes velocity and hence the relative speeds used in later events.
   For a single-species gas, the number of events per unit volume and time is:

.. math::
   :label: g03-eq-event-density

   \mathcal R=\frac12n\bar\nu
   =\frac12n^2\langle K\rangle.

.. container:: ap-lang ap-lang-zh

   一次二体碰撞涉及两个分子，系数 :math:`1/2` 将碰撞参与次数换成事件数。
   :math:`\langle K\rangle` 对两个独立入射速度样本取平均。
   给定速度分布和碰撞模型后，事件率随局部数密度的平方增长。

   若一段飞行中的碰撞频率为常量 :math:`\nu`，无碰撞概率满足
   :math:`dS/dt=-\nu S`，所以 :math:`S(t)=e^{-\nu t}`。
   平均等待时间为 :math:`1/\nu`，在 :math:`\Delta t` 内至少碰撞一次的概率为
   :math:`1-e^{-\nu\Delta t}`。变化的频率对应积分危险率
   :math:`S(t)=\exp[-\int_0^t\nu(s)\,ds]`。

.. container:: ap-lang ap-lang-en

   Each event involves two molecules, so the factor :math:`1/2` converts collision participations to events.
   :math:`\langle K\rangle` averages over two independent incoming velocities.
   With a fixed velocity distribution and model, the event rate grows as the square of density.

   For constant molecular frequency :math:`\nu`, collision-free survival obeys :math:`dS/dt=-\nu S`, hence :math:`S(t)=e^{-\nu t}`.
   The mean waiting time is :math:`1/\nu` and the probability of at least one collision in :math:`\Delta t` is :math:`1-e^{-\nu\Delta t}`.
   A varying frequency gives the integrated-hazard expression :math:`S(t)=\exp[-\int_0^t\nu(s)\,ds]`.

Scales for an Equilibrium Hard-Sphere Gas
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. container:: ap-lang ap-lang-zh

   同温、同平均流速的两个独立 Maxwell 速度样本之差，每个分量的方差为 :math:`k_BT/\mu_r`。
   记单分子的平均热速率为 :math:`\bar c=\sqrt{8k_BT/(\pi m)}`。对同质量分子，得到

.. container:: ap-lang ap-lang-en

   Subtract two independent Maxwell velocities at a common temperature and mean flow.
   Each relative component has variance :math:`k_BT/\mu_r`.
   Let :math:`\bar c=\sqrt{8k_BT/(\pi m)}` denote the mean molecular thermal speed.
   For equal molecular masses this gives:

.. math::
   :label: g03-equation-06

   \langle g\rangle=\sqrt{\frac{8k_BT}{\pi\mu_r}}=\sqrt2\,\bar c,\qquad
   \sqrt{\langle g^2\rangle}=\sqrt{\frac{6k_BT}{m}}.

.. container:: ap-lang ap-lang-zh

   因为硬球的总截面为常量，:math:`\bar\nu=n\sigma\langle g\rangle`，因此

.. container:: ap-lang ap-lang-en

   The HS cross section is constant, so :math:`\bar\nu=n\sigma\langle g\rangle` and:

.. math::
   :label: g03-eq-mfp

   \tau_{\mathrm{coll}}=\frac1{\bar\nu},\qquad
   \lambda=\frac{\bar c}{\bar\nu}=\frac1{\sqrt2n\sigma},\qquad n=\frac p{k_BT}.

.. container:: ap-lang ap-lang-zh

   这里的自由程按长时间内总热运动路程除以碰撞参与次数定义。
   一般非平衡分布或速度依赖截面可直接用当前分布对 :math:`K` 平均，求得相应的 :math:`\bar\nu`。
   碰撞间隔反映事件出现的快慢；方向动量与热流的弛豫还依赖散射角的作用，
   这也为“参数标定：为什么黏度与扩散约束不同的碰撞矩”提供了物理动机。

.. container:: ap-lang ap-lang-en

   Here mean free path means total thermal path length divided by the number of collision participations over a long observation.
   For a nonequilibrium distribution or a speed-dependent cross section, average :math:`K` over the actual distribution to obtain :math:`\bar\nu`.
   The collision interval measures event frequency; relaxation of directional momentum and heat flux also depends on scattering angles.
   This distinction motivates the transport calibration derived later.

Molecular and Macroscopic Scales
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. container:: ap-lang ap-lang-zh

   若温度、密度或流速显著变化的长度为 :math:`L`，则

.. container:: ap-lang ap-lang-en

   Let :math:`L` be the length over which density, temperature or flow velocity varies appreciably. Then:

.. math::
   :label: g03-eq-kn

   \mathrm{Kn}=\frac\lambda L.

.. container:: ap-lang ap-lang-zh

   这个比值比较分子输运距离与宏观非均匀尺度。
   当两者相近时，分子能在一次自由飞行中经历明显不同的局部状态，
   局部平衡附近的本构关系需要重新评估。
   DSMC 以速度分布为演化对象；“单元与时间步把局部近似限制在什么尺度”将据此确定时间步、碰撞单元和粒子样本所需的分辨率。

.. container:: ap-lang ap-lang-en

   The Knudsen number compares molecular travel with macroscopic variation.
   When these lengths are comparable, one free flight crosses substantially different local states, requiring reassessment of constitutive laws based on near-local equilibrium.
   DSMC evolves the velocity distribution itself.
   The later resolution discussion uses these scales to constrain time steps, collision cells and particle sampling.

.. _g03-kinetic-equation:

The Physical Processes in the Boltzmann Equation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   分布函数把前面的分子运动和碰撞连接到同一个演化问题。
   取与速度无关的加速度 :math:`\mathbf a`，气体在计算域内部满足

.. container:: ap-lang ap-lang-en

   The distribution function connects molecular motion and collisions in one evolution equation.
   For velocity-independent acceleration :math:`\mathbf a`, the gas inside the computational domain obeys:

.. math::
   :label: g03-eq-boltzmann

   \frac{\partial f}{\partial t}+\mathbf v\cdot\nabla_{\mathbf x}f
   +\mathbf a\cdot\nabla_{\mathbf v}f=Q(f,f).

.. container:: ap-lang ap-lang-zh

   左侧描述粒子在相空间中的输运：速度决定空间位置的变化，外力决定速度的变化。
   右侧 :math:`Q` 描述同一位置附近的二体碰撞，把分子从原速度状态重新分配到其他速度状态。
   分子混沌假设使碰前二体分布由两个单分子分布的乘积给出，因此碰撞项对 :math:`f` 为二次型。
   截面和角分布共同规定 :math:`Q`，从而规定这一气体模型的动力学。

   局部弹性碰撞保持分子数、总动量和总动能：

.. container:: ap-lang ap-lang-en

   The left side describes transport in phase space: velocity moves particles through position space, and acceleration moves them through velocity space.
   The collision operator :math:`Q` redistributes velocities through local binary events.
   Molecular chaos represents the incoming pair density by a product of one-molecule densities, making :math:`Q` quadratic in :math:`f`.
   The total cross section and angular law together specify this operator and the gas model's kinetics.

   Elastic local collisions conserve molecular number, total momentum and total kinetic energy:

.. math::
   :label: g03-equation-12

   \int Q\,d^3v=0,\qquad \int m\mathbf vQ\,d^3v=\mathbf0,\qquad
   \int\frac12mv^2Q\,d^3v=0.

.. container:: ap-lang ap-lang-zh

   这三个恒等式分别给出数目、动量和能量方程中的碰撞贡献。
   更高阶速度矩一般会随碰撞改变，例如方向温度差和剪切应力可以逐渐弛豫。
   因此，同样的总能量可以对应不同分布，而碰撞控制着这些分布之间的演化。

   DSMC 用有限样本近似这个动力学问题。这里已经明确它需要保持的物理量，
   以及模型必须提供的两个函数：碰撞率核 :math:`K(g)` 和条件角分布 :math:`p_\Omega`。
   “碰撞频率”“弹性散射”和“参数标定”依次推导这两个函数及其参数；
   “单元碰撞：NTC 与连续时钟”从 :math:`Q` 的弱形式出发，推导模拟粒子对的事件率并逐段对应单元碰撞内核。

   相应的数量恢复、Galilean 不变性与权重一致性检查见 :ref:`验证判据 <g03-validation-fundamentals>`。

.. container:: ap-lang ap-lang-en

   These three identities give the collision contributions to the number, momentum and energy balance equations.
   Higher moments can relax, including directional temperature differences and shear stress.
   Distributions with identical total energy can therefore evolve differently under collisions.

   DSMC approximates this kinetic evolution with finite samples.
   The required invariants and model functions are now explicit: :math:`K(g)` and :math:`p_\Omega`.
   Collision Rates, Elastic Scattering and Parameter Calibration derive these functions and their parameters.
   The cell-collision section starts from the weak form of :math:`Q`, obtains simulation-pair event rates, and maps the candidate loop to source code.

   Number recovery, Galilean invariance and weight consistency are checked in :ref:`Verification <g03-validation-fundamentals>`.
