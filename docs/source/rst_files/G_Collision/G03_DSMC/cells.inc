.. _id45:

.. _g03-s08:

.. _g03-cells:

Nonuniform Three-Dimensional Cylindrical Collision Cells
------------------------------------------------------------------------

.. container:: ap-lang ap-lang-zh

   本节对应 ``cylindrical.hpp`` 和 ``fun_G03_dsmc_cylindrical.cpp``。
   这里将体积积分、速度旋转、面区间查询与单元编号逐一对应到实际源码。
   当前实现是固定拓扑的三维 :math:`(r,\theta,z)` 网格，保留角向分辨率。
   本节 :math:`\theta` 表示位置的方位角。

.. container:: ap-lang ap-lang-en

   This section follows ``cylindrical.hpp`` and ``fun_G03_dsmc_cylindrical.cpp`` from volume
   integration and velocity rotation to interval queries and cell numbering. The implementation is
   a fixed-topology three-dimensional :math:`(r,\theta,z)` grid with angular resolution.
   Here :math:`\theta` is the spatial azimuth.

How Volume Integration Enters the Collision Rate
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   Boltzmann 碰撞是局部过程。DSMC 把单元内粒子当作局部分布的样本，
   某一模拟粒子对的目标事件率为 :math:`\lambda_{ij}=WK(g_{ij})/V`。
   分母 :math:`V` 是该碰撞单元的物理体积，由所选坐标系的体积元积分得到。

.. container:: ap-lang ap-lang-en

   Boltzmann collisions are local. DSMC represents the local distribution with the cell's
   samples and assigns pair rate :math:`\lambda_{ij}=WK(g_{ij})/V`.
   The denominator is that collision cell's physical volume, obtained by integrating the coordinate
   volume element.

.. container:: ap-lang ap-lang-zh

   柱坐标体积元是 :math:`dV=r\,dr\,d\theta\,dz`。对三个面数组定义的单元积分：

.. container:: ap-lang ap-lang-en

   The cylindrical volume element is :math:`dV=r\,dr\,d\theta\,dz`.
   Integration between the three pairs of cell faces gives

.. math::
   :label: g03-eq-cyl-volume

   V_{ijk}=\frac{r_{i+1}^2-r_i^2}{2}
           (\theta_{j+1}-\theta_j)(z_{k+1}-z_k).

.. container:: ap-lang ap-lang-zh

   :math:`r,z` 用 m，:math:`\theta` 用 rad，体积用 m³。
   若 :math:`r_c=(r_i+r_{i+1})/2`，表达式 :math:`r_c\Delta r\Delta\theta\Delta z`
   与上式完全等价。实现采用精确的径向面积差，直接把包含 Jacobian 的体积传给碰撞核。

.. container:: ap-lang ap-lang-en

   :math:`r,z` are in m, :math:`\theta` in rad and volume in m³. With
   :math:`r_c=(r_i+r_{i+1})/2`, :math:`r_c\Delta r\Delta\theta\Delta z` is exactly equivalent.
   The implementation passes the integrated volume, including the Jacobian, directly to the collision kernel.

.. container:: ap-lang ap-lang-zh

   在构造函数的三重循环中，``ir,it,iz`` 分别是三个方向的区间索引。
   ``radial_area`` 对应 :math:`(r_{i+1}^2-r_i^2)/2`，
   ``dtheta`` 与 ``dz`` 对应角宽和轴向宽度，``exact_volume`` 对应 :math:`V_{ijk}`。
   为减少相近半径平方相减的消减，实现将径向部分写为差与和的乘积，并使用扩展精度：

.. container:: ap-lang ap-lang-en

   In the constructor's three nested loops, ``ir,it,iz`` are interval indices.
   ``radial_area`` is :math:`(r_{i+1}^2-r_i^2)/2`, ``dtheta`` and ``dz`` are angular and axial
   widths, and ``exact_volume`` is :math:`V_{ijk}`. The radial factor is evaluated as a product
   of a difference and a sum in extended precision to reduce cancellation between nearby squared radii:

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_cylindrical.cpp
   :language: cpp
   :caption: fun_G03_dsmc_cylindrical.cpp · CylindricalGrid — per-cell volume integration
   :linenos:
   :lineno-match:
   :start-at: for (std::size_t ir =
   :end-before: if (!(exact_volume > 0)

.. container:: ap-lang ap-lang-zh

   随后检查体积有限、为正且可由 ``Real`` 表示，再把单元 ID 与体积存入 ``cells_``。
   碰撞内核读取 ``CollisionCell::volume_m3``，把它作为候选期望公式中的分母。

.. container:: ap-lang ap-lang-en

   The constructor checks that volume is finite, positive and representable by ``Real``, then
   stores cell ID and volume in ``cells_``. The collision kernel reads ``CollisionCell::volume_m3``
   as the denominator of its candidate expectation.

.. container:: ap-lang ap-lang-zh

   例如 :math:`[0,a]` 与 :math:`[a,2a]` 两个径向区间在相同角宽、轴向长度下体积比为 1:3。
   均匀数密度且统一权重时，平均模拟粒子数也为 1:3。
   第一层从轴线开始时，只要径向宽度、角宽和轴向长度均为正，体积就为正。

.. container:: ap-lang ap-lang-en

   For radial intervals :math:`[0,a]` and :math:`[a,2a]` with equal angular and axial extents,
   volumes have ratio 1:3. Uniform number density and equal weights therefore give the same ratio
   of mean simulation-particle counts. A layer starting at the axis still has positive volume
   when all three widths are positive.

.. container:: ap-lang ap-lang-zh

   碰撞内核只读取两个几何量：

.. container:: ap-lang ap-lang-en

   The collision kernel reads only the following two cell-geometry quantities:

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/cylindrical.hpp
   :language: cpp
   :caption: cylindrical.hpp · CollisionCell — stable ID and physical volume
   :linenos:
   :lineno-match:
   :start-at: struct CollisionCell
   :end-before: struct CylindricalPosition

Expressing Velocities in a Common Basis
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   局部正交基 :math:`\mathbf e_r(\theta),\mathbf e_\theta(\theta),\mathbf e_z`
   随粒子的方位角变化。坐标变换为

.. container:: ap-lang ap-lang-en

   The local orthonormal basis :math:`\mathbf e_r(\theta),\mathbf e_\theta(\theta),\mathbf e_z`
   rotates with the particle's azimuth. Its transformation to the common Cartesian basis is

.. math::
   :label: g03-eq-cyl-velocity

   \begin{pmatrix}v_x\\v_y\\v_z\end{pmatrix}
   =\begin{pmatrix}\cos\theta&-\sin\theta&0\\
                    \sin\theta& \cos\theta&0\\0&0&1\end{pmatrix}
    \begin{pmatrix}v_r\\v_\theta\\v_z\end{pmatrix}.

.. container:: ap-lang ap-lang-zh

   这里 :math:`v_\theta=r\dot\theta` 是切向线速度，单位为 :math:`\mathrm{m/s}`。
   该矩阵正交，反变换等于转置，所以保持 :math:`|\mathbf v|^2`。
   不同 :math:`\theta` 对应不同矩阵，因此先转换到全局基底，再计算相对速度。

.. container:: ap-lang ap-lang-en

   :math:`v_\theta=r\dot\theta` is tangential linear speed in :math:`\mathrm{m/s}`.
   The matrix is orthogonal, so its inverse is its transpose and :math:`|\mathbf v|^2` is preserved.
   Particles at different azimuths use different matrices; transform each velocity to the common
   basis before taking a relative velocity.

.. container:: ap-lang ap-lang-zh

   正向与反向转换直接按这个矩阵及其转置实现。
   ``vr_mps,vtheta_mps,vz_mps`` 为局部分量，``theta_rad`` 决定对应的局部基底。

.. container:: ap-lang ap-lang-en

   Forward and inverse conversions implement this matrix and its transpose directly.
   ``vr_mps,vtheta_mps,vz_mps`` are local components; ``theta_rad`` identifies their local basis.

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_cylindrical.cpp
   :language: cpp
   :caption: fun_G03_dsmc_cylindrical.cpp · to_cartesian_velocity / to_cylindrical_velocity
   :linenos:
   :lineno-match:
   :start-at: Vec3 to_cartesian_velocity
   :end-before: CylindricalGrid::CylindricalGrid

.. container:: ap-lang ap-lang-zh

   两个粒子在 :math:`\theta=0,\pi/2`，局部速度均为 :math:`(1,0,0)\,\mathrm{m/s}` 时，
   全局速度分别为 :math:`(1,0,0)` 和 :math:`(0,1,0)`，相对速率为 :math:`\sqrt2\,\mathrm{m/s}`。
   ``snapshot_particles`` 在创建碰撞快照时执行正向转换，
   ``prepare_particle_velocities`` 在准备写回时执行反向转换；Source Guide 展开这条调用链。
   转换后 HS/VHS/VSS 都使用共同正交基下的相对速度。

.. container:: ap-lang ap-lang-en

   Two particles at :math:`\theta=0,\pi/2`, each with local velocity
   :math:`(1,0,0)\,\mathrm{m/s}`, have Cartesian velocities :math:`(1,0,0)` and :math:`(0,1,0)`.
   Their relative speed is :math:`\sqrt2\,\mathrm{m/s}`. ``snapshot_particles`` performs the forward
   conversion; ``prepare_particle_velocities`` prepares the inverse conversion for commit.
   Source Guide follows this call chain. All HS/VHS/VSS relative speeds use the common orthonormal basis.

Locality and Angular-Momentum Error in Finite Cells
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   小扇形单元的物理尺度约为
   :math:`\Delta r,r\Delta\theta,\Delta z`，应能分辨局部平均自由程与流场变化尺度。
   固定权重下，数密度为 :math:`n` 的单元平均有 :math:`\mathbb E[N]=nV/W` 个样本；
   轴附近过小的体积可能导致样本不足。
   应通过协调网格和粒子预算满足采样需求。改变单元间权重时，需要相应的非等权重碰撞算法。

.. container:: ap-lang ap-lang-en

   A small sector cell has physical dimensions approximately
   :math:`\Delta r,r\Delta\theta,\Delta z`, which must resolve the local mean free path and field variations.
   With fixed weight, a cell at density :math:`n` has mean count :math:`\mathbb E[N]=nV/W`.
   Very small near-axis volumes can be undersampled, so coordinate refinement and particle budget
   must be chosen together. Spatially varying weights require an unequal-weight collision algorithm.

.. container:: ap-lang ap-lang-zh

   标准有限单元随机配对保持二体线动量和动能。
   令 :math:`\mathbf p_i=Wm\mathbf v_i` 为样本代表的动量。
   不同位置粒子交换动量时，:math:`\Delta\mathbf p_2=-\Delta\mathbf p_1`，
   这一对样本的总角动量改变量为

.. container:: ap-lang ap-lang-en

   Ordinary finite-cell random pairing conserves pair linear momentum and kinetic energy.
   Let :math:`\mathbf p_i=Wm\mathbf v_i` be represented momentum. If two particles at different
   positions exchange :math:`\Delta\mathbf p_2=-\Delta\mathbf p_1`, their total angular-momentum
   change is

.. math::
   :label: g03-eq-angular-momentum-error

   \Delta\mathbf L=(\mathbf x_1-\mathbf x_2)\times\Delta\mathbf p_1

.. container:: ap-lang ap-lang-zh

   一般不为零，形成有限单元配对的角动量离散误差。
   旋转流中应随单元尺寸细化检查这一误差。

.. container:: ap-lang ap-lang-en

   This is generally nonzero and is an angular-momentum discretization error of finite-cell
   pairing. Rotating-flow calculations should check it under cell refinement.

From Face Arrays to Cell IDs and Membership
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. container:: ap-lang ap-lang-zh

   构造 ``CylindricalGrid`` 时复制三组面坐标并生成单元表。每轴至少有两个有限、严格递增的值，
   径向面非负，角跨度不超过一整圈。体积和 ID 不可表示时明确失败。

.. container:: ap-lang ap-lang-en

   ``CylindricalGrid`` copies the three face-coordinate arrays and builds the cell table.
   Each axis requires at least two finite, strictly increasing faces. Radial faces are nonnegative,
   and angular extent is at most one revolution. Unrepresentable volumes or IDs are reported as errors.

.. container:: ap-lang ap-lang-zh

   设三个方向分别有 :math:`N_r,N_\theta,N_z` 个单元，零起始索引的编号为

.. container:: ap-lang ap-lang-en

   For :math:`N_r,N_\theta,N_z` intervals, the zero-based index is flattened as

.. math::
   :label: g03-eq-cyl-id

   \mathrm{ID}=\mathrm{first\_cell\_id}+(iN_\theta+j)N_z+k.

.. container:: ap-lang ap-lang-zh

   轴向索引变化最快。拓扑不变时 ID 稳定，可作为“随机抽样与可复现性”中的单元键。
   ``step`` 从同一个 ``CylindricalGrid`` 取得粒子归属和单元表，因而单元 ID 与体积始终对应。

.. container:: ap-lang ap-lang-en

   The axial index varies fastest. IDs remain stable for a fixed topology and serve as cell
   keys in Random Sampling. ``step`` obtains membership and the cell table from the same grid,
   so each ID stays paired with its own volume.

.. container:: ap-lang ap-lang-zh

   ``locate`` 找到三个方向的区间索引后，按该公式返回 ID：

.. container:: ap-lang ap-lang-en

   After finding the three interval indices, ``locate`` returns the flattened ID:

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_cylindrical.cpp
   :language: cpp
   :caption: fun_G03_dsmc_cylindrical.cpp · CylindricalGrid::locate — flattened cell indexing
   :linenos:
   :lineno-match:
   :start-at: const auto index =
   :end-before: } // namespace

.. container:: ap-lang ap-lang-zh

   定位对各面数组执行有序区间查询，约定如下：

.. container:: ap-lang ap-lang-en

   Location uses ordered interval searches with the following conventions:

.. container:: ap-lang ap-lang-zh

   * 所有单元使用左闭右开的区间；内部面归其右侧单元。
   * 径向、轴向最大面以及非周期角向最大面不属于网格，``locate`` 返回 ``nullopt``。
   * ``AngularBoundary::periodic`` 必须显式选择，且角跨度须为完整 :math:`2\pi`
     （允许浮点舍入误差）。它按存储跨度归约角度，最大角面映到首个角单元。
   * ``nonperiodic`` 表示角向扇区，直接按传入角度查找单元；物理壁面由调用程序处理。
   * 域外返回空结果；NaN、无穷值或负半径属于非法输入，抛出 ``Error``。
   * :math:`r=0` 时保留调用方传入的 :math:`\theta`，用于确定角单元和局部速度基底。
     调用程序须保持该约定一致，不能在速度转换前任意重设方位角。

.. container:: ap-lang ap-lang-en

   * Every interval is closed on its lower face and open on its upper face; an internal face belongs to the cell on its higher-coordinate side.
   * The largest radial and axial faces, and the largest nonperiodic angular face, are outside the grid; ``locate`` returns ``nullopt``.
   * ``AngularBoundary::periodic`` is explicit and requires a complete :math:`2\pi` extent, allowing roundoff. Angles are reduced by the stored period, and the upper angular face maps to the first angular cell.
   * ``nonperiodic`` describes a sector and searches the supplied azimuth directly. The calling program handles physical walls.
   * An out-of-domain point returns no cell. NaN, infinity or a negative radius is invalid input and throws ``Error``.
   * At :math:`r=0`, the supplied :math:`\theta` is retained to identify the angular cell and local velocity basis. The calling program must use this convention consistently when converting velocities.

.. container:: ap-lang ap-lang-zh

   当前网格描述有角向分辨率的三维全周或扇区几何。
   轴对称 DSMC 还需利用旋转对称性设计速度映射与局部配对，属于另一种离散方式。

.. container:: ap-lang ap-lang-en

   This grid resolves all three coordinates in a complete cylinder or a sector.
   Axisymmetric DSMC needs its own symmetry-based velocity mapping and pairing discretization.

Why Interval Search Uses upper_bound
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. container:: ap-lang ap-lang-zh

   给定面坐标 :math:`a_0\lt a_1\lt\cdots\lt a_n`，``upper_bound`` 返回第一个严格大于位置的面。
   减去一个索引后即为左端面编号，因而内部分界面自动归入右侧单元。
   查询前单独排除 :math:`x\lt a_0` 或 :math:`x\ge a_n`，实现左闭右开的整个网格约定。

.. container:: ap-lang ap-lang-en

   For faces :math:`a_0\lt a_1\lt\cdots\lt a_n`, ``upper_bound`` finds the first face strictly
   above the position. Subtracting one gives the lower-face index and assigns internal faces to
   the higher-coordinate cell. Excluding :math:`x\lt a_0` and :math:`x\ge a_n` before the query
   implements the grid's half-open domain.

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_cylindrical.cpp
   :language: cpp
   :caption: fun_G03_dsmc_cylindrical.cpp · interval — half-open interval search
   :linenos:
   :lineno-match:
   :start-at: std::optional<std::size_t> interval
   :end-before: void validate_velocity

.. container:: ap-lang ap-lang-zh

   周期角度先按实际存储的整圈跨度取模。下面的分支还处理了一个浮点边界情况：
   负的微小角偏移在加上一整圈后可能舍入为恰好一整圈；
   ``nextafter(period, 0.0L)`` 保持它仍属于末端单元。
   随后直接比较相对面坐标，减少角度重新转换为 ``Real`` 时在接缝处的舍入歧义。

.. container:: ap-lang ap-lang-en

   Periodic angles are reduced by the stored full-revolution span. A tiny negative offset
   can round to exactly one period after adding that period; ``nextafter(period, 0.0L)`` keeps
   it inside the final cell. Comparing relative face coordinates directly then reduces seam
   ambiguity from converting the azimuth back to ``Real``.

.. literalinclude:: ../../../../../G_Collision/G03_DSMC/fun_G03_dsmc_cylindrical.cpp
   :language: cpp
   :caption: fun_G03_dsmc_cylindrical.cpp · CylindricalGrid::locate — full-revolution angle reduction
   :linenos:
   :lineno-match:
   :start-at: const auto theta =
   :end-before: if (!it)

.. container:: ap-lang ap-lang-zh

   ``CylindricalGrid`` 在构造时持有面数组和单元表；``cells()`` 返回只读视图。
   调用程序提供面坐标数组，网格在构造时一次完成体积、编号和有效性检查。
   完整的网格构造、粒子装配和调用示例由算例页面组织。

.. container:: ap-lang ap-lang-en

   ``CylindricalGrid`` owns its face arrays and cell table; ``cells()`` exposes a read-only view.
   The calling program supplies face coordinates, and construction performs volume, numbering
   and validity checks once. Example pages organize complete grid and particle setup.

.. container:: ap-lang ap-lang-zh

   本模块的检查方法与判据见 :ref:`测试说明 <g03-validation-cells>`。

.. container:: ap-lang ap-lang-en

   Checks and acceptance criteria are given in :ref:`the test documentation <g03-validation-cells>`.
