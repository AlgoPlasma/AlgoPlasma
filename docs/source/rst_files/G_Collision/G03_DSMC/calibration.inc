.. _g03-calibration:

参数标定：为什么黏度与扩散约束不同的碰撞矩
------------------------------------------------------------------------

前述碰撞核与散射模型已经给出速率依赖和角分布。
本节将两者接到宏观输运量，回答三个问题：

* 为什么 VHS 的指数由黏度温度指数决定？
* 为什么只有黏度不足以确定 VSS 的角参数？
* 给定参考黏度和自扩散信息后，怎样得到自洽的参考直径？

推导对象为稀薄、单组分、中性、单原子、弹性气体。
自扩散指给少量同种分子加上不影响动力学的标签后，标签浓度的扩散。
混合气体的互扩散需要另行建立物种碰撞算子。

理论：先区分三个层次
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

从流场梯度到线性化碰撞算子
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

用 :math:`\mathbf c=\mathbf v-\mathbf u` 表示热运动速度，
以 :math:`s^2` 表示平衡态下每个速度分量的方差，定义归一化 Maxwell 分布

.. math::

   s^2=\frac{k_BT}{m},\qquad
   \mathcal M(\mathbf c)=\frac{1}{(2\pi s^2)^{3/2}}
                \exp\left(-\frac{c^2}{2s^2}\right),\qquad
   \int \mathcal M\,d^3c=1.

记局部平衡分布 :math:`f^{(0)}=n\mathcal M`。在其附近写成 :math:`f=f^{(0)}(1+\phi)`，其中
:math:`|\phi|\ll1`；扰动的质量、三分量动量和能量矩均为零，
使 :math:`n,\mathbf u,T` 仍由局部平衡部分确定。
对 Boltzmann 碰撞项保留 :math:`\phi` 的一次项，得到算子

.. math::
   :label: g03-cal-linear-operator

   Lh(\mathbf c_1)
   =n\int \mathcal M(\mathbf c_2)\,g
      \int\left(h_1'+h_2'-h_1-h_2\right)d\sigma\,d^3c_2.

这里 :math:`h_i=h(\mathbf c_i)`、:math:`h_i'=h(\mathbf c_i')`；撇号表示碰后值，
:math:`\mathbf g=\mathbf c_1-\mathbf c_2`、:math:`g=|\mathbf g|`。
微分截面 :math:`d\sigma=(d\sigma/d\Omega)d\Omega`
由前述碰撞核与角分布共同确定。在 Maxwell 加权内积下，:math:`L` 是非正算子，
表示碰撞衰减非守恒扰动。

考察温度、数密度局部均匀的弱平面剪切
:math:`\mathbf u=(u_x(y),0,0)`，记 :math:`G=\partial u_x/\partial y`。
此时 :math:`v_y=c_y`，局部 Maxwell 分布的流动梯度产生

.. math::

   \frac{1}{f^{(0)}}\mathbf v\cdot\nabla f^{(0)}
   =\frac{G}{s^2}c_xc_y.

因此求黏度的线性方程是

.. math::

   L\phi=\frac{G}{s^2}S,\qquad S(\mathbf c)=c_xc_y.

其因果关系是：相邻流层具有不同平均速度，分子的热运动携带这些差异，
产生 :math:`c_xc_y` 型的速度各向异性；碰撞再衰减该各向异性。
黏度给出这一响应形成的动量通量与速度梯度之间的比例。

剪切模态的投影为什么产生五次速率矩
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

定义 Maxwell 平均 :math:`\langle F\rangle=\int \mathcal M F\,d^3c`，
以及内积 :math:`\langle a,b\rangle=\langle ab\rangle`。
第一 Sonine 近似对剪切扰动采用

.. math::

   \phi\simeq-a_\eta GS.

将线性方程乘以 :math:`S` 并积分，令
:math:`B_2=-\langle S,LS\rangle`，利用
:math:`\langle S^2\rangle=s^4`，得到

.. math::

   a_\eta B_2=s^2,\qquad
   \mathsf P_{xy}=mn\langle S\phi\rangle
         =-mn a_\eta s^4G=-\mu_1G,

.. math::
   :label: g03-cal-mu-bracket

   \boxed{\mu_1=\frac{mn s^6}{B_2}}.

这里 :math:`\mathsf P_{xy}` 是分子输运产生的非对角动量通量；连续介质中的黏性应力为
:math:`\tau_{xy}=-\mathsf P_{xy}=\mu_1G`。

记 :math:`\mathcal M_i=\mathcal M(\mathbf c_i)`，
:math:`\Delta(S_1+S_2)=S_1'+S_2'-S_1-S_2`。
利用弹性碰撞的微观可逆性与
:math:`\mathcal M_1'\mathcal M_2'=\mathcal M_1\mathcal M_2`，碰撞括号可对称化为

.. math::

   B_2=\frac n4\int \mathcal M_1\mathcal M_2\,g
       \int\left[\Delta(S_1+S_2)\right]^2d\sigma\,
       d^3c_1d^3c_2.

把两分子的热速度改写为质心与相对速度，质心在碰撞中保持不变，于是

.. math::

   \Delta(S_1+S_2)
   =\frac12(g_x'g_y'-g_xg_y).

对于固定相对速率 :math:`g` 和偏转角 :math:`\chi`，
横线表示对均匀入射方向与散射方位的平均。各向同性四阶方向矩给出

.. math::

   \overline{g_x^2g_y^2}=\frac{g^4}{15},\qquad
   \overline{g_xg_y g_x'g_y'}=\frac{g^4}{30}(3\cos^2\chi-1).

碰前、碰后的平方项具有相同平均，展开差的平方便得到

.. math::

   \overline{\left[\Delta(S_1+S_2)\right]^2}
   =\frac14\left[\frac{2g^4}{15}
     -\frac{g^4}{15}(3\cos^2\chi-1)\right]
   =\frac{g^4}{20}(1-\cos^2\chi).

其中 :math:`g^4` 来自二阶速度模态的平方，
:math:`1-\cos^2\chi` 来自二阶方向模态。
再乘碰撞通量中的一个 :math:`g`，便得到

.. math::
   :label: g03-cal-b2

   \boxed{B_2=\frac n{80}
     \left\langle g^5Q^{(2)}(g)\right\rangle_{\mathrm{rel}}},\qquad
   Q^{(2)}=\int(1-\cos^2\chi)\,d\sigma.

下标 :math:`\mathrm{rel}` 表示两独立 Maxwell 速度之差的平均；
其相对速率密度将在后文给出。代回黏度表达式，得到

.. math::
   :label: g03-cal-mu-moment

   \boxed{\mu_1(T)=
   \frac{80(k_BT)^3}
        {m^2\left\langle g^5Q^{(2)}(g)\right\rangle_{\mathrm{rel}}}}.

黏度由这一角权重与速度权重共同决定；
即使 :math:`\langle \sigma g\rangle` 相同，模型的黏度仍可能不同。

标签自扩散为什么使用另一个算子
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

设极少量标签分子的数密度为 :math:`n_A(\mathbf x)`，
背景是相同质量、相同碰撞性质的未标记分子，数密度近似为 :math:`n`。
在恒定温度、无整体流动下，浓度梯度产生标签粒子数通量

.. math::

   \mathbf j_A=-D_1\nabla n_A.

标签不会改变碰撞轨道，但我们只追踪标签分子的速度。
其线性算子为

.. math::

   L_Dh(\mathbf c_1)
   =n\int \mathcal M_2\,g\int(h_1'-h_1)\,d\sigma\,d^3c_2.

背景分布保持 Maxwell 形式，因此这里只保留标签分子的 :math:`h_1'-h_1`。
标签分子的动量可转移给背景，使 :math:`L_D` 衰减 :math:`c_x` 模态；
相应地，完整单组分算子 :math:`L` 的 :math:`c_x` 模态由总动量守恒而保持不变。

写标签分布为 :math:`f_A=n_A\mathcal M(1+\phi_A)`，取 :math:`H=\partial_x\ln n_A`。
第一 Sonine 近似为 :math:`\phi_A=-a_D Hc_x`。
投影方程 :math:`L_D\phi_A=Hc_x` 给出

.. math::

   B_1=-\langle c_x,L_Dc_x\rangle,\qquad a_DB_1=s^2.

对应的粒子数通量为
:math:`j_{Ax}=n_A\langle c_x\phi_A\rangle=-a_Ds^2\partial_x n_A`，
与 Fick 定律比较即得 :math:`D_1=a_Ds^2=s^4/B_1`。
标签碰撞括号是

.. math::

   B_1=\frac n2\int \mathcal M_1\mathcal M_2\,g
       \int(c_{1x}'-c_{1x})^2d\sigma\,d^3c_1d^3c_2.

因为 :math:`\mathbf c_1'-\mathbf c_1=(\mathbf g'-\mathbf g)/2`，
而 :math:`|\mathbf g'-\mathbf g|^2=2g^2(1-\cos\chi)`，
方向平均后有

.. math::

   \overline{(c_{1x}'-c_{1x})^2}
   =\frac{g^2}{6}(1-\cos\chi).

因此

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

扩散使用三次速率矩和 :math:`1-\cos\chi`，
黏度使用五次速率矩和 :math:`1-\cos^2\chi`；二者测量的是不同碰撞矩。

相对速率分布与 Gamma 积分
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

两独立 Maxwell 速度相减后，每个相对速度分量的方差是 :math:`2s^2`。
相对速率的概率密度为

.. math::

   p_{\mathrm{rel}}(g)=
   \frac{g^2}{2\sqrt{\pi}s^3}
   \exp\left(-\frac{g^2}{4s^2}\right),\qquad g\ge0.

对任意函数 :math:`F(g)`，记
:math:`\langle F\rangle_{\mathrm{rel}}=\int_0^\infty F(g)p_{\mathrm{rel}}(g)\,dg`。
取 :math:`F=g^r`，以 :math:`x=g^2/(4s^2)` 换元可得（:math:`r>-3`）

.. math::
   :label: g03-cal-speed-moment

   \langle g^r\rangle_{\mathrm{rel}}
   =\frac{1}{2\sqrt{\pi}s^3}
      \int_0^\infty g^{r+2}e^{-g^2/(4s^2)}\,dg
   =(2s)^r\frac{\Gamma((r+3)/2)}{\Gamma(3/2)}.

概率密度中的 :math:`g^2` 来自三维速度空间的体积测度。
把期望展开为一维积分后，黏度分母的幂次为 :math:`g^7Q^{(2)}`，
扩散分母的幂次为 :math:`g^5Q^{(1)}`；这已包含该体积因子。

代入 VHS / VSS 并求出全部系数
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

将前文碰撞核的 Bird 规范改写为

.. math::

   \sigma(g)=C_\sigma g^{1-2\omega},\qquad
   C_\sigma=
   \frac{\pi d_{\mathrm{ref}}^2g_{\mathrm{ref}}^{2\omega-1}}
        {\Gamma(5/2-\omega)}.

由前文的散射角矩，

.. math::

   Q^{(1)}=A_1C_\sigma g^{1-2\omega},\qquad
   A_1=\frac2{\alpha+1},

.. math::

   Q^{(2)}=A_2C_\sigma g^{1-2\omega},\qquad
   A_2=\frac{4\alpha}{(\alpha+1)(\alpha+2)}.

于是两个碰撞矩分别是

.. math::

   \left\langle g^3Q^{(1)}\right\rangle
   =A_1C_\sigma(2s)^{4-2\omega}
      \frac{\Gamma(7/2-\omega)}{\Gamma(3/2)},

.. math::

   \left\langle g^5Q^{(2)}\right\rangle
   =A_2C_\sigma(2s)^{6-2\omega}
      \frac{\Gamma(9/2-\omega)}{\Gamma(3/2)}.

在参考温度使用 :math:`g_{\mathrm{ref}}=2s_{\mathrm{ref}}`，
再用 Gamma 递推
:math:`\Gamma(x+2)=x(x+1)\Gamma(x)`，
黏度分母中的 Gamma 比化成

.. math::

   \frac{\Gamma(9/2-\omega)}{\Gamma(5/2-\omega)}
   =\frac{(5-2\omega)(7-2\omega)}4.

最终得到

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

扩散同理得到

.. math::
   :label: g03-cal-d-reference

   \boxed{D_1(T,n)=
   \frac{3(\alpha+1)}
        {4(5-2\omega)n d_{\mathrm{ref}}^2}
   \sqrt{\frac{k_BT_{\mathrm{ref}}}{\pi m}}
   \left(\frac{T}{T_{\mathrm{ref}}}\right)^\omega}.

在 :math:`\omega=1/2,\alpha=1` 的 HS 极限，

.. math::

   \mu_{1,\mathrm{HS}}=\frac{5}{16d^2}
      \sqrt{\frac{mk_BT}{\pi}},\qquad
   D_{1,\mathrm{HS}}=\frac{3}{8nd^2}
      \sqrt{\frac{k_BT}{\pi m}}.

两式恢复标准的 HS 第一 Sonine 系数，同时核对了角分布归一化和同种分子的约化质量 :math:`m/2`。

.. rubric:: 源码对应：reference_viscosity 的公共系数

定义 :math:`C_\mu=\mu_{1,\mathrm{ref}}d_{\mathrm{ref}}^2`。
源码先用内部函数 ``viscosity_scale`` 计算这一公共系数，再除以直径平方：

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_calibration.cpp
   :language: cpp
   :start-at: Real viscosity_scale
   :end-before: } // namespace
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/fun_G03_dsmc_calibration.cpp — viscosity_scale()

``mass``、``temperature``、``omega``、``alpha`` 分别对应
:math:`m,T_{\mathrm{ref}},\omega,\alpha`。
局部变量 ``calibration`` 就是上面黏度公式中除 :math:`d_{\mathrm{ref}}^{-2}` 之外的完整系数，
单位为 :math:`\mathrm{Pa\,s\,m^2}`。
函数同时检查 :math:`m,T_{\mathrm{ref}}>0`、:math:`1/2\le\omega\le1` 与 :math:`\alpha\ge1`。

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_calibration.cpp
   :language: cpp
   :start-at: Real reference_viscosity
   :end-before: Real reference_diameter
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/fun_G03_dsmc_calibration.cpp — reference_viscosity()

``diameter`` 对应 :math:`d_{\mathrm{ref}}`，返回的 ``viscosity`` 对应 :math:`\mu_{1,\mathrm{ref}}`。
``DsmcModel`` 的构造函数调用它计算模型属性中的参考黏度；
每次碰撞直接使用已构造的速率核与角分布。

为什么温度幂指数不依赖 Sonine 截断
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

上面的第一 Sonine 计算给出了闭式系数，但幂律指数还有更一般的来源。
对固定 :math:`\alpha,\omega` 的齐次核，令
:math:`\mathbf c=s\boldsymbol\xi`，则完整的线性算子可写为

.. math::

   L=nC_\sigma s^{2-2\omega}\widehat L,

其中 :math:`\widehat L` 的速度变量无量纲，且不再依赖
:math:`n,T`；它只依赖角模型与幂指数。
剪切方程的右端为 :math:`G\xi_x\xi_y`，因此其解的尺度为

.. math::

   \phi\sim
   \frac{G}{nC_\sigma s^{2-2\omega}}
   \widehat L^{-1}(\xi_x\xi_y).

将它代入动量通量
:math:`\mathsf P_{xy}=mn s^2\langle\xi_x\xi_y\phi\rangle`，便得到

.. math::

   \mu\propto\frac{m}{C_\sigma}s^{2\omega}
   \propto T^\omega.

这里的逆算子在排除守恒零模的输运子空间上理解。
增加 Sonine 项会改进这个无量纲逆算子的表示，从而改变系数；
只要核保持相同齐次性，温度指数不变。
标签扩散的同样缩放给出 :math:`D\propto T^\omega/n`。
这一区分说明了哪些结果来自模型的尺度结构，哪些数值常数来自具体投影近似。

动力黏度为什么不显含密度，运动黏度却显含
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

在剪切投影中，压力矩的幅度正比于 :math:`n`，
碰撞松弛频率也正比于 :math:`n`；二者抵消，使
:math:`\mu_1` 在稀薄二体碰撞模型下不显含密度。
它仍依赖分子质量与碰撞模型参数，因此不同气体不具有同一个 :math:`\mu(T)`。

运动黏度与动力黏度必须区分：

.. math::

   \boxed{\nu_{\mathrm{kin}}=\frac{\mu}{\rho}},\qquad
   \rho=mn,\qquad
   [\mu]=\mathrm{Pa\,s},\quad
   [\nu_{\mathrm{kin}}]=[D]=\mathrm{m^2/s}.

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

Schmidt 数怎样确定角参数
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

将两个输运系数相除，截面幅度、数密度和温度全部抵消：

.. math::
   :label: g03-cal-schmidt

   \boxed{\mathrm{Sc}_1
   =\frac{\mu_1}{mnD_1}
   =\frac{5(\alpha+2)}{3\alpha(7-2\omega)}}.

因此，黏度温度变化首先确定 :math:`\omega`；
独立的自扩散信息通过 :math:`\mathrm{Sc}` 约束 :math:`\alpha`；
最后才由黏度幅度确定 :math:`d_{\mathrm{ref}}`。
VHS 固定 :math:`\alpha=1`，只能预测
:math:`\mathrm{Sc}_1=5/(7-2\omega)`，没有额外自由度调整这个比值。

在本库 :math:`\alpha\ge1` 的范围内，可反解

.. math::
   :label: g03-cal-alpha

   \boxed{\alpha=
   \frac{10}{3\mathrm{Sc}_1(7-2\omega)-5}}.

有限的允许参数须满足

.. math::

   \frac{5}{3(7-2\omega)}
   \lt \mathrm{Sc}_1
   \le \frac{5}{7-2\omega}.

下界只能在 :math:`\alpha\to\infty` 时逼近。
目标数据超出区间时，应核查数据类型、单位、温区与近似，必要时更换模型。
固定 :math:`\omega,\alpha` 给出恒定的 :math:`\mathrm{Sc}_1`，
其标定温区应选择在目标比值变化足够小的范围内。

上述反解使用同种分子的标签自扩散；异种二元扩散与多组分输运需采用相应的质量与耦合关系。

标定步骤：按什么顺序确定参数
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

.. math::
   :label: g03-cal-diameter

   \boxed{d_{\mathrm{ref}}=
   \left[
   \frac{5(\alpha+1)(\alpha+2)}
        {4\alpha(5-2\omega)(7-2\omega)\mu_{1,\mathrm{ref}}}
   \sqrt{\frac{mk_BT_{\mathrm{ref}}}{\pi}}
   \right]^{1/2}}.

.. rubric:: 源码对应：reference_diameter 反解直径

同一个 ``viscosity_scale`` 提供 :math:`C_\mu`，反解只需计算
:math:`d_{\mathrm{ref}}=\sqrt{C_\mu/\mu_{1,\mathrm{ref}}}`：

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_calibration.cpp
   :language: cpp
   :start-at: Real reference_diameter
   :end-before: } // namespace algoplasma::dsmc
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/fun_G03_dsmc_calibration.cpp — reference_diameter()

输入 ``viscosity`` 对应目标 :math:`\mu_{1,\mathrm{ref}}`，返回 ``diameter`` 的单位是米。
正算和反算共用同一系数，保证它们使用相同的 Bird 规范与第一 Sonine 约定。
调用方得到直径后，将其放入 ``ElasticModelParameters::diameter_ref_m``，
模型构造函数再把它传给 ``HardSphereRate`` 或 ``VhsRate``。

改变 :math:`\alpha` 会改变 :math:`Q^{(2)}`，因此通常也会改变黏度。
若想保持同一个 :math:`\mu_{\mathrm{ref}}`，应在更换角分布后重新计算参考直径。

温度用于输运标定；运行时则由每对粒子的相对速率 :math:`g` 直接计算碰撞核。

一个可复算的数值例
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

取教学参数

.. math::

   m=6.6335209\times10^{-26}\ \mathrm{kg},\quad
   T_{\mathrm{ref}}=300\ \mathrm K,\quad
   \mu_{1,\mathrm{ref}}=2.23\times10^{-5}\ \mathrm{Pa\,s},

.. math::

   \omega=0.81,\qquad \alpha=1.4,\qquad
   n_{\mathrm{ref}}=10^{23}\ \mathrm{m^{-3}}.

这组教学数据采用氩原子量级的质量。代入公式得到

.. math::

   d_{\mathrm{ref}}=4.09905589\times10^{-10}\ \mathrm m,\qquad
   \mathrm{Sc}_1=0.75234555,

.. math::

   D_{1,\mathrm{ref}}=4.46831113\times10^{-3}\ \mathrm{m^2/s},\qquad
   \nu_{\mathrm{kin},1,\mathrm{ref}}
   =3.36171399\times10^{-3}\ \mathrm{m^2/s}.

将这个 :math:`\mathrm{Sc}_1` 代回式 :eq:`g03-cal-alpha`，
应恢复 :math:`\alpha=1.4`。
若同样的参考黏度改用 VHS，即 :math:`\alpha=1`，
需要 :math:`d_{\mathrm{ref}}=4.15889929\times10^{-10}\ \mathrm m`。

在保持数密度不变、温度升至 :math:`600\ \mathrm K` 时，

.. math::

   \mu_1=3.90966152\times10^{-5}\ \mathrm{Pa\,s},\qquad
   D_1=7.83389421\times10^{-3}\ \mathrm{m^2/s}.

若改为保持压力不变，数密度还会减半；
此时 :math:`D_1` 是上述数值的两倍，而 :math:`\mu_1` 不变。
这说明讨论“输运系数随温度变化”时必须同时说明保持什么条件不变。

源码职责：参数标定与运行时碰撞的交接
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``calibration.hpp`` 声明上述正反两个公共函数，
``fun_G03_dsmc_calibration.cpp`` 实现共同的物理系数和参数检查。
黏度数据拟合、由自扩散确定角参数以及适用温区的选择，由调用方依据数据完成。

运行时使用的 ``VhsRate`` 保存由这些参数确定的核，``VssScattering`` 保存角参数的倒数。
碰撞内核给定相对速度后，即可得到 :math:`K(g)` 和 :math:`\mathbf g'`。
输入文件、命令行参数和初始粒子生成属于算例的组织方式；Tests 集中说明这些调用层内容。

.. rubric:: 阅读来源

Chapman 与 Cowling, *The Mathematical Theory of Non-Uniform Gases*, 第三版 (1970)，
提供 Chapman--Enskog、Sonine 展开与碰撞括号的系统推导；
Bird, *Molecular Gas Dynamics and the Direct Simulation of Gas Flows* (1994)，
给出 DSMC 分子模型与参考参数约定；
Koura 与 Matsumoto (1991) 的 VSS 原始论文说明利用角分布匹配输运性质的模型构造。

本模块的检查方法与判据见 :ref:`测试说明 <g03-validation-calibration>`。
