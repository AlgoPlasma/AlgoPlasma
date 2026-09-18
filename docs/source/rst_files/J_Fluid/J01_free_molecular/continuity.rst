Continuity utilities
====================

.. toctree::
    :maxdepth: 1
    :hidden:

    mod_J01_continuity_freeflow
    sub_J01_continuity_freeflow
    sub_J01_continuity_freeflow_2Drz

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 按实现文件阅读

   * :doc:`二维给定速度通量与更新：sub_J01_continuity_freeflow_2Drz.f90 <sub_J01_continuity_freeflow_2Drz>`

   .. rubric:: 用途

   ``J01_continuity_freeflow`` 使用三维 Lax-Friedrichs 有限体积格式推进自由流连续性方程。
   例程在一次调用中原地更新节点存储的数密度 ``n``，并使用 ``n0`` 作为更新前密度的工作缓冲区。
   由于 ``n`` 不是 cell-centered ``n(il:iu)`` 布局，而是节点布局，
   具体更新区间应以 ``sub_J01_continuity_freeflow.f90`` 中的数组范围和循环边界为准。
   粒子前处理见 :doc:`particle_transport`；本页介绍连续性更新和给定速度的通量计算。

   .. list-table:: 文件
      :header-rows: 1
      :widths: 40 60

      * - 文件
        - 说明
      * - :doc:`mod_J01_continuity_freeflow.f90 <mod_J01_continuity_freeflow>`
        - 模块包装器，通过 ``include`` 暴露连续性方程更新例程。
      * - :doc:`sub_J01_continuity_freeflow.f90 <sub_J01_continuity_freeflow>`
        - 计算三方向通量，并按当前实现约定更新
          ``i=il(1)-1:iu(1)``, ``j=il(2)-1:iu(2)``, ``k=il(3)-1:iu(3)`` 内的密度。

   .. rubric:: 三维连续性更新

   在每个方向上，界面通量采用

   .. math::

      F_{L/R}
      =
      \frac{1}{2}(u_L n_L + u_R n_R)
      - \frac{1}{2}\alpha(n_R-n_L),
      \qquad
      \alpha=\max(|u_L|,|u_R|).

   对更新区内的节点密度，更新为

   .. math::

      n^{new}_{i,j,k}
      =
      n^0_{i,j,k}
      - (F^x_{i+1/2,j,k}-F^x_{i-1/2,j,k})
      - (F^y_{i,j+1/2,k}-F^y_{i,j-1/2,k})
      - (F^z_{i,j,k+1/2}-F^z_{i,j,k-1/2})
      - s_{i,j,k}.

   由于约定 ``dt=dx=dy=dz=1``，代码中没有额外比例系数。

   .. rubric:: 边界和稳定性

   调用前需要设置保护层和边界条件。Lax-Friedrichs 格式是一阶格式，数值扩散与局部最大速度有关；
   多维显式更新的稳定性需要合并各方向的通量贡献，不能仅以各速度分量的最大值小于 1 判断。
   对常速度，常用充分条件为 ``|ux|+|uy|+|uz| <= 1``；变速度应按局部面耗散系数检查。

   .. rubric:: 二维给定速度接口

   .. list-table::
      :header-rows: 1

      * - 接口
        - 输入
        - 输出与功能
      * - ``sub_J01_build_faceflux_2Drz``
        - 有效单元、面类型、密度、给定径向与轴向速度
        - 用局部 Lax-Friedrichs 公式构造内部面通量及边界出射通量；该接口不计算粒子轨迹。
      * - ``sub_J01_continuity_step_2Drz``
        - 几何量、密度、面通量、体源、损失频率和时间步
        - 用面积加权散度及半隐式损失计算下一步密度。

   二维密度和速度数组为 ``(nr,nz)``，内部通量分别为 ``(nr-1,nz)`` 和
   ``(nr,nz-1)``，边界通量为 ``(4,nr,nz)``。面通量按坐标正方向带符号。
   三维接口的单位步长和保护层约定不适用于这些二维接口。

   .. rubric:: 文件分工与参数约定

   ``mod_J01_continuity_freeflow.f90`` 定义成功/错误码、四面序号和面类型，
   并在 contains 下包含两个 sub 文件。三维接口与二维给定速度接口不是同一个算法的连续步骤。

   ``sub_J01_continuity_freeflow.f90`` 先复制 n 到 n0，再逐方向计算面通量，
   最后原地更新 n。n0 是整块旧密度副本；s 是本步扣减量而不是每秒产生率。
   il、iu 确定循环索引，调用方负责填充保护层。

   ``sub_J01_continuity_freeflow_2Drz.f90`` 提供两个不同操作：
   build_faceflux 输入现有密度和速度，只构造通量；continuity_step 输入已经算好的
   通量，只做一次密度更新。前者不是通过粒子轨迹计算速度的 FM 前处理。

   .. rubric:: 测试

   :doc:`J01 测试页 </tests/011_fluid/J01_tests>` 记录
   ``tests/011_fluid/J01_free_molecular`` 的单步公式、正负方向输运、
   ``n0``/guard-cell 契约和周期质量守恒测试。运行 ``run.sh`` 后以
   ``n_failed=0`` 和 ``RESULT: PASS`` 作为通过条件。

   .. rubric:: 应用文献

   该自由流连续性方程更新用于 Hall 推力器三维 PIC 模拟中的中性气体密度演化。
   在早期工作中，它与 MCC 电离模型耦合，作为自洽中性气体密度流体求解器的一部分；
   后续工作则将相同的 Lax-Friedrichs 有限体积思想用于由预处理速度场驱动的连续介质中性气体模型。
   相关论文包括：

   .. raw:: html

      <ul>
        <li>K. Zhong, D. Zeng, Y. Zhao, and D. Yu, <em>Effects of RZ magnetic field components on electron drift instability in hall thrusters via 3D PIC simulations</em>, <em>Physics Letters A</em> 590 (2026) 131809. DOI: <a href="https://doi.org/10.1016/j.physleta.2026.131809" target="_blank" rel="noopener noreferrer">10.1016/j.physleta.2026.131809</a>.</li>
        <li>Y. Zhao and K. Zhong, <em>Effect of Magnetic Field Configuration on Hall Thruster Azimuthal Instability in 3D PIC simulations</em>, IEPC-2025-063, 39th International Electric Propulsion Conference, London, United Kingdom, 14-19 September 2025.</li>
        <li>Y. Zhao and K. Zhong, <em>3D PIC Simulations on Hall Thruster Electron Drift Instability: Influence of Magnetic Field on Electron Transport</em>, arXiv:2512.06222 [physics.plasm-ph] (2025). DOI: <a href="https://doi.org/10.48550/arXiv.2512.06222" target="_blank" rel="noopener noreferrer">10.48550/arXiv.2512.06222</a>.</li>
        <li>K. Zhong, D. Zeng, Y. Zhao, and D. Yu, <em>3D PIC Study of Magnetic Field Effects on Hall Thruster Electron Drift Instability</em>, arXiv:2504.14144 [physics.plasm-ph] (2025). DOI: <a href="https://doi.org/10.48550/arXiv.2504.14144" target="_blank" rel="noopener noreferrer">10.48550/arXiv.2504.14144</a>.</li>
        <li>Z. Liu, Z. Zhao, and Y. Zhao, <em>Near-Wall Pathways of Anomalous Electron Transport in Hall Thrusters Revealed by 3D PIC Simulations</em>, arXiv:2603.14849 [physics.plasm-ph] (2026). DOI: <a href="https://doi.org/10.48550/arXiv.2603.14849" target="_blank" rel="noopener noreferrer">10.48550/arXiv.2603.14849</a>.</li>
      </ul>

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">赵隐剑 (2025/12/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Module Role

   ``J01_continuity_freeflow`` advances the free-flow continuity equation with a
   three-dimensional Lax-Friedrichs finite-volume scheme. A call updates the
   node-stored number density ``n`` in place and uses ``n0`` as a work buffer
   holding the pre-update density.
   Particle preprocessing is now in :doc:`particle_transport`.

   .. list-table:: Files
      :header-rows: 1
      :widths: 40 60

      * - File
        - Description
      * - :doc:`mod_J01_continuity_freeflow.f90 <mod_J01_continuity_freeflow>`
        - Module wrapper that exposes the continuity update routine through ``include``.
      * - :doc:`sub_J01_continuity_freeflow.f90 <sub_J01_continuity_freeflow>`
        - Computes directional fluxes and updates the density over
          ``i=il(1)-1:iu(1)``, ``j=il(2)-1:iu(2)``, ``k=il(3)-1:iu(3)``.

   .. rubric:: Numerical Scheme

   In each coordinate direction, the face flux is

   .. math::

      F_{L/R}
      =
      \frac{1}{2}(u_L n_L + u_R n_R)
      - \frac{1}{2}\alpha(n_R-n_L),
      \qquad
      \alpha=\max(|u_L|,|u_R|).

   The active-cell update is

   .. math::

      n^{new}_{i,j,k}
      =
      n^0_{i,j,k}
      - (F^x_{i+1/2,j,k}-F^x_{i-1/2,j,k})
      - (F^y_{i,j+1/2,k}-F^y_{i,j-1/2,k})
      - (F^z_{i,j,k+1/2}-F^z_{i,j,k-1/2})
      - s_{i,j,k}.

   Because ``dt=dx=dy=dz=1``, no extra scaling factors appear in the code.

   .. rubric:: Boundaries and Stability

   Guard cells and boundary conditions must be set before calling the routine.
   The Lax-Friedrichs scheme is first order and introduces numerical diffusion
   proportional to the maximum local velocity. Under the normalized step sizes,
   a sufficient constant-velocity condition is ``|ux|+|uy|+|uz| <= 1``;
   variable velocities require checking local face dissipation coefficients.

   .. rubric:: Cylindrical Interfaces

   ``sub_J01_build_faceflux_2Drz`` constructs fluxes from prescribed cell velocities.
   ``sub_J01_continuity_step_2Drz`` advances density with area/volume weighting and
   semi-implicit loss. Particle histories are provided by the separate free-molecular module.
   Density arrays are (nr,nz), internal fluxes (nr-1,nz) and (nr,nz-1), and boundary fluxes (4,nr,nz).

   .. rubric:: Regression Test

   The :doc:`J01 test page </tests/011_fluid/J01_tests>` documents the single-step
   formula, positive/negative directional transport, ``n0``/guard-cell contract,
   and periodic mass-conservation checks under
   ``tests/011_fluid/J01_free_molecular``. A successful ``run.sh`` reports
   ``n_failed=0`` and ``RESULT: PASS``.

   .. rubric:: Applications and References

   This free-flow continuity update is used for neutral-gas-density evolution in
   Hall-thruster 3D PIC simulations. In earlier studies, it is coupled with MCC
   ionization as part of a self-consistent fluid solver for neutral gas density;
   later work uses the same Lax-Friedrichs finite-volume idea in a continuum
   neutral model driven by preprocessed velocity fields. Related papers include:

   .. raw:: html

      <ul>
        <li>K. Zhong, D. Zeng, Y. Zhao, and D. Yu, <em>Effects of RZ magnetic field components on electron drift instability in hall thrusters via 3D PIC simulations</em>, <em>Physics Letters A</em> 590 (2026) 131809. DOI: <a href="https://doi.org/10.1016/j.physleta.2026.131809" target="_blank" rel="noopener noreferrer">10.1016/j.physleta.2026.131809</a>.</li>
        <li>Y. Zhao and K. Zhong, <em>Effect of Magnetic Field Configuration on Hall Thruster Azimuthal Instability in 3D PIC simulations</em>, IEPC-2025-063, 39th International Electric Propulsion Conference, London, United Kingdom, 14-19 September 2025.</li>
        <li>Y. Zhao and K. Zhong, <em>3D PIC Simulations on Hall Thruster Electron Drift Instability: Influence of Magnetic Field on Electron Transport</em>, arXiv:2512.06222 [physics.plasm-ph] (2025). DOI: <a href="https://doi.org/10.48550/arXiv.2512.06222" target="_blank" rel="noopener noreferrer">10.48550/arXiv.2512.06222</a>.</li>
        <li>K. Zhong, D. Zeng, Y. Zhao, and D. Yu, <em>3D PIC Study of Magnetic Field Effects on Hall Thruster Electron Drift Instability</em>, arXiv:2504.14144 [physics.plasm-ph] (2025). DOI: <a href="https://doi.org/10.48550/arXiv.2504.14144" target="_blank" rel="noopener noreferrer">10.48550/arXiv.2504.14144</a>.</li>
        <li>Z. Liu, Z. Zhao, and Y. Zhao, <em>Near-Wall Pathways of Anomalous Electron Transport in Hall Thrusters Revealed by 3D PIC Simulations</em>, arXiv:2603.14849 [physics.plasm-ph] (2026). DOI: <a href="https://doi.org/10.48550/arXiv.2603.14849" target="_blank" rel="noopener noreferrer">10.48550/arXiv.2603.14849</a>.</li>
      </ul>

   .. rubric:: Indexing Convention

   The routine should be read with its concrete array bounds, because the
   density is node-stored rather than a simple cell-centered ``n(il:iu)`` field.
   In the current implementation:

   - ``n``, ``s``, ``ux``, ``uy``, ``uz``, and ``n0`` are declared on
     ``il(*)-2:iu(*)+1``.
   - The density update loop runs over
     ``i=il(1)-1:iu(1)``, ``j=il(2)-1:iu(2)``, ``k=il(3)-1:iu(3)``.
   - The work arrays ``Fx/Fy/Fz`` are face-staggered relative to that update
     region.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Yinjian ZHAO (2025/12/02) · Harbin Institute of Technology</p>
      </div>
