Complete Calculation
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   本页将前两页的接口连成一个完整计算。
   应用只需给 J03 标准场数组，不需把粒子、离散速度或前处理的内部数据结构传进去。
   下面先完成一次初始化，再分别说明瞬态时间循环和可选的稳态求解。

   .. rubric:: 1. 在进入 J03 前验收参考场

   准备同一网格上的有效标记、面类型、体积、四面面积，
   以及参考密度、内部面通量、分开的边界入射和出射。
   每个数组的尺寸与单位按 Transport Closure 的输入表统一。

   进入初始化前至少确认：

   - 参考密度和所有使用的通量有限，密度非负；来源计算没有报告失败或未完成。
   - 内部面符号沿正 r、正 z；两侧面类型和面积一致。
   - 边界入射与出射未混成同一个净通量，也未重复使用同一份净值。
   - 通量是完整网格面的平均值，不是已乘面积的粒子率。
   - 壁面模型与 J03 的零净通量假设一致。
   - 损失频率单位为 s⁻¹；若来源使用单位路程损失，不可直接把它传入。

   数据来自不同来源时，适配只在这里进行，不进入每步连续性循环。

   .. rubric:: 2. 现有参考场接口怎样连接

   .. list-table::
      :header-rows: 1
      :widths: 25 36 39

      * - J03 输入
        - J01 主过程的返回值
        - J02 完整求解结果
      * - ``density_ref``
        - ``density``
        - ``result%density``
      * - ``flux_r_ref,flux_z_ref``
        - ``flux_r,flux_z``
        - ``result%flux_r,result%flux_z``
      * - ``boundary_outflow_flux_ref``
        - ``boundary_outflow_flux``
        - ``result%outflow_flux``
      * - ``boundary_inflow_flux``
        - 应用按同一入口面积与粒子率补齐
        - ``result%inflow_flux``
      * - ``active,volume,face_area,face_type``
        - 应用保留的同一网格与物理标记
        - 从网格、几何和四面标记对象按固定面序整理

   J01 结果需先确认 ``ierr=J01_SUCCESS`` 且历史完整。
   其规定入射的补齐公式在该模块的 Complete Calculation 中说明；
   连续性适配不重新采样粒子。

   对单域 J02，``mesh%active`` 可用作有效标记，
   ``geometry%volume`` 用作体积；
   四个面积字段 ``area_r_lo/area_r_hi/area_z_lo/area_z_hi``
   依次填入 ``face_area(1:4,:,:)``，四个边界类型字段按相同顺序填入 ``face_type``。
   确认 ``ierr=SN_SUCCESS`` 和 ``result%converged`` 后使用返回场，
   不要再次把入口面积比例乘到已经重构好的通量上。

   空间分区结果还需先在应用层组成全域数组。
   进程交界面在全域网格中是内部面，其 ``partition_flux`` 只取一份，
   填入对应内部面位置；不能作为物理出入口交给 J03。
   当前没有自动汇集适配器，直接把某个分区的 REMOTE 标记传给 J03 会失败。

   导入时按表中约定核对几何、单位和符号；物理参数沿用对应前处理算例。

   .. rubric:: 3. 初始化一次闭合，另外指定初始密度

   调用 ``sub_J03_initialize_transport_closure``，取得 ``closure``，
   先检查返回状态，再开始时间推进。
   不同前处理方法都使用这一初始化入口，无需按参考场来源选择不同函数。

   此时需要另行确定：

   - 初始物理时刻 :math:`t_0` 与初始密度 :math:`n^0`；
   - 结束时刻 :math:`t_{\mathrm{end}}` 和输出时刻；
   - 怎样从外部物理模型得到每步的 :math:`S^q,\nu^q` 与规定入流；
   - 稳定系数和满足物理精度的步长上限。

   例如，研究一开始真空的通道如何充气，可以取 :math:`n^0=0`；
   研究已有中性场受到源损变化后的响应，可以使用已有密度。
   初始密度由所研究的时间演化问题确定。

   .. rubric:: 4. 一个物理时间步的完整顺序

   .. figure:: /_static/J_Fluid/continuity_time_loop.svg
      :alt: 本步物理输入、稳定时间步、旧密度通量、半隐式更新、收支检查与物理时钟推进
      :width: 900px

      只有初始化阶段建立面系数；循环内更新当前密度和本步源损、入流。

   .. list-table::
      :header-rows: 1
      :widths: 10 43 47

      * - 顺序
        - 调用或操作
        - 当前应持有的数据
      * - 1
        - 从外部模型更新本步物理输入
        - ``source_rate``、``closure%loss_frequency``、``closure%boundary_inflow_flux``
      * - 2
        - ``sub_J03_compute_stable_timestep``
        - 本步稳定上限，检查 ``ierr``
      * - 3
        - 选择实际 :math:`\Delta t`
        - 不超过稳定上限、物理精度限制及剩余时间
      * - 4
        - ``sub_J03_continuity_step``
        - 输入旧密度，取得新密度和状态
      * - 5
        - 检查新密度与离散收支
        - 保留旧、新两份密度进行本步验收
      * - 6
        - 用新密度替换旧密度，并推进时钟
        - :math:`t\leftarrow t+\Delta t`；按输出时刻保存结果

   实际步长可写为

   .. math::

      \Delta t=\min(\Delta t_{\mathrm{stable}},\Delta t_{\mathrm{physics}},
                   t_{\mathrm{end}}-t,\Delta t_{\mathrm{output}}),

   其中 :math:`\Delta t_{\mathrm{output}}` 仅在要求精确命中下一个输出时刻时使用。
   主时钟由应用推进；单步过程不会自行改变 :math:`t`。

   若与带电粒子程序耦合，时间步差异较大时，可在一个外层步内使用多个中性单步。
   怎样取得或插值源损属于耦合模型，J03 不替调用者计算反应率。
   更新损失频率后应重新计算稳定上限；改变其他输入后也要维持非负性与通量方向约定。

   .. rubric:: 5. 瞬态输出应记录什么

   至少记录物理时间、密度场、总粒子数、最小密度、
   边界入射与出射粒子率、体产生与损失，以及本步收支误差。
   单步收支按上一页的时间层计算：旧密度出流、新密度损失。

   ``sub_J03_compute_balance`` 给出各项粒子率。
   ``sub_J03_compute_residual`` 可显示哪里仍在变化，但其稳态残差不要求在瞬态过程中为零。
   只凭密度图看起来不变或全域总量变化很小，不能判断每个单元是否达到稳态。

   应用修改参考密度、参考通量或几何后，需要重新初始化闭合。
   只修改对象中的参考场副本不会同步更新面系数。

   .. rubric:: 6. 若只需要固定条件下的最终稳态

   源损与边界保持不变时，可在初始化后调用 ``sub_J03_solve_steady``。
   它从参考密度开始求当前闭合模型的稳态，内部使用同一个单步过程。
   检查 ``ierr``、``converged``、相对变化和归一化残差，
   不能只查看最后打印的一行变化量。

   这个入口不提供某个指定物理时间的响应，不能在每个外层物理步内默认调用到收敛。
   如果问题持续产生粒子却没有任何流出或损失，可能没有有限稳态；
   此时增加迭代次数并不能弥补收支条件的缺失。

   .. rubric:: 7. 将来增加方法时哪些部分需要改动

   新增参考场算法时，只要交付相同的几何、参考密度和面通量，就可使用通用初始化入口，
   不必在 ``sub_J03_continuity_step`` 内增加来源分支。

   若要改变输运闭合本身，应明确新的通量关系及其时间步条件；
   若增加吸附壁面或非线性反应，则需扩展相应边界或源项接口，
   不能仅改面类型名字或沿用当前的零净壁面与给定线性损失假设。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   A complete J03 application first validates reference arrays, initializes closure once,
   chooses an independent physical initial condition, then owns the time loop.

   J01 provides cell density, internal fluxes and outgoing boundary fluxes; the application supplies
   incoming flux from the same inlet model. J02 provides these plus result%inflow_flux.
   Pack geometry and face types into the common four-face order.
   Distributed reference results must be assembled globally first; remote interfaces become internal faces
   and are counted once. There is no automatic gather adapter or distributed J03 solver.

   A physical step updates source, loss and incoming flux, computes a stable bound, selects a smaller
   step as needed for accuracy/end/output times, calls continuity_step, verifies the new state and
   mixed-time-level balance, then advances the application clock.
   Record physical time, total inventory, density extrema and production/removal/boundary rates.

   The initial density need not equal reference density.
   Updating stored reference arrays alone does not recompute face coefficients.
   For fixed inputs and only a final equilibrium, solve_steady is an alternative to the external
   physical-time loop, not an operation to insert inside every outer physical step.

   New reference-field methods can use the generic initializer unchanged.
   A new closure, absorbing wall or nonlinear reaction requires its own physical and stability definition.
