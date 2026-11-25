Wall Reflection
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J02_sn_wall.f90`` 计算壁面反射所需的方向对应关系、热速度分布和归一化系数。
   当前模型中的壁面静止，不吸附也不产生粒子：撞到壁面的粒子全部返回气体区域。
   其中一部分发生镜面反射，另一部分按壁面温度发生热漫反射。
   壁温和两种反射的比例由调用者给定。

   .. rubric:: 1. 先明确壁面区域和入射、出射的含义

   本页的法向 :math:`\boldsymbol n_f` 始终是从气体计算域指向外部的单位法向。
   因此，对气体域而言：

   - :math:`\beta_{f,m}=\boldsymbol\Omega_m\cdot\boldsymbol n_f>0`：
     粒子离开气体域、撞向壁面，记为出射；
   - :math:`\beta_{f,m}<0`：粒子经壁面反射返回气体域，记为入射。

   “出射”不是指离开固体壁面。保持这一法向约定，壁面与入口、出口使用的通量符号才一致。

   :math:`W` 表示一个空间单元面上实际反射的区域，不是整个装置的全部壁面。
   一个面完全反射时，:math:`W` 就是该面；下端面含部分入口时，
   :math:`W` 是入口以外的两段壁面区域的并集。
   面积记为

   .. math::

      A_W=\int_W\mathrm dA.

   径向面有 :math:`\mathrm dA=\Theta r_f\,\mathrm dz`，
   轴向面有 :math:`\mathrm dA=\Theta r\,\mathrm dr`。
   :math:`A_W` 因此是三维物理面面积，单位为 :math:`\mathrm{m^2}`，
   不是截面图上边界线的长度。

   用 :math:`\boldsymbol x=(r,z)\in W` 表示壁面位置。
   :math:`\psi^{\mathrm{out}}_{W,m}(\boldsymbol x)`
   是相邻气体单元的分布函数在这个位置、这个出射速度上的值。
   壁面模型要根据它确定
   :math:`\psi^{\mathrm{in}}_{W,m}(\boldsymbol x)`，作为气体域的反射入流。

   .. rubric:: 2. 镜面反射：同一位置、同一速率、法向速度反号

   静止镜面不改变速率和切向速度，只改变法向速度的符号。
   对一个返回气体域的入射速度 :math:`m`，寻找与之对应的撞壁速度 :math:`R_f(m)`：

   .. math::

      \boldsymbol\Omega_{R_f(m)}
        =\boldsymbol\Omega_m-2\beta_{f,m}\boldsymbol n_f,\qquad
      v_{R_f(m)}=v_m.

   径向壁改变 :math:`\mu_m` 的符号，轴向壁改变 :math:`\eta_m` 的符号。
   反射前后使用同一个壁面位置，所以纯镜面条件是

   .. math::

      \psi^{\mathrm{spec}}_{W,m}(\boldsymbol x)
          =\psi^{\mathrm{out}}_{W,R_f(m)}(\boldsymbol x),
          \qquad \beta_{f,m}<0.

   当前求积的反射方向成对出现，并满足
   :math:`w_{R_f(m)}=w_m` 和
   :math:`\beta_{f,R_f(m)}=-\beta_{f,m}`。
   因此配对速度的法向粒子通量大小相同，纯镜面反射保持粒子数。
   若以后改变角度求积或使用不与坐标轴对齐的壁面，必须重新检查这些配对条件。

   ``fun_J02_reflected_direction_index``：

   - 输入 ``quadrature``、离散速度索引 ``direction`` 和单位法向 ``normal_r/normal_z``。
   - 返回整数索引 :math:`R_f(m)`。先计算理论反射方向，再在同一速率下的所有方向中，
     选取与它点积最大的方向。
   - 不返回 ``ierr``。有效索引、单位法向及按速率分组的排列由调用者保证。
     对当前求积可以找到成对方向；一般角度规则下，该查找可能只是最近方向近似。

   .. rubric:: 3. 热漫反射：速度分布由壁温决定

   热漫反射不保留粒子的原运动方向。当前用壁温 :math:`T_{\mathrm w}`
   确定反射后的二维 Maxwell 速度分布，先计算

   .. math::

      g_{\mathrm w,m}
         =\exp\!\left(-\frac{Mv_m^2}{2k_{\mathrm B}T_{\mathrm w}}\right).

   :math:`M` 是粒子质量，:math:`k_{\mathrm B}` 是 Boltzmann 常数。
   这里的 :math:`g_{\mathrm w,m}` 无量纲，只给出不同速度之间的相对分布。
   实际反射分布还需乘系数 :math:`C_W`：

   .. math::

      \psi^{\mathrm{diff}}_{W,m}(\boldsymbol x)=C_Wg_{\mathrm w,m},
      \qquad \boldsymbol x\in W,\quad\beta_{f,m}<0.

   当前代码为一个 :math:`W` 计算一个常数 :math:`C_W`，因此该区域内的纯漫反射分布
   不随位置变化。:math:`C_W` 的单位与 :math:`\psi` 相同，为
   :math:`\mathrm{s^2\,m^{-5}}`。
   它的数值由撞到这个区域的粒子总量决定，而不是直接由温度决定。

   ``sub_J02_build_wall_maxwell_shape``：

   - 输入 ``quadrature``、正的 ``temperature`` （:math:`\mathrm K`）、
     ``particle_mass`` （:math:`\mathrm{kg}`）。
   - 输出并分配 ``wall_shape(n_dir)``，即 :math:`g_{\mathrm w,m}`。
   - 输出 ``ierr``。非正温度或质量返回错误；求积须已成功初始化。
     所有速度上的指数值均下溢为零时，返回壁面归一化错误，应检查壁温和速度范围。

   .. rubric:: 4. 从撞壁粒子率推导漫反射系数

   先计算撞到 :math:`W` 的粒子率。对于一个出射速度，
   :math:`v_m\beta_{f,m}\psi^{\mathrm{out}}_{W,m}`
   是该速度处每单位速度面积的法向通量贡献；乘以速度面积权重，再对壁面面积积分，得到

   .. math::

      Q_W^{\mathrm{out}}
        =\sum_{\beta_{f,m}>0}w_mv_m\beta_{f,m}
           \int_W\psi^{\mathrm{out}}_{W,m}(\boldsymbol x)\,\mathrm dA.

   这个量非负，单位为 :math:`\mathrm{s^{-1}}`，表示单位时间撞到该区域的粒子数。

   现在假设这些粒子全部采用漫反射返回，纯漫反射的粒子率应按同样方式计算：

   .. math::

      \begin{aligned}
      Q_W^{\mathrm{diff}}
        &=\sum_{\beta_{f,m}<0}w_mv_m|\beta_{f,m}|
            \int_W\psi^{\mathrm{diff}}_{W,m}(\boldsymbol x)\,\mathrm dA\\
        &=\sum_{\beta_{f,m}<0}w_mv_m|\beta_{f,m}|
            \int_W C_Wg_{\mathrm w,m}\,\mathrm dA\\
        &=C_W A_W
            \sum_{\beta_{f,m}<0}w_mv_m|\beta_{f,m}|g_{\mathrm w,m}.
      \end{aligned}

   最后一步使用了 :math:`C_W` 和 :math:`g_{\mathrm w,m}` 在区域内不随位置变化这一假设。
   不是把任意非均匀壁面分布的积分都替换成面积乘一点的值。

   由于壁面不吸附、不产生粒子，纯漫反射应返回全部撞壁粒子，即
   :math:`Q_W^{\mathrm{diff}}=Q_W^{\mathrm{out}}`。由此才得到

   .. math::

      C_W=
        \frac{Q_W^{\mathrm{out}}}
             {A_W\displaystyle\sum_{\beta_{f,m}<0}
                w_mv_m|\beta_{f,m}|g_{\mathrm w,m}}.

   因此面积 :math:`A_W`、速度权重 :math:`w_m` 和法向速率
   :math:`v_m|\beta_{f,m}|` 各有不同作用，不能互相省略。

   这个条件保证 :math:`W` 上的积分粒子收支。
   如果撞壁通量沿壁面变化，严格的逐点漫反射模型应使用随位置变化的 :math:`C(\boldsymbol x)`。
   当前代码采用区域内统一的 :math:`C_W`，不保证每个位置的漫反射入流与撞壁通量分别相等。
   这是现有壁面离散的空间近似；镜面项仍保留原出射分布沿面的变化。

   .. rubric:: 5. 混合反射的完整边界条件

   令 :math:`d\in[0,1]` 为漫反射比例，且当前在壁面区域内为常数。
   用前面分别构造的纯镜面与纯漫反射分布混合，得到

   .. math::
      :label: sn-wall-mixture

      \boxed{
      \psi^{\mathrm{in}}_{W,m}(\boldsymbol x)
         =(1-d)\psi^{\mathrm{out}}_{W,R_f(m)}(\boldsymbol x)
            +d\,C_Wg_{\mathrm w,m}},
      \qquad \boldsymbol x\in W,\quad\beta_{f,m}<0.

   这条式子只规定返回气体域的方向。出射分布由气体域内的输运解给出，
   不再另行施加反射值。:math:`R_f(m)` 表示对应的出射速度，:math:`C_W`
   按该区域的全部撞壁粒子率计算，然后再乘漫反射比例。

   纯镜面和纯漫反射各自保持完整的撞壁粒子率，所以混合后的收支是

   .. math::

      Q_W^{\mathrm{in}}
         =(1-d)Q_W^{\mathrm{spec}}+dQ_W^{\mathrm{diff}}
         =(1-d)Q_W^{\mathrm{out}}+dQ_W^{\mathrm{out}}
         =Q_W^{\mathrm{out}}.

   实际漫反射部分的粒子率是 :math:`dQ_W^{\mathrm{out}}`，
   镜面部分是 :math:`(1-d)Q_W^{\mathrm{out}}`。
   不要把式中用于归一化的纯漫反射粒子率，误认为混合模型中已经乘过 :math:`d` 的部分。

   .. rubric:: 6. 代码如何计算区域积分与系数

   ``sub_J02_compute_diffuse_wall_constants``：

   - 输入 ``mesh``、``geometry``、``quadrature``、``boundary``，
     ``wall_shape(n_dir)`` 和 ``psi_old(3,nr,nz,n_dir)``。
     后者是上一轮分布的三个空间多项式系数，用于计算本轮的撞壁粒子率。
   - 可选输入 ``zlo_source_xi_lo(nr)`` 与 ``zlo_source_xi_hi(nr)``，
     两者同时提供，用于从下端面中排除入口区间。
   - 输出 ``diffuse_constant(4,nr,nz)``，即每个单元面反射区域上的 :math:`C_W`。
     无反射区域的位置为零。
   - 输出 ``ierr``，拒绝过小或为零的归一化分母；输入数组形状与区间遵守扫描接口约定。
     代码将负的计算系数截为零；非负出射分布应给出非负系数，无需此修正。

   整面壁面先计算出射分布的面积平均值，
   :math:`\int_W\psi\,\mathrm dA=A_W\overline\psi_W`，
   于是 :math:`A_W` 在 :math:`C_W` 的分子、分母中约去。
   这就是整面分支没有显式乘物理面面积的原因。

   部分入口两侧的反射区域对应
   :math:`[-1,\xi_L]\cup[\xi_H,1]`。程序分别积分两段、将结果相加，再除以两段总面积。
   这两段共用一个 :math:`C_W`，不是分别归一化，也不包括入口区间。
   共同的周向张角同样在分子、分母中抵消。

   .. rubric:: 7. 法向与整面平均值的辅助过程

   ``sub_J02_face_normal`` 是返回面外法向的子程序，名称与 ``sub_J02_`` 前缀一致。

   - 输入 ``face_id``，输出 ``normal_r``、``normal_z``。
   - 四面顺序为径向低端、径向高端、轴向低端、轴向高端，法向分别为
     :math:`(-1,0),(1,0),(0,-1),(0,1)`。
   - 未知编号返回零向量，不另报错误；调用者须传入合法面常量。

   ``fun_J02_face_trace`` 返回一次多项式的整面面积平均值。

   - 输入 ``coeff(3)``、``face_id`` 和 ``xi_bar``；
     输出为与分布函数同单位的实数。
   - 对 :math:`\psi=c_0+c_1\xi+c_2\zeta`，四面的平均值分别为

   .. math::

      \overline\psi_{r-}=c_0-c_1,\quad
      \overline\psi_{r+}=c_0+c_1,\qquad
      \overline\psi_{z-}=c_0+\overline\xi c_1-c_2,\quad
      \overline\psi_{z+}=c_0+\overline\xi c_1+c_2.

   径向面上，:math:`\zeta` 的平均为零；轴向面按 :math:`r\,\mathrm dr` 加权，
   所以 :math:`\overline\xi=h_r/(3r_c)` 一般不为零。
   该过程只适用于整面平均，部分壁面必须使用 DG 文件中的区间积分过程。

   .. rubric:: 8. 壁面关系怎样进入输运求解

   壁面出射分布依赖域内解，域内解又依赖壁面反射入流，因此需要迭代。
   每轮扫描开始前，代码用上一轮的出射分布计算 :math:`C_W`；
   镜面项也读取上一轮的反射方向系数。本轮各离散速度都把这些已知反射入流加入单元方程右端。

   DG 页将说明这些已知分布怎样形成右端积分，Reflection Iteration 页再展开一轮到下一轮
   的更新过程。收敛后，壁面入流与最终出射分布满足上述反射关系，精度受迭代容差限制。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``sub_J02_sn_wall.f90`` supplies reflected directions, the thermal velocity shape and normalization factors for wall
   reflection. The walls are stationary. Every particle that strikes a wall returns to the gas, with no
   adsorption or production. The caller specifies the wall temperature and the fractions of specular and
   thermal diffuse reflection.

   .. rubric:: 1. Wall regions and the meanings of incoming and outgoing

   The unit normal :math:`\boldsymbol n_f` points outward from the gas domain. All directions below use the gas domain as their
   frame of reference.

   - :math:`\beta_{f,m}=\boldsymbol\Omega_m\cdot\boldsymbol n_f>0` is outgoing. Particles leave the gas domain and strike the wall.
   - :math:`\beta_{f,m}<0` is incoming. Reflected particles return to the gas domain.

   An outgoing particle travels toward the solid. This definition keeps the wall flux sign consistent with
   inlet and outlet conventions.

   :math:`W` is the reflecting part of one spatial cell face. For a fully reflecting face, :math:`W` covers the entire
   face. For a lower face with a partial inlet, :math:`W` is the union of the two wall segments outside the inlet.
   Its area is

   .. math::

      A_W=\int_W\mathrm dA.

   The radial face measure is :math:`\mathrm dA=\Theta r_f\,\mathrm dz` and the axial face measure is :math:`\mathrm dA=\Theta r\,\mathrm dr`. Thus :math:`A_W` is a three-dimensional physical
   area in :math:`\mathrm{m^2}`. The boundary seen as a line in the cross-section has a different measure.

   Let :math:`\boldsymbol x=(r,z)\in W` denote a point on the wall. :math:`\psi^{\mathrm{out}}_{W,m}(\boldsymbol x)` is the trace from the adjacent gas cell at that point for an
   outgoing velocity. The wall model uses the outgoing distribution to determine :math:`\psi^{\mathrm{in}}_{W,m}(\boldsymbol x)`, the reflected inflow to
   the gas.

   .. rubric:: 2. Specular reflection at fixed position and speed

   A stationary specular wall preserves speed and tangential velocity and reverses the normal component. For
   each incoming velocity index :math:`m` returning to the gas, find the corresponding incident-on-wall velocity
   index :math:`R_f(m)`.

   .. math::

      \boldsymbol\Omega_{R_f(m)}
        =\boldsymbol\Omega_m-2\beta_{f,m}\boldsymbol n_f,\qquad
      v_{R_f(m)}=v_m.

   A radial wall reverses :math:`\mu_m` and an axial wall reverses :math:`\eta_m`. Reflection occurs at the same point on the wall,
   giving the pure specular condition

   .. math::

      \psi^{\mathrm{spec}}_{W,m}(\boldsymbol x)
          =\psi^{\mathrm{out}}_{W,R_f(m)}(\boldsymbol x),
          \qquad \beta_{f,m}<0.

   For the current quadrature, reflected directions come in pairs with :math:`w_{R_f(m)}=w_m` and :math:`\beta_{f,R_f(m)}=-\beta_{f,m}`. Each pair therefore has
   equal normal particle flux magnitudes, and pure specular reflection conserves particles. Recheck these
   pairings for alternative angular rules or walls that are not aligned with the coordinate axes.

   ``fun_J02_reflected_direction_index``：

   - Inputs are ``quadrature``, discrete velocity index ``direction`` and unit normal ``normal_r/normal_z``.
   - The result is the integer index :math:`R_f(m)`. The function calculates the ideal reflected direction and chooses
     the direction at the same speed with the largest dot product against it.
   - There is no ``ierr`` output. The caller supplies a valid index, unit normal and ordering by speed group. The
     current rule has exact direction pairs. For a general angular rule the lookup may only identify the
     nearest direction.

   .. rubric:: 3. Thermal diffuse reflection at the wall temperature

   Thermal diffuse reflection loses the incoming particle's original direction. The model uses wall
   temperature :math:`T_{\mathrm w}` to evaluate the following two-dimensional Maxwellian velocity shape.

   .. math::

      g_{\mathrm w,m}
         =\exp\!\left(-\frac{Mv_m^2}{2k_{\mathrm B}T_{\mathrm w}}\right).

   :math:`M` is particle mass and :math:`k_{\mathrm B}` is Boltzmann's constant. The dimensionless :math:`g_{\mathrm w,m}` describes the relative
   populations at different velocities. To obtain the physical reflected distribution, multiply by :math:`C_W`.

   .. math::

      \psi^{\mathrm{diff}}_{W,m}(\boldsymbol x)=C_Wg_{\mathrm w,m},
      \qquad \boldsymbol x\in W,\quad\beta_{f,m}<0.

   The implementation assigns one constant :math:`C_W` to each :math:`W`. Its purely diffuse distribution is uniform in
   position within that region. :math:`C_W` has the same units as :math:`\psi`, namely :math:`\mathrm{s^2\,m^{-5}}`. The total number of particles
   reaching that wall region sets the normalization, whereas temperature sets the shape.

   ``sub_J02_build_wall_maxwell_shape``：

   - Inputs are ``quadrature``, positive ``temperature`` in :math:`\mathrm K` and ``particle_mass`` in :math:`\mathrm{kg}`.
   - The routine allocates output ``wall_shape(n_dir)``, which contains :math:`g_{\mathrm w,m}`.
   - Output ``ierr`` reports nonpositive temperature or mass. Initialize the quadrature before calling. If the
     exponential underflows to zero at all speeds, the routine returns a wall normalization error. Check the
     wall temperature and the sampled speed range.

   .. rubric:: 4. Deriving the diffuse coefficient from the incident particle rate

   First find the particle rate striking :math:`W`. For an outgoing velocity, :math:`v_m\beta_{f,m}\psi^{\mathrm{out}}_{W,m}` is the normal flux contribution
   per unit velocity-space area. Multiply by the velocity-area weight and integrate over wall area to obtain

   .. math::

      Q_W^{\mathrm{out}}
        =\sum_{\beta_{f,m}>0}w_mv_m\beta_{f,m}
           \int_W\psi^{\mathrm{out}}_{W,m}(\boldsymbol x)\,\mathrm dA.

   This nonnegative rate in :math:`\mathrm{s^{-1}}` counts the particles striking the region per unit time.

   If all of those particles return diffusely, compute the purely diffuse return rate with the same
   measures.

   .. math::

      \begin{aligned}
      Q_W^{\mathrm{diff}}
        &=\sum_{\beta_{f,m}<0}w_mv_m|\beta_{f,m}|
            \int_W\psi^{\mathrm{diff}}_{W,m}(\boldsymbol x)\,\mathrm dA\\
        &=\sum_{\beta_{f,m}<0}w_mv_m|\beta_{f,m}|
            \int_W C_Wg_{\mathrm w,m}\,\mathrm dA\\
        &=C_W A_W
            \sum_{\beta_{f,m}<0}w_mv_m|\beta_{f,m}|g_{\mathrm w,m}.
      \end{aligned}

   The final equality uses the assumption that :math:`C_W` and :math:`g_{\mathrm w,m}` are constant across the region. An arbitrary
   nonuniform distribution must be integrated over the wall.

   The wall neither retains nor produces particles. Purely diffuse reflection returns the full incident
   rate, so :math:`Q_W^{\mathrm{diff}}=Q_W^{\mathrm{out}}`. This determines the normalization.

   .. math::

      C_W=
        \frac{Q_W^{\mathrm{out}}}
             {A_W\displaystyle\sum_{\beta_{f,m}<0}
                w_mv_m|\beta_{f,m}|g_{\mathrm w,m}}.

   The area :math:`A_W`, velocity-area weight :math:`w_m` and normal speed :math:`v_m|\beta_{f,m}|` each account for a different measure and all
   enter the normalization.

   This condition enforces particle balance integrated over :math:`W`. If the incident flux varies along the wall,
   a pointwise diffuse model would use a position-dependent :math:`C(\boldsymbol x)`. J02 uses one :math:`C_W` over the region, so local
   diffuse inflow can differ from local incident flux. The specular part retains the variation of the
   outgoing distribution along the face.

   .. rubric:: 5. Mixed reflection boundary condition

   Let :math:`d\in[0,1]` be the diffuse fraction, assumed constant on the wall region. Mixing the pure specular and pure
   diffuse distributions gives

   .. math::
      :label: sn-wall-mixture-en

      \boxed{
      \psi^{\mathrm{in}}_{W,m}(\boldsymbol x)
         =(1-d)\psi^{\mathrm{out}}_{W,R_f(m)}(\boldsymbol x)
            +d\,C_Wg_{\mathrm w,m}},
      \qquad \boldsymbol x\in W,\quad\beta_{f,m}<0.

   This condition prescribes only velocities returning to the gas. The interior transport solution supplies
   the outgoing distribution. :math:`R_f(m)` identifies the paired outgoing velocity. The entire incident rate on the
   region determines :math:`C_W` before the diffuse fraction is applied.

   Each pure reflection model returns the full incident rate. The mixed balance therefore gives

   .. math::

      Q_W^{\mathrm{in}}
         =(1-d)Q_W^{\mathrm{spec}}+dQ_W^{\mathrm{diff}}
         =(1-d)Q_W^{\mathrm{out}}+dQ_W^{\mathrm{out}}
         =Q_W^{\mathrm{out}}.

   The actual diffuse return rate is :math:`dQ_W^{\mathrm{out}}`, and the specular rate is :math:`(1-d)Q_W^{\mathrm{out}}`. The purely diffuse rate used for
   normalization is evaluated before applying :math:`d` in the mixture.

   .. rubric:: 6. Computing the region integrals and coefficients

   ``sub_J02_compute_diffuse_wall_constants``：

   - Inputs are ``mesh``, ``geometry``, ``quadrature``, ``boundary``, ``wall_shape(n_dir)`` and ``psi_old(3,nr,nz,n_dir)``. The last array holds the three spatial coefficients from the
     previous iteration for computing this iteration's incident particle rate.
   - Optional inputs ``zlo_source_xi_lo(nr)`` and ``zlo_source_xi_hi(nr)`` are supplied together to exclude the lower inlet interval from wall
     integration.
   - Output ``diffuse_constant(4,nr,nz)`` stores :math:`C_W` on the reflecting region of each cell face. Entries with no reflecting region are
     zero.
   - Output ``ierr`` reports a zero or excessively small normalization denominator. Input shapes and intervals
     must follow the sweep interface conventions. The code clips a negative computed coefficient to zero. A
     nonnegative outgoing distribution already yields a nonnegative coefficient.

   For a full wall face, first calculate the area average of the outgoing distribution, giving :math:`\int_W\psi\,\mathrm dA=A_W\overline\psi_W`. The
   factor :math:`A_W` then cancels from the numerator and denominator in :math:`C_W`, so the full-face branch needs no
   explicit physical area factor.

   The reflecting segments on either side of a partial inlet cover :math:`[-1,\xi_L]\cup[\xi_H,1]`. The code integrates both segments,
   sums their contributions and divides by their combined area. The segments share the same :math:`C_W` and exclude
   the inlet interval. The common azimuthal extent also cancels in the ratio.

   .. rubric:: 7. Face normals and whole-face averages

   ``sub_J02_face_normal`` returns a face's outward normal. Its name follows the ``sub_J02_`` subroutine prefix.

   - Input is ``face_id``. Outputs are ``normal_r`` and ``normal_z``.
   - Faces are ordered radial low, radial high, axial low, axial high. Their normals are :math:`(-1,0),(1,0),(0,-1),(0,1)`, respectively.
   - An unknown index returns the zero vector without a separate error code. Supply a valid face constant.

   ``fun_J02_face_trace`` returns the whole-face area average of a linear polynomial.

   - Inputs are ``coeff(3)``, ``face_id`` and ``xi_bar``. The return value is real and has the units of the distribution function.
   - For :math:`\psi=c_0+c_1\xi+c_2\zeta` the four face averages are

   .. math::

      \overline\psi_{r-}=c_0-c_1,\quad
      \overline\psi_{r+}=c_0+c_1,\qquad
      \overline\psi_{z-}=c_0+\overline\xi c_1-c_2,\quad
      \overline\psi_{z+}=c_0+\overline\xi c_1+c_2.

   On a radial face the mean of :math:`\zeta` is zero. An axial face uses the weight :math:`r\,\mathrm dr`, so :math:`\overline\xi=h_r/(3r_c)` is generally nonzero.
   This routine applies to whole-face averages. For a partial wall use the interval integration routines in
   the DG file.

   .. rubric:: 8. Using the wall condition in a transport solve

   The outgoing wall distribution depends on the interior solution, which in turn depends on the reflected
   inflow. At the start of each iteration, the previous outgoing distribution supplies :math:`C_W` and the
   coefficients in the reflected direction for the specular term. Each velocity solve includes this known
   reflected inflow on the right-hand side of its cell equation.

   The DG page explains how the prescribed distributions enter the right-hand side integrals. The Reflection
   Iteration page follows the updates between sweeps. At convergence, reflected inflow and the final
   outgoing distribution satisfy the wall condition to the iteration tolerance.
