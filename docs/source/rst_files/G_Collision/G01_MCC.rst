G01_MCC
=======

.. toctree::
    :maxdepth: 1
    :hidden:

    G01_MCC/mod_G01_collision
    G01_MCC/sub_G01_load_cross_section
    G01_MCC/fun_G01_cross_section
    G01_MCC/sub_G01_collision1
    G01_MCC/sub_G01_collision2
    G01_MCC/sub_G01_electron

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``G01_MCC`` 是基于 null-collision 的 Monte Carlo Collision 模块。它读取碰撞截面表，
   用截面和粒子速度计算各类碰撞频率，随机选取本步需要测试的粒子，并按碰撞类型更新速度、
   生成电离二次粒子或累积电离源项。

   .. list-table:: 文件角色
      :header-rows: 1
      :widths: 34 66

      * - 文件
        - 角色
      * - :doc:`mod_G01_collision.f90 <G01_MCC/mod_G01_collision>`
        - 模块包装器，include G01 的截面读取、插值、电子碰撞和离子碰撞例程。
      * - :doc:`sub_G01_load_cross_section.f90 <G01_MCC/sub_G01_load_cross_section>`
        - 从两列文本文件读取能量-截面表，并把短表补到 ``Nmax``。
      * - :doc:`fun_G01_cross_section.f90 <G01_MCC/fun_G01_cross_section>`
        - 对等间隔能量表做线性插值，超出表范围时使用边界截面。
      * - :doc:`sub_G01_collision1.f90 <G01_MCC/sub_G01_collision1>`
        - 电子-中性粒子 MCC；支持弹性散射、激发和电离，并在电离时生成新电子/离子。
      * - :doc:`sub_G01_collision2.f90 <G01_MCC/sub_G01_collision2>`
        - 离子-中性粒子 MCC；支持电荷交换和离子-中性粒子弹性散射。
      * - :doc:`sub_G01_electron.f90 <G01_MCC/sub_G01_electron>`
        - 电子碰撞后的散射角、能量损失和二次粒子速度抽样。

   .. rubric:: Null-Collision 流程

   当前 ``G01_MCC`` 的 null-collision 选择流程、电子散射角抽样和散射角几何示意遵循
   Vahedi 和 Surendra 的 MCC 算法文献。

   为避免每个时间步对所有粒子逐个计算碰撞概率，MCC 先构造一个覆盖所有能量和位置的最大频率
   ``nu_prime``：

   .. math::

      \nu' = \max_{x,E}\left(n_t(x)\,\sigma_T(E)\,v(E)\right)
           = \max_x n_t(x)\,\max_E\left(\sigma_T(E)v(E)\right)

   时间步 ``dt`` 内被抽中进入碰撞测试的最大概率为

   .. math::

      P_{\mathrm{null}} = 1 - \exp(-\nu' \Delta t)

   例程用 ``P_null * np`` 得到本步测试粒子数 ``Nc``，随机选取不重复粒子。对每个被选粒子，
   先根据当前位置插值得到中性粒子密度 ``n_t``，再对每个碰撞类型计算

   .. math::

      \nu_j(E_i) = n_t\,\sigma_j(E_i)\,v_i

   随机数 ``R`` 落入累积区间 ``sum(nu_1..nu_j) / nu_prime`` 时执行第 ``j`` 类真实碰撞；
   若没有落入任何真实碰撞区间，则本次测试是 null collision，粒子状态保持不变。

   .. rubric:: 已实现的碰撞类型

   ``sub_G01_collision1`` 用 ``collision_type`` 区分电子碰撞：

   - ``1``：电子-中性粒子弹性散射。
   - ``2``：激发；电子损失 ``energy_excitation``。
   - ``3``：电离；电子损失 ``energy_ionization``，产生一个新电子和一个新离子，并把源项沉积到 ``S``。

   ``sub_G01_collision2`` 用 ``collision_type`` 区分离子碰撞：

   - ``1``：电荷交换，离子速度替换为抽样得到的中性粒子速度。
   - ``2``：离子-中性粒子散射，使用各向同性方向抽样更新相对速度。

   当前 Sphinx 页只按源码中已有路径说明实现状态。分子解离、解离电离和解离附着等过程可按相同
   MCC 选择框架扩展，但当前 ``G01_MCC`` 源码没有对应分支。

   .. rubric:: 电子散射角和能量损失

   电子碰撞核使用 Vahedi 风格的角度抽样。入射电子能量为 ``energy`` 时，散射角满足

   .. math::

      \cos\chi =
      \frac{2 + \epsilon - 2(1+\epsilon)^R}{\epsilon}

   其中 ``R`` 是 ``[0,1]`` 上的随机数，``epsilon`` 是按例程参数 ``eV`` 缩放后的能量。
   方位角 ``phi = 2 pi R'`` 均匀抽样。弹性碰撞的能量损失按

   .. math::

      \Delta E = \frac{2m_e}{m_n}(1-\cos\chi)E

   激发直接扣除激发阈值；电离把剩余能量在保留电子和新电子之间平均分配。

   .. figure:: ../../images/G_Collision/G01_MCC_scatterangle.png
      :align: center
      :width: 50%
      :name: G01_MCC_scatterangle

      电子碰撞散射角几何关系；图示来自 Vahedi 和 Surendra (1995)。

   .. rubric:: 参考文献

   .. raw:: html

      <ul>
        <li>V. Vahedi and M. Surendra, <em>A Monte Carlo collision model for the particle-in-cell method: applications to argon and oxygen discharges</em>, <em>Computer Physics Communications</em> 87 (1995) 179-198. DOI: <a href="https://doi.org/10.1016/0010-4655(94)00171-W" target="_blank" rel="noopener noreferrer">10.1016/0010-4655(94)00171-W</a>.</li>
      </ul>

   .. rubric:: 调用注意

   - ``nu_max < 0`` 时例程会重新扫描截面表以初始化最大 ``sigma*v``；后续调用可复用 ``nu_max``。
   - ``den`` 和 ``S`` 使用 ``il(1)-1:iu(1)`` 等节点范围，粒子坐标需要落在可插值的网格单元内。
   - 当前代码假设位置坐标已经按网格间距归一化，内部注释也指出 ``dx=dy=dz=1``。
   - ``np1/np2`` 可能因电离增加；调用方需要保证 ``npmax1/npmax2`` 留有容量。
   - 截面表的能量单位、粒子质量、电荷常数和 ``eV`` 换算需要由调用方保持一致。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">谢礼桓 (2025/12/18) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``G01_MCC`` implements a null-collision Monte Carlo Collision layer. It loads
   tabulated collision cross sections, evaluates collision frequencies from
   cross sections and particle speed, samples particles that need collision
   tests in the current step, and then updates velocities, creates ionization
   products, or accumulates ionization source terms.

   .. list-table:: File Roles
      :header-rows: 1
      :widths: 34 66

      * - File
        - Role
      * - :doc:`mod_G01_collision.f90 <G01_MCC/mod_G01_collision>`
        - Module wrapper including the G01 table loader, interpolation helper, electron collision routine, and ion collision routine.
      * - :doc:`sub_G01_load_cross_section.f90 <G01_MCC/sub_G01_load_cross_section>`
        - Load a two-column energy/cross-section table and extend short tables to ``Nmax``.
      * - :doc:`fun_G01_cross_section.f90 <G01_MCC/fun_G01_cross_section>`
        - Linearly interpolate a uniformly spaced energy table and clamp out-of-range energies to boundary values.
      * - :doc:`sub_G01_collision1.f90 <G01_MCC/sub_G01_collision1>`
        - Electron-neutral MCC for elastic scattering, excitation, and ionization, including secondary electron/ion creation.
      * - :doc:`sub_G01_collision2.f90 <G01_MCC/sub_G01_collision2>`
        - Ion-neutral MCC for charge exchange and ion-neutral elastic scattering.
      * - :doc:`sub_G01_electron.f90 <G01_MCC/sub_G01_electron>`
        - Sample electron scattering angles, energy loss, and secondary-particle velocities.

   .. rubric:: Null-Collision Workflow

   The current ``G01_MCC`` null-collision selection workflow, electron
   scattering-angle sampling, and scattering-angle geometry follow the MCC
   algorithm paper by Vahedi and Surendra.

   To avoid testing every particle against every physical reaction in every time
   step, MCC first constructs a maximum frequency ``nu_prime`` that bounds all
   energies and positions:

   .. math::

      \nu' = \max_{x,E}\left(n_t(x)\,\sigma_T(E)\,v(E)\right)
           = \max_x n_t(x)\,\max_E\left(\sigma_T(E)v(E)\right)

   The maximum probability that a particle is selected for collision testing
   during one time step is

   .. math::

      P_{\mathrm{null}} = 1 - \exp(-\nu' \Delta t)

   The routines use ``P_null * np`` to obtain the number ``Nc`` of particles to
   test, then randomly select distinct particles. For each selected particle,
   the neutral density ``n_t`` is interpolated from the particle position, and
   each reaction frequency is evaluated as

   .. math::

      \nu_j(E_i) = n_t\,\sigma_j(E_i)\,v_i

   A random number ``R`` selects a physical reaction when it falls inside the
   cumulative interval ``sum(nu_1..nu_j) / nu_prime``. If no physical interval is
   selected, the event is a null collision and the particle state is unchanged.

   .. rubric:: Implemented Collision Types

   ``sub_G01_collision1`` uses ``collision_type`` for electron collisions:

   - ``1``: electron-neutral elastic scattering.
   - ``2``: excitation; the electron loses ``energy_excitation``.
   - ``3``: ionization; the electron loses ``energy_ionization``, a new electron and ion are created, and the source term is deposited into ``S``.

   ``sub_G01_collision2`` uses ``collision_type`` for ion collisions:

   - ``1``: charge exchange, replacing the ion velocity with a sampled neutral velocity.
   - ``2``: ion-neutral scattering, updating the relative velocity with an isotropic direction sample.

   This page documents the paths implemented in the current source. Molecular
   dissociation, dissociative ionization, and dissociative attachment can be
   added under the same MCC selection framework, but they do not have branches
   in the current ``G01_MCC`` routines.

   .. rubric:: Electron Scattering and Energy Loss

   The electron kernel uses Vahedi-style angular sampling. For an incident
   electron energy ``energy``, the scattering angle satisfies

   .. math::

      \cos\chi =
      \frac{2 + \epsilon - 2(1+\epsilon)^R}{\epsilon}

   where ``R`` is a uniform random number in ``[0,1]`` and ``epsilon`` is the
   energy scaled by the routine argument ``eV``. The azimuthal angle
   ``phi = 2 pi R'`` is sampled uniformly. Elastic energy loss is

   .. math::

      \Delta E = \frac{2m_e}{m_n}(1-\cos\chi)E

   Excitation subtracts the excitation threshold directly. Ionization splits the
   remaining energy equally between the retained electron and the new electron.

   .. figure:: ../../images/G_Collision/G01_MCC_scatterangle.png
      :align: center
      :width: 50%
      :name: G01_MCC_scatterangle_en

      Electron collision scattering-angle geometry; figure from Vahedi and Surendra (1995).

   .. rubric:: Reference

   .. raw:: html

      <ul>
        <li>V. Vahedi and M. Surendra, <em>A Monte Carlo collision model for the particle-in-cell method: applications to argon and oxygen discharges</em>, <em>Computer Physics Communications</em> 87 (1995) 179-198. DOI: <a href="https://doi.org/10.1016/0010-4655(94)00171-W" target="_blank" rel="noopener noreferrer">10.1016/0010-4655(94)00171-W</a>.</li>
      </ul>

   .. rubric:: Calling Notes

   - When ``nu_max < 0``, the routine scans the cross-section tables to initialize the maximum ``sigma*v``; later calls can reuse ``nu_max``.
   - ``den`` and ``S`` use node ranges such as ``il(1)-1:iu(1)``. Particle positions must remain inside cells that can be interpolated from those nodes.
   - The current code assumes positions are normalized by the grid spacing; an internal comment notes ``dx=dy=dz=1``.
   - ``np1`` and ``np2`` may increase after ionization, so callers must leave capacity in ``npmax1`` and ``npmax2``.
   - Cross-section energy units, particle masses, charge constants, and the ``eV`` conversion factor must be kept consistent by the caller.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Lihuan XIE (2025/12/18) · Harbin Institute of Technology</p>
      </div>
