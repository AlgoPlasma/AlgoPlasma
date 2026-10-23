.. _g03-random:

随机抽样与可复现性
------------------------------------------------------------------------

本节对应 ``random.hpp``。碰撞抽样只需要均匀实数、无偏整数索引以及按用途分开的随机流。
这里从这三个要求逐一读出实现；初始化速度分布的抽样由算例自行组织。

接受判定与指数等待需要哪些端点
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

接受判定使用 :math:`R\in[0,1)`：零概率事件永不接受，概率为 1 时总能接受。
``uniform`` 从 64 位整数中取高 53 位，再乘 :math:`2^{-53}`。
``open_uniform`` 用高 52 位加半个格点，再乘 :math:`2^{-52}`，
使数值严格位于 :math:`(0,1)`，适合连续候选时钟中的 :math:`-\ln U`。
它们分别是连续均匀分布在有限浮点精度下的离散表示。

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/random.hpp
   :language: cpp
   :caption: random.hpp · RandomStream::uniform / open_uniform：端点约定
   :linenos:
   :lineno-match:
   :start-at: // [0, 1)
   :end-before: std::uint64_t index

无偏整数索引如何实现均匀选对
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

64 位整数的总个数 :math:`2^{64}` 未必被 :math:`n` 整除，直接取余会让部分余数多出现一次。
对正整数 :math:`n`，令 :math:`b=2^{64}\bmod n`，先舍弃小于 :math:`b` 的整数，再对 :math:`n` 取余。
保留下来的区间长度可被 :math:`n` 整除，每个余数出现相同次数。
无符号算术中的 ``(uint64_t{0} - n) % n`` 正好给出这个阈值。

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/random.hpp
   :language: cpp
   :caption: random.hpp · RandomStream::index：拒绝不完整的余数周期
   :linenos:
   :lineno-match:
   :start-at: std::uint64_t index
   :end-before: private:

单元碰撞中第一次调用 ``index(N)`` 得到 :math:`i`，第二次调用 ``index(N-1)``
再跳过 :math:`i` 得到 :math:`j`，从而实现前面推导的均匀无序配对。
拒绝整数样本时仅继续消费本次选对流，接受和散射使用其他用途的流。

随机流怎样归属到物理任务
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

当前随机流由以下键确定：

.. code-block:: text

   seed / global_step / cell_id / candidate_index / purpose / substep

步进器先按单元 ID、粒子 ID 排序，同一物理单元的同一候选因而面对同一组有序样本。
构造函数混合这些稳定标识来初始化 ``state_``；原始粒子数组中的临时存储索引不参与流身份。

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/random.hpp
   :language: cpp
   :caption: random.hpp · RandomStream 构造函数：从稳定任务标识初始化随机流
   :linenos:
   :lineno-match:
   :start-at: RandomStream(std::uint64_t seed
   :end-before: std::uint64_t next()

舍入、选对、接受、散射与连续候选时钟使用不同用途值，各自消费随机序列。
概率推导采用独立均匀抽样；代码用这些分流的伪随机序列实现抽样。
这些数值属于重放约定，修改数值会改变轨迹：

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/random.hpp
   :language: cpp
   :caption: random.hpp · random_purpose：碰撞抽样用途
   :linenos:
   :lineno-match:
   :start-at: namespace random_purpose
   :end-before: // 用种子

连续时钟在每个候选使用 ``candidate_clock``，并从 ``open_uniform`` 抽取等待强度。
越过子步末端的最后一次等待用于判断结束，报告只统计实际进入选对过程的候选。
不同物理时间步或子步需要提供不同的键；重复全部标识会重用同一随机流。

逐位重放以相同的平台、编译选项、数学库和算法版本为前提。
源码当前按单元串行调度；稳定单元流为未来并行保留了条件，
共享预算与报告汇总还需随并行策略确定。
随机流内部只保存当前状态，``DsmcWorkspace`` 保存单步工作数据。

本模块的检查方法与判据见 :ref:`测试说明 <g03-validation-random>`。
