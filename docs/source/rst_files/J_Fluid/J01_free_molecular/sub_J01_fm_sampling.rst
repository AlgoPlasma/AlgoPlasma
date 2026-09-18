sub_J01_fm_sampling.f90
=======================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   由 ``mod_J01_neutral_free_molecular_2Drz`` 包含，编译时只编译 mod 文件，不单独编译此 sub 文件。
   :doc:`模块总览 <particle_transport>`。

   .. rubric:: 准备入口

   ``sub_J01_prepare_fm_inlet`` 输入径向网格、有效单元、面类型、扇区角、入口范围、质量、温度、漂移、密度参数和历史数；输出 ``inlet``、``history_rate``、``ierr``。仅使用轴向低端的有效开放面，与入口范围相交后得到 [a,b]：

   .. math::

      A_i=\frac{\Theta}{2}(b_i^2-a_i^2),\qquad P(i)=\frac{A_i}{\sum_j A_j},\qquad r=\sqrt{a_i^2+\xi(b_i^2-a_i^2)}.

   其中随机数 ξ 在 [0,1) 上均匀分布。``inlet`` 保存各段面积及上下界、总面积和热速度标准差。没有有效入口时返回配置错误。

   .. rubric:: 入射事件采样

   ``sub_J01_sample_fm_inlet`` 输入成功准备的 ``inlet``、起始轴向位置 ``z_start`` 及同一个漂移速度，输出 ``r,z,ur,uz``。径向位置按面积采样，速度为：

   .. math::

      v_r=\sigma Z_1,\qquad v_z=U_z+\sigma Z_2>0,\qquad \sigma=\sqrt{k_BT/m}.

   Z 为标准正态变量，轴向速度非正时重抽。此处把截断正态直接作为入射事件分布，没有额外乘 v_z 权重，不是储气池 Maxwell 通量采样。``inlet_density`` 不强制首层密度，而用于计算：

   .. math::

      \bar v_z^+=U_z+\sigma\frac{\varphi(U_z/\sigma)}{\Phi(U_z/\sigma)},\qquad \dot w=\frac{n_{\rm in}A_{\rm in}\bar v_z^+}{N}.

   φ、Φ 分别为标准正态密度和累积分布。非常大的负漂移会使拒绝采样效率极低，当前接口不适合该范围。

   .. rubric:: 随机数辅助

   ``fun_J01_standard_normal`` 用 Box–Muller 公式返回标准正态随机数。``sub_J01_set_random_seed(seed_value)`` 修改运行时随机状态。同种子复现仅适用于相同编译器及运行时，不保证跨平台逐位一致。

   .. rubric:: 接口声明

   .. code-block:: fortran

      subroutine sub_J01_prepare_fm_inlet(r_edge, active, face_type, theta_span, inlet_r_lo, &
      inlet_r_hi, neutral_mass, inlet_temperature, inlet_drift_z, inlet_density, &
      n_histories, inlet, history_rate, ierr)
      real, intent(in) :: r_edge(:), theta_span, inlet_r_lo, inlet_r_hi, neutral_mass
      real, intent(in) :: inlet_temperature, inlet_drift_z, inlet_density
      logical, intent(in) :: active(:, :)
      integer, intent(in) :: face_type(:, :, :), n_histories
      type(fm_inlet_2drz_type), intent(out) :: inlet
      real, intent(out) :: history_rate
      integer, intent(out) :: ierr

   .. code-block:: fortran

      subroutine sub_J01_sample_fm_inlet(inlet, z_start, inlet_drift_z, r, z, ur, uz)
      type(fm_inlet_2drz_type), intent(in) :: inlet
      real, intent(in) :: z_start, inlet_drift_z
      real, intent(out) :: r, z, ur, uz

   .. code-block:: fortran

      real function fun_J01_standard_normal()

   .. code-block:: fortran

      subroutine sub_J01_set_random_seed(seed_value)
      integer, intent(in) :: seed_value

   .. rubric:: 测试与源码

   :doc:`模块测试 </tests/011_fluid/J01_fm_tests>` 按子程序列出输入与断言。
   :download:`下载源码 <../../../../../J_Fluid/J01_free_molecular/sub_J01_fm_sampling.f90>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   Included by ``mod_J01_neutral_free_molecular_2Drz``. Compile the module, not this file.
   :doc:`Module overview <particle_transport>` · :doc:`Tests </tests/011_fluid/J01_fm_tests>`.
