C03_gather_3Draz_nonuniform Test
================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目的

   本目录检查 :doc:`C03 </rst_files/C_Gather/C03_gather_3Draz_nonuniform>` 是否能把网格场正确插值到粒子位置。
   测试先选择一个已知公式，在各网格采样位置填入场值，再调用 C03，最后直接在粒子位置代入公式求参考值。
   这样可以判断代码是否正确选择了场分量的交错位置、相邻单元和距离权重。

   算法源码的用途与执行过程见上面的模块页；本页说明测试怎样构造输入和判断结果。

   .. rubric:: 文件与运行方式

   .. list-table::
      :header-rows: 1
      :widths: 24 38 38

      * - 文件
        - 任务
        - 产物
      * - ``source_f90/main.f90``
        - 生成几何与场，调用三个公开接口。
        - ``output/c03_gather.csv``
      * - ``source_py/analyze.py``
        - 解析参考值、完整性检查、收敛阶和异常诊断。
        - ``summary.json`` 与错误日志
      * - ``make.sh`` / ``run.sh``
        - 编译 / 编译后运行并分析。
        - ``build/main``
      * - ``clean.sh``
        - 清理本测试目录下的生成文件。
        - 保留源文件

   .. code-block:: bash

      # From the repository root
      bash tests/007_gather/C03_gather_3Draz_nonuniform/run.sh

   需要 GNU Fortran 和 Python 3；Python 仅用标准库。编译开启
   ``-cpp -O2 -fdefault-real-8 -Wall -Wextra -fcheck=all -fbacktrace``。
   任一步失败，运行脚本以非零状态退出。重新运行会覆盖本次测试的 CSV、汇总和错误日志。

   .. rubric:: 网格与粒子怎样构造

   数组下界固定为 ``il=(-2,3,7)``，上界为 ``iu=il+n-1``，有意避免默认从 1 开始。
   普通算例的物理起点为 ``(0,0.2,-0.4)``，长度为 ``(2,1.2,1.6)``。
   非均匀网格先取 :math:`u=q/n`，再用下面的坐标映射：

   .. math::

      f_q=o+L(0.65u+0.35u^2),\qquad q=0,\ldots,n.

   左、右 ghost 宽度分别取相邻 owned 宽度的 0.7、1.3 倍，让边界插值必须正确使用 ghost 几何。
   E 的三个分量在 ``(face,center,center)``、``(center,face,center)``、
   ``(center,center,face)`` 处赋值，B 的三个分量在 ``(face,face,face)`` 处赋值。

   每组有 96 个确定性粒子位置，逐个检查六个分量。精确性算例的前 27 个位置覆盖整个 owned 盒的角点、
   边和面中点；第 28、29 个位置位于网格面和单元中心，其余位置位于内部。
   光滑场算例全部使用内部位置，避免边界延伸方式影响收敛阶。

   .. rubric:: 正常输入子测试

   .. list-table::
      :header-rows: 1
      :widths: 24 38 38

      * - 子测试
        - 输入安排
        - 要检查的功能
      * - ``constant``
        - 六个分量取不同常量。
        - 插值后仍应为原常量，检查八点权重及分量输出。
      * - ``uniform`` / ``nonuniform``
        - 分别在均匀 / 非均匀网格上，按各分量实际位置填入多线性函数。
        - 粒子处解析值与 gather 输出一致，检查几何距离和交错位置。
      * - ``wrapper``
        - 两列粒子数据，只计算第 2 列，第 1 列填无效占位值。
        - 输出符合第 2 个粒子的解析值，且粒子数组未被修改。
      * - ``cached``
        - 用独立线性扫描得到所属单元，传给 point。
        - 缓存路径仍符合解析值，不以另一次 gather 为参考。
      * - ``periodic`` / ``periodic_cached``
        - 角向区间 [6.0,6.6] 跨越 2π；输入角度加 -2 到 2 个周期，起点设为 0.25。
        - point 或带缓存 wrapper 应等于本地等价位置处的解析值。
      * - ``local_box``
        - 平移三个方向的物理起点，保留非单位数组下界和手动 ghost 值。
        - 验证局部坐标与数组下标不被混淆；不执行 MPI。
      * - ``single_cell_axis``
        - 三个方向都只有一个单元，并采样 r=0、边界和内部位置。
        - 单单元搜索和依赖两侧 ghost 中心的插值仍应符合解析值。
      * - ``smooth``
        - 固定物理范围和 96 个内部位置，每轴单元数依次为 8、16、32。
        - 与光滑解析场比较，检查两次加密的 RMS 收敛阶。

   .. rubric:: 参考值为什么可信

   分量编号 :math:`m=1,\ldots,6` 对应 Er、Ea、Ez、Br、Ba、Bz。
   常量场取 :math:`F_m=m/4-1`，其余精确性算例采用含交叉项的多线性函数：

   .. math::

      \begin{aligned}
      F_m(r,\alpha,z)={}&m+0.1mr-0.07(m+1)\alpha+0.03(m+2)z\\
      &+0.02r\alpha-0.01m\alpha z+0.005(m+1)rz+0.004mr\alpha z.
      \end{aligned}

   该函数对每个坐标分别至多一次，正确的三线性插值应在舍入误差范围内重现它。
   Fortran 只负责采样场并调用 C03；Python 自己代入粒子坐标计算参考值，不调用 C03 的搜索或权重函数。
   因此 wrapper、缓存路径并非只与 point 相互比较。

   周期算例使用跨 seam 的局部角向坐标填场，再平移输入角度。
   这里的多项式本身不是全局周期函数；检查的是代码能否选回正确的本地等价角度，
   而不是检验周期场通信或全局周期连续性。

   .. rubric:: 光滑场收敛检查

   使用下面的光滑函数，在每轴 8、16、32 个单元上重复采样和插值：

   .. math::

      F_m=m+\sin(0.7r+0.2m)\cos(0.6\alpha-0.1m)+0.2\sin(0.8z+0.3m).

   .. math::

      \varepsilon_n=\sqrt{\frac{1}{576}\sum_{p=1}^{96}\sum_{m=1}^{6}(F_{p,m}^{gather}-F_m(x_p))^2},\qquad s=\log_2(\varepsilon_n/\varepsilon_{2n}).

   常量误差上限为 ``1e-12``，其他精确场为 ``2e-11``。两次加密都要求 ``1.7<=s<=2.3``。
   分析还检查全部 6912 条记录是否齐全、每个样本是否唯一，以及坐标和结果是否有限，
   避免缺失数据或 NaN 被误判为通过。

   .. rubric:: 错误输入子测试

   每个错误输入都单独启动进程，因为 ``error stop`` 会终止 Fortran 程序。
   只有“退出码非零”且日志出现预期的 ``ERROR STOP C03: ...`` 才算通过；
   普通崩溃、数组越界或其他错误信息不能代替预期诊断。共有 11 个子测试：

   .. list-table::
      :header-rows: 1
      :widths: 24 38 38

      * - 子测试
        - 错误输入
        - 诊断关键内容
      * - ``bad_particle``
        - 粒子编号超过 np。
        - ``invalid particle index``
      * - ``negative_radius``
        - 负半径。
        - ``radius must be nonnegative``
      * - ``outside``
        - 粒子明显超出 owned 范围。
        - ``particle outside owned grid``
      * - ``stale_cell`` / ``outside_cell``
        - 缓存不包含粒子 / 缓存编号越界。
        - ``stale cached cell`` / ``cached cell outside owned grid``
      * - ``bad_period`` / ``origin_only``
        - 周期为零 / 只传周期起点。
        - ``angular period must be positive`` / ``a_origin requires a_period``
      * - ``bad_width`` / ``nan_width``
        - ghost 宽度为零 / owned 宽度为 NaN。
        - ``nonpositive or NaN width``
      * - ``inconsistent_width`` / ``nonmonotone``
        - 宽度与面差不符 / 面坐标不递增。
        - ``inconsistent face/width`` / ``faces must increase``

   .. rubric:: 输出文件与参考运行

   ``output/c03_gather.csv`` 每行保存子测试名、网格层级、粒子编号、分量编号、
   参考位置 r/alpha/z 和 gather 输出。``output/summary.json`` 保存逐组误差、收敛阶、
   错误输入结果与总体 ``pass``。每个错误输入的完整诊断单独保存在 ``output/<case>.log``。

   本次 GNU Fortran 双精度运行得到：

   .. code-block:: text

      expected/observed rows : 6912 / 6912
      constant max error     : 2.220e-16
      multilinear max error  : 2.665e-15
      smooth RMS (8/16/32)   : 3.815e-03 / 9.637e-04 / 2.392e-04
      refinement orders     : 1.9852 / 2.0105
      expected rejections   : 11 / 11
      result                : PASS

   .. rubric:: 覆盖边界

   这些是独立 gather 测试。ghost 场由解析函数手动填充，``local_box`` 只模拟本地子域数据。
   测试不执行 MPI 交换、Poisson 求解或粒子推进，也不验证轴上物理对称性。
   终端显示的最后几位误差可随编译器变化，判断以固定阈值和退出状态为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   This directory checks whether :doc:`C03 </rst_files/C_Gather/C03_gather_3Draz_nonuniform>`
   correctly gathers grid fields to particles. A known formula supplies field samples
   at the actual grid locations. After calling C03, Python evaluates that formula
   directly at the particle as a reference. This checks component staggering,
   neighbor selection, and distance weights. The module pages explain the code;
   this page explains test inputs and result criteria.

   .. rubric:: Files and Run Command

   .. list-table::
      :header-rows: 1
      :widths: 24 38 38

      * - File
        - Task
        - Output
      * - ``source_f90/main.f90``
        - Generate geometry/fields and call the three public interfaces.
        - ``output/c03_gather.csv``
      * - ``source_py/analyze.py``
        - Analytic references, completeness, convergence, and failure diagnostics.
        - summary.json and error logs
      * - ``make.sh`` / ``run.sh``
        - Build / build, run, and analyze.
        - ``build/main``
      * - ``clean.sh``
        - Remove products generated by this test.
        - Source files retained

   .. code-block:: bash

      # From the repository root
      bash tests/007_gather/C03_gather_3Draz_nonuniform/run.sh

   Requires GNU Fortran and Python 3, using only the Python standard library.
   Build flags are ``-cpp -O2 -fdefault-real-8 -Wall -Wextra -fcheck=all -fbacktrace``.
   Any failure makes the script exit nonzero. Rerunning overwrites the CSV, summary,
   and expected-failure logs.

   .. rubric:: Constructing the Grid and Particles

   Array lower bounds are deliberately non-unit: il=(-2,3,7), with iu=il+n-1.
   The default physical origin is (0,0.2,-0.4) and lengths are (2,1.2,1.6).
   For nonuniform meshes, set :math:`u=q/n` and map it to faces as:

   .. math::

      f_q=o+L(0.65u+0.35u^2),\qquad q=0,\ldots,n.

   Lower and upper ghost widths are 0.7 and 1.3 times their adjacent owned widths,
   so boundary interpolation must use the ghost geometry. E is sampled at
   (face,center,center), (center,face,center), (center,center,face); all B components
   are sampled at (face,face,face).

   Each case uses 96 deterministic positions and checks all six components. In exact
   cases, the first 27 positions cover owned-box corners, edges, and face centers;
   positions 28 and 29 lie on grid faces and cell centers. Remaining positions are
   interior. Smooth cases use only interior positions to isolate convergence from
   boundary extension choices.

   .. rubric:: Valid-Input Cases

   .. list-table::
      :header-rows: 1
      :widths: 24 38 38

      * - Case
        - Input
        - Property
      * - ``constant``
        - Distinct constants for six components.
        - Preserve each constant, checking weights and component outputs.
      * - ``uniform`` / ``nonuniform``
        - Sample a multilinear function at actual component locations on uniform / stretched meshes.
        - Match the analytic particle value, checking geometry and staggering.
      * - ``wrapper``
        - Use particle column 2; column 1 contains invalid placeholder coordinates.
        - Match the second particle and leave particle data unchanged.
      * - ``cached``
        - Supply containing cells found by an independent linear scan.
        - Match analytic values without using another gather as reference.
      * - ``periodic`` / ``periodic_cached``
        - Angular interval [6.0,6.6] crosses 2π; shift angles by -2 to 2 periods with origin 0.25.
        - Point or cached-wrapper output matches the local equivalent position.
      * - ``local_box``
        - Translate physical origins while retaining non-unit array bounds and explicit ghost values.
        - Check local coordinates versus array indices; no MPI communication.
      * - ``single_cell_axis``
        - One cell per axis, with axis, boundary, and interior particles.
        - Check single-cell search and interpolation using both ghost centers.
      * - ``smooth``
        - Fixed physical domain and 96 interior positions, with 8/16/32 cells per axis.
        - Measure RMS convergence for two refinements against a smooth analytic field.

   .. rubric:: How References Are Defined

   Component :math:`m=1,\ldots,6` denotes Er,Ea,Ez,Br,Ba,Bz. Constants use
   :math:`F_m=m/4-1`; the other exact cases use this multilinear function with cross terms:

   .. math::

      \begin{aligned}
      F_m(r,\alpha,z)={}&m+0.1mr-0.07(m+1)\alpha+0.03(m+2)z\\
      &+0.02r\alpha-0.01m\alpha z+0.005(m+1)rz+0.004mr\alpha z.
      \end{aligned}

   This function is at most linear in each coordinate separately, so correct
   trilinear interpolation reproduces it to roundoff. Fortran samples the field
   and calls C03; Python independently evaluates the formula at particle coordinates
   without calling C03 search or weight routines. Wrapper/cache cases therefore
   do not merely compare two code paths against one another.

   Periodic cases sample a local angular chart crossing the seam and then shift
   input angles. The polynomial is not globally periodic: these cases check correct
   selection of the local equivalent angle, not periodic field communication or
   global seam continuity.

   .. rubric:: Smooth-Field Convergence

   Sample and gather the following smooth function on 8,16,32 cells per axis:

   .. math::

      F_m=m+\sin(0.7r+0.2m)\cos(0.6\alpha-0.1m)+0.2\sin(0.8z+0.3m).

   .. math::

      \varepsilon_n=\sqrt{\frac{1}{576}\sum_{p=1}^{96}\sum_{m=1}^{6}(F_{p,m}^{gather}-F_m(x_p))^2},\qquad s=\log_2(\varepsilon_n/\varepsilon_{2n}).

   Constant tolerance is 1e-12; other exact cases use 2e-11. Both refinement orders
   must satisfy 1.7<=s<=2.3. Analysis also requires all 6912 unique expected records
   and finite coordinates/results, preventing missing data or NaNs from passing.

   .. rubric:: Invalid-Input Cases

   Each invalid input runs in a separate process because error stop terminates
   the Fortran driver. Passing requires both a nonzero exit code and the expected
   ERROR STOP C03 diagnostic. An unrelated crash or bounds error does not count.
   There are 11 cases:

   .. list-table::
      :header-rows: 1
      :widths: 24 38 38

      * - Case
        - Invalid input
        - Diagnostic text
      * - ``bad_particle``
        - Particle index exceeds np.
        - ``invalid particle index``
      * - ``negative_radius``
        - Negative radius.
        - ``radius must be nonnegative``
      * - ``outside``
        - Position outside the owned box.
        - ``particle outside owned grid``
      * - ``stale_cell`` / ``outside_cell``
        - Wrong containing cell / out-of-range cache.
        - ``stale cached cell`` / ``cached cell outside owned grid``
      * - ``bad_period`` / ``origin_only``
        - Zero period / origin without period.
        - ``angular period must be positive`` / ``a_origin requires a_period``
      * - ``bad_width`` / ``nan_width``
        - Zero ghost width / NaN owned width.
        - ``nonpositive or NaN width``
      * - ``inconsistent_width`` / ``nonmonotone``
        - Width disagrees with faces / non-increasing faces.
        - ``inconsistent face/width`` / ``faces must increase``

   .. rubric:: Output Files and Reference Run

   Each row of output/c03_gather.csv stores case, level, sample index, component
   index, reference position r/alpha/z, and gathered value. output/summary.json
   contains grouped errors, convergence orders, invalid-input results, and overall
   pass. Full diagnostics are saved as output/<case>.log.

   The GNU Fortran double-precision run produced:

   .. code-block:: text

      expected/observed rows : 6912 / 6912
      constant max error     : 2.220e-16
      multilinear max error  : 2.665e-15
      smooth RMS (8/16/32)   : 3.815e-03 / 9.637e-04 / 2.392e-04
      refinement orders     : 1.9852 / 2.0105
      expected rejections   : 11 / 11
      result                : PASS

   .. rubric:: Scope Limits

   These are standalone gather tests. Ghost fields are filled analytically and
   local_box only models local-subdomain data. No MPI exchange, Poisson solve,
   particle push, or physical axis-symmetry validation is performed. Last error
   digits can vary with the compiler; fixed thresholds and exit status determine success.
