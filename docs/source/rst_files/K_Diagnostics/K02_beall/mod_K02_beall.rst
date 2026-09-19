----------------
mod_K02_beall.py
----------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块职责

   本页说明该模块入口的职责、公开入口和汇总关系；具体参数以各 routine 页为准。

   .. rubric:: 公开入口 / 汇总关系

   .. list-table::
      :header-rows: 1
      :widths: 34 40 26

      * - 入口 / 文件
        - 角色
        - 关系
      * - ``fun_K02_separation_vector``
        - 由间距和方位角构造 :math:`\boldsymbol{\chi}`。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K02_separation_magnitude``
        - :math:`|\boldsymbol{\chi}|`，并集中做校验。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K02_nyquist_wavenumber``
        - :math:`\pi/|\boldsymbol{\chi}|`。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K02_project_wavenumber``
        - :math:`\mathbf{K}\cdot\hat{\boldsymbol{\chi}}`。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K02_fold_order``
        - 折叠阶数 :math:`n`。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K02_fold_wavenumber``
        - 折叠后的波数。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K02_wavenumber_edges``
        - 张成 :math:`\pm\pi/|\boldsymbol{\chi}|` 的直方图边界。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K02_beall_wavenumber``
        - :math:`\mathrm{wrap}(\theta)/|\boldsymbol{\chi}|`。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K02_beall_spectrum``
        - 累积 :math:`S(k,f)`。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K02_peak_wavenumber``
        - 每个频点的谱峰波数。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K02_wavenumber_residual``
        - 折叠轴上的圆周距离。
        - 由 ``from ... import`` 汇入模块入口。

   .. rubric:: 局部假设

   - 本模块以 Python 实现，模块入口用 ``from ... import`` 汇总，对应 Fortran 侧的 ``#include``。
   - 本页只说明本单元的局部约定；不假设调用方的数据来源、单位制或存储布局。

   .. rubric:: 实现逻辑

   - 模块入口只做导入与再导出，本身不含任何计算，也不是运行时 dispatcher。
   - 每个 routine 仍是一个可独立阅读的文件。

   .. rubric:: 调用注意

   - 调用方应把仓库根目录加入 ``sys.path``，再从该模块入口导入所需 routine。
   - 也可直接从单个 ``fun_`` 文件导入；模块入口只是便利入口，不改变任何行为。

   .. rubric:: 模块说明

   ``mod_K02_beall`` 是 K02 的模块入口。K02 包含混叠折叠的闭式代数和让混叠显形的 Beall 统计色散谱：单对探针只能报出 :math:`\pm\pi/|\boldsymbol{\chi}|` 以内的波数，越限的模态被折回，笔直的色散支被打断成重复的锯齿。

   .. rubric:: 使用说明

   .. code-block:: python

      import sys
      sys.path.insert(0, "/path/to/AlgoPlasma")

      import numpy as np
      from K_Diagnostics.K02_beall.mod_K02_beall import (
          fun_K02_beall_spectrum, fun_K02_peak_wavenumber,
          fun_K02_separation_vector, fun_K02_wavenumber_edges,
      )

      chi = fun_K02_separation_vector(20.0e-3, np.deg2rad(30.0))
      result = fun_K02_beall_spectrum(
          phase, magnitude, frequencies_hz, chi,
          fun_K02_wavenumber_edges(chi, 80), f_edges,
      )
      peaks = fun_K02_peak_wavenumber(result["spectrum"], result["k_centers"])

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   This page states the role of the module entry, its public entries and the aggregation relation; the arguments live on the routine pages.

   .. rubric:: Public Entries / Aggregation

   .. list-table::
      :header-rows: 1
      :widths: 34 40 26

      * - Entry / File
        - Role
        - Relation
      * - ``fun_K02_separation_vector``
        - Build :math:`\boldsymbol{\chi}` from a spacing and an orientation.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K02_separation_magnitude``
        - :math:`|\boldsymbol{\chi}|`, with the validation done once.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K02_nyquist_wavenumber``
        - :math:`\pi/|\boldsymbol{\chi}|`.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K02_project_wavenumber``
        - :math:`\mathbf{K}\cdot\hat{\boldsymbol{\chi}}`.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K02_fold_order``
        - The fold order :math:`n`.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K02_fold_wavenumber``
        - The folded wavenumber.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K02_wavenumber_edges``
        - Histogram edges spanning :math:`\pm\pi/|\boldsymbol{\chi}|`.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K02_beall_wavenumber``
        - :math:`\mathrm{wrap}(\theta)/|\boldsymbol{\chi}|`.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K02_beall_spectrum``
        - Accumulate :math:`S(k,f)`.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K02_peak_wavenumber``
        - Peak wavenumber at each frequency.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K02_wavenumber_residual``
        - Circular distance on the folded axis.
        - Re-exported by the module entry through ``from ... import``.

   .. rubric:: Local Assumptions

   - The unit is written in Python, so the module entry aggregates with ``from ... import``, the counterpart of the Fortran ``#include``.
   - This page states only the local conventions of the unit; it assumes nothing about the caller's data source, units or storage layout.

   .. rubric:: Implementation Notes

   - The module entry only imports and re-exports; it contains no computation and is not a runtime dispatcher.
   - Each routine remains a file that can be read on its own.

   .. rubric:: Calling Notes

   - Callers should add the repository root to ``sys.path`` and import the routines they need from this module entry.
   - Importing directly from an individual ``fun_`` file is equally valid; the module entry is a convenience and changes no behaviour.

   .. rubric:: Module Description

   ``mod_K02_beall`` is the module entry of K02, which holds the closed-form algebra of aliasing together with the Beall spectrum that makes it visible: a single pair can only report wavenumbers inside :math:`\pm\pi/|\boldsymbol{\chi}|`, so modes beyond that limit fold back and a straight branch is broken into a repeating sawtooth.

   .. rubric:: Usage

   .. code-block:: python

      import sys
      sys.path.insert(0, "/path/to/AlgoPlasma")

      import numpy as np
      from K_Diagnostics.K02_beall.mod_K02_beall import (
          fun_K02_beall_spectrum, fun_K02_peak_wavenumber,
          fun_K02_separation_vector, fun_K02_wavenumber_edges,
      )

      chi = fun_K02_separation_vector(20.0e-3, np.deg2rad(30.0))
      result = fun_K02_beall_spectrum(
          phase, magnitude, frequencies_hz, chi,
          fun_K02_wavenumber_edges(chi, 80), f_edges,
      )
      peaks = fun_K02_peak_wavenumber(result["spectrum"], result["k_centers"])

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
