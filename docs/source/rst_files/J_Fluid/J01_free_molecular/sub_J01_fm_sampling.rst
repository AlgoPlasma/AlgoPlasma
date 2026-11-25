Inlet Sampling
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J01_fm_sampling.f90`` 完成两件事：先确定入口的空间区域和总粒子率，
   再为每条历史抽取初始位置与速度。前一步只做一次，后一步调用多次。

   入口采样使用已穿过入口的粒子的速度概率分布。每条历史从该分布抽取初速度。

   .. rubric:: 1. 哪些位置可以注入

   入口位于网格第一排单元（:math:`k=1`）的轴向低端 :math:`z=z_1`。
   只有单元有效且该面被标为开放面时，才与用户给定半径范围
   :math:`[r_{\mathrm{in,lo}},r_{\mathrm{in,hi}}]` 求交：

   .. math::

      a_i=\max(r_i,r_{\mathrm{in,lo}}),\qquad
      b_i=\min(r_{i+1},r_{\mathrm{in,hi}}).

   若 :math:`b_i\le a_i`，该段没有入口面积；否则

   .. math::

      A_i=\int_{a_i}^{b_i}\Theta r\,\mathrm dr
          =\frac{\Theta}{2}(b_i^2-a_i^2),\qquad
      A_{\mathrm{in}}=\sum_i A_i.

   无效单元和非开放面对应 :math:`A_i=0`。
   入口可以跨越多个网格面；模块保存这些交集，不要求入口端点恰好落在网格边界上。

   这里的区间只限定注入位置，不改变 ``face_type``。
   例如一个面整体标为开放面，但只在其中间区域注入，粒子返回这个面的任意位置时仍会逃逸。
   若要求“中间开口、两侧反射”，应使网格与开口边缘对齐并分别标记，
   或另行扩展轨迹过程的面内判定；当前接口不会自动实现部分面反射。

   .. rubric:: 2. 均匀面积注入如何抽取位置

   均匀供气是每单位物理面积的入射粒子率相同，不是每单位半径相同。
   首先按 :math:`P(i)=A_i/A_{\mathrm{in}}` 选择入口段。
   代码抽取 :math:`\xi_1\in[0,1)`，在累计面积首次达到
   :math:`\xi_1 A_{\mathrm{in}}` 的非零段中注入。

   在已选段 :math:`[a_i,b_i]` 上，径向概率密度与累计概率分别为

   .. math::

      p_r(r\mid i)=\frac{2r}{b_i^2-a_i^2},\qquad
      F_r(r\mid i)=\frac{r^2-a_i^2}{b_i^2-a_i^2}.

   令 :math:`F_r=\xi_2`，反解得到

   .. math::

      r=\sqrt{a_i^2+\xi_2(b_i^2-a_i^2)}.

   所以程序均匀抽取的是 :math:`r^2`，而非 :math:`r`。
   轴向初始位置由调用者传入 ``z_start``；
   主过程取 :math:`z_1+\varepsilon_z`，将粒子放在域内一侧。

   .. rubric:: 3. 当前入口采用怎样的速度分布

   令粒子质量为 :math:`M`，入口温度参数为 :math:`T_{\mathrm{in}}`，
   轴向漂移为 :math:`U_z`，速度标准差为

   .. math::

      \sigma_{\mathrm{in}}=\sqrt{\frac{k_{\mathrm B}T_{\mathrm{in}}}{M}},
      \qquad k_{\mathrm B}=1.380649\times10^{-23}\,\mathrm{J\,K^{-1}}.

   径向没有漂移。程序独立生成标准正态随机数 :math:`Z_1,Z_2`，取

   .. math::

      v_r=\sigma_{\mathrm{in}}Z_1,\qquad
      v_z=U_z+\sigma_{\mathrm{in}}Z_2,
      \quad\text{仅接受 }v_z>0.

   轴向速度非正时只重抽轴向分量。这相当于在入射半平面使用归一化概率密度

   .. math::

      p_{\mathrm{in}}(v_r,v_z)=
      \frac{\exp[-(v_r^2+(v_z-U_z)^2)/(2\sigma_{\mathrm{in}}^2)]}
           {2\pi\sigma_{\mathrm{in}}^2\Phi(U_z/\sigma_{\mathrm{in}})}
           \,\boldsymbol 1_{v_z>0},

   .. math::

      \varphi(x)=\frac{e^{-x^2/2}}{\sqrt{2\pi}},\qquad
      \Phi(x)=\int_{-\infty}^{x}\varphi(y)\,\mathrm dy
             =\frac{1+\operatorname{erf}(x/\sqrt2)}{2}.

   :math:`\boldsymbol1_{v_z>0}` 表示只有正轴向速度有非零概率。
   分母中的 :math:`\Phi` 是未截断正态速度落在入射半平面的概率，用于条件分布归一化。

   这里直接对入射粒子使用截断正态分布，没有再乘 :math:`v_z`。
   若模型给定的是入口外侧气体的速度概率密度 :math:`g`，
   穿过入口的粒子应按 :math:`v_zg` 的相对概率抽样；这不是当前实现的模型。

   .. rubric:: 4. 每条历史为什么代表一个粒子率

   当前接口用 ``inlet_density``，即 :math:`n_{\mathrm{in}}`，规定供应强度。
   先求刚才那组入射粒子的平均轴向速度：

   .. math::

      \overline v_z^+
        =\int_{v_z>0}v_zp_{\mathrm{in}}\,\mathrm dv_r\,\mathrm dv_z
        =U_z+\sigma_{\mathrm{in}}
          \frac{\varphi(U_z/\sigma_{\mathrm{in}})}
               {\Phi(U_z/\sigma_{\mathrm{in}})}.

   由此按本接口约定定义

   .. math::

      J_{\mathrm{in}}=n_{\mathrm{in}}\overline v_z^+,\qquad
      Q_{\mathrm{in}}=A_{\mathrm{in}}J_{\mathrm{in}},\qquad
      \dot w=\frac{Q_{\mathrm{in}}}{N_{\mathrm{hist}}}.

   :math:`J_{\mathrm{in}}` 是单位面积入射通量，:math:`Q_{\mathrm{in}}` 是总粒子率，
   :math:`\dot w` 对应 ``history_rate``，单位为 :math:`\mathrm{s^{-1}}`。
   它不是一次时间步注入的粒子数。若应用先给定 :math:`Q_{\mathrm{in}}`，
   应使用上述关系反求输入 :math:`n_{\mathrm{in}}`。

   这个参数不等于边界分布积分后的实际气体密度。
   若将入射速度统计写成气体侧的分布函数，应有
   :math:`f_{\mathrm{in}}=J_{\mathrm{in}}p_{\mathrm{in}}/v_z`。
   接近切向的慢粒子可能有很长驻留时间，因此完整逃逸并不自动证明密度统计已充分收敛。

   .. rubric:: 5. 入口准备过程的输入与输出

   ``sub_J01_prepare_fm_inlet``：

   - 输入 ``r_edge``、``active``、``face_type``、``theta_span``，
     以及米为单位的 ``inlet_r_lo/inlet_r_hi``；尺寸见 Module and Data。
   - 输入 ``neutral_mass``（kg）、``inlet_temperature``（K）、
     ``inlet_drift_z``（m/s）、``inlet_density``（m⁻³）和正整数 ``n_histories``。
   - 输出 ``inlet``：分配分段数组，保存注入面积、区间及速度标准差。
   - 输出 ``history_rate`` 和 ``ierr``。没有可注入面积时返回配置错误；
     输入的正质量、正温度、正张角、非负供应强度和数组尺寸也在此检查。
   - 单独调用时仍须保证边界坐标单调、数值有限、面拓扑有效；这些检查并未全部在此重复。

   .. rubric:: 6. 采样与随机数过程的输入与输出

   ``sub_J01_sample_fm_inlet``：

   - 输入成功准备的 ``inlet``、``z_start`` 和与准备阶段相同的 ``inlet_drift_z``。
   - 输出四个标量 ``r,z,ur,uz``；后两个就是本页的 :math:`v_r,v_z`。
   - ``inlet`` 作为只读输入。该过程无 ``ierr`` 参数；调用前应完成入口准备，
     并保证采样位置位于计算域内。

   ``fun_J01_standard_normal`` 无显式输入，返回一个标准正态随机数。
   它采用 Box–Muller 变换：

   .. math::

      Z=\sqrt{-2\ln\xi_1}\cos(2\pi\xi_2).

   代码对进入对数的随机数取不小于 ``tiny(1.0)`` 的值，避免 :math:`\ln0`。
   ``sub_J01_set_random_seed(seed_value)`` 用整数种子设置运行时随机状态；
   它没有数值输出，也不保证不同编译器产生相同序列。

   大负漂移下 :math:`\Phi(U_z/\sigma_{\mathrm{in}})` 很小，拒绝采样会很慢，
   且平均速度公式可能受到消减误差影响。
   当前采样循环没有重抽次数上限，不宜把这一实现直接用于极端负漂移。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``sub_J01_fm_sampling.f90`` first determines the inlet area and total particle rate. For each history it
   then draws an initial position and velocity. Inlet preparation runs once and sampling runs once per
   history.

   The inlet velocity distribution describes particles that have crossed the inlet. Each history draws its
   initial velocity from that distribution.

   .. rubric:: 1. Locating the injection area

   Injection takes place at :math:`z=z_1`, the lower axial boundary of the first row of cells
   (:math:`k=1`). For each active cell with an open lower face, intersect the face with the prescribed
   radial range :math:`[r_{\mathrm{in,lo}},r_{\mathrm{in,hi}}]`:

   .. math::

      a_i=\max(r_i,r_{\mathrm{in,lo}}),\qquad
      b_i=\min(r_{i+1},r_{\mathrm{in,hi}}).

   If :math:`b_i\le a_i` the segment contributes no inlet area. Otherwise,

   .. math::

      A_i=\int_{a_i}^{b_i}\Theta r\,\mathrm dr
          =\frac{\Theta}{2}(b_i^2-a_i^2),\qquad
      A_{\mathrm{in}}=\sum_i A_i.

   Inactive cells and closed faces have :math:`A_i=0`. An inlet can span multiple faces. The module stores
   the intersections, so the inlet endpoints need not coincide with grid edges.

   The interval restricts injection position only; it does not change ``face_type``. If only the middle of
   an open face injects, a particle returning anywhere on that face still escapes. To model a central
   opening flanked by reflecting walls, align grid edges with the opening and label faces individually, or
   extend the tracker to resolve within-face boundaries.

   .. rubric:: 2. Sampling uniform injection per unit area

   Uniform supply gives equal incident rates per unit physical area. Select a segment with probability
   :math:`P(i)=A_i/A_{\mathrm{in}}`. The code draws :math:`\xi_1\in[0,1)` and selects the first nonzero
   segment whose cumulative area reaches :math:`\xi_1 A_{\mathrm{in}}`.

   On the selected interval :math:`[a_i,b_i]` the radial density and cumulative probability are

   .. math::

      p_r(r\mid i)=\frac{2r}{b_i^2-a_i^2},\qquad
      F_r(r\mid i)=\frac{r^2-a_i^2}{b_i^2-a_i^2}.

   Setting :math:`F_r=\xi_2` and inverting gives

   .. math::

      r=\sqrt{a_i^2+\xi_2(b_i^2-a_i^2)}.

   Thus :math:`r^2` is uniform, while :math:`r` has the density above. The caller supplies ``z_start``. The
   driver uses :math:`z_1+\varepsilon_z`, just inside the domain.

   .. rubric:: 3. Inlet velocity distribution

   For particle mass :math:`M`, inlet temperature parameter :math:`T_{\mathrm{in}}` and axial drift
   :math:`U_z`, the velocity standard deviation is

   .. math::

      \sigma_{\mathrm{in}}=\sqrt{\frac{k_{\mathrm B}T_{\mathrm{in}}}{M}},
      \qquad k_{\mathrm B}=1.380649\times10^{-23}\,\mathrm{J\,K^{-1}}.

   There is no radial drift. Draw independent standard normal variates :math:`Z_1,Z_2` and set

   .. math::

      v_r=\sigma_{\mathrm{in}}Z_1,\qquad
      v_z=U_z+\sigma_{\mathrm{in}}Z_2,
      \quad\text{accept only }v_z>0.

   If the axial velocity is nonpositive, redraw only that component. This procedure samples the normalized
   density on the incident half-plane,

   .. math::

      p_{\mathrm{in}}(v_r,v_z)=
      \frac{\exp[-(v_r^2+(v_z-U_z)^2)/(2\sigma_{\mathrm{in}}^2)]}
           {2\pi\sigma_{\mathrm{in}}^2\Phi(U_z/\sigma_{\mathrm{in}})}
           \,\boldsymbol 1_{v_z>0},

   .. math::

      \varphi(x)=\frac{e^{-x^2/2}}{\sqrt{2\pi}},\qquad
      \Phi(x)=\int_{-\infty}^{x}\varphi(y)\,\mathrm dy
             =\frac{1+\operatorname{erf}(x/\sqrt2)}{2}.

   The indicator :math:`\boldsymbol1_{v_z>0}` restricts the density to positive axial velocities. The
   denominator :math:`\Phi` is the probability that the untruncated Gaussian falls in the incident
   half-plane, so division by it normalizes the conditional distribution.

   J01 samples the truncated normal distribution of incident particles directly, without an additional
   :math:`v_z` weight. If the supplied distribution :math:`g` instead described the gas outside the inlet,
   crossings would have relative probability :math:`v_zg`.

   .. rubric:: 4. Particle rate represented by one history

   The interface sets the supply strength through ``inlet_density``, denoted :math:`n_{\mathrm{in}}`. First
   calculate the mean axial velocity of the incoming particles:

   .. math::

      \overline v_z^+
        =\int_{v_z>0}v_zp_{\mathrm{in}}\,\mathrm dv_r\,\mathrm dv_z
        =U_z+\sigma_{\mathrm{in}}
          \frac{\varphi(U_z/\sigma_{\mathrm{in}})}
               {\Phi(U_z/\sigma_{\mathrm{in}})}.

   The interface then defines

   .. math::

      J_{\mathrm{in}}=n_{\mathrm{in}}\overline v_z^+,\qquad
      Q_{\mathrm{in}}=A_{\mathrm{in}}J_{\mathrm{in}},\qquad
      \dot w=\frac{Q_{\mathrm{in}}}{N_{\mathrm{hist}}}.

   :math:`J_{\mathrm{in}}` is incident flux per unit area, :math:`Q_{\mathrm{in}}` is the total particle
   rate and :math:`\dot w` is returned as ``history_rate`` in :math:`\mathrm{s^{-1}}`. The weight is a
   rate. If the application specifies :math:`Q_{\mathrm{in}}` first, invert these relations to obtain the
   input :math:`n_{\mathrm{in}}`.

   The supply parameter differs from the gas density obtained by integrating a boundary distribution. The
   gas-side distribution corresponding to these incoming-particle statistics is
   :math:`f_{\mathrm{in}}=J_{\mathrm{in}}p_{\mathrm{in}}/v_z`. Near-grazing, slow particles can have long
   residence times, so even if all histories escape the density estimate may need more samples.

   .. rubric:: 5. Inputs and outputs of inlet preparation

   ``sub_J01_prepare_fm_inlet``:

   - Supply ``r_edge``, ``active``, ``face_type``, ``theta_span`` and the radius bounds
     ``inlet_r_lo/inlet_r_hi`` in metres. See Module and Data for array shapes.
   - Supply ``neutral_mass`` (kg), ``inlet_temperature`` (K), ``inlet_drift_z`` (m/s), ``inlet_density``
     (m⁻³) and a positive integer ``n_histories``.
   - The routine allocates the segment arrays in ``inlet`` and stores inlet areas, radial intervals and the
     velocity standard deviation.
   - It returns ``history_rate`` and ``ierr``. Zero available injection area is a configuration error. The
     routine also checks positive mass, temperature and angular span, nonnegative supply strength and array
     shapes.
   - Direct callers must also provide increasing edges, finite inputs and valid face connectivity. The
     routine does not repeat all driver checks.

   .. rubric:: 6. Sampling and random-number routines

   ``sub_J01_sample_fm_inlet``:

   - Supply the prepared ``inlet``, ``z_start`` and the same ``inlet_drift_z`` used during preparation.
   - The four scalar outputs are ``r,z,ur,uz``; the last two are the components :math:`v_r,v_z` used here.
   - ``inlet`` is read-only. There is no ``ierr`` argument. Complete the preparation first and ensure the
     initial position lies inside the domain.

   ``fun_J01_standard_normal`` takes no explicit arguments and returns one standard normal variate using
   the Box–Muller transform:

   .. math::

      Z=\sqrt{-2\ln\xi_1}\cos(2\pi\xi_2).

   The logarithm argument is bounded below by ``tiny(1.0)`` to avoid :math:`\ln0`.
   ``sub_J01_set_random_seed(seed_value)`` sets the runtime random state from an integer seed and has no
   numerical output. Different compilers can produce different sequences.

   For a large negative drift, :math:`\Phi(U_z/\sigma_{\mathrm{in}})` is small. Rejection sampling is then
   slow and the mean velocity formula is susceptible to cancellation. The sampler has no retry limit and is
   unsuitable for extreme negative drift.
