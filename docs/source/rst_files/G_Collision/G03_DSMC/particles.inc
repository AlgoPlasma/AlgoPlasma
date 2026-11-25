.. _g03-particles:

Particle Data: Cylindrical Records, Snapshots and Writeback
------------------------------------------------------------------------

.. container:: ap-lang ap-lang-zh

   本节沿 ``particles.hpp`` 和 ``fun_G03_dsmc_particles.cpp`` 的源码说明数据读取与写回。
   公开粒子记录保存调用程序使用的柱坐标量；碰撞工作区保存共同全局基底下的速度。
   ``snapshot_particles`` 与 ``prepare_particle_velocities`` 完成两种表示之间的衔接，
   它们的内部声明集中在 ``collision_kernel.hpp``。

.. container:: ap-lang ap-lang-en

   This section follows ``particles.hpp`` and ``fun_G03_dsmc_particles.cpp`` through input reading and velocity writeback.
   Public records store the cylindrical quantities used by the calling program; the collision workspace stores velocities in a common global basis.
   ``snapshot_particles`` and ``prepare_particle_velocities`` connect these representations.
   Their internal declarations are collected in ``collision_kernel.hpp``.

Public Records and Internal Snapshots
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   ``step`` 接收的数组元素类型为 ``CylindricalParticleState``：

.. container:: ap-lang ap-lang-en

   The array elements passed to ``step`` have type ``CylindricalParticleState``:

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/particles.hpp
   :language: cpp
   :start-at: struct CylindricalParticleState
   :end-before: } // namespace
   :linenos:
   :lineno-match:
   :caption: particles.hpp — CylindricalParticleState

.. container:: ap-lang ap-lang-zh

   ``id`` 标识一个模拟粒子，``species_id`` 与模型中的物种 ID 对应。
   ``position`` 保存 :math:`(r,\theta,z)`，单位分别为 m、rad、m；
   ``velocity_mps`` 保存该方位角基底下的 :math:`(v_r,v_\theta,v_z)`，单位均为 m/s。
   其中 :math:`v_\theta=r\dot\theta` 是物理切向速度。分子质量与统一权重由 ``DsmcModel`` 提供。

.. container:: ap-lang ap-lang-en

   ``id`` identifies one simulated particle; ``species_id`` matches the model's species ID.
   ``position`` stores :math:`(r,\theta,z)` in m, rad and m.
   ``velocity_mps`` stores :math:`(v_r,v_\theta,v_z)` in the basis at that azimuth, with all components in m/s.
   Here :math:`v_\theta=r\dot\theta` is physical tangential speed.
   ``DsmcModel`` supplies the molecular mass and uniform statistical weight.

.. container:: ap-lang ap-lang-zh

   工作区元素 ``detail::CollisionParticle`` 定义在 ``stepper.hpp``，供内部碰撞过程使用：

.. container:: ap-lang ap-lang-en

   The workspace element ``detail::CollisionParticle`` is defined in ``stepper.hpp`` for the internal collision calculation:

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/stepper.hpp
   :language: cpp
   :start-at: struct CollisionParticle
   :end-before: } // namespace detail
   :linenos:
   :lineno-match:
   :caption: stepper.hpp — detail::CollisionParticle

.. container:: ap-lang ap-lang-zh

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

.. container:: ap-lang ap-lang-en

   .. list-table:: Fields in a working snapshot
      :header-rows: 1
      :widths: 34 66

      * - Field
        - Purpose
      * - ``id``
        - Determine member order and identify particles in event records
      * - ``cell_id``
        - Store the result of ``grid.locate(position)`` for cell grouping
      * - ``velocity_mps``
        - Current global xyz velocity, updated by the collision kernel
      * - ``initial_velocity_mps``
        - Initial global velocity, retained to recognize an unchanged final velocity
      * - ``source_index``
        - Original array index, sorted with the working record and used for direct writeback

.. container:: ap-lang ap-lang-zh

   物种在建立快照时统一校验；每个单元的碰撞函数随后只需成员、速度、质量与权重。
   位置留在原始记录中，用于定位和恢复局部速度基底。

.. container:: ap-lang ap-lang-en

   Species consistency is checked once while constructing snapshots.
   Cell collisions subsequently need the members, velocities, mass and weight.
   Positions remain in the original records for location and recovery of the local velocity basis.

snapshot_particles: Validation, Location and Velocity Conversion
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_particles.cpp
   :language: cpp
   :start-at: void snapshot_particles
   :end-before: void prepare_particle_velocities
   :linenos:
   :lineno-match:
   :caption: fun_G03_dsmc_particles.cpp — snapshot_particles

.. container:: ap-lang ap-lang-zh

   ``out.clear()`` 清除上次调用留下的工作记录，``reserve`` 为本次粒子数预留容量。
   循环中的 ``i`` 是原始数组下标；``ids.insert(...).second`` 检查 ID 是否第一次出现，
   随后将 ``species_id`` 与模型传入的物种 ID 比较。

.. container:: ap-lang ap-lang-en

   ``out.clear()`` removes records from the previous call, and ``reserve`` reserves space for the current particle count.
   The loop index ``i`` is the original array index.
   ``ids.insert(...).second`` tests whether an ID appears for the first time, after which ``species_id`` is compared with the model's ID.

.. container:: ap-lang ap-lang-zh

   ``grid.locate`` 校验位置并返回所属单元；域外位置得到空结果，在这里转为错误。
   因此调用程序应在进入碰撞子步前完成出流、入流和边界处理。
   ``to_cartesian_velocity`` 检查局部速度与角度的有限性，并使用当前粒子的方位角进行转换。
   所有粒子的工作速度由此具有共同基底，可以直接相减得到物理相对速度。

.. container:: ap-lang ap-lang-en

   ``grid.locate`` validates the position and returns its cell; an out-of-domain position gives an empty result, which becomes an error here.
   The calling program should therefore finish outflow, inflow and boundary handling before entering the collision substep.
   ``to_cartesian_velocity`` checks finite local velocities and angles and transforms using the particle's current azimuth.
   The resulting working velocities share a basis, so subtraction gives a physical relative velocity.

.. container:: ap-lang ap-lang-zh

   最后的 ``push_back`` 依次保存粒子 ID、单元 ID、两份相同的初始全局速度以及原下标。
   碰撞仅更新第一份速度，第二份在本次调用内保持不变。
   这里从原始数组读取数据；检查、分配或转换失败时，原始速度仍保持调用前状态。

.. container:: ap-lang ap-lang-en

   The final ``push_back`` stores the particle ID, cell ID, two identical copies of the initial global velocity and the original index, in that order.
   Collisions update only the first velocity copy; the second remains fixed for the current call.
   Data are read from the original array, whose velocities retain their incoming values if validation, allocation or conversion fails.

prepare_particle_velocities: Original Indices and Local Velocities
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   碰撞结束后，工作快照按单元与粒子 ID 排列。
   准备函数用每条记录的 ``source_index`` 找到原始粒子，并把结果放入相同下标的待写回数组：

.. container:: ap-lang ap-lang-en

   After collision, working records are ordered by cell and particle ID.
   The preparation function uses each record's ``source_index`` to recover the original particle and places the result at that index in the pending array:

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_particles.cpp
   :language: cpp
   :start-at: void prepare_particle_velocities
   :end-before: } // namespace
   :linenos:
   :lineno-match:
   :caption: fun_G03_dsmc_particles.cpp — prepare_particle_velocities

.. container:: ap-lang ap-lang-zh

   ``pending.resize`` 建立与原粒子数组等长的缓冲区。
   ``source`` 给出该粒子的原方位角和原局部速度，``velocity`` 是最终全局速度，
   ``initial`` 是保存的初始全局速度。
   三个分量逐项相等时，函数直接保留 ``source.velocity_mps``；
   速度发生变化时，才调用 ``to_cylindrical_velocity`` 恢复该粒子的局部表示。
   这使零时间步、未发生碰撞或最终速度保持原值的粒子避免反复坐标往返造成的舍入漂移。

.. container:: ap-lang ap-lang-en

   ``pending.resize`` creates a buffer matching the original particle count.
   ``source`` supplies the original azimuth and local velocity, ``velocity`` is the final global velocity,
   and ``initial`` is the saved initial global velocity.
   If all three components compare equal, the function directly retains ``source.velocity_mps``.
   Only a changed velocity is transformed with ``to_cylindrical_velocity``.
   This prevents coordinate round-trip drift for zero timesteps, particles without collisions, and particles whose final velocity equals their initial value.

.. container:: ap-lang ap-lang-zh

   每个原下标在快照中恰好出现一次，因此准备结束时缓冲区的每个元素都已确定。
   步进器随后逐项赋值完成写回；若准备期间发生异常，原始数组尚未被修改。
   一次 ``step`` 期间，调用程序须保持粒子数组和网格有效，且不修改粒子成员、位置、速度和存储顺序。
   同一粒子数组及同一工作区各由一次调用独占。

.. container:: ap-lang ap-lang-en

   Every original index occurs once in the snapshot, so every pending entry is determined when preparation completes.
   The stepper then commits these values by assignment; an exception during preparation leaves the original array untouched.
   During one ``step`` call, the calling program keeps the particle array and grid valid and preserves members, positions, velocities and storage order.
   Each particle array and each workspace is used exclusively by one call at a time.

.. container:: ap-lang ap-lang-zh

   本模块的检查方法与判据见 :ref:`测试说明 <g03-validation-particles>`。

.. container:: ap-lang ap-lang-en

   Checks and pass criteria for this module are described in :ref:`the validation page <g03-validation-particles>`.
