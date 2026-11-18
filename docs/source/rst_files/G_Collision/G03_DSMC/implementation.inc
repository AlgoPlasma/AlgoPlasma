.. _g03-stepper:

.. _g03-architecture:

.. _g03-cpp-acceptance:

One Step: Cylindrical Particles to Velocity Commit
------------------------------------------------------------------------

.. container:: ap-lang ap-lang-zh

   公共头文件 ``G_Collision/G03_DSMC/dsmc.hpp`` 引入模型、柱坐标网格、粒子与步进器。
   ``DsmcStepper::step`` 完成一个碰撞子步；调用程序在此之前完成位置推进和边界处理。
   入口定义在 ``stepper.hpp``，函数体位于 ``fun_G03_dsmc_stepper.cpp``：

.. container:: ap-lang ap-lang-en

   The public header ``G_Collision/G03_DSMC/dsmc.hpp`` brings together the model, cylindrical grid, particles and stepper.
   ``DsmcStepper::step`` advances one collision substep; the calling program advances positions and handles boundaries beforehand.
   The declaration is in ``stepper.hpp`` and the definition is in ``fun_G03_dsmc_stepper.cpp``:

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/stepper.hpp
   :language: cpp
   :start-at: class DsmcStepper {
   :end-before: private:
   :linenos:
   :lineno-match:
   :caption: stepper.hpp — DsmcStepper public interface

.. container:: ap-lang ap-lang-zh

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

.. container:: ap-lang ap-lang-en

   .. list-table:: How the four arguments enter the implementation
      :header-rows: 1
      :widths: 23 37 40

      * - Argument
        - Contents
        - Use within step
      * - ``particles``
        - Writable view of the cylindrical particle array
        - Read positions and local velocities; update velocities after every calculation succeeds
      * - ``grid``
        - Read-only reference to the three-dimensional cylindrical grid
        - Supply location, cell IDs and physical volumes
      * - ``context``
        - ``dt_s``, ``global_step``, ``seed``, ``substep``
        - Set candidate intensity and the keys of reproducible random streams
      * - ``workspace``
        - Particle snapshots, cell ranges and pending local velocities
        - Hold intermediate results and reuse allocated memory

.. container:: ap-lang ap-lang-zh

   ``DsmcStepper`` 持有模型和 ``StepOptions``，后者选择候选调度、计算预算与事件记录方式。
   一次调用期间，粒子数组和网格保持有效，调用程序保持粒子成员、位置和存储顺序不变。
   下面的调用链使用源码中的实际函数名：

.. container:: ap-lang ap-lang-en

   ``DsmcStepper`` owns the model and ``StepOptions``, which select the candidate schedule, computational budgets and event recording.
   Throughout a call, the particle array and grid remain valid, and the calling program preserves membership, positions and storage order.
   The following call chain uses the actual source names:

.. container:: ap-lang ap-lang-zh

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

.. container:: ap-lang ap-lang-en

   .. code-block:: text
      :caption: Execution order of one collision step

      DsmcStepper::step                          fun_G03_dsmc_stepper.cpp
        grid.cells()                            borrow the grid's ordered cells
        detail::snapshot_particles              fun_G03_dsmc_particles.cpp
          check IDs and species -> grid.locate -> convert to global xyz velocities
        sort snapshots by (cell_id, id), build cell_offsets
        call detail::collide_cell for each cell  fun_G03_dsmc_collision.cpp
          model.rate().majorant
          RoundedNtc or ContinuousClock
          select a uniform pair -> model.rate().kernel
          accept -> model.scattering().sample
          update the two snapshot velocities and check conservation
        accumulate StepReport
        detail::prepare_particle_velocities      prepare local velocities by original index
        assign velocities                       commit to the original particle array

.. _g03-implementation-notation:

1. Read Cells and Particle Membership from One Grid
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   入口先检查 ``dt_s`` 有限且非负，再借用 ``grid.cells()`` 返回的单元视图，生成粒子工作快照：

.. container:: ap-lang ap-lang-en

   The entry checks that ``dt_s`` is finite and nonnegative, borrows the cell view returned by ``grid.cells()``,
   and creates a working particle snapshot:

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_stepper.cpp
   :language: cpp
   :start-at: StepReport DsmcStepper::step
   :end-before:     std::sort(work.particles_
   :linenos:
   :lineno-match:
   :caption: fun_G03_dsmc_stepper.cpp — cell view and snapshot creation

.. container:: ap-lang ap-lang-zh

   ``CylindricalGrid`` 在构造时已验证面坐标、体积与编号范围，并按 ID 顺序生成单元。
   ``snapshot_particles`` 使用这个网格的 ``locate`` 确定每个粒子的单元，检查粒子 ID 唯一、
   物种与模型一致，并将局部速度转为共同全局基底下的速度。
   因此，成员归属与候选强度中的体积来自同一套几何数据。
   这些检查或转换失败时，只有工作区可能已发生变化，原始粒子速度保持调用前状态。

.. container:: ap-lang ap-lang-en

   The ``CylindricalGrid`` constructor has already validated face coordinates, volumes and ID ranges, and generated cells in ID order.
   ``snapshot_particles`` uses this same grid's ``locate`` operation, checks unique particle IDs and agreement with the model's species,
   and converts local velocities to a common global basis. Membership and the volume in the candidate intensity therefore come from the same geometry.
   A failed check or conversion may change the workspace; original particle velocities retain their incoming values.

.. _g03-step-dataflow:

.. _g03-s10:

2. Sort, Group and Call the Cell Kernel
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   按 ``(cell_id, id)`` 排序使同一单元的粒子连续排列，单元内的顺序由唯一 ID 决定。
   这样，给定相同种子和物理数据，随机抽到的下标对应相同粒子。
   排序仅作用于工作快照，原始数组中的位置由快照的 ``source_index`` 保存。
   随后 ``cell_offsets_[c]`` 与 ``cell_offsets_[c+1]`` 给出第 c 个单元的半开区间：

.. container:: ap-lang ap-lang-en

   Sorting by ``(cell_id, id)`` makes each cell's particles contiguous and orders its members by unique ID.
   With the same seed and physical data, a sampled index then identifies the same particle.
   Only the working snapshot is sorted; ``source_index`` retains the original array position.
   The half-open range of cell c is given by ``cell_offsets_[c]`` and ``cell_offsets_[c+1]``:

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_stepper.cpp
   :language: cpp
   :start-at:     std::sort(work.particles_
   :end-before:     StepReport report;
   :linenos:
   :lineno-match:
   :caption: fun_G03_dsmc_stepper.cpp — sorting and cell_offsets

.. container:: ap-lang ap-lang-zh

   每经过一个单元，循环先记录区间起点，再移动 ``cursor`` 越过该单元的全部粒子。
   末尾额外记录一次终点，因此偏移数组的长度为单元数加一；空单元的起点和终点相等。
   例如原始粒子 ID 为 ``[7,2,9,4]``，前两个属于单元 10，后两个属于单元 11，
   排序后快照的 ID 为 ``[2,7 | 4,9]``，``source_index`` 为 ``[1,0 | 3,2]``，
   成员区间为 ``[0,2)`` 与 ``[2,4)``。写回时使用保存的原下标。

.. container:: ap-lang ap-lang-en

   For each cell, the loop records its starting offset and advances ``cursor`` past all its particles.
   The final endpoint makes the offset array one element longer than the cell count; an empty cell has equal start and end offsets.
   For example, original IDs ``[7,2,9,4]`` in cells 10,10,11,11 become ``[2,7 | 4,9]``,
   with ``source_index`` values ``[1,0 | 3,2]`` and member ranges ``[0,2)`` and ``[2,4)``.
   Writeback uses those saved original indices.

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_stepper.cpp
   :language: cpp
   :start-at:     // 各单元独立处理
   :end-before:         report.candidates +=
   :linenos:
   :lineno-match:
   :caption: fun_G03_dsmc_stepper.cpp — detail::collide_cell

.. container:: ap-lang ap-lang-zh

   ``group`` 是这一段工作粒子的可写 ``span``，直接引用工作区中的元素。
   ``collide_cell`` 接收成员视图、对应单元、模型、时间步和选项，
   在内部选择 NTC 或连续时钟，随后共用选对、接受与散射过程。
   函数声明位于 ``collision_kernel.hpp``，实现位于 ``fun_G03_dsmc_collision.cpp``；
   Theory & Algorithm 的单元碰撞部分给出该函数的逐式推导。

.. container:: ap-lang ap-lang-en

   ``group`` is a writable ``span`` directly referring to this cell's working records.
   ``collide_cell`` receives the members, cell, model, timestep and options.
   It selects NTC or the continuous clock, then shares pair selection, acceptance and scattering.
   Its declaration is in ``collision_kernel.hpp`` and its implementation in ``fun_G03_dsmc_collision.cpp``;
   the cell-collision section of Theory & Algorithm derives its equations.

.. _g03-output-dataflow:

3. Accumulate Cell Results into a Step Report
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   ``CellReport`` 保存本单元的候选数、接受数、拒绝数、核上界和相对守恒误差。
   步进器累加计数并保存各单元报告；``StepReport`` 中的最大相对误差用于查看最差单元，
   绝对残差则汇总全步收支。

.. container:: ap-lang ap-lang-en

   ``CellReport`` stores candidate, accepted and rejected counts, the kernel majorant and relative conservation errors.
   The stepper accumulates counts and retains the individual cell reports.
   Maximum relative errors in ``StepReport`` identify the worst cell; absolute residuals summarize the whole-step balance.

.. container:: ap-lang ap-lang-zh

   对等权重、等质量的弹性体系，每单元代表的总动量与实验室系总动能为

.. container:: ap-lang ap-lang-en

   For equal-weight, equal-mass elastic particles, the physical momentum and laboratory-frame kinetic energy represented by a cell are

.. math::
   :label: g03-eq-step-conservation

   \mathbf P_c^{\mathrm{tot}}=Wm\sum_{i\in c}\mathbf v_i,\qquad
   E_c^{\mathrm{lab}}=\frac{Wm}{2}\sum_{i\in c}|\mathbf v_i|^2.

.. container:: ap-lang ap-lang-zh

   单元内核在固定参考速度下累计碰前、碰后矩，并用中心热运动尺度归一化相对误差，
   以分辨强共同漂移下的热能偏差。相对误差超过容差时抛出异常。
   报告中的绝对动量与能量残差已乘以 ``model.weight() * model.species().mass_kg``，
   分别使用 kg m/s 和 J；动量分量采用全局 xyz 基底。

.. container:: ap-lang ap-lang-en

   The cell kernel accumulates pre- and post-collision moments about a fixed reference velocity and normalizes relative errors by the centered thermal scale.
   This resolves thermal-energy errors even under a strong common drift; an error above the tolerance raises an exception.
   Absolute momentum and energy residuals in the report include the factor ``model.weight() * model.species().mass_kg``.
   Their units are kg m/s and J, and momentum components use the global xyz basis.

.. container:: ap-lang ap-lang-zh

   可选 ``EventRecord`` 记录接受事件的粒子 ID 与碰前、碰后全局速度。
   连续时钟的 ``time_offset_s`` 给出相对于碰撞子步起点的时间；随机舍入 NTC 中该字段为空。
   日志容量限制记录数量，候选预算限制允许执行的候选数量；预算不足会使本步失败。

.. container:: ap-lang ap-lang-en

   Optional ``EventRecord`` entries contain the accepted pair's IDs and global velocities before and after collision.
   For the continuous clock, ``time_offset_s`` is measured from the collision substep's start; it is empty for randomly rounded NTC.
   The log capacity limits stored records, while candidate budgets limit computation; exceeding a budget fails the step.

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/stepper.hpp
   :language: cpp
   :start-at: struct StepReport
   :end-before: namespace detail {
   :linenos:
   :lineno-match:
   :caption: stepper.hpp — StepReport

4. Prepare All Local Velocities Before Writeback
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   完成所有单元的碰撞与报告检查后，``prepare_particle_velocities`` 按 ``source_index``
   准备原始数组顺序下的局部速度。全部反变换和所需内存分配都在这个阶段完成。
   准备成功后，最后的循环只进行速度赋值：

.. container:: ap-lang ap-lang-en

   After every cell and report check succeeds, ``prepare_particle_velocities`` uses ``source_index`` to prepare local velocities in original array order.
   All reverse transformations and required allocation occur during preparation.
   The final loop then performs only velocity assignments:

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_stepper.cpp
   :language: cpp
   :start-at:     // 全部单元成功后
   :end-before: } // namespace
   :linenos:
   :lineno-match:
   :caption: fun_G03_dsmc_stepper.cpp — preparation and velocity commit

.. container:: ap-lang ap-lang-zh

   后续单元或任一反变换失败时，前面的计算结果仍只保存在工作区。
   原始粒子的 ID、物种和位置在成功调用后也保持原值。
   “粒子数据：柱坐标记录、碰撞快照与写回”一节展开快照结构与准备函数，
   解释如何保留未变化粒子的原始局部速度。

.. container:: ap-lang ap-lang-en

   If a later cell or any reverse transformation fails, earlier results remain confined to the workspace.
   Particle IDs, species and positions also retain their original values after a successful call.
   The particle-data section below explains the snapshot and preparation functions, including exact preservation of unchanged local velocities.

.. _g03-application:

.. rubric:: Application Setup

.. container:: ap-lang ap-lang-zh

   参数与时间循环的组织见 :ref:`Tests 的当前接口示例 <g03-current-examples>`。

.. container:: ap-lang ap-lang-en

   Parameter setup and the time loop are described in :ref:`the current-interface test example <g03-current-examples>`.

.. _g03-s13:

.. _g03-test-callchain:

.. rubric:: Verification

.. container:: ap-lang ap-lang-zh

   本模块的检查方法与判据见 :ref:`测试说明 <g03-validation-implementation>`。

.. container:: ap-lang ap-lang-en

   Checks and pass criteria for this module are described in :ref:`the validation page <g03-validation-implementation>`.
