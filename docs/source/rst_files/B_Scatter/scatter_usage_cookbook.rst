======================
Scatter Usage Cookbook
======================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 这页解决什么问题

   本页面面向 **已经把 B_Scatter 模块编译进自己代码**、要在 PIC 循环里调用沉积算子
   的开发者。它说明怎么选模块、调用方需要负责什么、最小时间步循环长什么样、
   OMP / 并行场景的注意事项，以及常见集成错误。不重复
   :doc:`Learning Path <scatter_learning_path>` 里的理论，
   也不替代每个 routine 自己的 API 页。

   .. rubric:: 先选哪个模块

   .. list-table::
      :header-rows: 1
      :widths: 14 22 22 42

      * - 模块 / 子程序
        - 坐标
        - 沉积量
        - 何时选它
      * - ``sub_B01_scatter_3Dxyz``
        - Cartesian ``(x,y,z)``
        - 标量密度 ``den``
        - 默认选择：3D Cartesian PIC，需要节点密度做 Poisson 求解或电流沉积。
      * - ``sub_B01_scatter_3Dxyz_v``
        - Cartesian ``(x,y,z)``
        - 速度矩 ``den_v``
        - 需要节点上的速度分量 ``<v_d>`` 时调用，``d=4/5/6`` 对应 ``v_x/v_y/v_z``。
          流体诊断、Vlasov 矩闭合都走这条。
      * - ``sub_B01_scatter_3Dxyz_T``
        - Cartesian ``(x,y,z)``
        - 温度（方差） ``den_T``
        - 需要节点上的方差/温度时调用；用最近格子法，不是 CIC。
      * - :doc:`B02 <B02_deposit_3d_cyl>`
        - 柱坐标 ``(r,\phi,z)``
        - ``rho`` + ``J_r, J_\phi, J_z``
        - 几何天然柱对称（圆柱腔、聚焦束流、等离子柱）；需要 charge 和 current
          deposition 一起做。

   选型判据：

   - 先按 **几何** 确定 Cartesian (B01) 还是 cylindrical (B02)。
   - 在 Cartesian 内，按 **需要的物理量** 选择 ``B01`` / ``_v`` / ``_T``。
     三个互不冲突，可以在同一时间步里依次调用。
   - 当前没有"相对论 scatter"——所有 routine 都假设宏粒子权重是经典质量/电荷。
     高 ``\gamma`` 工况下电流沉积要在调用方侧把 ``v`` 换成 ``\gamma v`` 后再传入。

   .. rubric:: 调用方必须负责的事情

   scatter routine 是无状态的；它 **只** 做一次累加。下面这些都必须由调用方组织：

   1. **粒子数组布局**。所有 B_Scatter routine 都要求
      ``par(1:3, 1:np)`` 是位置（``B01``）或
      ``par(1:6, 1:np)`` 包含位置+速度（``B01 _v / _T`` 需要 ``v`` 分量）。
      **传入维度必须严格匹配子程序声明**，否则会 stride 错位（见
      :doc:`Learning Path <scatter_learning_path>` 里的 "20 单位质量堆 (0,0,0)" 案例）。
   2. **网格初始化**。目标数组为 ``den``；``den = 0`` 必须 **显式** 完成。routine 采用
      **累加** 方式，
      不是覆盖式；第二次调用会叠加在第一次的结果上。
   3. **粒子权重** ``w``。多数 routine 把 ``w`` 当作整体缩放因子在循环结束后乘上；
      ``B02`` 里粒子权重直接进沉积公式。请按各 API 页的约定填。
   4. **Ghost cell / 边界**。``den`` 至少要分配 ``(il-1:iu+1, ...)`` 范围以容纳
      落在域边的粒子的 CIC 权重外溢；调用方在 routine 之后再处理 ghost cell
      的同步或周期 wrap。
   5. **粒子是否在域内**。落在 ``[il-1, iu+1]`` 之外的粒子由调用方在 scatter
      之前处理（注入、反射、删除等），scatter routine 自己不检查。
   6. **柱坐标的体积归一化**。``B02`` 沉积出的 ``rho`` 是 "charge per cell"
      而非物理电荷密度；要除以 ``r \Delta r \Delta\phi \Delta z`` 得到密度，
      或在场求解器里直接处理"按 cell 体积积过的源项"。

   .. rubric:: 编译和精度

   - 默认编译命令（跟测试目录里一致）：

     .. code-block:: bash

        gfortran -cpp -O3 -fdefault-real-8 -fopenmp main.f90

   - ``-fdefault-real-8`` 把所有 ``real`` 提升到 8 字节。强烈建议在生产代码里
     开这个：CIC 权重的累加在 ``np`` 大时会受单精度误差影响，
     ``sum(den) = sum(w_p)`` 守恒可能就保不住。
   - ``-fopenmp`` 是必须的：上游 ``!$omp parallel`` 没有 fallback；
     如果用 ``ifort`` 改成 ``-qopenmp``。
   - 没有外部依赖，不需要链接 BLAS / FFTW / MPI。

   .. rubric:: 最小时间步结构

   伪代码骨架，针对一次完整的密度沉积：

   .. code-block:: text

      ! 一次时间步内的 scatter
      apply_boundary_or_inject(par, np)              ! 出域粒子和注入由调用方处理
      den = 0.0                                      ! 必须先清零

      call sub_B01_scatter_3Dxyz(il, iu, den, np, par, w)   ! 累加

      ! 可选：同步 ghost cell（MPI 跨域）
      call exchange_ghost_cells(den)

      ! 可选：同步 velocity moment / temperature
      den_v = 0.0
      call sub_B01_scatter_3Dxyz_v(il, iu, den_v, np, par, w, d=4)
      ! den_T 无需清零，子程序内部自行归零
      call sub_B01_scatter_3Dxyz_T(il, iu, den_T, np, par, w, d=4)

      ! 后续：场求解、诊断
      call poisson_solve(den, phi)

   一些注释：

   - 真实代码会按 ``np`` 数组 **直接** 传入，不需要按粒子写循环；上游已经内部
     并行。
   - ``apply_boundary_or_inject`` 是用户代码，本页不展开。
   - ``exchange_ghost_cells`` 是 ``H_MPI_Exchange`` 模块；在单进程跑测试时
     可省略。
   - 多次调用 ``_v`` 需要每次都清零对应的目标数组；``_T`` 由子程序内部清零，调用方无需操作。

   .. rubric:: OMP 和并行考虑

   上游 ``sub_B01_scatter_3Dxyz`` 的 OMP 设计是：

   .. code-block:: fortran

      !$omp parallel default(firstprivate) reduction(+:den)
      !$omp do
      do p = 1, np
          ... CIC accumulation ...
      end do
      !$omp end do
      !$omp end parallel

   两个隐藏代价：

   1. **OpenMP 的** ``default(firstprivate)`` **会把** ``par`` **拷到每个线程的栈**。
      ``par`` 维度是
      ``3 × np``，``np = 1e7`` 时每线程占 ~240 MB。64 线程 = 15 GB 拷贝，
      系统栈 8 MB 直接溢出。因此 **测试目录的 run 脚本已设置所需栈参数**：
      ``ulimit -s unlimited`` 和 ``OMP_STACKSIZE=1G``。集成到生产代码时
      要同样设置，否则 ``np`` 一上去就崩。
   2. **OpenMP 的** ``reduction(+:den)`` **在循环结束时做归约**。每个线程私有的 ``den``
      在循环结束累加到主 ``den``。线程数高时归约开销不小，但相比 ``par``
      拷贝是次要的。

   实测数据（见 :doc:`B01 鲲鹏对比 </tests/kunpeng_compare/B01_scatter_3Dxyz_omp>`）：

   - 小 ``np`` (1e4)：OMP 开销主导，2-4 线程是最优档位，再加线程负扩展。
   - 大 ``np`` (1e7)：``firstprivate`` 拷贝主导，64 线程比 1 线程慢
     37 倍（在 AMD服务器上），鲲鹏好一些但也只能做到 2.6 倍慢。
   - 任何 ``np``：实测加速比不会超过 ~3×，远低于线性。

   换句话说，当前 kernel 不适合高 OMP 并行。
   生产代码里集成时的可行折中：

   - 把线程数控制在 4-8 档位附近。
   - 真要做高并行，绕开上游 routine，自己实现 ``default(shared)`` + atomic
     add 或 per-thread local accumulation 后手动合并的版本。这超出了本页范围。

   .. rubric:: 常见集成错误

   - ``par`` **维度不匹配子程序声明**。调用方分配 ``par(1:6, 1:np_max)``，
     直接传给只接收 ``par(1:3, 1:np)`` 的 routine——Fortran 按 stride 3
     重解释，每隔一列读到的是速度槽（0），位置严重错位。**这是上线前必须查的 bug**。
   - ``den`` **没清零**。多步 PIC 循环里前一步的 ``den`` 残留累加到这一步。
   - **没分配 guard cell**。``den(il:iu, ...)`` 不留外延一圈，落在域边的粒子的
     CIC 权重写到边界外、触发段错误或 silent corruption。正确分配是
     ``den(il-1:iu+1, ...)``。
   - **B02 把"per cell" 当成 "density"**。``B02`` 直接输出"格内积分量"，
     不是物理密度。后续 Poisson 求解时要约定是用积分量还是密度。
   - **栈大小没调**。``ulimit -s`` 默认 8 MB，``OMP_STACKSIZE`` 默认 ~4 MB。
     ``np = 1e7`` 配 ``firstprivate`` 会直接段错误。修复见上面 OMP 节。
   - **温度沉积期望 CIC 守恒**。``sub_..._T`` 是最近格子法，不能套
     ``sum(den_T) = sum(w*v^2)``。它给出节点级方差，不是"二阶矩"。

.. container:: ap-lang ap-lang-en

   .. rubric:: What This Page Is For

   This page targets developers who have already built ``B_Scatter`` into
   their own code and need to call the scatter operators inside a PIC loop.
   It covers how to choose a module, what the caller owns, the minimal
   time-step shape, OMP / parallel considerations, and common integration
   mistakes. It does not repeat the theory from
   :doc:`Learning Path <scatter_learning_path>` and does not replace each
   routine's API page.

   .. rubric:: Choose the Module First

   .. list-table::
      :header-rows: 1
      :widths: 14 22 22 42

      * - Module / subroutine
        - Coordinates
        - Deposited quantity
        - When to pick it
      * - ``sub_B01_scatter_3Dxyz``
        - Cartesian ``(x,y,z)``
        - Scalar density ``den``
        - Default: 3D Cartesian PIC needing node density for Poisson or
          current deposition.
      * - ``sub_B01_scatter_3Dxyz_v``
        - Cartesian ``(x,y,z)``
        - Velocity moment ``den_v``
        - When you need a node-level velocity component ``<v_d>``, with
          ``d=4/5/6`` for ``v_x/v_y/v_z``. Fluid diagnostics and Vlasov
          moment closures call this.
      * - ``sub_B01_scatter_3Dxyz_T``
        - Cartesian ``(x,y,z)``
        - Temperature / variance ``den_T``
        - When you need node-level variance / temperature. Uses
          nearest-cell, not CIC.
      * - :doc:`B02 <B02_deposit_3d_cyl>`
        - Cylindrical ``(r,\phi,z)``
        - ``rho`` and ``J_r, J_\phi, J_z``
        - Naturally cylindrical geometry (cavities, focused beams, plasma
          columns) where charge and current deposition are done together.

   Selection rules of thumb:

   - First choose Cartesian (B01) vs cylindrical (B02) by **geometry**.
   - Inside Cartesian, choose ``B01`` / ``_v`` / ``_T`` by the **physical
     quantity** you need. The three are independent and can be called in
     sequence within the same time step.
   - There is no "relativistic scatter" yet — every routine assumes
     classical macro-particle mass / charge. At high ``\gamma`` the caller
     must replace ``v`` with ``\gamma v`` before passing it to ``_v``.

   .. rubric:: What the Caller Owns

   The scatter routines are stateless; they **only** accumulate. The
   caller owns:

   1. **Particle array layout.** Every B_Scatter routine wants
      ``par(1:3, 1:np)`` for position-only (``B01``) or
      ``par(1:6, 1:np)`` including velocity (``B01 _v / _T``). The shape
      **must match the subroutine declaration exactly**, or Fortran
      reinterprets the memory by the wrong stride (see the "20 units of
      mass at ``(0,0,0)``" case in :doc:`Learning Path <scatter_learning_path>`).
   2. **Initialising the grid array** ``den``. ``den = 0`` must be done **explicitly**.
      The routine accumulates, not overwrites; a second call adds on top
      of the first.
   3. **Particle weight** ``w``. Most routines apply ``w`` as a global
      scale after the loop; ``B02`` mixes ``w`` into the deposition
      formula directly. Follow each API page's convention.
   4. **Ghost cells / boundaries.** ``den`` should be allocated at least
      ``(il-1:iu+1, ...)`` to absorb the CIC overflow from particles at
      the domain edge; the caller synchronises ghost cells (or applies
      periodic wrap) after the call.
   5. **Out-of-domain particles.** Particles outside ``[il-1, iu+1]`` are
      not checked. The caller handles injection / reflection / deletion
      before scatter.
   6. **Cylindrical volume normalisation.** ``B02`` produces "charge per
      cell", not physical charge density. Divide by
      ``r \Delta r \Delta\phi \Delta z`` to recover density, or arrange
      the field solver to consume the cell-integrated source directly.

   .. rubric:: Compilation and Precision

   - Default command line (matches the test directories):

     .. code-block:: bash

        gfortran -cpp -O3 -fdefault-real-8 -fopenmp main.f90

   - ``-fdefault-real-8`` promotes every ``real`` to 8 bytes. **Strongly
     recommended** in production: the CIC accumulation loses
     ``sum(den) = sum(w_p)`` conservation under single-precision rounding
     once ``np`` is large.
   - ``-fopenmp`` is required: the upstream ``!$omp parallel`` has no
     fallback. Use ``-qopenmp`` if you compile with ``ifort``.
   - No external dependencies — no BLAS, FFTW, or MPI required.

   .. rubric:: Minimal Time-Step Structure

   Pseudo-code skeleton for one full density deposition:

   .. code-block:: text

      ! Scatter inside one time step
      apply_boundary_or_inject(par, np)              ! out-of-domain / injection is caller-side
      den = 0.0                                      ! must zero first

      call sub_B01_scatter_3Dxyz(il, iu, den, np, par, w)   ! accumulate

      ! Optional: synchronise ghost cells across MPI domains
      call exchange_ghost_cells(den)

      ! Optional: velocity moment / temperature
      den_v = 0.0
      call sub_B01_scatter_3Dxyz_v(il, iu, den_v, np, par, w, d=4)
      ! den_T needs no pre-zeroing; the subroutine zeroes it internally
      call sub_B01_scatter_3Dxyz_T(il, iu, den_T, np, par, w, d=4)

      ! Downstream: field solve, diagnostics
      call poisson_solve(den, phi)

   Notes:

   - Production code passes ``par`` straight in by ``np`` — no per-particle
     loop; the upstream routine parallelises internally.
   - ``apply_boundary_or_inject`` is user code; not expanded here.
   - ``exchange_ghost_cells`` is the ``H_MPI_Exchange`` module; can be
     skipped in single-process test runs.
   - Each ``_v`` call needs its own zero-initialised target array.
     ``_T`` is zeroed internally by the subroutine; no pre-zeroing is
     required from the caller.

   .. rubric:: OMP and Parallel Considerations

   The upstream ``sub_B01_scatter_3Dxyz`` uses:

   .. code-block:: fortran

      !$omp parallel default(firstprivate) reduction(+:den)
      !$omp do
      do p = 1, np
          ... CIC accumulation ...
      end do
      !$omp end do
      !$omp end parallel

   Two hidden costs:

   1. **OpenMP** ``default(firstprivate)`` **copies** ``par`` **to every thread stack.**
      ``par`` is ``3 × np`` reals; at ``np = 1e7`` each thread takes
      ~240 MB. 64 threads = 15 GB of copies, and the default 8 MB OS stack
      overflows immediately. The test directories' run scripts set
      ``ulimit -s unlimited`` and ``OMP_STACKSIZE=1G`` for exactly this
      reason — production code must do the same or it will crash as soon
      as ``np`` is non-trivial.
   2. **OpenMP** ``reduction(+:den)`` **does a final merge.** Each thread's private
      ``den`` is summed into the shared one at loop exit. The merge cost
      is non-trivial at high thread counts but is secondary compared to
      the ``par`` copy.

   Measured behaviour (see
   :doc:`B01 Kunpeng comparison </tests/kunpeng_compare/B01_scatter_3Dxyz_omp>`):

   - **Small problem** (``np = 1e4``): OMP overhead dominates; the sweet spot is
     2-4 threads, and adding more makes it slower.
   - **Large problem** (``np = 1e7``): ``firstprivate`` copies dominate; 64 threads
     are **37× slower than 1 thread** on the AMD server, and even on
     Kunpeng the kernel is only 2.6× slower at 64 threads.
   - **Across all particle counts** (``np``): measured speedup never reaches more than ~3×,
     well below linear.

   In other words, **the current kernel does not scale well**. Practical
   compromises:

   - Keep the thread count in the 4-8 range.
   - For genuine high parallelism, bypass the upstream routine and write a
     custom version using ``default(shared)`` with atomic adds or
     per-thread local accumulation merged by hand. That is beyond this
     page.

   .. rubric:: Common Integration Mistakes

   - ``par`` **shape mismatch.** Caller allocates ``par(1:6, 1:np_max)``
     and passes the slab to a routine declared as ``par(1:3, 1:np)`` —
     Fortran reinterprets the memory with stride 3 and reads every other
     column as garbage velocity slots. **Always check this before going
     live.**
   - ``den`` **not zeroed.** Residue from the previous step accumulates
     into the current one inside a multi-step PIC loop.
   - **No guard cell allocated.** ``den(il:iu, ...)`` with no overflow
     ring catches CIC weights from edge particles writing past the
     boundary, producing a segfault or silent corruption. The correct
     layout is ``den(il-1:iu+1, ...)``.
   - **Treating B02 "per cell" output as density.** ``B02`` produces the
     cell-integrated quantity, not the physical density. Decide once
     whether the downstream solver consumes cell integrals or densities.
   - **Stack too small.** Default ``ulimit -s`` is 8 MB and
     ``OMP_STACKSIZE`` is around 4 MB; ``np = 1e7`` with
     ``firstprivate`` segfaults immediately. Fix per the OMP section
     above.
   - **Expecting CIC conservation from** ``_T``. ``sub_..._T`` uses
     nearest-cell, not CIC, so ``sum(den_T) = sum(w*v^2)`` does not hold.
     It provides per-node variance, not "the second moment".
