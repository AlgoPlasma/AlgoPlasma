001_Two-stream Example
======================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 概述与物理设置

   本示例演示如何将多个 AlgoPlasma 组件组合成一个面向具体问题的静电
   粒子网格（particle-in-cell, PIC）程序。算例采用二维空间和三维速度
   （2D3V），研究周期区域中的电子双流不稳定性。两束等权电子沿 :math:`x`
   方向以 :math:`\pm3v_{te}` 反向漂移，固定、均匀的正电荷背景维持初始电中性，
   其中 :math:`v_{te}=\sqrt{k_{\mathrm B}T_e/m_e}` 是每束 Maxwell 速度分布
   单个分量的标准差。

   第一束电子由 I01 在每个网格单元中规则布置粒子并采样速度；第二束复制其位置，
   同时反转三个速度分量，从而形成保持对称性的静启动。随后对两束电子施加纵向位移

   .. math::

      \boldsymbol{\xi}
      =\delta_0\frac{\boldsymbol{k}}{|\boldsymbol{k}|^2}
      \sin(\boldsymbol{k}\cdot\boldsymbol{x}),
      \qquad
      k_x=\frac{2\pi m_x}{L_x},\quad
      k_y=\frac{2\pi m_y}{L_y}.

   当前设置取 :math:`\delta_0=0.005` 和 :math:`(m_x,m_y)=(2,1)`，对应一阶
   近似下幅度为 0.5% 的密度扰动。指定单一斜模态既提供了明确的线性增长率比较对象，
   也同时检验二维沉积、场求解和插值过程中 :math:`x`、:math:`y` 两个方向的耦合。

   .. list-table:: 模拟参数
      :header-rows: 1
      :widths: 38 62

      * - 参数
        - 取值
      * - 模型
        - 二维静电、三维速度（2D3V）PIC
      * - 归一化计算域
        - :math:`L_x\times L_y=64\lambda_{De}\times64\lambda_{De}`
      * - 网格
        - :math:`64\times64`，:math:`\Delta x=\Delta y=\lambda_{De}`
      * - 电子束
        - 两束等权 Maxwell 分布，漂移速度 :math:`\pm3v_{te}`
      * - 宏粒子
        - 每束每单元 64 个（:math:`8\times8`），总数 524,288
      * - 时间步长与终止时刻
        - :math:`\Delta t=0.05\,\omega_{pe}^{-1}`，:math:`\omega_{pe}t_{\max}=40`
          （800 步）
      * - 初始扰动
        - :math:`\delta_0=0.005`，模态 :math:`(m_x,m_y)=(2,1)`
      * - 边界条件
        - 粒子和场在 :math:`x`、:math:`y` 方向均为周期性
      * - Poisson 求解容差
        - :math:`10^{-10}`

   .. rubric:: 实现与计算流程

   **程序结构。** 应用层仅包含三个 Fortran 源文件；编译、运行和后处理由独立脚本完成。

   .. list-table:: 文件及职责
      :header-rows: 1
      :widths: 38 62

      * - 文件
        - 职责
      * - ``src/main.f90``
        - 初始化 MPI，组织静电 PIC 时间循环，并控制诊断输出时刻。
      * - ``src/case_parameters.f90``
        - 定义网格、粒子数、归一化参数、时间步长、扰动和输出频率。
      * - ``src/two_stream_case.f90``
        - 管理算例数组，并封装 AlgoPlasma 组件调用、周期边界和粒子位置更新。
      * - ``CMakeLists.txt``
        - 选择本示例使用的 AlgoPlasma 源文件，并链接 MPI 与 HYPRE。
      * - ``run.sh`` / ``clean.sh``
        - 配置、编译和运行算例，或删除生成的编译文件、结果与图片。
      * - ``plot.py``
        - 读取粒子和电场输出，计算增长率、理论解和能量诊断，并生成参考图。

   **AlgoPlasma 组件调用。** 应用程序按照下表组合九组库例程。

   .. list-table:: AlgoPlasma 组件及其作用
      :header-rows: 1
      :widths: 15 45 40

      * - 组件
        - 调用例程
        - 作用
      * - :doc:`I01 </rst_files/I_Initializer/I01_par_distribute>`
        - :doc:`sub_I01_par_distribute_equilibrium </rst_files/I_Initializer/I01_par_distribute/sub_I01_par_distribute_equilibrium>`
        - 初始化粒子位置和 Maxwell 速度分布。
      * - :doc:`B01 </rst_files/B_Scatter/B01_scatter_3Dxyz>`
        - :doc:`sub_B01_scatter_3Dxyz </rst_files/B_Scatter/B01_scatter_3Dxyz/sub_B01_scatter_3Dxyz>`
        - 将粒子电荷沉积到网格。
      * - :doc:`D02 </rst_files/D_Poisson/D02_hypre_3Dxyz_bc>`
        - :doc:`sub_D02_hypre_3Dxyz_bc_A </rst_files/D_Poisson/D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A>`、
          :doc:`sub_D02_hypre_3Dxyz_bc_fortran </rst_files/D_Poisson/D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_fortran>`
        - 构造并求解周期 Poisson 方程。
      * - :doc:`D05 </rst_files/D_Poisson/D05_phi1d_to_phi3d>` / :doc:`D06 </rst_files/D_Poisson/D06_phi_to_E>`
        - :doc:`sub_D05_phi1d_to_phi3d </rst_files/D_Poisson/D05_phi1d_to_phi3d/sub_D05_phi1d_to_phi3d>`、
          :doc:`sub_D06_phi_to_E </rst_files/D_Poisson/D06_phi_to_E/sub_D06_phi_to_E>`
        - 重构三维势数组并计算网格电场。
      * - :doc:`C01 </rst_files/C_Gather/C01_gather_3Dxyz>`
        - :doc:`sub_C01_gather_3Dxyz </rst_files/C_Gather/C01_gather_3Dxyz/sub_C01_gather_3Dxyz>`
        - 将网格电场插值到粒子位置。
      * - :doc:`A01 </rst_files/A_Pusher/A01_Boris_3Dxyz>`
        - :doc:`sub_A01_Boris_3Dxyz </rst_files/A_Pusher/A01_Boris_3Dxyz/sub_A01_Boris_3Dxyz>`
        - 推进粒子速度。
      * - :doc:`F02 </rst_files/F_IO/F02_par_output>` / :doc:`F04 </rst_files/F_IO/F04_field_output>`
        - :doc:`sub_F02_par_output </rst_files/F_IO/F02_par_output/sub_F02_par_output>`、
          :doc:`sub_F04_field_output_3d_bin </rst_files/F_IO/F04_field_output/sub_F04_field_output_3d_bin>`
        - 输出粒子和电场二进制数据。

   AlgoPlasma 提供各阶段的数值操作，而应用层程序保留对数据结构、执行顺序、粒子位置更新、
   周期边界和输出频率的控制。完整主程序如下；算例相关的数组管理和接口细节被集中在
   ``two_stream_case`` 模块中，因此主循环保持简短、明确。

   .. literalinclude:: ../../../examples/001_two_stream_2d/src/main.f90
      :language: fortran
      :linenos:
      :caption: 双流不稳定性示例的应用层主程序。

   .. rubric:: 编译、运行与输出

   本示例需要 GNU Fortran、CMake、MPI、HYPRE 3.1 或更高版本，以及 NumPy、
   SciPy 和 Matplotlib。一种已经测试通过的 HYPRE 安装方式是从
   `HYPRE GitHub 仓库 <https://github.com/hypre-space/hypre>`__ 下载源码，
   并将 ``hypre/`` 目录与 ``algoplasma/`` 目录平行放置：

   .. code-block:: text

      parent/
      ├── algoplasma/
      └── hypre/

   然后编译并安装 HYPRE：

   .. code-block:: bash

      cd hypre/src
      ./configure
      make install -j 8

   其中 ``-j 8`` 表示使用 8 个 CPU 核心并行编译。安装完成后，进入本示例目录运行：

   .. code-block:: bash

      cd ../../algoplasma/examples/001_two_stream_2d
      ./run.sh

   在上述平行目录结构下，``run.sh`` 会自动使用 ``hypre/src/hypre`` 下的
   HYPRE 安装路径。如果 HYPRE 安装在其他位置，可显式指定安装前缀：

   .. code-block:: bash

      HYPRE_ROOT=/path/to/hypre/src/hypre ./run.sh

   如果已经位于 AlgoPlasma 仓库根目录，则通常直接执行：

   .. code-block:: bash

      cd examples/001_two_stream_2d
      bash run.sh

   ``run.sh`` 依次完成 CMake 配置、并行编译、单进程计算和 Python 后处理。
   当前示例仅支持一个 MPI 进程。程序将数据写入以下目录：

   - ``output/Ex`` 和 ``output/Ey``：初始步、第 1 步及其后每 5 步的电场快照；
   - ``output/par01``：初始步、第 1 步及其后每 50 步的粒子快照；
   - ``figures``：``plot.py`` 生成的两张参考图片。

   清理全部编译与运行产物可执行：

   .. code-block:: bash

      ./clean.sh

   .. rubric:: 参考结果

   **相空间演化。** 为直接观察粒子与指定斜模态之间的相位关联，结果采用沿波矢方向的坐标

   .. math::

      \theta=(k_xx+k_yy)\bmod 2\pi,
      \qquad
      v_{\parallel}=\frac{k_xv_x+k_yv_y}{|\boldsymbol{k}|}.

   这种表示对垂直于 :math:`\boldsymbol{k}` 的空间方向进行投影，因而比常规的
   :math:`x-v_x` 图更直接地揭示所激发模态的速度调制和粒子混合。初始两束电子位于
   :math:`v_{\parallel}\simeq\pm2.68v_{te}`；在 :math:`\omega_{pe}t=17.5`
   时形成明显的相位相关调制，在 :math:`\omega_{pe}t=25` 时展宽并混合，表明不稳定性
   已进入非线性饱和阶段。

   .. figure:: ../images/examples/001_two_stream_2d/fig1_phase_space_evolution.png
      :align: center
      :width: 75%

      :math:`\omega_{pe}t=0`、17.5 和 25 时沿波矢方向的电子相空间分布。

   **电场增长与能量平衡。** 第二张图的 (a) 显示

   .. math::

      E_{\parallel}=\frac{k_xE_x+k_yE_y}{|\boldsymbol{k}|}

   在 :math:`\omega_{pe}t=22.5` 时的空间分布。倾斜条纹对应所激发的
   :math:`(2,1)` 模态。图 (b) 跟踪该模态的幅值
   :math:`2|\widehat{E}_{\parallel}(2,1)|`。在
   :math:`10\leq\omega_{pe}t\leq19` 区间对其对数进行最小二乘拟合，得到
   :math:`\gamma_{\mathrm{PIC}}=0.2603\,\omega_{pe}` 和 :math:`R^2=0.9836`。

   图中的理论值通过求解对称双 Maxwell 电子束的 Vlasov--Poisson 色散关系获得：

   .. math::

      \epsilon(\omega,\boldsymbol{k})
      =1+\frac{1}{2(k\lambda_{De})^2}
      \sum_{\sigma=\pm1}\left[1+\zeta_\sigma Z(\zeta_\sigma)\right]=0,
      \qquad
      \zeta_\sigma=
      \frac{\omega-\sigma k v_{d,\parallel}}
      {\sqrt{2}\,k v_{te}},

   其中 :math:`v_{d,\parallel}=v_dk_x/k`。数值求根给出
   :math:`\gamma_{\mathrm{th}}=0.2616\,\omega_{pe}`，与 PIC 结果相差约 0.48%。
   图 (c) 表明电场能的增加与粒子动能的减少相互对应；整个计算中最大相对总能量误差为
   0.0183%。这些结果共同验证了组合程序能够再现预期的线性增长、非线性相空间演化和
   良好的全局能量守恒。

   .. figure:: ../images/examples/001_two_stream_2d/fig2_field_growth_energy.png
      :align: center
      :width: 75%

      双流不稳定性示例的电场结构、模态增长和能量平衡。(a) 在
      :math:`\omega_{pe}t=22.5` 时的平行电场；(b) :math:`(2,1)` 模态幅值及
      PIC 拟合与动理学理论比较；(c) 场能、粒子动能和相对总能量误差。

.. container:: ap-lang ap-lang-en

   .. rubric:: Overview and Physical Setup

   This example shows how several AlgoPlasma components can be assembled into
   an application-specific electrostatic particle-in-cell (PIC) program. It
   considers the electron two-stream instability in two spatial and three
   velocity dimensions (2D3V) with periodic boundaries. Two equally weighted
   electron populations drift in opposite directions along :math:`x` at
   :math:`\pm3v_{te}`, while a uniform, immobile positive background maintains
   initial charge neutrality. Here
   :math:`v_{te}=\sqrt{k_{\mathrm B}T_e/m_e}` is the standard deviation of one
   velocity component in each Maxwellian beam.

   I01 places the first population regularly within each grid cell and samples
   its velocities. The second population copies those positions and reverses
   all three velocity components, producing a symmetry-preserving quiet start.
   Both populations are then displaced longitudinally by

   .. math::

      \boldsymbol{\xi}
      =\delta_0\frac{\boldsymbol{k}}{|\boldsymbol{k}|^2}
      \sin(\boldsymbol{k}\cdot\boldsymbol{x}),
      \qquad
      k_x=\frac{2\pi m_x}{L_x},\quad
      k_y=\frac{2\pi m_y}{L_y}.

   The present setup uses :math:`\delta_0=0.005` and
   :math:`(m_x,m_y)=(2,1)`, corresponding to a 0.5% first-order density
   perturbation. Seeding one oblique mode provides an unambiguous target for
   the linear-growth comparison while exercising coupling in both spatial
   directions during deposition, field solution, and interpolation.

   .. list-table:: Simulation parameters
      :header-rows: 1
      :widths: 38 62

      * - Parameter
        - Value
      * - Model
        - Two-dimensional electrostatic, three-velocity (2D3V) PIC
      * - Normalized domain
        - :math:`L_x\times L_y=64\lambda_{De}\times64\lambda_{De}`
      * - Grid
        - :math:`64\times64`, with :math:`\Delta x=\Delta y=\lambda_{De}`
      * - Electron populations
        - Two equally weighted Maxwellians drifting at :math:`\pm3v_{te}`
      * - Macroparticles
        - 64 per cell per beam (:math:`8\times8`), 524,288 in total
      * - Time step and duration
        - :math:`\Delta t=0.05\,\omega_{pe}^{-1}` and
          :math:`\omega_{pe}t_{\max}=40` (800 steps)
      * - Initial perturbation
        - :math:`\delta_0=0.005`, mode :math:`(m_x,m_y)=(2,1)`
      * - Boundary conditions
        - Periodic for particles and fields in :math:`x` and :math:`y`
      * - Poisson-solver tolerance
        - :math:`10^{-10}`

   .. rubric:: Implementation and Workflow

   **Program structure.** The application layer contains only three Fortran
   source files; separate scripts handle configuration, execution, and
   post-processing.

   .. list-table:: Files and responsibilities
      :header-rows: 1
      :widths: 38 62

      * - File
        - Responsibility
      * - ``src/main.f90``
        - Initializes MPI, defines the electrostatic PIC time loop, and controls
          diagnostic output times.
      * - ``src/case_parameters.f90``
        - Defines the grid, particle count, normalized parameters, time step,
          perturbation, and output cadence.
      * - ``src/two_stream_case.f90``
        - Manages example arrays and wraps AlgoPlasma calls, periodic
          boundaries, and the particle-position update.
      * - ``CMakeLists.txt``
        - Selects the AlgoPlasma sources used here and links MPI and HYPRE.
      * - ``run.sh`` / ``clean.sh``
        - Configure, build, and run the example, or remove generated build,
          output, and figure files.
      * - ``plot.py``
        - Reads particle and field output, evaluates growth, theory, and energy
          diagnostics, and generates the reference figures.

   **AlgoPlasma component calls.** The application combines nine groups of
   library routines.

   .. list-table:: AlgoPlasma components and roles
      :header-rows: 1
      :widths: 15 45 40

      * - Component
        - Called routine
        - Role
      * - :doc:`I01 </rst_files/I_Initializer/I01_par_distribute>`
        - :doc:`sub_I01_par_distribute_equilibrium </rst_files/I_Initializer/I01_par_distribute/sub_I01_par_distribute_equilibrium>`
        - Initialize particle positions and Maxwellian velocities.
      * - :doc:`B01 </rst_files/B_Scatter/B01_scatter_3Dxyz>`
        - :doc:`sub_B01_scatter_3Dxyz </rst_files/B_Scatter/B01_scatter_3Dxyz/sub_B01_scatter_3Dxyz>`
        - Deposit particle charge onto the grid.
      * - :doc:`D02 </rst_files/D_Poisson/D02_hypre_3Dxyz_bc>`
        - :doc:`sub_D02_hypre_3Dxyz_bc_A </rst_files/D_Poisson/D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A>`,
          :doc:`sub_D02_hypre_3Dxyz_bc_fortran </rst_files/D_Poisson/D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_fortran>`
        - Assemble and solve the periodic Poisson problem.
      * - :doc:`D05 </rst_files/D_Poisson/D05_phi1d_to_phi3d>` / :doc:`D06 </rst_files/D_Poisson/D06_phi_to_E>`
        - :doc:`sub_D05_phi1d_to_phi3d </rst_files/D_Poisson/D05_phi1d_to_phi3d/sub_D05_phi1d_to_phi3d>`,
          :doc:`sub_D06_phi_to_E </rst_files/D_Poisson/D06_phi_to_E/sub_D06_phi_to_E>`
        - Reconstruct the three-dimensional potential array and evaluate the
          grid electric field.
      * - :doc:`C01 </rst_files/C_Gather/C01_gather_3Dxyz>`
        - :doc:`sub_C01_gather_3Dxyz </rst_files/C_Gather/C01_gather_3Dxyz/sub_C01_gather_3Dxyz>`
        - Interpolate grid fields to particle positions.
      * - :doc:`A01 </rst_files/A_Pusher/A01_Boris_3Dxyz>`
        - :doc:`sub_A01_Boris_3Dxyz </rst_files/A_Pusher/A01_Boris_3Dxyz/sub_A01_Boris_3Dxyz>`
        - Advance particle velocities.
      * - :doc:`F02 </rst_files/F_IO/F02_par_output>` / :doc:`F04 </rst_files/F_IO/F04_field_output>`
        - :doc:`sub_F02_par_output </rst_files/F_IO/F02_par_output/sub_F02_par_output>`,
          :doc:`sub_F04_field_output_3d_bin </rst_files/F_IO/F04_field_output/sub_F04_field_output_3d_bin>`
        - Write particle and electric-field data in binary form.

   AlgoPlasma supplies the numerical operations at each stage, while the
   application retains control of data structures, execution order, particle
   position updates, periodic boundaries, and output cadence. The complete
   driver is shown below. Example-specific array management and interface
   details remain in ``two_stream_case``, leaving the main loop short and
   explicit.

   .. literalinclude:: ../../../examples/001_two_stream_2d/src/main.f90
      :language: fortran
      :linenos:
      :caption: Application-level driver of the two-stream example.

   .. rubric:: Build, Run, and Outputs

   The example requires GNU Fortran, CMake, MPI, HYPRE 3.1 or later, NumPy,
   SciPy, and Matplotlib. One tested HYPRE setup is to download HYPRE from
   the `HYPRE GitHub repository <https://github.com/hypre-space/hypre>`__ and
   place the ``hypre/`` directory next to the ``algoplasma/`` directory:

   .. code-block:: text

      parent/
      ├── algoplasma/
      └── hypre/

   Then build and install HYPRE with:

   .. code-block:: bash

      cd hypre/src
      ./configure
      make install -j 8

   Here ``-j 8`` uses 8 CPU cores for parallel compilation. After installation,
   enter this example and run:

   .. code-block:: bash

      cd ../../algoplasma/examples/001_two_stream_2d
      ./run.sh

   With the sibling-directory layout above, ``run.sh`` automatically uses the
   HYPRE installation under ``hypre/src/hypre``. If HYPRE is installed
   elsewhere, pass the installation prefix explicitly:

   .. code-block:: bash

      HYPRE_ROOT=/path/to/hypre/src/hypre ./run.sh

   If you are already inside the AlgoPlasma repository, the usual command is:

   .. code-block:: bash

      cd examples/001_two_stream_2d
      bash run.sh

   ``run.sh`` performs CMake configuration, a parallel build, the single-rank
   calculation, and Python post-processing in sequence. The present example
   supports one MPI rank. Generated files are organized as follows:

   - ``output/Ex`` and ``output/Ey``: electric-field snapshots at the initial
     and first steps, then every five steps;
   - ``output/par01``: particle snapshots at the initial and first steps, then
     every fifty steps;
   - ``figures``: the two reference figures generated by ``plot.py``.

   Remove all build and run products with:

   .. code-block:: bash

      ./clean.sh

   .. rubric:: Reference Results

   **Phase-space evolution.** To expose phase correlation with the seeded
   oblique mode, the distribution is plotted in coordinates aligned with the
   wave vector:

   .. math::

      \theta=(k_xx+k_yy)\bmod 2\pi,
      \qquad
      v_{\parallel}=\frac{k_xv_x+k_yv_y}{|\boldsymbol{k}|}.

   This projection removes the spatial direction perpendicular to
   :math:`\boldsymbol{k}` and therefore reveals the selected mode's velocity
   modulation and particle mixing more directly than a conventional
   :math:`x-v_x` plot. The two populations initially lie near
   :math:`v_{\parallel}\simeq\pm2.68v_{te}`. A phase-correlated modulation is
   distinct at :math:`\omega_{pe}t=17.5`; by
   :math:`\omega_{pe}t=25`, the populations have broadened and mixed as the
   instability enters nonlinear saturation.

   .. figure:: ../images/examples/001_two_stream_2d/fig1_phase_space_evolution.png
      :align: center
      :width: 75%

      Electron phase-space distributions in wave-aligned coordinates at
      :math:`\omega_{pe}t=0`, 17.5, and 25.

   **Field growth and energy balance.** Panel (a) of the second figure shows

   .. math::

      E_{\parallel}=\frac{k_xE_x+k_yE_y}{|\boldsymbol{k}|}

   at :math:`\omega_{pe}t=22.5`; the oblique bands follow the seeded
   :math:`(2,1)` mode. Panel (b) tracks its amplitude
   :math:`2|\widehat{E}_{\parallel}(2,1)|`. A least-squares fit to its logarithm
   over :math:`10\leq\omega_{pe}t\leq19` gives
   :math:`\gamma_{\mathrm{PIC}}=0.2603\,\omega_{pe}` with
   :math:`R^2=0.9836`.

   The theoretical curve is obtained by solving the Vlasov--Poisson dispersion
   relation for two symmetric drifting Maxwellians,

   .. math::

      \epsilon(\omega,\boldsymbol{k})
      =1+\frac{1}{2(k\lambda_{De})^2}
      \sum_{\sigma=\pm1}\left[1+\zeta_\sigma Z(\zeta_\sigma)\right]=0,
      \qquad
      \zeta_\sigma=
      \frac{\omega-\sigma k v_{d,\parallel}}
      {\sqrt{2}\,k v_{te}},

   where :math:`v_{d,\parallel}=v_dk_x/k`. Numerical root finding gives
   :math:`\gamma_{\mathrm{th}}=0.2616\,\omega_{pe}`, differing from the PIC
   result by approximately 0.48%. Panel (c) shows the corresponding transfer
   between field and particle kinetic energies. The maximum relative
   total-energy error over the run is 0.0183%. Together, these diagnostics show
   the expected linear growth, nonlinear phase-space evolution, and good global
   energy conservation of the assembled workflow.

   .. figure:: ../images/examples/001_two_stream_2d/fig2_field_growth_energy.png
      :align: center
      :width: 75%

      Electric-field structure, mode growth, and energy balance in the
      two-stream example. (a) Parallel electric field at
      :math:`\omega_{pe}t=22.5`. (b) Amplitude of the :math:`(2,1)` mode,
      compared with a PIC fit and kinetic theory. (c) Field energy, particle
      kinetic energy, and relative total-energy error.
