sub_I02_load_init_particles_bin.f90
-----------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_I02_load_init_particles_bin`` 从离线二进制初值文件筛选并载入当前 MPI 子域的粒子。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``npmax``
        - out
        - scalar or caller-provided array
        - 粒子数组第二维容量上限，调用前必须足以容纳本地粒子。
      * - ``np``
        - out
        - ``(:)``
        - 粒子数；读写例程只处理 ``par(:,1:np)``，碰撞/交换例程可能更新它。
      * - ``ns``
        - in
        - scalar or caller-provided array
        - 粒子种类数。
      * - ``np_load``
        - in
        - scalar or caller-provided array
        - 从文件读取或筛选到的粒子数。
      * - ``mpi_i_para``
        - in
        - scalar or caller-provided array
        - 调用方传入的 MPI rank。
      * - ``il``
        - in
        - ``(1:3)``
        - 本地 active cell 下界索引。
      * - ``iu``
        - in
        - ``(1:3)``
        - 本地 active cell 上界索引。
      * - ``ierr_para``
        - in/out
        - scalar or caller-provided array
        - MPI 错误码。
      * - ``mpi_int_para``
        - in
        - scalar or caller-provided array
        - MPI 整数 datatype。
      * - ``mpi_max_para``
        - in
        - scalar or caller-provided array
        - MPI_MAX reduction 操作。
      * - ``mpi_comm_world_para``
        - in
        - scalar or caller-provided array
        - MPI communicator。
      * - ``par``
        - out
        - ``(:,:,:)``
        - 粒子数组；通常 ``1:3`` 为位置，``4:6`` 为速度，列或第二维为粒子编号。
      * - ``f_npmax``
        - in
        - scalar or caller-provided array
        - 粒子文件中的容量或计数信息。
      * - ``wei``
        - out
        - ``(:)``
        - 粒子权重。
      * - ``np_real``
        - in
        - scalar or caller-provided array
        - 实际物理粒子数或权重换算后的数量。

   .. rubric:: 局部假设

   初始化例程写入调用方提供的粒子数组，不负责后续推进或边界交换。粒子坐标采用网格指标单位；二进制载入流程依赖离线生成文件的字段顺序和实数精度。

   .. rubric:: 实现逻辑

   实现从离线二进制文件读取全局粒子记录，按当前 rank 的 ``il``/``iu`` 范围筛选并写入本地 ``par``。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_I02_load_init_particles_bin`` read initial particle binary files and distribute particles to the local MPI subdomain.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``npmax``
        - out
        - scalar or caller-provided array
        - integer, maximum allocated local particle number after applying the expansion factor
          ``f_npmax``
      * - ``np``
        - out
        - ``(:)``
        - integer (:), local particle number of each species in the current MPI rank
      * - ``ns``
        - in
        - scalar or caller-provided array
        - integer, total number of particle species
      * - ``np_load``
        - in
        - scalar or caller-provided array
        - integer, number of particles read from each binary file before local filtering
      * - ``mpi_i_para``
        - in
        - scalar or caller-provided array
        - integer, MPI rank index
      * - ``il``
        - in
        - ``(1:3)``
        - integer (1:3), cell-center lower indices in x,y,z
      * - ``iu``
        - in
        - ``(1:3)``
        - integer (1:3), cell-center upper indices in x,y,z
      * - ``ierr_para``
        - in/out
        - scalar or caller-provided array
        - integer, MPI error flag
      * - ``mpi_int_para``
        - in
        - scalar or caller-provided array
        - integer, MPI integer datatype handle
      * - ``mpi_max_para``
        - in
        - scalar or caller-provided array
        - integer, MPI max reduction operator handle
      * - ``mpi_comm_world_para``
        - in
        - scalar or caller-provided array
        - integer, MPI communicator handle
      * - ``par``
        - out
        - ``(:,:,:)``
        - real (:,:,:), local particle array storing ``x,y,z,vx,vy,vz``
      * - ``f_npmax``
        - in
        - scalar or caller-provided array
        - real, expansion factor used to enlarge ``npmax`` for array allocation
      * - ``wei``
        - out
        - ``(:)``
        - real (:), particle weight of each species
      * - ``np_real``
        - in
        - scalar or caller-provided array
        - real, physical particle number represented by the loaded particles

   .. rubric:: Local Assumptions

   Initializer routines write into caller-provided particle arrays and do not perform later pushing or boundary exchange. Particle coordinates are in grid-index units. Binary loading depends on the offline file field order and real precision.

   .. rubric:: Implementation Notes

   The implementation reads global particle records from offline binary files, filters them by this rank's ``il``/``iu`` bounds, and writes local ``par``.

   .. rubric:: Generated API

   .. doxygenfile:: sub_I02_load_init_particles_bin.f90
