Cylindrical Flux Utilities
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J01_continuity_freeflow_2Drz.f90`` 提供两个可分别调用的工具：
   用已知单元密度和速度生成数值面通量，以及用已知面通量完成一次密度更新。
   它们不生成粒子历史，也不求解速度分布。
   本页使用物理单位和单元中心数组，不沿用三维工具的单位步长或保护层。

   .. rubric:: 1. 给定密度与速度，先计算内部面通量

   ``sub_J01_build_faceflux_2Drz`` 对相邻的两个有效单元 L、R 使用

   .. math::

      \Gamma_f=\frac{u_Ln_L+u_Rn_R}{2}
         -\frac{\max(|u_L|,|u_R|)}{2}(n_R-n_L).

   径向用 ``velocity_r``，轴向用 ``velocity_z``。
   两侧速度相等时，这是迎风通量；不相等时包含相应的局部耗散项。
   此时尚未乘面积，单位为 m⁻²s⁻¹。

   该过程在相邻有效单元之间生成内部数组，不逐项根据 ``face_type`` 过滤这些相邻位置。
   哪些通量实际参与更新，由后面的面类型选择决定。
   不应把内部数组中某个位置的非零值自动理解为物理壁面穿透。

   .. rubric:: 2. 开放面的出射与规定入射分别处理

   若给定单元速度朝向开放面的域外，输出 :math:`u n`；
   否则该面的出射输出为零。
   因此径向/轴向低端出射为负，高端出射为正。

   输入参数 ``boundary_inflow_flux`` 在通量生成过程中只检查形状，
   不被加入输出。它不是遗漏的返回量：规定入流由调用者保存，
   在单步更新时与这里算出的出射相加。

   ``sub_J01_build_faceflux_2Drz`` 的输入与输出：

   - 输入 ``active(nr,nz)``、``face_type(4,nr,nz)``。
   - 输入 ``density,velocity_r,velocity_z``，形状均为 ``(nr,nz)``；
     密度单位 m⁻³，速度 m/s。
   - 输入 ``boundary_inflow_flux(4,nr,nz)``，单位 m⁻²s⁻¹。
   - 输出分配的 ``flux_r(nr-1,nz)``、``flux_z(nr,nz-1)``、
     ``boundary_outflow_flux(4,nr,nz)``，以及 ``ierr``。
   - 检查形状和负密度；不全面验收拓扑、有限性或速度模型。

   .. rubric:: 3. 使用已知通量推进一步

   ``sub_J01_continuity_step_2Drz`` 按面类型选择通量：
   内部面读取给定内部数组，开放面使用入射与出射之和，壁面保持零。
   记净流出粒子率

   .. math::

      Q_K^{\mathrm{net}}
         =A_{r+}\Gamma_{r+}-A_{r-}\Gamma_{r-}
          +A_{z+}\Gamma_{z+}-A_{z-}\Gamma_{z-}.

   使用给定正时间步，更新为

   .. math::

      n_K^{q+1}
         =\frac{n_K^q-\Delta t Q_K^{\mathrm{net}}/V_K+\Delta t S_K}
                {1+\Delta t\nu_K}.

   输运通量和产生项来自本步已知输入，线性损失采用新密度。
   与三维工具的扣减量不同，这里的 :math:`S_K` 为非负体产生率，正值增加密度。

   .. rubric:: 4. 单步输入、输出与限制

   - 输入 ``active,face_type``，以及 ``volume(nr,nz)`` （m³）、
     ``face_area(4,nr,nz)`` （m²）。
   - 输入 ``density,source_rate,loss_frequency``，均为 ``(nr,nz)``，
     单位依次为 m⁻³、m⁻³s⁻¹、s⁻¹。
   - 输入前述内部通量和分开的 ``boundary_inflow_flux,boundary_outflow_flux``，
     以及 ``dt`` （s）。
   - 输出分配的 ``density_new(nr,nz)`` 与 ``ierr``；输入密度不改，无效单元输出零。
   - 检查尺寸、正时间步、非负密度/源损及有效体积。
     不自动选择稳定步长，不完整检查拓扑和面积，也没有负输出截断。

   本次传入什么通量就使用什么通量，单步过程不根据更新后的密度自动重算它。
   若反复使用这组工具推进，调用者负责每步准备所需通量。
   这里也不建立参考面系数，因此不能把它与“从参考场建立固定闭合”的接口混为一谈。

   .. rubric:: 5. 状态码

   本文件实际使用的返回码为成功 0、形状错误 101、负输入或无效体积 102、
   非正时间步 103。它们属于保留工具模块，不应按粒子前处理模块或 J03 的错误码解释。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   This file has a prescribed-velocity flux builder and a prescribed-flux density step.
   It uses physical cylindrical geometry and cell arrays, unlike the normalized Cartesian interface.

   ``sub_J01_build_faceflux_2Drz`` reads active/face arrays, cell density and velocities,
   and an incoming boundary array. It allocates radial/axial internal fluxes and outgoing boundary fluxes.
   Interior arrays use the local Lax–Friedrichs formula for each adjacent active pair.
   Face-type filtering of actual contributions occurs in the later step.
   The incoming array is shape-checked only; it is not added to the flux outputs.

   ``sub_J01_continuity_step_2Drz`` reads geometry, density, source, loss, all internal/incoming/outgoing
   fluxes and dt. It selects flux by face type and computes

   .. math::

      n_K^{q+1}=
      \frac{n_K^q-\Delta t\sum_f s_fA_f\Gamma_f/V_K+\Delta t S_K}
           {1+\Delta t\nu_K}.

   It allocates density_new, leaves input density unchanged and sets inactive cells to zero.
   It does not recalculate supplied fluxes, determine a stable dt, or clip negative output.

   Actual status codes here are 0 success, 101 shape, 102 negative input/invalid active volume,
   103 nonpositive timestep, interpreted within the retained utilities module.
