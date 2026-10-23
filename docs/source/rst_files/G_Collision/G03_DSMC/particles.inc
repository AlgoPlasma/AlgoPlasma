.. _g03-particles:

粒子数据：柱坐标记录、碰撞快照与写回
------------------------------------------------------------------------

本节沿 ``particles.hpp`` 和 ``fun_G03_dsmc_particles.cpp`` 的源码说明数据读取与写回。
公开粒子记录保存调用程序使用的柱坐标量；碰撞工作区保存共同全局基底下的速度。
``snapshot_particles`` 与 ``prepare_particle_velocities`` 完成两种表示之间的衔接，
它们的内部声明集中在 ``collision_kernel.hpp``。

公开记录与内部快照分别保存什么
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``step`` 接收的数组元素类型为 ``CylindricalParticleState``：

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/particles.hpp
   :language: cpp
   :start-at: struct CylindricalParticleState
   :end-before: } // namespace
   :linenos:
   :lineno-match:
   :caption: particles.hpp — CylindricalParticleState

``id`` 标识一个模拟粒子，``species_id`` 与模型中的物种 ID 对应。
``position`` 保存 :math:`(r,\theta,z)`，单位分别为 m、rad、m；
``velocity_mps`` 保存该方位角基底下的 :math:`(v_r,v_\theta,v_z)`，单位均为 m/s。
其中 :math:`v_\theta=r\dot\theta` 是物理切向速度。分子质量与统一权重由 ``DsmcModel`` 提供。

工作区元素 ``detail::CollisionParticle`` 定义在 ``stepper.hpp``，供内部碰撞过程使用：

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/stepper.hpp
   :language: cpp
   :start-at: struct CollisionParticle
   :end-before: } // namespace detail
   :linenos:
   :lineno-match:
   :caption: stepper.hpp — detail::CollisionParticle

.. list-table:: 工作快照中的字段
   :header-rows: 1
   :widths: 34 66

   * - 字段
     - 用途
   * - ``id``
     - 确定单元内排序，并标识事件记录中的粒子
   * - ``cell_id``
     - 保存 ``grid.locate(position)`` 的结果，供单元分组使用
   * - ``velocity_mps``
     - 当前全局 xyz 速度；碰撞内核更新这个字段
   * - ``initial_velocity_mps``
     - 快照刚建立时的全局速度，用于判断最终速度是否保持原值
   * - ``source_index``
     - 该粒子在原始数组中的下标，随工作记录一起排序，最后用于直接写回

物种在建立快照时统一校验；每个单元的碰撞函数随后只需成员、速度、质量与权重。
位置留在原始记录中，用于定位和恢复局部速度基底。

snapshot_particles：校验、定位与速度转换
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_particles.cpp
   :language: cpp
   :start-at: void snapshot_particles
   :end-before: void prepare_particle_velocities
   :linenos:
   :lineno-match:
   :caption: fun_G03_dsmc_particles.cpp — snapshot_particles

``out.clear()`` 清除上次调用留下的工作记录，``reserve`` 为本次粒子数预留容量。
循环中的 ``i`` 是原始数组下标；``ids.insert(...).second`` 检查 ID 是否第一次出现，
随后将 ``species_id`` 与模型传入的物种 ID 比较。

``grid.locate`` 校验位置并返回所属单元；域外位置得到空结果，在这里转为错误。
因此调用程序应在进入碰撞子步前完成出流、入流和边界处理。
``to_cartesian_velocity`` 检查局部速度与角度的有限性，并使用当前粒子的方位角进行转换。
所有粒子的工作速度由此具有共同基底，可以直接相减得到物理相对速度。

最后的 ``push_back`` 依次保存粒子 ID、单元 ID、两份相同的初始全局速度以及原下标。
碰撞仅更新第一份速度，第二份在本次调用内保持不变。
这里从原始数组读取数据；检查、分配或转换失败时，原始速度仍保持调用前状态。

prepare_particle_velocities：恢复原下标与局部速度
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

碰撞结束后，工作快照按单元与粒子 ID 排列。
准备函数用每条记录的 ``source_index`` 找到原始粒子，并把结果放入相同下标的待写回数组：

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_particles.cpp
   :language: cpp
   :start-at: void prepare_particle_velocities
   :end-before: } // namespace
   :linenos:
   :lineno-match:
   :caption: fun_G03_dsmc_particles.cpp — prepare_particle_velocities

``pending.resize`` 建立与原粒子数组等长的缓冲区。
``source`` 给出该粒子的原方位角和原局部速度，``velocity`` 是最终全局速度，
``initial`` 是保存的初始全局速度。
三个分量逐项相等时，函数直接保留 ``source.velocity_mps``；
速度发生变化时，才调用 ``to_cylindrical_velocity`` 恢复该粒子的局部表示。
这使零时间步、未发生碰撞或最终速度保持原值的粒子避免反复坐标往返造成的舍入漂移。

每个原下标在快照中恰好出现一次，因此准备结束时缓冲区的每个元素都已确定。
步进器随后逐项赋值完成写回；若准备期间发生异常，原始数组尚未被修改。
一次 ``step`` 期间，调用程序须保持粒子数组和网格有效，且不修改粒子成员、位置、速度和存储顺序。
同一粒子数组及同一工作区各由一次调用独占。

本模块的检查方法与判据见 :ref:`测试说明 <g03-validation-particles>`。
