Scatter Usage Cookbook
==============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-b04-doc

   .. rubric:: 选择接口并准备调用

   **先按网格和输出量选择算法，再按该接口准备数组与调用循环。** 各模块的粒子输入、体积归一化和数组更新方式见下表；具体参数以链接页面为准。

   .. list-table::
      :header-rows: 1
      :widths: 22 38 40

      * - 算法
        - 输入与主要用途
        - 调用方式与输出
      * - :doc:`B01 <B01_scatter_3Dxyz>`
        - Cartesian 网格指标坐标；基础沉积接收 ``par(1:3,1:np)``，分量／方差例程接收 ``par(1:6,1:np)``
        - 内部遍历粒子。基础及 ``_v`` 例程在最后整体乘 ``w``；``_T`` 写出单元方差
      * - :doc:`B02 <B02_deposit_3d_cyl>`
        - 均匀柱坐标；电荷沉积使用当前位置，电流沉积使用旧、新位置和时间步
        - 调用方逐粒子调用；写出已作几何归一化的电荷或电流密度
      * - :doc:`B03 <B03_scatter_3Dxyz_bspline>`
        - Cartesian 网格指标坐标、``par(1:6,1:np)`` 与 B-spline 阶数
        - 内部遍历粒子，将 ``w`` 或 ``w*par(d,p)`` 加入目标数组；保留已有累加量
      * - :doc:`B04 <B04_scatter_3Draz_nonuniform>`
        - 非均匀柱坐标节点数组、单粒子 ``position``、所在单元 ``cell``、贡献量 ``amount``
        - 先准备几何量，再逐粒子调用；累加已作体积归一化的节点数密度或电荷密度

   .. rubric:: 密度累加与初始化

   - **B01 基础及分量沉积：** 通常每次调用前清零目标数组。代码最后对整个数组乘 ``w``；若分批处理，应分别沉积到临时数组后相加。
   - **B03 和 B04 沉积：** 每轮新的沉积前清零一次；同一轮中多个粒子或批次可以继续累加。B04 的 ``amount`` 可逐粒子改变。
   - **B01 方差统计：** ``_T`` 内部初始化并写出各单元方差；调用方按需要将方差换算为温度。

   B02 和 B04 的节点密度已经包含体积归一化。下游需要总量时，按配套有效体积计算 :math:`\sum_a V_aD_a`；下游需要密度时，使用该密度及相应单位。

   .. _scatter-b04-calling-zh:

   .. rubric:: B04：一次准备，多轮沉积

   1. **网格建立或改变时：** 分配数组，调用 ``sub_B04_build_geometry``，保存 ``inv_volume`` 和 ``phi_measure``。
   2. **每轮沉积开始：** 清零 ``density``；调用方按应用的边界规则准备粒子位置，并确定粒子所在单元。
   3. **粒子循环内：** 每个粒子调用一次 ``sub_B04_scatter_3Draz_nonuniform``，并检查 ``ierr``。
   4. **粒子循环之后：** 分区计算先汇集共享节点贡献；含轴全周区域再进行轴点平均。需要单元平均源项时调用 ``sub_B04_project_density``。

   所需数组布局与各步骤的直接产物见 :ref:`B04 调用流程 <b04-workflow-zh>`；可直接编译的短程序见 :doc:`B04 调用示例 <B04_scatter_3Draz_nonuniform/usage>`。

   .. rubric:: 网格边缘与并行调用

   **数组范围由具体例程决定。** B01 的基础／分量沉积使用 ``il-1:iu+1`` 范围，B03 的额外节点层数随阶数变化；B04 使用接口规定的物理节点范围和独立周期节点。
   物理边界模型、粒子去留和进程间通信由调用程序组织。

   对 B04，物理端点只计域内基函数支撑；MPI 内部接口则需要两侧支撑构成的完整有效体积。
   共享节点各份贡献使用一致体积，再进行求和。几何量的准备方式见 :doc:`build_geometry <B04_scatter_3Draz_nonuniform/sub_B04_build_geometry>`。
   多个线程同时向同一 ``density`` 写入时，调用方使用独立缓冲区再求和，或组织同步。

   .. rubric:: 编译与后续入口

   - module 和调用程序采用一致的默认 ``real`` 精度；GNU Fortran 可用 ``-fdefault-real-8`` 选择双精度默认实数。
   - 含 ``#include`` 的 module 启用预处理，并提供源文件搜索路径。B04 的具体命令见 :ref:`模块编译说明 <b04-compile-zh>`。
   - ``-fopenmp`` 用于启用带 OpenMP 指令的例程；各模块的并行方式分别以执行代码为准。B01 的已有性能数据见 :doc:`平台比较 </tests/kunpeng_compare/B01_scatter_3Dxyz_omp>`。

   返回 :doc:`学习入口 <scatter_learning_path>` · :doc:`测试指南 <scatter_testing_guide>` · :doc:`B_Scatter </rst_files/B_Scatter>`。

.. container:: ap-lang ap-lang-en ap-b04-doc

   .. rubric:: Select an interface and prepare the call

   **Choose the algorithm by grid and output quantity, then prepare arrays and loops for that interface.** Particle inputs, normalization and array updates differ as follows. Linked pages provide the complete parameters.

   .. list-table::
      :header-rows: 1
      :widths: 22 38 40

      * - Algorithm
        - Inputs and purpose
        - Calls and output
      * - :doc:`B01 <B01_scatter_3Dxyz>`
        - Cartesian grid-index coordinates; basic scatter takes ``par(1:3,1:np)``, component/variance routines take ``par(1:6,1:np)``
        - Internal particle loop. Basic and ``_v`` routines scale the whole array by ``w`` at the end; ``_T`` writes cell variance
      * - :doc:`B02 <B02_deposit_3d_cyl>`
        - Uniform cylindrical grid; charge deposition takes current position, current deposition takes old/new positions and a time step
        - Caller loops over particles; output is geometrically normalized charge or current density
      * - :doc:`B03 <B03_scatter_3Dxyz_bspline>`
        - Cartesian grid-index coordinates, ``par(1:6,1:np)`` and B-spline degree
        - Internal particle loop adds ``w`` or ``w*par(d,p)`` contributions, preserving previous accumulated values
      * - :doc:`B04 <B04_scatter_3Draz_nonuniform>`
        - Nonuniform cylindrical node arrays, one particle's ``position``, containing ``cell`` and ``amount``
        - Prepare geometry, then call per particle; accumulate volume-normalized nodal number or charge density

   .. rubric:: Accumulation and initialization

   - **B01 basic and component scatter:** normally clear the target before each call. The final statement scales the whole array by ``w``; deposit batches into separate temporary arrays and sum them.
   - **B03 and B04 scatter:** clear once at the start of a new deposition stage; particles or batches in that stage can accumulate into the same array. B04 permits a different ``amount`` for each particle.
   - **B01 variance:** ``_T`` initializes and writes cell variance internally. The caller supplies any conversion to temperature.

   B02 and B04 nodal densities already include volume normalization. Recover a total as :math:`\sum_a V_aD_a` with the matching effective volumes; consumers of density use the density and its units directly.

   .. _scatter-b04-calling-en:

   .. rubric:: B04: prepare once, deposit repeatedly

   1. **At grid creation or change:** allocate arrays, call ``sub_B04_build_geometry`` and retain ``inv_volume`` and ``phi_measure``.
   2. **At the start of each deposition stage:** clear ``density``; apply the application's particle boundary rules and locate containing cells.
   3. **Inside the particle loop:** call ``sub_B04_scatter_3Draz_nonuniform`` once per particle and check ``ierr``.
   4. **After the loop:** sum shared-node contributions in partitioned calculations, then average a full-circle axis where present. Call ``sub_B04_project_density`` when a cell-average source is needed.

   See the :ref:`B04 workflow <b04-workflow-en>` for layouts and direct results, and the :doc:`B04 calling example <B04_scatter_3Draz_nonuniform/usage>` for a short compilable program.

   .. rubric:: Grid edges and parallel calls

   **Array extents follow the selected routine.** B01 basic/component scatter uses ``il-1:iu+1``; B03 padding depends on degree. B04 uses physical-node extents and independent periodic nodes specified by its interface.
   The application organizes physical boundary models, particle retention and communication.

   B04 physical endpoints have one-sided basis support; MPI interfaces require complete effective volumes including support on both sides.
   Shared-node contributions use matching volumes before summation; see :doc:`build_geometry <B04_scatter_3Draz_nonuniform/sub_B04_build_geometry>`.
   Concurrent writes to ``density`` require separate buffers followed by summation, or caller-managed synchronization.

   .. rubric:: Compilation and further reading

   - Compile the module and caller with consistent default ``real`` precision; GNU Fortran supports ``-fdefault-real-8`` for double-precision default reals.
   - Enable preprocessing and source search paths for modules using ``#include``. See :ref:`B04 compilation <b04-compile-en>`.
   - ``-fopenmp`` enables OpenMP directives in routines that use them. Parallel behavior follows each implementation; existing B01 performance measurements are documented in the :doc:`platform comparison </tests/kunpeng_compare/B01_scatter_3Dxyz_omp>`.

   Return to the :doc:`learning path <scatter_learning_path>` · :doc:`testing guide <scatter_testing_guide>` · :doc:`B_Scatter </rst_files/B_Scatter>`.
