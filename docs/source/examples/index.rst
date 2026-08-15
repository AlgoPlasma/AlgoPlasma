Examples
========

.. toctree::
   :maxdepth: 1
   :hidden:

   001_two_stream_2d

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 示例入口

   本节介绍如何选择并组合 AlgoPlasma 算法，构建面向具体物理问题的模拟程序。
   与用于检查单个算法正确性的 :doc:`测试文档 </tests/index>` 不同，示例重点说明
   完整计算流程、应用层代码与结果分析。

   .. list-table:: 当前示例
      :header-rows: 1
      :widths: 12 38 50

      * - ID
        - 示例
        - 内容
      * - ``001``
        - :doc:`二维静电双流不稳定性 <001_two_stream_2d>`
        - 将粒子初始化、电荷沉积、Poisson 求解、场插值、粒子推进和数据输出组件
          组合成一个紧凑的 2D3V PIC 程序，并与线性理论和能量守恒进行比较。

.. container:: ap-lang ap-lang-en

   .. rubric:: Example Entry Points

   This section shows how AlgoPlasma algorithms can be selected and combined
   into simulation programs for specific physical problems. Unlike the
   :doc:`test documentation </tests/index>`, which checks individual
   algorithms, examples emphasize complete workflows, application-level code,
   and interpretation of the resulting diagnostics.

   .. list-table:: Available examples
      :header-rows: 1
      :widths: 12 38 50

      * - ID
        - Example
        - Description
      * - ``001``
        - :doc:`Two-dimensional electrostatic two-stream instability <001_two_stream_2d>`
        - Combines particle initialization, charge deposition, a Poisson
          solve, field interpolation, particle advancement, and data output
          into a compact 2D3V PIC program, with comparisons against linear
          theory and global energy conservation.
