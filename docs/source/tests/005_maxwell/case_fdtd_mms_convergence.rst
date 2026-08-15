case_fdtd_mms_convergence
=========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   ``case_fdtd_mms_convergence`` 用 manufactured solution 验证 E01/E02/E03 核心 FDTD
   内核是否在网格加密时达到接近二阶的误差收敛。MMS 中的源项是为了维持解析解而构造的，
   不是物理天线或电流源。

   .. rubric:: 覆盖子程序

   - ``mod_E01_fdtd_2d_rz_tez`` 和 ``mod_E01_fdtd_2d_rz_tmz``。
   - ``mod_E02_fdtd_3d_cylindrical``，覆盖 ``m=0`` 和带 ``phi`` 变化的 ``m=1``。
   - ``mod_E03_fdtd_3d_cartesian``。

   .. rubric:: 文件说明

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 文件
        - 作用
      * - ``test_mms_*_convergence.f90``
        - 五个主收敛测试，对不同几何和模式跑三套分辨率。
      * - ``mms_exact_sources.f90``
        - 解析场、解析源项和各分量采样位置。
      * - ``mms_convergence_utils.f90``
        - 误差范数、收敛阶和 PASS/FAIL 汇总。
      * - ``visualize_mms_*.py``
        - 可选后处理脚本，用于画误差或数值/解析对比图。

   .. rubric:: 运行方式

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_fdtd_mms_convergence
      bash run.sh

   .. note::

      这是 005 Maxwell 中较重的全量 MMS 收敛验证。当前开发机上一次完整运行约 ``15`` 分钟，
      主要耗时来自 ``3D Cartesian``、``3D cylindrical m=0`` 和 ``3D cylindrical m=1``。
      程序运行时会打印类似 ``progress 100/4000 steps`` 的进度行；如果这些数字仍在增长，
      说明细网格层还在正常推进。

   .. rubric:: 主流程

   1. 对每个几何选择三套网格，并保持相同物理终止时间和 CFL 比例。
   2. 用 ``mms_exact_sources.f90`` 初始化 staggered 位置上的解析场。
   3. 每步调用生产 FDTD ``H`` 更新，再注入对应 MMS 磁场源项。
   4. 调用生产 FDTD ``E`` 更新，再注入对应 MMS 电场源项。
   5. 在更新区间的原生 Yee 位置计算 ``L2``、``Linf`` 和轴线带误差。
   6. 用三套分辨率的误差估计 observed order。

   .. rubric:: 典型例子：3D Cartesian MMS 收敛

   ``test_mms_3d_cartesian_convergence.f90`` 是最标准的 MMS 例子。它使用三套网格
   ``16^3``、``32^3``、``64^3``，每套网格根据 CFL 重新计算 ``dt``，并保持相同物理终止时间。
   这样比较误差时，网格间距和时间步长一起减半，二阶空间/时间离散的主误差应接近四倍下降。

   .. code-block:: fortran

      integer, parameter :: nx_list(nlev) = (/16, 32, 64/)

      dt_levels(ilev) = compute_dt(nx_list(ilev),ny_list(ilev),nz_list(ilev),c0)
      call run_level(nx_list(ilev),ny_list(ilev),nz_list(ilev), &
          dt_levels(ilev),nsteps(ilev),omega, ...)

   在每个 ``run_level`` 中，生产 FDTD 内核只负责 Maxwell curl 更新；MMS 源项由测试文件随后加入，
   用来让离散解追踪预设解析解。最后 ``compute_errors`` 在 Yee 原生采样位置比较数值场和解析场，
   ``observed_order`` 再用相邻两级误差给出收敛阶。

   .. code-block:: fortran

      call sub_E03_fdtd_3d_cartesian_H(..., Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu)
      call add_h_source(nx,ny,nz,dx,dy,dz,dt,t_n,omega0,Hx,Hy,Hz)

      call sub_E03_fdtd_3d_cartesian_E(..., Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,ep)
      call add_e_source(nx,ny,nz,dx,dy,dz,dt,t_n+0.5*dt,omega0,Ex,Ey,Ez)

      call compute_errors(..., Ex,Ey,Ez,Hx,Hy,Hz, l2c, linfc, ...)

   .. rubric:: 重点调用方式

   .. code-block:: text

      call sub_*_H(...)
      call add_h_source(..., t_n, ...)
      call sub_*_E(...)
      call add_e_source(..., t_n + 0.5*dt, ...)
      call compute_error_against_mms_exact(...)

   .. rubric:: 结果判断

   代码内置判据：``L2`` observed order 至少 ``1.8``，``Linf`` observed order 至少 ``1.5``。
   当前五个 case 均为 ``PASS``；典型摘要：

   .. code-block:: text

      3D Cartesian periodic MMS: L2 orders 2.017, 2.009, result PASS
      2D RZ TMz MMS:             L2 orders 2.014, 2.007, result PASS
      3D cylindrical m=0 MMS:    L2 orders 2.015, 2.007, result PASS
      2D RZ TEz MMS:             L2 orders 2.016, 2.008, result PASS
      3D cylindrical m=1 MMS:    L2 orders 2.019, 1.998, result PASS

   .. rubric:: 常见误读

   MMS 检查的是离散算子和源项采样的一致性；它不代表自由空间波包传播，也不测试 CPML。
   对 RZ/cylindrical，误差范数带有 ``r`` 权重，轴线附近还会单独报告 ``axis_band_Linf``。

   .. include:: _contributors_zh.inc

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   ``case_fdtd_mms_convergence`` uses manufactured solutions to verify that the
   E01/E02/E03 core FDTD kernels approach second-order convergence under mesh
   refinement. The MMS source terms are constructed to sustain the analytic
   solution; they are not physical antennas or current sources.

   .. rubric:: Covered Routines

   - ``mod_E01_fdtd_2d_rz_tez`` and ``mod_E01_fdtd_2d_rz_tmz``.
   - ``mod_E02_fdtd_3d_cylindrical`` for ``m=0`` and ``m=1`` with ``phi`` variation.
   - ``mod_E03_fdtd_3d_cartesian``.

   .. rubric:: Files

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - File
        - Role
      * - ``test_mms_*_convergence.f90``
        - Five convergence drivers, each using three resolutions.
      * - ``mms_exact_sources.f90``
        - Analytic fields, analytic sources, and component sampling locations.
      * - ``mms_convergence_utils.f90``
        - Error norms, observed orders, and PASS/FAIL helpers.
      * - ``visualize_mms_*.py``
        - Optional postprocessing for error or numerical/exact comparison plots.

   .. rubric:: Run Command

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_fdtd_mms_convergence
      bash run.sh

   .. note::

      This is a relatively heavy full MMS convergence check in the 005 Maxwell
      test set. On the current development machine, a complete run takes about
      ``15`` minutes. Most of the time is spent in ``3D Cartesian``,
      ``3D cylindrical m=0``, and ``3D cylindrical m=1``. During execution, the
      drivers print lines such as ``progress 100/4000 steps``; if these numbers
      continue to increase, the fine-grid level is still advancing normally.

   .. rubric:: Main Flow

   1. Choose three grids for each geometry with the same physical end time and CFL scale.
   2. Initialize analytic fields at native staggered locations.
   3. Call the production ``H`` update, then inject the MMS magnetic source.
   4. Call the production ``E`` update, then inject the MMS electric source.
   5. Compute ``L2``, ``Linf``, and axis-band errors on active update regions.
   6. Estimate observed order from the three resolutions.

   .. rubric:: Example: 3D Cartesian MMS Convergence

   ``test_mms_3d_cartesian_convergence.f90`` is the most standard MMS example.
   It uses three grids, ``16^3``, ``32^3``, and ``64^3``. Each grid recomputes
   ``dt`` from the CFL condition while keeping the same physical end time. With
   both spacing and time step halved, a second-order discretization should show
   roughly a fourfold error reduction.

   .. code-block:: fortran

      integer, parameter :: nx_list(nlev) = (/16, 32, 64/)

      dt_levels(ilev) = compute_dt(nx_list(ilev),ny_list(ilev),nz_list(ilev),c0)
      call run_level(nx_list(ilev),ny_list(ilev),nz_list(ilev), &
          dt_levels(ilev),nsteps(ilev),omega, ...)

   Inside each ``run_level``, the production FDTD kernels perform only Maxwell
   curl updates. The test then injects MMS source terms so the solution tracks a
   known analytic field. ``compute_errors`` compares numerical and exact fields
   at native Yee locations, and ``observed_order`` converts adjacent grid errors
   into convergence rates.

   .. code-block:: fortran

      call sub_E03_fdtd_3d_cartesian_H(..., Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,mu)
      call add_h_source(nx,ny,nz,dx,dy,dz,dt,t_n,omega0,Hx,Hy,Hz)

      call sub_E03_fdtd_3d_cartesian_E(..., Ex,Ey,Ez,Hx,Hy,Hz,dt,dx,dy,dz,ep)
      call add_e_source(nx,ny,nz,dx,dy,dz,dt,t_n+0.5*dt,omega0,Ex,Ey,Ez)

      call compute_errors(..., Ex,Ey,Ez,Hx,Hy,Hz, l2c, linfc, ...)

   .. rubric:: Core Call Pattern

   .. code-block:: text

      call sub_*_H(...)
      call add_h_source(..., t_n, ...)
      call sub_*_E(...)
      call add_e_source(..., t_n + 0.5*dt, ...)
      call compute_error_against_mms_exact(...)

   .. rubric:: Result Interpretation

   Built-in criteria require ``L2`` observed order at least ``1.8`` and
   ``Linf`` observed order at least ``1.5``. Current reference runs pass:

   .. code-block:: text

      3D Cartesian periodic MMS: L2 orders 2.017, 2.009, result PASS
      2D RZ TMz MMS:             L2 orders 2.014, 2.007, result PASS
      3D cylindrical m=0 MMS:    L2 orders 2.015, 2.007, result PASS
      2D RZ TEz MMS:             L2 orders 2.016, 2.008, result PASS
      3D cylindrical m=1 MMS:    L2 orders 2.019, 1.998, result PASS

   .. rubric:: Common Pitfall

   MMS checks operator/source sampling consistency; it is not a free-space
   wave-packet or CPML test. RZ/cylindrical norms use ``r`` weighting and also
   report ``axis_band_Linf`` near the axis.

   .. include:: _contributors_en.inc
