.. J_Fluid contribution history (Git author dates; edit times include timezone).
   2026-09-18 12:00 +08:00 | Yingjie Chen | git 69bdc8603906
   2026-10-06 23:50 +08:00 | Yingjie Chen | git fa8cb9f5be05
   2026-11-25 15:14 +08:00 | Yingjie Chen | git 8652258184b5
   2026-11-25 15:59 +08:00 | Yingjie Chen | edit (Codex-assisted)

J02 Discrete Ordinates
==========================================================================================

.. toctree::
   :maxdepth: 1
   :titlesonly:

   01 Mesh and Geometry <J02_neutral_sn_transport_2Drz/sub_J02_sn_geometry>
   02 Velocity Quadrature <J02_neutral_sn_transport_2Drz/sub_J02_sn_quadrature>
   03 Boundary Geometry <J02_neutral_sn_transport_2Drz/sub_J02_sn_boundary>
   04 Inlet Distribution <J02_neutral_sn_transport_2Drz/sub_J02_sn_inflow>
   05 Inlet Normalization <J02_neutral_sn_transport_2Drz/sub_J02_sn_source>
   06 Wall Reflection <J02_neutral_sn_transport_2Drz/sub_J02_sn_wall>
   07 Volume Loss <J02_neutral_sn_transport_2Drz/sub_J02_sn_loss>
   08 DG Discretization <J02_neutral_sn_transport_2Drz/sub_J02_sn_dg_operator>
   09 Upwind Sweep <J02_neutral_sn_transport_2Drz/sub_J02_sn_sweep>
   10 Reflection Iteration <J02_neutral_sn_transport_2Drz/sub_J02_sn_reflection>
   11 Field Reconstruction <J02_neutral_sn_transport_2Drz/sub_J02_sn_reconstruction>
   12 Complete Calculation <J02_neutral_sn_transport_2Drz/sub_J02_sn_transport>
   13 Spatial MPI Partition <J02_neutral_sn_transport_2Drz/sub_J02_sn_partition>
   14 Distributed Sweep and Flux <J02_neutral_sn_transport_2Drz/sub_J02_sn_mpi_sweep>
   Error Reference <J02_neutral_sn_transport_2Drz/sub_J02_sn_error>

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   J02 求解稳态中性粒子输运问题。输入包括计算域、入口粒子率与速度分布、壁面反射条件、
   开放出口和体损失；输出是中性粒子的密度、平均速度及各网格面上的粒子通量。

   计算的出发点是：具有不同速度的粒子沿不同方向运动，也可能有不同的损失强度。
   离散纵标法（Discrete Ordinates Method，记作 SN）选取有限组确定的速度，
   分别计算每组速度的粒子在空间中怎样分布，再对这些分布作加权求和，得到密度和通量。
   其中，用有限个方向及其权重近似角积分的原理见
   :ref:`Carlson 与 Lathrop（1965） <j02-overview-ref-cl65>` 第 3.3 节。

   空间上采用一阶不连续 Galerkin 方法（Discontinuous Galerkin，记作 DG，具体为 P1-DG）。
   每个单元内用一次多项式表示分布，保存常数项和两个方向的一次项系数；
   相邻单元通过面上的入流、出流联系起来。这里的“一阶”指多项式次数，
   不是对所有算例的误差收敛阶作保证；保正处理还可能将个别单元退回常数表示。
   关于输运方程中如何用迎风侧的分布连接间断单元，可参见
   :ref:`Reed 与 Hill（1973） <j02-overview-ref-rh73>` 的三角网格推导。

   本章先定义完整的物理问题，再按“准备输入—建立单元方程—扫描与反射迭代—计算密度和通量”
   的顺序说明实现。01–12 页介绍单域求解，13–14 页在此基础上说明并行分工与进程通信。
   各页保留过程名、作用、输入输出和公式，便于对照源码阅读。

   .. rubric:: 计算问题与适用范围

   考虑图示环形通道的 :math:`r`–:math:`z` 截面。径向范围为
   :math:`0.01\text{--}0.02\,\mathrm m`，轴向范围为
   :math:`0\text{--}0.04\,\mathrm m`，物理周向取完整一圈。
   下端的 :math:`0.012\text{--}0.018\,\mathrm m` 环带是入口，
   其余下端和两个径向侧面是反射壁，上端是开放出口。
   域内存在给定损失频率，不含体产生项和粒子间散射。

   .. figure:: ../../images/J_Fluid/sn_problem_en.svg
      :alt: 环形通道截面：下端部分入口，其余反射壁，上端出口，域内损失
      :width: 800px

      本章贯穿使用的完整计算问题；图中边界条件同时成立。

   本例用入射半平面上的漂移高斯分布描述入射粒子的速度概率密度；
   它描述穿过入口的粒子，而非入口外侧气体中的全部粒子。壁面按固定比例混合镜面反射和热漫反射，
   不吸附粒子；开放出口的外部入射为零。下表中的参数用于 Complete Calculation 页的组装示例，
   可由调用程序修改。

   .. list-table::
      :header-rows: 1
      :widths: 22 48 30

      * - 条件
        - 给定值
        - 计算中形成的数据
      * - 入口
        - :math:`Q=10^{15}\,\mathrm{s^{-1}}`，:math:`T_{\mathrm{in}}=300\,\mathrm K`，
          :math:`\boldsymbol U=(0,200)\,\mathrm{m\,s^{-1}}`
        - 规定入射分布函数 :math:`h_m`
      * - 粒子质量
        - :math:`M=6.6335\times10^{-26}\,\mathrm{kg}`
        - 入口与壁面的热速度尺度
      * - 壁面
        - :math:`T_{\mathrm w}=300\,\mathrm K`，漫反射比例 :math:`d=0.5`
        - 壁面速度分布 :math:`g_{\mathrm w,m}` 与反射规则
      * - 出口
        - 上端开放，外部入射为零
        - 开放面标记及零入流
      * - 体损失
        - :math:`\nu_K=2000\,\mathrm{s^{-1}}`
        - 各速度上的损失系数 :math:`\sigma_{K,m}`

   当前模型只有两个速度分量 :math:`v_r,v_z`，没有周向速度，
   也没有完整柱坐标动力学方程中的速度空间惯性项。
   下文推导的是这一约化守恒模型的离散方法，不能将它称为完整的三速度轴对称动力学模型。

   .. rubric:: 未知分布、粒子收支与控制方程

   定义速度分布函数 :math:`\psi(r,z,v_r,v_z)`，使
   :math:`\psi\,\mathrm dv_r\,\mathrm dv_z` 表示单位物理体积内、
   速度处于相应微小区间的粒子数。因此

   .. math::

      n(r,z)=\int_{\mathbb R^2}\psi(r,z,v_r,v_z)\,\mathrm dv_r\,\mathrm dv_z.

   粒子数按无量纲计，:math:`n` 的单位为 :math:`\mathrm{m^{-3}}`，
   :math:`\psi` 的单位为 :math:`\mathrm{s^2\,m^{-5}}`。
   求解器首先求 :math:`\psi`，不是直接求 :math:`n`。

   在一个物理单元 :math:`K` 内，稳态意味着每个速度上的净流出率与损失率相抵。
   设 :math:`\boldsymbol n_f` 为面的单位外法向，模型收支为

   .. math::
      :label: sn-balance

      \oint_{\partial K}(\boldsymbol v\cdot\boldsymbol n_f)\psi\,\mathrm dA
          +\int_K\nu_K\psi\,\mathrm dV=0.

   柱坐标物理体积元为 :math:`\mathrm dV=\Theta r\,\mathrm dr\,\mathrm dz`，
   其中 :math:`\Theta` 是周向张角。对上述守恒式应用散度定理，得到本模型的微分形式：

   .. math::
      :label: sn-continuous

      \frac1r\frac{\partial(rv_r\psi)}{\partial r}
          +\frac{\partial(v_z\psi)}{\partial z}+\nu_K\psi=0.

   在连续速度平面中选取第 :math:`m` 个速度向量
   :math:`\boldsymbol v_m=(v_{r,m},v_{z,m})=v_m(\mu_m,\eta_m)`。
   其中 :math:`v_m>0` 是速率，:math:`(\mu_m,\eta_m)` 是方向余弦。
   这个向量是速度积分的取值位置，不是空间网格坐标。例如，
   :math:`(v_{r,m},v_{z,m})=(100,200)\,\mathrm{m\,s^{-1}}`
   表示选取径向速度为 100、轴向速度为 200 的粒子来计算其空间分布。

   记

   .. math::

      \psi_m(r,z)=\psi(r,z,v_{r,m},v_{z,m}).

   固定 :math:`m` 只固定了速度，:math:`\psi_m` 仍随 :math:`r,z` 变化。
   因此每个离散速度都要在整个空间网格上求解一次，而不是只计算一个空间点。
   将控制方程除以该速率，得到

   .. math::
      :label: sn-ordinate

      \frac1r\frac{\partial(r\mu_m\psi_m)}{\partial r}
          +\frac{\partial(\eta_m\psi_m)}{\partial z}
          +\sigma_{K,m}\psi_m=0,\qquad
      \sigma_{K,m}=\frac{\nu_K}{v_m}.

   本模型没有粒子间散射。在边界入流已知时，各离散速度的空间方程可以分别求解。
   壁面反射则会改变粒子速度：某一出射速度的粒子碰壁后，会成为另一速度上的入射粒子。
   因此有反射壁时，需要反复更新壁面入流并求解空间方程，直到两者一致。

   密度不是把 :math:`\psi_m` 直接相加，而是使用速度积分权重 :math:`w_m`：

   .. math::

      n(r,z)\approx\sum_m w_m\psi_m(r,z).

   求积页将说明如何选取这些速度及其权重；DG 页再将每个 :math:`\psi_m(r,z)`
   写成各空间单元内的三个多项式系数。

   .. rubric:: 全章符号与数组约定

   数学公式统一采用下列记号；程序参数使用等宽字体。
   后文在同一单元、同一速度的局部推导中会省略 :math:`K,m`，
   但不改变符号含义。

   .. list-table::
      :header-rows: 1
      :widths: 24 43 33

      * - 数学记号
        - 含义与单位
        - 程序表示
      * - :math:`K=(i,k)`，:math:`f`
        - 径向、轴向单元索引；面编号。单元数记为 :math:`N_r,N_z`
        - 四面次序为 r-low、r-high、z-low、z-high
      * - :math:`r_c,z_c,h_r,h_z`
        - 单元中心与半宽，:math:`\mathrm m`
        - ``geometry%rc/hr/hz``；轴向中心由边界坐标计算
      * - :math:`\xi,\zeta`
        - 局部无量纲坐标，均在 :math:`[-1,1]`
        - 基函数顺序为常数、径向一次项、轴向一次项
      * - :math:`\Theta`，:math:`\theta_a`
        - 周向张角；速度平面方向角
        - ``theta_span``；角度求积节点
      * - :math:`\boldsymbol v_m`，:math:`v_m`
        - 速度向量；它的正模长，:math:`\mathrm{m\,s^{-1}}`
        - 向量由 ``speed`` 与 ``mu/eta`` 相乘得到
      * - :math:`\boldsymbol\Omega_m=(\mu_m,\eta_m)`
        - 无量纲单位方向
        - ``quadrature%mu/eta``
      * - :math:`w_m`
        - 二维速度面积权重，:math:`\mathrm{m^2\,s^{-2}}`
        - ``quadrature%weight``
      * - :math:`\beta_{f,m}=\boldsymbol\Omega_m\cdot\boldsymbol n_f`
        - 带符号方向余弦；负为入射、正为出射
        - ``outward_dot`` 或 ``ndot``
      * - :math:`s_{f,m}=|\beta_{f,m}|`
        - 方向余弦的非负大小，无量纲
        - DG 过程的参数 ``s``，不是速率
      * - :math:`u_{n,f,m}=v_m\beta_{f,m}`
        - 带符号法向速度，:math:`\mathrm{m\,s^{-1}}`
        - ``speed*ndot``
      * - :math:`\boldsymbol c=(c_0,c_1,c_2)^{\mathsf T}`
        - 空间多项式 :math:`\psi_m=c_0+c_1\xi+c_2\zeta` 的系数
        - ``psi(1:3,i,k,m)``
      * - :math:`g_m`，:math:`h_m`
        - 尚未按通量归一化的入口分布；规定入射分布函数
        - ``inflow_shape``；``psi_in`` 或 ``zlo_inflow``
      * - :math:`\nu_K`，:math:`\sigma_{K,m}`
        - 损失频率 :math:`\mathrm{s^{-1}}`；路程损失系数 :math:`\mathrm{m^{-1}}`
        - ``ionization_frequency``；``sigma_t``
      * - :math:`V_K,A_f`
        - 物理体积 :math:`\mathrm{m^3}`、面面积 :math:`\mathrm{m^2}`
        - ``volume``、``area_*``
      * - :math:`\mathsf A,\boldsymbol b`
        - 单元内 3×3 线性方程组的矩阵和右端
        - ``a(3,3)``、``rhs(3)``
      * - :math:`\Gamma_r,\Gamma_z`
        - 沿坐标正向计正的面通量，:math:`\mathrm{m^{-2}\,s^{-1}}`
        - ``flux_r/flux_z``

   系数下标从零开始，而 Fortran 数组与矩阵行列从一开始：
   :math:`c_0` 对应 ``psi(1,...)``。第一维长度三表示三个空间系数，不是三个速度分量。

   .. rubric:: 文件分工与阅读顺序

   .. list-table::
      :header-rows: 1
      :widths: 24 39 37

      * - 阶段与文件
        - 完成的工作
        - 传给后续计算的数据
      * - ``geometry``、``quadrature``
        - 计算网格几何量，建立速度积分规则
        - 体积、面积、局部坐标；离散速度和权重
      * - ``boundary``、``inflow``、``source``
        - 确定入口位置、分布与粒子率
        - 面类型、入口区间、:math:`h_m`
      * - ``wall``、``loss``
        - 给定反射关系，将损失频率换为路程损失
        - 壁面速度分布与反射方向；:math:`\sigma_{K,m}`
      * - ``dg_operator``、``sweep``
        - 形成单元方程，沿上游至下游求解
        - 当前一轮的 :math:`\boldsymbol c_{K,m}`
      * - ``reflection``
        - 根据上一轮出射分布更新反射入流，迭代至收敛
        - 收敛分布和迭代诊断
      * - ``reconstruction``、``transport``
        - 从分布积分出物理量，提供完整求解接口
        - 密度、速度、面通量与状态

   按上述顺序，可以从网格和物理条件得到稳态分布及其密度、速度、面通量。
   空间 MPI 版本使用相同的物理模型和单元方程，只增加分区数据、进程间通信以及交界面通量的处理。

   ``mod_J02_neutral_sn_transport_2Drz.f90`` 定义共享类型，并包含上述功能文件。
   应用编译这个模块文件即可，不应把已包含的子过程文件再次独立编译。
   本章只解释模型、算法和调用；数值测试、误差判据和测试结果在 Tests 中说明。

   .. rubric:: 并行计算在哪里进行

   并行有两种分工。OpenMP（Open Multi-Processing）让同一个进程中的多个线程
   分别计算不同离散速度的空间分布；MPI（Message Passing Interface，消息传递接口）
   则把空间网格分给多个进程，每个进程只计算自己负责的区域。

   可以把前者理解为“分配不同速度的计算任务”，后者理解为“划分空间区域”。
   MPI 分区之间需要交换相邻单元的分布信息，才能继续沿粒子运动方向求解。
   两者也可以结合：先用 MPI 划分空间，再在各区域内用 OpenMP 分配速度任务。
   具体交换什么数据、何时交换，在介绍过单元方程与扫描顺序后的 13–14 页展开。

   .. rubric:: 参考文献

   .. _j02-overview-ref-cl65:

   B. G. Carlson and K. D. Lathrop (1965).
   *Transport Theory: The Method of Discrete Ordinates*.
   Los Alamos Scientific Laboratory, LA-3251-MS.
   `报告全文 <https://mcnp.lanl.gov/pdf_files/TechReport_1965_LANL_LA-3251-MS_CarlsonLathrop.pdf>`__

   .. _j02-overview-ref-rh73:

   W. H. Reed and T. R. Hill (1973).
   *Triangular Mesh Methods for the Neutron Transport Equation*.
   Los Alamos Scientific Laboratory, LA-UR-73-479.
   `报告全文 <https://www.osti.gov/servlets/purl/4491151>`__

.. container:: ap-lang ap-lang-en ap-fluid-doc

   J02 solves steady neutral-particle transport. The inputs specify the domain, inlet particle rate and
   velocity distribution, wall reflection, open outlet and volumetric loss. The outputs are neutral number
   density, mean velocity and particle flux on each mesh face.

   Particles with different velocities travel in different directions and may experience different losses.
   The discrete ordinates method (SN) selects a finite set of velocities, solves for the spatial
   distribution at each velocity and sums the contributions with quadrature weights to obtain density and
   flux. For the angular quadrature principle, see :ref:`Carlson and Lathrop (1965) <j02-overview-ref-cl65-en>`, Section 3.3.

   J02 uses a piecewise linear discontinuous Galerkin (P1-DG) method in space. Each cell stores a constant
   and two linear coefficients. Inflow and outflow across a common face couple adjacent cells. The degree of
   the polynomial is one. The error convergence rate depends on the problem, and the positivity treatment
   can reduce individual cells to a constant distribution. For a triangular-mesh derivation of the upwind
   coupling, see :ref:`Reed and Hill (1973) <j02-overview-ref-rh73-en>`.

   The chapter starts from the physical problem and follows the calculation from input preparation through
   cell assembly, sweeping and reflection iteration to density and flux reconstruction. Pages 01–12 cover
   the single-domain solution. Pages 13–14 extend it to parallel work distribution and interprocess
   communication. Each page gives the routine names, responsibilities, inputs, outputs and equations for
   comparison with the source.

   .. rubric:: Problem setup and scope

   Consider the :math:`r`–:math:`z` section of the annular channel shown below. Its radial range is :math:`0.01\text{--}0.02\,\mathrm m`, its axial range is
   :math:`0\text{--}0.04\,\mathrm m`, and it spans a full revolution. The annulus from :math:`0.012\text{--}0.018\,\mathrm m` on the lower boundary forms the inlet. The rest
   of the lower boundary and both radial sides reflect particles. The upper boundary is an open outlet. The
   domain has a prescribed loss frequency, with no volumetric production or interparticle scattering.

   .. figure:: ../../images/J_Fluid/sn_problem_en.svg
      :alt: Annular channel with a partial lower inlet, reflecting walls, an open upper outlet and volumetric loss
      :width: 800px

      The complete problem used throughout this chapter. All the boundary conditions shown apply
      simultaneously.

   The example specifies the velocity probability density of particles crossing the inlet by a drifting
   Gaussian on the incoming half-plane. The walls combine specular and thermal diffuse reflection in fixed
   proportions and retain no particles. The open outlet has zero external inflow. The Complete Calculation
   example uses the parameters below, which the caller can change.

   .. list-table::
      :header-rows: 1
      :widths: 22 48 30

      * - Condition
        - Prescribed value
        - Data used in the solve
      * - Inlet
        - :math:`Q=10^{15}\,\mathrm{s^{-1}}`, :math:`T_{\mathrm{in}}=300\,\mathrm K`,  :math:`\boldsymbol U=(0,200)\,\mathrm{m\,s^{-1}}`
        - Prescribed incoming distribution function :math:`h_m`
      * - Particle mass
        - :math:`M=6.6335\times10^{-26}\,\mathrm{kg}`
        - Thermal speed scale at the inlet and walls
      * - Wall
        - :math:`T_{\mathrm w}=300\,\mathrm K`, diffuse fraction :math:`d=0.5`
        - Wall velocity distribution :math:`g_{\mathrm w,m}` and reflection rule
      * - Outlet
        - Upper end open, zero external inflow
        - Open-face marker and zero inflow
      * - Volumetric loss
        - :math:`\nu_K=2000\,\mathrm{s^{-1}}`
        - Loss coefficient :math:`\sigma_{K,m}` for each speed

   The model retains two velocity components, :math:`v_r,v_z`. It omits azimuthal velocity and the inertial terms in
   velocity space that arise in the full cylindrical kinetic equation. The discretization below applies to
   this reduced conservative model.

   .. rubric:: Distribution function, particle balance and governing equation

   Define the velocity distribution :math:`\psi(r,z,v_r,v_z)` so that :math:`\psi\,\mathrm dv_r\,\mathrm dv_z` is the number of particles per unit physical volume in the
   indicated infinitesimal velocity interval. The number density is therefore

   .. math::

      n(r,z)=\int_{\mathbb R^2}\psi(r,z,v_r,v_z)\,\mathrm dv_r\,\mathrm dv_z.

   Counting particles as dimensionless gives :math:`n` units of :math:`\mathrm{m^{-3}}` and :math:`\psi` units of :math:`\mathrm{s^2\,m^{-5}}`. The solver obtains :math:`\psi` first
   and recovers :math:`n` by integration.

   In a physical cell :math:`K` at steady state, net outward particle flow and volumetric loss balance at each
   velocity. With :math:`\boldsymbol n_f` denoting a unit outward face normal, the balance is

   .. math::
      :label: sn-balance-en

      \oint_{\partial K}(\boldsymbol v\cdot\boldsymbol n_f)\psi\,\mathrm dA
          +\int_K\nu_K\psi\,\mathrm dV=0.

   The cylindrical volume element is :math:`\mathrm dV=\Theta r\,\mathrm dr\,\mathrm dz`, where :math:`\Theta` is the azimuthal extent. Applying the divergence theorem
   gives the differential form of the model.

   .. math::
      :label: sn-continuous-en

      \frac1r\frac{\partial(rv_r\psi)}{\partial r}
          +\frac{\partial(v_z\psi)}{\partial z}+\nu_K\psi=0.

   Select the velocity vector with index :math:`m` in the continuous velocity plane, :math:`\boldsymbol v_m=(v_{r,m},v_{z,m})=v_m(\mu_m,\eta_m)`. Its speed is :math:`v_m>0` and its
   direction cosines are :math:`(\mu_m,\eta_m)`. This vector marks a point in the velocity integral. For example, :math:`(v_{r,m},v_{z,m})=(100,200)\,\mathrm{m\,s^{-1}}` selects
   particles with radial velocity 100 and axial velocity 200 metres per second, whose distribution is
   computed throughout the spatial domain.

   Write

   .. math::

      \psi_m(r,z)=\psi(r,z,v_{r,m},v_{z,m}).

   Fixing :math:`m` fixes the velocity, while :math:`\psi_m` still varies with :math:`r,z`. Each ordinate therefore requires a solve
   over the whole spatial mesh. Dividing the governing equation by its speed gives

   .. math::
      :label: sn-ordinate-en

      \frac1r\frac{\partial(r\mu_m\psi_m)}{\partial r}
          +\frac{\partial(\eta_m\psi_m)}{\partial z}
          +\sigma_{K,m}\psi_m=0,\qquad
      \sigma_{K,m}=\frac{\nu_K}{v_m}.

   The model contains no interparticle scattering. With prescribed boundary inflow, the spatial equations
   can be solved independently for each velocity. Wall reflection couples velocities because particles
   arriving at the wall in one direction can reenter in another. The solver alternates updates of the wall
   inflow with spatial solves until the two agree.

   Reconstruct density by summing :math:`\psi_m` with the velocity-space quadrature weights :math:`w_m`.

   .. math::

      n(r,z)\approx\sum_m w_m\psi_m(r,z).

   The quadrature page explains how to choose the velocities and weights. The DG page represents each :math:`\psi_m(r,z)` by
   three polynomial coefficients per spatial cell.

   .. rubric:: Notation and array conventions

   The equations use the notation below. Program arguments appear in monospace. Local derivations for a
   single cell and velocity may omit :math:`K,m` without changing the definitions.

   .. list-table::
      :header-rows: 1
      :widths: 24 43 33

      * - Symbol
        - Meaning and units
        - Implementation
      * - :math:`K=(i,k)`, :math:`f`
        - Radial and axial cell indices and face index. The cell counts are :math:`N_r,N_z`.
        - Face order is r-low, r-high, z-low, z-high
      * - :math:`r_c,z_c,h_r,h_z`
        - Cell centres and half-widths, :math:`\mathrm m`
        - ``geometry%rc/hr/hz``. The axial centre is computed from boundary coordinates.
      * - :math:`\xi,\zeta`
        - Dimensionless local coordinates in :math:`[-1,1]`
        - Basis order is constant, radial linear, axial linear
      * - :math:`\Theta`, :math:`\theta_a`
        - Azimuthal extent and direction angle in the velocity plane
        - ``theta_span`` and angular quadrature nodes
      * - :math:`\boldsymbol v_m`, :math:`v_m`
        - Velocity vector and its positive magnitude, :math:`\mathrm{m\,s^{-1}}`
        - Multiply ``speed`` by the components ``mu/eta``
      * - :math:`\boldsymbol\Omega_m=(\mu_m,\eta_m)`
        - Dimensionless unit direction
        - ``quadrature%mu/eta``
      * - :math:`w_m`
        - Two-dimensional velocity-area weight, :math:`\mathrm{m^2\,s^{-2}}`
        - ``quadrature%weight``
      * - :math:`\beta_{f,m}=\boldsymbol\Omega_m\cdot\boldsymbol n_f`
        - Signed direction cosine, negative for incoming and positive for outgoing particles
        - ``outward_dot`` or ``ndot``
      * - :math:`s_{f,m}=|\beta_{f,m}|`
        - Magnitude of the direction cosine, dimensionless
        - DG argument ``s``, distinct from speed
      * - :math:`u_{n,f,m}=v_m\beta_{f,m}`
        - Signed normal velocity, :math:`\mathrm{m\,s^{-1}}`
        - ``speed*ndot``
      * - :math:`\boldsymbol c=(c_0,c_1,c_2)^{\mathsf T}`
        - Coefficients of the spatial polynomial :math:`\psi_m=c_0+c_1\xi+c_2\zeta`
        - ``psi(1:3,i,k,m)``
      * - :math:`g_m`, :math:`h_m`
        - Inlet shape before flux normalization and prescribed incoming distribution function
        - ``inflow_shape`` and ``psi_in`` or ``zlo_inflow``
      * - :math:`\nu_K`, :math:`\sigma_{K,m}`
        - Loss frequency in :math:`\mathrm{s^{-1}}` and loss per unit path length in :math:`\mathrm{m^{-1}}`
        - ``ionization_frequency``; ``sigma_t``
      * - :math:`V_K,A_f`
        - Physical volume in :math:`\mathrm{m^3}` and face area in :math:`\mathrm{m^2}`
        - ``volume``, ``area_*``
      * - :math:`\mathsf A,\boldsymbol b`
        - Matrix and right-hand side of the local 3 × 3 system
        - ``a(3,3)``, ``rhs(3)``
      * - :math:`\Gamma_r,\Gamma_z`
        - Face flux positive in the increasing coordinate direction, :math:`\mathrm{m^{-2}\,s^{-1}}`
        - ``flux_r/flux_z``

   Coefficient indices start at zero, whereas Fortran array indices, matrix rows and matrix columns start at
   one. Thus :math:`c_0` corresponds to ``psi(1,...)``. The first array dimension holds three spatial coefficients for each
   velocity.

   .. rubric:: Source files and reading order

   .. list-table::
      :header-rows: 1
      :widths: 24 39 37

      * - Stage and files
        - Operation
        - Data passed to subsequent stages
      * - ``geometry``, ``quadrature``
        - Compute mesh geometry and construct the velocity quadrature
        - Volumes, areas, local coordinates, discrete velocities and weights
      * - ``boundary``, ``inflow``, ``source``
        - Determine the inlet location, distribution and particle rate
        - Face types, inlet intervals and :math:`h_m`
      * - ``wall``, ``loss``
        - Specify reflection and convert loss frequency to loss per unit path length
        - Wall velocity distribution, reflected direction and :math:`\sigma_{K,m}`
      * - ``dg_operator``, ``sweep``
        - Assemble the cell equations and solve from upstream to downstream
        - :math:`\boldsymbol c_{K,m}` for the current sweep
      * - ``reflection``
        - Update reflected inflow from the previous outgoing distribution and iterate to convergence
        - Converged distribution and iteration diagnostics
      * - ``reconstruction``, ``transport``
        - Integrate the distribution to recover physical fields and provide the complete solver interface
        - Density, velocity, face fluxes and solver status

   With this sequence, the mesh and physical inputs determine the steady distribution and the corresponding
   density, velocity and face fluxes. The spatial MPI version uses the same physical model and cell
   equations, with additional partition data, interprocess communication and interface flux handling.

   ``mod_J02_neutral_sn_transport_2Drz.f90`` defines the shared types and includes the implementation files listed above. Compile that module as a
   single unit. The Tests section documents numerical tests, error criteria and results. This chapter covers
   the model, algorithms and calling sequence.

   .. rubric:: Where parallelism enters the calculation

   OpenMP (Open Multi-Processing) distributes distinct velocity solves among threads in a process. MPI
   (Message Passing Interface) partitions the spatial mesh among processes, each responsible for its own
   subdomain.

   OpenMP divides work by velocity and MPI divides it by spatial region. Adjacent MPI partitions exchange
   cell distribution data so that the solve can proceed in the direction of travel. The approaches can be
   combined by partitioning space with MPI and sharing velocity solves among OpenMP threads in each
   subdomain. After the discussion of cell equations and sweep order, pages 13–14 detail what is exchanged
   and when.

   .. rubric:: References

   .. _j02-overview-ref-cl65-en:

   Carlson, B. G., and K. D. Lathrop (1965).
   *Transport Theory: The Method of Discrete Ordinates*.
   Los Alamos Scientific Laboratory, LA-3251-MS.
   `Full report <https://mcnp.lanl.gov/pdf_files/TechReport_1965_LANL_LA-3251-MS_CarlsonLathrop.pdf>`__

   .. _j02-overview-ref-rh73-en:

   Reed, W. H., and T. R. Hill (1973).
   *Triangular Mesh Methods for the Neutron Transport Equation*.
   Los Alamos Scientific Laboratory, LA-UR-73-479.
   `Full report <https://www.osti.gov/servlets/purl/4491151>`__
