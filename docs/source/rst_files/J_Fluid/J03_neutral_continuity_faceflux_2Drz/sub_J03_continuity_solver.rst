.. J_Fluid contribution history (Git author dates; edit times include timezone).
   2026-09-18 12:00 +08:00 | Yingjie Chen | git 69bdc8603906
   2026-10-06 23:50 +08:00 | Yingjie Chen | git fa8cb9f5be05
   2026-11-25 15:14 +08:00 | Yingjie Chen | git 8652258184b5
   2026-11-25 15:59 +08:00 | Yingjie Chen | edit (Codex-assisted)

Time Advance and Diagnostics
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J03_continuity_solver.f90`` 使用上一页建立的 ``closure`` 计算当前通量，
   完成一次密度更新，并提供收支、残差及稳态辅助过程。
   下面按“取面通量—写单元收支—离散时间—选择时间步—检查结果”的顺序说明。

   单元记为 :math:`K=(i,k)`，物理时间层为 :math:`q`，
   即 :math:`n_K^q=n_K(t_q)`、:math:`t_{q+1}=t_q+\Delta t`。
   一个时间步内使用给定的 :math:`S_K^q,\nu_K^q` 和边界入流。

   .. rubric:: 1. 用当前密度求四个面的通量

   内部面从低索引单元 L 指向高索引单元 R。
   上一页得到的系数 :math:`u_f` 固定，当前通量为

   .. math::

      \Gamma_f^q=
      \begin{cases}
         u_f n_L^q,&u_f\ge0,\\
         u_f n_R^q,&u_f<0.
      \end{cases}

   同一面两侧读取相同系数和相同迎风密度，因此得到相同的坐标向通量。
   开放面与壁面分别使用

   .. math::

      \Gamma_b^q=\Gamma_{b,\mathrm{in}}^q+u_{b,\mathrm{out}}n_K^q,
      \qquad \Gamma_{\mathrm{wall}}^q=0.

   ``sub_J03_cell_fluxes`` 输入 ``closure``、当前 ``density`` 和合法单元索引 ``i,k``，
   输出 ``frlo,frhi,fzlo,fzhi`` 四个实数通量，按径向低/高、轴向低/高排列。
   该过程不更新密度、不乘面面积，也不返回错误码；有效邻居和尺寸由上层保证。

   .. rubric:: 2. 从粒子数守恒得到单元方程

   将连续性方程在固定单元内积分，单元粒子数为 :math:`V_Kn_K`。
   体积与面积由调用者传入。对边界为 :math:`r_i,r_{i+1},z_k,z_{k+1}`、
   周向张角为 :math:`\Theta` 的柱坐标单元，它们为

   .. math::

      V_K=\frac{\Theta}{2}(r_{i+1}^2-r_i^2)\Delta z_k,\quad
      A_{r-}=\Theta r_i\Delta z_k,\quad A_{r+}=\Theta r_{i+1}\Delta z_k,\quad
      A_{z\pm}=\frac{\Theta}{2}(r_{i+1}^2-r_i^2).

   :math:`\Delta z_k=z_{k+1}-z_k`；这些量已经包含对周向的积分。
   用面平均通量和单元平均源损，得到

   .. math::

      V_K\frac{\mathrm dn_K}{\mathrm dt}
         =-Q_K^{\mathrm{net}}+V_KS_K-V_K\nu_Kn_K,

   .. math::

      Q_K^{\mathrm{net}}
         =A_{r+}\Gamma_{r+}-A_{r-}\Gamma_{r-}
          +A_{z+}\Gamma_{z+}-A_{z-}\Gamma_{z-},\qquad
      D_K(n)=\frac{Q_K^{\mathrm{net}}(n)}{V_K}.

   :math:`Q_K^{\mathrm{net}}` 对应源码中的 ``net``，单位是粒子率 s⁻¹；
   :math:`D_K` 是密度变化率 m⁻³s⁻¹。
   径向几何效应已经包含在体积和面面积中，不需再在更新式里额外乘或除一次 :math:`r`。

   .. rubric:: 3. 显式输运与半隐式线性损失

   本步的输运和体产生使用已知数据，线性损失使用新密度：

   .. math::

      \frac{n_K^{q+1}-n_K^q}{\Delta t}
         =-D_K(n^q)+S_K^q-\nu_K^q n_K^{q+1}.

   把未知损失项移到左侧即可得到代码中的更新：

   .. math::

      n_K^{q+1}
         =\frac{n_K^q-\Delta t D_K(n^q)+\Delta t S_K^q}
                {1+\Delta t\nu_K^q}.

   分母来自时间离散，不是经验衰减因子。
   这里只有逐单元除法，不需要解全局隐式输运方程。
   无输运、无产生且损失恒定时，
   :math:`n^{q+1}=n^q/(1+\Delta t\nu)`；
   它近似连续解 :math:`n(t)=n(0)e^{-\nu t}`，不是有限时间步上的精确指数更新。

   .. rubric:: 4. 正密度条件与时间步

   在非负初态、非负源项和方向正确的边界数据下，
   可以把单元的显式输运写成

   .. math::

      n_K^{q+1}
       =\frac{(1-\Delta t\,a_K)n_K^q
              +\Delta t\sum_{L\ \mathrm{upstream}}b_{KL}n_L^q
              +\Delta t I_K^q+\Delta t S_K^q}
             {1+\Delta t\nu_K^q}.

   其中 :math:`a_K\ge0` 是本单元密度对应的总流出系数，
   :math:`b_{KL}\ge0` 是上游输入系数，
   :math:`I_K^q\ge0` 是规定边界入流除以体积后的贡献。
   若 :math:`\Delta t\,a_K\le1`，分子各项均非负。

   为给出保守步长，``sub_J03_compute_stable_timestep`` 采用
   Courant–Friedrichs–Lewy（CFL）系数 :math:`c_{\mathrm{CFL}}\in(0,1]`，计算

   .. math::

      \lambda_K=\nu_K+
          \frac{\displaystyle\sum_{f\in\mathrm{INTERIOR}}A_f|u_f|
                +\displaystyle\sum_{f\in\mathrm{OPEN}}A_f|u_{b,\mathrm{out}}|}
               {V_K},
      \qquad
      \Delta t_{\mathrm{stable}}
         =\frac{c_{\mathrm{CFL}}}{\max_{K\ \mathrm{active}}\lambda_K}.

   这里把所有内部面的绝对速度都计入，而不只是本单元的出流面，所以
   :math:`\lambda_K\ge a_K`。线性损失虽已半隐式处理，代码仍将它加入步长限制；
   这是当前实现的保守选择，不是说这一损失项本身要求显式稳定条件。

   固定入流不随本单元密度增加，不作为流出系数计入。
   若最大速率不大于 ``tiny(1.0)``，程序返回 1 秒作为缺省值。
   应用仍需结合物理变化、输出时刻及耦合程序选择更小步长。

   过程输入为已初始化的 ``closure`` 和 ``cfl``；
   输出 ``dt`` （s）与 ``ierr``。它检查 CFL 范围，不重新验收所有闭合数据。

   .. rubric:: 5. 单步过程的参数与实际返回行为

   ``sub_J03_continuity_step``：

   - 输入 ``closure``、``density(nr,nz)``、非负
     ``source_rate(nr,nz)`` 和正时间步 ``dt``。
   - 输入逻辑参数 ``clip_negative``，决定是否将负更新值截为零。
   - 输出并分配 ``density_new(nr,nz)``，无效单元置零；旧密度不修改。
   - 输出 ``ierr``；检查数组形状、正时间步、非负源项。
     关闭截断时还拒绝负输入密度。

   单步过程不会自动调用步长计算，也不会因本步产生负值而自动报错。
   因此在关闭截断时，即使返回成功，过大时间步仍可能产生负输出。
   调用者应先选稳定时间步，再检查输出的有限性和非负性。

   开启截断只在更新式算完后执行
   :math:`n_K^{q+1}=\max(n_K^*,0)`。
   由此额外增加的粒子数为

   .. math::

      \Delta N_{\mathrm{clip}}
         =\sum_{K\ \mathrm{active}}V_K\max(-n_K^*,0).

   所以截断不是守恒修复，也不能替代前面的步长与数据条件。
   代码不单独返回这个修正量；需要守恒验收时，通常关闭截断并排查负值原因。

   .. rubric:: 6. 瞬态总量收支怎样检查

   令总粒子数 :math:`N^q=\sum_K V_Kn_K^q`。
   把所有单元更新式乘体积后相加，内部面抵消，未作负值截断时有

   .. math::

      \frac{N^{q+1}-N^q}{\Delta t}
         =Q_{\mathrm{in}}^q+Q_{\mathrm{src}}^q
          -Q_{\mathrm{out}}(n^q)-Q_{\mathrm{loss}}^q(n^{q+1}).

   特别注意右端的时间层：出流使用旧密度，损失使用新密度。
   这是检验当前半隐式离散的收支关系。
   不能用同一时刻的四个粒子率简单代替右端，也不能在瞬态中要求流入与流出相等。

   ``sub_J03_compute_balance`` 对给定的一份密度计算

   .. math::

      \begin{aligned}
      Q_{\mathrm{in}}&=-\sum_{\mathrm{OPEN}}s_f A_f\Gamma_{b,\mathrm{in}},\\
      Q_{\mathrm{out}}(n)&=\sum_{\mathrm{OPEN}}s_f A_fu_{b,\mathrm{out}}n_K,\\
      Q_{\mathrm{src}}&=\sum_KV_KS_K,\qquad
      Q_{\mathrm{loss}}(n)=\sum_KV_K\nu_Kn_K,
      \end{aligned}
      \qquad s_f=(-1,+1,-1,+1).

   过程输入 ``closure,density,source_rate``，
   输出 ``inflow,outflow,production,removal``，单位均为 s⁻¹，
   以及无量纲 ``relative_balance`` 和 ``ierr``。
   它检查形状，不完成全部物理输入验证。

   检验单步时，可在保持同一组本步源损与边界参数的条件下，
   用旧密度取得 ``outflow``，用新密度取得 ``removal``，
   再与粒子总数变化比较。

   其额外返回的相对失衡是

   .. math::

      E_B=\frac{|Q_{\mathrm{out}}+Q_{\mathrm{loss}}
                       -Q_{\mathrm{in}}-Q_{\mathrm{src}}|}
              {\max(|Q_{\mathrm{in}}|+|Q_{\mathrm{src}}|,
                    |Q_{\mathrm{out}}|+|Q_{\mathrm{loss}}|,
                    \operatorname{tiny}(1.0))}.

   这是同一密度下的稳态收支指标。在瞬态过程中，:math:`E_B` 非零可以只是说明总粒子数正在变化。

   .. rubric:: 7. 局部残差与全局失衡不是一回事

   把稳态方程的左端记为

   .. math::

      R_K(n)=D_K(n)+\nu_K n_K-S_K.

   ``sub_J03_compute_residual`` 输入 ``closure,density,source_rate``，
   输出并分配 ``residual(nr,nz)``，同时返回

   .. math::

      R_{\max}=\max_{K\ \mathrm{active}}|R_K|,
      \qquad B=\sum_{K\ \mathrm{active}}V_KR_K.

   ``max_abs_residual`` 的单位为 m⁻³s⁻¹；
   ``global_balance`` 即 :math:`B`，单位为 s⁻¹。
   无效单元残差为零，过程还返回尺寸检查状态 ``ierr``。

   对合法内部面，:math:`B=Q_{\mathrm{out}}+Q_{\mathrm{loss}}-Q_{\mathrm{in}}-Q_{\mathrm{src}}`。
   不同单元的正负残差可能抵消，所以全局失衡小并不保证各处接近稳态。
   瞬态物理解也不要求 :math:`R_K=0`；
   在连续时间方程中它对应 :math:`-\mathrm dn_K/\mathrm dt`。

   .. rubric:: 8. 稳态辅助求解采用什么停止条件

   ``sub_J03_solve_steady`` 只用于固定源损与固定边界的问题。
   它以 ``closure%density_ref`` 为初态，只计算一次步长，
   之后反复调用同一个单步过程。
   第 :math:`j` 次迭代检查密度相对变化

   .. math::

      E_n^{j+1}=
        \frac{\sum_{K\ \mathrm{active}}|n_K^{j+1}-n_K^j|}
             {\max(\sum_{K\ \mathrm{active}}|n_K^j|,
                   \operatorname{tiny}(1.0))}.

   仅检查变化量不够：很小的步长也会让更新很小，而方程仍未平衡。
   因此每步同时计算当前残差，并用固定尺度归一化。

   ``sub_J03_reference_residual_scale`` 输入闭合和体源，
   在迭代开始前按参考密度生成各面的实际闭合通量，取

   .. math::

      R_{\mathrm{scale}}=
        \max\!\left[
          \operatorname{tiny}(1.0),
          \max_{K\ \mathrm{active}}\left\{
             \frac{\sum_f A_f|\Gamma_f(n^{\mathrm{ref}})|}{V_K}
             +|S_K|+\nu_K|n_K^{\mathrm{ref}}|
          \right\}\right].

   这里用的是 :math:`\Gamma_f(n^{\mathrm{ref}})`，
   不是无条件照抄原始参考通量；密度下限生效时两者可能不同。
   过程输出标量 ``scale`` （m⁻³s⁻¹），不返回错误码，要求输入已经验证。
   它不依赖当前迭代密度或时间步，因此不会随迭代变化一起缩小。

   归一化残差为 :math:`E_R=R_{\max}/R_{\mathrm{scale}}`。
   只有同时满足

   .. math::

      E_n\le\text{tolerance},\qquad
      E_R\le\text{residual\_tolerance}

   才返回收敛。总量指标 :math:`E_B` 可辅助解释结果，但不替代局部最大残差。

   .. rubric:: 9. 稳态过程的输入、输出与失败

   ``sub_J03_solve_steady`` 的输入：

   - ``closure``、固定的 ``source_rate(nr,nz)``；
   - ``cfl``、正的 ``tolerance``、正整数 ``max_iterations``；
   - ``clip_negative``；
   - 可选非负 ``progress_interval``：零或省略关闭日志，正值控制迭代报告间隔；
   - 可选正的 ``residual_tolerance``；
     省略时使用 :math:`\max(\text{tolerance},100\,\operatorname{epsilon}(1.0))`。

   输出：

   - 分配的 ``density``：成功或达到上限时保留最后完整迭代密度；
   - ``converged``、``iterations``、``final_relative_change``；
   - ``max_abs_residual``、``global_balance``；
   - 可选 ``final_scaled_residual``；
   - ``ierr``：达到上限仍不收敛时为 ``J03_ERR_NOT_CONVERGED``。

   该接口不接收任意初始场，也不返回物理终止时刻。
   研究指定初态的瞬态过程，应在外层组织单步循环，而不是调用此入口后把迭代步数当成物理结果。
   收敛只表示当前离散闭合方程已近似满足，不证明参考输运模型或空间、时间分辨率已经足够。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``sub_J03_continuity_solver.f90`` uses the ``closure`` built on the preceding page to evaluate current
   fluxes, advance density by one time step and calculate balance, residuals and an optional steady
   solution. The derivation proceeds from face fluxes and cell conservation through time discretization and
   step selection to diagnostics.

   Write :math:`K=(i,k)` for a cell and :math:`q` for the time level, with :math:`n_K^q=n_K(t_q)` and
   :math:`t_{q+1}=t_q+\Delta t`. The volume source and loss :math:`S_K^q,\nu_K^q` and the prescribed
   boundary inflow are held fixed over one step.

   .. rubric:: 1. Fluxes on the four faces at current density

   An internal face points from the lower-index cell L to the higher-index cell R. With fixed face
   coefficient :math:`u_f` from the closure, the current flux is

   .. math::

      \Gamma_f^q=
      \begin{cases}
         u_f n_L^q,&u_f\ge0,\\
         u_f n_R^q,&u_f<0.
      \end{cases}

   Both cells read the same coefficient and upwind density, so they agree on the signed
   coordinate-direction flux. Open faces and walls use

   .. math::

      \Gamma_b^q=\Gamma_{b,\mathrm{in}}^q+u_{b,\mathrm{out}}n_K^q,
      \qquad \Gamma_{\mathrm{wall}}^q=0.

   ``sub_J03_cell_fluxes`` takes ``closure``, current ``density`` and valid indices ``i,k``. It returns
   four real fluxes ``frlo,frhi,fzlo,fzhi`` in the order lower radial, upper radial, lower axial, upper
   axial. It does not advance density, apply face area or return an error code. The caller must provide
   valid shapes and neighbours.

   .. rubric:: 2. The cell equation from particle conservation

   Integrate the continuity equation over the fixed cell. Its particle number is :math:`V_Kn_K`. The caller
   supplies the volume and areas. For a cylindrical cell with edges :math:`r_i,r_{i+1},z_k,z_{k+1}` and
   angular span :math:`\Theta` they are

   .. math::

      V_K=\frac{\Theta}{2}(r_{i+1}^2-r_i^2)\Delta z_k,\quad
      A_{r-}=\Theta r_i\Delta z_k,\quad A_{r+}=\Theta r_{i+1}\Delta z_k,\quad
      A_{z\pm}=\frac{\Theta}{2}(r_{i+1}^2-r_i^2).

   Here :math:`\Delta z_k=z_{k+1}-z_k`. These measures already include azimuthal integration. With
   face-averaged flux and cell-averaged production and loss,

   .. math::

      V_K\frac{\mathrm dn_K}{\mathrm dt}
         =-Q_K^{\mathrm{net}}+V_KS_K-V_K\nu_Kn_K,

   .. math::

      Q_K^{\mathrm{net}}
         =A_{r+}\Gamma_{r+}-A_{r-}\Gamma_{r-}
          +A_{z+}\Gamma_{z+}-A_{z-}\Gamma_{z-},\qquad
      D_K(n)=\frac{Q_K^{\mathrm{net}}(n)}{V_K}.

   :math:`Q_K^{\mathrm{net}}` is the particle rate in s⁻¹ stored in ``net``. :math:`D_K` is the density
   change rate in m⁻³ s⁻¹. Volumes and face areas account for the radial geometry; apply no additional
   factor of :math:`r` in the update.

   .. rubric:: 3. Explicit transport and semi-implicit linear loss

   Transport and production use known values from this step, while linear loss uses the new density:

   .. math::

      \frac{n_K^{q+1}-n_K^q}{\Delta t}
         =-D_K(n^q)+S_K^q-\nu_K^q n_K^{q+1}.

   Move the unknown loss term to the left to obtain the implemented update:

   .. math::

      n_K^{q+1}
         =\frac{n_K^q-\Delta t D_K(n^q)+\Delta t S_K^q}
                {1+\Delta t\nu_K^q}.

   Time discretization gives the denominator. Each cell requires only a scalar division. With no transport
   or production and constant loss, :math:`n^{q+1}=n^q/(1+\Delta t\nu)` approximates the continuous decay
   :math:`n(t)=n(0)e^{-\nu t}`; finite steps do not integrate the exponential exactly.

   .. rubric:: 4. Nonnegative density and the stable time step

   With nonnegative initial density and sources and correctly oriented boundary data, the explicit
   transport part in one cell can be written as

   .. math::

      n_K^{q+1}
       =\frac{(1-\Delta t\,a_K)n_K^q
              +\Delta t\sum_{L\ \mathrm{upstream}}b_{KL}n_L^q
              +\Delta t I_K^q+\Delta t S_K^q}
             {1+\Delta t\nu_K^q}.

   Here :math:`a_K\ge0` is the total outflow coefficient multiplying the cell density, :math:`b_{KL}\ge0`
   the upstream inflow coefficients and :math:`I_K^q\ge0` the prescribed boundary contribution per unit
   volume. All numerator contributions are nonnegative if :math:`\Delta t\,a_K\le1`.

   For a conservative bound, ``sub_J03_compute_stable_timestep`` takes the Courant–Friedrichs–Lewy factor
   :math:`c_{\mathrm{CFL}}\in(0,1]` and computes

   .. math::

      \lambda_K=\nu_K+
          \frac{\displaystyle\sum_{f\in\mathrm{INTERIOR}}A_f|u_f|
                +\displaystyle\sum_{f\in\mathrm{OPEN}}A_f|u_{b,\mathrm{out}}|}
               {V_K},
      \qquad
      \Delta t_{\mathrm{stable}}
         =\frac{c_{\mathrm{CFL}}}{\max_{K\ \mathrm{active}}\lambda_K}.

   This bound counts absolute velocities at all internal faces, including inflow, so
   :math:`\lambda_K\ge a_K`. The implementation also counts the linear loss frequency even though the time
   integration treats loss semi-implicitly. This makes the time-step choice conservative.

   Prescribed inflow is independent of the cell density and contributes no outflow coefficient. If the
   maximum rate is at most ``tiny(1.0)`` the routine returns a default of 1 s. Physical time scales,
   requested output times and model coupling may require a smaller step.

   Supply initialized ``closure`` and ``cfl``. The routine returns ``dt`` in seconds and ``ierr``. It
   validates the CFL range but assumes the underlying closure data are valid.

   .. rubric:: 5. Single-step arguments and return behaviour

   ``sub_J03_continuity_step``:

   - Supply ``closure``, ``density(nr,nz)``, nonnegative ``source_rate(nr,nz)`` and positive ``dt``.
   - The logical option ``clip_negative`` selects whether to clip negative updated values to zero.
   - The output ``density_new(nr,nz)`` is allocated, with zero in inactive cells. The old density is left
     available to the caller.
   - The output ``ierr`` reports incompatible shapes, nonpositive time step and negative source. Negative
     input density is also rejected when clipping is off.

   The step routine does not calculate the stable time step or automatically report a negative output. With
   clipping off, too large a step can therefore return successfully with negative densities. Select a
   stable step first and check the output for nonnegativity and finiteness.

   With clipping on, :math:`n_K^{q+1}=\max(n_K^*,0)` is applied after the update. The added particle number is

   .. math::

      \Delta N_{\mathrm{clip}}
         =\sum_{K\ \mathrm{active}}V_K\max(-n_K^*,0).

   Clipping changes the particle balance and cannot replace suitable time steps and valid input data. The
   code does not return this correction separately. For conservation checks, normally disable clipping and
   diagnose the cause of negative values.

   .. rubric:: 6. Checking the transient particle balance

   Let the total particle number be :math:`N^q=\sum_K V_Kn_K^q`. Multiply every cell update by its volume
   and sum. Internal face contributions cancel, giving the following relation when negative densities have
   not been clipped:

   .. math::

      \frac{N^{q+1}-N^q}{\Delta t}
         =Q_{\mathrm{in}}^q+Q_{\mathrm{src}}^q
          -Q_{\mathrm{out}}(n^q)-Q_{\mathrm{loss}}^q(n^{q+1}).

   Use the stated time levels: outflow uses old density and loss uses new density. Four rates computed at
   just one time level cannot in general test this semi-implicit step. Inflow and outflow can differ during
   a transient.

   For one supplied density, ``sub_J03_compute_balance`` computes

   .. math::

      \begin{aligned}
      Q_{\mathrm{in}}&=-\sum_{\mathrm{OPEN}}s_f A_f\Gamma_{b,\mathrm{in}},\\
      Q_{\mathrm{out}}(n)&=\sum_{\mathrm{OPEN}}s_f A_fu_{b,\mathrm{out}}n_K,\\
      Q_{\mathrm{src}}&=\sum_KV_KS_K,\qquad
      Q_{\mathrm{loss}}(n)=\sum_KV_K\nu_Kn_K,
      \end{aligned}
      \qquad s_f=(-1,+1,-1,+1).

   With inputs ``closure,density,source_rate`` the routine returns ``inflow,outflow,production,removal`` in
   s⁻¹, dimensionless ``relative_balance`` and status ``ierr``. It checks shapes and relies on the caller
   for physical input validation.

   To test a step, hold its source, loss and boundary inputs fixed. Obtain ``outflow`` from the old density
   and ``removal`` from the new density, then compare the resulting balance with the measured change in
   total particle number.

   The routine also returns the relative imbalance

   .. math::

      E_B=\frac{|Q_{\mathrm{out}}+Q_{\mathrm{loss}}
                       -Q_{\mathrm{in}}-Q_{\mathrm{src}}|}
              {\max(|Q_{\mathrm{in}}|+|Q_{\mathrm{src}}|,
                    |Q_{\mathrm{out}}|+|Q_{\mathrm{loss}}|,
                    \operatorname{tiny}(1.0))}.

   This measures steady particle balance at one density. During a transient a nonzero :math:`E_B` can
   simply reflect a changing total particle number.

   .. rubric:: 7. Local residuals and global imbalance

   Write the left-hand side of the steady equation as

   .. math::

      R_K(n)=D_K(n)+\nu_K n_K-S_K.

   ``sub_J03_compute_residual`` takes ``closure,density,source_rate``, allocates ``residual(nr,nz)`` and
   also returns

   .. math::

      R_{\max}=\max_{K\ \mathrm{active}}|R_K|,
      \qquad B=\sum_{K\ \mathrm{active}}V_KR_K.

   ``max_abs_residual`` is in m⁻³ s⁻¹. ``global_balance`` gives :math:`B` in s⁻¹. Inactive cells have zero
   residual. ``ierr`` reports the shape check.

   With valid internal faces,
   :math:`B=Q_{\mathrm{out}}+Q_{\mathrm{loss}}-Q_{\mathrm{in}}-Q_{\mathrm{src}}`. Local residuals of
   opposite signs can cancel even when individual cells remain far from steady. A transient solution need
   not have :math:`R_K=0`; in continuous time the residual is :math:`-\mathrm dn_K/\mathrm dt`.

   .. rubric:: 8. Stopping conditions for the steady solver

   ``sub_J03_solve_steady`` applies to fixed sources, losses and boundary conditions. It starts from
   ``closure%density_ref``, computes a time step once and repeatedly calls the same step routine. At
   iteration :math:`j` the relative change in density is

   .. math::

      E_n^{j+1}=
        \frac{\sum_{K\ \mathrm{active}}|n_K^{j+1}-n_K^j|}
             {\max(\sum_{K\ \mathrm{active}}|n_K^j|,
                   \operatorname{tiny}(1.0))}.

   A small time step can make this change small even when the equation remains unbalanced. Each iteration
   therefore also computes the current residual and normalizes it against a fixed scale.

   ``sub_J03_reference_residual_scale`` takes the closure and volume source. Before iteration, it evaluates
   the face fluxes produced by applying the closure to the reference density and sets

   .. math::

      R_{\mathrm{scale}}=
        \max\!\left[
          \operatorname{tiny}(1.0),
          \max_{K\ \mathrm{active}}\left\{
             \frac{\sum_f A_f|\Gamma_f(n^{\mathrm{ref}})|}{V_K}
             +|S_K|+\nu_K|n_K^{\mathrm{ref}}|
          \right\}\right].

   Use :math:`\Gamma_f(n^{\mathrm{ref}})` here. When the density floor is active, this value may differ
   from the originally supplied flux. The scalar output ``scale`` is in m⁻³ s⁻¹. The routine assumes
   validated inputs and returns no error code. The scale is independent of iterative density and step size,
   so it does not shrink as the iterations settle.

   The normalized residual is :math:`E_R=R_{\max}/R_{\mathrm{scale}}`. Convergence requires both conditions

   .. math::

      E_n\le\text{tolerance},\qquad
      E_R\le\text{residual\_tolerance}

   to hold. The global balance measure :math:`E_B` helps interpret the solution; the maximum local residual
   remains part of the stopping test.

   .. rubric:: 9. Inputs, outputs and failure of the steady solver

   Inputs to ``sub_J03_solve_steady``:

   - ``closure`` and fixed ``source_rate(nr,nz)``.
   - ``cfl``, positive ``tolerance`` and positive integer ``max_iterations``.
   - ``clip_negative``.
   - Optional nonnegative ``progress_interval``. Omit it or set it to zero to suppress progress logs.
     Positive values set the reporting interval.
   - Optional positive ``residual_tolerance``, defaulting to
     :math:`\max(\text{tolerance},100\,\operatorname{epsilon}(1.0))`.

   Outputs:

   - Allocated ``density`` containing the last complete iterate on convergence or reaching the iteration limit.
   - ``converged``, ``iterations``, ``final_relative_change``.
   - ``max_abs_residual``, ``global_balance``.
   - Optional ``final_scaled_residual``.
   - ``ierr``, set to ``J03_ERR_NOT_CONVERGED`` when the iteration limit is reached without convergence.

   This interface does not accept an arbitrary initial field or return an end time. For a prescribed
   transient initial state, run an outer physical-time loop using the step routine. The iteration count is
   a solver diagnostic. Convergence establishes approximate satisfaction of this discrete closure equation;
   the physical model and spatial and temporal resolution require separate assessment.
