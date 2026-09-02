===========
K03_mle_k2d
===========

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   * :doc:`mod_K03_mle_k2d.py <K03_mle_k2d/mod_K03_mle_k2d>`:

       ``mod_K03_mle_k2d`` 是 K03 的模块入口，汇总二维波矢联合反演的全部 routine。

       汇总的 routine：``wavenumber_grid``、``predicted_phase``、``config_log_likelihood``、``joint_log_likelihood``、``peak_wavevector``、``search_wavevector``。

   * :doc:`fun_K03_joint_log_likelihood.py <K03_mle_k2d/fun_K03_joint_log_likelihood>`:

       ``fun_K03_joint_log_likelihood`` 是本单元的核心。单构型的似然是一族平行条纹，在垂直于 :math:`\boldsymbol{\chi}` 的方向上严格不变、沿该方向以 :math:`2\pi/|\boldsymbol{\chi}|` 为周期；多构型求和使条纹族相交，而不同**间距长度**的周期不可通约，这才能定出唯一的折叠阶数。

   * :doc:`fun_K03_config_log_likelihood.py <K03_mle_k2d/fun_K03_config_log_likelihood>`:

       ``fun_K03_config_log_likelihood`` 给出单构型的贡献。残差在平方前先折算——正是这一步使混叠构型贡献出周期性的一族脊而非单条脊，混叠信息因而保留在似然里、可以被其他构型解出。

   * :doc:`fun_K03_search_wavevector.py <K03_mle_k2d/fun_K03_search_wavevector>`:

       ``fun_K03_search_wavevector`` 处理宽频带：波数跨越一个数量级以上时，单一均匀网格既要够到最大波矢又要分辨最小波矢，无法两全，因此先全域粗搜、再在粗峰附近细化。

   * :doc:`fun_K03_predicted_phase.py <K03_mle_k2d/fun_K03_predicted_phase>`:

       ``fun_K03_predicted_phase`` 与 ``fun_K03_wavenumber_grid``、``fun_K03_peak_wavevector`` 是搜索的三个基础件：分别给出前向模型、搜索网格和峰位读取。前向模型不依赖频率，同一几何上扫多个频点时应只算一次。

      * :doc:`fun_K03_wavenumber_grid.py <K03_mle_k2d/fun_K03_wavenumber_grid>`:

       ``fun_K03_wavenumber_grid`` 与 ``fun_K03_peak_wavevector`` 是搜索的两端：前者给出均匀网格，后者从似然读出峰位并同时返回直角与极坐标形式。估计值被限制在网格上，精度有半个网格步长的下限。

   * :doc:`fun_K03_peak_wavevector.py <K03_mle_k2d/fun_K03_peak_wavevector>`:

       见上一条。

   .. rubric:: 测试

   相关测试说明见 :doc:`010_diagnostics 测试 </tests/010_diagnostics/index>`。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>


.. container:: ap-lang ap-lang-en

   * :doc:`mod_K03_mle_k2d.py <K03_mle_k2d/mod_K03_mle_k2d>`:

       ``mod_K03_mle_k2d`` is the module entry of K03, collecting the joint two-dimensional inversion.

       Collected routines: ``wavenumber_grid``, ``predicted_phase``, ``config_log_likelihood``, ``joint_log_likelihood``, ``peak_wavevector``, ``search_wavevector``.

   * :doc:`fun_K03_joint_log_likelihood.py <K03_mle_k2d/fun_K03_joint_log_likelihood>`:

       ``fun_K03_joint_log_likelihood`` is the core of the unit. A single configuration's likelihood is a family of parallel fringes, exactly invariant perpendicular to :math:`\boldsymbol{\chi}` and periodic along it with period :math:`2\pi/|\boldsymbol{\chi}|`; summing intersects those families, and only separations of different **length** have incommensurate periods and can fix the fold order.

   * :doc:`fun_K03_config_log_likelihood.py <K03_mle_k2d/fun_K03_config_log_likelihood>`:

       ``fun_K03_config_log_likelihood`` supplies the contribution of one configuration. The residual is wrapped before squaring, and that step is what makes an aliased configuration contribute a periodic family of ridges rather than a single one, so the folded information stays in the likelihood and can be resolved by the others.

   * :doc:`fun_K03_search_wavevector.py <K03_mle_k2d/fun_K03_search_wavevector>`:

       ``fun_K03_search_wavevector`` handles a wide band: once the wavenumbers span more than a decade a single uniform grid cannot both reach the largest and resolve the smallest, so the search runs coarse over the whole range and then fine around the coarse peak.

   * :doc:`fun_K03_predicted_phase.py <K03_mle_k2d/fun_K03_predicted_phase>`:

       ``fun_K03_predicted_phase``, ``fun_K03_wavenumber_grid`` and ``fun_K03_peak_wavevector`` are the three building blocks of the search: the forward model, the grid, and the reading of the peak. The forward model does not depend on frequency and should be built once per geometry.

      * :doc:`fun_K03_wavenumber_grid.py <K03_mle_k2d/fun_K03_wavenumber_grid>`:

       ``fun_K03_wavenumber_grid`` and ``fun_K03_peak_wavevector`` are the two ends of the search: the uniform grid, and the reading of the peak in both Cartesian and polar form. The estimate is confined to the grid, so the accuracy has a floor of half a grid step.

   * :doc:`fun_K03_peak_wavevector.py <K03_mle_k2d/fun_K03_peak_wavevector>`:

       See the entry above.

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

    K03_mle_k2d/mod_K03_mle_k2d
    K03_mle_k2d/fun_K03_config_log_likelihood
    K03_mle_k2d/fun_K03_joint_log_likelihood
    K03_mle_k2d/fun_K03_peak_wavevector
    K03_mle_k2d/fun_K03_predicted_phase
    K03_mle_k2d/fun_K03_search_wavevector
    K03_mle_k2d/fun_K03_wavenumber_grid
