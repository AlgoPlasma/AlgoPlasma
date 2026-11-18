.. _g03-rate:

.. _g03-elastic-models:

Collision Rates: From Cross Sections to HS and VHS Kernels
------------------------------------------------------------------------

.. container:: ap-lang ap-lang-zh

   本模块回答一个问题： **给定两分子的相对速度，它们以多大的速率发生碰撞？**
   它输出碰撞率核 :math:`K(g)=\sigma(g)g`。碰撞核确定发生频率，弹性散射模型确定碰后朝向，
   输运数据确定参考参数。三者组合后构成完整的 HS、VHS 或 VSS 模型。

   本节限定为经典稀薄、单组分、中性单原子气体的二体弹性碰撞。
   :math:`m` 是单分子质量；所有相对速度均在共同的正交基底下计算。

.. container:: ap-lang ap-lang-en

   This module determines the collision rate for a molecular pair with a specified relative velocity.
   Its output is :math:`K(g)=\sigma(g)g`.
   The rate kernel sets event frequency, the elastic-scattering model sets the outgoing direction, and transport data fix the reference parameters.
   Together these define HS, VHS or VSS.

   The scope is classical, dilute, single-species, neutral monatomic gas with binary elastic collisions.
   :math:`m` denotes molecular mass; all relative velocities use a common orthonormal basis.

Theory: The Collision Rate Kernel
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   前面的扫掠体积给出 :math:`dV_{\mathrm{sweep}}=\sigma(g)g\,dt`。
   因此相对速率为 :math:`g` 的一对分子对应物理函数

.. container:: ap-lang ap-lang-en

   The swept volume is :math:`dV_{\mathrm{sweep}}=\sigma(g)g\,dt`.
   This identifies the following physical function for a pair with relative speed :math:`g`:

.. math::
   :label: g03-rate-kernel

   \boxed{K(g)=\sigma(g)g},\qquad
   [\sigma]=\mathrm{m^2},\quad [g]=\mathrm{m/s},\quad
   [K]=\mathrm{m^3/s}.

.. container:: ap-lang ap-lang-zh

   乘上目标数密度后，它给出碰撞频率；对目标速度分布平均后，得到前述 :math:`\nu(\mathbf v)`。
   本节要确定的是 :math:`\sigma(g)` 的具体形式。
   共同给所有速度加一个漂移 :math:`\mathbf U` 保持 :math:`\mathbf g` 不变，
   所以这些核也满足 Galilean 不变性。

.. container:: ap-lang ap-lang-en

   Multiplying by target number density gives a collision frequency; averaging over target velocities gives :math:`\nu(\mathbf v)`.
   The remaining task is to choose :math:`\sigma(g)`.
   A common drift :math:`\mathbf U` preserves relative velocity, so these kernels are Galilean invariant.

HS: Consequences of the Hard-Sphere Assumption
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. container:: ap-lang ap-lang-zh

   HS 假设两个直径为 :math:`d` 的球在接触前没有作用，接触时瞬时弹性反射。
   相对入射轨迹的碰撞参数 :math:`b` 小于两个半径之和 :math:`d` 时发生碰撞。
   因此

.. container:: ap-lang ap-lang-en

   HS assumes free motion until contact between spheres of diameter :math:`d`, followed by instantaneous elastic reflection.
   Contact occurs when the relative trajectory's impact parameter :math:`b` is smaller than the sum of radii, :math:`d`.
   Integrating the permitted annuli gives:

.. math::

   \sigma_{\mathrm{HS}}
   =\int_0^d 2\pi b\,db=\pi d^2,\qquad
   \boxed{K_{\mathrm{HS}}(g)=\pi d^2g}.

.. container:: ap-lang ap-lang-zh

   这里 :math:`d` 是两个等直径分子中 **每个分子的直径**，
   碰撞圆盘的半径恰好也为 :math:`d`。模拟粒子权重 :math:`W` 则决定每个样本代表的分子数，
   通过配对的统计速率进入算法；分子直径由气体物性确定。

   模拟粒子的位置用于确定局部碰撞单元；相互作用的几何信息则通过截面进入碰撞核。

   HS 还规定了散射角与 :math:`b` 的几何关系，因而不仅是一个常截面模型。
   本章“弹性散射：守恒律、角测度与 VSS”中的“从碰撞参数到角概率：HS 的几何推导”
   将利用这一接触几何得到各向同性微分截面。

.. container:: ap-lang ap-lang-en

   Here :math:`d` is the diameter of **each molecule**; the collision disk also has radius :math:`d` for two equal spheres.
   The weight :math:`W` counts molecules represented by one sample and enters the statistical pair rate.
   Molecular properties determine :math:`d`.

   Sample positions locate collision cells; the cross section carries the interaction geometry into the rate kernel.
   HS additionally specifies the relation between :math:`b` and scattering angle.
   The HS geometry subsection in Elastic Scattering uses that relation to derive the isotropic differential cross section.

.. rubric:: Source: HardSphereRate::kernel

.. container:: ap-lang ap-lang-zh

   ``HardSphereRate`` 在构造时保存 :math:`\pi d^2`，每次 ``kernel(g)`` 返回 :math:`\pi d^2g`：

.. container:: ap-lang ap-lang-en

   ``HardSphereRate`` stores :math:`\pi d^2` at construction; each ``kernel(g)`` returns :math:`\pi d^2g`:

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_rate.cpp
   :language: cpp
   :start-at: HardSphereRate::HardSphereRate
   :end-before: VhsRate::VhsRate
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/fun_G03_dsmc_rate.cpp

.. container:: ap-lang ap-lang-zh

   ``diameter`` 对应 :math:`d`，``cross_section_m2_`` 对应 :math:`\sigma`，
   ``q`` 是返回的 :math:`K(g)`。单元内核 ``collide_cell`` 根据当前双方速度计算 ``g``，
   再通过 ``model.rate().kernel(...)`` 调用这个函数。
   这样，气体物性只在构造时设置，相对速率则在每次候选时重新取得。

.. container:: ap-lang ap-lang-en

   ``diameter`` is :math:`d`, ``cross_section_m2_`` is :math:`\sigma`, and the returned ``q`` is :math:`K(g)`.
   ``collide_cell`` obtains ``g`` from the pair's current velocities and calls ``model.rate().kernel(...)``.
   Gas parameters are fixed at construction; each candidate supplies its current relative speed.

Why the Effective Cross Section Depends on Speed
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. container:: ap-lang ap-lang-zh

   真实分子间的作用力通常随距离连续变化。
   相对动能增大时，给定碰撞参数下的偏转角通常减小。
   一个可说明尺度的例子是斥力势

.. container:: ap-lang ap-lang-en

   Real intermolecular forces generally vary continuously with separation.
   At a fixed impact parameter, increasing relative kinetic energy usually reduces deflection.
   A repulsive potential illustrates the associated scaling:

.. math::

   U(r)=A r^{-s},\qquad A>0,\quad s>0.

.. container:: ap-lang ap-lang-zh

   等质量分子的相对动能为 :math:`E_{\mathrm{rel}}=mg^2/4`。
   由 :math:`U(r_*)\sim E_{\mathrm{rel}}` 得到特征作用尺度

.. container:: ap-lang ap-lang-en

   For equal masses :math:`E_{\mathrm{rel}}=mg^2/4`.
   Equating the potential scale with this energy, :math:`U(r_*)\sim E_{\mathrm{rel}}`, defines:

.. math::

   r_*=\left(\frac{A}{E_{\mathrm{rel}}}\right)^{1/s}
   \propto g^{-2/s}.

.. container:: ap-lang ap-lang-zh

   将经典二体轨道方程中的距离除以 :math:`r_*` 后，剩余轨道形状只依赖无量纲碰撞参数。
   因此，在相应角积分收敛的条件下， **输运截面** 具有严格的齐次缩放

.. container:: ap-lang ap-lang-en

   After scaling distances in the classical two-body trajectory equation by :math:`r_*`, the trajectory shape depends only on the dimensionless impact parameter.
   Where the relevant angular integral converges, the **transport cross section** therefore has the homogeneous scaling:

.. math::

   Q^{(l)}(g)\propto r_*^2\propto g^{-4/s}.

.. container:: ap-lang ap-lang-zh

   这一缩放为幂律模型提供了尺度依据。有效总截面与角分布仍需作为模型的一部分选定。
   无限作用范围的幂律势允许任意远处的微小偏转，若把所有非零偏转都算作一次碰撞，
   其总截面可发散；输运截面中的小角度权重可使相应积分收敛。
   VHS 用有限的有效总截面和简化角分布，近似重现选定的输运性质。

.. container:: ap-lang ap-lang-en

   This provides a basis for a power-law effective model; its total cross section and angular law still require specification.
   An infinite-range potential permits arbitrarily distant weak deflections.
   Counting every nonzero deflection can yield a divergent total cross section, while small-angle weights can make transport integrals finite.
   VHS uses a finite effective total cross section and a simple angular law to reproduce selected transport properties.

The VHS Exponent and the Viscosity Exponent
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. container:: ap-lang ap-lang-zh

   用 :math:`\beta` 表示截面对相对速率的衰减指数，先假设有效截面具有幂律形式，且归一化角分布不依赖速率：

.. container:: ap-lang ap-lang-en

   Let :math:`\beta` denote the decay exponent of an effective cross section, and assume the normalised angular law is independent of speed:

.. math::

   \sigma(g)\propto g^{-\beta},\qquad
   K(g)\propto g^{1-\beta}.

.. container:: ap-lang ap-lang-zh

   用 :math:`\mu(T)` 表示动力黏度，单位为 :math:`\mathrm{Pa\,s}`。
   在局部 Maxwell 分布中，所有热速度按 :math:`\sqrt{T}` 缩放。
   因此线性化碰撞算子的速率尺度是
   :math:`nT^{(1-\beta)/2}`。黏性应力的驱动尺度为压力 :math:`nk_BT`，
   除以碰撞松弛速率便给出

.. container:: ap-lang ap-lang-en

   Dynamic viscosity :math:`\mu(T)` has units :math:`\mathrm{Pa\,s}`.
   All thermal velocities in a local Maxwellian scale as :math:`\sqrt T`, so the linearised collision-operator rate scales as :math:`nT^{(1-\beta)/2}`.
   The shear-driving scale is pressure, :math:`nk_BT`.
   Dividing by the relaxation-rate scale gives:

.. math::

   \mu(T)\propto
   \frac{nT}{nT^{(1-\beta)/2}}
   =T^{(1+\beta)/2}.

.. container:: ap-lang ap-lang-zh

   “参数标定：为什么黏度与扩散约束不同的碰撞矩”将用无量纲化后的 Chapman--Enskog 方程严格确认这一关系。
   对于这个齐次核，完整的一级 Chapman--Enskog 解与第一 Sonine 截断具有相同温度指数；
   截断影响的是前面的系数。

   若希望模型符合一个温区内的关系
   :math:`\mu(T)=\mu_{\mathrm{ref}}(T/T_{\mathrm{ref}})^\omega`，
   必须令

.. container:: ap-lang ap-lang-en

   Parameter Calibration confirms this scaling by nondimensionalising the Chapman–Enskog equation.
   For a homogeneous kernel, the full first-order Chapman–Enskog solution and its first Sonine approximation share the temperature exponent; truncation changes the coefficient.

   To reproduce :math:`\mu(T)=\mu_{\mathrm{ref}}(T/T_{\mathrm{ref}})^\omega` within a selected temperature range, choose:

.. math::
   :label: g03-rate-exponents

   \beta=2\omega-1,\qquad
   \boxed{\sigma_{\mathrm{VHS}}(g)\propto g^{1-2\omega}},\qquad
   \boxed{K_{\mathrm{VHS}}(g)\propto g^{2-2\omega}}.

.. container:: ap-lang ap-lang-zh

   于是 HS 对应 :math:`\omega=1/2`，Maxwell 型速率核对应 :math:`\omega=1`。
   当上述斥力势的输运积分收敛时，尺度关系给出 :math:`\omega=1/2+2/s`；
   这里的 :math:`s` 是 **势能** 的幂指数，若用力的指数记号则会相差 1。

   幂律与参数的选取属于建模过程。固定 :math:`\omega` 的适用性以标定温区为依据；
   向其他温区或强非平衡条件推广时，需要重新评估模型与目标气体的符合程度。

.. container:: ap-lang ap-lang-en

   HS corresponds to :math:`\omega=1/2`; a Maxwell-type constant rate kernel corresponds to :math:`\omega=1`.
   For the repulsive potential above, convergent transport integrals give :math:`\omega=1/2+2/s`.
   Here :math:`s` is the **potential-energy** exponent; a force-law exponent differs by one.

   The chosen power law and constant :math:`\omega` are justified over their calibration range.
   Extensions to other temperatures or strong nonequilibrium require checking agreement with the target gas.

The Gamma Function in Bird’s Reference-Diameter Convention
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. container:: ap-lang ap-lang-zh

   同种分子的约化质量为 :math:`m/2`，定义

.. container:: ap-lang ap-lang-en

   For identical molecules the reduced mass is :math:`m/2`. Define the reference relative speed:

.. math::

   g_{\mathrm{ref}}=\sqrt{\frac{4k_BT_{\mathrm{ref}}}{m}}.

.. container:: ap-lang ap-lang-zh

   本库采用 Bird 的参考直径规范，其中 :math:`\Gamma` 为 Gamma 函数：

.. container:: ap-lang ap-lang-en

   The library uses Bird's reference-diameter convention, with Gamma function :math:`\Gamma`:

.. math::
   :label: g03-rate-bird

   \sigma(g)=
   \frac{\pi d_{\mathrm{ref}}^2}{\Gamma(5/2-\omega)}
   \left(\frac{g_{\mathrm{ref}}}{g}\right)^{2\omega-1},
   \qquad g>0,

.. math::

   \boxed{
   K(g)=K_{\mathrm{ref}}
   \left(\frac{g}{g_{\mathrm{ref}}}\right)^{2-2\omega}},
   \qquad
   K_{\mathrm{ref}}=
   \frac{\pi d_{\mathrm{ref}}^2g_{\mathrm{ref}}}{\Gamma(5/2-\omega)}.

.. rubric:: Source: The Three Precomputed Quantities in VhsRate

.. container:: ap-lang ap-lang-zh

   ``VhsRate`` 的构造函数直接保存 :math:`g_{\mathrm{ref}}`、:math:`K_{\mathrm{ref}}`
   和 :math:`a=2-2\omega`，使每次计算只需要一次无量纲幂运算：

.. container:: ap-lang ap-lang-en

   The ``VhsRate`` constructor stores :math:`g_{\mathrm{ref}}`, :math:`K_{\mathrm{ref}}` and :math:`a=2-2\omega`.
   Each later evaluation then needs only a dimensionless power:

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_rate.cpp
   :language: cpp
   :start-at:     g_ref_ =
   :end-at:     exponent_ =
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/fun_G03_dsmc_rate.cpp

.. container:: ap-lang ap-lang-zh

   ``temperature`` 是输入的参考温度 :math:`T_{\mathrm{ref}}`，``mass`` 是单分子质量 :math:`m`，
   ``diameter`` 是 Bird 规范的 :math:`d_{\mathrm{ref}}`。
   这些量在模型寿命内固定；当前粒子对的速度通过 ``kernel(g)`` 单独传入。

   Gamma 因子规定参考直径的归一化方式。
   对于同温、同平均流速的两个独立 Maxwell 速度样本，相对速率矩为：

.. container:: ap-lang ap-lang-en

   ``temperature``, ``mass`` and ``diameter`` are :math:`T_{\mathrm{ref}}`, molecular mass :math:`m` and Bird's :math:`d_{\mathrm{ref}}`.
   They remain fixed throughout the model's lifetime; each pair supplies its speed to ``kernel(g)``.

   The Gamma factor normalises the reference diameter.
   For two independent Maxwell velocities with common temperature and mean flow, relative-speed moments are:

.. math::

   \langle g^r\rangle_T
   =\left(\frac{4k_BT}{m}\right)^{r/2}
     \frac{\Gamma((r+3)/2)}{\Gamma(3/2)},\qquad r>-3.

.. container:: ap-lang ap-lang-zh

   把 :math:`r=2-2\omega` 代入上式，得到

.. container:: ap-lang ap-lang-en

   Substitute :math:`r=2-2\omega` into this moment to obtain:

.. math::
   :label: g03-rate-mean

   \langle K\rangle_T
   =\frac{\pi d_{\mathrm{ref}}^2g_{\mathrm{ref}}}{\Gamma(3/2)}
     \left(\frac{T}{T_{\mathrm{ref}}}\right)^{1-\omega}
   =\pi d_{\mathrm{ref}}^2\langle g\rangle_T
     \left(\frac{T_{\mathrm{ref}}}{T}\right)^{\omega-1/2}.

.. container:: ap-lang ap-lang-zh

   因此，在 :math:`T=T_{\mathrm{ref}}` 时，模型的平均总碰撞核
   等于直径为 :math:`d_{\mathrm{ref}}` 的 HS 平均核。
   在参考相对速率处则有 :math:`\sigma(g_{\mathrm{ref}})=\pi d_{\mathrm{ref}}^2/\Gamma(5/2-\omega)`。
   采用其他直径归一化约定时，应同步换算直径与黏度标定公式。

.. container:: ap-lang ap-lang-en

   At :math:`T=T_{\mathrm{ref}}`, the mean total rate kernel therefore equals that of HS with diameter :math:`d_{\mathrm{ref}}`.
   At the reference speed itself, :math:`\sigma(g_{\mathrm{ref}})=\pi d_{\mathrm{ref}}^2/\Gamma(5/2-\omega)`.
   Other diameter conventions require corresponding conversions of both diameter and viscosity-calibration formulas.

Numerical Evaluation: From the Power Law to kernel(g)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   碰撞内核使用 :math:`K(g)`，实现直接计算这个有限物理量。
   这样在 :math:`g\to0` 时也能明确处理幂律的端点。

   本库范围为 :math:`1/2\le\omega\le1`，令 :math:`a=2-2\omega`，则
   :math:`0\le a\le1`：

   * :math:`a>0` 且 :math:`g=0` 时，:math:`K=0`。
   * :math:`a=0` 时，:math:`K=K_{\mathrm{ref}}`，包括 :math:`g=0`；
     这是 Maxwell 型模型核的连续延拓，代码不计算 :math:`0^0`。
   * :math:`g>0` 时，计算 :math:`K_{\mathrm{ref}}(g/g_{\mathrm{ref}})^a`。
   * 输入为负数或非有限值，以及结果溢出时，报告错误。

   :math:`\omega=1,g=0` 时形式上仍可能接受一次事件，
   但两分子的相对速度为零，弹性散射后速度不会变化。
   这给出了 Maxwell 型有效核在零相对速率处的退化行为。

.. container:: ap-lang ap-lang-en

   The implementation evaluates the finite physical kernel :math:`K(g)` directly, including its zero-speed limit.
   The supported range is :math:`1/2\le\omega\le1`, giving :math:`0\le a=2-2\omega\le1`:

   * If :math:`a>0` and :math:`g=0`, return :math:`K=0`.
   * If :math:`a=0`, return :math:`K=K_{\mathrm{ref}}` even at :math:`g=0`. This continuous extension of the Maxwell-type kernel avoids evaluating :math:`0^0`.
   * If :math:`g>0`, evaluate :math:`K_{\mathrm{ref}}(g/g_{\mathrm{ref}})^a`.
   * Reject negative or non-finite inputs and report overflow.

   For :math:`\omega=1,g=0`, a formal event can still be accepted, but elastic scattering leaves both velocities unchanged.
   This is the constant effective kernel's degenerate zero-relative-speed case.

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_rate.cpp
   :language: cpp
   :start-at: Real VhsRate::kernel
   :end-before: } // namespace algoplasma::dsmc
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/fun_G03_dsmc_rate.cpp

.. container:: ap-lang ap-lang-zh

   这里 ``exponent_`` 对应 :math:`a`，``kernel_ref_`` 对应 :math:`K_{\mathrm{ref}}`。
   两个提前返回分别实现常核与零相对速率分支；最后的 ``q`` 就是上面 Bird 规范的幂律。
   所有分支统一返回 :math:`\mathrm{m^3/s}`，调用方随后使用它计算候选接受概率。

   因为本范围内 :math:`K(g)` 单调不减，给出可靠的相对速率上界
   :math:`g_{\max}` 后，可令

.. container:: ap-lang ap-lang-en

   ``exponent_`` is :math:`a`, and ``kernel_ref_`` is :math:`K_{\mathrm{ref}}`.
   The early returns implement the constant-kernel and zero-speed branches; ``q`` evaluates Bird's power law.
   Every branch returns :math:`\mathrm{m^3/s}`, which the caller uses in the candidate acceptance probability.

   Within the supported range :math:`K(g)` is nondecreasing.
   A reliable speed bound :math:`g_{\max}` therefore gives:

.. math::

   K_{\max}=K(g_{\max}),\qquad
   K(g)\le K_{\max}\quad(0\le g\le g_{\max}).

.. container:: ap-lang ap-lang-zh

   ``majorant(g_max)`` 承诺的是整个区间上的上界。
   调用方仍须保证碰撞过程中所有实际相对速率落在该区间。
   :math:`\omega>1` 会产生零速率处发散的核，需要另行设计上界策略与对应算法。

.. container:: ap-lang ap-lang-en

   ``majorant(g_max)`` promises a bound over the entire interval.
   The caller must ensure that all relative speeds reached during the collision substep remain within it.
   :math:`\omega>1` produces a kernel singular at zero speed and requires a different bound and scheduling strategy.

Source: One Rate Interface for One Mathematical Object
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   公开接口位于 ``G_Collision/G03_DSMC/rate.hpp``；
   ``HardSphereRate`` 与 ``VhsRate`` 分别实现上述两个核。
   速率模块不读取参数文件，也不关心单元形状、模拟粒子权重和随机数。

.. container:: ap-lang ap-lang-en

   The public interface is in ``G_Collision/G03_DSMC/rate.hpp``.
   ``HardSphereRate`` and ``VhsRate`` implement the two kernels above.
   This module is independent of parameter-file parsing, cell geometry, sample weight and random numbers.

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/rate.hpp
   :language: cpp
   :start-at: class PairRateModel
   :end-before: class HardSphereRate
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/rate.hpp

.. container:: ap-lang ap-lang-zh

   ``DsmcModel`` 的构造函数根据模型类型选择 ``HardSphereRate`` 或 ``VhsRate``。
   前者用于 HS，后者同时供 VHS 和 VSS 使用；VHS 与 VSS 的区别由散射对象承担。
   ``collide_cell`` 通过 ``PairRateModel`` 读取核及区间上界；
   增加其他速率规律时，需要同时扩展速率实现与 ``DsmcModel`` 的构造分支。
   若希望 VHS 与 VSS 具有相同参考黏度，应根据各自角分布分别标定参考直径。

.. container:: ap-lang ap-lang-en

   ``DsmcModel`` selects ``HardSphereRate`` for HS and ``VhsRate`` for both VHS and VSS.
   The scattering object supplies the distinction between VHS and VSS.
   ``collide_cell`` reads the kernel and interval bound through ``PairRateModel``.
   Adding a rate law requires its implementation and a corresponding model-construction branch.
   To match the same reference viscosity with VHS and VSS, calibrate their reference diameters using their respective angular laws.

.. rubric:: References and Verification

.. container:: ap-lang ap-lang-zh

   Bird, *Molecular Gas Dynamics and the Direct Simulation of Gas Flows* (1994) 的分子模型部分；
   Chapman 与 Cowling, *The Mathematical Theory of Non-Uniform Gases*, 第三版 (1970) 的
   碰撞积分与逆幂势分析。有关“真实势、有效截面与输运拟合”的区别，应将本节与
   后续的散射与参数标定两节连续阅读。

   本模块的检查方法与判据见 :ref:`测试说明 <g03-validation-rate>`。

.. container:: ap-lang ap-lang-en

   See the molecular-model chapters in Bird, *Molecular Gas Dynamics and the Direct Simulation of Gas Flows* (1994),
   and the collision-integral and inverse-power-potential analysis in Chapman and Cowling, *The Mathematical Theory of Non-Uniform Gases*, third edition (1970).
   Read this section with Elastic Scattering and Parameter Calibration to connect a physical potential, effective cross sections and transport fitting.

   Checks and acceptance criteria are given in :ref:`Verification <g03-validation-rate>`.
