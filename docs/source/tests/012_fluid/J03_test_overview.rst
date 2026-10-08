J03 Tests
==========================================================================================

.. toctree::
   :maxdepth: 1
   :hidden:

   01 Closure and Step <J03_tests>
   02 Time Evolution <J03_transient_tests>
   03 Preprocessing Coupling <integration_tests>
   04 Applications <application_tests>

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 从单步更新到完整应用

   J03 接收参考密度与面通量，构造面输运系数，再推进当前密度。
   测试先固定参考数据验证公式，再逐步增加时间演化、实际前处理和器件几何。

   .. list-table::
      :header-rows: 1
      :widths: 23 39 38

      * - 阅读顺序
        - 数据从哪里来、怎样运行
        - 怎样判断结果
      * - 01 Closure and Step
        - 指定几单元的参考密度、通量、面积与体积；初始化闭合后调用一次更新或诊断
        - 迎风系数、稳定步长、新密度、残差和各项粒子率的手算值
      * - 02 Time Evolution
        - 固定闭合，从已知初值推进到指定时刻；另运行平衡求解
        - 指数衰减、源损解析解、两单元输运、时间步减半及瞬态总量收支
      * - 03 Preprocessing Coupling
        - J01 真实轨迹或 J02 真实输运生成参考数组，再由 J03 从空场推进
        - FM 两单元时间解；SN 空间解析分布、网格加密和恢复参考场
      * - 04 Applications
        - 256×256 器件网格、部分入口、混合反射；分别接入 FM、SN 的参考场
        - 前处理完成、非负密度、J03 收敛、局部残差及全域粒子收支

   第一层把给定通量当成已知输入，便于直接核对单步公式。
   第三层则由前处理程序生成这些通量，检查两套模块的数组位置、单位、符号和面积约定是否接得上。
   完整应用沿用相同调用顺序，增加实际区域和更多速度或粒子历史。

   .. rubric:: 小测试的执行顺序

   ``tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh`` 依次运行：

   1. ``test_J03_continuity_units``：面系数、稳定步长和单步公式。
   2. ``test_J03_equilibrium``：边界平衡、源损平衡和封闭两单元守恒。
   3. ``test_J03_transient``：时间解析解、共享面、稳态判据及混合时间层收支。
   4. ``test_application_case``：应用有效区域与 ION 损失窗口。
   5. ``test_J01_J03_channel``：轨迹统计接入 J03。
   6. ``test_J02_J03_analytic``：解析输运问题接入 J03。

   .. code-block:: bash

      bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh

   六个程序均在 2026-10-06 通过，日志按程序名写入 ``build``。
   第四个程序的几何与损失配置说明在应用页；第五、六个程序的参考解推导在串联页。

   .. rubric:: 小测试之后运行什么

   完整应用使用独立脚本，并将输出保存到新的目录。
   先选择 FM B0 或 SN B0，确认前处理与连续性计算均通过验收，
   再运行有损失的 SN ION。应用页给出命令、输出文件、自动阈值和现有图像的版本。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Progression

   Prescribed reference arrays verify closure and one-step formulas first.
   Repeated steps are then checked against time-dependent analytical solutions and
   equilibria. Actual J01/J02 outputs are connected to J03 next, followed by full
   256×256 applications.

   The J03 runner executes ``test_J03_continuity_units``,
   ``test_J03_equilibrium``, ``test_J03_transient``, ``test_application_case``,
   ``test_J01_J03_channel`` and ``test_J02_J03_analytic``, in that order.

   .. code-block:: bash

      bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh

   All six passed on 2026-10-06; individual logs are in ``build``.
   Application setup is documented on the application page. Full FM B0, SN B0
   and SN ION runs use separate scripts and output directories.
