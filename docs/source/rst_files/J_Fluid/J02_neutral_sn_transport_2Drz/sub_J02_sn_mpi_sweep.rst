.. J_Fluid contribution history (Git author dates; edit times include timezone).
   2026-10-06 23:50 +08:00 | Yingjie Chen | git fa8cb9f5be05
   2026-10-07 00:49 +08:00 | Yingjie Chen | git 8f4066fd17ec
   2026-11-25 15:14 +08:00 | Yingjie Chen | git 8652258184b5
   2026-11-25 15:59 +08:00 | Yingjie Chen | edit (Codex-assisted)

Distributed Sweep and Flux
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J02_sn_mpi_sweep.f90`` 实现分区后的迎风通信和交界面通量。
   这里的两个过程均为模块内部过程；应用仍调用
   ``sub_J02_sweep`` 或 ``sub_J02_solve_transport``，
   只增加可选参数 ``partition``。不传分区时，原来的单域路径保持可用。

   本页继续使用上一页的甲、乙、丙、丁四个空间分区。
   一个进程内的单元方程与单域版本相同；区别是某些上游单元不在本地内存中，
   必须先接收它们的分布系数。下面先说明需要哪些数据，再说明收发顺序、反射收敛与最终通量。

   .. rubric:: 1. 进程间需要传递哪些上游数据

   DG 页已经把单元问题写成
   :math:`\mathsf A_{K,m}\boldsymbol c_{K,m}=\boldsymbol b_{K,m}`。
   其中每个入流面的贡献是

   .. math::

      b_{f,a}=s_{f,m}\int_f
          \phi_{a,K}\,\psi^{\mathrm{up}}_m\,r\,\mathrm d\ell,\qquad a=1,2,3.

   :math:`s_{f,m}=|\boldsymbol\Omega_m\cdot\boldsymbol n_f|`，
   :math:`\phi_1=1,\phi_2=\xi,\phi_3=\zeta`；共同周向因子与 DG 单元方程一样约去。
   只要知道上游多项式的三个系数，这个积分就与“上游单元在哪个进程”无关。

   例如，乙区域从左侧的甲区域取得入流。对于 :math:`\mu_m>0`，
   甲区域右边缘单元在公共面上的分布为

   .. math::

      \psi_m^{\mathrm{up}}(\zeta)=c_{0,L,m}
                               +c_{1,L,m}
                               +c_{2,L,m}\zeta.

   下标 L 表示甲区域内紧邻交界面的左侧单元。
   乙需要把这个沿面的函数乘自己的检验函数并积分，才能构成右端。
   因此通信传输 :math:`(c_0,c_1,c_2)`，不只传密度或 :math:`c_0`。
   否则接收端会丢掉沿面的线性分布，得到的不是原来的 P1 离散。
   接收端调用 ``sub_J02_add_neighbor_rhs`` 组装入射面右端，
   随后进行 3×3 线性方程求解和保正处理，与单域版本使用相同的过程。

   .. rubric:: 2. 按方向象限安排通信与扫描

   对固定离散速度 :math:`m`，:math:`\mu_m` 和 :math:`\eta_m` 的正负决定上游方向。
   例如两者均为正时，每块依赖 r-low 和 z-low 邻居，
   完成后将结果送给 r-high 和 z-high 邻居。

   .. figure:: /_static/J_Fluid/sn_spatial_mpi_english.svg
      :alt: 四块空间网格从左下向右上进行迎风通信；每块内部线程处理不同离散速度
      :width: 900px

      图中只画正径向、正轴向的速度组。甲没有进程上游，最先计算；
      乙与丙收到甲的结果后可同时计算，丁则需要等乙和丙。
      甲乙丙丁表示空间位置，不是固定的进程编号。

   图中的执行顺序来自粒子的运动方向：
   甲先根据物理入口或已准备好的壁面入流求解，将右边缘系数发给乙、上边缘系数发给丙；
   乙和丙分别完成自己的单元计算后，再向丁发送其所需的上游系数。
   丁的每个入射交界面因此都有了已知分布。

   径向、轴向方向余弦有四种符号组合。当前代码按
   :math:`(+,+),(-,+),(+,-),(-,-)` 的顺序分别处理，
   同一组内的全部速率使用相同的进程依赖关系。
   例如 :math:`(-,-)` 组先从丁开始，随后是乙、丙，最后是甲。
   每个象限在一个进程内的操作顺序为：

   1. 主线程接收两个上游边上的三个空间系数；物理外侧没有邻居，不等待数据。
   2. 启动共用的 ``sub_J02_sweep_batch``。
      OpenMP 工作线程各取一组离散速度；每个离散速度内部仍沿本块迎风顺序逐单元求解。
   3. 等本象限的所有本地速度任务完成，主线程打包两个下游边。
   4. 向下游发送系数，确认发送完成后才复用缓冲，再进入下一象限。

   同一个象限有 :math:`N_q` 个离散速度时：

   - 径向交界面沿轴向有 :math:`n_z` 个相邻单元，每个速度、每个单元发送三个系数，
     因此接收数组尺寸为 :math:`(3,n_z,N_q)`；
   - 轴向交界面沿径向有 :math:`n_r` 个相邻单元，接收数组尺寸为 :math:`(3,n_r,N_q)`。

   在上一页 :math:`n_r=4,n_z=3`、192 个离散速度的例子中，每个象限有 48 个速度。
   径向接收 432 个实数，轴向接收 576 个实数。
   这些缓冲数组只保存进程边缘的邻居系数，不是另一个完整空间场。发送缓冲与之对应。
   相邻进程只交换这些边上的系数，不汇集完整场。
   非周期矩形分区保证依赖图无环；当前不使用跨象限异步重叠或分块通信优化。

   ``sub_J02_mpi_sweep`` 的输入是本地网格、几何、求积、损失、物理边界与用于反射的上一轮分布；
   内部输出是本地新系数和各离散速度的错误记录。
   对应的代码顺序是：``MPI_Recv`` 接收上游数据，
   ``sub_J02_sweep_batch`` 分配本地速度任务，
   ``MPI_Isend`` 发送下游数据，``MPI_Waitall`` 确认发送完成后再复用缓冲。
   MPI 收发都在 OpenMP 工作线程计算区之外，因此不要求允许多个线程同时通信的
   ``MPI_THREAD_MULTIPLE``。
   不启用 OpenMP 时，每块内部串行执行同一个任务循环，即纯 MPI 路径。

   .. rubric:: 3. 各进程共同判断反射迭代的收敛

   只要任一进程含有壁面或部分入口，所有进程就必须进入反射迭代。
   求解过程对“是否有反射”作全局逻辑或，不能让无壁面的块提前走单次扫描并退出。

   壁面反射仍由本进程负责的壁面计算。每个进程保留全部离散速度，
   所以每个面的镜面映射和漫反射归一化都能在本地完成；
   不需要跨进程累加同一个物理面的速度积分。
   REMOTE 面没有壁面反射，它使用本轮收到的上游系数。

   迭代收敛必须考虑所有空间块。令 :math:`\boldsymbol c_p` 是进程 p 的本地系数集合，
   先求全局尺度

   .. math::

      S=\max_p\max\!\left(
          |\boldsymbol c_p^{(\ell)}|,\,
          |\boldsymbol c_p^{(\ell+1)}|\right).

   在 :math:`S>0` 时，各块计算本地绝对值和，再作全局求和：

   .. math::

      \begin{aligned}
      D&=\sum_p\sum
          \left|\boldsymbol c_p^{(\ell+1)}/S-\boldsymbol c_p^{(\ell)}/S\right|,\\
      B_{\mathrm{old}}&=\sum_p\sum|\boldsymbol c_p^{(\ell)}/S|,\\
      B_{\mathrm{new}}&=\sum_p\sum|\boldsymbol c_p^{(\ell+1)}/S|.
      \end{aligned}

   .. math::

      E_{\ell+1}=\frac{D}{\max(B_{\mathrm{old}},B_{\mathrm{new}})}.

   内层求和遍历本块的单元、离散速度和三个系数。
   分母先分别求全局新、旧范数，再取最大值；
   不能用各块最大值的和替代。:math:`S=0` 时变化量定义为零。
   代码用 ``MPI_Allreduce`` 完成这些全局计算：每个进程提交本地值，
   MPI 进行最大值或求和运算，并将同一个结果返回所有进程。
   这里依次需要一个全局最大值 :math:`S`，以及三个全局和
   :math:`D,B_{\mathrm{old}},B_{\mathrm{new}}`。
   所有进程由此计算相同的 :math:`E_{\ell+1}`，同时继续或停止。
   某个区域即使已不再变化，也必须继续参与通信，因为其他区域仍可能有入流传来。

   空间分区可能改变浮点全局求和次序，因此一致性要求使用精度相关容差；
   不同划分的结果可能存在末位舍入差异。

   .. rubric:: 4. 重构进程交界面通量

   前面扫描时的通信，是为了让下游单元完成方程求解。
   收敛后还需要计算交界面上的最终通量，这两个步骤的用途不同。
   ``sub_J02_reconstruct_partition_fluxes`` 再交换相邻块边缘的最终系数，
   使两侧进程同时拥有该面左右（或上下）单元的数据。
   对每个离散速度，按速度符号选取上游单元，并计算其面平均分布
   :math:`\overline\psi^{\mathrm{up}}`，与 Field Reconstruction 页的定义相同。
   以 r 方向交界面为例，

   .. math::

      \overline\psi^{\mathrm{up}}_{r,m}=
      \begin{cases}
         c_{0,L,m}+c_{1,L,m},&\mu_m>0,\\
         c_{0,R,m}-c_{1,R,m},&\mu_m<0,
      \end{cases}
      \qquad
      \Gamma_r=\sum_m w_m v_m\mu_m\overline\psi^{\mathrm{up}}_{r,m}.

   L、R 表示交界面左、右单元，不是 MPI rank 大小。
   轴向交界面的面平均包含原有径向权重修正：

   .. math::

      \overline\psi^{\mathrm{up}}_{z,m}=
      \begin{cases}
         c_{0,B,m}+\bar\xi_i c_{1,B,m}+c_{2,B,m},&\eta_m>0,\\
         c_{0,T,m}+\bar\xi_i c_{1,T,m}-c_{2,T,m},&\eta_m<0,
      \end{cases}
      \qquad
      \Gamma_z=\sum_m w_m v_m\eta_m\overline\psi^{\mathrm{up}}_{z,m},
      \qquad
      \bar\xi_i=\frac{h_{r,i}}{3r_{c,i}}.

   B、T 分别表示交界面下方和上方的单元。
   这些公式与本地内部面的重构相同。两侧进程取得相同系数并按相同的离散速度顺序求和，
   故同一交界面的两个结果具有相同的坐标向符号。
   例如径向交界面上的 :math:`\Gamma_r>0` 表示粒子从左块流向右块。
   对左块，它是流出 :math:`+A_f\Gamma_r`；对右块，它是流入，
   外向计数为 :math:`-A_f\Gamma_r`。两块相加后该内部贡献抵消。
   因此两侧存储相同的坐标向通量，使用时才乘各自的外法向符号和面积。

   输出分三类，不能混用：

   - ``flux_r/flux_z``：两个单元都在本块的内部面。
   - ``partition_flux(4,nr,nz)``：REMOTE 面，单位 :math:`\mathrm{m^{-2}s^{-1}}`；
     每侧进程各存一份，物理收支不能把两份再当成两个外部出口。
   - ``inflow_flux/outflow_flux``：物理 OPEN 面。REMOTE 面在这两个数组中保持零。

   只调用 ``sub_J02_sweep`` 时返回本地分布，不进行这些重构；
   调用 ``sub_J02_solve_transport`` 才返回全部本地场与交界面通量。

   .. rubric:: 5. 错误同步与定位

   进入迎风收发前，求解器先同步本地输入检查结果，检查公共求积与迭代选项，
   并核对交界面坐标和面类型。某个进程检查失败时，其他进程也一起返回。

   若错误发生在单元计算中，仍完成当前通信流程，
   再统一选择错误。失败方向优先选编号最小者；
   同方向按原未分区扫描的迎风单元次序选择。
   返回的 ``failed_i/failed_k`` 是全局单元索引，
   没有单元位置的错误保持零。失败场不可用作有效解。

   这保证已检查到的数值错误不会让其他进程永久等候上游数据；
   不涵盖进程崩溃、网络故障或违反通信器调用约定的程序错误。

   .. rubric:: 6. 构建、调用顺序与后续连续性计算

   MPI 构建使用 MPI Fortran 编译器并定义 ``-DJ02_USE_MPI``；
   混合构建还需编译和链接时均加 ``-fopenmp``。
   普通构建只需 ``-cpp``，不链接 MPI。所有调用端与模块的实数精度必须一致。

   应用程序按以下顺序准备分布式计算：

   1. 初始化 MPI，建立非周期二维 Cartesian 通信器。
   2. 调用 ``sub_J02_initialize_partition``，根据 ``first/count`` 准备本地网格与场。
   3. 初始化带分区的面类型；各进程只设置自己拥有的物理边界。
   4. 对入口面积作全局求和，再按总入口粒子率归一化入流。
   5. 所有进程共同调用 ``sub_J02_solve_transport(..., partition=part)``。
   6. 检查返回码后读取本地场，对入口、出口及体损失粒子率作全局求和。
   7. 应用释放通信器并结束 MPI。

   使用 Open MPI 时，``mpiexec -np N`` 指定空间分区的进程数；
   混合构建中的 ``OMP_NUM_THREADS`` 指定每个进程的线程数。
   不添加 ``-fopenmp`` 时，每个进程内部串行扫描。
   直接启动多个未传入 ``partition`` 的程序，只会重复执行单域计算。

   当前 J03 仍使用单域网格，没有 MPI 通信过程。
   要把分区后的 J02 结果交给现有 J03，应用需先按 ``first/count`` 组装全局单元场与内部面；
   每个 REMOTE 面只取一份，填入对应的全局内部面位置。
   这些面在全局网格中属于内部面，不应填入 J03 的物理开放边界数组。
   当前接口提供组装所需的索引和通量；自动汇集过程及分布式 J03 尚未实现。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``sub_J02_sn_mpi_sweep.f90`` implements partitioned upwind communication and interface-flux reconstruction. Both routines are
   private to the module. Applications call ``sub_J02_sweep`` or ``sub_J02_solve_transport`` with optional ``partition``. Omitting the partition selects
   the single-domain path.

   Continue with blocks A, B, C, and D from the previous page. The cell equation within each block is
   unchanged, but upstream coefficients residing on another rank must be received. The following
   sections cover the data needed, message order, reflection convergence, and final flux.

   .. rubric:: 1. Upstream data exchanged between ranks

   The DG cell equation is :math:`\mathsf A_{K,m}\boldsymbol c_{K,m}=\boldsymbol b_{K,m}`. Each incoming face contributes

   .. math::

      b_{f,a}=s_{f,m}\int_f
          \phi_{a,K}\,\psi^{\mathrm{up}}_m\,r\,\mathrm d\ell,\qquad a=1,2,3.

   Here :math:`s_{f,m}=|\boldsymbol\Omega_m\cdot\boldsymbol n_f|` and :math:`\phi_1=1,\phi_2=\xi,\phi_3=\zeta`. The common azimuthal factor cancels as in the local DG equation. Once the three
   upstream polynomial coefficients are known, the integral is independent of which rank owns the
   upstream cell.

   For example, B receives inflow from A on its left. For :math:`\mu_m>0` the distribution on the shared face from
   A's rightmost cell is

   .. math::

      \psi_m^{\mathrm{up}}(\zeta)=c_{0,L,m}
                               +c_{1,L,m}
                               +c_{2,L,m}\zeta.

   Subscript L denotes A's cell on the left side of the interface. Rank B integrates this face function
   against its test functions to form its right-hand side. Therefore transmit :math:`(c_0,c_1,c_2)`. Transmitting only
   density or :math:`c_0` would lose the linear variation along the face and change the P1 discretization. The
   receiver uses ``sub_J02_add_neighbor_rhs`` to assemble the incoming term, then performs the same 3 × 3 solve and positivity
   treatment as in a single domain.

   .. rubric:: 2. Communication and sweeps by direction quadrant

   For fixed velocity :math:`m`, the signs of :math:`\mu_m` and :math:`\eta_m` select upstream neighbors. When both are positive,
   each block depends on its r-low and z-low neighbors, then sends results to r-high and z-high.

   .. figure:: /_static/J_Fluid/sn_spatial_mpi_english.svg
      :alt: Upwind communication from lower left to upper right across four blocks, with threads handling velocities within each block
      :width: 900px

      Only the group with positive radial and axial components is shown. A has no upstream rank and
      starts first. B and C can proceed simultaneously once they receive A's data; D waits for both.
      Letters denote spatial blocks, independent of MPI rank numbers.

   Particle motion sets the dependency order. A uses its physical inlet or prepared wall inflow, solves
   locally, then sends its right edge to B and upper edge to C. B and C solve and send the upstream
   coefficients needed by D. D then has data on both incoming interfaces.

   There are four sign combinations for the radial and axial cosines. The current code processes :math:`(+,+),(-,+),(+,-),(-,-)` in
   order. All speeds in a group share one process dependency pattern. For group :math:`(-,-)` the wave starts at
   D, proceeds through B and C, and ends at A. Each rank executes these steps for a quadrant:

   1. The main thread receives three spatial coefficients on each upstream edge. No receive is required
      on a physical outer boundary.
   2. Start the shared ``sub_J02_sweep_batch``. OpenMP threads take velocity tasks. Each velocity traverses local cells in
      upwind order.
   3. Wait for all local tasks in the quadrant and pack the two downstream edges on the main thread.
   4. Send coefficients downstream and confirm completion before reusing buffers for the next quadrant.

   For :math:`N_q` velocities in a quadrant:

   - A radial interface has :math:`n_z` cells along z and sends three coefficients per cell and velocity. The
     receive buffer has shape :math:`(3,n_z,N_q)`.
   - An axial interface has :math:`n_r` cells along r and receive shape :math:`(3,n_r,N_q)`.

   In the preceding example with :math:`n_r=4,n_z=3` and 192 velocities, each quadrant contains 48 velocities. The
   radial receive holds 432 reals and the axial receive 576. Buffers contain only neighbor edge
   coefficients, with matching send buffers. Ranks exchange edge data without gathering the full field.
   The nonperiodic rectangular partition gives an acyclic dependency graph. The present implementation
   does not overlap quadrants asynchronously or tile their communication.

   ``sub_J02_mpi_sweep`` takes local mesh, geometry, quadrature, loss, physical boundaries, and the previous distribution
   for reflection. It produces new local coefficients and one error record per velocity. ``MPI_Recv`` receives
   upstream data, ``sub_J02_sweep_batch`` assigns local tasks, ``MPI_Isend`` sends downstream data, and ``MPI_Waitall`` confirms completion before
   buffer reuse. MPI calls occur outside OpenMP worker regions, so ``MPI_THREAD_MULTIPLE`` is unnecessary. With OpenMP
   disabled, the same local task loop executes serially on each MPI rank.

   .. rubric:: 3. Collective convergence of reflection iteration

   If any rank owns a wall or partial inlet, every rank enters the reflection iteration. A global
   logical OR selects this branch so wall-free blocks cannot finish a single sweep and exit early.

   Each rank computes reflection on the wall faces it owns. Because it retains all velocities, specular
   mapping and diffuse normalization are local; one physical face's velocity integral needs no
   cross-rank sum. A REMOTE face uses the upstream coefficients received in the current sweep.

   Global convergence depends on all blocks. Let :math:`\boldsymbol c_p` be rank p's local coefficients. First compute the
   global scale

   .. math::

      S=\max_p\max\!\left(
          |\boldsymbol c_p^{(\ell)}|,\,
          |\boldsymbol c_p^{(\ell+1)}|\right).

   When :math:`S>0` each block computes local sums of absolute values, and then these are summed globally:

   .. math::

      \begin{aligned}
      D&=\sum_p\sum
          \left|\boldsymbol c_p^{(\ell+1)}/S-\boldsymbol c_p^{(\ell)}/S\right|,\\
      B_{\mathrm{old}}&=\sum_p\sum|\boldsymbol c_p^{(\ell)}/S|,\\
      B_{\mathrm{new}}&=\sum_p\sum|\boldsymbol c_p^{(\ell+1)}/S|.
      \end{aligned}

   .. math::

      E_{\ell+1}=\frac{D}{\max(B_{\mathrm{old}},B_{\mathrm{new}})}.

   The inner sums cover local cells, velocities, and all three coefficients. Compute the global old and
   new norms separately, then take the larger; a sum of blockwise maxima would use a different
   denominator. For :math:`S=0` define the change as zero. The code uses ``MPI_Allreduce``: each rank contributes a local value
   and receives the same global result. Reduce one global maximum :math:`S` and three global sums :math:`D,B_{\mathrm{old}},B_{\mathrm{new}}`. All
   ranks calculate the same :math:`E_{\ell+1}` and stop or continue together. Even an unchanged block participates
   because later inflow may arrive from another region.

   Partitioning may change the order of floating-point sums. Compare runs at a tolerance appropriate to
   the real precision; a different partition can change the last rounded digits.

   .. rubric:: 4. Reconstructing flux on partition interfaces

   Upstream communication during the sweep lets downstream cells solve their equations. After
   convergence, a separate operation reconstructs interface flux. ``sub_J02_reconstruct_partition_fluxes`` exchanges final edge coefficients
   so each neighbor holds the cells on both sides of a shared face. For each velocity choose the
   upstream cell by its direction sign and compute the face-averaged distribution :math:`\overline\psi^{\mathrm{up}}` as on the Field
   Reconstruction page. For a radial interface,

   .. math::

      \overline\psi^{\mathrm{up}}_{r,m}=
      \begin{cases}
         c_{0,L,m}+c_{1,L,m},&\mu_m>0,\\
         c_{0,R,m}-c_{1,R,m},&\mu_m<0,
      \end{cases}
      \qquad
      \Gamma_r=\sum_m w_m v_m\mu_m\overline\psi^{\mathrm{up}}_{r,m}.

   L and R denote spatially left and right cells regardless of rank order. On an axial face the average
   retains the radial weighting correction:

   .. math::

      \overline\psi^{\mathrm{up}}_{z,m}=
      \begin{cases}
         c_{0,B,m}+\bar\xi_i c_{1,B,m}+c_{2,B,m},&\eta_m>0,\\
         c_{0,T,m}+\bar\xi_i c_{1,T,m}-c_{2,T,m},&\eta_m<0,
      \end{cases}
      \qquad
      \Gamma_z=\sum_m w_m v_m\eta_m\overline\psi^{\mathrm{up}}_{z,m},
      \qquad
      \bar\xi_i=\frac{h_{r,i}}{3r_{c,i}}.

   B and T denote the bottom and top cells. The same reconstruction applies on local interior faces.
   Both ranks see the same coefficients and sum velocities in the same order, producing the same
   coordinate-directed flux. For instance :math:`\Gamma_r>0` on a radial interface indicates flow from left to right.
   The left block counts outflow :math:`+A_f\Gamma_r` while the right block's outward contribution is :math:`-A_f\Gamma_r`. These cancel in
   the global balance. The stored flux has one coordinate sign; each block applies its own outward sign
   and area.

   Outputs have three distinct storage locations:

   - ``flux_r/flux_z`` holds interior faces with both cells on this block.
   - ``partition_flux(4,nr,nz)`` holds REMOTE flux in :math:`\mathrm{m^{-2}s^{-1}}`. Both sides store a copy; this internal exchange is counted once when
     assembling faces and excluded from external escape.
   - ``inflow_flux/outflow_flux`` holds physical OPEN faces. Both arrays contain zero at REMOTE faces.

   ``sub_J02_sweep`` alone returns the local distribution without reconstructing flux. ``sub_J02_solve_transport`` returns all local fields and
   interface fluxes.

   .. rubric:: 5. Synchronizing and locating errors

   Before upwind communication, synchronize local input checks, compare quadratures and iteration
   options, and check interface coordinates and face types. If a rank fails validation, all ranks
   return together.

   If a cell calculation fails, complete the current communication sequence before collectively
   selecting the failure. Prefer the lowest failed velocity index, then the earliest cell in the
   unpartitioned upwind order for that direction. Returned ``failed_i/failed_k`` are global indices. Errors unrelated to a
   cell retain zero indices. A failed field is unsuitable as a solution.

   This prevents detected numerical errors from leaving ranks waiting for upstream data. It does not
   handle process crashes, network failures, or incorrect use of the communicator by the application.

   .. rubric:: 6. Build, call order, and subsequent continuity solve

   For MPI builds, use an MPI Fortran compiler and define ``-DJ02_USE_MPI``. Hybrid builds also require ``-fopenmp`` at compile
   and link time. Serial builds need only ``-cpp`` and do not link MPI. All callers must match the module's
   real precision.

   Prepare and execute a distributed calculation in this order:

   1. Initialize MPI and create a nonperiodic two-dimensional Cartesian communicator.
   2. Call ``sub_J02_initialize_partition`` and use ``first/count`` to prepare the local mesh and fields.
   3. Initialize partition-aware face types and set only physical boundaries owned by the local rank.
   4. Sum the inlet area globally and normalize the inflow to the total inlet particle rate.
   5. Call ``sub_J02_solve_transport(..., partition=part)`` collectively on all ranks.
   6. Check the return code, read local fields, and globally sum inlet, escape, and volume-loss rates.
   7. Release the communicator and finalize MPI in the application.

   With Open MPI, ``mpiexec -np N`` selects the number of spatial ranks; ``OMP_NUM_THREADS`` selects threads per rank in a hybrid
   build. Without ``-fopenmp``, each rank sweeps serially. Launching multiple processes without passing ``partition``
   duplicates the single-domain calculation.

   J03 currently operates on one domain and has no MPI communication. To pass distributed J02 output to
   J03, use ``first/count`` to assemble global cell fields and interior faces first. For each REMOTE face, take one
   copy and place it in the corresponding global interior-face slot. The J03 physical open-boundary
   arrays exclude these internal faces. The interface provides the indices and fluxes for assembly; it
   does not yet gather the data automatically or implement distributed J03.
