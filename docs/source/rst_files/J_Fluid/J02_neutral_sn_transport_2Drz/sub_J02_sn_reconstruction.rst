Field Reconstruction
==========================================================================================

``sub_J02_sn_reconstruction.f90`` 根据已求得的空间多项式系数计算物理量：
单元密度、平均速度、内部面通量和开放边界的入射/出射通量。
本文件不再求输运方程，不改变分布。
每个量都使用求解时的速度权重和柱坐标体积、面积元，保证求解与统计采用相同定义。

.. rubric:: 1. 单元平均分布与密度

已知每个单元、离散速度的多项式
:math:`\psi_{K,m}=c_0+c_1\xi+c_2\zeta`。
按物理体积平均后，

.. math::

   \overline{\psi}_{K,m}
      =\frac1{V_K}\int_K\psi_{K,m}\,\mathrm dV
      =c_0+\overline{\xi}c_1,\qquad
   \overline{\xi}=\frac{h_r}{3r_c}.

再作速度积分，得到单元平均密度与两个粒子流密度分量：

.. math::

   n_K=\sum_mw_m\overline{\psi}_{K,m},\qquad
   j_{r,K}=\sum_mw_mv_m\mu_m\overline{\psi}_{K,m},\qquad
   j_{z,K}=\sum_mw_mv_m\eta_m\overline{\psi}_{K,m}.

平均速度定义为

.. math::

   u_{r,K}=j_{r,K}/n_K,\qquad u_{z,K}=j_{z,K}/n_K.

程序只在密度大于 ``tiny(1.0)`` 时相除，其余位置速度保持零。
平均速度由粒子数加权的速度矩除以密度得到。

``sub_J02_reconstruct_cell_moments``：

- 输入 ``mesh``、``geometry``、``quadrature``、
  ``psi(3,nr,nz,n_dir)``。
- 输出并分配 ``density(nr,nz)``，单位 :math:`\mathrm{m^{-3}}`；
  ``velocity_r(nr,nz)``、``velocity_z(nr,nz)``，
  单位 :math:`\mathrm{m\,s^{-1}}`。
- 无效单元输出零；输入场尺寸不匹配时通过 ``ierr`` 报告。
  直接调用时应先保证几何与求积对象有效，本过程不重复做完整对象验证。

.. rubric:: 2. 内部面通量的迎风重构

内部面的通量不能简单地取相邻单元密度与平均速度的算术平均，
因为不同速度方向的上游单元不同。
对径向内部面，两侧分别记为左单元 :math:`L`、右单元 :math:`R`。
面平均迎风分布是

.. math::

   \overline{\psi}^{\mathrm{up}}_{r,m}=
   \begin{cases}
      c_{0,L,m}+c_{1,L,m},&\mu_m>0,\\
      c_{0,R,m}-c_{1,R,m},&\mu_m<0.
   \end{cases}

轴向内部面两侧记为下单元 :math:`B`、上单元 :math:`T`：

.. math::

   \overline{\psi}^{\mathrm{up}}_{z,m}=
   \begin{cases}
     c_{0,B,m}+\overline{\xi}c_{1,B,m}+c_{2,B,m},&\eta_m>0,\\
     c_{0,T,m}+\overline{\xi}c_{1,T,m}-c_{2,T,m},&\eta_m<0.
   \end{cases}

由法向速度矩得到沿坐标正向计正的通量：

.. math::

   \Gamma_r=\sum_mw_mv_m\mu_m\overline{\psi}^{\mathrm{up}}_{r,m},
   \qquad
   \Gamma_z=\sum_mw_mv_m\eta_m\overline{\psi}^{\mathrm{up}}_{z,m}.

它们是单位面积通量，单位 :math:`\mathrm{m^{-2}\,s^{-1}}`，
乘相应物理面面积后才是粒子率。
同一公共面只有一个通量值，相邻单元在收支中使用相反的外法向符号。

``sub_J02_reconstruct_internal_face_fluxes``：

- 输入与单元矩重构相同。
- 输出 ``flux_r(max(nr-1,0),nz)``，
  元素 ``(i,k)`` 位于单元 ``(i,k)`` 和 ``(i+1,k)`` 之间。
- 输出 ``flux_z(nr,max(nz-1,0))``，
  元素 ``(i,k)`` 位于单元 ``(i,k)`` 和 ``(i,k+1)`` 之间。
- 只有两侧均有效的内部面参与计算，其他位置保持零。
  不在这些数组中存储网格外边界通量。
- 输出 ``ierr``，输入场尺寸错误时失败。

.. rubric:: 3. 开放边界的入射与出射分开统计

开放面上，入射来自规定值 :math:`h_m`，出射来自单元内的分布。
令 :math:`e_{\alpha,m}` 为沿该面坐标轴的方向分量：
径向面取 :math:`\mu_m`，轴向面取 :math:`\eta_m`。
整面开放时，

.. math::

   \Gamma_f^{\mathrm{in}}
       =\sum_{\beta_{f,m}<0}w_mv_me_{\alpha,m}h_m,\qquad
   \Gamma_f^{\mathrm{out}}
       =\sum_{\beta_{f,m}>0}w_mv_me_{\alpha,m}\overline{\psi}_{f,m}.

分类使用外法向投影 :math:`\beta_{f,m}`，
存储符号却使用坐标分量 :math:`e_{\alpha,m}`。
因此这两个数组不是一律非负的入射量、出射量：
低端面的入射为正、出射为负，高端面正好相反。
总的坐标向通量等于两数组之和。

.. rubric:: 4. 部分开口按完整面积归一化

若下端只有 :math:`[\xi_L,\xi_H]` 开放，
入射的完整面平均值为 :math:`\chi_i h_m`。
出射则要对开口内的多项式精确积分：

.. math::

   \overline{\psi}_{f,m}^{\mathrm{open/full}}
       =\frac{(c_0-c_2)M_0[\xi_L,\xi_H]+c_1M_1[\xi_L,\xi_H]}
                    {M_0[-1,1]},
   \qquad M_0[-1,1]=2r_ch_r.

分母是完整面面积去掉公共张角后的值，不是开口面积。
于是通量数组乘完整物理面积就得到真实开口粒子率；
不再乘 :math:`\chi_i`，否则会重复缩小贡献。
对出射多项式也不能先取整面平均再乘比例，因为入口可能偏在径向一侧。

``sub_J02_reconstruct_open_boundary_fluxes``：

- 输入 ``mesh,geometry,boundary,quadrature``、
  ``psi(3,nr,nz,n_dir)``。
- 规定入流通过 ``prescribed_inflow(4,nr,nz,n_dir)``
  或 ``zlo_inflow(n_dir)`` 传入。正常流程沿用求解时选定的一种表示。
- 可选输入两个下端局部区间数组，必须与求解时一致且同时提供。
- 输出 ``inflow_flux(4,nr,nz)``、``outflow_flux(4,nr,nz)``，
  单位均为 :math:`\mathrm{m^{-2}\,s^{-1}}`；
  只统计 OPEN 面，壁面、内部面与 REMOTE 面位置保持零。
- 输出 ``ierr``，用于报告分布、规定入流、面类型数组的尺寸错误或区间数据错误。

内部函数 ``fun_prescribed_value`` 输入面、单元、方向索引，返回规定入射分布函数。
它优先读取完整边界数组；否则只在第一排下端读取 ``zlo_inflow``，
无对应输入则返回零。这个重构过程没有完整求解接口中的入流参数二选一检查，
直接调用者仍应遵守同一入口约定，避免重构所用边界与求解时不同。

.. rubric:: 5. 将输出用于粒子收支

令面位置符号 :math:`\varepsilon_f=-1` 表示低端，
:math:`\varepsilon_f=+1` 表示高端。用完整面积统计总入射率与逸出率：

.. math::

   Q_{\mathrm{in}}
       =-\sum_{\text{OPEN }f}\varepsilon_fA_f\Gamma_f^{\mathrm{in}},
   \qquad
   Q_{\mathrm{open,out}}
       =\sum_{\text{OPEN }f}\varepsilon_fA_f\Gamma_f^{\mathrm{out}}.

逸出统计包含入口开口上的反向逃逸，不仅是名为“出口”的上端。
对于当前不吸附壁面、无体产生的稳态模型，

.. math::

   Q_{\mathrm{in}}
       =Q_{\mathrm{open,out}}+\sum_K\nu_Kn_KV_K.

这是输出量之间应满足的物理收支。实际数值误差还受反射迭代容差与浮点计算影响。
内部通量和开放通量供后续守恒计算使用时，必须同时保留这里的面积与符号约定，
不能仅依据数组名把所有边界通量改为正值。

.. rubric:: 6. 空间分区下的输出范围

本文件的重构过程都是本地计算，不包含 MPI 调用。
分区时，它们计算本地单元的密度与速度，以及本地内部面、入口和开放出口上的通量，
不会把本地数组边缘自动当成外部开口。

完整求解接口另外调用 MPI 文件中的交界面重构，得到
``result%partition_flux``；其推导与输出约定在 14 页展开。
全域粒子收支只对真实 OPEN 面和体损失作全局求和，
不把进程之间的 REMOTE 通量作为外部逸出。
