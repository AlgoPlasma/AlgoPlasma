Mesh and Geometry
==========================================================================================

``sub_J02_sn_geometry.f90`` 根据径向、轴向边界坐标和有效单元标记，
计算单元中心、半宽、体积、面面积及径向平均系数。
这些量分别用于 DG 矩阵积分、入口区间计算和密度、通量重构。

.. rubric:: 1. 张量积网格与有效单元

当前方法使用径向、轴向分别划分的矩形截面网格，允许非均匀间距。
令径向边界为 :math:`r_{i-1/2},r_{i+1/2}`，
轴向边界为 :math:`z_{k-1/2},z_{k+1/2}`。单元 :math:`K=(i,k)` 的中心和半宽为

.. math::

   r_c=\frac{r_{i-1/2}+r_{i+1/2}}2,\quad
   h_r=\frac{r_{i+1/2}-r_{i-1/2}}2,\qquad
   z_c=\frac{z_{k-1/2}+z_{k+1/2}}2,\quad
   h_z=\frac{z_{k+1/2}-z_{k-1/2}}2.

有效标记 ``active(i,k)`` 决定这个单元是否参加输运。
无效单元位于计算域之外；与它相邻的有效单元面默认标为壁面。

为在不同大小的单元上使用同一组基函数，引入无量纲局部坐标：

.. math::

   \xi=\frac{r-r_c}{h_r},\qquad
   \zeta=\frac{z-z_c}{h_z},\qquad
   -1\leq\xi,\zeta\leq1.

这里的 :math:`\xi,\zeta` 在后面的空间多项式、面区间和矩阵积分中含义不变。
``geometry`` 存储径向中心和两方向半宽；不存储轴向中心，
因为当前局部算子的积分只需要半宽。

.. rubric:: 2. 单元体积与面面积

矩形是 :math:`r`–:math:`z` 截面；绕轴展开周向张角 :math:`\Theta` 后，
它对应一个环形体积。柱坐标微元为
:math:`\mathrm dV=r\,\mathrm dr\,\mathrm d\varphi\,\mathrm dz`。
对物理周向角 :math:`\varphi` 积分后，

.. math::

   V_K=\Theta\int_{z_{k-1/2}}^{z_{k+1/2}}
                   \int_{r_{i-1/2}}^{r_{i+1/2}}r\,\mathrm dr\,\mathrm dz
       =4\Theta r_ch_rh_z.

积分中的 :math:`r` 来自柱坐标体积元。
完整一圈取 :math:`\Theta=2\pi`；扇区模型使用实际张角。
体积单位为 :math:`\mathrm{m^3}`。

径向面上半径固定，轴向面上轴向坐标固定，故四个物理面积分别为

.. math::

   \begin{aligned}
   A_{r-}&=\Theta(r_c-h_r)\int_{z_{k-1/2}}^{z_{k+1/2}}\mathrm dz
          =2\Theta(r_c-h_r)h_z,\\
   A_{r+}&=2\Theta(r_c+h_r)h_z,\\
   A_{z-}=A_{z+}&=\Theta\int_{r_{i-1/2}}^{r_{i+1/2}}r\,\mathrm dr
          =2\Theta r_ch_r.
   \end{aligned}

面通量乘相应物理面积得到粒子率，单位为 :math:`\mathrm{s^{-1}}`。

.. rubric:: 3. 一次多项式的体积平均

后续求解的单元内分布写成
:math:`\psi_m=c_0+c_1\xi+c_2\zeta`。
重构密度需要计算它的物理体积平均。
将坐标变换代入体积分，有

.. math::

   \overline{\xi}
     =\frac{\int_{-1}^{1}\int_{-1}^{1}
                  \xi(r_c+h_r\xi)\,\mathrm d\xi\,\mathrm d\zeta}
            {\int_{-1}^{1}\int_{-1}^{1}
                  (r_c+h_r\xi)\,\mathrm d\xi\,\mathrm d\zeta}
     =\frac{(2h_r/3)\,2}{(2r_c)\,2}
     =\frac{h_r}{3r_c},\qquad
   \overline{\zeta}=0.

于是

.. math::

   \overline{\psi}_{K,m}=c_0+\frac{h_r}{3r_c}c_1.

``xi_bar(i)`` 保存 :math:`h_r/(3r_c)`。即使局部坐标区间对称，
柱坐标体积平均也一般不等于 :math:`c_0`；径向外侧的物理体积更大。

.. rubric:: 4. 各过程的输入、输出与职责

``sub_J02_initialize_mesh`` —— 检查并保存网格。

- 输入 ``r_edge(nr+1)``、``z_edge(nz+1)``：实数边界坐标，单位 :math:`\mathrm m`。
  两者至少各有两个元素，严格递增，首个径向边界非负。
- 输入 ``active(nr,nz)``：逻辑数组，表示参加计算的单元。
- 输出 ``mesh``：保存维数、坐标的副本和有效标记。
- 输出 ``ierr``：成功为零；坐标数量、标记尺寸、负半径或坐标顺序错误分别报告。
  调用者必须检查成功后再使用 ``mesh``。

``sub_J02_build_geometry`` —— 由网格计算上述几何量。

- 输入 ``mesh``、``theta_span``：已初始化网格与正的周向张角。
  当前代码只检查张角大于零，没有实施不大于 :math:`2\pi` 的限制。
- 输出 ``geometry%rc/hr/xi_bar(nr)``、``hz(nz)``：
  径向中心、半宽、径向平均系数与轴向半宽。
- 输出 ``volume(nr,nz)`` 和四个 ``area_*(nr,nz)``：
  单位分别为 :math:`\mathrm{m^3}`、:math:`\mathrm{m^2}`。
  无效单元的体积设为零；其面面积仍按坐标计算，因此使用时仍须检查 ``active``。
- 输出 ``ierr``：网格不完整或张角非正时返回错误。

``sub_J02_initialize_boundary_types`` —— 建立初始面类型。

- 输入 ``mesh``；输出 ``boundary`` 中四个整数数组，尺寸均为 ``(nr,nz)``。
- 可选输入 ``partition``：MPI 空间分区信息。提供时本过程为集体调用；
  相邻进程的有效单元之间设为 ``SN_FACE_REMOTE``，邻接无效区域仍设为 WALL。
  不提供时使用下述单域分类。分区初始化与数据约定在 13 页说明。
- 有效单元之间的相邻面设为 ``SN_FACE_INTERIOR``；
  计算网格外边界设为 ``SN_FACE_OPEN``；
  有效单元旁的无效区域设为 ``SN_FACE_WALL``。
- 所有数组先初始化为壁面，无效单元不继续分类。
  这只是初始面类型，应用仍需把实际反射壁显式设置为壁面。
- 输出 ``ierr``：报告面类型初始化是否成功。

``sub_J02_configure_zlo_partial_inlet_boundary`` —— 根据开口比例更新下端面类型。

- 输入 ``mesh``、``face_fraction(nr)``，后者为 :math:`[0,1]` 内的面积比例。
- 输入并修改 ``boundary``：对有效的第一排单元，正比例设为 OPEN，
  零比例设为 WALL；其他面保持原值。
- 输出 ``ierr``。它只修改整面标记，不保存面内分界；
  部分开口的精确区间必须另外传入求解器，不能只传面积比例。

``fun_J02_geometry_is_valid`` —— 检查局部算子所需数组是否存在且尺寸匹配。

- 输入 ``mesh`` 和 ``geometry``；返回逻辑值，无 ``ierr``。
- 检查有效标记及 ``rc/hr/hz/xi_bar`` 的分配状态和维数。
  此函数不检查坐标的单调性或体积、面积数组。
  使用时应先调用上述初始化与几何构建过程，确保对象中的数据完整。

.. rubric:: 5. 本文件在计算流程中的位置

输入边界坐标之后，先初始化网格，再构建几何，随后建立初始面类型。
下一步的速度求积与空间网格独立；边界几何则使用这里的坐标求入口区间。
DG 积分使用 :math:`r_c,h_r,h_z`，重构使用 :math:`\overline{\xi}`，
粒子率统计使用 :math:`V_K,A_f`，三者不能各自采用不同的几何约定。
