J01 Legacy Updates
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 被测接口与程序

   这里保留三维归一化连续性更新，以及二维给定速度下的面通量和单步更新检查。

   .. list-table::
      :header-rows: 1
      :widths: 40 60

      * - 测试文件（J01 测试目录的 source_f90 下）
        - 对应正式源码与过程
      * - ``test_J01_continuity_freeflow.f90``
        - ``sub_J01_continuity_freeflow.f90``：``sub_J01_continuity_freeflow``
      * - ``test_J01_faceflux_2Drz_units.f90``
        - ``sub_J01_continuity_freeflow_2Drz.f90``：``sub_J01_build_faceflux_2Drz``、``sub_J01_continuity_step_2Drz``

   第二个文件还包含完整粒子主入口检查，放在本组的 Complete FM Solve 页说明。

   .. rubric:: 1. 三维更新的参考公式与索引

   三维接口采用 :math:`\Delta x=\Delta y=\Delta z=\Delta t=1`。
   在任意方向，左右密度为 :math:`n_L,n_R`，该方向速度为
   :math:`u_L,u_R`，局部 Lax–Friedrichs 面通量为

   .. math::

      F=\frac{u_Ln_L+u_Rn_R}{2}
         -\frac{\max(|u_L|,|u_R|)}{2}(n_R-n_L).

   由六个面的通量得到

   .. math::

      n_{ijk}^{\rm new}=n_{ijk}^{\rm old}
      -(F^x_{i+1/2,j,k}-F^x_{i-1/2,j,k})
      -(F^y_{i,j+1/2,k}-F^y_{i,j-1/2,k})
      -(F^z_{i,j,k+1/2}-F^z_{i,j,k-1/2})-s_{ijk}.

   测试取 ``lo=[1,2,3]``、``hi=[4,6,5]``。
   更新范围为各方向的 ``lo-1:hi``，数组两端 ``lo-2`` 与 ``hi+1`` 是保护层。
   三个方向的范围不同，可以暴露方向互换或错位索引。
   每次调用前保存原场；调用后同时检查新密度、旧场副本 ``n0`` 和保护层。

   .. rubric:: 2. 按限制情形逐项核对三维公式

   .. list-table::
      :header-rows: 1
      :widths: 22 23 32 23

      * - 测试子程序
        - 问题与输入
        - 参考值及断言
        - 实测结果（2026-10-06，real8）
      * - ``test_zero_velocity_identity``
        - 非均匀密度，三方向速度和 s 全为零
        - 所有面通量为零，密度保持；n0 精确复制调用前的数组
        - 密度与副本的最大差均为 0
      * - ``test_source_sign``
        - 速度为零，更新区设 ``s=0.002*(2*i-j+3*k)+0.015``
        - 更新区满足 :math:`n^{\rm new}=n^{\rm old}-s`；保护层不变
        - 密度与副本的最大差均为 0
      * - ``test_single_step_reference``
        - 三方向速度、密度和 s 均随位置变化
        - ``reference_step`` 从每点的六个邻面独立算通量，再按上式核对全部更新点
        - 所有点最大误差 0，容差 1e−12
      * - ``test_unit_shifts``
        - 每次只启用一个方向，速度取 +1 或 −1，使用周期保护层
        - 六种组合均为沿速度方向平移一格；旧场副本和保护层仍保持
        - x 方向两种符号误差均为 0；y、z 均为 1.7764e−15，容差 1e−12
      * - ``test_periodic_mass_conservation``
        - 非均匀密度、速度，周期保护层，s=0
        - 对更新区求和，共享面相消、周期首尾面相消，总密度保持
        - 更新前 246.2099453，更新后 246.2099453；差 1.7053e−13，容差 2.4621e−10

   整格平移可以直接由通量式推出：当 :math:`u_L=u_R=1` 时，
   :math:`F=n_L`，从而 :math:`n_i^{\rm new}=n_{i-1}^{\rm old}`；
   速度为 −1 时 :math:`F=-n_R`，得到 :math:`n_i^{\rm new}=n_{i+1}^{\rm old}`。
   它同时检查迎风方向和面索引。

   密度逐点绝对容差为 :math:`10^{-12}`，旧场副本与保护层要求精确相等。
   周期总量容差按测试中的总密度尺度缩放。
   任一失败都会报告对应数组或检查名称，并使程序非零退出。

   .. rubric:: 3. 二维内部面与边界通量

   ``test_lax_friedrichs_signs`` 给定两个相邻单元的密度 :math:`[2,5]`，
   调用 ``sub_J01_build_faceflux_2Drz``。同一个面通量式给出三组手算值：

   .. math::

      \begin{aligned}
      u_L=u_R=1 &: \quad F=\tfrac12(2+5)-\tfrac12(5-2)=2,\\
      u_L=u_R=-1 &: \quad F=\tfrac12(-2-5)-\tfrac12(5-2)=-5,\\
      (u_L,u_R)=(1,3) &: \quad F=\tfrac12(2+15)-\tfrac32(5-2)=4.
      \end{aligned}

   测试在两个径向相邻单元的共享面核对以上数值，绝对容差为 :math:`10^{-13}`。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 速度 +1
        - 2
        - 2
        - 0
        - 1e−13
      * - 速度 −1
        - −5
        - −5
        - 0
        - 1e−13
      * - 左右速度 1、3
        - 4
        - 4
        - 0
        - 1e−13

   ``test_boundary_outflow_signs`` 使用密度 3、速度
   :math:`(u_r,u_z)=(-2,4)`。按
   :math:`(r\text{低端},r\text{高端},z\text{低端},z\text{高端})` 的顺序，
   流出通量应为 :math:`(-6,0,0,12)`。
   这里通量按坐标方向带符号，低端流出为负，高端流出为正；
   其余两面速度朝内，流出部分为零。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 四面流出通量
        - (−6,0,0,12)
        - (−6,0,0,12)
        - 最大差 0
        - 1e−13

   .. rubric:: 4. 面积、体积与半隐式损失

   ``test_cylindrical_step_formula`` 调用 ``sub_J01_continuity_step_2Drz``。
   单元体积 :math:`V=2`、入口面积 :math:`A=3`、入射通量大小 2，
   故单位体积的入射贡献为 :math:`A\Gamma_{\rm in}/V=3`。
   初始密度 2、体源 4、损失频率 1、时间步 0.5，则

   .. math::

      n^{\rm new}
      =\frac{n^{\rm old}+\Delta t(A\Gamma_{\rm in}/V+S)}
             {1+\Delta t\,\nu}
      =\frac{2+0.5\times3+0.5\times4}{1.5}
      =\frac{11}{3}.

   测试将实际密度与此值核对，定位面积/体积权重或损失时间层的错误。
   ``test_input_errors`` 再向通量过程输入负密度，
   要求返回 ``J01_ERR_NEGATIVE_INPUT``。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 核对量
        - 计算值
        - 参考值
        - 误差
        - 容差
      * - 更新后密度
        - 3.666666667
        - 11/3
        - 0
        - 1e−13

   负密度输入返回码为 102，与 ``J01_ERR_NEGATIVE_INPUT`` 一致。

   .. rubric:: 运行与结果

   .. code-block:: bash

      bash tests/012_fluid/J01_free_molecular/run.sh

   脚本先运行三维程序，再运行二维通量程序，之后才执行粒子过程测试。
   日志分别为 ``build/test_J01_continuity_freeflow.log``、
   ``build/test_J01_faceflux_2Drz_units.log``。
   2026-10-06 两个程序通过，三维程序报告的最大绝对误差为
   :math:`1.7053\times10^{-13}`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Programs and production interfaces

   ``test_J01_continuity_freeflow.f90`` exercises the retained 3D
   ``sub_J01_continuity_freeflow``.
   ``test_J01_faceflux_2Drz_units.f90`` checks the 2D
   ``sub_J01_build_faceflux_2Drz`` and ``sub_J01_continuity_step_2Drz``.
   The complete particle-driver check in the latter file is described on Complete FM Solve.

   .. rubric:: 1. Three-dimensional reference

   With unit spacing and timestep, each face uses

   .. math::

      F=\tfrac12(u_Ln_L+u_Rn_R)-\tfrac12\max(|u_L|,|u_R|)(n_R-n_L).

   The update subtracts the three directional face differences and s.
   Test bounds are lo=[1,2,3], hi=[4,6,5]; the updated range is lo−1:hi,
   with guards at lo−2 and hi+1. Unequal directional ranges expose index swaps.

   ``test_zero_velocity_identity`` checks zero-transport identity.
   ``test_source_sign`` checks :math:`n_{\rm new}=n_{\rm old}-s`.
   ``test_single_step_reference`` independently evaluates six face fluxes per point
   with spatially varying data.
   ``test_unit_shifts`` checks all six unit-speed translations: positive speed
   gives :math:`F=n_L` and copies the upstream point; negative speed gives
   :math:`F=-n_R`.
   ``test_periodic_mass_conservation`` checks total density when paired faces cancel.

   Pointwise density tolerance is :math:`10^{-12}`. The old-state copy and guards
   must match exactly; the mass tolerance scales with total density.

   .. rubric:: 2. Two-dimensional flux and step checks

   For densities [2,5], velocities +1, −1 and [1,3] yield internal face fluxes
   2, −5 and 4 on their shared radial face, checked to :math:`10^{-13}`.
   For density 3 and velocity (−2,4), boundary outflow in r-low/r-high/z-low/z-high
   order is (−6,0,0,12), signed along the coordinate axes.

   With V=2, inlet A=3, incident flux magnitude 2, initial density 2, source 4,
   loss frequency 1 and timestep 0.5, the expected half-implicit result is

   .. math::

      n_{\rm new}=\frac{2+0.5(3\times2/2+4)}{1+0.5}=\frac{11}{3}.

   A separate negative-density input must return ``J01_ERR_NEGATIVE_INPUT``.

   .. rubric:: Execution and record

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Quantity
        - Computed
        - Reference
        - Error
        - Limit
      * - 3D identity/source/reference max error
        - 0
        - 0
        - 0
        - 1e−12
      * - 3D shifts max error
        - 1.7764e−15
        - 0
        - 1.7764e−15
        - 1e−12
      * - Periodic sum
        - 246.2099453
        - 246.2099453
        - 1.7053e−13
        - 2.4621e−10
      * - 2D internal fluxes
        - 2 / −5 / 4
        - 2 / −5 / 4
        - 0
        - 1e−13
      * - 2D boundary fluxes
        - (−6,0,0,12)
        - (−6,0,0,12)
        - 0
        - 1e−13
      * - 2D step density
        - 3.666666667
        - 11/3
        - 0
        - 1e−13

   .. code-block:: bash

      bash tests/012_fluid/J01_free_molecular/run.sh

   The 3D and 2D programs run first; individual logs are saved under ``build``.
   Both passed on 2026-10-06. The recorded 3D maximum absolute error is
   :math:`1.7053\times10^{-13}`.
