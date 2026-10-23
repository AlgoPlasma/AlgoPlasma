.. _g03-model:
.. _g03-configuration:
.. _g03-dispatch:
.. _g03-model-recipes:

模型组合与源码职责索引
------------------------------------------------------------------------

本节对应 ``model.hpp`` 与 ``fun_G03_dsmc_model.cpp``。
调用程序用 ``DsmcModel(species, weight, parameters)`` 构造模型；
它保存单物种参数、统一权重，并根据 HS/VHS/VSS 类型创建碰撞核与散射对象。
碰撞步对这些物理参数只读访问。文件读取、单位换算和初始粒子生成由调用程序完成。

一个构造入口
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``Species`` 提供物种 ID、名称、单分子质量与电荷数，当前仅接受中性物种。
``weight`` 是每个模拟粒子代表的真实分子数。
``ElasticModelParameters`` 给出模型类型、参考直径、参考温度、黏度指数与散射角参数：

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/model.hpp
   :language: cpp
   :start-at: enum class ElasticModel
   :end-before: struct ModelProperties
   :linenos:
   :lineno-match:
   :caption: model.hpp — 内建弹性模型的数值参数

构造函数先检查物种与权重，再检查模型参数的约束：

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_model.cpp
   :language: cpp
   :start-at: DsmcModel::DsmcModel
   :end-before:     const Real viscosity = reference_viscosity
   :linenos:
   :lineno-match:
   :caption: fun_G03_dsmc_model.cpp — DsmcModel 的构造与参数检查

HS 使用 :math:`\omega=1/2,\alpha=1`，VHS 使用 :math:`\alpha=1`；
所有模型要求正且有限的质量、权重、参考直径和参考温度，
:math:`1/2\leq\omega\leq1`，:math:`\alpha\geq1`。
质量与权重的正值检查复用 ``common.hpp`` 中的 ``detail::require_positive``；
直径、温度和模型指数由下文调用的标定函数与物理对象继续检查。
已知参考动力黏度时，先用 ``reference_diameter`` 求参考直径，再调用同一个构造函数。

从物理模型到两个计算对象
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

总核与条件角分布决定了两个计算对象的职责：

.. math::
   :label: g03-eq-model-factorization

   g\,d\sigma=K(g)\,p_\Omega(\Omega\mid g)\,d\Omega,
   \qquad \int p_\Omega\,d\Omega=1.

其中 :math:`\Omega=(\chi,\varphi)` 是相对入射方向定义的散射角坐标。
``PairRateModel`` 计算 ``kernel(g)`` 并提供区间上界；
``ElasticScattering`` 的 ``sample`` 接收相对速度，返回保持模长的碰后相对速度。
下面展示同一物理分解怎样成为模型构造函数中的实际分支：

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_model.cpp
   :language: cpp
   :start-at:     const Real viscosity = reference_viscosity
   :end-at:     properties_ =
   :linenos:
   :lineno-match:
   :caption: fun_G03_dsmc_model.cpp — DsmcModel 内部组合核与散射

HS 构造 ``HardSphereRate + IsotropicScattering``；VHS 构造 ``VhsRate + IsotropicScattering``；
VSS 构造 ``VhsRate + VssScattering``。VHS 与 VSS 共用速率类，角分布由各自的散射对象决定。
``rate_`` 与 ``scattering_`` 在模型内部管理这两个对象的寿命；
``rate()`` 与 ``scattering()`` 向碰撞内核提供只读访问。
``ModelProperties`` 保存参数及计算得到的参考黏度，供 ``properties()`` 查询和输出。

.. _g03-extension:

扩展时应修改哪个位置
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

当前公开入口覆盖 HS/VHS/VSS 与柱坐标粒子。
频率计算、方向抽样和网格几何仍各自独立，后续增加功能时可以沿相应职责修改：

.. list-table:: 需求与改动位置
   :header-rows: 1
   :widths: 28 38 34

   * - 需要改变的行为
     - 实现位置
     - 必须维持的约定
   * - 相对速率对应的碰撞频率
     - ``rate`` 模块及 ``DsmcModel`` 构造分支
     - 核非负，``majorant(g_max)`` 覆盖整个速率区间
   * - 弹性碰后的方向分布
     - ``scattering`` 模块及 ``DsmcModel`` 构造分支
     - 返回有限相对速度并保持其模长
   * - 柱坐标粒子的读取与写回
     - ``particles`` 模块
     - 共同速度基底、稳定 ID、原数组下标、全部准备成功后提交
   * - 碰撞网格几何
     - ``CylindricalGrid``
     - 唯一单元 ID、真实正体积、共同速度基底

新增碰撞物理需要同步调整参数校验和模型构造；增加物种、改变权重或在子步中增删粒子时，
还需调整状态表示、配对率和守恒收支。

.. _g03-source-map:

源码索引：从文件找到计算职责
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

以下路径均相对于 ``G_Collision/G03_DSMC/``，共 11 个头文件与 8 个实现文件。
每行给出实际入口与其计算内容，其中 ``fun_G03_dsmc_`` 是实现文件的统一前缀。

.. list-table::
   :header-rows: 1
   :widths: 39 31 30

   * - 源文件
     - 主要类型或函数
     - 说明位置
   * - ``common.hpp``
     - ``Real``、``Vec3``、ID、常数与公共数值检查
     - Theory & Algorithm：物理量与样本表示
   * - ``rate.hpp``、``fun_G03_dsmc_rate.cpp``
     - ``HardSphereRate::kernel``、``VhsRate::kernel``
     - Theory & Algorithm：碰撞核
   * - ``scattering.hpp``、``fun_G03_dsmc_scatter.cpp``
     - ``IsotropicScattering::sample``、``VssScattering::sample``
     - Theory & Algorithm：弹性散射
   * - ``calibration.hpp``、``fun_G03_dsmc_calibration.cpp``
     - ``reference_viscosity``、``reference_diameter``
     - Theory & Algorithm：输运标定
   * - ``collision_kernel.hpp``、``fun_G03_dsmc_collision.cpp``
     - 内部函数声明；``detail::collide_cell`` 实现
     - Theory & Algorithm：上界、两种调度、选对与速度更新
   * - ``cylindrical.hpp``、``fun_G03_dsmc_cylindrical.cpp``
     - ``CollisionCell``、``CylindricalGrid``、速度变换
     - Theory & Algorithm：非均匀三维柱坐标
   * - ``random.hpp``
     - ``RandomStream::uniform/open_uniform/index``
     - Theory & Algorithm：随机抽样与重放
   * - ``dsmc.hpp``、``stepper.hpp``、``fun_G03_dsmc_stepper.cpp``
     - ``DsmcStepper::step``、内部 ``CollisionParticle``、工作区与报告
     - Source Guide：一次 step 调用
   * - ``particles.hpp``、``fun_G03_dsmc_particles.cpp``
     - ``CylindricalParticleState``、``snapshot_particles``、``prepare_particle_velocities``
     - Source Guide：柱坐标存储、快照与写回准备
   * - ``model.hpp``、``fun_G03_dsmc_model.cpp``
     - ``DsmcModel`` 数值构造与物理对象组合
     - Source Guide：模型组合

本模块的检查方法与判据见 :ref:`测试说明 <g03-validation-model>`。
