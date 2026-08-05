002_pusher Tests
================

.. toctree::
   :maxdepth: 1
   :hidden:

   A01_Boris_3Dxyz
   A02_Boris_3Drtz
   A03_Higuera_Cary_relativistic_3Dxyz

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   本节整理 ``tests/002_pusher`` 下与 A_Pusher 相关的验证程序。这里的页面不替代
   A01/A02/A03 的算法说明，而是说明如何运行已有测试、如何读输出数据，以及静态参考图对应的物理图像。

   .. list-table:: 当前测试页面
      :header-rows: 1
      :widths: 18 38 44

      * - ID
        - 测试页面
        - 说明
      * - A01
        - :doc:`A01_Boris_3Dxyz 测试 <A01_Boris_3Dxyz>`
        - 非相对论 3D Cartesian Boris 速度推进的四个参考算例。
      * - A02
        - :doc:`A02_Boris_3Drtz 测试 <A02_Boris_3Drtz>`
        - 非相对论柱坐标 ``(r,\theta,z)`` Boris 推进器的四个参考算例，与 A01 物理参数完全对齐。
      * - A03
        - :doc:`A03_Higuera_Cary_relativistic_3Dxyz 测试 <A03_Higuera_Cary_relativistic_3Dxyz>`
        - 相对论 Higuera-Cary 速度推进的四个参考算例。

   静态图片来自一次参考运行，并保存到 ``docs/source/images/tests/002_pusher``。
   如果修改了测试程序、pusher 算法或绘图脚本，应重新运行测试并更新这些图片。

.. container:: ap-lang ap-lang-en

   This section documents the A_Pusher validation programs under
   ``tests/002_pusher``. These pages do not replace the algorithm notes for
   A01/A02/A03; they explain how to run the existing tests, how to read the
   output data, and what the static reference figures show.

   .. list-table:: Available test pages
      :header-rows: 1
      :widths: 18 38 44

      * - ID
        - Test page
        - Notes
      * - A01
        - :doc:`A01_Boris_3Dxyz tests <A01_Boris_3Dxyz>`
        - Four reference cases for the non-relativistic 3D Cartesian Boris velocity pusher.
      * - A02
        - :doc:`A02_Boris_3Drtz tests <A02_Boris_3Drtz>`
        - Four reference cases for the non-relativistic cylindrical ``(r,\theta,z)`` Boris pusher, parameter-aligned with A01.
      * - A03
        - :doc:`A03_Higuera_Cary_relativistic_3Dxyz tests <A03_Higuera_Cary_relativistic_3Dxyz>`
        - Four reference cases for the relativistic Higuera-Cary velocity pusher.

   The static figures are copied from one reference run and stored under
   ``docs/source/images/tests/002_pusher``. If the tests, pusher implementation,
   or plotting script changes, regenerate the figures and update these images.
