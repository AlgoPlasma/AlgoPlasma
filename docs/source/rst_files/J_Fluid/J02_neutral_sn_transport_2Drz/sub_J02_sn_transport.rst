Complete Calculation
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J02_sn_transport.f90`` 提供完整求解接口：
   根据调用者已经准备好的物理条件，选择一次扫描或反射迭代，
   再依次重构密度、速度和面通量。
   本页沿用总览中的环形通道，按调用顺序说明每一步需要哪些输入、产生哪些数据。

   .. rubric:: 动态计算流程

   下图先展示小网格上的一轮扫描，再由本轮结果建立下一轮反射入流。
   可切换单域或空间分区、改变速度方向、逐步查看每个单元的上游数据，
   并展开右端、面矩阵、体矩阵和保正处理。示意中没有真实密度值，不能用它判断收敛速度或精度。

   .. raw:: html

      <iframe id="sn-walkthrough" title="SN 迎风扫描、方程组装与反射迭代" style="width:100%;height:1400px;border:1px solid #d5dde3;" loading="lazy"></iframe>

   静态阅读时，下面仍按输入准备、求解与重构的顺序给出完整调用过程。
   动画对应本页第 6 步的内部执行，不改变各功能页的公式和接口。

   .. rubric:: 1. 完整问题需要准备哪些输入

   沿用总览的环形通道：下端部分入口，其余下端与径向侧面反射，上端开放，
   域内存在损失。本页采用四个径向单元、六个轴向单元，
   16 个角节点、12 个速率区间，速度上限为
   :math:`1800\,\mathrm{m\,s^{-1}}`，说明输入准备与求解的顺序。
   这些规模用于说明调用关系，不代表空间或速度收敛的推荐配置。

   整个计算的数据关系为

   .. math::

      \begin{gathered}
      \text{空间边界、有效区域}\ \longrightarrow\
             \text{单元几何、面类型、入口区间},\\
      \text{速度求积、入射粒子的速度分布、入口粒子率}\ \longrightarrow\ h_m,\\
      \text{壁温、反射比例、损失频率}\ \longrightarrow\
             g_{\mathrm w,m},\,d,\,\sigma_{K,m},\\
      \text{上述数据}\ \longrightarrow\
             \boldsymbol c_{K,m}\ \longrightarrow\
             n_K,\,u_{r,K},\,u_{z,K},\,\Gamma.
      \end{gathered}

   调用者需要准备空间和速度离散、入口分布与粒子率、壁面参数和体损失。
   这些数据共同确定边值问题，随后才能调用求解过程。

   .. rubric:: 2. 第一步：构建空间与速度离散

   先给出递增的径向、轴向边界坐标和有效单元标记。
   依次调用 ``sub_J02_initialize_mesh``、``sub_J02_build_geometry``，
   取 :math:`\Theta=2\pi` 得到完整环形通道的体积与面积。

   随后调用 ``sub_J02_build_phase_quadrature``，
   选择当前的等角中点与速率方向的求积规则。
   输出包含 :math:`N_{\mathrm{dir}}=16\times12=192` 个离散速度。
   后续入口、壁面、损失、扫描及重构全部共享该对象，
   使归一化、求解和积分使用相同的离散速度与权重。

   .. rubric:: 3. 第二步：设置壁面、出口和入口区间

   调用 ``sub_J02_initialize_boundary_types`` 建立内部面与外边界的初始类型。
   将两个径向侧面改为 WALL，上端保留 OPEN 且外部入射为零。

   对下端径向区间
   :math:`[0.012,0.018]\,\mathrm m`，
   调用 ``sub_J02_build_partial_zlo_inlet`` 得到
   :math:`\chi_i,\xi_{L,i},\xi_{H,i}`。
   再调用 ``sub_J02_configure_zlo_partial_inlet_boundary``：
   有开口的下端面标 OPEN，其余下端面标 WALL。
   对于部分开放的面，将入口区间端点传给求解器，区间外的部分按壁面处理。

   入口总面积和目标通量为

   .. math::

      A_{\mathrm{in}}=\sum_i\chi_iA_{z-,i,1},\qquad
      J_{\mathrm{in}}=\frac{Q}{A_{\mathrm{in}}},
      \qquad Q=10^{15}\,\mathrm{s^{-1}}.

   这里使用入口与有效单元面相交后的总面积，确保归一化面积与实际施加入流的区域一致。

   .. rubric:: 4. 第三步：构建本例的入射粒子的速度分布

   本例明确采用入射粒子模型。令热速度方差为
   :math:`a_T^2=k_{\mathrm B}T_{\mathrm{in}}/M`，
   在下端的入射速度 :math:`\eta_m>0` 上给出尚未归一化的概率密度

   .. math::

      \widetilde p_m=
      \begin{cases}
         \exp\!\left[-\dfrac{(v_m\mu_m-U_r)^2+(v_m\eta_m-U_z)^2}{2a_T^2}\right],
            &\eta_m>0,\\
         0,&\eta_m\leq0.
      \end{cases}

   使用 :math:`T_{\mathrm{in}}=300\,\mathrm K`，
   :math:`\boldsymbol U=(0,200)\,\mathrm{m\,s^{-1}}`，
   :math:`M=6.6335\times10^{-26}\,\mathrm{kg}`。
   省略高斯公共前因子是允许的，因为之后会按实际离散入流归一化。

   先调用 ``sub_J02_build_mc_crossing_pdf_inflow_shape``，
   使用外法向 :math:`(0,-1)` 转为
   :math:`g_m=\widetilde p_m/(v_m\eta_m)`。
   再调用 ``sub_J02_normalize_inflow_flux``，
   指定 :math:`J_{\mathrm{in}}`，得到 :math:`h_m`，
   保存为 ``zlo_inflow``。

   第一次调用除以法向速率，将入射粒子的速度概率密度转换为待归一化的分布；
   第二次调用按给定通量确定其系数，得到实际边界分布函数。
   若改用入口外侧气体模型，则用 ``sub_J02_build_drifted_maxwellian_inflow_shape``
   生成 :math:`g_m`，再进行同样的通量归一化，后续求解流程不变。

   .. rubric:: 5. 第四步：给定反射与体损失

   调用 ``sub_J02_build_wall_maxwell_shape``，
   使用 :math:`T_{\mathrm w}=300\,\mathrm K` 和相同粒子质量，
   生成 :math:`g_{\mathrm w,m}`；设置漫反射比例 :math:`d=0.5`。

   逐单元给定 :math:`\nu_K=2000\,\mathrm{s^{-1}}`，
   调用 ``sub_J02_build_sigma_from_frequency``，
   得到 :math:`\sigma_{K,m}=\nu_K/v_m`。
   壁面温度控制再发射速度分布，损失频率控制单位时间内的粒子损失，
   二者是独立输入，不从入口温度或入口流量自动推导。

   .. rubric:: 6. 第五步：求分布，再重构物理量

   调用 ``sub_J02_solve_transport``，同时提供下端入流、入口区间、壁面速度分布和求解选项。
   对于本例，它的内部顺序是：

   1. 使用已初始化的基础对象，发现整面壁面或部分面区间后启用反射迭代；入口检查交给扫描过程。
   2. 调用 ``sub_J02_solve_source_iteration``；
      每轮由上一轮出射分布计算壁面入流，调用 ``sub_J02_sweep`` 求新分布。
   3. 只有求解成功，才调用 ``sub_J02_reconstruct_cell_moments``。
   4. 接着调用 ``sub_J02_reconstruct_internal_face_fluxes``。
   5. 最后调用 ``sub_J02_reconstruct_open_boundary_fluxes``，
      使用与求解一致的入口数据及区间。

   全开放边界且采用整面入口时，执行一次扫描，再由所得分布完成上述三次积分重构。

   对每个离散速度，扫描沿运动方向从上游推进到下游，见
   :ref:`Carlson 与 Lathrop（1965） <j02-transport-ref-cl65>` 第 3.6.1 节。
   单元内独立使用多项式近似并通过迎风侧分布耦合相邻单元的 DG 方法，
   可参见 :ref:`Reed 与 Hill（1973） <j02-transport-ref-rh73>`。

   .. rubric:: 7. 完整求解接口的参数

   ``sub_J02_solve_transport`` 的必需输入：

   - ``mesh``、``geometry``、``quadrature``、``boundary``：
     已完成初始化和物理边界设置的对象。
   - ``sigma_t(nr,nz,n_dir)``：非负路程损失系数，单位 :math:`\mathrm{m^{-1}}`。

   规定入流必须二选一：

   - ``boundary_inflow(4,nr,nz,n_dir)``，适合一般整面规定入流；
   - ``zlo_inflow(n_dir)``，适合下端共用同一速度分布的入口。

   两者单位均为分布函数单位。可选的
   ``zlo_source_xi_lo(nr)``、``zlo_source_xi_hi(nr)``
   必须同时出现，给定第一排下端面内的开放区间。
   有漫反射时还须输入 ``wall_shape(n_dir)``。
   调用者无需提供初始分布；本过程从全零分布开始进行反射迭代。

   可选输入 ``options`` 的字段为：

   .. list-table::
      :header-rows: 1
      :widths: 28 18 54

      * - 字段
        - 默认值
        - 含义与限制
      * - ``diffuse_fraction``
        - 0
        - 全局漫反射比例，范围 :math:`[0,1]`
      * - ``tolerance``
        - :math:`10^{-6}`
        - 正的反射迭代相对变化容差
      * - ``max_iterations``
        - 200
        - 反射迭代上限，至少为二
      * - ``progress_interval``
        - 0
        - 非负进度间隔；有反射时按迭代轮数，无反射时按离散速度总数

   本例的反射迭代容差为 :math:`10^{-9}`，最大迭代轮数为 500。

   .. rubric:: 8. 返回结果与后续使用

   输出 ``result`` 将一次完整计算的分布、物理量和诊断放在一起：

   .. list-table::
      :header-rows: 1
      :widths: 28 30 42

      * - 字段
        - 尺寸
        - 含义
      * - ``psi``
        - ``(3,nr,nz,n_dir)``
        - 三个空间系数，单位 :math:`\mathrm{s^2\,m^{-5}}`
      * - ``density``
        - ``(nr,nz)``
        - 单元平均密度，单位 :math:`\mathrm{m^{-3}}`
      * - ``velocity_r/velocity_z``
        - ``(nr,nz)``
        - 平均速度分量，单位 :math:`\mathrm{m\,s^{-1}}`
      * - ``flux_r``
        - ``(max(nr-1,0),nz)``
        - 径向内部面通量
      * - ``flux_z``
        - ``(nr,max(nz-1,0))``
        - 轴向内部面通量
      * - ``inflow_flux/outflow_flux``
        - ``(4,nr,nz)``
        - OPEN 面的入射、出射通量；沿坐标正向计正
      * - ``partition_flux``
        - ``(4,nr,nz)``，仅空间 MPI 路径分配
        - REMOTE 面坐标向通量；物理开放边界与本块内部面仍分别存储
      * - ``converged``
        - 标量逻辑值
        - 求解及全部重构成功完成后置真
      * - ``iterations/relative_change``
        - 标量
        - 迭代计数与最后相对变化；无反射时一次扫描，变化量保持默认零
      * - ``failed_direction/failed_i/failed_k``
        - 三个整数
        - 失败位置；不适用或尚未进入对应步骤时可能为零

   各通量单位均为 :math:`\mathrm{m^{-2}\,s^{-1}}`。
   部分开口的通量已经按完整面面积归一化。
   输出 ``ierr`` 为零后才应使用全部结果；
   任何一个阶段失败都会提前返回，后续数组可能尚未分配。

   可选输入 ``partition`` 使上述尺寸均指本块单元数，失败单元索引改为全局位置。
   此时所有进程必须共同调用；壁面存在性和反射收敛量在全域归约。
   具体的分区准备、入口面积归约和各输出数组的存储范围见本章 13–14 页。
   J03 当前仍是单域过程，不能把本地结果直接当作完整网格交给它。

   .. rubric:: 9. OpenMP 构建与线程设置

   公共过程的参数不因串行或并行而改变。
   GNU Fortran 需要在编译 J02 模块和最终链接时都启用 ``-fopenmp``；
   仅设置线程数，不能把一个串行可执行文件变成并行程序。
   不加该选项时，OpenMP 指令被当作注释，仍使用同一套单方向求解实现。

   运行已启用 OpenMP 的应用程序时，设置 ``OMP_NUM_THREADS=4`` 可请求四个线程，
   ``OMP_DYNAMIC=FALSE`` 关闭运行时的动态缩减；实际可用线程仍受运行环境限制。
   启用进度输出后，扫描日志中的 ``sweep workers`` 给出实际线程数。

   空间 MPI 构建需要应用建立通信器和分区，并把 ``partition`` 传入求解过程。
   仅用 ``mpirun`` 启动多个单域可执行文件，会重复计算整个区域。
   模块和应用必须采用相同的实数精度；例如使用 GNU Fortran 的
   ``-fdefault-real-8`` 时，两者都要采用该选项。

   两个全速度分布场仍存储在共享内存中，不为每个线程复制整个场。
   改变线程数不会降低这两个场本身的存储需求。
   对于很小的网格，多线程可能比串行慢；生产算例应依据实际耗时选择线程数，
   不要把线程数量直接当作加速比。

   .. rubric:: 10. 结果读取与粒子收支

   求解成功后，从 ``result`` 读取密度、面通量及迭代状态，
   再由几何面积与损失频率计算粒子率。
   对本例，开放逸出包括上端出口和下端入口的反向逃逸：

   .. math::

      Q_{\mathrm{open,out}}
          =\sum_iA_{z+,i,N_z}\Gamma_{z+,i}^{\mathrm{out}}
            -\sum_iA_{z-,i,1}\Gamma_{z-,i}^{\mathrm{out}},\qquad
      Q_{\mathrm{loss}}=\sum_K\nu_Kn_KV_K.

   减号来自下端外法向，与通量的坐标向存储约定一致。
   每次调用后先检查 ``ierr``；非零时通过 ``fun_J02_error_message`` 取得原因，
   不要继续读取失败步骤的输出。

   .. rubric:: 参考文献

   .. _j02-transport-ref-cl65:

   B. G. Carlson and K. D. Lathrop (1965).
   *Transport Theory: The Method of Discrete Ordinates*.
   Los Alamos Scientific Laboratory, LA-3251-MS.
   `报告全文 <https://mcnp.lanl.gov/pdf_files/TechReport_1965_LANL_LA-3251-MS_CarlsonLathrop.pdf>`__

   .. _j02-transport-ref-rh73:

   W. H. Reed and T. R. Hill (1973).
   *Triangular Mesh Methods for the Neutron Transport Equation*.
   Los Alamos Scientific Laboratory, LA-UR-73-479.
   `报告全文 <https://www.osti.gov/servlets/purl/4491151>`__

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``sub_J02_sn_transport.f90`` provides the complete solver interface. Given the physical inputs, it chooses between one sweep
   and reflection iteration, then reconstructs density, mean velocity, and face fluxes in order. The
   annular channel from the overview is used below to identify the inputs and outputs of each call.

   .. rubric:: Interactive calculation walkthrough

   The animation first sweeps a small mesh and then uses the result to construct wall inflow for the
   next iteration. Switch between a single domain and a spatial partition, change the velocity
   direction, inspect each cell's upstream data, and expand the right-hand side, face and volume
   matrices, and positivity treatment. The graphic illustrates dependencies and contains no computed
   density data from which to estimate convergence or accuracy.

   .. raw:: html

      <iframe id="sn-walkthrough-en" title="Discrete ordinates upwind sweeps, cell assembly, and reflection iteration" style="width:100%;height:1400px;border:1px solid #d5dde3;" loading="lazy"></iframe>

   The following static description covers input preparation, the transport solve, and reconstruction.
   The animation shows the operations within the solve in Section 6, using the formulas and interfaces
   described on the individual method pages.

   .. rubric:: 1. Inputs for the full problem

   Use the annular channel from the overview: a partial inlet at the bottom, reflecting walls on the
   rest of the lower face and both radial sides, an open top, and a volume loss. This example uses four
   radial cells, six axial cells, 16 angular nodes, 12 speed intervals, and a maximum speed of :math:`1800\,\mathrm{m\,s^{-1}}` to
   illustrate call order. Actual spatial and velocity resolution must be chosen by convergence studies.

   The data flow through the calculation is

   .. math::

      \begin{gathered} \text{mesh edges, active region}\ \longrightarrow\ \text{geometry, face types, inlet intervals},\\ \text{velocity quadrature, crossing distribution, inlet rate}\ \longrightarrow\ h_m,\\ \text{wall temperature, reflection fraction, loss frequency}\ \longrightarrow\ g_{\mathrm w,m},\,d,\,\sigma_{K,m},\\ \text{prepared inputs}\ \longrightarrow\ \boldsymbol c_{K,m}\ \longrightarrow\ n_K,\,u_{r,K},\,u_{z,K},\,\Gamma. \end{gathered}

   Supply the spatial and velocity discretizations, inlet distribution and particle rate, wall
   parameters, and volume loss. Once these determine the boundary-value problem, call the solver.

   .. rubric:: 2. Step 1: construct the spatial and velocity discretizations

   Supply increasing radial and axial edge coordinates and the active-cell mask. Call ``sub_J02_initialize_mesh`` followed by
   ``sub_J02_build_geometry``. Use :math:`\Theta=2\pi` to obtain the volumes and areas of a full annular channel.

   Call ``sub_J02_build_phase_quadrature`` to select the equal-angle midpoint rule and the speed quadrature. This produces :math:`N_{\mathrm{dir}}=16\times12=192` discrete
   velocities. The inlet, wall, loss, sweep, and reconstruction stages share the same velocity nodes
   and weights for normalization, solution, and integration.

   .. rubric:: 3. Step 2: specify walls, outlet, and inlet intervals

   Call ``sub_J02_initialize_boundary_types`` to initialize interior and external face types. Set both radial sides to WALL and leave the
   upper boundary OPEN with zero external inflow.

   For lower radial interval :math:`[0.012,0.018]\,\mathrm m` call ``sub_J02_build_partial_zlo_inlet`` to obtain :math:`\chi_i,\xi_{L,i},\xi_{H,i}`. Then call ``sub_J02_configure_zlo_partial_inlet_boundary`` to label lower faces containing an
   opening as OPEN and the remaining lower faces as WALL. Supply the inlet endpoints to the solver so
   that the remainder of a partially open face is treated as a wall.

   The total inlet area and target flux are

   .. math::

      A_{\mathrm{in}}=\sum_i\chi_iA_{z-,i,1},\qquad
      J_{\mathrm{in}}=\frac{Q}{A_{\mathrm{in}}},
      \qquad Q=10^{15}\,\mathrm{s^{-1}}.

   Use the area actually intersecting active cell faces so the normalization and the applied inflow
   cover the same region.

   .. rubric:: 4. Step 3: construct the crossing-particle velocity distribution

   This example prescribes the velocity distribution of particles crossing the inlet. With thermal
   velocity variance :math:`a_T^2=k_{\mathrm B}T_{\mathrm{in}}/M`, the unnormalized probability density for incoming velocities :math:`\eta_m>0` on the lower
   face is

   .. math::

      \widetilde p_m=
      \begin{cases}
         \exp\!\left[-\dfrac{(v_m\mu_m-U_r)^2+(v_m\eta_m-U_z)^2}{2a_T^2}\right],
            &\eta_m>0,\\
         0,&\eta_m\leq0.
      \end{cases}

   Use :math:`T_{\mathrm{in}}=300\,\mathrm K`, :math:`\boldsymbol U=(0,200)\,\mathrm{m\,s^{-1}}`, and :math:`M=6.6335\times10^{-26}\,\mathrm{kg}`. The common Gaussian prefactor can be omitted because the shape is normalized
   against the discrete incoming flux below.

   Call ``sub_J02_build_mc_crossing_pdf_inflow_shape`` with outward normal :math:`(0,-1)` to obtain :math:`g_m=\widetilde p_m/(v_m\eta_m)`. Then call ``sub_J02_normalize_inflow_flux``, supplying :math:`J_{\mathrm{in}}`, to obtain :math:`h_m` and store it
   as ``zlo_inflow``.

   The first call divides the crossing velocity density by the normal speed to obtain a distribution
   shape. The second scales it to the specified flux and gives the boundary distribution. For an
   exterior-gas inlet model, use ``sub_J02_build_drifted_maxwellian_inflow_shape`` to generate :math:`g_m` and apply the same flux normalization before
   continuing with the solve.

   .. rubric:: 5. Step 4: prescribe reflection and volume loss

   Call ``sub_J02_build_wall_maxwell_shape`` with :math:`T_{\mathrm w}=300\,\mathrm K` and the same particle mass to generate :math:`g_{\mathrm w,m}`. Set the diffuse fraction to :math:`d=0.5`.

   For each cell specify :math:`\nu_K=2000\,\mathrm{s^{-1}}` and call ``sub_J02_build_sigma_from_frequency`` to obtain :math:`\sigma_{K,m}=\nu_K/v_m`. Wall temperature sets the reemitted velocity
   distribution, whereas loss frequency specifies removal per unit time. They are independent of one
   another and must be supplied separately from inlet temperature and flow.

   .. rubric:: 6. Step 5: solve the distribution and reconstruct the fields

   Call ``sub_J02_solve_transport`` with the lower inflow, inlet intervals, wall velocity distribution, and solver options. For
   this example the operations are:

   1. Start from the initialized objects. Detect whole wall faces or partial-face intervals and enable
      reflection iteration. The sweep verifies the inlet.
   2. Call ``sub_J02_solve_source_iteration``. In each iteration compute incoming wall data from the preceding outgoing distribution
      and call ``sub_J02_sweep`` to obtain the new distribution.
   3. After a successful solve, call ``sub_J02_reconstruct_cell_moments``.
   4. Then call ``sub_J02_reconstruct_internal_face_fluxes``.
   5. Finally call ``sub_J02_reconstruct_open_boundary_fluxes`` with the same inlet data and intervals as the solve.

   For all-open boundaries with whole-face inlets, one sweep suffices before the same three
   reconstructions.

   For each discrete velocity, the sweep advances from upstream to downstream along the direction of
   motion; see :ref:`Carlson and Lathrop (1965) <j02-transport-ref-cl65-en>`, Section 3.6.1. For the DG use of independent cell polynomials coupled by the upwind
   distribution, see :ref:`Reed and Hill (1973) <j02-transport-ref-rh73-en>`.

   .. rubric:: 7. Complete solver interface

   Required inputs to ``sub_J02_solve_transport`` are:

   - ``mesh``, ``geometry``, ``quadrature``, and ``boundary`` after initialization and assignment of physical boundary types.
   - ``sigma_t(nr,nz,n_dir)``, the nonnegative loss per unit path length in :math:`\mathrm{m^{-1}}`.

   Choose exactly one prescribed inflow representation:

   - ``boundary_inflow(4,nr,nz,n_dir)`` for general prescribed whole-face inflow.
   - ``zlo_inflow(n_dir)`` for lower-face inlets sharing a single velocity distribution.

   Both have the units of the distribution function. Optional ``zlo_source_xi_lo(nr)`` and ``zlo_source_xi_hi(nr)`` must appear together and
   specify the open interval on each lower face of the first row. Diffuse reflection also requires ``wall_shape(n_dir)``.
   Reflection iteration starts from zero without a caller-supplied initial field.

   Optional input ``options`` contains the following fields:

   .. list-table::
      :header-rows: 1
      :widths: 28 18 54

      * - Field
        - Default
        - Meaning and constraints
      * - ``diffuse_fraction``
        - 0
        - Global diffuse fraction, in :math:`[0,1]`
      * - ``tolerance``
        - :math:`10^{-6}`
        - Positive relative-change tolerance for reflection iteration
      * - ``max_iterations``
        - 200
        - Maximum reflection iterations, at least two
      * - ``progress_interval``
        - 0
        - Nonnegative reporting interval, measured in iterations with reflection or velocity tasks
          without reflection

   This example uses tolerance :math:`10^{-9}` and a maximum of 500 reflection iterations.

   .. rubric:: 8. Results and subsequent use

   Output ``result`` groups the distribution, physical fields, and diagnostics for one complete calculation.

   .. list-table::
      :header-rows: 1
      :widths: 28 30 42

      * - Field
        - Shape
        - Meaning
      * - ``psi``
        - ``(3,nr,nz,n_dir)``
        - Three spatial coefficients, in :math:`\mathrm{s^2\,m^{-5}}`
      * - ``density``
        - ``(nr,nz)``
        - Cell-averaged density, in :math:`\mathrm{m^{-3}}`
      * - ``velocity_r/velocity_z``
        - ``(nr,nz)``
        - Mean velocity components, in :math:`\mathrm{m\,s^{-1}}`
      * - ``flux_r``
        - ``(max(nr-1,0),nz)``
        - Radial interior face flux
      * - ``flux_z``
        - ``(nr,max(nz-1,0))``
        - Axial interior face flux
      * - ``inflow_flux/outflow_flux``
        - ``(4,nr,nz)``
        - Incoming and outgoing fluxes on OPEN faces, positive in the increasing coordinate direction
      * - ``partition_flux``
        - ``(4,nr,nz)``, allocated only in the spatial MPI path
        - Coordinate-directed flux on REMOTE faces. Physical open faces and interior faces within the
          block have separate arrays.
      * - ``converged``
        - Logical scalar
        - True after the solve and every reconstruction complete successfully
      * - ``iterations/relative_change``
        - Scalar
        - Iteration count and last relative change. Without reflection there is one sweep and the
          change retains its default of zero.
      * - ``failed_direction/failed_i/failed_k``
        - Three integers
        - Failure location. Indices may be zero when inapplicable or when that stage has not yet been
          reached.

   All fluxes are in :math:`\mathrm{m^{-2}\,s^{-1}}`. Partial openings are already normalized by the whole face area. Use the
   complete result only when ``ierr`` is zero; an early return can leave later arrays unallocated.

   With optional ``partition``, shapes refer to the local block and failed cell indices are global. All ranks call
   the interface collectively. Wall existence and reflection convergence are reduced across the entire
   domain. Pages 13 and 14 cover partitions, global inlet area, and output ownership. J03 currently
   takes a single global domain, so its input must first be assembled from local results.

   .. rubric:: 9. Building and setting OpenMP threads

   The public arguments are the same in serial and parallel builds. With GNU Fortran use ``-fopenmp`` both when
   compiling J02 and at final link. A serial executable treats OpenMP directives as comments and uses
   the same single-direction solver; setting a thread count alone does not enable threading.

   For an OpenMP executable, ``OMP_NUM_THREADS=4`` requests four threads and ``OMP_DYNAMIC=FALSE`` disables dynamic adjustment. The execution
   environment can still limit available threads. With progress reporting enabled, ``sweep workers`` in the sweep log
   reports the actual count.

   For spatial MPI, the application creates a communicator and partition and passes ``partition`` to the solver.
   Launching several single-domain processes with ``mpirun`` would simply repeat the entire calculation. The
   module and application must use the same real precision, for example ``-fdefault-real-8`` in both GNU Fortran
   compilations.

   Two full velocity fields remain in shared memory; they are not replicated for each thread.
   Increasing the thread count leaves their storage requirements unchanged. Thread overhead may slow a
   small mesh. Select thread counts using measured run times for the production case.

   .. rubric:: 10. Reading results and checking particle balance

   After success retrieve density, face fluxes, and iteration status from ``result``. Use the physical areas
   and loss frequency to compute particle rates. Escape includes both the upper outlet and backflow out
   of the lower inlet:

   .. math::

      Q_{\mathrm{open,out}}
          =\sum_iA_{z+,i,N_z}\Gamma_{z+,i}^{\mathrm{out}}
            -\sum_iA_{z-,i,1}\Gamma_{z-,i}^{\mathrm{out}},\qquad
      Q_{\mathrm{loss}}=\sum_K\nu_Kn_KV_K.

   The minus sign follows from the outward normal on the lower face and the coordinate-directed flux
   convention. Check ``ierr`` after each call. On failure retrieve the reason with ``fun_J02_error_message`` before attempting to
   use any output.

   .. rubric:: References

   .. _j02-transport-ref-cl65-en:

   Carlson, B. G., and K. D. Lathrop (1965). *Transport Theory: The Method of Discrete Ordinates*. Los
   Alamos Scientific Laboratory, LA-3251-MS. `Full report <https://mcnp.lanl.gov/pdf_files/TechReport_1965_LANL_LA-3251-MS_CarlsonLathrop.pdf>`__

   .. _j02-transport-ref-rh73-en:

   Reed, W. H., and T. R. Hill (1973). *Triangular Mesh Methods for the Neutron Transport Equation*. Los
   Alamos Scientific Laboratory, LA-UR-73-479. `Full report <https://www.osti.gov/servlets/purl/4491151>`__

.. The following markup supplies the two walkthrough frames on this page.

.. raw:: html

   <template id="j02-view-zh">

.. raw:: html
   :file: ../../../_static/J_Fluid/sn_walkthrough.html

.. raw:: html

   <template id="assembly-incoming">
   <p><span data-cell></span> 的两个迎风面提供右端。内部面取本轮已求出的上游多项式；跨分区面取已接收的三个系数；入口用给定的 <span data-tex="h_m"></span>；壁面用上一轮分布确定的反射入流。</p>
   <div class="formula" data-tex="b_a^{(\ell+1)}=\sum_{f:\,\beta_f&lt;0}|\beta_f|\int_f r\phi_a\psi_f^{\mathrm{up},(\ell+1)}\,\mathrm ds"></div>
   <p class="small"><span data-tex="\psi_f^{\mathrm{up},(\ell+1)}"></span> 是本轮使用的已知入流面值；其中壁面项由旧分布计算，并不使用尚未求出的本轮出射值。跨分区传递的是上游单元的 <span data-tex="\boldsymbol c^{(\ell+1)}=(c_0^{(\ell+1)},c_1^{(\ell+1)},c_2^{(\ell+1)})^{\mathsf T}"></span>。</p>
   <div class="code">sub_J02_add_neighbor_rhs / sub_J02_add_constant_rhs / sub_J02_add_specular_rhs</div>
   </template>
   <template id="assembly-outgoing">
   <p>出流面满足 <span data-tex="\beta_f&gt;0"></span>，面值取本单元未知分布。把 <span data-tex="\psi=\sum_{b=1}^{3}\phi_b c_{b-1}"></span> 代入面积分，每个出流面贡献一个矩阵：</p>
   <div class="formula" data-tex="(F_f)_{ab}=|\beta_f|\int_f r\phi_a\phi_b\,\mathrm ds,\qquad a,b=1,2,3"></div>
   <p class="small">径向面上 <span data-tex="r"></span> 为常数，<span data-tex="\mathrm ds=\mathrm dz"></span>；轴向面上 <span data-tex="\mathrm ds=\mathrm dr"></span>。共同的周向张角已约去。组装时将全部出流面的 <span data-tex="\mathsf F_f"></span> 相加。</p>
   <div class="code">sub_J02_add_self_face_matrix</div>
   </template>
   <template id="assembly-volume">
   <p>把守恒输运方程乘以检验函数 <span data-tex="\phi_a"></span> 并分部积分，面项已归入出流矩阵和入流右端，剩下体输运矩阵 <span data-tex="\mathsf T"></span> 和损失矩阵 <span data-tex="\sigma\mathsf H"></span>：</p>
   <div class="formula" data-tex="\begin{aligned}T_{ab}&amp;=-\int_K r\phi_b(\boldsymbol\Omega\cdot\nabla\phi_a)\,\mathrm dr\,\mathrm dz,\\ H_{ab}&amp;=\int_K r\phi_a\phi_b\,\mathrm dr\,\mathrm dz.\end{aligned}"></div>
   <p class="small"><span data-tex="\sigma=\nu_K/v_m"></span> 在当前单元和离散速度下是常数。第一行的检验函数 <span data-tex="\phi_1=1"></span> 梯度为零，所以 <span data-tex="T_{1b}=0"></span>；这一行仍包含出流和损失，约束单元粒子收支。</p>
   <div class="code">sub_J02_add_volume_matrix / sub_J02_add_absorption_matrix</div>
   </template>
   <template id="assembly-solve">
   <div class="formula" data-tex="\mathsf A=\mathsf T+\sigma\mathsf H+\sum_{f:\,\beta_f&gt;0}\mathsf F_f,\qquad \mathsf A\boldsymbol c^{(\ell+1)}=\boldsymbol b^{(\ell+1)}"></div>
   <p>用部分选主元求解三阶线性方程组，再检查四个角点 <span data-tex="\psi=c_0\pm c_1\pm c_2"></span> 是否非负。若出现负值，采用常数回退：</p>
   <div class="formula" data-tex="\boldsymbol c^{(\ell+1)}\leftarrow\begin{pmatrix}b_1^{(\ell+1)}/A_{11}\\0\\0\end{pmatrix}"></div>
   <p class="small">这里 <span data-tex="b_1"></span> 和 <span data-tex="A_{11}"></span> 是矩阵第一行的元素，对应程序中的 <code>rhs(1)</code>、<code>a(1,1)</code>。回退保留第一行粒子收支，一般不再满足原系统的第二、三行。</p>
   <p>将三个系数写入本轮分布，随后供下游单元计算入流。图中当前单元变为“✓ 已求解”。</p>
   <div class="code">sub_J02_solve_local_3x3 → sub_J02_enforce_local_positivity → psi(:,i,k,m)</div>
   </template>
   </template>

.. raw:: html

   <template id="j02-view-en">
   <h1>How does one reflection iteration build the distribution?</h1>
   <p>The grid has 4 × 6 cells, eight directions and one speed. Particles enter through the middle of the lower boundary. The side walls and the rest of the lower boundary reflect, the top is open and particles can be lost inside the domain.</p>
   <p class="muted">Colors show which cells have been solved. Playback illustrates dependencies; it does not compute density or measure runtime. Here the inlet spans two whole faces. The accompanying chapter covers partial-face integration.</p>
   <div class="controls">
   <label>Execution mode <select id="mode"><option value="hybrid">2 × 2 spatial blocks, 2 threads per block</option><option value="single">One domain, 2 threads</option></select></label>
   <label>Velocity direction <select id="quadrant"></select></label>
   </div>
   <div class="controls">
   <button id="reset">Reset to first iteration</button><button id="prev">Previous</button><button id="play" class="primary">Play</button><button id="next">Next</button>
   <label>Playback speed <select id="pace"><option value="700">Slow</option><option value="350" selected>Normal</option><option value="120">Fast</option></select></label><span id="iteration" class="iteration"></span>
   </div>
   <div class="range"><label for="timeline">Iteration progress</label><input id="timeline" type="range" min="0" value="0"><output id="progress"></output></div>
   <div class="layout">
   <section class="panel">
   <svg id="domain" viewBox="0 0 470 470" role="img" aria-label="Four-by-six grid with upwind dependencies and MPI block interfaces"><defs><marker id="arrow" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto"><path d="M0 0L8 4L0 8" fill="#155b8f"/></marker><marker id="wallarrow" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto"><path d="M0 0L8 4L0 8" fill="#8c3970"/></marker></defs><g id="drawing"></g></svg>
   <div class="legend"><span class="key" style="--c:#fff">Pending</span><span class="key" style="--c:#dcebf6">✓ Solved</span><span class="key" style="--c:#f3d491">● Current cell</span><span class="old">Purple arrow: reflected inflow from the previous iteration</span></div>
   <p class="muted">Radius r increases rightward and z upward. Cells are indexed by (i,k). <span data-tex="P_{p_r,p_z}"></span> identifies radial and axial block indices starting at zero. MPI ranks and physical coordinates are defined separately.</p>
   </section>
   <section class="panel">
   <div id="stage" class="stage" aria-live="polite"></div>
   <div id="explanation"></div><div id="workers" class="workers"></div>
   <p id="routine" class="code"></p>
   <div class="status"><span class="old">Wall inflow reads the completed iteration: <span data-tex="\boldsymbol c_{K,R_f(m)}^{(\ell)}"></span></span><br><span class="new">Interior faces read upstream cells in the current sweep: <span data-tex="\boldsymbol c_{K_{\mathrm{up}},m}^{(\ell+1)}"></span></span><br>Prescribed inlet <span data-tex="h_m"></span> stays fixed throughout the iterations.</div>
   <p class="small">Each thread handles one velocity and writes its own distribution. The animation advances directions with the same signs together for clarity. Actual threads can finish at different times.</p>
   <button id="repeat" hidden>Start the next iteration with these results</button>
   <button id="finish" hidden>If converged, view reconstruction</button>
   </section>
   </div>
   <section class="panel" id="convergence" hidden>
   <h2>How is convergence checked?</h2>
   <p>As in the chapter, <span data-tex="K"></span> ranges over all cells, <span data-tex="m"></span> over discrete velocities, and <span data-tex="j=0,1,2"></span> over the three coefficients for each cell and velocity. Use the largest absolute coefficient from both iterates as a common scale.</p>
   <div class="formula" data-tex="S=\max_{K,m,\;j=0,1,2}\left\{|c_{j,K,m}^{(\ell)}|,\ |c_{j,K,m}^{(\ell+1)}|\right\}"></div>
   <p>If <span data-tex="S&gt;0"></span>, compute the change <span data-tex="D"></span> and the sums of absolute coefficients for the two iterates, <span data-tex="B_{\mathrm{old}},B_{\mathrm{new}}"></span>:</p>
   <div class="formula" data-tex="\begin{aligned}D&amp;=\sum_{K,m}\sum_{j=0}^{2}\left|\frac{c_{j,K,m}^{(\ell+1)}}S-\frac{c_{j,K,m}^{(\ell)}}S\right|,\\ B_{\mathrm{old}}&amp;=\sum_{K,m}\sum_{j=0}^{2}\left|\frac{c_{j,K,m}^{(\ell)}}S\right|,\qquad B_{\mathrm{new}}=\sum_{K,m}\sum_{j=0}^{2}\left|\frac{c_{j,K,m}^{(\ell+1)}}S\right|.\end{aligned}"></div>
   <div class="formula" data-tex="E_{\ell+1}=\frac{D}{\max(B_{\mathrm{old}},B_{\mathrm{new}})}"></div>
   <p class="small">Scaling cancels in the ratio and avoids summing large values directly. If <span data-tex="S=0"></span>, both iterates are zero and <span data-tex="E_{\ell+1}=0"></span>. The stopping condition requires at least two iterations and <span data-tex="E_{\ell+1}\leq\text{tolerance}"></span>. The caller supplies <span data-tex="\text{tolerance}"></span> as the relative-change tolerance. This compares consecutive iterates. Discretization error and particle balance require separate checks.</p>
   </section>
   <section class="panel" id="equations">
   <h2>How is the cell equation assembled?</h2>
   <p class="small">Fix cell <span data-tex="K"></span> and discrete velocity <span data-tex="m"></span>. The local integrals below omit those indices. Matrices are denoted by <span data-tex="\mathsf A"></span>, vectors by <span data-tex="\boldsymbol c,\boldsymbol b,\boldsymbol\phi"></span>, and individual entries by <span data-tex="A_{ab},b_a,\phi_a"></span>.</p>
   <div class="formula" data-tex="\boldsymbol\phi=\begin{pmatrix}1\\\xi\\\zeta\end{pmatrix},\qquad \boldsymbol c=\begin{pmatrix}c_0\\c_1\\c_2\end{pmatrix},\qquad \psi_m=\boldsymbol\phi^{\mathsf T}\boldsymbol c=c_0+c_1\xi+c_2\zeta"></div>
   <p class="small">As in the text and Fortran arrays, the row and column indices are <span data-tex="a,b=1,2,3"></span>. The coefficient indices are <span data-tex="0,1,2"></span>, so column <span data-tex="b"></span> corresponds to <span data-tex="c_{b-1}"></span>. The superscript <span data-tex="(\ell)"></span> identifies the completed iteration and <span data-tex="(\ell+1)"></span> identifies the iteration being solved.</p>
   <p class="small"><span data-tex="\boldsymbol\Omega_m=(\mu_m,\eta_m)^{\mathsf T}"></span> is the unit direction and <span data-tex="\beta_{f,m}=\boldsymbol\Omega_m\cdot\boldsymbol n_f"></span> is its dot product with the outward face normal. The loss per unit path length is <span data-tex="\sigma_{K,m}=\nu_K/v_m"></span>. Here <span data-tex="v_m"></span> is the speed and <span data-tex="\nu_K"></span> is the loss frequency.</p>
   <p class="small">The local coordinates are <span data-tex="\xi=(r-r_c)/h_r"></span>, <span data-tex="\zeta=(z-z_c)/h_z"></span>; <span data-tex="h_r,h_z"></span> are the radial and axial cell half-widths.</p>
   <div class="steps" id="terms"><button data-term="incoming" aria-pressed="true">1 Inflow right-hand side</button><button data-term="outgoing" aria-pressed="false">2 Outflow matrix</button><button data-term="volume" aria-pressed="false">3 Volume streaming and loss</button><button data-term="solve" aria-pressed="false">4 Solve and enforce positivity</button></div>
   <div id="assembly" class="term"></div>
   <details><summary>Why iterate the reflected inflow?</summary>
   <p>Particles arriving at a wall in one direction provide inflow in another. Reading a reflected direction before the current sweep has solved it introduces a cycle. The sweep holds the previous wall outflow fixed while taking interior-face values from upstream cells solved in the current iteration.</p>
   <p><span data-tex="W"></span> is the reflecting region of the current face, <span data-tex="A_W=\int_W\mathrm dA"></span> its physical area, and <span data-tex="\boldsymbol x\in W"></span> a position on the wall. The diffuse fraction is <span data-tex="d"></span> and the specular partner is <span data-tex="R_f(m)"></span>. The wall distribution shape is <span data-tex="g_{\mathrm w,m}"></span> and the velocity integration weight is <span data-tex="w_m"></span>.</p>
   <div class="formula" data-tex="\begin{aligned}\psi_{W,m}^{\mathrm{in},(\ell+1)}(\boldsymbol x)&amp;=(1-d)\,\psi_{W,R_f(m)}^{\mathrm{out},(\ell)}(\boldsymbol x)\\&amp;\quad+d\,C_W^{(\ell)}g_{\mathrm w,m},\qquad \beta_{f,m}&lt;0.\end{aligned}"></div>
   <p>Integrate the previous outgoing distribution to find the particle rate incident on this wall region.</p>
   <div class="formula" data-tex="Q_W^{\mathrm{out},(\ell)}=\sum_{m:\,\beta_{f,m}&gt;0}w_mv_m\beta_{f,m}\int_W\psi_{W,m}^{\mathrm{out},(\ell)}(\boldsymbol x)\,\mathrm dA"></div>
   <p>Equate incident and returned particle rates to obtain the diffuse coefficient of each wall region.</p>
   <div class="formula" data-tex="C_W^{(\ell)}=\frac{Q_W^{\mathrm{out},(\ell)}}{A_W\displaystyle\sum_{m:\,\beta_{f,m}&lt;0}w_mv_m|\beta_{f,m}|g_{\mathrm w,m}}"></div>
   <p>The specular term preserves the dependence on wall position <span data-tex="\boldsymbol x"></span>. The diffuse coefficient <span data-tex="C_W^{(\ell)}"></span> is constant over the region and balances its total incident and reflected particle rates.</p>
   </details>
   <p class="muted">The diagram shows one permissible order for the MPI blocks. In the solver, communication and upstream dependencies determine when each rank can proceed. The wavefronts shown here impose no global barrier and report no performance measurements.</p>
   </section>
   <noscript>Enable JavaScript to play the animation. The parent page and the Upwind Sweep, Reflection Iteration, and Distributed Sweep and Flux pages give the equations and corresponding source routines.</noscript>
   <template id="assembly-incoming">
   <p><span data-cell></span> receives its right-hand side from the two upwind faces. An interior face reads the upstream polynomial from this sweep, a partition interface reads the three received coefficients, the inlet uses <span data-tex="h_m"></span> and a wall uses the reflected inflow from the previous distribution.</p>
   <div class="formula" data-tex="b_a^{(\ell+1)}=\sum_{f:\,\beta_f&lt;0}|\beta_f|\int_f r\phi_a\psi_f^{\mathrm{up},(\ell+1)}\,\mathrm ds"></div>
   <p class="small"><span data-tex="\psi_f^{\mathrm{up},(\ell+1)}"></span> is the known inflow trace in this iteration. Wall values come from the old field. Across a partition boundary the upstream cell sends <span data-tex="\boldsymbol c^{(\ell+1)}=(c_0^{(\ell+1)},c_1^{(\ell+1)},c_2^{(\ell+1)})^{\mathsf T}"></span>.</p>
   <div class="code">sub_J02_add_neighbor_rhs / sub_J02_add_constant_rhs / sub_J02_add_specular_rhs</div>
   </template>
   <template id="assembly-outgoing">
   <p>An outgoing face satisfies <span data-tex="\beta_f&gt;0"></span> and uses the unknown trace from this cell. Substituting <span data-tex="\psi=\sum_{b=1}^{3}\phi_b c_{b-1}"></span> into the face integral gives the following matrix for each outgoing face.</p>
   <div class="formula" data-tex="(F_f)_{ab}=|\beta_f|\int_f r\phi_a\phi_b\,\mathrm ds,\qquad a,b=1,2,3"></div>
   <p class="small">On a radial face <span data-tex="r"></span> is constant and <span data-tex="\mathrm ds=\mathrm dz"></span>. On an axial face <span data-tex="\mathrm ds=\mathrm dr"></span>. The common azimuthal span cancels. The cell matrix includes <span data-tex="\mathsf F_f"></span> from every outgoing face.</p>
   <div class="code">sub_J02_add_self_face_matrix</div>
   </template>
   <template id="assembly-volume">
   <p>Multiply the conservative transport equation by <span data-tex="\phi_a"></span> and integrate by parts. After collecting the boundary terms, the cell retains the streaming matrix <span data-tex="\mathsf T"></span> and loss matrix <span data-tex="\sigma\mathsf H"></span>.</p>
   <div class="formula" data-tex="\begin{aligned}T_{ab}&amp;=-\int_K r\phi_b(\boldsymbol\Omega\cdot\nabla\phi_a)\,\mathrm dr\,\mathrm dz,\\ H_{ab}&amp;=\int_K r\phi_a\phi_b\,\mathrm dr\,\mathrm dz.\end{aligned}"></div>
   <p class="small"><span data-tex="\sigma=\nu_K/v_m"></span> is constant for this cell and velocity. The first test function <span data-tex="\phi_1=1"></span> has zero gradient, so <span data-tex="T_{1b}=0"></span>. Outflow and loss remain in the first row and enforce the cell particle balance.</p>
   <div class="code">sub_J02_add_volume_matrix / sub_J02_add_absorption_matrix</div>
   </template>
   <template id="assembly-solve">
   <div class="formula" data-tex="\mathsf A=\mathsf T+\sigma\mathsf H+\sum_{f:\,\beta_f&gt;0}\mathsf F_f,\qquad \mathsf A\boldsymbol c^{(\ell+1)}=\boldsymbol b^{(\ell+1)}"></div>
   <p>Solve the three equations with partial pivoting. At the four corners check whether <span data-tex="\psi=c_0\pm c_1\pm c_2"></span> is nonnegative. If any corner value is negative, fall back to a constant distribution.</p>
   <div class="formula" data-tex="\boldsymbol c^{(\ell+1)}\leftarrow\begin{pmatrix}b_1^{(\ell+1)}/A_{11}\\0\\0\end{pmatrix}"></div>
   <p class="small">Here <span data-tex="b_1"></span> and <span data-tex="A_{11}"></span> correspond to <code>rhs(1)</code> and <code>a(1,1)</code>. The fallback preserves the particle balance in the first row and generally no longer satisfies rows two and three.</p>
   <p>Store the three new coefficients for downstream cells to read on their inflow faces. The current cell is now marked as solved.</p>
   <div class="code">sub_J02_solve_local_3x3 → sub_J02_enforce_local_positivity → psi(:,i,k,m)</div>
   </template>
   </template>

.. raw:: html

   <template id="j02-frame-head">
   <meta charset="utf-8">
   <meta name="viewport" content="width=device-width, initial-scale=1">
   <link rel="stylesheet" href="../../../_static/J_Fluid/sn_walkthrough.css">
   <script src="../../../_static/katex.min.js"></script>
   </template>
   <template id="j02-frame-script">
   <script type="module">

.. raw:: html
   :file: ../../../_static/J_Fluid/sn_walkthrough_model.mjs

.. raw:: html

   const $=id=>document.getElementById(id);
   const english=document.documentElement.lang==="en";
   const label=(zh,en)=>english?en:zh;
   const mathCache=new Map();
   // Reuse Sphinx's local KaTeX parser; the browser renders the resulting MathML.
   function typeset(root){
    for(const el of root.querySelectorAll("[data-tex]")){
     const tex=el.dataset.tex,display=el.classList.contains("formula"),key=display+":"+tex;
     if(el.dataset.rendered===key)continue;
     if(!mathCache.has(key))mathCache.set(key,katex.renderToString(tex,{
      output:"mathml",displayMode:display,throwOnError:true,strict:"error"
     }));
     el.innerHTML=mathCache.get(key);
     // MathML Core only guarantees the normal variant; preserve the requested
     // matrix/vector font with CSS in browsers that ignore the other variants.
     for(const glyph of el.querySelectorAll('[mathvariant="bold-italic"],[mathvariant="sans-serif"]')){
      glyph.dataset.variant=glyph.getAttribute("mathvariant");
      glyph.setAttribute("mathvariant","normal");
     }
     el.dataset.rendered=key;
    }
   }
   let mode="hybrid",frames=schedule(mode),index=0,iteration=1,timer=null,term="incoming",reconstructed=false;
   quadrants.forEach((q,i)=>{const o=document.createElement("option");o.value=i;o.textContent=q.label.replace("，",label("，",", "));$("quadrant").append(o)});
   function stop(){clearTimeout(timer);timer=null;$("play").textContent=label("播放","Play")}
   function play(){if(index===frames.length-1){stop();return}index++;render();timer=setTimeout(play,Number($("pace").value))}
   function setIndex(i){stop();reconstructed=false;index=Math.max(0,Math.min(frames.length-1,i));render()}
   $("play").onclick=()=>{if(timer){stop()}else{$("play").textContent=label("暂停","Pause");timer=setTimeout(play,Number($("pace").value))}};
   $("prev").onclick=()=>setIndex(index-1);$("next").onclick=()=>setIndex(index+1);
   $("timeline").oninput=()=>setIndex(Number($("timeline").value));
   $("reset").onclick=()=>{iteration=1;setIndex(0)};
   $("mode").onchange=()=>{mode=$("mode").value;frames=schedule(mode);setIndex(0)};
   $("quadrant").onchange=()=>setIndex(frames.findIndex(f=>f.q===Number($("quadrant").value)&&f.phase!=="boundary"));
   $("repeat").onclick=()=>{iteration++;setIndex(0)};
   $("finish").onclick=()=>{stop();reconstructed=true;render()};
   document.querySelectorAll("[data-term]").forEach(b=>b.onclick=()=>{term=b.dataset.term;renderAssembly();sendSize()});
   document.addEventListener("visibilitychange",()=>{if(document.hidden)stop()});
   window.addEventListener("pagehide",stop);
   const same=(a,b)=>a[0]===b[0]&&a[1]===b[1], inside=([i,k])=>i>=0&&i<NR&&k>=0&&k<NZ;
   const point=([i,k])=>[74+i*76+38,402-k*52-26];
   function draw(){
    const f=frames[index],q=quadrants[f.q],done=f.done,current=f.cells;
    let out="";
    const line=(x1,y1,x2,y2,color="#155b8f",dash="",arrow=true)=>'<line x1="'+x1+'" y1="'+y1+'" x2="'+x2+'" y2="'+y2+'" stroke="'+color+'" stroke-width="2" '+(dash?'stroke-dasharray="'+dash+'" ':'')+(arrow?'marker-end="url(#'+(color==="#8c3970"?"wallarrow":"arrow")+')"':'')+'/>';
    const text=(x,y,value,extra="")=>'<text x="'+x+'" y="'+y+'" '+extra+'>'+value+'</text>';
    out+=text(84,20,label("上端开放：外部入射为零","Open outlet: zero external inflow"));
    for(let i=0;i<NR;i++)for(let k=0;k<NZ;k++){
     const cell=[i,k],isCurrent=current.some(c=>same(c,cell)),isDone=done.some(c=>same(c,cell));
     const [x,y]=point(cell);
     out+='<rect x="'+(x-37)+'" y="'+(y-25)+'" width="74" height="50" fill="'+(isCurrent?"#f3d491":isDone?"#dcebf6":"#fff")+'" stroke="'+(isCurrent?"#8b651d":"#a4b1bc")+'" stroke-width="'+(isCurrent?2:1)+'"/>';
     out+=text(x,y+4,(isCurrent?"● ":isDone?"✓ ":"")+(i+1)+","+(k+1),'text-anchor="middle"');
    }
    // The same global boundaries exist in both execution modes.
    out+=line(71,402,71,90,"#8c3970","",false)+line(381,402,381,90,"#8c3970","",false);
    out+=line(74,405,150,405,"#8c3970","",false)+line(302,405,378,405,"#8c3970","",false);
    out+=line(151,406,301,406,"#155b8f","",false);
    out+=text(166,431,label('给定入口 <tspan font-style="italic">h</tspan><tspan baseline-shift="sub" font-size="10">m</tspan>',"Prescribed inlet <tspan font-style=\"italic\">h</tspan><tspan baseline-shift=\"sub\" font-size=\"10\">m</tspan>"));
    out+=text(11,260,label("反射壁","Reflecting wall"),'transform="rotate(-90 11 260)"')+text(450,200,label("反射壁","Reflecting wall"),'transform="rotate(90 450 200)"');
    out+=line(74,402,74,66,"#24313d","",false)+text(53,65,"z ↑")+text(376,452,"r →");
    if(mode==="hybrid"){
     out+=line(226,90,226,402,"#5e6870","6 4",false)+line(74,246,378,246,"#5e6870","6 4",false);
     for(let x=0;x<2;x++)for(let y=0;y<2;y++)out+=text(77+x*152,101+(1-y)*156,'P<tspan baseline-shift="sub" font-size="9">'+x+','+y+'</tspan>','style="font-size:10px"');
    }
    if(f.phase==="cell"){
     for(const c of current){
      const [x,y]=point(c);
      for(const up of upstream(f.q,...c)){
       const [ux,uy]=point(up);
       if(inside(up)){
        const remote=mode==="hybrid"&&!same(owner(...up),owner(...c));
        out+=line(ux,uy,x,y,"#155b8f",remote?"4 3":"");
       }else{
        const wall=(up[0]<0||up[0]>=NR)||(up[1]<0&&(c[0]===0||c[0]===3));
        const clippedX=Math.max(58,Math.min(395,ux)),clippedY=Math.max(62,Math.min(420,uy));
        out+=line(clippedX,clippedY,x,y,wall?"#8c3970":"#155b8f",wall?"4 3":"");
       }
      }
     }
    }
    if((f.phase==="receive"||f.phase==="send")&&mode==="hybrid"){
     for(const [x,y] of f.blocks){
      const c=[2*x+(q.sr>0?0:1),3*y+(q.sz>0?0:2)];
      const end=f.phase==="send"?[2*x+(q.sr>0?1:0),3*y+(q.sz>0?2:0)]:c;
      for(const delta of [[q.sr,0],[0,q.sz]]){
       const from=f.phase==="send"?end:[c[0]-delta[0],c[1]-delta[1]],to=f.phase==="send"?[end[0]+delta[0],end[1]+delta[1]]:c;
       if(inside(from)&&inside(to)){const a=point(from),b=point(to);out+=line(...a,...b,"#155b8f","4 3")}
      }
     }
    }
    if(f.phase==="boundary"){
     out+=text(89,48,iteration===1?label("旧分布为零 → 第一轮反射入流为零","Zero initial field → zero reflected inflow"):label("读取上一轮壁面出射 → 固定本轮反射入流","Previous outflow → fixed reflected inflow"));
    }
    $("drawing").innerHTML=out;
   }
   function renderAssembly(){
    document.querySelectorAll("[data-term]").forEach(b=>b.setAttribute("aria-pressed",String(b.dataset.term===term)));
    const cell=frames[index].cells[0];
    const content=$("assembly-"+term).content.cloneNode(true);
    const cellLabel=content.querySelector("[data-cell]");
    if(cellLabel){
     cellLabel.textContent=cell ? label("当前单元","Cell")+" ("+(cell[0]+1)+","+(cell[1]+1)+")" : label("任一待求解单元 K","Cell K");
    }
    $("assembly").replaceChildren(content);
    typeset($("assembly"));
   }
   function render(){
    const f=frames[index],q=quadrants[f.q];
    $("timeline").max=frames.length-1;$("timeline").value=index;$("progress").value=(index+1)+"/"+frames.length;
    $("iteration").textContent=label("当前第 ","Iteration ")+iteration+label(" 轮（ℓ = "," (ℓ = ")+(iteration-1)+label("）",")");$("quadrant").value=f.q;
    $("prev").disabled=index===0;$("next").disabled=index===frames.length-1;$("play").disabled=index===frames.length-1;
    $("convergence").hidden=f.phase!=="check"||reconstructed;
    $("repeat").hidden=f.phase!=="check";$("finish").hidden=f.phase!=="check";
    $("finish").disabled=iteration<2;$("finish").title=iteration<2?label("正式程序至少完成两轮后才检查收敛出口","The solver checks for convergence after at least two iterations."):"";
    const cells=f.cells.map(([i,k])=>"("+(i+1)+","+(k+1)+")").join(label("、",", "));
    const stages = {
     boundary: [
      label("固定本轮边界入流", "Fix the boundary inflow"),
      label(
       "上一轮所有速度的分布保持不变。逐面计算漫反射归一化，并按镜面对应方向读取旧出射分布。",
       "Hold the previous distribution fixed at all velocities. Normalize diffuse reflection on each wall region and read the old outgoing trace in the specular partner direction. "
      ) + (iteration === 1
       ? label(
       "第一轮旧分布为零；只有规定入口提供粒子。",
       "Initially the old distribution is zero. Only the prescribed inlet supplies particles."
      )
       : label(
       "从第二轮起，壁面返回上一轮到达壁面的粒子。",
       "From the second iteration on, the wall returns particles that reached it in the previous iteration."
      )),
      "sub_J02_solve_source_iteration → sub_J02_sweep / sub_J02_compute_diffuse_wall_constants",
     ],
     ready: [
      label("分配离散速度任务", "Assign discrete velocities"),
      label(
       "单域 OpenMP 可以同时分配所有离散速度。这里分四组显示，便于观察迎风方向；单域程序没有四组之间的同步屏障。",
       "In a single domain, OpenMP may assign all velocities at once. The animation groups them by quadrant to show the sweep direction. The solver needs no barrier between these groups."
      ),
      "sub_J02_sweep_batch · schedule(static)",
     ],
     receive: [
      label("接收上游分区系数", "Receive upstream coefficients"),
      label("本组方向：", "Velocity group: ")+q.label.replace("，",label("，", ", "))+label(
       "。当前分区先接收两个上游方向的界面系数，随后才能开始区域内扫描。物理外边界没有上游进程，按入口、出口或壁面条件处理。",
       ". This block receives interface coefficients from its upstream neighbors before its local sweep. At physical boundaries it applies the inlet, outlet or wall condition."
      ),
      "sub_J02_mpi_sweep · MPI_Recv → sub_J02_sweep_batch",
     ],
     cell: [
      label("求解单元 ", "Solve cell ")+cells,
      label(
       "按 i 外层、k 内层的迎风顺序前进。蓝箭头指出本轮已知的上游；虚线跨分区箭头使用接收缓冲区；紫箭头来自上一轮壁面。下方展开本单元方程的四个组装步骤。",
       "The sweep follows i in the outer loop and k in the inner loop. Blue arrows show upstream data from this iteration. Dashed blue arrows read another block's receive buffer. Purple arrows use the previous wall data. The four assembly steps below show how the cell is solved."
      ),
      label(
       "sub_J02_sweep_velocity → DG 单元装配 → 3×3 求解 → 保正",
       "sub_J02_sweep_velocity → DG assembly → 3×3 solve → positivity check"
      ),
     ],
     send: [
      label("发送下游分区所需系数", "Send downstream coefficients"),
      label(
       "本分区完成这一方向组的全部速度任务后，将两个下游边界上的三个系数打包发送，并等待发送完成。接收方据此继续。图中同一波前的分区可以并行。",
       "After all velocities in this quadrant finish locally, the block packs the three coefficients on its two downstream edges, sends them and waits for completion. The receiving blocks can then proceed. Blocks on the same wavefront can work in parallel."
      ),
      "sub_J02_mpi_sweep · MPI_Isend → MPI_Waitall",
     ],
     quadrant: [
      label("这一符号组合完成", "Quadrant complete"),
      label(
       "这组离散速度在整个域内已有本轮分布。下一组改变迎风方向，壁面仍使用同一份上一轮数据，不立即使用刚得到的出射结果。",
       "The current iterate is now available for these velocities throughout the domain. The next group follows a different sweep direction and continues to use wall inflow from the previous iterate."
      ),
      "sub_J02_mpi_sweep · quadrant = 0,1,2,3",
     ],
     check: [
      label("所有速度完成：检查反射迭代", "All velocities complete: check convergence"),
      label(
       "比较本轮与上一轮的全部空间系数，按下方公式计算相对变化。MPI 的最大值与求和覆盖所有分区。至少完成两轮且达到容差后才停止；本图仅演示流程，不计算实际收敛值。",
       "Compare all spatial coefficients with the previous iterate using the relative change below. MPI reductions include every block. The solver stops after at least two iterations once the tolerance is met. This animation illustrates the sequence without computing a residual."
      ),
      label(
       "sub_J02_solve_source_iteration · 全域归约 → 相对变化判据",
       "sub_J02_solve_source_iteration · global reductions → relative change"
      ),
     ],
    };
    let [title,desc,routine]=stages[f.phase];
    if(reconstructed){title=label("收敛后：积分得到场与面通量","After convergence: reconstruct fields and face fluxes");desc=label("对各离散速度用权重求和，先得到单元密度和平均速度，再按迎风面迹重构内部面与开放面通量。MPI 还重构进程交界面通量；只有全部成功后 result%converged 才置真。","Integrate over the velocity weights to obtain cell density and mean velocity. Use upwind traces for interior and open faces. MPI also reconstructs fluxes at block interfaces. Only after all stages succeed does result%converged become true.");routine="sub_J02_reconstruct_cell_moments → internal_face_fluxes → open_boundary_fluxes → partition_fluxes";}
    $("stage").textContent=title;$("explanation").textContent=desc;$("routine").textContent=routine;
    $("workers").innerHTML=q.velocities.map((m,t)=>'<span class="worker">'+label('线程示意 ', 'Thread ')+(t+1)+' · m = '+m+' '+q.label.slice(-1)+'</span>').join("");
    draw();renderAssembly();sendSize();
   }
   function sendSize(){
    if(parent===window)return;
    // Local documents have opaque origins; the parent also checks the sending frame.
    const parentURL = new URL(document.baseURI);
    const targetOrigin = parentURL.protocol === "file:" ? "*" : parentURL.origin;
    requestAnimationFrame(()=>parent.postMessage({type:"sn-walkthrough-height",height:Math.ceil(document.body.getBoundingClientRect().height)},targetOrigin));
   }
   new ResizeObserver(sendSize).observe(document.body);document.querySelectorAll("details").forEach(d=>d.addEventListener("toggle",sendSize));
   typeset(document);
   render();
   </script>
   </template>

.. raw:: html

   <script>
   (() => {
     const head = document.getElementById("j02-frame-head");
     const script = document.getElementById("j02-frame-script");
     const frames = ["sn-walkthrough", "sn-walkthrough-en"].map(id => document.getElementById(id));
     for (const [index, language] of ["zh", "en"].entries()) {
       const view = document.getElementById("j02-view-" + language);
       // The Chinese source is a complete HTML document. Both views use the head and model below.
       view.content.querySelectorAll("meta, title, link, script").forEach(node => node.remove());
       frames[index].srcdoc = '<!doctype html><html lang="' + language + '"><head>' +
         head.innerHTML + '<title>' + frames[index].title + '</title></head><body>' +
         view.innerHTML + script.innerHTML + '</body></html>';
     }
     window.addEventListener("message", event => {
       if (event.data?.type !== "sn-walkthrough-height") return;
       const frame = frames.find(item => item.contentWindow === event.source);
       if (!frame) return;
       const localFrame = location.protocol === "file:" && event.origin === "null";
       if (!localFrame && event.origin !== location.origin) return;
       const height = event.data.height;
       if (Number.isFinite(height) && height >= 300 && height <= 5000) {
         frame.style.height = (height + 6) + "px";
       }
     });
   })();
   </script>
