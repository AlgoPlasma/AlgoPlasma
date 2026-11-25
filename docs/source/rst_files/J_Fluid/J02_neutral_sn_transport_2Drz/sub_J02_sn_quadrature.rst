.. J_Fluid contribution history (Git author dates; edit times include timezone).
   2026-09-18 12:00 +08:00 | Yingjie Chen | git 69bdc8603906
   2026-10-06 23:50 +08:00 | Yingjie Chen | git fa8cb9f5be05
   2026-10-23 10:58 +08:00 | Yingjie Chen | git cd0d957281af
   2026-11-25 15:14 +08:00 | Yingjie Chen | git 8652258184b5
   2026-11-25 15:59 +08:00 | Yingjie Chen | edit (Codex-assisted)

Velocity Quadrature
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J02_sn_quadrature.f90`` 生成离散速度及其积分权重。
   入口归一化、壁面通量、输运求解和密度重构使用这组离散速度，
   把连续的二维速度积分写成有限项求和。

   .. rubric:: 1. 当前采用的求积方法

   离散纵标法用有限个方向上的函数值和权重近似角积分，见 :ref:`Carlson 与 Lathrop（1965） <j02-quadrature-ref-cl65>` 第 3.3 节。
   当前实现将二维速度平面写成极坐标，再使用角度与速率的乘积规则：

   - 角度方向使用全圆等角复合中点法，每个角区间取一个中点。
   - 速率方向使用等宽或调用者给定的非均匀区间，在区间中点取分布值，权重则对区间内的
     :math:`v\,\mathrm dv` 精确积分。
   - 速率上限由调用者给定，积分域由无限速度平面截断为有限圆盘。

   上述方法属于中点求积，与 Gauss–Legendre、Gauss–Laguerre 求积不同。
   角度选项 ``gauss-chebyshev`` 在当前代码中只是 ``midpoint`` 的别名：
   两者进入同一实现，生成完全相同的节点和权重，并非另一种求积方法。

   .. figure:: ../../../images/J_Fluid/sn_velocity_quadrature_en.svg
      :alt: 速度圆盘按角区间和速率区间划分，每个扇环有一个中点节点
      :width: 900px

      一个离散速度对应一个扇环。角区间等宽不意味着所有节点的二维速度权重相等；
      越靠外的同宽速率区间具有越大的速度面积。图中橙色扇环的权重由后文的
      :math:`W^v_gW^\theta_a` 给出。

   .. rubric:: 2. 从二维速度积分到极坐标积分

   速度积分把所有速度的贡献累加成密度或流密度。例如，在固定空间位置 :math:`(r,z)`，

   .. math::

      n=\int_{\mathbb R^2}\psi(v_r,v_z)\,\mathrm dv_r\,\mathrm dv_z,\qquad
      j_r=\int_{\mathbb R^2}v_r\psi(v_r,v_z)\,\mathrm dv_r\,\mathrm dv_z.

   第一式累加粒子数量，第二式还乘径向速度，得到径向粒子流密度。
   下面用 :math:`F(v_r,v_z)` 表示被积函数，按待求物理量取值：

   - 计算密度时，:math:`F=\psi`；
   - 计算径向流密度时，:math:`F=v_r\psi`；
   - 计算轴向流密度时，:math:`F=v_z\psi`。

   求积过程生成取值位置与权重；调用端在这些位置计算 :math:`F`，再进行加权求和。

   为划分速度平面，将速度大小记为 :math:`v`，方向角记为 :math:`\theta`：

   .. math::

      v_r=v\cos\theta,\qquad v_z=v\sin\theta,\qquad
      \mathrm dv_r\,\mathrm dv_z=v\,\mathrm dv\,\mathrm d\theta.

   因此在当前截断域内，

   .. math::

      I[F]=\int_0^{2\pi}\int_0^{v_{\max}}
                F(v\cos\theta,v\sin\theta)\,v\,\mathrm dv\,\mathrm d\theta.

   这里的 :math:`\theta` 是速度平面中的方向角，不是周向张角 :math:`\Theta`。
   权重中的 :math:`v` 来自速度极坐标变换的雅可比。

   .. rubric:: 3. 角度中点规则的节点与权重

   将全圆均分为 :math:`N_\theta` 个区间，区间宽度与中点为

   .. math::

      \Delta\theta=\frac{2\pi}{N_\theta},\qquad
      \theta_a=\left(a-\frac12\right)\Delta\theta,\qquad
      a=1,\ldots,N_\theta.

   在每个区间内以中点函数值近似函数，得到

   .. math::

      \int_0^{2\pi}F(\theta)\,\mathrm d\theta
          \approx\sum_{a=1}^{N_\theta}W^\theta_aF(\theta_a),\qquad
      W^\theta_a=\Delta\theta,\quad
      \mu_a=\cos\theta_a,\quad\eta_a=\sin\theta_a.

   当前要求 :math:`N_\theta\geq8` 且可被四整除。
   这样四象限具有相同结构，中点不落在坐标轴上，并能为轴向、径向镜面反射提供成对方向。
   扫描过程不支持方向余弦为零的节点，因此这一约束不仅是精度选择，也是当前实现的调用条件。

   .. rubric:: 4. 速率区间的节点与权重

   原等宽接口将 :math:`[0,v_{\max}]` 分成 :math:`N_v` 个区间：

   .. math::

      \Delta v=\frac{v_{\max}}{N_v},\qquad
      v_{g-1/2}=(g-1)\Delta v,\qquad
      v_{g+1/2}=g\Delta v,\qquad
      v_g=\left(g-\frac12\right)\Delta v.

   非均匀接口接收边界 :math:`0=e_0<e_1<\cdots<e_{N_v}`，使用

   .. math::

      v_g=(e_{g-1}+e_g)/2,\qquad \Delta v_g=e_g-e_{g-1}.

   下面的面积公式对两种接口均成立；非均匀时将 :math:`\Delta v` 替换成 :math:`\Delta v_g`。
   只对分布值作中点近似，速度面积权重保留精确积分：

   .. math::

      \int_{v_{g-1/2}}^{v_{g+1/2}}F(v)\,v\,\mathrm dv
          \approx F(v_g)W^v_g,\qquad
      W^v_g=\int_{v_{g-1/2}}^{v_{g+1/2}}v\,\mathrm dv
           =\frac{v_{g+1/2}^2-v_{g-1/2}^2}{2}
           =v_g\Delta v.

   因此第一个速率节点严格大于零，后续 :math:`\nu_K/v_g` 和入射概率转换不会在零速率处除零。
   对区间内的常数函数，这个权重给出精确的速度面积；
   对随速度变化的分布仍有离散误差，不能据此称整个求积为精确积分。

   .. rubric:: 5. 合并索引、总权重与量纲

   程序将角度和速率合并为一个索引。每个速率取值下先排列所有角度：

   .. math::

      m=(g-1)N_\theta+a,\qquad N_{\mathrm{dir}}=N_vN_\theta,
      \qquad
      \boldsymbol v_m=v_g(\mu_a,\eta_a),\qquad
      w_m=W^v_gW^\theta_a.

   于是

   .. math::
      :label: sn-quadrature-sum

      I[F]\approx\sum_{m=1}^{N_{\mathrm{dir}}}w_mF(\boldsymbol v_m).

   这里 :math:`m` 同时确定一个速率 :math:`v_g` 和一个方向
   :math:`(\mu_a,\eta_a)`，合起来才是一个离散速度。
   例如 :math:`N_v=2,N_\theta=8` 时，共有 16 个离散速度；
   前 8 个具有同一速率、不同方向，后 8 个使用另一个速率。
   程序的 ``n_dir`` 存储这个总数，不能只按角度数分配数组。
   :math:`w_m` 的单位为 :math:`\mathrm{m^2\,s^{-2}}`；
   对常数函数，总权重为截断速度圆盘的面积：

   .. math::

      \sum_m w_m=2\pi\sum_g W^v_g=\pi v_{\max}^2.

   由同一规则得到的密度与流密度分别为

   .. math::

      n\approx\sum_m w_m\psi_m,\qquad
      n\boldsymbol u\approx\sum_mw_m\boldsymbol v_m\psi_m.

   密度求和不再额外乘速率，因为权重已经含有 :math:`v\,\mathrm dv`；
   流密度中的速度因子则来自所求物理量本身，两者不能相互替代。

   .. rubric:: 6. 各过程的输入与输出

   ``sub_J02_build_angular_nodes`` —— 生成角度规则。

   - 输入 ``n_angles``：角节点数，满足上述数量限制。
   - 输入 ``scheme``：当前识别 ``midpoint`` 和 ``gauss-chebyshev``，结果相同。
   - 输出 ``mu(n_angles)``、``eta(n_angles)``：无量纲方向余弦；
     输出 ``weight(n_angles)``：角权重 :math:`W^\theta_a`，不是最终二维权重。
   - 输出 ``ierr``：数量或方案名不合法时返回错误。输出数组由过程分配。

   ``sub_J02_build_speed_groups`` —— 生成速率节点及对应的速度面积权重。

   - 输入 ``n_speeds``：正整数；``speed_max``：正的截断速率，单位 :math:`\mathrm{m\,s^{-1}}`。
   - 输出 ``speed(n_speeds)``：正速率节点；
     ``weight(n_speeds)``：:math:`W^v_g`，单位 :math:`\mathrm{m^2\,s^{-2}}`。
   - 输出 ``ierr``：报告速率数量和截断速率是否有效。

   ``sub_J02_build_phase_quadrature`` —— 构造求解器使用的完整求积对象。

   - 输入 ``n_angles``、``n_speeds``、``angular_scheme``、``speed_max``。
   - 内部调用前两个过程，按速率组优先、角度在组内连续的顺序展开。
   - 输出 ``quadrature``：记录节点数量、速率上限，以及长度均为 ``n_dir`` 的
     ``mu``、``eta``、``speed``、``weight``。
     其中 ``weight`` 此时才是 :math:`w_m`。
   - 输出 ``ierr``：传播角度或速率构造错误。成功后，该对象可直接用于后续各过程。

   ``sub_J02_build_speed_groups_from_edges(speed_edge, speed, weight, ierr)``
   返回非均匀速率节点与径向权重。边界至少两个，须有限、严格递增且首项为零；
   不满足时返回 ``SN_ERR_SPEED_EDGES``，不能表示正节点/权重时返回 ``SN_ERR_SPEED_RANGE``。
   失败时输出数组不保留上次结果。

   ``sub_J02_build_phase_quadrature_from_edges(n_angles, speed_edge, angular_scheme, quadrature, ierr)``
   由边界推断组数及上限，输出与原接口相同的完整求积对象。每组仍使用相同的全部角度节点。

   .. code-block:: fortran

      call sub_J02_build_phase_quadrature_from_edges(128, speed_edge, 'midpoint', quad, ierr)

   .. rubric:: 7. 精度选择与更换求积方法

   角度数量控制方向分辨率，速率区间数控制有限速度区间内的分辨率，
   速率上限控制被截去的尾部范围。增加速率区间数并不能补回上限之外的分布；
   有漂移入口时，应同时考虑热速度尺度和漂移速度，检查有效分布是否落在截断圆盘内。

   当前非均匀速率接口保持了积分变量和面积元；若进一步增加其他求积规则，也应保证节点速率、权重为正，
   方向为单位向量。当前镜面方向查找依赖每个速率组内连续排列的等数量角节点；
   扫描还要求两个方向余弦都非零。修改规则时必须一并核查这些条件，
   不能只替换权重而假定反射映射仍然正确。

   后续入口页在这些节点上取分布值，入口归一化页用同一组 :math:`w_m`
   将分布归一化到给定入口通量；求解与重构继续使用这组离散速度。

   冷/快 Maxwell 分布以及混合分布的可重复对比位于
   ``tests/012_fluid/J02_neutral_sn_transport_2Drz/nonuniform_speed``。
   原始矩不先归一化，避免把欠分辨误差隐藏在归一化系数中；
   输运比较固定空间和角度分辨率，并另行报告角度、截断及参考解细化变化。

   .. rubric:: 参考文献

   .. _j02-quadrature-ref-cl65:

   B. G. Carlson and K. D. Lathrop (1965).
   *Transport Theory: The Method of Discrete Ordinates*.
   Los Alamos Scientific Laboratory, LA-3251-MS.
   `报告全文 <https://mcnp.lanl.gov/pdf_files/TechReport_1965_LANL_LA-3251-MS_CarlsonLathrop.pdf>`__

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``sub_J02_sn_quadrature.f90`` generates the discrete velocities and their integration weights. Inlet normalization, wall fluxes, the
   transport solve and density reconstruction all use this rule to approximate a continuous two-dimensional
   velocity integral by a finite sum.

   .. rubric:: 1. Quadrature used by J02

   The discrete ordinates method approximates an angular integral using values and weights at a finite set
   of directions. See :ref:`Carlson and Lathrop (1965) <j02-quadrature-ref-cl65-en>`, Section 3.3. J02 uses polar coordinates in the velocity plane and a product rule
   in angle and speed.

   - In angle, the composite midpoint rule takes the midpoint of each equal angular interval around the full
     circle.
   - In speed, the intervals may be uniform or supplied by the caller. The distribution is evaluated at the
     midpoint, and the weight integrates :math:`v\,\mathrm dv` exactly over the interval.
   - The caller chooses the upper speed limit, truncating the infinite velocity plane to a finite disk.

   This is midpoint quadrature. Gauss–Legendre and Gauss–Laguerre quadratures use different nodes and
   weights. In the current code the angular option ``gauss-chebyshev`` is an alias for ``midpoint``. Both call the same implementation
   and return identical nodes and weights.

   .. figure:: ../../../images/J_Fluid/sn_velocity_quadrature_en.svg
      :alt: Velocity disk divided into angular and speed intervals, with one midpoint node in each annular sector
      :width: 900px

      Each discrete velocity represents an annular sector. Equal angular intervals give different
      velocity-area weights when equal-width speed intervals lie at different radii. The orange sector has
      the weight :math:`W^v_gW^\theta_a` derived below.

   .. rubric:: 2. Velocity integrals in polar coordinates

   Integrating over velocity gives density or flux density. For example, at a fixed spatial position :math:`(r,z)`,

   .. math::

      n=\int_{\mathbb R^2}\psi(v_r,v_z)\,\mathrm dv_r\,\mathrm dv_z,\qquad
      j_r=\int_{\mathbb R^2}v_r\psi(v_r,v_z)\,\mathrm dv_r\,\mathrm dv_z.

   The first expression counts particles. The second includes radial velocity and gives the radial particle
   flux density. Let :math:`F(v_r,v_z)` denote the integrand for the desired quantity.

   - For density, :math:`F=\psi`.
   - For radial flux density, :math:`F=v_r\psi`.
   - For axial flux density, :math:`F=v_z\psi`.

   The quadrature routine returns the nodes and weights. The caller evaluates :math:`F` at the nodes and takes the
   weighted sum.

   Introduce the speed :math:`v` and direction angle :math:`\theta` to subdivide the velocity plane.

   .. math::

      v_r=v\cos\theta,\qquad v_z=v\sin\theta,\qquad
      \mathrm dv_r\,\mathrm dv_z=v\,\mathrm dv\,\mathrm d\theta.

   On the truncated disk the integral becomes

   .. math::

      I[F]=\int_0^{2\pi}\int_0^{v_{\max}}
                F(v\cos\theta,v\sin\theta)\,v\,\mathrm dv\,\mathrm d\theta.

   Here :math:`\theta` is the direction angle in the velocity plane, while :math:`\Theta` is the physical azimuthal extent. The
   polar-coordinate Jacobian supplies the factor :math:`v` in the weights.

   .. rubric:: 3. Angular midpoint nodes and weights

   Divide the full circle into :math:`N_\theta` equal intervals. The width and midpoints are

   .. math::

      \Delta\theta=\frac{2\pi}{N_\theta},\qquad
      \theta_a=\left(a-\frac12\right)\Delta\theta,\qquad
      a=1,\ldots,N_\theta.

   Using the midpoint value within each interval gives

   .. math::

      \int_0^{2\pi}F(\theta)\,\mathrm d\theta
          \approx\sum_{a=1}^{N_\theta}W^\theta_aF(\theta_a),\qquad
      W^\theta_a=\Delta\theta,\quad
      \mu_a=\cos\theta_a,\quad\eta_a=\sin\theta_a.

   J02 requires :math:`N_\theta\geq8` with the count divisible by four. Each quadrant then has the same structure, the nodes
   avoid the coordinate axes, and radial and axial specular reflections have paired directions. A sweep
   requires nonzero direction cosines, making this a calling requirement as well as a resolution choice.

   .. rubric:: 4. Speed nodes and weights

   The uniform-grid interface divides :math:`[0,v_{\max}]` into :math:`N_v` intervals.

   .. math::

      \Delta v=\frac{v_{\max}}{N_v},\qquad
      v_{g-1/2}=(g-1)\Delta v,\qquad
      v_{g+1/2}=g\Delta v,\qquad
      v_g=\left(g-\frac12\right)\Delta v.

   The nonuniform interface takes edges :math:`0=e_0<e_1<\cdots<e_{N_v}` and uses

   .. math::

      v_g=(e_{g-1}+e_g)/2,\qquad \Delta v_g=e_g-e_{g-1}.

   The following area formula applies to both interfaces. For nonuniform edges replace :math:`\Delta v` by :math:`\Delta v_g`. The
   midpoint approximation applies to the distribution value, while the velocity-area weight is integrated
   exactly.

   .. math::

      \int_{v_{g-1/2}}^{v_{g+1/2}}F(v)\,v\,\mathrm dv
          \approx F(v_g)W^v_g,\qquad
      W^v_g=\int_{v_{g-1/2}}^{v_{g+1/2}}v\,\mathrm dv
           =\frac{v_{g+1/2}^2-v_{g-1/2}^2}{2}
           =v_g\Delta v.

   The first speed node is strictly positive, so :math:`\nu_K/v_g` and the conversion of incoming probabilities do not
   divide by zero speed. The weight integrates a constant exactly over the interval. A speed-dependent
   distribution still has quadrature error.

   .. rubric:: 5. Combined index, total weight and units

   The implementation combines angle and speed into a single index. All angles are contiguous within each
   speed group.

   .. math::

      m=(g-1)N_\theta+a,\qquad N_{\mathrm{dir}}=N_vN_\theta,
      \qquad
      \boldsymbol v_m=v_g(\mu_a,\eta_a),\qquad
      w_m=W^v_gW^\theta_a.

   The resulting nodes and weights are

   .. math::
      :label: sn-quadrature-sum-en

      I[F]\approx\sum_{m=1}^{N_{\mathrm{dir}}}w_mF(\boldsymbol v_m).

   Index :math:`m` selects both a speed :math:`v_g` and a direction :math:`(\mu_a,\eta_a)`, together defining one discrete velocity. For
   example, :math:`N_v=2,N_\theta=8` gives 16 velocities. The first eight share one speed and cover eight directions, and the next
   eight use the other speed. ``n_dir`` stores the total number of velocities. Allocate arrays for that total. The
   units of :math:`w_m` are :math:`\mathrm{m^2\,s^{-2}}`, and the weights for a constant sum to the area of the truncated disk.

   .. math::

      \sum_m w_m=2\pi\sum_g W^v_g=\pi v_{\max}^2.

   The same rule gives the following density and flux density.

   .. math::

      n\approx\sum_m w_m\psi_m,\qquad
      n\boldsymbol u\approx\sum_mw_m\boldsymbol v_m\psi_m.

   The density sum already includes :math:`v\,\mathrm dv` through the weight. The extra velocity factor in flux density comes
   from the physical quantity being integrated.

   .. rubric:: 6. Routine inputs and outputs

   ``sub_J02_build_angular_nodes`` constructs the angular rule.

   - Input ``n_angles`` is the angular node count, subject to the restrictions above.
   - Input ``scheme`` accepts ``midpoint`` and ``gauss-chebyshev``, which give identical results.
   - Outputs ``mu(n_angles)`` and ``eta(n_angles)`` are dimensionless direction cosines. Output ``weight(n_angles)`` contains the angular weights :math:`W^\theta_a`, one
     factor in the two-dimensional weights.
   - Output ``ierr`` reports an invalid count or scheme name. The routine allocates the output arrays.

   ``sub_J02_build_speed_groups`` generates speed nodes and their velocity-area weights.

   - Inputs are ``n_speeds``, a positive integer, and ``speed_max``, a positive cutoff speed in :math:`\mathrm{m\,s^{-1}}`.
   - Output ``speed(n_speeds)`` contains positive speed nodes. ``weight(n_speeds)`` contains :math:`W^v_g` in :math:`\mathrm{m^2\,s^{-2}}`.
   - Output ``ierr`` reports whether the count and cutoff speed are valid.

   ``sub_J02_build_phase_quadrature`` constructs the complete quadrature object used by the solver.

   - Inputs are ``n_angles``, ``n_speeds``, ``angular_scheme`` and ``speed_max``.
   - The routine calls the preceding two builders, expanding the nodes by speed group with consecutive
     angular nodes within each group.
   - Output ``quadrature`` records the node count, speed cutoff and four arrays of length ``n_dir``, namely ``mu``, ``eta``, ``speed`` and ``weight``.
     In this object ``weight`` contains the complete two-dimensional weights :math:`w_m`.
   - Output ``ierr`` propagates errors from angular or speed construction. On success, subsequent routines can use
     the object directly.

   ``sub_J02_build_speed_groups_from_edges(speed_edge, speed, weight, ierr)`` returns nonuniform speed nodes and radial weights. Supply at least two finite, strictly increasing
   edges starting at zero. Invalid edges give ``SN_ERR_SPEED_EDGES``, and an unrepresentable positive node or weight gives ``SN_ERR_SPEED_RANGE``.
   On failure the output arrays do not retain earlier results.

   ``sub_J02_build_phase_quadrature_from_edges(n_angles, speed_edge, angular_scheme, quadrature, ierr)`` infers the group count and speed cutoff from the edges and produces the same complete quadrature
   object as the uniform interface. Every group uses the full set of angular nodes.

   .. code-block:: fortran

      call sub_J02_build_phase_quadrature_from_edges(128, speed_edge, 'midpoint', quad, ierr)

   .. rubric:: 7. Choosing resolution and changing the quadrature

   The angle count controls directional resolution. The speed interval count controls resolution up to the
   cutoff, and the cutoff determines how much of the tail is discarded. Refining a fixed interval cannot
   recover a tail beyond it. For a drifting inlet, consider both the thermal speed and drift velocity when
   checking that the disk captures the distribution.

   The nonuniform-speed interface preserves the integration variables and area element. Any alternative
   quadrature must supply positive speeds and weights and unit directions. Specular direction lookup assumes
   the same number of consecutive angular nodes in each speed group. Sweeping also requires both direction
   cosines to be nonzero. Recheck these conditions and the reflection mapping when changing the rule.

   The inlet routines evaluate their distributions at these nodes. Inlet normalization uses the same :math:`w_m` to
   obtain the specified inlet flux. The solve and reconstruction retain the same discrete velocities.

   Reproducible comparisons for cold, fast and mixed Maxwellian distributions are available in ``tests/012_fluid/J02_neutral_sn_transport_2Drz/nonuniform_speed``. Raw
   moments are measured before normalization so that a normalization factor cannot conceal under-resolution.
   The transport comparison fixes spatial and angular resolution and separately reports changes under
   angular refinement, speed truncation and reference-solution refinement.

   .. rubric:: References

   .. _j02-quadrature-ref-cl65-en:

   Carlson, B. G., and K. D. Lathrop (1965).
   *Transport Theory: The Method of Discrete Ordinates*.
   Los Alamos Scientific Laboratory, LA-3251-MS.
   `Full report <https://mcnp.lanl.gov/pdf_files/TechReport_1965_LANL_LA-3251-MS_CarlsonLathrop.pdf>`__
