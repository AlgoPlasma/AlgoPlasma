===============
A02_Boris_3Drtz
===============

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   * :doc:`mod_A02_Boris_3Drtz.f90 <A02_Boris_3Drtz/mod_A02_Boris_3Drtz>`:

       ``mod_A02_Boris_3Drtz`` 是 A02 柱坐标非相对论 Boris pusher 的
       Fortran module 入口。它主要用于收纳并导出本组子程序，方便调用端通过
       ``use mod_A02_Boris_3Drtz`` 使用。

       收纳的子程序：

       - ``sub_A02_Boris_3Drtz_push_v_x.f90``: 在柱坐标
         :math:`(r,\theta,z)` 中推进单个粒子的位置
         :math:`\mathbf{x}` 和速度 :math:`\mathbf{v}`。

   * :doc:`sub_A02_Boris_3Drtz_push_v_x.f90 <A02_Boris_3Drtz/sub_A02_Boris_3Drtz_push_v_x>`:

       ``sub_A02_Boris_3Drtz_push_v_x`` 是本模块的核心 particle pusher。
       给定粒子位置处的电场和磁场，它执行 non-relativistic cylindrical
       Boris push，并在一个完整时间步内更新
       :math:`\mathbf{x} = (r,\theta,z)` 与
       :math:`\mathbf{v} = (v_r,v_\theta,v_z)`。

   .. rubric:: 测试

   相关测试说明见 :doc:`A02_Boris_3Drtz 测试 </tests/002_pusher/A02_Boris_3Drtz>`。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">赵中平 (2025/11/20) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   * :doc:`mod_A02_Boris_3Drtz.f90 <A02_Boris_3Drtz/mod_A02_Boris_3Drtz>`:

       ``mod_A02_Boris_3Drtz`` is the Fortran module entry point for the A02
       non-relativistic Boris pusher in cylindrical coordinates. It groups and
       exports the routines in this component for callers that use
       ``mod_A02_Boris_3Drtz``.

       Contained subroutines:

       - ``sub_A02_Boris_3Drtz_push_v_x.f90``: advances a single particle
         position :math:`\mathbf{x}` and velocity :math:`\mathbf{v}` in
         cylindrical coordinates :math:`(r,\theta,z)`.

   * :doc:`sub_A02_Boris_3Drtz_push_v_x.f90 <A02_Boris_3Drtz/sub_A02_Boris_3Drtz_push_v_x>`:

       ``sub_A02_Boris_3Drtz_push_v_x`` is the core particle pusher in this
       module. Given the electric and magnetic fields at the particle position,
       it performs a non-relativistic cylindrical Boris push and advances both
       :math:`\mathbf{x} = (r,\theta,z)` and
       :math:`\mathbf{v} = (v_r,v_\theta,v_z)` over one full time step.

   .. rubric:: Tests

   See :doc:`A02_Boris_3Drtz tests </tests/002_pusher/A02_Boris_3Drtz>` for
   the reference test cases and figures.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zhongping ZHAO (2025/11/20) · Harbin Institute of Technology</p>
      </div>

.. toctree::
    :maxdepth: 1
    :hidden:

    A02_Boris_3Drtz/mod_A02_Boris_3Drtz
    A02_Boris_3Drtz/sub_A02_Boris_3Drtz_push_v_x
