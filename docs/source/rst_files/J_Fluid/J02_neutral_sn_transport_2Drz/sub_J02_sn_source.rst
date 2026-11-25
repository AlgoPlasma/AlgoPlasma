.. J_Fluid contribution history (Git author dates; edit times include timezone).
   2026-09-18 12:00 +08:00 | Yingjie Chen | git 69bdc8603906
   2026-10-06 23:50 +08:00 | Yingjie Chen | git fa8cb9f5be05
   2026-10-23 10:58 +08:00 | Yingjie Chen | git cd0d957281af
   2026-11-25 15:14 +08:00 | Yingjie Chen | git 8652258184b5
   2026-11-25 15:59 +08:00 | Yingjie Chen | edit (Codex-assisted)

Inlet Normalization
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J02_sn_source.f90`` 根据给定的入口通量，将前面得到的速度分布
   :math:`g_m` 归一化为实际入射分布函数 :math:`h_m`。
   本页先由总粒子率和入口面积计算单位面积通量，再求分布的归一化系数。
   文件名中的 source 在这里指边界入流，本过程不添加体积源项。

   .. rubric:: 1. 从总粒子率得到单位面积通量

   设入口总粒子率为 :math:`Q`，单位 :math:`\mathrm{s^{-1}}`，
   实际入口面积为 :math:`A_{\mathrm{in}}`。当前组装示例在入口区域采用均匀的入流强度：

   .. math::

      A_{\mathrm{in}}=\sum_i\chi_iA_{z-,i,1},\qquad
      J_{\mathrm{in}}=\frac{Q}{A_{\mathrm{in}}}.

   :math:`J_{\mathrm{in}}` 的单位为 :math:`\mathrm{m^{-2}\,s^{-1}}`。
   对部分入口，应在这里使用真实开口面积，而不是所有下端面的总面积。
   随后 DG 积分已经限定到入口区间，不应再把归一化后的分布函数乘面积比例。

   .. rubric:: 2. 使用离散速度与权重归一化

   入射分布函数 :math:`h_m` 必须满足

   .. math::

      J_{\mathrm{in}}
          =\sum_{\beta_{f,m}<0}w_mv_m|\beta_{f,m}|h_m.

   令 :math:`h_m=C_{\mathrm{in}}g_m`，先将 :math:`g_m` 代入离散通量求和

   .. math::

      D_{\mathrm{in}}
          =\sum_{\beta_{f,m}<0}w_mv_m|\beta_{f,m}|g_m,
      \qquad
      C_{\mathrm{in}}=\frac{J_{\mathrm{in}}}{D_{\mathrm{in}}}.

   于是

   .. math::
      :label: sn-inflow-normalization

      h_m=
      \begin{cases}
         J_{\mathrm{in}}g_m/D_{\mathrm{in}},&\beta_{f,m}<0,\\
         0,&\beta_{f,m}\geq0.
      \end{cases}

   代回第一式，离散通量就等于目标值。
   归一化保证离散入口通量等于给定值；速度分布是否被充分解析，还需检查角度和速率的分辨率。
   相同的离散速度与权重必须继续用于求解和通量重构。

   对于连续概率密度输入，代入 :math:`g_m=p_m/(v_m|\beta_{f,m}|)` 后，
   :math:`D_{\mathrm{in}}=\sum_{\mathrm{in}}w_mp_m`；
   对于速度网格单元内的概率输入，则
   :math:`D_{\mathrm{in}}=\sum_{\mathrm{in}}P_m`。
   这也解释了输入概率尚未归一化时，公共比例仍会自动消去。

   .. rubric:: 3. 通量归一化过程

   ``sub_J02_normalize_inflow_flux`` 的职责是计算上式。

   - 输入 ``quadrature``：与后续求解相同的求积对象。
   - 输入 ``normal_r``、``normal_z``：无量纲单位外法向。
     下端入口使用 :math:`(0,-1)`，其入射速度满足 :math:`\eta_m>0`。
   - 输入 ``target_flux``：目标入射通量 :math:`J_{\mathrm{in}}\geq0`，
     单位 :math:`\mathrm{m^{-2}\,s^{-1}}`。
   - 输入 ``inflow_shape(n_dir)``：非负的 :math:`g_m`。只有入射速度参与归一化，
     因此入口外侧气体分布接口生成的全速度分布可直接传入。
   - 输出并分配 ``psi_in(n_dir)``：:math:`h_m`，单位
     :math:`\mathrm{s^2\,m^{-5}}`；出射速度置零。
   - 输出 ``ierr``。入口分布尺寸不匹配、非单位法向、负目标通量、
     分布中有负值或入射归一化因子为零时均返回错误。

   即使 ``target_flux`` 为零，本过程仍要求 :math:`g_m` 的入射归一化因子非零。
   若只需无外部入射的出口，应直接给对应边界零值，
   无需用全零分布调用归一化过程。

   .. rubric:: 4. 公共检查函数（位于 sub_J02_sn_validation.f90）

   ``fun_J02_normal_is_unit``：

   - 输入 ``normal_r``、``normal_z``；返回逻辑值，无副作用。
   - 当前判断为
     :math:`|n_r^2+n_z^2-1|\leq100\,\operatorname{epsilon}(1)`，
     容差由实际编译实数精度决定。
   - 它检查法向长度，不会自动归一化输入向量。

   .. rubric:: 5. 归一化结果如何成为边界数据

   若整个问题只有下端入口，可把输出作为 ``zlo_inflow(n_dir)``。
   其他开放面默认无外部入射。若多个面有不同规定入流，
   应填写 ``boundary_inflow(4,nr,nz,n_dir)``，把各面的分布函数放在相应位置。

   调用完整求解过程时，``zlo_inflow`` 和 ``boundary_inflow`` 只能选择一种。
   它们传递的是分布函数，不是通量；面通量由求解器或重构过程再乘
   :math:`w_mv_m\beta_{f,m}` 得到。部分入口仍需另传局部区间，
   归一化数组本身不携带几何位置。

   .. rubric:: 6. 入射分布怎样用于输运求解

   :math:`h_m` 是第 :math:`m` 个离散速度在入口处的分布函数值，
   作为已知边界条件进入相邻单元方程的右端项。

   对下端入口，:math:`\eta_m>0` 表示入射，求解器使用 :math:`h_m`；
   :math:`\eta_m<0` 表示粒子从域内离开，使用靠近该面的单元内分布。
   因此入口允许两个方向的运动，但只有入射方向由调用者给定。

   在 DG 单元方程中，已知入口数据进入右端向量。设第 :math:`a` 个检验函数为
   :math:`\phi_a`，入口占当前面的区域为 :math:`I_f`，则入口贡献为

   .. math::

      b_{a}^{\mathrm{inlet}}
        =|\beta_{f,m}|\int_{I_f}r\,\phi_a h_m\,\mathrm ds.

   :math:`\mathrm ds` 是 r-z 截面上的边界线元，:math:`r\,\mathrm ds`
   是约去共同周向张角后的面积元。式中没有速率 :math:`v_m`，
   因为这里使用的输运方程已经除以速率；也没有速度积分权重 :math:`w_m`，
   因为此时只在求一个确定速度的分布。

   例如，下端整个面都是均匀入口时，局部坐标 :math:`\zeta=-1`，
   检验函数为 :math:`(1,\xi,-1)`，于是

   .. math::

      \boldsymbol b^{\mathrm{inlet}}
        =\eta_m h_m
          \begin{pmatrix}
            2r_ch_r\\[2pt]2h_r^2/3\\[2pt]-2r_ch_r
          \end{pmatrix},
          \qquad \eta_m>0.

   若入口只占面的一部分，则把积分范围换成实际入口区间。
   扫描文件根据面类型调用 ``sub_J02_add_constant_rhs`` 或
   ``sub_J02_add_zface_constant_interval_rhs``，将此贡献加入 ``rhs(3)``。
   随后 DG 局部求解过程解出第一个单元的分布系数，其出射值又成为下游单元的已知入流。

   因此，实际传递顺序是：入口速度模型给出 :math:`g_m`，
   本文件给出 :math:`h_m`，扫描将 :math:`h_m` 写入单元方程右端，
   求解得到空间分布 :math:`\psi_m(r,z)`，最后才对全部离散速度积分得到密度与通量。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``sub_J02_sn_source.f90`` normalizes the velocity shape :math:`g_m` from the previous step to the physical incoming distribution :math:`h_m` for
   the prescribed flux. First divide the total particle rate by inlet area, then calculate the normalization
   coefficient. The source in this file is a boundary inflow. The routine adds no volumetric source.

   .. rubric:: 1. From total particle rate to flux per unit area

   Let the total inlet particle rate be :math:`Q` in :math:`\mathrm{s^{-1}}` and the actual inlet area be :math:`A_{\mathrm{in}}`. The assembly example uses
   uniform inflow intensity over the opening.

   .. math::

      A_{\mathrm{in}}=\sum_i\chi_iA_{z-,i,1},\qquad
      J_{\mathrm{in}}=\frac{Q}{A_{\mathrm{in}}}.

   :math:`J_{\mathrm{in}}` has units of :math:`\mathrm{m^{-2}\,s^{-1}}`. For a partial inlet, use the area of the actual opening. The subsequent DG
   integration is already restricted to the inlet interval, so the normalized distribution needs no
   additional area-fraction factor.

   .. rubric:: 2. Normalization with discrete velocities and weights

   The incoming distribution :math:`h_m` must satisfy

   .. math::

      J_{\mathrm{in}}
          =\sum_{\beta_{f,m}<0}w_mv_m|\beta_{f,m}|h_m.

   Set :math:`h_m=C_{\mathrm{in}}g_m`. First evaluate the discrete flux of :math:`g_m`.

   .. math::

      D_{\mathrm{in}}
          =\sum_{\beta_{f,m}<0}w_mv_m|\beta_{f,m}|g_m,
      \qquad
      C_{\mathrm{in}}=\frac{J_{\mathrm{in}}}{D_{\mathrm{in}}}.

   The result is

   .. math::
      :label: sn-inflow-normalization-en

      h_m=
      \begin{cases}
         J_{\mathrm{in}}g_m/D_{\mathrm{in}},&\beta_{f,m}<0,\\
         0,&\beta_{f,m}\geq0.
      \end{cases}

   Substituting into the first expression recovers the target discrete flux. Check angular and speed
   resolution separately to determine whether the shape is adequately resolved. Use the same velocities and
   weights in the solve and flux reconstruction.

   For a continuous probability density, substitution of :math:`g_m=p_m/(v_m|\beta_{f,m}|)` gives :math:`D_{\mathrm{in}}=\sum_{\mathrm{in}}w_mp_m`. For probabilities per velocity bin it
   gives :math:`D_{\mathrm{in}}=\sum_{\mathrm{in}}P_m`. In both cases a common factor applied to the input probabilities cancels in normalization.

   .. rubric:: 3. Flux normalization routine

   ``sub_J02_normalize_inflow_flux`` evaluates this normalization.

   - Input ``quadrature`` is the quadrature object that will also be used for the solve.
   - Inputs ``normal_r`` and ``normal_z`` form a dimensionless unit outward normal. At the lower inlet use :math:`(0,-1)`, for which
     incoming velocities satisfy :math:`\eta_m>0`.
   - Input ``target_flux`` is the prescribed incoming flux :math:`J_{\mathrm{in}}\geq0` in :math:`\mathrm{m^{-2}\,s^{-1}}`.
   - Input ``inflow_shape(n_dir)`` is the nonnegative shape :math:`g_m`. Only incoming velocities enter the normalization, so a full
     velocity distribution produced by the exterior gas interface can be passed directly.
   - The routine allocates output ``psi_in(n_dir)``, containing :math:`h_m` in :math:`\mathrm{s^2\,m^{-5}}`. Values at outgoing velocities are set to zero.
   - Output ``ierr`` reports a shape mismatch, a nonunit normal, a negative target flux, a negative distribution
     value or a zero incoming normalization factor.

   Even for zero ``target_flux``, the routine requires a nonzero incoming normalization factor for :math:`g_m`. To set an outlet
   with zero external inflow, prescribe zero boundary values directly.

   .. rubric:: 4. Shared validation function in sub_J02_sn_validation.f90

   ``fun_J02_normal_is_unit``：

   - Inputs are ``normal_r`` and ``normal_z``. The function returns a logical result without side effects.
   - The test is :math:`|n_r^2+n_z^2-1|\leq100\,\operatorname{epsilon}(1)`. The tolerance depends on the real precision used in the build.
   - The function checks the normal length. The caller supplies the normalized vector.

   .. rubric:: 5. Supplying the normalized distribution as boundary data

   For a problem with only a lower inlet, pass the result as ``zlo_inflow(n_dir)``. Other open faces default to zero external
   inflow. To prescribe different inflows on several faces, populate ``boundary_inflow(4,nr,nz,n_dir)`` with the appropriate distributions.

   Pass either ``zlo_inflow`` or ``boundary_inflow`` to the complete solver. Both hold distribution functions. The solver or
   reconstruction routine multiplies by :math:`w_mv_m\beta_{f,m}` to obtain flux. For a partial inlet, pass the local interval
   separately to specify its location.

   .. rubric:: 6. How the transport solve uses incoming data

   :math:`h_m` is the inlet distribution at discrete velocity :math:`m`. It supplies known boundary data to the right-hand
   side of the adjacent cell equation.

   At the lower inlet :math:`\eta_m>0` is incoming and uses :math:`h_m`. At :math:`\eta_m<0` particles leave the domain and the interior cell
   trace supplies their distribution. The inlet thus permits motion in both directions while the caller
   prescribes only the incoming directions.

   The DG equations put the known inlet data into the right-hand side. For test function number :math:`a`, denoted
   by :math:`\phi_a`, and inlet region :math:`I_f` on the face, the contribution is

   .. math::

      b_{a}^{\mathrm{inlet}}
        =|\beta_{f,m}|\int_{I_f}r\,\phi_a h_m\,\mathrm ds.

   :math:`\mathrm ds` is a line element along the boundary in the r–z cross-section. :math:`r\,\mathrm ds` is the area element after cancelling
   the common azimuthal extent. The speed :math:`v_m` has already been divided out of the transport equation. The
   equation is for one discrete velocity, so it does not yet contain a quadrature weight :math:`w_m`.

   For example, a uniform inlet covering the entire lower face has :math:`\zeta=-1` and test functions :math:`(1,\xi,-1)`. These give

   .. math::

      \boldsymbol b^{\mathrm{inlet}}
        =\eta_m h_m
          \begin{pmatrix}
            2r_ch_r\\[2pt]2h_r^2/3\\[2pt]-2r_ch_r
          \end{pmatrix},
          \qquad \eta_m>0.

   For a partial inlet, integrate over its actual interval. Depending on face type, the sweep calls ``sub_J02_add_constant_rhs`` or ``sub_J02_add_zface_constant_interval_rhs``
   to add the contribution to ``rhs(3)``. Solving the DG system gives the first cell's distribution coefficients,
   whose outgoing trace becomes known inflow in the next cell downstream.

   The inlet velocity model provides :math:`g_m`. This file computes :math:`h_m`, and the sweep inserts :math:`h_m` into the cell
   right-hand side. Solving all cells gives :math:`\psi_m(r,z)`. Integrating over all velocities then yields density and
   flux.
