B04: Calling Example
====================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-b04-doc

   .. rubric:: 从几何准备到密度输出

   本例采用一个非均匀环形扇区，角向两端是物理端面。单个宏粒子位于已知单元中，代表八个真实粒子。
   依次完成 **准备体积 → 清零密度 → 沉积 → 读取总粒子数 → 可选单元平均** 。
   例子没有轴线，因而直接使用内径节点。

   .. literalinclude:: ../../../../../examples/B04_scatter_3d_cyl_nonuniform/main.f90
      :language: fortran
      :linenos:

   源文件位于仓库的 ``examples/B04_scatter_3d_cyl_nonuniform/main.f90``，也可
   :download:`下载示例主程序 <../../../../../examples/B04_scatter_3d_cyl_nonuniform/main.f90>`。
   按下面的命令，将它与仓库中的 B04 模块一起编译。

   .. rubric:: 编译和预期输出

   .. code-block:: bash

      # From the repository root; GNU Fortran
      mkdir -p examples/B04_scatter_3d_cyl_nonuniform/build
      gfortran -cpp -std=f2008 -fdefault-real-8 -O0 -g -fcheck=all \
        -I B_Scatter/B04_scatter_3d_cyl_nonuniform \
        -J examples/B04_scatter_3d_cyl_nonuniform/build \
        B_Scatter/B04_scatter_3d_cyl_nonuniform/mod_B04_scatter_3d_cyl_nonuniform.f90 \
        examples/B04_scatter_3d_cyl_nonuniform/main.f90 \
        -o examples/B04_scatter_3d_cyl_nonuniform/build/b04_minimal
      examples/B04_scatter_3d_cyl_nonuniform/build/b04_minimal


   运行结束后，终端显示：

   .. code-block:: text

      Represented number =     8.000000
      Cell array shape = 2 2 2

   第一行表示沉积后的节点数据合计代表 **8 个真实粒子**，与输入的宏粒子权重一致。
   ``density/inv_volume`` 等于节点密度乘以有效体积，各节点对应的粒子数相加得到总数。
   第二行表示 ``cell_density`` 在径向、角向和轴向各有 **2 个单元**。
   坐标按统一的长度尺度解释；若按 m 使用，``density`` 的单位为 :math:`\mathrm{m}^{-3}`。

   .. _b04-adapt-example-zh:

   .. rubric:: 把这个单粒子示例接入自己的程序

   可以沿用上面的调用顺序，把示例中的网格和单个粒子替换为自己的数据。
   **网格准备一次；每轮沉积先清零，再把本轮所有粒子的贡献累加进去。**

   **第一步：换成自己的网格，准备对应数组。**

   .. list-table:: 从示例设置到实际输入
      :header-rows: 1
      :widths: 23 33 44

      * - 数据
        - 本例中的设置
        - 接入自己的程序时
      * - 节点位置
        - 三组坐标分别给出 3 个节点，每向 2 个单元
        - 填入实际的 ``r``、``phi``、``z``；各组严格递增，半径保留到圆柱轴线的真实距离
      * - 角向连接
        - ``.false.``：扇区两端是物理端面
        - 周期连接用 ``.true.``，各次调用采用相同设置；坐标仍含两端点，密度只存独立角节点
      * - 几何与密度数组
        - 节点数组每向 3 项，单元数组每向 2 项
        - 按自己的节点数和周期设置分配，见 :ref:`数组布局 <b04-grid-zh>`；随后调用几何准备例程

   网格与周期设置固定时，``inv_volume`` 和 ``phi_measure`` 可供后续各轮复用。

   **第二步：为每个粒子准备位置、单元号和贡献量。**

   示例中的 ``[1.25,0.5,0.5]`` 是实际柱坐标位置，``[0,0,0]`` 表示三个方向均在第一个单元内。
   在自己的程序中，先按物理边界规则处理粒子，再用同一组节点坐标确定其所在单元。
   每次沉积传入的贡献量决定输出是哪一种密度：

   - **数密度：** 传入宏粒子代表的真实粒子数 ``wp``，对应本例的 ``8.0``。
   - **电荷密度：** 传入 ``qp*wp``，其中 ``qp`` 是一个真实粒子的带符号电荷。
     不同物种可以累加到同一电荷密度数组；各物种数密度则分别保存。

   **第三步：把一次沉积调用放进粒子循环。**

   下面是粒子数据已经准备好时的调用结构。``particle_position(:,p)`` 保存第 ``p`` 个粒子的三个坐标，
   ``particle_cell(:,p)`` 保存其三个单元号，``particle_amount(p)`` 保存上一步选定的贡献量；
   ``np`` 为本轮参与沉积的宏粒子数，与 ``p``、``ierr`` 一样为整数。

   本段示意数组的类型和形状为：实数数组 ``particle_position(3,np)``、整数数组 ``particle_cell(3,np)``
   和实数数组 ``particle_amount(np)``。这些是示例中的容器名称，实际程序可沿用自己的粒子存储方式，逐粒子取出上述三项数据传入。

   .. code-block:: fortran

      density = 0.0
      do p = 1, np
          call sub_B04_scatter_3d_cyl_nonuniform(r, phi, z, periodic_phi, &
              particle_cell(:,p), particle_position(:,p), particle_amount(p), &
              inv_volume, density, ierr)
          if (ierr /= B04_OK) error stop 'B04 scatter failed'
      end do

   例如，本轮只有两个宏粒子，分别代表 8 个和 5 个真实粒子：密度清零后，第一次调用累加前 8 个，
   第二次在已有结果上再累加 5 个，合计为 13 个。**清零放在粒子循环之前，才能保留本轮所有粒子的贡献。**
   下一轮重新计算密度时，再清零一次。

   **第四步：按计算区域和下游需要使用结果。**

   - **环域或普通节点：** 沉积后的 ``density`` 可交给后续节点计算。
   - **包含完整全周轴线：** 用 :doc:`轴点平均例程 <sub_B04_average_axis>` 统一同一物理轴点的密度，并检查返回状态。
   - **采用 MPI 分区：** 使用包含共享节点两侧贡献的完整有效体积；粒子沉积后先汇总共享节点贡献，再进行所需的全周轴点平均和下游计算。
   - **下游需要单元平均源项：** 如上方示例，调用 :doc:`单元平均例程 <sub_B04_project_density>`，把 ``cell_density`` 交给源项组装；需要节点量时使用 ``density``。

   调用条件和参数细节见 :doc:`几何准备 <sub_B04_build_geometry>` 与 :doc:`单粒子沉积 <sub_B04_scatter_3d_cyl_nonuniform>`；
   自动误差判据和已有运行结果见 :doc:`测试页 </tests/004_scatter/B04_scatter_3d_cyl_nonuniform>`。

   返回 :doc:`B04 总览 </rst_files/B_Scatter/B04_scatter_3d_cyl_nonuniform>` · :doc:`模块与公共接口 <mod_B04_scatter_3d_cyl_nonuniform>` · :doc:`测试与结果 </tests/004_scatter/B04_scatter_3d_cyl_nonuniform>`

.. container:: ap-lang ap-lang-en ap-b04-doc

   .. rubric:: Geometry preparation and density output

   The example uses a nonuniform annular sector with physical angular endpoints and one located macroparticle representing eight real particles.
   It follows **prepare volumes → clear density → scatter → read total number → optionally average over cells**.
   The domain has no axis, so inner-radius nodes are used directly.

   .. literalinclude:: ../../../../../examples/B04_scatter_3d_cyl_nonuniform/main.f90
      :language: fortran
      :linenos:

   The source is ``examples/B04_scatter_3d_cyl_nonuniform/main.f90`` in the repository, also available as a
   :download:`downloadable example main program <../../../../../examples/B04_scatter_3d_cyl_nonuniform/main.f90>`.
   Compile it together with the repository's B04 module using the command below.

   .. rubric:: Build and expected output

   .. code-block:: bash

      # From the repository root; GNU Fortran
      mkdir -p examples/B04_scatter_3d_cyl_nonuniform/build
      gfortran -cpp -std=f2008 -fdefault-real-8 -O0 -g -fcheck=all \
        -I B_Scatter/B04_scatter_3d_cyl_nonuniform \
        -J examples/B04_scatter_3d_cyl_nonuniform/build \
        B_Scatter/B04_scatter_3d_cyl_nonuniform/mod_B04_scatter_3d_cyl_nonuniform.f90 \
        examples/B04_scatter_3d_cyl_nonuniform/main.f90 \
        -o examples/B04_scatter_3d_cyl_nonuniform/build/b04_minimal
      examples/B04_scatter_3d_cyl_nonuniform/build/b04_minimal


   After execution, the terminal shows:

   .. code-block:: text

      Represented number =     8.000000
      Cell array shape = 2 2 2

   The first line gives **8 represented real particles** in the deposited nodal data, matching the input macroparticle weight.
   ``density/inv_volume`` multiplies each nodal density by its effective volume; summing these amounts gives the total number.
   The second line means that ``cell_density`` has **2 cells in each of the radial, angular and axial directions**.
   Choose one common length scale; metre coordinates give density in :math:`\mathrm{m}^{-3}`.

   .. _b04-adapt-example-en:

   .. rubric:: Use this single-particle example in your program

   Keep the calling sequence above and replace the example mesh and particle with your data.
   **Prepare geometry once; at each deposition stage, clear density and then accumulate all participating particles.**

   **Step 1: supply your mesh and allocate matching arrays.**

   .. list-table:: From example settings to application inputs
      :header-rows: 1
      :widths: 23 33 44

      * - Data
        - This example
        - In your program
      * - Node positions
        - Three nodes and two cells in each direction
        - Supply actual, strictly increasing ``r``, ``phi`` and ``z`` arrays; retain radius measured from the cylindrical axis
      * - Angular connectivity
        - ``.false.``: physical endpoints of a sector
        - Use ``.true.`` for periodic connectivity, consistently across calls; coordinates retain both endpoints, while density stores independent angular nodes
      * - Geometry and density arrays
        - Three entries per direction for nodes, two for cells
        - Allocate from your node counts and periodicity; see :ref:`array layouts <b04-grid-en>`, then call geometry preparation

   Reuse ``inv_volume`` and ``phi_measure`` in later stages while the mesh and periodicity remain fixed.

   **Step 2: prepare each particle's position, cell and represented amount.**

   In the example, ``[1.25,0.5,0.5]`` is a physical cylindrical position and ``[0,0,0]`` selects the first cell in each direction.
   In your program, apply particle boundary rules, then locate particles using the same mesh coordinates.
   The amount passed to deposition determines the density produced:

   - **Number density:** pass the represented real-particle number ``wp``, corresponding to ``8.0`` here.
   - **Charge density:** pass ``qp*wp``, where ``qp`` is the signed charge of one real particle.
     Species can contribute to a common charge-density array; keep their number-density arrays separate.

   **Step 3: place the deposition call inside your particle loop.**

   The structure below assumes that particle data have been prepared. ``particle_position(:,p)`` contains three coordinates,
   ``particle_cell(:,p)`` contains three cell indices, and ``particle_amount(p)`` contains the selected amount for particle ``p``.
   ``np`` counts participating macroparticles; it, ``p`` and ``ierr`` are integers.

   The illustrative arrays are real ``particle_position(3,np)``, integer ``particle_cell(3,np)``
   and real ``particle_amount(np)``. These names describe example containers; your program can retain its particle storage
   and extract the same three inputs for each call.

   .. code-block:: fortran

      density = 0.0
      do p = 1, np
          call sub_B04_scatter_3d_cyl_nonuniform(r, phi, z, periodic_phi, &
              particle_cell(:,p), particle_position(:,p), particle_amount(p), &
              inv_volume, density, ierr)
          if (ierr /= B04_OK) error stop 'B04 scatter failed'
      end do

   For example, two macroparticles may represent 8 and 5 real particles. After clearing density, the first call adds the first 8;
   the second adds another 5 to the existing result, giving a total of 13.
   **Clear before the particle loop to retain every contribution in this stage.** Clear again when starting a new density calculation.

   **Step 4: use the result according to your domain and downstream calculation.**

   - **An annulus or ordinary nodes:** pass the deposited ``density`` to subsequent nodal calculations.
   - **A complete full-circle axis:** use :doc:`axis averaging <sub_B04_average_axis>` to give each physical axis point a common density, and check the returned status.
   - **MPI partitions:** use complete effective volumes covering both sides of shared nodes. After deposition, sum shared-node contributions before full-circle axis averaging and downstream calculations.
   - **A cell-average source:** as in the example above, call :doc:`cell averaging <sub_B04_project_density>` and pass ``cell_density`` to source assembly. Nodal calculations use ``density``.

   See :doc:`geometry preparation <sub_B04_build_geometry>` and :doc:`single-particle deposition <sub_B04_scatter_3d_cyl_nonuniform>` for call conditions and parameters;
   :doc:`tests and results </tests/004_scatter/B04_scatter_3d_cyl_nonuniform>` supplies automated criteria and saved results.

   :doc:`B04 overview </rst_files/B_Scatter/B04_scatter_3d_cyl_nonuniform>` · :doc:`Module and public interfaces <mod_B04_scatter_3d_cyl_nonuniform>` · :doc:`Tests and results </tests/004_scatter/B04_scatter_3d_cyl_nonuniform>`

