-------------------------
mod_K01_signal_spectra.py
-------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   新增导出 fun_K01_pair_power，提供两路自功率平均权重。

   .. rubric:: 模块职责

   本页说明该模块入口的职责、公开入口和汇总关系；具体参数以各 routine 页为准。

   .. rubric:: 公开入口 / 汇总关系

   .. list-table::
      :header-rows: 1
      :widths: 34 40 26

      * - 入口 / 文件
        - 角色
        - 关系
      * - ``fun_K01_wrap_to_pi``
        - 把角度折算到 :math:`[-\pi,\pi]`。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K01_segment_ffts``
        - 分段（不重叠）、去均值、实数 FFT。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K01_power_spectrum``
        - 分段平均的单边功率谱密度。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K01_coherence``
        - 幅度平方相干度。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K01_cross_phase``
        - 每段的互相位与互谱幅度。
        - 由 ``from ... import`` 汇入模块入口。
      * - ``fun_K01_phase_mode_statistics``
        - 众数估计的相位均值与方差。
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

   ``mod_K01_signal_spectra`` 是 K01 的模块入口。K01 是诊断链的前端：把两路探针的原始波形化为后续单元需要的谱量。分段方式与相位符号约定在本单元定义一次，K02 与 K03 共用。

   .. rubric:: 使用说明

   .. code-block:: python

      import sys
      sys.path.insert(0, "/path/to/AlgoPlasma")

      from K_Diagnostics.K01_signal_spectra.mod_K01_signal_spectra import (
          fun_K01_cross_phase, fun_K01_phase_mode_statistics, fun_K01_segment_ffts,
      )

      ffts_1 = fun_K01_segment_ffts(probe_1, nperseg)
      ffts_2 = fun_K01_segment_ffts(probe_2, nperseg)
      phase, magnitude = fun_K01_cross_phase(ffts_1, ffts_2)
      mean_phase, variance = fun_K01_phase_mode_statistics(phase[:, mode_bins])

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   Also exports fun_K01_pair_power for the mean pair auto-power weight.

   .. rubric:: Module Role

   This page states the role of the module entry, its public entries and the aggregation relation; the arguments live on the routine pages.

   .. rubric:: Public Entries / Aggregation

   .. list-table::
      :header-rows: 1
      :widths: 34 40 26

      * - Entry / File
        - Role
        - Relation
      * - ``fun_K01_wrap_to_pi``
        - Wrap angles into :math:`[-\pi,\pi]`.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K01_segment_ffts``
        - Segment without overlap, detrend, real FFT.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K01_power_spectrum``
        - Segment-averaged one-sided power spectral density.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K01_coherence``
        - Magnitude-squared coherence.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K01_cross_phase``
        - Per-segment cross phase and cross-spectral magnitude.
        - Re-exported by the module entry through ``from ... import``.
      * - ``fun_K01_phase_mode_statistics``
        - Histogram-mode phase mean and variance.
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

   ``mod_K01_signal_spectra`` is the module entry of K01, the front end of the diagnostic chain: it turns two raw probe records into the quantities the later units consume. The segmentation scheme and the phase sign convention are defined here once and shared by K02 and K03.

   .. rubric:: Usage

   .. code-block:: python

      import sys
      sys.path.insert(0, "/path/to/AlgoPlasma")

      from K_Diagnostics.K01_signal_spectra.mod_K01_signal_spectra import (
          fun_K01_cross_phase, fun_K01_phase_mode_statistics, fun_K01_segment_ffts,
      )

      ffts_1 = fun_K01_segment_ffts(probe_1, nperseg)
      ffts_2 = fun_K01_segment_ffts(probe_2, nperseg)
      phase, magnitude = fun_K01_cross_phase(ffts_1, ffts_2)
      mean_phase, variance = fun_K01_phase_mode_statistics(phase[:, mode_bins])

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
