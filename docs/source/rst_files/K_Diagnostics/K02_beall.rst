=========
K02_beall
=========

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   * :doc:`mod_K02_beall.py <K02_beall/mod_K02_beall>`:

       ``mod_K02_beall`` 是 K02 的模块入口，汇总混叠折叠代数与 Beall 谱的全部 routine。

       汇总的 routine 分两组：几何与折叠代数（``separation_vector``、``separation_magnitude``、``nyquist_wavenumber``、``project_wavenumber``、``fold_order``、``fold_wavenumber``），以及谱的构造与读取（``wavenumber_edges``、``beall_wavenumber``、``beall_spectrum``、``peak_wavenumber``、``wavenumber_residual``）。

   * :doc:`fun_K02_fold_wavenumber.py <K02_beall/fun_K02_fold_wavenumber>`:

       ``fun_K02_fold_wavenumber`` 给出单对探针实际会报出的波数：相位只能被观测到模 :math:`2\pi`，越过 :math:`\pi/|\boldsymbol{\chi}|` 的色散支被折回，在 Beall 图上表现为重复的锯齿。它与 ``fun_K02_fold_order`` 一起构成本单元的闭式预言。

   * :doc:`fun_K02_beall_spectrum.py <K02_beall/fun_K02_beall_spectrum>`:

       ``fun_K02_beall_spectrum`` 累积 :math:`S(k,f)`：每个 (分段, 频点) 样本按两路自功率平均加权投进一个波数格。这是**统计**估计器，不相干的分段散开、相干的堆叠，因此需要的分段数远多于求一个均值相位所需。

   * :doc:`fun_K02_wavenumber_residual.py <K02_beall/fun_K02_wavenumber_residual>`:

       ``fun_K02_wavenumber_residual`` 用于把实测峰位与闭式预言作比较。波数轴以 :math:`2\pi/|\boldsymbol{\chi}|` 为周期，直接相减会在贴近 Nyquist 边时报出整整一个周期的假误差。

   * :doc:`fun_K02_nyquist_wavenumber.py <K02_beall/fun_K02_nyquist_wavenumber>`:

       ``fun_K02_nyquist_wavenumber`` 给出该间距的硬限制 :math:`\pi/|\boldsymbol{\chi}|`，当基线平行于传播方向时，首次混叠频率为 :math:`v/(2|\boldsymbol{\chi}|)`，完整折叠周期为 :math:`v/|\boldsymbol{\chi}|`。占用的折叠阶数应按生成模态计数；斜向基线还需考虑投影。

      * :doc:`fun_K02_separation_vector.py <K02_beall/fun_K02_separation_vector>`:

       ``fun_K02_separation_vector`` 与 ``fun_K02_separation_magnitude`` 是几何的两个基础件：前者由间距和方位角构造 :math:`\boldsymbol{\chi}`，后者给出其长度并集中做形状、有限性与零长度校验。间距的指向决定了整个模块族的符号约定。

   * :doc:`fun_K02_separation_magnitude.py <K02_beall/fun_K02_separation_magnitude>`:

       见上一条；本单元每个 routine 都经它取 :math:`|\boldsymbol{\chi}|`。

   * :doc:`fun_K02_project_wavenumber.py <K02_beall/fun_K02_project_wavenumber>`:

       ``fun_K02_project_wavenumber`` 给出 :math:`\mathbf{K}\cdot\hat{\boldsymbol{\chi}}`，即一对探针唯一可能携带信息的那个分量；垂直分量完全不进入测量。

   * :doc:`fun_K02_fold_order.py <K02_beall/fun_K02_fold_order>`:

       ``fun_K02_fold_order`` 从已知投影波数计算折叠阶数 :math:`n`，用于比较理论波数与主值区间内的折叠波数。

   * :doc:`fun_K02_wavenumber_edges.py <K02_beall/fun_K02_wavenumber_edges>`:

       ``fun_K02_wavenumber_edges`` 与 ``fun_K02_beall_wavenumber`` 为谱的构造做准备：前者张成恒定的 :math:`\pm\pi/|\boldsymbol{\chi}|` 范围，后者把相位换算为该范围内的波数。

   * :doc:`fun_K02_beall_wavenumber.py <K02_beall/fun_K02_beall_wavenumber>`:

       见上一条。

   * :doc:`fun_K02_peak_wavenumber.py <K02_beall/fun_K02_peak_wavenumber>`:

       ``fun_K02_peak_wavenumber`` 从 :math:`S(k,f)` 读出每个频点的谱峰。它取的是直方图最大值，即有限样本下的众数，精度不等于格宽。

   .. rubric:: 测试

   相关测试说明见 :doc:`010_diagnostics 测试 </tests/010_diagnostics/index>`。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>


.. container:: ap-lang ap-lang-en

   * :doc:`mod_K02_beall.py <K02_beall/mod_K02_beall>`:

       ``mod_K02_beall`` is the module entry of K02, collecting the folding algebra and the Beall spectrum.

       The routines fall in two groups: geometry and folding (``separation_vector``, ``separation_magnitude``, ``nyquist_wavenumber``, ``project_wavenumber``, ``fold_order``, ``fold_wavenumber``), and building and reading the spectrum (``wavenumber_edges``, ``beall_wavenumber``, ``beall_spectrum``, ``peak_wavenumber``, ``wavenumber_residual``).

   * :doc:`fun_K02_fold_wavenumber.py <K02_beall/fun_K02_fold_wavenumber>`:

       ``fun_K02_fold_wavenumber`` gives the wavenumber a single pair actually reports: the phase is observable only modulo :math:`2\pi`, so a branch running past :math:`\pi/|\boldsymbol{\chi}|` folds back and appears as a repeating sawtooth on the Beall map. With ``fun_K02_fold_order`` it forms the closed-form prediction of the unit.

   * :doc:`fun_K02_beall_spectrum.py <K02_beall/fun_K02_beall_spectrum>`:

       ``fun_K02_beall_spectrum`` accumulates :math:`S(k,f)`: each (segment, frequency) sample is weighted by the mean of the two auto-powers and dropped into one wavenumber bin. It is a **statistical** estimator in which incoherent segments spread out and coherent ones pile up, so it needs many more segments than a mean phase does.

   * :doc:`fun_K02_wavenumber_residual.py <K02_beall/fun_K02_wavenumber_residual>`:

       ``fun_K02_wavenumber_residual`` compares a measured peak with the closed-form prediction. The wavenumber axis is periodic with period :math:`2\pi/|\boldsymbol{\chi}|`, so a plain difference reports a full period of spurious error near a Nyquist edge.

   * :doc:`fun_K02_nyquist_wavenumber.py <K02_beall/fun_K02_nyquist_wavenumber>`:

       ``fun_K02_nyquist_wavenumber`` gives the hard limit :math:`\pi/|\boldsymbol{\chi}|` of a separation, with first alias frequency :math:`v/(2|\boldsymbol{\chi}|)` when aligned with propagation. The full fold period is :math:`v/|\boldsymbol{\chi}|`. Count occupied orders from the generated modes; oblique baselines also require projection.

      * :doc:`fun_K02_separation_vector.py <K02_beall/fun_K02_separation_vector>`:

       ``fun_K02_separation_vector`` and ``fun_K02_separation_magnitude`` are the two geometric primitives: the first builds :math:`\boldsymbol{\chi}` from a spacing and an orientation, the second returns its length and performs the shape, finiteness and zero-length checks once. The sense of the separation fixes the sign convention of the whole module family.

   * :doc:`fun_K02_separation_magnitude.py <K02_beall/fun_K02_separation_magnitude>`:

       See the entry above; every routine in this unit takes :math:`|\boldsymbol{\chi}|` through it.

   * :doc:`fun_K02_project_wavenumber.py <K02_beall/fun_K02_project_wavenumber>`:

       ``fun_K02_project_wavenumber`` returns :math:`\mathbf{K}\cdot\hat{\boldsymbol{\chi}}`, the only component a pair can carry information about; the perpendicular component never enters the measurement.

   * :doc:`fun_K02_fold_order.py <K02_beall/fun_K02_fold_order>`:

       ``fun_K02_fold_order`` computes the fold order :math:`n` from a known projected wavenumber, for comparing theoretical wavenumbers with their values in the principal interval.

   * :doc:`fun_K02_wavenumber_edges.py <K02_beall/fun_K02_wavenumber_edges>`:

       ``fun_K02_wavenumber_edges`` and ``fun_K02_beall_wavenumber`` prepare the spectrum: the first spans the fixed :math:`\pm\pi/|\boldsymbol{\chi}|` range, the second converts a phase into a wavenumber inside it.

   * :doc:`fun_K02_beall_wavenumber.py <K02_beall/fun_K02_beall_wavenumber>`:

       See the entry above.

   * :doc:`fun_K02_peak_wavenumber.py <K02_beall/fun_K02_peak_wavenumber>`:

       ``fun_K02_peak_wavenumber`` reads the peak of :math:`S(k,f)` at each frequency. It takes the histogram maximum, a finite-sample mode whose accuracy is not the bin width.

   .. rubric:: Tests

   See :doc:`010_diagnostics tests </tests/010_diagnostics/index>` for the reference case and figures.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>


.. toctree::
    :maxdepth: 1
    :hidden:

    K02_beall/mod_K02_beall
    K02_beall/fun_K02_beall_spectrum
    K02_beall/fun_K02_beall_wavenumber
    K02_beall/fun_K02_fold_order
    K02_beall/fun_K02_fold_wavenumber
    K02_beall/fun_K02_nyquist_wavenumber
    K02_beall/fun_K02_peak_wavenumber
    K02_beall/fun_K02_project_wavenumber
    K02_beall/fun_K02_separation_magnitude
    K02_beall/fun_K02_separation_vector
    K02_beall/fun_K02_wavenumber_edges
    K02_beall/fun_K02_wavenumber_residual
