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

   This file evaluates current face fluxes, advances physical time and computes diagnostics.
   At an interior face oriented L→R, use u*nL for u≥0 and u*nR otherwise.
   Open flux is prescribed inflow plus the outgoing coefficient times current cell density; walls are zero.
   ``sub_J03_cell_fluxes`` returns four coordinate-oriented fluxes without areas or density updates.

   The cell equation and semi-implicit step are

   .. math::

      D_K(n)=\frac{\sum_f s_fA_f\Gamma_f(n)}{V_K},\quad
      \frac{n_K^{q+1}-n_K^q}{\Delta t}
        =-D_K(n^q)+S_K^q-\nu_K^q n_K^{q+1},

   .. math::

      n_K^{q+1}=\frac{n_K^q-\Delta tD_K(n^q)+\Delta t S_K^q}
                       {1+\Delta t\nu_K^q}.

   ``sub_J03_compute_stable_timestep`` returns cfl/max(lambda), using all absolute interior-face
   coefficients, outgoing open coefficients, and loss frequency in lambda.
   This is conservative; fixed incoming flux does not remove current particles.
   If all rates are negligible it returns 1 s, which is not a physical accuracy recommendation.

   ``sub_J03_continuity_step`` reads closure, density, source_rate, dt and clip_negative,
   allocates density_new and returns ierr. It validates shapes, positive dt and nonnegative source.
   Without clipping it rejects negative input density, but does not automatically reject excessive
   dt or negative output. Clipping adds particles and is not a conservation or CFL repair.

   For an unclipped step, the exact discrete total balance uses mixed time levels:

   .. math::

      \frac{N^{q+1}-N^q}{\Delta t}
        =Q_{\mathrm{in}}^q+Q_{\mathrm{src}}^q
          -Q_{\mathrm{out}}(n^q)-Q_{\mathrm{loss}}^q(n^{q+1}).

   ``sub_J03_compute_balance`` returns incoming, outgoing, production and removal rates
   for one supplied density, plus a relative steady imbalance and ierr.
   To verify a transient step, use old-density outflow and new-density removal with unchanged step data.

   ``sub_J03_compute_residual`` returns R=D+nu*n-S, max|R| and sum(VR).
   Small global imbalance can hide cancelling local residuals.
   Neither R nor the steady imbalance must vanish during a genuine transient.

   ``sub_J03_solve_steady`` starts from reference density and uses one fixed step for fixed inputs.
   It requires relative L1 iterate change and normalized maximum residual to pass simultaneously.
   ``sub_J03_reference_residual_scale`` computes a fixed scale from closure-evaluated reference fluxes,
   source and loss rates, independent of dt or current iterate.

   Steady inputs include closure, source, cfl, tolerance, max_iterations and clipping;
   optional progress_interval controls logging, residual_tolerance defaults to max(tolerance,100*epsilon).
   Outputs include density, convergence flag, iteration count, relative change, maximum residual,
   global balance, optional scaled residual and ierr.
   Reaching the limit preserves the last state but returns J03_ERR_NOT_CONVERGED.
