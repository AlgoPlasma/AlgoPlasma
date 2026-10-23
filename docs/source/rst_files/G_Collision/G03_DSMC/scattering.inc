.. _g03-scattering:
.. _g03-s07:

弹性散射：守恒律、角测度与 VSS
------------------------------------------------------------------------

前面的碰撞核决定发生速率。本模块给出碰撞发生后的末态规律：
**怎样抽取新的相对方向，并保证两分子的动量和动能守恒？**
HS、VHS 使用各向同性散射；VSS 用一个角参数调节分子动量与剪切应力的输运比例。
以下始终以同种、等质量分子的弹性碰撞为对象。

理论：守恒律为什么没有决定散射角
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

质心运动与相对运动
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

取两分子速度 :math:`\mathbf v_1,\mathbf v_2`，定义

.. math::

   \mathbf V_{\mathrm{cm}}=\frac{\mathbf v_1+\mathbf v_2}{2},\qquad
   \mathbf g=\mathbf v_1-\mathbf v_2,\qquad g=|\mathbf g|.

总动量与总动能分别为

.. math::

   \mathbf P_{\mathrm{pair}}=2m\mathbf V_{\mathrm{cm}},\qquad
   E=m|\mathbf V_{\mathrm{cm}}|^2+\frac{m}{4}g^2.

因此，孤立二体弹性碰撞要求

.. math::

   \mathbf V_{\mathrm{cm}}'=\mathbf V_{\mathrm{cm}},\qquad |\mathbf g'|=g,

符合这两个条件的相对末态构成半径为 :math:`g` 的球面，
相互作用规律进一步确定球面上的散射概率。

用入射相对方向为极轴，令 :math:`\chi\in[0,\pi]` 为偏转角，
:math:`\varphi\in[0,2\pi)` 为方位角。中心相互作用没有优先方位，
所以 :math:`\varphi` 均匀；:math:`\chi` 仍需由模型指定。

抽到 :math:`\mathbf g'` 后，末态重建为

.. math::
   :label: g03-scatter-reconstruct

   \boxed{
   \mathbf v_1'=\mathbf V_{\mathrm{cm}}+\frac12\mathbf g',\qquad
   \mathbf v_2'=\mathbf V_{\mathrm{cm}}-\frac12\mathbf g'}.

这两个式子保持总动量；只要 :math:`|\mathbf g'|=g`，总动能就同时保持。
单个分子的速率一般会改变，因为它在非零质心速度上叠加了一个新方向。

.. rubric:: 源码对应：把相对速度还原为双方速度

``collide_cell`` 中保存了碰前的 ``v1``、``v2`` 和 ``relative = v1 - v2``。
接受一次碰撞后，以下实际实现将散射函数返回的 :math:`\mathbf g'` 写回两个样本：

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_collision.cpp
   :language: cpp
   :start-at:         const Vec3 outgoing =
   :end-at:         particles[j].velocity_mps = b;
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/fun_G03_dsmc_collision.cpp — collide_cell() 的弹性末态重建

``outgoing`` 对应 :math:`\mathbf g'`，``center`` 对应 :math:`\mathbf V_{\mathrm{cm}}`，
``a``、``b`` 对应 :math:`\mathbf v_1'`、:math:`\mathbf v_2'`。
散射模块只返回相对速度；单元内核保留双方索引并完成成对写回。

这里所有向量必须处于同一个正交基底。不同方位角处的局部柱坐标速度
需要在相减前转换成共同的全局速度表示。本章“非均匀三维柱坐标碰撞单元”给出变换公式与实现。

从碰撞参数到角概率：HS 的几何推导
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

当碰撞已经发生时，入射轨迹在有效碰撞圆盘上按面积均匀分布。
圆盘半径记为 :math:`b_{\max}`，则半径环带的条件概率是

.. math::

   p_b(b)\,db=\frac{2\pi b\,db}{\pi b_{\max}^2}
   =\frac{2b}{b_{\max}^2}\,db,\qquad 0\le b\le b_{\max}.

因此 :math:`R=(b/b_{\max})^2` 均匀分布于 :math:`[0,1]`。
均匀面积抽样对应 :math:`b=b_{\max}\sqrt R`。

HS 有 :math:`b_{\max}=d`。由接触法向上的弹性反射几何，

.. math::

   b=d\cos\frac{\chi}{2},\qquad
   \cos\chi=2(b/d)^2-1.

从而

.. math::

   \boxed{\cos\chi=2R-1},\qquad R\sim U(0,1).

令 :math:`\xi=\cos\chi`。因为立体角测度为
:math:`d\Omega=d\varphi\,|d\xi|`，:math:`\xi` 均匀与
:math:`\varphi` 均匀共同给出

.. math::

   p_\Omega=\frac{1}{4\pi},\qquad
   \frac{d\sigma}{d\Omega}=\frac{\sigma}{4\pi}=\frac{d^2}{4}.

所以 HS 在相对速度空间中各向同性。
对应的偏转角概率密度为 :math:`p_\chi(\chi)=\tfrac12\sin\chi`。
VHS 保留这一角规律，只改变碰撞率核。

VSS 引入了哪一个额外假设
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

VHS 的角分布固定后，一旦用黏度确定截面幅度，
模型对扩散与黏度之比的预测也随之固定。
若希望再匹配一个独立的输运比，需要至少增加一个角分布自由度。

把总截面写成有效碰撞圆盘面积 :math:`\sigma(g)=\pi b_{\max}^2(g)`。
VSS 为该圆盘上的入射轨迹规定如下角关系，其中 :math:`\alpha` 是无量纲角参数：

.. math::
   :label: g03-scatter-impact

   \boxed{\frac{b}{b_{\max}}=
   \left(\frac{1+\cos\chi}{2}\right)^{\alpha/2}}
   =\cos^\alpha\frac{\chi}{2}.

Koura 与 Matsumoto 用这一可调角规律匹配目标输运性质；本库采用固定 :math:`\alpha\ge1` 的形式。

取两个独立均匀随机数 :math:`R,R_2\sim U(0,1)`。
代入面积抽样关系 :math:`R=(b/b_{\max})^2`，得到逆变换

.. math::
   :label: g03-scatter-inverse

   \boxed{\xi=\cos\chi=2R^{1/\alpha}-1},\qquad
   \boxed{\varphi=2\pi R_2}.

.. rubric:: 源码对应：由均匀随机数抽取两个角变量

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_scatter.cpp
   :language: cpp
   :start-at:     const Real mu =
   :end-at:     const Real azimuth =
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/fun_G03_dsmc_scatter.cpp — scatter() 的逆变换抽样

``inverse_alpha`` 是预存的 :math:`1/\alpha`，代码变量 ``mu`` 表示角余弦 :math:`\xi=\cos\chi`，
``azimuth`` 是 :math:`\varphi`。两次 ``uniform()`` 提供角抽样所需的两个均匀样本。
``IsotropicScattering::sample`` 传入 ``inverse_alpha=1``，
``VssScattering::sample`` 传入构造时保存的 :math:`1/\alpha`，因此共用这段逆变换。

它的累积分布和密度为

.. math::

   F_\xi(x)=\left(\frac{1+x}{2}\right)^\alpha,\qquad
   p_\xi(x)=\frac{\alpha}{2}
             \left(\frac{1+x}{2}\right)^{\alpha-1},
   \qquad -1\le x\le1,

.. math::

   \frac{d\sigma}{d\Omega}
   =\frac{\alpha\,\sigma(g)}{4\pi}
     \left(\frac{1+\cos\chi}{2}\right)^{\alpha-1}.

当 :math:`\alpha=1` 时回到各向同性；:math:`\alpha>1` 时更偏向前向散射。
“软球”在这里指具有上述角规律的有效散射模型。

为什么扩散与黏度看到不同的角权重
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

先定义两个输运截面：

.. math::
   :label: g03-scatter-transport-cross-sections

   Q^{(1)}(g)=\int(1-\cos\chi)\,d\sigma,\qquad
   Q^{(2)}(g)=\int(1-\cos^2\chi)\,d\sigma.

标签分子的速度是一阶向量。把出射方向的方位角平均后，

.. math::

   \int(\mathbf g'-\mathbf g)\,d\sigma
   =-Q^{(1)}(g)\,\mathbf g.

因此，一阶速度偏差的损失涉及 :math:`1-\cos\chi`，
它进入标签自扩散的碰撞算子。

剪切应力对应二阶、无迹张量。记
:math:`\mathsf A(\mathbf g)=\mathbf g\mathbf g-\tfrac13g^2\mathsf I`。
轴对称角平均给出

.. math::

   \int[\mathsf A(\mathbf g')-\mathsf A(\mathbf g)]\,d\sigma
   =-\frac32Q^{(2)}(g)\mathsf A(\mathbf g).

其原因是二阶方向模态按 Legendre 多项式
:math:`P_2(\cos\chi)=(3\cos^2\chi-1)/2` 衰减，而
:math:`1-P_2(\cos\chi)=\tfrac32(1-\cos^2\chi)`。
因此黏度涉及二阶角权重。本章“参数标定：为什么黏度与扩散约束不同的碰撞矩”
将把这些角权重与相对速率分布一起积分，得到输运系数。

一个直观的检查是 :math:`\chi=\pi`：
等质量分子交换速度，带标签的分子失去原有定向动量，
但这一对分子的总剪切应力不变。因此
:math:`1-\cos\chi=2`，而 :math:`1-\cos^2\chi=0`。
这解释了为什么仅用“碰撞次数”不足以同时描述两种输运。

VSS 角积分的完整结果
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

令 :math:`X=(1+\xi)/2`，其密度为 :math:`p_X(x)=\alpha x^{\alpha-1}`。
于是

.. math::

   \langle X^r\rangle=\int_0^1x^r\alpha x^{\alpha-1}\,dx
   =\frac{\alpha}{\alpha+r},\qquad r>-\alpha.

利用 :math:`\xi=2X-1`，得到一阶与二阶角矩：

.. math::

   \begin{aligned}
   \langle\xi\rangle&=2\langle X\rangle-1=\frac{\alpha-1}{\alpha+1},\\
   \langle\xi^2\rangle&=4\langle X^2\rangle-4\langle X\rangle+1
   =1-\frac{4\alpha}{(\alpha+1)(\alpha+2)}.
   \end{aligned}

从定义立即得到

.. math::
   :label: g03-scatter-q-values

   \boxed{Q^{(1)}=\frac{2}{\alpha+1}\sigma},\qquad
   \boxed{Q^{(2)}=\frac{4\alpha}{(\alpha+1)(\alpha+2)}\sigma}.

因此改变 :math:`\alpha` 会同时改变两种输运截面。
固定总截面时，:math:`Q^{(1)}/\sigma` 随 :math:`\alpha` 增大而减小，但 :math:`Q^{(2)}/\sigma`
在 :math:`\alpha=\sqrt2` 处达到最大值。两类输运对角分布的响应需要分别计算。

数值求值：从散射角构造相对速度
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

当 :math:`g>0` 时，将 :math:`\mathbf e_0=\mathbf g/g` 作为极轴，再构造两个垂直单位向量
:math:`\mathbf e_1,\mathbf e_2`。出射相对速度为

.. math::

   \mathbf g'=g\left[
      \xi\mathbf e_0+\sqrt{1-\xi^2}
      \left(\cos\varphi\,\mathbf e_1+\sin\varphi\,\mathbf e_2\right)
   \right].

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_scatter.cpp
   :language: cpp
   :start-at:     const Vec3 axis =
   :end-at:     return (axis * mu
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/fun_G03_dsmc_scatter.cpp — scatter() 的局部基底与速度重建

``axis``、``e1``、``e2`` 分别对应 :math:`\mathbf e_0,\mathbf e_1,\mathbf e_2`；
``sine`` 对应 :math:`\sqrt{1-\xi^2}`。返回值把单位方向乘回原模长 ``g``，
从而满足弹性约束 :math:`|\mathbf g'|=g`。

执行步骤为：

#. 若 :math:`g=0`，返回零向量。
#. 抽取 :math:`\xi=2R^{1/\alpha}-1` 与 :math:`\varphi=2\pi R_2`。
#. 选一个不近似平行于 :math:`\mathbf e_0` 的辅助轴 :math:`\mathbf h`。
#. 令 :math:`\mathbf e_1=(\mathbf e_0\times\mathbf h)/
   |\mathbf e_0\times\mathbf h|`，:math:`\mathbf e_2=\mathbf e_0\times\mathbf e_1`。
#. 用上式构造 :math:`\mathbf g'`，再由式 :eq:`g03-scatter-reconstruct` 更新两个速度。

辅助轴的选择只是数值构造，不改变目标分布。
旋转入射方向后，抽样 **分布** 必须相应旋转；
同一个随机种子生成的逐次向量不必与旧向量逐一旋转对应，
因为构造的方位零点可能改变。

代码对 :math:`1-\xi^2` 的极小负舍入误差取零。
这样可保持平方根端点处的数值稳定。

源码：散射接口只需要相对速度和随机流
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

公开接口位于 ``scattering.hpp``，实现位于
``fun_G03_dsmc_scatter.cpp``。它不接收质量、黏度、粒子权重或参数文件；
这些信息不属于“保持模长、抽取方向”的职责。

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/scattering.hpp
   :language: cpp
   :start-at: class ElasticScattering
   :end-before: class IsotropicScattering
   :linenos:
   :lineno-match:
   :caption: G_Collision/G03_DSMC/scattering.hpp — ElasticScattering 的调用接口

``collide_cell`` 在接受候选后创建该事件的散射随机流，再调用 ``model.scattering().sample``。
``DsmcModel`` 的构造函数将 HS/VHS 配为 ``IsotropicScattering``，将 VSS 配为 ``VssScattering``。
这条调用关系把模型指定的角分布传给每个已接受事件；“单元碰撞：NTC 与连续时钟”给出完整的候选循环。

.. rubric:: 阅读来源

Bird, *Molecular Gas Dynamics and the Direct Simulation of Gas Flows* (1994)；
Koura 与 Matsumoto, “Variable soft sphere molecular model for inverse-power-law or
Lennard-Jones potential”, *Physics of Fluids A* **3**, 2459--2465 (1991)。
接下来把这些角权重代入速度矩，推导宏观输运性质并确定参数。

本模块的检查方法与判据见 :ref:`测试说明 <g03-validation-scattering>`。
