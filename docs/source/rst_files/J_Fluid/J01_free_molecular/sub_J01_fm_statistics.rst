.. J_Fluid contribution history (Git author dates; edit times include timezone).
   2026-09-18 12:00 +08:00 | Yingjie Chen | git 69bdc8603906
   2026-10-06 23:50 +08:00 | Yingjie Chen | git fa8cb9f5be05
   2026-11-25 15:14 +08:00 | Yingjie Chen | git 8652258184b5
   2026-11-25 15:59 +08:00 | Yingjie Chen | edit (Codex-assisted)

Field Estimators
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J01_fm_statistics.f90`` 把原始轨迹统计转换成物理场。
   入口给出的 :math:`\dot w` 是每条历史代表的粒子率；
   本页将它与驻留时间、穿面次数结合，再使用单元体积和面面积归一化。

   .. rubric:: 1. 先区分历史、飞行段和空间单元

   历史编号为 :math:`h`。一条历史经历多次碰面，因此由许多飞行段组成。
   记 :math:`\mathcal S_K` 为所有历史中落在单元 :math:`K` 内的飞行段集合；
   第 :math:`s` 段持续 :math:`\tau_s`，速度为 :math:`(v_{r,s},v_{z,s})`。
   累计数组实际保存

   .. math::

      T_K=\sum_{s\in\mathcal S_K}\tau_s,\qquad
      M_{r,K}=\sum_{s\in\mathcal S_K}v_{r,s}\tau_s,\qquad
      M_{z,K}=\sum_{s\in\mathcal S_K}v_{z,s}\tau_s.

   同一历史多次返回单元时，每一段都计入。
   各段速度按其驻留时间加权。

   .. rubric:: 2. 驻留时间为什么能给出稳态粒子数

   设某类轨迹以粒子率 :math:`\dot w` 持续注入。
   在稳态下，年龄位于 :math:`[a,a+\mathrm da]` 的这类粒子数为
   :math:`\dot w\,\mathrm da`。只累计它位于单元 :math:`K` 的时间区间：

   .. math::

      N_K^{(h)}
         =\dot w\int_0^{t_{\mathrm{escape},h}}
               \boldsymbol1_K(\boldsymbol x_h(a))\,\mathrm da
         =\dot w\,T_K^{(h)}.

   :math:`a` 是单个粒子从注入起的年龄，
   :math:`\boldsymbol1_K` 在粒子位于该单元时为一，其余为零。
   对全部历史相加，得到单元平均密度

   .. math::

      n_K=\frac{N_K}{V_K}=\frac{\dot w T_K}{V_K}.

   单位链为 :math:`\mathrm{s^{-1}}\times\mathrm s/\mathrm{m^3}=\mathrm{m^{-3}}`。
   这里没有“总模拟时间”作为分母，因为入口供应率已包含在 :math:`\dot w` 中。
   增加样本数时 :math:`\dot w=Q_{\mathrm{in}}/N_{\mathrm{hist}}` 相应减小，
   不会让密度随样本数线性增加。

   .. rubric:: 3. 单元平均速度是驻留加权平均

   对单元内的粒子速度矩使用同一驻留权重：

   .. math::

      n_K\overline v_{r,K}=\frac{\dot w M_{r,K}}{V_K},\qquad
      n_K\overline v_{z,K}=\frac{\dot w M_{z,K}}{V_K}.

   除以密度后，粒子率和体积消去：

   .. math::

      \overline v_{r,K}=\frac{M_{r,K}}{T_K},\qquad
      \overline v_{z,K}=\frac{M_{z,K}}{T_K}.

   输出 ``velocity_r/velocity_z`` 是这两个平均量，不是某条粒子的 ``ur/uz``。
   未访问单元 :math:`T_K=0` 时，密度和两个速度都置零，以避免除零；
   这只表示没有统计样本，不能据此断定连续物理解严格为零。

   .. rubric:: 4. 面通量来自穿面次数

   对面 :math:`f`，记所有历史的正向、反向穿越次数为
   :math:`N_f^+,N_f^-`。一条历史可以反复穿越同一个面。
   有符号计数 :math:`C_f=N_f^+-N_f^-` 给出

   .. math::

      Q_f=\dot w C_f,\qquad \Gamma_f=\frac{\dot w C_f}{A_f}.

   :math:`Q_f` 是坐标正向粒子率，:math:`\Gamma_f` 是完整网格面上的平均通量。
   内部面分别写入 ``flux_r``、``flux_z``。
   开放边界只统计离开计算域的事件，写入 ``boundary_outflow_flux``：
   低端出射为负，高端出射为正。

   壁面反射没有净穿面，所以这里不生成壁面出流。
   轴线径向低端面积为零时，代码保留该面通量为零，不执行除零；
   这并不替代调用程序对轴线运动模型的判断。

   单元速度矩 :math:`n_K\overline v_K` 是体内平均，
   而 :math:`\Gamma_f` 是面上的穿越统计，两者位置和取样方式不同。
   不能先舍弃穿面计数，再用插值后的单元密度与均速替代原始面通量。

   .. rubric:: 5. 两个统计过程的输入与输出

   ``sub_J01_initialize_fm_tally(nr,nz,tally)``：

   - 输入正的空间单元数。
   - 输出分配并清零的 ``tally``；各字段和形状见 Module and Data。
   - 在整个历史循环前调用一次，无状态码返回。

   ``sub_J01_finalize_fm_tally``：

   - 输入 ``r_edge,z_edge,theta_span,active``、
     ``history_rate`` 和全部历史累加后的 ``tally``。
   - 输出并分配 ``density,velocity_r,velocity_z``，形状均为 ``(nr,nz)``。
   - 输出并分配 ``flux_r(nr-1,nz)``、``flux_z(nr,nz-1)``，
     以及 ``boundary_outflow_flux(4,nr,nz)``。
   - 密度单位 m⁻³，速度 m/s，通量 m⁻²s⁻¹；无效单元场值保持零。
   - ``tally`` 作为只读输入；该过程无 ``ierr`` 参数。
     调用者须保证数组形状、有效体积及所需面面积正确。
     规定入射通量由入口参数另行提供。

   该过程没有检查历史是否完整。主入口即使发现中断，也会生成部分统计场供排查；
   应用不能因为数组已经分配就将它当成合格结果。

   .. rubric:: 6. 粒子历史数与统计误差

   所有历史均正常逃逸时，总逃逸计数等于历史数，因此全域出射粒子率满足

   .. math::

      Q_{\mathrm{out}}=\dot w N_{\mathrm{hist}}=Q_{\mathrm{in}}
      \quad\text{（舍入误差除外）}.

   这不意味着每个单元的密度和每个面的通量已经精确。
   不同入口段被抽中的次数、慢粒子的长驻留和壁面随机速度都会造成局部统计波动。
   应根据场量随样本数和种子的变化判断统计是否充分，不能只看全域粒子率相等。

   后续若使用解析规定入流，各入口面的规定粒子率未必与有限样本的注入计数逐面完全相等。
   因此参考场继续用于连续性计算时，可能发生局部调整；
   这种差别与历史中断、符号错误或面积重复相乘应分开排查。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``sub_J01_fm_statistics.f90`` converts raw trajectory tallies into physical fields. The inlet supplies a
   particle rate :math:`\dot w` per history. The estimators combine it with residence times or crossing
   counts, then normalize by cell volume or face area.

   .. rubric:: 1. Histories, flight segments and cells

   Index histories by :math:`h`. Each encounter with a face ends a flight segment, so one history contains
   many segments. Let :math:`\mathcal S_K` contain all segments in cell :math:`K` from every history.
   Segment :math:`s` lasts :math:`\tau_s` and has velocity :math:`(v_{r,s},v_{z,s})`. The arrays store

   .. math::

      T_K=\sum_{s\in\mathcal S_K}\tau_s,\qquad
      M_{r,K}=\sum_{s\in\mathcal S_K}v_{r,s}\tau_s,\qquad
      M_{z,K}=\sum_{s\in\mathcal S_K}v_{z,s}\tau_s.

   Each return visit by the same history contributes another segment. Residence time weights each segment's
   velocity.

   .. rubric:: 2. From residence time to steady particle number

   Suppose trajectories of one type are continuously injected at rate :math:`\dot w`. At steady state,
   :math:`\dot w\,\mathrm da` particles of this type have ages in :math:`[a,a+\mathrm da]`. Accumulate only
   the age intervals spent in cell :math:`K`:

   .. math::

      N_K^{(h)}
         =\dot w\int_0^{t_{\mathrm{escape},h}}
               \boldsymbol1_K(\boldsymbol x_h(a))\,\mathrm da
         =\dot w\,T_K^{(h)}.

   :math:`a` is the particle's age since injection. The indicator :math:`\boldsymbol1_K` is one inside this
   cell and zero elsewhere. Summing over histories gives the cell-averaged density

   .. math::

      n_K=\frac{N_K}{V_K}=\frac{\dot w T_K}{V_K}.

   The units are :math:`\mathrm{s^{-1}}\times\mathrm s/\mathrm{m^3}=\mathrm{m^{-3}}`. The injection rate is
   already in :math:`\dot w`, so there is no total simulation time in the denominator. As the sample count
   grows, :math:`\dot w=Q_{\mathrm{in}}/N_{\mathrm{hist}}` decreases accordingly; the expected density
   remains fixed.

   .. rubric:: 3. Residence-weighted cell mean velocity

   Use the same residence weights for velocity moments in the cell:

   .. math::

      n_K\overline v_{r,K}=\frac{\dot w M_{r,K}}{V_K},\qquad
      n_K\overline v_{z,K}=\frac{\dot w M_{z,K}}{V_K}.

   Division by density cancels the particle rate and volume:

   .. math::

      \overline v_{r,K}=\frac{M_{r,K}}{T_K},\qquad
      \overline v_{z,K}=\frac{M_{z,K}}{T_K}.

   The outputs ``velocity_r/velocity_z`` hold these two cell averages; ``ur/uz`` is the velocity of an
   individual trajectory. An unvisited cell has :math:`T_K=0`, so density and both velocity outputs are set
   to zero to avoid division by zero. Such a cell has no samples from which to infer the continuum value.

   .. rubric:: 4. Face flux from crossing counts

   Let :math:`N_f^+,N_f^-` be the numbers of forward and reverse crossings of face :math:`f` over all
   histories. A single history may cross repeatedly. The signed count :math:`C_f=N_f^+-N_f^-` gives

   .. math::

      Q_f=\dot w C_f,\qquad \Gamma_f=\frac{\dot w C_f}{A_f}.

   :math:`Q_f` is the signed particle rate along the positive coordinate direction and :math:`\Gamma_f` the
   flux averaged over the full grid face. Internal fluxes go into ``flux_r`` and ``flux_z``. Only escaping
   events are tallied in ``boundary_outflow_flux``: outflow is negative at a lower face and positive at an
   upper face.

   A wall reflection has zero net crossings and generates no wall outflow. If the lower radial face on the
   axis has zero area, its flux stays zero to avoid division by zero. The application must still decide
   whether the axis motion model suits the problem.

   The cell velocity moment :math:`n_K\overline v_K` is a volume average; :math:`\Gamma_f` samples
   crossings at a face. Retain the crossing counts to obtain the original face flux. Interpolating cell
   density and mean velocity samples a different quantity.

   .. rubric:: 5. Inputs and outputs of the tally routines

   ``sub_J01_initialize_fm_tally(nr,nz,tally)``:

   - Supply positive cell counts in both spatial directions.
   - The output ``tally`` is allocated and zeroed. Module and Data lists its fields and shapes.
   - Call once before the entire history loop. The routine has no status return.

   ``sub_J01_finalize_fm_tally``:

   - Supply ``r_edge,z_edge,theta_span,active``, ``history_rate`` and the ``tally`` accumulated across all
     histories.
   - Allocate and return ``density,velocity_r,velocity_z``, each with shape ``(nr,nz)``.
   - Allocate and return ``flux_r(nr-1,nz)``, ``flux_z(nr,nz-1)`` and ``boundary_outflow_flux(4,nr,nz)``.
   - Density is in m⁻³, velocities in m/s and fluxes in m⁻² s⁻¹. Inactive-cell fields stay zero.
   - ``tally`` is read-only, and there is no ``ierr`` argument. The caller must supply compatible shapes
     and valid active volumes and face areas. The inlet parameters supply prescribed inflow separately.

   Finalization does not check history completion. The driver returns partial fields for diagnosis even
   after a truncation, so check the status before using allocated outputs.

   .. rubric:: 6. History count and statistical error

   When all histories escape normally, the total escape count equals the number of histories, and the
   global outgoing particle rate satisfies

   .. math::

      Q_{\mathrm{out}}=\dot w N_{\mathrm{hist}}=Q_{\mathrm{in}}
      \quad\text{(up to roundoff)}.

   Local density and face-flux estimates still fluctuate. Inlet-segment counts, long residence times of
   slow particles and random wall velocities all contribute. Assess sample adequacy by varying the history
   count and random seed, alongside checking global rate balance.

   With analytically prescribed inflow, the expected rate on each face can differ from its finite-sample
   injection count. The reference field may therefore adjust locally in a subsequent continuity solve.
   Check sampling differences separately from truncated histories, sign errors or applying a face area
   twice.
