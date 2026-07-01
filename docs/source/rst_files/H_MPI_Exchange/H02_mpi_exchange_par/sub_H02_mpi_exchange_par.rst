sub_H02_mpi_exchange_par.f90
----------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_H02_mpi_exchange_par`` 将越过本地子域边界的粒子打包并交换到相邻 MPI rank，
   并在返回时恢复“每个粒子只属于一个本地半开盒子”的所有权一致性。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``ns``
        - in
        - scalar or caller-provided array
        - 粒子种类数。
      * - ``np``
        - inout
        - ``(1:ns)``
        - 粒子数；读写例程只处理 ``par(:,1:np)``，碰撞/交换例程可能更新它。
      * - ``npmax``
        - in
        - scalar or caller-provided array
        - 粒子数组第二维容量上限，调用前必须足以容纳本地粒子。
      * - ``par``
        - inout
        - ``(1:6,1:npmax,1:ns)``
        - 粒子数组；通常 ``1:3`` 为位置，``4:6`` 为速度，列或第二维为粒子编号。
      * - ``il``
        - in
        - ``(1:3)``
        - 本地 active cell 下界索引。
      * - ``iu``
        - in
        - ``(1:3)``
        - 本地 active cell 上界索引。
      * - ``il0``
        - in
        - ``(1:3)``
        - 全局物理网格下界索引。
      * - ``iu0``
        - in
        - ``(1:3)``
        - 全局物理网格上界索引。
      * - ``domain_split``
        - in
        - ``(1:3)``
        - x/y/z 三方向的 MPI 切分数量。
      * - ``l``
        - in
        - ``(1:3)``
        - 周期长度；大于 0 表示该方向可周期包裹。
      * - ``nsmax``
        - out
        - scalar or caller-provided array
        - 一次交换需要的全局最大缓冲需求。
      * - ``istat``
        - out
        - scalar or caller-provided array
        - 状态码；0 成功，非 0 表示需要调用方处理容量或错误。

   .. rubric:: 局部假设

   - 调用前必须已经执行 ``sub_H02_mpi_exchange_par_init``。
   - 位置 ``par(1:3,:,:)`` 和周期长度 ``l(1:3)`` 使用 cell units。
   - 局部所有权按半开区间 ``[il(d)-1, iu(d))`` 判断。
   - 未分裂且周期的方向本地回绕；未分裂且非周期的方向本地删除；其余越界情况才走 MPI。

   .. rubric:: 实现逻辑

   例程先统计每个邻居/物种的迁出粒子数，再交换计数，随后按邻居优先、物种拼接的布局交换 payload，
   最后把收到粒子追加回本地物种数组。

   .. rubric:: 调用注意

   ``istat=1`` 不是通信失败，而是容量契约失败：说明 ``nsmax > H02_npm``，调用方应增大 ``npm``、
   重新初始化并重试。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_H02_mpi_exchange_par`` exchanges particles across MPI subdomains for
   all species and returns with ownership restored so that each particle belongs
   to exactly one local half-open box.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``ns``
        - in
        - scalar or caller-provided array
        - integer, number of species.
      * - ``np``
        - inout
        - ``(1:ns)``
        - integer (1:ns), current number of particles per species.
      * - ``npmax``
        - in
        - scalar or caller-provided array
        - integer, maximum number of particles per species array.
      * - ``par``
        - inout
        - ``(1:6,1:npmax,1:ns)``
        - real (1:6,1:npmax,1:ns), particle array.
      * - ``il``
        - in
        - ``(1:3)``
        - integer (1:3), cell-center lower indices in x,y,z.
      * - ``iu``
        - in
        - ``(1:3)``
        - integer (1:3), cell-center upper indices in x,y,z.
      * - ``il0``
        - in
        - ``(1:3)``
        - integer (1:3), global cell-center lower indices in x,y,z.
      * - ``iu0``
        - in
        - ``(1:3)``
        - integer (1:3), global cell-center upper indices in x,y,z.
      * - ``domain_split``
        - in
        - ``(1:3)``
        - integer (1:3), MPI splits in x,y,z.
      * - ``l``
        - in
        - ``(1:3)``
        - real (1:3), periodic length in x,y,z (<=0 non-periodic).
      * - ``nsmax``
        - out
        - scalar or caller-provided array
        - integer, global maximum of per-neighbor send and recv totals.
      * - ``istat``
        - out
        - scalar or caller-provided array
        - integer, status flag. 0 means success; 1 means ``nsmax>H02_npm`` and the caller
          should increase ``npm``, re-run ``sub_H02_mpi_exchange_par_init``, and retry.

   .. rubric:: Local Assumptions

   - ``sub_H02_mpi_exchange_par_init`` must already have been called.
   - Positions ``par(1:3,:,:)`` and periodic lengths ``l(1:3)`` are in cell units.
   - Local ownership is tested with half-open intervals ``[il(d)-1, iu(d))``.
   - Unsplit periodic directions wrap locally; unsplit non-periodic directions
     remove particles locally; only the remaining out-of-box cases use MPI.

   .. rubric:: Implementation Notes

   The routine first counts outgoing particles per neighbor and species, then
   exchanges counts, then exchanges payloads in a neighbor-major,
   species-concatenated layout, and finally appends received particles to the
   local species arrays.

   .. rubric:: Generated API

   .. doxygenfile:: sub_H02_mpi_exchange_par.f90
