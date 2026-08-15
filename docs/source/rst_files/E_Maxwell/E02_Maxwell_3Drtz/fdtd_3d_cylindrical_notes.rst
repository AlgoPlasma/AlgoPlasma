3D Cylindrical (rtz) FDTD
=========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 3D Cylindrical (rtz) FDTD

   .. rubric:: 1. 问题定义

   本求解器使用三维柱坐标 :math:`(r,\phi,z)` 处理完整三维电磁问题。不作轴对称约化，
   因此保留 :math:`\partial/\partial\phi` 项。空间离散采用 Yee 交错网格，时间推进采用
   leapfrog 格式。

   该形式适用于柱形几何、旋转结构，以及在柱坐标算子下比直角坐标算子更自然的电磁问题。

   .. figure:: ../../../images/E_Maxwell/E02_3Drtz.png
      :align: center
      :width: 65%

      3D cylindrical ``(r,\phi,z)`` Yee 网格坐标系示意图。

   场分量分别沿径向、方位角向和轴向交错布置。柱坐标中的 metric 项必须在与被更新分量匹配的
   半径位置上计算。

   .. rubric:: 2. 连续方程

   由 :math:`\partial_t\mathbf{E}=(1/\epsilon)\nabla\times\mathbf{H}` 得到电场方程：

   .. math::

      \frac{\partial E_r}{\partial t}
      = \frac{1}{\epsilon}
      \left(
      \frac{1}{r}\frac{\partial H_z}{\partial \phi}
      - \frac{\partial H_\phi}{\partial z}
      \right).

   .. math::

      \frac{\partial E_\phi}{\partial t}
      = \frac{1}{\epsilon}
      \left(
      \frac{\partial H_r}{\partial z}
      - \frac{\partial H_z}{\partial r}
      \right).

   .. math::

      \frac{\partial E_z}{\partial t}
      = \frac{1}{\epsilon}
      \left(
      \frac{1}{r}\frac{\partial (rH_\phi)}{\partial r}
      - \frac{1}{r}\frac{\partial H_r}{\partial \phi}
      \right).

   由 :math:`\partial_t\mathbf{H}=-(1/\mu)\nabla\times\mathbf{E}` 得到磁场方程：

   .. math::

      \frac{\partial H_r}{\partial t}
      = -\frac{1}{\mu}
      \left(
      \frac{1}{r}\frac{\partial E_z}{\partial \phi}
      - \frac{\partial E_\phi}{\partial z}
      \right).

   .. math::

      \frac{\partial H_\phi}{\partial t}
      = -\frac{1}{\mu}
      \left(
      \frac{\partial E_r}{\partial z}
      - \frac{\partial E_z}{\partial r}
      \right).

   .. math::

      \frac{\partial H_z}{\partial t}
      = -\frac{1}{\mu}
      \left(
      \frac{1}{r}\frac{\partial (rE_\phi)}{\partial r}
      - \frac{1}{r}\frac{\partial E_r}{\partial \phi}
      \right).

   柱坐标中有两类关键算子：

   - :math:`(1/r)\partial_\phi(\cdot)`
   - :math:`(1/r)\partial_r(r\cdot)`

   轴线奇异点处理和径向权重规则都来自这两类算子。

   初学者可以先按下面的方式读这些符号：

   - :math:`E_r,E_\phi,E_z` 是电场在径向、方位角向和轴向的分量；
     :math:`H_r,H_\phi,H_z` 是磁场对应方向的分量。
   - 下标 :math:`r,\phi,z` 表示分量方向，不是数组下标；
     数组位置由后面的 :math:`i,j,k` 指标给出。
   - :math:`\epsilon` 是介电常数，:math:`\mu` 是磁导率。
   - :math:`\partial/\partial t` 表示时间导数；
     :math:`\partial/\partial r`、:math:`\partial/\partial \phi`
     和 :math:`\partial/\partial z` 表示三个坐标方向上的空间导数。
   - :math:`1/r` 和 :math:`(1/r)\partial_r(r\cdot)` 是柱坐标 metric
     带来的几何因子；它们必须在正确的 Yee 半径位置上计算。

   .. rubric:: 3. Yee 网格与变量位置

   代码中每个坐标方向使用一个逻辑指标：

   - :math:`i \rightarrow r`
   - :math:`j \rightarrow \phi`
   - :math:`k \rightarrow z`
   - :math:`n \rightarrow` 时间层

   网格步长和时间步长为：

   - :math:`\Delta r,\ \Delta\phi,\ \Delta z,\ \Delta t`

   由于柱坐标 metric 依赖半径，stencil 中需要显式使用节点半径和半节点半径：

   - :math:`r_i=i\Delta r`
   - :math:`r_{i+1/2}=(i+1/2)\Delta r`

   本求解器中的 Yee 分量位置为：

   - :math:`E_r(i+1/2,j,k)`
   - :math:`E_\phi(i,j+1/2,k)`
   - :math:`E_z(i,j,k+1/2)`
   - :math:`H_r(i,j+1/2,k+1/2)`
   - :math:`H_\phi(i+1/2,j,k+1/2)`
   - :math:`H_z(i+1/2,j+1/2,k)`

   等价地，对 :math:`a\in\{r,\phi,z\}`：

   - :math:`E_a`：在 :math:`a` 方向取半指标，在另外两个方向取整数指标。
   - :math:`H_a`：在 :math:`a` 方向取整数指标，在另外两个方向取半指标。

   该布置直接沿用 :ref:`fdtd_cartesian_component_convention` 中的 Cartesian 分量方向约定，
   只是把 :math:`a` 映射为 :math:`r,\phi,z`。

   这些位置的含义是：

   - 每个电场分量与该分量方向的网格边同位。
   - 每个磁场分量在两个横向方向上相对电场偏移半个网格。
   - 这种偏移使每个 curl 项都可以写成交错网格上的最近邻中心差分。

   时间交错为：

   - 电场位于 :math:`n` 时间层。
   - 磁场位于 :math:`n+1/2` 时间层。

   这是标准 Yee leapfrog 配对：由 :math:`\mathbf{E}^n` 推进 :math:`\mathbf{H}`，
   再由 :math:`\mathbf{H}^{n+1/2}` 推进 :math:`\mathbf{E}`。

   后面的离散式中，形如 :math:`F_{i,j,k}^n` 的符号表示场分量
   :math:`F` 在逻辑指标 :math:`(i,j,k)` 和时间层 :math:`n`
   上的数值；半指标如 :math:`i+1/2` 或 :math:`j+1/2`
   表示该分量位于相邻网格点之间。条件 :math:`i>0`
   表示普通内部公式不用于轴线。

   .. rubric:: 4. 离散更新方程

   电场更新：

   .. math::

      E_{r,i+1/2,j,k}^{n+1}
      = E_{r,i+1/2,j,k}^{n}
      + \frac{\Delta t}{\epsilon}
      \left[
      \frac{H_{z,i+1/2,j+1/2,k}^{n+1/2}-H_{z,i+1/2,j-1/2,k}^{n+1/2}}
      {r_{i+1/2}\Delta\phi}
      - \frac{H_{\phi,i+1/2,j,k+1/2}^{n+1/2}-H_{\phi,i+1/2,j,k-1/2}^{n+1/2}}
      {\Delta z}
      \right].

   这是离散 :math:`(\nabla\times\mathbf{H})_r` 项，其中 :math:`\phi` 方向导数的 metric
   使用 :math:`r_{i+1/2}`。

   .. math::

      E_{\phi,i,j+1/2,k}^{n+1}
      = E_{\phi,i,j+1/2,k}^{n}
      + \frac{\Delta t}{\epsilon}
      \left[
      \frac{H_{r,i,j+1/2,k+1/2}^{n+1/2}-H_{r,i,j+1/2,k-1/2}^{n+1/2}}{\Delta z}
      - \frac{H_{z,i+1/2,j+1/2,k}^{n+1/2}-H_{z,i-1/2,j+1/2,k}^{n+1/2}}{\Delta r}
      \right].

   这是离散 :math:`(\nabla\times\mathbf{H})_\phi` 项，其中 :math:`H_z` 使用径向差分。

   .. math::

      E_{z,i,j,k+1/2}^{n+1}
      = E_{z,i,j,k+1/2}^{n}
      + \frac{\Delta t}{\epsilon}
      \left[
      \frac{r_{i+1/2}H_{\phi,i+1/2,j,k+1/2}^{n+1/2}
      - r_{i-1/2}H_{\phi,i-1/2,j,k+1/2}^{n+1/2}}
      {r_i\Delta r}
      - \frac{H_{r,i,j+1/2,k+1/2}^{n+1/2}-H_{r,i,j-1/2,k+1/2}^{n+1/2}}
      {r_i\Delta\phi}
      \right],\ i>0.

   这是离散 :math:`(\nabla\times\mathbf{H})_z` 项，径向部分通过 :math:`rH_\phi`
   的守恒型差分给出。

   磁场更新：

   .. math::

      H_{r,i,j+1/2,k+1/2}^{n+1/2}
      = H_{r,i,j+1/2,k+1/2}^{n-1/2}
      - \frac{\Delta t}{\mu}
      \left[
      \frac{E_{z,i,j+1,k+1/2}^{n}-E_{z,i,j,k+1/2}^{n}}{r_i\Delta\phi}
      - \frac{E_{\phi,i,j+1/2,k+1}^{n}-E_{\phi,i,j+1/2,k}^{n}}{\Delta z}
      \right],\ i>0.

   这是离散 :math:`-(\nabla\times\mathbf{E})_r` 项，其中 :math:`\phi` 方向含柱坐标 metric。

   .. math::

      H_{\phi,i+1/2,j,k+1/2}^{n+1/2}
      = H_{\phi,i+1/2,j,k+1/2}^{n-1/2}
      - \frac{\Delta t}{\mu}
      \left[
      \frac{E_{r,i+1/2,j,k+1}^{n}-E_{r,i+1/2,j,k}^{n}}{\Delta z}
      - \frac{E_{z,i+1,j,k+1/2}^{n}-E_{z,i,j,k+1/2}^{n}}{\Delta r}
      \right].

   这是由 :math:`z` 和 :math:`r` 方向差分构成的离散
   :math:`-(\nabla\times\mathbf{E})_\phi` 项。

   .. math::

      H_{z,i+1/2,j+1/2,k}^{n+1/2}
      = H_{z,i+1/2,j+1/2,k}^{n-1/2}
      - \frac{\Delta t}{\mu}
      \left[
      \frac{r_{i+1}E_{\phi,i+1,j+1/2,k}^{n}
      - r_iE_{\phi,i,j+1/2,k}^{n}}{r_{i+1/2}\Delta r}
      - \frac{E_{r,i+1/2,j+1,k}^{n}-E_{r,i+1/2,j,k}^{n}}
      {r_{i+1/2}\Delta\phi}
      \right].

   这是离散 :math:`-(\nabla\times\mathbf{E})_z` 项，径向部分通过 :math:`rE_\phi`
   的守恒型差分给出。

   .. rubric:: 5. 径向权重规则

   对普通 :math:`(1/r)` 因子，使用当前更新点所在位置的半径
   （根据分量位置取 :math:`r_i` 或 :math:`r_{i+1/2}`）。

   对 :math:`\partial_r(rA)`，采用守恒形式离散：

   .. math::

      \frac{1}{r}\frac{\partial (rA)}{\partial r}
      \ \Rightarrow\
      \frac{r_{i+1/2}A_{i+1/2}-r_{i-1/2}A_{i-1/2}}{r_i\Delta r}.

   数值实现上，这意味着先对 :math:`rA` 做差分，而不是写成
   :math:`r\,\partial_r A`。

   .. rubric:: 6. :math:`r=0` 轴线处理

   含 :math:`1/r` 的更新式不能直接用于轴线节点。对轴线上的 :math:`E_z`，
   该实现使用专门闭合公式：

   .. math::

      E_{z,0,j,k+1/2}^{n+1}
      = E_{z,0,j,k+1/2}^{n}
      + \frac{4\Delta t}{\epsilon\Delta r}\,
      \left\langle H_{\phi,1/2,j,k+1/2}^{n+1/2}\right\rangle_{\phi}.

   该公式来自 Maxwell 方程积分形式在趋于零的小圆环/圆盘上的极限，用来替代奇异的逐点公式。
   其中 :math:`\left\langle\cdot\right\rangle_\phi` 表示沿方位角方向的平均；
   它把第一层离轴环上的 :math:`H_\phi` 合成为轴线 :math:`E_z`
   更新所需的等效环量。

   .. note::

      **轴线方向分量近似：** 在 :math:`r=0` 处，局部径向/方位角向基矢退化，
      轴线上使用的横向分量需要用第一层径向位置上的配对横向分量表示。当前实现中，
      :math:`H_r` 的轴线值用 :math:`H_\phi` 近似，:math:`E_\phi` 的轴线值用
      :math:`E_r` 近似。几何原因是 :math:`H_r` 和 :math:`E_\phi` 在轴线附近都被看作
      局部横向平面中离开轴线的分量，因此第一层离轴横向分量提供一致的轴线闭合值。

   轴线附近单元与普通内部单元必须使用不同的更新规则。

   .. rubric:: 7. :math:`\phi` 方向周期性

   :math:`\phi` 方向是周期方向。指标 :math:`j=0` 与 :math:`j=N_\phi`
   表示同一个物理角度。

   所有 :math:`\phi` 方向差分都必须使用周期回绕，例如通过周期 ghost cell 实现。
   这是拓扑闭合，不是物理外边界条件。

   .. rubric:: 8. 时间推进顺序

   推荐实现顺序为：

   1. 更新 :math:`H_r,\ H_\phi,\ H_z`。
   2. 施加磁场特殊处理，例如轴线约束和周期回绕。
   3. 更新 :math:`E_r,\ E_\phi,\ E_z`。
   4. 施加轴线上 :math:`E_z(r=0)` 的专门修正。
   5. 施加 :math:`\phi` 周期闭合和其它边界算子。

   这是标准 Yee leapfrog 工作流在柱坐标 metric 下的形式。

   .. rubric:: 9. 边界与特殊单元

   实现中应区分三类单元：

   - 普通内部单元
   - 轴线单元
   - :math:`\phi` 接缝单元，即周期回绕位置

   PEC、PMC、CPML 和源项等接口应接在核心 curl 更新之后，同时保持 leapfrog 时间交错和
   Yee 空间交错的一致性。

   .. rubric:: 10. CPML 吸收边界

   三维柱坐标 CPML 对 :math:`r`、:math:`\phi`、:math:`z` 三个坐标方向的
   curl 差分分别做复频移坐标拉伸：

   .. math::

      s_u(\omega)=\kappa_u+\frac{\sigma_u}{\alpha_u+j\omega\epsilon_0},
      \qquad
      D_u q\Rightarrow \frac{D_u q}{\kappa_u}+\psi_u,
      \qquad u\in\{r,\phi,z\}.

   memory 变量在时域中递推：

   .. math::

      \psi_u^n=b_u\psi_u^{n-1}+a_uD_uq^n.

   这组 CPML 公式中的符号含义如下：

   - :math:`u` 表示被拉伸的坐标方向，可取 :math:`r`、:math:`\phi`
     或 :math:`z`。
   - :math:`D_u q` 表示对场量 :math:`q` 做 :math:`u` 方向的有限差分；
     :math:`q` 是占位符，实际可以是某个 :math:`E` 或 :math:`H` 分量。
   - :math:`\psi_u` 是递推卷积 memory 变量；在具体场分量里，
     :math:`\psi_{E_r,\phi}` 表示更新 :math:`E_r` 时，
     方位角向差分对应的 memory 项。
   - :math:`\kappa_u,\sigma_u,\alpha_u` 是 PML 剖面参数；
     :math:`a_u,b_u` 是对应的时域递推系数。
   - :math:`\omega` 是角频率，:math:`j` 是虚数单位，:math:`\epsilon_0`
     是真空介电常数。

   因为柱坐标 curl 含有 :math:`1/r` 和
   :math:`(1/r)\partial_r(r\cdot)`，CPML 只替换对应坐标方向上的差分算子。
   对径向守恒型项，AlgoPlasma 按
   :math:`(1/r)\partial_r(rq)=\partial_r q+q/r` 拆分：memory 变量只作用于
   :math:`\partial_r q`，而 :math:`q/r` 作为柱坐标 metric 项在当前 Yee 位置的半径上单独加回。
   例如 :math:`E_r` 和 :math:`E_z` 的 CPML 形式可写为

   .. math::

      E_r^{n+1}=E_r^n+\frac{\Delta t}{\epsilon}
      \left[
      \frac{1}{r_{i+1/2}}
      \left(\frac{D_\phi H_z}{\kappa_\phi}+\psi_{E_r,\phi}\right)
      -
      \left(\frac{D_zH_\phi}{\kappa_z}+\psi_{E_r,z}\right)
      \right],

   .. math::

      E_z^{n+1}=E_z^n+\frac{\Delta t}{\epsilon}
      \left[
      \left(\frac{D_rH_\phi}{\kappa_r}+\psi_{E_z,r}+M_r(H_\phi)\right)
      -
      \frac{1}{r_i}
      \left(\frac{D_\phi H_r}{\kappa_\phi}+\psi_{E_z,\phi}\right)
      \right],\quad i>0.

   这里 :math:`M_r(q)=\bar q/r` 表示该 Yee 位置上的柱坐标 metric 项。
   :math:`H_z` 中的径向 :math:`E_\phi` 项同样使用
   :math:`D_rE_\phi/\kappa_r+\psi_{H_z,r}+M_r(E_\phi)`，memory 不作用于
   :math:`q/r` metric 项。:math:`E_\phi`、:math:`H_r`、:math:`H_\phi` 和
   :math:`H_z` 按同样方式对
   各自 curl 中的两个横向差分引入 memory 项。AlgoPlasma 的
   ``sub_E02_cpml_3d_cylindrical_E`` 与 ``sub_E02_cpml_3d_cylindrical_H`` 对六个场
   分量共保存十二个 ``psi_*`` 数组，例如 ``psi_E_r_phi``、
   ``psi_E_r_z``、``psi_E_phi_z``、``psi_E_phi_r``、``psi_E_z_r``、
   ``psi_E_z_phi`` 以及对应的磁场 memory 数组。

   :math:`\phi` 方向在本页基础 FDTD 中是周期方向；若仍使用完整圆周周期边界，
   则 :math:`\phi` 方向 CPML 系数应退化为内部区取值
   :math:`\kappa_\phi=1`、:math:`a_\phi=0`、:math:`b_\phi=1`。只有在模拟
   非周期角扇区或人为截断的角向区域时，才应给 :math:`\phi` 方向设置真实
   吸收层。

   轴线 :math:`r=0` 不是 PML。CPML 例程在 ``i=0`` 使用与非 CPML FDTD
   相同的轴线闭合：``Ephi(0)=Er(0)``、``Hr(0)=Hphi(0)``，并用
   :math:`4\Delta t/(\epsilon\Delta r)` 形式的轴线 :math:`E_z` 更新替代
   含 :math:`1/r` 的普通 :math:`E_z` 公式。

   .. rubric:: 11. 参考文献

   - `Inan U S, Marshall R A. *Numerical electromagnetics: the FDTD method*. Cambridge University Press, 2011. <https://books.google.com/books?hl=zh-CN&lr=&id=mGdH_W0YBdQC&oi=fnd&pg=PR7&dq=Numerical+Electromagnetics++The+FDTD+Method&ots=G2FOsDB5R5&sig=vPvGj05ui_Fn1uDbmyEOqIFgqt0#v=onepage&q=Numerical%20Electromagnetics%20%20The%20FDTD%20Method&f=false>`_
   - Roden J A, Gedney S D. Convolution PML (CPML): An efficient FDTD implementation of the CFS-PML for arbitrary media.
     *Microwave and Optical Technology Letters*, 27(5): 334-339, 2000.
     DOI: `10.1002/1098-2760(20001205)27:5\<334::AID-MOP14\>3.0.CO;2-A <https://doi.org/10.1002/1098-2760(20001205)27:5%3C334::AID-MOP14%3E3.0.CO;2-A>`_.

.. container:: ap-lang ap-lang-en

   .. rubric:: 3D Cylindrical (rtz) FDTD

   .. rubric:: 1. Problem Definition

   This solver uses cylindrical coordinates :math:`(r,\phi,z)` for a full 3D
   electromagnetic problem. No axisymmetric reduction is assumed, so
   :math:`\partial/\partial\phi` is retained. Spatial discretization uses a Yee
   staggered grid and time integration uses a leapfrog scheme.

   This formulation is natural for cylindrical geometries, rotating structures,
   and cases where cylindrical operators are simpler than Cartesian operators.

   .. figure:: ../../../images/E_Maxwell/E02_3Drtz.png
      :align: center
      :width: 65%

      3D cylindrical ``(r,\phi,z)`` Yee-grid coordinate system.

   The field components are staggered on radial, azimuthal, and axial directions,
   and cylindrical metric terms are evaluated with the matching radius locations.

   .. rubric:: 2. Continuous Equations

   The electric-field equations from :math:`\partial_t\mathbf{E}
   =(1/\epsilon)\nabla\times\mathbf{H}` are:

   .. math::

      \frac{\partial E_r}{\partial t}
      = \frac{1}{\epsilon}
      \left(
      \frac{1}{r}\frac{\partial H_z}{\partial \phi}
      - \frac{\partial H_\phi}{\partial z}
      \right).

   .. math::

      \frac{\partial E_\phi}{\partial t}
      = \frac{1}{\epsilon}
      \left(
      \frac{\partial H_r}{\partial z}
      - \frac{\partial H_z}{\partial r}
      \right).

   .. math::

      \frac{\partial E_z}{\partial t}
      = \frac{1}{\epsilon}
      \left(
      \frac{1}{r}\frac{\partial (rH_\phi)}{\partial r}
      - \frac{1}{r}\frac{\partial H_r}{\partial \phi}
      \right).

   The magnetic-field equations from :math:`\partial_t\mathbf{H}
   =-(1/\mu)\nabla\times\mathbf{E}` are:

   .. math::

      \frac{\partial H_r}{\partial t}
      = -\frac{1}{\mu}
      \left(
      \frac{1}{r}\frac{\partial E_z}{\partial \phi}
      - \frac{\partial E_\phi}{\partial z}
      \right).

   .. math::

      \frac{\partial H_\phi}{\partial t}
      = -\frac{1}{\mu}
      \left(
      \frac{\partial E_r}{\partial z}
      - \frac{\partial E_z}{\partial r}
      \right).

   .. math::

      \frac{\partial H_z}{\partial t}
      = -\frac{1}{\mu}
      \left(
      \frac{1}{r}\frac{\partial (rE_\phi)}{\partial r}
      - \frac{1}{r}\frac{\partial E_r}{\partial \phi}
      \right).

   Two cylindrical-specific operator families are critical:

   - :math:`(1/r)\partial_\phi(\cdot)`
   - :math:`(1/r)\partial_r(r\cdot)`

   Axis singular handling and all radial weighting rules come from these terms.

   For a first reading, use this notation map:

   - :math:`E_r,E_\phi,E_z` are electric-field components in the radial,
     azimuthal, and axial directions; :math:`H_r,H_\phi,H_z` are the
     corresponding magnetic-field components.
   - Subscripts :math:`r,\phi,z` denote component directions, not array indices;
     array locations are given later by :math:`i,j,k`.
   - :math:`\epsilon` is permittivity and :math:`\mu` is permeability.
   - :math:`\partial/\partial t` is a time derivative, while
     :math:`\partial/\partial r`, :math:`\partial/\partial \phi`, and
     :math:`\partial/\partial z` are spatial derivatives in the three coordinate
     directions.
   - :math:`1/r` and :math:`(1/r)\partial_r(r\cdot)` are cylindrical metric
     factors and must be evaluated at the correct Yee radius location.

   .. rubric:: 3. Yee Grid and Variable Locations

   The code uses one logical index per coordinate direction:

   - :math:`i \rightarrow r`
   - :math:`j \rightarrow \phi`
   - :math:`k \rightarrow z`
   - :math:`n \rightarrow` time level

   Grid and time steps are:

   - :math:`\Delta r,\ \Delta\phi,\ \Delta z,\ \Delta t`

   Because cylindrical metrics depend on radius, both node and half-node radii
   are used explicitly in the stencil:

   - :math:`r_i=i\Delta r`
   - :math:`r_{i+1/2}=(i+1/2)\Delta r`

   Yee placement in this solver is:

   - :math:`E_r(i+1/2,j,k)`
   - :math:`E_\phi(i,j+1/2,k)`
   - :math:`E_z(i,j,k+1/2)`
   - :math:`H_r(i,j+1/2,k+1/2)`
   - :math:`H_\phi(i+1/2,j,k+1/2)`
   - :math:`H_z(i+1/2,j+1/2,k)`

   Equivalent naming rule (for :math:`a\in\{r,\phi,z\}`):

   - :math:`E_a`: half index in direction :math:`a`, integer indices in the other
     two directions
   - :math:`H_a`: integer index in direction :math:`a`, half indices in the other
     two directions

   This placement directly follows the Cartesian component-direction convention in
   :ref:`fdtd_cartesian_component_convention`, with :math:`a` mapped to
   :math:`r,\phi,z`.

   Interpretation of these locations:

   - each electric component is collocated with the edge direction of that
     component
   - each magnetic component is shifted by half a cell in the two transverse
     directions
   - this offset makes each curl term a nearest-neighbor central difference on
     the staggered grid

   Time staggering is:

   - electric fields at :math:`n`
   - magnetic fields at :math:`n+1/2`

   This is the standard Yee leapfrog pair, where :math:`\mathbf{H}` is advanced
   from :math:`\mathbf{E}^n` and :math:`\mathbf{E}` is advanced from
   :math:`\mathbf{H}^{n+1/2}`.

   In the discrete equations below, a symbol such as :math:`F_{i,j,k}^n` means
   field component :math:`F` at logical indices :math:`(i,j,k)` and time level
   :math:`n`. Half indices such as :math:`i+1/2` or :math:`j+1/2` mean that the
   component is stored halfway between neighboring grid points. The condition
   :math:`i>0` means that the regular interior formula is not used on the axis.

   .. rubric:: 4. Discrete Update Equations

   Electric-field updates:

   .. math::

      E_{r,i+1/2,j,k}^{n+1}
      = E_{r,i+1/2,j,k}^{n}
      + \frac{\Delta t}{\epsilon}
      \left[
      \frac{H_{z,i+1/2,j+1/2,k}^{n+1/2}-H_{z,i+1/2,j-1/2,k}^{n+1/2}}
      {r_{i+1/2}\Delta\phi}
      - \frac{H_{\phi,i+1/2,j,k+1/2}^{n+1/2}-H_{\phi,i+1/2,j,k-1/2}^{n+1/2}}
      {\Delta z}
      \right].

   This is the discrete :math:`(\nabla\times\mathbf{H})_r` term with
   :math:`r_{i+1/2}` in the :math:`\phi` derivative metric.

   .. math::

      E_{\phi,i,j+1/2,k}^{n+1}
      = E_{\phi,i,j+1/2,k}^{n}
      + \frac{\Delta t}{\epsilon}
      \left[
      \frac{H_{r,i,j+1/2,k+1/2}^{n+1/2}-H_{r,i,j+1/2,k-1/2}^{n+1/2}}{\Delta z}
      - \frac{H_{z,i+1/2,j+1/2,k}^{n+1/2}-H_{z,i-1/2,j+1/2,k}^{n+1/2}}{\Delta r}
      \right].

   This is the discrete :math:`(\nabla\times\mathbf{H})_\phi` term with radial
   difference on :math:`H_z`.

   .. math::

      E_{z,i,j,k+1/2}^{n+1}
      = E_{z,i,j,k+1/2}^{n}
      + \frac{\Delta t}{\epsilon}
      \left[
      \frac{r_{i+1/2}H_{\phi,i+1/2,j,k+1/2}^{n+1/2}
      - r_{i-1/2}H_{\phi,i-1/2,j,k+1/2}^{n+1/2}}
      {r_i\Delta r}
      - \frac{H_{r,i,j+1/2,k+1/2}^{n+1/2}-H_{r,i,j-1/2,k+1/2}^{n+1/2}}
      {r_i\Delta\phi}
      \right],\ i>0.

   This is the discrete :math:`(\nabla\times\mathbf{H})_z` term with conservative
   radial weighting through :math:`rH_\phi`.

   Magnetic-field updates:

   .. math::

      H_{r,i,j+1/2,k+1/2}^{n+1/2}
      = H_{r,i,j+1/2,k+1/2}^{n-1/2}
      - \frac{\Delta t}{\mu}
      \left[
      \frac{E_{z,i,j+1,k+1/2}^{n}-E_{z,i,j,k+1/2}^{n}}{r_i\Delta\phi}
      - \frac{E_{\phi,i,j+1/2,k+1}^{n}-E_{\phi,i,j+1/2,k}^{n}}{\Delta z}
      \right],\ i>0.

   This is the discrete :math:`-(\nabla\times\mathbf{E})_r` term with cylindrical
   metric in :math:`\phi`.

   .. math::

      H_{\phi,i+1/2,j,k+1/2}^{n+1/2}
      = H_{\phi,i+1/2,j,k+1/2}^{n-1/2}
      - \frac{\Delta t}{\mu}
      \left[
      \frac{E_{r,i+1/2,j,k+1}^{n}-E_{r,i+1/2,j,k}^{n}}{\Delta z}
      - \frac{E_{z,i+1,j,k+1/2}^{n}-E_{z,i,j,k+1/2}^{n}}{\Delta r}
      \right].

   This is the discrete :math:`-(\nabla\times\mathbf{E})_\phi` term from
   :math:`z` and :math:`r` differences.

   .. math::

      H_{z,i+1/2,j+1/2,k}^{n+1/2}
      = H_{z,i+1/2,j+1/2,k}^{n-1/2}
      - \frac{\Delta t}{\mu}
      \left[
      \frac{r_{i+1}E_{\phi,i+1,j+1/2,k}^{n}
      - r_iE_{\phi,i,j+1/2,k}^{n}}{r_{i+1/2}\Delta r}
      - \frac{E_{r,i+1/2,j+1,k}^{n}-E_{r,i+1/2,j,k}^{n}}
      {r_{i+1/2}\Delta\phi}
      \right].

   This is the discrete :math:`-(\nabla\times\mathbf{E})_z` term with conservative
   radial weighting through :math:`rE_\phi`.

   .. rubric:: 5. Radial Weighting Rules

   For plain :math:`(1/r)` factors, use the radius of the current update point
   (:math:`r_i` or :math:`r_{i+1/2}` according to component location).

   For :math:`\partial_r(rA)`, discretize in conservative form:

   .. math::

      \frac{1}{r}\frac{\partial (rA)}{\partial r}
      \ \Rightarrow\
      \frac{r_{i+1/2}A_{i+1/2}-r_{i-1/2}A_{i-1/2}}{r_i\Delta r}.

   Numerically, this means "difference of :math:`rA`", not
   :math:`r\,\partial_r A`.

   .. rubric:: 6. Axis Handling at :math:`r=0`

   Updates containing :math:`1/r` cannot be applied directly at axis nodes.
   For :math:`E_z` on axis, this implementation uses a dedicated closure:

   .. math::

      E_{z,0,j,k+1/2}^{n+1}
      = E_{z,0,j,k+1/2}^{n}
      + \frac{4\Delta t}{\epsilon\Delta r}\,
      \left\langle H_{\phi,1/2,j,k+1/2}^{n+1/2}\right\rangle_{\phi}.

   This comes from integral-form Maxwell on a vanishing circular loop/disc and
   replaces the singular pointwise formula.
   Here :math:`\left\langle\cdot\right\rangle_\phi` denotes an azimuthal
   average; it combines :math:`H_\phi` on the first off-axis ring into the
   effective circulation needed for the on-axis :math:`E_z` update.

   .. note::

      **Axis-direction component approximation:** At :math:`r=0`, the local
      radial/azimuthal basis is degenerate, so the in-plane component used at the
      axis is represented by its paired transverse component from the first radial
      layer. In this implementation, :math:`H_r` on axis is approximated using
      :math:`H_\phi`, and :math:`E_\phi` on axis is approximated using
      :math:`E_r`. The geometric reason is that both :math:`H_r` and
      :math:`E_\phi` are treated as components pointing away from the axis in the
      local transverse plane, so the first off-axis transverse component provides
      the consistent axis closure value.

   Axis-near cells and interior cells must be updated with different rules.

   .. rubric:: 7. Phi Periodicity

   The :math:`\phi` direction is periodic. Indices :math:`j=0` and
   :math:`j=N_\phi` represent the same physical angle.

   All :math:`\phi`-direction differences must use periodic wrap-around, for
   example through periodic ghost cells. This is topological closure, not a
   physical outer boundary condition.

   .. rubric:: 8. Time-Stepping Order

   Recommended implementation order:

   1. Update :math:`H_r,\ H_\phi,\ H_z`.
   2. Apply magnetic-field special handling (axis constraints, periodic wrap).
   3. Update :math:`E_r,\ E_\phi,\ E_z`.
   4. Apply axis-specific :math:`E_z(r=0)` correction.
   5. Apply :math:`\phi` periodic closure and other boundary operators.

   This is the standard Yee leapfrog workflow adapted to cylindrical metrics.

   .. rubric:: 9. Boundaries and Special Cells

   Three cell categories should be handled separately:

   - regular interior cells
   - axis cells
   - :math:`\phi` seam cells (periodic wrap)

   Interfaces for PEC/PMC/CPML/source terms should attach after the core curl
   updates, while preserving the leapfrog and staggering consistency.

   .. rubric:: 10. CPML Absorbing Boundaries

   In 3D cylindrical coordinates, CPML stretches the curl finite differences in
   the :math:`r`, :math:`\phi`, and :math:`z` directions separately:

   .. math::

      s_u(\omega)=\kappa_u+\frac{\sigma_u}{\alpha_u+j\omega\epsilon_0},
      \qquad
      D_u q\Rightarrow \frac{D_u q}{\kappa_u}+\psi_u,
      \qquad u\in\{r,\phi,z\}.

   The time-domain memory variable is updated recursively:

   .. math::

      \psi_u^n=b_u\psi_u^{n-1}+a_uD_uq^n.

   The CPML notation means:

   - :math:`u` is the stretched coordinate direction, one of :math:`r`,
     :math:`\phi`, or :math:`z`.
   - :math:`D_u q` is the finite difference of field quantity :math:`q` in the
     :math:`u` direction; :math:`q` is a placeholder for an actual electric or
     magnetic component.
   - :math:`\psi_u` is the recursive-convolution memory variable. In component
     equations, :math:`\psi_{E_r,\phi}` means the memory term for the azimuthal
     derivative used while updating :math:`E_r`.
   - :math:`\kappa_u,\sigma_u,\alpha_u` are PML profile parameters;
     :math:`a_u,b_u` are the corresponding time-domain recursion coefficients.
   - :math:`\omega` is angular frequency, :math:`j` is the imaginary unit, and
     :math:`\epsilon_0` is vacuum permittivity.

   Cylindrical curls include :math:`1/r` factors and
   :math:`(1/r)\partial_r(r\cdot)` terms. CPML replaces the coordinate finite
   difference. For conservative radial terms, AlgoPlasma uses
   :math:`(1/r)\partial_r(rq)=\partial_r q+q/r`: the memory variable is applied
   only to :math:`\partial_r q`, while the :math:`q/r` cylindrical metric term is
   added separately at the current Yee radius. For example, the :math:`E_r` and
   :math:`E_z` updates become

   .. math::

      E_r^{n+1}=E_r^n+\frac{\Delta t}{\epsilon}
      \left[
      \frac{1}{r_{i+1/2}}
      \left(\frac{D_\phi H_z}{\kappa_\phi}+\psi_{E_r,\phi}\right)
      -
      \left(\frac{D_zH_\phi}{\kappa_z}+\psi_{E_r,z}\right)
      \right],

   .. math::

      E_z^{n+1}=E_z^n+\frac{\Delta t}{\epsilon}
      \left[
      \left(\frac{D_rH_\phi}{\kappa_r}+\psi_{E_z,r}+M_r(H_\phi)\right)
      -
      \frac{1}{r_i}
      \left(\frac{D_\phi H_r}{\kappa_\phi}+\psi_{E_z,\phi}\right)
      \right],\quad i>0.

   Here :math:`M_r(q)=\bar q/r` denotes the cylindrical metric term at the
   matching Yee location. The radial :math:`E_\phi` term in :math:`H_z` uses the
   same split,
   :math:`D_rE_\phi/\kappa_r+\psi_{H_z,r}+M_r(E_\phi)`, so the memory variable
   does not act on the :math:`q/r` metric term. :math:`E_\phi`, :math:`H_r`,
   :math:`H_\phi`, and :math:`H_z` follow the
   same rule: each transverse curl difference gets its own memory term. AlgoPlasma
   stores twelve memory arrays across ``sub_E02_cpml_3d_cylindrical_E`` and
   ``sub_E02_cpml_3d_cylindrical_H``, such as ``psi_E_r_phi``, ``psi_E_r_z``,
   ``psi_E_phi_z``, ``psi_E_phi_r``, ``psi_E_z_r``, ``psi_E_z_phi``, and the
   corresponding magnetic-field arrays.

   The :math:`\phi` direction is periodic in the base solver. For a full
   periodic cylinder, the :math:`\phi` CPML coefficients should reduce to
   interior values, :math:`\kappa_\phi=1`, :math:`a_\phi=0`, and
   :math:`b_\phi=1`. A real :math:`\phi` PML is appropriate only for a
   truncated angular sector or another intentionally non-periodic angular
   domain.

   The axis :math:`r=0` is not a PML boundary. The CPML kernels use the same
   axis closures as the non-CPML FDTD update at ``i=0``: ``Ephi(0)=Er(0)``,
   ``Hr(0)=Hphi(0)``, and the :math:`4\Delta t/(\epsilon\Delta r)` axis
   update for :math:`E_z` instead of the singular :math:`1/r` formula.

   .. rubric:: 11. Reference

   - `Inan U S, Marshall R A. *Numerical electromagnetics: the FDTD method*. Cambridge University Press, 2011. <https://books.google.com/books?hl=zh-CN&lr=&id=mGdH_W0YBdQC&oi=fnd&pg=PR7&dq=Numerical+Electromagnetics++The+FDTD+Method&ots=G2FOsDB5R5&sig=vPvGj05ui_Fn1uDbmyEOqIFgqt0#v=onepage&q=Numerical%20Electromagnetics%20%20The%20FDTD%20Method&f=false>`_
   - Roden J A, Gedney S D. Convolution PML (CPML): An efficient FDTD implementation of the CFS-PML for arbitrary media.
     *Microwave and Optical Technology Letters*, 27(5): 334-339, 2000.
     DOI: `10.1002/1098-2760(20001205)27:5\<334::AID-MOP14\>3.0.CO;2-A <https://doi.org/10.1002/1098-2760(20001205)27:5%3C334::AID-MOP14%3E3.0.CO;2-A>`_.
