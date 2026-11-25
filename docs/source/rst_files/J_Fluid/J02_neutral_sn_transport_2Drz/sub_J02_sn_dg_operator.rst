.. J_Fluid contribution history (Git author dates; edit times include timezone).
   2026-09-18 12:00 +08:00 | Yingjie Chen | git 69bdc8603906
   2026-10-06 23:50 +08:00 | Yingjie Chen | git fa8cb9f5be05
   2026-11-25 15:14 +08:00 | Yingjie Chen | git 8652258184b5
   2026-11-25 15:59 +08:00 | Yingjie Chen | edit (Codex-assisted)

DG Discretization
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J02_sn_dg_operator.f90`` 把一个空间单元、一个离散速度的输运方程写成具有三个未知系数的线性方程组。
   采用一阶 DG（P1-DG）：单元内使用一次空间多项式，单元之间使用迎风面值；
   体积分、面积分均按多项式解析展开，不在本文件内另作空间数值求积。
   在平面三角网格上用不连续单元近似输运方程、用迎风值连接相邻单元的推导，见 :ref:`Reed 与 Hill（1973） <j02-dg-ref-rh73>`。
   下文给出 J02 在矩形单元上按柱坐标体积元积分得到的矩阵。

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

   .. rubric:: 参考文献

   .. _j02-dg-ref-rh73:

   W. H. Reed and T. R. Hill (1973).
   *Triangular Mesh Methods for the Neutron Transport Equation*.
   Los Alamos Scientific Laboratory, LA-UR-73-479.
   `报告全文 <https://www.osti.gov/servlets/purl/4491151>`__

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``sub_J02_sn_dg_operator.f90`` expresses the transport equation for one cell and one discrete velocity as a linear system with
   three unknown coefficients. The P1 discontinuous Galerkin (DG) approximation uses linear spatial
   polynomials in each cell and upwind traces on their interfaces. The code evaluates the volume and
   face integrals analytically. :ref:`Reed and Hill (1973) <j02-dg-ref-rh73-en>` derive an upwind discontinuous finite element method on planar
   triangles. Here the matrices are derived for J02's rectangular cells with cylindrical volume
   weighting.

   The preceding pages define the geometry, velocity directions, inlet data, reflection law, and loss
   coefficients. Fix cell :math:`K` and velocity :math:`m` and suppress these two indices. The known quantities are
   :math:`r_c,h_r,h_z,\mu,\eta,\sigma`. Only the three spatial coefficients :math:`c_0,c_1,c_2` remain to be determined.

   1. Approximate the distribution within the cell using three coefficients.
   2. Convert the differential equation to three integral equations.
   3. Put the unknown outgoing contributions on the left and known incoming data on the right.
   4. Evaluate volume, whole-face, and partial-face integrals separately.
   5. Sum the contributions, solve for the three coefficients, and check the distribution for
      nonnegativity.

   For this derivation assume the distribution is given on every incoming face. The sweep on the next
   page obtains the data in the required order.

   .. rubric:: 1. Linear polynomial and three test equations

   Retain the central value and the linear variation in each direction:

   .. math::

      \psi_h(r,z)=c_0+c_1\xi+c_2\zeta,\qquad
      \xi=\frac{r-r_c}{h_r},\quad \zeta=\frac{z-z_c}{h_z}.

   The subscript :math:`h` denotes a spatial approximation. Below we write :math:`\psi` for brevity. :math:`c_0` is the value at
   the center. :math:`c_1,c_2` measure the changes per unit local coordinate, corresponding to physical derivatives
   :math:`c_1/h_r,c_2/h_z`. All three coefficients have the units of the distribution function.

   Collect the three spatial basis functions into a vector:

   .. math::

      \boldsymbol\phi=(1,\xi,\zeta)^{\mathsf T},\qquad
      \psi=\boldsymbol\phi^{\mathsf T}\boldsymbol c,\qquad
      \boldsymbol c=(c_0,c_1,c_2)^{\mathsf T},
      \qquad
      \partial_r\boldsymbol\phi=(0,1/h_r,0)^{\mathsf T},\quad
      \partial_z\boldsymbol\phi=(0,0,1/h_z)^{\mathsf T}.

   This polynomial has total degree at most one and contains no quadratic cross term :math:`\xi\zeta`. Each cell
   stores its coefficients independently, so the two traces on an interface may differ. The upwind rule
   chooses the transported trace. Testing the conservation equation against :math:`1,\xi,\zeta` gives three equations:
   the constant test enforces particle balance, and the two others constrain the radially and axially
   weighted residual. The polynomial must satisfy these three integral conditions. The Galerkin choice
   uses the same functions :math:`1,\xi,\zeta` to test the residual and represent the solution.

   .. rubric:: 2. Integral conservation equation and matrix contributions

   Start with the transport equation divided by speed:

   .. math::

      \frac1r\partial_r(r\mu\psi)+\partial_z(\eta\psi)+\sigma\psi=0.

   Multiply by :math:`r` and denote the residual on the left by :math:`\mathcal E`:

   .. math::

      \mathcal E=\partial_r(r\mu\psi)+\partial_z(r\eta\psi)+r\sigma\psi.

   For each :math:`a=1,2,3` impose :math:`\int_K\phi_a\mathcal E\,\mathrm dr\,\mathrm dz=0`. Integrating the two derivative terms by parts gives

   .. math::

      \begin{aligned}
      \int_K\phi_a\partial_r(r\mu\psi)\,\mathrm dr\,\mathrm dz
         &=\int_{\partial K}\phi_a r\mu\psi\,n_r\,\mathrm ds
           -\int_Kr\mu\psi\,\partial_r\phi_a\,\mathrm dr\,\mathrm dz,\\
      \int_K\phi_a\partial_z(r\eta\psi)\,\mathrm dr\,\mathrm dz
         &=\int_{\partial K}\phi_a r\eta\psi\,n_z\,\mathrm ds
           -\int_Kr\eta\psi\,\partial_z\phi_a\,\mathrm dr\,\mathrm dz.
      \end{aligned}

   The derivatives now act on the known test functions and the boundary terms represent transport
   through the faces. Adjacent cells have independent polynomials. Select the trace from the side from
   which particles arrive for this velocity, denoted by :math:`\psi_f^{\mathrm{up}}`.

   Combine the face integrals in the two directions and use :math:`\beta_f=\mu n_r+\eta n_z` to obtain

   .. math::

      -\int_K r(\boldsymbol\Omega\cdot\nabla\phi_a)\psi\,\mathrm dr\,\mathrm dz
      +\int_K r\sigma\phi_a\psi\,\mathrm dr\,\mathrm dz
      +\oint_{\partial K}r\beta_f\phi_a\psi_f^{\mathrm{up}}\,\mathrm ds=0.

   Here :math:`\mathrm ds` is the line element in the meridional plane and :math:`\Theta r\,\mathrm ds` the physical area element. The common
   factor :math:`\Theta` cancels. The test-function index :math:`a` and coefficient column :math:`b` both run from one to three.
   The first column corresponds to :math:`c_0`.

   At an outgoing face, :math:`\beta_f>0`, the unknown trace belongs to the current cell and stays on the left. At an
   incoming face, :math:`\beta_f<0`, use the known upstream or boundary value on the right. Since :math:`\beta_f=-|\beta_f|` there, moving the
   negative face term across the equality gives a positive incoming contribution. Set :math:`s_f=|\beta_f|`, substitute
   :math:`\psi=\sum_{b=1}^3\phi_b c_{b-1}`, and collect terms multiplying each coefficient:

   .. math::
      :label: sn-local-system-en

      \mathsf A\boldsymbol c=\boldsymbol b,\qquad
      \mathsf A=\mathsf T+\sigma\mathsf H+\sum_{\beta_f>0}\mathsf F_f,
      \qquad \boldsymbol b=\sum_{\beta_f<0}\boldsymbol b_f,

   .. math::

      \begin{aligned}
      T_{ab}&=-\int_Kr(\boldsymbol\Omega\cdot\nabla\phi_a)\phi_b\,\mathrm dr\,\mathrm dz,\\
      H_{ab}&=\int_Kr\phi_a\phi_b\,\mathrm dr\,\mathrm dz,\\
      (F_f)_{ab}&=s_f\int_f r\phi_a\phi_b\,\mathrm ds.
      \end{aligned}

   :math:`\mathsf T` is the volume transport term after integration by parts, :math:`\sigma\mathsf H` the loss term, and :math:`\mathsf F_f` the outgoing
   face term. All entries have units of :math:`\mathrm{m^2}`. Each row corresponds to a test function and each column to
   an unknown coefficient. For example, :math:`T_{21}` multiplies the constant coefficient :math:`c_0` in the radial test
   equation. The right-hand side has units of distribution times area, :math:`\mathrm{s^2\,m^{-3}}`. The ``add_*`` routines add to the
   existing entries, so the caller initializes the matrix and right-hand side to zero. These
   integration routines require valid face indices and validated local geometry and return no status.
   The enclosing sweep, local solve, and positivity procedure report errors.

   .. rubric:: 3. Basic spatial integrals

   Use :math:`r=r_c+h_r\xi` and :math:`\mathrm dr\,\mathrm dz=h_rh_z\,\mathrm d\xi\,\mathrm d\zeta`. The volume integrals require only the following one-dimensional moments:

   .. math::

      \int_{-1}^{1}1\,\mathrm d\xi=2,\quad
      \int_{-1}^{1}\xi\,\mathrm d\xi=0,\quad
      \int_{-1}^{1}\xi^2\,\mathrm d\xi=\frac23,\quad
      \int_{-1}^{1}\xi^3\,\mathrm d\xi=0.

   The corresponding integrals in :math:`\zeta` have the same values. Including the radial geometric weight gives

   .. math::

      \int_{-1}^{1}(r_c+h_r\xi)\,\mathrm d\xi=2r_c,\qquad
      \int_{-1}^{1}\xi(r_c+h_r\xi)\,\mathrm d\xi=\frac{2h_r}{3},\qquad
      \int_{-1}^{1}\xi^2(r_c+h_r\xi)\,\mathrm d\xi=\frac{2r_c}{3}.

   To form an entry, multiply the two basis functions and then multiply by :math:`r_c+h_r\xi`. Odd powers integrate to
   zero on the symmetric interval. For instance, :math:`\xi` averages to zero, but :math:`\xi(r_c+h_r\xi)` contains the even term :math:`h_r\xi^2`
   and has a nonzero integral. This produces the radial off-diagonal entries.

   .. rubric:: 4. Entries of the volume transport matrix

   The first test function is constant, so its gradient and the entire first row vanish. The radial
   derivative in row two is :math:`1/h_r` and the axial derivative in row three is :math:`1/h_z`:

   .. math::

      \begin{aligned}
      T_{21}&=-\frac{\mu}{h_r}h_rh_z(2r_c)(2)=-4\mu r_ch_z,\\
      T_{22}&=-\frac{\mu}{h_r}h_rh_z(2h_r/3)(2)=-\frac43\mu h_rh_z,\\
      T_{31}&=-\frac{\eta}{h_z}h_rh_z(2r_c)(2)=-4\eta r_ch_r,\\
      T_{32}&=-\frac{\eta}{h_z}h_rh_z(2h_r/3)(2)=-\frac43\eta h_r^2.
      \end{aligned}

   The third column contains odd integrals of :math:`\zeta` and vanishes. The matrix is therefore

   .. math::

      \mathsf T=
      \begin{pmatrix}
      0&0&0\\
      -4\mu r_ch_z&-\frac43\mu h_rh_z&0\\
      -4\eta r_ch_r&-\frac43\eta h_r^2&0
      \end{pmatrix}.

   ``sub_J02_add_volume_matrix`` takes ``mu,eta,rc,hr,hz`` and adds these four nonzero entries to the input/output matrix ``a(3,3)``, retaining any face
   terms already present. It requires validated geometry and returns no status.

   .. rubric:: 5. Entries of the loss matrix

   The loss coefficient :math:`\sigma` is constant within the cell. Factor it out of the integral and form all
   pairwise products of the three basis functions:

   .. math::

      \mathsf H=h_rh_z\int_{-1}^{1}\int_{-1}^{1}
        (r_c+h_r\xi)
        \begin{pmatrix}
          1&\xi&\zeta\\
          \xi&\xi^2&\xi\zeta\\
          \zeta&\xi\zeta&\zeta^2
        \end{pmatrix}\,\mathrm d\xi\,\mathrm d\zeta.

   The cross terms between the first two basis functions are nonzero. Terms with a single factor of :math:`\zeta`
   vanish. Evaluating the entries gives

   .. math::

      \begin{aligned}
      H_{11}&=h_rh_z(2r_c)(2)=4r_ch_rh_z,\\
      H_{12}=H_{21}&=h_rh_z(2h_r/3)(2)=\frac43h_r^2h_z,\\
      H_{22}&=h_rh_z(2r_c/3)(2)=\frac43r_ch_rh_z,\\
      H_{33}&=h_rh_z(2r_c)(2/3)=\frac43r_ch_rh_z.
      \end{aligned}

   The remaining entries are :math:`H_{13}=H_{31}=H_{23}=H_{32}=0`, because each contains :math:`\int_{-1}^1\zeta\,\mathrm d\zeta=0`. The full loss matrix is

   .. math::

      \sigma\mathsf H=\sigma
      \begin{pmatrix}
      4r_ch_rh_z&\frac43h_r^2h_z&0\\
      \frac43h_r^2h_z&\frac43r_ch_rh_z&0\\
      0&0&\frac43r_ch_rh_z
      \end{pmatrix}.

   The constant and radial linear modes are coupled, so a diagonal approximation would lose part of the
   loss integral. ``sub_J02_add_absorption_matrix`` takes ``sigma,rc,hr,hz`` and adds the result to ``a(3,3)``. It adds nothing for nonpositive ``sigma``. The sweep
   interface must reject negative loss coefficients before this point.

   .. rubric:: 6. Analytical matrices on the four outgoing faces

   Use :math:`\varepsilon=-1,+1` for low and high face positions respectively. This sign identifies the face position
   independently of the incoming or outgoing sign of :math:`\beta_f`.

   On a radial face, :math:`\xi=\varepsilon` and :math:`\boldsymbol\phi=(1,\varepsilon,\zeta)^{\mathsf T}`, giving

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

   On an axial face, :math:`\zeta=\varepsilon`. Define three radial moments on that face:

   .. math::

      M_j=h_r\int_{-1}^{1}(r_c+h_r\xi)\xi^j\,\mathrm d\xi,\qquad
      M_0=2r_ch_r,\quad M_1=\frac23h_r^2,\quad M_2=\frac23r_ch_r.

   :math:`M_0` is the area integral of a constant, :math:`M_1` the integral of :math:`\xi`, and :math:`M_2` the integral of :math:`\xi^2`, all before
   multiplication by the azimuthal span. With basis vector :math:`(1,\xi,\varepsilon)^{\mathsf T}` on the axial face, entry :math:`(1,3)` is :math:`s_f\varepsilon M_0`, entry
   :math:`(2,3)` is :math:`s_f\varepsilon M_1`, and entry :math:`(3,3)` is :math:`s_f\varepsilon^2M_0=s_fM_0`. Together they give

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

   ``sub_J02_add_self_face_matrix`` takes ``face_id,s,rc,hr,hz`` and accumulates ``a(3,3)`` using the four formulas above. ``s`` is the dimensionless :math:`s_f`. The local
   variable ``c0,c1,c11`` denotes :math:`s_fM_0,s_fM_1,s_fM_2`. The caller supplies a valid face index and a nonnegative directional cosine.

   .. rubric:: 7. Contribution of the upstream distribution to an interior face

   Write the upstream coefficients as :math:`\boldsymbol c^{\mathrm{up}}`. A radial face at :math:`\xi=\varepsilon` in the current cell lies at :math:`\xi_{\mathrm{up}}=-\varepsilon` in the
   upstream cell. The upwind trace is therefore

   .. math::

      \psi^{\mathrm{up}}_f
          =c^{\mathrm{up}}_0-\varepsilon c^{\mathrm{up}}_1
             +c^{\mathrm{up}}_2\zeta.

   Evaluate the test functions :math:`(1,\varepsilon,\zeta)^{\mathsf T}` on the current cell. With :math:`t=c^{\mathrm{up}}_0-\varepsilon c^{\mathrm{up}}_1`, the three component integrals are

   .. math::

      \int_{-1}^1(t+c^{\mathrm{up}}_2\zeta)\,\mathrm d\zeta=2t,\qquad
      \int_{-1}^1\varepsilon(t+c^{\mathrm{up}}_2\zeta)\,\mathrm d\zeta=2\varepsilon t,\qquad
      \int_{-1}^1\zeta(t+c^{\mathrm{up}}_2\zeta)\,\mathrm d\zeta=\frac23c^{\mathrm{up}}_2.

   Multiplying by the common factor :math:`s_fh_z(r_c+\varepsilon h_r)` and substituting back for :math:`t` gives

   .. math::

      \boldsymbol b_{r\varepsilon}^{\mathrm{up}}
         =s_fh_z(r_c+\varepsilon h_r)
           \begin{pmatrix}
           2&-2\varepsilon&0\\
           2\varepsilon&-2&0\\
           0&0&2/3
           \end{pmatrix}\boldsymbol c^{\mathrm{up}}.

   The upstream trace on an axial face is :math:`c^{\mathrm{up}}_0+c^{\mathrm{up}}_1\xi-\varepsilon c^{\mathrm{up}}_2`. For the three test equations, multiply this trace by :math:`1,\xi,\varepsilon`
   and integrate, collecting its constant and radial linear parts with :math:`M_0,M_1,M_2`. This gives

   .. math::

      \boldsymbol b_{z\varepsilon}^{\mathrm{up}}
         =s_f\begin{pmatrix}
           M_0&M_1&-\varepsilon M_0\\
           M_1&M_2&-\varepsilon M_1\\
           \varepsilon M_0&\varepsilon M_1&-M_0
           \end{pmatrix}\boldsymbol c^{\mathrm{up}}.

   ``sub_J02_add_neighbor_rhs`` takes ``face_id,s,coeff_up(3),rc,hr,hz`` and adds to the input/output vector ``rhs(3)``. It reads the upstream face touching the current
   cell, whose normal coordinate has the opposite sign. This differs from multiplying by the current
   cell's own face matrix. The ordering and units of the upstream coefficients are identical to those
   in the current cell.

   .. rubric:: 8. Prescribed inflow and whole-face specular reflection

   An inlet distribution :math:`h_m` that is constant over the face can be taken outside the area integral. Its
   value can still vary with discrete velocity. Integrate :math:`(1,\varepsilon,\zeta)` on radial faces and :math:`(1,\xi,\varepsilon)` on axial faces to
   obtain

   .. math::

      \boldsymbol b_{r\varepsilon}^{\mathrm{const}}
          =s_fh_mh_z(r_c+\varepsilon h_r)(2,2\varepsilon,0)^{\mathsf T},
      \qquad
      \boldsymbol b_{z\varepsilon}^{\mathrm{const}}
          =s_fh_m(M_0,M_1,\varepsilon M_0)^{\mathsf T}.

   ``sub_J02_add_constant_rhs`` takes ``face_id,s,g,rc,hr,hz`` and adds the result to ``rhs(3)``. Here ``g`` is an already normalized distribution, such as inlet
   :math:`h_m` or diffuse reflection :math:`C_Wg_{\mathrm w,m}`.

   Specular reflection uses coefficients from the previous iteration at the reflected direction on the
   same physical face of the same cell:

   .. math::

      \boldsymbol b_f^{\mathrm{spec}}
          =\mathsf F_f\boldsymbol c^{\mathrm{old}}_{R_f(m)}.

   ``sub_J02_add_specular_rhs`` takes ``face_id,s,coeff_reflected(3),rc,hr,hz`` and accumulates ``rhs(3)``. It reuses the current cell's face matrix because the local face
   coordinate is unchanged. The sweep combines the mixed-wall contributions with :math:`(1-d)\boldsymbol b^{\mathrm{spec}}+d\boldsymbol b^{\mathrm{const}}`.

   .. rubric:: 9. Integrals over part of an axial face

   A partial inlet subdivides the radial interval of a face at :math:`\zeta=\varepsilon`. For any :math:`[\xi_L,\xi_H]` define

   .. math::

      M_j[\xi_L,\xi_H]
          =h_r\int_{\xi_L}^{\xi_H}\xi^j(r_c+h_r\xi)\,\mathrm d\xi.

   For arbitrary :math:`j=0,1,2` the antiderivative is

   .. math::

      M_j[\xi_L,\xi_H]
       =h_r\left[
          \frac{r_c}{j+1}\xi^{j+1}+
          \frac{h_r}{j+2}\xi^{j+2}
         \right]_{\xi_L}^{\xi_H}.

   Substituting :math:`j=0,1,2` gives the three moments:

   .. math::

      \begin{aligned}
      M_0&=h_r\left[r_c(\xi_H-\xi_L)+\frac{h_r}{2}(\xi_H^2-\xi_L^2)\right],\\
      M_1&=h_r\left[\frac{r_c}{2}(\xi_H^2-\xi_L^2)+\frac{h_r}{3}(\xi_H^3-\xi_L^3)\right],\\
      M_2&=h_r\left[\frac{r_c}{3}(\xi_H^3-\xi_L^3)+\frac{h_r}{4}(\xi_H^4-\xi_L^4)\right].
      \end{aligned}

   ``sub_J02_zface_interval_moments`` takes ``rc,hr,xi_lo,xi_hi`` and returns the real values ``m0,m1,m2``. Each has units :math:`\mathrm{m^2}` and excludes :math:`\Theta`. An upper bound no
   larger than the lower bound produces three zeros. The caller checks the remaining interval
   constraints.

   Let the distribution restricted to the interval be :math:`t_0+t_1\xi`. For test function :math:`1` the integrand is :math:`t_0+t_1\xi` and
   its integral is :math:`t_0M_0+t_1M_1`. For :math:`\xi` the integral is :math:`t_0M_1+t_1M_2`. For :math:`\varepsilon` the integral equals the first integral
   multiplied by :math:`\varepsilon`. The resulting right-hand side is

   .. math::

      \boldsymbol b_{z\varepsilon}[\xi_L,\xi_H]
          =s_f\begin{pmatrix}
            t_0M_0+t_1M_1\\
            t_0M_1+t_1M_2\\
            \varepsilon(t_0M_0+t_1M_1)
          \end{pmatrix}.

   Two routines accumulate these contributions:

   - ``sub_J02_add_zface_constant_interval_rhs`` takes ``s,g,zeta,xi_lo,xi_hi,rc,hr``, uses :math:`t_0=g,t_1=0`, and adds to ``rhs(3)``.
   - ``sub_J02_add_zface_coeff_interval_rhs`` takes ``s,coeff(3),zeta,xi_lo,xi_hi,rc,hr``, uses :math:`t_0=c_0+\varepsilon c_2,t_1=c_1`, and adds to ``rhs(3)``.

   In both routines ``zeta`` gives the face position :math:`\varepsilon=\pm1`. The coefficient form evaluates a polynomial on the
   same face, without converting to the neighbor's coordinates. Integrate prescribed inflow on the open
   interval, then add specular and diffuse contributions integrated over the two complementary wall
   intervals. Outgoing particles cross the entire cell face, so the left-hand outgoing matrix uses its
   full area.

   ``fun_J02_zface_coeff_interval_integral`` returns just the integral of the distribution over a face interval, without forming a
   three-component right-hand side:

   .. math::

      I_\psi=h_r\int_{\xi_L}^{\xi_H}
          (c_0+c_1\xi+\varepsilon c_2)(r_c+h_r\xi)\,\mathrm d\xi
          =(c_0+\varepsilon c_2)M_0+c_1M_1.

   The inputs are ``coeff(3),zeta,xi_lo,xi_hi,rc,hr``. The result has units of distribution times :math:`\mathrm{m^2}` and excludes the azimuthal span.
   Wall normalization and open-flux reconstruction use this integral.

   .. rubric:: 10. Assembling a cell equation

   For :math:`\mu>0,\eta>0`, particles enter from the left and bottom and leave through the right and top faces. Suppose
   all four neighbors are active and the upstream coefficients in the left and bottom cells are known.
   Then

   .. math::

      \underbrace{(\mathsf T+\sigma\mathsf H
                     +\mathsf F_{r+}+\mathsf F_{z+})}_{\mathsf A}
          \begin{pmatrix}c_0\\c_1\\c_2\end{pmatrix}
        =\underbrace{\boldsymbol b_{r-}^{\mathrm{up}}
                       +\boldsymbol b_{z-}^{\mathrm{up}}}_{\boldsymbol b}.

   The left-hand matrices depend on local geometry, velocity direction, and loss. The right-hand side
   uses the known left and bottom traces. For an inlet below the cell, replace :math:`\boldsymbol b_{z-}^{\mathrm{up}}` by the prescribed
   inflow integral using :math:`h_m`. For a wall, use the mixed specular and diffuse integrals. For a partially
   open face, integrate separately over its inlet and wall intervals and add the contributions.

   The first row illustrates the particle balance. Since :math:`\phi_1=1`, the first row of the volume transport
   matrix vanishes and the first equation becomes

   .. math::

      \underbrace{\sum_{\beta_f>0}\beta_f \int_f r\psi\,\mathrm ds}_{\text{outflow}} +\underbrace{\sigma\int_Kr\psi\,\mathrm dr\,\mathrm dz}_{\text{loss}} =\underbrace{\sum_{\beta_f<0}|\beta_f| \int_f r\psi_f^{\mathrm{up}}\,\mathrm ds}_{\text{inflow}}.

   Multiply by :math:`\Theta v_m w_m` to obtain this discrete velocity's contribution to the physical particle rate.
   Summing over velocities gives the total cell balance. The other two rows determine spatial variation
   within the cell. The first row thus identifies the required face terms, the sign of the incoming
   contributions, and the balance to retain when enforcing positivity.

   The sweep zeros ``a`` and ``rhs``, calls the appropriate face routine for each of the four faces, and then
   calls ``sub_J02_add_volume_matrix`` and ``sub_J02_add_absorption_matrix``. The local solve uses the sum of these contributions.

   .. rubric:: 11. Solving the local system

   ``sub_J02_solve_local_3x3`` uses Gaussian elimination with partial pivoting. In each column it selects the largest remaining
   absolute entry at or below the current row and exchanges rows to place the pivot. When eliminating
   row :math:`i>j` in column :math:`j`,

   .. math::

      \lambda_i=A_{ij}/A_{jj},\qquad
      A_{i,j:3}\leftarrow A_{i,j:3}-\lambda_iA_{j,j:3},\qquad
      b_i\leftarrow b_i-\lambda_ib_j.

   After triangularization, back-substitute from the third row to the first:

   .. math::

      c_{i-1}=\frac{b_i-\sum_{j=i+1}^{3}A_{ij}c_{j-1}}{A_{ii}}.

   - Inputs ``a(3,3)`` and ``b(3)`` are copied for elimination and remain unchanged.
   - Output ``x(3)`` contains :math:`c_0,c_1,c_2` in that order. The routine also returns ``ierr``.
   - If the selected pivot is no larger than ``100*tiny(1.0)``, return a singular-system error and zero the output.
     This test detects small pivots. It does not estimate the condition number, so an ill-conditioned
     system may still lose accuracy.

   .. rubric:: 12. Enforcing positivity of the linear polynomial

   The minimum of the linear polynomial over the reference rectangle occurs at a corner and equals

   .. math::

      \psi_{\min}=c_0-|c_1|-|c_2|.

   If the minimum is nonnegative, keep all three coefficients. Otherwise revert to a cellwise constant
   and solve the constant test equation alone:

   .. math::

      c_1=c_2=0,\qquad c_0=b_1/A_{11}.

   ``sub_J02_enforce_local_positivity``:

   - Inputs are ``a(3,3)`` and ``rhs(3)``, with ``coeff(3)`` on input and output.
   - Output ``ierr`` reports status. Optional output ``corrected`` records whether the constant fallback was used.
   - Inputs must be finite and satisfy :math:`A_{11}>0` and :math:`b_1\geq0`. Nonfinite data or a negative incoming particle rate
     produce a positivity error.
   - The fallback preserves particle balance in the constant test equation. It can change the mean of
     the original linear polynomial and does not enforce the two remaining test equations.

   This file supplies the cell matrix and right-hand side integrals, local solve, and positivity check.
   The sweep obtains the upstream distribution or boundary value for each face type, assembles these
   terms, and solves each cell. A different inlet or wall model can reuse the same matrix integrals by
   providing its incoming distribution.

   .. rubric:: References

   .. _j02-dg-ref-rh73-en:

   Reed, W. H., and T. R. Hill (1973). *Triangular Mesh Methods for the Neutron Transport Equation*. Los
   Alamos Scientific Laboratory, LA-UR-73-479. `Full report <https://www.osti.gov/servlets/purl/4491151>`__
