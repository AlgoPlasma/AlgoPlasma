===================
B01_scatter_3Dxyz
===================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块说明

   ``B01_scatter_3Dxyz`` 提供直角坐标三维网格上的基础粒子沉积例程。
   粒子位置使用网格单位，粒子数组采用 ``par(1:6,p)`` 约定：
   ``par(1:3,p)`` 为 ``x,y,z`` 位置，``par(4:6,p)`` 可存放速度或其他待沉积物理量。

   .. list-table:: 文件与职责
      :header-rows: 1

      * - 文件
        - 作用
      * - :doc:`mod_B01_scatter_3Dxyz.f90 <B01_scatter_3Dxyz/mod_B01_scatter_3Dxyz>`
        - 模块入口，通过源文件 ``include`` 导出 B01 的核心沉积例程。
      * - :doc:`sub_B01_scatter_3Dxyz.f90 <B01_scatter_3Dxyz/sub_B01_scatter_3Dxyz>`
        - 将每个粒子的单位权重按 CIC 权重沉积到八个相邻节点，最后整体乘以 ``w``。
      * - :doc:`sub_B01_scatter_3Dxyz_v.f90 <B01_scatter_3Dxyz/sub_B01_scatter_3Dxyz_v>`
        - 将 ``par(d,p)`` 按 CIC 权重沉积到网格，并在末尾乘以粒子权重 ``w``。
      * - :doc:`sub_B01_scatter_3Dxyz_T.f90 <B01_scatter_3Dxyz/sub_B01_scatter_3Dxyz_T>`
        - 使用两遍 NGP 统计每个单元内 ``par(d,p)`` 的方差。

   .. rubric:: 公共接口

   .. list-table::
      :header-rows: 1
      :widths: 34 18 44

      * - 接口
        - 沉积方式
        - 输出
      * - ``sub_B01_scatter_3Dxyz(il,iu,den,np,par,w)``
        - CIC
        - ``den(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1)``
      * - ``sub_B01_scatter_3Dxyz_v(il,iu,den,np,par,w,d)``
        - CIC
        - 同上，沉积 ``par(d,p)``。
      * - ``sub_B01_scatter_3Dxyz_T(il,iu,T,np,par,d)``
        - NGP 统计
        - ``T(il(1):iu(1), il(2):iu(2), il(3):iu(3))``。

   调用者负责在沉积前清零输出数组，并保证粒子位置不会越过输出数组可用的
   ghost-cell 范围。

   .. rubric:: CIC 权重

   对粒子位置 :math:`(x_p,y_p,z_p)`，参考节点为

   .. math::

      i=\lfloor x_p\rfloor,\qquad
      j=\lfloor y_p\rfloor,\qquad
      k=\lfloor z_p\rfloor .

   局部偏移为

   .. math::

      f_i=x_p-i,\qquad f_j=y_p-j,\qquad f_k=z_p-k .

   对节点 :math:`(i+\delta_i,j+\delta_j,k+\delta_k)`，
   :math:`\delta_i,\delta_j,\delta_k\in\{0,1\}`，CIC 权重为

   .. math::

      W_{\delta_i\delta_j\delta_k}
      = w_i(\delta_i)w_j(\delta_j)w_k(\delta_k),
      \qquad
      w_i(0)=1-f_i,\quad w_i(1)=f_i ,

   ``y`` 和 ``z`` 方向同理。八个权重之和为 1，因此单粒子的沉积量在网格上守恒。

   .. figure:: /_static/B_Scatter/cic_schematic.png
      :width: 60%
      :align: center

      CIC 权重在固定 ``k`` 平面内的二维示意图。

   .. rubric:: NGP 方差统计

   ``sub_B01_scatter_3Dxyz_T`` 把粒子分配到唯一单元
   :math:`(\lfloor x_p\rfloor+1,\lfloor y_p\rfloor+1,\lfloor z_p\rfloor+1)`。
   第一遍统计单元平均值，第二遍统计平方偏差：

   .. math::

      T_{i,j,k}
      =
      \frac{1}{N_{i,j,k}}
      \sum_{p\in C_{i,j,k}}
      \left(q_p-\bar q_{i,j,k}\right)^2 .

   这里 :math:`q_p` 是 ``par(d,p)``。该例程只返回方差；若需要温度单位，
   质量、Boltzmann 常数或其他归一化由调用者处理。

   .. rubric:: MPI 与边界

   沉积完成后的 MPI 边界同步由 :doc:`H03_mpi_exchange_den </rst_files/H_MPI_Exchange/H03_mpi_exchange_den>`
   负责。H03 先在未进行 MPI 切分且周期的方向做本地折叠，再把相邻 rank 的边界节点贡献
   累加到本地密度数组（与场量交换 H01 的覆盖语义不同）。

   .. rubric:: 测试

   相关测试位于 ``tests/004_scatter``，包含单粒子、多粒子和统计量沉积案例。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/04/06; 2026/04/16) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Description

   ``B01_scatter_3Dxyz`` provides basic particle deposition routines on a
   three-dimensional Cartesian grid. Particle positions are stored in grid
   units. The particle array follows the convention ``par(1:6,p)``:
   ``par(1:3,p)`` are ``x,y,z`` positions, while ``par(4:6,p)`` may store
   velocities or other deposited quantities.

   .. list-table:: Files And Roles
      :header-rows: 1

      * - File
        - Role
      * - :doc:`mod_B01_scatter_3Dxyz.f90 <B01_scatter_3Dxyz/mod_B01_scatter_3Dxyz>`
        - Module entry point that exports the B01 core deposition routine
          through source-level ``include``.
      * - :doc:`sub_B01_scatter_3Dxyz.f90 <B01_scatter_3Dxyz/sub_B01_scatter_3Dxyz>`
        - Deposits unit particle weight to the eight neighboring nodes with
          CIC weights, then scales the whole array by ``w``.
      * - :doc:`sub_B01_scatter_3Dxyz_v.f90 <B01_scatter_3Dxyz/sub_B01_scatter_3Dxyz_v>`
        - Deposits ``par(d,p)`` with CIC weights and scales the result by
          particle weight ``w``.
      * - :doc:`sub_B01_scatter_3Dxyz_T.f90 <B01_scatter_3Dxyz/sub_B01_scatter_3Dxyz_T>`
        - Computes per-cell variance of ``par(d,p)`` with a two-pass NGP
          assignment.

   .. rubric:: Public Interfaces

   .. list-table::
      :header-rows: 1
      :widths: 34 18 44

      * - Interface
        - Scheme
        - Output
      * - ``sub_B01_scatter_3Dxyz(il,iu,den,np,par,w)``
        - CIC
        - ``den(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1)``
      * - ``sub_B01_scatter_3Dxyz_v(il,iu,den,np,par,w,d)``
        - CIC
        - Same layout, depositing ``par(d,p)``.
      * - ``sub_B01_scatter_3Dxyz_T(il,iu,T,np,par,d)``
        - NGP statistics
        - ``T(il(1):iu(1), il(2):iu(2), il(3):iu(3))``.

   The caller is responsible for zeroing output arrays before deposition and
   for keeping particle positions inside the available owned-plus-ghost-cell
   range.

   .. rubric:: CIC Weights

   For a particle at :math:`(x_p,y_p,z_p)`, the reference node is

   .. math::

      i=\lfloor x_p\rfloor,\qquad
      j=\lfloor y_p\rfloor,\qquad
      k=\lfloor z_p\rfloor .

   The local offsets are

   .. math::

      f_i=x_p-i,\qquad f_j=y_p-j,\qquad f_k=z_p-k .

   For node :math:`(i+\delta_i,j+\delta_j,k+\delta_k)`, with
   :math:`\delta_i,\delta_j,\delta_k\in\{0,1\}`, the CIC weight is

   .. math::

      W_{\delta_i\delta_j\delta_k}
      = w_i(\delta_i)w_j(\delta_j)w_k(\delta_k),
      \qquad
      w_i(0)=1-f_i,\quad w_i(1)=f_i ,

   with analogous factors in ``y`` and ``z``. The eight weights sum to one, so
   each single-particle contribution is conserved on the grid.

   .. figure:: /_static/B_Scatter/cic_schematic.png
      :width: 60%
      :align: center

      CIC weighting in a fixed-``k`` two-dimensional cross-section.

   .. rubric:: NGP Variance Statistics

   ``sub_B01_scatter_3Dxyz_T`` assigns a particle to the unique cell
   :math:`(\lfloor x_p\rfloor+1,\lfloor y_p\rfloor+1,\lfloor z_p\rfloor+1)`.
   The first pass computes the cell mean and the second pass computes squared
   deviations:

   .. math::

      T_{i,j,k}
      =
      \frac{1}{N_{i,j,k}}
      \sum_{p\in C_{i,j,k}}
      \left(q_p-\bar q_{i,j,k}\right)^2 .

   Here :math:`q_p` is ``par(d,p)``. The routine returns variance only; mass,
   Boltzmann factors, or other temperature normalization are left to the
   caller.

   .. rubric:: MPI And Boundaries

   Post-scatter MPI boundary synchronization is handled by
   :doc:`H03_mpi_exchange_den </rst_files/H_MPI_Exchange/H03_mpi_exchange_den>`.
   H03 first folds periodic endpoint contributions locally in non-split
   dimensions, then **accumulates** neighboring-rank boundary-node contributions
   into the local density array (unlike H01 field exchange, which overwrites).

   .. rubric:: Tests

   Related tests live in ``tests/004_scatter`` and cover single-particle,
   multi-particle, and statistical deposition cases.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/04/06; 2026/04/16) · Harbin Institute of Technology</p>
      </div>

.. toctree::
    :maxdepth: 1
    :hidden:

    B01_scatter_3Dxyz/mod_B01_scatter_3Dxyz
    B01_scatter_3Dxyz/sub_B01_scatter_3Dxyz
    B01_scatter_3Dxyz/sub_B01_scatter_3Dxyz_v
    B01_scatter_3Dxyz/sub_B01_scatter_3Dxyz_T
