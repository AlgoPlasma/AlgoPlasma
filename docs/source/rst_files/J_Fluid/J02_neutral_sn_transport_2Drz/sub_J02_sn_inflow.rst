Inlet Distribution
==========================================================================================

``sub_J02_sn_inflow.f90`` 根据入口模型计算各离散速度上的非负分布值
:math:`g_m`。本文件先确定粒子速度的分布，再由入口归一化过程根据给定通量计算
实际入射分布函数 :math:`h_m`。这里的 :math:`g_m` 是中间结果，尚未包含入口的总粒子率。

.. rubric:: 1. 两类入口模型的物理含义

入口外侧气体模型描述气体中粒子的速度分布。入射粒子模型则描述穿过入口的粒子中，
各个速度所占的比例。速度法向分量越大的粒子，在相同时间内越容易穿过同一个面，
所以两种分布相差一个法向速率因子。

设入口外法向为 :math:`\boldsymbol n_f`，
入射半平面为 :math:`\beta_{f,m}<0`。
分布函数在面上给定后，速度微元贡献的入射通量为

.. math::

   \mathrm dJ_{\mathrm{in}}
       =|\boldsymbol v\cdot\boldsymbol n_f|\,
          \psi_{\mathrm{in}}(\boldsymbol v)\,\mathrm d^2v.

下面两种输入都从这个通量关系转换为边界上的分布函数。即使两种输入都采用高斯函数，
得到的入射分布函数也不同：入射粒子的速度统计已经包含法向速度的影响，转换时需要将其除去。

.. rubric:: 2. 入口外侧气体模型：二维漂移 Maxwell 分布

当前入口外侧气体模型采用温度 :math:`T>0`、质量 :math:`M>0`、
漂移速度 :math:`\boldsymbol U=(U_r,U_z)` 的二维 Maxwell 分布：

.. math::

   g(\boldsymbol v)=\frac{M}{2\pi k_{\mathrm B}T}
       \exp\!\left[-\frac{M}{2k_{\mathrm B}T}
         \big((v_r-U_r)^2+(v_z-U_z)^2\big)\right],
   \qquad \int_{\mathbb R^2}g\,\mathrm d^2v=1.

其中 :math:`k_{\mathrm B}=1.380649\times10^{-23}\,\mathrm{J\,K^{-1}}`。
在每个离散速度上取值即可：

.. math::

   g_m=g(v_m\mu_m,v_m\eta_m).

这里的 :math:`g` 是入口外侧气体的速度概率密度，积分为一；乘以气体数密度才得到
具有实际粒子数量的分布函数。它没有包含穿过入口时的法向速度因子，因此无需除以法向速度。
本过程在全部离散速度上求值，入口归一化过程再选取入射半平面。
速度积分只保留有限范围，并用有限个离散速度求和，因此离散积分不严格等于一，
最终入口通量以实际离散求和归一化。

``sub_J02_build_drifted_maxwellian_inflow_shape`` 的输入与输出：

- 输入 ``quadrature``；``temperature``，单位 :math:`\mathrm K`；
  ``particle_mass``，单位 :math:`\mathrm{kg}`；
  ``drift_velocity_r``、``drift_velocity_z``，单位 :math:`\mathrm{m\,s^{-1}}`。
- 输出并分配 ``inflow_shape(n_dir)``，即 :math:`g_m`，
  单位 :math:`\mathrm{s^2\,m^{-2}}`。它表示速度概率密度，而非气体数密度。
- 零漂移也使用本过程，只需令两个漂移分量为零。
- 输出 ``ierr``；无效求积、非正温度或质量返回错误。

.. rubric:: 3. 入射粒子模型：连续概率密度

设 :math:`p(\boldsymbol v)` 是已穿过入口的粒子在入射半平面上的概率密度，
按 :math:`\mathrm d^2v` 积分。若给定的入口粒子通量为 :math:`J_{\mathrm{in}}`，

.. math::

   \mathrm dJ_{\mathrm{in}}
       =J_{\mathrm{in}}p(\boldsymbol v)\,\mathrm d^2v
       =|\boldsymbol v\cdot\boldsymbol n_f|\,
          \psi_{\mathrm{in}}(\boldsymbol v)\,\mathrm d^2v.

因此，先除以法向速率，得到待归一化的分布

.. math::

   g_m=\frac{p_m}{v_m|\beta_{f,m}|}\quad(\beta_{f,m}<0),
   \qquad g_m=0\quad(\beta_{f,m}\geq0).

.. rubric:: 本章通道示例采用的入口分布

示例位于下端 :math:`z=z_{\min}`，外法向是 :math:`(0,-1)`，
所以进入计算域要求 :math:`v_z>0`。本例直接规定入射粒子的速度统计：
径向速度集中在 :math:`U_r=0` 附近，轴向速度集中在
:math:`U_z=200\,\mathrm{m\,s^{-1}}` 附近，仅保留 :math:`v_z>0` 的部分。
温度参数 :math:`T_{\mathrm{in}}=300\,\mathrm K` 和粒子质量
:math:`M=6.6335\times10^{-26}\,\mathrm{kg}` 确定速度分布的宽度

.. math::

   a_T^2=\frac{k_{\mathrm B}T_{\mathrm{in}}}{M}.

具体采用的高斯函数及其概率密度为

.. math::

   \widetilde p(v_r,v_z)=
   \begin{cases}
     \exp\!\left[-\dfrac{(v_r-U_r)^2+(v_z-U_z)^2}{2a_T^2}\right],&v_z>0,\\
     0,&v_z\leq0,
   \end{cases}

.. math::

   Z_p=\int_{v_z>0}\widetilde p\,\mathrm dv_r\,\mathrm dv_z,\qquad
   p=\frac{\widetilde p}{Z_p},\qquad
   p_m=p(v_{r,m},v_{z,m}).

:math:`p_m` 是速度概率密度在第 :math:`m` 个离散速度上的取值，
不是该速度对应的概率；乘速度面积权重后，:math:`w_mp_m` 才近似表示相应速度网格单元内的概率。
本例的温度和漂移参数描述的是入射粒子的速度统计，并不意味着入口外侧气体一定处于
同温度的 Maxwell 平衡态。

示例源码用 ``event_pdf(m)`` 保存 :math:`\widetilde p_m`，没有预先除以 :math:`Z_p`。
这样做是允许的：本过程先得到 :math:`g_m=\widetilde p_m/v_{z,m}`，
下一页再按目标通量归一化，共同系数 :math:`Z_p` 会在分子与分母中消去。
这里的高斯函数、除以法向速率以及通量归一化，是三个不同步骤。

当 :math:`v_{z,m}` 接近零时，上述除法可能产生很大的 :math:`g_m`。
因此应检查角度分辨率和接近切向的入射速度对结果的影响；
避开严格切向的求积点并不能消除这种模型敏感性。

``sub_J02_build_mc_crossing_pdf_inflow_shape`` 的输入与输出：

- 输入 ``quadrature``、单位外法向 ``normal_r/normal_z``，
  以及 ``crossing_pdf(n_dir)``：按二维速度面积定义的入射粒子的速度概率密度。
  对归一化概率密度，其单位为 :math:`\mathrm{s^2\,m^{-2}}`。
- 输入必须非负，只能在入射速度非零，且至少有一个正入射值。
  不要求输入已经归一化；公共比例会在后续通量归一化中消去。
- 输出 ``inflow_shape(n_dir)``：按上式除以法向速率后的分布值；
  对上述概率密度单位，它的单位为 :math:`\mathrm{s^3\,m^{-3}}`。
  它仍是中间结果，后续按通量归一化才得到实际的 :math:`\psi_{\mathrm{in}}`。
- 输出 ``ierr``。尺寸、法向、负值、出射速度上的非零输入或全零入射均有对应错误。

.. rubric:: 4. 入射粒子模型：各速度网格单元内的入射概率

另一类输入是每个速度网格单元的概率 :math:`P_m`。
它表示粒子速度落在这个网格单元内的概率，已经对单元的速度面积作过积分，与离散速度上的概率密度取值不同。
由 :math:`P_m\approx w_mp_m` 可得

.. math::

   g_m=\frac{P_m}{w_mv_m|\beta_{f,m}|}\quad(\beta_{f,m}<0).

与连续概率密度的转换相比，这里先用 :math:`P_m/w_m` 近似还原该离散速度上的概率密度，
再除以法向速率。因此分母中同时有速度面积权重和法向速率。

``sub_J02_build_mc_crossing_bins_inflow_shape`` 的输入与输出：

- 输入 ``quadrature``、单位外法向，以及
  ``crossing_bin_probability(n_dir)``：无量纲的各速度网格单元内的概率。
  这些数据可来自 Monte Carlo 采样，也可由已知概率密度积分得到。
- 输入必须非负、出射速度为零、入射总量为正。
  不强制总和等于一，后续会按目标通量归一化。
- 输出 ``inflow_shape(n_dir)``，按上式生成；
  若输入为无量纲概率，则输出单位仍为 :math:`\mathrm{s^3\,m^{-3}}`。
- 输出 ``ierr``，验证条件与连续概率密度接口类似。

.. rubric:: 5. 选择接口与传递结果

若物理输入是入口外侧气体的温度、粒子质量和漂移速度，使用漂移 Maxwell 分布生成过程。
若输入描述已穿过入口的粒子的速度统计，先判断数据是概率密度还是各速度网格单元内的概率，
再选择对应的概率转换接口。不要对入口外侧气体的速度分布除法向速度，也不要把概率密度误当成网格单元内的概率。

三个接口都输出待归一化的 :math:`g_m`。
入口归一化过程用 :math:`g_m` 计算离散通量，再将其调整到给定值。三个接口的中间结果
可以具有不同单位，归一化后的 :math:`h_m` 则具有相同的物理含义和单位。
增加入口模型时，应先明确输入是速度概率密度、单元内概率还是气体的分布函数，再转换为
:math:`g_m`。后续归一化和 DG 面积分仍可沿用。
