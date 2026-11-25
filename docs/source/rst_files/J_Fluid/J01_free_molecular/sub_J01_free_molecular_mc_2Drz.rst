Complete Calculation
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J01_free_molecular_mc_2Drz.f90`` 依次完成入口准备、随机采样、粒子跟踪和统计归一化。
   调用端提供网格、边界和物理参数，一次调用即可得到参考密度、单元均速及面通量。

   .. rubric:: 1. 按物理问题准备输入

   贯穿示例中，应用先建立环形通道网格：下端和上端开放，径向两侧反射，
   其余为内部面。下端供气参数、粒子质量和壁面参数均由应用传入。
   边界标记决定反向逃逸和反射；只指定入口半径而不设置面类型是不够的。

   .. list-table::
      :header-rows: 1
      :widths: 31 25 44

      * - 输入
        - 尺寸与单位
        - 用途
      * - ``r_edge,z_edge,theta_span``
        - 边界数组，m；标量，rad
        - 定位粒子、计算入口面积和统计几何
      * - ``active,face_type``
        - ``(nr,nz)``、``(4,nr,nz)``
        - 有效区域与面类型
      * - ``inlet_r_lo,inlet_r_hi``
        - m
        - 下端开放面上的注入半径范围
      * - ``neutral_mass``
        - kg，正数
        - 入口及壁面热速度尺度
      * - ``inlet_temperature,wall_temperature``
        - K，正数
        - 入射正态分布宽度与漫反射热分布
      * - ``inlet_drift_z``
        - m/s
        - 入射轴向漂移；径向漂移为零
      * - ``inlet_density``
        - m⁻³，非负
        - 按采样页约定确定总粒子率
      * - ``diffuse_fraction``
        - 无量纲，0 至 1
        - 每次碰壁选择漫反射的概率
      * - ``n_histories,max_events``
        - 正整数
        - 样本数、每条历史的事件循环上限
      * - ``random_seed_value``
        - 整数
        - 初始化运行时随机状态
      * - ``progress_interval``
        - 可选整数
        - 正值按已处理历史数报告进度；省略或非正时关闭

   所有物理输入应有限。主入口检查数组尺寸、递增坐标、正参数及内部面双向拓扑，
   但没有全面检查 NaN、无穷值或各种极端参数；应用仍需验收外部输入。

   .. rubric:: 2. 一次调用内部按什么顺序执行

   .. list-table::
      :header-rows: 1
      :widths: 9 46 45

      * - 顺序
        - 过程或操作
        - 数据变化
      * - 1
        - 检查配置与内部面邻接
        - 确认粒子不会通过非法内部面访问数组
      * - 2
        - ``sub_J01_prepare_fm_inlet``
        - 得到入口结构和 :math:`\dot w`
      * - 3
        - ``sub_J01_initialize_fm_tally``
        - 全部累计数组分配清零
      * - 4
        - 根据壁温计算 :math:`\sigma_{\mathrm w}`，设置定位位移和随机种子
        - 为反射与轨迹准备固定输入
      * - 5
        - 重复 ``sub_J01_sample_fm_inlet`` 和 ``sub_J01_trace_fm_history``
        - 每次抽一条新历史，累计到同一组统计数组
      * - 6
        - ``sub_J01_finalize_fm_tally``
        - 将累计时间与计数转换成场
      * - 7
        - 检查中断历史数
        - 返回成功或跟踪不完整错误

   第 5 步中的碰壁速度更新由轨迹过程调用反射过程。
   外层没有全域物理时间循环，也没有“所有粒子推进同一时间步”的同步操作。
   日志报告的是已处理历史数；其中可能含中断历史。

   .. rubric:: 3. 返回的场量与状态

   .. list-table::
      :header-rows: 1
      :widths: 32 27 41

      * - 输出
        - 尺寸与单位
        - 含义
      * - ``density``
        - ``(nr,nz)``，m⁻³
        - 驻留统计得到的单元密度
      * - ``velocity_r,velocity_z``
        - ``(nr,nz)``，m/s
        - 驻留加权的单元平均速度
      * - ``flux_r,flux_z``
        - ``(nr-1,nz)``、``(nr,nz-1)``，m⁻²s⁻¹
        - 内部面的坐标向通量
      * - ``boundary_outflow_flux``
        - ``(4,nr,nz)``，m⁻²s⁻¹
        - 开放边界逃逸通量，不含规定入流
      * - ``history_rate``
        - s⁻¹
        - 每条历史代表的粒子率
      * - ``n_completed,n_truncated``
        - 整数
        - 正常逃逸数、未完整结束数
      * - ``ierr``
        - 整数
        - 下表中的完成状态

   场数组由主过程分配。早期输入检查失败时它们可能未分配；
   完整历史循环结束后才可使用计数关系
   :math:`N_{\mathrm{completed}}+N_{\mathrm{truncated}}=N_{\mathrm{hist}}`。

   .. list-table::
      :header-rows: 1
      :widths: 13 38 49

      * - 状态码
        - 常量
        - 调用者应如何处理
      * - 0
        - ``J01_SUCCESS``
        - 历史完整；另检查统计精度是否满足使用要求
      * - 101
        - ``J01_ERR_SHAPE``
        - 检查网格、标记和边界数组尺寸
      * - 105
        - ``J01_ERR_CONFIGURATION``
        - 检查物理参数、网格递增性、有效入口和内部面拓扑
      * - 106
        - ``J01_ERR_PARTICLE_TRACKING``
        - 至少一条历史中断；返回场是部分统计，不能按成功结果使用

   增加 ``max_events`` 只可能解决正常长轨迹被上限截断的问题；
   若闭合区域没有出口、粒子进入非法位置或定位阈值不适合网格尺度，增加上限并不能修复原因。

   .. rubric:: 4. 怎样交付完整的参考场

   返回场已经提供密度、内部通量和边界出射。
   规定入射来自调用者的供气模型，不是逃逸统计：
   第 :math:`i` 个注入段的已知粒子率为 :math:`J_{\mathrm{in}}A_i`。
   若接收方使用完整网格面面积 :math:`A_{z-,i}`，则其下端入射数组应为

   .. math::

      \Gamma_{\mathrm{in},3,i,1}
         =\frac{J_{\mathrm{in}}A_i}{A_{z-,i}}
         =\chi_iJ_{\mathrm{in}},
      \qquad \chi_i=\frac{A_i}{A_{z-,i}}.

   该值为正，因为下端入射沿正轴向。无注入的位置为零。
   分段面积与粒子率必须沿用本次调用的入口定义，不能换成另一组参数。
   之后接收方乘完整面面积即可得到粒子率，不再乘一次 :math:`\chi_i`。

   这一步属于场数据的交付，不改变粒子结果。连续性时间循环及参考场闭合
   集中在 J03 的 Complete Calculation 中，本页到参考场准备完成为止。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``sub_J01_free_molecular_mc_2Drz.f90`` prepares the inlet, samples and tracks particles, then normalizes
   the tallies. The caller supplies the grid, boundaries and physical parameters; a single call returns the
   reference density, cell mean velocity and face fluxes.

   .. rubric:: 1. Preparing inputs for the physical problem

   Build the example annular grid with both axial ends open, both radial walls reflecting and internal
   faces between active neighbours. The application supplies the inlet, mass and wall parameters. Mark face
   types as well as the inlet radii: the face flags determine reflection and escape through either open
   end.

   .. list-table::
      :header-rows: 1
      :widths: 31 25 44

      * - Input
        - Shape and units
        - Purpose
      * - ``r_edge,z_edge,theta_span``
        - Edge arrays, m; scalar, rad
        - Locate particles and calculate inlet area and tally geometry
      * - ``active,face_type``
        - ``(nr,nz)``, ``(4,nr,nz)``
        - Active domain and face types
      * - ``inlet_r_lo,inlet_r_hi``
        - m
        - Injection radii on the open lower faces
      * - ``neutral_mass``
        - Positive, kg
        - Inlet and wall thermal velocity scales
      * - ``inlet_temperature,wall_temperature``
        - Positive, K
        - Width of the inlet normal distribution and wall temperature for diffuse reflection
      * - ``inlet_drift_z``
        - m/s
        - Axial injection drift; radial drift is zero
      * - ``inlet_density``
        - Nonnegative, m⁻³
        - Set the total particle rate using the Inlet Sampling convention
      * - ``diffuse_fraction``
        - Dimensionless, 0 to 1
        - Probability of diffuse reflection at each wall collision
      * - ``n_histories,max_events``
        - Positive integers
        - Number of samples and maximum event count per history
      * - ``random_seed_value``
        - Integer
        - Initialize the runtime random state
      * - ``progress_interval``
        - Optional integer
        - Positive values report progress in processed histories; omit or use a nonpositive value to
          disable reporting

   All physical inputs should be finite. The driver validates shapes, increasing coordinates, positive
   parameters and reciprocal internal faces. Applications remain responsible for screening external inputs,
   including NaNs, infinities and extreme parameter values.

   .. rubric:: 2. Order of operations in a call

   .. list-table::
      :header-rows: 1
      :widths: 9 46 45

      * - Step
        - Procedure or operation
        - Result
      * - 1
        - Validate configuration and internal-face adjacency
        - Ensure an internal crossing stays within valid array bounds
      * - 2
        - ``sub_J01_prepare_fm_inlet``
        - Obtain the inlet structure and :math:`\dot w`
      * - 3
        - ``sub_J01_initialize_fm_tally``
        - Allocate and zero all tally arrays
      * - 4
        - Compute :math:`\sigma_{\mathrm w}` from wall temperature and set offsets and the random seed
        - Prepare fixed inputs for reflection and tracking
      * - 5
        - Repeat ``sub_J01_sample_fm_inlet`` and ``sub_J01_trace_fm_history``
        - Sample one new history at a time and accumulate in the same tally arrays
      * - 6
        - ``sub_J01_finalize_fm_tally``
        - Convert accumulated residence times and counts to fields
      * - 7
        - Check the number of truncated histories
        - Return success or an incomplete-tracking error

   In step 5 the tracker calls the reflection routine to change velocity at a wall. Histories are
   independent; the outer loop does not advance particles together on a global physical clock. Progress
   reports count all processed histories, including truncations.

   .. rubric:: 3. Returned fields and status

   .. list-table::
      :header-rows: 1
      :widths: 32 27 41

      * - Output
        - Shape and units
        - Meaning
      * - ``density``
        - ``(nr,nz)``, m⁻³
        - Cell density from residence tallies
      * - ``velocity_r,velocity_z``
        - ``(nr,nz)``, m/s
        - Residence-weighted cell mean velocity
      * - ``flux_r,flux_z``
        - ``(nr-1,nz)``, ``(nr,nz-1)``, m⁻²s⁻¹
        - Coordinate-oriented fluxes on internal faces
      * - ``boundary_outflow_flux``
        - ``(4,nr,nz)``, m⁻²s⁻¹
        - Escape flux through open boundaries; prescribed inflow is supplied separately
      * - ``history_rate``
        - s⁻¹
        - Particle rate represented by one history
      * - ``n_completed,n_truncated``
        - Integers
        - Numbers of normal escapes and incomplete histories
      * - ``ierr``
        - Integer
        - Completion status as listed below

   The driver allocates the field arrays. They may be unallocated after an early input error. The relation
   :math:`N_{\mathrm{completed}}+N_{\mathrm{truncated}}=N_{\mathrm{hist}}` applies once the full history
   loop has run.

   .. list-table::
      :header-rows: 1
      :widths: 13 38 49

      * - Status code
        - Constant
        - Caller action
      * - 0
        - ``J01_SUCCESS``
        - All histories completed. Check statistical precision before using the fields.
      * - 101
        - ``J01_ERR_SHAPE``
        - Check dimensions of grid, masks and boundary arrays.
      * - 105
        - ``J01_ERR_CONFIGURATION``
        - Check physical parameters, increasing edges, inlet availability and reciprocal internal faces.
      * - 106
        - ``J01_ERR_PARTICLE_TRACKING``
        - At least one history was truncated. Treat the returned fields as partial diagnostic tallies.

   Increasing ``max_events`` helps only when valid long trajectories reach the cap. Check for trapped
   particles in closed regions, invalid positions and unsuitable position offsets when diagnosing other
   causes.

   .. rubric:: 4. Passing the complete reference field to the next stage

   The returns already supply density, internal fluxes and outgoing boundary flux. The caller's inlet model
   supplies incoming flux separately. The prescribed particle rate of segment :math:`i` is
   :math:`J_{\mathrm{in}}A_i`. If the consumer uses the full face area :math:`A_{z-,i}`, its lower-face
   inflow array must contain

   .. math::

      \Gamma_{\mathrm{in},3,i,1}
         =\frac{J_{\mathrm{in}}A_i}{A_{z-,i}}
         =\chi_iJ_{\mathrm{in}},
      \qquad \chi_i=\frac{A_i}{A_{z-,i}}.

   The value is positive because lower-face inflow points along positive z. It is zero outside the inlet.
   Use the segment areas and particle rate from the same inlet definition. Multiplying by the full face
   area recovers the particle rate; the fraction :math:`\chi_i` has already been applied.

   This handoff leaves the particle results unchanged. The J03 Complete Calculation page continues with the
   reference-field closure and physical-time continuity loop.
