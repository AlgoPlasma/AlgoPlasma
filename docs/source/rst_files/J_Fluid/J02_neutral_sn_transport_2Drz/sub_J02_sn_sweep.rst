.. J_Fluid contribution history (Git author dates; edit times include timezone).
   2026-09-18 12:00 +08:00 | Yingjie Chen | git 69bdc8603906
   2026-10-06 23:50 +08:00 | Yingjie Chen | git fa8cb9f5be05
   2026-10-23 10:58 +08:00 | Yingjie Chen | git cd0d957281af
   2026-11-25 15:14 +08:00 | Yingjie Chen | git 8652258184b5
   2026-11-25 15:59 +08:00 | Yingjie Chen | edit (Codex-assisted)

Upwind Sweep
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J02_sn_sweep.f90`` 用上一页的单元方程计算整个网格上的分布。
   一次扫描中，规定入流和用于反射的上一轮分布保持不变，各离散速度分别求解。
   启用 OpenMP 后，不同离散速度的求解任务分给多个线程；每个离散速度内的单元仍按迎风顺序求解。
   有反射壁面时，外层迭代重复调用这一扫描过程，以更新壁面再入射分布。

   .. rubric:: 1. 迎风顺序与已知数据

   沿离散方向先求上游单元、再用出流值求下游单元的扫描方法，见 :ref:`Carlson 与 Lathrop（1965） <j02-sweep-ref-cl65>` 第 3.6.1 节。
   对离散速度 :math:`m`，信息沿 :math:`\boldsymbol\Omega_m=(\mu_m,\eta_m)` 传播。
   若 :math:`\mu_m>0`，径向从小索引扫向大索引；负值则反向。
   轴向索引由 :math:`\eta_m` 同样决定：

   .. list-table::
      :header-rows: 1
      :widths: 30 35 35

      * - 方向符号
        - 径向顺序
        - 轴向顺序
      * - :math:`\mu_m>0,\eta_m>0`
        - :math:`1\rightarrow N_r`
        - :math:`1\rightarrow N_z`
      * - :math:`\mu_m>0,\eta_m<0`
        - :math:`1\rightarrow N_r`
        - :math:`N_z\rightarrow1`
      * - :math:`\mu_m<0,\eta_m>0`
        - :math:`N_r\rightarrow1`
        - :math:`1\rightarrow N_z`
      * - :math:`\mu_m<0,\eta_m<0`
        - :math:`N_r\rightarrow1`
        - :math:`N_z\rightarrow1`

   当前实现对每个径向索引遍历整条轴向序列，再移动到下一个径向索引。
   这样两类上游邻居都已经在本轮求出。无效单元直接跳过；
   内部面必须指向有效邻居，否则报告拓扑错误。
   当前不支持沿坐标轴的离散速度，即两个方向余弦都必须显著非零。

   .. figure:: ../../../images/J_Fluid/sn_upwind_sweep_en.svg
      :alt: 两种相反速度方向下，中心单元分别读取左下或右上的上游分布
      :width: 900px

      数字表示求解顺序，而非固定的单元编号。左图从左下开始，右图从右上开始；
      两图中的第 5 步都只读取已经完成的第 2、4 步，但这些步骤对应的空间位置不同。
      网格本身没有改变，改变的是当前粒子的运动方向及其上游位置。

   .. rubric:: 2. 一个单元内的组装顺序

   到达有效单元 :math:`K` 后，先令 :math:`\mathsf A=0`、:math:`\boldsymbol b=0`。
   检查四个面的 :math:`\beta_{f,m}`，依次按下表累加：

   .. list-table::
      :header-rows: 1
      :widths: 27 38 35

      * - 当前面与方向
        - 使用的数据
        - 加入的量
      * - 出射面
        - 本单元待求分布
        - 左端 :math:`\mathsf F_f`
      * - 内部入射面
        - 本轮已求出的上游系数
        - 邻居右端 :math:`\boldsymbol b_f^{\mathrm{up}}`
      * - 开放入射面
        - 规定分布函数 :math:`h_m`
        - 常数面右端
      * - 壁面入射
        - 上一轮反射方向系数、由上一轮分布算得的漫反射系数
        - 镜面与漫反射的混合右端
      * - 下端部分入口
        - 开放区间的 :math:`h_m` 与其余壁面区间的反射数据
        - 三段区间积分之和

   然后加入体输运矩阵与损失矩阵，求解

   .. math::

      \left(\mathsf T+\sigma_{K,m}\mathsf H+
                \sum_{\beta_{f,m}>0}\mathsf F_f\right)\boldsymbol c_{K,m}
          =\sum_{\beta_{f,m}<0}\boldsymbol b_f.

   局部求解成功后执行保正检查，将三个系数写入当前场。
   后续单元读取的是这个已完成保正处理的上游结果。

   内部面取本轮数据，壁面取上轮数据，两者不能混淆。
   前者建立单向的空间求解顺序；后者避免不同反射方向在同一轮中相互等待。
   对于没有反射壁的开放问题，不需要上一轮分布，一次完整扫描即可求出当前离散系统。

   .. rubric:: 3. 主过程的必需输入与输出

   ``sub_J02_sweep`` 是公共扫描接口，内部按离散速度调用同一套单元求解过程。

   - 输入 ``mesh``、``geometry``、``quadrature``、``boundary``：
     已初始化的网格、几何、求积和面类型对象。
   - 输入 ``sigma_t(nr,nz,n_dir)``：非负的单位路程损失，
     单位 :math:`\mathrm{m^{-1}}`。
   - 输出并分配 ``psi(3,nr,nz,n_dir)``：当前轮三个空间系数，
     单位 :math:`\mathrm{s^2\,m^{-5}}`；无效单元保持零。
   - 输出 ``ierr``；可选输出 ``failed_direction``、``failed_i``、``failed_k``。
     进入过程时定位值置零；方向或单元内失败时写入相关位置。
     尚未进入单元求解的输入错误可能没有完整的位置。
   - 可选输入 ``progress_interval``：非负整数，零表示不输出进度，
     正值控制每完成多少个速度任务输出一次，首个和最后一个完成任务也会报告。
     扫描开始时报告实际线程数。完成计数不是速度索引，可能包含失败后结束的任务。

   网格、几何、速度求积和内部面邻接关系须由初始化过程正确建立，场数组尺寸遵守接口约定。
   扫描不再复查这些结构；仍检查方向有限性、负损失、入口组合、反射参数和面类型值。
   MPI 扫描另核对各进程的速度离散和交界面一致性。

   .. rubric:: 4. 规定入流的两种表示

   以下二者必须且只能传入一个：

   - ``boundary_inflow(4,nr,nz,n_dir)``：每个单元面各自给定入射分布函数。
     适合多个不同入口；开放出口的入射填零。
   - ``zlo_inflow(n_dir)``：第一排单元下端面共用的入射分布函数。
     其他开放面返回零外部入射。

   二者都不是面通量，单位与 :math:`\psi` 相同。
   若采用下端部分入口，还需同时传
   ``zlo_source_xi_lo(nr)``、``zlo_source_xi_hi(nr)``。
   未提供区间时，OPEN 面按整面开放解释；只传入一半端点会失败。

   .. rubric:: 5. 壁面相关可选输入

   只要有效单元存在 WALL 面，或传入部分入口区间，就启用壁面处理：

   - ``psi_old(3,nr,nz,n_dir)``：上一轮分布，必须提供。
     它只用于壁面入流，不用作内部面上游数据。
   - ``diffuse_fraction``：全局漫反射比例 :math:`d\in[0,1]`，
     省略时取零，即纯镜面。
   - ``wall_shape(n_dir)``：尚未归一化的非负壁面速度分布。
     当 :math:`d>0` 时必须提供；纯镜面不需要热运动分布。
   - 漫反射系数在该轮扫描开始前由上一轮分布计算，
     在该轮各方向计算期间保持不变。

   本接口一次只执行一轮；直接调用时，需要保存上一轮分布并自行判断收敛。
   通常可调用 ``sub_J02_solve_transport``，由其内部的反射迭代过程完成这些工作。

   .. rubric:: 6. 文件内部过程的具体职责

   ``sub_J02_sweep_batch`` 将一组离散速度的求解分给线程。

   - 输入 ``nodes(:)``：本批要计算的离散速度索引，以及已经验证的网格、边界、损失和反射数据。
     无 MPI 分区时，一批包含全部速度；MPI 分区时，一批包含当前象限内的速度。
   - 对每个索引 :math:`m` 调用 ``sub_J02_sweep_velocity``。
     串行版本依次调用；OpenMP 版本使用静态分配，让不同线程计算不同索引。
   - 结果写入 ``psi(:,:,:,m)``，错误写入对应索引的状态数组。
     所有线程完成后再返回，因此下一轮反射迭代不会读取尚未计算完的分布。


   ``sub_J02_sweep_velocity`` 是同一文件中的私有过程，负责一个离散速度上的扫描。
   串行和 OpenMP 版本都通过它完成单元计算。

   - 输入 ``mesh,geometry,quadrature,boundary``、速度索引 ``m``，
     该速度的 ``sigma(nr,nz)``，以及混合比例、规定入流和本轮固定的壁面数据。
   - 输出 ``psi_direction(3,nr,nz)``，它直接关联到总场的
     ``psi(:,:,:,m)`` 切片，不额外复制一个全速度场。
   - 输出本方向的 ``ierr,failed_i,failed_k``。
     索引、局部矩阵、右端及系数都属于当前调用，其他线程不会读写它们。
   - 该过程只接受公开扫描接口已经验证过的数据。
     没有 OpenMP 时，公开接口仍按速度索引顺序调用同一个过程。

   下列辅助过程位于这个私有单方向过程内部，读取的是当前调用自身的单元和矩阵：

   ``add_face``：

   - 输入 ``face_id``、``outward_dot``、``neighbor_i/neighbor_k``。
   - ``outward_dot`` 对应 :math:`\beta_{f,m}`；
     出射时累加本单元的面矩阵，入射时按面类型选择邻居、规定值或反射数据。
   - 修改外层 ``a`` 或 ``rhs``；异常类型可设置外层 ``ierr``。
     部分下端 OPEN 面在此分成入口区间和两段壁面补集。

   ``add_zlo_complement_coeff``：

   - 输入 ``s``、``coefficient(3)``，输入输出 ``vector(3)``。
   - 在 :math:`[-1,\xi_L]` 和 :math:`[\xi_H,1]`
     对同一反射方向多项式积分，把两段镜面贡献累加到向量。

   ``add_zlo_complement_constant``：

   - 输入 ``s``、``value``，输入输出 ``vector(3)``。
   - 在相同两段补集积分常数分布函数，供漫反射使用。

   ``fun_boundary_value``：

   - 输入面编号、单元索引和离散速度索引；返回规定入射分布函数。
   - 优先读取完整边界数组；使用 ``zlo_inflow`` 时，只在第一排下端返回对应值，
     其余位置返回零。

   .. rubric:: 7. 并行阶段的数据依赖与同步

   假设当前有 192 个离散速度。固定壁面入流后，第 1 个速度的空间方程
   不需要第 2 个速度正在计算的分布；二者只读取相同的网格和已准备好的边界数据。
   因此可以由不同线程同时求解，这就是本模块 OpenMP 并行的依据。

   但对同一个离散速度，当前单元需要上游单元的新结果，因此按图示的迎风顺序逐单元求解。

   不传空间分区时，OpenMP 分配全部离散速度索引 :math:`m`，使用静态任务分配。
   传入可选 ``partition`` 时，MPI 先交换本块上游系数，再按方向象限调用同一个线程循环；
   每个离散速度在本块内部仍保持迎风单元顺序。
   分区接口与空间通信分别在 13、14 页展开，本页的单元组装公式不变。

   .. list-table::
      :header-rows: 1
      :widths: 30 36 34

      * - 数据
        - 线程访问方式
        - 依据
      * - 网格、几何、求积、入口与损失
        - 所有线程只读
        - 一轮扫描中保持不变
      * - 上一轮分布与漫反射系数
        - 所有线程只读
        - 壁面入流在扫描前准备好
      * - 新场 ``psi(:,:,:,m)``
        - 仅当前速度任务写入
        - 各离散速度不读取其他离散速度正在计算的结果
      * - 单元矩阵、右端与当前单元索引
        - 每个调用独有
        - 避免多个线程覆盖临时数据
      * - 错误状态与失败单元
        - 每个离散速度独占一个记录
        - 全部任务结束后选择首个失败
      * - 进度计数与终端输出
        - 在临界区内逐个更新
        - 防止计数竞争和日志交错

   并行循环结束处等待全部线程完成，再检查每个离散速度的状态。
   若多个离散速度失败，总是报告编号最小的失败速度索引；
   不会因为某个线程更快而改变诊断位置。
   出错时其他离散速度可能已经计算完毕，返回的场仍不应作为有效结果使用。

   线程并行没有改变每个离散速度的单元求解次序。本块的壁面归一化与重构求和仍按固定顺序执行。
   MPI 分区还需要对收敛量作全局归约，求和顺序可能随分区改变，不能要求跨分区逐位相同。
   线程数很多不等于必然更快：小网格的线程调度开销、共享内存带宽和串行阶段都会限制加速。

   .. rubric:: 8. 扫描结束后的数据

   返回成功表示本轮所有速度、所有有效单元均已求解。
   有反射时，这不意味着壁面条件已自洽；必须继续下一页的反射迭代。
   失败时，已经分配的场可能只包含部分计算结果，不应拿它继续重构或报告为稳态解。

   .. rubric:: 9. 可选的空间分区输入

   ``partition`` 是由 ``sub_J02_initialize_partition`` 建立的只读分区对象。
   传入它时，所有数组均为本进程负责的单元数据，求积仍含全部离散速度，
   所有进程必须共同调用扫描。失败单元索引返回全局位置，不再是本地位置。
   不传该参数时不进行 MPI 通信，失败索引仍对应整个传入网格。

   .. rubric:: 参考文献

   .. _j02-sweep-ref-cl65:

   B. G. Carlson and K. D. Lathrop (1965).
   *Transport Theory: The Method of Discrete Ordinates*.
   Los Alamos Scientific Laboratory, LA-3251-MS.
   `报告全文 <https://mcnp.lanl.gov/pdf_files/TechReport_1965_LANL_LA-3251-MS_CarlsonLathrop.pdf>`__

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``sub_J02_sn_sweep.f90`` uses the local equation from the preceding page to compute the distribution over the mesh. Within
   a sweep, prescribed inflow and the previous distribution used for reflection stay fixed, so discrete
   velocities can be solved independently. OpenMP assigns velocities to threads while retaining upwind
   cell order for each velocity. With reflecting walls, the outer iteration repeats the sweep to update
   returning particles.

   .. rubric:: 1. Upwind order and available data

   For the directional sweep from upstream cells to their downstream neighbors, see :ref:`Carlson and Lathrop (1965) <j02-sweep-ref-cl65-en>`, Section 3.6.1.
   At discrete velocity :math:`m`, information propagates along :math:`\boldsymbol\Omega_m=(\mu_m,\eta_m)`. For :math:`\mu_m>0`, radial indices increase; for a
   negative radial cosine, they decrease. The sign of :math:`\eta_m` similarly sets the axial order.

   .. list-table::
      :header-rows: 1
      :widths: 30 35 35

      * - Direction signs
        - Radial order
        - Axial order
      * - :math:`\mu_m>0,\eta_m>0`
        - :math:`1\rightarrow N_r`
        - :math:`1\rightarrow N_z`
      * - :math:`\mu_m>0,\eta_m<0`
        - :math:`1\rightarrow N_r`
        - :math:`N_z\rightarrow1`
      * - :math:`\mu_m<0,\eta_m>0`
        - :math:`N_r\rightarrow1`
        - :math:`1\rightarrow N_z`
      * - :math:`\mu_m<0,\eta_m<0`
        - :math:`N_r\rightarrow1`
        - :math:`N_z\rightarrow1`

   For each radial index, the implementation traverses the entire axial sequence before advancing
   radially. Both kinds of upstream neighbors have then been solved in the current sweep. Inactive
   cells are skipped. An interior face must touch an active neighbor or the topology is invalid.
   Axis-aligned velocities are unsupported: both direction cosines must be appreciably different from
   zero.

   .. figure:: ../../../images/J_Fluid/sn_upwind_sweep_en.svg
      :alt: For two opposite velocities the center cell reads upstream data from the lower left or the upper right
      :width: 900px

      The numbers show solution order. The left sweep starts at the lower left, the right sweep at the
      upper right. In both, step 5 reads only completed steps 2 and 4, but those steps occupy different
      physical cells. Reversing the particle direction changes the upstream neighbors on the same mesh.

   .. rubric:: 2. Assembly order within a cell

   For each active cell :math:`K`, initialize :math:`\mathsf A=0` and :math:`\boldsymbol b=0`. Inspect :math:`\beta_{f,m}` on the four faces and accumulate the
   following terms.

   .. list-table::
      :header-rows: 1
      :widths: 27 38 35

      * - Face and direction
        - Data used
        - Contribution
      * - Outgoing face
        - Unknown distribution in this cell
        - Left-hand :math:`\mathsf F_f`
      * - Incoming interior face
        - Upstream coefficients from this sweep
        - Neighbor contribution :math:`\boldsymbol b_f^{\mathrm{up}}` on the right
      * - Incoming open face
        - Prescribed distribution :math:`h_m`
        - Constant face contribution on the right
      * - Incoming wall face
        - Previous reflected-direction coefficients and diffuse coefficient computed from the previous
          distribution
        - Mixed specular and diffuse contributions on the right
      * - Partial inlet on the lower boundary
        - :math:`h_m` on the open interval and reflection data on the remaining wall intervals
        - Sum of three interval integrals

   Then add the volume transport and loss matrices and solve

   .. math::

      \left(\mathsf T+\sigma_{K,m}\mathsf H+
                \sum_{\beta_{f,m}>0}\mathsf F_f\right)\boldsymbol c_{K,m}
          =\sum_{\beta_{f,m}<0}\boldsymbol b_f.

   After a successful local solve, enforce positivity and write the three coefficients to the current
   field. Downstream cells read these corrected coefficients.

   Interior faces read current-sweep data to establish a one-way spatial dependency. Wall faces read
   the previous iteration so reflected directions need not wait on each other within a sweep. An open
   problem with no reflecting walls needs no old distribution: one full sweep solves the discrete
   system.

   .. rubric:: 3. Required inputs and outputs

   ``sub_J02_sweep`` is the public sweep interface. It uses the same cell-solution procedure for every discrete
   velocity.

   - Inputs ``mesh``, ``geometry``, ``quadrature``, and ``boundary`` are the initialized mesh, geometry, quadrature, and face types.
   - Input ``sigma_t(nr,nz,n_dir)`` is a nonnegative loss per unit path length, in :math:`\mathrm{m^{-1}}`.
   - The routine allocates output ``psi(3,nr,nz,n_dir)`` for the three spatial coefficients of the current sweep, in :math:`\mathrm{s^2\,m^{-5}}`.
     Inactive cells remain zero.
   - It returns ``ierr`` and optional outputs ``failed_direction``, ``failed_i``, and ``failed_k``. Location fields start at zero and identify the
     direction or cell of a failure when available. An input failure before the cell solve may have no
     complete location.
   - Optional input ``progress_interval`` is a nonnegative integer. Zero disables progress reports. A positive value
     specifies the interval in completed velocity tasks, with the first and last also reported. The
     sweep reports the actual thread count at startup. The completion count is independent of the
     velocity index and may include tasks that ended in failure.

   Initialization must produce a consistent mesh, geometry, velocity quadrature, and interior
   adjacency. Field shapes must follow the interface. The sweep relies on these structures and checks
   direction finiteness, negative loss, inlet argument combinations, reflection parameters, and
   face-type values. MPI also checks velocity discretizations and partition interfaces across ranks.

   .. rubric:: 4. Two ways to prescribe inflow

   Pass exactly one of these inputs:

   - ``boundary_inflow(4,nr,nz,n_dir)`` supplies a distribution for every cell face. Use it for distinct inlets and zero the incoming
     distribution on open outlets.
   - ``zlo_inflow(n_dir)`` supplies the incoming distribution shared by the lower faces of the first row. External inflow
     on other open faces is zero.

   Both contain distributions in the same units as :math:`\psi`. A partial lower inlet requires both ``zlo_source_xi_lo(nr)`` and ``zlo_source_xi_hi(nr)``.
   Without intervals, OPEN denotes a fully open face. Passing just one endpoint array is an error.

   .. rubric:: 5. Optional wall inputs

   Wall processing is active if an active cell has a WALL face or partial-inlet intervals are supplied:

   - ``psi_old(3,nr,nz,n_dir)`` is the required previous distribution. It supplies the incoming wall data. Interior faces still
     use current upstream data.
   - ``diffuse_fraction`` specifies the global diffuse fraction :math:`d\in[0,1]`. The default is zero for purely specular reflection.
   - ``wall_shape(n_dir)`` is the nonnegative unnormalized wall velocity distribution. Supply it when :math:`d>0`. Pure specular
     reflection requires no thermal distribution.
   - Diffuse coefficients come from the previous distribution before the sweep starts and remain fixed
     while all directions are solved.

   One call executes one sweep. A caller driving iteration directly saves the previous distribution and
   checks convergence. Normally ``sub_J02_solve_transport`` handles both through its reflection iteration.

   .. rubric:: 6. Responsibilities of the internal procedures

   ``sub_J02_sweep_batch`` assigns a batch of discrete velocities to threads.

   - Input ``nodes(:)`` lists the velocity indices in the batch. The procedure also receives validated mesh,
     boundary, loss, and reflection data. A serial domain uses one batch for all velocities. In MPI, a
     batch contains the current quadrant.
   - For every index :math:`m` call ``sub_J02_sweep_velocity``. The serial version processes indices in order. The OpenMP version uses
     static scheduling across indices.
   - Results go into ``psi(:,:,:,m)`` and failures into the status array for that index. The batch returns after all
     threads finish, so the next reflection iteration reads a complete field.

   ``sub_J02_sweep_velocity`` is the file's private single-velocity sweep. Both serial and OpenMP execution use it for the cell
   calculations.

   - Inputs are ``mesh,geometry,quadrature,boundary``, velocity index ``m``, the direction's ``sigma(nr,nz)``, the mixing fraction, prescribed inflow, and
     wall data fixed for this sweep.
   - Output ``psi_direction(3,nr,nz)`` aliases slice ``psi(:,:,:,m)`` of the full field. No extra copy of the full velocity field is made.
   - The routine returns this direction's ``ierr,failed_i,failed_k``. Indices, local matrix, right-hand side, and coefficients
     belong to the current call and are private to the executing thread.
   - This procedure assumes that the public interface has validated its inputs. Without OpenMP, the
     public interface calls it in velocity-index order.

   The following helpers are internal to the single-direction procedure and operate on the cell and
   matrix of the current call.

   ``add_face``:

   - Inputs are ``face_id``, ``outward_dot``, and ``neighbor_i/neighbor_k``.
   - ``outward_dot`` denotes :math:`\beta_{f,m}`. For outflow, add the cell's face matrix. For inflow, select the neighbor,
     prescribed value, or reflected data according to face type.
   - Updates the enclosing ``a`` or ``rhs`` and may set ``ierr`` for an invalid type. A partial lower OPEN face is
     split into an inlet interval and two complementary wall intervals.

   ``add_zlo_complement_coeff``:

   - Inputs are ``s`` and ``coefficient(3)``, with ``vector(3)`` on input and output.
   - Integrates the same reflected-direction polynomial over :math:`[-1,\xi_L]` and :math:`[\xi_H,1]` and adds both specular
     contributions to the vector.

   ``add_zlo_complement_constant``:

   - Inputs are ``s`` and ``value``, with ``vector(3)`` on input and output.
   - Integrates a constant distribution over the same two complementary intervals for diffuse
     reflection.

   ``fun_boundary_value``:

   - Takes a face index, cell indices, and velocity index. Returns the prescribed incoming
     distribution.
   - Uses the full boundary array when present. With ``zlo_inflow`` it returns the corresponding value only on the
     lower face of the first row and zero elsewhere.

   .. rubric:: 7. Dependencies and synchronization in parallel execution

   Consider 192 discrete velocities. Once incoming wall data are fixed, the spatial equation for the
   first velocity is independent of the solution being computed for the second. Both read the same mesh
   and prepared boundary data. Different threads can therefore solve them concurrently.

   For a single velocity, each cell requires the new result from its upstream neighbor, so its cells
   are solved one at a time in the illustrated upwind order.

   Without partitioning, OpenMP statically schedules all velocity indices :math:`m`. With optional ``partition``, MPI
   exchanges upstream coefficients and invokes the same threaded loop by quadrant. Each velocity
   retains the upwind order within the local block. Pages 13 and 14 describe the partition interface
   and communication. The same local assembly equations apply.

   .. list-table::
      :header-rows: 1
      :widths: 30 36 34

      * - Data
        - Thread access
        - Reason
      * - Mesh, geometry, quadrature, inlet, and loss
        - Read-only for all threads
        - Fixed throughout a sweep
      * - Previous distribution and diffuse coefficients
        - Read-only for all threads
        - Incoming wall data are prepared before sweeping
      * - New field ``psi(:,:,:,m)``
        - Written only by the task for this velocity
        - No direction reads another direction's current result
      * - Cell matrix, right-hand side, and current indices
        - Private to each call
        - Temporary values are isolated between threads
      * - Error status and failed cell
        - One record per discrete velocity
        - The first failing index is selected after all tasks finish
      * - Progress count and terminal output
        - Updated serially in a critical region
        - Prevents count races and interleaved messages

   The parallel loop waits for all threads before inspecting status by velocity. If several fail, the
   smallest failed velocity index is reported regardless of completion order. Other directions may have
   completed, but a field returned after an error cannot be used as a valid result.

   Threading preserves the cell order for each velocity. Wall normalization and reconstruction sums
   within a block retain their fixed order. MPI convergence reductions can add terms in a different
   order for different partitions, so cross-partition results need not agree bit for bit. Small meshes,
   shared-memory bandwidth, and serial stages can limit the speedup with many threads.

   .. rubric:: 8. Data available after the sweep

   Success means all velocities and active cells were solved for this sweep. For reflecting walls,
   continue the reflection iteration on the next page to obtain self-consistent wall conditions. After
   failure, the allocated field may be incomplete and is unsuitable for reconstruction or reporting as
   a steady solution.

   .. rubric:: 9. Optional spatial partition

   ``partition`` is a read-only partition created by ``sub_J02_initialize_partition``. With it, cell arrays describe this rank's block, the
   quadrature still contains all velocities, and all ranks call the sweep collectively. Failure
   locations use global cell indices. Without it, no MPI communication occurs and failed indices refer
   to the entire supplied mesh.

   .. rubric:: References

   .. _j02-sweep-ref-cl65-en:

   Carlson, B. G., and K. D. Lathrop (1965). *Transport Theory: The Method of Discrete Ordinates*. Los
   Alamos Scientific Laboratory, LA-3251-MS. `Full report <https://mcnp.lanl.gov/pdf_files/TechReport_1965_LANL_LA-3251-MS_CarlsonLathrop.pdf>`__
