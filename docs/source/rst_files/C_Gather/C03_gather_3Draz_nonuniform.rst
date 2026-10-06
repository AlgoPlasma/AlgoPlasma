C03_gather_3Draz_nonuniform
===========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``C03_gather_3Draz_nonuniform`` 的作用是：已知网格上的电场和磁场，求出某一个粒子所在位置的电场和磁场。
   网格只保存若干固定位置的场值，而粒子可以位于这些位置之间，因此代码需要根据附近的场值进行插值。
   这里的 gather 就是“从网格场计算粒子处的场”。得到的结果可交给粒子推进程序使用。

   本模块使用柱坐标 ``(r,alpha,z)``，分别表示半径、方位角和轴向位置。
   名称中的 ``nonuniform`` 表示网格单元可以大小不一，因此代码按实际坐标距离计算插值权重。

   .. rubric:: 输入什么，得到什么

   .. list-table::
      :header-rows: 1
      :widths: 30 30 30

      * - 数据
        - 在代码中的名字
        - 用途
      * - 粒子位置
        - ``par(1:3,p)`` 或 ``x(3)``
        - 说明要在哪个位置求场；单位为 m、rad、m。
      * - 网格几何
        - ``il,iu,r_face,a_face,z_face,dr,da,dz``
        - 用来寻找粒子附近的网格位置，并计算距离。
      * - 网格场
        - ``Er,Ea,Ez,Br,Ba,Bz``
        - 已有的六个场分量数组，只读取，不修改。
      * - 粒子处的场
        - ``E(3),B(3)``
        - 输出径向、角向、轴向三个分量，单位与输入场一致。

   .. rubric:: 代码中的面、中心和单元

   理解数组下标时，先看任意一个方向。``face(i-1)`` 和 ``face(i)`` 是单元 ``i`` 的两个边界，
   两者的中点是该单元中心。``width(i)`` 表示这两个边界之间的距离。
   径向用 ``r_face/dr``，角向用 ``a_face/da``，轴向用 ``z_face/dz``。

   ``il(d):iu(d)`` 表示当前程序负责的单元范围，``d=1,2,3`` 分别对应 r、alpha、z。
   这套编号与 D04 的几何编号一致：单元 i 的右侧面编号也是 i。

   .. code-block:: text

      face(i-1) -------- center(i) -------- face(i)
                <----------- cell i ----------->

   .. rubric:: 为什么各场分量要分别取值

   六个场数组的大小相同，但它们保存场值的位置不同，这种安排称为交错存储。
   例如 ``Er(i,j,k)`` 的径向位置是 ``r_face(i)``，而角向、轴向位置是单元中心。
   所以代码不能对六个场分量都使用同一组八个物理位置。

   .. list-table::
      :header-rows: 1
      :widths: 30 30 30 30

      * - 场分量
        - r 方向
        - alpha 方向
        - z 方向
      * - ``Er``
        - 面
        - 中心
        - 中心
      * - ``Ea``
        - 中心
        - 面
        - 中心
      * - ``Ez``
        - 中心
        - 中心
        - 面
      * - ``Br,Ba,Bz``
        - 面
        - 面
        - 面

   .. rubric:: 一次调用怎样完成计算

   1. 从 ``par(1:3,p)`` 取出第 p 个粒子的位置；若调用者已经有 ``x(3)``，可以直接进入 point 接口。
   2. 在三个方向分别寻找粒子所在单元，确定附近可用于插值的面和中心。
   3. 根据粒子到相邻位置的距离，计算两端各占多少比例，这些比例就是插值权重。
   4. 按照上表，为每个场分量在三个方向各选两个位置，组成八点模板。模板就是这次计算要读取的网格点集合。
   5. 将八个场值乘以各自权重后相加，六个分量分别计算，最终写入 ``E`` 和 ``B``。

   .. rubric:: 文件角色与阅读顺序

   .. list-table::
      :header-rows: 1
      :widths: 30 30

      * - 文件
        - 功能
      * - :doc:`mod_C03_gather_3Draz_nonuniform.f90 <C03_gather_3Draz_nonuniform/mod_C03_gather_3Draz_nonuniform>`
        - 模块入口：把本目录的子程序组织起来，供其他程序 use。
      * - :doc:`sub_C03_gather_3Draz_nonuniform.f90 <C03_gather_3Draz_nonuniform/sub_C03_gather_3Draz_nonuniform>`
        - 粒子数组入口：取出第 p 个粒子的位置，再调用单点插值。
      * - :doc:`sub_C03_gather_3Draz_nonuniform_point.f90 <C03_gather_3Draz_nonuniform/sub_C03_gather_3Draz_nonuniform_point>`
        - 单点插值入口：根据各场分量的存放位置，计算粒子处的 E 和 B。
      * - :doc:`sub_C03_gather_helpers.f90 <C03_gather_3Draz_nonuniform/sub_C03_gather_helpers>`
        - 辅助例程：检查网格、寻找单元、计算权重，以及完成八点加权。

   建议先读粒子数组入口，了解输入位置怎样传递；再读 point，了解六个输出分量怎样得到；
   最后按需要查看 helpers 中的单元搜索与权重计算。调用关系如下：

   .. code-block:: text

      sub_C03_gather_3Draz_nonuniform
        -> sub_C03_gather_3Draz_nonuniform_point
             -> c03_build_stencil
                  -> c03_axis_stencil  (r, alpha, z)
                       -> c03_center
             -> c03_trilinear         (Er, Ea, Ez, Br, Ba, Bz)

   .. rubric:: 调用前需要准备的内容

   粒子应位于本程序负责的网格范围内，网格场也应已经计算好。靠近边界时，插值可能需要范围外一层的场值；
   这些额外保存的邻接数据称为 ghost cell（幽灵单元）数据，调用方需要提前填好。

   C03 读取场并输出粒子处的场，不更新粒子位置或速度。输出仍是柱坐标分量，
   也不进行坐标系转换。这里的交错布局用于静电电场和给定节点磁场，输入数组须符合上表。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">王佰胜 · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``C03_gather_3Draz_nonuniform`` computes the electric and magnetic fields at one
   particle from fields already stored on a grid. Grid values are available only at
   fixed sample locations, while particles can lie between them. Interpolation
   estimates the field at the particle from nearby samples. This grid-to-particle
   operation is called gather; its outputs can be passed to a particle pusher.

   The coordinates ``(r,alpha,z)`` mean radius, azimuth, and axial position.
   ``nonuniform`` means cells can have different sizes, so interpolation weights
   are calculated from actual coordinate distances.

   .. rubric:: Inputs and Outputs

   .. list-table::
      :header-rows: 1
      :widths: 30 30 30

      * - Data
        - Source names
        - Purpose
      * - Particle position
        - ``par(1:3,p)`` or ``x(3)``
        - Where to evaluate the fields, in m, rad, m.
      * - Grid geometry
        - ``il,iu,r_face,a_face,z_face,dr,da,dz``
        - Locate nearby samples and calculate distances.
      * - Grid fields
        - ``Er,Ea,Ez,Br,Ba,Bz``
        - Six existing component arrays, read without modification.
      * - Particle fields
        - ``E(3),B(3)``
        - Output radial, angular, and axial components in input field units.

   .. rubric:: Faces, Centers, and Cells

   Consider one axis. ``face(i-1)`` and ``face(i)`` are the boundaries of cell i,
   and their midpoint is its center. ``width(i)`` is the distance between these
   boundaries. The radial, angular, and axial arrays are ``r_face/dr``, ``a_face/da``,
   and ``z_face/dz`` respectively.

   ``il(d):iu(d)`` gives the cells owned by this program instance; d=1,2,3 means
   r, alpha, z. This follows D04 geometry numbering: the upper face of cell i is face i.

   .. code-block:: text

      face(i-1) -------- center(i) -------- face(i)
                <----------- cell i ----------->

   .. rubric:: Why Components Use Different Samples

   The six arrays share the same bounds but store values at different physical
   locations. This is called staggering. For example, ``Er(i,j,k)`` lies at
   ``r_face(i)`` radially and at cell centers in alpha and z. Consequently, the
   six components do not all use the same eight physical sample locations.

   .. list-table::
      :header-rows: 1
      :widths: 30 30 30 30

      * - Component
        - r direction
        - alpha direction
        - z direction
      * - ``Er``
        - Face
        - Center
        - Center
      * - ``Ea``
        - Center
        - Face
        - Center
      * - ``Ez``
        - Center
        - Center
        - Face
      * - ``Br,Ba,Bz``
        - Face
        - Face
        - Face

   .. rubric:: What Happens During One Call

   1. Read particle p from ``par(1:3,p)``, or enter the point routine directly with ``x(3)``.
   2. Locate the containing cell along each axis and identify neighboring faces and centers.
   3. Calculate the share contributed by each neighbor from coordinate distances; these shares are interpolation weights.
   4. Use the component layout above to select two samples per direction, forming an eight-point stencil. A stencil is the set of grid samples read for this calculation.
   5. Multiply the eight values by their weights and sum them for each of the six components, returning E and B.

   .. rubric:: File Roles and Reading Order

   .. list-table::
      :header-rows: 1
      :widths: 30 30

      * - File
        - Purpose
      * - :doc:`mod_C03_gather_3Draz_nonuniform.f90 <C03_gather_3Draz_nonuniform/mod_C03_gather_3Draz_nonuniform>`
        - Module entry: collects routines for callers to access with use.
      * - :doc:`sub_C03_gather_3Draz_nonuniform.f90 <C03_gather_3Draz_nonuniform/sub_C03_gather_3Draz_nonuniform>`
        - Particle-array entry: reads particle p and delegates to point gather.
      * - :doc:`sub_C03_gather_3Draz_nonuniform_point.f90 <C03_gather_3Draz_nonuniform/sub_C03_gather_3Draz_nonuniform_point>`
        - Point entry: gathers E and B using each component's sample locations.
      * - :doc:`sub_C03_gather_helpers.f90 <C03_gather_3Draz_nonuniform/sub_C03_gather_helpers>`
        - Helpers: validate geometry, locate cells, calculate weights, and sum eight samples.

   Start with the particle-array entry to follow the position, then read point
   to see how the six outputs are formed, and finally inspect helper routines for
   cell search and weights. The call hierarchy is:

   .. code-block:: text

      sub_C03_gather_3Draz_nonuniform
        -> sub_C03_gather_3Draz_nonuniform_point
             -> c03_build_stencil
                  -> c03_axis_stencil  (r, alpha, z)
                       -> c03_center
             -> c03_trilinear         (Er, Ea, Ez, Br, Ba, Bz)

   .. rubric:: What the Caller Prepares

   The particle must lie in the owned grid range and grid fields must already be
   available. Near boundaries, interpolation can require values one layer outside
   that range. These extra neighboring values are called ghost-cell data and must
   be supplied before the call.

   C03 reads fields and returns fields at the particle without updating its position
   or velocity. Outputs remain cylindrical components. The table describes the
   electrostatic E and prescribed nodal B layout required by these routines.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Baisheng WANG · Harbin Institute of Technology</p>
      </div>

.. toctree::
   :maxdepth: 1
   :hidden:

   C03_gather_3Draz_nonuniform/mod_C03_gather_3Draz_nonuniform
   C03_gather_3Draz_nonuniform/sub_C03_gather_3Draz_nonuniform
   C03_gather_3Draz_nonuniform/sub_C03_gather_3Draz_nonuniform_point
   C03_gather_3Draz_nonuniform/sub_C03_gather_helpers
