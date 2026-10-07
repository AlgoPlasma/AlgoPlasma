J02 Discrete Ordinates
==========================================================================================

J02 求解稳态中性粒子输运问题。输入包括计算域、入口粒子率与速度分布、壁面反射条件、
开放出口和体损失；输出是中性粒子的密度、平均速度及各网格面上的粒子通量。

计算的出发点是：具有不同速度的粒子沿不同方向运动，也可能有不同的损失强度。
离散纵标法（Discrete Ordinates Method，记作 SN）选取有限组确定的速度，
分别计算每组速度的粒子在空间中怎样分布，再对这些分布作加权求和，得到密度和通量。

空间上采用一阶不连续 Galerkin 方法（Discontinuous Galerkin，记作 DG，具体为 P1-DG）。
每个单元内用一次多项式表示分布，保存常数项和两个方向的一次项系数；
相邻单元通过面上的入流、出流联系起来。这里的“一阶”指多项式次数，
不是对所有算例的误差收敛阶作保证；保正处理还可能将个别单元退回常数表示。

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

.. figure:: /_static/J_Fluid/sn_problem.svg
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
