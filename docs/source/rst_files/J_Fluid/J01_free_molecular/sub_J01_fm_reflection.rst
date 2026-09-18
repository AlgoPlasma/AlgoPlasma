sub_J01_fm_reflection.f90
=========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   由 ``mod_J01_neutral_free_molecular_2Drz`` 包含，编译时只编译 mod 文件，不单独编译此 sub 文件。
   :doc:`模块总览 <particle_transport>`。

   .. rubric:: 镜面与漫反射

   ``sub_J01_reflect_velocity`` 输入面编号、漫反射比例和 ``sigma_wall=sqrt(kB*Twall/m)``，原地修改 ``ur,uz``。面序为径向低端、径向高端、轴向低端、轴向高端。调用方须保证面编号有效、壁温标准差为正、比例在 [0,1]。

   以 ``1-diffuse_fraction`` 的概率执行镜面反射，仅翻转法向速度：

   .. math::

      v_n'=-v_n,\qquad v_t'=v_t.

   以 ``diffuse_fraction`` 的概率执行漫反射：

   .. math::

      |v_n'|=\sigma_w\sqrt{-2\ln\xi},\qquad v_t'=\sigma_w Z.

   法向符号指向域内，切向速度为零均值正态。法向使用通量加权分布，与入口采用的截断正态事件分布不同。本子程序只改变速度，不定位粒子、不累计通量。

   .. rubric:: 接口声明

   .. code-block:: fortran

      subroutine sub_J01_reflect_velocity(ur, uz, face, diffuse_fraction, sigma_wall)
      real, intent(inout) :: ur, uz
      integer, intent(in) :: face
      real, intent(in) :: diffuse_fraction, sigma_wall

   .. rubric:: 测试与源码

   :doc:`模块测试 </tests/011_fluid/J01_fm_tests>` 按子程序列出输入与断言。
   :download:`下载源码 <../../../../../J_Fluid/J01_free_molecular/sub_J01_fm_reflection.f90>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   Included by ``mod_J01_neutral_free_molecular_2Drz``. Compile the module, not this file.
   :doc:`Module overview <particle_transport>` · :doc:`Tests </tests/011_fluid/J01_fm_tests>`.
