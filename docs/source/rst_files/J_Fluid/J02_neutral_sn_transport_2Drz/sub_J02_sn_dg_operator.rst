DG Discretization
==========================================================================================

``sub_J02_sn_dg_operator.f90`` 把一个空间单元、一个离散速度的输运方程写成具有三个未知系数的线性方程组。
采用一阶 DG（P1-DG）：单元内使用一次空间多项式，单元之间使用迎风面值；
体积分、面积分均按多项式解析展开，不在本文件内另作空间数值求积。

前面各页已经给出几何、速度方向、入口值、反射规律及损失系数。
本页固定单元 :math:`K` 与离散速度 :math:`m`，省略这两个下标。
已知量为 :math:`r_c,h_r,h_z,\mu,\eta,\sigma`，
待求量只有三个空间系数 :math:`c_0,c_1,c_2`。本页按以下顺序推导：

1. 用三个系数近似单元内的分布；
2. 把微分方程变成三个积分方程；
3. 将未知的本单元出射项放在左端，已知入射项放在右端；
4. 分别计算体积分、完整面积分和部分面积分；
5. 将这些项相加，求解三个系数，并检查分布是否非负。

这里先假定各入射面上的分布已经给定。下一页的扫描过程负责按顺序取得这些入流数据。

.. rubric:: 1. 一次多项式与三个检验方程

在单元中心值附近，只保留常数项和两个方向的一次变化：

.. math::

   \psi_h(r,z)=c_0+c_1\xi+c_2\zeta,\qquad
   \xi=\frac{r-r_c}{h_r},\quad \zeta=\frac{z-z_c}{h_z}.

下标 :math:`h` 表示空间离散近似，后文为简洁仍写 :math:`\psi`。
:math:`c_0` 是中心值；:math:`c_1,c_2` 描述局部坐标变化一个单位时分布的变化量，
对应物理导数为 :math:`c_1/h_r,c_2/h_z`。
三者单位都与分布函数相同。

将这三个空间函数写成基函数向量

.. math::

   \boldsymbol\phi=(1,\xi,\zeta)^{\mathsf T},\qquad
   \psi=\boldsymbol\phi^{\mathsf T}\boldsymbol c,\qquad
   \boldsymbol c=(c_0,c_1,c_2)^{\mathsf T},
   \qquad
   \partial_r\boldsymbol\phi=(0,1/h_r,0)^{\mathsf T},\quad
   \partial_z\boldsymbol\phi=(0,0,1/h_z)^{\mathsf T}.

这是总次数不超过一的多项式，不含二次交叉项 :math:`\xi\zeta`。
每个单元独立保存三个系数，允许公共面两侧的分布不连续；
面上的输运值由迎风规则选取。为确定三个系数，
分别用 :math:`1,\xi,\zeta` 检验守恒方程，得到三个独立方程。
常数检验方程约束粒子收支，另外两条约束方程残差沿径向和轴向的加权平均。
这就是本页中“检验函数”的作用：要求近似解满足三个积分条件，
而不是要求一次多项式在单元内每一点都严格满足原微分方程。
采用与近似空间相同的三个函数 :math:`1,\xi,\zeta` 作检验，就是这里的 Galerkin 选择。

.. rubric:: 2. 守恒方程的积分形式与矩阵分组

从已除以速率的输运方程出发：

.. math::

   \frac1r\partial_r(r\mu\psi)+\partial_z(\eta\psi)+\sigma\psi=0.

乘以 :math:`r`，并把左端记为残差 :math:`\mathcal E`：

.. math::

   \mathcal E=\partial_r(r\mu\psi)+\partial_z(r\eta\psi)+r\sigma\psi.

对每个 :math:`a=1,2,3`，要求
:math:`\int_K\phi_a\mathcal E\,\mathrm dr\,\mathrm dz=0`。
分别对两个导数项分部积分：

.. math::

   \begin{aligned}
   \int_K\phi_a\partial_r(r\mu\psi)\,\mathrm dr\,\mathrm dz
      &=\int_{\partial K}\phi_a r\mu\psi\,n_r\,\mathrm ds
        -\int_Kr\mu\psi\,\partial_r\phi_a\,\mathrm dr\,\mathrm dz,\\
   \int_K\phi_a\partial_z(r\eta\psi)\,\mathrm dr\,\mathrm dz
      &=\int_{\partial K}\phi_a r\eta\psi\,n_z\,\mathrm ds
        -\int_Kr\eta\psi\,\partial_z\phi_a\,\mathrm dr\,\mathrm dz.
   \end{aligned}

这样把分布函数的导数转移到了已知检验函数上，同时产生了单元面的输运项。
相邻单元各有自己的多项式，公共面两侧的值可以不同，因此还需指定面上用哪一侧的值。
采用迎风选择：沿当前速度方向回看，使用粒子进入该面的那一侧分布，即
:math:`\psi_f^{\mathrm{up}}`。

合并两个方向的面积分，利用
:math:`\beta_f=\mu n_r+\eta n_z`，得到

.. math::

   -\int_K r(\boldsymbol\Omega\cdot\nabla\phi_a)\psi\,\mathrm dr\,\mathrm dz
   +\int_K r\sigma\phi_a\psi\,\mathrm dr\,\mathrm dz
   +\oint_{\partial K}r\beta_f\phi_a\psi_f^{\mathrm{up}}\,\mathrm ds=0.

其中 :math:`\mathrm ds` 是截面上的线元，物理面积元为
:math:`\Theta r\,\mathrm ds`。所有项共有的 :math:`\Theta` 已约去。
检验函数索引 :math:`a` 与系数列索引 :math:`b` 均取一至三；
第一列对应 :math:`c_0`。

出射面满足 :math:`\beta_f>0`，取本单元未知分布，放在左端；
入射面满足 :math:`\beta_f<0`，取已知上游或边界分布，移至右端。
对入射面，:math:`\beta_f=-|\beta_f|`，原来的面积分在左端为负；
移到右端后变成正的入射贡献。记 :math:`s_f=|\beta_f|`，
代入 :math:`\psi=\sum_{b=1}^3\phi_b c_{b-1}` 并按未知系数收集，得到

.. math::
   :label: sn-local-system

   \mathsf A\boldsymbol c=\boldsymbol b,\qquad
   \mathsf A=\mathsf T+\sigma\mathsf H+\sum_{\beta_f>0}\mathsf F_f,
   \qquad \boldsymbol b=\sum_{\beta_f<0}\boldsymbol b_f,

.. math::

   \begin{aligned}
   T_{ab}&=-\int_Kr(\boldsymbol\Omega\cdot\nabla\phi_a)\phi_b\,\mathrm dr\,\mathrm dz,\\
   H_{ab}&=\int_Kr\phi_a\phi_b\,\mathrm dr\,\mathrm dz,\\
   (F_f)_{ab}&=s_f\int_f r\phi_a\phi_b\,\mathrm ds.
   \end{aligned}

:math:`\mathsf T` 表示分部积分后的体输运项，:math:`\sigma\mathsf H` 表示损失，
:math:`\mathsf F_f` 表示出射面项。它们的元素单位均为 :math:`\mathrm{m^2}`。
这里称为“矩阵”的原因是：每一行对应一个检验函数，每一列对应一个未知系数。
例如，:math:`T_{21}` 是径向检验方程中乘在常数系数 :math:`c_0` 前的数。
右端的单位为分布函数乘面积，即 :math:`\mathrm{s^2\,m^{-3}}`。
程序的 ``add_*`` 过程执行累加，调用者必须先把矩阵和右端置零。
这些积分累加过程不返回错误码，要求传入有效面编号和已验证的局部几何；
错误诊断由外层扫描以及局部求解、保正过程负责。

.. rubric:: 3. 基本空间积分

使用 :math:`r=r_c+h_r\xi` 和
:math:`\mathrm dr\,\mathrm dz=h_rh_z\,\mathrm d\xi\,\mathrm d\zeta`。
所有体积分只需以下一维矩：

.. math::

   \int_{-1}^{1}1\,\mathrm d\xi=2,\quad
   \int_{-1}^{1}\xi\,\mathrm d\xi=0,\quad
   \int_{-1}^{1}\xi^2\,\mathrm d\xi=\frac23,\quad
   \int_{-1}^{1}\xi^3\,\mathrm d\xi=0.

:math:`\zeta` 的对应积分相同。带径向几何权重后，

.. math::

   \int_{-1}^{1}(r_c+h_r\xi)\,\mathrm d\xi=2r_c,\qquad
   \int_{-1}^{1}\xi(r_c+h_r\xi)\,\mathrm d\xi=\frac{2h_r}{3},\qquad
   \int_{-1}^{1}\xi^2(r_c+h_r\xi)\,\mathrm d\xi=\frac{2r_c}{3}.

计算矩阵时，先将两个基函数相乘，再乘 :math:`r_c+h_r\xi`。
奇次项在对称区间上积分为零，偶次项按上述结果计算。
例如 :math:`\xi` 本身平均为零，但 :math:`\xi(r_c+h_r\xi)`
包含偶次项 :math:`h_r\xi^2`，所以其积分不为零。径向的非对角元素正是由此产生。

.. rubric:: 4. 体输运矩阵的全部元素

第一行检验函数为常数，梯度为零，故该行全零。
第二行径向导数为 :math:`1/h_r`，第三行轴向导数为 :math:`1/h_z`：

.. math::

   \begin{aligned}
   T_{21}&=-\frac{\mu}{h_r}h_rh_z(2r_c)(2)=-4\mu r_ch_z,\\
   T_{22}&=-\frac{\mu}{h_r}h_rh_z(2h_r/3)(2)=-\frac43\mu h_rh_z,\\
   T_{31}&=-\frac{\eta}{h_z}h_rh_z(2r_c)(2)=-4\eta r_ch_r,\\
   T_{32}&=-\frac{\eta}{h_z}h_rh_z(2h_r/3)(2)=-\frac43\eta h_r^2.
   \end{aligned}

第三列含有 :math:`\zeta` 的奇次积分，全部为零。因此

.. math::

   \mathsf T=
   \begin{pmatrix}
   0&0&0\\
   -4\mu r_ch_z&-\frac43\mu h_rh_z&0\\
   -4\eta r_ch_r&-\frac43\eta h_r^2&0
   \end{pmatrix}.

``sub_J02_add_volume_matrix`` 输入 ``mu,eta,rc,hr,hz``，
将这四个非零元素累加到输入输出矩阵 ``a(3,3)``，不覆盖已有面项。
它不返回错误码，要求传入已验证的单元几何。

.. rubric:: 5. 损失矩阵的全部元素

单元内 :math:`\sigma` 为常数，提出积分。
把三个基函数两两相乘，先写出完整被积矩阵：

.. math::

   \mathsf H=h_rh_z\int_{-1}^{1}\int_{-1}^{1}
     (r_c+h_r\xi)
     \begin{pmatrix}
       1&\xi&\zeta\\
       \xi&\xi^2&\xi\zeta\\
       \zeta&\xi\zeta&\zeta^2
     \end{pmatrix}\,\mathrm d\xi\,\mathrm d\zeta.

第一、二行的交叉项不为零，而含一个 :math:`\zeta` 的元素为零。
逐项计算得到

.. math::

   \begin{aligned}
   H_{11}&=h_rh_z(2r_c)(2)=4r_ch_rh_z,\\
   H_{12}=H_{21}&=h_rh_z(2h_r/3)(2)=\frac43h_r^2h_z,\\
   H_{22}&=h_rh_z(2r_c/3)(2)=\frac43r_ch_rh_z,\\
   H_{33}&=h_rh_z(2r_c)(2/3)=\frac43r_ch_rh_z.
   \end{aligned}

余下元素为
:math:`H_{13}=H_{31}=H_{23}=H_{32}=0`，因为每项都含有
:math:`\int_{-1}^1\zeta\,\mathrm d\zeta=0`。完整损失矩阵是

.. math::

   \sigma\mathsf H=\sigma
   \begin{pmatrix}
   4r_ch_rh_z&\frac43h_r^2h_z&0\\
   \frac43h_r^2h_z&\frac43r_ch_rh_z&0\\
   0&0&\frac43r_ch_rh_z
   \end{pmatrix}.

常数项与径向一次项相互耦合，因此不能把它近似为对角矩阵。
``sub_J02_add_absorption_matrix`` 输入 ``sigma,rc,hr,hz``，
累加到 ``a(3,3)``；``sigma`` 非正时本过程不加任何项。
负损失系数应在扫描接口拒绝，不能利用这里的跳过分支掩盖错误输入。

.. rubric:: 6. 四个出射面的解析矩阵

用位置符号 :math:`\varepsilon=-1,+1` 分别表示低端、高端面。
它与 :math:`\beta_f` 的入射、出射符号不同。

径向面上 :math:`\xi=\varepsilon`，
:math:`\boldsymbol\phi=(1,\varepsilon,\zeta)^{\mathsf T}`，
所以

.. math::

   \mathsf F_{r\varepsilon}
    =s_fh_z(r_c+\varepsilon h_r)
       \int_{-1}^{1}
       \begin{pmatrix}
       1&\varepsilon&\zeta\\
       \varepsilon&1&\varepsilon\zeta\\
       \zeta&\varepsilon\zeta&\zeta^2
       \end{pmatrix}\mathrm d\zeta
    =s_fh_z(r_c+\varepsilon h_r)
       \begin{pmatrix}2&2\varepsilon&0\\2\varepsilon&2&0\\0&0&2/3\end{pmatrix}.

轴向面上 :math:`\zeta=\varepsilon`。定义该面上的三个径向矩：

.. math::

   M_j=h_r\int_{-1}^{1}(r_c+h_r\xi)\xi^j\,\mathrm d\xi,\qquad
   M_0=2r_ch_r,\quad M_1=\frac23h_r^2,\quad M_2=\frac23r_ch_r.

这里 :math:`M_0` 对应常数函数的面积积分，:math:`M_1` 对应
:math:`\xi` 的面积积分，:math:`M_2` 对应 :math:`\xi^2` 的面积积分，均未乘周向张角。
轴向面上的基函数向量是 :math:`(1,\xi,\varepsilon)^{\mathsf T}`，
所以矩阵中第 :math:`(1,3)` 个元素为 :math:`s_f\varepsilon M_0`，
第 :math:`(2,3)` 个元素为 :math:`s_f\varepsilon M_1`，
第 :math:`(3,3)` 个元素为 :math:`s_f\varepsilon^2M_0=s_fM_0`。
将所有元素放在一起：

.. math::

   \mathsf F_{z\varepsilon}
     =s_fh_r\int_{-1}^{1}(r_c+h_r\xi)
       \begin{pmatrix}
       1&\xi&\varepsilon\\
       \xi&\xi^2&\varepsilon\xi\\
       \varepsilon&\varepsilon\xi&1
       \end{pmatrix}\mathrm d\xi
     =s_f\begin{pmatrix}
       M_0&M_1&\varepsilon M_0\\
       M_1&M_2&\varepsilon M_1\\
       \varepsilon M_0&\varepsilon M_1&M_0
       \end{pmatrix}.

``sub_J02_add_self_face_matrix`` 输入 ``face_id,s,rc,hr,hz``，
按上述四面公式累加 ``a(3,3)``。
``s`` 对应无量纲的 :math:`s_f`，不是速率。
局部变量 ``c0,c1,c11`` 是 :math:`s_fM_0,s_fM_1,s_fM_2`，
并非待求空间系数。面编号与非负方向余弦由调用者保证。

.. rubric:: 7. 内部面上游分布对右端的贡献

上游单元系数记为 :math:`\boldsymbol c^{\mathrm{up}}`。
本单元径向面 :math:`\xi=\varepsilon` 对应上游单元的
:math:`\xi_{\mathrm{up}}=-\varepsilon`，所以迎风面值为

.. math::

   \psi^{\mathrm{up}}_f
       =c^{\mathrm{up}}_0-\varepsilon c^{\mathrm{up}}_1
          +c^{\mathrm{up}}_2\zeta.

检验函数仍取本单元面上的 :math:`(1,\varepsilon,\zeta)^{\mathsf T}`。
令 :math:`t=c^{\mathrm{up}}_0-\varepsilon c^{\mathrm{up}}_1`，
三个分量需要的积分依次为

.. math::

   \int_{-1}^1(t+c^{\mathrm{up}}_2\zeta)\,\mathrm d\zeta=2t,\qquad
   \int_{-1}^1\varepsilon(t+c^{\mathrm{up}}_2\zeta)\,\mathrm d\zeta=2\varepsilon t,\qquad
   \int_{-1}^1\zeta(t+c^{\mathrm{up}}_2\zeta)\,\mathrm d\zeta=\frac23c^{\mathrm{up}}_2.

乘上共同因子 :math:`s_fh_z(r_c+\varepsilon h_r)`，并还原 :math:`t`，得到

.. math::

   \boldsymbol b_{r\varepsilon}^{\mathrm{up}}
      =s_fh_z(r_c+\varepsilon h_r)
        \begin{pmatrix}
        2&-2\varepsilon&0\\
        2\varepsilon&-2&0\\
        0&0&2/3
        \end{pmatrix}\boldsymbol c^{\mathrm{up}}.

轴向面上游单元的面值为
:math:`c^{\mathrm{up}}_0+c^{\mathrm{up}}_1\xi-\varepsilon c^{\mathrm{up}}_2`，
三个检验方程分别将它乘以 :math:`1,\xi,\varepsilon` 后积分，
即用 :math:`M_0,M_1,M_2` 收集常数项与径向一次项。由此得到

.. math::

   \boldsymbol b_{z\varepsilon}^{\mathrm{up}}
      =s_f\begin{pmatrix}
        M_0&M_1&-\varepsilon M_0\\
        M_1&M_2&-\varepsilon M_1\\
        \varepsilon M_0&\varepsilon M_1&-M_0
        \end{pmatrix}\boldsymbol c^{\mathrm{up}}.

``sub_J02_add_neighbor_rhs`` 输入 ``face_id,s,coeff_up(3),rc,hr,hz``，
累加输入输出向量 ``rhs(3)``。它读取上游单元与当前面相接的那一面，因此局部坐标符号与本单元不同，不能直接使用本单元的面矩阵。
上游系数的顺序和单位与本单元系数相同。

.. rubric:: 8. 规定入流与整面镜面反射

入口分布 :math:`h_m` 在当前面内为常数时，可以提出面积分；
“常数”仅指空间位置，并不表示所有离散速度具有同一个值。
径向面需要积分 :math:`(1,\varepsilon,\zeta)`，
轴向面需要积分 :math:`(1,\xi,\varepsilon)`，因此

.. math::

   \boldsymbol b_{r\varepsilon}^{\mathrm{const}}
       =s_fh_mh_z(r_c+\varepsilon h_r)(2,2\varepsilon,0)^{\mathsf T},
   \qquad
   \boldsymbol b_{z\varepsilon}^{\mathrm{const}}
       =s_fh_m(M_0,M_1,\varepsilon M_0)^{\mathsf T}.

``sub_J02_add_constant_rhs`` 输入 ``face_id,s,g,rc,hr,hz``，
将以上结果累加到 ``rhs(3)``。参数 ``g`` 在这里是已归一化的分布函数，
可传入口 :math:`h_m` 或漫反射 :math:`C_Wg_{\mathrm w,m}`，
不是尚待归一化的入口分布。

镜面反射取同一单元、同一个物理面上的反射方向旧系数，因此

.. math::

   \boldsymbol b_f^{\mathrm{spec}}
       =\mathsf F_f\boldsymbol c^{\mathrm{old}}_{R_f(m)}.

``sub_J02_add_specular_rhs`` 输入 ``face_id,s,coeff_reflected(3),rc,hr,hz``，
累加 ``rhs(3)``。它内部复用本单元的面矩阵，因为这里没有邻居坐标的反号。
混合壁面右端由扫描过程按
:math:`(1-d)\boldsymbol b^{\mathrm{spec}}+d\boldsymbol b^{\mathrm{const}}` 组合。

.. rubric:: 9. 轴向部分面区间的全部积分

部分入口在 :math:`\zeta=\varepsilon` 的面上划分径向区间。
对任意 :math:`[\xi_L,\xi_H]`，定义

.. math::

   M_j[\xi_L,\xi_H]
       =h_r\int_{\xi_L}^{\xi_H}\xi^j(r_c+h_r\xi)\,\mathrm d\xi.

先写出任意 :math:`j=0,1,2` 的原函数：

.. math::

   M_j[\xi_L,\xi_H]
    =h_r\left[
       \frac{r_c}{j+1}\xi^{j+1}+
       \frac{h_r}{j+2}\xi^{j+2}
      \right]_{\xi_L}^{\xi_H}.

分别代入 :math:`j=0,1,2`，得到三个所需矩

.. math::

   \begin{aligned}
   M_0&=h_r\left[r_c(\xi_H-\xi_L)+\frac{h_r}{2}(\xi_H^2-\xi_L^2)\right],\\
   M_1&=h_r\left[\frac{r_c}{2}(\xi_H^2-\xi_L^2)+\frac{h_r}{3}(\xi_H^3-\xi_L^3)\right],\\
   M_2&=h_r\left[\frac{r_c}{3}(\xi_H^3-\xi_L^3)+\frac{h_r}{4}(\xi_H^4-\xi_L^4)\right].
   \end{aligned}

``sub_J02_zface_interval_moments`` 输入 ``rc,hr,xi_lo,xi_hi``，
输出实数 ``m0,m1,m2``，单位均为 :math:`\mathrm{m^2}`，不含 :math:`\Theta`。
若上限不大于下限，三个输出为零；其余合法范围由调用者保证。

设分布函数在该面区间上的值为 :math:`t_0+t_1\xi`。
乘检验函数 :math:`1`，被积式为 :math:`t_0+t_1\xi`，
积分是 :math:`t_0M_0+t_1M_1`；
乘 :math:`\xi`，积分为 :math:`t_0M_1+t_1M_2`；
乘 :math:`\varepsilon`，则是第一个积分的 :math:`\varepsilon` 倍。
因此右端为

.. math::

   \boldsymbol b_{z\varepsilon}[\xi_L,\xi_H]
       =s_f\begin{pmatrix}
         t_0M_0+t_1M_1\\
         t_0M_1+t_1M_2\\
         \varepsilon(t_0M_0+t_1M_1)
       \end{pmatrix}.

对应的两个累加过程分别为：

- ``sub_J02_add_zface_constant_interval_rhs``：
  输入 ``s,g,zeta,xi_lo,xi_hi,rc,hr``；
  取 :math:`t_0=g,t_1=0`，累加 ``rhs(3)``。
- ``sub_J02_add_zface_coeff_interval_rhs``：
  输入 ``s,coeff(3),zeta,xi_lo,xi_hi,rc,hr``；
  取 :math:`t_0=c_0+\varepsilon c_2,t_1=c_1`，累加 ``rhs(3)``。

两者的 ``zeta`` 都是面位置 :math:`\varepsilon=\pm1`；
系数版本取同一面上的多项式，不自动改成相邻单元的坐标。
部分入口的规定入流在开放区间积分，
镜面和漫反射在两段壁面补集积分，然后相加。
出射粒子仍穿过完整单元面，左端出射矩阵不按入口比例缩小。

``fun_J02_zface_coeff_interval_integral`` 不形成三分量右端，
只返回分布本身的面区间积分：

.. math::

   I_\psi=h_r\int_{\xi_L}^{\xi_H}
       (c_0+c_1\xi+\varepsilon c_2)(r_c+h_r\xi)\,\mathrm d\xi
       =(c_0+\varepsilon c_2)M_0+c_1M_1.

其输入为 ``coeff(3),zeta,xi_lo,xi_hi,rc,hr``，
输出单位为分布函数乘 :math:`\mathrm{m^2}`，不含周向张角。
壁面归一化与开放通量重构使用这个积分。

.. rubric:: 10. 把各项组成一个实际单元方程

以 :math:`\mu>0,\eta>0` 为例：粒子从左面和下面进入，从右面和上面离开。
设当前单元左右上下的邻居都有效，左、下上游单元的系数已知，则

.. math::

   \underbrace{(\mathsf T+\sigma\mathsf H
                  +\mathsf F_{r+}+\mathsf F_{z+})}_{\mathsf A}
       \begin{pmatrix}c_0\\c_1\\c_2\end{pmatrix}
     =\underbrace{\boldsymbol b_{r-}^{\mathrm{up}}
                    +\boldsymbol b_{z-}^{\mathrm{up}}}_{\boldsymbol b}.

左端所有矩阵由本单元几何、当前速度方向和损失系数确定。
右端由已知的左、下邻居分布确定。
若下面是入口，则将 :math:`\boldsymbol b_{z-}^{\mathrm{up}}`
换为使用 :math:`h_m` 的规定入流积分；
若是壁面，换为镜面、漫反射的混合积分；
若一部分是入口、一部分是壁面，则按上一节对各区间分别积分再相加。

可以用第一行检验这些项的物理含义。由于 :math:`\phi_1=1`，
体输运矩阵第一行为零，第一条方程变为

.. math::

   \underbrace{\sum_{\beta_f>0}\beta_f
          \int_f r\psi\,\mathrm ds}_{\text{流出}}
   +\underbrace{\sigma\int_Kr\psi\,\mathrm dr\,\mathrm dz}_{\text{损失}}
   =\underbrace{\sum_{\beta_f<0}|\beta_f|
          \int_f r\psi_f^{\mathrm{up}}\,\mathrm ds}_{\text{流入}}.

再乘 :math:`\Theta v_m w_m`，就得到该离散速度对物理粒子率的收支贡献；
对全部速度求和，得到总的单元粒子收支。其余两行则决定单元内的空间变化。
这一关系也解释了为什么矩阵不能缺少面项、为什么入流在右端、为什么保正时要保留第一条方程。

在代码中，扫描先将 ``a`` 和 ``rhs`` 置零，按四个面依次调用对应的面过程，
再调用 ``sub_J02_add_volume_matrix`` 与 ``sub_J02_add_absorption_matrix``。
这些项相加以后，才进入下面的局部求解步骤。

.. rubric:: 11. 局部系统的求解

``sub_J02_solve_local_3x3`` 使用带部分主元选择的高斯消元。
每列在当前行及其下方寻找绝对值最大的主元，通过交换行完成选主元。
在第 :math:`j` 列消去第 :math:`i>j` 行时，

.. math::

   \lambda_i=A_{ij}/A_{jj},\qquad
   A_{i,j:3}\leftarrow A_{i,j:3}-\lambda_iA_{j,j:3},\qquad
   b_i\leftarrow b_i-\lambda_ib_j.

得到上三角系统后，从第三行向第一行回代：

.. math::

   c_{i-1}=\frac{b_i-\sum_{j=i+1}^{3}A_{ij}c_{j-1}}{A_{ii}}.

- 输入 ``a(3,3)``、``b(3)``，过程使用副本消元，不修改输入。
- 输出 ``x(3)``，依次对应 :math:`c_0,c_1,c_2`；输出 ``ierr``。
- 若所选主元不大于 ``100*tiny(1.0)``，返回局部奇异错误，并把输出置零。
  该检查只识别过小的主元，并不估计矩阵条件数；未触发错误仍可能存在病态矩阵引起的精度问题。

.. rubric:: 12. 一次多项式的保正处理

求得一次多项式后，其在参考矩形上的最小值位于角点，等于

.. math::

   \psi_{\min}=c_0-|c_1|-|c_2|.

若该值非负，保留三个系数；否则退回单元常数表示，
只重新满足常数检验方程：

.. math::

   c_1=c_2=0,\qquad c_0=b_1/A_{11}.

``sub_J02_enforce_local_positivity``：

- 输入 ``a(3,3)``、``rhs(3)``，输入输出 ``coeff(3)``。
- 输出 ``ierr``；可选输出 ``corrected`` 表示是否发生常数回退。
- 要求输入有限、:math:`A_{11}>0`、:math:`b_1\geq0`。
  非有限数据或负入射粒子率无法在这里修复，返回保正错误。
- 回退保留常数检验的粒子收支，不保留原一次多项式的平均值，
  也不再满足原系统的另两条检验方程。

本文件提供单元矩阵、右端的计算过程以及局部求解和保正过程。
扫描过程按面类型准备上游分布或边界值，调用这些过程组装并求解每个单元。
因此，更换入口或壁面模型时，只需提供相应的入射分布，仍可使用这里的矩阵积分。
