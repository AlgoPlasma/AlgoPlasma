.. J_Fluid contribution history (Git author dates; edit times include timezone).
   2026-09-18 12:00 +08:00 | Yingjie Chen | git 69bdc8603906
   2026-10-06 23:50 +08:00 | Yingjie Chen | git fa8cb9f5be05
   2026-11-25 15:14 +08:00 | Yingjie Chen | git 8652258184b5
   2026-11-25 15:59 +08:00 | Yingjie Chen | edit (Codex-assisted)

Reflection Iteration
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J02_sn_reflection.f90`` 反复更新壁面入流并调用迎风扫描，求出稳态分布。
   之所以不能只扫描一次，是因为反射入流依赖未知的撞壁分布；
   而撞壁分布必须先解域内输运方程才能得到。

   本文件采用固定点迭代。用上一轮出流确定下一轮反射入流的做法见
   :ref:`Carlson 与 Lathrop（1965） <j02-reflection-ref-cl65>` 第 3.7.4 节。
   每次更新壁面入流后，重新求解域内分布，直到变化足够小。迭代次数不代表物理时间，
   过程中没有时间步长，也不是在计算粒子随真实时间的演化。

   .. rubric:: 1. 从上一轮分布得到下一轮分布

   令 :math:`\ell=0,1,2,\ldots` 为已完成的迭代轮数。
   :math:`\psi_m^{(\ell)}` 表示该轮的空间分布；
   其单元内三个系数记为
   :math:`\boldsymbol c_{K,m}^{(\ell)}=(c_{0,K,m}^{(\ell)},c_{1,K,m}^{(\ell)},c_{2,K,m}^{(\ell)})^{\mathsf T}`。
   上标 :math:`(\ell)` 只表示轮次，不是幂。

   **第一步：使用上一轮分布，计算各壁面区域的反射系数。**

   沿用壁面页定义的 :math:`W`、:math:`A_W` 和 :math:`g_{\mathrm w,m}`，
   从上一轮的出射分布计算撞壁粒子率，再归一化漫反射：

   .. math::

      Q_W^{\mathrm{out},(\ell)}
         =\sum_{\beta_{f,m}>0}w_mv_m\beta_{f,m}
             \int_W\psi_{W,m}^{\mathrm{out},(\ell)}(\boldsymbol x)\,\mathrm dA,

   .. math::

      C_W^{(\ell)}
         =\frac{Q_W^{\mathrm{out},(\ell)}}
                {A_W\displaystyle\sum_{\beta_{f,m}<0}
                     w_mv_m|\beta_{f,m}|g_{\mathrm w,m}}.

   镜面项同样读取上一轮对应出射速度的分布。因此本轮扫描采用的已知壁面入流为

   .. math::

      \psi_{W,m}^{\mathrm{in},(\ell+1)}(\boldsymbol x)
        =(1-d)\psi_{W,R_f(m)}^{\mathrm{out},(\ell)}(\boldsymbol x)
          +dC_W^{(\ell)}g_{\mathrm w,m},\qquad \beta_{f,m}<0.

   式子左侧标为 :math:`\ell+1`，表示它将用于下一轮输运求解；
   右侧全部来自已知的第 :math:`\ell` 轮，所以各离散速度可以分别计算。
   规定入口 :math:`h_m`、壁温、反射比例和损失系数在这些轮次中保持不变。

   **第二步：固定本轮壁面入流，按迎风顺序求解空间单元。**

   对第 :math:`m` 个离散速度和当前单元 :math:`K`，组装

   .. math::

      \mathsf A_{K,m}\boldsymbol c_{K,m}^{(\ell+1)}
        =\boldsymbol b_{K,m}^{\mathrm{interior},(\ell+1)}
          +\boldsymbol b_{K,m}^{\mathrm{inlet}}
          +\boldsymbol b_{K,m}^{\mathrm{wall},(\ell+1)}.

   三个右端分别表示：

   - 内部入流：读取本轮已算完的上游单元系数，所以标为 :math:`\ell+1`；
   - 规定入口：读取不随迭代改变的 :math:`h_m`；无外部入射的出口贡献为零；
   - 壁面入流：把第一步得到的反射分布代入 DG 面积分。

   并非每个单元都具有这三类入流；不存在的贡献为零。
   矩阵 :math:`\mathsf A_{K,m}` 由几何、方向和损失决定，不因反射轮次改变。
   每个单元求解后执行保正处理，得到的系数再供本轮下游单元使用。

   **第三步：所有离散速度计算完成后，检查新旧分布的变化。**

   达到下节判据就返回新分布；否则将新分布作为上一轮分布，再回到第一步。
   “同一轮内部面用新值、壁面用上一轮值”是两种明确的数据依赖，不能相互替换。

   初始时全部系数为零。因此第一轮的撞壁粒子率和反射入流都为零，
   只有规定入口产生分布。第二轮开始使用这些粒子的出射分布计算反射入流。
   中间轮次的壁面入流对应上一轮出射值，未必与本轮出射值平衡；
   收敛后两轮分布一致，才满足稳态反射条件。

   若持续有入口供应，却没有开放出口、体损失或吸附等移除机制，就可能不存在有限稳态解。
   此时增加迭代上限不能解决物理收支问题。

   .. figure:: ../../../images/J_Fluid/sn_parallel_iteration_en.svg
      :alt: 上一轮分布确定壁面入流，各线程计算不同离散速度的空间分布，全部完成后检查收敛
      :width: 900px

      一轮内的不同速度任务可以使用 OpenMP 并行；下一轮必须等待本轮完整结果。
      图中的同步表示等待本轮所有线程完成，不是物理时间步。

   .. rubric:: 2. 怎样衡量新旧分布的变化

   代码比较全部多项式系数，而不是只比较密度。这样不会遗漏两个分布具有相近密度、
   但速度分布或空间一次项仍有变化的情况。
   求和范围是所有有效空间单元、所有离散速度以及每组的三个系数。
   无效单元始终为零，实际数组求和包含它们也不影响结果。

   为避免数据过大或过小时的数值问题，先用新旧分布中最大的系数绝对值作共同缩放：

   .. math::

      S=\max_{K,m,\;a=0,1,2}
          \left(|c_{a,K,m}^{(\ell)}|,
                |c_{a,K,m}^{(\ell+1)}|\right).

   :math:`S=0` 时，两轮都为零，定义相对变化为零。
   :math:`S>0` 时，先算三个量：

   .. math::

      \begin{aligned}
      D&=\sum_{K,m}\sum_{a=0}^2
          \left|\frac{c_{a,K,m}^{(\ell+1)}}S
                       -\frac{c_{a,K,m}^{(\ell)}}S\right|,\\
      B_{\mathrm{old}}&=\sum_{K,m}\sum_{a=0}^2
                          \left|\frac{c_{a,K,m}^{(\ell)}}S\right|,\\
      B_{\mathrm{new}}&=\sum_{K,m}\sum_{a=0}^2
                          \left|\frac{c_{a,K,m}^{(\ell+1)}}S\right|.
      \end{aligned}

   :math:`D` 是变化量，:math:`B_{\mathrm{old}},B_{\mathrm{new}}`
   是两轮分布各自的大小。最后使用

   .. math::

      E_{\ell+1}=\frac{D}{\max(B_{\mathrm{old}},B_{\mathrm{new}})}.

   共同缩放 :math:`S` 在比值中抵消，只改变计算时的数值大小，不改变判据含义。
   例如，所有系数统一乘一个正数，只要不发生浮点溢出或下溢，:math:`E_{\ell+1}` 就不变。
   取新旧大小中的较大者，还避免只用旧场作分母时第一轮全零导致除零。

   至少完成两轮，并满足 :math:`E_{\ell+1}\leq\text{tolerance}`，程序才报告收敛。
   这表明反射更新已足够小，不直接说明网格、角度和速率离散误差的大小，
   也不是对局部方程残差或全局粒子收支作了单独验收。

   MPI 分区时，上述最大值和求和都覆盖所有进程。
   各进程不能只用自己区域的变化量决定是否停止；13–14 页说明这些全局计算怎样执行。

   .. rubric:: 3. 主过程的输入

   本文件只有 ``sub_J02_solve_source_iteration`` 一个过程。

   - 输入 ``mesh``、``geometry``、``quadrature``、``boundary``，
     以及 ``sigma_t(nr,nz,n_dir)``。
   - 入流二选一：``boundary_inflow(4,nr,nz,n_dir)``
     或 ``zlo_inflow(n_dir)``，含义与扫描接口相同。
   - 输入 ``wall_shape(n_dir)`` 与 ``diffuse_fraction``。
     漫反射比例为零，即纯镜面反射时，可将 ``wall_shape`` 全部设为零；
     有漫反射时，则要求它能按壁面入射通量归一化。
   - 输入 ``max_iterations``：至少为二；``tolerance``：有限且严格为正。
   - 可选输入 ``partition``：本地空间分区信息；传入后所有进程共同迭代，失败索引使用全局坐标。
   - 可选的两个下端入口区间数组必须同时传入，尺寸均为 ``nr``。
   - 可选 ``progress_interval``：非负整数，零表示关闭迭代进度；
     正数控制每隔多少轮打印相对变化，首轮也打印。
     当前启用迭代进度时，内部方向进度另按 800 个离散速度的间隔报告。

   本过程不接收初始场，始终从零初始化。
   若未来需要续算或使用已有解作初值，需要增加相应的初始分布输入；当前接口不读取上一次计算结果。

   .. rubric:: 4. 输出与失败处理

   - 输出 ``psi(3,nr,nz,n_dir)``：最后保留的完整一轮系数。
   - 输出 ``converged``：逻辑收敛状态；
     ``iterations``：迭代计数；
     ``final_relative_change``：最后一次计算的无量纲变化量。
   - 输出 ``ierr``：成功为零，达到迭代上限仍未满足判据时为
     ``SN_ERR_SOURCE_ITERATION_NOT_CONVERGED``；
     扫描失败时传播其错误码。
   - 可选输出 ``failed_direction``、``failed_i``、``failed_k``：
     用于定位扫描中发生的方向和单元错误。

   正常收敛时，迭代计数就是完成轮数。用尽上限时返回 ``max_iterations``；
   若单轮中途失败，计数表示尝试到的那一轮，不能把它解释成已完成一轮。

   若中途扫描失败，过程保留上一轮完整场，而不是本次半完成的新场。
   在参数检查很早就失败时，场可能尚未分配，失败位置初始化为零；
   所有输出都应在检查 ``ierr`` 后按失败类型使用。
   未收敛的分布可用于排查问题，但不能作为收敛的稳态解。

   .. rubric:: 5. 与后续重构的衔接

   迭代成功后，完整求解接口才调用重构过程，
   由同一组系数和原求积权重计算密度、速度与面通量。
   迭代期间，规定入口分布保持不变；密度由收敛后的分布积分得到。
   对近乎封闭或弱损失的系统，粒子可能多次碰壁反射，收敛较慢；
   此时应结合边界逃逸和损失条件分析，而不是把迭代轮数当作实际驻留时间。

   .. rubric:: 参考文献

   .. _j02-reflection-ref-cl65:

   B. G. Carlson and K. D. Lathrop (1965).
   *Transport Theory: The Method of Discrete Ordinates*.
   Los Alamos Scientific Laboratory, LA-3251-MS.
   `报告全文 <https://mcnp.lanl.gov/pdf_files/TechReport_1965_LANL_LA-3251-MS_CarlsonLathrop.pdf>`__

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``sub_J02_sn_reflection.f90`` finds the steady distribution by alternating wall-inflow updates and upwind sweeps. The reflected
   inflow depends on the unknown distribution of particles reaching the wall, which in turn depends on
   transport through the domain.

   The fixed-point iteration uses outgoing data from the previous sweep to prescribe incoming
   reflection for the next sweep, as in :ref:`Carlson and Lathrop (1965) <j02-reflection-ref-cl65-en>`, Section 3.7.4. After each wall update, solve for the
   interior distribution again until changes are small. The iteration count measures progress toward a
   steady solution. No physical time step is involved.

   .. rubric:: 1. Advancing the distribution by one iteration

   Let :math:`\ell=0,1,2,\ldots` be the number of completed iterations. :math:`\psi_m^{(\ell)}` denotes the spatial distribution at that iteration
   and :math:`\boldsymbol c_{K,m}^{(\ell)}=(c_{0,K,m}^{(\ell)},c_{1,K,m}^{(\ell)},c_{2,K,m}^{(\ell)})^{\mathsf T}` its three coefficients in a cell. The superscript :math:`(\ell)` is an iteration index.

   **Step 1. Compute reflection coefficients for each wall region from the previous distribution.**

   Use :math:`W`, :math:`A_W`, and :math:`g_{\mathrm w,m}` as defined on the wall-reflection page. Compute the particle rate striking the
   wall from the previous outgoing distribution, then normalize diffuse reflection:

   .. math::

      Q_W^{\mathrm{out},(\ell)}
         =\sum_{\beta_{f,m}>0}w_mv_m\beta_{f,m}
             \int_W\psi_{W,m}^{\mathrm{out},(\ell)}(\boldsymbol x)\,\mathrm dA,

   .. math::

      C_W^{(\ell)}
         =\frac{Q_W^{\mathrm{out},(\ell)}}
                {A_W\displaystyle\sum_{\beta_{f,m}<0}
                     w_mv_m|\beta_{f,m}|g_{\mathrm w,m}}.

   The specular term also reads the previous distribution in the corresponding outgoing direction. The
   known incoming wall distribution for the sweep is

   .. math::

      \psi_{W,m}^{\mathrm{in},(\ell+1)}(\boldsymbol x)
        =(1-d)\psi_{W,R_f(m)}^{\mathrm{out},(\ell)}(\boldsymbol x)
          +dC_W^{(\ell)}g_{\mathrm w,m},\qquad \beta_{f,m}<0.

   The left side is marked :math:`\ell+1` because it is used for the next transport solve. The right side uses only
   the completed iteration :math:`\ell`, allowing each discrete velocity to be solved independently. Prescribed
   inlet :math:`h_m`, wall temperature, reflection fraction, and loss coefficients remain fixed throughout.

   **Step 2. Hold wall inflow fixed and solve the cells in upwind order.**

   For discrete velocity :math:`m` and cell :math:`K` assemble

   .. math::

      \mathsf A_{K,m}\boldsymbol c_{K,m}^{(\ell+1)}
        =\boldsymbol b_{K,m}^{\mathrm{interior},(\ell+1)}
          +\boldsymbol b_{K,m}^{\mathrm{inlet}}
          +\boldsymbol b_{K,m}^{\mathrm{wall},(\ell+1)}.

   The three contributions to the right-hand side are:

   - Interior inflow uses the newly computed upstream coefficients from this sweep, denoted by :math:`\ell+1`.
   - Prescribed inlet data use the fixed :math:`h_m`. An outlet with no external inflow contributes zero.
   - Wall inflow uses the reflected distribution from step 1 in the DG face integral.

   Only the incoming face types present in a cell contribute. Matrix :math:`\mathsf A_{K,m}` depends on the geometry,
   direction, and loss and stays fixed across iterations. Enforce positivity after each cell solve
   before passing the coefficients downstream.

   **Step 3. Compare the old and new distributions after all velocities finish.**

   Return the new distribution when the criterion below is satisfied. Otherwise use it as the previous
   distribution and return to step 1. Interior faces thus depend on new values from this sweep, while
   walls depend on values from the preceding sweep.

   All coefficients initially vanish. In the first sweep there are no particles arriving at the walls
   and no reflected inflow; only the prescribed inlet produces a distribution. The second sweep starts
   reflecting particles from the first sweep. During iteration, wall inflow balances the preceding
   outgoing distribution and may differ from current outflow. At convergence the two distributions
   agree and the steady reflection condition holds.

   A continuous inlet with no open outlet, volume loss, adsorption, or other removal mechanism may have
   no finite steady solution. Raising the iteration limit cannot restore physical particle balance.

   .. figure:: ../../../images/J_Fluid/sn_parallel_iteration_en.svg
      :alt: The old distribution sets the wall inflow; threads solve different discrete velocities and check convergence after all finish
      :width: 900px

      OpenMP can distribute velocity tasks within an iteration. The next iteration waits for the
      complete result. The synchronization shown is a thread barrier, independent of physical time.

   .. rubric:: 2. Measuring changes between distributions

   The code compares all polynomial coefficients. This detects changes in velocity distribution or
   spatial slopes even when densities agree. The sum covers all active cells, all discrete velocities,
   and all three coefficients. Inactive cells stay zero, so including them in array sums has no effect.

   To avoid loss of numerical range for very large or small values, first find the largest absolute
   coefficient across both fields as a common scale:

   .. math::

      S=\max_{K,m,\;a=0,1,2}
          \left(|c_{a,K,m}^{(\ell)}|,
                |c_{a,K,m}^{(\ell+1)}|\right).

   When :math:`S=0` both fields vanish and the relative change is defined as zero. When :math:`S>0` compute three
   quantities:

   .. math::

      \begin{aligned}
      D&=\sum_{K,m}\sum_{a=0}^2
          \left|\frac{c_{a,K,m}^{(\ell+1)}}S
                       -\frac{c_{a,K,m}^{(\ell)}}S\right|,\\
      B_{\mathrm{old}}&=\sum_{K,m}\sum_{a=0}^2
                          \left|\frac{c_{a,K,m}^{(\ell)}}S\right|,\\
      B_{\mathrm{new}}&=\sum_{K,m}\sum_{a=0}^2
                          \left|\frac{c_{a,K,m}^{(\ell+1)}}S\right|.
      \end{aligned}

   :math:`D` is the change; :math:`B_{\mathrm{old}},B_{\mathrm{new}}` measure the magnitudes of the two fields. Use the following relative change:

   .. math::

      E_{\ell+1}=\frac{D}{\max(B_{\mathrm{old}},B_{\mathrm{new}})}.

   The common scale :math:`S` cancels from the ratio. Multiplying every coefficient by the same positive
   factor leaves :math:`E_{\ell+1}` unchanged barring overflow or underflow. Taking the larger of the two norms also
   permits comparison with an initially zero field.

   Convergence requires at least two completed iterations and :math:`E_{\ell+1}\leq\text{tolerance}`. The criterion measures the size of
   the reflection update. Spatial, angular, and speed discretization error, local residuals, and global
   particle balance require separate checks.

   For MPI partitions the maxima and sums cover all ranks. All ranks use the same stopping decision.
   Pages 13 and 14 detail the global operations.

   .. rubric:: 3. Inputs to the iteration

   This file contains one procedure, ``sub_J02_solve_source_iteration``.

   - Inputs are ``mesh``, ``geometry``, ``quadrature``, ``boundary``, and ``sigma_t(nr,nz,n_dir)``.
   - Specify exactly one inflow representation: ``boundary_inflow(4,nr,nz,n_dir)`` or ``zlo_inflow(n_dir)``, as in the sweep interface.
   - Supply ``wall_shape(n_dir)`` and ``diffuse_fraction``. With zero diffuse fraction (pure specular reflection), all of ``wall_shape`` may be zero.
     For diffuse reflection the distribution must admit normalization by the wall's incoming flux.
   - ``max_iterations`` must be at least two. ``tolerance`` must be finite and strictly positive.
   - Optional ``partition`` describes the local spatial partition. When supplied, all ranks iterate collectively
     and failure indices use global coordinates.
   - Pass both optional lower-inlet interval arrays together. Each has size ``nr``.
   - Optional ``progress_interval`` is a nonnegative integer. Zero disables iteration progress. A positive value prints
     the relative change on the first iteration and at the requested interval. With iteration reporting
     enabled, inner progress is also reported at intervals of 800 discrete velocities.

   The routine always starts at zero and has no initial-field argument. Restarting from a previous
   solution would require an additional distribution input.

   .. rubric:: 4. Outputs and failures

   - ``psi(3,nr,nz,n_dir)`` returns coefficients from the last complete iteration retained.
   - ``converged`` is the logical convergence status, ``iterations`` the iteration count, and ``final_relative_change`` the last dimensionless change
     computed.
   - ``ierr`` is zero on success and ``SN_ERR_SOURCE_ITERATION_NOT_CONVERGED`` if the iteration limit is reached without satisfying the criterion. A
     failed sweep propagates its status.
   - Optional ``failed_direction``, ``failed_i``, and ``failed_k`` locate the failed direction and cell in a sweep.

   On convergence the count is the number of completed iterations. Exhausting the limit returns ``max_iterations``. If
   a sweep fails partway through, the counter identifies the attempted iteration.

   After a failed sweep, the routine retains the previous complete field. If initial validation fails,
   the field may still be unallocated and location indices are initially zero. Check ``ierr`` before using
   outputs and interpret them according to the failure. An unconverged field can help diagnose a
   problem.

   .. rubric:: 5. Passing the solution to reconstruction

   After successful iteration the full solver calls reconstruction. The same coefficients and
   quadrature weights yield density, velocity, and face fluxes. The prescribed inlet remains fixed
   while the density is integrated from the converged distribution. Nearly closed or weakly absorbing
   systems can require many reflections and converge slowly. Interpret the iteration behavior in light
   of escape and loss; the iteration count does not measure residence time.

   .. rubric:: References

   .. _j02-reflection-ref-cl65-en:

   Carlson, B. G., and K. D. Lathrop (1965). *Transport Theory: The Method of Discrete Ordinates*. Los
   Alamos Scientific Laboratory, LA-3251-MS. `Full report <https://mcnp.lanl.gov/pdf_files/TechReport_1965_LANL_LA-3251-MS_CarlsonLathrop.pdf>`__
