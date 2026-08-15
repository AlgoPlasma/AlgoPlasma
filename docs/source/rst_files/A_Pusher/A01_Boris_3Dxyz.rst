===============
A01_Boris_3Dxyz
===============

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   * :doc:`mod_A01_Boris_3Dxyz.f90 <A01_Boris_3Dxyz/mod_A01_Boris_3Dxyz>`:

       ``mod_A01_Boris_3Dxyz`` 是 A01 直角坐标非相对论 Boris pusher 的
       Fortran module 入口。它本身不展开算法细节，主要用于收纳并导出本组子程序，方便调用端通过 ``use mod_A01_Boris_3Dxyz`` 使用。

       收纳的子程序：

       - ``sub_A01_Boris_3Dxyz.f90``: 对单个粒子的三维直角坐标速度
         :math:`\mathbf{v}` 执行一次完整的 non-relativistic Boris 更新。

   * :doc:`sub_A01_Boris_3Dxyz.f90 <A01_Boris_3Dxyz/sub_A01_Boris_3Dxyz>`:

       ``sub_A01_Boris_3Dxyz`` 是本模块的核心 particle pusher。它对单个粒子执行 non-relativistic 3D Boris velocity update：先进行电场半步加速，
       再进行磁场旋转，最后再进行一次电场半步加速，从而在一个完整时间步内推进 :math:`\mathbf{v}`。

   .. rubric:: 测试

   相关测试说明见 :doc:`A01_Boris_3Dxyz 测试 </tests/002_pusher/A01_Boris_3Dxyz>`。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">赵隐剑 (2025/11/04) · 哈尔滨工业大学</p>
        <p class="ap-home-contact">赵中平 (2025/11/04) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   * :doc:`mod_A01_Boris_3Dxyz.f90 <A01_Boris_3Dxyz/mod_A01_Boris_3Dxyz>`:

       ``mod_A01_Boris_3Dxyz`` is the Fortran module entry point for the A01
       non-relativistic Boris pusher in 3D Cartesian coordinates. It does not
       duplicate the algorithm description; instead, it groups and exports the
       routines in this component for callers that use ``mod_A01_Boris_3Dxyz``.

       Contained subroutines:

       - ``sub_A01_Boris_3Dxyz.f90``: advances a single particle velocity
         :math:`\mathbf{v}` with one full non-relativistic Boris update in
         3D Cartesian coordinates.

   * :doc:`sub_A01_Boris_3Dxyz.f90 <A01_Boris_3Dxyz/sub_A01_Boris_3Dxyz>`:

       ``sub_A01_Boris_3Dxyz`` is the core particle pusher in this module. It
       performs a non-relativistic 3D Boris velocity update for a single
       particle: applies the electric-field half-kicks and magnetic-field
       rotation to advance :math:`\mathbf{v}` over one full time step.

   .. rubric:: Tests

   See :doc:`A01_Boris_3Dxyz tests </tests/002_pusher/A01_Boris_3Dxyz>` for
   the reference test cases and figures.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Yinjian ZHAO (2025/11/04) · Harbin Institute of Technology</p>
        <p class="ap-home-contact">Zhongping ZHAO (2025/11/04) · Harbin Institute of Technology</p>
      </div>

.. toctree::
    :maxdepth: 1
    :hidden:

    A01_Boris_3Dxyz/mod_A01_Boris_3Dxyz
    A01_Boris_3Dxyz/sub_A01_Boris_3Dxyz
