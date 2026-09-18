Application tests
======================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 测试目标

   检验两种中性粒子前处理产生的密度和面通量能否用于 J03 的连续性方程求解。分别运行自由分子（FM）与离散纵标（SN）前处理，将各自结果传给 J03。图中左右两幅分别为前处理密度与对应的 J03 稳态密度。

   .. rubric:: 计算条件

   .. list-table::
      :header-rows: 1

      * - 参数
        - B0 设置
      * - 空间网格
        - 256×256，r-z 单元；无效区域不参与计算。
      * - 入口
        - 轴向低端面，径向范围 0.0151837363–0.0232205007 m。
      * - 入口密度参数
        - 5.0×10¹⁸ m⁻³，用于注入通量归一化。
      * - 入口与壁温；轴向漂移
        - 550 K；300 m/s。
      * - 反射条件
        - 漫反射比例 0.7，其余为镜面反射。
      * - 入口分布
        - 穿面事件采样的漂移 Maxwell 分布；不等同于储气池相密度输入。
      * - 体源与电离损失
        - B0 为零；ION 使用 application_case.f90 在单元中心生成的余弦窗口电离频率。
      * - 前处理规模
        - FM：240 万条历史；SN：400 角方向×16 速度组。



   .. rubric:: 应用驱动文件与正式计算代码

   驱动文件负责读取算例、组装参数、调用模块和写出结果；输运与连续性离散仍在 J_Fluid 中。
   下列四个驱动均位于各应用目录的 source_f90 下。

   .. list-table::
      :header-rows: 1
      :widths: 35 65

      * - 驱动文件
        - 调用与验证对象
      * - application_reference_J01 / run_J01_application_reference.f90
        - 调用 sub_J01_free_molecular_mc_2Drz，验证轨迹前处理在完整几何上的执行与输出；不是读取现成密度后重构通量。
      * - application_reference_J01 / run_J03_from_J01_reference.f90
        - 读取 J01 的密度和通量，调用 sub_J03_initialize_transport_closure、sub_J03_solve_steady，得到 FM 闭合下的连续性解。
      * - application_reference / run_J02_application_reference.f90
        - 调用 J02 的网格、求积、入口、吸收和反射源迭代接口，再重构单元矩、内部面与开放边界通量。
      * - application_reference / run_J03_application_reference.f90
        - 导入 J02 密度与面通量，调用 sub_J03_initialize_transport_closure、sub_J03_solve_steady，得到 SN 闭合下的连续性解。

   驱动文件中的格式读取和出图不属于输运方程；单元测试中的公式断言也不由图片替代。

   .. rubric:: 程序执行过程

   FM 入口为 ``application_reference_J01/run.sh``：编译两个驱动 → J01 跟踪粒子并写出密度/面通量 → J03 导入闭合并迭代 → 读取输出生成图。

   SN 入口为 ``application_reference/run_application_reference.sh``：J02 构造网格、入口及反射条件 → 源迭代 → 重构密度/通量 → J03 迭代 → 生成图。

   两个目录位于 ``tests/011_fluid/J03_neutral_continuity_faceflux_2Drz``。默认网格随仓库放在 application_inputs。
   四个驱动共用 application_case.f90：有效区域为 (65:192,1:72) 与 (:,73:256)，共 56320 个有效单元。
   ION 在规定的 r、z 窗口内取两个余弦因子的乘积，峰值 1e5 s⁻¹，窗口外为零。
   具体范围见 application_inputs/README.md，不再读取历史输出中的掩码或频率。

   .. rubric:: 本页静态图的版本

   下列图片来自 2026-09-17 完成的 Fortran 运行，均通过当前密度、残差和粒子收支检查。
   FM B0 对应运行编号 161616；SN ION 为 164900；SN B0 为 210906。
   两个 SN 算例均已启用局部 P0 保正回退。它保证局部粒子收支，但会增加回退单元的数值扩散；
   本页结果不代替网格精度验证。

   .. list-table:: 本次应用测试记录
      :header-rows: 1

      * - 算例
        - J03 步数
        - 缩放残差
        - 粒子收支相对误差
      * - FM B0
        - 10675
        - 9.9955×10⁻⁹
        - 7.4811×10⁻⁸
      * - SN B0
        - 4398
        - 9.9925×10⁻⁹
        - 3.8957×10⁻⁸
      * - SN ION
        - 6200
        - 9.9974×10⁻⁹
        - 4.6258×10⁻⁸

   .. rubric:: 自由分子前处理与连续性解

   .. figure:: /_static/J_Fluid/application_reference/j01_chain_density.png
      :width: 92%
      :align: center

      左：J01 自由分子前处理密度；右：相同面通量驱动的 J03 稳态密度。共用色标，单位为 m⁻³，白色表示无效区域。

   此图对应 240 万条粒子历史，未完成的截断轨迹数为零。

   .. rubric:: 离散纵标前处理与连续性解

   .. figure:: /_static/J_Fluid/application_reference/j02_chain_density.png
      :width: 92%
      :align: center

      左：J02 离散纵标前处理密度；右：对应的 J03 稳态密度。坐标和色标与前处理图保持一致。

   此图为启用保正处理后的 SN B0 结果。

   .. rubric:: 含电离损失的 SN ION 测试

   .. figure:: /_static/J_Fluid/application_reference/j02_ion_chain_density.png
      :width: 92%
      :align: center

      左：含给定电离损失的 J02 密度；右：对应 J03 收敛密度。两图共用色标。

   J02、J03 在全部 56320 个有效单元中的密度均有限且非负。

   .. rubric:: 结果的含义

   以前处理有效单元密度为分母，记录两个阶段之间的相对变化：

   .. math::

      E_n=\frac{\|n_{\mathrm{J03}}-n_{\mathrm{pre}}\|_2}
                {\|n_{\mathrm{pre}}\|_2}.

   FM B0 的 E_n 为 3.6410×10⁻³，SN B0 为 3.1699×10⁻⁶，SN ION 为 3.4296×10⁻⁶。
   这些是运行记录值，没有针对它们设置独立的自动通过阈值。

   J03 从参考密度开始，按固定面速度推进。两阶段密度差异可能与参考场的离散不平衡、边界入口归一化、低密度处理和迭代误差有关；仅凭这两张图不能确定各因素的贡献。源项为零时若参考场已满足同一离散平衡且闭合不被密度下限改变，J03 应保持该场。

   稳态驱动同时要求相对密度变化≤1e-10、归一化局部残差≤1e-8。
   应用验收另外要求相对粒子率失衡≤1e-6；失衡由出射加体损失减入射减体源计算。
   小测试见 :doc:`J03 单元测试 <J03_tests>`。这些条件适用于本页的稳态应用；瞬态另检查带有密度累积项的守恒关系。

   当前出图工具只读取本次前处理与 J03 密度以及本次写出的有效区域。自动检查两阶段有效区密度有限且非负、前处理完成、J03 收敛、局部残差和总量平衡；密度相对变化仍只作为诊断，不设通过阈值。

   .. rubric:: 运行、输出与清理

   .. code-block:: bash

      bash tests/011_fluid/J03_neutral_continuity_faceflux_2Drz/application_reference_J01/run.sh
      bash tests/011_fluid/J03_neutral_continuity_faceflux_2Drz/application_reference/run_application_reference.sh B0

   默认直接使用仓库的 application_inputs。若指定其他网格目录，通过 FM 第一个参数、SN 第二个参数传入；
   该目录需含 grid_r.dat、grid_z.dat，且采用相同的 256×256 区域索引约定。输入在运行前校验。
   若输出目录已有文件，脚本拒绝覆盖。设置 APPLICATION_OUTPUT 为新目录再运行，例如：

   .. code-block:: bash

      APPLICATION_OUTPUT=/tmp/algoplasma_sn_B0_new bash tests/011_fluid/J03_neutral_continuity_faceflux_2Drz/application_reference/run_application_reference.sh B0

   默认 FM 输出位于 ``application_reference_J01/build/output_B0``；SN 输出位于 ``application_reference/build/application_reference/output_B0``。各自含 j01 或 j02、j03 数据子目录、日志、summary.txt 与图片。ION 通过把 SN 命令中的 B0 改为 ION 启动。J03 测试目录的 clean.sh 会删除这些默认运行输出；需要保留时，应使用仓库外的 APPLICATION_OUTPUT 目录。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Goal and setup

   B0 uses a 256×256 r-z grid, a partial z-low inlet, density parameter 5e18 m^-3, inlet/wall temperature 550 K, axial drift 300 m/s and diffuse fraction 0.7. The inlet is crossing-sampled. FM runs 2.4 million histories; SN uses 400 angles and 16 speeds. Each passes its own density and fluxes to J03.

   .. rubric:: FM results

   .. figure:: /_static/J_Fluid/application_reference/j01_chain_density.png
      :width: 92%
      :align: center

      J01 preprocessing (left) and J03 steady density (right), with a common colour scale.

   FM B0 completed 2.4 million histories without truncation on 2026-09-17 (run 161616).
   J03 converged in 10675 steps; scaled residual 9.9955e-9, relative number imbalance 7.4811e-8.

   .. rubric:: SN results

   .. figure:: /_static/J_Fluid/application_reference/j02_chain_density.png
      :width: 92%
      :align: center

      J02 preprocessing (left) and J03 steady density (right).

   SN B0 (run 210906, 2026-09-17) uses the P0 positivity fallback and passed:
   4398 J03 steps, scaled residual 9.9925e-9, relative number imbalance 3.8957e-8.

   .. rubric:: SN ION results

   .. figure:: /_static/J_Fluid/application_reference/j02_ion_chain_density.png
      :width: 92%
      :align: center

      J02 with prescribed ionization loss (left) and its J03 solution (right).

   SN ION (run 164900, 2026-09-17) passed: 6200 J03 steps,
   scaled residual 9.9974e-9, relative number imbalance 4.6258e-8.
   Both stages are finite and nonnegative in all active cells. The P0 fallback
   increases local diffusion; these checks do not replace grid accuracy studies.

   .. rubric:: Interpretation

   Field changes are recorded diagnostics with no independent acceptance threshold. The steady solver enforces iterate change and scaled residual thresholds; application acceptance additionally checks number-rate balance and finite, nonnegative densities in both stages. Differences can reflect discrete imbalance, boundary normalization, density floors and iteration error; these plots do not isolate the causes.

   .. rubric:: Execution and dependencies

   Use the two application scripts under the J03 test directory; replace B0 with ION for the SN ionization case. Grids are bundled in application_inputs; application_case.f90 generates the shared active region and prescribed ION loss. No external solution directory is needed. Outputs reside under the application build directories or APPLICATION_OUTPUT. Existing nonempty output directories are protected from overwriting. clean.sh removes default build outputs; retain important results outside the repository.
