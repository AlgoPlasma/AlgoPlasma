J01 particle unit tests
======================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>


.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 源码与执行入口

   测试源码为 ``tests/011_fluid/J01_free_molecular/source_f90/test_J01_fm_units.f90``。
   被测源码位于 ``J_Fluid/J01_free_molecular``，不读取外部历史结果。

   .. code-block:: bash

      bash tests/011_fluid/J01_free_molecular/run.sh

   .. rubric:: 入口采样

   ``test_sampling`` 调用 :doc:`采样文件 </rst_files/J_Fluid/J01_free_molecular/sub_J01_fm_sampling>` 中的 prepare、sample 和 seed。
   网格 r=[1,2,3]，部分入口 [1.5,2.5]，扇区角 2；检查分段面积为 1.75、2.25。
   设 kBT/m=1、零漂移、密度参数 10、历史数 100，粒子率应为 0.4√(2/π)。
   检查同运行时种子重复性、1,000 次采样的入口范围、正轴向速度及有限性；空入口应报配置错误。
   这些断言验证采样约束与归一化，不声称验证完整统计分布。

   .. rubric:: 壁面反射

   ``test_reflection`` 调用 :doc:`反射文件 </rst_files/J_Fluid/J01_free_molecular/sub_J01_fm_reflection>` 的 reflect_velocity。
   对四面逐一验证镜面法向翻转、切向不变；纯漫反射每面抽样 100 次，检查速度有限且朝域内。
   该测试不替代大样本的壁面速度分布检验。

   .. rubric:: 单条轨迹与定位

   ``test_trajectory`` 调用 :doc:`轨迹文件 </rst_files/J_Fluid/J01_free_molecular/sub_J01_fm_trajectory>` 的 locate_cell 和 trace_fm_history。
   r=[1,2]、z=[0,1,2]，从 z=0.25 以 vz=2 穿过两个单元，检查驻留时间为 0.375 和 (1−εz)/2，
   内部与高端出口计数为 +1。反向轨迹检查内部与低端出口计数为 −1。
   另检查半开区间定位、事件上限和域外起点不被当作成功逃逸。

   .. rubric:: 统计量归一化

   ``test_statistics`` 调用 :doc:`统计文件 </rst_files/J_Fluid/J01_free_molecular/sub_J01_fm_statistics>` 的 initialize 和 finalize。
   人工设置驻留时间 2、速度矩 6 和 −4、径向计数 −2、轴向计数 3、低端出射 −1。
   给定粒子率 6 和测试几何，应得到密度 4、均速 (3,−2)、内部通量 (−3,6)、低端通量 −3；未访问单元为零。

   .. rubric:: 主入口失败诊断

   ``test_driver_errors`` 调用 :doc:`主调度文件 </rst_files/J_Fluid/J01_free_molecular/sub_J01_free_molecular_mc_2Drz>`。
   两单元仅入口开放，每条轨迹最多一个事件；20 条历史都应截断，完成数为 0，并返回跟踪错误。
   将域边界错误标成内部面，应在推进前返回配置错误。

   .. rubric:: 判据与范围

   确定性标量使用 ``abs(actual-expected) <= 1e-11*max(1,abs(expected))``。失败时打印测试名和数值。
   本组已通过，``n_failed=0``，程序零状态退出。另有 :doc:`单网格总注入/出射守恒测试 <J01_tests>`。
   完整器件的采样收敛性及 J03 场测试见 :doc:`application_tests`，不能由这些小测试替代。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   The standalone suite checks partial-inlet areas and rate, sampling bounds, reflection signs,
   deterministic histories, residence/count normalization and truncation/configuration failures.
   It uses analytical expectations, not archived external solutions. Scalar tolerance is
   1e-11 times max(1, absolute expected value). All checks passed.
