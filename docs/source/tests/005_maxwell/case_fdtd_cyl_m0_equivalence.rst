case_fdtd_cyl_m0_equivalence
============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   ``case_fdtd_cyl_m0_equivalence`` 检查完整 3D cylindrical 内核在 ``m=0``、无
   ``phi`` 依赖时，是否退化为 2D RZ 的 TEz/TMz 更新。这是 E01 和 E02 之间的几何一致性测试。

   .. rubric:: 覆盖子程序

   - :doc:`E01 2D RZ </rst_files/E_Maxwell/E01_Maxwell_2Drz>`：
     ``sub_E01_fdtd_2d_rz_tmz_*`` 和 ``sub_E01_fdtd_2d_rz_tez_*``。
   - :doc:`E02 3D cylindrical </rst_files/E_Maxwell/E02_Maxwell_3Drtz>`：
     ``sub_E02_fdtd_3d_cylindrical_E`` 和 ``sub_E02_fdtd_3d_cylindrical_H``。

   .. rubric:: 文件说明

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 文件
        - 作用
      * - ``test_geom_m0_equivalence.f90``
        - 主程序，同时运行 TMz 和 TEz 等价性检查。
      * - ``geom_special_common.f90``
        - 误差统计、场映射和公共监控工具。
      * - ``geom_special_fdtd_support.f90``
        - 2D/3D 场分量之间的映射、边界填充和轴线处理辅助。
      * - ``m0_equivalence_summary.csv``
        - ``family, combined_rel_L2, combined_rel_Linf, result`` 等摘要。

   .. rubric:: 运行方式

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_fdtd_cyl_m0_equivalence
      bash run.sh

   可选参数 ``bash run.sh <Nequiv>`` 控制推进步数，默认 ``600``。

   .. rubric:: 主流程

   1. 构造同一组轴对称初始场。
   2. 将 2D RZ TEz/TMz 分量映射到 3D cylindrical ``m=0`` 场数组。
   3. 分别用 E01 和 E02 内核推进相同步数。
   4. 每步补齐 ``z`` 周期、``phi`` 周期和轴线/外半径 ghost。
   5. 把 3D ``m=0`` 结果投影回 RZ 分量。
   6. 比较 ``Er,Ez,Hphi`` 和 ``Ephi,Hr,Hz`` 的联合相对误差。

   .. rubric:: 典型例子：TMz 的 2D/3D 同步推进

   ``test_geom_m0_equivalence.f90`` 的 ``run_tmz_equiv`` 是最清楚的入口。它先用同一组
   ``nr=40,nphi=32,nz=64`` 和 ``cfl=0.8`` 定义 2D RZ 与 3D cylindrical 网格，然后把
   2D 的 ``Er/Ez/Hphi`` 复制到 3D 数组的每一个 ``phi`` 面上。这样构造出来的 3D 初值没有
   角向变化，理论上应退化为 E01 的 2D RZ TMz 问题。

   .. code-block:: fortran

      call init_2d_tmz(nr,nz,dr,dz,amp0,rmax,lz,Er2,Ez2,Ha2)
      do k = 0, nz
      do j = 0, nphi+1
      do i = 0, nr
          Er3(i,j,k)   = Er2(i,k)
          Ez3(i,j,k)   = Ez2(i,k)
          Hphi3(i,j,k) = Ha2(i,k)
      end do
      end do
      end do

   每一步都同步调用 2D 与 3D 生产内核，然后各自做边界填充。最后比较的是物理上应相同的
   ``Er``、``Ez`` 和 ``Hphi``，而不是所有六个 3D 分量；``Ephi/Hr/Hz`` 在这个 TMz 退化问题中应保持非主导。

   .. code-block:: fortran

      call sub_E01_fdtd_2d_rz_tmz_H(..., Ha2,Er2,Ez2,dt,dr,dz,mu)
      call sub_E01_fdtd_2d_rz_tmz_E(..., Ha2,Er2,Ez2,dt,dr,dz,ep)

      call sub_E02_fdtd_3d_cylindrical_H(..., Er3,Ephi3,Ez3,Hr3,Hphi3,Hz3,dt,dr,dphi,dz,mu)
      call sub_E02_fdtd_3d_cylindrical_E(..., Er3,Ephi3,Ez3,Hr3,Hphi3,Hz3,dt,dr,dphi,dz,ep)

      call compare_er(Er2,Er3,dr,dz,dphi,l2_rel(1),linf_rel(1))

   .. rubric:: 重点调用方式

   .. code-block:: fortran

      call sub_E01_fdtd_2d_rz_tmz_H(...)
      call sub_E01_fdtd_2d_rz_tmz_E(...)
      call sub_E02_fdtd_3d_cylindrical_H(...)
      call sub_E02_fdtd_3d_cylindrical_E(...)
      call compare_m0_projection_with_rz(...)

   .. rubric:: 结果判断

   判据是 ``combined_rel_L2 <= 2e-2`` 且 ``combined_rel_Linf <= 1e-1``。当前参考结果：

   .. code-block:: text

      m0_equivalence,TMz,2.776E-15,1.059E-14,pass,Er,Ez,Hphi
      m0_equivalence,TEz,4.456E-16,8.833E-16,pass,Ephi,Hr,Hz

   .. rubric:: 常见误读

   ``m=0`` 等价测试不是说 3D cylindrical 总是等同于 2D RZ；它只在没有 ``phi`` 变化时成立。
   这页中的 TMz/TEz 仍按物理场分量理解，而不是按历史文件名理解。

   .. include:: _contributors_zh.inc

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   ``case_fdtd_cyl_m0_equivalence`` checks that the full 3D cylindrical kernel
   reduces to 2D RZ TEz/TMz updates when ``m=0`` and there is no ``phi``
   dependence. It is a geometry-consistency test between E01 and E02.

   .. rubric:: Covered Routines

   - :doc:`E01 2D RZ </rst_files/E_Maxwell/E01_Maxwell_2Drz>`:
     ``sub_E01_fdtd_2d_rz_tmz_*`` and ``sub_E01_fdtd_2d_rz_tez_*``.
   - :doc:`E02 3D cylindrical </rst_files/E_Maxwell/E02_Maxwell_3Drtz>`:
     ``sub_E02_fdtd_3d_cylindrical_E`` and ``sub_E02_fdtd_3d_cylindrical_H``.

   .. rubric:: Files

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - File
        - Role
      * - ``test_geom_m0_equivalence.f90``
        - Main program for both TMz and TEz equivalence checks.
      * - ``geom_special_common.f90``
        - Error statistics, field mapping, and shared monitors.
      * - ``geom_special_fdtd_support.f90``
        - 2D/3D component mapping, boundary fill, and axis helpers.
      * - ``m0_equivalence_summary.csv``
        - Summary of family, relative errors, result, and compared components.

   .. rubric:: Run Command

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_fdtd_cyl_m0_equivalence
      bash run.sh

   Optional: ``bash run.sh <Nequiv>`` sets the number of steps; the default is
   ``600``.

   .. rubric:: Main Flow

   1. Build one axisymmetric initial field.
   2. Map 2D RZ TEz/TMz components into 3D cylindrical ``m=0`` arrays.
   3. Advance the same number of steps with E01 and E02 kernels.
   4. Fill ``z`` periodic, ``phi`` periodic, axis, and outer-radius ghosts.
   5. Project the 3D ``m=0`` result back to RZ components.
   6. Compare combined errors for ``Er,Ez,Hphi`` and ``Ephi,Hr,Hz``.

   .. rubric:: Example: Lockstep TMz 2D/3D Advance

   ``run_tmz_equiv`` in ``test_geom_m0_equivalence.f90`` is the clearest entry
   point. It uses the same ``nr=40,nphi=32,nz=64`` geometry with ``cfl=0.8`` for
   both runs, initializes the 2D ``Er/Ez/Hphi`` fields, and copies them onto
   every ``phi`` plane of the 3D arrays. The constructed 3D initial state has no
   angular variation, so it should reduce to the E01 2D RZ TMz problem.

   .. code-block:: fortran

      call init_2d_tmz(nr,nz,dr,dz,amp0,rmax,lz,Er2,Ez2,Ha2)
      do k = 0, nz
      do j = 0, nphi+1
      do i = 0, nr
          Er3(i,j,k)   = Er2(i,k)
          Ez3(i,j,k)   = Ez2(i,k)
          Hphi3(i,j,k) = Ha2(i,k)
      end do
      end do
      end do

   Each step advances the 2D and 3D production kernels and then applies the
   matching boundary fills. The comparison focuses on the physically equivalent
   ``Er``, ``Ez``, and ``Hphi`` components rather than all six 3D components.

   .. code-block:: fortran

      call sub_E01_fdtd_2d_rz_tmz_H(..., Ha2,Er2,Ez2,dt,dr,dz,mu)
      call sub_E01_fdtd_2d_rz_tmz_E(..., Ha2,Er2,Ez2,dt,dr,dz,ep)

      call sub_E02_fdtd_3d_cylindrical_H(..., Er3,Ephi3,Ez3,Hr3,Hphi3,Hz3,dt,dr,dphi,dz,mu)
      call sub_E02_fdtd_3d_cylindrical_E(..., Er3,Ephi3,Ez3,Hr3,Hphi3,Hz3,dt,dr,dphi,dz,ep)

      call compare_er(Er2,Er3,dr,dz,dphi,l2_rel(1),linf_rel(1))

   .. rubric:: Core Call Pattern

   .. code-block:: fortran

      call sub_E01_fdtd_2d_rz_tmz_H(...)
      call sub_E01_fdtd_2d_rz_tmz_E(...)
      call sub_E02_fdtd_3d_cylindrical_H(...)
      call sub_E02_fdtd_3d_cylindrical_E(...)
      call compare_m0_projection_with_rz(...)

   .. rubric:: Result Interpretation

   The pass criteria are ``combined_rel_L2 <= 2e-2`` and
   ``combined_rel_Linf <= 1e-1``. Current reference output:

   .. code-block:: text

      m0_equivalence,TMz,2.776E-15,1.059E-14,pass,Er,Ez,Hphi
      m0_equivalence,TEz,4.456E-16,8.833E-16,pass,Ephi,Hr,Hz

   .. rubric:: Common Pitfall

   The equivalence only holds for ``m=0`` with no ``phi`` variation. TEz/TMz
   labels refer to physical field groups, not historical file names.

   .. include:: _contributors_en.inc
