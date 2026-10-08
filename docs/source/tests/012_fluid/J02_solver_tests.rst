J02 Assembled Transport
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 从单元方程到全域解

   这一层依次连接空间单元、反射边界和场重构。
   先求全开放区域的一轮扫描，再固定上一轮分布核对混合反射，
   随后运行反射迭代，最后检查完整求解入口。
   各测试自行构造小网格，源码位于
   ``tests/012_fluid/J02_neutral_sn_transport_2Drz/source_f90``。

   .. list-table::
      :header-rows: 1
      :widths: 27 39 34

      * - 步骤
        - 测试程序
        - 正式调用
      * - 连接内部单元
        - ``test_J02_unified_sweep``
        - ``sub_J02_sweep`` → 开放边界通量重构
      * - 连接反射入射与出射
        - ``test_J02_reflection_partial_inlet``
        - 单轮混合扫描 → ``sub_J02_solve_source_iteration`` → 密度与边界通量
      * - 保正与收支
        - ``test_J02_positivity``
        - 尖锐入口 → 全域扫描 → 各速度角点和收支
      * - 完整结果及重复调用
        - ``test_J02_transport_entry``
        - ``sub_J02_solve_transport`` → 分布、密度、均速和各面通量
      * - 幅值与壁温
        - ``test_J02_review_regressions``
        - 缩放入口后重新求解；低温壁面归一化及错误返回

   .. rubric:: 1. 全开放区域：一次扫描连接相邻单元

   ``test_J02_unified_sweep.f90`` 使用径向边界 [1,2,3]、
   轴向边界 [0,1,2]，形成 2×2 有效单元。
   所有外边界开放，损失为零，求积为 8 个角度、2 个速率区间、上限 4。
   低端入射分布对 :math:`\eta_a>0` 取 1，其余为零。

   执行过程为：

   1. 调用 ``sub_J02_sweep``，每个方向按迎风顺序求解相邻单元。
   2. 用 ``sub_J02_reconstruct_open_boundary_fluxes`` 将结果积分成边界通量。
   3. 把通量乘对应面积，再按外法向符号累加为入射和逸出粒子率。
   4. 将同一入口改用完整四面数组表示，重复扫描并核对全部分布系数。

   零损失下的全域方程是 :math:`Q_{\rm in}=Q_{\rm out}`。
   内部面的流出与相邻单元流入相互抵消，因而最终只需累加外边界。
   要求入射率为正，且

   .. math::

      \frac{|Q_{\rm out}-Q_{\rm in}|}{Q_{\rm in}}<10^{-12}.

   完整入口与紧凑入口结果的最大绝对差也须小于 :math:`10^{-12}`。
   将高端改为反射壁却省略上一轮分布时，应返回
   ``SN_ERR_REFLECTION_INPUT``；
   将面类型设为非法值 −1 时，应返回拓扑错误并定位到单元 (1,1)。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 入射粒子率
        - 164.1875445
        - 出射 164.1875445
        - 相对差 1.7311e−16
        - 1e−12
      * - 完整/紧凑分布最大差
        - 0
        - 0
        - 0
        - 1e−12

   缺少壁面状态实际返回 613；非法面类型返回 612，定位单元 (1,1)，符合预期。

   .. rubric:: 2. 固定上一轮分布，核对混合反射

   ``test_mixed_reflection_linearity`` 使用单元
   :math:`r\in[1,2],z\in[0,1]`，径向低端与轴向高端为壁面。
   损失频率为 0.2，求积为 8×2。
   给定上一轮每个速度的系数

   .. math::

      (c_{0,m},c_{1,m},c_{2,m})
      =(1+0.02m,\ 0.03m,\ -0.01m).

   保持这组旧分布和其他输入不变，以漫反射比例 :math:`d=0,1,0.35`
   各调用一次 ``sub_J02_sweep``。
   入射壁面数据对两种反射贡献线性加权，局部输运方程也是线性的，
   因此三次扫描结果应满足

   .. math::

      \psi_{d=0.35}=0.65\psi_{d=0}+0.35\psi_{d=1}.

   全部空间系数的最大绝对误差须不超过 :math:`3\times10^{-13}`。
   这里固定旧分布，核对的是一轮扫描中壁面数据的组装。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 实测误差
        - 容差
      * - 混合分布与线性组合的最大差
        - 1.3323e−15
        - 3e−13

   .. rubric:: 3. 部分入口与反射迭代

   ``test_partial_inlet_source_iteration`` 使用同一单元，但两径向面和高端均反射。
   低端只在局部区间 :math:`\xi\in[-0.5,0.5]` 开放，其余部分反射。
   入射方向的分布为 1，漫反射比例 0.7，损失频率 0.2。

   由于 :math:`r_c=1.5,h_r=0.5`，开口面积占低端完整面的比例为

   .. math::

      \chi=
      \frac{\int_{-0.5}^{0.5}(1.5+0.5\xi)\,d\xi}
           {\int_{-1}^{1}(1.5+0.5\xi)\,d\xi}
      =\frac12.

   **调用顺序。** ``sub_J02_solve_source_iteration`` 在每轮中由旧出射分布构造反射入射，
   执行全域扫描，再计算相对变化。测试最多允许 800 轮，收敛阈值为 :math:`10^{-14}`。
   随后分别调用单元矩与开放边界通量重构。

   **断言。** 要求返回成功、迭代数大于 2、最终变化不超过阈值。
   对一次多项式 :math:`c_0+c_1\xi+c_2\zeta`，
   四角非负等价于 :math:`c_0\ge|c_1|+|c_2|`；
   测试对所有速度检查该条件，并核对重构密度非负。

   **独立收支。** 低端数组按完整面面积平均。设完整面积为 :math:`A`，
   该处坐标向入射通量为正、出射通量为负，则

   .. math::

      Q_{\rm in}=A\Gamma_{\rm in},\qquad
      Q_{\rm out}=-A\Gamma_{\rm out},\qquad
      Q_{\rm loss}=0.2\,Vn.

   要求 :math:`|Q_{\rm out}+Q_{\rm loss}-Q_{\rm in}|\le2\times10^{-10}`。
   此外，入射重构值应为
   :math:`\tfrac12\sum_{m:\eta_a>0}w_mv_g\eta_a`，
   绝对误差不超过 :math:`2\times10^{-13}`。
   这一步直接检查部分开口面积是否正确传入重构。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 迭代次数 / 最终相对变化
        - 102 / 9.3923e−15
        - 相对变化 ≤ 1e−14
        - —
        - 1e−14
      * - 流入粒子率
        - 193.4288938
        - 流出 + 损失
        - —
        - —
      * - 流出 / 体损失粒子率
        - 90.22111749 / 103.2077763
        - 和等于流入
        - 4.6469e−12
        - 2e−10
      * - 最小多项式角点值
        - 0.01317485452
        - 非负
        - —
        - ≥ 0
      * - 部分入口通量重构误差
        - 0
        - 0
        - 0
        - 2e−13

   同文件的 ``test_compact_zlo_inflow`` 用完整与紧凑数组分别扫描同一入口，
   检查分布及开放通量的一致性，容差 :math:`2\times10^{-13}`。
   ``test_reflection_errors`` 则检查比例 1.1 和最大迭代轮数 1 的指定错误码。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 实测误差
        - 容差
      * - 完整/紧凑分布最大差
        - 0
        - 2e−13
      * - 两类开放通量最大差之和
        - 0
        - 2e−13

   .. rubric:: 4. 尖锐入口下的保正和全域守恒

   ``test_J02_positivity.f90`` 在 :math:`[1,2]\times[0,1]` 上建立 8×8 网格，
   外边界开放，8 个角方向、单一速率 1。
   低端只在第 4、5 个径向单元对入射方向设置分布 1，其余位置为零。
   这样入口边缘具有明显的不连续变化。

   分别以路程损失系数 :math:`\sigma=0` 和 :math:`10` 执行扫描。
   局部过程在出现负角点时使用满足首行收支方程的常数解。
   扫描后逐速度、逐单元检查四角非负，再独立累加边界和体积分：

   .. math::

      Q_{{\rm in},m}
      =Q_{{\rm out},m}+\sigma\sum_KV_K\bar\psi_{K,m}.

   这里单一速率为 1；每个方向的共同速度权重在相对误差中抵消。
   每个方向的相对收支误差须小于 :math:`10^{-12}`，
   零入射方向的分母使用 :math:`10^{-30}` 防止除零。
   该测试同时核对入口陡变后的非负性与粒子数量守恒。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 损失系数
        - 所有速度和单元的最小角点值
        - 各速度相对收支误差的最大值
        - 收支容差
      * - σ = 0
        - 0
        - 5.8023e−16
        - 1e−12
      * - σ = 10
        - 0
        - 3.8682e−16
        - 1e−12

   .. rubric:: 5. 完整入口是否返回完整且对应本次调用的结果

   ``test_J02_transport_entry.f90`` 通过 ``sub_J02_solve_transport``
   依次运行下列情况：

   .. list-table::
      :header-rows: 1
      :widths: 27 37 36

      * - 输入
        - 执行
        - 断言
      * - 全开放单元、零入口、零损失
        - 完整求解与重构
        - 成功且收敛；密度已分配并为零，出射为零
      * - 单元部分入口、其余反射，比例 0.7、零损失
        - 完整入口；另逐步调用反射迭代和三类重构
        - 分布、密度、入射和出射数组最大差 ≤ :math:`10^{-12}`；相对粒子收支 < :math:`10^{-8}`
      * - 同一入口改为紧凑数组
        - 再次求解
        - 密度最大差 ≤ :math:`10^{-12}`
      * - 将迭代上限降至 2
        - 再次调用同一结果对象
        - 返回未收敛；收敛标记为假，密度数组未分配
      * - 2×2 全开放网格、非零低端入口
        - 分别使用完整和紧凑表示
        - 两类内部面数组存在，轴向输运非零；密度、径向和轴向通量差均 ≤ :math:`10^{-12}`
      * - 入口遗漏、两种表示同时给出、区间只给一个端点
        - 分别调用完整入口
        - 返回指定输入错误

   成功调用之后紧接失败调用，能够检查结果对象是否清除了上一次的重构场。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 零输入：最大密度 / 出射通量
        - 0 / 0
        - 0 / 0
        - 0
        - 精确零场
      * - 反射主入口与逐步组装：四类数组最大差
        - 0 / 0 / 0 / 0
        - 0
        - 0
        - 1e−12
      * - 反射主入口粒子收支
        - 4.9240e−10
        - 0
        - 4.9240e−10
        - 1e−8
      * - 紧凑反射入口密度最大差
        - 0
        - 0
        - 0
        - 1e−12
      * - 2×2 网格：密度 / 径向通量 / 轴向通量最大差
        - 0 / 0 / 0
        - 0
        - 0
        - 1e−12

   完整反射求解使用 137 轮，最终变化 8.7634e−11，小于 1e−10。
   上限改为 2 后实际返回 615（未收敛），收敛标记和密度分配状态均为 F。

   .. rubric:: 6. 入口幅值与低温壁面

   ``test_J02_review_regressions.f90`` 对第 3 项的部分入口单元使用
   :math:`a=1,10^{-20},10^{20}` 三个入射幅值。
   线性输运和反射归一化应给出 :math:`\psi(a)=a\psi(1)`。
   每次重新迭代并重构，要求

   .. math::

      \frac{\|\psi(a)/a-\psi(1)\|_\infty}{\|\psi(1)\|_\infty}<10^{-8},

   收敛迭代数相差至多 1，且相对粒子收支误差小于 :math:`10^{-8}`。
   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 入口幅值
        - 迭代数
        - 缩放分布相对误差
        - 相对粒子收支误差
      * - 1
        - 73
        - 0
        - 1.9246e−10
      * - 1e−20
        - 73
        - 3.6595e−16
        - 1.9246e−10
      * - 1e20
        - 73
        - 2.7446e−16
        - 1.9246e−10

   零输入另核对零场固定点。

   随后将壁温降到该速度网格无法表示热分布的范围。
   壁面形状构造必须返回 ``SN_ERR_WALL_NORMALIZATION``，
   错误消息应提示检查 velocity grid。
   完整壁面和部分入口剩余壁面的零归一化分母都要报错；
   纯镜面扫描则应成功，因为其返回速度由镜面映射直接确定。

   **实测错误状态。** 低温 Maxwell 形状返回 617，与 ``SN_ERR_WALL_NORMALIZATION`` 一致；
   错误消息包含 velocity grid。纯镜面调用返回成功。

   .. rubric:: 执行与结果

   .. code-block:: bash

      bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run.sh

   上述各程序在 2026-10-06 通过。日志按程序名保存到 ``build``。
   正向计算检查数值误差与收支，错误用例检查约定的返回码和失败输出。
   接下来在并行页使用相同公共求解过程，改变线程和空间分区重新核对结果。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Assembled calculations

   The tests connect local equations through upwind sweeps, then reflection iteration,
   positivity recovery and complete field reconstruction.

   1. ``test_J02_unified_sweep``: a 2×2 open grid, eight angles, two speeds up to 4,
      unit incoming shape at z-low and zero loss. Reconstruct boundary rates after a
      sweep; relative number imbalance and full/compact distribution difference must
      be below 1e-12. Invalid wall state and face type return specific errors.
      **Measured:** incoming/outgoing rates 164.1875444763250 / 164.1875444763249;
      relative imbalance 1.7311e-16; full/compact maximum difference 0.

   2. ``test_mixed_reflection_linearity``: hold the previous distribution fixed and
      sweep a reflecting cell with diffuse fractions 0, 1 and 0.35.
      Check :math:`\psi_{0.35}=0.65\psi_0+0.35\psi_1` within 3e-13.
      **Measured:** maximum coefficient difference 1.3323e-15, below 3e-13.

   3. ``test_partial_inlet_source_iteration``: one annular cell, three reflecting faces,
      lower inlet interval [-0.5,0.5], diffuse fraction 0.7 and loss frequency 0.2.
      Up to 800 iterations must reach relative change 1e-14. Verify nonnegative
      corners/density, half-area inlet reconstruction within 2e-13 and absolute
      particle imbalance at most 2e-10.
      **Measured:** 102 iterations, final change 9.3923e-15. Incoming, outgoing and
      loss rates were 193.4288938266637, 90.22111748850800 and 103.2077763381511;
      imbalance 4.6469e-12. Minimum corner value 0.0131748545.

   4. ``test_J02_positivity``: an 8×8 open grid, one speed 1, eight directions,
      and only two lower inlet cells populated. Run absorption 0 and 10.
      All polynomial corners must be nonnegative; independently summed directional
      boundary escape plus volume loss must equal injection within relative 1e-12.
      **Measured:** minimum corner 0 in both cases; maximum directional relative
      imbalances 5.8023e-16 (zero loss) and 3.8682e-16 (loss 10).

   5. ``test_J02_transport_entry``: zero input, reflecting partial inlet, full/compact
      representations, nonzero multicell internal fluxes and repeated calls after failure.
      Fields agree with explicit iteration/reconstruction within 1e-12.
      Failed solves must clear the previous density; missing or ambiguous input reports errors.
      **Measured:** 137 reflecting iterations, change 8.7634e-11, relative imbalance
      4.9240e-10. All assembled/full/compact field differences were zero.
      Iteration-limit code 615 left both convergence and density-allocation flags false.

   6. ``test_J02_review_regressions``: amplitudes 1, 1e-20 and 1e20 give normalized
      fields within 1e-8, iteration counts within one and relative balance below 1e-8.
      Zero input gives a zero fixed point. Underresolved thermal walls report
      normalization errors with a velocity-grid hint; pure-specular transport remains valid.

      **Measured:** all amplitudes required 73 iterations; rescaled field errors
      were 0, 3.6595e-16 and 2.7446e-16. Relative imbalances were at most 1.9247e-10.
      Underresolved-wall error code was 617, as expected.

   .. rubric:: Independent balance

   For the partial reflecting cell, the inlet and escape share the lower open area:

   .. math::

      Q_{\rm in}=A\Gamma_{\rm in},\quad
      Q_{\rm out}=-A\Gamma_{\rm out},\quad
      Q_{\rm loss}=0.2Vn,\qquad
      Q_{\rm in}=Q_{\rm out}+Q_{\rm loss}.

   The flux arrays are normalized by the complete face area; the open fraction is
   already present in reconstructed values.

   .. code-block:: bash

      bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run.sh

   All programs passed on 2026-10-06. Logs are under ``build``.
