mod_B04_scatter_3d_raz_nonuniform
=================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-b04-doc

   .. rubric:: 集成的算法

   **本 module 集成非均匀三维柱坐标网格上的粒子沉积（scatter）算法及其配套操作。**
   核心过程采用线性 CIC 权重并按有效节点体积归一化，输出节点数密度或电荷密度。
   网格和算法思路见 :ref:`B04 基本思想 <b04-principle-zh>`；本页说明模块接口、公共量和编译方式。

   .. rubric:: 公开子程序及分工

   模块提供以下四个子程序，**由调用方按计算需要组织调用**；各自的公式、参数和代码对应关系见链接页面。

   - :doc:`sub_B04_build_geometry <sub_B04_build_geometry>`：**准备几何量**，计算有效节点体积的倒数和角向节点基函数积分，供沉积及轴点处理使用。
   - :doc:`sub_B04_scatter_3d_raz_nonuniform <sub_B04_scatter_3d_raz_nonuniform>`：**执行单粒子沉积**，根据粒子位置、所在单元和所代表的粒子数或电荷量，累加节点密度。
   - :doc:`sub_B04_average_axis <sub_B04_average_axis>`：**处理全周网格的轴点密度**，对 ``r=0`` 处各角向节点的密度加权平均，使同一轴点具有一致的密度值。
   - :doc:`sub_B04_project_density <sub_B04_project_density>`：**计算单元体积平均密度**，在后续计算需要单元量时，由节点密度计算各单元内的体积平均值。

   .. code-block:: fortran

      use mod_B04_scatter_3d_raz_nonuniform

   .. rubric:: 子程序之间传递的数据

   **数组由调用方分配和保存，通过参数在子程序之间传递。** 主要约定如下：

   - **网格与周期性：** ``r``、``phi``、``z`` 为节点坐标，``periodic_phi`` 指定角向是否周期连接；各次调用应使用一致的网格和角向节点存储约定。
   - **几何量：** ``build_geometry`` 输出的 ``inv_volume`` 供沉积归一化使用，``phi_measure`` 供轴点加权平均使用；网格和周期配置不变时可以复用。
   - **密度：** ``density`` 保存累加的节点密度；轴点处理更新其中的轴线部分，单元平均操作将结果写入另一个数组 ``cell_density``。

   模块公开的公共常量为下面六个返回状态码。通用布局见 :ref:`网格与存储约定 <b04-grid-zh>`，各参数的读写方式见子程序页。

   .. _b04-status-zh:

   .. rubric:: 公共返回状态

   每次调用后检查 ``ierr`` 。非零状态返回时，目标数组保持调用前的值；错误原因由调用方记录或处理。
   源码中的定义集中在本 module，以下中文表解释同一组常量。

   .. list-table::
      :header-rows: 1
      :widths: 31 9 60

      * - 常量
        - 数值
        - 含义
      * - ``B04_OK``
        - 0
        - 成功完成
      * - ``B04_BAD_SHAPE``
        - 1
        - 数组维度不满足接口要求
      * - ``B04_BAD_GRID``
        - 2
        - 坐标数组或局部几何不满足要求
      * - ``B04_BAD_CELL``
        - 3
        - 输入单元号超出有效范围
      * - ``B04_BAD_VALUE``
        - 4
        - 输入或检查到的计算结果不是有限数值；密度累加超出可表示范围；粒子不在指定单元内
      * - ``B04_BAD_VOLUME``
        - 5
        - 节点体积、逆体积、角向权重或权重和未通过有效性检查

   完整几何检查由 ``build_geometry`` 承担；逐粒子沉积检查局部几何和访问的数组项。
   数值尺度应保证中间运算可表示，浮点异常的捕获遵循编译配置。

   .. _b04-compile-zh:

   .. rubric:: 编译与独立调用

   源码使用默认 ``real`` 。module 和调用程序使用一致精度；GNU Fortran 双精度可用 ``-fdefault-real-8`` 。
   启用 ``-cpp`` ，并将 B04 目录加入 ``-I`` 搜索路径。四个 ``sub_*.f90`` 已被入口包含，无需再单独编译。
   算法仅使用 Fortran 内建 ``ieee_arithmetic`` ，粒子容器、内存分配和通信由调用方组织。

   可直接编译的程序及命令见 :doc:`调用示例 <usage>`。


   返回 :doc:`B04 总览 </rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform>` · :doc:`调用示例 <usage>` · :doc:`测试与结果 </tests/004_scatter/B04_scatter_3d_raz_nonuniform>`

.. container:: ap-lang ap-lang-en ap-b04-doc

   .. rubric:: Algorithm provided

   **This module provides particle-to-grid deposition (scatter) on nonuniform three-dimensional cylindrical grids, together with its supporting operations.**
   The core routine uses linear CIC weights and effective-volume normalization to produce nodal number or charge density.
   See the :ref:`B04 principle <b04-principle-en>` for the grid and method; this page describes module interfaces, shared definitions and compilation.

   .. rubric:: Public routines and roles

   The module exposes four routines. **The caller selects and sequences the calls**; the linked pages explain their formulas, parameters and implementation.

   - :doc:`sub_B04_build_geometry <sub_B04_build_geometry>`: **prepare geometric measures**, computing inverse effective nodal volumes and angular nodal basis integrals for deposition and axis averaging.
   - :doc:`sub_B04_scatter_3d_raz_nonuniform <sub_B04_scatter_3d_raz_nonuniform>`: **deposit one particle**, using its position, containing cell and represented number or charge to accumulate nodal density.
   - :doc:`sub_B04_average_axis <sub_B04_average_axis>`: **average density on a full-circle axis**, giving angular nodes at the same physical point on ``r=0`` a common weighted density.
   - :doc:`sub_B04_project_density <sub_B04_project_density>`: **compute cell-volume-averaged density** from nodal density when downstream calculations require cell-based quantities.

   .. code-block:: fortran

      use mod_B04_scatter_3d_raz_nonuniform

   .. rubric:: Data passed between routines

   **The caller allocates and retains arrays, passing them as routine arguments.** The main conventions are:

   - **Grid and periodicity:** ``r``, ``phi`` and ``z`` hold node coordinates; ``periodic_phi`` selects periodic angular connectivity. Calls must use consistent grid and angular-node storage conventions.
   - **Geometric measures:** ``build_geometry`` supplies ``inv_volume`` for deposition normalization and ``phi_measure`` for axis averaging. Both can be reused while the grid and periodic configuration remain unchanged.
   - **Density:** ``density`` holds accumulated nodal density. Axis averaging updates its axis portion; cell averaging writes to a separate ``cell_density`` array.

   The module's public constants are the six return-status codes below. See :ref:`grid and storage conventions <b04-grid-en>` for shared layouts and each routine page for parameter input/output roles.

   .. _b04-status-en:

   .. rubric:: Return status

   Check ``ierr`` after each call. A nonzero returned status preserves target arrays; the caller reports or handles the error.
   The six constants and their meanings are defined in the generated module API below, alongside the source definitions.
   Geometry preparation checks full coordinates; scatter checks local geometry and accessed values. Use scales that keep intermediate arithmetic representable; exception trapping follows compiler configuration.

   .. _b04-compile-en:

   .. rubric:: Compilation and independent calls

   All sources use default ``real``. Compile module and caller consistently; GNU Fortran can use ``-fdefault-real-8``.
   Enable ``-cpp`` and add the B04 directory to ``-I``. The module includes the four ``sub_*.f90`` files; compile the entry once.
   The algorithm uses intrinsic ``ieee_arithmetic``; the caller manages particles, allocations and communication.
   The :doc:`calling example <usage>` supplies a complete source and build command.


   :doc:`B04 overview </rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform>` · :doc:`Usage example <usage>` · :doc:`Tests and results </tests/004_scatter/B04_scatter_3d_raz_nonuniform>`

   .. rubric:: Generated API

   .. doxygennamespace:: mod_b04_scatter_3d_raz_nonuniform
      :desc-only:

   .. doxygenvariable:: mod_b04_scatter_3d_raz_nonuniform::b04_ok

   .. doxygenvariable:: mod_b04_scatter_3d_raz_nonuniform::b04_bad_shape

   .. doxygenvariable:: mod_b04_scatter_3d_raz_nonuniform::b04_bad_grid

   .. doxygenvariable:: mod_b04_scatter_3d_raz_nonuniform::b04_bad_cell

   .. doxygenvariable:: mod_b04_scatter_3d_raz_nonuniform::b04_bad_value

   .. doxygenvariable:: mod_b04_scatter_3d_raz_nonuniform::b04_bad_volume

