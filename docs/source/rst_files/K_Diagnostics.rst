K_Diagnostics
=============

.. toctree::
    :maxdepth: 1

    K_Diagnostics/probe_wave_diagnostics
    K_Diagnostics/K01_signal_spectra
    K_Diagnostics/K02_beall
    K_Diagnostics/K03_mle_k2d
    K_Diagnostics/K04_breathing_waveform

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 概览

   ``K_Diagnostics`` 收纳从实验测量和数值模拟数据中提取物理诊断量的计算方法。
   目前提供信号频谱与相位统计、探针对波数–频率分析、多构型波矢反演，以及呼吸周期重复波形提取。
   各算法的输入要求、适用条件和输出含义由对应页面说明。

   当前算法以 Python 实现。文件组织仍遵循一个 routine 一个
   文件、``mod_`` 只做汇总的约定：``mod_`` 用 ``from ... import`` 汇总，对应 Fortran 侧的
   ``#include``。各单元的计算函数均不做文件读写；由调用方（如示例或测试主程序）提供数据并调用计算函数。

   .. list-table:: 按诊断问题选择算法
      :header-rows: 1
      :widths: 8 30 26 36

      * - ID
        - 想了解什么
        - 输入
        - 输出
      * - :doc:`K01 <K_Diagnostics/K01_signal_spectra>`
        - 信号有哪些频率成分，两路信号的相干和相位关系如何
        - 单路或两路等间隔采样的实数时序；两路分析要求采样对齐
        - 分段谱、功率谱、相干度、互相位及其均值与方差
      * - :doc:`K02 <K_Diagnostics/K02_beall>`
        - 一对探针能得到怎样的投影波数与频谱
        - 互相位、两路自功率平均、频率和间距；折叠阶计算另需已知投影波数
        - 折叠波数、``S(k, f)``；仅对已知投影波数计算折叠阶，不从单对相位恢复它
      * - :doc:`K03 <K_Diagnostics/K03_mle_k2d>`
        - 多种探针构型能否共同约束二维波矢
        - 多构型的基线向量、相位均值与方差，以及搜索范围
        - 每频点的二维波矢 ``(K_x, K_y)``

      * - :doc:`K04 <K_Diagnostics/K04_breathing_waveform>`
        - 多条重复记录中，随呼吸周期重复的波形是什么
        - 同一空间点、相同条件下的多条电压记录
        - 相位重复波形 C 与残差 R

   .. rubric:: 学习入口

   :doc:`探针波动诊断专题 <K_Diagnostics/probe_wave_diagnostics>` 按 K01 → K02 → K03 安排阅读顺序，
   介绍从探针时序到频率、投影波数和二维波矢的分析流程。基础讲解、学习路径、使用示例和测试指南均归入该专题。
   K01 的频谱工具也可单独使用；Beall 权重和相位统计的具体约定见 :doc:`K01 函数说明 <K_Diagnostics/K01_signal_spectra>`。

   :doc:`K04 呼吸波形提取 <K_Diagnostics/K04_breathing_waveform>` 是独立的学习入口，
   从人工数据逐步说明怎样从同一空间点、相同条件下的重复记录得到相位重复波形 C 与残差 R。

   .. rubric:: 相关测试

   :doc:`tests/010_diagnostics </tests/010_diagnostics/index>` 覆盖 K01–K03：一份合成宽带信号同时驱动这三个单元，
   参考真值取自生成器，验收比较谱指数、折叠波数及恢复波矢的误差。
   :doc:`基础数值测试 </tests/010_diagnostics/case_basic_checks>` 按三组比较参考值、实测值、误差和验收判据，
   覆盖频谱功率与相位、相位统计、Beall 权重与谱峰。

   :doc:`tests/011_K04_breathing_waveform </tests/011_K04_breathing_waveform/index>`：K04 的本地测试、人工示例和文档图片复现。

.. container:: ap-lang ap-lang-en

   .. rubric:: Overview

   ``K_Diagnostics`` collects computational methods that extract physical diagnostic quantities
   from experimental measurements and numerical simulation data. Current capabilities include
   signal spectra and phase statistics, probe-pair wavenumber–frequency analysis, wavevector
   inversion across configurations, and breathing-cycle waveform extraction. Each algorithm
   page specifies its input requirements, assumptions and output meanings.

   The current algorithms are written in Python. File organisation follows the convention of one routine per file with a ``mod_``
   wrapper that only aggregates: here the wrapper re-exports through ``from ... import``, the
   counterpart of the Fortran ``#include``. Numerical routines perform no file I/O;
   callers, such as example or test drivers, supply data and invoke the routines.

   .. list-table:: Choose an Algorithm by Diagnostic Question
      :header-rows: 1
      :widths: 8 30 26 36

      * - ID
        - Question
        - Input
        - Output
      * - :doc:`K01 <K_Diagnostics/K01_signal_spectra>`
        - Which frequencies are present, and how coherent are two signals and what is their phase relation?
        - One or two uniformly sampled real time series; paired analysis requires aligned samples
        - Segment spectra, power spectra, coherence, cross phase with its mean and variance
      * - :doc:`K02 <K_Diagnostics/K02_beall>`
        - What projected wavenumbers and spectrum can one probe pair measure?
        - Cross phase, mean pair auto-power, frequency and separation; fold-order calculation additionally needs a known projected wavenumber
        - Folded wavenumber and ``S(k, f)``; fold order only from a known projected wavenumber, not recovered from one pair's phase
      * - :doc:`K03 <K_Diagnostics/K03_mle_k2d>`
        - Can several probe configurations jointly constrain a two-dimensional wavevector?
        - Baseline vectors, phase means and variances for several configurations, and a search range
        - Two-dimensional wavevector ``(K_x, K_y)`` per frequency

      * - :doc:`K04 <K_Diagnostics/K04_breathing_waveform>`
        - Which waveform repeats with the breathing cycle across repeated records?
        - Repeated voltage records at one spatial point under the same conditions
        - Phase-repeatable waveform C and residual R

   .. rubric:: Learning Routes

   The :doc:`probe wave diagnostics topic <K_Diagnostics/probe_wave_diagnostics>` uses the reading order K01 → K02 → K03,
   from probe time series to frequencies, projected wavenumbers and two-dimensional wavevectors.
   It contains the foundations, learning path, usage cookbook and testing guide.
   K01 spectral tools can also be used independently; see the :doc:`K01 reference <K_Diagnostics/K01_signal_spectra>`
   for the specific Beall weighting and phase-statistics conventions.

   :doc:`K04 breathing waveform extraction <K_Diagnostics/K04_breathing_waveform>` provides a separate learning route.
   Artificial data illustrate how repeated records at one spatial point under the same conditions
   yield a phase-repeatable waveform C and a residual R.

   .. rubric:: Related Tests

   :doc:`tests/010_diagnostics </tests/010_diagnostics/index>` covers K01–K03: one synthetic broadband dataset
   drives these three units. Reference values come from the generator; acceptance uses explicit
   numerical tolerances for spectral slope, folded wavenumbers and recovered wavevectors.
   :doc:`basic_numerical tests </tests/010_diagnostics/case_basic_checks>` compare references, measured values,
   errors and acceptance rules in three groups: spectral power and phase, phase statistics,
   and Beall weights and peaks.

   :doc:`tests/011_K04_breathing_waveform </tests/011_K04_breathing_waveform/index>`:
   K04 local tests, artificial examples and documentation figure reproduction.
