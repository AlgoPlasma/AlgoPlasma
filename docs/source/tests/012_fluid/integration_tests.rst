J03 Preprocessing Coupling
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 测试目标与调用顺序

   本页的输入是小网格、入口条件和损失频率。测试先执行前处理，
   再将得到的参考密度与面通量交给 J03，检查连续性方程的时间演化。
   FM 一组以轨迹的解析驻留时间和两单元时间解为参考；
   SN 一组以输运方程的解析分布为参考。

   .. list-table::
      :header-rows: 1
      :widths: 30 45 25

      * - 测试文件
        - 正式调用链
        - 独立判据
      * - ``test_J01_J03_channel.f90``
        - ``sub_J01_trace_fm_history`` → ``sub_J01_finalize_fm_tally`` → J03 闭合初始化 → 单步推进；另调用完整 FM 主入口
        - 驻留时间与穿面计数解析值、两单元时间解、粒子收支
      * - ``test_J02_J03_analytic.f90``
        - J02 网格/几何/求积/损失设置 → ``sub_J02_solve_transport`` → J03 闭合初始化 → 从空场推进
        - 输运方程解析分布、空间加密、局部与全域粒子收支

   文件均位于 ``tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/source_f90``。
   两条路线都调用 ``sub_J03_initialize_transport_closure`` 和
   ``sub_J03_continuity_step``。每组按下面四步执行：

   1. 建立几何、入口与损失条件，运行前处理。
   2. 用解析参考检查前处理的密度、面通量或空间加密误差。
   3. 将前处理输出的参考密度、内部面通量、边界入射和出射通量传入闭合初始化；
      保留入口通量，得到内部面与出口的输运系数。
   4. 另设 J03 的当前密度，从空场开始推进，检查时间解、粒子收支及最终状态。

   .. rubric:: 1. FM：两种速度的轨迹统计

   使用 :math:`1\le r\le2,\ 0\le z\le2` 的通道，转角为 2，
   径向一个单元，轴向两个等长单元。轴向面面积 :math:`A=3`，
   每个单元体积 :math:`V=3`。两端开放，径向为镜面壁。

   先规定两条粒子历史的初始位置 :math:`(r,z)=(1.5,0)`，
   速度分别为 :math:`(v_r,v_z)=(0,1),(0,3)`。
   ``sub_J01_trace_fm_history`` 跟踪两条历史经过两个单元并从出口离开，
   随后由 ``sub_J01_finalize_fm_tally`` 将驻留时间与穿面次数换算为密度和通量。
   每条历史代表粒子率 :math:`q=6`。

   长度为 1 的每个单元中，两条历史的驻留时间为 1 和 :math:`1/3`，
   每个轴向面各穿过两次。解析参考为

   .. math::

      n_*=\frac{q(1+1/3)}{V}=\frac83,\qquad
      \Gamma_*=\frac{2q}{A}=4,\qquad
      u_f=\frac{\Gamma_*}{n_*}=\frac32.

   实际跟踪在穿面后有 :math:`10^{-12}` 的位置偏移，故密度与面系数允许
   :math:`10^{-11}` 的绝对误差，计数通量允许 :math:`10^{-13}`。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 两单元密度
        - 2.666666667 / 2.666666667
        - 8/3
        - 最大差 2.6668e−12
        - 1e−11
      * - 内部 / 出口通量
        - 4 / 4
        - 4 / 4
        - 0
        - 1e−13
      * - 内部面系数
        - 1.5
        - 3/2
        - 0
        - 1e−11

   .. rubric:: 2. FM → J03：从空通道开始充填

   将上一步得到的实际密度、内部通量和出口通量传给 J03。
   保持入口通量为 4，源项和损失为零，当前密度从零开始。
   J03 的两单元空间离散方程为

   .. math::

      \frac{dn_1}{dt}=4-\frac32n_1,\qquad
      \frac{dn_2}{dt}=\frac32(n_1-n_2).

   这里 :math:`A/V=1`。初值均为零时，

   .. math::

      n_1(t)=\frac83(1-e^{-3t/2}),\qquad
      n_2(t)=\frac83\left[1-\left(1+\frac32t\right)e^{-3t/2}\right].

   分别用 200、400 步推进至 :math:`t=1`，
   取两个单元的最大绝对误差。要求细步长误差小于 0.004，
   粗细误差之比在 1.9–2.1 之间；整个推进不使用负值截断。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 步数
        - 两单元计算密度
        - 两单元解析密度
        - 最大绝对误差
      * - 200
        - 2.075007198 / 1.180811527
        - 2.071652906 / 1.179132266
        - 0.003354292
      * - 400
        - 2.073328215 / 1.179970446
        - 同上
        - 0.001675309

   误差比实测为 2.00219303，处于要求的 1.9–2.1；400 步误差小于 0.004。

   这里固定两单元网格，只减小时间步长，因此误差比检验的是 J03 的一阶时间精度。

   .. rubric:: 3. FM 完整随机主入口

   同一测试还调用 ``sub_J01_free_molecular_mc_2Drz``，
   完成 4,096 条随机历史：:math:`k_BT/m=1`、轴向漂移 4、
   入口密度参数 2、纯镜面反射，单条最多 100,000 个事件。
   必须所有历史成功离开，不能接受截断的统计场。

   若 :math:`X\sim N(4,1)`，当前入口模型给出的通量为
   :math:`\Gamma_{\rm in}=2E[X\mid X>0]`。
   测试用正态分布解析条件均值检查注入归一化，
   并要求内部面和出口的计数通量与注入相等。
   随后把完整主入口返回的场传给 J03，检查参考场保持和开放边界收支，
   相对容差为 :math:`10^{-12}`。

   这组的参考密度来自 4,096 条随机历史，入口通量的参考来自高斯条件均值。
   前两节的 :math:`8/3` 则由指定的两条轨迹得到，两组输入与断言分别设置。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 完成 / 截断历史数
        - 4096 / 0
        - 4096 / 0
        - 0
        - 精确相等
      * - 注入通量
        - 8.000267669
        - 条件高斯均值：8.000267669
        - 0
        - 1e−12
      * - 内部通量与注入通量最大差
        - 0
        - 0
        - 0
        - 1e−12
      * - J03 单步参考场相对变化
        - 0
        - 0
        - 0
        - 1e−12
      * - 全域相对收支
        - 0
        - 0
        - 0
        - 1e−12

   .. rubric:: 4. SN：有损失的解析输运问题

   选取区域 :math:`1\le r\le2,\ 0\le z\le1`，所有外边界开放。
   使用正式求积过程生成 8 个方向、1 个速率区间，最大速率为 4，
   因此离散速率为 2。只在角度 :math:`\theta=3\pi/8` 的离散速度上给非零入射，
   其方向余弦为 :math:`\mu=\cos\theta,\eta=\sin\theta`。
   其他离散速度的边界输入为零，无速度间散射。

   损失频率 :math:`\nu=1`，对应 :math:`\sigma=\nu/v=1/2`。
   此离散速度的方程及解析解为

   .. math::

      \frac1r\frac{\partial(r\mu\psi)}{\partial r}
      +\eta\frac{\partial\psi}{\partial z}+\sigma\psi=0,
      \qquad
      \psi(r,z)=\frac{e^{-az}}r,\qquad a=\frac{\sigma}{\eta}.

   验证很直接：:math:`r\psi=e^{-az}` 不随 :math:`r` 变化，
   径向导数为零；轴向导数项为 :math:`-\eta a\psi=-\sigma\psi`，
   与损失项抵消。入口分别位于径向低端与轴向低端，
   其输入取解析分布在每个面的面积平均值。

   对单元 :math:`[r_-,r_+]\times[z_-,z_+]`，
   设 :math:`r_c=(r_-+r_+)/2`、:math:`\Delta z=z_+-z_-`。
   径向几何权重积分后得到精确单元平均分布

   .. math::

      \bar\psi_K=
      \frac{\int_{z_-}^{z_+}\int_{r_-}^{r_+}r\psi\,dr\,dz}
           {\int_{z_-}^{z_+}\int_{r_-}^{r_+}r\,dr\,dz}
      =\frac{e^{-az_-}-e^{-az_+}}{a\,\Delta z\,r_c}.

   密度参考为 :math:`n_K^{\rm exact}=w_m\bar\psi_K`；
   :math:`w_m` 是该离散速度的求积权重。只有一个速度贡献，
   故均速必须等于 :math:`(2\mu,2\eta)`。

   .. rubric:: 5. SN 空间加密与 J03 接续

   使用 4×4、8×8、16×16 网格。密度误差按单元体积加权：

   .. math::

      E_h=
      \left[
      \frac{\sum_K V_K(n_K-n_K^{\rm exact})^2}
           {\sum_K V_K(n_K^{\rm exact})^2}
      \right]^{1/2}.

   每次加密要求 :math:`E_{h/2}<0.7E_h`，
   最细网格要求 :math:`E_h<0.03`。
   入口数组在每个面上给出一个常数平均值，误差同时包含空间离散与入口表示误差。
   因此断言检查实际误差下降比例和最细网格误差，而不预设固定的整体收敛阶。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 网格
        - 密度体积加权相对二范数误差
        - 本次 / 上一级误差
        - 要求
      * - 4×4
        - 7.7897606e−3
        - —
        - —
      * - 8×8
        - 2.9101420e−3
        - 0.37359
        - < 0.7
      * - 16×16
        - 1.0384899e−3
        - 0.35685
        - < 0.7，且误差 < 0.03

   每个网格都把 J02 返回的密度、内部通量、边界入射和出射通量直接传给 J03。
   首先检查参考场的逐单元残差，再从零密度推进 2,000 步，
   步长由 J03 稳定步长过程以安全系数 0.7 给出。

   要求 J03 最终密度相对 SN 参考场的最大差小于 :math:`10^{-9}`，
   粒子收支失衡小于 :math:`10^{-9}`，全过程密度非负且不启用截断。
   两层断言分别回答两个问题：解析解与加密误差检验 J02 的输运精度，
   J03 的最终状态与收支检验闭合和时间推进是否保留了前处理的离散平衡。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 网格
        - 参考场缩放单元残差（< 1e−10）
        - J03 最终相对差（< 1e−9）
        - 最终相对收支（< 1e−9）
      * - 4×4
        - 1.5303e−15
        - 6.8792e−16
        - 8.1146e−16
      * - 8×8
        - 5.5919e−15
        - 1.7970e−15
        - 2.5503e−15
      * - 16×16
        - 2.2090e−14
        - 1.0409e−15
        - 4.6369e−16

   三个网格的入射粒子率均为 30.64720770039148。16×16 网格上，SN 出射率为
   20.94478541837066、体损失率为 9.702422282020832，相对收支为 4.6369e−16。
   J03 充填后入口率没有变化。

   .. rubric:: 运行与结果范围

   .. code-block:: bash

      bash tests/012_fluid/J01_free_molecular/run.sh
      bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run.sh
      bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh

   第三个脚本先运行局部测试，再运行本页两项测试。各程序须零状态退出，
   日志分别为 ``build/test_J01_J03_channel.log`` 和
   ``build/test_J02_J03_analytic.log``。

   本页使用独立生成的小网格，检查二维简化模型的前处理与单域 J03 的连接。
   B0、ION 的几何、运行规模与输出记录在下一页应用测试中展开。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Actual production connections

   Both files live in ``J03_neutral_continuity_faceflux_2Drz/source_f90``.
   They pass actual preprocessing density and signed face fluxes to
   ``sub_J03_initialize_transport_closure`` and ``sub_J03_continuity_step``.
   Neither route is used as the other's reference.

   .. rubric:: FM trajectories, statistics and time evolution

   ``test_J01_J03_channel.f90`` traces two histories with axial speeds 1 and 3
   through two unit-length cells. Sector angle 2 and radial bounds [1,2] give
   area and volume 3. Each history has rate 6, hence

   .. math::

      n_*=\frac{6(1+1/3)}3=\frac83,\quad
      \Gamma_*=\frac{12}3=4,\quad u_f=\frac32.

   Actual tallies are normalized, not filled manually.
   Residence and coefficient tolerances are 1e-11 (including tracking offsets);
   crossing-flux tolerance is 1e-13.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - Two-history density
        - 2.666666667 / 2.666666667
        - 8/3
        - max 2.6668e−12
        - 1e−11
      * - Internal / outlet flux
        - 4 / 4
        - 4 / 4
        - 0
        - 1e−13
      * - Face coefficient
        - 1.5
        - 1.5
        - 0
        - 1e−11

   Starting J03 from zero with fixed inlet flux 4 gives the semidiscrete solution

   .. math::

      n_1=\frac83(1-e^{-3t/2}),\qquad
      n_2=\frac83[1-(1+3t/2)e^{-3t/2}].

   At time 1, 200/400 steps produce maximum errors 3.354292e-3 and 1.675309e-3.
   The fine error must be below 0.004 and the error ratio between 1.9 and 2.1.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - 200 steps
        - 2.075007198 / 1.180811527
        - 2.071652906 / 1.179132266
        - 0.003354292
        - —
      * - 400 steps
        - 2.073328215 / 1.179970446
        - same exact pair
        - 0.001675309
        - 0.004
      * - Error ratio
        - 2.00219303
        - First order: 2
        - —
        - 1.9–2.1

   A separate complete FM-driver call samples 4,096 histories with
   :math:`k_BT/m=1`, drift 4, density parameter 2 and specular walls.
   It checks completion, analytic conditional-normal injection, internal/outlet
   number balance and preservation by J03. It does not claim an exact stochastic density.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - Completed / truncated
        - 4096 / 0
        - 4096 / 0
        - 0
        - exact
      * - Injection flux
        - 8.000267669
        - 8.000267669
        - 0
        - 1e−12
      * - Internal flux max error
        - 0
        - 0
        - 0
        - 1e−12
      * - J03 step change / balance
        - 0 / 0
        - 0 / 0
        - 0
        - 1e−12

   .. rubric:: SN analytical transport and refinement

   ``test_J02_J03_analytic.f90`` uses the standard 8-angle, one-speed quadrature,
   speed 2, an open :math:`[1,2]\times[0,1]` domain and loss frequency 1.
   Only the beam at :math:`\theta=3\pi/8` has nonzero input.
   With :math:`\sigma=1/2,\eta=\sin\theta`,

   .. math::

      \frac1r\partial_r(r\mu\psi)+\eta\partial_z\psi+\sigma\psi=0,\qquad
      \psi=\frac{e^{-az}}r,\quad a=\sigma/\eta.

   Incoming face constants are exact area means. Exact cell density is

   .. math::

      n_K^{\rm exact}=w_m\frac{e^{-az_-}-e^{-az_+}}{a\Delta z\,r_c}.

   Volume-weighted relative L2 errors on 4×4, 8×8 and 16×16 grids are
   7.789761e-3, 2.910142e-3 and 1.038490e-3.
   Each refinement must reduce error by a factor below 0.7, and the fine-grid error
   must be below 0.03. Constant face input includes boundary-representation error;
   no fixed global DG order is claimed.

   For each grid, actual J02 outputs initialize J03. Local residual and global
   balance are checked, followed by 2,000 unclipped steps from zero using CFL 0.7.
   Final relative maximum difference from the reference and relative number imbalance
   must be below 1e-9. This consistency check complements, not replaces, the exact solution.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Grid
        - SN relative L2 error
        - Scaled cell residual
        - Final J03 reference difference
        - Final relative balance
      * - 4×4
        - 7.7897606e−3
        - 1.5303e−15
        - 6.8792e−16
        - 8.1146e−16
      * - 8×8
        - 2.9101420e−3
        - 5.5919e−15
        - 1.7970e−15
        - 2.5503e−15
      * - 16×16
        - 1.0384899e−3
        - 2.2090e−14
        - 1.0409e−15
        - 4.6369e−16

   .. rubric:: Execution and limits

   .. code-block:: bash

      bash tests/012_fluid/J01_free_molecular/run.sh
      bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run.sh
      bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh

   The J03 runner executes local checks before these two integration programs.
   Logs are ``build/test_J01_J03_channel.log`` and ``build/test_J02_J03_analytic.log``.
   No full B0/ION run, full three-velocity model or distributed J03 is implied.
