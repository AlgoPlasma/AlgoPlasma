:tocdepth: 1

.. _g03-acceptance-tests:

.. rst-class:: ap-g03

G03_DSMC Validation
============================================================

本页先说明各项独立检查，再用均匀气体弛豫观察它们组合后的演化。
测试对象为单组分、等权重中性气体的弹性碰撞。

.. _g03-custom-runs:

Run and Output
------------------------------------------------------------

从仓库根目录执行：

.. code-block:: bash

   bash tests/009_collision/G03_DSMC/run.sh

需要 Bash、C++20 编译器、Python 3 和 Matplotlib 3.6 或以上。
成功时逐组输出 ``PASS``；失败时报告原因并返回非零状态。
六组时间序列、``summary.csv``、``relaxation.png`` 和 ``run.log``
保存在本测试目录的 ``results/`` 中。
命令后加 ``models`` 等组名可单独检查，加 ``plots`` 可重画已有数据；
命令前加 ``G03_DSMC_SANITIZERS=1`` 可检查内存错误和未定义行为。

Verification Scope
------------------------------------------------------------

前四组检查物性公式、散射方向、空间几何和随机抽样这些基础环节；
后四组检查它们进入完整碰撞步后的守恒、事件频率、复现和异常处理。
最后的弛豫算例观察这些环节组合后的多步物理演化。
解析计算采用浮点误差容差，抽样统计按理论方差和样本量设置容差。

.. _g03-validation-fundamentals:
.. _g03-validation-rate:
.. _g03-validation-calibration:
.. _g03-validation-configuration:
.. _g03-validation-model:

.. rubric:: 1. models — 碰撞核与物性标定

**测试目的：** 确认给定气体参数后，库计算的碰撞核和参考黏度符合 HS/VHS/VSS 的定义，
为后续事件率计算提供正确物性。重点发现核的指数、归一化、参考质量或直径与黏度换算中的错误。

**对应源码：** ``cpp/test_models.cpp`` 的 ``models()``。

对 HS、VHS、VSS，在 :math:`g=10^{-3},30,500,5000\,\mathrm{m/s}`
处按 Bird 截面公式独立计算 :math:`\sigma(g)g`，与模型返回值比较，相对容差为 :math:`3\times10^{-14}`。
同时检查抽查值不超过区间上界、VHS 在 :math:`\omega=1/2` 时恢复 HS、
:math:`\omega=1` 时碰撞核为常数，以及零相对速率分支。
在两倍参考温度下，对 Maxwell 相对速率分布做 Simpson 积分，
与解析热平均比较，相对容差为 :math:`2\times10^{-9}`。

标定部分检查直径与黏度的往返换算、直径加倍后黏度变为四分之一，
并独立对照 HS 黏度闭式公式，避免往返换算共享同一错误。
非法质量、权重、温度、指数、角参数和物种信息应抛出异常。

.. _g03-validation-scattering:

.. rubric:: 2. scattering — 弹性散射抽样

**测试目的：** 确认一次已接受的碰撞保持相对速率，并按指定角分布产生碰后方向。
角分布决定动量与能量在方向之间的转移，需要独立核对前后向偏向和方位对称性；
只检查相对速率无法发现这些方向抽样错误。

**对应源码：** ``cpp/test_models.cpp`` 的 ``scattering()``。

固定入射相对速度，对 :math:`\alpha=1,1.4,2.5` 各抽样 60000 次。
逐次检查相对速率守恒；令 :math:`\chi` 为相对速度的散射偏转角、:math:`\xi=\cos\chi`，
再将样本统计与解析目标比较：

.. math::

   \langle\xi\rangle=\frac{\alpha-1}{\alpha+1},\qquad
   \langle\xi^2\rangle=1-\frac{4\alpha}{(\alpha+1)(\alpha+2)},\qquad
   P(\xi\lt0)=2^{-\alpha}.

统计偏差须在六个理论标准误差内；横向分量的均值应接近零，检查方位对称性。
另覆盖坐标轴附近的入射方向、零相对速度，以及 :math:`\alpha=1` 与各向同性散射的逐样本一致性。
这组检查同时约束散射角的分布和方向基底的构造。

.. _g03-validation-cells:

.. rubric:: 3. geometry — 非均匀柱坐标网格

**测试目的：** 确认参与配对的粒子属于正确单元，碰撞频率使用真实单元体积，
相对速度在共同基底下计算。体积错误会改变事件率，归属或基底错误会使错误的粒子对或相对速率进入碰撞。

**对应源码：** ``cpp/test_geometry.cpp`` 的 ``geometry()``。

构造 :math:`2\times3\times2` 个非均匀单元，逐个核对编号、中心点归属和积分体积

.. math::

   V_c=\frac{r_+^2-r_-^2}{2}(\theta_+-\theta_-)(z_+-z_-).

所有体积求和须等于整个圆柱体积。另检查内部面归属、径向与轴向上边界、
角向周期接缝、多圈绕回、非周期扇区，以及轴线上保留给定方位角的约定。
局部速度转到全局后再转回，应恢复原向量；不同方位角处的相同径向分量
应得到相应的全局相对速度。这能发现直接相减不同局部基底分量的接入错误。

.. _g03-validation-random:

.. rubric:: 4. random — 随机数范围与索引频数

**测试目的：** 确认实数端点和整数索引的抽样约定正确，并检查索引的等概率性。
索引偏差会使部分粒子更频繁地被选中；端点错误可能引起越界或对数等待时间计算异常。

**对应源码：** ``cpp/test_geometry.cpp`` 的 ``random_sampling()``。

抽查 200000 次，确认两种实数抽样分别落在 :math:`[0,1)` 与 :math:`(0,1)`。
对 :math:`n=1,3,7,17,1000` 各抽取 200000 个索引，
检查范围 :math:`[0,n)`，并按二项分布的理论方差检验每个索引的频数。
非二次幂的范围用于检查整数映射的偏差。
相同随机键还须逐次复现，并覆盖大整数范围和空范围异常。

.. _g03-validation-implementation:

.. rubric:: 5. conservation — 多单元守恒与事件报告

**测试目的：** 确认单次弹性碰撞的守恒性质在经过坐标变换、多单元调度和多步写回后仍成立。
它检查完整调用链是否引入动量或能量漂移，并核对事件报告中的计数和守恒量。

**对应源码：** ``cpp/test_stepper.cpp`` 的 ``conservation()``。

对三种模型与两种调度，分别让 128 个粒子在八个非均匀单元内碰撞 48 步。
初态叠加 :math:`10^6\,\mathrm{m/s}` 的共同漂移，热速度分量的标准差为 :math:`250\,\mathrm{m/s}`。
总残差以扣除固定漂移后的热运动尺度归一化，容差为 :math:`2\times10^{-8}`；
这样可避免很大的整体动能掩盖热运动误差。

逐事件另核对二体动量、动能，确认两个粒子不同，并检查连续时钟的时刻顺序；
逐单元计数之和须与整步报告一致。粒子 ID、物种、位置和原数组顺序保持原值。

.. _g03-validation-algorithm:

.. rubric:: 6. schedules — 候选计数、选对与接受频率

**测试目的：** 确认物理碰撞率被正确转换为事件数量、等待时间和选对概率。
碰撞次数过多或过少仍可能满足动量与能量守恒，因此这里直接检查是否出现多碰、少碰或带偏选对。

**对应源码：** ``cpp/test_stepper.cpp`` 的 ``schedules()``。

先用八个粒子和 :math:`\omega=1` 的常数碰撞核，使所有候选都被接受。
分别令期望候选数 :math:`A=0.2,3.7`，各重复 20000 个种子，检查

.. math::

   \begin{aligned}
   \mathbb E[N_c]&=A,\qquad f=A-\lfloor A\rfloor,\\
   \operatorname{Var}(N_c)&=
   \begin{cases}
   f(1-f),&\text{随机舍入 NTC},\\
   A,&\text{连续时钟},
   \end{cases}.
   \end{aligned}

NTC 的计数只应落在 :math:`\lfloor A\rfloor` 和 :math:`\lceil A\rceil`。
连续时钟还检查前半步没有候选的概率 :math:`e^{-A/2}`。
28 个无序粒子对的抽中频数应均匀，以核对选对过程。

随后对三种模型各取四粒子初态，将候选数限制到零或一次，使接受前的速度保持初值。
将实际接受频率与独立求和的精确期望比较：

.. math::

   \mathbb E[N_{\mathrm{accepted}}]
   =\frac{W\Delta t}{V}\sum_{i\lt j}K(g_{ij}).

这一步同时检查权重、体积、相对速率与接受概率是否正确进入碰撞频率。

.. _g03-validation-particles:

.. rubric:: 7. replay — 重排复现与写回范围

**测试目的：** 确认同一物理初态与随机键在粒子重排或日志限长后得到相同结果，
并保证只修改传入子区间的粒子。可发现随机流误绑数组下标、日志分支扰动随机序列或速度写回位置错误。

**对应源码：** ``cpp/test_stepper.cpp`` 的 ``replay()``。

在相同随机键下打乱 96 个粒子的存储顺序，计算后按 ID 对齐，速度须逐位相同，
候选数与接受数也须一致。将事件日志限为一条后，物理结果应保持相同。
另外检查空数组、单粒子、零时间步、零候选及带符号零分量。
传入 ``span`` 子区间时，只有该区间参与计算与写回，前后保护粒子保持原值。

.. rubric:: 8. errors — 异常处理与整步回滚

**测试目的：** 确认非法输入或计算中途失败时，调用程序得到明确异常且保有完整原状态。
特别检查后续单元失败时，前面单元的计算结果也不会留下部分更新，以便调用程序安全处理失败。

**对应源码：** ``cpp/test_stepper.cpp`` 的 ``errors()``。

分别注入重复 ID、未知物种、域外位置、非有限速度、非法时间步和非法选项，
要求抛出异常且粒子状态逐位保持原值。
再构造两个单元：第一单元已经发生碰撞，第二单元触发单元或整步候选预算上限。
失败后两个单元的原始粒子都应保持原值；同一工作区随后仍须能执行合法步骤。

.. _g03-relaxation-example:

Relaxation Results
------------------------------------------------------------

.. _g03-current-examples:

.. rubric:: 1. 初始条件与计算参数

**测试目的：** 将物性、候选调度、散射和写回连成多步计算，检查各向异性初态的
二阶与四阶统计量是否趋向 Maxwell 平衡目标，同时保持总动量与总能量。

**对应源码：** ``examples/relaxation.cpp``；``--check`` 同时执行全程守恒和后期均值检查。

粒子位置固定在单个柱坐标单元内，只演化速度。
初始全局速度等量取 :math:`(v_0,0,0)` 与 :math:`(-v_0,0,0)`，
:math:`v_0=\sqrt{3k_BT_0/m}`，:math:`T_0=300\,\mathrm K`。
三种模型与两种调度各运行一次，每组默认使用 16384 个粒子、2000 步、随机种子 42。
:math:`\Delta t=10^{-7}\,\mathrm s`，总时长 :math:`200\,\mu\mathrm s`；
:math:`n=10^{21}\,\mathrm{m^{-3}}`，:math:`d_{\mathrm{ref}}=4\times10^{-10}\,\mathrm m`；
VHS/VSS 的 :math:`\omega=0.81`，VSS 的 :math:`\alpha=1.4`，权重按 :math:`W=nV/N` 设置。
粒子数用于减小统计涨落，支持下述 1% 相对误差检查。

.. rubric:: 2. 结果图与读图说明

图中展示 VSS + 随机舍入 NTC 的一次计算。
令 :math:`\mathbf c_i=\mathbf v_i-\overline{\mathbf v}`，两个纵轴分别为

.. math::

   F_a=\frac{\sum_i c_{i,a}^2}{\sum_i|\mathbf c_i|^2},\quad a\in\{x,y,z\},
   \qquad
   \kappa_x=\frac{\langle c_x^4\rangle}{\langle c_x^2\rangle^2}.

这里的尖括号表示同一时刻对粒子的平均。

1. 横轴为物理时间，终点 :math:`200\,\mu\mathrm s` 对应第 2000 步。
2. 上图的方向能量份额从 :math:`(1,0,0)` 趋近各 :math:`1/3`；下图的峰度从 1 趋近 3。
   两个目标分别检验方向能量均分和速度分布的四阶统计特征。
3. 灰色区域标出 :math:`100\text{–}200\,\mu\mathrm s` 的取平均区间。
   曲线保留逐步输出的统计涨落；图内 ``Late mean`` 标注该区间的时间均值。

.. plot::
   :include-source: false
   :context: reset
   :alt: VSS 与 NTC 在 200 微秒内的碰撞弛豫：上图为三方向能量份额，下图为 x 分量峰度；灰色区域为 100 至 200 微秒的取平均区间。

   from pathlib import Path
   import runpy
   repo = next(p for p in (Path.cwd(), *Path.cwd().parents)
               if (p / "tests/009_collision/G03_DSMC/plot_results.py").is_file())
   test_dir = repo / "tests/009_collision/G03_DSMC"
   plots = runpy.run_path(str(test_dir / "plot_results.py"))
   measured = plots["load_results"](test_dir / "results", missing_ok=True)
   plots["plot_relaxation"](measured)

.. rubric:: 3. 自动回归检查

对后半程 :math:`(100,200]\,\mu\mathrm s` 的 1000 个等间隔输出取时间均值，
即第 1001–2000 步。对每个时刻先计算 :math:`F_a` 和 :math:`\kappa_x`，再求均值：

.. math::

   \overline h=\frac1M\sum_{j=1}^{M}h(t_j),
   \qquad h\in\{F_x,F_y,F_z,\kappa_x\},\quad M=1000.

三个方向采用最大的相对误差，峰度采用相对目标 3 的误差，统一要求

.. math::

   \begin{aligned}
   \varepsilon_F
   &=\max_{a\in\{x,y,z\}}\frac{|\overline{F_a}-1/3|}{1/3}\leq10^{-2},\\
   \varepsilon_\kappa
   &=\frac{|\overline{\kappa_x}-3|}{3}\leq10^{-2}.
   \end{aligned}

两项均须通过，用于检查后期均值与平衡目标的一致性。
固定使用后半程采样，避免按某个瞬时末态的涨落决定结果；自选步数时沿用同一取样规则。

数值守恒单独逐步检查：温度相对变化 :math:`|T/T_0-1|` 和
归一化平均速度变化 :math:`|\overline{\mathbf v}-\overline{\mathbf v}_0|/v_0`
全程均须不超过 :math:`10^{-10}`。任一检查失败，程序返回非零状态。

``summary.csv`` 同时保留末态值、后期时间均值、两项相对误差及全程最大守恒误差；
``run.log`` 记录检查结果。空间输运和输运系数需相应算例。
