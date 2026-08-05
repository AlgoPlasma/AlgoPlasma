init_particles_bin.py
---------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 用途

   ``init_particles_bin.py`` 是 I02 的离线粒子初值生成脚本。它在三维 T 形计算区域内采样电子和离子宏粒子，先根据解析密度分布生成位置，再按物种规则生成速度，最后写入 Fortran 载入例程可读取的原始二进制文件。

   .. rubric:: 计算区域

   全局网格大小为

   .. math::

      (i_x,i_y,i_z) = (256,\,64,\,256).

   有效区域不是完整长方体，而是 T 形区域：

   .. math::

      0 \le y < 64,\qquad 0 \le z < 256,
      \qquad
      \left\{
      \begin{aligned}
      &64 \le x < 192, && z<72,\\
      &0 \le x < 256,  && z\ge 72.
      \end{aligned}
      \right.

   脚本通过 ``is_inside_t_domain`` 判断候选粒子是否属于该区域。

   .. rubric:: 位置采样

   电子和离子共享同一个位置池。目标密度写作

   .. math::

      n(x,y,z) = n_x(x)\,n_y(y)\,n_z(z),

   这里的 ``x,y,z`` 是连续网格坐标（cell-index/code units）。

   该密度分布限制在 T 形有效区域内。三个方向的密度因子分别控制不同的空间变化：
   ``n_x`` 是横向截断正弦分布，正弦函数为正时从背景值平滑升高，为负时被截断回背景值；
   ``n_y`` 是弱正弦调制，以 ``amp_y=0.1`` 让 ``y`` 方向只出现小幅周期起伏；
   ``n_z`` 是类似 Gaussian 的轴向分布，以 ``z_p=60`` 为中心、``z_w=30`` 为宽度，
   并保留 ``nmin_z=0.2`` 的背景密度。

   .. math::

      n_x = 0.2 + 0.8\max\left[\sin\left(2\pi\frac{x-64}{256}\right),0\right],

   .. math::

      n_y = 0.1\sin\left(2\pi\frac{y}{64/7}\right)+0.9,
      \qquad
      n_z = 0.8\exp\left[-\left(\frac{z-60}{30}\right)^2\right]+0.2.

   脚本用拒绝采样从 ``sample_density(x,y,z)`` 生成位置，因此两个物种的初始空间分布相同。

   .. figure:: ../../../images/I_Initializer/I02_par_init_and_load/init__nn_slices.png
      :align: center
      :width: 40%


   .. rubric:: 速度采样

   电子速度按三维 Maxwellian 分布采样，漂移速度为零。离子也先按 Maxwellian 分布采样，
   但随后会覆盖 ``v_z``，令其成为轴向位置的给定函数：

   .. math::

      z_{\mathrm{phys}} = z \times 0.1\times 10^{-3},

   .. math::

      v_{z,i}
      =
      \frac{
      \frac{1}{2}
      \left[a + \dfrac{b-a}{1+\left(z_{\mathrm{phys}}/c\right)^d}\right]
      }{VV}.

   当前常数为 ``a=1.6575e4``、``b=-1.5208e3``、``c=0.0091``、
   ``d=4.4528``、``VV=20000000.00``。

   下图给出该轴向漂移速度在物理单位下的剖面；写入二进制粒子文件的是除以 ``VV`` 后的归一化速度。

   .. figure:: ../../../images/I_Initializer/I02_par_init_and_load/init__ion_axial_drift_profile.png
      :align: center
      :width: 40%


   .. rubric:: 输出与运行成本

   脚本默认生成

   .. math::

      N_e = N_i = 5\times 10^7

   个宏粒子，并输出到：

   .. code-block:: text

      output_init_particles_bin/par_ele_init.bin
      output_init_particles_bin/par_ion_init.bin

   每个粒子记录为 6 个 ``float64`` 值：``x,y,z,vx,vy,vz``。脚本还会输出初始密度组图和离子轴向漂移速度剖面图。
   由于默认粒子数很大，运行前应确认内存、磁盘空间和 NumPy/SciPy/Matplotlib 环境。

.. container:: ap-lang ap-lang-en

   .. rubric:: Purpose

   ``init_particles_bin.py`` is the offline particle-initial-condition generator
   for I02. It samples electron and ion macro-particles in a three-dimensional
   T-shaped computational region, first generating positions from an analytical
   density model, then assigning species-dependent velocities, and finally
   writing raw binary files for the Fortran loader.

   .. rubric:: Computational Domain

   The global grid size is

   .. math::

      (i_x,i_y,i_z) = (256,\,64,\,256).

   The admissible region is T-shaped rather than a full rectangular box:

   .. math::

      0 \le y < 64,\qquad 0 \le z < 256,
      \qquad
      \left\{
      \begin{aligned}
      &64 \le x < 192, && z<72,\\
      &0 \le x < 256,  && z\ge 72.
      \end{aligned}
      \right.

   The helper ``is_inside_t_domain`` checks whether candidate particles belong
   to this valid region.

   .. rubric:: Position Sampling

   Electrons and ions share the same sampled position pool. The target density is

   .. math::

      n(x,y,z) = n_x(x)\,n_y(y)\,n_z(z),

   Here ``x,y,z`` are continuous grid coordinates (cell-index/code units).

   The density is restricted to the T-shaped region. The three density factors control different
   spatial variations: ``n_x`` is a clipped transverse sinusoid that rises above
   the background only where the sine is positive; ``n_y`` is a weak sinusoidal
   modulation with ``amp_y=0.1``; and ``n_z`` is a Gaussian-like axial profile
   centered at ``z_p=60`` with width ``z_w=30`` and background level
   ``nmin_z=0.2``.

   .. math::

      n_x = 0.2 + 0.8\max\left[\sin\left(2\pi\frac{x-64}{256}\right),0\right],

   .. math::

      n_y = 0.1\sin\left(2\pi\frac{y}{64/7}\right)+0.9,
      \qquad
      n_z = 0.8\exp\left[-\left(\frac{z-60}{30}\right)^2\right]+0.2.

   The script uses rejection sampling against ``sample_density(x,y,z)``, so both
   species have the same initial spatial distribution.

   .. figure:: ../../../images/I_Initializer/I02_par_init_and_load/init__nn_slices.png
      :align: center
      :width: 40%


   .. rubric:: Velocity Sampling

   Electron velocities are sampled from a three-dimensional Maxwellian
   distribution with zero drift. Ion velocities are also initially Maxwellian,
   but ion ``v_z`` is then overwritten by a prescribed axial profile:

   .. math::

      z_{\mathrm{phys}} = z \times 0.1\times 10^{-3},

   .. math::

      v_{z,i}
      =
      \frac{
      \frac{1}{2}
      \left[a + \dfrac{b-a}{1+\left(z_{\mathrm{phys}}/c\right)^d}\right]
      }{VV}.

   The current constants are ``a=1.6575e4``, ``b=-1.5208e3``,
   ``c=0.0091``, ``d=4.4528``, and ``VV=20000000.00``.

   The figure below shows this axial drift profile in physical units; the binary
   particle file stores the normalized velocity after division by ``VV``.

   .. figure:: ../../../images/I_Initializer/I02_par_init_and_load/init__ion_axial_drift_profile.png
      :align: center
      :width: 40%


   .. rubric:: Outputs and Runtime Cost

   By default, the script generates

   .. math::

      N_e = N_i = 5\times 10^7

   macro-particles and writes:

   .. code-block:: text

      output_init_particles_bin/par_ele_init.bin
      output_init_particles_bin/par_ion_init.bin

   Each particle record contains six ``float64`` values:
   ``x,y,z,vx,vy,vz``. The script also writes the initial-density panel and the
   ion axial drift profile. Because the default particle count is large, check
   memory, disk space, and the NumPy/SciPy/Matplotlib environment before running it.
