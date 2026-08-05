3D Cartesian (xyz) FDTD
=======================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 3D Cartesian (xyz) FDTD

   .. rubric:: 1. 问题定义

   本页说明三维直角坐标 :math:`(x,y,z)` 中基于 Yee 交错网格和 leapfrog 时间推进的
   Maxwell 方程组有限差分时域方法（Finite-Difference Time-Domain, FDTD）核心。
   该形式直接求解完整三维 Maxwell 旋度方程组，不做 TE/TM 模式分裂。

   .. figure:: ../../../images/E_Maxwell/E03_3Dxyz.png
      :align: center
      :width: 65%

      3D Cartesian ``(x,y,z)`` Yee 网格坐标系示意图。

   网格采用相互正交的 :math:`x`、:math:`y`、:math:`z` 坐标轴。电场分量与磁场分量在空间上
   按 Yee 方式交错布置，在时间上相差半个时间步。

   .. rubric:: 2. 连续方程

   对未知量 :math:`E_x,E_y,E_z,H_x,H_y,H_z`，无源 Maxwell 旋度方程可写为：

   .. math::

      \frac{\partial E_x}{\partial t}
      = \frac{1}{\epsilon}
      \left(
      \frac{\partial H_z}{\partial y}
      - \frac{\partial H_y}{\partial z}
      \right),
      \qquad
      \frac{\partial H_x}{\partial t}
      = -\frac{1}{\mu}
      \left(
      \frac{\partial E_z}{\partial y}
      - \frac{\partial E_y}{\partial z}
      \right).

   .. math::

      \frac{\partial E_y}{\partial t}
      = \frac{1}{\epsilon}
      \left(
      \frac{\partial H_x}{\partial z}
      - \frac{\partial H_z}{\partial x}
      \right),
      \qquad
      \frac{\partial H_y}{\partial t}
      = -\frac{1}{\mu}
      \left(
      \frac{\partial E_x}{\partial z}
      - \frac{\partial E_z}{\partial x}
      \right).

   .. math::

      \frac{\partial E_z}{\partial t}
      = \frac{1}{\epsilon}
      \left(
      \frac{\partial H_y}{\partial x}
      - \frac{\partial H_x}{\partial y}
      \right),
      \qquad
      \frac{\partial H_z}{\partial t}
      = -\frac{1}{\mu}
      \left(
      \frac{\partial E_y}{\partial x}
      - \frac{\partial E_x}{\partial y}
      \right).

   初读这些公式时，可先按下面的符号理解：

   - :math:`E_x,E_y,E_z` 是电场在 :math:`x,y,z` 方向的分量；
     :math:`H_x,H_y,H_z` 是磁场对应方向的分量。
   - 下标 :math:`x,y,z` 表示分量方向，不是数组下标；
     数组位置由后面的 :math:`i,j,k` 指标给出。
   - :math:`\epsilon` 是介电常数，:math:`\mu` 是磁导率。
     离散式中的 :math:`\epsilon_x,\epsilon_y,\epsilon_z`
     和 :math:`\mu_x,\mu_y,\mu_z` 表示把材料参数采样到对应分量所在的
     Yee 位置。
   - :math:`\partial/\partial t` 表示时间导数；
     :math:`\partial/\partial x`、:math:`\partial/\partial y`
     和 :math:`\partial/\partial z` 表示三个坐标方向上的空间导数。
   - :math:`\nabla\times` 是旋度算子；每个旋度分量都由另外两个横向方向的差分相减得到。

   .. rubric:: 3. Yee 网格布局

   指标约定：

   - :math:`i \to x`
   - :math:`j \to y`
   - :math:`k \to z`
   - :math:`n \to` 整数时间层

   网格步长和时间步长为：

   - :math:`\Delta x,\ \Delta y,\ \Delta z,\ \Delta t`

   Yee 分量位置为：

   - :math:`E_x(i+1/2,j,k)`
   - :math:`E_y(i,j+1/2,k)`
   - :math:`E_z(i,j,k+1/2)`
   - :math:`H_x(i,j+1/2,k+1/2)`
   - :math:`H_y(i+1/2,j,k+1/2)`
   - :math:`H_z(i+1/2,j+1/2,k)`

   等价地，对 :math:`a\in\{x,y,z\}`：

   - :math:`E_a`：在 :math:`a` 方向取半指标，在另外两个方向取整数指标。
   - :math:`H_a`：在 :math:`a` 方向取整数指标，在另外两个方向取半指标。

   这是 E_Maxwell 中 FDTD 说明采用的基础分量方向约定。推广到其它正交坐标系时，
   只需把 :math:`a` 替换成局部坐标方向符号，并保持同样的指标逻辑：
   :math:`E_a` 在本方向取半指标，:math:`H_a` 在本方向取整数指标。

   时间交错为：

   - 电场位于整数时间层 :math:`n`。
   - 磁场位于半整数时间层 :math:`n+1/2`。

   这种布置使每一个旋度分量都可以用两个横向方向上的最近邻中心差分表示。

   后面的离散式中，形如 :math:`F_{i,j,k}^n` 的符号表示场分量
   :math:`F` 在逻辑指标 :math:`(i,j,k)` 和时间层 :math:`n`
   上的数值；上标 :math:`n+1` 表示推进后的下一整数时间层，
   :math:`n+1/2` 表示位于两层电场之间的半整数磁场时间层。

   .. rubric:: 4. 离散更新方程

   电场更新：

   .. math::

      E_{x,i,j,k}^{n+1}
      = E_{x,i,j,k}^{n}
      + \frac{\Delta t}{\epsilon_x}
      \left[
      \frac{H_{z,i,j,k}^{n+1/2}-H_{z,i,j-1,k}^{n+1/2}}{\Delta y}
      - \frac{H_{y,i,j,k}^{n+1/2}-H_{y,i,j,k-1}^{n+1/2}}{\Delta z}
      \right].

   这是 :math:`(\nabla\times\mathbf{H})_x`，使用 :math:`y` 和 :math:`z` 方向差分。

   .. math::

      E_{y,i,j,k}^{n+1}
      = E_{y,i,j,k}^{n}
      + \frac{\Delta t}{\epsilon_y}
      \left[
      \frac{H_{x,i,j,k}^{n+1/2}-H_{x,i,j,k-1}^{n+1/2}}{\Delta z}
      - \frac{H_{z,i,j,k}^{n+1/2}-H_{z,i-1,j,k}^{n+1/2}}{\Delta x}
      \right].

   这是 :math:`(\nabla\times\mathbf{H})_y`，使用 :math:`z` 和 :math:`x` 方向差分。

   .. math::

      E_{z,i,j,k}^{n+1}
      = E_{z,i,j,k}^{n}
      + \frac{\Delta t}{\epsilon_z}
      \left[
      \frac{H_{y,i,j,k}^{n+1/2}-H_{y,i-1,j,k}^{n+1/2}}{\Delta x}
      - \frac{H_{x,i,j,k}^{n+1/2}-H_{x,i,j-1,k}^{n+1/2}}{\Delta y}
      \right].

   这是 :math:`(\nabla\times\mathbf{H})_z`，使用 :math:`x` 和 :math:`y` 方向差分。

   磁场更新：

   .. math::

      H_{x,i,j,k}^{n+1/2}
      = H_{x,i,j,k}^{n-1/2}
      - \frac{\Delta t}{\mu_x}
      \left[
      \frac{E_{z,i,j+1,k}^{n}-E_{z,i,j,k}^{n}}{\Delta y}
      - \frac{E_{y,i,j,k+1}^{n}-E_{y,i,j,k}^{n}}{\Delta z}
      \right].

   这是 :math:`-(\nabla\times\mathbf{E})_x`，使用 :math:`y` 和 :math:`z` 方向差分。

   .. math::

      H_{y,i,j,k}^{n+1/2}
      = H_{y,i,j,k}^{n-1/2}
      - \frac{\Delta t}{\mu_y}
      \left[
      \frac{E_{x,i,j,k+1}^{n}-E_{x,i,j,k}^{n}}{\Delta z}
      - \frac{E_{z,i+1,j,k}^{n}-E_{z,i,j,k}^{n}}{\Delta x}
      \right].

   这是 :math:`-(\nabla\times\mathbf{E})_y`，使用 :math:`z` 和 :math:`x` 方向差分。

   .. math::

      H_{z,i,j,k}^{n+1/2}
      = H_{z,i,j,k}^{n-1/2}
      - \frac{\Delta t}{\mu_z}
      \left[
      \frac{E_{y,i+1,j,k}^{n}-E_{y,i,j,k}^{n}}{\Delta x}
      - \frac{E_{x,i,j+1,k}^{n}-E_{x,i,j,k}^{n}}{\Delta y}
      \right].

   这是 :math:`-(\nabla\times\mathbf{E})_z`，使用 :math:`x` 和 :math:`y` 方向差分。

   .. rubric:: 5. 时间推进顺序

   Leapfrog 推进的典型顺序为：

   1. 由 :math:`\mathbf{E}^{n}` 更新 :math:`\mathbf{H}^{n+1/2}`。
   2. 由 :math:`\mathbf{H}^{n+1/2}` 更新 :math:`\mathbf{E}^{n+1}`。

   这种时间交错使旋度算子在时间上保持中心格式，并保留标准 Yee 更新的二阶结构。

   .. rubric:: 6. 材料参数

   在离散公式中，:math:`\epsilon` 或 :math:`\mu` 应位于被更新分量所在的 Yee 位置。
   例如 :math:`\epsilon_x` 对应 :math:`E_x` 节点。若介质为空间变化但各向同性，
   一般应把标量材料参数采样到相应的交错分量位置。

   AlgoPlasma 当前的 ``sub_E03_fdtd_3d_cartesian_E`` 和 ``sub_E03_fdtd_3d_cartesian_H`` 例程使用
   标量参数 ``ep`` 和 ``mu``，即一次调用中所有更新点共享同一个介电常数或磁导率。
   若后续需要非均匀介质，需要把材料参数扩展为与分量位置匹配的数组或外层分块调用。

   .. rubric:: 7. 实现注意

   - 场分量数组必须与 Yee 交错位置保持一致；同名数组索引表示该分量的离散存储位置。
   - ``sub_E03_fdtd_3d_cartesian_H`` 先读 :math:`E^n` 并原位更新 ``Hx``、``Hy``、``Hz``。
   - ``sub_E03_fdtd_3d_cartesian_E`` 再读 :math:`H^{n+1/2}` 并原位更新 ``Ex``、``Ey``、``Ez``。
   - 不要在同一个更新核中混用 :math:`n` 与 :math:`n+1/2` 的错误时间层。
   - 旋度项符号必须与右手系方向保持一致：电场用 :math:`+\nabla\times\mathbf{H}`，磁场用
     :math:`-\nabla\times\mathbf{E}`。
   - 当前例程只执行给定 ``il:iu``、``jl:ju``、``kl:ku`` 范围内的内部差分更新；
     边界条件、源项、MPI ghost cell 交换以及 CPML memory 变量由调用方或 CPML 模块负责。
   - 由于电场更新会访问 ``j-1``、``k-1``、``i-1``，磁场更新会访问 ``j+1``、``k+1``、``i+1``，
     调用方必须保证更新范围周围有可读的物理边界值或 ghost cell。

   .. rubric:: 8. CPML 吸收边界

   CPML（convolutional perfectly matched layer）是在复频移 PML
   （CFS-PML）基础上的递推卷积实现。对任一坐标方向
   :math:`u\in\{x,y,z\}`，频域坐标拉伸写作

   .. math::

      s_u(\omega)=\kappa_u+\frac{\sigma_u}{\alpha_u+j\omega\epsilon_0},
      \qquad
      \frac{\partial}{\partial u}\Rightarrow
      \frac{1}{s_u}\frac{\partial}{\partial u}.

   回到时域后，每个被拉伸的一阶差分由一个 ``kappa`` 缩放项和一个
   memory 变量组成：

   .. math::

      \psi_u^n=b_u\psi_u^{n-1}+a_u D_u q^n,
      \qquad
      D_u q\Rightarrow \frac{D_u q}{\kappa_u}+\psi_u^n.

   一种常用系数约定为

   .. math::

      b_u=\exp\left[-\left(\frac{\sigma_u}{\kappa_u}+\alpha_u\right)
      \frac{\Delta t}{\epsilon_0}\right],
      \qquad
      a_u=\frac{\sigma_u}{\sigma_u\kappa_u+\kappa_u^2\alpha_u}
      \left(b_u-1\right).

   其中 :math:`\sigma_u`、:math:`\kappa_u` 和 :math:`\alpha_u` 只在 PML
   层内渐变；普通内部区通常取 :math:`\sigma=0`、:math:`\kappa=1`、
   :math:`a=0`、:math:`b=1`。

   这组 CPML 公式中的符号含义如下：

   - :math:`u` 表示被拉伸的坐标方向，可取 :math:`x`、:math:`y`
     或 :math:`z`。
   - :math:`D_u q` 表示对场量 :math:`q` 做 :math:`u` 方向的有限差分；
     :math:`q` 是占位符，实际可以是某个 :math:`E` 或 :math:`H` 分量。
   - :math:`\psi_u` 是递推卷积 memory 变量；在具体场分量里，
     :math:`\psi_{E_x,y}` 表示更新 :math:`E_x` 时，:math:`y`
     方向差分对应的 memory 项。
   - :math:`\kappa_u,\sigma_u,\alpha_u` 是 PML 剖面参数；
     :math:`a_u,b_u` 是对应的时域递推系数。
   - :math:`\omega` 是角频率，:math:`j` 是虚数单位，:math:`\epsilon_0`
     是真空介电常数。
   - :math:`\kappa_{E_y}` 这类下标表示“更新电场时用于 :math:`y`
     方向差分的 CPML 系数”，对应代码里的 ``key`` 一类数组。

   对三维直角坐标，六个 Maxwell 分量共有十二个横向导数，因此需要
   十二个 memory 变量。例如 :math:`E_x` 更新中的两个 CPML 项为

   .. math::

      \psi_{E_x,y}^{n+1/2}
      =b_{E_y}\psi_{E_x,y}^{n-1/2}
      +a_{E_y}D_y H_z^{n+1/2},
      \qquad
      \psi_{E_x,z}^{n+1/2}
      =b_{E_z}\psi_{E_x,z}^{n-1/2}
      +a_{E_z}D_z H_y^{n+1/2},

   .. math::

      E_x^{n+1}=E_x^n+\frac{\Delta t}{\epsilon}
      \left[
      \left(\frac{D_yH_z}{\kappa_{E_y}}+\psi_{E_x,y}\right)
      -
      \left(\frac{D_zH_y}{\kappa_{E_z}}+\psi_{E_x,z}\right)
      \right].

   :math:`H_x`、:math:`E_y`、:math:`H_y`、:math:`E_z` 和 :math:`H_z`
   的处理完全类似，只需把对应 curl 中的每个差分
   :math:`D_u q` 替换为 :math:`D_u q/\kappa_u+\psi`。AlgoPlasma 中
   ``sub_E03_cpml_3d_cartesian_E`` 和 ``sub_E03_cpml_3d_cartesian_H`` 正是按这个规则
   使用 ``aex/bex/kex``、``aey/bey/key``、``aez/bez/kez`` 以及对应的
   ``psi_*`` 数组。

   .. rubric:: 9. 参考文献

   - `Inan U S, Marshall R A. *Numerical electromagnetics: the FDTD method*. Cambridge University Press, 2011. <https://books.google.com/books?hl=zh-CN&lr=&id=mGdH_W0YBdQC&oi=fnd&pg=PR7&dq=Numerical+Electromagnetics++The+FDTD+Method&ots=G2FOsDB5R5&sig=vPvGj05ui_Fn1uDbmyEOqIFgqt0#v=onepage&q=Numerical%20Electromagnetics%20%20The%20FDTD%20Method&f=false>`_
   - Roden J A, Gedney S D. Convolution PML (CPML): An efficient FDTD implementation of the CFS-PML for arbitrary media.
     *Microwave and Optical Technology Letters*, 27(5): 334-339, 2000.
     DOI: `10.1002/1098-2760(20001205)27:5\<334::AID-MOP14\>3.0.CO;2-A <https://doi.org/10.1002/1098-2760(20001205)27:5%3C334::AID-MOP14%3E3.0.CO;2-A>`_.

.. container:: ap-lang ap-lang-en

   .. rubric:: 3D Cartesian (xyz) FDTD

   .. rubric:: 1. Problem definition

   This document describes the 3D Cartesian :math:`(x,y,z)` FDTD core based on
   the Yee staggered grid and leapfrog time integration. It solves the full
   3D Maxwell curl system directly, without TE/TM mode decomposition.

   .. figure:: ../../../images/E_Maxwell/E03_3Dxyz.png
      :align: center
      :width: 65%

      3D Cartesian ``(x,y,z)`` Yee-grid coordinate system.

   The mesh uses orthogonal axes with standard Yee staggering, where electric and
   magnetic components are offset in space and half a time-step in leapfrog.

   .. rubric:: 2. Continuous equations

   For unknowns :math:`E_x,E_y,E_z,H_x,H_y,H_z`, the source-free curl equations
   are:

   .. math::

      \frac{\partial E_x}{\partial t}
      = \frac{1}{\epsilon}
      \left(
      \frac{\partial H_z}{\partial y}
      - \frac{\partial H_y}{\partial z}
      \right),
      \qquad
      \frac{\partial H_x}{\partial t}
      = -\frac{1}{\mu}
      \left(
      \frac{\partial E_z}{\partial y}
      - \frac{\partial E_y}{\partial z}
      \right).

   .. math::

      \frac{\partial E_y}{\partial t}
      = \frac{1}{\epsilon}
      \left(
      \frac{\partial H_x}{\partial z}
      - \frac{\partial H_z}{\partial x}
      \right),
      \qquad
      \frac{\partial H_y}{\partial t}
      = -\frac{1}{\mu}
      \left(
      \frac{\partial E_x}{\partial z}
      - \frac{\partial E_z}{\partial x}
      \right).

   .. math::

      \frac{\partial E_z}{\partial t}
      = \frac{1}{\epsilon}
      \left(
      \frac{\partial H_y}{\partial x}
      - \frac{\partial H_x}{\partial y}
      \right),
      \qquad
      \frac{\partial H_z}{\partial t}
      = -\frac{1}{\mu}
      \left(
      \frac{\partial E_y}{\partial x}
      - \frac{\partial E_x}{\partial y}
      \right).

   For a first reading, use this notation map:

   - :math:`E_x,E_y,E_z` are electric-field components in the :math:`x,y,z`
     directions; :math:`H_x,H_y,H_z` are the corresponding magnetic-field
     components.
   - Subscripts :math:`x,y,z` denote component directions, not array indices;
     array locations are given later by :math:`i,j,k`.
   - :math:`\epsilon` is permittivity and :math:`\mu` is permeability.
     In the discrete equations, :math:`\epsilon_x,\epsilon_y,\epsilon_z` and
     :math:`\mu_x,\mu_y,\mu_z` mean material values sampled at the Yee locations
     of the corresponding components.
   - :math:`\partial/\partial t` is a time derivative, while
     :math:`\partial/\partial x`, :math:`\partial/\partial y`, and
     :math:`\partial/\partial z` are spatial derivatives.
   - :math:`\nabla\times` is the curl operator; each curl component is a
     difference of derivatives in the two transverse directions.

   .. _fdtd_cartesian_component_convention:

   .. rubric:: 3. Yee grid layout

   Index convention:

   - :math:`i \to x`
   - :math:`j \to y`
   - :math:`k \to z`
   - :math:`n \to` time level

   Grid and time steps are:

   - :math:`\Delta x,\ \Delta y,\ \Delta z,\ \Delta t`

   Yee positions:

   - :math:`E_x(i+1/2,j,k)`
   - :math:`E_y(i,j+1/2,k)`
   - :math:`E_z(i,j,k+1/2)`
   - :math:`H_x(i,j+1/2,k+1/2)`
   - :math:`H_y(i+1/2,j,k+1/2)`
   - :math:`H_z(i+1/2,j+1/2,k)`

   Equivalent naming rule (for :math:`a\in\{x,y,z\}`):

   - :math:`E_a`: half index in direction :math:`a`, integer indices in the other
     two directions
   - :math:`H_a`: integer index in direction :math:`a`, half indices in the other
     two directions

   This is the base component-direction convention used across the FDTD notes:
   for any orthogonal coordinate system, replace :math:`a` with the local
   coordinate direction symbol and keep the same index logic
   (:math:`E_a` half in :math:`a`, :math:`H_a` integer in :math:`a`).

   Time staggering:

   - electric fields at integer time :math:`n`
   - magnetic fields at half-integer time :math:`n+1/2`

   This placement makes each curl component a nearest-neighbor centered
   difference using two transverse directions.

   In the discrete equations below, a symbol such as :math:`F_{i,j,k}^n` means
   field component :math:`F` at logical indices :math:`(i,j,k)` and time level
   :math:`n`. Superscript :math:`n+1` is the next integer electric-field time
   level, while :math:`n+1/2` is the half-integer magnetic-field time level
   between two electric-field levels.

   .. rubric:: 4. Discrete update equations

   Electric updates:

   .. math::

      E_{x,i,j,k}^{n+1}
      = E_{x,i,j,k}^{n}
      + \frac{\Delta t}{\epsilon_x}
      \left[
      \frac{H_{z,i,j,k}^{n+1/2}-H_{z,i,j-1,k}^{n+1/2}}{\Delta y}
      - \frac{H_{y,i,j,k}^{n+1/2}-H_{y,i,j,k-1}^{n+1/2}}{\Delta z}
      \right].

   This is :math:`(\nabla\times\mathbf{H})_x`, using :math:`y` and :math:`z`
   differences.

   .. math::

      E_{y,i,j,k}^{n+1}
      = E_{y,i,j,k}^{n}
      + \frac{\Delta t}{\epsilon_y}
      \left[
      \frac{H_{x,i,j,k}^{n+1/2}-H_{x,i,j,k-1}^{n+1/2}}{\Delta z}
      - \frac{H_{z,i,j,k}^{n+1/2}-H_{z,i-1,j,k}^{n+1/2}}{\Delta x}
      \right].

   This is :math:`(\nabla\times\mathbf{H})_y`, using :math:`z` and :math:`x`
   differences.

   .. math::

      E_{z,i,j,k}^{n+1}
      = E_{z,i,j,k}^{n}
      + \frac{\Delta t}{\epsilon_z}
      \left[
      \frac{H_{y,i,j,k}^{n+1/2}-H_{y,i-1,j,k}^{n+1/2}}{\Delta x}
      - \frac{H_{x,i,j,k}^{n+1/2}-H_{x,i,j-1,k}^{n+1/2}}{\Delta y}
      \right].

   This is :math:`(\nabla\times\mathbf{H})_z`, using :math:`x` and :math:`y`
   differences.

   Magnetic updates:

   .. math::

      H_{x,i,j,k}^{n+1/2}
      = H_{x,i,j,k}^{n-1/2}
      - \frac{\Delta t}{\mu_x}
      \left[
      \frac{E_{z,i,j+1,k}^{n}-E_{z,i,j,k}^{n}}{\Delta y}
      - \frac{E_{y,i,j,k+1}^{n}-E_{y,i,j,k}^{n}}{\Delta z}
      \right].

   This is :math:`-(\nabla\times\mathbf{E})_x`, using :math:`y` and :math:`z`
   differences.

   .. math::

      H_{y,i,j,k}^{n+1/2}
      = H_{y,i,j,k}^{n-1/2}
      - \frac{\Delta t}{\mu_y}
      \left[
      \frac{E_{x,i,j,k+1}^{n}-E_{x,i,j,k}^{n}}{\Delta z}
      - \frac{E_{z,i+1,j,k}^{n}-E_{z,i,j,k}^{n}}{\Delta x}
      \right].

   This is :math:`-(\nabla\times\mathbf{E})_y`, using :math:`z` and :math:`x`
   differences.

   .. math::

      H_{z,i,j,k}^{n+1/2}
      = H_{z,i,j,k}^{n-1/2}
      - \frac{\Delta t}{\mu_z}
      \left[
      \frac{E_{y,i+1,j,k}^{n}-E_{y,i,j,k}^{n}}{\Delta x}
      - \frac{E_{x,i,j+1,k}^{n}-E_{x,i,j,k}^{n}}{\Delta y}
      \right].

   This is :math:`-(\nabla\times\mathbf{E})_z`, using :math:`x` and :math:`y`
   differences.

   .. rubric:: 5. Time-marching procedure

   Leapfrog update order:

   1. Update :math:`\mathbf{H}^{n+1/2}` from :math:`\mathbf{E}^{n}`.
   2. Update :math:`\mathbf{E}^{n+1}` from :math:`\mathbf{H}^{n+1/2}`.

   This staggering keeps the curl operators centered in time and preserves the
   standard second-order Yee update structure.

   .. rubric:: 6. Material parameters

   In each update equation, :math:`\epsilon` or :math:`\mu` is evaluated at the
   location of the component being updated (for example,
   :math:`\epsilon_x` at :math:`E_x` nodes). If medium properties vary in space
   but remain isotropic, use position-dependent scalar values sampled on the same
   staggered locations as each component.

   The current AlgoPlasma ``sub_E03_fdtd_3d_cartesian_E`` and
   ``sub_E03_fdtd_3d_cartesian_H`` kernels take scalar ``ep`` and ``mu`` arguments,
   so one call uses one permittivity or permeability value for all updated
   cells. Spatially varying media require either component-aligned material
   arrays in a future interface or outer-level blocking with appropriate scalar
   values.

   .. rubric:: 7. Implementation notes

   - keep component storage exactly consistent with Yee offsets
   - ``sub_E03_fdtd_3d_cartesian_H`` reads :math:`\mathbf{E}^n` and updates
     ``Hx``, ``Hy``, and ``Hz`` in place
   - ``sub_E03_fdtd_3d_cartesian_E`` reads :math:`\mathbf{H}^{n+1/2}` and updates
     ``Ex``, ``Ey``, and ``Ez`` in place
   - do not mix :math:`n` and :math:`n+1/2` layers in one update kernel
   - keep curl signs consistent with the right-hand-rule ordering
   - preserve update order (:math:`H` first, then :math:`E`)
   - sample material parameters at updated-component locations
   - separate interior-cell updates from boundary-cell operators
   - the current kernels update only the supplied ``il:iu``, ``jl:ju``,
     ``kl:ku`` ranges; boundary conditions, sources, MPI ghost-cell exchange,
     and CPML memory variables are handled by the caller or the CPML module
   - electric updates read ``j-1``, ``k-1``, and ``i-1`` neighbors, while
     magnetic updates read ``j+1``, ``k+1``, and ``i+1`` neighbors; the caller
     must provide valid boundary values or ghost cells around the update range

   .. rubric:: 8. CPML Absorbing Boundaries

   CPML (convolutional perfectly matched layer) is a recursive-convolution
   implementation of the complex-frequency-shifted PML. For each coordinate
   direction :math:`u\in\{x,y,z\}`, the stretched-coordinate operator is

   .. math::

      s_u(\omega)=\kappa_u+\frac{\sigma_u}{\alpha_u+j\omega\epsilon_0},
      \qquad
      \frac{\partial}{\partial u}\Rightarrow
      \frac{1}{s_u}\frac{\partial}{\partial u}.

   In time domain, each stretched finite difference is written as a ``kappa``
   scaled derivative plus one memory variable:

   .. math::

      \psi_u^n=b_u\psi_u^{n-1}+a_u D_u q^n,
      \qquad
      D_u q\Rightarrow \frac{D_u q}{\kappa_u}+\psi_u^n.

   A common coefficient convention is

   .. math::

      b_u=\exp\left[-\left(\frac{\sigma_u}{\kappa_u}+\alpha_u\right)
      \frac{\Delta t}{\epsilon_0}\right],
      \qquad
      a_u=\frac{\sigma_u}{\sigma_u\kappa_u+\kappa_u^2\alpha_u}
      \left(b_u-1\right).

   The profiles :math:`\sigma_u`, :math:`\kappa_u`, and :math:`\alpha_u` are
   graded only inside the PML. Interior cells normally use
   :math:`\sigma=0`, :math:`\kappa=1`, :math:`a=0`, and :math:`b=1`.

   The CPML notation means:

   - :math:`u` is the stretched coordinate direction, one of :math:`x`,
     :math:`y`, or :math:`z`.
   - :math:`D_u q` is the finite difference of field quantity :math:`q` in the
     :math:`u` direction; :math:`q` is a placeholder for an actual electric or
     magnetic component.
   - :math:`\psi_u` is the recursive-convolution memory variable. In component
     equations, :math:`\psi_{E_x,y}` means the memory term for the
     :math:`y`-direction derivative used while updating :math:`E_x`.
   - :math:`\kappa_u,\sigma_u,\alpha_u` are PML profile parameters;
     :math:`a_u,b_u` are the corresponding time-domain recursion coefficients.
   - :math:`\omega` is angular frequency, :math:`j` is the imaginary unit, and
     :math:`\epsilon_0` is vacuum permittivity.
   - A subscript such as :math:`\kappa_{E_y}` means the CPML coefficient used
     for a :math:`y`-direction derivative while updating electric-field terms,
     corresponding to code arrays such as ``key``.

   In 3D Cartesian FDTD, the six Maxwell components contain twelve transverse
   derivatives, so twelve memory variables are required. For example, the
   :math:`E_x` CPML update uses

   .. math::

      \psi_{E_x,y}^{n+1/2}
      =b_{E_y}\psi_{E_x,y}^{n-1/2}
      +a_{E_y}D_y H_z^{n+1/2},
      \qquad
      \psi_{E_x,z}^{n+1/2}
      =b_{E_z}\psi_{E_x,z}^{n-1/2}
      +a_{E_z}D_z H_y^{n+1/2},

   .. math::

      E_x^{n+1}=E_x^n+\frac{\Delta t}{\epsilon}
      \left[
      \left(\frac{D_yH_z}{\kappa_{E_y}}+\psi_{E_x,y}\right)
      -
      \left(\frac{D_zH_y}{\kappa_{E_z}}+\psi_{E_x,z}\right)
      \right].

   :math:`H_x`, :math:`E_y`, :math:`H_y`, :math:`E_z`, and :math:`H_z`
   follow the same replacement rule for every curl derivative
   :math:`D_u q`. In AlgoPlasma this is implemented by
   ``sub_E03_cpml_3d_cartesian_E`` and ``sub_E03_cpml_3d_cartesian_H`` with the
   ``aex/bex/kex``, ``aey/bey/key``, ``aez/bez/kez``, and corresponding
   ``psi_*`` arrays.

   .. rubric:: 9. Reference

   - `Inan U S, Marshall R A. *Numerical electromagnetics: the FDTD method*. Cambridge University Press, 2011. <https://books.google.com/books?hl=zh-CN&lr=&id=mGdH_W0YBdQC&oi=fnd&pg=PR7&dq=Numerical+Electromagnetics++The+FDTD+Method&ots=G2FOsDB5R5&sig=vPvGj05ui_Fn1uDbmyEOqIFgqt0#v=onepage&q=Numerical%20Electromagnetics%20%20The%20FDTD%20Method&f=false>`_
   - Roden J A, Gedney S D. Convolution PML (CPML): An efficient FDTD implementation of the CFS-PML for arbitrary media.
     *Microwave and Optical Technology Letters*, 27(5): 334-339, 2000.
     DOI: `10.1002/1098-2760(20001205)27:5\<334::AID-MOP14\>3.0.CO;2-A <https://doi.org/10.1002/1098-2760(20001205)27:5%3C334::AID-MOP14%3E3.0.CO;2-A>`_.
