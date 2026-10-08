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

   The public driver validates inputs, prepares the inlet and tallies, sets the wall thermal speed,
   offsets and random seed, then repeats sampling and tracking before final normalization.

   Inputs are edge geometry, active/face arrays, injection bounds, mass, inlet/wall temperatures,
   axial drift, supply density, diffuse probability, history/event counts and random seed.
   Positive progress_interval reports processed histories; it does not guarantee successful escape.
   The driver validates shapes, monotonic geometry, basic parameters and reciprocal internal topology,
   but callers must still reject nonfinite external inputs.

   Outputs are allocated cell density and mean velocities, signed internal face fluxes,
   outgoing boundary fluxes, history_rate, completion counts and ierr.
   Statuses are 0 success, 101 shape, 105 configuration/topology, and 106 incomplete tracking.
   Partial fields may be allocated on a tracking error; they are not completed reference solutions.

   To deliver prescribed lower-boundary inflow, the application uses the same inlet model:

   .. math::

      \Gamma_{\mathrm{in},3,i,1}=J_{\mathrm{in}}A_i/A_{z-,i}.

   This is positive in the axial coordinate convention and averaged over the complete face.
   No second opening-area factor may be applied. The driver does not provide this incoming array
   and does not run a continuity time loop.
