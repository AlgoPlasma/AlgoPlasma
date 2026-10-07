J03 Application Tests
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 1. 完整算例检查什么

   小规模串联测试通过后，应用测试将相同调用过程用于 256×256 的器件网格。
   分别执行 FM B0、SN B0 和 SN ION：前处理生成参考密度与面通量，
   J03 由这些数据建立闭合，从参考密度开始推进至平衡。
   验收包括前处理完成状态、密度有效性、连续性残差及全域粒子收支；
   图片展示每条计算路线在两个阶段的密度。

   计算采用 r-z 空间和两个速度分量 :math:`(v_r,v_z)` 的约化模型。
   SN 的角方向在这一速度平面内，J03 推进单元中的标量密度。

   .. list-table:: 输入条件
      :header-rows: 1
      :widths: 27 73

      * - 参数
        - 设置
      * - 网格和有效区域
        - 256×256；有效单元为 (65:192,1:72) 与 (:,73:256)，共 56,320 个
      * - 入口
        - 轴向低端面，径向范围 0.0151837363–0.0232205007 m
      * - 入口密度参数
        - :math:`5.0\times10^{18}\ {\rm m}^{-3}`，用于注入通量归一化
      * - 入口与壁温；轴向漂移
        - 550 K；300 m/s
      * - 反射
        - 漫反射比例 0.7，镜面反射比例 0.3
      * - 入射速度
        - 入射粒子的速度采用截断漂移高斯分布
      * - 体源和损失
        - 体源为零；B0 无损失，ION 使用下述给定电离频率
      * - 前处理规模
        - FM：240 万条粒子历史；SN：400 个角方向、16 个速率区间

   .. rubric:: 2. 先检查算例配置与验收程序

   四个应用驱动共用 ``application_case.f90``。
   普通 J03 测试脚本中的 ``test_application_case.f90`` 先单独检查它：

   * ``build_case_mask``：有效单元数应为
     :math:`128\times72+256\times184=56320`；
     (64,72) 无效，(65,72) 与 (1,73) 有效，验证通道与外部区域的接合位置。
   * ``build_case_loss``：在损失窗口中心应得到
     :math:`10^5\ {\rm s}^{-1}`，绝对误差小于 :math:`10^{-8}\ {\rm s}^{-1}`；
     B0、无效单元和窗口外的损失应为零。

   ION 损失窗口为
   :math:`r\in[0.013683098220475191,0.024672244366128356]\ {\rm m}`、
   :math:`z\in[0.0024709824265487373,0.010022411397665104]\ {\rm m}`。
   记窗口中心为 :math:`(r_c,z_c)`，宽度为 :math:`L_r,L_z`，
   在有效单元中心计算

   .. math::

      \nu(r,z)=10^5
      \cos\!\left(\frac{\pi(r-r_c)}{L_r}\right)
      \cos\!\left(\frac{\pi(z-z_c)}{L_z}\right)\ {\rm s}^{-1}.

   窗口中心的两个余弦均为 1，因此峰值可以直接核对；窗口外置零。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 有效单元数
        - 56320
        - 56320
        - 0
        - 精确相等
      * - 窗口中心电离频率 / s⁻¹
        - 100000
        - 100000
        - 0
        - 1e−8
      * - B0 / 无效单元 / 窗口外频率
        - 0 / 0 / 0
        - 0 / 0 / 0
        - 0
        - 精确零值

   区域接合处三个掩码值实际为 F、T、T，与配置的索引范围一致。

   ``test_application_checks.py`` 检查本仓库的输入校验和结果验收工具，共 9 项测试：
   合法网格、缺失或空网格、有效区密度、SN→J03 驱动拒绝非法参考密度、
   平衡收支、失衡收支、大残差、缺失或非有限诊断、负粒子率。
   例如给定入射率 3、出射率 2、体源率 1、损失率 2，应满足
   :math:`2+2-3-1=0`；将出射率改为 1 后必须判失败。
   将有效单元密度改为负数、NaN 或无穷大，应报告具体单元位置。

   .. code-block:: bash

      cd tests/012_fluid/J03_neutral_continuity_faceflux_2Drz
      bash application_reference/make.sh
      python3 -m unittest -v test_application_checks.py

   这组检查使用临时小数组和合成文件，检查结束后删除临时数据。
   其中 Fortran 驱动检查需要先编译；未编译时该项会标为跳过。
   2026-10-06 的记录为 9 项全部通过、无跳过。

   .. rubric:: 3. 完整运行的调用与数据传递

   以下目录均位于 ``tests/012_fluid/J03_neutral_continuity_faceflux_2Drz``。

   .. list-table::
      :header-rows: 1
      :widths: 18 41 41

      * - 顺序
        - FM B0
        - SN B0 / ION
      * - 校验和编译
        - ``application_reference_J01/run.sh`` 检查网格，编译两个驱动
        - ``application_reference/run_application_reference.sh`` 检查网格和算例名，编译两个驱动
      * - 前处理
        - ``run_J01_application_reference.f90`` 调用 ``sub_J01_free_molecular_mc_2Drz``，执行采样、跟踪和统计
        - ``run_J02_application_reference.f90`` 设置网格、求积、入口、损失与壁面，调用 ``sub_J02_solve_transport``
      * - 接入 J03
        - ``run_J03_from_J01_reference.f90`` 读取 J01 的参考密度与面通量
        - ``run_J03_application_reference.f90`` 读取 J02 的参考密度与面通量
      * - 连续性计算
        - ``sub_J03_initialize_transport_closure`` 建立面系数；``sub_J03_solve_steady`` 反复推进密度
        - 同样建立闭合并推进；ION 同时使用给定的体损失频率
      * - 验收和出图
        - ``plot_application.py FM ...`` 读取本次输出，写出验收结果和双幅密度图
        - ``plot_application.py SN ...`` 完成相同检查和出图

   前处理与 J03 通过以下文件传递数据。文件名中的 ``face_flux`` 表示粒子通量，
   J03 用它与参考密度构造面输运系数。

   .. list-table::
      :header-rows: 1
      :widths: 45 55

      * - 文件（相对于一次运行的输出目录）
        - 数据用途
      * - ``j01/na_j01_rz_f64.bin`` 或 ``j02/na_sn_rz_f64.bin``
        - 前处理参考密度，作为闭合参考和本应用的初值
      * - ``j01/`` 或 ``j02/`` 下的 ``ur_face_flux_f64.bin``、``uz_face_flux_f64.bin``
        - 径向、轴向内部面通量
      * - 同目录的 ``boundary_inflow_flux_f64.bin``、``boundary_outflow_flux_f64.bin``
        - 开放边界的入射、出射通量
      * - ``j03/na_cont_rz_f64.bin``、``j03/j03_run_summary.txt``
        - 连续性密度、收敛状态、残差和各项粒子率
      * - 输出根目录的 ``summary.txt`` 和 ``j01_chain_density.png`` 或 ``j02_chain_density.png``
        - 最终 PASS/FAIL 及前处理、J03 密度图

   .. rubric:: 4. 自动通过条件

   设 :math:`Q_{\rm in},Q_{\rm out},Q_S,Q_\nu` 分别为全域入射、出射、
   体产生和体损失粒子率，稳态粒子收支误差为

   .. math::

      E_Q=\frac{|Q_{\rm out}+Q_\nu-Q_{\rm in}-Q_S|}
                  {\max(Q_{\rm in}+Q_S,\ Q_{\rm out}+Q_\nu,\ \epsilon_{\rm tiny})}.

   分子检查总收支，分母取流入端或流出端的较大粒子率；
   :math:`\epsilon_{\rm tiny}` 仅用于避免零分母。
   ``plot_application.py::assess_balance`` 按此式验收。

   .. list-table::
      :header-rows: 1
      :widths: 30 42 28

      * - 检查项
        - 条件
        - 数据或检查位置
      * - 前处理完成
        - FM 截断历史数为零；SN 反射迭代已收敛
        - ``j01_fm_summary.txt`` / ``j02_run_summary.txt``
      * - 两阶段密度
        - 全部有效单元密度有限且非负
        - ``validate_density``
      * - J03 收敛
        - 相邻步相对变化 ≤ :math:`10^{-10}`，缩放局部残差 ≤ :math:`10^{-8}`
        - 求解器同时检查，验收工具核对收敛标志和残差
      * - 全域收支
        - :math:`E_Q\le10^{-6}`
        - ``assess_balance``

   另外记录两个阶段的密度差异

   .. math::

      E_n=\frac{\|n_{\rm J03}-n_{\rm pre}\|_2}{\|n_{\rm pre}\|_2},

   求和限于有效单元。:math:`E_n` 用于描述参考场在连续性推进中的变化，
   没有独立的自动通过阈值。若参考场已满足同一离散平衡，且密度下限未改变面系数，
   J03 应保持该场；实际变化还可能来自低密度处理和有限的迭代误差。

   .. rubric:: 5. 本次应用结果与图片

   以下结果均来自 2026-10-06 的完整运行。修正 J01 的近角点穿面计数后，
   FM B0 已在 ``fluid-fix-20261006-233223/FM_B0`` 重新执行前处理和 J03。
   SN B0、ION 保留 ``fluid-20261006-192111`` 中的结果：本次未修改 J02、J03 数值实现，
   其日志确认使用 4 个 OpenMP 线程，未启用空间 MPI。下方图片与各自结果记录一致。

   除核对摘要外，还读取了保存的二进制密度与面通量：
   56,320 个有效单元的掩码全部正确，所有输出场有限，两阶段密度非负。
   按柱坐标面积重新积分边界粒子率，并由面系数重新计算 J03 局部残差，
   与程序摘要一致；粒子率的相对差异不超过 :math:`9.3\times10^{-16}`。
   这里核对的是计算结果与输出文件的一致性，不是独立的物理模型验证。

   .. list-table:: 前处理完成情况
      :header-rows: 1

      * - 算例
        - 完成量
        - 最终判据
        - 要求
      * - FM B0
        - 2,400,000 条完整历史
        - 截断 0 条
        - 无截断
      * - SN B0
        - 20 轮反射迭代
        - 相对变化 7.138210094e−7
        - ≤ 1e−6
      * - SN ION
        - 15 轮反射迭代
        - 相对变化 8.392788118e−7
        - ≤ 1e−6

   .. figure:: /_static/J_Fluid/application_reference/sn_iteration_zh.svg
      :width: 100%
      :align: center

      相对变化按全部分布系数计算。B0 在第 20 轮、ION 在第 15 轮低于 1e−6。
      此图展示真实迭代记录；不是各单元扫描时的密度变化。

   下表诊断量取五位有效数字；完整精度数值保存在本页附带记录中。

   .. list-table:: J03 收敛和粒子收支
      :header-rows: 1

      * - 算例
        - 步数
        - 相邻步变化
        - 缩放残差
        - :math:`E_Q`
        - :math:`E_n`
      * - FM B0
        - 10675
        - 4.9759e−11
        - 9.9979e−9
        - 7.4834e−8
        - 3.6405e−3
      * - SN B0
        - 3647
        - 9.9958e−11
        - 4.2844e−9
        - 2.2322e−7
        - 3.0252e−6
      * - SN ION
        - 6223
        - 2.8193e−11
        - 9.9953e−9
        - 4.6204e−8
        - 3.4498e−6
      * - 通过上限
        - —
        - 1e−10
        - 1e−8
        - 1e−6
        - 仅作诊断

   .. list-table:: J03 全域粒子率（单位：s⁻¹）
      :header-rows: 1

      * - 算例
        - 入射
        - 逸出
        - 体损失
      * - FM B0
        - 1.559283997e18
        - 1.559283880e18
        - 0
      * - SN B0
        - 1.559274509e18
        - 1.559274857e18
        - 0
      * - SN ION
        - 1.559274509e18
        - 5.902672612e17
        - 9.690071754e17

   ION 的逸出与体损失相加后等于入射，误差见 :math:`E_Q`；全部算例的体产生为零。
   FM 前处理采用 :math:`\Theta=1/3` 弧度扇区，J03 按 :math:`2\pi` 积分总粒子率。
   前处理输出为单位体积密度和单位面积通量，无需乘周向换算因子；
   只有总粒子率需按 :math:`2\pi/(1/3)=6\pi` 换算后才能核对。

   :download:`完整数值和文件校验值 <records/application_tests_2026-10-06.json>`
   保存了密度范围、摘要、独立重算结果、逐轮变化量及输出文件 SHA-256。
   FM 复跑前已保存源码和脚本的逐文件校验值；记录中注明其位置与汇总校验值。
   SN 原运行没有保存编译时源码校验值，历史可执行文件的版本无法事后完整追溯。

   .. figure:: /_static/J_Fluid/application_reference/j01_chain_density.png
      :width: 92%
      :align: center

      FM B0：左为 J01 前处理密度，右为对应的 J03 平衡密度。240 万条历史全部完成。

   .. figure:: /_static/J_Fluid/application_reference/j02_chain_density.png
      :width: 92%
      :align: center

      SN B0：左为 J02 前处理密度，右为对应的 J03 平衡密度。

   .. figure:: /_static/J_Fluid/application_reference/j02_ion_chain_density.png
      :width: 92%
      :align: center

      SN ION：左为含电离损失的 J02 密度，右为对应的 J03 平衡密度。

   每对图片共用色标，密度单位为 :math:`{\rm m}^{-3}`，白色表示无效区域。
   两个 SN 算例启用了局部常数（P0）保正回退：保持局部粒子收支，
   同时增加回退单元的数值扩散。空间精度由小规模解析输运及网格加密测试另行检查。

   .. rubric:: 6. 运行命令与输出位置

   在仓库根目录、已安装 NumPy 与 Matplotlib 的 Python 环境中运行：

   .. code-block:: bash

      cd ~/algoplasma
      source ~/.venv/bin/activate
      test_root=tests/012_fluid/J03_neutral_continuity_faceflux_2Drz
      run_dir="$HOME/algoplasma-runs/fluid-$(date +%Y%m%d-%H%M%S)"
      mkdir -p "$run_dir"
      export OPENMP=1 OMP_NUM_THREADS=4 OMP_DYNAMIC=FALSE

      APPLICATION_OUTPUT="$run_dir/FM_B0" bash "$test_root/application_reference_J01/run.sh"
      APPLICATION_OUTPUT="$run_dir/SN_B0" bash "$test_root/application_reference/run_application_reference.sh" B0
      APPLICATION_OUTPUT="$run_dir/SN_ION" bash "$test_root/application_reference/run_application_reference.sh" ION

   三项依次运行，上一项显示 ``RESULT: PASS`` 后再执行下一项。
   SN 使用 4 个 OpenMP 线程，FM 仍按当前串行实现执行。
   输出保存在本次新建的 ``run_dir`` 下；每项均重新运行前处理和 J03，
   并写出 ``summary.txt``、分阶段 ``run.log`` 和密度图。
   在同一终端执行 ``echo "$run_dir"`` 可查看本次输出根目录。

   默认网格位于 ``application_inputs``。指定其他网格目录时，FM 使用第一个参数，
   SN 使用第二个参数；该目录需含 ``grid_r.dat``、``grid_z.dat``，
   并采用相同的 256×256 区域索引。

   默认输出位置分别为：

   * FM B0：``application_reference_J01/build/output_B0``。
   * SN B0 / ION：``application_reference/build/application_reference/output_B0`` 或 ``output_ION``。

   已有非空输出目录会阻止运行，以免覆盖结果。复跑时指定新目录，例如：

   .. code-block:: bash

      APPLICATION_OUTPUT=/tmp/algoplasma_sn_B0_new bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/application_reference/run_application_reference.sh B0

   各阶段的 ``run.log`` 显示进度，根目录 ``summary.txt`` 给出最终验收结果。
   J03 测试目录的 ``clean.sh`` 会删除默认构建和运行输出；
   需要保留的结果应放在仓库外的 ``APPLICATION_OUTPUT`` 目录。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: 1. Setup and purpose

   The application tests extend the small coupling tests to a 256×256 device mesh.
   FM B0, SN B0 and SN ION each produce their own reference density and face fluxes.
   J03 builds its closure and advances from the reference density to equilibrium.
   The reduced model uses r-z space and two velocity components.

   The active regions are (65:192,1:72) and (:,73:256), totaling 56,320 cells.
   The z-low inlet spans r = 0.0151837363–0.0232205007 m. Its density parameter is
   :math:`5\times10^{18}\ {\rm m}^{-3}`, inlet/wall temperature 550 K, axial drift
   300 m/s, and diffuse fraction 0.7. Incident velocities follow a truncated
   drifting Gaussian. FM uses 2.4 million histories; SN uses 400 angles and
   16 speed intervals. B0 has zero volume source and loss; ION adds prescribed loss.

   .. rubric:: 2. Configuration and acceptance unit tests

   ``test_application_case.f90`` checks ``application_case.f90``: the exact active
   count, channel/plume junction indices, ION peak and zero loss for B0, inactive
   cells and cells outside the window. Inside the window,

   .. math::

      \nu(r,z)=10^5\cos\!\left(\frac{\pi(r-r_c)}{L_r}\right)
                     \cos\!\left(\frac{\pi(z-z_c)}{L_z}\right)\ {\rm s}^{-1}.

   The bounds are r = [0.013683098220475191, 0.024672244366128356] m and
   z = [0.0024709824265487373, 0.010022411397665104] m.
   At the centre, the expected peak is :math:`10^5`, checked within :math:`10^{-8}`.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - Active cells
        - 56320
        - 56320
        - 0
        - exact
      * - ION peak / s⁻¹
        - 100000
        - 100000
        - 0
        - 1e−8
      * - B0 / inactive / outside loss
        - 0 / 0 / 0
        - 0 / 0 / 0
        - 0
        - exact

   ``test_application_checks.py`` contains nine checks for grids, finite/nonnegative
   active densities, the SN-to-J03 driver's rejection of invalid reference density,
   balanced and unbalanced rates, residual limits, missing/nonfinite diagnostics
   and negative rates. For example, inflow 3, outflow 2, production 1 and removal 2
   satisfy 2+2−3−1=0; changing outflow to 1 must fail.

   .. code-block:: bash

      cd tests/012_fluid/J03_neutral_continuity_faceflux_2Drz
      bash application_reference/make.sh
      python3 -m unittest -v test_application_checks.py

   The driver test is skipped if its executable is absent. All nine passed without
   skips on 2026-10-06.

   .. rubric:: 3. Production calls and file handoff

   The FM runner calls ``sub_J01_free_molecular_mc_2Drz``. The SN runner prepares
   the mesh, quadrature, inlet, loss and walls, then calls ``sub_J02_solve_transport``.
   The two J03 drivers read the resulting fields, call
   ``sub_J03_initialize_transport_closure`` and ``sub_J03_solve_steady``,
   and write density and diagnostics. ``plot_application.py`` validates and plots
   the current run.

   Reference densities are ``j01/na_j01_rz_f64.bin`` or ``j02/na_sn_rz_f64.bin``.
   Internal flux files are ``ur_face_flux_f64.bin`` and ``uz_face_flux_f64.bin``;
   boundary files are ``boundary_inflow_flux_f64.bin`` and
   ``boundary_outflow_flux_f64.bin``. J03 writes ``j03/na_cont_rz_f64.bin``
   and ``j03/j03_run_summary.txt``. Final acceptance and figures are written at
   the output root as ``summary.txt`` and ``j01_chain_density.png`` or
   ``j02_chain_density.png``.

   .. rubric:: 4. Acceptance

   FM must complete without truncated histories; SN must converge. Both density
   fields must be finite and nonnegative in active cells. J03 requires iterate
   change ≤ :math:`10^{-10}` and scaled local residual ≤ :math:`10^{-8}`.
   The output checker also requires convergence and

   .. math::

      E_Q=\frac{|Q_{\rm out}+Q_\nu-Q_{\rm in}-Q_S|}
                  {\max(Q_{\rm in}+Q_S,Q_{\rm out}+Q_\nu,\epsilon_{\rm tiny})}
           \le10^{-6}.

   Here the four rates represent inflow, outflow, volume production and removal.
   The active-cell density change
   :math:`E_n=\|n_{\rm J03}-n_{\rm pre}\|_2/\|n_{\rm pre}\|_2` is a recorded
   diagnostic without a separate acceptance threshold.

   .. rubric:: 5. Application results from 2026-10-06

   FM B0 was rerun after the J01 near-corner correction in
   ``fluid-fix-20261006-233223/FM_B0``. SN B0 and ION retain their completed
   ``fluid-20261006-192111`` runs; this correction did not change the J02/J03
   numerical sources. The SN logs confirm four OpenMP workers and no spatial MPI.
   Each figure below comes from its corresponding recorded run. Saved binary fields were independently
   checked: the exact 56,320-cell mask, finite fields, nonnegative densities,
   cylindrical boundary integrals and J03 local residuals agree with the summaries.
   The largest relative discrepancy in integrated particle rates is 9.3e−16.

   FM completed all 2,400,000 histories without truncation. SN B0 and ION
   converged in 20 and 15 iterations, with final changes 7.138210094e−7 and
   8.392788118e−7 (limit 1e−6). Diagnostics below use five significant digits;
   full-precision values are retained in the linked record.

   .. list-table::
      :header-rows: 1

      * - Case
        - J03 steps
        - Change (≤1e−10)
        - Residual (≤1e−8)
        - :math:`E_Q` (≤1e−6)
        - :math:`E_n`
      * - FM B0
        - 10675
        - 4.9759e−11
        - 9.9979e−9
        - 7.4834e−8
        - 3.6405e−3
      * - SN B0
        - 3647
        - 9.9958e−11
        - 4.2844e−9
        - 2.2322e−7
        - 3.0252e−6
      * - SN ION
        - 6223
        - 2.8193e−11
        - 9.9953e−9
        - 4.6204e−8
        - 3.4498e−6

   .. figure:: /_static/J_Fluid/application_reference/sn_iteration_en.svg
      :width: 100%
      :align: center

      Measured iteration change over all distribution coefficients; tolerance 1e−6.
      This is an iteration history, not physical time evolution.

   J03 integrates over a full revolution. FM samples a 1/3-radian sector:
   density and flux per unit area transfer unchanged, whereas total rates
   differ by a factor :math:`6\pi`.
   The ION outgoing and removal rates are 5.902672612e17 and 9.690071754e17 s⁻¹;
   their sum balances the injection of 1.559274509e18 s⁻¹.

   :download:`Numerical record and file hashes <records/application_tests_2026-10-06.json>`
   includes density ranges, reconstructed diagnostics, iteration histories and
   SHA-256 hashes. A source-and-script manifest was saved before the FM rerun;
   its location and checksum are included in the record. The earlier SN runs did
   not store build-time source hashes, so their executable identity cannot be
   established retrospectively.

   .. figure:: /_static/J_Fluid/application_reference/j01_chain_density.png
      :width: 92%
      :align: center

      FM B0: preprocessing density (left), J03 equilibrium (right).

   .. figure:: /_static/J_Fluid/application_reference/j02_chain_density.png
      :width: 92%
      :align: center

      SN B0: preprocessing density (left), J03 equilibrium (right).

   .. figure:: /_static/J_Fluid/application_reference/j02_ion_chain_density.png
      :width: 92%
      :align: center

      SN ION: preprocessing density with loss (left), J03 equilibrium (right).

   Each pair shares a colour scale in :math:`{\rm m}^{-3}`; white marks inactive cells.
   FM completed all 2.4 million histories. Both SN cases used the conservative local
   P0 positivity fallback, which increases diffusion in affected cells. Spatial
   accuracy is checked separately by analytical small-grid tests and refinement.

   .. rubric:: 6. Running and retaining outputs

   From the repository root, with NumPy and Matplotlib available:

   .. code-block:: bash

      cd ~/algoplasma
      source ~/.venv/bin/activate
      test_root=tests/012_fluid/J03_neutral_continuity_faceflux_2Drz
      run_dir="$HOME/algoplasma-runs/fluid-$(date +%Y%m%d-%H%M%S)"
      mkdir -p "$run_dir"
      export OPENMP=1 OMP_NUM_THREADS=4 OMP_DYNAMIC=FALSE

      APPLICATION_OUTPUT="$run_dir/FM_B0" bash "$test_root/application_reference_J01/run.sh"
      APPLICATION_OUTPUT="$run_dir/SN_B0" bash "$test_root/application_reference/run_application_reference.sh" B0
      APPLICATION_OUTPUT="$run_dir/SN_ION" bash "$test_root/application_reference/run_application_reference.sh" ION

   Run these sequentially, proceeding only after the preceding case reports ``RESULT: PASS``.
   SN uses four OpenMP workers; FM uses the current serial implementation.
   Each case reruns preprocessing and J03, saving progress logs, summary and figures
   below the new ``run_dir``. Print it with ``echo "$run_dir"`` in the same terminal.

   The bundled ``application_inputs`` provide the grids. An alternative directory
   is the first FM or second SN argument and must preserve the 256×256 indexing.
   Default outputs are ``application_reference_J01/build/output_B0`` for FM and
   ``application_reference/build/application_reference/output_B0`` or ``output_ION``
   for SN. Nonempty directories are protected; use ``APPLICATION_OUTPUT`` for a
   fresh destination. Progress is in each stage's ``run.log`` and final acceptance
   in ``summary.txt``. The J03 test cleanup removes default build outputs; retain
   important runs outside the repository.
