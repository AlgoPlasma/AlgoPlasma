2D Cylindrical (rz) FDTD
========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 2D 轴对称柱坐标 (rz) FDTD

   .. rubric:: 1. 问题定义

   本页说明二维轴对称柱坐标 :math:`(r,z)` 中的 Maxwell 方程组有限差分时域法
   （Finite-Difference Time-Domain, FDTD）离散。轴对称假设为：

   .. math::

      \frac{\partial}{\partial \phi}=0.

   空间上采用 Yee 交错网格，时间上采用 leapfrog 交错推进：电场
   :math:`\mathbf{E}` 位于整数时间层，磁场 :math:`\mathbf{H}` 位于半整数时间层。

   .. figure:: ../../../images/E_Maxwell/E01_2Drz.png
      :align: center
      :width: 65%

      2D 轴对称柱坐标 ``(r,z)`` Yee 网格示意图。

   坐标原点位于对称轴 :math:`r=0`。由于柱坐标方程中含有
   :math:`1/r` 型项，轴线处不能直接套用内部点 stencil，必须使用专门的轴线闭合公式。

   .. rubric:: 2. 模式分裂

   在 :math:`\partial/\partial\phi=0` 下，完整柱坐标 Maxwell 方程可以分裂成两个互不耦合的子系统：

   - **TEz 模式** （:math:`E_z=0`）：非零分量为
     :math:`H_r,\ E_\phi,\ H_z`。
   - **TMz 模式** （:math:`H_z=0`）：非零分量为
     :math:`E_r,\ H_\phi,\ E_z`。

   AlgoPlasma 源文件名、module 名和 routine 名使用 ``tez`` 与 ``tmz`` 后缀，分别对应上述 TEz 与 TMz 分量组。

   .. rubric:: 3. 连续方程

   **TEz 子系统：**

   .. math::

      \frac{\partial E_\phi}{\partial t}
      = \frac{1}{\epsilon}\left(\frac{\partial H_r}{\partial z}
      - \frac{\partial H_z}{\partial r}\right).

   该式用磁场旋度更新方位向电场 :math:`E_\phi`。

   .. math::

      \frac{\partial H_r}{\partial t}
      = \frac{1}{\mu}\frac{\partial E_\phi}{\partial z},
      \qquad
      \frac{\partial H_z}{\partial t}
      = -\frac{1}{\mu r}\frac{\partial (rE_\phi)}{\partial r}.

   这两式用 :math:`E_\phi` 的旋度项更新磁场分量。

   **TMz 子系统：**

   .. math::

      \frac{\partial E_r}{\partial t}
      = -\frac{1}{\epsilon}\frac{\partial H_\phi}{\partial z},
      \qquad
      \frac{\partial E_z}{\partial t}
      = \frac{1}{\epsilon r}\frac{\partial (rH_\phi)}{\partial r}.

   这两式用 :math:`H_\phi` 的旋度项更新电场分量。

   .. math::

      \frac{\partial H_\phi}{\partial t}
      = \frac{1}{\mu}\left(\frac{\partial E_z}{\partial r}
      - \frac{\partial E_r}{\partial z}\right).

   该式用电场旋度更新方位向磁场 :math:`H_\phi`。

   初读这些公式时，可先按下面的符号理解：

   - :math:`E_r,E_\phi,E_z` 是电场在径向、方位角向和轴向的分量；
     :math:`H_r,H_\phi,H_z` 是磁场对应方向的分量。
   - 下标 :math:`r,\phi,z` 表示分量方向，不是数组下标；
     本页的轴对称假设使所有物理量不随 :math:`\phi` 变化。
   - :math:`\epsilon` 是介电常数，:math:`\mu` 是磁导率；
     若介质均匀，它们可看作常数。
   - :math:`\partial/\partial t` 表示时间导数；
     :math:`\partial/\partial r` 和 :math:`\partial/\partial z`
     表示沿径向和轴向的空间导数。
   - :math:`(1/r)\partial_r(r\cdot)` 是柱坐标特有的 metric 项；
     它是轴线处理和径向守恒差分的来源。

   .. rubric:: 4. Yee 网格与交错位置

   令 :math:`i,k,n` 分别表示径向网格指标、轴向网格指标和整数时间层：
   :math:`r_i=i\Delta r`，:math:`r_{i+1/2}=(i+1/2)\Delta r`，
   :math:`z_k=k\Delta z`，:math:`z_{k+1/2}=(k+1/2)\Delta z`，
   :math:`t^n=n\Delta t`。

   - 时间交错：:math:`\mathbf{E}^n` 与 :math:`\mathbf{H}^{n+1/2}`。
   - **TMz 分量位置：**

     - :math:`E_r(i+1/2,k)`
     - :math:`E_z(i,k+1/2)`
     - :math:`H_\phi(i+1/2,k+1/2)`

   - **TEz 分量位置：**

     - :math:`E_\phi(i,k)`
     - :math:`H_r(i,k+1/2)`
     - :math:`H_z(i+1/2,k)`

   等价地，从三维柱坐标 Yee 网格的分量方向规则出发，对
   :math:`a\in\{r,\phi,z\}`：

   - :math:`E_a`：在 :math:`a` 方向取半指标，在另外两个方向取整数指标。
   - :math:`H_a`：在 :math:`a` 方向取整数指标，在另外两个方向取半指标。

   在 :math:`\partial/\partial\phi=0` 的轴对称约化下，上述三维规则就退化为这里列出的
   2D :math:`(r,z)` 布局。这个分量方向约定与
   :ref:`fdtd_cartesian_component_convention` 中定义的 Cartesian FDTD 约定一致。

   后面的离散式中，形如 :math:`F_{i,k}^n` 的符号表示场分量
   :math:`F` 在径向指标 :math:`i`、轴向指标 :math:`k`、时间层
   :math:`n` 上的数值；:math:`i+1/2` 或 :math:`k+1/2`
   表示该分量放在相邻网格点之间的半格位置。
   条件 :math:`i>0` 表示该公式只用于离开轴线的内部点。

   .. rubric:: 5. 二阶中心差分离散更新公式

   **TEz 模式更新：**

   .. math::

      E_{\phi,i,k}^{n+1}
      = E_{\phi,i,k}^{n}
      + \frac{\Delta t}{\epsilon}
      \left[
      \frac{H_{r,i,k+1/2}^{n+1/2}-H_{r,i,k-1/2}^{n+1/2}}{\Delta z}
      - \frac{H_{z,i+1/2,k}^{n+1/2}-H_{z,i-1/2,k}^{n+1/2}}{\Delta r}
      \right],\ i>0.

   该式由离散 :math:`\nabla\times\mathbf{H}` 更新 :math:`E_\phi`。

   .. math::

      H_{r,i,k+1/2}^{n+1/2}
      = H_{r,i,k+1/2}^{n-1/2}
      + \frac{\Delta t}{\mu}
      \frac{E_{\phi,i,k+1}^{n}-E_{\phi,i,k}^{n}}{\Delta z},\ i>0.

   该式由 :math:`E_\phi` 的轴向导数更新 :math:`H_r`。

   .. note::

      **更正（TEz 模式的 H_r 更新）：** 参考书中该式有时会被印成
      :math:`H_r^{n+1/2}=H_r^{n-1/2}-\cdots`。这里采用上式所示的正确正号形式，
      即 :math:`H_r^{n+1/2}=H_r^{n-1/2}+\cdots`。

   .. math::

      H_{z,i+1/2,k}^{n+1/2}
      = H_{z,i+1/2,k}^{n-1/2}
      - \frac{\Delta t}{\mu}
      \frac{r_{i+1}E_{\phi,i+1,k}^{n}-r_iE_{\phi,i,k}^{n}}
      {r_{i+1/2}\Delta r}.

   该式使用守恒形式的 :math:`(1/r)\partial_r(rE_\phi)` 更新 :math:`H_z`。

   **TMz 模式更新：**

   .. math::

      E_{r,i+1/2,k}^{n+1}
      = E_{r,i+1/2,k}^{n}
      - \frac{\Delta t}{\epsilon}
      \frac{H_{\phi,i+1/2,k+1/2}^{n+1/2}
      - H_{\phi,i+1/2,k-1/2}^{n+1/2}}{\Delta z}.

   该式由 :math:`H_\phi` 的轴向变化更新 :math:`E_r`。

   .. note::

      **更正（TMz 模式的 E_r 更新）：** 参考书中该式有时会被印成
      :math:`E_r^{n+1}=E_r^n+\cdots`。这里采用上式所示的正确负号形式，
      即 :math:`E_r^{n+1}=E_r^n-\cdots`。

   .. math::

      E_{z,i,k+1/2}^{n+1}
      = E_{z,i,k+1/2}^{n}
      + \frac{\Delta t}{\epsilon}
      \frac{1}{r_i}
      \frac{r_{i+1/2}H_{\phi,i+1/2,k+1/2}^{n+1/2}
      - r_{i-1/2}H_{\phi,i-1/2,k+1/2}^{n+1/2}}
      {\Delta r},\ i>0.

   该式由 :math:`rH_\phi` 的径向散度更新 :math:`E_z`。

   .. math::

      H_{\phi,i+1/2,k+1/2}^{n+1/2}
      = H_{\phi,i+1/2,k+1/2}^{n-1/2}
      + \frac{\Delta t}{\mu}
      \left[
      \frac{E_{z,i+1,k+1/2}^{n}-E_{z,i,k+1/2}^{n}}{\Delta r}
      - \frac{E_{r,i+1/2,k+1}^{n}-E_{r,i+1/2,k}^{n}}{\Delta z}
      \right].

   该式由离散电场旋度更新 :math:`H_\phi`。

   .. rubric:: 6. :math:`r=0` 轴线处理

   :math:`(1/r)\partial_r(r\cdot)` 型项在轴线上奇异，不能直接使用内部点公式。

   对 TMz 子系统中 :math:`r=0` 处的 :math:`E_z`，闭合公式可由 Ampere-Maxwell 定律的积分形式得到。
   取以轴线为中心、半径为 :math:`\Delta r/2` 的小圆盘 :math:`S`，并取单位 :math:`z` 向厚度：

   .. math::

      \frac{\partial}{\partial t}\int_S \epsilon E_z\,dS
      = \oint_{\partial S} H_\phi\,dl.

   这里 :math:`S` 是轴线附近的小圆盘，:math:`\partial S` 是圆盘边界；
   :math:`dS` 和 :math:`dl` 分别表示面积微元和线元。

   在轴对称近似下，:math:`E_z` 在 :math:`S` 上近似均匀，边界
   :math:`\partial S` 上的 :math:`H_\phi` 用
   :math:`H_{\phi,1/2,k+1/2}^{n+1/2}` 表示：

   .. math::

      \epsilon\pi\left(\frac{\Delta r}{2}\right)^2
      \frac{\partial E_z}{\partial t}
      =
      2\pi\left(\frac{\Delta r}{2}\right)H_{\phi,1/2,k+1/2}.

   因此，

   .. math::

      \frac{\partial E_z}{\partial t}
      = \frac{4}{\epsilon\Delta r}H_{\phi,1/2,k+1/2}.

   采用 leapfrog 时间离散后得到：

   .. math::

      E_{z,0,k+1/2}^{n+1}
      = E_{z,0,k+1/2}^{n}
      + \frac{4\Delta t}{\epsilon\Delta r}
      H_{\phi,1/2,k+1/2}^{n+1/2}.

   这是代码中用于稳定、一致更新 TMz 子系统轴线 :math:`E_z` 的闭合公式。

   对当前代码中的 :math:`(E_\phi,H_r,H_z)` 子系统，
   :math:`E_{\phi,0,k}=0` 和 :math:`H_{r,0,k+1/2}=0` 是显式约束。
   :math:`H_z` 存储在 :math:`i+1/2` 位置，因此不直接落在奇异轴点
   :math:`r=0` 上，也就不需要单独的轴线更新公式。

   .. rubric:: 7. CPML 吸收边界

   轴对称 :math:`(r,z)` 问题只需要在径向外边界和轴向端面设置吸收层；
   :math:`r=0` 是几何对称轴，不应作为普通 PML 边界处理。CPML 对每个
   被拉伸方向 :math:`u\in\{r,z\}` 使用复频移坐标拉伸

   .. math::

      s_u(\omega)=\kappa_u+\frac{\sigma_u}{\alpha_u+j\omega\epsilon_0},
      \qquad
      D_u q\Rightarrow \frac{D_u q}{\kappa_u}+\psi_u,

   其中 memory 变量递推为

   .. math::

      \psi_u^n=b_u\psi_u^{n-1}+a_u D_u q^n.

   这组 CPML 公式中的符号含义如下：

   - :math:`u` 表示被拉伸的坐标方向，本页只取 :math:`r` 或 :math:`z`。
   - :math:`D_u q` 表示对场量 :math:`q` 做 :math:`u` 方向的有限差分；
     :math:`q` 只是占位符，实际可以是某个 :math:`E` 或 :math:`H` 分量。
   - :math:`\psi_u` 是递推卷积 memory 变量，用来保存 PML 对该方向导数的历史贡献；
     在具体更新式中常写成 :math:`\psi_{F,u}`，表示更新场分量
     :math:`F` 时对应 :math:`u` 方向导数的 memory。
   - :math:`\kappa_u,\sigma_u,\alpha_u` 是 PML 剖面参数；
     :math:`a_u,b_u` 是由这些剖面参数和 :math:`\Delta t` 得到的递推系数。
   - :math:`\omega` 是角频率，:math:`j` 是虚数单位，:math:`\epsilon_0`
     是真空介电常数。

   :math:`(E_\phi,H_r,H_z)` **子系统。** 对 :math:`E_\phi` 的两个 curl
   差分分别引入 ``z`` 和 ``r`` 方向 memory：

   .. math::

      E_\phi^{n+1}=E_\phi^n+\frac{\Delta t}{\epsilon}
      \left[
      \left(\frac{D_zH_r}{\kappa_z}+\psi_{E_\phi,z}\right)
      -
      \left(\frac{D_rH_z}{\kappa_r}+\psi_{E_\phi,r}\right)
      \right].

   :math:`H_r` 只包含 :math:`z` 向导数：

   .. math::

      H_r^{n+1/2}=H_r^{n-1/2}
      +\frac{\Delta t}{\mu}
      \left(\frac{D_zE_\phi}{\kappa_z}+\psi_{H_r,z}\right).

   :math:`H_z` 的径向项来自 :math:`(1/r)\partial_r(rE_\phi)`；实现时要把
   Yee 差分中的径向导数和圆柱坐标 metric 一起放在正确的交错位置上。
   当前 AlgoPlasma 的 ``sub_E01_cpml_2d_rz_tez_H`` 对径向差分使用
   :math:`D_rE_\phi/\kappa_r+\psi_{H_z,r}`，并把 :math:`E_\phi/r`
   类型的 metric 项保留在 memory 变量之外。

   :math:`(E_r,H_\phi,E_z)` **子系统。** :math:`E_r` 的轴向项、
   :math:`H_\phi` 的径向和轴向项按同一替换规则处理：

   .. math::

      E_r^{n+1}=E_r^n-\frac{\Delta t}{\epsilon}
      \left(\frac{D_zH_\phi}{\kappa_z}+\psi_{E_r,z}\right),

   .. math::

      H_\phi^{n+1/2}=H_\phi^{n-1/2}
      +\frac{\Delta t}{\mu}
      \left[
      \left(\frac{D_rE_z}{\kappa_r}+\psi_{H_\phi,r}\right)
      -
      \left(\frac{D_zE_r}{\kappa_z}+\psi_{H_\phi,z}\right)
      \right].

   :math:`E_z` 在 :math:`i=0` 使用第 6 节的轴线闭合；CPML 更新范围应避开
   物理轴线，或在轴线上退回专门闭合公式。AlgoPlasma 的
   ``sub_E01_cpml_2d_rz_tmz_E``、``sub_E01_cpml_2d_rz_tmz_H``、
   ``sub_E01_cpml_2d_rz_tez_E`` 和 ``sub_E01_cpml_2d_rz_tez_H`` 分别保存
   ``psi_ez_r``、``psi_er_z``、``psi_ha_r``、``psi_ha_z``、
   ``psi_ephi_r``、``psi_ephi_z``、``psi_hr_z``、``psi_hz_r`` 等 memory
   变量。``tez``/``tmz`` 文件名与上述 TEz/TMz 分量组保持一致。

   .. rubric:: 8. 参考文献

   - `Inan U S, Marshall R A. *Numerical electromagnetics: the FDTD method*. Cambridge University Press, 2011. <https://books.google.com/books?hl=zh-CN&lr=&id=mGdH_W0YBdQC&oi=fnd&pg=PR7&dq=Numerical+Electromagnetics++The+FDTD+Method&ots=G2FOsDB5R5&sig=vPvGj05ui_Fn1uDbmyEOqIFgqt0#v=onepage&q=Numerical%20Electromagnetics%20%20The%20FDTD%20Method&f=false>`_
   - Roden J A, Gedney S D. Convolution PML (CPML): An efficient FDTD implementation of the CFS-PML for arbitrary media.
     *Microwave and Optical Technology Letters*, 27(5): 334-339, 2000.
     DOI: `10.1002/1098-2760(20001205)27:5\<334::AID-MOP14\>3.0.CO;2-A <https://doi.org/10.1002/1098-2760(20001205)27:5%3C334::AID-MOP14%3E3.0.CO;2-A>`_.

.. container:: ap-lang ap-lang-en

   .. rubric:: 2D Cylindrical (rz) FDTD

   .. rubric:: 1. Problem Definition

   This solver uses a 2D :math:`(r,z)` slice with axisymmetry:

   .. math::

      \frac{\partial}{\partial \phi}=0.

   It applies a Yee staggered grid in space and leapfrog staggering in time
   (:math:`\mathbf{E}` at integer time and :math:`\mathbf{H}` at half time).

   .. figure:: ../../../images/E_Maxwell/E01_2Drz.png
      :align: center
      :width: 65%

      2D axisymmetric cylindrical ``(r,z)`` Yee-grid coordinate system.

   The coordinate origin is on the symmetry axis (:math:`r=0`), so axis closure
   is required for terms involving :math:`1/r`.

   .. rubric:: 2. Mode Split

   - **TEz mode** (:math:`E_z=0`): non-zero fields are
     :math:`H_r,\ E_\phi,\ H_z`.
   - **TMz mode** (:math:`H_z=0`): non-zero fields are
     :math:`E_r,\ H_\phi,\ E_z`.

   In this axisymmetric reduction, TEz and TMz are two decoupled subsystems of
   the full cylindrical Maxwell equations. AlgoPlasma source filenames, module names,
   and routine names use ``tez`` and ``tmz`` suffixes to match these axial mode names.

   .. rubric:: 3. Continuous Equations

   **TEz subsystem:**

   .. math::

      \frac{\partial E_\phi}{\partial t}
      = \frac{1}{\epsilon}\left(\frac{\partial H_r}{\partial z}
      - \frac{\partial H_z}{\partial r}\right).

   This updates azimuthal electric field from the curl of magnetic fields.

   .. math::

      \frac{\partial H_r}{\partial t}
      = \frac{1}{\mu}\frac{\partial E_\phi}{\partial z},
      \qquad
      \frac{\partial H_z}{\partial t}
      = -\frac{1}{\mu r}\frac{\partial (rE_\phi)}{\partial r}.

   These update magnetic fields from the curl of :math:`E_\phi`.

   **TMz subsystem:**

   .. math::

      \frac{\partial E_r}{\partial t}
      = -\frac{1}{\epsilon}\frac{\partial H_\phi}{\partial z},
      \qquad
      \frac{\partial E_z}{\partial t}
      = \frac{1}{\epsilon r}\frac{\partial (rH_\phi)}{\partial r}.

   These update electric fields from :math:`H_\phi` curl terms.

   .. math::

      \frac{\partial H_\phi}{\partial t}
      = \frac{1}{\mu}\left(\frac{\partial E_z}{\partial r}
      - \frac{\partial E_r}{\partial z}\right).

   This updates azimuthal magnetic field from electric curls.

   For a first reading, use the following notation map:

   - :math:`E_r,E_\phi,E_z` are electric-field components in the radial,
     azimuthal, and axial directions; :math:`H_r,H_\phi,H_z` are the
     corresponding magnetic-field components.
   - Subscripts :math:`r,\phi,z` denote component directions, not array indices;
     axisymmetry means the fields do not vary with :math:`\phi` on this page.
   - :math:`\epsilon` is permittivity and :math:`\mu` is permeability; for a
     homogeneous medium they may be treated as constants.
   - :math:`\partial/\partial t` is a time derivative, while
     :math:`\partial/\partial r` and :math:`\partial/\partial z` are radial and
     axial spatial derivatives.
   - :math:`(1/r)\partial_r(r\cdot)` is the cylindrical metric term that drives
     the special axis treatment and conservative radial differencing.

   .. rubric:: 4. Yee Grid and Staggering

   Let :math:`i,k,n` be radial index, axial index, and integer time index:
   :math:`r_i=i\Delta r`, :math:`r_{i+1/2}=(i+1/2)\Delta r`,
   :math:`z_k=k\Delta z`, :math:`z_{k+1/2}=(k+1/2)\Delta z`,
   :math:`t^n=n\Delta t`.

   - Time staggering: :math:`\mathbf{E}^n` and :math:`\mathbf{H}^{n+1/2}`.
   - **TMz placement:**
     - :math:`E_r(i+1/2,k)`
     - :math:`E_z(i,k+1/2)`
     - :math:`H_\phi(i+1/2,k+1/2)`
   - **TEz placement:**
     - :math:`E_\phi(i,k)`
     - :math:`H_r(i,k+1/2)`
     - :math:`H_z(i+1/2,k)`

   Equivalent naming rule (reduced from 3D cylindrical, for
   :math:`a\in\{r,\phi,z\}`):

   - :math:`E_a`: half index in direction :math:`a`, integer indices in the other
     directions
   - :math:`H_a`: integer index in direction :math:`a`, half indices in the other
     directions

   Under :math:`\partial/\partial\phi=0`, this 3D rule collapses to the 2D
   :math:`(r,z)` layout listed above.
   This follows the same component-direction convention defined in
   :ref:`fdtd_cartesian_component_convention`.

   In the discrete equations below, a symbol such as :math:`F_{i,k}^n` means
   field component :math:`F` sampled at radial index :math:`i`, axial index
   :math:`k`, and time level :math:`n`. Half indices such as :math:`i+1/2` or
   :math:`k+1/2` mean that the component is stored halfway between neighboring
   grid points. The condition :math:`i>0` means that the interior formula is not
   used on the axis.

   .. rubric:: 5. Discrete Update Equations (2nd-order centered)

   **TEz mode updates:**

   .. math::

      E_{\phi,i,k}^{n+1}
      = E_{\phi,i,k}^{n}
      + \frac{\Delta t}{\epsilon}
      \left[
      \frac{H_{r,i,k+1/2}^{n+1/2}-H_{r,i,k-1/2}^{n+1/2}}{\Delta z}
      - \frac{H_{z,i+1/2,k}^{n+1/2}-H_{z,i-1/2,k}^{n+1/2}}{\Delta r}
      \right],\ i>0.

   This updates :math:`E_\phi` from discrete :math:`\nabla\times\mathbf{H}`.

   .. math::

      H_{r,i,k+1/2}^{n+1/2}
      = H_{r,i,k+1/2}^{n-1/2}
      + \frac{\Delta t}{\mu}
      \frac{E_{\phi,i,k+1}^{n}-E_{\phi,i,k}^{n}}{\Delta z},\ i>0.

   This updates :math:`H_r` from the axial derivative of :math:`E_\phi`.

   .. note::

      **Correction (TEz update for H_r):** In the cited reference, this formula
      is sometimes printed as :math:`H_r^{n+1/2}=H_r^{n-1/2}-\cdots`. Here the
      correct sign is the plus form shown above, i.e.
      :math:`H_r^{n+1/2}=H_r^{n-1/2}+\cdots`.

   .. math::

      H_{z,i+1/2,k}^{n+1/2}
      = H_{z,i+1/2,k}^{n-1/2}
      - \frac{\Delta t}{\mu}
      \frac{r_{i+1}E_{\phi,i+1,k}^{n}-r_iE_{\phi,i,k}^{n}}
      {r_{i+1/2}\Delta r}.

   This updates :math:`H_z` using the conservative
   :math:`(1/r)\partial_r(rE_\phi)` form.

   **TMz mode updates:**

   .. math::

      E_{r,i+1/2,k}^{n+1}
      = E_{r,i+1/2,k}^{n}
      - \frac{\Delta t}{\epsilon}
      \frac{H_{\phi,i+1/2,k+1/2}^{n+1/2}
      - H_{\phi,i+1/2,k-1/2}^{n+1/2}}{\Delta z}.

   This updates :math:`E_r` from the axial variation of :math:`H_\phi`.

   .. note::

      **Correction (TMz update for E_r):** In the cited reference, this formula
      is sometimes printed as :math:`E_r^{n+1}=E_r^n+\cdots`. Here the correct
      sign is the minus form shown above, i.e.
      :math:`E_r^{n+1}=E_r^n-\cdots`.

   .. math::

      E_{z,i,k+1/2}^{n+1}
      = E_{z,i,k+1/2}^{n}
      + \frac{\Delta t}{\epsilon}
      \frac{1}{r_i}
      \frac{r_{i+1/2}H_{\phi,i+1/2,k+1/2}^{n+1/2}
      - r_{i-1/2}H_{\phi,i-1/2,k+1/2}^{n+1/2}}
      {\Delta r},\ i>0.

   This updates :math:`E_z` from the radial divergence of :math:`rH_\phi`.

   .. math::

      H_{\phi,i+1/2,k+1/2}^{n+1/2}
      = H_{\phi,i+1/2,k+1/2}^{n-1/2}
      + \frac{\Delta t}{\mu}
      \left[
      \frac{E_{z,i+1,k+1/2}^{n}-E_{z,i,k+1/2}^{n}}{\Delta r}
      - \frac{E_{r,i+1/2,k+1}^{n}-E_{r,i+1/2,k}^{n}}{\Delta z}
      \right].

   This updates :math:`H_\phi` from discrete electric curls.

   .. rubric:: 6. Axis Handling at :math:`r=0`

   The terms :math:`(1/r)\partial_r(r\cdot)` are singular at the axis and cannot use
   the interior formula directly.

   For TMz :math:`E_z` at :math:`r=0`, the closure is derived from the integral
   form of Ampere-Maxwell law over a small disk :math:`S` of radius
   :math:`\Delta r/2` centered on the axis (unit depth in :math:`z`):

   .. math::

      \frac{\partial}{\partial t}\int_S \epsilon E_z\,dS
      = \oint_{\partial S} H_\phi\,dl.

   Here :math:`S` is the small disk around the axis and :math:`\partial S` is
   its boundary; :math:`dS` and :math:`dl` denote area and line elements.

   With axisymmetry, :math:`E_z` is approximately uniform on :math:`S`, and
   :math:`H_\phi` on :math:`\partial S` is represented by
   :math:`H_{\phi,1/2,k+1/2}^{n+1/2}`:

   .. math::

      \epsilon\pi\left(\frac{\Delta r}{2}\right)^2
      \frac{\partial E_z}{\partial t}
      =
      2\pi\left(\frac{\Delta r}{2}\right)H_{\phi,1/2,k+1/2}.

   Therefore,

   .. math::

      \frac{\partial E_z}{\partial t}
      = \frac{4}{\epsilon\Delta r}H_{\phi,1/2,k+1/2}.

   Applying leapfrog time discretization gives:

   .. math::

      E_{z,0,k+1/2}^{n+1}
      = E_{z,0,k+1/2}^{n}
      + \frac{4\Delta t}{\epsilon\Delta r}
      H_{\phi,1/2,k+1/2}^{n+1/2}.

   This is the axis closure used in code for stable and consistent TMz updates.

   For the :math:`(E_\phi,H_r,H_z)` subsystem in the current code,
   :math:`E_{\phi,0,k}=0` and :math:`H_{r,0,k+1/2}=0` are explicit constraints.
   :math:`H_z` is stored at :math:`i+1/2`, so it is not located on the singular
   axis point :math:`r=0`; therefore no separate axis-only update formula is used
   for :math:`H_z`.

   .. rubric:: 7. CPML Absorbing Boundaries

   In the axisymmetric :math:`(r,z)` problem, absorbing layers are normally
   placed on the outer radial boundary and the axial ends. The physical
   :math:`r=0` axis is a symmetry line, not a regular PML boundary. For each
   stretched direction :math:`u\in\{r,z\}`, CPML uses

   .. math::

      s_u(\omega)=\kappa_u+\frac{\sigma_u}{\alpha_u+j\omega\epsilon_0},
      \qquad
      D_u q\Rightarrow \frac{D_u q}{\kappa_u}+\psi_u,

   with recursive memory

   .. math::

      \psi_u^n=b_u\psi_u^{n-1}+a_u D_u q^n.

   The CPML notation means:

   - :math:`u` is the stretched coordinate direction, here either :math:`r` or
     :math:`z`.
   - :math:`D_u q` is the finite difference of field quantity :math:`q` in the
     :math:`u` direction; :math:`q` is a placeholder for an actual electric or
     magnetic component.
   - :math:`\psi_u` is the recursive-convolution memory variable storing the
     history contribution of that stretched derivative. In component equations
     it is written as :math:`\psi_{F,u}`, meaning the memory term used while
     updating field component :math:`F` for a derivative in direction
     :math:`u`.
   - :math:`\kappa_u,\sigma_u,\alpha_u` are PML profile parameters;
     :math:`a_u,b_u` are the recursion coefficients derived from those profiles
     and :math:`\Delta t`.
   - :math:`\omega` is angular frequency, :math:`j` is the imaginary unit, and
     :math:`\epsilon_0` is vacuum permittivity.

   The :math:`(E_\phi,H_r,H_z)` **subsystem.** The :math:`E_\phi` update has
   one ``z`` derivative and one ``r`` derivative, so it gets two memory terms:

   .. math::

      E_\phi^{n+1}=E_\phi^n+\frac{\Delta t}{\epsilon}
      \left[
      \left(\frac{D_zH_r}{\kappa_z}+\psi_{E_\phi,z}\right)
      -
      \left(\frac{D_rH_z}{\kappa_r}+\psi_{E_\phi,r}\right)
      \right].

   :math:`H_r` contains only a ``z`` derivative:

   .. math::

      H_r^{n+1/2}=H_r^{n-1/2}
      +\frac{\Delta t}{\mu}
      \left(\frac{D_zE_\phi}{\kappa_z}+\psi_{H_r,z}\right).

   The :math:`H_z` radial term comes from
   :math:`(1/r)\partial_r(rE_\phi)`. Its Yee derivative and cylindrical metric
   must be evaluated at the correct staggered radius. The current AlgoPlasma
   ``sub_E01_cpml_2d_rz_tez_H`` applies CPML to the radial difference
   :math:`D_rE_\phi/\kappa_r+\psi_{H_z,r}` and keeps the
   :math:`E_\phi/r`-type metric contribution outside the memory variable.

   The :math:`(E_r,H_\phi,E_z)` **subsystem.** The axial :math:`E_r` term and
   the two :math:`H_\phi` curl terms use the same replacement rule:

   .. math::

      E_r^{n+1}=E_r^n-\frac{\Delta t}{\epsilon}
      \left(\frac{D_zH_\phi}{\kappa_z}+\psi_{E_r,z}\right),

   .. math::

      H_\phi^{n+1/2}=H_\phi^{n-1/2}
      +\frac{\Delta t}{\mu}
      \left[
      \left(\frac{D_rE_z}{\kappa_r}+\psi_{H_\phi,r}\right)
      -
      \left(\frac{D_zE_r}{\kappa_z}+\psi_{H_\phi,z}\right)
      \right].

   :math:`E_z` at :math:`i=0` must use the axis closure from section 6.
   Therefore the CPML update range should avoid the physical axis, or the
   caller should fall back to the dedicated axis formula there. AlgoPlasma stores the
   memory variables in ``sub_E01_cpml_2d_rz_tmz_E``,
   ``sub_E01_cpml_2d_rz_tmz_H``, ``sub_E01_cpml_2d_rz_tez_E``, and
   ``sub_E01_cpml_2d_rz_tez_H`` as ``psi_ez_r``, ``psi_er_z``,
   ``psi_ha_r``, ``psi_ha_z``, ``psi_ephi_r``, ``psi_ephi_z``,
   ``psi_hr_z``, and ``psi_hz_r``. The ``tez``/``tmz`` filenames match the TEz/TMz component groups above.

   .. rubric:: 8. Reference

   - `Inan U S, Marshall R A. *Numerical electromagnetics: the FDTD method*. Cambridge University Press, 2011. <https://books.google.com/books?hl=zh-CN&lr=&id=mGdH_W0YBdQC&oi=fnd&pg=PR7&dq=Numerical+Electromagnetics++The+FDTD+Method&ots=G2FOsDB5R5&sig=vPvGj05ui_Fn1uDbmyEOqIFgqt0#v=onepage&q=Numerical%20Electromagnetics%20%20The%20FDTD%20Method&f=false>`_
   - Roden J A, Gedney S D. Convolution PML (CPML): An efficient FDTD implementation of the CFS-PML for arbitrary media.
     *Microwave and Optical Technology Letters*, 27(5): 334-339, 2000.
     DOI: `10.1002/1098-2760(20001205)27:5\<334::AID-MOP14\>3.0.CO;2-A <https://doi.org/10.1002/1098-2760(20001205)27:5%3C334::AID-MOP14%3E3.0.CO;2-A>`_.
