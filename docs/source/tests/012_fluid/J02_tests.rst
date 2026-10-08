J02 Local Processes
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 检查顺序

   局部测试沿着“几何与速度积分 → 边界输入 → 单元方程 → 场重构”展开。
   测试直接指定某一步的输入，用解析积分或已知数值核对输出。
   测试源码位于 ``tests/012_fluid/J02_neutral_sn_transport_2Drz/source_f90``，
   正式过程位于 ``J_Fluid/J02_neutral_sn_transport_2Drz``。

   .. list-table::
      :header-rows: 1
      :widths: 20 42 38

      * - 步骤
        - 测试文件
        - 正式文件及主要输出
      * - 几何与求积
        - ``test_J02_neutral_sn_transport_2Drz.f90``、``test_J02_transport_units.f90``
        - ``sub_J02_sn_geometry.f90``：体积、面积、面类型；``sub_J02_sn_quadrature.f90``：离散速度、权重
      * - 入口与壁面
        - 上述两个文件，加 ``test_J02_reflection_partial_inlet.f90``
        - ``sub_J02_sn_boundary.f90``：面类型；``sub_J02_sn_inflow.f90``：入口区间；``sub_J02_sn_source.f90``：入口分布；``sub_J02_sn_wall.f90``：反射映射与壁面归一化
      * - 单元方程
        - 上述文件，加 ``test_J02_dg_faces.f90``、``test_J02_positivity.f90``
        - ``sub_J02_sn_dg_operator.f90``：矩阵、右端、局部解及保正系数
      * - 场重构
        - ``test_J02_neutral_sn_transport_2Drz.f90``、``test_J02_transport_units.f90``
        - ``sub_J02_sn_reconstruction.f90``：密度、均速、内部和边界通量

   .. rubric:: 1. 从坐标核对体积、面积和面类型

   ``test_geometry`` 将径向边界 [1,2,4]、轴向边界 [0,2] 传给
   ``sub_J02_initialize_mesh``，再以张角 :math:`2\pi` 调用
   ``sub_J02_build_geometry``。第一个单元的解析量为

   .. math::

      V=2\pi\int_0^2\int_1^2r\,dr\,dz=6\pi,\qquad
      A_{r-}=4\pi,\quad A_{r+}=8\pi.

   该单元中心 :math:`r_c=1.5`、径向半宽 :math:`h_r=0.5`，
   所以线性基函数的径向平均系数 :math:`\bar\xi=h_r/(3r_c)=1/9`。
   体积与面积绝对容差为 :math:`10^{-12}`，平均系数容差为 :math:`10^{-14}`。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 环形体积
        - 18.84955592
        - 6π
        - 0
        - 1e−12
      * - 径向低/高面面积
        - 12.56637061 / 25.13274123
        - 4π / 8π
        - 0
        - 1e−12
      * - 径向平均系数
        - 0.1111111111
        - 1/9
        - 0
        - 1e−14

   ``test_axis_geometry`` 把单元改为 :math:`r\in[0,1],z\in[0,2]`，
   核对轴面面积为零、体积 :math:`2\pi`、平均系数 :math:`1/3`。
   这覆盖了半径下边界为零的情况。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 轴面面积
        - 0
        - 0
        - 0
        - 1e−14
      * - 轴单元体积
        - 6.283185307
        - 2π
        - 0
        - 1e−13
      * - 轴单元平均系数
        - 0.3333333333
        - 1/3
        - 0
        - 1e−14

   ``test_face_topology`` 调用 ``sub_J02_initialize_boundary_types``：
   两个有效单元的公共面两侧都应为 INTERIOR，网格外侧为 OPEN。
   将右单元设为无效后，左单元右面应变为 WALL。
   ``test_partial_inlet_boundary`` 再给下端开口比例 [0,0.25]，
   调用 ``sub_J02_configure_zlo_partial_inlet_boundary``，
   核对两个下端面分别为 WALL、OPEN。

   **实测状态。** 共享面两侧均为 INTERIOR，外边界为 OPEN，无效邻居处为 WALL；
   部分入口两个下端面实际为 WALL、OPEN，均与上述预期一致。

   .. rubric:: 2. 从速度圆盘积分核对求积权重

   ``test_quadrature`` 调用 ``sub_J02_build_phase_quadrature``，
   使用 8 个角度、2 个速率区间、最大速率 4。
   输出应有 16 个离散速度，两个速率取值分别为 1、3。
   以下用 :math:`g` 表示速率序号、:math:`a` 表示角度序号，
   合并序号为 :math:`m=(g-1)N_\theta+a`。
   离散速度为 :math:`\boldsymbol v_m=v_g(\mu_a,\eta_a)`，权重为 :math:`w_m`；
   对 :math:`m` 求和时，:math:`g,a` 取该速度对应的两个序号。

   以常数 1 为被积函数，精确积分等于速度圆盘面积：

   .. math::

      \sum_m w_m\ \longrightarrow\
      \int_0^{2\pi}\int_0^4 v\,dv\,d\theta=16\pi.

   按全圆对称性，还应有

   .. math::

      \sum_mw_m\mu_a=0,\qquad \sum_mw_m\eta_a=0.

   权重和绝对容差为 :math:`10^{-12}`，一阶方向矩容差为 :math:`10^{-13}`。
   再分别用 ``midpoint`` 和 ``gauss-chebyshev`` 调用，
   逐值检查两个别名生成相同数组。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 速度积分权重和
        - 50.26548246
        - 16π = 50.26548246
        - 1.4211e−14
        - 1e−12
      * - 径向方向矩
        - −4.4409e−15
        - 0
        - 4.4409e−15
        - 1e−13
      * - 轴向方向矩
        - −1.3323e−15
        - 0
        - 1.3323e−15
        - 1e−13
      * - 两种名称所得数组最大差
        - 0
        - 0
        - 0
        - 逐值相等

   ``test_frequency_conversion`` 使用同一求积、损失频率 :math:`\nu=6`，
   调用 ``sub_J02_build_sigma_from_frequency``。
   对应速率 1、3 的路程损失系数应为

   .. math::

      \sigma_1=6/1=6,\qquad \sigma_2=6/3=2,

   绝对容差为 :math:`10^{-13}`。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 速率 1 的损失系数
        - 6
        - 6
        - 0
        - 1e−13
      * - 速率 3 的损失系数
        - 2
        - 2
        - 0
        - 1e−13

   .. rubric:: 3. 入口分布怎样变成规定通量

   ``test_inflow_normalization`` 给定各离散速度上的形状为 1、
   下端外法向 :math:`(0,-1)`、目标入射通量 7。
   调用 ``sub_J02_normalize_inflow_flux`` 得到边界分布 :math:`h_m` 后，
   测试重新计算入射速度上的离散积分：

   .. math::

      J_{\rm in}^{\rm calc}=\sum_{\eta_a>0}w_m v_g\eta_a h_m.

   要求 :math:`|J_{\rm in}^{\rm calc}-7|<10^{-12}`。
   这里只累加入射方向；正法向出射速度不贡献该值。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 常数形状的入射通量
        - 7
        - 7
        - 8.8818e−16
        - 1e−12

   ``test_source_shapes`` 进一步调用
   ``sub_J02_build_drifted_maxwellian_inflow_shape``。
   输入温度 300 K、质量 :math:`6.6335209\times10^{-26}` kg，
   速度求积为 8 个角度、4 个速率区间、上限 2000 m/s。
   零漂移的二维 Maxwell 形状为

   .. math::

      g(\boldsymbol v)=\frac{\alpha}{\pi}e^{-\alpha|\boldsymbol v|^2},
      \qquad \alpha=\frac{m_{\rm particle}}{2k_BT}.

   第一速率组内 8 个值应相等，且与公式值相差不超过参考值的 :math:`10^{-13}`。
   径向漂移改为 300 m/s 后，正径向方向的形状值应高于对应负径向方向；
   将它归一化为通量 12，离散积分应在 :math:`10^{-12}` 内恢复 12。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 零漂移第一速度的形状值
        - 0.000001545263558
        - 二维 Maxwell 公式
        - 0
        - 1.5453e−19
      * - 同速率组各向同性最大差
        - 4.2352e−22
        - 0
        - 4.2352e−22
        - 1.5453e−19
      * - 漂移后入射通量
        - 12
        - 12
        - 1.7764e−15
        - 1e−12

   正/负径向对应形状值为 2.280114e−6 与 2.477764e−7，满足正漂移方向占优。

   同一子测试把前四个入射速度的相对概率设为 [1,2,3,4]，
   调用 ``sub_J02_build_mc_crossing_bins_inflow_shape`` 后归一化到总通量 10。
   四个速度各自的通量贡献应恰为 1、2、3、4，逐项容差 :math:`10^{-12}`。
   ``test_crossing_representations`` 则将同一概率写成
   :math:`P_m=w_mp_m`，分别通过 bins 和 pdf 两个入口转换，
   形状数组最大绝对差须小于 :math:`10^{-13}`。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 实测误差
        - 容差
      * - 四个离散速度的通量贡献最大误差
        - 8.8818e−16
        - 1e−12
      * - PDF 与区间概率转换后的最大差
        - 4.4409e−16
        - 1e−13

   .. rubric:: 4. 部分入口与壁面

   **部分入口。** ``test_partial_inlet_geometry`` 使用径向边界 [1,2,3]、
   入口 [1.5,2.5]，调用 ``sub_J02_build_partial_zlo_inlet``。
   面积比例由环形面积之比得到：

   .. math::

      \chi_1=\frac{2^2-1.5^2}{2^2-1^2}=\frac7{12},\qquad
      \chi_2=\frac{2.5^2-2^2}{3^2-2^2}=0.45.

   由 :math:`\xi=(r-r_c)/h_r`，两个开口区间应分别为 [0,1] 和 [−1,0]，
   绝对容差 :math:`10^{-14}`。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 两个面积比例
        - 7/12，0.45
        - 7/12，0.45
        - 最大差 0
        - 1e−14
      * - 两个局部开口区间
        - [0,1]，[−1,0]
        - [0,1]，[−1,0]
        - 最大差之和 0
        - 1e−14

   **部分面积分。** ``test_interval_operators`` 分别调用整面右端过程和区间右端过程，
   核对区间 [−1,1] 时两者相等。
   随后用 :math:`r_c=2,h_r=0.5,\xi\in[-0.5,0.5]`，
   调用 ``sub_J02_zface_interval_moments``。三个积分为

   .. math::

      M_j=h_r\int_{-1/2}^{1/2}(r_c+h_r\xi)\xi^j\,d\xi,\qquad
      (M_0,M_1,M_2)=\left(1,\frac1{48},\frac1{12}\right).

   三个绝对误差之和须不超过 :math:`10^{-14}`。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 实测误差
        - 容差
      * - 整面与全区间右端最大差
        - 0
        - 1e−14
      * - 三个矩的绝对误差之和
        - 0
        - 1e−14

   **镜面映射。** ``test_reflection_map`` 对 16 个离散速度逐个调用
   ``fun_J02_reflected_direction_index``，分别反射径向和轴向法向。
   核对法向分量反号、切向分量与速率保持，容差 :math:`2\times10^{-15}`。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 实测误差
        - 容差
      * - 16 个速度、两种法向的映射最大误差
        - 7.2164e−16
        - 2e−15

   **漫反射。** ``test_diffuse_normalization`` 将单元高端设为壁面，
   给定每个速度的空间系数
   :math:`(c_0,c_1,c_2)=(2+0.03m,0.1,-0.2)`。
   调用 ``sub_J02_compute_diffuse_wall_constants`` 得到 :math:`C` 后，
   分别累加该面的出射和反射入射：

   .. math::

      J_{\rm out}=\sum_{\eta_a>0}w_mv_g\eta_a
         (c_{0,m}+\bar\xi c_{1,m}+c_{2,m}),\qquad
      J_{\rm return}=\sum_{\eta_a<0}w_mv_g|\eta_a|C g_{w,m}.

   要求 :math:`|J_{\rm out}-J_{\rm return}|\le2\times10^{-13}`。
   这检查壁面归一化如何将给定出射分布转换为等粒子率的再入射。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 壁面返回通量
        - 86.28511539
        - 出射通量 86.28511539
        - 1.4211e−14
        - 2e−13

   .. rubric:: 5. 单元方程：体积、面、局部解

   空间基函数取 :math:`\boldsymbol\phi=(1,\xi,\zeta)^T`。
   矩阵三个行分别对应三个检验函数，列对应三个分布系数。

   **输运体积分。** ``test_local_volume_operator`` 从零矩阵开始，
   调用 ``sub_J02_add_volume_matrix``，输入方向
   :math:`(\mu,\eta)=(0.3,-0.4)` 及
   :math:`r_c=2,h_r=0.5,h_z=0.25`。
   弱形式的体积分为

   .. math::

      A^{\rm stream}_{pq}
        =-\int_K r\phi_q(\mu\partial_r\phi_p+\eta\partial_z\phi_p)\,dr\,dz.

   第一行检验函数为常数，导数为零。对另外两行积分得到

   .. math::

      \mathsf A^{\rm stream}=
      \begin{pmatrix}
      0&0&0\\
      -0.6&-0.05&0\\
      1.6&2/15&0
      \end{pmatrix}.

   最大逐项误差须小于 :math:`10^{-14}`。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 实测误差
        - 容差
      * - 输运矩阵逐元素最大误差
        - 6.9389e−18
        - 1e−14

   **吸收体积分。** ``test_absorption_matrix`` 调用
   ``sub_J02_add_absorption_matrix``，输入
   :math:`\sigma=2,r_c=3,h_r=0.5,h_z=0.25`。
   径向带权积分给出

   .. math::

      \mathsf A^{\rm loss}=
      \sigma h_rh_z\int_{-1}^1\int_{-1}^1
      (r_c+h_r\xi)\boldsymbol\phi\boldsymbol\phi^T\,d\xi\,d\zeta
      =
      \begin{pmatrix}3&1/6&0\\1/6&1&0\\0&0&1\end{pmatrix}.

   逐项容差同为 :math:`10^{-14}`。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 实测误差
        - 容差
      * - 吸收矩阵逐元素最大误差
        - 0
        - 1e−14

   **面贡献。** ``test_J02_dg_faces.f90`` 对四个面分别调用
   ``sub_J02_add_self_face_matrix``、``sub_J02_add_neighbor_rhs``、
   ``sub_J02_add_constant_rhs``。
   输入为 :math:`r_c=3,h_r=0.5,h_z=0.25,|\boldsymbol\Omega\cdot\boldsymbol n|=0.7`，
   邻居系数 [1.2,0.3,−0.2]，常数入口 1.3。

   正式过程使用展开的矩阵元素。测试则用三点 Gauss–Legendre 求积，
   在面上独立积分 :math:`r\boldsymbol\phi\boldsymbol\phi^T`、
   :math:`r\boldsymbol\phi\psi_{\rm up}` 和 :math:`r\boldsymbol\phi h`：

   .. math::

      x=(0,-\sqrt{3/5},\sqrt{3/5}),\qquad
      W=(8/9,5/9,5/9).

   面上被积多项式最高为三次，该规则可精确积分。
   邻居分布在其相反面取值；矩阵与右端预先设为非零，以检查新贡献加到原数组上。
   三类贡献分别取所有元素中的最大绝对误差，容差均为 :math:`2\times10^{-13}`。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 面
        - 自身矩阵误差
        - 邻居右端误差
        - 常数入口右端误差
      * - 径向低端
        - 5.5511e−17
        - 5.5511e−17
        - 0
      * - 径向高端
        - 1.6653e−16
        - 0
        - 2.2204e−16
      * - 轴向低端
        - 0
        - 0
        - 2.7756e−17
      * - 轴向高端
        - 0
        - 1.1102e−16
        - 2.7756e−17

   **局部解。** 同文件调用 ``sub_J02_solve_local_3x3``，
   使用首主元为零的可解系统：

   .. math::

      \begin{pmatrix}0&2&1\\1&-1&0\\2&1&3\end{pmatrix}
      \begin{pmatrix}1\\-2\\3\end{pmatrix}
      =
      \begin{pmatrix}-1\\3\\9\end{pmatrix}.

   测试核对解 [1,−2,3]，并检查输入矩阵、右端保持原值；
   奇异系统应返回局部求解错误。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 局部解
        - [1,−2,3]
        - [1,−2,3]
        - 最大差 0
        - 2e−13
      * - 输入矩阵与右端的改变量
        - 0
        - 0
        - 0
        - 2e−13

   **局部保正。** ``test_J02_positivity.f90`` 给出第一行
   :math:`A_{1,:}=(2,0.5,0.25)`、:math:`b_1=3`，
   初始系数 [1,2,0] 在一个角点为负。
   调用 ``sub_J02_enforce_local_positivity`` 后应得到 [1.5,0,0]，
   既非负又满足 :math:`A_{1,:}c=b_1`，容差 :math:`10^{-13}`。
   另检查负平均值的回退、合法系数的保持以及负入射粒子率的错误返回。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 修正后系数
        - [1.5,0,0]
        - [1.5,0,0]
        - 最大差 0
        - 1e−13
      * - 首行收支误差
        - 0
        - 0
        - 0
        - 1e−13

   .. rubric:: 6. 从指定分布重构密度和通量

   ``test_reconstruction`` 采用径向边界 [1,2,3]、轴向边界 [0,1,2]。
   只有单元 (1,1) 的第一个离散速度有非零系数 [2,3,4]。
   依次调用 ``sub_J02_reconstruct_cell_moments`` 和
   ``sub_J02_reconstruct_internal_face_fluxes``。

   该单元 :math:`\bar\xi=1/9`，体积平均分布为
   :math:`\bar\psi=2+3/9=7/3`。因此

   .. math::

      n=w_1\frac73,\qquad
      (u_r,u_z)=(v_{r,1},v_{z,1}).

   径向高端面取 :math:`\xi=1`，其面平均值为 :math:`2+3=5`；
   轴向高端面取 :math:`\zeta=1`，其加权平均值为 :math:`7/3+4=19/3`。
   对应内部面通量应为

   .. math::

      \Gamma_r=5w_1v_{r,1},\qquad
      \Gamma_z=\frac{19}{3}w_1v_{z,1}.

   :math:`v_{r,1},v_{z,1}` 是第一个离散速度的两个分量。
   逐项容差 :math:`10^{-13}`，其余单元密度应为零。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 密度
        - 3.665191429
        - w₁×7/3
        - 0
        - 1e−13
      * - 径向均速
        - 0.9238795325
        - 0.9238795325
        - 1.1102e−16
        - 1e−13
      * - 轴向均速
        - 0.3826834324
        - 0.3826834324
        - 0
        - 1e−13
      * - 径向通量
        - 7.25613288
        - 5w₁vᵣ,₁
        - 0
        - 1e−13
      * - 轴向通量
        - 3.807078956
        - (19/3)w₁v_z,₁
        - 0
        - 1e−13

   ``test_four_boundary_signs`` 再用四面开放单元、常数出射分布 2、
   规定入射分布 3，调用 ``sub_J02_reconstruct_open_boundary_fluxes``。
   低端面的入射为正、出射为负；高端面相反。
   这一子测试核对的是四面的符号。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 面
        - 实际入射 / 出射通量
        - 预期符号
      * - 径向低端 / 轴向低端
        - +12.314066 / −8.209377
        - + / −
      * - 径向高端 / 轴向高端
        - −12.314066 / +8.209377
        - − / +

   此项只断言符号，不将上述数值作为独立精度验证。

   .. rubric:: 7. 错误输入与定位

   .. list-table::
      :header-rows: 1

      * - 子测试和输入
        - 预期结果
      * - ``test_error_diagnostics``：温度为零
        - ``SN_ERR_SOURCE_TEMPERATURE``；消息含 temperature
      * - 同子测试：保留数组尺寸，将局部半宽设为零使矩阵奇异
        - ``SN_ERR_SWEEP_LOCAL_SOLVE``；失败位置为方向 1、单元 (1,1)
      * - ``test_frequency_conversion``：频率 −1
        - ``SN_ERR_SIGMA_NEGATIVE_FREQUENCY``
      * - ``test_negative_sigma_error``：扫描系数为负
        - ``SN_ERR_SWEEP_NEGATIVE_SIGMA``
      * - ``test_partial_inlet_geometry``：入口落在无效单元
        - ``SN_ERR_PARTIAL_INLET``

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 输入
        - 实际返回
        - 预期返回
      * - 零温度
        - 401
        - SN_ERR_SOURCE_TEMPERATURE = 401
      * - 奇异局部方程
        - 609；方向 1、单元 (1,1)
        - 609；方向 1、单元 (1,1)
      * - 负损失频率
        - 323
        - SN_ERR_SIGMA_NEGATIVE_FREQUENCY = 323
      * - 负扫描系数
        - 610
        - SN_ERR_SWEEP_NEGATIVE_SIGMA = 610

   .. rubric:: 运行与结果

   .. code-block:: bash

      bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run.sh

   各断言使用默认八字节实数构建。2026-10-06 上述检查通过。
   日志位于 ``build/*.log``；脚本运行全部程序并汇总非零退出状态。
   下一页把局部方程连接成全域扫描，再加入反射迭代和完整求解入口。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Order and files

   Tests follow geometry/quadrature → boundary data → local DG equations → field reconstruction.
   Sources are under ``J02_neutral_sn_transport_2Drz/source_f90``.
   The core and transport-units programs cover geometry, input and reconstruction;
   the reflection/partial-inlet program adds boundary integrals; DG-faces and positivity
   programs check local numerical operators.

   .. rubric:: Geometry and quadrature

   For r=[1,2], z=[0,2], sector angle :math:`2\pi`, exact volume is :math:`6\pi`,
   radial areas are :math:`4\pi,8\pi` and :math:`\bar\xi=1/9`.
   The axis-touching cell r=[0,1] gives volume :math:`2\pi` and :math:`\bar\xi=1/3`.
   Face-type tests check paired interior faces, outer open faces, inactive-neighbor
   walls and partial-inlet classification.

   Eight angles and two speed intervals up to 4 produce 16 discrete velocities,
   speeds 1 and 3, total weight :math:`16\pi` and zero first angular moments.
   Tolerances are 1e-12 for the weight sum and 1e-13 for angular symmetry.
   The two angular scheme names generate identical arrays.
   Loss frequency 6 converts to coefficients 6 and 2.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - Volume
        - 18.84955592
        - 6π
        - 0
        - 1e−12
      * - Quadrature weight sum
        - 50.26548246
        - 16π
        - 1.4211e−14
        - 1e−12
      * - Angular moments
        - −4.4409e−15 / −1.3323e−15
        - 0
        - as computed
        - 1e−13
      * - Loss coefficients
        - 6 / 2
        - 6 / 2
        - 0
        - 1e−13

   .. rubric:: Inlet and wall data

   Constant inlet shape normalized to flux 7 must integrate to 7 within 1e-12.
   At 300 K and mass 6.6335209e-26 kg, zero-drift Maxwell values are checked against
   :math:`(\alpha/\pi)e^{-\alpha v^2}`. A 300 m/s radial drift changes directional
   preference and normalizes to flux 12.
   Crossing probabilities [1,2,3,4] normalized to total flux 10 must preserve those
   individual contributions. PDF and weighted-probability representations agree within 1e-13.

   Inlet [1.5,2.5] intersecting edges [1,2,3] gives area fractions 7/12 and 0.45.
   For :math:`r_c=2,h_r=0.5,\xi\in[-0.5,0.5]`, interval moments are
   :math:`1,1/48,1/12`. Specular mapping reverses the normal and preserves speed/tangent.
   Diffuse normalization balances independently summed outgoing and returning flux
   within 2e-13.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - Unit-shape inlet
        - 7
        - 7
        - 8.8818e−16
        - 1e−12
      * - Drifted inlet
        - 12
        - 12
        - 1.7764e−15
        - 1e−12
      * - Partial fractions
        - 7/12, 0.45
        - 7/12, 0.45
        - 0
        - 1e−14
      * - Specular map max error
        - 7.2164e−16
        - 0
        - 7.2164e−16
        - 2e−15
      * - Returning wall flux
        - 86.28511539
        - 86.28511539
        - 1.4211e−14
        - 2e−13

   .. rubric:: Local DG operators

   The streaming-volume test uses :math:`(\mu,\eta)=(0.3,-0.4),r_c=2,h_r=0.5,h_z=0.25`.
   The absorption test uses :math:`\sigma=2,r_c=3` and the same half widths. Expected matrices are

   .. math::

      A^{\rm stream}=\begin{pmatrix}0&0&0\\-0.6&-0.05&0\\1.6&2/15&0\end{pmatrix},
      \qquad
      A^{\rm loss}=\begin{pmatrix}3&1/6&0\\1/6&1&0\\0&0&1\end{pmatrix}.

   Elementwise tolerance is 1e-14.
   All four self/neighbor/constant face contributions are independently integrated by
   three-point Gauss–Legendre quadrature, with nonzero initial arrays to verify addition.
   The maximum error must be below 2e-13.
   A pivoted 3×3 worked system checks the solution [1,-2,3], input preservation and
   singular-system rejection.
   Positivity recovery maps [1,2,0] to [1.5,0,0] for balance row (2,0.5,0.25) and RHS 3.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - Streaming matrix max error
        - 6.9389e−18
        - 0
        - 6.9389e−18
        - 1e−14
      * - Absorption matrix max error
        - 0
        - 0
        - 0
        - 1e−14
      * - All face operators max error
        - 2.2204e−16
        - 0
        - 2.2204e−16
        - 2e−13
      * - Local solve
        - [1,-2,3]
        - [1,-2,3]
        - 0
        - 2e−13
      * - Positivity coefficients
        - [1.5,0,0]
        - [1.5,0,0]
        - 0
        - 1e−13

   .. rubric:: Reconstruction and failures

   A single populated velocity with coefficients [2,3,4] in a cell with
   :math:`\bar\xi=1/9` gives mean distribution 7/3, radial face trace 5 and axial
   face mean 19/3. Density, velocity and flux are checked within 1e-13.
   Four open boundaries check coordinate-oriented inlet/outlet signs.

   Zero temperature, negative loss, invalid partial inlet and a singular local solve
   must return specific codes; the forced solve failure reports direction 1, cell (1,1).

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - Density
        - 3.665191429
        - 7w1/3
        - 0
        - 1e−13
      * - Radial velocity
        - 0.9238795325
        - 0.9238795325
        - 1.1102e−16
        - 1e−13
      * - Radial flux
        - 7.25613288
        - 5w1 vr1
        - 0
        - 1e−13
      * - Axial flux
        - 3.807078956
        - 19w1 vz1/3
        - 0
        - 1e−13

   Observed error codes: 401 (temperature), 609 (local solve, direction 1, cell 1,1),
   323 (negative frequency), and 610 (negative sigma), equal to their expected codes.

   .. code-block:: bash

      bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run.sh

   All checks passed on 2026-10-06 in the default real8 build. Logs are in ``build``.
   The runner executes every program and returns a failure status if any program fails.
