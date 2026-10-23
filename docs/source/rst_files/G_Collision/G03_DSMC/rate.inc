.. _g03-rate:
.. _g03-elastic-models:

碰撞频率：从截面到 HS / VHS 核
------------------------------------------------------------------------

本模块回答一个问题： **给定两分子的相对速度，它们以多大的速率发生碰撞？**
它输出碰撞率核 :math:`K(g)=\sigma(g)g`。碰撞核确定发生频率，弹性散射模型确定碰后朝向，
输运数据确定参考参数。三者组合后构成完整的 HS、VHS 或 VSS 模型。

本节限定为经典稀薄、单组分、中性单原子气体的二体弹性碰撞。
:math:`m` 是单分子质量；所有相对速度均在共同的正交基底下计算。

理论：从相互作用模型确定碰撞率核
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

前面的扫掠体积给出 :math:`dV_{\mathrm{sweep}}=\sigma(g)g\,dt`。
因此相对速率为 :math:`g` 的一对分子对应物理函数

.. math::
   :label: g03-rate-kernel

   \boxed{K(g)=\sigma(g)g},\qquad
   [\sigma]=\mathrm{m^2},\quad [g]=\mathrm{m/s},\quad
   [K]=\mathrm{m^3/s}.

乘上目标数密度后，它给出碰撞频率；对目标速度分布平均后，得到前述 :math:`\nu(\mathbf v)`。
本节要确定的是 :math:`\sigma(g)` 的具体形式。
共同给所有速度加一个漂移 :math:`\mathbf U` 保持 :math:`\mathbf g` 不变，
所以这些核也满足 Galilean 不变性。

HS：哪些结论来自硬球假设
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

HS 假设两个直径为 :math:`d` 的球在接触前没有作用，接触时瞬时弹性反射。
相对入射轨迹的碰撞参数 :math:`b` 小于两个半径之和 :math:`d` 时发生碰撞。
因此

.. math::

   \sigma_{\mathrm{HS}}
   =\int_0^d 2\pi b\,db=\pi d^2,\qquad
   \boxed{K_{\mathrm{HS}}(g)=\pi d^2g}.

这里 :math:`d` 是两个等直径分子中 **每个分子的直径**，
碰撞圆盘的半径恰好也为 :math:`d`。模拟粒子权重 :math:`W` 则决定每个样本代表的分子数，
通过配对的统计速率进入算法；分子直径由气体物性确定。

模拟粒子的位置用于确定局部碰撞单元；相互作用的几何信息则通过截面进入碰撞核。

HS 还规定了散射角与 :math:`b` 的几何关系，因而不仅是一个常截面模型。
本章“弹性散射：守恒律、角测度与 VSS”中的“从碰撞参数到角概率：HS 的几何推导”
将利用这一接触几何得到各向同性微分截面。

.. rubric:: 源码对应：HardSphereRate::kernel

``HardSphereRate`` 在构造时保存 :math:`\pi d^2`，每次 ``kernel(g)`` 返回 :math:`\pi d^2g`：

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_rate.cpp
   :language: cpp
   :start-at: HardSphereRate::HardSphereRate
   :end-before: VhsRate::VhsRate
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/fun_G03_dsmc_rate.cpp — HardSphereRate 的构造与 kernel()

``diameter`` 对应 :math:`d`，``cross_section_m2_`` 对应 :math:`\sigma`，
``q`` 是返回的 :math:`K(g)`。单元内核 ``collide_cell`` 根据当前双方速度计算 ``g``，
再通过 ``model.rate().kernel(...)`` 调用这个函数。
这样，气体物性只在构造时设置，相对速率则在每次候选时重新取得。

为什么需要随速率变化的有效截面
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

真实分子间的作用力通常随距离连续变化。
相对动能增大时，给定碰撞参数下的偏转角通常减小。
一个可说明尺度的例子是斥力势

.. math::

   U(r)=A r^{-s},\qquad A>0,\quad s>0.

等质量分子的相对动能为 :math:`E_{\mathrm{rel}}=mg^2/4`。
由 :math:`U(r_*)\sim E_{\mathrm{rel}}` 得到特征作用尺度

.. math::

   r_*=\left(\frac{A}{E_{\mathrm{rel}}}\right)^{1/s}
   \propto g^{-2/s}.

将经典二体轨道方程中的距离除以 :math:`r_*` 后，剩余轨道形状只依赖无量纲碰撞参数。
因此，在相应角积分收敛的条件下， **输运截面** 具有严格的齐次缩放

.. math::

   Q^{(l)}(g)\propto r_*^2\propto g^{-4/s}.

这一缩放为幂律模型提供了尺度依据。有效总截面与角分布仍需作为模型的一部分选定。
无限作用范围的幂律势允许任意远处的微小偏转，若把所有非零偏转都算作一次碰撞，
其总截面可发散；输运截面中的小角度权重可使相应积分收敛。
VHS 用有限的有效总截面和简化角分布，近似重现选定的输运性质。

VHS 指数为什么与黏度指数相联系
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

用 :math:`\beta` 表示截面对相对速率的衰减指数，先假设有效截面具有幂律形式，且归一化角分布不依赖速率：

.. math::

   \sigma(g)\propto g^{-\beta},\qquad
   K(g)\propto g^{1-\beta}.

用 :math:`\mu(T)` 表示动力黏度，单位为 :math:`\mathrm{Pa\,s}`。
在局部 Maxwell 分布中，所有热速度按 :math:`\sqrt{T}` 缩放。
因此线性化碰撞算子的速率尺度是
:math:`nT^{(1-\beta)/2}`。黏性应力的驱动尺度为压力 :math:`nk_BT`，
除以碰撞松弛速率便给出

.. math::

   \mu(T)\propto
   \frac{nT}{nT^{(1-\beta)/2}}
   =T^{(1+\beta)/2}.

“参数标定：为什么黏度与扩散约束不同的碰撞矩”将用无量纲化后的 Chapman--Enskog 方程严格确认这一关系。
对于这个齐次核，完整的一级 Chapman--Enskog 解与第一 Sonine 截断具有相同温度指数；
截断影响的是前面的系数。

若希望模型符合一个温区内的关系
:math:`\mu(T)=\mu_{\mathrm{ref}}(T/T_{\mathrm{ref}})^\omega`，
必须令

.. math::
   :label: g03-rate-exponents

   \beta=2\omega-1,\qquad
   \boxed{\sigma_{\mathrm{VHS}}(g)\propto g^{1-2\omega}},\qquad
   \boxed{K_{\mathrm{VHS}}(g)\propto g^{2-2\omega}}.

于是 HS 对应 :math:`\omega=1/2`，Maxwell 型速率核对应 :math:`\omega=1`。
当上述斥力势的输运积分收敛时，尺度关系给出 :math:`\omega=1/2+2/s`；
这里的 :math:`s` 是 **势能** 的幂指数，若用力的指数记号则会相差 1。

幂律与参数的选取属于建模过程。固定 :math:`\omega` 的适用性以标定温区为依据；
向其他温区或强非平衡条件推广时，需要重新评估模型与目标气体的符合程度。

Bird 参考直径为什么含 Gamma 函数
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

同种分子的约化质量为 :math:`m/2`，定义

.. math::

   g_{\mathrm{ref}}=\sqrt{\frac{4k_BT_{\mathrm{ref}}}{m}}.

本库采用 Bird 的参考直径规范，其中 :math:`\Gamma` 为 Gamma 函数：

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

.. rubric:: 源码对应：VhsRate 的三个预计算量

``VhsRate`` 的构造函数直接保存 :math:`g_{\mathrm{ref}}`、:math:`K_{\mathrm{ref}}`
和 :math:`a=2-2\omega`，使每次计算只需要一次无量纲幂运算：

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_rate.cpp
   :language: cpp
   :start-at:     g_ref_ =
   :end-at:     exponent_ =
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/fun_G03_dsmc_rate.cpp — VhsRate::VhsRate() 的参考量

``temperature`` 是输入的参考温度 :math:`T_{\mathrm{ref}}`，``mass`` 是单分子质量 :math:`m`，
``diameter`` 是 Bird 规范的 :math:`d_{\mathrm{ref}}`。
这些量在模型寿命内固定；当前粒子对的速度通过 ``kernel(g)`` 单独传入。

Gamma 因子规定参考直径的归一化方式。
对于同温、同平均流速的两个独立 Maxwell 速度样本，相对速率矩为：

.. math::

   \langle g^r\rangle_T
   =\left(\frac{4k_BT}{m}\right)^{r/2}
     \frac{\Gamma((r+3)/2)}{\Gamma(3/2)},\qquad r>-3.

把 :math:`r=2-2\omega` 代入上式，得到

.. math::
   :label: g03-rate-mean

   \langle K\rangle_T
   =\frac{\pi d_{\mathrm{ref}}^2g_{\mathrm{ref}}}{\Gamma(3/2)}
     \left(\frac{T}{T_{\mathrm{ref}}}\right)^{1-\omega}
   =\pi d_{\mathrm{ref}}^2\langle g\rangle_T
     \left(\frac{T_{\mathrm{ref}}}{T}\right)^{\omega-1/2}.

因此，在 :math:`T=T_{\mathrm{ref}}` 时，模型的平均总碰撞核
等于直径为 :math:`d_{\mathrm{ref}}` 的 HS 平均核。
在参考相对速率处则有 :math:`\sigma(g_{\mathrm{ref}})=\pi d_{\mathrm{ref}}^2/\Gamma(5/2-\omega)`。
采用其他直径归一化约定时，应同步换算直径与黏度标定公式。

数值求值：从幂律到 kernel(g)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_rate.cpp
   :language: cpp
   :start-at: Real VhsRate::kernel
   :end-before: } // namespace algoplasma::dsmc
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/fun_G03_dsmc_rate.cpp — VhsRate::kernel()

这里 ``exponent_`` 对应 :math:`a`，``kernel_ref_`` 对应 :math:`K_{\mathrm{ref}}`。
两个提前返回分别实现常核与零相对速率分支；最后的 ``q`` 就是上面 Bird 规范的幂律。
所有分支统一返回 :math:`\mathrm{m^3/s}`，调用方随后使用它计算候选接受概率。

因为本范围内 :math:`K(g)` 单调不减，给出可靠的相对速率上界
:math:`g_{\max}` 后，可令

.. math::

   K_{\max}=K(g_{\max}),\qquad
   K(g)\le K_{\max}\quad(0\le g\le g_{\max}).

``majorant(g_max)`` 承诺的是整个区间上的上界。
调用方仍须保证碰撞过程中所有实际相对速率落在该区间。
:math:`\omega>1` 会产生零速率处发散的核，需要另行设计上界策略与对应算法。

源码：一个速率接口对应一个数学对象
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

公开接口位于 ``G_Collision/G03_DSMC/rate.hpp``；
``HardSphereRate`` 与 ``VhsRate`` 分别实现上述两个核。
速率模块不读取参数文件，也不关心单元形状、模拟粒子权重和随机数。

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/rate.hpp
   :language: cpp
   :start-at: class PairRateModel
   :end-before: class HardSphereRate
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/rate.hpp — PairRateModel 的调用接口

``DsmcModel`` 的构造函数根据模型类型选择 ``HardSphereRate`` 或 ``VhsRate``。
前者用于 HS，后者同时供 VHS 和 VSS 使用；VHS 与 VSS 的区别由散射对象承担。
``collide_cell`` 通过 ``PairRateModel`` 读取核及区间上界；
增加其他速率规律时，需要同时扩展速率实现与 ``DsmcModel`` 的构造分支。
若希望 VHS 与 VSS 具有相同参考黏度，应根据各自角分布分别标定参考直径。

.. rubric:: 阅读来源

Bird, *Molecular Gas Dynamics and the Direct Simulation of Gas Flows* (1994) 的分子模型部分；
Chapman 与 Cowling, *The Mathematical Theory of Non-Uniform Gases*, 第三版 (1970) 的
碰撞积分与逆幂势分析。有关“真实势、有效截面与输运拟合”的区别，应将本节与
后续的散射与参数标定两节连续阅读。

本模块的检查方法与判据见 :ref:`测试说明 <g03-validation-rate>`。
