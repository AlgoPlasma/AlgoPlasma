J01 Local Processes
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 检查顺序与文件

   这一层按粒子计算的先后顺序检查入口采样、壁面反射、单条轨迹和统计归一化。
   每个子测试自行设置输入，直接核对该过程的输出。

   测试文件在 ``tests/012_fluid/J01_free_molecular/source_f90``；
   被测过程在 ``J_Fluid/J01_free_molecular``。

   .. list-table::
      :header-rows: 1
      :widths: 33 32 35

      * - 测试文件与子测试
        - 正式过程所在文件
        - 输出量
      * - ``test_J01_fm_units.f90``：``test_sampling``
        - ``sub_J01_fm_sampling.f90``
        - 各入口段面积、单条历史粒子率、位置和初速度
      * - 同文件：``test_reflection``
        - ``sub_J01_fm_reflection.f90``
        - 四种面法向下的反射速度
      * - 同文件：``test_trajectory``
        - ``sub_J01_fm_trajectory.f90``
        - 单元索引、驻留时间、穿面计数、逃逸或截断状态
      * - 同文件：``test_statistics``
        - ``sub_J01_fm_statistics.f90``
        - 单元密度、均速、内部面与出口通量
      * - ``test_J01_corner_crossings.f90``
        - ``sub_J01_fm_trajectory.f90``
        - 同时到达两面的连通路径及各单元净计数
      * - ``test_J01_sampling_distribution.f90``
        - 采样与反射文件
        - 多次抽样的事件频率，与解析概率核对

   .. rubric:: 1. 入口面积和单条历史的权重

   **问题与输入。** 径向边界为 [1,2,3]，入口为 [1.5,2.5]，周向张角为 2。
   入口分别与两个轴向低端面相交。取热速度标准差 :math:`\sqrt{k_BT/m}=1`、
   轴向漂移为零、入口密度参数 10、历史数 100。

   **执行。** ``test_sampling`` 调用 ``sub_J01_prepare_fm_inlet``，
   取得分段面积和 ``history_rate``；再设置种子 17，调用
   ``sub_J01_sample_fm_inlet`` 生成位置和速度。

   **参考值。** 环形开口面积为 :math:`A=\Theta(r_+^2-r_-^2)/2`，所以

   .. math::

      A_1=2(2^2-1.5^2)/2=1.75,\qquad
      A_2=2(2.5^2-2^2)/2=2.25.

   总面积为 4。零漂移截断正态的平均入射速度为 :math:`\sqrt{2/\pi}`，
   每条历史代表的粒子率为

   .. math::

      q=\frac{n_{\rm in}A_{\rm in}E[v_z]}{N}
        =\frac{10\times4}{100}\sqrt{\frac2\pi}
        =0.4\sqrt{\frac2\pi}.

   **断言。** 逐项核对两个面积和 :math:`q`。
   重新设置相同种子后，第一组位置、速度应一致。
   随后抽样 1,000 次，检查 :math:`1.5\le r\le2.5`、:math:`v_z>0`，
   以及四个状态量均为有限数。全部单元改为无效后，入口准备必须返回
   ``J01_ERR_CONFIGURATION``。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 入口段面积 A₁
        - 1.75
        - 1.75
        - 0
        - 1.75e−11
      * - 入口段面积 A₂
        - 2.25
        - 2.25
        - 0
        - 2.25e−11
      * - 单条历史粒子率 q
        - 0.3191538243
        - 0.3191538243
        - 5.5511e−17
        - 1e−11

   同种子重置后四个状态量的最大差为 0；1,000 次入口抽样均在规定范围内且速度有限。
   空入口实际返回 105，与 ``J01_ERR_CONFIGURATION`` 一致。

   .. rubric:: 2. 入口位置与速度的概率

   ``test_J01_sampling_distribution.f90`` 将入口扩为 [1,3]，调用相同采样过程。
   每种条件抽样 :math:`N=32768` 次，并用三个固定种子重复。

   均匀物理面积对应 :math:`r^2` 在 [1,9] 上均匀，因此

   .. math::

      P(r^2<5)=\frac{5-1}{9-1}=\frac12.

   热速度标准差为 1 时，径向速度服从标准正态；零漂移的轴向速度为正半轴条件正态。
   设 :math:`\Phi` 为标准正态累积分布函数，则

   .. math::

      P(|v_r|<1)=P(v_z<1)=2\Phi(1)-1
          =\operatorname{erf}(1/\sqrt2)\simeq0.6826895.

   将轴向漂移改为 1，轴向速度服从 :math:`X\sim N(1,1)` 在 :math:`X>0` 上的条件分布：

   .. math::

      P(X<1\mid X>0)
      =\frac{\Phi(0)-\Phi(-1)}{\Phi(1)}
      \simeq0.4057133.

   测试统计满足条件的样本数 :math:`N_{\rm hit}`，得到实测概率
   :math:`\hat p=N_{\rm hit}/N`。每项要求

   .. math::

      |\hat p-p|\le 7\sqrt{\frac{p(1-p)}{N}}.

   右边是七倍二项分布标准差。日志同时输出实测概率、解析概率和容差。
   这个检查可区分均匀半径与均匀面积抽样，也可检验漂移后正半轴截断的归一化。
   三个种子检验相同的概率条件；同一种子的逐值重复性由第 1 项单独检查。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 面积概率
        - 0.4949951–0.5054626
        - 0.5000000
        - 0.005462646
        - 0.01933495
      * - 径向速度概率
        - 0.6820679–0.6862793
        - 0.6826895
        - 0.003589805
        - 0.01799811
      * - 零漂移轴向概率
        - 0.6781616–0.6831055
        - 0.6826895
        - 0.004527871
        - 0.01799811
      * - 漂移为 1 的轴向概率
        - 0.4028015–0.4040833
        - 0.4057133
        - 0.002911778
        - 0.01898806

   计算值一列列出三个种子、相应漂移条件下的最小值至最大值；误差为这些运行中的最大绝对偏差。

   .. rubric:: 3. 镜面与漫反射速度

   **镜面输入。** ``test_reflection`` 对四个面分别设置 :math:`(v_r,v_z)=(2,3)`，
   以漫反射比例 0 调用 ``sub_J01_reflect_velocity``。
   径向面应得到 :math:`(-2,3)`，轴向面应得到 :math:`(2,-3)`，
   即法向反号、切向保持。

   **漫反射输入。** 比例改为 1，热速度标准差仍为 1。
   小测试每面抽取 100 次，检查低端面朝正坐标方向、高端面朝负坐标方向，
   以及速度有限。概率程序再对每面抽取 32768 次。

   令 :math:`v_n>0` 表示朝气体区域的法向速率，:math:`v_t` 表示切向速度。
   当前壁面模型的概率密度为

   .. math::

      p_n(v_n)=v_ne^{-v_n^2/2},\quad v_n>0,\qquad
      p_t(v_t)=\frac{e^{-v_t^2/2}}{\sqrt{2\pi}}.

   积分得到测试使用的两个参考概率：

   .. math::

      P(v_n<1)=\int_0^1v_ne^{-v_n^2/2}\,dv_n=1-e^{-1/2},\qquad
      P(|v_t|<1)=\operatorname{erf}(1/\sqrt2).

   四面均使用第 2 项的统计容差。这样同时检查反射方向与速度抽样分布。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 径向镜面反射 (vᵣ,v_z)
        - (−2,3)
        - (−2,3)
        - 0
        - 2e−11 / 3e−11
      * - 轴向镜面反射 (vᵣ,v_z)
        - (2,−3)
        - (2,−3)
        - 0
        - 2e−11 / 3e−11
      * - 漫反射法向概率
        - 0.3928833–0.3966980
        - 0.3934693
        - 0.003228658
        - 0.01889100
      * - 漫反射切向概率
        - 0.6797180–0.6843567
        - 0.6826895
        - 0.002971475
        - 0.01799811

   两个概率区间涵盖四个面、三个种子的 12 次运行；所有反射样本均朝气体区域。

   .. rubric:: 4. 一条直线轨迹经过两个单元

   **问题与输入。** 径向边界 [1,2]，轴向边界 [0,1,2]；
   两单元之间是内部面，外边界开放。
   从 :math:`(r,z)=(1.5,0.25)` 以 :math:`(v_r,v_z)=(0,2)` 运动。

   **执行。** ``test_trajectory`` 清零 ``tally`` 后调用
   ``sub_J01_trace_fm_history``。粒子先穿过 :math:`z=1`，再从 :math:`z=2` 离开。
   穿面后位置沿运动方向偏移 :math:`\varepsilon_z=10^{-9}`，避免重复命中同一个面。

   **参考值。** 第一段的飞行距离为 0.75，第二段为 :math:`1-\varepsilon_z`，故

   .. math::

      T_1=\frac{1-0.25}{2}=0.375,\qquad
      T_2=\frac{1-\varepsilon_z}{2}.

   内部面和高端出口计数均为 +1。
   反向测试从 :math:`z=1.75` 以 :math:`v_z=-2` 出发，
   内部面和低端出口计数均为 −1。

   **状态检查。** 正常轨迹应返回 ``escaped=.true.``、``truncated=.false.``。
   事件数上限改为 1，必须标记为截断。
   定位采用左闭右开的单元区间：:math:`z=1` 属于第二单元，:math:`z=2` 返回域外索引。
   域外起点返回截断状态，避免继续访问无效数组位置。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 第一单元驻留时间
        - 0.375
        - 0.375
        - 0
        - 1e−11
      * - 第二单元驻留时间
        - 0.4999999995
        - (1−10⁻⁹)/2
        - 5.5511e−17
        - 1e−11
      * - 正向内部/出口计数
        - +1 / +1
        - +1 / +1
        - 0
        - 1e−11
      * - 反向内部/出口计数
        - −1 / −1
        - −1 / −1
        - 0
        - 1e−11

   定位返回值为 2 和 −1；正常轨迹的逃逸/截断标志为 T/F，事件上限及域外起点为 F/T。

   .. rubric:: 5. 角点与阶梯边界

   ``test_J01_corner_crossings.f90`` 使用 2×2 网格，
   从一个单元中心以 :math:`(v_r,v_z)=(\pm1,\pm1)` 出发，0.5 后同时到达两个面。
   四种符号分别执行一次轨迹过程。

   当前角点约定是先穿径向面，再穿新单元的轴向面。例如正向轨迹的单元路径为

   .. code-block:: text

      (1,1) --径向面--> (2,1) --轴向面--> (2,2)

   中间单元的净计数为零，起点单元为 −1，终点单元为 +1；
   总驻留时间仍为 0.5。各计数和驻留时间绝对误差须小于 :math:`10^{-12}`。

   随后把终点单元设为无效，分别将新单元的轴向面设为开放或镜面壁：
   开放时必须从该面逃逸；镜面时轴向速度反号。
   两种情况都只记录已发生的径向穿越，轴向内部面计数保持零。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 四种方向的径向/轴向穿面计数
        - 按预期路径计数
        - 径向优先路径
        - 最大差 0
        - 1e−12
      * - 四种方向的单元净计数
        - 起点 −1、中间 0、终点 +1
        - 同左
        - 最大差 0
        - 1e−12
      * - 四种方向的总驻留时间
        - 0.5
        - 0.5
        - 0
        - 1e−12

   阶梯开放面：径向计数 1、轴向内部计数 0、逃逸 T。阶梯镜面壁：计数仍为 1 和 0，反射后轴向速度 −1。


   **近角点的多事件回归。** 径向网格为 [0.001,0.002,0.003] m，轴向网格为
   [0,0.001,0.002] m。粒子从 (0.0015,0.0004999995) m 出发，
   两个速度分量均为 1000 m/s。到达内部径向面和轴向面的时间分别为
   :math:`5\times10^{-7}` s 与 :math:`5.000005\times10^{-7}` s，
   因此应先穿径向面，再穿轴向面，各记一次，最终从径向高端逃逸。
   跟踪最多执行 10 个事件，检查整条历史而不是在角点后立即停止。

   实测轴向穿越次数为 1（修复前为 2），逐单元收支最大误差为 0；
   总驻留时间为 :math:`1.499999999\times10^{-6}` s，
   与直线轨迹解析值 :math:`1.5\times10^{-6}` s 的差为定位偏移造成的
   :math:`10^{-15}` s，小于测试上限 :math:`10^{-14}` s。

   再交换两面的到达次序、遍历四种速度符号，并分别使用 1000 和
   :math:`10^7` m/s，共 16 组确定性算例；后一速度仅用于检验很短时间间隔的数值处理。
   全部轨迹正常逃逸且只有一次出口计数，穿面计数与逐单元收支最大误差均为 0。
   驻留时间相对误差最大为 :math:`6.6667\times10^{-10}`，
   绝对误差满足 :math:`4\varepsilon/v+128\epsilon_{\mathrm{mach}}t_{\mathrm{exact}}`；
   其中 :math:`\varepsilon=10^{-12}` m 是定位偏移，:math:`v` 是速度分量的大小，
   :math:`\epsilon_{\mathrm{mach}}` 是当前浮点类型的机器精度，
   :math:`t_{\mathrm{exact}}` 是解析飞行时间。
   参考计数由直线依次穿过哪些面确定，参考时间由到出口的距离除以速度得到。

   .. rubric:: 6. 将统计数组换成场量

   ``test_statistics`` 单独调用 ``sub_J01_initialize_fm_tally`` 和
   ``sub_J01_finalize_fm_tally``。使用径向边界 [1,2,3]、
   轴向边界 [0,1,2]、张角 2、历史粒子率 :math:`q=6`。

   在单元 (1,1) 设置驻留时间 2、径向速度时间积分 6、轴向速度时间积分 −4；
   径向内部面计数为 −2，轴向内部面计数为 3，径向低端出口计数为 −1。
   该单元体积为 3，三个相关面面积依次为 4、3、2，所以

   .. math::

      n=\frac{6\times2}{3}=4,\qquad
      u_r=\frac62=3,\qquad u_z=\frac{-4}{2}=-2,

   .. math::

      \Gamma_r=\frac{6(-2)}4=-3,\qquad
      \Gamma_z=\frac{6\times3}{3}=6,\qquad
      \Gamma_{r-,\rm out}=\frac{6(-1)}2=-3.

   断言逐项核对这些值，并检查新建统计数组为零、未访问单元的密度为零。
   确定性标量容差为 :math:`10^{-11}\max(1,|\mathrm{expected}|)`。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 密度 n
        - 4
        - 4
        - 0
        - 4e−11
      * - 均速 (uᵣ,u_z)
        - (3,−2)
        - (3,−2)
        - 0
        - 3e−11 / 2e−11
      * - 内部通量 (Γᵣ,Γ_z)
        - (−3,6)
        - (−3,6)
        - 0
        - 3e−11 / 6e−11
      * - 低端出口通量
        - −3
        - −3
        - 0
        - 3e−11
      * - 未访问单元密度
        - 0
        - 0
        - 0
        - 1e−11

   表中的 0 是本次浮点计算得到的零差值，并非只根据断言通过推断；显示位数相同的非零误差仍单独列出。

   .. rubric:: 运行与结果

   .. code-block:: bash

      bash tests/012_fluid/J01_free_molecular/run.sh

   本页涉及的三个程序在 2026-10-06 全部通过。
   数值断言记录计算值、参考值、误差及容差；失败时另打印检查名称。
   日志文件名与程序名相同，位于本测试目录的 ``build`` 中。
   下一页使用完整主入口，让上述过程在同一次粒子计算中连续执行。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   Near-corner regressions now follow complete histories. The original failing fixture
   records one axial crossing (previously two) and zero cell-balance error.
   Sixteen cases cover both arrival orders, all velocity signs and two time scales;
   all signed counts and balances agree exactly, with maximum relative residence
   error 6.6667e-10 due to positioning offsets.

   .. rubric:: Files and progression

   Under ``J01_free_molecular/source_f90``, ``test_J01_fm_units.f90`` checks
   sampling, reflection, trajectories and statistics; ``test_J01_corner_crossings.f90``
   checks simultaneous face events; ``test_J01_sampling_distribution.f90`` checks probabilities.
   Production routines are the corresponding sampling, reflection, trajectory and
   statistics processes in ``J_Fluid/J01_free_molecular``.

   .. rubric:: Inlet sampling

   Radial edges [1,2,3], inlet [1.5,2.5] and sector angle 2 give segment areas
   1.75 and 2.25. With thermal standard deviation 1, zero drift, density parameter
   10 and 100 histories, the rate per history is :math:`0.4\sqrt{2/\pi}`.
   The test checks these values, seed repeatability, 1,000 valid samples and empty-inlet errors.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - Inlet area A1
        - 1.75
        - 1.75
        - 0
        - 1.75e−11
      * - Inlet area A2
        - 2.25
        - 2.25
        - 0
        - 2.25e−11
      * - History rate
        - 0.3191538243
        - 0.3191538243
        - 5.5511e−17
        - 1e−11

   For an inlet [1,3], analytical probabilities are

   .. math::

      P(r^2<5)=1/2,\qquad
      P(|v_r|<1)=P(v_z<1)=\operatorname{erf}(1/\sqrt2).

   With axial drift 1, :math:`P(X<1\mid X>0)=[\Phi(0)-\Phi(-1)]/\Phi(1)`.
   Each condition uses 32768 samples and three seeds, accepting frequency error
   at most :math:`7\sqrt{p(1-p)/N}`.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - Area probability
        - 0.4949951–0.5054626
        - 0.5000000
        - 0.005462646
        - 0.01933495
      * - Radial probability
        - 0.6820679–0.6862793
        - 0.6826895
        - 0.003589805
        - 0.01799811
      * - Axial, zero drift
        - 0.6781616–0.6831055
        - 0.6826895
        - 0.004527871
        - 0.01799811
      * - Axial, unit drift
        - 0.4028015–0.4040833
        - 0.4057133
        - 0.002911778
        - 0.01898806

   .. rubric:: Reflection

   Specular reflection reverses the normal component and preserves the tangent
   on all four faces. Diffuse samples must point inward and have finite velocities.
   With unit thermal scale, the inward normal speed has Rayleigh density
   :math:`v_ne^{-v_n^2/2}` and the tangent is standard normal.
   The probability tests verify :math:`P(v_n<1)=1-e^{-1/2}` and the Gaussian
   tangential probability, using the same sample size and tolerance.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - Wall normal
        - 0.3928833–0.3966980
        - 0.3934693
        - 0.003228658
        - 0.01889100
      * - Wall tangent
        - 0.6797180–0.6843567
        - 0.6826895
        - 0.002971475
        - 0.01799811

   Ranges span four faces and three seeds. Specular velocities were (-2,3) on radial
   faces and (2,-3) on axial faces, with zero component errors.

   .. rubric:: Trajectories and corner events

   A particle starting at z=0.25 with axial speed 2 crosses z=1 and escapes at z=2.
   Residence times are 0.375 and :math:`(1-10^{-9})/2`; internal/outlet counts are +1.
   A reversed path gives -1 counts. Locator endpoints, truncation and outside starts
   are checked separately.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - Residence 1
        - 0.375
        - 0.375
        - 0
        - 1e−11
      * - Residence 2
        - 0.4999999995
        - (1−10⁻⁹)/2
        - 5.5511e−17
        - 1e−11
      * - Forward counts
        - +1 / +1
        - +1 / +1
        - 0
        - 1e−11
      * - Reverse counts
        - −1 / −1
        - −1 / −1
        - 0
        - 1e−11

   On a 2×2 grid, all four velocity signs hit a corner after 0.5.
   Radial-first crossing must use the new cell's axial face: start/end net counts
   are -1/+1, the intermediate count is zero, and total residence is 0.5.
   Stepped boundaries check escape or reflection after the radial crossing.

   Measured corner residence was 0.5 for all four signs; maximum crossing-count
   and cell-balance errors were zero (limit 1e-12). Stepped-wall axial velocity was -1.

   .. rubric:: Tally normalization

   Prescribed residence 2, velocity integrals 6 and -4, crossing counts -2 and 3,
   and low-r exit count -1 are normalized with rate 6, volume 3 and face areas 4,3,2.
   Expected density is 4, mean velocity (3,-2), internal fluxes (-3,6) and exit flux -3.
   Scalar tolerance is :math:`10^{-11}\max(1,|\mathrm{expected}|)`; corner checks use 1e-12.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - Density
        - 4
        - 4
        - 0
        - 4e−11
      * - Velocity
        - (3,−2)
        - (3,−2)
        - 0
        - 3e−11 / 2e−11
      * - Internal flux
        - (−3,6)
        - (−3,6)
        - 0
        - 3e−11 / 6e−11
      * - Exit flux
        - −3
        - −3
        - 0
        - 3e−11
      * - Unvisited density
        - 0
        - 0
        - 0
        - 1e−11

   .. code-block:: bash

      bash tests/012_fluid/J01_free_molecular/run.sh

   All three programs passed on 2026-10-06. Logs are in ``build``; probability
   records include observed value, reference and tolerance.
