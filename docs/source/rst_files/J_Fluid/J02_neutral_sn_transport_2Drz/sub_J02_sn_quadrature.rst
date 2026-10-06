Velocity Quadrature
==========================================================================================

``sub_J02_sn_quadrature.f90`` 生成离散速度及其积分权重。
入口归一化、壁面通量、输运求解和密度重构使用这组离散速度，
把连续的二维速度积分写成有限项求和。

.. rubric:: 1. 当前采用的求积方法

当前实现将二维速度平面写成极坐标，再使用角度与速率的乘积规则：

- 角度方向使用全圆等角复合中点法，每个角区间取一个中点。
- 速率方向划分为等宽区间，在区间中点取分布值，权重则对区间内的
  :math:`v\,\mathrm dv` 精确积分。
- 速率上限由调用者给定，积分域由无限速度平面截断为有限圆盘。

上述方法属于中点求积，与 Gauss–Legendre、Gauss–Laguerre 求积不同。
角度选项 ``gauss-chebyshev`` 在当前代码中只是 ``midpoint`` 的别名：
两者进入同一实现，生成完全相同的节点和权重，并非另一种求积方法。

.. figure:: /_static/J_Fluid/sn_velocity_quadrature.svg
   :alt: 速度圆盘按角区间和速率区间划分，每个扇环有一个中点节点
   :width: 900px

   一个离散速度对应一个扇环。角区间等宽不意味着所有节点的二维速度权重相等；
   越靠外的同宽速率区间具有越大的速度面积。图中橙色扇环的权重由后文的
   :math:`W^v_gW^\theta_a` 给出。

.. rubric:: 2. 从二维速度积分到极坐标积分

速度积分把所有速度的贡献累加成密度或流密度。例如，在固定空间位置 :math:`(r,z)`，

.. math::

   n=\int_{\mathbb R^2}\psi(v_r,v_z)\,\mathrm dv_r\,\mathrm dv_z,\qquad
   j_r=\int_{\mathbb R^2}v_r\psi(v_r,v_z)\,\mathrm dv_r\,\mathrm dv_z.

第一式累加粒子数量，第二式还乘径向速度，得到径向粒子流密度。
下面用 :math:`F(v_r,v_z)` 表示被积函数，按待求物理量取值：

- 计算密度时，:math:`F=\psi`；
- 计算径向流密度时，:math:`F=v_r\psi`；
- 计算轴向流密度时，:math:`F=v_z\psi`。

求积过程生成取值位置与权重；调用端在这些位置计算 :math:`F`，再进行加权求和。

为划分速度平面，将速度大小记为 :math:`v`，方向角记为 :math:`\theta`：

.. math::

   v_r=v\cos\theta,\qquad v_z=v\sin\theta,\qquad
   \mathrm dv_r\,\mathrm dv_z=v\,\mathrm dv\,\mathrm d\theta.

因此在当前截断域内，

.. math::

   I[F]=\int_0^{2\pi}\int_0^{v_{\max}}
             F(v\cos\theta,v\sin\theta)\,v\,\mathrm dv\,\mathrm d\theta.

这里的 :math:`\theta` 是速度平面中的方向角，不是周向张角 :math:`\Theta`。
权重中的 :math:`v` 来自速度极坐标变换的雅可比。

.. rubric:: 3. 角度中点规则的节点与权重

将全圆均分为 :math:`N_\theta` 个区间，区间宽度与中点为

.. math::

   \Delta\theta=\frac{2\pi}{N_\theta},\qquad
   \theta_a=\left(a-\frac12\right)\Delta\theta,\qquad
   a=1,\ldots,N_\theta.

在每个区间内以中点函数值近似函数，得到

.. math::

   \int_0^{2\pi}F(\theta)\,\mathrm d\theta
       \approx\sum_{a=1}^{N_\theta}W^\theta_aF(\theta_a),\qquad
   W^\theta_a=\Delta\theta,\quad
   \mu_a=\cos\theta_a,\quad\eta_a=\sin\theta_a.

当前要求 :math:`N_\theta\geq8` 且可被四整除。
这样四象限具有相同结构，中点不落在坐标轴上，并能为轴向、径向镜面反射提供成对方向。
扫描过程不支持方向余弦为零的节点，因此这一约束不仅是精度选择，也是当前实现的调用条件。

.. rubric:: 4. 速率区间的节点与权重

将 :math:`[0,v_{\max}]` 分成 :math:`N_v` 个等宽区间：

.. math::

   \Delta v=\frac{v_{\max}}{N_v},\qquad
   v_{g-1/2}=(g-1)\Delta v,\qquad
   v_{g+1/2}=g\Delta v,\qquad
   v_g=\left(g-\frac12\right)\Delta v.

只对分布值作中点近似，速度面积权重保留精确积分：

.. math::

   \int_{v_{g-1/2}}^{v_{g+1/2}}F(v)\,v\,\mathrm dv
       \approx F(v_g)W^v_g,\qquad
   W^v_g=\int_{v_{g-1/2}}^{v_{g+1/2}}v\,\mathrm dv
        =\frac{v_{g+1/2}^2-v_{g-1/2}^2}{2}
        =v_g\Delta v.

因此第一个速率节点严格大于零，后续 :math:`\nu_K/v_g` 和入射概率转换不会在零速率处除零。
对区间内的常数函数，这个权重给出精确的速度面积；
对随速度变化的分布仍有离散误差，不能据此称整个求积为精确积分。

.. rubric:: 5. 合并索引、总权重与量纲

程序将角度和速率合并为一个索引。每个速率取值下先排列所有角度：

.. math::

   m=(g-1)N_\theta+a,\qquad N_{\mathrm{dir}}=N_vN_\theta,
   \qquad
   \boldsymbol v_m=v_g(\mu_a,\eta_a),\qquad
   w_m=W^v_gW^\theta_a.

于是

.. math::
   :label: sn-quadrature-sum

   I[F]\approx\sum_{m=1}^{N_{\mathrm{dir}}}w_mF(\boldsymbol v_m).

这里 :math:`m` 同时确定一个速率 :math:`v_g` 和一个方向
:math:`(\mu_a,\eta_a)`，合起来才是一个离散速度。
例如 :math:`N_v=2,N_\theta=8` 时，共有 16 个离散速度；
前 8 个具有同一速率、不同方向，后 8 个使用另一个速率。
程序的 ``n_dir`` 存储这个总数，不能只按角度数分配数组。
:math:`w_m` 的单位为 :math:`\mathrm{m^2\,s^{-2}}`；
对常数函数，总权重为截断速度圆盘的面积：

.. math::

   \sum_m w_m=2\pi\sum_g W^v_g=\pi v_{\max}^2.

由同一规则得到的密度与流密度分别为

.. math::

   n\approx\sum_m w_m\psi_m,\qquad
   n\boldsymbol u\approx\sum_mw_m\boldsymbol v_m\psi_m.

密度求和不再额外乘速率，因为权重已经含有 :math:`v\,\mathrm dv`；
流密度中的速度因子则来自所求物理量本身，两者不能相互替代。

.. rubric:: 6. 各过程的输入与输出

``sub_J02_build_angular_nodes`` —— 生成角度规则。

- 输入 ``n_angles``：角节点数，满足上述数量限制。
- 输入 ``scheme``：当前识别 ``midpoint`` 和 ``gauss-chebyshev``，结果相同。
- 输出 ``mu(n_angles)``、``eta(n_angles)``：无量纲方向余弦；
  输出 ``weight(n_angles)``：角权重 :math:`W^\theta_a`，不是最终二维权重。
- 输出 ``ierr``：数量或方案名不合法时返回错误。输出数组由过程分配。

``sub_J02_build_speed_groups`` —— 生成速率节点及对应的速度面积权重。

- 输入 ``n_speeds``：正整数；``speed_max``：正的截断速率，单位 :math:`\mathrm{m\,s^{-1}}`。
- 输出 ``speed(n_speeds)``：正速率节点；
  ``weight(n_speeds)``：:math:`W^v_g`，单位 :math:`\mathrm{m^2\,s^{-2}}`。
- 输出 ``ierr``：报告速率数量和截断速率是否有效。

``sub_J02_build_phase_quadrature`` —— 构造求解器使用的完整求积对象。

- 输入 ``n_angles``、``n_speeds``、``angular_scheme``、``speed_max``。
- 内部调用前两个过程，按速率组优先、角度在组内连续的顺序展开。
- 输出 ``quadrature``：记录节点数量、速率上限，以及长度均为 ``n_dir`` 的
  ``mu``、``eta``、``speed``、``weight``。
  其中 ``weight`` 此时才是 :math:`w_m`。
- 输出 ``ierr``：传播角度或速率构造错误。成功后，该对象可直接用于后续各过程。

.. rubric:: 7. 精度选择与更换求积方法

角度数量控制方向分辨率，速率区间数控制有限速度区间内的分辨率，
速率上限控制被截去的尾部范围。增加速率区间数并不能补回上限之外的分布；
有漂移入口时，应同时考虑热速度尺度和漂移速度，检查有效分布是否落在截断圆盘内。

若将来增加非均匀速率划分或其他求积规则，应说明权重对应的积分变量及面积元，并保证节点速率、权重为正，
方向为单位向量。当前镜面方向查找依赖每个速率组内连续排列的等数量角节点；
扫描还要求两个方向余弦都非零。修改规则时必须一并核查这些条件，
不能只替换权重而假定反射映射仍然正确。

后续入口页在这些节点上取分布值，入口归一化页用同一组 :math:`w_m`
将分布归一化到给定入口通量；求解与重构继续使用这组离散速度。
