J03 Closure and Step
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 测试目标

   给定参考密度、面通量、面积、体积和源损数据，依次核对面输运系数、稳定步长、
   一次更新后的密度及残差。每个子测试使用可以直接手算的小数组。

   .. rubric:: 文件与被测过程

   测试文件位于 ``tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/source_f90``；
   正式源码位于 ``J_Fluid/J03_neutral_continuity_faceflux_2Drz``。

   .. list-table::
      :header-rows: 1
      :widths: 31 37 32

      * - 测试文件
        - 被测过程
        - 检查什么
      * - ``test_J03_continuity_units.f90``
        - ``sub_J03_initialize_transport_closure``；``sub_J03_compute_stable_timestep``；``sub_J03_continuity_step``；``sub_J03_compute_residual``
        - 迎风侧选择、稳定步长、单步公式、残差及错误输入

   闭合初始化在 ``sub_J03_transport_closure.f90``；
   时间推进、残差和收支计算在 ``sub_J03_continuity_solver.f90``。
   每个子测试独立构造输入。其公共调用顺序为：

   1. 设置有效单元、面类型、几何量和参考场。
   2. 调用 ``sub_J03_initialize_transport_closure``，生成面系数并保存参考数据。
   3. 设置当前密度与源项，调用本项需要的步长、单步或残差过程。
   4. 将输出与下列参考值逐项核对。

   参考密度用于构造面系数；当前密度用于计算本步通量，两者在测试中分别指定。

   .. rubric:: 1. 从参考通量确定迎风系数

   ``test_upwind_closure_signs`` 使用三个单元，参考密度为 [2,4,8]，
   两个内部面参考通量为 [6,−12]。通量正方向沿坐标增加方向。
   面系数用参考通量除以迎风侧参考密度：

   .. math::

      u_{12}=\frac{6}{2}=3,\qquad
      u_{23}=\frac{-12}{8}=-1.5.

   测试检查这两个数值，绝对容差为 :math:`10^{-13}`。
   正通量从左单元取参考密度，负通量从右单元取参考密度。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 正通量面系数
        - 3
        - 6/2 = 3
        - 0
        - 1e−13
      * - 负通量面系数
        - −1.5
        - −12/8 = −1.5
        - 0
        - 1e−13

   .. rubric:: 2. 核对稳定时间步

   ``test_exact_cfl`` 使用体积 :math:`V=6`、出口面积 :math:`A=3`、
   参考密度 2、参考出射通量 4。出口系数是 :math:`u=4/2=2`，
   损失频率 :math:`\nu=1`，安全系数 :math:`C=0.8`。
   当前实现采用含损失项的保守步长：

   .. math::

      \Delta t=\frac{C}{Au/V+\nu}
      =\frac{0.8}{3\times2/6+1}=0.4.

   调用 ``sub_J03_compute_stable_timestep`` 后，返回步长与 0.4 的差须小于
   :math:`10^{-13}`。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 稳定时间步
        - 0.4
        - 0.4
        - 0
        - 1e−13

   .. rubric:: 3. 核对单步公式及残差

   ``test_step_and_residual_formula`` 使用体积 :math:`V=6`，给定当前密度 :math:`n^q=3`、
   体源 :math:`S=4`、损失频率 :math:`\nu=1`、时间步 :math:`\Delta t=0.5`。
   低端入射通量为 2、面积为 3；高端出口系数为 2、面积为 1。
   在当前密度处，流入和流出粒子率均为 6，所以散度 :math:`D(n^q)=0`。

   源项显式、损失项隐式的单步结果应为

   .. math::

      n^{q+1}
      =\frac{n^q+\Delta t[S-D(n^q)]}{1+\Delta t\,\nu}
      =\frac{3+0.5\times4}{1.5}=\frac{10}{3}.

   在 **旧密度** :math:`n^q=3` 上计算的稳态残差则是

   .. math::

      R(n^q)=D(n^q)+\nu n^q-S=-1,\qquad VR=-6.

   先调用 ``sub_J03_continuity_step`` 核对新密度，再对旧密度调用
   ``sub_J03_compute_residual`` 核对局部残差及体积分。
   三项均使用绝对容差 :math:`10^{-13}`。残差符号为“流出散度 + 损失 − 源”。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 更新后密度
        - 3.333333333
        - 10/3
        - 0
        - 1e−13
      * - 旧密度的局部残差
        - −1
        - −1
        - 0
        - 1e−13
      * - 残差体积分
        - −6
        - −6
        - 0
        - 1e−13

   .. rubric:: 4. 检查边界及错误输入

   .. list-table::
      :header-rows: 1
      :widths: 32 35 33

      * - 子测试
        - 输入条件
        - 必须得到的结果
      * - ``test_axis_zero_area``
        - 轴面面积为零、体积为正
        - 初始化成功
      * - ``test_invalid_topology``
        - 没有邻居的域边界标为内部面
        - ``J03_ERR_FACE_TYPE``
      * - ``test_nonconvergence_diagnostic``
        - 仅允许一次不足以收敛的迭代
        - 未收敛错误、``converged=.false.``、迭代数 1
      * - ``test_negative_reference_clipping``
        - 输入密度 −2，分别启用和关闭截断
        - 开启时截为零；关闭时返回负输入错误

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 输入
        - 实际返回值
        - 预期返回值
      * - 非法内部面
        - 104
        - J03_ERR_FACE_TYPE = 104
      * - 单次迭代上限
        - 106 / F / 1
        - 106 / F / 1
      * - 开启截断后的密度
        - 0
        - 0
      * - 关闭截断、输入负密度
        - 103
        - J03_ERR_NEGATIVE_INPUT = 103

   截断选项把负值置零，会改变粒子总数。完整应用的结果验收会检查两阶段密度，要求有效单元中的值有限且非负。

   .. rubric:: 运行与判定

   .. code-block:: bash

      bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh

   脚本先运行四个局部、时间演化和配置测试，再运行两个跨模块串联程序，日志写入 ``build/*.log``。
   每个程序必须没有失败断言并以零状态退出。
   本页对应日志为 ``build/test_J03_continuity_units.log``，2026-10-06 全部通过。
   下一页在同一单步过程上增加时间循环，检查解析时间解、平衡解与收支。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Scope and source mapping

   The tests under ``J03_neutral_continuity_faceflux_2Drz/source_f90`` check
   closure coefficients, timestep selection, one-step evolution and residuals from prescribed small arrays.
   Closure initialization is in ``sub_J03_transport_closure.f90``;
   time evolution and diagnostics are in ``sub_J03_continuity_solver.f90``.

   .. rubric:: Local worked references

   ``test_J03_continuity_units.f90`` checks:

   * Reference densities [2,4,8] and internal fluxes [6,-12] give upwind
     coefficients [3,-1.5], with absolute tolerance 1e-13.
   * For volume 6, outlet area 3, outlet coefficient 2, loss 1 and CFL 0.8,
     the selected timestep is :math:`0.8/(3\times2/6+1)=0.4`.
   * With density 3, source 4, loss 1, zero net flux and timestep 0.5,
     the new density is :math:`(3+0.5\times4)/1.5=10/3`.
     The old-field residual is -1 and its volume integral is -6.
   * Axis zero area is valid. Invalid topology, nonconvergence and negative
     inputs return specific errors. Optional clipping is tested as behavior,
     not claimed conservative.

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - Upwind coefficients
        - 3 / −1.5
        - 3 / −1.5
        - 0
        - 1e−13
      * - Stable timestep
        - 0.4
        - 0.4
        - 0
        - 1e−13
      * - New density
        - 3.333333333
        - 10/3
        - 0
        - 1e−13
      * - Old residual / integral
        - −1 / −6
        - −1 / −6
        - 0
        - 1e−13

   Observed codes were 104 (topology), 106 (one iteration, not converged),
   and 103 (negative input without clipping). Clipping returned density zero.

   .. rubric:: Execution

   .. code-block:: bash

      bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh

   The Fortran runner executes four local/setup programs, then two integration programs and writes ``build/*.log``.
   All assertions and process exit statuses must indicate success.
   This page corresponds to ``build/test_J03_continuity_units.log``; all checks passed on 2026-10-06.
