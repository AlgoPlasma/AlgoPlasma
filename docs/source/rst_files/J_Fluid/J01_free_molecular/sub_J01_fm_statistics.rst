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

   The tally stores sums over every trajectory segment inside a cell:

   .. math::

      T_K=\sum_s\tau_s,\quad M_{r,K}=\sum_s v_{r,s}\tau_s,\quad
      M_{z,K}=\sum_s v_{z,s}\tau_s.

   A history represents an injection rate dot w. Integrating the particle age over time spent in K
   gives inventory dot w times residence, hence

   .. math::

      n_K=\dot w T_K/V_K,\qquad
      \overline v_{r,K}=M_{r,K}/T_K,\qquad
      \overline v_{z,K}=M_{z,K}/T_K.

   No global simulation-time denominator is needed.
   An unvisited cell returns zero density and velocity, which means no samples, not proven zero physical density.

   Signed crossings yield independent face estimators:

   .. math::

      \Gamma_f=\dot w(N_f^+-N_f^-)/A_f.

   Internal and outgoing-boundary fluxes use full physical face areas and coordinate signs.
   They must not be replaced with cell density times mean velocity.

   ``sub_J01_initialize_fm_tally`` allocates and zeros the arrays once.
   ``sub_J01_finalize_fm_tally`` reads geometry, active mask, history_rate and tallies;
   it allocates density/velocities (nr,nz), internal fluxes (nr-1,nz)/(nr,nz-1),
   and outgoing boundary fluxes (4,nr,nz), without an ierr or completeness check.
   It does not generate prescribed inflow.

   Complete histories imply total escape rate equals total injection rate.
   Local fields still have statistical error, and analytic per-face prescribed inflow can differ
   from a finite sample's per-face injection counts.
