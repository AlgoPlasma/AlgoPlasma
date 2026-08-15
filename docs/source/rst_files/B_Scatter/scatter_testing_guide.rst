=====================
Scatter Testing Guide
=====================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 1. 范围

   本指南概述 AlgoPlasma 中 ``B_Scatter`` 模块的验证方式、测试算例所在位置、
   推荐运行顺序和结果解读。如果只想看目录式测试入口，可先看
   :doc:`/tests/004_scatter/index`。

   当前覆盖：

   - **B01** ``sub_B01_scatter_3Dxyz`` / ``_v`` / ``_T``：3D Cartesian 三线性
     CIC 沉积，分别处理密度、速度矩和温度（方差）。
   - **B02** ``B02_deposit_3d_cyl``：3D 柱坐标 ``(r,\phi,z)`` 电荷/电流
     deposition，验证均匀物理密度场景下 ``rho``、``Jr``、``Jphi``、``Jz``
     与连续性方程的自洽性。

   除非各 case 的 README 明确说明，这些测试 **不** 覆盖：

   - CPML / 吸收边界
   - 粒子推进、场求解和滤波
   - GPU 后端

   .. rubric:: 2. 测试矩阵

   - ``tests/004_scatter/B01_scatter_3Dxyz``
     B01 的综合测试，按 case 01-11 顺序验证三个子程序的所有典型场景。
     Cases 01-04 为单 / 多粒子的几何沉积，case 05-06 为 OMP 正确性 + 性能基准，
     case 07-09 为速度矩沉积，case 10-11 为温度沉积。
     输出在 ``build/output_case*.dat``，绘图在 ``build/result_many.png``。
     详见 :doc:`B01 综合测试 </tests/004_scatter/B01_scatter_3Dxyz>`。

   - ``tests/kunpeng_compare/B01_scatter_3Dxyz_omp``
     B01 OMP 扩展性的跨平台对比测试。在 AMD服务器和鲲鹏服务器上分别跑
     ``np`` × ``nthread`` 二维扫描，比较 ``sub_B01_scatter_3Dxyz`` 的
     ``firstprivate`` + ``reduction`` 设计在两台机器上的开销差异。
     详见 :doc:`B01 鲲鹏对比 </tests/kunpeng_compare/B01_scatter_3Dxyz_omp>`。

   - ``tests/004_scatter/B02_deposit_3d_cyl/test1``
     B02 在柱坐标体积均匀采样（``r = R_max * \sqrt{U}``）+ 粒子权重均匀
     场景下的沉积验证。输出 ``*.dat`` 和 ``*.png``。

   - ``tests/004_scatter/B02_deposit_3d_cyl/test2``
     B02 在 ``r`` 均匀采样 + 非均匀宏粒子权重（``w_p = 2r/R_max \cdot w_0``）
     场景下的沉积一致性验证。

   .. rubric:: 3. 快速运行命令

   B01 综合测试：

   .. code-block:: bash

      cd tests/004_scatter/B01_scatter_3Dxyz
      bash clean.sh && bash make.sh && bash run.sh && bash plot.sh

   B01 鲲鹏对比（在 AMD服务器 / Kunpeng 各跑一次）：

   .. code-block:: bash

      cd tests/kunpeng_compare/B01_scatter_3Dxyz_omp
      bash run_AMD.sh        # 在 AMD服务器上
      bash run_kunpeng.sh    # 在鲲鹏上
      bash plot.sh           # 两边 log 都到位后

   B02 子测试：

   .. code-block:: bash

      cd tests/004_scatter/B02_deposit_3d_cyl/test1
      bash clean.sh && bash make.sh && bash run.sh 1000

      cd ../test2
      bash clean.sh && bash make.sh && bash run.sh 1000

   ``B02`` 的 ``run.sh`` 接受粒子数参数；README 默认数值偏大，
   smoke test 时建议显式给一个较小数值。

   .. rubric:: 4. 建议验证顺序

   首次接触建议按以下顺序排查：

   1. **B01 case 01-03** （单粒子 / 多粒子基础沉积）
      验证三线性权重和 ``sum(den) = np * w`` 守恒。
   2. **B01 case 04** （hollow-square / H / cross 几何图案）
      验证多粒子结构化沉积的形状和切片可视化。
   3. **B01 case 05-06** （OMP 正确性 + 单机性能基准）
      验证串行 / 并行节点一致，给出单机 speedup 参考。
   4. **B01 case 07-09** （速度矩 ``_v`` 子程序）
      验证带符号速度量和守恒性。
   5. **B01 case 10-11** （温度 ``_T`` 子程序）
      验证基于最近格子法的 ``<(v-<v>)²>`` 实现。
   6. **B02 test1 / test2** （柱坐标沉积）
      在两种采样 / 权重组合下验证 ``rho``、``J`` 和连续性残差。
   7. **B01 鲲鹏对比** （仅当需要做跨平台性能调优时）
      在两台目标机器上跑完后做对比，定位 OMP 扩展瓶颈。

   .. rubric:: 5. 结果解读

   - **守恒检查** （B01 / B02 都有）：单步沉积后 ``sum(den)`` 应等于
     ``sum(w_p)``，浮点误差应在 ``1e-4`` 量级以内。这条不过等于沉积彻底坏了。
   - **节点权重精度** （B01 case 01-04）：单粒子分配到 8 节点的权重应等于
     三线性公式的解析值，逐节点误差应在浮点机器精度量级。
   - **OMP 一致性** （B01 case 05）：``maxval(|den_serial - den_parallel|)``
     应小于 ``1e-10``。注意 ``reduction(+:)`` 的浮点求和顺序不固定，
     完全位级一致不保证；保留打印的 NOTE 状态用于人工判断。
   - **B01 鲲鹏对比** ：实测 speedup 距 ``ideal = N`` 的差距 = OMP 开销代价；
     曲线 **跌破 1** 即真负扩展。详细分析见
     :doc:`B01_scatter_3Dxyz_omp 对比 </tests/kunpeng_compare/B01_scatter_3Dxyz_omp>`。
   - **B02 连续性残差**：``∂ρ/∂t + ∇·J`` 在 macro-particle 步进后的离散值，
     用来判断电流沉积和电荷沉积是否互相自洽。

   .. rubric:: 6. 说明

   - B01 主 case（01-11）的输出对照 ``source_f90/sub_case*.f90`` 中的解析期望值，
     程序自身打印 ``PASS/FAIL``；外部脚本不会复算，把 stdout 留着就够了。
   - B01 鲲鹏对比是 **性能 benchmark**，不验证数值正确性。如果想同时跑数值校验，
     需要先确认 ``tests/004_scatter/B01_scatter_3Dxyz`` 主 case 全部通过。
   - 改 ``sub_B01_scatter_3Dxyz`` 的 OMP 设计（去掉 ``default(firstprivate)``、
     改用 shared par + 原子加 / 局部累加）之后，B01 鲲鹏对比的图会立刻反映
     效果——是最方便的回归基准。

.. container:: ap-lang ap-lang-en

   .. rubric:: 1. Scope

   This guide summarizes how ``B_Scatter`` modules are validated in AlgoPlasma,
   where the test cases live, the recommended run order, and how to read the
   results. For the directory-oriented test entry, see
   :doc:`/tests/004_scatter/index`.

   Currently covered:

   - **B01** ``sub_B01_scatter_3Dxyz`` / ``_v`` / ``_T``: 3D Cartesian
     trilinear (CIC) scatter for density, velocity moment, and temperature
     (variance).
   - **B02** ``B02_deposit_3d_cyl``: 3D cylindrical ``(r,\phi,z)`` charge
     and current deposition, checking self-consistency of ``rho``, ``Jr``,
     ``Jphi``, ``Jz``, and the continuity equation under uniform physical
     density.

   Unless individual READMEs state otherwise, these suites do **not** cover
   CPML, particle pushes, field solves, filters, or GPU backends.

   .. rubric:: 2. Test Matrix

   - ``tests/004_scatter/B01_scatter_3Dxyz``
     B01 main suite. Cases 01-11 sequentially validate all three subroutines.
     Cases 01-04 are geometric scatter on single / multi-particle layouts;
     05-06 are OMP correctness + single-node performance; 07-09 cover the
     velocity moment subroutine; 10-11 cover temperature. Outputs land under
     ``build/output_case*.dat`` and ``build/result_many.png``. See
     :doc:`B01 main suite </tests/004_scatter/B01_scatter_3Dxyz>`.

   - ``tests/kunpeng_compare/B01_scatter_3Dxyz_omp``
     Cross-platform OMP scalability comparison for B01: a joint
     ``np`` × ``nthread`` sweep run on both the AMD server and the Kunpeng
     server, highlighting the cost of ``sub_B01_scatter_3Dxyz``'s
     ``firstprivate + reduction`` design on each machine. See
     :doc:`B01 Kunpeng comparison </tests/kunpeng_compare/B01_scatter_3Dxyz_omp>`.

   - ``tests/004_scatter/B02_deposit_3d_cyl/test1``
     B02 with uniform cylindrical-volume sampling
     (``r = R_max * \sqrt{U}``) and uniform particle weights.

   - ``tests/004_scatter/B02_deposit_3d_cyl/test2``
     B02 with uniform ``r`` sampling and non-uniform macro-particle weights
     (``w_p = 2r/R_max \cdot w_0``).

   .. rubric:: 3. Quick Run Commands

   B01 main suite:

   .. code-block:: bash

      cd tests/004_scatter/B01_scatter_3Dxyz
      bash clean.sh && bash make.sh && bash run.sh && bash plot.sh

   B01 Kunpeng comparison (one run per platform):

   .. code-block:: bash

      cd tests/kunpeng_compare/B01_scatter_3Dxyz_omp
      bash run_AMD.sh        # on the AMD server
      bash run_kunpeng.sh    # on the Kunpeng server
      bash plot.sh           # after both logs are in place

   B02 subtests:

   .. code-block:: bash

      cd tests/004_scatter/B02_deposit_3d_cyl/test1
      bash clean.sh && bash make.sh && bash run.sh 1000

      cd ../test2
      bash clean.sh && bash make.sh && bash run.sh 1000

   The ``run.sh`` argument for B02 is the particle count; the README default
   is intentionally large, so pass a smaller value for a quick smoke test.

   .. rubric:: 4. Suggested Validation Order

   For first-time validation, work through the cases in this order:

   1. **B01 cases 01-03** (single / multi-particle basic scatter) — verify
      trilinear weights and ``sum(den) = np * w`` conservation.
   2. **B01 case 04** (hollow-square / H / cross patterns) — verify
      structured multi-particle deposition shape and slice visualization.
   3. **B01 cases 05-06** (OMP correctness + single-node benchmark) — verify
      serial / parallel node-by-node consistency and capture per-machine
      speedup.
   4. **B01 cases 07-09** (velocity-moment ``_v`` subroutine) — verify signed
      velocity quantities and conservation.
   5. **B01 cases 10-11** (temperature ``_T`` subroutine) — verify the
      nearest-cell ``<(v-<v>)²>`` implementation.
   6. **B02 test1 / test2** (cylindrical deposition) — verify ``rho``, ``J``,
      and the continuity residual under two sampling / weighting choices.
   7. **B01 Kunpeng comparison** (only when cross-platform tuning is needed) —
      run on both target machines and compare to locate OMP scaling bottlenecks.

   .. rubric:: 5. Result Interpretation

   - **Conservation** (B01 and B02): after one scatter step, ``sum(den)``
     must equal ``sum(w_p)`` to within about ``1e-4``. **Failing this means
     scatter is fundamentally broken.**
   - **Node-weight accuracy** (B01 cases 01-04): single-particle weight at
     each of the 8 surrounding nodes must match the analytical trilinear
     formula to within floating-point precision.
   - **OMP consistency** (B01 case 05):
     ``maxval(|den_serial - den_parallel|)`` should be below ``1e-10``.
     ``reduction(+:)`` does not pin the floating-point summation order, so
     bit-exact equality is not guaranteed; the program prints a NOTE status
     for human inspection.
   - **B01 Kunpeng comparison**: vertical gap between the measured speedup
     curve and the ``ideal = N`` line is the OMP overhead cost. Curves
     **falling below 1** indicate true negative scaling. Full reading is in
     :doc:`B01_scatter_3Dxyz_omp comparison </tests/kunpeng_compare/B01_scatter_3Dxyz_omp>`.
   - **B02 continuity residual**: discrete ``∂ρ/∂t + ∇·J`` after a
     macro-particle step; used to verify current and charge deposition are
     consistent.

   .. rubric:: 6. Notes

   - B01 main cases (01-11) compare their output against analytical
     expectations baked into ``source_f90/sub_case*.f90``; the program
     itself prints ``PASS/FAIL``. No external script recomputes anything —
     keeping stdout is enough.
   - The B01 Kunpeng comparison is a **performance benchmark** and does not
     re-verify numerical correctness. Confirm the main B01 suite under
     ``tests/004_scatter/B01_scatter_3Dxyz`` passes before relying on the
     comparison numbers.
   - After changes to ``sub_B01_scatter_3Dxyz``'s OMP design (drop
     ``default(firstprivate)``, switch to shared ``par`` with atomic adds or
     local accumulation), the B01 Kunpeng comparison plots are the most
     convenient regression view to confirm the effect.
