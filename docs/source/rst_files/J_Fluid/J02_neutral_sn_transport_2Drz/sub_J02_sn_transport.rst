Complete Calculation
==========================================================================================

``sub_J02_sn_transport.f90`` 提供完整求解接口：
根据调用者已经准备好的物理条件，选择一次扫描或反射迭代，
再依次重构密度、速度和面通量。
本页沿用总览中的环形通道，按调用顺序说明每一步需要哪些输入、产生哪些数据。

.. rubric:: 动态计算流程

下图先展示小网格上的一轮扫描，再由本轮结果建立下一轮反射入流。
可切换单域或空间分区、改变速度方向、逐步查看每个单元的上游数据，
并展开右端、面矩阵、体矩阵和保正处理。示意中没有真实密度值，不能用它判断收敛速度或精度。

.. raw:: html

   <iframe id="sn-walkthrough" title="SN 迎风扫描、方程组装与反射迭代" src="../../../_static/J_Fluid/sn_walkthrough.html" style="width:100%;height:1400px;border:1px solid #d5dde3;" loading="lazy"></iframe>

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

1. 检查基础对象和入口表示，发现整面壁面或部分面区间后启用反射迭代。
2. 调用 ``sub_J02_solve_source_iteration``；
   每轮由上一轮出射分布计算壁面入流，调用 ``sub_J02_sweep`` 求新分布。
3. 只有求解成功，才调用 ``sub_J02_reconstruct_cell_moments``。
4. 接着调用 ``sub_J02_reconstruct_internal_face_fluxes``。
5. 最后调用 ``sub_J02_reconstruct_open_boundary_fluxes``，
   使用与求解一致的入口数据及区间。

全开放边界且采用整面入口时，执行一次扫描，再由所得分布完成上述三次积分重构。

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
