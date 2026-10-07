J03 Time Evolution
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 测试目标与被测源码

   ``source_f90/test_J03_transient.f90`` 检查连续性方程在指定物理时间上的解。
   ``source_f90/test_J03_equilibrium.f90`` 检查平衡参考场的保持与内部输运守恒。
   测试调用 ``sub_J03_initialize_transport_closure`` 构造闭合，
   反复调用 ``sub_J03_continuity_step`` 推进。
   ``sub_J03_solve_steady`` 和 ``sub_J03_compute_balance`` 仅用于各自的收敛与收支检查。

   测试使用指定参考场初始化闭合，再设置当前密度。时间单位为秒，密度采用测试中的归一化数值。

   时间循环由辅助过程 ``evolve`` 执行：设 ``dt=1/steps``，每一步设置本步损失频率，
   调用单步过程取得 ``next``，再将它作为下一步的当前密度。
   运行 40 步和 80 步时各自重新初始化到同一个初值，均推进至 t=1。
   以下先核对无空间输运的时间解，再加入内部面，最后检查收支和稳态判断。

   .. rubric:: 1. 无输运时的指数衰减与时间精度

   测试数组包含两个相互隔离的封闭单元；两者使用相同输入。
   取任一单元，零源项、恒定损失频率 :math:`\nu=2`，
   初始密度 :math:`n(0)=1`。连续性方程退化为

   .. math::

      \frac{dn}{dt}=-2n,\qquad n(t)=e^{-2t}.

   ``test_time_evolution`` 分别用 40、80 步推进到 :math:`t=1`，
   将最终密度与同一个解析值 :math:`e^{-2}` 核对。
   误差和时间阶的判据为

   .. math::

      E_{\Delta t}=|n_{\Delta t}(1)-e^{-2}|,\qquad
      1.9<\frac{E_{\Delta t}}{E_{\Delta t/2}}<2.1.

   当前单步过程对损失采用隐式欧拉，预期时间一阶；
   步长减半后误差应约为原来的一半。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 40 步，Δt=0.025
        - 0.1420456823
        - e⁻² = 0.1353352832
        - 0.006710399
        - —
      * - 80 步，Δt=0.0125
        - 0.1387045695
        - 同上
        - 0.003369286
        - —
      * - 粗/细误差比
        - 1.99163817
        - 一阶时间精度趋近 2
        - —
        - 1.9–2.1

   .. rubric:: 2. 恒定源项与损失共同作用

   同一子测试设置 :math:`S=3,\nu=2,n(0)=1`。由

   .. math::

      \frac{dn}{dt}=S-\nu n

   得到

   .. math::

      n(t)=\frac{S}{\nu}+
      \left(n(0)-\frac{S}{\nu}\right)e^{-\nu t}
      =1.5-0.5e^{-2t}.

   使用 80 步推进至 :math:`t=1`，绝对误差应小于 0.002。
   平衡密度为 1.5；t=1 的参考值还包含初值尚未衰减完的部分。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 有源损密度 n(1)
        - 1.430647715
        - 1.432332358
        - 0.001684643
        - 0.002

   .. rubric:: 3. 每步更新损失频率

   前半段 :math:`0\le t<0.5` 取 :math:`\nu=1`，
   后半段 :math:`0.5\le t\le1` 取 :math:`\nu=3`，源项为零。
   在时间步上对齐切换点，有

   .. math::

      n(1)=n(0)\exp\left[-\int_0^1\nu(t)\,dt\right]=e^{-2}.

   80 步结果与这个连续解析解的差应小于 0.005。
   另与隐式欧拉的离散乘积
   :math:`(1+1/80)^{-40}(1+3/80)^{-40}` 核对，差应小于
   :math:`10^{-12}`。后者检查每步是否使用更新后的频率；
   连续解析值检查时间误差，离散乘积检查频率在第 41 步切换为 3。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 分段频率：与离散乘积核对
        - 0.1395322216
        - 0.1395322216
        - 8.3267e−17
        - 1e−12
      * - 分段频率：与连续解析解核对
        - 0.1395322216
        - 0.1353352832
        - 0.004196938
        - 0.005

   .. rubric:: 4. 两单元内部输运

   ``test_transport`` 将两个单位体积单元用一个面积为 1 的内部面连接，
   面系数为 1，外边界封闭，初始密度均为 1，零源项、零损失。
   固定空间离散后，两个单元的密度满足

   .. math::

      \frac{dn_1}{dt}=-n_1,\qquad
      \frac{dn_2}{dt}=n_1,\qquad
      n_1(t)=e^{-t},\quad n_2(t)=2-e^{-t}.

   100 步、每步 0.01 秒，推进至 :math:`t=1`。
   第一个单元与 :math:`e^{-1}` 的差应小于 0.002，
   总粒子数与初始值 2 的差应小于 :math:`10^{-12}`。
   第一个单元的解析值和总粒子数共同确定第二个单元的参考值。
   这里以固定两单元离散后的常微分方程为参考，测量时间推进误差。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 第一单元 n₁(1)
        - 0.3660323413
        - e⁻¹ = 0.3678794412
        - 0.001847100
        - 0.002
      * - 总粒子数
        - 2
        - 2
        - 约 1e−15
        - 1e−12

   随后该测试打开两个外边界并指定源损，
   独立检查入射率 3、出射率 2、体产生率 1、体损失率 2；
   净收支为零，绝对误差小于 :math:`10^{-12}`。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 入射 / 出射 / 体产生粒子率
        - 3 / 2 / 1
        - 3 / 2 / 1
        - 0
        - 1e−12
      * - 体损失粒子率
        - 2
        - 2
        - 约 1e−15
        - 1e−12
      * - 归一化收支
        - 2.2204e−16
        - 0
        - 2.2204e−16
        - 1e−12

   .. rubric:: 5. 避免把很小的时间步误判成稳态

   ``test_small_timestep`` 使用 :math:`10^{-12}` 的安全系数和纯损失。
   相邻步变化虽小于 :math:`10^{-6}`，归一化残差仍大于 0.9，
   因此 3 次迭代后必须报告未收敛。
   另给独立的残差阈值 :math:`10^{-6}`，确认稳态求解同时满足变化量和残差要求。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 输入
        - 最终相对变化
        - 缩放残差
        - 实际判定
      * - 极小步长，3 轮
        - 1.00009e−12
        - 1
        - 未收敛
      * - 独立残差阈值，35 轮
        - 0.333333
        - 6.86761e−7
        - 收敛；变化阈值 0.9、残差阈值 1e−6

   ``test_faces`` 则检查内部面必须成对、共享面面积必须相同。
   这些约定是前述两单元守恒成立的条件。

   .. rubric:: 6. 非均匀网格的瞬态总粒子数

   ``test_mixed_time_balance`` 用体积 2、5 的两单元区域，
   内部面面积为 3，面系数为 −0.5，检查反向内部输运。
   两个开放外边界既有入射也有出射，体源和损失均非零。

   当前密度为 [2,3]、损失频率为 [0.4,0.7]，时间步为 0.01。
   两个外边界面积均为 2，入射通量大小为 0.7、1.1；
   出口系数大小为 0.3、0.15。体源分别为 0.2、0.5。因而

   .. math::

      Q_{\rm in}=2(0.7+1.1)=3.6,\qquad
      Q_{\rm out}^{q}=2(0.3\times2+0.15\times3)=2.1,\qquad
      Q_S=2\times0.2+5\times0.5=2.9.

   测试先对旧密度调用收支过程核对这三项，再使用新密度检查

   .. math::

      \frac{\sum_KV_K(n_K^{q+1}-n_K^q)}{\Delta t}
      =3.6-2.1+2.9-\sum_K V_K\nu_K n_K^{q+1}.

   出射使用旧密度，隐式损失使用新密度；两侧内部面贡献相互抵消。
   两边之差的绝对值须小于 :math:`10^{-12}`，
   本轮为约 :math:`1.95\times10^{-14}`。
   此项能发现把隐式损失误改为显式损失的错误。

   另在初始化后修改调用端的参考密度和通量，确认闭合中保留的数据与系数不随之改变。
   更新后的密度必须非负，测试不启用负值截断。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 粒子总数变化率
        - −7.636089208
        - 4.4 − 12.03608921
        - 1.95399e−14
        - 1e−12

   这里 4.4 是旧时间层流入减流出加体源，12.03608920821184 是新时间层的体损失。

   .. rubric:: 7. 平衡场的保持

   ``test_J03_equilibrium.f90`` 包含三种输入：

   * ``test_j03_boundary_equilibrium``：单位体积和面积，参考密度 2，
     低端入射通量 2、高端参考出射通量 2，源损为零。
     面系数为 1，因此单元方程为 :math:`dn/dt=2-n`。
     从参考密度 2 调用稳态过程，应保持 2 且残差为零，容差 :math:`10^{-12}`。
   * ``test_j03_ionization_equilibrium``：边界通量为零，
     :math:`S=4,\nu=2`。方程 :math:`dn/dt=4-2n` 的平衡为 2。
     同样从该平衡密度开始，稳态求解应成功并保持该值，容差 :math:`2\times10^{-11}`。
   * ``test_j03_closed_conservation``：封闭两单元，体积和内部面积均为 1，
     初始密度 [1,2]，内部参考通量 1，源损为零。
     以 0.1 时间步执行一次更新，内部面从第一单元移出的数量等于第二单元得到的数量，
     总粒子数应保持为 3，容差 :math:`10^{-13}`。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 边界平衡密度 / 残差
        - 2 / 0
        - 2 / 0
        - 0
        - 1e−12
      * - 源损平衡密度
        - 2
        - S/ν = 2
        - 0
        - 2e−11
      * - 封闭域单步总粒子数
        - 3
        - 3
        - 0
        - 1e−13

   前两项检验平衡解保持；从非平衡初值出发的时间演化由第 1–4 项检查。

   .. rubric:: 运行与输出

   .. code-block:: bash

      bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh

   本程序日志为 ``build/test_J03_transient.log``。
   需要同时看到指数衰减的误差比通过、其他断言通过以及零退出状态。
   平衡测试日志为 ``build/test_J03_equilibrium.log``。两程序在 2026-10-06 全部通过。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Goal and production routines

   ``source_f90/test_J03_transient.f90`` initializes a closure and repeatedly calls
   ``sub_J03_continuity_step`` to prescribed physical times.
   The steady driver and balance routine are tested separately for their own diagnostics.

   .. rubric:: Analytical references

   For a closed cell with :math:`n(0)=1,S=0,\nu=2`,

   .. math::

      n'= -2n,\qquad n(t)=e^{-2t}.

   At time 1, 40 and 80 steps produce errors approximately
   6.710399e-3 and 3.369286e-3. The required ratio is 1.9–2.1,
   demonstrating first-order time convergence.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - 40 steps
        - 0.1420456823
        - 0.1353352832
        - 0.006710399
        - —
      * - 80 steps
        - 0.1387045695
        - 0.1353352832
        - 0.003369286
        - —
      * - Error ratio
        - 1.99163817
        - First order: 2
        - —
        - 1.9–2.1

   For :math:`S=3,\nu=2` the reference is
   :math:`n(t)=1.5-0.5e^{-2t}`, with error below 0.002 at time 1 using 80 steps.
   Piecewise loss (1 then 3, half a second each) has final exact density
   :math:`e^{-2}`; error must be below 0.005.
   An additional discrete-product check verifies that every step uses the updated loss,
   but is not itself an independent accuracy test.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - Source and loss
        - 1.430647715
        - 1.432332358
        - 0.001684643
        - 0.002
      * - Piecewise loss vs discrete product
        - 0.1395322216
        - 0.1395322216
        - 8.3267e−17
        - 1e−12
      * - Piecewise loss vs continuous solution
        - 0.1395322216
        - 0.1353352832
        - 0.004196938
        - 0.005

   .. rubric:: Internal transfer and diagnostics

   Two unit-volume cells with unit face area/coefficient and initial densities 1 satisfy

   .. math::

      n_1'=-n_1,\quad n_2'=n_1,\qquad
      n_1=e^{-t},\quad n_2=2-e^{-t}.

   After 100 steps of 0.01, the first-cell error must be below 0.002 and total-number
   error below 1e-12. This is a semidiscrete ODE reference, not spatial convergence.
   Separate boundary/source/loss rates are checked against 3, 2, 1 and 2.
   Shared faces must be paired with equal areas.
   A tiny timestep must not produce false steady convergence when the residual is large.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - First-cell density
        - 0.3660323413
        - 0.3678794412
        - 0.001847100
        - 0.002
      * - Total number
        - 2
        - 2
        - about 1e−15
        - 1e−12
      * - Scaled open balance
        - 2.2204e−16
        - 0
        - 2.2204e−16
        - 1e−12

   The tiny-step test returned nonconvergence after 3 iterations: change 1.00009e-12,
   residual 0.999999999997. With a separate 1e-6 residual limit it took 35 iterations,
   ending at residual 6.86761e-7 and change 0.333333 (change limit 0.9).

   .. rubric:: Nonuniform transient number balance

   ``test_mixed_time_balance`` uses two cells of volumes 2 and 5, a negative
   internal coefficient and nonzero inlet, outlet, source and loss.
   It verifies independently known rates 3.6, 2.1 and 2.9, then checks

   .. math::

      \sum_KV_K(n_K^{q+1}-n_K^q)/\Delta t
      =3.6-2.1+2.9-\sum_KV_K\nu_Kn_K^{q+1}.

   The absolute defect must be below 1e-12 (observed about 1.95e-14).
   It also verifies copied closure data and nonnegative evolution without clipping.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - Storage rate
        - −7.636089208
        - 4.4 − 12.03608921
        - 1.95399e−14
        - 1e−12

   .. rubric:: Equilibrium preservation

   The equilibrium program starts from the known density 2 in both
   the boundary-driven equation :math:`n'=2-n` and source/loss equation
   :math:`n'=4-2n`. It checks preservation within 1e-12 and 2e-11 respectively.
   A closed two-cell step with initial densities [1,2] preserves total number 3
   within 1e-13. Time evolution from nonequilibrium states is checked above.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - Boundary equilibrium density/residual
        - 2 / 0
        - 2 / 0
        - 0
        - 1e−12
      * - Source-loss equilibrium density
        - 2
        - 2
        - 0
        - 2e−11
      * - Closed-cell total
        - 3
        - 3
        - 0
        - 1e−13

   .. rubric:: Run

   .. code-block:: bash

      bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh

   The log is ``build/test_J03_transient.log``.
   All assertions and the exit status must indicate success.
