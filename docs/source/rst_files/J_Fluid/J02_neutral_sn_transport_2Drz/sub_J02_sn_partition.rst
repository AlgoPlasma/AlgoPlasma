Spatial MPI Partition
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J02_sn_partition.f90`` 记录每个进程负责的空间区域，建立进程交界面的连接，并在各进程间共同检查输入。
   本页先说明如何划分网格和准备本地数据；下一页说明如何通信和求解。
   物理模型与 DG 单元方程沿用前面 01–12 页的定义。

   先区分两种计算单位。进程有各自的数组和内存；一个进程不能直接读取另一个进程的数组，
   需要通过 MPI 发送和接收数据。线程在同一进程内部工作，可以读取共同的网格和边界数组。
   本模块用 OpenMP 将不同离散速度的求解分给这些线程。

   例如，单域有 192 个离散速度时，可以让 4 个线程分别计算其中的一部分，
   但每个速度仍须遍历完整空间网格。MPI 则先将空间网格划为多个区域，
   一个进程只计算自己区域内的单元，所需的外部上游分布由邻居进程发来。
   混合并行同时使用这两种分工。

   Open MPI 是提供 MPI 功能的一种软件实现；它与 OpenMP 不是同一个名称，也不是同一种分工方式。

   .. rubric:: 1. 空间分区与本地数组

   将全局 :math:`N_r\times N_z` 网格划为 :math:`P_r\times P_z` 个矩形块。
   每个进程只保存自己块内的单元，但保留全部 :math:`N_{\mathrm{dir}}` 个离散速度。
   设当前块的起点为 :math:`(I_0,K_0)`，单元数为 :math:`(n_r,n_z)`，则

   .. math::

      I=I_0+i-1,\qquad K=K_0+k-1,\qquad
      1\leq i\leq n_r,\quad 1\leq k\leq n_z.

   :math:`(I,K)` 是全局单元索引，:math:`(i,k)` 是传给 J02 的本地数组索引。
   本地边界坐标仍是实际物理坐标，不能把每块的径向起点重设为零。

   以 :math:`8\times6` 个空间单元、:math:`2\times2` 个进程分区为例：

   .. list-table::
      :header-rows: 1
      :widths: 18 24 28 30

      * - 区域
        - 分区坐标
        - 全局单元范围
        - 本地起点与尺寸
      * - 甲（左下）
        - :math:`(0,0)`
        - :math:`I=1\ldots4,\ K=1\ldots3`
        - ``first=[1,1]``，``count=[4,3]``
      * - 乙（右下）
        - :math:`(1,0)`
        - :math:`I=5\ldots8,\ K=1\ldots3`
        - ``first=[5,1]``，``count=[4,3]``
      * - 丙（左上）
        - :math:`(0,1)`
        - :math:`I=1\ldots4,\ K=4\ldots6`
        - ``first=[1,4]``，``count=[4,3]``
      * - 丁（右上）
        - :math:`(1,1)`
        - :math:`I=5\ldots8,\ K=4\ldots6`
        - ``first=[5,4]``，``count=[4,3]``

   每个进程的数组都用本地索引 :math:`i=1\ldots4,\ k=1\ldots3`。
   例如丁区域的本地单元 :math:`(1,1)` 是全局单元 :math:`(5,4)`。
   若使用 192 个离散速度，则每个进程保存的分布尺寸为 ``psi(3,4,3,192)``；
   它保存全部速度，但只保存四分之一的空间单元。

   .. list-table::
      :header-rows: 1
      :widths: 32 28 40

      * - 输入或输出
        - 本地尺寸
        - 存储范围
      * - ``mesh%r_edge/z_edge``
        - ``nr+1`` / ``nz+1``
        - 本进程所负责单元的全部边界；相邻块共用的边界坐标须一致
      * - ``mesh%active``、密度、速度
        - ``(nr,nz)``
        - 仅本地单元，不要求调用者另加用于存放邻居数据的虚单元
      * - ``sigma_t``
        - ``(nr,nz,n_dir)``
        - 本块损失系数，保留全部离散速度
      * - ``psi``
        - ``(3,nr,nz,n_dir)``
        - 本块三个空间系数；不是全局场的复制
      * - ``boundary_inflow``
        - ``(4,nr,nz,n_dir)``
        - 物理入口和开放出口上的规定入流；不存储进程交界面数据
      * - ``partition_flux``
        - ``(4,nr,nz)``
        - 本块 REMOTE 面的坐标向通量；其他位置为零

   通信缓冲由 J02 在内部建立。两个迭代场的主要存储量随本地单元数减小，
   另需与块周长和离散速度总数成正比的系数缓冲。
   把全局数组原封不动传给每个进程，并不符合这个接口。

   .. rubric:: 2. 初始化过程与参数

   通信器指定参与同一次计算的进程集合。二维 Cartesian（笛卡尔）通信器还为每个进程
   安排一个逻辑网格坐标，从而能找到径向和轴向的相邻进程。
   这个逻辑网格描述进程之间的关系，不改变柱坐标物理模型。

   应用先初始化 MPI 并建立这个非周期通信器，再由所有参与进程调用
   ``sub_J02_initialize_partition``。这叫作“集体调用”：
   每个进程都执行同一过程，各自提交本地信息，并共同完成检查。

   .. list-table::
      :header-rows: 1
      :widths: 25 18 57

      * - 参数
        - 方向
        - 说明
      * - ``communicator``
        - 输入
        - 由 ``use mpi`` 接口产生的整数通信器；两个拓扑方向依次是 r、z
      * - ``global_shape(2)``
        - 输入
        - 全局单元数 ``[N_r,N_z]``；各进程相同，且两个方向都足以分配至少一个单元
      * - ``first(2), count(2)``
        - 可选输入
        - 必须成对提供；指定当前进程的全局起点与单元数。省略时均衡划分
      * - ``partition``
        - 输出
        - 保存通信器、邻居、拓扑坐标、本地单元范围，以及匹配默认 ``real`` 的 MPI 数据类型
      * - ``ierr``
        - 输出
        - 成功为零；其余编号由 ``fun_J02_error_message`` 解释

   默认划分将每个方向的单元尽量均分。设当前进程的逻辑坐标为
   :math:`(q_r,q_z)`，两个坐标都从零开始，则全局起点和本地单元数为

   .. math::

      \begin{aligned}
      I_0&=\left\lfloor\frac{N_rq_r}{P_r}\right\rfloor+1,&
      n_r&=\left\lfloor\frac{N_r(q_r+1)}{P_r}\right\rfloor-I_0+1,\\
      K_0&=\left\lfloor\frac{N_zq_z}{P_z}\right\rfloor+1,&
      n_z&=\left\lfloor\frac{N_z(q_z+1)}{P_z}\right\rfloor-K_0+1.
      \end{aligned}

   向下取整使所有单元恰好覆盖一次，不能整除时，不同区域的单元数最多相差一。
   逻辑坐标与进程编号（rank）不是同一个量；程序通过通信器取得邻居，
   不假定进程编号越大就一定处于更右或更上的位置。
   若手动提供 ``first/count``，必须无重叠、无缺口，相邻块的切向网格范围一致。

   ``sn_partition_type`` 的字段含义：

   - ``comm, rank, n_ranks``：借用的通信器及其进程编号、进程数。
   - ``dims(2), coords(2)``：进程网格尺寸及零起始拓扑坐标。
   - ``global_shape(2), first(2), count(2)``：全局尺寸、本块起点与尺寸。
   - ``neighbor(4)``：按 r-low、r-high、z-low、z-high 排列的邻居；物理外侧为 ``MPI_PROC_NULL``。
   - ``real_type``：与本次编译默认实数宽度匹配的 MPI 类型。

   这些字段供应用读取；初始化后不要自行改写。
   应用负责 MPI 启停与通信器释放，J02 不调用 ``MPI_Init`` 或 ``MPI_Finalize``，
   也不在初始化时复制全局网格。

   .. rubric:: 3. 区分进程交界面与物理边界

   完成本地网格初始化后，所有进程调用
   ``sub_J02_initialize_boundary_types(..., partition=partition)``。
   它先确定本块内部相邻关系，再交换邻接边的物理坐标和有效标记。

   .. list-table::
      :header-rows: 1
      :widths: 25 35 40

      * - 面类型
        - 含义
        - 入流来自哪里
      * - ``INTERIOR``
        - 两个有效单元都在本块
        - 本轮已求出的上游单元
      * - ``REMOTE``
        - 有效邻居在另一进程
        - 本轮通信得到的上游系数
      * - ``WALL``
        - 真实壁面或有效区域边缘
        - 上一轮出射分布经反射关系计算
      * - ``OPEN``
        - 真实入口或开放出口
        - 用户规定分布；真空入流为零

   邻接块对应单元无效时，有效侧形成 WALL，不形成 REMOTE。
   只要每块仍包含至少一个网格单元，就允许其所有 ``active`` 标记都是假；
   该进程仍须参加通信与集体调用。

   初始化后，应用仅在本进程负责的物理边界上设置壁面和入口。
   在上述例子中，只有甲、乙满足 ``first(2)==1``，因而接触计算域的下端边界；
   丙、丁的本地第一排单元位于域内，它们的下侧是进程交界面。
   不能把每块本地 ``k=1`` 都当作物理入口，也不能用 OPEN 覆盖 REMOTE。

   .. rubric:: 4. 部分入口的位置与通量归一化

   全局入口带 :math:`[r_{\min},r_{\max}]` 先与各下端块的径向范围相交。
   ``sub_J02_build_partial_zlo_inlet`` 要求区间位于传入网格内，
   因此应用应先裁出本块交集，再调用它；没有交集时令本地开口面积比例和两个区间端点均为零。
   不包含整个计算域下端边界的进程不传入部分入口区间数组。

   若指定的是整个入口的粒子率 :math:`Q`，归一化面积必须是

   .. math::

      A_{\mathrm{in}}=\sum_p A_{\mathrm{in},p},\qquad
      A_{\mathrm{in},p}
        =\sum_{i\in\text{本块物理下端}}\chi_i A_{z-,i,1},\qquad
      J_{\mathrm{in}}=\frac{Q}{A_{\mathrm{in}}}.

   应用用一次全局求和得到 :math:`A_{\mathrm{in}}`，
   然后各进程以同一 :math:`J_{\mathrm{in}}` 构造入口分布函数。
   例如甲、乙各承担入口的一半面积，则它们应各注入 :math:`Q/2`，
   但都使用同一个单位面积通量 :math:`Q/A_{\mathrm{in}}`。
   若分别用 :math:`Q/A_{\mathrm{in},p}`，每块都会注入完整的 :math:`Q`，
   两块合起来就错误地变成 :math:`2Q`。
   每个进程均可传入 ``zlo_inflow``；若该进程不包含计算域的下端边界，求解器会忽略这项入流。

   .. rubric:: 5. 调用约束与当前支持范围

   所有进程须按相同顺序进入同一公共求解过程，即使某块没有入口、没有壁面或没有有效单元。
   离散速度、权重、实数精度、周向张角与反射迭代的停止条件须一致；
   物理场、损失系数和物理边界条件可以因空间位置不同而不同。

   混合构建要求应用使用 ``MPI_Init_thread``，获得至少 ``MPI_THREAD_FUNNELED``。
   这个级别表示：程序可以有多个线程，但 MPI 通信只由初始化 MPI 的主线程执行。
   OpenMP 工作线程负责单元计算，不直接收发消息。
   所有 J02 求解调用由 MPI 主线程发起，通信不放在 OpenMP 工作线程里。
   建议为 J02 单独创建通信器；不能在同一通信器上交叠运行多次求解，
   因为内部通信使用固定标签。

   当前支持非周期、相邻网格面匹配的二维矩形分区，以及每块内部的有效区域掩码。
   不支持周期通信环、非匹配网格、自适应分区或零单元块。
   输入检查失败会在后续通信前同步返回；MPI 通信本身失败则报告并终止该通信器上的任务，
   它不能恢复已经崩溃的进程或中断的网络连接。


   .. rubric:: 6. 从应用输入到分布式求解的调用顺序

   1. 应用初始化 MPI，建立二维进程通信器；
   2. 调用 ``sub_J02_initialize_partition``，取得 ``first/count`` 和邻居信息；
   3. 按这些范围准备本地边界坐标、有效单元标记和损失场，初始化本地网格与几何；
   4. 所有进程调用带 ``partition`` 的面类型初始化；随后只在真实物理边界上设置入口、出口和壁面；
   5. 各进程生成相同的速度求积；应用求入口总面积并据此归一化入流；
   6. 所有进程调用带 ``partition`` 的 ``sub_J02_sweep`` 或 ``sub_J02_solve_transport``；
   7. 检查共同的返回状态，使用本地结果，按需要汇总物理量；最后由应用释放通信器、结束 MPI。

   分区初始化保存本地起止索引和邻居关系，并检查各块衔接。
   应用按这些索引准备本地输入；第 6 步的通信顺序在下一页展开。

   .. rubric:: 7. 本文件内部过程的分工

   下面的辅助过程均为私有过程。应用不直接调用它们，而通过分区初始化、
   面类型初始化或公共求解接口使用这些检查与通信。

   .. list-table::
      :header-rows: 1
      :widths: 40 60

      * - 过程
        - 输入、输出与作用
      * - ``sub_J02_partition_check``
        - 输入本地网格与分区，检查本地单元数和数组尺寸，集体返回状态
      * - ``sub_J02_connect_partition_faces``
        - 输入邻接边坐标与有效标记；初始化时更新面类型，求解时只核对、不覆盖用户数据
      * - ``sub_J02_partition_quadrature``
        - 输入各进程求积对象；通过全局计算检查离散速度数量和数据，输出一致性状态
      * - ``sub_J02_partition_iteration_options``
        - 输入迭代停止条件和反射比例；检查各进程一致，避免提前退出
      * - ``sub_J02_partition_any``
        - 输入本块逻辑值，返回全局逻辑或，用于选择反射分支
      * - ``sub_J02_partition_real_reduce``
        - 输入本块实数标量，返回全局最大值或和，用于收敛量
      * - ``sub_J02_sync_status``
        - 输入本地错误与可选失败位置，返回统一错误及全局位置
      * - ``sub_J02_check_mpi``
        - 输入 MPI 返回码；通信失败时输出 MPI 原因并终止通信器任务

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``sub_J02_sn_partition.f90`` defines spatial ownership and collective validation.
   MPI distributes rectangular r-z blocks; each rank retains all velocity nodes.
   OpenMP threads work inside each rank. Open MPI is an MPI implementation, not OpenMP.

   .. rubric:: Ownership and initialization

   Call ``sub_J02_initialize_partition(communicator, global_shape, partition, ierr, first, count)``
   collectively on an application-owned, nonperiodic 2D Cartesian communicator
   created with the integer ``use mpi`` interface. Topology directions are r then z.
   ``global_shape(2)`` is identical on every rank; optional ``first/count`` must be supplied together.
   They specify one-based global cell starts and positive local cell counts.
   Without them, each axis uses

   .. math::

      F_a=\left\lfloor N_aq_a/P_a\right\rfloor+1,\qquad
      C_a=\left\lfloor N_a(q_a+1)/P_a\right\rfloor-F_a+1.

   Custom blocks must tile the grid without overlap or gaps and have matching transverse extents.
   Rank reordering is supported. J02 borrows the communicator and never initializes or finalizes MPI.
   Read but do not modify the returned metadata: ``comm/rank/n_ranks``, ``dims/coords``,
   ``global_shape/first/count``, ``neighbor(4)``, and ``real_type``.

   Local arrays contain owned cells only: ``psi(3,nr,nz,n_dir)``, ``sigma_t(nr,nz,n_dir)``
   and cell fields ``(nr,nz)``. Coordinate arrays have ``nr+1`` or ``nz+1`` physical edge values;
   no caller-provided ghosts or global field replication is required.
   Global indices are local indices plus ``first-1``.

   .. rubric:: Physical boundaries versus process interfaces

   Call ``sub_J02_initialize_boundary_types`` collectively with ``partition``.
   Matching active neighbors become REMOTE, inactive neighbors form WALL, and physical exterior
   faces default to OPEN. Local active neighbors remain INTERIOR.
   Only overwrite actual physical boundary faces afterwards.

   Partial z-low inlet intervals belong only to ranks with ``first(2)==1``.
   Intersect the global inlet band with the local radial range before calling the local geometry helper;
   use zero fractions/intervals for an empty intersection.
   Normalize a specified global particle rate with the globally summed inlet area, not each block's area.
   The compact ``zlo_inflow`` may be supplied everywhere: the solver suppresses it away from global z-low.

   .. rubric:: Collective contract

   Every rank enters the same solve in the same order, including wholly inactive blocks.
   Quadrature and stopping options must agree. Hybrid builds require MPI main-thread calls
   and at least ``MPI_THREAD_FUNNELED``. Use a dedicated communicator and do not overlap solves
   on it. MPI real types match the default real width; all linked sources must use consistent precision.

   Supported layouts are nonperiodic conforming rectangular blocks with positive cell counts and
   arbitrary local active masks. Periodic cycles, nonconforming grids, adaptive repartitioning and
   zero-cell ranks are unsupported. Numerical/input errors return collectively; genuine MPI
   communication errors abort the communicator rather than providing process-failure recovery.
