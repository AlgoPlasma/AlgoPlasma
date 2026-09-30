.. rst-class:: ap-g02 ap-g02-guide

G02_MCC_network
===============

.. toctree::
   :maxdepth: 2
   :hidden:

   Basics <G02_MCC_network/group_foundation>
   Model <G02_MCC_network/group_model_data>
   Collision <G02_MCC_network/group_collision>
   C API <G02_MCC_network/group_c_interface>
   Fortran API <G02_MCC_network/group_fortran_interface>
   MPI <G02_MCC_network/group_mpi_interface>

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. _g02-mcc-basics-zh:

   .. rubric:: 1. MCC 基础：用概率模拟碰撞
      :class: g02-chapter

   .. tip::
      :class: g02-terms

      - MCC（Monte Carlo Collision，蒙特卡洛碰撞）：用随机抽样决定碰撞何时发生、发生哪种反应，以及粒子怎样变化；大量粒子的统计应符合给定模型。

   它根据碰撞数据，用随机数抽样三个问题：**什么时候碰撞、发生哪种反应、碰后怎样运动？**
   对许多粒子反复做这样的计算，就能研究平均速度、温度和粒子数量怎样随时间变化。

   .. admonition:: 用一个数字理解随机抽样
      :class: g02-intuition

      “按概率抽样”可以从一个小例子理解：若某个事件的概率为 10%，就在 0 到 1 之间取一个
      均匀随机数，小于 0.1 时让它发生。重复 1000 次，通常会得到接近 100 次事件，
      实际次数会有起伏。MCC 用碰撞数据确定这些概率，再检验大量事件是否符合物理规律。

   .. container:: g02-route

      - :ref:`01 · MCC 基础 <g02-mcc-basics-zh>`

        粒子、背景与碰撞概率
      - :ref:`02 · 程序实现 <g02-implementation-zh>`

        文件分工、抽样流程与接口
      - :ref:`03 · MCC 加速 <g02-acceleration-zh>`

        缓存、采样与 CPU 并行
      - :ref:`04 · 通用性与边界 <g02-generality-zh>`

        可以改什么，何时需要扩展

   .. rubric:: 1.1 被跟踪粒子与背景

   .. tip::
      :class: g02-terms

      - projectile / primary：projectile 是当前跟踪的入射粒子；primary 是一次事件后对这条原粒子记录的处理结果，可更新、移除或改变物种。background 是用密度、温度等描述的碰撞伙伴。

   在 G02 中，被跟踪的粒子可以是电子、离子或模型指定的其他粒子，程序逐个保存它们的速度与种类。
   周围气体称为 **背景**，用数密度、温度和平均速度描述。
   需要搭档速度时，从背景的速度分布中抽样，无需保存气体中每个分子的轨迹。

   二体反应有一个被跟踪粒子和一个背景反应物；三体反应有一个被跟踪粒子和两个背景反应物。
   一条 **反应通道** 规定谁参与、生成什么以及发生多快；多条通道组成碰撞网络。

   .. list-table:: 先认识这几个词
      :header-rows: 1
      :widths: 25 75

      * - 概念
        - 含义
      * - 速度与速率
        - 速度有方向，x 方向速度可正可负；速率是速度的大小，总是非负。
      * - 漂移与温度
        - 漂移是全体粒子的平均速度。温度由相对这个平均速度的热运动计算；整体运动要先扣除。
      * - 弹性碰撞
        - 碰撞双方总动量、总动能保持不变。双方可以交换能量，所以单个粒子可以变快或变慢。
      * - 数密度与样本数
        - 背景数密度是每立方米有多少背景粒子；程序保存的被跟踪粒子数决定统计样本有多少。
      * - 物种与态
        - 物种是粒子种类，例如电子、原子或离子；态是同一物种的内部能级。

   .. rubric:: 1.2 碰撞概率与频率

   .. tip::
      :class: g02-terms

      - null collision（空碰撞）：算法安排的候选被拒绝，只消耗抽样等待时间，粒子状态不变。它是抽样技巧，不是一种新的物理反应。
      - majorant（频率上界）：一个不小于真实碰撞频率的数，用它安排候选事件，再按“真实频率÷上界”接受候选。上界过松会增加空碰撞；低于真实频率则报错。

   先知道碰撞有多频繁，才能抽样等待时间。碰撞频率用 :math:`\nu` 表示，单位为 1/s：
   频率为 1000/s，表示这种条件下一个粒子平均每秒发生 1000 次碰撞。
   具体两次碰撞之间的等待时间仍会不同。

   两类常见输入数据分别是：

   - **截面** :math:`\sigma`，单位 m²，描述一次相遇发生某种反应的有效面积，可随相对运动能量变化。
     给定相对速率 :math:`g` 时，:math:`n\sigma g` 给出相应的频率；
     背景有热运动时，还需对背景速度抽样或平均。
   - **二体速率系数** :math:`k`，单位 m³/s，乘背景数密度 :math:`n` 后，
     直接得到 :math:`\nu=nk`。G02 的这类数据按指定背景温度查表。
     三体速率系数单位为 m⁶/s，要乘两个背景密度才得到频率。

   .. container:: g02-equation

      当真实碰撞频率在一段时间 :math:`\Delta t` 内保持恒定时，至少碰撞一次的概率为：

      .. math::

         P = 1-\exp(-\nu\Delta t).

      这里 :math:`\Delta t` 是经过的时间，:math:`\exp(x)=e^x` 是指数函数。
      例如 :math:`\nu\Delta t=0.1` 时，:math:`P\approx9.52\%`。
      一段时间内也可能发生多次碰撞；G02 会逐次抽样候选时间，直到本步时间用完。

   .. rubric:: 1.3 碰撞后还要遵守物理规律

   一次真实碰撞可能只改变速度，也可能改变内部能量、物种或粒子数量。
   例如激发把部分运动能量转为内部能量，电离会产生额外的自由电子。
   这些变化由所选反应的物理模型决定，程序还要把粒子与背景的动量、能量收支一起核算。

   有了“发生多快”和“发生后怎样变化”这两部分，下面就可以看 G02 怎样组织计算。

   .. _g02-implementation-zh:

   .. rubric:: 2. G02 的 MCC 实现
      :class: g02-chapter

   G02 把反应规则写在 CSV 表格中：先读取模型，检查物种、能量和单位，再按这些规则处理碰撞。
   主程序提供粒子状态、背景条件和时间步；G02 返回更新后的粒子、反应计数与背景收支。
   例如粒子把能量传给气体，报告中就记下气体收到的能量。

   .. _g02-csv-input-zh:

   .. rubric:: 2.1 CSV 模型输入与模板

   使用 G02 前，先准备一个 **模型包目录**：里面的 CSV 文件共同描述“有哪些粒子、能发生哪些反应、碰撞有多快”。
   CSV 第一行是列名，后面是数据。加载时传入整个目录的路径，程序从 ``manifest.csv`` 找到其他表格。

   .. list-table:: 模型包里的表格
      :header-rows: 1
      :widths: 48 52

      * - 文件
        - 告诉程序什么？
      * - ``manifest.csv``
        - 文件清单：这个模型需要读取哪些表。
      * - ``species.csv`` 、 ``states.csv``
        - 有哪些粒子，以及它们的质量、电荷和内部能级。
      * - ``reactions.csv`` 、 ``reactants.csv`` 、 ``products.csv``
        - 哪些粒子碰撞，使用哪种算法，生成什么产物。
      * - ``rate_laws.csv`` 、 ``datasets.csv`` 、 ``tables/*.csv``
        - 怎样查截面或速率系数，以及具体数值、单位和数据来源。
      * - ``composition.csv`` （可选）
        - 物种的元素组成，供程序核算元素守恒。

   .. tip:: 从模板开始填写

      推荐先复制原始的 ``collision_box_elastic`` 已填示例，它只有一条弹性反应。
      :doc:`Tests → 009 → CSV 模板 </tests/009_collision/G02_csv_templates>` 提供 **空白模板、已填示例下载、填写顺序和检查命令**。
      G02 自带一份空白模板：``G_Collision/G02_MCC_network/templates/blank/``，与 ``fortran_interface/`` 同级的 ``templates/`` 内。
      Tests 保留相同模板和已填示例；两份空白模板内容一致。
      示例数值都是合成值，只用于软件验证。

   模型准备好后，C++ 用 ``MccEngine::load``，Fortran 用
   :doc:`sub_G02_mcc_load <G02_MCC_network/sub_G02_mcc_load>` 加载；通常在初始化时加载一次。

   .. rubric:: 2.2 模块定位与文件分工

   G02 用一个被跟踪粒子和一到两个背景反应物描述碰撞，支持二体截面、二体速率系数和三体速率系数。
   它负责碰撞，主程序负责电场、位置推进、壁面处理，以及是否根据收支更新背景。

   .. figure:: ../../images/G_Collision/G02/architecture_zh.svg
      :alt: C++、C、Fortran 入口连接批量层、碰撞引擎、模型表格和运动学计算
      :width: 100%

      沿箭头阅读：接收粒子 → 批量处理 → 抽样碰撞 → 计算碰后速度 → 返回更新与报告。
      反应数据为抽样提供规则和频率；图中第二行标明对应源码文件。
      点击图片可查看原图。

   核心用 C++20 编写；C ABI（供其他语言调用的 C 函数边界）把功能提供给 C 和 Fortran。
   Fortran 通过 ``ISO_C_BINDING`` 使用 ``mod_G02_MCC_network`` 中的子程序。
   MPI 用多个进程分担工作，OpenMP 用多个 CPU 线程分担工作；两者都可选，基本运行不需要它们。

   侧栏按 Basics、Model、Collision、C API、Fortran API、MPI 六个功能分组组织。
   下表列出主要实现文件；每组的完整头文件和源码列表见对应分组页。
   头文件和 C++ 实现位于 G02 根目录，Fortran 接口位于 ``fortran_interface/``。
   点击带后缀的文件名即可查看用途和接口。

   .. list-table:: 文件角色
      :header-rows: 1
      :widths: 38 62

      * - 程序文件
        - 角色
      * - :doc:`mod_G02_MCC_network.f90 <G02_MCC_network/mod_G02_MCC_network>`
        - Fortran 模块入口，定义数据类型并 include 子程序与函数。
      * - :doc:`sub_G02_mcc_load.f90 <G02_MCC_network/sub_G02_mcc_load>`
        - 读取模型包并建立碰撞上下文。
      * - :doc:`sub_G02_mcc_model_queries.f90 <G02_MCC_network/sub_G02_mcc_model_queries>`
        - 查询物种、态、反应的名称、编号和参数。
      * - :doc:`sub_G02_mcc_step.f90 <G02_MCC_network/sub_G02_mcc_step>`
        - 推进整个粒子数组的本步碰撞。
      * - :doc:`sub_G02_mcc_collide.f90 <G02_MCC_network/sub_G02_mcc_collide>`
        - 计算一个粒子的碰撞结果。
      * - :doc:`sub_G02_mcc_session.f90 <G02_MCC_network/sub_G02_mcc_session>`
        - 初始化或关闭可跨时间步复用的会话。
      * - :doc:`sub_G02_mcc_cleanup.f90 <G02_MCC_network/sub_G02_mcc_cleanup>`
        - 整理报告，释放结果和模型资源。
      * - :doc:`fun_G02_mcc_api_version.f90 <G02_MCC_network/fun_G02_mcc_api_version>`
        - 返回接口版本号。
      * - :doc:`fun_G02_mcc_model.cpp <G02_MCC_network/fun_G02_mcc_model>`
        - 读取、校验模型和数据表；配合 compile、table、csv 实现文件。
      * - :doc:`fun_G02_mcc_engine.cpp <G02_MCC_network/fun_G02_mcc_engine>`
        - 抽样候选时刻、反应通道和真实碰撞，记录背景收支。
      * - :doc:`fun_G02_mcc_batch.cpp <G02_MCC_network/fun_G02_mcc_batch>`
        - 批量处理粒子，复用工作区，统一提交更新。
      * - :doc:`fun_G02_mcc_kinematics.cpp <G02_MCC_network/fun_G02_mcc_kinematics>`
        - 根据总动量和可用能量计算碰后速度。
      * - :doc:`fun_G02_mcc_c_api.cpp <G02_MCC_network/fun_G02_mcc_c_api>`
        - 提供 C 函数边界，管理句柄、状态码和错误消息。
      * - :doc:`mod_G02_MCC_network_mpi.f90 <G02_MCC_network/mod_G02_MCC_network_mpi>`
        - MPI 模块入口，包含并行会话和步进子程序。
      * - :doc:`sub_G02_mcc_mpi_session.f90 <G02_MCC_network/sub_G02_mcc_mpi_session>`
        - 创建与关闭 MPI 碰撞会话。
      * - :doc:`sub_G02_mcc_mpi_step.f90 <G02_MCC_network/sub_G02_mcc_mpi_step>`
        - 协调各进程推进碰撞，分配全局唯一的新粒子 ID。

   .. rubric:: 2.3 单个时间步的处理流程

   先把“模型准备”和“每步碰撞”分开：反应数据通常只在初始化时加载一次，
   后续每步重复下面的流程。

   .. figure:: ../../images/G_Collision/G02/step_flow_zh.svg
      :alt: 批量时间步：抽样、真实或空碰撞、循环与统一提交
      :width: 100%

   .. rst-class:: g02-steps

   1. **读取当前条件**：取得粒子的物种、内部态，以及所在单元的背景密度、温度和平均速度。
   2. **安排一个候选时刻**：用不小于真实频率的上界抽样等待时间。
      没有可用通道，或等待超过本步剩余时间，就结束这个粒子的本步计算。
   3. **选通道并接受或拒绝**：先按各通道的上界占比选择通道，
      再按“该通道真实频率 ÷ 该通道上界”决定候选是否成为真实碰撞。
   4. **更新或保持状态**：真实碰撞调用相应物理算法；拒绝的候选叫 null collision（空碰撞），
      只消耗等待时间，粒子状态不变。然后继续处理剩余时间。
   5. **汇总并写回**：全部粒子处理成功后，批量接口提交更新与新粒子，返回计数和守恒账本；
      失败时保留原粒子数组。这种“先准备、后提交”的方式也称为事务化。

   .. figure:: ../../images/G_Collision/G02/event_timeline_zh.svg
      :alt: 一个时间步内的真实事件、空碰撞和超出本步的等待
      :width: 100%

      图中时刻用于示意。超出本步的候选不执行，下一步重新抽样。
      点击图片可查看原图。

   .. tip:: 算法编号的范围

      “G02 算法 C01–C08”只表示本碰撞模块内部的算法编号；导航中的 ``C_Gather`` 有自己的模块编号。
      CSV 的 ``algorithm`` 字段仍填写 ``C02`` 等原始值；G02 算法 C01 是公共抽样流程。

   这套抽样流程在代码中称为 **G02 算法 C01**；G02 算法 C02–C08 负责真实碰撞后的物理变化。
   “上界”帮助安排候选，接受/拒绝步骤使真实事件按模型规定的频率发生。
   :ref:`架构页 <g02-architecture-zh>` 说明数据怎样传递，
   :ref:`抽样页 <g02-sampling-zh>` 说明随机数和通道选择。

   .. raw:: html

      <details class="g02-details">
        <summary>进阶阅读 · 频率公式与状态处理</summary>

   .. only:: not html

      .. rubric:: 频率公式与状态处理（可第二遍读）

   G02 按当前粒子的背景条件计算上界，不需要全局 ``nu_prime``。
   上界总和为零时，本粒子没有候选事件，直接结束本步。
   这里 ``projectile`` 指当前被处理粒子，majorant 指频率上界。
   下式中 r 为通道编号，n 为背景密度，s 为该背景的反应物个数，shape 为表格导出的速率因子上界，
   safety 为无量纲余量系数；u 是 0 到 1 之间的均匀随机数（不取 1），ln 为自然对数。
   对同一 projectile 的所有通道求总频率上界：

   .. math::

      \Lambda = \sum_r \Lambda_r,
      \qquad
      \Lambda_r = \text{shape}_r \cdot \prod_i n_i^{s_i} \cdot f_{\mathrm{safety}}.

   二体通道取 :math:`n`，混合三体取 :math:`n_1 n_2`，同种背景计量 2 时取 :math:`n^2`。
   当总上界大于零时，候选等待时间为：

   .. math::

      \tau = -\frac{\ln(1-u)}{\Lambda}.

   :math:`\tau` 落在剩余 :math:`\Delta t` 内时产生候选，
   通道按 majorant 份额竞争，因此多个背景组分自动竞争。候选若为真实事件则按对应
   G02 算法 C02–C08构造末态；否则为 null 事件，粒子不变。若实际速率超过编译出的 majorant，
   直接硬错误，绝不静默截断。

   通道还必须与 primary 的 ``(species, state)`` 完全匹配；没有适用通道时零事件。真实
   ``Update`` 后按新的 primary 状态重建活动通道和总 majorant，再采样剩余 :math:`\Delta t`；
   批量接口在 ``MoveSpecies`` 后继续采样剩余时间，``Remove`` 停止本步；旧单粒子接口
   在物种迁移时停止。null 事件不重建。只要求活动通道的背景。

   .. raw:: html

      </details>

   .. rubric:: 2.4 已实现的物理算法与碰后变化

   G02 算法 C01 选中真实事件后，才进入下面对应的物理算法。初读先看每项的物理含义，
   修改反应表时再检查字段约束。

   .. code-block:: text
      :caption: 算法分工示意（伪代码，不是可调用的函数）

      while remaining_time > 0 and particle_alive:
          if no_active_channel:
              break
          event = sample_candidate()  # G02 算法 C01：候选事件
          if event.wait > remaining_time:
              break
          remaining_time -= event.wait
          if event.is_null:
              continue                # 空碰撞：保持粒子状态
          rule = reaction.algorithm   # G02 算法 C02–C08
          outcome = apply_physics(rule, reactants, products, energy)
          check_conservation(outcome) # 核算动量与能量
          collect(outcome)            # 汇总粒子变化及背景收支
          update_primary(outcome)     # 更新/转种/移除，按需重建活动通道

   例如 ``A + B → A + B`` 的 G02 算法 C02 弹性碰撞，**改变的是速度，物种和内部态保持不变**。
   程序根据两粒子的总动量与可用能量计算碰后速度；单个 A 粒子的动能可以增加或减少。
   实现可对照 :doc:`碰撞引擎 <G02_MCC_network/fun_G02_mcc_engine>` 与
   :doc:`末态速度计算 <G02_MCC_network/fun_G02_mcc_kinematics>`。

   - G02 算法 ``C02`` 弹性二体：交换动量与动能，物种和内部态保持不变；
   - G02 算法 ``C03`` 离散态跃迁：激发或退激发改变内部能级，``q`` 必须与 ``states.csv`` 的态能差一致；
   - G02 算法 ``C04`` 解离/多产物：分子分裂或生成多个产物；
   - G02 算法 ``C05`` 电离：释放额外的自由电子，产物自由电子数必须增加；
   - G02 算法 ``C06`` 附着/脱附：捕获或释放电子，改变负离子的形成情况；
   - G02 算法 ``C07`` 电荷交换，``identity_exchange`` 仅用于严格共振通道：两侧物种计量相同、
     两个物种电荷不同且互换、反应物质量相等、``q/radiated/ker_min=0``，并按产物物种映射
     速度（projectile 物种取背景速度，background 物种取 projectile 速度）；
   - G02 算法 ``C08`` 复合/互中和：带电粒子结合或交换电子，带电粒子数必须减少。

   角模型支持 ``isotropic``、显式 ``cone`` （``angular_cos_min`` / ``angular_cos_max``）和
   ``identity_exchange``；能量模型支持 ``n_body_phase_space`` 与 ``equal_share`` （恰好两个
   产物）。 ``opal_like`` 等未实现模型在加载阶段直接拒绝。二体、N 体和 ``equal_share`` 末态
   都验证 ``ker_min_ev``，能量比较使用基于 ``numeric_limits<double>::epsilon()`` 的尺度相关
   容差；单产物通道的 ``ker_min_ev>0`` 在编译期拒绝。

   .. rubric:: 2.5 主程序调用方法

   .. tip::
      :class: g02-terms

      - ParticleAdapter（粒子适配器）：把主程序已有的粒子存储接到 G02 的“转换接头”，负责读取粒子和提交更新，不是额外的物理粒子。
      - workspace（工作区）是反复使用的临时内存；session（会话）是 C/Fortran 接口持有这类工作状态的对象。跨时间步复用可减少分配，但同一对象不能同时处理两个调用。
      - ABI（应用二进制接口）规定不同语言编译后怎样传参和返回结果。handle（句柄）是库对象的引用；保存并通过接口使用它，不直接读取其内部数据。

   PIC（Particle-in-Cell，粒子与网格结合的模拟方法）把场计算、粒子运动和碰撞分成不同环节。
   在这样的时间循环中，推荐每个碰撞步调用一次：C++ ``MccStepper::step(adapter, background, dt, step, seed)``，
   C ``ap_g02_mcc_step``，Fortran ``sub_G02_mcc_step``。输入按单元/物种/态提供背景场，
   结果包含背景收支、反应计数和守恒账本。C++ ``ParticleAdapter`` 对接宿主现有粒子容器；
   新粒子下一步才参与碰撞，失败时不提交粒子。旧 ``MccEngine::collide`` 单粒子接口保留。

   .. code-block:: text
      :caption: 主程序的调用顺序（伪代码）

      initialize(model, particles, background, workspace)
      for step in time_steps:
          update_host_state()  # 更新场、位置和背景条件
          result = collision_step()
          if result.success:
              apply_sources(result)  # 主程序按自身模型处理背景收支
          else:
              handle_error()         # 不使用失败结果
      cleanup()  # Fortran 关闭会话与模型

   **C++：初始化一次，每步调用一次。** 下面直接摘自可编译的宿主示例。
   ``argv[1]`` 是模型目录；该示例使用 ``tests/009_collision/G02_MCC_network/data/demo_binary``，包含 ``e-``、``M`` 等物种。
   片段省略的粒子与背景初始化见
   :download:`完整 C++ 示例 <../../../../tests/009_collision/G02_MCC_network/examples/host_pic/main.cpp>`。

   .. literalinclude:: ../../../../tests/009_collision/G02_MCC_network/examples/host_pic/main.cpp
      :language: cpp
      :lines: 13-17
      :dedent: 4
      :caption: 初始化模型、步进器与工作区

   .. literalinclude:: ../../../../tests/009_collision/G02_MCC_network/examples/host_pic/main.cpp
      :language: cpp
      :lines: 37-44
      :dedent: 4
      :caption: 真实调用：执行三个碰撞步并输出计数

   这里 ``adapter`` 连接粒子数组，``background`` 提供背景条件；``1.0e-8`` 是步长（秒），
   ``step`` 是步编号，``1234`` 是随机种子，``workspace`` 是重复利用的临时存储。
   返回的 ``result.reservoir`` 记录背景得到或失去的量；是否更新背景，由主程序决定。

   .. tip:: Fortran 片段需要的声明

      ``iso_c_binding`` 是 Fortran 自带的 C 类型桥接模块，提供 ``c_double``、``c_int``、``c_int32_t``、``c_int64_t`` 等类型参数。G02 不会把这些名称转导出给主程序。
      在主程序声明区先写 ``use, intrinsic :: iso_c_binding``，再写 ``use mod_G02_MCC_network`` 和 ``implicit none``；``status`` 声明为 ``integer(c_int)``。
      本页简短调用式需要相应的 context、数组和步参数；:doc:`完整声明与初始化 <G02_MCC_network/sub_G02_mcc_load>` 给出可构建示例。

   **Fortran：同样的流程，用状态码判断是否成功。** 以下片段也来自
   :download:`完整 Fortran 示例 <../../../../tests/009_collision/G02_MCC_network/examples/host_fortran/main.f90>`，
   ``context``、``particles`` 和 ``gas`` 已在前面初始化，模型同样使用 ``demo_binary``。

   .. literalinclude:: ../../../../tests/009_collision/G02_MCC_network/examples/host_fortran/main.f90
      :language: fortran
      :start-at: call sub_G02_mcc_session_init
      :end-at: call sub_G02_mcc_close(context)
      :dedent: 4
      :caption: 真实调用：创建会话、推进、检查状态并清理

   ``status=0`` 表示成功；示例用 ``stop`` 在错误时结束，实际主程序也可以记录错误并自行处理。

   使用旧单粒子接口时，宿主必须把 ``StepOutcome`` 原子提交：``Update`` 替换 projectile，``Remove`` 删除，
   ``MoveSpecies`` 转种，``None`` 不变；``CreatedProduct`` 的 ``birth_step`` 为下一步；
   ``ReservoirDelta`` 计入背景源汇；任何错误整体丢弃本步。

   写调用程序时，再按需要查看这些入口：

   - 初始化：:doc:`加载模型 <G02_MCC_network/sub_G02_mcc_load>`，
     :doc:`查询物种、态与反应 <G02_MCC_network/sub_G02_mcc_model_queries>`。
   - 每步推进：:doc:`Fortran 批量参数 <G02_MCC_network/sub_G02_mcc_step>`；
     :ref:`粒子、背景与报告字段 <g02-data-types-zh>`。
   - 连续运行与结束：:doc:`工作区会话 <G02_MCC_network/sub_G02_mcc_session>`，
     :doc:`报告转换与资源清理 <G02_MCC_network/sub_G02_mcc_cleanup>`。
   - 旧程序接入：:doc:`Fortran 单粒子接口 <G02_MCC_network/sub_G02_mcc_collide>`。
     C++、C 和 MPI 的详细页面可从前面的文件角色表进入。

   .. rubric:: 2.6 单位与使用边界

   .. tip::
      :class: g02-terms

      - reservoir（背景库）记录背景得到或失去的粒子、动量和能量；ledger（守恒账本）记录反应前后总量以核查守恒。两者用途不同，不能重复当作源项加入背景。

   模型表中的能量用 eV（电子伏特），温度用 K，质量用 kg；位置和时间分别用 m、s。
   接口的动量与能量收支分别用 kg·m/s 和 J，具体字段见 :ref:`数据类型 <g02-data-types-zh>`。
   截面单位为 m²（仅二体）；二体速率系数为 m³/s，三体为 m⁶/s。
   ``q_value_ev`` 正值放能、负值吸能；``threshold_ev`` 只控制通道阈值；
   ``ker_min_ev`` 只作最低末态相对动能约束；``radiated_energy_ev`` 记录辐射/未分辨能量。

   .. code-block:: text
      :caption: 单位对照示例（数值用于说明，不是额外的 API）

      模型表：energy_ev = 5.0          表示 5 eV
      背景：  temperature_k = 300.0    表示 300 K，不是 300 ℃
      背景：  density_m3 = 1.0e20      表示每立方米 10^20 个粒子
      粒子：  velocity = (1000, 0, 0)  表示沿 x 方向以 1000 m/s 运动
      调用：  dt = 1.0e-8             表示 10 ns

   比较模型表与报告中的能量时，先统一单位。例如 **5 eV ≈ 8.01 × 10⁻¹⁹ J**。
   C++ 中可使用库里定义的换算常数；下面是计算片段：

   .. code-block:: cpp
      :caption: 将表格中的 eV 数值换成 J

      const double energy_ev = 5.0;
      const double energy_j =
          energy_ev * algoplasma::mcc::elementary_charge_c;

   ``q_value_ev`` 的符号可这样读：

   .. code-block:: text

      q_value_ev = +2.0    反应释放 2 eV
      q_value_ev = -2.0    反应吸收 2 eV
      threshold_ev = 3.0  该通道的阈值为 3 eV；不表示每次扣掉 3 eV

   这些值还必须满足对应算法与能级的约束，不能独立随意填写。

   当前不考虑 CUDA；MPI/OpenMP 均为可选 CPU 并行方案。不做显式粒子配对；演示数据为合成值，
   不可用于科研结论。

   .. rubric:: 2.7 代码组织与编译方法

   ``G_Collision/G02_MCC_network/`` 包含功能代码、CSV 模板和模块 README：
   根目录的 ``*.hpp`` 和 ``*.h`` 是头文件，``*.cpp`` 是 C++ 实现，
   ``fortran_interface/`` 是 Fortran 调用接口。
   示例、合成数据、回归测试和 CMake 配置集中放在
   ``tests/009_collision/G02_MCC_network/``。

   .. code-block:: text
      :caption: 源码与测试目录对应关系

      G_Collision/G02_MCC_network/
      ├── mcc.hpp, *.hpp, *.h
      ├── fun_G02_mcc_*.cpp
      ├── templates/blank/  # CSV templates
      └── fortran_interface/
          ├── mod_G02_*.f90
          ├── sub_G02_*.f90
          └── fun_G02_*.f90

      tests/009_collision/G02_MCC_network/
      ├── examples/, data/, templates/
      ├── cpp/, fortran/
      ├── tools/validate_model.cpp
      ├── cmake/, CMakeLists.txt
      └── run.sh

   在 Linux/WSL 终端中，从仓库根目录执行以下命令可编译并安装库。
   需要 CMake 3.20 或以上、支持 C++20 的 C++ 编译器，以及 C 和 Fortran 编译器：

   .. code-block:: bash

      cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_mcc_module \
        -DCMAKE_BUILD_TYPE=Release -DG02_MCC_BUILD_TESTS=OFF
      cmake --build /tmp/g02_mcc_module -j 4
      cmake --install /tmp/g02_mcc_module --prefix /tmp/g02_mcc_install

   ``G02_MCC_BUILD_TESTS=OFF`` 表示只构建库；不需要 Fortran 时再加
   ``-DG02_MCC_ENABLE_FORTRAN=OFF``。模型包路径由调用程序传入，
   合成数据保留在测试目录中。完整测试命令见 :doc:`碰撞测试说明 <../../tests/009_collision/index>`。

   .. _g02-acceleration-zh:

   .. rubric:: 3. MCC 加速方法
      :class: g02-chapter

   粒子很多时，重复查表、分配内存和遍历反应通道都会花时间。G02 从“少做重复工作”和“分担粒子计算”两方面加速。
   下列机制已在 CPU 实现中提供；当前没有 GPU/CUDA 后端。

   .. rubric:: 3.1 先减少重复工作

   - **模型只加载一次**：``fun_G02_mcc_compile.cpp`` 在初始化阶段检查反应并准备频率上界，避免每步重新读取 CSV。
   - **复用工作区与通道缓存**：``fun_G02_mcc_batch.cpp`` 保留临时数组，并让背景条件、网格、物种和内部态相同的粒子复用通道准备结果；相关背景或配置变化时更新缓存。
   - **跳过不可能发生的反应**：背景密度为零时，该通道的频率也为零，可精确跳过，不会漏掉本来应发生的碰撞。
   - **减少排序和复制**：已按 ID 排序的输入可跳过排序；没有粒子出生或删除时，可以直接更新现有粒子。

   .. rubric:: 3.2 多通道采样加速

   ``fun_G02_mcc_engine.cpp`` 默认使用 Prefix（前缀采样）：先累计各通道权重，再定位随机数落在哪一段。
   通道很多时，也可选 Alias（别名采样）：预先建立辅助表，让一次选通道只做固定数量的操作。
   建表本身需要时间，所以通道少或缓存复用少时，Alias 未必更快。两者都按相同的通道概率抽样。

   .. rubric:: 3.3 OpenMP 与 MPI：把粒子分给多个工作者

   **OpenMP** 在一个进程内使用多个 CPU 线程，主要实现在 ``fun_G02_mcc_batch.cpp``。
   **MPI** 让多个进程各自处理本地粒子，主要实现在 ``fun_G02_mcc_mpi.cpp``；主程序负责分区和粒子迁移。
   MPI 协调错误状态和新粒子 ID；正常碰撞不需要把整批粒子传给其他进程。两者可以组合使用。

   .. code-block:: bash
      :caption: 从仓库根目录构建 CPU 并行版本

      cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_parallel \
        -DCMAKE_BUILD_TYPE=Release -DG02_MCC_ENABLE_OPENMP=ON -DG02_MCC_ENABLE_MPI=ON
      cmake --build /tmp/g02_parallel -j 4

   .. code-block:: cpp
      :caption: C++ 设置片段（模型、粒子和背景由主程序准备）

      using namespace algoplasma::mcc;
      const auto engine = MccEngine::load(
          "tests/009_collision/G02_MCC_network/data/collision_box_elastic");
      StepOptions options;
      options.backend = CpuBackend::OpenMp;
      options.threads = 4;
      options.sampler = ChannelSampler::Prefix;
      MccStepper stepper(engine, options);
      MccWorkspace workspace;  // 在时间循环外创建并跨步复用
      // 时间循环内：
      auto report = stepper.step(adapter, background, dt, step, seed, workspace);

   以上类型位于 ``algoplasma::mcc`` 命名空间。MPI 主程序需先初始化 MPI，再使用
   ``DistributedMccStepper``；详见 :doc:`MPI 分组 <G02_MCC_network/group_mpi_interface>`。

   .. tip:: 加速效果的测量与验证

      固定模型、粒子数和步数，用 Release 构建比较单线程与并行版本的整步耗时，多次运行后取中位数。
      小粒子群可能被线程启动或通信开销拖慢；先复用工作区，再增加线程或进程。
      同时检查碰撞计数、守恒和结果的一致性，不能只看耗时。
      :download:`性能说明与基准命令 <../../../../tests/009_collision/G02_MCC_network/PERFORMANCE.md>` 提供具体测量方法。

   .. _g02-generality-zh:

   .. rubric:: 4. G02 的通用性与适用边界
      :class: g02-chapter

   G02 的定位是 **可配置的、多物种“粒子—背景”碰撞核心**。
   在已支持的反应规则内，物种、能级、反应网络和速率数据可以更换，同一套程序仍负责抽样、计算碰后状态和返回收支。
   它的通用范围由下面三个问题决定：**数据能否表达、物理规则是否已实现、主程序能否提供所需背景？**

   .. rubric:: 4.1 通用性设计

   可以把 G02 看作“执行反应规则的程序”：CSV 给出规则，碰撞核心负责执行。

   - **数据与算法分开**：物种名称、质量、电荷、能级和反应表从 CSV 读取；程序不把某一套气体反应写死在步进循环里。
   - **计算流程复用**：不同通道共同使用 G02 算法 C01 抽样，再进入 G02 算法 C02–C08 对应的物理处理。
     增加一条已支持类型的反应，可以复用计数、产物处理和守恒核算。
   - **与主程序分开**：主程序提供粒子数组、网格编号、背景和时间步；G02 返回粒子变化与背景收支。
     C++、C、Fortran 接口调用同一套核心，适配器可以连接不同粒子存储方式。

   例如，从一条弹性反应扩展到“弹性 + 激发 + 电离”，需要增加完整的物种、态、反应和速率数据，
   并满足各算法约束；通常可以继续使用原来的批量调用入口。
   “能运行这套反应网络”和“这套数据适合真实气体”需要分别验证。

   .. rubric:: 4.2 配置范围与扩展方式

   .. list-table:: 按你要改变的内容判断
      :header-rows: 1
      :widths: 30 32 38

      * - 想做什么
        - 修改哪里
        - 条件或限制
      * - 换物种、质量、电荷或内部能级
        - CSV 模型包
        - 同步所有引用；质量、态和反应必须自洽。
      * - 增删已支持类型的反应，或替换截面/速率表
        - CSV 模型包
        - 符合 G02 算法 C02–C08 的约束、单位和适用范围。
      * - 使用混合背景，改变各组分密度、温度或漂移速度
        - 主程序每步提供的背景数组
        - 背景按网格、物种、内部态查询；相关反应数据仍需齐全。
      * - 从零维盒子接到有空间网格的程序
        - 主程序的粒子、网格编号和背景接口
        - G02 做局部碰撞；网格几何、场和粒子位置推进由主程序负责。
      * - 改用 C/Fortran，或不同的粒子存储方式
        - 接口或粒子适配器
        - 保持单位、有效 ID、粒子生命周期和错误处理约定。
      * - 引入新散射定律、新能量分配规则或新反应机制
        - 扩展核心代码、格式校验和测试
        - 只有 CSV 中写了一个新名字，程序还不会执行它。

   物种和通道数量可以随模型扩展，但仍受 ID 类型范围、内存和计算时间限制。
   前面的零维碰撞盒是入门验证算例；库的输入接口也支持主程序提供按空间单元变化的背景。

   .. rubric:: 4.3 当前实现的边界

   .. list-table:: 能用到哪里，需要在哪一步停下来检查
      :header-rows: 1
      :widths: 26 74

      * - 边界
        - 当前约定
      * - 谁和谁碰撞
        - 每条反应恰有一个被跟踪粒子，以及一个或两个背景反应物，总反应阶数为 2 或 3。
          当前不直接配对两个被跟踪粒子，也不提供通用的带电粒子库仑配对碰撞模型。
      * - 碰撞率怎样给出
        - 二体反应可用相对能量对应的截面，或温度对应的速率系数；三体使用温度速率系数。
          任意依赖电场、历史轨迹或其他变量的速率公式，需要扩展实现。
      * - 背景速度怎样描述
        - 每个背景组分由密度、一个温度和平均速度描述。需要背景速度时，按带漂移的麦克斯韦分布抽样；
          任意形状的非热速度分布不在当前接口内。
      * - 碰后怎样运动
        - 使用已有的经典、非相对论运动学。角模型为 isotropic、cone 或受严格条件限制的 identity_exchange；
          能量模型为 n_body_phase_space 或恰好两个产物的 equal_share。任意微分截面或 Opal 类能量分配不能仅靠换表实现。
      * - 背景会不会自动变化
        - 一次调用使用主程序给定的背景；碰撞返回背景收到或失去的量。
          耗尽、加热或流动怎样影响下一步，需由主程序更新。背景明显变化时，要检查耦合方式与时间步。
      * - 整个模拟由谁完成
        - G02 不求电磁场、不移动粒子位置、不处理壁面，也不负责 MPI 分区与粒子迁移。
          当前并行后端为可选的 CPU OpenMP/MPI。

   .. tip::
      :class: g02-terms

      **麦克斯韦分布（Maxwellian）**：用一个温度描述随机热运动，再叠加整体平均速度。
      温度越高，热速度的分散程度越大。若背景是两束方向不同的粒子流，或有很强的非热高能尾部，
      仅给一个温度和平均速度可能无法描述所需碰撞物理。
      **非相对论**：这里用普通动量和动能公式，适用于速度远低于光速的情形。

   温度速率系数通常已经包含对某种速度分布的平均；所用数据的假设也要符合你的实际场景。
   电荷与能量等检查可以发现部分错误，不能替代对反应数据及物理近似的判断。
   元素守恒只检查模型中声明的元素组成，因此组成信息也需要填写完整。

   .. rubric:: 4.4 新问题的适用性判断

   1. **先写出反应物**：能否表示为一个被跟踪粒子 + 一个或两个背景反应物？
   2. **再看规则和数据**：是否有匹配的 G02 算法、角/能量模型，以及覆盖所需能量或温度范围的数据？
   3. **最后看主程序**：能否提供背景，并根据返回收支更新下一步条件？随后再做针对这个模型的验证。

   三项都满足时，通常可以通过配置数据和连接接口接入。
   任一项超出范围，就应先扩展对应层；例如自定义散射需要改运动学，显式粒子配对需要新的碰撞处理方式。
   :ref:`CSV 规范 <g02-schema-zh>` 和 :doc:`物理处理接口 <G02_MCC_network/fun_G02_mcc_kinematics>` 可用于进一步核对。
   现有合成算例验证的是指定条件下的软件行为，不构成对任意气体、反应或能量范围的验证。

   零维碰撞盒用于验证守恒、碰撞统计和热化过程，物理背景、运行方法与结果判据见
   :ref:`Tests → 009 → 零维碰撞盒 <g02-collision-box-zh>`。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">AlgoPlasma contributors</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. _g02-mcc-basics-en:

   .. rubric:: 1. MCC basics: sampling particle collisions
      :class: g02-chapter

   .. tip::
      :class: g02-terms

      - MCC (Monte Carlo Collision) uses random draws to decide collision timing, reaction type and outcomes; ensemble statistics should follow the model.

   MCC stands for Monte Carlo Collision. It uses collision data and random numbers to answer:
   **when does a collision occur, which reaction occurs, and how do particles move afterwards?**
   Repeating this calculation for many particles lets us study changes in mean velocity, temperature and particle counts.

   .. admonition:: A small example of random sampling
      :class: g02-intuition

      To understand sampling, imagine an event with a 10% probability. Draw a uniform number between 0 and 1
      and let the event occur if the number is below 0.1. Across 1000 trials, the count will usually be near 100,
      with fluctuations. MCC obtains its probabilities from collision data and checks the statistics against the model.

   .. container:: g02-route

      - :ref:`01 · MCC basics <g02-mcc-basics-en>`

        Particles, background and probability
      - :ref:`02 · Implementation <g02-implementation-en>`

        Files, sampling workflow and interfaces
      - :ref:`03 · Acceleration <g02-acceleration-en>`

        Caches, sampling and CPU parallelism
      - :ref:`04 · Scope and limits <g02-generality-en>`

        What can change, and when to extend

   .. rubric:: 1.1 Tracked particles and the background

   .. tip::
      :class: g02-terms

      - The projectile is the tracked incoming particle. The primary outcome tells what happens to that original particle record: update, removal or species change. Background partners are described by density and temperature.

   G02 stores the velocity and species of each tracked particle, which may be an electron, ion or another modeled species.
   The surrounding gas is the **background**, described by number density, temperature and mean velocity.
   When a partner velocity is needed, it is sampled from the background distribution without storing every gas molecule's path.

   A two-body reaction has one tracked particle and one background reactant; a three-body reaction has two background reactants.
   A **reaction channel** specifies participants, products and rate. Several channels form a collision network.

   .. list-table:: Terms to know first
      :header-rows: 1
      :widths: 25 75

      * - Term
        - Meaning
      * - Velocity and speed
        - Velocity has a direction; its x component may be positive or negative. Speed is its nonnegative magnitude.
      * - Drift and temperature
        - Drift is the mean velocity. Temperature measures thermal motion relative to that mean, with bulk motion removed.
      * - Elastic collision
        - The pair's total momentum and kinetic energy stay constant. Energy exchange can speed up or slow down either particle.
      * - Number density and sample size
        - Background density counts background particles per cubic metre; the number of tracked particles sets the statistical sample size.
      * - Species and state
        - Species identifies an electron, atom or ion; state identifies an internal energy level of that species.

   .. rubric:: 1.2 Collision probabilities and rates

   .. tip::
      :class: g02-terms

      - A null collision is a rejected candidate: sampled waiting time is consumed but the particle state stays unchanged. It is a sampling device, not a physical reaction.
      - A majorant bounds the true collision rate from above. Candidates use this bound and are accepted with actual-rate/bound probability. Loose bounds waste candidates; violated bounds cause errors.

   First determine how often collisions occur. The collision frequency :math:`\nu` has units 1/s.
   A frequency of 1000/s means an average of 1000 collisions per particle per second under those conditions.
   Individual waiting times still vary.

   Two common kinds of input are:

   - A **cross section** :math:`\sigma` in m² describes the effective area for a reaction and can depend on relative energy.
     At a given relative speed :math:`g`, :math:`n\sigma g` gives the corresponding frequency.
     A moving background requires sampling or averaging over partner velocities.
   - A **two-body rate coefficient** :math:`k` in m³/s gives :math:`\nu=nk` after multiplication by background number density :math:`n`.
     G02 looks up these coefficients at the specified background temperature.
     Three-body coefficients have units m⁶/s and require two density factors.

   .. container:: g02-equation

      If the real collision frequency stays constant throughout an interval :math:`\Delta t`,
      the probability of at least one collision is:

      .. math::

         P = 1-\exp(-\nu\Delta t).

      Here :math:`\Delta t` is elapsed time and :math:`\exp(x)=e^x` is the exponential function.
      For :math:`\nu\Delta t=0.1`, :math:`P\approx9.52\%`.
      More than one collision can occur in the interval; G02 samples candidate times successively until the step ends.

   .. rubric:: 1.3 Outcomes must obey the physical model

   A real collision may change only velocities, or also internal energies, species and particle counts.
   Excitation, for example, transfers energy into an internal level; ionization creates an additional free electron.
   The selected reaction model determines the outcome. Momentum and energy accounting includes both particles and background.

   With a rule for how often events occur and a rule for their outcomes, we can now follow G02's implementation.

   .. _g02-implementation-en:

   .. rubric:: 2. MCC implementation in G02
      :class: g02-chapter

   G02 stores reaction rules in CSV tables. It loads the model, validates species, energies and units, then samples collisions.
   The host supplies particles, background conditions and a time step.
   G02 returns updated particles, reaction counts and background exchange.
   If particles transfer energy to the gas, that transfer appears in the report.

   .. _g02-csv-input-en:

   .. rubric:: 2.1 CSV model input and templates

   Before using G02, prepare a **model-package directory**. Its CSV files describe the species, reactions and collision rates.
   The first row contains column names; later rows contain data. Pass the directory path to the loader,
   which uses ``manifest.csv`` to find the other tables.

   .. list-table:: Tables in a model package
      :header-rows: 1
      :widths: 48 52

      * - Files
        - What do they describe?
      * - ``manifest.csv``
        - The file list: which tables to read.
      * - ``species.csv``, ``states.csv``
        - Species, masses, charges and internal energy levels.
      * - ``reactions.csv``, ``reactants.csv``, ``products.csv``
        - Collision participants, algorithms and resulting products.
      * - ``rate_laws.csv``, ``datasets.csv``, ``tables/*.csv``
        - Cross-section or rate-coefficient lookup, numerical values, units and data sources.
      * - ``composition.csv`` (optional)
        - Element composition for element-balance checks.

   .. tip:: Start from a template

      Copy the original filled ``collision_box_elastic`` example first; it contains just one elastic reaction.
      :doc:`Tests → 009 → CSV templates </tests/009_collision/G02_csv_templates>` provides
      **blank templates, filled downloads, a filling order and checking commands**.
      A blank copy lives in ``G_Collision/G02_MCC_network/templates/blank/``.
      Tests retains the identical blank template and the filled examples in its ``data/`` directory.
      All example values are synthetic and only intended for software validation.

   Load the prepared model with C++ ``MccEngine::load`` or Fortran
   :doc:`sub_G02_mcc_load <G02_MCC_network/sub_G02_mcc_load>`, usually once at initialization.

   .. rubric:: 2.2 Module role and file responsibilities

   G02 describes one tracked particle interacting with one or two background reactants.
   It accepts two-body cross sections and two- or three-body rate coefficients.
   The host handles fields, position updates, walls, and any evolution of the background using the reported exchange.

   .. figure:: ../../images/G_Collision/G02/architecture_en.svg
      :alt: C++, C and Fortran entries connecting batch processing, engine, model tables and kinematics
      :width: 100%

      Follow the arrows: receive particles → process the batch → sample collisions → compute outgoing velocities → return updates.
      Reaction data supplies sampling rules and rates; each box identifies the corresponding source file.
      Select the image to open it at full size.

   The core is C++20. A C ABI exposes C functions to C and Fortran;
   Fortran uses ``ISO_C_BINDING`` through ``mod_G02_MCC_network``.
   MPI distributes work among processes and OpenMP among CPU threads.
   Both are optional; the base build needs neither.

   The sidebar groups files under Basics, Model, Collision, C API, Fortran API and MPI.
   This table lists the main implementations; group pages include every header and source file.
   Headers and C++ implementations are directly in the G02 root,
   and Fortran wrappers in ``fortran_interface/``. Follow a filename for the detailed interface.

   .. list-table:: File roles
      :header-rows: 1
      :widths: 38 62

      * - Source file
        - Role
      * - :doc:`mod_G02_MCC_network.f90 <G02_MCC_network/mod_G02_MCC_network>`
        - Fortran module defining types and including routines and functions.
      * - :doc:`sub_G02_mcc_load.f90 <G02_MCC_network/sub_G02_mcc_load>`
        - Load a model package and create a collision context.
      * - :doc:`sub_G02_mcc_model_queries.f90 <G02_MCC_network/sub_G02_mcc_model_queries>`
        - Query names, IDs and properties of species, states and reactions.
      * - :doc:`sub_G02_mcc_step.f90 <G02_MCC_network/sub_G02_mcc_step>`
        - Advance collisions for the particle array.
      * - :doc:`sub_G02_mcc_collide.f90 <G02_MCC_network/sub_G02_mcc_collide>`
        - Compute a single-particle outcome.
      * - :doc:`sub_G02_mcc_session.f90 <G02_MCC_network/sub_G02_mcc_session>`
        - Initialize or close reusable sessions.
      * - :doc:`sub_G02_mcc_cleanup.f90 <G02_MCC_network/sub_G02_mcc_cleanup>`
        - Collect reports and release results and model resources.
      * - :doc:`fun_G02_mcc_api_version.f90 <G02_MCC_network/fun_G02_mcc_api_version>`
        - Return the ABI version.
      * - :doc:`fun_G02_mcc_model.cpp <G02_MCC_network/fun_G02_mcc_model>`
        - Read and validate models and tables with the compile, table and csv implementations.
      * - :doc:`fun_G02_mcc_engine.cpp <G02_MCC_network/fun_G02_mcc_engine>`
        - Sample candidate times, channels and real collisions; record background exchange.
      * - :doc:`fun_G02_mcc_batch.cpp <G02_MCC_network/fun_G02_mcc_batch>`
        - Process particles in batches, reuse workspace and commit updates.
      * - :doc:`fun_G02_mcc_kinematics.cpp <G02_MCC_network/fun_G02_mcc_kinematics>`
        - Compute final velocities from total momentum and available energy.
      * - :doc:`fun_G02_mcc_c_api.cpp <G02_MCC_network/fun_G02_mcc_c_api>`
        - Expose the C interface, handles, status codes and errors.
      * - :doc:`mod_G02_MCC_network_mpi.f90 <G02_MCC_network/mod_G02_MCC_network_mpi>`
        - MPI module including session and step routines.
      * - :doc:`sub_G02_mcc_mpi_session.f90 <G02_MCC_network/sub_G02_mcc_mpi_session>`
        - Create and close MPI collision sessions.
      * - :doc:`sub_G02_mcc_mpi_step.f90 <G02_MCC_network/sub_G02_mcc_mpi_step>`
        - Coordinate collision steps and globally unique child IDs.

   .. rubric:: 2.3 Time-step workflow

   Load and prepare the reaction model during initialization.
   Then repeat this workflow for each time step:

   .. figure:: ../../images/G_Collision/G02/step_flow_en.svg
      :alt: Batch step: sampling, real or null collisions, iteration and commit
      :width: 100%

   .. rst-class:: g02-steps

   1. **Read current conditions:** particle species/state and the cell's background density, temperature and mean velocity.
   2. **Schedule a candidate:** sample a waiting time using an upper bound on the real frequency.
      Stop for this particle if no channel is available or the wait exceeds the remaining time.
   3. **Select and accept or reject:** choose a channel in proportion to its bound,
      then accept it with probability equal to its real frequency divided by its bound.
   4. **Update or retain the state:** a real event invokes the physical model.
      A rejected candidate is a null collision; time advances while the particle stays unchanged.
      Continue through the remaining time.
   5. **Aggregate and commit:** after all particles succeed, the batch interface commits updates and children,
      returning counters and a conservation ledger. Failure preserves the original particle array.
      This prepare-before-commit approach is called transactional.

   .. figure:: ../../images/G_Collision/G02/event_timeline_en.svg
      :alt: Real and null candidates within a time step, followed by an out-of-step wait
      :width: 100%

      Illustrative times. The out-of-step candidate is not executed; sampling restarts next step.
      Select the image to open it at full size.

   The code calls this sampling workflow **G02 algorithm C01**. G02 algorithm C02–C08 compute the physical outcomes of real collisions.
   The upper bound schedules candidates; acceptance/rejection recovers the model's real event rate.
   See :ref:`architecture <g02-architecture-en>` for data flow and
   :ref:`sampling <g02-sampling-en>` for random numbers and channel selection.

   .. tip:: Scope of algorithm IDs

      “G02 algorithms C01–C08” names algorithms inside this collision module. ``C_Gather`` has its own module IDs.
      The CSV ``algorithm`` field still uses raw values such as ``C02``; G02 algorithm C01 is the shared sampling procedure.

   .. raw:: html

      <details class="g02-details">
        <summary>Further reading · Rate formulas and state changes</summary>

   .. only:: not html

      .. rubric:: Rate formulas and state changes (second reading)

   Bounds follow the current particle's background conditions; no global ``nu_prime`` is required.
   A zero total bound means no candidate events for this particle in this step.
   Here projectile means the tracked particle being processed and majorant means a frequency bound.
   In the formulas, r labels channels, n is background density, s its reactant count, shape bounds the tabulated rate factor,
   and safety is a dimensionless margin. The random number u is uniform from 0 to 1, excluding 1; ln is the natural logarithm.
   For the current projectile ``(species, state)`` the engine sums the channel bounds:

   .. math::

      \Lambda = \sum_r \Lambda_r,
      \qquad
      \Lambda_r = \text{shape}_r \cdot \prod_i n_i^{s_i} \cdot f_{\mathrm{safety}}.

   For a positive total bound, the candidate waiting time is:

   .. math::

      \tau = -\frac{\ln(1-u)}{\Lambda}.

   A candidate occurs when :math:`\tau` fits in the
   remaining :math:`\Delta t`; the channel is drawn proportionally to its
   majorant contribution, so multiple background components compete
   automatically. A candidate is a real event (final state built by the
   corresponding G02 algorithm C02–C08 algorithm) or a null event that leaves the particle
   unchanged. If the real rate exceeds the compiled majorant the engine raises
   a hard error instead of clipping silently.

   A channel is eligible only when the primary ``(species, state)`` matches its
   declared projectile state; no eligible channel means zero events. After a
   real ``Update`` the engine rebuilds the active channels and total majorant
   from the new primary state before sampling the remaining :math:`\Delta t`;
   The batch interface continues the remaining time after ``MoveSpecies``;
   ``Remove`` stops the step. The legacy single-particle interface stops after
   a species move. Null events do not rebuild. Only active backgrounds are required.

   .. raw:: html

      </details>

   .. rubric:: 2.4 Implemented physics and collision outcomes

   Once G02 algorithm C01 selects a real event, its physics is handled by one of these algorithms.
   Start with the physical meanings; consult field constraints when editing a model.

   .. code-block:: text
      :caption: Algorithm responsibilities (pseudocode, not callable functions)

      while remaining_time > 0 and particle_alive:
          if no_active_channel:
              break
          event = sample_candidate()  # G02 algorithm C01: sample candidate
          if event.wait > remaining_time:
              break
          remaining_time -= event.wait
          if event.is_null:
              continue                # Null collision: preserve state
          rule = reaction.algorithm   # G02 algorithms C02–C08
          outcome = apply_physics(rule, reactants, products, energy)
          check_conservation(outcome) # Check momentum and energy
          collect(outcome)            # Collect particle and reservoir changes
          update_primary(outcome)     # Update/remove/convert; rebuild channels if needed

   For a G02 algorithm C02 elastic reaction ``A + B → A + B``, **velocities change while species and internal states remain the same**.
   Outgoing velocities follow the pair's total momentum and available energy; the individual A particle can gain or lose kinetic energy.
   Compare the :doc:`collision engine <G02_MCC_network/fun_G02_mcc_engine>` and
   :doc:`final-state kinematics <G02_MCC_network/fun_G02_mcc_kinematics>` implementations.

   - G02 algorithm ``C02`` elastic two-body: exchange momentum and kinetic energy, preserving species and internal states;
   - G02 algorithm ``C03`` discrete state transition: excitation or de-excitation changes an internal level, with ``q`` consistent with the state
     energies in ``states.csv``;
   - G02 algorithm ``C04`` dissociation / multi-product: split a molecule or form several products;
   - G02 algorithm ``C05`` ionization, requiring an additional free electron;
   - G02 algorithm ``C06`` attachment / detachment: capture or release an electron;
   - G02 algorithm ``C07`` charge exchange, with ``identity_exchange`` restricted to strict
     resonant channels: same species multiset, two distinct species with
     different charges, equal reactant masses, ``q/radiated/ker_min = 0``, and
     velocities mapped by product species (the projectile-species product takes
     the background velocity and the background-species product takes the
     projectile velocity);
   - G02 algorithm ``C08`` recombination / mutual neutralization, requiring the number of
     charged particles to decrease.

   Angular models are ``isotropic``, explicit ``cone``
   (``angular_cos_min``/``angular_cos_max``) and ``identity_exchange``. Energy
   models are ``n_body_phase_space`` and ``equal_share`` (exactly two
   products). Unimplemented models such as ``opal_like`` are rejected at load
   time. The two-body, N-body and equal-share final states all enforce
   ``ker_min_ev`` with a scale-aware tolerance derived from
   ``numeric_limits<double>::epsilon()``; a single-product channel with
   ``ker_min_ev > 0`` is rejected at compile time.

   .. rubric:: 2.5 Host integration

   .. tip::
      :class: g02-terms

      - ParticleAdapter connects host-owned storage to G02, exposing particle reads and update commits. It is an interface, not another physical particle.
      - A workspace is reusable scratch memory. A session holds this state for C/Fortran callers. Reuse reduces allocation, but one instance must not serve concurrent calls.
      - ABI (Application Binary Interface) defines how compiled code passes arguments and results. A handle refers to a library-owned object; use API functions rather than inspecting its internals.

   PIC (Particle-in-Cell) organizes fields, particle motion and collisions into separate operations.
   Call G02 once for each collision step in the time loop: C++ ``MccStepper::step(adapter, background, dt, step, seed)``,
   C ``ap_g02_mcc_step``, or Fortran ``sub_G02_mcc_step``. Provide cell/species/state
   background fields and receive exchange increments, reaction counts and a conservation ledger.
   C++ ``ParticleAdapter`` connects host-owned storage. Children participate
   from the next step; a failed call does not commit particles. The legacy
   ``MccEngine::collide`` single-particle API remains available.

   .. code-block:: text
      :caption: Host call order (pseudocode)

      initialize(model, particles, background, workspace)
      for step in time_steps:
          update_host_state()  # Update fields, positions and background
          result = collision_step()
          if result.success:
              apply_sources(result)  # Apply exchange using the host model
          else:
              handle_error()         # Do not consume failed results
      cleanup()  # Close Fortran session and model

   **C++: initialize once, call once per step.** These excerpts come directly from a buildable host example.
   ``argv[1]`` is the model directory. This caller uses ``tests/009_collision/G02_MCC_network/data/demo_binary`` with species such as ``e-`` and ``M``.
   Particle and background initialization is in the
   :download:`complete C++ example <../../../../tests/009_collision/G02_MCC_network/examples/host_pic/main.cpp>`.

   .. literalinclude:: ../../../../tests/009_collision/G02_MCC_network/examples/host_pic/main.cpp
      :language: cpp
      :lines: 13-17
      :dedent: 4
      :caption: Initialize the model, stepper and workspace

   .. literalinclude:: ../../../../tests/009_collision/G02_MCC_network/examples/host_pic/main.cpp
      :language: cpp
      :lines: 37-44
      :dedent: 4
      :caption: Actual call: run three collision steps and print counts

   ``adapter`` connects the particle array; ``background`` supplies gas conditions.
   ``1.0e-8`` is the time step in seconds, ``step`` is the step index, ``1234`` the random seed,
   and ``workspace`` reusable temporary storage. ``result.reservoir`` records background exchange;
   the host decides whether to evolve the background.

   .. tip:: Declarations required by Fortran fragments

      The intrinsic ``iso_c_binding`` module provides C-compatible kinds such as ``c_double``, ``c_int``, ``c_int32_t`` and ``c_int64_t``. G02 does not re-export them to the host.
      In the declaration section, write ``use, intrinsic :: iso_c_binding``, ``use mod_G02_MCC_network`` and ``implicit none``; declare status as ``integer(c_int)``.
      Short calls assume initialized context, arrays and step parameters; see :doc:`the complete caller <G02_MCC_network/sub_G02_mcc_load>`.

   **Fortran: the same flow, with status-code checks.** This excerpt comes from the
   :download:`complete Fortran example <../../../../tests/009_collision/G02_MCC_network/examples/host_fortran/main.f90>`.
   The caller has already initialized ``context``, ``particles`` and ``gas`` using ``demo_binary``.

   .. literalinclude:: ../../../../tests/009_collision/G02_MCC_network/examples/host_fortran/main.f90
      :language: fortran
      :start-at: call sub_G02_mcc_session_init
      :end-at: call sub_G02_mcc_close(context)
      :dedent: 4
      :caption: Actual call: create session, advance, check status and clean up

   ``status=0`` means success. The example stops on errors; a production host may log and handle them itself.

   With the legacy single-particle API, the host commits ``StepOutcome`` atomically: ``Update`` replaces the
   projectile, ``Remove`` deletes it, ``MoveSpecies`` changes its species,
   ``None`` leaves it unchanged; ``CreatedProduct`` entries carry
   ``birth_step`` for the next step; ``ReservoirDelta`` entries update the
   background source/sink; any error discards the whole step.

   When writing a caller, follow the entry needed at each stage:

   - Initialize: :doc:`load the model <G02_MCC_network/sub_G02_mcc_load>` and
     :doc:`query species, states and reactions <G02_MCC_network/sub_G02_mcc_model_queries>`.
   - Advance a step: :doc:`Fortran batch parameters <G02_MCC_network/sub_G02_mcc_step>` and
     :ref:`particle, background and report fields <g02-data-types-en>`.
   - Repeated steps and shutdown: :doc:`workspace sessions <G02_MCC_network/sub_G02_mcc_session>` and
     :doc:`report conversion and cleanup <G02_MCC_network/sub_G02_mcc_cleanup>`.
   - Integrate a legacy caller: :doc:`Fortran single-particle interface <G02_MCC_network/sub_G02_mcc_collide>`.
     Find the C++, C and MPI interfaces in the file-role table above.

   .. rubric:: 2.6 Units and boundaries

   .. tip::
      :class: g02-terms

      - Reservoir deltas track background gains/losses of particles, momentum and energy. A conservation ledger compares totals before and after reactions. Do not apply both as background source terms.

   Model tables use eV for energy, K for temperature and kg for mass; positions and time use m and s.
   Momentum and energy exchange in reports use kg·m/s and J; see :ref:`data types <g02-data-types-en>`.
   Cross sections are m²
   (two-body only); two-body rate coefficients are m³/s and three-body rate
   coefficients are m⁶/s. ``q_value_ev`` is positive for exothermic and
   negative for endothermic channels; ``threshold_ev`` only controls the
   channel threshold; ``ker_min_ev`` only imposes a minimum final relative
   kinetic energy; ``radiated_energy_ev`` records radiated/unresolved energy.

   .. code-block:: text
      :caption: Unit examples (illustrative values, not an additional API)

      Model:      energy_ev = 5.0          means 5 eV
      Background: temperature_k = 300.0    means 300 K, not 300 degrees Celsius
      Background: density_m3 = 1.0e20      means 10^20 particles per cubic metre
      Particle:   velocity = (1000, 0, 0)  means 1000 m/s along x
      Call:       dt = 1.0e-8              means 10 ns

   Convert to the same units before comparing table energies with report energies:
   **5 eV ≈ 8.01 × 10⁻¹⁹ J**. This C++ fragment uses the library's conversion constant:

   .. code-block:: cpp
      :caption: Convert a table energy from eV to J

      const double energy_ev = 5.0;
      const double energy_j =
          energy_ev * algoplasma::mcc::elementary_charge_c;

   Read the sign of ``q_value_ev`` as follows:

   .. code-block:: text

      q_value_ev = +2.0    the reaction releases 2 eV
      q_value_ev = -2.0    the reaction absorbs 2 eV
      threshold_ev = 3.0  the channel threshold is 3 eV; it does not deduct 3 eV per event

   These values must also satisfy the selected algorithm and state-energy constraints; they cannot be chosen independently.

   No CUDA; MPI and OpenMP are optional CPU backends. No explicit
   particle pairing; the demonstration data are synthetic and must not be used
   for scientific conclusions.

   .. rubric:: 2.7 Source layout and build commands

   ``G_Collision/G02_MCC_network/`` contains functional code, CSV templates and module READMEs:
   The root holds ``*.hpp`` and ``*.h`` headers and ``*.cpp`` implementations,
   and ``fortran_interface/`` holds the Fortran calling interface.
   Examples, synthetic data, regression tests and CMake recipes live in
   ``tests/009_collision/G02_MCC_network/``.

   .. code-block:: text
      :caption: Source and test directory layout

      G_Collision/G02_MCC_network/
      ├── mcc.hpp, *.hpp, *.h
      ├── fun_G02_mcc_*.cpp
      ├── templates/blank/  # CSV templates
      └── fortran_interface/
          ├── mod_G02_*.f90
          ├── sub_G02_*.f90
          └── fun_G02_*.f90

      tests/009_collision/G02_MCC_network/
      ├── examples/, data/, templates/
      ├── cpp/, fortran/
      ├── tools/validate_model.cpp
      ├── cmake/, CMakeLists.txt
      └── run.sh

   From the repository root in a Linux/WSL terminal, build and install the library with the commands below.
   You need CMake 3.20 or newer, a C++20 compiler, and C and Fortran compilers:

   .. code-block:: bash

      cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_mcc_module \
        -DCMAKE_BUILD_TYPE=Release -DG02_MCC_BUILD_TESTS=OFF
      cmake --build /tmp/g02_mcc_module -j 4
      cmake --install /tmp/g02_mcc_module --prefix /tmp/g02_mcc_install

   ``G02_MCC_BUILD_TESTS=OFF`` builds only the library. Add ``-DG02_MCC_ENABLE_FORTRAN=OFF``
   if you do not need Fortran. The caller supplies the model-package path; synthetic data stay in the test directory.
   See the :doc:`collision test guide <../../tests/009_collision/index>` for the full suite.

   .. _g02-acceleration-en:

   .. rubric:: 3. Accelerating MCC
      :class: g02-chapter

   G02 reduces repeated work and distributes particle calculations on CPUs. There is no GPU/CUDA backend.

   .. rubric:: 3.1 Reduce repeated work

   - **Prepare once:** ``fun_G02_mcc_compile.cpp`` validates reactions and prepares bounds at initialization.
   - **Reuse memory and channels:** ``fun_G02_mcc_batch.cpp`` reuses workspaces and prepared channels for matching cells, species, states and backgrounds. Relevant changes invalidate caches.
   - **Skip zero-density channels:** their rates are exactly zero, so pruning preserves the model.
   - **Avoid redundant sorting and copying:** sorted IDs skip sorting; steps without births or removals can update particles in place.

   .. rubric:: 3.2 Faster channel selection

   ``fun_G02_mcc_engine.cpp`` offers default Prefix sampling and optional Alias sampling.
   Prefix sampling searches cumulative weights. Alias sampling builds a lookup table for constant-time draws.
   Setup costs mean Alias is not always faster; compare complete steps on your workload. Both sample the same probabilities.

   .. rubric:: 3.3 OpenMP and MPI: share the particles

   ``fun_G02_mcc_batch.cpp`` uses OpenMP threads within a process.
   ``fun_G02_mcc_mpi.cpp`` coordinates processes, each owning local particles; the host owns partitioning and migration.
   MPI coordinates failures and child IDs without transferring ordinary collision particles. Both modes can be combined.

   .. code-block:: bash

      cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_parallel \
        -DCMAKE_BUILD_TYPE=Release -DG02_MCC_ENABLE_OPENMP=ON -DG02_MCC_ENABLE_MPI=ON
      cmake --build /tmp/g02_parallel -j 4

   .. code-block:: cpp
      :caption: C++ settings fragment (host supplies particles and background)

      using namespace algoplasma::mcc;
      const auto engine = MccEngine::load(
          "tests/009_collision/G02_MCC_network/data/collision_box_elastic");
      StepOptions options;
      options.backend = CpuBackend::OpenMp;
      options.threads = 4;
      options.sampler = ChannelSampler::Prefix;
      MccStepper stepper(engine, options);
      MccWorkspace workspace;  // Create before the time loop; reuse
      // Inside the time loop:
      auto report = stepper.step(adapter, background, dt, step, seed, workspace);

   These types are in ``algoplasma::mcc``.
   Create ``MccWorkspace`` outside the time loop and reuse it in ``MccStepper::step``.
   ``StepOptions`` selects ``CpuBackend::OpenMp``, a thread count and ``ChannelSampler::Prefix`` or ``Alias``.
   MPI requires host initialization and ``DistributedMccStepper``; see :doc:`MPI <G02_MCC_network/group_mpi_interface>`.

   Compare Release builds using identical models, particle counts and step counts. Warm up, repeat, and compare median whole-step times.
   Small workloads may lose to thread or communication overhead. Check conservation and statistical consistency as well as timing.
   See the :download:`performance guide <../../../../tests/009_collision/G02_MCC_network/PERFORMANCE.md>` for benchmark commands.

   .. _g02-generality-en:

   .. rubric:: 4. G02 generality and limits
      :class: g02-chapter

   G02 is a **configurable, multispecies particle–background collision core**.
   Within its supported reaction rules, species, states, reaction networks and rate data can change while the same core samples events, constructs outcomes and reports exchange.
   Its scope depends on three questions: **Can the data represent the model? Are its physics rules implemented? Can the host supply the required background?**

   .. rubric:: 4.1 Reusable design

   Think of G02 as a program that executes reaction rules: CSV files describe the rules, and the collision core applies them.

   - **Data is separate from algorithms:** species names, masses, charges, states and reactions come from CSV. A particular gas network is not hard-coded into the stepping loop.
   - **The computational flow is shared:** channels use G02 algorithm C01 for sampling and G02 algorithms C02–C08 for physical outcomes.
     Adding a supported reaction reuses event counting, product handling and conservation accounting.
   - **The host is separate from collisions:** the host supplies particles, cell IDs, backgrounds and time steps. G02 returns particle changes and background exchange.
     C++, C and Fortran use the same core; adapters connect different particle storage layouts.

   For example, expanding one elastic channel into an elastic + excitation + ionization network requires complete species, state, reaction and rate data that satisfy the algorithm constraints.
   The same batch entry can normally be retained. Whether the network runs and whether its data represents a real gas require separate validation.

   .. rubric:: 4.2 Configuration and extensions

   .. list-table:: Decide by the change you need
      :header-rows: 1
      :widths: 30 32 38

      * - Desired change
        - Where to change it
        - Conditions or limits
      * - Species, masses, charges or internal states
        - CSV model package
        - Update references; masses, states and reactions must be consistent.
      * - Add/remove supported reactions or replace cross-section/rate tables
        - CSV model package
        - Obey G02 algorithms C02–C08, units and validity ranges.
      * - Mixed backgrounds or new densities, temperatures and drift velocities
        - Background arrays supplied each step
        - Backgrounds are indexed by cell, species and state; reaction data must remain complete.
      * - Move from a zero-dimensional box to a spatial simulation
        - Host particles, cell IDs and background interface
        - G02 handles local collisions; the host owns geometry, fields and position updates.
      * - Use C/Fortran or a different particle layout
        - Language interface or particle adapter
        - Preserve units, valid IDs, particle lifecycle and error-handling contracts.
      * - Add a scattering law, energy-sharing rule or reaction mechanism
        - Extend core code, schema validation and tests
        - Writing a new name in CSV does not implement its behavior.

   Species and channel counts can grow with the model, subject to ID ranges, memory and computational cost.
   The zero-dimensional collision box is an introductory validation case; the library also accepts host-provided backgrounds that vary by spatial cell.

   .. rubric:: 4.3 Current implementation boundaries

   .. list-table:: Where to check the assumptions
      :header-rows: 1
      :widths: 26 74

      * - Boundary
        - Current contract
      * - Collision partners
        - Each reaction has exactly one tracked particle and one or two background reactants, for total order 2 or 3.
          There is no direct pairing of two tracked particles or general paired Coulomb collision model.
      * - Rate input
        - Two-body reactions use cross sections versus relative energy or rate coefficients versus temperature. Three-body reactions use temperature rate coefficients.
          Arbitrary dependence on fields, trajectory history or other variables requires an extension.
      * - Background velocities
        - Each component has a density, one temperature and a mean velocity. Required background velocities are sampled from a drifting Maxwellian.
          Arbitrary nonthermal velocity distributions are outside the current interface.
      * - Outgoing motion
        - Existing kinematics is classical and nonrelativistic. Angular models are isotropic, cone or strictly constrained identity_exchange.
          Energy models are n_body_phase_space or equal_share with exactly two products. Arbitrary differential cross sections or Opal-like sharing need code changes.
      * - Background evolution
        - A call uses the supplied background and returns exchange increments. The host updates depletion, heating or flow for subsequent steps.
          Significant background changes require checking the coupling method and time step.
      * - Full simulation
        - G02 does not solve fields, advance positions, handle walls, partition MPI domains or migrate particles.
          Optional parallel backends currently use CPU OpenMP/MPI.

   .. tip::
      :class: g02-terms

      A **Maxwellian** describes random thermal motion with one temperature, plus a mean drift velocity.
      Higher temperature gives a wider thermal velocity spread. Two distinct beams or a strong nonthermal high-energy tail may require more information than one temperature and mean velocity.
      **Nonrelativistic** means ordinary momentum and kinetic-energy formulas, applicable at speeds much lower than light.

   Temperature rate coefficients generally include an average over an assumed velocity distribution; those data assumptions must also match the application.
   Charge and energy checks catch some errors but do not establish the validity of reaction data or physical approximations.
   Element checks use only declared compositions, so composition data also needs to be complete.

   .. rubric:: 4.4 Assessing a new application

   1. **Write the reactants:** can each reaction be represented as one tracked particle plus one or two background reactants?
   2. **Check rules and data:** are the G02 algorithm, angular/energy model and data over the required energy or temperature range available?
   3. **Check the host:** can it supply backgrounds and update later conditions from reported exchange? Then validate the particular model.

   When all three hold, configuration and interface integration are usually sufficient.
   Otherwise extend the relevant layer first: custom scattering needs new kinematics; explicit particle pairing needs a different collision treatment.
   Consult the :ref:`CSV reference <g02-schema-en>` and :doc:`kinematics interface <G02_MCC_network/fun_G02_mcc_kinematics>`.
   Existing synthetic cases validate software behavior under specified conditions, not every gas, reaction or energy range.

   The zero-dimensional collision box checks conservation, collision statistics and thermalization.
   See :ref:`Tests → 009 → Collision box <g02-collision-box-en>` for the physics, run instructions and pass criteria.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">AlgoPlasma contributors</p>
      </div>
