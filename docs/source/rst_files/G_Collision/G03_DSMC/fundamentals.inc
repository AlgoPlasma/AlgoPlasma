.. _g03-physical-foundations:

物理基础：分布、守恒与碰撞尺度
------------------------------------------------------------------------

DSMC 用位置与速度样本表示气体的分布，再通过粒子运动和随机二体碰撞推进这个分布。
本节先明确分布函数、宏观量、二体守恒和碰撞尺度，再用 Boltzmann 方程概括气体的演化。
随后三节分别给出碰撞率核、角分布和参数标定，并在公式旁展示实现这些物理关系的函数。
在这些模型确定之后，“单元碰撞：NTC 与连续时钟”由碰撞算子推导有限样本的事件率与候选调度。

.. _g03-notation:

.. rubric:: 本节符号与单位

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
   * - :math:`f,\phi_v=f/n,F(c)`
     - 数分布函数、速度概率密度、热速率概率密度，:math:`c=|\mathbf c|`
     - :math:`\mathrm{s^3/m^6,s^3/m^3,s/m}`
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

.. _g03-box-experiment:

一、DSMC 的粒子样本表示什么
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

气体的单分子统计状态用数分布函数 :math:`f(\mathbf x,\mathbf v,t)` 描述：
:math:`f\,d^3x\,d^3v` 是位置区间 :math:`d^3x`、速度区间 :math:`d^3v` 内的期望分子数。
输运改变分子所处的位置，外力与碰撞改变速度；这些变化共同决定 :math:`f` 的演化。

DSMC 以一组带统计权重的位置、速度样本近似这个连续分布。
一个等权重模拟粒子代表 :math:`W` 个真实分子，因此包含 :math:`N` 个样本的单元代表 :math:`NW` 个分子。
对体积为 :math:`V_{\mathrm{cell}}` 的单元，将分布在空间上平均后，其速度分布的样本表示为

.. math::
   :label: g03-eq-empirical-distribution

   f_N(\mathbf v)=\frac{W}{V_{\mathrm{cell}}}
   \sum_{i=1}^{N}\delta^{(3)}(\mathbf v-\mathbf v_i).

:math:`\delta^{(3)}` 是三维 Dirac 分布：对任何速度函数 :math:`\psi`，
:math:`\int\psi(\mathbf v)\delta^{(3)}(\mathbf v-\mathbf v_i)\,d^3v=\psi(\mathbf v_i)`。
于是连续分布的积分可以由样本求和计算；这是宏观量采样和碰撞抽样共用的表示。
实际程序保存 :math:`\mathbf x_i,\mathbf v_i,W`，空间分组给出局部的 :math:`f_N`。

.. rubric:: 源码对应：位置、速度与粒子标识的基本类型

粒子样本中的位置和速度是三维向量，代码用 ``Vec3`` 保存三个分量，
用 ``Real`` 保存分量、质量和时间等数值，用粒子 ID 标识同一个样本。
``common.hpp`` 定义这些基础类型和 Boltzmann 常数，物理量统一采用 SI 单位。

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/common.hpp
   :language: cpp
   :start-at: using Real
   :end-before: inline Vec3 operator+
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/common.hpp — 样本数据使用的基础类型

本章采用经典稀薄气体的二体弹性碰撞模型，其物理前提是：

* 分子间距远大于相互作用尺度。硬球气体可用 :math:`nd^3\ll1` 衡量稀薄性。
* 碰撞持续时间远小于相邻碰撞的平均间隔，因而可分别处理自由运动和局部瞬时碰撞。
* 即将相遇的两分子，其碰前速度联合分布用两个单分子分布的乘积近似。这是 **分子混沌假设**，也是单元内随机配对的依据。

这些假设把多体演化简化为单分子分布与二体碰撞；碰撞模型进一步提供发生速率和末态规律。
当前主库处理单组分、等权重的弹性碰撞，下面先在这一范围内建立完整对应关系。

.. _g03-s02:

二、从分布与样本得到宏观量
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

有了 :math:`f`，数密度就是速度空间的总数，平均流速就是分子的速度平均。
扣除平均流动以后，每个分子的平均平动能定义平动温度：

.. math::
   :label: g03-eq-moments

   n=\int f\,d^3v,\qquad
   \mathbf u=\frac1n\int\mathbf v f\,d^3v,\qquad
   \frac32k_BT_{\mathrm{tr}}=\frac{m}{2n}\int|\mathbf v-\mathbf u|^2f\,d^3v.

将上面的样本分布 :math:`f_N` 代入，对 :math:`N>0` 的单元立即得到采样公式：

.. math::
   :label: g03-eq-sample-moments

   n_N=\frac{NW}{V_{\mathrm{cell}}},\qquad
   \mathbf u_N=\frac1N\sum_i\mathbf v_i,\qquad
   T_N=\frac{m}{3k_BN}\sum_i|\mathbf v_i-\mathbf u_N|^2.

这说明权重用于把样本数量换成物理数量，而流速与温度来自样本分布的形状。
上述温度是样本中心二阶矩对应的平动温度；本章单原子气体简记 :math:`T=T_{\mathrm{tr}}`。
即使局部速度分布远离平衡，这个定义仍然成立。

方向动量通量和热流还需要更高的速度信息：

.. math::
   :label: g03-eq-moment-closure

   \mathbf c=\mathbf v-\mathbf u,\qquad
   \mathsf P=m\int\mathbf c\mathbf c\,f\,d^3v,\qquad
   \mathbf q=\frac m2\int c^2\mathbf c\,f\,d^3v.

:math:`\mathbf c\mathbf c` 是外积，例如其 :math:`xy` 分量为 :math:`c_xc_y`；
:math:`\mathsf I` 表示三维单位张量，:math:`\mathrm{tr}` 表示张量的迹。
:math:`\mathsf P` 的对角元记录各方向的动量通量，非对角元记录方向之间的动量输运；
:math:`\mathbf q` 记录相对于平均流动的能量输运。
标量动理学压力 :math:`p=\mathrm{tr}(\mathsf P)/3=nk_BT` 是三个法向动量通量的平均值。
DSMC 推进完整的速度样本，因此这些量都能按同一个积分转求和的规则统计。

局部平衡态的分布为

.. math::
   :label: g03-eq-maxwell

   f_{\mathrm{eq}}(\mathbf v)=n\left(\frac{m}{2\pi k_BT}\right)^{3/2}
   \exp\!\left[-\frac{m|\mathbf v-\mathbf u|^2}{2k_BT}\right].

此时三个热速度分量各为均值 0、方差 :math:`k_BT/m` 的独立高斯量，
:math:`\mathsf P=nk_BT\mathsf I`、:math:`\mathbf q=0`。
Maxwell 分布可以提供平衡初值和速度尺度；进入时间推进以后，局部分布由当前样本及其碰撞历史决定。

.. raw:: html

   <details class="g03-supplement"><summary>补充：平衡态的速率分布与三个特征速率</summary>

对热速度空间半径为 :math:`c`、厚度为 :math:`dc` 的球壳积分，体积因子为 :math:`4\pi c^2dc`，故

.. math::
   :label: g03-eq-speed-pdf

   F(c)\,dc=\frac{f_{\mathrm{eq}}(c)}n4\pi c^2dc,\qquad
   F(c)=\frac4{\sqrt\pi}\frac{c^2}{c_{\mathrm{mp}}^3}e^{-c^2/c_{\mathrm{mp}}^2},\qquad
   c_{\mathrm{mp}}=\sqrt{\frac{2k_BT}{m}}.

这里 :math:`f_{\mathrm{eq}}(c)` 在热速度坐标中取值，:math:`F` 在正半轴积分为 1。
最概然速率 :math:`c_{\mathrm{mp}}` 是峰位置；平均速率 :math:`\bar c=\sqrt{8k_BT/(\pi m)}`
用于平均路程；均方根速率 :math:`c_{\mathrm{rms}}=\sqrt{3k_BT/m}` 对应平均热运动动能。

.. figure:: /_static/G_Collision/G03_DSMC/maxwell.svg
   :alt: Maxwell 速率分布中最概然、平均和均方根速率的位置
   :width: 700px

   球壳因子使零速率处的概率密度为零，指数项限制高速尾部。

.. raw:: html

   </details>

.. _g03-binary-physics:

三、二体碰撞的守恒与末态
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

相对运动与质心运动
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

二体末态由总动量、总能量和散射方向共同确定。先把运动分解为整对分子的平移与分子之间的相对运动：

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

相同的整体漂移只改变质心运动，分子之间的接近过程由 :math:`\mathbf g` 描述。
孤立二体弹性碰撞保持总动量与总动能，等价于保持 :math:`\mathbf V_{\mathrm{cm}}` 和 :math:`g`，并改变相对速度的方向。
因此弹性模型还需给定碰后方向 :math:`\widehat{\mathbf g}'`。
令 :math:`\mathbf g'=g\widehat{\mathbf g}'`，还原两个分子的速度：

.. math::
   :label: g03-eq-fund-outgoing

   \mathbf v_1'=\mathbf V_{\mathrm{cm}}+\frac{m_2}{m_1+m_2}\mathbf g',\qquad
   \mathbf v_2'=\mathbf V_{\mathrm{cm}}-\frac{m_1}{m_1+m_2}\mathbf g'.

当前单组分库中 :math:`m_1=m_2=m`，两个系数都为 :math:`1/2`。
同时更新这两个速度，就把单次碰撞的动量和能量守恒落实到了样本上。

总截面与角分布提供两类碰撞信息
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

硬球模型假设分子在接触前自由运动，接触时发生瞬时弹性反射。
碰撞参数 :math:`b` 是未偏转的相对入射轨迹到目标球心的最短距离。
两个直径均为 :math:`d` 的球在 :math:`b\lt d` 时接触，允许轨迹的面积为

.. math::
   :label: g03-eq-cross-section

   \sigma=\pi d^2,\qquad
   \sigma_{12}=\pi\left(\frac{d_1+d_2}{2}\right)^2.

这里 :math:`d` 是分子在硬球相互作用模型中的有效直径，用于定义截面。
统计权重 :math:`W` 决定样本代表的分子数；两者分别进入分子碰撞核与模拟粒子配对率。

.. figure:: /_static/G_Collision/G03_DSMC/collision-geometry.svg
   :alt: 两个直径为 d 的硬球，允许碰撞的相对轨迹区域半径为 d
   :width: 700px

   截面圆盘的半径等于两分子半径之和。图中虚线圆的半径为 d。

总截面累加所有允许轨迹的面积，决定碰撞发生率。
对于已经选中的碰撞，末态方向由微分截面给出：

.. math::
   :label: g03-eq-fund-angular-law

   \sigma(g)=\int_{S^2}\frac{d\sigma}{d\Omega}(g,\Omega)\,d\Omega,
   \qquad
   p_\Omega(\Omega\mid g)=\frac1{\sigma(g)}\frac{d\sigma}{d\Omega}(g,\Omega).

:math:`S^2` 是单位球面；:math:`\Omega=(\chi,\varphi)` 是以入射方向 :math:`\mathbf g/g` 为极轴的角坐标，
:math:`d\Omega=\sin\chi\,d\chi\,d\varphi` 是立体角元。
偏转角 :math:`\chi` 从极轴量起，方位角 :math:`\varphi` 绕极轴测量。
条件概率密度 :math:`p_\Omega` 对整个球面积分为 1，因而可以直接用于抽取碰后方向。

HS 的接触几何给出各向同性角分布 :math:`p_\Omega=1/(4\pi)`。
“弹性散射：守恒律、角测度与 VSS”将从碰撞参数推导这一结果，再引入 VSS 的角分布。
总截面与角分布分别规定碰撞发生率与碰后方向。

.. _g03-s03:

四、从碰撞率得到时间与空间尺度
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

先看一组速度相同、数密度为 :math:`n` 的目标分子。
测试分子相对它们以速率 :math:`g` 运动，在 :math:`dt` 内扫过体积 :math:`\sigma(g)gdt`，
平均遇到 :math:`n\sigma(g)gdt` 个目标。
由此定义碰撞率核 :math:`K(g)=\sigma(g)g`；它的单位是体积/时间，乘数密度得到碰撞频率。

实际目标有不同速度。令 :math:`\mathbf w` 为目标速度，
:math:`\phi_v(\mathbf w)=f(\mathbf w)/n` 为归一化速度概率密度，分别计算各速度群的贡献并积分：

.. math::
   :label: g03-eq-frequency

   \nu(\mathbf v)=n\int K(|\mathbf v-\mathbf w|)\phi_v(\mathbf w)\,d^3w,\qquad
   \bar\nu=\int\phi_v(\mathbf v)\nu(\mathbf v)\,d^3v.

碰撞更新速度，也就更新后续的相对速率与碰撞频率。
在单组分气体中，单位体积内的碰撞事件率为

.. math::
   :label: g03-eq-event-density

   \mathcal R=\frac12n\bar\nu
   =\frac12n^2\langle K\rangle.

一次二体碰撞涉及两个分子，系数 :math:`1/2` 将碰撞参与次数换成事件数。
:math:`\langle K\rangle` 对两个独立入射速度样本取平均。
给定速度分布和碰撞模型后，事件率随局部数密度的平方增长。

若一段飞行中的碰撞频率为常量 :math:`\nu`，无碰撞概率满足
:math:`dS/dt=-\nu S`，所以 :math:`S(t)=e^{-\nu t}`。
平均等待时间为 :math:`1/\nu`，在 :math:`\Delta t` 内至少碰撞一次的概率为
:math:`1-e^{-\nu\Delta t}`。变化的频率对应积分危险率
:math:`S(t)=\exp[-\int_0^t\nu(s)\,ds]`。

平衡硬球气体的尺度公式
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

同温、同平均流速的两个独立 Maxwell 速度样本之差，每个分量的方差为 :math:`k_BT/\mu_r`。
对同质量分子，得到

.. math::
   :label: g03-equation-06

   \langle g\rangle=\sqrt{\frac{8k_BT}{\pi\mu_r}}=\sqrt2\,\bar c,\qquad
   \sqrt{\langle g^2\rangle}=\sqrt{\frac{6k_BT}{m}}.

因为硬球的总截面为常量，:math:`\bar\nu=n\sigma\langle g\rangle`，因此

.. math::
   :label: g03-eq-mfp

   \tau_{\mathrm{coll}}=\frac1{\bar\nu},\qquad
   \lambda=\frac{\bar c}{\bar\nu}=\frac1{\sqrt2n\sigma},\qquad n=\frac p{k_BT}.

这里的自由程按长时间内总热运动路程除以碰撞参与次数定义。
一般非平衡分布或速度依赖截面可直接用当前分布对 :math:`K` 平均，求得相应的 :math:`\bar\nu`。
碰撞间隔反映事件出现的快慢；方向动量与热流的弛豫还依赖散射角的作用，
这也为“参数标定：为什么黏度与扩散约束不同的碰撞矩”提供了物理动机。

碰撞尺度与宏观尺度
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

若温度、密度或流速显著变化的长度为 :math:`L`，则

.. math::
   :label: g03-eq-kn

   \mathrm{Kn}=\frac\lambda L.

这个比值比较分子输运距离与宏观非均匀尺度。
当两者相近时，分子能在一次自由飞行中经历明显不同的局部状态，
局部平衡附近的本构关系需要重新评估。
DSMC 以速度分布为演化对象；“单元与时间步把局部近似限制在什么尺度”将据此确定时间步、碰撞单元和粒子样本所需的分辨率。

.. _g03-kinetic-equation:

五、Boltzmann 方程描述什么物理过程
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

分布函数把前面的分子运动和碰撞连接到同一个演化问题。
取与速度无关的加速度 :math:`\mathbf a`，气体在计算域内部满足

.. math::
   :label: g03-eq-boltzmann

   \frac{\partial f}{\partial t}+\mathbf v\cdot\nabla_{\mathbf x}f
   +\mathbf a\cdot\nabla_{\mathbf v}f=Q(f,f).

左侧描述粒子在相空间中的输运：速度决定空间位置的变化，外力决定速度的变化。
右侧 :math:`Q` 描述同一位置附近的二体碰撞，把分子从原速度状态重新分配到其他速度状态。
分子混沌假设使碰前二体分布由两个单分子分布的乘积给出，因此碰撞项对 :math:`f` 为二次型。
截面和角分布共同规定 :math:`Q`，从而规定这一气体模型的动力学。

局部弹性碰撞保持分子数、总动量和总动能：

.. math::
   :label: g03-equation-12

   \int Q\,d^3v=0,\qquad \int m\mathbf vQ\,d^3v=\mathbf0,\qquad
   \int\frac12mv^2Q\,d^3v=0.

这三个恒等式分别给出数目、动量和能量方程中的碰撞贡献。
更高阶速度矩一般会随碰撞改变，例如方向温度差和剪切应力可以逐渐弛豫。
因此，同样的总能量可以对应不同分布，而碰撞控制着这些分布之间的演化。

DSMC 用有限样本近似这个动力学问题。这里已经明确它需要保持的物理量，
以及模型必须提供的两个函数：碰撞率核 :math:`K(g)` 和条件角分布 :math:`p_\Omega`。
“碰撞频率”“弹性散射”和“参数标定”依次推导这两个函数及其参数；
“单元碰撞：NTC 与连续时钟”从 :math:`Q` 的弱形式出发，推导模拟粒子对的事件率并逐段对应单元碰撞内核。

相应的数量恢复、Galilean 不变性与权重一致性检查见 :ref:`验证判据 <g03-validation-fundamentals>`。
