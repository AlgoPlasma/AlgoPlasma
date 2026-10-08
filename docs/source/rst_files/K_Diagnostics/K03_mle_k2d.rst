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

       每条基线通过相位差约束波矢沿该方向的投影。将多个构型的对数似然相加，可以在二维波数平面上寻找共同支持的波矢。基线的方向和长度共同决定相位条纹的交汇位置。

   * :doc:`fun_K03_config_log_likelihood.py <K03_mle_k2d/fun_K03_config_log_likelihood>`:

       ``fun_K03_config_log_likelihood`` 给出单构型的贡献。残差在平方前先折算——正是这一步使混叠构型贡献出周期性的一族脊而非单条脊，混叠信息因而保留在似然里、可以被其他构型解出。

   * :doc:`fun_K03_search_wavevector.py <K03_mle_k2d/fun_K03_search_wavevector>`:

       在给定的二维波数范围内建立均匀网格，计算各网格点的联合对数似然，取最大值对应的波矢作为估计结果。n_grid 指定每个坐标轴的点数，block_rows 指定每批计算的网格行数。

   * :doc:`fun_K03_predicted_phase.py <K03_mle_k2d/fun_K03_predicted_phase>`:

       ``fun_K03_predicted_phase`` 与 ``fun_K03_wavenumber_grid``、``fun_K03_peak_wavevector`` 是搜索的三个基础件：分别给出前向模型、搜索网格和峰位读取。前向模型不依赖频率，同一几何上扫多个频点时应只算一次。

      * :doc:`fun_K03_wavenumber_grid.py <K03_mle_k2d/fun_K03_wavenumber_grid>`:

       ``fun_K03_wavenumber_grid`` 与 ``fun_K03_peak_wavevector`` 是搜索的两端：前者给出均匀网格，后者从似然读出峰位并同时返回直角与极坐标形式。估计值被限制在网格上，精度与网格分辨率及混叠分支选择有关。

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

       Each baseline constrains the wavevector projection along its direction through the measured phase difference. Summing the configurations' log likelihoods locates jointly supported wavevectors in the two-dimensional wavenumber plane. Baseline directions and lengths determine where the phase fringes intersect.

   * :doc:`fun_K03_config_log_likelihood.py <K03_mle_k2d/fun_K03_config_log_likelihood>`:

       ``fun_K03_config_log_likelihood`` supplies the contribution of one configuration. The residual is wrapped before squaring, and that step is what makes an aliased configuration contribute a periodic family of ridges rather than a single one, so the folded information stays in the likelihood and can be resolved by the others.

   * :doc:`fun_K03_search_wavevector.py <K03_mle_k2d/fun_K03_search_wavevector>`:

       Build a uniform grid over the chosen two-dimensional wavenumber range, evaluate the joint log likelihood at every point, and report the wavevector at its maximum. n_grid sets the number of points per axis; block_rows sets the number of rows evaluated in each batch.

   * :doc:`fun_K03_predicted_phase.py <K03_mle_k2d/fun_K03_predicted_phase>`:

       ``fun_K03_predicted_phase``, ``fun_K03_wavenumber_grid`` and ``fun_K03_peak_wavevector`` are the three building blocks of the search: the forward model, the grid, and the reading of the peak. The forward model does not depend on frequency and should be built once per geometry.

      * :doc:`fun_K03_wavenumber_grid.py <K03_mle_k2d/fun_K03_wavenumber_grid>`:

       ``fun_K03_wavenumber_grid`` and ``fun_K03_peak_wavevector`` are the two ends of the search: the uniform grid, and the reading of the peak in both Cartesian and polar form. The estimate is confined to the grid, so the accuracy depends on grid resolution and alias selection.

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
