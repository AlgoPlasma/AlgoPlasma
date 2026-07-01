B_Scatter
=========

.. toctree::
    :maxdepth: 1

    B_Scatter/scatter_learning_path
    B_Scatter/scatter_usage_cookbook
    B_Scatter/scatter_testing_guide
    B_Scatter/B01_scatter_3Dxyz
    B_Scatter/B02_deposit_3d_cyl
    B_Scatter/B03_scatter_3Dxyz_bspline

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 概览

   ``B_Scatter`` 收纳 PIC 中从粒子到网格的沉积算子。它把粒子位置、权重、电荷、电流或统计量投影到离散网格，
   使 Poisson、Maxwell 或流体求解器可以使用网格量继续推进。

   .. list-table:: B_Scatter 模块
      :header-rows: 1
      :widths: 10 26 22 28 34

      * - ID
        - 模块
        - 坐标系
        - 沉积量
        - 典型用途
      * - B01
        - :doc:`B01_scatter_3Dxyz <B_Scatter/B01_scatter_3Dxyz>`
        - 3D Cartesian / ``xyz``
        - 数密度、动量密度、方差类统计量
        - 用 CIC 或 NGP 风格权重把已有粒子数组 ``par(1:6,np)`` 沉积到直角网格。
      * - B02
        - :doc:`B02_deposit_3d_cyl <B_Scatter/B02_deposit_3d_cyl>`
        - 3D cylindrical / ``r,phi,z``
        - 电荷密度和三分量电流密度
        - 处理柱坐标几何、径向 Jacobian、轴线退化和守恒电流沉积。
      * - B03
        - :doc:`B03_scatter_3Dxyz_bspline <B_Scatter/B03_scatter_3Dxyz_bspline>`
        - 3D Cartesian / ``xyz``
        - 任意阶 B-spline 粒子数和粒子分量
        - 使用 centered B-spline 张量积权重，把粒子数或 ``par(d,p)`` 沉积到直角网格。

   .. rubric:: 在 PIC 循环中的位置

   scatter 是 gather 的伴随环节：gather 把网格场插值到粒子位置，scatter 则把粒子的电荷、电流或统计量写回网格。
   沉积权重、网格位置和边界交换必须与 gather 和 field solver 保持一致，否则完整 PIC 循环可能出现电荷不守恒、
   边界重复计数或能量误差增长。

   .. rubric:: 编译与精度

   源码使用默认 ``real`` 精度；需要双精度默认实数时，应在主程序、模块和测试中使用一致的编译选项，
   例如 ``-fdefault-real-8`` 或 ``-real-size 64``。包含 ``#include`` 的模块入口和 MPI 交换例程通常还需要启用预处理，例如 ``-cpp`` 或 ``-fpp``。

.. container:: ap-lang ap-lang-en

   .. rubric:: Overview

   ``B_Scatter`` collects particle-to-grid deposition operators for PIC
   workflows. These routines project particle positions, weights, charge,
   current, or statistical quantities onto discrete grids so Poisson, Maxwell,
   or fluid solvers can advance grid-based fields.

   .. list-table:: B_Scatter Modules
      :header-rows: 1
      :widths: 10 26 22 28 34

      * - ID
        - Module
        - Coordinates
        - Deposited quantity
        - Typical use
      * - B01
        - :doc:`B01_scatter_3Dxyz <B_Scatter/B01_scatter_3Dxyz>`
        - 3D Cartesian / ``xyz``
        - Number density, momentum density, variance-like statistics
        - Deposit an existing particle array ``par(1:6,np)`` to a Cartesian grid with CIC or NGP-style weighting.
      * - B02
        - :doc:`B02_deposit_3d_cyl <B_Scatter/B02_deposit_3d_cyl>`
        - 3D cylindrical / ``r,phi,z``
        - Charge density and three current-density components
        - Handle cylindrical geometry, radial Jacobian factors, axis degeneracy, and conservative current deposition.
      * - B03
        - :doc:`B03_scatter_3Dxyz_bspline <B_Scatter/B03_scatter_3Dxyz_bspline>`
        - 3D Cartesian / ``xyz``
        - Arbitrary-order B-spline particle number and particle components
        - Deposit particle number or ``par(d,p)`` to a Cartesian grid with centered B-spline tensor-product weights.

   .. rubric:: Role in the PIC Cycle

   Deposition is the counterpart of gather: gather interpolates electromagnetic
   fields from the grid to particle positions, while scatter writes particle
   charge, current, or statistics back to the grid. Deposition weights, grid
   locations, and boundary exchange must remain consistent with gather and the
   field solver to avoid charge-conservation errors, boundary double counting,
   or growing energy error.

   .. rubric:: Compilation and Precision

   The Fortran sources use default ``real`` declarations. For double-precision
   default reals, compile the main program, modules, and related tests with a
   consistent option such as ``-fdefault-real-8`` or ``-real-size 64``. Module
   entry files and MPI exchange routines using ``#include`` normally require
   preprocessing, for example ``-cpp`` or ``-fpp``.
