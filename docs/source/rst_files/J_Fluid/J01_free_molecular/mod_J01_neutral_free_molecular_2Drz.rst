Module and Data
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``mod_J01_neutral_free_molecular_2Drz.f90`` 定义本章的类型与常量，
   并包含五个功能文件。完整计算入口是 ``sub_J01_free_molecular_mc_2Drz``。

   .. rubric:: 1. 应用准备的网格与边界

   ``r_edge(nr+1)``、``z_edge(nz+1)`` 是米为单位的网格边界，
   ``theta_span`` 是物理周向张角。有效单元用 ``active(nr,nz)`` 标记；
   ``face_type(4,nr,nz)`` 的每个元素回答“粒子碰到这个单元的这个面后，下一步做什么”。

   .. list-table::
      :header-rows: 1
      :widths: 34 12 54

      * - 常量
        - 值
        - 轨迹行为
      * - ``J01_FACE_INTERIOR``
        - 0
        - 穿到相邻有效单元，速度不变
      * - ``J01_FACE_OPEN``
        - 1
        - 记录逃逸并结束历史
      * - ``J01_FACE_WALL``
        - 2
        - 更新速度后留在气体区域，继续同一历史

   第一维面编号是 ``J01_R_LO=1``、``J01_R_HI=2``、
   ``J01_Z_LO=3``、``J01_Z_HI=4``。内部面两侧都必须标为内部面，
   且相邻单元有效。这里不需要保护层，也不接收 MPI 进程交界面。

   贯穿示例的下端与上端设为开放面，两个径向侧面为壁面，域内相邻面为内部面。
   入口准备过程只在第一排单元的轴向低端寻找注入区域。
   内部障碍须由有效单元标记和壁面标记共同定义，不能只将障碍中的密度设为零。

   对单元 :math:`(i,k)`，定义 :math:`\Delta z_k=z_{k+1}-z_k`，
   周向张角记为 :math:`\Theta`，完整一圈取 :math:`2\pi`。
   入口面积和统计归一化使用同一组物理几何量：

   .. math::

      V_{i,k}=\int_{z_k}^{z_{k+1}}\int_{r_i}^{r_{i+1}}
                   \Theta r\,\mathrm dr\,\mathrm dz
              =\frac{\Theta}{2}(r_{i+1}^2-r_i^2)\Delta z_k,

   .. math::

      A_{r-}=\Theta r_i\Delta z_k,\quad
      A_{r+}=\Theta r_{i+1}\Delta z_k,\quad
      A_{z-}=A_{z+}=\frac{\Theta}{2}(r_{i+1}^2-r_i^2).

   体积单位为 m³，面积为 m²。密度放在单元中；通量放在面上，
   按正 r 或正 z 方向取正。因而低端面流入为正、流出为负，高端面相反。

   .. figure:: /_static/J_Fluid/cell_flux.svg
      :alt: 单元密度和四个坐标方向面通量
      :width: 780px

      通量乘完整面面积才得到粒子率。图中箭头定义正方向，不预先规定实际流向。

   .. rubric:: 2. 一条粒子历史保存哪些状态

   粒子状态是四个实数 :math:`(r,z,v_r,v_z)`。
   程序名 ``ur,uz`` 在这里表示当前粒子的速度，不是单元平均速度。
   位置单位为 :math:`\mathrm m`，速度为 :math:`\mathrm{m\,s^{-1}}`。

   跟踪过程根据位置查找单元索引 :math:`i,k`；不需要调用者长期保存单元号。
   它原地修改状态，直至逃逸或被事件上限中断。
   模块没有保存整批粒子位置的数组；已完成历史只留下累计统计量。

   .. rubric:: 3. 入口结构：准备一次，反复采样

   ``fm_inlet_2drz_type`` 由 ``sub_J01_prepare_fm_inlet`` 输出，
   由 ``sub_J01_sample_fm_inlet`` 读取。

   .. list-table::
      :header-rows: 1
      :widths: 32 20 48

      * - 字段
        - 单位与尺寸
        - 含义
      * - ``segment_lo/segment_hi``
        - m，``(nr)``
        - 每个下端面的实际注入半径区间
      * - ``segment_area``
        - m²，``(nr)``
        - 该区间对应的环形面积；不可注入的位置为零
      * - ``inlet_area``
        - m²，标量
        - 所有注入段面积之和
      * - ``sigma_inlet``
        - m/s，标量
        - 入口正态速度分布的标准差

   每条历史代表的粒子率 ``history_rate`` 单独返回，不存入入口结构。
   它用于最后的统计归一化，不参与抽取某一条轨迹的速度。

   .. rubric:: 4. 统计结构：所有历史累加到同一组数组

   ``fm_tally_2drz_type`` 先由 ``sub_J01_initialize_fm_tally`` 分配并清零。
   每次跟踪累加它，最后由 ``sub_J01_finalize_fm_tally`` 读取。

   .. list-table::
      :header-rows: 1
      :widths: 30 25 45

      * - 字段
        - 尺寸
        - 原始统计量
      * - ``residence``
        - ``(nr,nz)``
        - 累计驻留时间，s
      * - ``moment_r/moment_z``
        - ``(nr,nz)``
        - 速度乘驻留时间的累计量，m
      * - ``count_r/count_z``
        - ``(nr-1,nz)``、``(nr,nz-1)``
        - 带坐标方向符号的内部穿面次数
      * - ``boundary_count``
        - ``(4,nr,nz)``
        - 带坐标方向符号的开放边界逃逸次数

   这些数组尚未乘粒子率，也未除以体积或面积。
   同一历史再次进入某个单元时仍继续累加；跨内部面后不能清零。
   无效单元保持零，只有一个单元的方向可以具有零长度内部面数组。

   .. rubric:: 5. 构建与调用约定

   只编译本模块文件，启用预处理，并把所在目录加入包含路径。
   各 ``sub`` 文件在同一个模块内实现过程，不是另外五个独立模块。
   默认 ``real`` 的精度由构建选项决定，调用端与模块必须保持一致。

   主入口负责形状、基本参数和内部面拓扑检查。
   直接调用底层过程时，调用者需要自行满足这些条件；
   底层过程未全部重复验证，也未全部返回错误码。
   随机种子修改 Fortran 运行时状态，相同种子的复现范围受编译器及运行时限制。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``mod_J01_neutral_free_molecular_2Drz.f90`` contains five implementation files.
   Compile this module with preprocessing and the include path; keep real precision consistent.

   The input grid uses edge arrays (nr+1,nz+1), an active mask (nr,nz), and face types (4,nr,nz).
   Face order is radial low/high, axial low/high. INTERIOR=0 crosses to a valid reciprocal neighbour,
   OPEN=1 terminates a history with an escape tally, WALL=2 reflects and continues it.
   No ghost layers or MPI partition faces are accepted by this interface.
   With sector angle :math:`\Theta` and cell length :math:`\Delta z_k`,

   .. math::

      V_{i,k}=\tfrac{\Theta}{2}(r_{i+1}^2-r_i^2)\Delta z_k,\quad
      A_{r-}=\Theta r_i\Delta z_k,\quad A_{r+}=\Theta r_{i+1}\Delta z_k,\quad
      A_{z\pm}=\tfrac{\Theta}{2}(r_{i+1}^2-r_i^2).

   Face fluxes use positive coordinate directions. Multiplication by full-face area gives particle rates.

   A particle state is (r,z,ur,uz), where ur/uz are particle velocities.
   The inlet structure stores per-segment bounds and areas, total inlet area, and thermal speed.
   The separate history_rate output supplies normalization.

   The tally structure stores cell residence (s), velocity-time moments (m),
   signed internal crossing counts, and signed boundary escape counts.
   Prepare the inlet once, initialize tallies once, accumulate all histories, then normalize.
   Lower-level calls require valid prepared data; they do not all repeat driver validation.
