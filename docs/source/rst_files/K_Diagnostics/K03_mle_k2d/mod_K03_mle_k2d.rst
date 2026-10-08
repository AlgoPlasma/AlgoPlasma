------------------
mod_K03_mle_k2d.py
------------------

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
      * - ``fun_K03_wavenumber_grid``
        - 均匀搜索网格。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K03_predicted_phase``
        - 前向模型在网格上的取值。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K03_config_log_likelihood``
        - 单构型对数似然。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K03_joint_log_likelihood``
        - 多构型求和。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K03_peak_wavevector``
        - 峰位及其极坐标形式。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K03_search_wavevector``
        - 完整均匀网格遍历。
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

   每条基线通过相位差约束波矢沿该方向的投影。将多个构型的对数似然相加，可以在二维波数平面上寻找共同支持的波矢。基线的方向和长度共同决定相位条纹的交汇位置。

   .. rubric:: 使用说明

   .. code-block:: python

      import sys
      sys.path.insert(0, "/path/to/AlgoPlasma")

      from K_Diagnostics.K03_mle_k2d.mod_K03_mle_k2d import fun_K03_search_wavevector

      configurations = [(chi_j, delta_theta_j, variance_j) for ...]
      result = fun_K03_search_wavevector(configurations, k_range_rad_m=3800.0)
      # result["kx"], result["ky"], result["k_magnitude"], result["angle_deg"]

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
      * - ``fun_K03_wavenumber_grid``
        - Uniform search grid.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K03_predicted_phase``
        - The forward model on the grid.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K03_config_log_likelihood``
        - Log-likelihood of one configuration.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K03_joint_log_likelihood``
        - Sum over configurations.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K03_peak_wavevector``
        - Peak location, Cartesian and polar.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K03_search_wavevector``
        - Exhaustive uniform-grid search in row blocks.
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

   Each baseline constrains the wavevector projection along its direction through the measured phase difference. Summing the configurations' log likelihoods locates jointly supported wavevectors in the two-dimensional wavenumber plane. Baseline directions and lengths determine where the phase fringes intersect.

   .. rubric:: Usage

   .. code-block:: python

      import sys
      sys.path.insert(0, "/path/to/AlgoPlasma")

      from K_Diagnostics.K03_mle_k2d.mod_K03_mle_k2d import fun_K03_search_wavevector

      configurations = [(chi_j, delta_theta_j, variance_j) for ...]
      result = fun_K03_search_wavevector(configurations, k_range_rad_m=3800.0)
      # result["kx"], result["ky"], result["k_magnitude"], result["angle_deg"]

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
