sub_E03_fdtd_3d_cartesian_H.f90
--------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   在三维 Cartesian Yee 网格上，用 ``Ex/Ey/Ez`` 的 curl 更新 ``Hx/Hy/Hz``。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 14 10 25 33 22 38

      * - 参数
        - 方向
        - shape / 范围
        - 含义
        - 单位 / 归一化
        - 索引 / ghost-cell 要求
      * - ``ilo_f``
        - ``in``
        - ``integer scalar``
        - 场数组第一维下界
        - 整数下标
        - 声明所有场数组和 CPML 数组的有效下标边界。
      * - ``ihi_f``
        - ``in``
        - ``integer scalar``
        - 场数组第一维上界
        - 整数下标
        - 声明所有场数组和 CPML 数组的有效下标边界。
      * - ``jlo_f``
        - ``in``
        - ``integer scalar``
        - 场数组第二维下界
        - 整数下标
        - 声明所有场数组和 CPML 数组的有效下标边界。
      * - ``jhi_f``
        - ``in``
        - ``integer scalar``
        - 场数组第二维上界
        - 整数下标
        - 声明所有场数组和 CPML 数组的有效下标边界。
      * - ``klo_f``
        - ``in``
        - ``integer scalar``
        - 场数组 z 方向下界
        - 整数下标
        - 声明所有场数组和 CPML 数组的有效下标边界。
      * - ``khi_f``
        - ``in``
        - ``integer scalar``
        - 场数组 z 方向上界
        - 整数下标
        - 声明所有场数组和 CPML 数组的有效下标边界。
      * - ``il``
        - ``in``
        - ``integer scalar``
        - 第一维更新下界
        - 整数下标
        - 更新区间必须落在声明边界内，并给差分访问留出相邻点。
      * - ``iu``
        - ``in``
        - ``integer scalar``
        - 第一维更新上界
        - 整数下标
        - 更新区间必须落在声明边界内，并给差分访问留出相邻点。
      * - ``jl``
        - ``in``
        - ``integer scalar``
        - 第二维更新下界
        - 整数下标
        - 更新区间必须落在声明边界内，并给差分访问留出相邻点。
      * - ``ju``
        - ``in``
        - ``integer scalar``
        - 第二维更新上界
        - 整数下标
        - 更新区间必须落在声明边界内，并给差分访问留出相邻点。
      * - ``kl``
        - ``in``
        - ``integer scalar``
        - z 方向更新下界
        - 整数下标
        - 更新区间必须落在声明边界内，并给差分访问留出相邻点。
      * - ``ku``
        - ``in``
        - ``integer scalar``
        - z 方向更新上界
        - 整数下标
        - 更新区间必须落在声明边界内，并给差分访问留出相邻点。
      * - ``Ex``
        - ``in``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - x 向电场分量
        - 调用者归一化下的场值
        - 按 ``*_f`` 边界声明；调用者需提前填好差分会访问的相邻/ghost cell。
      * - ``Ey``
        - ``in``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - y 向电场分量
        - 调用者归一化下的场值
        - 按 ``*_f`` 边界声明；调用者需提前填好差分会访问的相邻/ghost cell。
      * - ``Ez``
        - ``in``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - z/轴向电场分量
        - 调用者归一化下的场值
        - 按 ``*_f`` 边界声明；调用者需提前填好差分会访问的相邻/ghost cell。
      * - ``Hx``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - x 向磁场分量
        - 调用者归一化下的场值
        - 按 ``*_f`` 边界声明；调用者需提前填好差分会访问的相邻/ghost cell。
      * - ``Hy``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - y 向磁场分量
        - 调用者归一化下的场值
        - 按 ``*_f`` 边界声明；调用者需提前填好差分会访问的相邻/ghost cell。
      * - ``Hz``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - z/轴向磁场分量
        - 调用者归一化下的场值
        - 按 ``*_f`` 边界声明；调用者需提前填好差分会访问的相邻/ghost cell。
      * - ``dt``
        - ``in``
        - ``real scalar``
        - 时间步长
        - 调用者单位的时间步长
        - 本例程只使用传入标量，不读取全局设置。
      * - ``dx``
        - ``in``
        - ``real scalar``
        - x 方向网格间距
        - 调用者单位的长度
        - 本例程只使用传入标量，不读取全局设置。
      * - ``dy``
        - ``in``
        - ``real scalar``
        - y 方向网格间距
        - 调用者单位的长度
        - 本例程只使用传入标量，不读取全局设置。
      * - ``dz``
        - ``in``
        - ``real scalar``
        - z 方向网格间距
        - 调用者单位的长度
        - 本例程只使用传入标量，不读取全局设置。
      * - ``mu``
        - ``in``
        - ``real scalar``
        - 磁导率
        - 调用者归一化下的磁导率
        - 本例程只使用传入标量，不读取全局设置。

   .. rubric:: 局部假设 / 前置条件

   - 网格是三维 Cartesian ``x-y-z`` Yee staggered 布局。
   - 所有步长、介质参数和数组边界都由调用者传入；本例程不假设全局 ``dx=1``、``dt=1`` 或固定 real kind。
   - 本例程只更新指定的局部范围；不做 MPI exchange、外边界条件、源项注入或粒子电流沉积。
   - 若差分使用 ``j-1`` 或 ``j+1``，方位角/横向边界的 periodic 或 ghost cell 必须在调用前处理好。

   .. rubric:: 实现逻辑

   - 三个嵌套循环内按 Yee curl 逐点原地更新 ``Hx``、``Hy``、``Hz``。
   - 磁场更新使用电场的前向差分，符号为 Maxwell 方程中 ``-dt/mu*curl(E)``。

   .. rubric:: 调用注意

   - 调用者负责维持 Yee leapfrog 时间层关系；本例程只完成一次局部场更新。
   - 传入的更新范围要与场数组 stagger 位置一致，否则可能在边界处读到未定义相邻点。


.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Updates ``Hx/Hy/Hz`` from the curl of ``Ex/Ey/Ez`` on a 3D Cartesian Yee grid.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 14 10 25 33 22 38

      * - Parameter
        - Direction
        - Shape / Range
        - Meaning
        - Units / Normalization
        - Index / ghost-cell requirement
      * - ``ilo_f``
        - ``in``
        - ``integer scalar``
        - lower ``x`` index bound of field arrays.
        - integer index
        - Defines valid bounds for field and CPML arrays.
      * - ``ihi_f``
        - ``in``
        - ``integer scalar``
        - upper ``x`` index bound of field arrays.
        - integer index
        - Defines valid bounds for field and CPML arrays.
      * - ``jlo_f``
        - ``in``
        - ``integer scalar``
        - lower ``y`` index bound of field arrays.
        - integer index
        - Defines valid bounds for field and CPML arrays.
      * - ``jhi_f``
        - ``in``
        - ``integer scalar``
        - upper ``y`` index bound of field arrays.
        - integer index
        - Defines valid bounds for field and CPML arrays.
      * - ``klo_f``
        - ``in``
        - ``integer scalar``
        - lower ``z`` index bound of field arrays.
        - integer index
        - Defines valid bounds for field and CPML arrays.
      * - ``khi_f``
        - ``in``
        - ``integer scalar``
        - upper ``z`` index bound of field arrays.
        - integer index
        - Defines valid bounds for field and CPML arrays.
      * - ``il``
        - ``in``
        - ``integer scalar``
        - lower update ``x`` index.
        - integer index
        - Update range must stay inside declared bounds and leave needed neighbor cells available.
      * - ``iu``
        - ``in``
        - ``integer scalar``
        - upper update ``x`` index.
        - integer index
        - Update range must stay inside declared bounds and leave needed neighbor cells available.
      * - ``jl``
        - ``in``
        - ``integer scalar``
        - lower update ``y`` index.
        - integer index
        - Update range must stay inside declared bounds and leave needed neighbor cells available.
      * - ``ju``
        - ``in``
        - ``integer scalar``
        - upper update ``y`` index.
        - integer index
        - Update range must stay inside declared bounds and leave needed neighbor cells available.
      * - ``kl``
        - ``in``
        - ``integer scalar``
        - lower update ``z`` index.
        - integer index
        - Update range must stay inside declared bounds and leave needed neighbor cells available.
      * - ``ku``
        - ``in``
        - ``integer scalar``
        - upper update ``z`` index.
        - integer index
        - Update range must stay inside declared bounds and leave needed neighbor cells available.
      * - ``Ex``
        - ``in``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - ``x`` electric field component.
        - field value in caller normalization
        - Array bounds follow ``*_f``; caller must provide neighboring or ghost cells touched by finite differences.
      * - ``Ey``
        - ``in``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - ``y`` electric field component.
        - field value in caller normalization
        - Array bounds follow ``*_f``; caller must provide neighboring or ghost cells touched by finite differences.
      * - ``Ez``
        - ``in``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - ``z`` electric field component.
        - field value in caller normalization
        - Array bounds follow ``*_f``; caller must provide neighboring or ghost cells touched by finite differences.
      * - ``Hx``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - ``x`` magnetic field component.
        - field value in caller normalization
        - Array bounds follow ``*_f``; caller must provide neighboring or ghost cells touched by finite differences.
      * - ``Hy``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - ``y`` magnetic field component.
        - field value in caller normalization
        - Array bounds follow ``*_f``; caller must provide neighboring or ghost cells touched by finite differences.
      * - ``Hz``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - ``z`` magnetic field component.
        - field value in caller normalization
        - Array bounds follow ``*_f``; caller must provide neighboring or ghost cells touched by finite differences.
      * - ``dt``
        - ``in``
        - ``real scalar``
        - time step.
        - time step in caller units
        - Used exactly as passed; no global spacing or material state is read.
      * - ``dx``
        - ``in``
        - ``real scalar``
        - grid spacing in ``x``.
        - length in caller units
        - Used exactly as passed; no global spacing or material state is read.
      * - ``dy``
        - ``in``
        - ``real scalar``
        - grid spacing in ``y``.
        - length in caller units
        - Used exactly as passed; no global spacing or material state is read.
      * - ``dz``
        - ``in``
        - ``real scalar``
        - grid spacing in ``z``.
        - length in caller units
        - Used exactly as passed; no global spacing or material state is read.
      * - ``mu``
        - ``in``
        - ``real scalar``
        - permeability.
        - permeability in caller normalization
        - Used exactly as passed; no global spacing or material state is read.

   .. rubric:: Local Assumptions / Preconditions

   - The grid is a 3D Cartesian ``x-y-z`` Yee-staggered layout.
   - All spacings, material parameters, and bounds are passed explicitly; the routine assumes no global ``dx=1``, ``dt=1``, or fixed real kind.
   - Only the requested local range is modified; MPI exchange, external boundary conditions, sources, and current deposition are outside this routine.
   - Any periodic or ghost values used by ``j-1``/``j+1`` differences must be prepared by the caller.

   .. rubric:: Implementation Notes

   - Updates ``Hx``, ``Hy``, and ``Hz`` in place with standard Yee curl loops.
   - The magnetic update uses forward electric-field differences with the Maxwell sign ``-dt/mu*curl(E)``.

   .. rubric:: Calling Notes

   - The caller maintains the Yee leapfrog time staggering; this routine performs only one local field update.
   - The update range must match the staggered locations of the fields so boundary neighbors are defined.

   .. rubric:: Generated API

   .. doxygenfile:: sub_E03_fdtd_3d_cartesian_H.f90
