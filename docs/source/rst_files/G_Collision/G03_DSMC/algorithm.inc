.. _g03-algorithm:

.. _g03-collision-schedules:

单元碰撞：NTC 与连续时钟
------------------------------------------------------------------------

本节沿着“碰撞算子 → 样本对事件率 → 候选调度 → 两体更新”推导单元碰撞算法。
每得到一个可执行步骤，就给出 ``fun_G03_dsmc_collision.cpp`` 中 ``detail::collide_cell`` 的实际源码，
片段保留源文件行号。范围为固定成员、等权重、单组分、单原子弹性碰撞；
“碰撞频率”与“弹性散射”已经给出 :math:`K(g)` 与条件角分布 :math:`p_\Omega` 的具体形式。

.. _g03-algorithm-notation:

.. rubric:: 本节核心符号

.. list-table::
   :header-rows: 1
   :widths: 28 48 24

   * - 符号
     - 定义
     - 单位/约定
   * - :math:`N,W,V,n`
     - 单元模拟粒子数、统计权重、真实单元体积、真实数密度
     - 无量纲、无量纲、m³、m⁻³
   * - :math:`\Delta t,R_0,R,U`
     - 物理时间步；舍入、接受判定、等待时间所用的均匀随机数
     - s；通常在 [0,1)，取对数时使用 (0,1)
   * - :math:`K(g)=\sigma(g)g,M`
     - 当前相对速率下的碰撞率核；整个碰撞子步内有效的核上界
     - m³/s；:math:`0\le K\le M`
   * - :math:`A,N_{\mathrm{cand}},P_{\mathrm{acc}}`
     - 候选数期望、抽样得到的候选整数个数、单候选接受概率
     - 计数、计数、[0,1]
   * - :math:`\mathbf u_c,E_c;\ \mathbf V_{\mathrm{cm}}`
     - 单元平均速度、未乘权重的样本质心系动能；一对粒子的质心速度
     - m/s、J；m/s（与单元体积 V 区分）
   * - :math:`\Omega,p_\Omega`
     - 散射方向及其单位立体角概率密度
     - :math:`d\Omega` 的单位为 sr；:math:`p_\Omega` 为 sr⁻¹
   * - :math:`\omega`
     - 黏度温度指数，决定 VHS 核的幂次
     - 无量纲

:math:`\mathbb E` 表示期望，:math:`\lfloor\cdot\rfloor` 表示向下取整。

.. rubric:: 采用哪些来源，哪些是本文的实现选择

物理与 DSMC 基本流程以 :ref:`Bird 1994 <g03-ref-bird1994>` 为主；
VSS 依据 :ref:`Koura–Matsumoto 1991 <g03-ref-vss>`。
本节对公式给出所需条件和局部推导。**随机舍入与连续时钟两种调度、守恒能量上界和工作副本提交是当前 G03 的具体选择**，
其他 DSMC 程序可以采用不同的调度、上界和数据提交方式。

.. _g03-s05:

.. _g03-s04:

从 Boltzmann 方程到分步粒子演化
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Boltzmann 方程 :eq:`g03-eq-boltzmann` 同时包含沿轨迹输运与局部碰撞。
算法首先把这两个作用拆成可以分别执行的子问题。令碰撞项为零，沿满足

.. math::
   :label: g03-eq-characteristics

   \frac{d\mathbf x}{dt}=\mathbf v,\qquad
   \frac{d\mathbf v}{dt}=\mathbf a

的轨迹，分布满足 :math:`df/dt=0`。因此可以移动承载分布的样本来求解输运；
无外力时即为 :math:`\mathbf x_i\leftarrow\mathbf x_i+\mathbf v_i\Delta t`。
壁面反射、出流和入流给出轨迹在边界上的处理规则。
完成运动后，按新位置建立单元成员表，供碰撞子步使用。

碰撞子步固定位置，推进 :math:`\partial_t f=Q(f,f)`。
在一阶分步方法中，输运与碰撞各推进 :math:`\Delta t`，共同近似同一个物理时间间隔。
飞行决定接下来可以配对的局部样本，碰撞决定下一次飞行的速度。
这两个操作的顺序差异形成分裂误差，随时间步缩小而减小。
当前 G03 接收调用程序整理好的单元和粒子，执行其中的碰撞子步。

.. _g03-s01:

单元与时间步把局部近似限制在什么尺度
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Boltzmann 碰撞项使用同一位置的分布；有限粒子实现用小单元内的样本代表这个局部分布。
碰撞单元需要分辨平均自由程及密度、温度、流速的变化尺度，
时间步需要分辨碰撞间隔与流动变化时间。常用起点为
:math:`\Delta t\ll\tau_{\mathrm{coll}}`、单元尺度不大于当地平均自由程，
具体精度由时间步、单元尺寸与粒子数的收敛结果确定。

细化单元会减少伙伴间距，同时降低固定粒子总数下的单元样本数。
单元中还需要足够多的样本，以减轻少量粒子反复互撞产生的碰前相关性。
接近连续流区时，自由程和碰撞间隔变小，这些分辨率要求会提高 DSMC 的计算成本。
碰撞网格、宏观采样网格与 PIC 场网格分别服务于局部配对、统计和场求解，可以分别设计。
“非均匀三维柱坐标碰撞单元”给出相应的体积与定位实现。

碰撞弱形式给出随机事件的目标
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

取任意速度函数 :math:`\psi(\mathbf v)`：例如 :math:`\psi=1` 统计数目，
:math:`\psi=m\mathbf v` 统计动量，:math:`\psi=mv^2/2` 统计动能。
一对分子从 :math:`\mathbf v_1,\mathbf v_2` 变为 :math:`\mathbf v_1',\mathbf v_2'` 时，
对这一统计量的改变量为

.. math::
   :label: g03-eq-pair-moment-change

   \Delta\psi=\psi(\mathbf v_1')+\psi(\mathbf v_2')
              -\psi(\mathbf v_1)-\psi(\mathbf v_2).

将所有入射速度对、所有散射方向的改变量按事件率相加，便得到碰撞算子的弱形式：

.. math::
   :label: g03-eq-q

   \int\psi(\mathbf v)Q(f,f)(\mathbf v)\,d^3v
   =\frac12\int_{\mathbb R^3}\int_{\mathbb R^3}
     f_1f_2\,K(g)
     \left[\int_{S^2}p_\Omega(\Omega\mid g)\,\Delta\psi\,d\Omega\right]
     d^3v_1\,d^3v_2.

这里 :math:`f_1,f_2` 取同一位置与时刻，分别对应两种入射速度。
分子混沌假设使入射配对密度写为 :math:`f_1f_2`；
:math:`K(g)` 给出该速度对的碰撞率核，:math:`p_\Omega\,d\Omega` 给出碰撞后的方向概率。
因双积分将一个无序对计数两遍，式前有系数 :math:`1/2`。

这就确定了算法的目标：**随机事件应复现每一种速度统计量的平均变化率**。
对碰撞不变量 :math:`1,m\mathbf v,mv^2/2`，每次二体更新满足 :math:`\Delta\psi=0`；
对其他速度函数，持续累积通常非零的改变量，就得到分布的碰撞演化。

.. _g03-fund-to-algorithm:

从碰撞算子到模拟粒子的配对事件率
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

采用“物理基础：分布、守恒与碰撞尺度”定义的等权重样本表示，令单元真实体积为 :math:`V_{\mathrm{cell}}`。
单元中一个模拟碰撞更新样本 :math:`i,j`，它对单位体积统计量的改变量为
:math:`(W/V_{\mathrm{cell}})\Delta\psi_{ij}`。
记这一无序样本对的事件率为 :math:`\lambda_{ij}`。
先构造以这些事件率演化的连续时间随机过程。给定当前速度状态时，
它对统计量的瞬时平均变化率为

.. math::
   :label: g03-eq-sample-event-generator

   \lim_{h\to0^+}\frac{\mathbb E[M_\psi(t+h)-M_\psi(t)\mid\{\mathbf v_i(t)\}]}{h}
   =\frac{W}{V_{\mathrm{cell}}}\sum_{i\lt j}\lambda_{ij}
      \langle\Delta\psi_{ij}\rangle_\Omega,
   \qquad
   M_\psi=\frac{W}{V_{\mathrm{cell}}}\sum_i\psi(\mathbf v_i).

:math:`\langle\cdot\rangle_\Omega` 表示按 :math:`p_\Omega` 对散射方向取平均。
另一方面，用不同样本之间的配对来近似弱形式中的入射双积分，得到

.. math::
   :label: g03-eq-discrete-collision-moment

   \int\psi Q\,d^3v
   \;\approx\;
   \left(\frac{W}{V_{\mathrm{cell}}}\right)^2
   \sum_{i\lt j}K(g_{ij})\langle\Delta\psi_{ij}\rangle_\Omega.

双积分的系数 :math:`1/2` 已经包含在无序对 :math:`i\lt j` 的计数中。
有限样本配对排除自碰撞，实际对数为 :math:`N(N-1)/2`。
若 :math:`N` 个样本独立来自给定的 :math:`\phi_v`，并令 :math:`n=NW/V_{\mathrm{cell}}`，
这一配对估计的期望相对于连续分布的 :math:`n^2` 系数带有 :math:`1-1/N` 因子；
这一有限样本差异随 :math:`N` 增大而减小。空间平均的误差则由单元尺度控制。
比较这两式，各对采用

.. math::
   :label: g03-eq-fund-pair-rate

   \boxed{\lambda_{ij}=\frac{W}{V_{\mathrm{cell}}}K(g_{ij})}

就产生了所需的离散碰撞变化率。
这条关系同时解释权重和体积的位置：一个样本代表的目标数为 :math:`W`，
它在单元内对应的目标数密度为 :math:`W/V_{\mathrm{cell}}`；乘 :math:`K` 后得到配对频率。

这条事件率确定了目标有限粒子碰撞过程：连续时钟直接抽样这一过程，
随机舍入 NTC 通过有限步候选数近似它的演化。
后文简写 :math:`V=V_{\mathrm{cell}}`，直接对 :math:`C=N(N-1)/2` 个无序样本对抽样。
逐一枚举这些对需要平方级工作量；引入上界后，可以把工作集中在随机生成的候选上。

对整个碰撞步有效的上界
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

上界必须覆盖碰撞引起的速度重分配。仅取步初最大 :math:`g` 可能在后续事件中失效。
若 :math:`K(g)>M`，把接受概率截为 1 后，该对的接受率被限制为 :math:`WM/V`，
低于目标 :math:`WK(g)/V`；调高后续上界仍需补偿此前缺少的候选。

当前 G03 从守恒量构造整个碰撞子步有效的保守上界。其推导如下。
对于同质量、固定粒子数、碰撞子步无粒子或能量进出的单元，
设 :math:`\mathbf u_c=N^{-1}\sum_i\mathbf v_i`，其质心系动能为

.. math::
   :label: g03-eq-majorant

   E_c=\frac{m}{2}\sum_i|\mathbf v_i-\mathbf u_c|^2,\qquad g_{ij}\le\sqrt{\frac{4E_c}{m}}.

这里 :math:`E_c` 是未乘统计权重的样本动能，代表气体的总热动能为 :math:`WE_c`。
令 :math:`\mathbf c_i=\mathbf v_i-\mathbf u_c`，则

.. math::

   g_{ij}^2=|\mathbf c_i-\mathbf c_j|^2
   \le 2(|\mathbf c_i|^2+|\mathbf c_j|^2)
   \le 2\sum_k|\mathbf c_k|^2=\frac{4E_c}{m}.

弹性碰撞保持 :math:`E_c` 不变，故这个界覆盖整个子步。
硬球模型可直接取 :math:`M=\sigma\sqrt{4E_c/m}`。采用可能在子步内被突破的自适应界时，须设计候选恢复机制。
实现检测到核超界时抛出异常，由整步调用层丢弃工作副本。
反应放热、内能转平动或子步内注入粒子时，须依据新的能量重新确定上界。

源码中的 ``variance_sum`` 等于 :math:`\sum_i|\mathbf v_i-\mathbf u_c|^2`，
所以 ``sqrt(2 * variance_sum)`` 对应 :math:`\sqrt{4E_c/m}`；
实际 ``g_max`` 还乘以 :math:`1+10^{-10}`，为浮点舍入保留余量。
平均速度通过相对参考速度的增量计算，可降低整体漂移速度很大时的数值消减。

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_collision.cpp
   :language: cpp
   :caption: fun_G03_dsmc_collision.cpp · collide_cell：热运动尺度与有效核上界
   :linenos:
   :lineno-match:
   :start-at: const Vec3 reference =
   :end-before: result.majorant_m3_per_s =

``model.rate().majorant(g_max)`` 将相对速率范围转换成核上界 :math:`M`，
返回值保存在 ``majorant`` 中，供整段候选循环共同使用。
HS 的核随 :math:`g` 线性增长；当前 VHS 参数范围内的核也单调不减，
因此相应模型直接在 ``g_max`` 处求核。自定义模型必须保证其返回值覆盖整个区间。
当 ``majorant == 0`` 时，单元直接结束碰撞子步。
:math:`\omega=1` 的 VHS 核为正的常数，即使 :math:`g=0` 仍可接受候选；
此时末态相对速度仍为零，粒子速度保持原值。

.. _g03-s06:

从核上界到候选数：随机舍入 NTC
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

每个无序对的候选率取为 :math:`WM/V`，单元共有 :math:`C=N(N-1)/2` 个这样的对。
时间步内候选总数的期望为

.. math::
   :label: g03-eq-ntc-count

   A=C\frac{W\Delta t}{V}M
     =\frac{N(N-1)}2\frac{W\Delta t}{V}M.

对应源码中 ``n`` 为 :math:`N`，``model.weight()`` 为 :math:`W`，
``cell.volume_m3`` 为 :math:`V`，``context.dt_s`` 为 :math:`\Delta t`，
``expectation`` 为 :math:`A`。``budget`` 是允许执行的候选数上限，用于报告资源不足。

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_collision.cpp
   :language: cpp
   :caption: fun_G03_dsmc_collision.cpp · collide_cell：候选数期望 A
   :linenos:
   :lineno-match:
   :start-at: // 共同的候选强度积分
   :end-before: std::uint64_t rounded_candidates

NTC（No-Time-Counter）的基本思想是按这个期望生成候选，再按真实核与上界的比值接受。
当前默认的 ``RoundedNtc`` 先取整数部分 :math:`\lfloor A\rfloor`，
将小数部分 :math:`A_{\mathrm{frac}}=A-\lfloor A\rfloor` 作为再增加一个候选的概率。
抽取 :math:`R_0\sim\mathrm{Unif}[0,1)` 后，候选数为

.. math::
   :label: g03-eq-rounded-candidates

   N_{\mathrm{cand}}=
   \begin{cases}
      \lfloor A\rfloor+1, & R_0\lt A_{\mathrm{frac}},\\
      \lfloor A\rfloor,   & R_0\ge A_{\mathrm{frac}}.
   \end{cases}

由此 :math:`\mathbb E[N_{\mathrm{cand}}]=A`。
例如 :math:`A=0.2` 时，以 20% 的概率测试一对，以 80% 的概率测试零对。
``integral`` 对应 :math:`\lfloor A\rfloor`，``rounded_candidates`` 对应实际候选数。
``rounding`` 用途为舍入分配单独的伪随机流，后续选对、接受和散射各自使用其他用途的流。

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_collision.cpp
   :language: cpp
   :caption: fun_G03_dsmc_collision.cpp · collide_cell：随机舍入候选数
   :linenos:
   :lineno-match:
   :start-at: std::uint64_t rounded_candidates
   :end-before: long double elapsed_hazard

这段计算完成后，循环执行恰好 ``rounded_candidates`` 次候选操作。
每次候选结束时更新的是速度工作副本，后续候选继续读取当前速度。
该调度按候选次数推进；“连续时间候选时钟：怎样得到另一种调度”按候选时刻推进，二者共享候选操作。

NTC 的物理背景见 Bird（1994，第 11 章）。本实现采用每步独立随机舍入，
其他实现也可以携带候选数的小数余量；比较事件统计时需要明确采用的计数规则。

.. _g03-continuous-clock:

连续时间候选时钟：怎样得到另一种调度
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

为什么还需要一个时钟
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

随机舍入 NTC 已经满足候选数期望 :math:`A`，但没有为每个候选赋予时间。
若希望直接抽样这个有限粒子系统的连续时间碰撞过程，可以把相同的核上界用于
**指数等待时间 + 均匀选对 + 接受拒绝**。主库以 ``ContinuousClock`` 提供这一选择；
``RoundedNtc`` 仍是默认值。切换的是候选调度，HS/VHS/VSS 模型与二体更新保持相同。

记单元中的无序对数为 :math:`C=N(N-1)/2`，每对的上界事件率为 :math:`WM/V`，
于是所有候选的总强度为

.. math::
   :label: g03-eq-clock-intensity

   \Lambda=C\frac{W}{V}M,\qquad A=\Lambda\Delta t.

这里 :math:`\Lambda` 的单位是 :math:`\mathrm{s^{-1}}`，:math:`A` 无量纲。
本实现中 :math:`N,W,V,M` 在整个碰撞子步内固定，因而 :math:`\Lambda` 恒定；
被接受的碰撞会改变当前速度及实际核 :math:`K(g_{ij})`，但守恒能量上界仍然有效。

从小时间概率推导指数等待
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

设距上一个候选的等待时间为 :math:`\tau`，无候选概率为 :math:`S(s)=P(\tau>s)`。
恒定强度意味着在长度 :math:`h` 的小区间内出现一个候选的概率为
:math:`\Lambda h+o(h)`，多个候选的概率为 :math:`o(h)`。
由独立增量得到

.. math::
   :label: g03-eq-clock-survival

   S(s+h)=S(s)[1-\Lambda h+o(h)],\qquad
   S'(s)=-\Lambda S(s),\qquad S(0)=1.

解为 :math:`S(s)=e^{-\Lambda s}`。若 :math:`U\sim\mathrm{Unif}(0,1)`，则

.. math::
   :label: g03-eq-clock-wait

   \boxed{\tau=-\frac{\ln U}{\Lambda}},\qquad
   P(\tau>s)=P(U\lt e^{-\Lambda s})=e^{-\Lambda s}.

必须使用严格开区间随机数，因为 :math:`\ln0` 不存在，而 :math:`U=1` 会给出零等待。
若 :math:`\Lambda=0`，没有候选，直接结束碰撞子步。

算法依次累积候选时刻：当下一个时刻达到或超过 :math:`\Delta t` 时停止；
否则均匀选一对，以 :math:`K(g_{ij})/M` 接受。接受时更新双方速度，拒绝时速度不变。
**无论接受还是拒绝，候选时钟都向前推进**，被拒绝的候选同样消耗等待时间。

源码采用等价的积分强度坐标 :math:`H=\Lambda t`：每次累加 :math:`-\ln U`，
与 :math:`A=\Lambda\Delta t` 比较。这样不必显式计算可能溢出或下溢的
:math:`1/\Lambda`；记录事件时间时再换回 :math:`t=(H/A)\Delta t`。
若候选预算不足或时钟累加失去数值分辨率，整步失败并丢弃工作副本。

``elapsed_hazard`` 保存 :math:`H`，``wait`` 是一次单位强度的指数等待量。
``wait >= expectation - elapsed_hazard`` 表示下一个候选达到或越过子步末端。
若仍在子步内，更新 ``elapsed_hazard``，并用 ``time_offset`` 保存相应的物理时刻。
下面的分支位于公共候选循环内；NTC 分支使用整数候选数结束，连续时钟分支使用累计强度结束。

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_collision.cpp
   :language: cpp
   :caption: fun_G03_dsmc_collision.cpp · collide_cell：两种候选调度的循环入口
   :linenos:
   :lineno-match:
   :start-at: long double elapsed_hazard
   :end-before: ++result.candidates;

为什么接受后的过程具有目标事件率
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

在当前状态 :math:`X=(\mathbf v_1,\ldots,\mathbf v_N)` 下，
一个小时间 :math:`h` 内选中并接受指定无序对的概率为

.. math::
   :label: g03-eq-clock-thinning

   (\Lambda h+o(h))\frac1C\frac{K(g_{ij})}{M}
   =\frac WV K(g_{ij})h+o(h).

再按条件角分布 :math:`p_\Omega` 生成末态，就得到有限粒子碰撞过程的生成元：

.. math::
   :label: g03-eq-clock-generator

   (\mathcal L F)(X)
   =\sum_{i\lt j}\frac WV K(g_{ij})
      \int_{S^2}[F(T_{ij,\Omega}X)-F(X)]
             p_\Omega(\Omega\mid g_{ij})\,d\Omega.

其中 :math:`F` 是这个粒子系统的观测量，:math:`T_{ij,\Omega}` 表示一次守恒的二体更新。
每次接受后都从新状态重新计算实际核。恒定上界控制候选率，
接受概率随当前速度变化，从而保留真实事件率的演化。

在有效上界与上述固定成员假设下，指数时钟对这个有限粒子、单元局部碰撞子问题给出连续时间抽样。
其结果仍包含有限粒子统计误差、单元内局部混合的空间误差，
以及飞行或场推动与碰撞分步处理的时间误差；这些误差分别由粒子数、单元尺寸和全局步长控制。

两种调度怎样比较
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. list-table:: 相同候选数期望 A 下的区别
   :header-rows: 1
   :widths: 24 38 38

   * - 项目
     - 随机舍入 NTC
     - 连续候选时钟
   * - 候选生成
     - 先取整数部分，再按小数部分概率补一次
     - 连续抽指数等待，直到越过子步末端
   * - 候选数分布
     - :math:`\lfloor A\rfloor+\mathrm{Bernoulli}(A_{\mathrm{frac}})`，:math:`A_{\mathrm{frac}}=A-\lfloor A\rfloor`
     - :math:`\mathrm{Poisson}(A)`
   * - 候选数均值、方差
     - :math:`A`、:math:`A_{\mathrm{frac}}(1-A_{\mathrm{frac}})`
     - :math:`A`、:math:`A`
   * - 事件时间
     - 不赋予逐候选时间
     - 有碰撞子步内的候选时间；接受事件可记录
   * - 当前支持范围
     - 固定成员、等权重、单组分弹性
     - 固定成员、等权重、单组分弹性

例如 :math:`A=3.7`，NTC 只产生 3 或 4 个候选，方差为 0.21；
连续时钟可以产生任意非负整数个候选，方差为 3.7。
二者的平均候选数相同，但计数涨落与事件序列不同，不能要求相同种子给出相同轨迹。
应比较各自的分布性质、守恒和在充分分辨条件下的物理统计量。

这种上界候选率与接受拒绝的构造也称 majorant collision frequency 方法；
相关文献列于本页末尾的“参考文献与延伸阅读”。

连续时钟是否自然允许电离
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

连续调度便于在事件间重算候选率。将其用于电离，还需给出反应状态与更新规则。
若一次反应改变粒子数，:math:`C`、物种对、权重和可用能量都可能改变；
需要同步更新成员和状态、重算合法的核上界与总候选率，再从新状态抽下一等待时间。
当前 ``ContinuousClock`` 接口采用固定成员的弹性碰撞约定。变成员反应需要扩展状态与提交机制。
总览中的教学动画自行实现了变成员调度，它与这里的弹性接口有不同的适用范围。

两种调度共用的候选操作
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

均匀选出两个不同样本
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

先从 :math:`0,\ldots,N-1` 选 :math:`i`，再从 :math:`0,\ldots,N-2` 选 :math:`j_0`。
若 :math:`j_0\ge i` 则令 :math:`j=j_0+1`，否则令 :math:`j=j_0`。
这相当于从除 :math:`i` 以外的索引中均匀取样。每个有序对概率为 :math:`1/[N(N-1)]`，
每个无序对可以按两个顺序选中，所以概率为 :math:`1/C`。
不同候选之间可以再次选到同一粒子。

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_collision.cpp
   :language: cpp
   :caption: fun_G03_dsmc_collision.cpp · collide_cell：无偏选择无序粒子对
   :linenos:
   :lineno-match:
   :start-at: // 先选 i
   :end-before: const Vec3 v1 =

``select.index(n)`` 使用有界整数拒绝法，“随机抽样与可复现性”给出其无偏性与实现。
流的键包含单元 ID、候选 ``event`` 和 ``pair_selection`` 用途；
同一个候选中的两次整数抽样来自这一流的连续两个结果。

用当前速度计算核并接受
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

选中样本后，从工作区重新读取 :math:`\mathbf v_i,\mathbf v_j`，
计算 :math:`g_{ij}=|\mathbf v_i-\mathbf v_j|`，接受概率为

.. math::
   :label: g03-eq-accept

   P_{\mathrm{acc}}=\frac{K(g_{ij})}{M}.

``q`` 对应当前碰撞核 :math:`K(g_{ij})`，``majorant`` 对应 :math:`M`。
代码先确认上界有效，再用接受判定专用的随机流接受或拒绝；被拒绝时 ``continue`` 返回候选循环入口。

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_collision.cpp
   :language: cpp
   :caption: fun_G03_dsmc_collision.cpp · collide_cell：当前核与接受判定
   :linenos:
   :lineno-match:
   :start-at: const Vec3 v1 =
   :end-before: // 等质量二体弹性碰撞

对随机舍入 NTC，冻结当前速度后，一对样本的平均接受次数为

.. math::
   :label: g03-equation-18

   \underbrace{A}_{\text{候选数期望}}
   \underbrace{\frac1C}_{\text{选中该对的概率}}
   \underbrace{\frac{K(g_{ij})}{M}}_{\text{接受概率}}
   =\frac{W\Delta t}{V}K(g_{ij}).

上界在这个冻结状态的乘积中消去；较松的有效上界增加拒绝候选，保持该平均率。
实际执行会逐候选更新速度，随机舍入 NTC 仍需控制碰撞子步大小。
连续时钟的相同乘积则给出 :eq:`g03-eq-clock-thinning` 中的瞬时条件率，
从而对应前面已经写出的有限粒子生成元。

按角分布散射并写回双方速度
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

接受之后，``sample(relative, scatter)`` 按物理模型的 :math:`p_\Omega` 抽取方向，
返回长度仍为 :math:`g_{ij}` 的末态相对速度 :math:`\mathbf g'`。
对当前等质量模型，双方末态为

.. math::
   :label: g03-eq-algorithm-elastic-update

   \mathbf V_{\mathrm{cm}}=\frac{\mathbf v_i+\mathbf v_j}{2},\qquad
   \mathbf v_i'=\mathbf V_{\mathrm{cm}}+\frac{\mathbf g'}2,\qquad
   \mathbf v_j'=\mathbf V_{\mathrm{cm}}-\frac{\mathbf g'}2.

``center`` 对应 :math:`\mathbf V_{\mathrm{cm}}`，``outgoing`` 对应 :math:`\mathbf g'`，
``a,b`` 为双方末态。写回 ``particles`` 的两行使下一候选立即看到更新后的速度。

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_collision.cpp
   :language: cpp
   :caption: fun_G03_dsmc_collision.cpp · collide_cell：散射与双方速度写回
   :linenos:
   :lineno-match:
   :start-at: // 等质量二体弹性碰撞
   :end-before: if (options.record_events)

这几步完成一次候选。循环结束后，内核以热运动尺度检查累计动量和能量残差，
返回单元报告；整步调用层汇总所有单元，并在全部成功后将速度写回调用程序的粒子数组。
``collision_kernel.hpp`` 声明这个内部入口；Source Guide 沿 ``DsmcStepper::step``
继续说明快照、单元切片、报告与提交的实际调用关系。

模型扩展对事件率提出的要求
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

等权重混合气中，同种配对数为 :math:`N_a(N_a-1)/2`，异种配对数为 :math:`N_aN_b`；
各物种对需要相应的截面、质量、散射和核上界。
非等权重碰撞还需重新设计配对率与加权状态更新，使表示的分子数、事件率和守恒相容。
这些扩展会改变当前单组分内核的约定，应与对应的物理模型一起实现和验证。

.. _g03-s09:

本模块的检查方法与判据见 :ref:`测试说明 <g03-validation-algorithm>`。
