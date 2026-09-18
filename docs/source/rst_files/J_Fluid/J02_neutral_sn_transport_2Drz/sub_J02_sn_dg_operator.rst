sub_J02_sn_dg_operator.f90
==========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 局部不连续伽辽金算子

   源码：``J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_dg_operator.f90``。
   由 ``mod_J02_neutral_sn_transport_2Drz`` 包含，不能作为独立模块编译。
   :doc:`返回模块总览 <../J02_neutral_sn_transport_2Drz>`。
   正文中的简写过程名省略了所属模块的 sub 前缀，完整接口见下方声明。

   .. rubric:: 离散算子文件：局部矩阵从何而来

   ``sub_J02_sn_dg_operator.f90`` 装配一个单元、一个方向的系统。
   取 :math:`\phi=(1,\xi,\zeta)`，局部系数 a 表示常数项、径向斜率系数和轴向斜率系数，
   不是三个速度分量。消去公共扇区角后的弱形式为

   .. math::

      \begin{aligned}
      A_{ab}&=-\int_K r\phi_b\boldsymbol\Omega\cdot\nabla\phi_a\,dr\,dz
      +\int_K r\sigma_t\phi_a\phi_b\,dr\,dz\\
      &\quad+\int_{\partial K^+}r(\boldsymbol\Omega\cdot\boldsymbol n)\phi_a\phi_b\,ds,\\
      b_a&=\int_{\partial K^-}r|\boldsymbol\Omega\cdot\boldsymbol n|
      \phi_a\psi_{\rm up}\,ds,\\
      A\boldsymbol a&=\boldsymbol b.
      \end{aligned}

   ``add_volume_matrix`` 加入第一个积分：

   .. math::

      A^{\rm vol}=\begin{pmatrix}
      0&0&0\\-4\mu r_ch_z&-\frac43\mu h_rh_z&0\\
      -4\eta r_ch_r&-\frac43\eta h_r^2&0
      \end{pmatrix}.

   第一行零值来自常数检验函数的导数为零。``add_absorption_matrix`` 加入第二个积分：

   .. math::

      A^{\rm abs}=4\sigma_t h_rh_z
      \begin{pmatrix}r_c&h_r/3&0\\h_r/3&r_c/3&0\\0&0&r_c/3\end{pmatrix}.

   非对角项来自柱坐标权重 r。``add_self_face_matrix`` 加入出流面项；
   ``add_neighbor_rhs`` 读取迎风邻居的对面迹值；``add_constant_rhs`` 加入常数入口；
   ``add_specular_rhs`` 用反射方向的同一壁面系数构造右端项。
   这些过程累加到 a 或 rhs，调用方须先置零。

   ``zface_interval_moments`` 计算部分轴向面上的三个矩：

   .. math::

      M_j=h_r\int_{\xi_a}^{\xi_b}(r_c+h_r\xi)\xi^j\,d\xi,\quad j=0,1,2.

   ``add_zface_constant_interval_rhs`` 加入 :math:`sg(M_0,M_1,\zeta_fM_0)`；
   ``add_zface_coeff_interval_rhs`` 对一次面迹值积分；
   ``fun_J02_zface_coeff_interval_integral`` 返回
   :math:`(a_0+\zeta_fa_2)M_0+a_1M_1`。
   这里 s 为方向余弦与外法向点积的绝对值，轴向下、上面的 zeta_f 为 -1、+1。
   ``solve_local_3x3`` 使用列主元选择的高斯消元与回代，输出三个系数；
   主元过小返回局部奇异错误。

   .. rubric:: 保正处理与局部守恒

   开放边界和反射边界扫掠均在局部求解后调用
   ``sub_J02_enforce_local_positivity(a, rhs, coeff, ierr, corrected)``。
   输入 a、rhs 为已装配的矩阵和右端；coeff 为原地更新的三个系数；
   可选输出 corrected 表示是否进行了低阶回退。

   线性分布在矩形单元上的最小值为
   :math:`a_0-|a_1|-|a_2|`。若其非负，保留原 P1 解；否则使用常数解：

   .. math::

      a_0^{\rm new}=b_1/A_{11},\qquad a_1^{\rm new}=a_2^{\rm new}=0.

   第一行对应常数检验函数，即出流加吸收等于入流的粒子收支。
   因而这一步保留收支方程，但不保留原 P1 单元平均值，也不再满足两个斜率方程。
   下游扫掠、反射、密度和面通量重构均使用更新后的系数。
   这不是密度截零或平均值保持的斜率限制器；发生回退的单元降为 P0，数值扩散会增加。
   网格精度和完整算例结果仍需重新验证。

   在非负入口和非负吸收系数下，右端粒子率应非负且 A11 应为正。
   若不满足，或矩阵、右端、系数含非有限数，返回错误码 502，
   扫掠同时返回出错方向和单元位置，不静默修补非法输入。

   .. rubric:: 参数含义速查

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 参数或字段
        - 含义
      * - ``a、rhs、b、x``
        - a 为 3×3 局部矩阵；rhs/b 为三个检验方程的右端；x 为求得的三个分布系数。
      * - ``rc、hr、hz``
        - 径向中心及径向/轴向半宽（m），局部坐标为 (r-rc)/hr 和 (z-zc)/hz。
      * - ``mu、eta、sigma``
        - 方向余弦（无量纲）及吸收系数（m⁻¹）。
      * - ``face_id、s、g``
        - 四面编号、法向方向余弦绝对值、给定常数入口相密度。此处 s 不是 J01 的密度扣减项。
      * - ``coeff_up、coeff_reflected、coeff``
        - 迎风邻居、反射方向或待积分面所属单元的三个 P1 系数，顺序为常数、径向、轴向。
      * - ``xi_lo/hi、zeta、m0/m1/m2``
        - 径向局部积分范围、轴向面的局部坐标（±1）、带 r 权重的零/一/二阶面矩。

   .. rubric:: 逐个过程的接口声明

   以下声明来自本文件。``intent(in)`` 为输入，``intent(out)`` 为本次调用的输出，
   ``intent(inout)`` 表示原值参与计算并被修改；``allocatable, intent(out)`` 数组由过程分配。
   ``optional`` 可省略，数组形状中的 nr、nz 为网格单元数。过程名中的 sub/fun 前缀不改变 Fortran 调用规则。

   .. rubric:: sub_J02_add_self_face_matrix

   .. code-block:: fortran

      subroutine sub_J02_add_self_face_matrix(a, face_id, s, rc, hr, hz)
      real, intent(inout) :: a(3, 3)
      integer, intent(in) :: face_id
      real, intent(in) :: s, rc, hr, hz

   .. rubric:: sub_J02_add_neighbor_rhs

   .. code-block:: fortran

      subroutine sub_J02_add_neighbor_rhs(rhs, face_id, s, coeff_up, rc, hr, hz)
      real, intent(inout) :: rhs(3)
      integer, intent(in) :: face_id
      real, intent(in) :: s, coeff_up(3), rc, hr, hz

   .. rubric:: sub_J02_add_constant_rhs

   .. code-block:: fortran

      subroutine sub_J02_add_constant_rhs(rhs, face_id, s, g, rc, hr, hz)
      real, intent(inout) :: rhs(3)
      integer, intent(in) :: face_id
      real, intent(in) :: s, g, rc, hr, hz

   .. rubric:: sub_J02_zface_interval_moments

   .. code-block:: fortran

      subroutine sub_J02_zface_interval_moments(rc, hr, xi_lo, xi_hi, m0, m1, m2)
      real, intent(in) :: rc, hr, xi_lo, xi_hi
      real, intent(out) :: m0, m1, m2

   .. rubric:: sub_J02_add_zface_constant_interval_rhs

   .. code-block:: fortran

      subroutine sub_J02_add_zface_constant_interval_rhs(rhs, s, g, zeta, xi_lo, xi_hi, rc, hr)
      real, intent(inout) :: rhs(3)
      real, intent(in) :: s, g, zeta, xi_lo, xi_hi, rc, hr

   .. rubric:: sub_J02_add_zface_coeff_interval_rhs

   .. code-block:: fortran

      subroutine sub_J02_add_zface_coeff_interval_rhs(rhs, s, coeff, zeta, xi_lo, xi_hi, rc, hr)
      real, intent(inout) :: rhs(3)
      real, intent(in) :: s, coeff(3), zeta, xi_lo, xi_hi, rc, hr

   .. rubric:: fun_J02_zface_coeff_interval_integral

   .. code-block:: fortran

      real function fun_J02_zface_coeff_interval_integral(coeff, zeta, xi_lo, xi_hi, rc, hr)
      real, intent(in) :: coeff(3), zeta, xi_lo, xi_hi, rc, hr

   .. rubric:: sub_J02_add_specular_rhs

   .. code-block:: fortran

      subroutine sub_J02_add_specular_rhs(rhs, face_id, s, coeff_reflected, rc, hr, hz)
      real, intent(inout) :: rhs(3)
      integer, intent(in) :: face_id
      real, intent(in) :: s, coeff_reflected(3), rc, hr, hz

   .. rubric:: sub_J02_add_volume_matrix

   .. code-block:: fortran

      subroutine sub_J02_add_volume_matrix(a, mu, eta, rc, hr, hz)
      real, intent(inout) :: a(3, 3)
      real, intent(in) :: mu, eta, rc, hr, hz

   .. rubric:: sub_J02_add_absorption_matrix

   .. code-block:: fortran

      subroutine sub_J02_add_absorption_matrix(a, sigma, rc, hr, hz)
      real, intent(inout) :: a(3, 3)
      real, intent(in) :: sigma, rc, hr, hz

   .. rubric:: sub_J02_solve_local_3x3

   .. code-block:: fortran

      subroutine sub_J02_solve_local_3x3(a, b, x, ierr)
      real, intent(in) :: a(3, 3), b(3)
      real, intent(out) :: x(3)
      integer, intent(out) :: ierr

   .. rubric:: 测试与源码

   :doc:`对应测试及断言 </tests/011_fluid/J02_tests>` 列出调用本文件的测试项。
   :download:`下载实现源码 <../../../../../J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_dg_operator.f90>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   This file is included by ``mod_J02_neutral_sn_transport_2Drz``.
   Both sweeps apply ``sub_J02_enforce_local_positivity`` after the local solve.
   Nonnegative P1 polynomials are unchanged. A negative corner triggers a P0
   fallback with coefficient ``rhs(1)/a(1,1)`` and zero slopes. This preserves
   the constant-test particle balance, not the original mean or slope equations.
   All downstream traces and moments use the corrected coefficients. Troubled
   cells become more diffusive; full application and grid accuracy need revalidation.
   Nonfinite data, nonpositive A11, or a negative incoming rate return error 502.
   :doc:`Module overview <../J02_neutral_sn_transport_2Drz>` · :doc:`Tests </tests/011_fluid/J02_tests>`.
