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

   This page connects the preceding interfaces into a complete calculation. J03 receives field arrays on
   its grid; particle histories, discrete velocities and internal preprocessing structures stay with the
   caller. Initialize once, then choose the transient loop or the optional steady solve.

   .. rubric:: 1. Checking the reference field before calling J03

   Provide active-cell flags, face types, cell volumes, all four face areas, reference density, internal
   face fluxes, and separate boundary inflow and outflow on the same grid. Use the shapes and units in the
   Transport Closure input table.

   Before initialization check the following:

   - All reference densities and used fluxes are finite, density is nonnegative and the source calculation
     completed successfully.
   - Internal fluxes follow positive r or z, with matching face types and areas on both sides.
   - Boundary inflow and outflow are available separately. Do not use one net flux for both.
   - Fluxes are averages over full grid faces. They have not yet been multiplied by face area.
   - The wall model satisfies J03's zero-net-flux condition.
   - Loss frequency is in s⁻¹. Convert any loss per unit path length before use.

   Adapt fields from their source once here, outside the continuity time loop.

   .. rubric:: 2. Connecting the available reference-field interfaces

   .. list-table::
      :header-rows: 1
      :widths: 25 36 39

      * - J03 input
        - J01 driver output
        - J02 complete-solution result
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
        - Application supplies this from the same inlet area and particle rate
        - ``result%inflow_flux``
      * - ``active,volume,face_area,face_type``
        - Application retains the same grid and physical face flags
        - Pack mesh, geometry and boundary flags in the fixed four-face order

   Check ``ierr=J01_SUCCESS`` and verify that all J01 histories completed. The J01 Complete Calculation
   page gives the prescribed-inflow formula. Adapting the fields requires no further particle sampling.

   For a single J02 domain, use ``mesh%active`` for the active mask and ``geometry%volume`` for volume.
   Pack ``area_r_lo/area_r_hi/area_z_lo/area_z_hi`` into ``face_area(1:4,:,:)`` in that order and pack the
   four boundary-type fields into ``face_type`` in the same order. Check ``ierr=SN_SUCCESS`` and
   ``result%converged`` before consuming the result. The reconstructed inlet flux already includes the
   inlet area fraction.

   For spatially partitioned data, first assemble global arrays in the application. A partition interface
   is internal in the global grid. Take one copy of its ``partition_flux`` and assign it to the
   corresponding internal face. Passing a partition's REMOTE flag directly to J03 fails; there is no
   automatic gathering adapter.

   On import, check the geometry, units and signs against the table and use the physical parameters from
   the corresponding preprocessing case.

   .. rubric:: 3. Initializing the closure and choosing an initial density

   Call ``sub_J03_initialize_transport_closure`` to construct ``closure`` and check the status before
   stepping. This is the common entry point for all preprocessing methods.

   Also choose:

   - Initial physical time :math:`t_0` and initial density :math:`n^0`.
   - End time :math:`t_{\mathrm{end}}` and output times.
   - How to obtain :math:`S^q,\nu^q` and prescribed inflow from the external physical model at each step.
   - A stability factor and a time-step cap that resolves the physical response.

   For filling an initially evacuated channel, choose :math:`n^0=0`. For the response of an existing
   neutral population to changes in sources or losses, initialize with that density. The transient problem
   determines the initial condition.

   .. rubric:: 4. Sequence for one physical time step

   .. figure:: ../../../images/J_Fluid/continuity_time_loop_en.svg
      :alt: Update physical inputs, choose a stable step, evaluate old-density fluxes, apply the semi-implicit update, check balance and advance the clock.
      :width: 900px

      Initialization builds the face coefficients once. The loop updates density, sources, losses and inflow.

   .. list-table::
      :header-rows: 1
      :widths: 10 43 47

      * - Step
        - Call or operation
        - Data available at this point
      * - 1
        - Update physical inputs from the external model
        - ``source_rate``, ``closure%loss_frequency``, ``closure%boundary_inflow_flux``
      * - 2
        - ``sub_J03_compute_stable_timestep``
        - Stability bound for this step; check ``ierr``
      * - 3
        - Choose the actual :math:`\Delta t`
        - Respect the stability bound, physical resolution limit and remaining time
      * - 4
        - ``sub_J03_continuity_step``
        - Pass old density and obtain new density and status
      * - 5
        - Check new density and discrete particle balance
        - Keep old and new density until this step has been checked
      * - 6
        - Replace old density with new density and advance the clock
        - :math:`t\leftarrow t+\Delta t`; save results at the output times

   The actual time step can be written as

   .. math::

      \Delta t=\min(\Delta t_{\mathrm{stable}},\Delta t_{\mathrm{physics}},
                   t_{\mathrm{end}}-t,\Delta t_{\mathrm{output}}),

   Use :math:`\Delta t_{\mathrm{output}}` only when an output time must be hit exactly. The application
   advances the main clock; the single-step routine leaves :math:`t` to the caller.

   When charged-particle and neutral time scales differ, the application can subcycle the neutral update
   inside one outer step. How to obtain or interpolate sources and losses belongs to the coupling model;
   J03 does not calculate reaction rates. Recompute the stability bound after changing loss frequency and
   retain nonnegativity and the flux sign convention when updating other inputs.

   .. rubric:: 5. Recording transient outputs

   Record physical time, density field, total particle number, minimum density, boundary inflow and outflow
   rates, volume production and loss, and the balance error for this step. Use the time levels derived on
   the preceding page: outflow from old density and loss from new density.

   ``sub_J03_compute_balance`` returns the individual particle rates. ``sub_J03_compute_residual`` locates
   cells that continue to change; its steady residual can be nonzero during a transient. A nearly unchanged
   density plot or small change in global particle number does not establish cellwise steady state.

   Reinitialize the closure after changing reference density, reference flux or geometry. Editing a stored
   reference array alone leaves the face coefficients unchanged.

   .. rubric:: 6. Finding a final steady state under fixed conditions

   For fixed sources, losses and boundaries, call ``sub_J03_solve_steady`` after initialization. It starts
   from reference density and uses the same single-step update to approach the steady state of the present
   closure. Inspect ``ierr``, ``converged``, relative change and normalized residual together.

   This entry point does not return the response at a chosen physical time. Calling it to convergence at
   every outer step would discard the transient response. With continuous production and neither outflow
   nor loss, a finite steady state may not exist; increasing the iteration limit does not supply the
   missing sink.

   .. rubric:: 7. Extending the calculation

   A new reference-field method can use the common initializer if it provides the same geometry, reference
   density and face fluxes. No source-specific branch is needed in ``sub_J03_continuity_step``.

   Changing the closure requires a new flux relation and corresponding stable time-step condition.
   Adsorbing walls or nonlinear reactions need an appropriate boundary or source interface in addition to
   changes in the physical model.
