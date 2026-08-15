===================================
A03_Higuera_Cary_relativistic_3Dxyz
===================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   * :doc:`mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher.f90 <A03_Higuera_Cary_relativistic_3Dxyz/mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher>`:

       ``mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher`` 是 A03
       relativistic Higuera-Cary 3D velocity pusher 的 Fortran module 入口。
       它主要用于收纳并导出本组子程序，方便调用端通过
       ``use mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher`` 使用。

       收纳的子程序：

       - ``sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v.f90``:
         使用 Higuera-Cary relativistic particle pusher 推进单个粒子的三维直角坐标速度 :math:`\mathbf{v}`。

   * :doc:`sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v.f90 <A03_Higuera_Cary_relativistic_3Dxyz/sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v>`:

       ``sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v`` 是本模块的核心
       relativistic velocity pusher。它将粒子速度转换为 proper velocity
       :math:`\mathbf{u} = \gamma\mathbf{v}`，执行电场半步推进和磁场旋转，
       再转换回速度 :math:`\mathbf{v}`。

   .. rubric:: 测试

   相关测试说明见 :doc:`A03_Higuera_Cary_relativistic_3Dxyz 测试 </tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz>`。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2025/11/19; 2025/12/03) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   * :doc:`mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher.f90 <A03_Higuera_Cary_relativistic_3Dxyz/mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher>`:

       ``mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher`` is the Fortran module
       entry point for the A03 relativistic Higuera-Cary 3D velocity pusher. It
       groups and exports the routines in this component for callers that use
       ``mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher``.

       Contained subroutines:

       - ``sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v.f90``: advances a
         single particle velocity :math:`\mathbf{v}` in 3D Cartesian
         coordinates using the relativistic Higuera-Cary particle pusher.

   * :doc:`sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v.f90 <A03_Higuera_Cary_relativistic_3Dxyz/sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v>`:

       ``sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v`` is the core
       relativistic velocity pusher in this module. It converts particle
       velocity to proper velocity :math:`\mathbf{u} = \gamma\mathbf{v}`,
       applies the electric half kicks and magnetic rotation, and converts the
       result back to velocity :math:`\mathbf{v}`.

   .. rubric:: Tests

   See :doc:`A03_Higuera_Cary_relativistic_3Dxyz tests </tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz>`
   for the reference test cases and figures.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2025/11/19; 2025/12/03) · Harbin Institute of Technology</p>
      </div>

.. toctree::
    :maxdepth: 1
    :hidden:

    A03_Higuera_Cary_relativistic_3Dxyz/mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher
    A03_Higuera_Cary_relativistic_3Dxyz/sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v
