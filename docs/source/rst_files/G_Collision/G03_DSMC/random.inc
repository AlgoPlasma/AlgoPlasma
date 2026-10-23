.. _g03-random:

Random Sampling and Reproducibility
------------------------------------------------------------------------

.. container:: ap-lang ap-lang-zh

   本节对应 ``random.hpp``。碰撞抽样只需要均匀实数、无偏整数索引以及按用途分开的随机流。
   这里从这三个要求逐一读出实现；初始化速度分布的抽样由算例自行组织。

.. container:: ap-lang ap-lang-en

   This section follows ``random.hpp``. Collision sampling needs uniform real variates,
   unbiased integer indices and purpose-separated random streams. Initial velocity-distribution
   sampling is organized by the examples.

Endpoints for Acceptance and Exponential Waiting
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   接受判定使用 :math:`R\in[0,1)`：零概率事件永不接受，概率为 1 时总能接受。
   ``uniform`` 从 64 位整数中取高 53 位，再乘 :math:`2^{-53}`。
   ``open_uniform`` 用高 52 位加半个格点，再乘 :math:`2^{-52}`，
   使数值严格位于 :math:`(0,1)`，适合连续候选时钟中的 :math:`-\ln U`。
   它们分别是连续均匀分布在有限浮点精度下的离散表示。

.. container:: ap-lang ap-lang-en

   Acceptance uses :math:`R\in[0,1)`: probability-zero events are always rejected and
   probability-one events always accepted. ``uniform`` takes the high 53 bits of a 64-bit integer
   and multiplies by :math:`2^{-53}`. ``open_uniform`` takes the high 52 bits, adds half a grid
   spacing and multiplies by :math:`2^{-52}`. Its values lie strictly inside :math:`(0,1)`, as
   required by :math:`-\ln U` in the continuous clock. Both are finite-precision discrete
   representations of continuous uniform variates.

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/random.hpp
   :language: cpp
   :caption: random.hpp · RandomStream::uniform / open_uniform — endpoint conventions
   :linenos:
   :lineno-match:
   :start-at: // [0, 1)
   :end-before: std::uint64_t index

Unbiased Integer Indices for Uniform Pair Selection
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   64 位整数的总个数 :math:`2^{64}` 未必被 :math:`n` 整除，直接取余会让部分余数多出现一次。
   对正整数 :math:`n`，令 :math:`b=2^{64}\bmod n`，先舍弃小于 :math:`b` 的整数，再对 :math:`n` 取余。
   保留下来的区间长度可被 :math:`n` 整除，每个余数出现相同次数。
   无符号算术中的 ``(uint64_t{0} - n) % n`` 正好给出这个阈值。

.. container:: ap-lang ap-lang-en

   The :math:`2^{64}` possible integers need not divide evenly into :math:`n` residues.
   A direct remainder would give some indices one extra preimage. For positive :math:`n`, let
   :math:`b=2^{64}\bmod n`; reject integers below :math:`b`, then take the remainder modulo
   :math:`n`. The retained interval has length divisible by :math:`n`, so every index occurs
   equally often. Unsigned ``(uint64_t{0} - n) % n`` evaluates exactly this threshold.

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/random.hpp
   :language: cpp
   :caption: random.hpp · RandomStream::index — rejecting an incomplete residue cycle
   :linenos:
   :lineno-match:
   :start-at: std::uint64_t index
   :end-before: private:

.. container:: ap-lang ap-lang-zh

   单元碰撞中第一次调用 ``index(N)`` 得到 :math:`i`，第二次调用 ``index(N-1)``
   再跳过 :math:`i` 得到 :math:`j`，从而实现前面推导的均匀无序配对。
   拒绝整数样本时仅继续消费本次选对流，接受和散射使用其他用途的流。

.. container:: ap-lang ap-lang-en

   The collision loop draws :math:`i` with ``index(N)``, then draws ``index(N-1)`` and skips
   :math:`i` to obtain :math:`j`. This implements the uniform unordered pairing derived above.
   An integer rejection consumes only the current pair-selection stream; acceptance and scattering
   use different purposes.

Assigning Random Streams to Physical Tasks
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   当前随机流由以下键确定：

.. container:: ap-lang ap-lang-en

   The present stream identity consists of the following keys:

.. code-block:: text

   seed / global_step / cell_id / candidate_index / purpose / substep

.. container:: ap-lang ap-lang-zh

   步进器先按单元 ID、粒子 ID 排序，同一物理单元的同一候选因而面对同一组有序样本。
   构造函数混合这些稳定标识来初始化 ``state_``；原始粒子数组中的临时存储索引不参与流身份。

.. container:: ap-lang ap-lang-en

   The stepper sorts by cell ID and particle ID, so a candidate in a given physical cell
   sees the same ordered samples. The constructor mixes these stable identifiers into ``state_``.
   Temporary storage indices in the original particle array are excluded from stream identity.

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/random.hpp
   :language: cpp
   :caption: random.hpp · RandomStream constructor — initializing streams from stable task identifiers
   :linenos:
   :lineno-match:
   :start-at: RandomStream(std::uint64_t seed
   :end-before: std::uint64_t next()

.. container:: ap-lang ap-lang-zh

   舍入、选对、接受、散射与连续候选时钟使用不同用途值，各自消费随机序列。
   概率推导采用独立均匀抽样；代码用这些分流的伪随机序列实现抽样。
   这些数值属于重放约定，修改数值会改变轨迹：

.. container:: ap-lang ap-lang-en

   Rounding, pair selection, acceptance, scattering and the continuous clock use separate
   purpose values and consume separate sequences. The probability derivations use independent
   uniform variates; the implementation approximates them with these split pseudorandom streams.
   Purpose numbers form part of the replay convention: changing them changes trajectories.

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/random.hpp
   :language: cpp
   :caption: random.hpp · random_purpose — collision sampling purposes
   :linenos:
   :lineno-match:
   :start-at: namespace random_purpose
   :end-before: // 用种子

.. container:: ap-lang ap-lang-zh

   连续时钟在每个候选使用 ``candidate_clock``，并从 ``open_uniform`` 抽取等待强度。
   越过子步末端的最后一次等待用于判断结束，报告只统计实际进入选对过程的候选。
   不同物理时间步或子步需要提供不同的键；重复全部标识会重用同一随机流。

.. container:: ap-lang ap-lang-en

   Each clock candidate uses ``candidate_clock`` and draws integrated waiting intensity with
   ``open_uniform``. The final wait crossing the substep end only determines termination;
   reported candidates count those that actually reach pair selection. Different physical steps
   or substeps need different keys. Repeating every identifier reuses the same stream.

.. container:: ap-lang ap-lang-zh

   逐位重放以相同的平台、编译选项、数学库和算法版本为前提。
   源码当前按单元串行调度；稳定单元流为未来并行保留了条件，
   共享预算与报告汇总还需随并行策略确定。
   随机流内部只保存当前状态，``DsmcWorkspace`` 保存单步工作数据。

.. container:: ap-lang ap-lang-en

   Bitwise replay assumes the same platform, compiler options, mathematical library and
   algorithm version. Current cell scheduling is serial. Stable cell streams provide a basis for
   future parallel execution, whose shared budgets and report reductions still need a defined
   policy. A random stream stores only its current state; ``DsmcWorkspace`` stores step working data.

.. container:: ap-lang ap-lang-zh

   本模块的检查方法与判据见 :ref:`测试说明 <g03-validation-random>`。

.. container:: ap-lang ap-lang-en

   Checks and acceptance criteria are given in :ref:`the test documentation <g03-validation-random>`.
