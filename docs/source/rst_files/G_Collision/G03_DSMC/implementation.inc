.. _g03-stepper:
.. _g03-architecture:
.. _g03-cpp-acceptance:

一次 step 调用：从柱坐标粒子到速度提交
------------------------------------------------------------------------

公共头文件 ``G_Collision/G03_DSMC/dsmc.hpp`` 引入模型、柱坐标网格、粒子与步进器。
``DsmcStepper::step`` 完成一个碰撞子步；调用程序在此之前完成位置推进和边界处理。
入口定义在 ``stepper.hpp``，函数体位于 ``fun_G03_dsmc_stepper.cpp``：

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/stepper.hpp
   :language: cpp
   :start-at: class DsmcStepper {
   :end-before: private:
   :linenos:
   :lineno-match:
   :caption: stepper.hpp — DsmcStepper 的公开入口

.. list-table:: 四个参数怎样进入实现
   :header-rows: 1
   :widths: 23 37 40

   * - 参数
     - 携带什么
     - step 内怎样使用
   * - ``particles``
     - 柱坐标粒子数组的可写视图
     - 读入位置和局部速度；全部计算成功后只更新速度
   * - ``grid``
     - 三维柱坐标网格的只读引用
     - 同时提供位置定位、单元 ID 与真实体积
   * - ``context``
     - ``dt_s``、``global_step``、``seed``、``substep``
     - 时间步决定候选强度，其余标识确定可重放的随机流
   * - ``workspace``
     - 粒子快照、单元成员区间和待写回局部速度
     - 保存中间结果并复用已分配内存

``DsmcStepper`` 持有模型和 ``StepOptions``，后者选择候选调度、计算预算与事件记录方式。
一次调用期间，粒子数组和网格保持有效，调用程序保持粒子成员、位置和存储顺序不变。
下面的调用链使用源码中的实际函数名：

.. code-block:: text
   :caption: 一次碰撞步的执行顺序

   DsmcStepper::step                          fun_G03_dsmc_stepper.cpp
     grid.cells()                            借用网格已生成的有序单元
     detail::snapshot_particles              fun_G03_dsmc_particles.cpp
       检查 ID 与物种 → grid.locate → 转换为全局 xyz 速度
     按 (cell_id, id) 排序快照，建立 cell_offsets
     对每个单元调用 detail::collide_cell       fun_G03_dsmc_collision.cpp
       model.rate().majorant
       RoundedNtc 或 ContinuousClock
       均匀选对 → model.rate().kernel
       接受 → model.scattering().sample
       更新工作快照中的两个速度，检查守恒
     汇总 StepReport
     detail::prepare_particle_velocities      按原下标准备全部局部速度
     逐项赋值                                统一写回原始粒子数组

.. _g03-implementation-notation:

1. 从同一网格取得单元与粒子归属
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

入口先检查 ``dt_s`` 有限且非负，再借用 ``grid.cells()`` 返回的单元视图，生成粒子工作快照：

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_stepper.cpp
   :language: cpp
   :start-at: StepReport DsmcStepper::step
   :end-before:     std::sort(work.particles_
   :linenos:
   :lineno-match:
   :caption: fun_G03_dsmc_stepper.cpp — 取得单元视图并生成快照

``CylindricalGrid`` 在构造时已验证面坐标、体积与编号范围，并按 ID 顺序生成单元。
``snapshot_particles`` 使用这个网格的 ``locate`` 确定每个粒子的单元，检查粒子 ID 唯一、
物种与模型一致，并将局部速度转为共同全局基底下的速度。
因此，成员归属与候选强度中的体积来自同一套几何数据。
这些检查或转换失败时，只有工作区可能已发生变化，原始粒子速度保持调用前状态。

.. _g03-step-dataflow:
.. _g03-s10:

2. 排序与分组，把每个单元交给碰撞内核
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

按 ``(cell_id, id)`` 排序使同一单元的粒子连续排列，单元内的顺序由唯一 ID 决定。
这样，给定相同种子和物理数据，随机抽到的下标对应相同粒子。
排序仅作用于工作快照，原始数组中的位置由快照的 ``source_index`` 保存。
随后 ``cell_offsets_[c]`` 与 ``cell_offsets_[c+1]`` 给出第 c 个单元的半开区间：

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_stepper.cpp
   :language: cpp
   :start-at:     std::sort(work.particles_
   :end-before:     StepReport report;
   :linenos:
   :lineno-match:
   :caption: fun_G03_dsmc_stepper.cpp — 排序与 cell_offsets

每经过一个单元，循环先记录区间起点，再移动 ``cursor`` 越过该单元的全部粒子。
末尾额外记录一次终点，因此偏移数组的长度为单元数加一；空单元的起点和终点相等。
例如原始粒子 ID 为 ``[7,2,9,4]``，前两个属于单元 10，后两个属于单元 11，
排序后快照的 ID 为 ``[2,7 | 4,9]``，``source_index`` 为 ``[1,0 | 3,2]``，
成员区间为 ``[0,2)`` 与 ``[2,4)``。写回时使用保存的原下标。

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_stepper.cpp
   :language: cpp
   :start-at:     // 各单元独立处理
   :end-before:         report.candidates +=
   :linenos:
   :lineno-match:
   :caption: fun_G03_dsmc_stepper.cpp — 调用 detail::collide_cell

``group`` 是这一段工作粒子的可写 ``span``，直接引用工作区中的元素。
``collide_cell`` 接收成员视图、对应单元、模型、时间步和选项，
在内部选择 NTC 或连续时钟，随后共用选对、接受与散射过程。
函数声明位于 ``collision_kernel.hpp``，实现位于 ``fun_G03_dsmc_collision.cpp``；
Theory & Algorithm 的单元碰撞部分给出该函数的逐式推导。

.. _g03-output-dataflow:

3. 单元结果怎样汇总成整步报告
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``CellReport`` 保存本单元的候选数、接受数、拒绝数、核上界和相对守恒误差。
步进器累加计数并保存各单元报告；``StepReport`` 中的最大相对误差用于查看最差单元，
绝对残差则汇总全步收支。

对等权重、等质量的弹性体系，每单元代表的总动量与实验室系总动能为

.. math::
   :label: g03-eq-step-conservation

   \mathbf P_c^{\mathrm{tot}}=Wm\sum_{i\in c}\mathbf v_i,\qquad
   E_c^{\mathrm{lab}}=\frac{Wm}{2}\sum_{i\in c}|\mathbf v_i|^2.

单元内核在固定参考速度下累计碰前、碰后矩，并用中心热运动尺度归一化相对误差，
以分辨强共同漂移下的热能偏差。相对误差超过容差时抛出异常。
报告中的绝对动量与能量残差已乘以 ``model.weight() * model.species().mass_kg``，
分别使用 kg m/s 和 J；动量分量采用全局 xyz 基底。

可选 ``EventRecord`` 记录接受事件的粒子 ID 与碰前、碰后全局速度。
连续时钟的 ``time_offset_s`` 给出相对于碰撞子步起点的时间；随机舍入 NTC 中该字段为空。
日志容量限制记录数量，候选预算限制允许执行的候选数量；预算不足会使本步失败。

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/stepper.hpp
   :language: cpp
   :start-at: struct StepReport
   :end-before: namespace detail {
   :linenos:
   :lineno-match:
   :caption: stepper.hpp — StepReport

4. 全部局部速度准备成功后再写回
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

完成所有单元的碰撞与报告检查后，``prepare_particle_velocities`` 按 ``source_index``
准备原始数组顺序下的局部速度。全部反变换和所需内存分配都在这个阶段完成。
准备成功后，最后的循环只进行速度赋值：

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_stepper.cpp
   :language: cpp
   :start-at:     // 全部单元成功后
   :end-before: } // namespace
   :linenos:
   :lineno-match:
   :caption: fun_G03_dsmc_stepper.cpp — 准备与统一写回

后续单元或任一反变换失败时，前面的计算结果仍只保存在工作区。
原始粒子的 ID、物种和位置在成功调用后也保持原值。
“粒子数据：柱坐标记录、碰撞快照与写回”一节展开快照结构与准备函数，
解释如何保留未变化粒子的原始局部速度。

.. _g03-application:

参数与时间循环的组织见 :ref:`Tests 的当前接口示例 <g03-current-examples>`。

.. _g03-s13:
.. _g03-test-callchain:

本模块的检查方法与判据见 :ref:`测试说明 <g03-validation-implementation>`。
