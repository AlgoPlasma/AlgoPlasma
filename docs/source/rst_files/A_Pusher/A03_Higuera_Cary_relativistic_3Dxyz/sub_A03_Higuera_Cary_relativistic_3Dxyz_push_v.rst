-------------------------------------------------------------------------------
sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v.f90
-------------------------------------------------------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   用 Higuera-Cary relativistic pusher 推进单个粒子速度。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 14 10 28 34 26 40

      * - 参数
        - 方向
        - shape / 范围
        - 含义
        - 单位 / 归一化
        - 索引 / ghost-cell 要求
      * - ``v``
        - ``in/out``
        - ``real(1:3)``
        - 粒子速度向量
        - 调用者归一化下的粒子/场单位
        - 单粒子向量，无 ghost cell；分量顺序由本页坐标系决定。
      * - ``E``
        - ``in``
        - ``real(1:3)``
        - 粒子位置处的电场向量
        - 调用者归一化下的粒子/场单位
        - 单粒子向量，无 ghost cell；分量顺序由本页坐标系决定。
      * - ``B``
        - ``in``
        - ``real(1:3)``
        - 粒子位置处的磁场向量
        - 调用者归一化下的粒子/场单位
        - 单粒子向量，无 ghost cell；分量顺序由本页坐标系决定。
      * - ``k``
        - ``in``
        - ``real scalar``
        - Boris/Higuera-Cary 半步系数，通常为 q*dt/(2m)。
        - 调用者归一化下的电荷质量比与时间步组合。
        - 单粒子标量；无 ghost cell。
   .. rubric:: 局部假设 / 前置条件

   - 坐标系为 Cartesian，分量顺序为 ``(x,y,z)``。
   - 本页只说明本 routine 的局部约定；不假设全局主程序的单位制、时间步或边界策略。

   .. rubric:: 实现逻辑

   - 源码先把速度转换为 proper velocity，再执行 Higuera-Cary 的电场 kick 和磁场 rotation。
   - 末尾用新的 Lorentz factor 把 proper velocity 转回普通速度。
   - 源码变量 ``gamma_minus`` 存储的是
     :math:`(\gamma^-)^2 = 1 + |\mathbf{u}^-|^2/c^2`，而非 :math:`\gamma^-`
     本身；公式中的 :math:`\sigma = (\gamma^-)^2 - \boldsymbol{\tau}^2`
     因此直接写作 ``sigma = gamma_minus - beta2``。

   .. rubric:: 调用注意

   - 该 routine 只处理单粒子局部更新，场插值、粒子循环和边界处理在上层完成。


   .. rubric:: 子程序说明

   ``sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v`` 是三维直角坐标中的
   relativistic Higuera-Cary velocity pusher。它将粒子速度
   :math:`\mathbf{v}` 转换为 proper velocity
   :math:`\mathbf{u}=\gamma\mathbf{v}`，执行电场半步推进、磁场旋转和第二次电场半步推进，再将更新后的 :math:`\mathbf{u}` 转换回速度
   :math:`\mathbf{v}`。

   .. list-table::
      :header-rows: 1

      * - 参数
        - 方向
        - 含义
      * - ``v(1:3)``
        - in/out
        - 粒子速度 :math:`\mathbf{v} = (v_x,v_y,v_z)`；出口为一次完整
          relativistic Higuera-Cary 更新后的速度。
      * - ``E(1:3)``
        - in
        - 粒子位置处的电场 :math:`\mathbf{E} = (E_x,E_y,E_z)`。
      * - ``B(1:3)``
        - in
        - 粒子位置处的磁场 :math:`\mathbf{B} = (B_x,B_y,B_z)`。
      * - ``k``
        - in
        - 通常为 :math:`q\Delta t/(2m)`，控制电场 half-kick 和磁场旋转强度。

   .. rubric:: 算法说明

   相对论带电粒子的平动关系为

   .. math::
      \frac{\mathrm{d}\mathbf{x}}{\mathrm{d}t}
      = \mathbf{v} = \mathbf{u}/\gamma,
      \qquad
      \gamma = \sqrt{1 + \|\mathbf{u}/c\|^2}

   proper velocity :math:`\mathbf{u}` 满足 Lorentz force 方程

   .. math::
      \frac{\mathrm{d}\mathbf{u}}{\mathrm{d}t}
      = \frac{q}{m}
      \left( \mathbf{E} + \mathbf{v}\times\mathbf{B} \right)

   对 Newton-Lorentz 方程作 centered finite-difference 离散，可得到

   .. math::
      \frac{\mathbf{x}^{n+1}-\mathbf{x}^{n}}{\Delta t}
      = \mathbf{v}^{n+1/2},
      \qquad
      \mathbf{x}^{n+1}
      = \mathbf{x}^{n} + \Delta t\,\mathbf{v}^{n+1/2}

   .. math::
      \frac{\mathbf{u}^{n+1/2}-\mathbf{u}^{n-1/2}}{\Delta t}
      =
      \frac{q}{m}
      \left(\mathbf{E}^{n}
      + \bar{\mathbf{v}}^{n}\times\mathbf{B}^{n}\right)

   Higuera-Cary 显式更新可写为：

   .. math::
      \mathbf{u}^{-}
      = \mathbf{u}^{n-1/2}
      + \frac{q\Delta t}{2m}\mathbf{E}^n

   .. math::
      \mathbf{u}^{+}
      =
      s\left[
      \mathbf{u}^{-}
      + (\mathbf{u}^{-}\cdot\mathbf{t})\mathbf{t}
      + \mathbf{u}^{-}\times\mathbf{t}
      \right]

   .. math::
      \mathbf{u}^{n+1/2}
      =
      \mathbf{u}^{+}
      + \frac{q\Delta t}{2m}\mathbf{E}^n
      + \mathbf{u}^{+}\times\mathbf{t}

   其中辅助量为
   :math:`\gamma^{-} = \sqrt{1 + (\mathbf{u}^{-})^2/c^2}`，
   :math:`\boldsymbol{\tau} = \mathbf{B}^n q\Delta t/(2m)`，
   :math:`u^{*} = \mathbf{u}^{-}\cdot\boldsymbol{\tau}/c`，
   :math:`\sigma = (\gamma^{-})^2 - \boldsymbol{\tau}^2`，
   :math:`\mathbf{t} = \boldsymbol{\tau}/\gamma^{+}`，
   :math:`s = 1/(1+\mathbf{t}^2)`，并且

   .. math::
      \gamma^{+}
      =
      \sqrt{
      \frac{
      \sigma + \sqrt{\sigma^2 + 4(\tau^2 + (u^{*})^2)}
      }{2}}

   .. note::

      1. 计算 relativistic correction 时需要保持速度、场量、时间步长和光速
         :math:`c` 的量纲一致。

      2. 实现时应检查磁场旋转步骤前后的 proper velocity 模长关系；这通常是判断磁旋转实现是否正确的重要信号。

   .. rubric:: 参考文献

   [1] A.V. Higuera, J.R. Cary, Structure-preserving second-order integration
   of relativistic charged particle trajectories in electromagnetic fields,
   Phys. Plasmas 24 (2017) 052104.
   DOI: `10.1063/1.4979989 <https://doi.org/10.1063/1.4979989>`_.

   [2] B. Ripperda, F. Bacchini, J. Teunissen, C. Xia, O. Porth, L. Sironi,
   G. Lapenta, R. Keppens, A comprehensive comparison of relativistic particle
   integrators, Astrophys. J. Suppl. Ser. 235 (2018) 21.
   DOI: `10.3847/1538-4365/aab114 <https://doi.org/10.3847/1538-4365/aab114>`_.

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Advances one particle velocity with the relativistic Higuera-Cary pusher.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 14 10 28 34 26 40

      * - Parameter
        - Direction
        - Shape / Range
        - Meaning
        - Units / Normalization
        - Index / ghost-cell requirement
      * - ``v``
        - ``in/out``
        - ``real(1:3)``
        - particle velocity vector
        - particle/field units chosen by the caller
        - Single-particle vector with no ghost cells; component order follows the coordinate system on this page.
      * - ``E``
        - ``in``
        - ``real(1:3)``
        - electric field vector at the particle
        - particle/field units chosen by the caller
        - Single-particle vector with no ghost cells; component order follows the coordinate system on this page.
      * - ``B``
        - ``in``
        - ``real(1:3)``
        - magnetic field vector at the particle
        - particle/field units chosen by the caller
        - Single-particle vector with no ghost cells; component order follows the coordinate system on this page.
      * - ``k``
        - ``in``
        - ``real scalar``
        - Boris/Higuera-Cary half-step coefficient, usually q*dt/(2m).
        - charge-to-mass and time-step combination in caller normalization
        - Single-particle scalar with no ghost-cell requirement.

   .. rubric:: Local Assumptions / Preconditions

   - The coordinate system is Cartesian with component order ``(x,y,z)``.
   - This page states only the local routine conventions; it does not assume a global driver unit system, time step, or boundary policy.

   .. rubric:: Implementation Notes

   - Converts velocity to proper velocity, then applies the Higuera-Cary electric kick and magnetic rotation.
   - At the end, the new Lorentz factor converts proper velocity back to ordinary velocity.
   - The source variable ``gamma_minus`` stores
     :math:`(\gamma^-)^2 = 1 + |\mathbf{u}^-|^2/c^2`, not :math:`\gamma^-`
     itself; the formula :math:`\sigma = (\gamma^-)^2 - \boldsymbol{\tau}^2`
     therefore maps directly to ``sigma = gamma_minus - beta2``.

   .. rubric:: Calling Notes

   - The routine handles only a single-particle local update; field gather, particle loops, and boundary handling live above this layer.


   .. rubric:: Generated API

   .. doxygenfile:: sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v.f90

   .. rubric:: Instruction

   The relativistic Higuera-Cary Method:

   Charged particles in the electromagnetic field follow the dynamics of relativistic translation:

   .. math::
       \frac{\mathrm{d}\mathbf{x}}{\mathrm{d}t} = \mathbf{v} = \mathbf{u}/\gamma \quad \gamma = \sqrt{1 + \|\mathbf{u}/c\|^2}

   and the Lorentz force:

   .. math::
       \frac{\mathrm{d}\mathbf{u}}{\mathrm{d}t} = \frac{q}{m} \left( \mathbf{E} + \mathbf{v} \times \mathbf{B} \right)

   A centered finite-difference discretization of the Newton-Lorentz equations of motion is given by [1]_

   .. math::
       \frac{\mathbf{x}^{n+1}-\mathbf{x}^{n}}{\Delta t} = \mathbf{v}^{n+1/2} \quad \Longrightarrow \quad \mathbf{x}^{n+1} = \mathbf{x}^{n} + \Delta t \cdot \mathbf{v}^{n+1/2}

   .. math::
       \frac{\mathbf{u}^{n+1/2}-\mathbf{u}^{n-1/2}}{\Delta t}=\frac{q}{m}{\left(\mathbf{E}^{n}+\bar{\mathbf{{v}}}^{n}\times\mathbf{B}^{n}\right)}

   Explicit calculate [2]_

   .. math::
       \mathbf{u}^{-} = \mathbf{u}^{n-1/2} + \frac{q\Delta t}{2m} \mathbf{E}^n

   .. math::
       \mathbf{u}^{+} = s[\mathbf{u}^{-} + (\mathbf{u}^{-} \cdot \mathbf{t})\mathbf{t} + \mathbf{u}^{-} \times \mathbf{t}]

   .. math::
       \mathbf{u}^{n+1/2} = \mathbf{u}^{+} + \frac{q\Delta t}{2m} \mathbf{E}^n + \mathbf{u}^{+} \times \mathbf{t}

   Here, the auxiliary quantities are :math:`\gamma^{-} = \sqrt{1 + (\mathbf{u}^{-})^2 / c^2}`,
   :math:`\boldsymbol{\tau} = \mathbf{B}^n q\Delta t / (2m)`,
   :math:`u^{*} = \mathbf{u}^{-} \cdot \boldsymbol{\tau} / c`,
   :math:`\sigma = (\gamma^{-})^2 - \boldsymbol{\tau}^2`,
   :math:`\mathbf{t} = \boldsymbol{\tau} / \gamma^{+}`, and
   :math:`s = 1/(1 + \mathbf{t}^2)`, with

   .. math::
       \gamma^{+} = \sqrt{ \frac{ \sigma + \sqrt{ \sigma^2 + 4(\tau^2 + (u^{*})^2) } }{2} }

   .. note::

       1. Pay attention to dimensional consistency regarding the speed of light :math:`c` when computing :math:`γ^{new}`.

       2. When implementing the algorithm, strict attention must be paid to whether the magnitudes of :math:`{u}^{-}` and :math:`{u}^{+}` are equal. This indicates the correctness of the magnetic field rotation step.


   .. [1] A.V. Higuera, J.R. Cary, Structure-preserving second-order integration of relativistic charged particle trajectories in electromagnetic fields, Phys. Plasmas 24 (2017) 052104. DOI: `10.1063/1.4979989 <https://doi.org/10.1063/1.4979989>`_.

   .. [2] B. Ripperda, F. Bacchini, J. Teunissen, C. Xia, O. Porth, L. Sironi, G. Lapenta, R. Keppens,
          A comprehensive comparison of relativistic particle integrators, Astrophys. J. Suppl. Ser. 235 (2018) 21. DOI: `10.3847/1538-4365/aab114 <https://doi.org/10.3847/1538-4365/aab114>`_.
